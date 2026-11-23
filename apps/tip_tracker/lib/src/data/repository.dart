import 'package:app_core/app_core.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup/backup_service.dart';
import '../domain/periods.dart';
import '../domain/tip_math.dart';
import 'database.dart';

export 'database.dart';

final tipsDbProvider = Provider<TipsDb>((ref) {
  // Before any future schema upgrade, every row is copied to a backup file.
  final db = TipsDb(
    openAppDatabase('tips'),
    beforeUpgrade: (db, from) =>
        BackupService(db, ref.read(backupDirProvider), DateTime.now).writeBackup(BackupKind.upgrade),
  );
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<TipsRepository>((ref) => TipsRepository(ref.watch(tipsDbProvider)));

final activeJobsProvider = StreamProvider<List<Job>>((ref) => ref.watch(repositoryProvider).watchJobs());
final allJobsProvider = StreamProvider<List<Job>>(
  (ref) => ref.watch(repositoryProvider).watchJobs(includeArchived: true),
);
final allShiftsProvider = StreamProvider<List<Shift>>((ref) => ref.watch(repositoryProvider).watchShifts());

TipOutRule ruleOfJob(Job j) => TipOutRule(tipOutKindFromName(j.tipOutKind), j.tipOutValue);
TipOutRule ruleOfShift(Shift s) => TipOutRule(tipOutKindFromName(s.ruleKind), s.ruleValue);

ShiftMath mathOf(Shift s) => computeShift(
  ShiftInput(
    minutes: s.minutes,
    cashCents: s.cashCents,
    cardCents: s.cardCents,
    tipInCents: s.tipInCents,
    salesCents: s.salesCents,
    rateCents: s.rateCents,
    rule: ruleOfShift(s),
    tipOutOverrideCents: s.tipOutCents,
  ),
);

class SaveResult {
  const SaveResult.ok(this.id) : error = null;
  const SaveResult.error(this.error) : id = null;
  final int? id;
  final String? error;
  bool get ok => error == null;
}

/// Everything the shift editor hands over to be saved.
class ShiftDraft {
  ShiftDraft({
    this.id,
    required this.jobId,
    required this.day,
    this.startMinute,
    this.endMinute,
    this.breakMinutes = 0,
    this.typedMinutes,
    this.cashCents = 0,
    this.cardCents = 0,
    this.tipInCents = 0,
    this.salesCents,
    this.tipOutOverrideCents,
    this.note = '',
  });

  final int? id;
  final int jobId;
  final DateTime day;
  final int? startMinute;
  final int? endMinute;
  final int breakMinutes;
  final int? typedMinutes;
  final int cashCents;
  final int cardCents;
  final int tipInCents;
  final int? salesCents;
  final int? tipOutOverrideCents;
  final String note;

  bool get usesTimes => startMinute != null || endMinute != null;

  int? get minutes {
    if (usesTimes) {
      if (startMinute == null || endMinute == null) return null;
      return spanMinutes(startMinute!, endMinute!) - breakMinutes;
    }
    return typedMinutes;
  }

  ShiftInput input(int minutes, {required int rateCents, required TipOutRule rule}) => ShiftInput(
    minutes: minutes,
    cashCents: cashCents,
    cardCents: cardCents,
    tipInCents: tipInCents,
    salesCents: salesCents,
    rateCents: rateCents,
    rule: rule,
    tipOutOverrideCents: tipOutOverrideCents,
  );
}

class TipsRepository {
  TipsRepository(this.db);
  final TipsDb db;

  Stream<List<Job>> watchJobs({bool includeArchived = false}) {
    final q = db.select(db.jobs)..orderBy([(j) => OrderingTerm(expression: j.id)]);
    if (!includeArchived) q.where((j) => j.archived.equals(false));
    return q.watch();
  }

  /// Every row that can still be read from damaged data, row by row, so one
  /// bad row doesn't hide the rest. [skipped] counts rows that couldn't be.
  Future<({List<Job> jobs, List<Shift> shifts, int skipped})> readable() async {
    var skipped = 0;
    Future<List<T>> rows<T>(String table, T Function(Map<String, dynamic>) map) async {
      List<QueryRow> raw;
      try {
        raw = await db.customSelect('SELECT * FROM $table ORDER BY id').get();
      } catch (_) {
        skipped++;
        return <T>[];
      }
      final out = <T>[];
      for (final r in raw) {
        try {
          out.add(map(r.data));
        } catch (_) {
          skipped++;
        }
      }
      return out;
    }

    final jobs = await rows<Job>('jobs', (d) => db.jobs.map(d));
    final shifts = await rows<Shift>('shifts', (d) => db.shifts.map(d));
    return (jobs: jobs, shifts: shifts, skipped: skipped);
  }

  Future<List<Job>> jobs({bool includeArchived = true}) {
    final q = db.select(db.jobs)..orderBy([(j) => OrderingTerm(expression: j.id)]);
    if (!includeArchived) q.where((j) => j.archived.equals(false));
    return q.get();
  }

  Future<Job?> job(int id) => (db.select(db.jobs)..where((j) => j.id.equals(id))).getSingleOrNull();

  /// Newest first.
  Stream<List<Shift>> watchShifts() =>
      (db.select(db.shifts)..orderBy([
            (s) => OrderingTerm(expression: s.day, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.startMinute, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.id, mode: OrderingMode.desc),
          ]))
          .watch();

  Future<List<Shift>> shifts() =>
      (db.select(db.shifts)..orderBy([(s) => OrderingTerm(expression: s.day), (s) => OrderingTerm(expression: s.id)]))
          .get();

  Future<Shift?> shift(int id) => (db.select(db.shifts)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> shiftCountForJob(int jobId) async {
    final c = db.shifts.id.count();
    final row = await (db.selectOnly(db.shifts)
          ..addColumns([c])
          ..where(db.shifts.jobId.equals(jobId)))
        .getSingle();
    return row.read(c) ?? 0;
  }

  /// Validates and saves a job. Names must be unique among active jobs.
  Future<SaveResult> saveJob({
    int? id,
    required String name,
    required String role,
    required int rateCents,
    required TipOutRule rule,
    required bool tracksSales,
    required int colorIndex,
    PayPeriodKind? payKind,
    DateTime? payAnchor,
  }) async {
    final n = name.trim();
    if (n.isEmpty) return const SaveResult.error('Give the job a name.');
    if (n.length > 60) return const SaveResult.error('Keep the name under 60 letters.');
    if (rateCents < 0 || rateCents > maxMoneyCents) return const SaveResult.error('Check the hourly wage.');
    if (rule.kind != TipOutKind.none && rule.value <= 0) {
      return const SaveResult.error('Enter the tip-out amount, or pick No tip-out.');
    }
    if ((rule.kind == TipOutKind.pctSales || rule.kind == TipOutKind.pctTips) && rule.value > 10000) {
      return const SaveResult.error('A percentage can’t be over 100.');
    }
    final clash = await (db.select(db.jobs)..where((j) => j.archived.equals(false) & j.name.lower().equals(n.toLowerCase()))).get();
    if (clash.any((j) => j.id != id)) return const SaveResult.error('You already have a job with that name.');
    final c = JobsCompanion(
      name: Value(n),
      role: Value(role),
      rateCents: Value(rateCents),
      tipOutKind: Value(rule.kind.name),
      tipOutValue: Value(rule.kind == TipOutKind.none ? 0 : rule.value),
      tracksSales: Value(tracksSales || rule.needsSales),
      colorIndex: Value(colorIndex),
      payKind: Value(payKind?.name),
      payAnchor: Value(payAnchor == null ? null : dayKey(payAnchor)),
    );
    if (id != null) {
      await (db.update(db.jobs)..where((j) => j.id.equals(id))).write(c);
      return SaveResult.ok(id);
    }
    final newId = await db.into(db.jobs).insert(c.copyWith(createdAt: Value(DateTime.now())));
    return SaveResult.ok(newId);
  }

  Future<void> setArchived(int id, bool archived) =>
      (db.update(db.jobs)..where((j) => j.id.equals(id))).write(JobsCompanion(archived: Value(archived)));

  /// Deletes a job only when it has no shifts.
  Future<SaveResult> deleteJob(int id) async {
    if (await shiftCountForJob(id) > 0) {
      return const SaveResult.error('This job has shifts. Archive it instead to keep them.');
    }
    await (db.delete(db.jobs)..where((j) => j.id.equals(id))).go();
    return SaveResult.ok(id);
  }

  Future<SaveResult> saveShift(ShiftDraft d, {required DateTime now}) async {
    final job = await this.job(d.jobId);
    if (job == null) return const SaveResult.error('Pick a job.');
    // Editing keeps the wage and rule the shift was first saved with.
    final found = d.id == null ? null : await shift(d.id!);
    if (d.id != null && found == null) return const SaveResult.error('This shift was deleted.');
    // A shift moved to another job takes that job's wage and rule.
    final existing = found != null && found.jobId == d.jobId ? found : null;
    final rate = existing?.rateCents ?? job.rateCents;
    final rule = existing == null ? ruleOfJob(job) : ruleOfShift(existing);
    final check = checkShift(
      day: d.day,
      today: now,
      startMinute: d.startMinute,
      endMinute: d.endMinute,
      breakMinutes: d.breakMinutes,
      typedMinutes: d.typedMinutes,
      build: (m) => d.input(m, rateCents: rate, rule: rule),
    );
    if (!check.ok) return SaveResult.error(check.error);
    final minutes = d.minutes!;
    final math = computeShift(d.input(minutes, rateCents: rate, rule: rule));
    final c = ShiftsCompanion(
      jobId: Value(d.jobId),
      day: Value(dayKey(d.day)),
      startMinute: Value(d.usesTimes ? d.startMinute : null),
      endMinute: Value(d.usesTimes ? d.endMinute : null),
      breakMinutes: Value(d.usesTimes ? d.breakMinutes : 0),
      minutes: Value(minutes),
      cashCents: Value(d.cashCents),
      cardCents: Value(d.cardCents),
      tipInCents: Value(d.tipInCents),
      salesCents: Value(d.salesCents),
      tipOutCents: Value(math.tipOut),
      tipOutEdited: Value(d.tipOutOverrideCents != null),
      rateCents: Value(rate),
      ruleKind: Value(rule.kind.name),
      ruleValue: Value(rule.value),
      note: Value(d.note.trim()),
      updatedAt: Value(now),
    );
    return db.transaction(() async {
      if (d.id != null) {
        await (db.update(db.shifts)..where((s) => s.id.equals(d.id!))).write(c);
        return SaveResult.ok(d.id);
      }
      final id = await db.into(db.shifts).insert(c.copyWith(createdAt: Value(now)));
      return SaveResult.ok(id);
    });
  }

  Future<void> deleteShift(int id) => (db.delete(db.shifts)..where((s) => s.id.equals(id))).go();

  /// Puts a deleted shift back exactly as it was (Undo).
  Future<void> restoreShift(Shift s) => db.into(db.shifts).insert(s, mode: InsertMode.insertOrReplace);
}

/// App preferences beyond the shared core settings.
class TipPrefs {
  TipPrefs(this.ref);
  final Ref ref;

  static const weekStartKey = 'tips.week_start';
  static const payKindKey = 'tips.pay_kind';
  static const payAnchorKey = 'tips.pay_anchor';
  static const taxPctKey = 'tips.tax_bp';
  static const lastJobKey = 'tips.last_job';
  static const hoursModeKey = 'tips.hours_mode_times';
  static const autoBackupKey = 'tips.auto_backup';
  static const draftKey = 'tips.shift_draft';
}

class TipSettings {
  const TipSettings({
    required this.weekStartsOn,
    required this.payKind,
    required this.payAnchor,
    required this.taxBp,
    required this.lastJobId,
    required this.useTimes,
    required this.autoBackup,
  });
  final int weekStartsOn;
  final PayPeriodKind payKind;
  final DateTime payAnchor;
  final int taxBp;
  final int? lastJobId;
  final bool useTimes;
  final bool autoBackup;
}

class TipSettingsNotifier extends Notifier<TipSettings> {
  @override
  TipSettings build() {
    final p = ref.watch(sharedPrefsProvider);
    final anchor = p.getString(TipPrefs.payAnchorKey);
    return TipSettings(
      weekStartsOn: p.getInt(TipPrefs.weekStartKey) ?? DateTime.monday,
      payKind: payPeriodKindFromName(p.getString(TipPrefs.payKindKey) ?? 'weekly'),
      payAnchor: anchor == null ? DateTime(2026, 1, 5) : parseDay(anchor),
      taxBp: p.getInt(TipPrefs.taxPctKey) ?? 1500,
      lastJobId: p.getInt(TipPrefs.lastJobKey),
      useTimes: p.getBool(TipPrefs.hoursModeKey) ?? true,
      autoBackup: p.getBool(TipPrefs.autoBackupKey) ?? true,
    );
  }

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  Future<void> setWeekStart(int d) async {
    await _p.setInt(TipPrefs.weekStartKey, d);
    ref.invalidateSelf();
  }

  Future<void> setPayPeriod(PayPeriodKind k, DateTime anchor) async {
    await _p.setString(TipPrefs.payKindKey, k.name);
    await _p.setString(TipPrefs.payAnchorKey, dayKey(anchor));
    ref.invalidateSelf();
  }

  Future<void> setTaxBp(int bp) async {
    await _p.setInt(TipPrefs.taxPctKey, bp);
    ref.invalidateSelf();
  }

  Future<void> setLastJob(int id) async {
    await _p.setInt(TipPrefs.lastJobKey, id);
    ref.invalidateSelf();
  }

  Future<void> setUseTimes(bool v) async {
    await _p.setBool(TipPrefs.hoursModeKey, v);
    ref.invalidateSelf();
  }

  Future<void> setAutoBackup(bool v) async {
    await _p.setBool(TipPrefs.autoBackupKey, v);
    ref.invalidateSelf();
  }
}

final tipSettingsProvider = NotifierProvider<TipSettingsNotifier, TipSettings>(TipSettingsNotifier.new);

/// Formats cents in the person's chosen currency.
final moneyFmtProvider = Provider<String Function(int)>((ref) {
  final cur = ref.watch(coreSettingsProvider.select((s) => s.currency));
  return (c) => Money.format(c, currency: cur);
});

/// The pay period [job] is paid on, or the Settings default when no job is
/// picked or the job never set one. Each job can be paid on its own cycle.
Period payPeriodFor(Job? job, TipSettings s, DateTime now) {
  final kind = job?.payKind == null ? s.payKind : payPeriodKindFromName(job!.payKind!);
  final anchor = job?.payAnchor == null ? s.payAnchor : parseDay(job!.payAnchor!);
  return payPeriodContaining(now, kind, anchor);
}

PayPeriodKind payKindFor(Job? job, TipSettings s) => job?.payKind == null ? s.payKind : payPeriodKindFromName(job!.payKind!);
