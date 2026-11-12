import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/time_format.dart';
import 'job_edit_screen.dart';
import 'jobs_tab.dart';
import 'pay_tab.dart';
import 'shift_edit_screen.dart';
import 'week_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);
    final jobs = jobsAsync.value;
    final job = ref.watch(currentJobProvider);

    if (jobs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (jobs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(ref.watch(appConfigProvider).appName)),
        body: EmptyState(
          icon: Icons.work_outline,
          title: 'Add your job',
          body: 'Your hourly rate and overtime rules go here. You can change them later.',
          action: FilledButton(
            key: const Key('add-first-job'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobEditScreen())),
            child: const Text('Add job'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: jobs.length > 1
            ? DropdownButton<int>(
                key: const Key('job-switcher'),
                value: job!.id,
                underline: const SizedBox.shrink(),
                items: [for (final j in jobs) DropdownMenuItem(value: j.id, child: Text(j.name))],
                onChanged: (id) => id == null ? null : ref.read(selectedJobIdProvider.notifier).select(id),
              )
            : Text(job!.name),
        actions: [
          IconButton(
            key: const Key('open-settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoreSettingsScreen())),
          ),
        ],
      ),
      body: Column(children: [
        const ClockBanner(),
        Expanded(
          child: IndexedStack(index: _tab, children: const [WeekTab(), PayTab(), JobsTab()]),
        ),
      ]),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              key: const Key('add-shift'),
              icon: const Icon(Icons.add),
              label: const Text('Add shift'),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ShiftEditScreen(job: ref.read(currentJobProvider)!))),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(key: Key('tab-week'), icon: Icon(Icons.view_week_outlined), label: 'Week'),
          NavigationDestination(key: Key('tab-pay'), icon: Icon(Icons.payments_outlined), label: 'Pay'),
          NavigationDestination(key: Key('tab-jobs'), icon: Icon(Icons.work_outline), label: 'Jobs'),
        ],
      ),
    );
  }
}

class ClockBanner extends ConsumerWidget {
  const ClockBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openShiftProvider).value;
    final job = ref.watch(currentJobProvider);
    final jobs = ref.watch(jobsProvider).value ?? const [];
    final theme = Theme.of(context);
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;

    if (open != null) {
      final openJob = jobs.where((j) => j.id == open.jobId).firstOrNull;
      return Material(
        color: theme.colorScheme.primaryContainer,
        child: ListTile(
          key: const Key('clock-banner-open'),
          leading: const Icon(Icons.timer),
          title: Text('On the clock since ${clock(open.start, use24h: use24)}'),
          subtitle: Text(openJob?.name ?? ''),
          onTap: openJob == null
              ? null
              : () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ShiftEditScreen(job: openJob, shift: open))),
          trailing: FilledButton(
            key: const Key('clock-out'),
            onPressed: () async {
              final now = ref.read(clockProvider)();
              final r = await ref.read(repositoryProvider).clockOut(open, now);
              if (!context.mounted) return;
              if (r.ok) {
                showSnack(context, 'Shift saved. Tap it in the week to edit.');
                await ref.read(ratingPrompterProvider).recordCompletedTask();
              } else {
                showSnack(context, r.error!);
              }
            },
            child: const Text('Clock out'),
          ),
        ),
      );
    }
    if (job == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const Key('clock-in'),
          icon: const Icon(Icons.play_arrow),
          label: Text('Clock in to ${job.name}'),
          onPressed: () async {
            final r = await ref.read(repositoryProvider).clockIn(job, ref.read(clockProvider)());
            if (!r.ok && context.mounted) showSnack(context, r.error!);
          },
        ),
      ),
    );
  }
}
