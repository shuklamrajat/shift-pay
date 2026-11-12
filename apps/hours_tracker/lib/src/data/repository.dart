import 'package:app_core/app_core.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pay_engine.dart';
import 'database.dart';

export 'database.dart';

final hoursDbProvider = Provider<HoursDb>((ref) {
  final db = HoursDb(openAppDatabase('hours'));
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<HoursRepository>((ref) => HoursRepository(ref.watch(hoursDbProvider)));

PayRules rulesFor(Job j) => PayRules(
  dailyRegularLimitMin: j.dailyLimitMin,
  dailyDoubleLimitMin: j.dailyDoubleMin,
  weeklyRegularLimitMin: j.weeklyLimitMin,
  otMultiplierPct: j.otPct,
  doubleMultiplierPct: j.doublePct,
  weekStartsOn: j.weekStartsOn,
  workdayStartMinute: j.workdayStartMinute,
);

DateTime truncateToMinute(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute);

class SaveShiftResult {
  const SaveShiftResult.ok(this.id) : error = null;
  const SaveShiftResult.error(this.error) : id = null;
  final int? id;
  final String? error;
  bool get ok => error == null;
}

class HoursRepository {
  HoursRepository(this.db);
  final HoursDb db;

  Stream<List<Job>> watchJobs() =>
      (db.select(db.jobs)
            ..where((j) => j.archived.equals(false))
            ..orderBy([(j) => OrderingTerm(expression: j.id)]))
          .watch();

  Future<Job> job(int id) => (db.select(db.jobs)..where((j) => j.id.equals(id))).getSingle();

  Future<int> saveJob(JobsCompanion c) async {
    if (c.id.present) {
      await (db.update(db.jobs)..where((j) => j.id.equals(c.id.value))).write(c);
      return c.id.value;
    }
    return db.into(db.jobs).insert(c.copyWith(createdAt: Value(DateTime.now())));
  }

  Future<void> archiveJob(int id) =>
      (db.update(db.jobs)..where((j) => j.id.equals(id))).write(const JobsCompanion(archived: Value(true)));

  Stream<Shift?> watchOpenShift() =>
      (db.select(db.shifts)
            ..where((s) => s.end.isNull())
            ..limit(1))
          .watchSingleOrNull();

  /// Shifts of a job whose start falls in [from, toExclusive), open ones included.
  Stream<List<Shift>> watchShifts(int jobId, DateTime from, DateTime toExclusive) =>
      (db.select(db.shifts)
            ..where(
              (s) =>
                  s.jobId.equals(jobId) & s.start.isBiggerOrEqualValue(from) & s.start.isSmallerThanValue(toExclusive),
            )
            ..orderBy([(s) => OrderingTerm(expression: s.start)]))
          .watch();

  /// Pay for the workdays in [from, toExclusive), computed on whole weeks.
  Stream<(PayResult, PaySummary)> watchPay(Job job, DateTime from, DateTime toExclusive) {
    final rules = rulesFor(job);
    final weekFrom = weekStartOf(dateOnly(from), rules.weekStartsOn);
    // One extra day on each side catches shifts moved by the workday start.
    final qFrom = DateTime(weekFrom.year, weekFrom.month, weekFrom.day - 1);
    final qTo = DateTime(toExclusive.year, toExclusive.month, toExclusive.day + 1);
    return watchShifts(job.id, qFrom, qTo).map((rows) {
      final closed = [
        for (final s in rows)
          if (s.end != null)
            ShiftInput(
              id: '${s.id}',
              start: s.start,
              end: s.end!,
              unpaidBreakMin: s.unpaidBreakMin,
              rateCents: s.rateCents,
            ),
      ];
      final result = computePay(closed, rules);
      return (result, summarize(result, from: from, toExclusive: toExclusive));
    });
  }

  Future<SaveShiftResult> saveShift({
    int? id,
    required int jobId,
    required DateTime start,
    required DateTime? end,
    required int unpaidBreakMin,
    required int rateCents,
    String note = '',
  }) async {
    start = truncateToMinute(start);
    end = end == null ? null : truncateToMinute(end);
    if (end != null) {
      final err = validateShift(start, end, unpaidBreakMin);
      if (err != null) return SaveShiftResult.error(err);
    } else {
      final open = await (db.select(db.shifts)..where((s) => s.end.isNull())).get();
      if (open.any((s) => s.id != id)) {
        return const SaveShiftResult.error('You are already clocked in on another shift.');
      }
    }
    // Overlap check against neighbours within a day either side.
    final effectiveEnd = end ?? start.add(const Duration(minutes: 1));
    final near =
        await (db.select(db.shifts)..where(
              (s) =>
                  s.jobId.equals(jobId) &
                  s.start.isBiggerOrEqualValue(start.subtract(const Duration(hours: 25))) &
                  s.start.isSmallerThanValue(effectiveEnd),
            ))
            .get();
    final clash = findOverlap(
      [for (final s in near) (id: '${s.id}', start: s.start, end: s.end ?? DateTime(9999))],
      start,
      effectiveEnd,
      ignoreId: id == null ? null : '$id',
    );
    if (clash != null) {
      final other = near.firstWhere((s) => '${s.id}' == clash);
      return SaveShiftResult.error('This overlaps another shift that starts ${_fmt(other.start)}.');
    }
    final c = ShiftsCompanion(
      jobId: Value(jobId),
      start: Value(start),
      end: Value(end),
      unpaidBreakMin: Value(unpaidBreakMin),
      rateCents: Value(rateCents),
      note: Value(note.trim()),
      updatedAt: Value(DateTime.now()),
    );
    if (id != null) {
      await (db.update(db.shifts)..where((s) => s.id.equals(id))).write(c);
      return SaveShiftResult.ok(id);
    }
    return SaveShiftResult.ok(await db.into(db.shifts).insert(c));
  }

  Future<void> deleteShift(int id) => (db.delete(db.shifts)..where((s) => s.id.equals(id))).go();

  Future<SaveShiftResult> clockIn(Job job, DateTime now) =>
      saveShift(jobId: job.id, start: now, end: null, unpaidBreakMin: 0, rateCents: job.rateCents);

  Future<SaveShiftResult> clockOut(Shift open, DateTime now) {
    var end = truncateToMinute(now);
    if (!end.isAfter(open.start)) end = open.start.add(const Duration(minutes: 1));
    return saveShift(
      id: open.id,
      jobId: open.jobId,
      start: open.start,
      end: end,
      unpaidBreakMin: open.unpaidBreakMin,
      rateCents: open.rateCents,
      note: open.note,
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Currently selected job id (null = first job).
class SelectedJob extends Notifier<int?> {
  static final _pref = PrefValue<int>('hours.selectedJob', -1);
  @override
  int? build() {
    final v = _pref.read(ref.watch(sharedPrefsProvider));
    return v < 0 ? null : v;
  }

  Future<void> select(int id) async {
    await _pref.write(ref.read(sharedPrefsProvider), id);
    state = id;
  }
}

final selectedJobIdProvider = NotifierProvider<SelectedJob, int?>(SelectedJob.new);

final jobsProvider = StreamProvider<List<Job>>((ref) => ref.watch(repositoryProvider).watchJobs());

final currentJobProvider = Provider<Job?>((ref) {
  final jobs = ref.watch(jobsProvider).value ?? const [];
  if (jobs.isEmpty) return null;
  final id = ref.watch(selectedJobIdProvider);
  return jobs.firstWhere((j) => j.id == id, orElse: () => jobs.first);
});

final openShiftProvider = StreamProvider<Shift?>((ref) => ref.watch(repositoryProvider).watchOpenShift());

typedef PayKey = ({int jobId, DateTime from, DateTime toExclusive});

final payProvider = StreamProvider.family<(PayResult, PaySummary), PayKey>((ref, key) async* {
  final repo = ref.watch(repositoryProvider);
  // Watching the job list recomputes pay when the job's rules change.
  final jobs = await ref.watch(jobsProvider.future);
  final job = jobs.where((j) => j.id == key.jobId).firstOrNull ?? await repo.job(key.jobId);
  yield* repo.watchPay(job, key.from, key.toExclusive);
});

final weekShiftsProvider = StreamProvider.family<List<Shift>, PayKey>(
  (ref, key) => ref.watch(repositoryProvider).watchShifts(key.jobId, key.from, key.toExclusive),
);
