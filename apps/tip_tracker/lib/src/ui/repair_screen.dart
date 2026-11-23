import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_service.dart';
import '../data/repository.dart';
import '../domain/periods.dart';
import '../export/tip_export.dart';
import 'backup_screen.dart';
import 'fields.dart';

/// Saves every shift that can still be read as a spreadsheet and hands it to
/// the share sheet. Reads only; nothing on the phone changes. Never behind
/// Pro: getting your own data out is not a feature.
Future<void> exportReadable(BuildContext context, WidgetRef ref) async {
  try {
    final r = await ref.read(repositoryProvider).readable();
    if (r.shifts.isEmpty) {
      if (context.mounted) snack(context, 'No shifts could be read. Try restoring a backup instead.');
      return;
    }
    final exp = ref.read(exportServiceProvider);
    final now = ref.read(clockProvider)();
    final f = await exp.writeCsv('tips-readable-${dayKey(now)}.csv', shiftsCsv(r.shifts, {for (final j in r.jobs) j.id: j}));
    await exp.share(f, subject: 'Tipwell shifts');
    if (context.mounted) {
      snack(
        context,
        'Exported ${r.shifts.length} shift${r.shifts.length == 1 ? '' : 's'}'
        '${r.skipped == 0 ? '' : ' (${r.skipped} couldn’t be read)'}. Nothing on the phone was changed.',
      );
    }
  } catch (e) {
    if (context.mounted) snack(context, 'Couldn’t export: $e');
  }
}

/// Shown instead of the app when the launch check finds the database
/// damaged. Offers the newest backup first; nothing is changed without a tap.
class RepairScreen extends ConsumerWidget {
  const RepairScreen({super.key, required this.problems, required this.onRepaired, required this.onContinue});
  final List<String> problems;
  final VoidCallback onRepaired;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(backupListProvider);
    final now = ref.watch(clockProvider)();
    final backups = list.value ?? const <BackupFileInfo>[];
    return Scaffold(
      key: const Key('repair-screen'),
      appBar: AppBar(title: const Text('Your data needs a check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Something is wrong with the data on this phone. This can happen after the phone runs out of space or shuts down mid-save.',
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text('What was found'),
            children: [for (final p in problems.take(10)) ListTile(dense: true, title: Text(p))],
          ),
          const SizedBox(height: 8),
          if (backups.isNotEmpty) ...[
            FilledButton.icon(
              key: const Key('repair-restore-latest'),
              icon: const Icon(Icons.restore),
              label: Text('Restore the backup from ${whenLabel(backups.first.createdAt, now)}'),
              onPressed: () async {
                final bytes = await backups.first.file.readAsBytes();
                if (!context.mounted) return;
                if (await restoreFlow(context, ref, bytes)) onRepaired();
              },
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            key: const Key('repair-restore-file'),
            icon: const Icon(Icons.folder_open),
            label: const Text('Restore from a file'),
            onPressed: () async {
              final bytes = await ref.read(backupFilePickerProvider)();
              if (bytes == null || !context.mounted) return;
              if (await restoreFlow(context, ref, bytes)) onRepaired();
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('repair-export'),
            icon: const Icon(Icons.table_view_outlined),
            label: const Text('Export what’s readable'),
            onPressed: () => exportReadable(context, ref),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('repair-continue'),
            onPressed: onContinue,
            child: const Text('Open the app anyway'),
          ),
          if (backups.length > 1) ...[
            const SectionHeader('Older backups', padding: EdgeInsets.fromLTRB(4, 16, 4, 6)),
            for (final b in backups.skip(1))
              ListTile(
                title: Text(whenLabel(b.createdAt, now)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final bytes = await b.file.readAsBytes();
                  if (!context.mounted) return;
                  if (await restoreFlow(context, ref, bytes)) onRepaired();
                },
              ),
          ],
        ],
      ),
    );
  }
}
