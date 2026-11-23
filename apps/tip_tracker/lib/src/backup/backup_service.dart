import 'dart:convert';
import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/repository.dart';
import '../domain/periods.dart';
import '../domain/tip_math.dart';

const backupFormat = 'widdle.tips.backup';
const backupFormatVersion = 1;
const keepAuto = 14;
const keepSafety = 5;

enum BackupKind { auto, safety, upgrade, manual }

final backupListProvider = FutureProvider<List<BackupFileInfo>>((ref) => ref.watch(backupServiceProvider).listBackups());

/// Where automatic and safety copies live (the app's private folder).
final backupDirProvider = Provider<Future<Directory> Function()>((ref) {
  return () async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'backups')).create(recursive: true);
  };
});

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(tipsDbProvider), ref.watch(backupDirProvider), ref.watch(clockProvider)),
);

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What a backup holds, shown before anything is replaced.
class BackupPreview {
  BackupPreview({
    required this.createdAt,
    required this.jobs,
    required this.shifts,
    required this.firstDay,
    required this.lastDay,
    required this.jobRows,
    required this.shiftRows,
  });
  final DateTime createdAt;
  final int jobs;
  final int shifts;
  final String? firstDay;
  final String? lastDay;
  final List<Map<String, dynamic>> jobRows;
  final List<Map<String, dynamic>> shiftRows;
}

class BackupFileInfo {
  BackupFileInfo(this.file, this.kind, this.createdAt);
  final File file;
  final BackupKind kind;
  final DateTime createdAt;
}

class BackupService {
  BackupService(this.db, this.dir, this.clock);
  final TipsDb db;
  final Future<Directory> Function() dir;
  final DateTime Function() clock;

  // ---- writing ----

  Future<Map<String, dynamic>> _dataSection() async {
    final jobs = await db.customSelect('SELECT * FROM jobs ORDER BY id').get();
    final shifts = await db.customSelect('SELECT * FROM shifts ORDER BY id').get();
    return {
      'jobs': [for (final r in jobs) _jobJson(r.data)],
      'shifts': [for (final r in shifts) _shiftJson(r.data)],
    };
  }

  // Raw rows so this keeps working on an old schema during an upgrade.
  Map<String, dynamic> _jobJson(Map<String, dynamic> r) => {
    'id': r['id'],
    'name': r['name'],
    'role': r['role'] ?? 'server',
    'rateCents': r['rate_cents'] ?? 0,
    'tipOutKind': r['tip_out_kind'] ?? 'none',
    'tipOutValue': r['tip_out_value'] ?? 0,
    'tracksSales': _bool(r['tracks_sales']),
    'colorIndex': r['color_index'] ?? 0,
    'archived': _bool(r['archived']),
    'createdAt': r['created_at'],
  };

  Map<String, dynamic> _shiftJson(Map<String, dynamic> r) => {
    'id': r['id'],
    'jobId': r['job_id'],
    'day': r['day'],
    'startMinute': r['start_minute'],
    'endMinute': r['end_minute'],
    'breakMinutes': r['break_minutes'] ?? 0,
    'minutes': r['minutes'],
    'cashCents': r['cash_cents'] ?? 0,
    'cardCents': r['card_cents'] ?? 0,
    'tipInCents': r['tip_in_cents'] ?? 0,
    'salesCents': r['sales_cents'],
    'tipOutCents': r['tip_out_cents'] ?? 0,
    'tipOutEdited': _bool(r['tip_out_edited']),
    'rateCents': r['rate_cents'],
    'ruleKind': r['rule_kind'] ?? 'none',
    'ruleValue': r['rule_value'] ?? 0,
    'note': r['note'] ?? '',
    'createdAt': r['created_at'],
    'updatedAt': r['updated_at'],
  };

  static bool _bool(Object? v) => v == true || v == 1;

