import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app.dart' show featureExport;
import '../backup/backup_service.dart';
import '../data/repository.dart';
import '../domain/periods.dart';
import '../export/tip_export.dart';
import 'fields.dart';
import 'scenes.dart';

/// Lets the person pick a file. Swapped out in tests.
final backupFilePickerProvider = Provider<Future<Uint8List?> Function()>((ref) {
  return () async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Choose a backup file');
    if (files.isEmpty) return null;
    return files.first.readAsBytes();
  };
});

const lastOffDeviceKey = 'tips.last_offdevice';

/// When a backup last left the phone (shared to Drive, email, files).
class LastOffDevice extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final v = ref.watch(sharedPrefsProvider).getString(lastOffDeviceKey);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> mark(DateTime t) async {
    await ref.read(sharedPrefsProvider).setString(lastOffDeviceKey, t.toIso8601String());
    state = t;
  }
}

final lastOffDeviceProvider = NotifierProvider<LastOffDevice, DateTime?>(LastOffDevice.new);

String whenLabel(DateTime t, DateTime now) {
  final d = dateOnly(now).difference(dateOnly(t)).inDays;
  final time = DateFormat.jm().format(t);
  if (d == 0) return 'Today, $time';
  if (d == 1) return 'Yesterday, $time';
  if (d < 7) return '${DateFormat.EEEE().format(t)}, $time';
  return DateFormat('d MMM yyyy').format(t);
}

/// Writes a backup and hands it to the share sheet so it leaves the phone.
Future<void> saveBackupOffDevice(BuildContext context, WidgetRef ref) async {
  try {
    final file = await ref.read(backupServiceProvider).writeBackup(BackupKind.manual);
    ref.invalidate(backupListProvider);
    await ref.read(fileSharerProvider).share(file, mimeType: 'application/json', subject: 'Tipwell backup');
    await ref.read(lastOffDeviceProvider.notifier).mark(ref.read(clockProvider)());
    if (context.mounted) snack(context, 'Backup saved. Keep it somewhere off this phone, like Drive or email.');
  } catch (e) {
    if (context.mounted) snack(context, 'Couldn’t save the backup: $e');
  }
}

