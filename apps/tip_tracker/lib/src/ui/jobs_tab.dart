import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart' show featureMultipleJobs;
import '../data/repository.dart';
import '../domain/tip_math.dart';
import 'fields.dart';
import 'job_edit_screen.dart';

class JobsTab extends ConsumerWidget {
  const JobsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(allJobsProvider).value ?? const <Job>[];
    final shifts = ref.watch(allShiftsProvider).value ?? const <Shift>[];
    final money = ref.watch(moneyFmtProvider);
    final active = jobs.where((j) => !j.archived).toList();
    final archived = jobs.where((j) => j.archived).toList();

    Widget tile(Job j, int i) {
      final mine = shifts.where((s) => s.jobId == j.id);
      final t = Totals(mine.map(mathOf));
      final rule = ruleOfJob(j);
      return Appear(
        index: i,
        child: Card(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: ListTile(
            key: Key('job-${j.id}'),
            leading: CircleAvatar(
              backgroundColor: jobColor(j.colorIndex).withValues(alpha: j.archived ? 0.4 : 1),
              foregroundColor: Colors.white,
              child: Icon(roleIcon(j.role)),
            ),
            title: Text(j.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                j.rateCents == 0 ? 'No hourly wage' : '${money(j.rateCents)}/h',
                if (rule.kind != TipOutKind.none) 'tip-out ${rule.describe(money)}',
              ].join(' · '),
            ),
            trailing: t.count == 0
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${money(t.perHourCents)}/h', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${t.count} shifts', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobEditScreen(job: j))),
          ),
        ),
      );
    }

    return ListView(
      key: const Key('jobs-list'),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        for (final (i, j) in active.indexed) tile(j, i),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            key: const Key('add-job'),
            icon: const Icon(Icons.add),
            label: Text(active.isEmpty ? 'Add a job' : 'Add another job'),
            onPressed: () async {
              if (active.isNotEmpty && !await requirePro(context, ref, featureMultipleJobs)) return;
              if (!context.mounted) return;
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const JobEditScreen()));
            },
          ),
        ),
        if (archived.isNotEmpty)
          ExpansionTile(
            key: const Key('archived-jobs'),
            title: Text('Archived (${archived.length})'),
            subtitle: const Text('Their shifts still count in your stats'),
            children: [for (final (i, j) in archived.indexed) tile(j, i)],
          ),
      ],
    );
  }
}