  /// The backup as bytes. The checksum covers the exact JSON of `data`.
  Future<Uint8List> buildBackup({String appVersion = '0.1.0'}) async {
    final data = await _dataSection();
    final dataJson = jsonEncode(data);
    final days = [for (final s in data['shifts'] as List) s['day'] as String]..sort();
    final doc = {
      'format': backupFormat,
      'formatVersion': backupFormatVersion,
      'schemaVersion': db.schemaVersion,
      'appVersion': appVersion,
      'createdAt': clock().toIso8601String(),
      'counts': {'jobs': (data['jobs'] as List).length, 'shifts': days.length},
      'range': {'from': days.isEmpty ? null : days.first, 'to': days.isEmpty ? null : days.last},
      'sha256': sha256.convert(utf8.encode(dataJson)).toString(),
      'data': data,
    };
    return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent(' ').convert(doc)));
  }

  String fileName(BackupKind kind, DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}${two(at.second)}';
    return 'tips-${kind.name}-$stamp.json';
  }

  /// Writes a backup into the private backups folder. Writes to a temp file
  /// first and renames, so a failed write never leaves a half file.
  Future<File> writeBackup(BackupKind kind, {Directory? into}) async {
    final bytes = await buildBackup();
    final folder = into ?? await dir();
    final now = clock();
    var target = File(p.join(folder.path, fileName(kind, now)));
    var n = 1;
    while (await target.exists()) {
      target = File(p.join(folder.path, fileName(kind, now).replaceFirst('.json', '-$n.json')));
      n++;
    }
    final tmp = File('${target.path}.tmp');
    try {
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(target.path);
    } catch (e) {
      if (await tmp.exists()) await tmp.delete();
      throw BackupException('Couldn’t write the backup: $e');
    }
    await _prune();
    return target;
  }

  Future<List<BackupFileInfo>> listBackups() async {
    final folder = await dir();
    if (!await folder.exists()) return [];
    final re = RegExp(r'^tips-(auto|safety|upgrade|manual)-(\d{8})-(\d{6})(?:-\d+)?\.json$');
    final out = <BackupFileInfo>[];
    await for (final e in folder.list()) {
      if (e is! File) continue;
      final m = re.firstMatch(p.basename(e.path));
      if (m == null) continue;
      final d = m.group(2)!;
      final t = m.group(3)!;
      final at = DateTime(
        int.parse(d.substring(0, 4)),
        int.parse(d.substring(4, 6)),
        int.parse(d.substring(6, 8)),
        int.parse(t.substring(0, 2)),
        int.parse(t.substring(2, 4)),
        int.parse(t.substring(4, 6)),
      );
      out.add(BackupFileInfo(e, BackupKind.values.byName(m.group(1)!), at));
    }
    out.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.file.path.compareTo(a.file.path);
    });
    return out;
  }

  Future<void> _prune() async {
    final all = await listBackups();
    final auto = all.where((b) => b.kind == BackupKind.auto).toList();
    final safety = all.where((b) => b.kind == BackupKind.safety || b.kind == BackupKind.upgrade).toList();
    for (final b in [...auto.skip(keepAuto), ...safety.skip(keepSafety)]) {
      await b.file.delete();
    }
  }

  /// At most one automatic backup per calendar day. Skips an empty database.
  /// Returns the file written, or null.
  Future<File?> maybeAutoBackup() async {
    final count = await db.customSelect('SELECT (SELECT COUNT(*) FROM jobs) + (SELECT COUNT(*) FROM shifts) AS n').getSingle();
    if ((count.data['n'] as int) == 0) return null;
    final today = dayKey(clock());
    final autos = (await listBackups()).where((b) => b.kind == BackupKind.auto);
    if (autos.any((b) => dayKey(b.createdAt) == today)) return null;
    return writeBackup(BackupKind.auto);
  }

  Future<DateTime?> lastBackupAt() async {
    final all = await listBackups();
    return all.isEmpty ? null : all.first.createdAt;
  }

  // ---- reading and restoring ----

  /// Checks everything about a backup without touching the database.
  BackupPreview inspect(Uint8List bytes) {
    final Object? doc;
    try {
      doc = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw BackupException('This isn’t a Tipwell backup file.');
    }
    if (doc is! Map<String, dynamic> || doc['format'] != backupFormat) {
      throw BackupException('This isn’t a Tipwell backup file.');
    }
    final version = doc['formatVersion'];
    if (version is! int) throw BackupException('This backup file is damaged.');
    if (version > backupFormatVersion) {
      throw BackupException('This backup was made by a newer version. Update the app to restore it.');
    }
    final data = doc['data'];
    if (data is! Map<String, dynamic>) throw BackupException('This backup file is damaged.');
    final sum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
    if (sum != doc['sha256']) {
      throw BackupException('This backup file was changed or is incomplete, so it can’t be trusted.');
    }
    final jobs = data['jobs'];
    final shifts = data['shifts'];
    if (jobs is! List || shifts is! List) throw BackupException('This backup file is damaged.');

    final jobIds = <int>{};
    final jobRows = <Map<String, dynamic>>[];
    for (final (i, j) in jobs.indexed) {
      if (j is! Map<String, dynamic>) throw BackupException('Job ${i + 1} in the backup is damaged.');
      final id = j['id'];
      final name = j['name'];
      if (id is! int || name is! String || name.trim().isEmpty || name.length > 60) {
        throw BackupException('Job ${i + 1} in the backup is damaged.');
      }
      if (!jobIds.add(id)) throw BackupException('The backup lists job $id twice.');
      if (_money(j['rateCents']) == null || j['tipOutValue'] is! int || (j['tipOutValue'] as int) < 0) {
        throw BackupException('Job “$name” in the backup has a bad amount.');
      }
      jobRows.add(j);
    }
    final shiftIds = <int>{};
    final shiftRows = <Map<String, dynamic>>[];
    final dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    for (final (i, s) in shifts.indexed) {
      final where = 'Shift ${i + 1} in the backup';
      if (s is! Map<String, dynamic>) throw BackupException('$where is damaged.');
      final id = s['id'];
      if (id is! int) throw BackupException('$where is damaged.');
      if (!shiftIds.add(id)) throw BackupException('The backup lists shift $id twice.');
      if (!jobIds.contains(s['jobId'])) throw BackupException('$where belongs to a job that isn’t in the file.');
      final day = s['day'];
      if (day is! String || !dayRe.hasMatch(day)) throw BackupException('$where has a bad date.');
      final minutes = s['minutes'];
      if (minutes is! int || minutes <= 0 || minutes > maxShiftMinutes) {
        throw BackupException('$where has a bad length.');
      }
      for (final k in ['cashCents', 'cardCents', 'tipInCents', 'tipOutCents', 'rateCents']) {
        if (_money(s[k]) == null) throw BackupException('$where has a bad amount.');
      }
      if (s['salesCents'] != null && _money(s['salesCents']) == null) {
        throw BackupException('$where has a bad amount.');
      }
      shiftRows.add(s);
    }
    final days = [for (final s in shiftRows) s['day'] as String]..sort();
    return BackupPreview(
      createdAt: DateTime.tryParse('${doc['createdAt']}') ?? DateTime(1970),
      jobs: jobRows.length,
      shifts: shiftRows.length,
      firstDay: days.isEmpty ? null : days.first,
      lastDay: days.isEmpty ? null : days.last,
      jobRows: jobRows,
      shiftRows: shiftRows,
    );
  }

  static int? _money(Object? v) => v is int && v >= 0 && v <= 999999999 ? v : null;

  /// Replaces all data with the backup's. Writes a safety copy of the
  /// current data first. All-or-nothing.
  Future<File?> restore(BackupPreview b) async {
    final safety = await _hasData() ? await writeBackup(BackupKind.safety) : null;
    DateTime ts(Object? v) {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      return DateTime.tryParse('$v') ?? clock();
    }

    await db.transaction(() async {
      await db.delete(db.shifts).go();
      await db.delete(db.jobs).go();
      for (final j in b.jobRows) {
        await db
            .into(db.jobs)
            .insert(
              JobsCompanion.insert(
                id: Value(j['id'] as int),
                name: (j['name'] as String).trim(),
                role: Value('${j['role'] ?? 'server'}'),
                rateCents: Value(j['rateCents'] as int),
                tipOutKind: Value(tipOutKindFromName('${j['tipOutKind']}').name),
                tipOutValue: Value(j['tipOutValue'] as int),
                tracksSales: Value(j['tracksSales'] == true),
                colorIndex: Value((j['colorIndex'] as int?) ?? 0),
                archived: Value(j['archived'] == true),
                createdAt: ts(j['createdAt']),
              ),
            );
      }
      for (final s in b.shiftRows) {
        await db
            .into(db.shifts)
            .insert(
              ShiftsCompanion.insert(
                id: Value(s['id'] as int),
                jobId: s['jobId'] as int,
                day: s['day'] as String,
                startMinute: Value(s['startMinute'] as int?),
                endMinute: Value(s['endMinute'] as int?),
                breakMinutes: Value((s['breakMinutes'] as int?) ?? 0),
                minutes: s['minutes'] as int,
                cashCents: Value(s['cashCents'] as int),
                cardCents: Value(s['cardCents'] as int),
                tipInCents: Value(s['tipInCents'] as int),
                salesCents: Value(s['salesCents'] as int?),
                tipOutCents: Value(s['tipOutCents'] as int),
                tipOutEdited: Value(s['tipOutEdited'] == true),
                rateCents: s['rateCents'] as int,
                ruleKind: Value(tipOutKindFromName('${s['ruleKind']}').name),
                ruleValue: Value((s['ruleValue'] as int?) ?? 0),
                note: Value('${s['note'] ?? ''}'),
                createdAt: ts(s['createdAt']),
                updatedAt: ts(s['updatedAt']),
              ),
            );
      }
      final problems = await db.healthProblems();
      if (problems.isNotEmpty) throw BackupException('Restore stopped: ${problems.join(', ')}');
    });
    return safety;
  }

  Future<bool> _hasData() async {
    final r = await db.customSelect('SELECT (SELECT COUNT(*) FROM jobs) + (SELECT COUNT(*) FROM shifts) AS n').getSingle();
    return (r.data['n'] as int) > 0;
  }
}