/// Inspect → preview → (extra confirm if it would empty the app) → restore.
/// Returns true when data was replaced.
Future<bool> restoreFlow(BuildContext context, WidgetRef ref, Uint8List bytes) async {
  final svc = ref.read(backupServiceProvider);
  final BackupPreview preview;
  try {
    preview = svc.inspect(bytes);
  } on BackupException catch (e) {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        key: const Key('restore-refused'),
        title: const Text('Can’t restore this file'),
        content: Text(e.message, key: const Key('restore-refused-reason')),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
    return false;
  }
  if (!context.mounted) return false;
  final current = ref.read(allShiftsProvider).value?.length ?? 0;
  String day(String? k) => k == null ? '' : DateFormat('d MMM yyyy').format(parseDay(k));
  final go = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      key: const Key('restore-preview'),
      title: const Text('Restore this backup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Made ${DateFormat('d MMM yyyy, h:mm a').format(preview.createdAt)}'),
          const SizedBox(height: 8),
          Text(
            '${preview.shifts} shifts and ${preview.jobs} jobs'
            '${preview.firstDay == null ? '' : ', ${day(preview.firstDay)} to ${day(preview.lastDay)}'}',
            key: const Key('restore-preview-counts'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            current == 0
                ? 'This will fill the app with the backup.'
                : 'This replaces the $current shifts in the app now. A safety copy of them is saved first, so you can undo this.',
          ),
        ],
      ),
      actions: [
        TextButton(key: const Key('restore-cancel'), onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(key: const Key('restore-confirm'), onPressed: () => Navigator.pop(c, true), child: const Text('Replace')),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  if (preview.shifts == 0 && current > 0) {
    final sure = await confirmDialog(
      context,
      'This backup is empty',
      'Restoring it leaves the app with no shifts. Your $current shifts go to a safety copy.',
      confirm: 'Restore anyway',
    );
    if (!sure || !context.mounted) return false;
  }
  try {
    await svc.restore(preview);
  } catch (e) {
    if (context.mounted) snack(context, 'Nothing was changed. The restore failed: $e');
    return false;
  }
  ref.invalidate(backupListProvider);
  if (context.mounted) {
    snack(
      context,
      current == 0 ? 'Restored ${preview.shifts} shifts.' : 'Restored ${preview.shifts} shifts. Your old data is in a safety copy below.',
      duration: const Duration(seconds: 6),
    );
  }
  return true;
}

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = ref.watch(backupListProvider);
    final settings = ref.watch(tipSettingsProvider);
    final now = ref.watch(clockProvider)();
    final offDevice = ref.watch(lastOffDeviceProvider);
    final backups = list.value ?? const <BackupFileInfo>[];
    final latest = backups.firstOrNull;
    final shifts = ref.watch(allShiftsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          BrandPanel(
            key: const Key('backup-status'),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const SizedBox.square(dimension: 96, child: AnimatedScene(paint: safeJarScene)),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: BrandColors.of(context).onBrand),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latest == null ? 'No backup yet' : 'Last backup',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (latest != null) Text(whenLabel(latest.createdAt, now), key: const Key('backup-last')),
                        const SizedBox(height: 6),
                        Text(
                          offDevice == null ? 'Never saved off this phone' : 'Saved off this phone: ${whenLabel(offDevice, now)}',
                          key: const Key('backup-offdevice'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: FilledButton.icon(
              key: const Key('backup-now'),
              onPressed: () => saveBackupOffDevice(context, ref),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Save a backup to Drive, email or files'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: OutlinedButton.icon(
              key: const Key('backup-restore-file'),
              onPressed: () async {
                final bytes = await ref.read(backupFilePickerProvider)();
                if (bytes == null || !context.mounted) return;
                await restoreFlow(context, ref, bytes);
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restore from a file'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'If you lose or change your phone, install the app and restore the file you saved. There is no account, so nothing else is needed.',
            ),
          ),
          SwitchListTile(
            key: const Key('auto-backup'),
            title: const Text('Daily backup on this phone'),
            subtitle: const Text('Made the first time you open the app each day. The last 14 are kept.'),
            value: settings.autoBackup,
            onChanged: (v) => ref.read(tipSettingsProvider.notifier).setAutoBackup(v),
          ),
          ListTile(
            key: const Key('export-all-csv'),
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('Export every shift as a spreadsheet'),
            subtitle: const Text('A CSV file for Excel, Sheets or your accountant'),
            enabled: shifts > 0,
            onTap: () async {
              if (!await requirePro(context, ref, featureExport)) return;
              final all = await ref.read(repositoryProvider).shifts();
              final jobs = {for (final j in await ref.read(repositoryProvider).jobs()) j.id: j};
              final exp = ref.read(exportServiceProvider);
              final f = await exp.writeCsv('tips-all-shifts.csv', shiftsCsv(all, jobs));
              await exp.share(f, subject: 'All shifts');
            },
          ),
          const SectionHeader('Backups on this phone'),
          if (list.isLoading) const Center(child: CircularProgressIndicator()),
          if (!list.isLoading && backups.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('The first one is made once you’ve logged a shift.'),
            ),
          for (final b in backups)
            ListTile(
              key: Key('backup-row-${b.file.uri.pathSegments.last}'),
              leading: Icon(switch (b.kind) {
                BackupKind.auto => Icons.event_repeat,
                BackupKind.safety => Icons.health_and_safety_outlined,
                BackupKind.upgrade => Icons.system_update_alt,
                BackupKind.manual => Icons.cloud_done_outlined,
              }),
              title: Text(whenLabel(b.createdAt, now)),
              subtitle: Text(switch (b.kind) {
                BackupKind.auto => 'Daily backup',
                BackupKind.safety => 'Safety copy made before a restore',
                BackupKind.upgrade => 'Made before an app update',
                BackupKind.manual => 'Saved by you',
              }),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final bytes = await b.file.readAsBytes();
                if (context.mounted) await restoreFlow(context, ref, bytes);
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Backups on this phone are lost with the phone. Save one off the phone every few weeks.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
