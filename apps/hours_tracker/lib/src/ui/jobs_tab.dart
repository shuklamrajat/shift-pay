import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/repository.dart';
import 'job_edit_screen.dart';

class JobsTab extends ConsumerWidget {
  const JobsTab({super.key});

  String _rules(Job j) {
    final parts = <String>[];
    if (j.dailyLimitMin != null) parts.add('OT after ${j.dailyLimitMin! / 60}h/day');
    if (j.dailyDoubleMin != null) parts.add('2x after ${j.dailyDoubleMin! / 60}h/day');
    if (j.weeklyLimitMin != null) parts.add('OT after ${j.weeklyLimitMin! / 60}h/week');
    return parts.isEmpty ? 'No overtime rules' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider).value ?? const [];
    final currency = ref.watch(coreSettingsProvider).currency;
    return ListView(
      children: [
        for (final (i, j) in jobs.indexed)
          Appear(
            index: i,
            child: Card(
              child: ListTile(
                key: Key('job-${j.id}'),
                leading: _Initials(j.name),
                title: Text(j.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${Money.format(j.rateCents, currency: currency)}/h · ${_rules(j)}'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobEditScreen(job: j))),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            key: const Key('add-job'),
            icon: const Icon(Icons.add),
            label: const Text('Add another job'),
            onPressed: () async {
              if (jobs.isNotEmpty && !await requirePro(context, ref, featureMultipleJobs)) return;
              if (!context.mounted) return;
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const JobEditScreen()));
            },
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final letters = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: brand.linear),
      child: Text(
        letters.toUpperCase(),
        style: TextStyle(color: brand.onBrand, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}
