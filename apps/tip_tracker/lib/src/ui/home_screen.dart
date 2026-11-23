import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import 'job_edit_screen.dart';
import 'jobs_tab.dart';
import 'settings_tab.dart';
import 'shifts_tab.dart';
import 'stats_tab.dart';

/// Four tabs. Back on any tab but Shifts goes to Shifts; Back on Shifts
/// leaves the app. With no job yet, the first-run job setup is shown.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  static const _titles = ['Shifts', 'Stats', 'Jobs', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(allJobsProvider).value;
    if (jobs == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (jobs.isEmpty) return const JobEditScreen(firstRun: true);

    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        appBar: _tab == 3 ? null : AppBar(title: Text(_tab == 0 ? ref.watch(appConfigProvider).appName : _titles[_tab])),
        body: IndexedStack(index: _tab, children: const [ShiftsTab(), StatsTab(), JobsTab(), SettingsTab()]),
        floatingActionButton: _tab == 0
            ? FloatingActionButton.extended(
                key: const Key('add-shift'),
                icon: const Icon(Icons.add),
                label: const Text('Log shift'),
                onPressed: () => openShiftEditor(context, ref),
              )
            : null,
        bottomNavigationBar: AdDock(
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(key: Key('tab-shifts'), icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Shifts'),
              NavigationDestination(key: Key('tab-stats'), icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Stats'),
              NavigationDestination(key: Key('tab-jobs'), icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
              NavigationDestination(key: Key('tab-settings'), icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
