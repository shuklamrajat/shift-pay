import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup/backup_service.dart';
import 'data/repository.dart';
import 'ui/home_screen.dart';
import 'ui/repair_screen.dart';
import 'ui/scenes.dart';

const featureExport = 'export';
const featureMultipleJobs = 'multiple_jobs';

/// Kept in step with pubspec.yaml's version name.
const tipsAppVersion = '0.1.0';

const tipsConfig = AppConfig(
  appName: 'Tipwell',
  version: tipsAppVersion,
  tagline: 'Every tip, every shift, never lost',
  privacyPolicyUrl: 'https://shuklamrajat.github.io/widdle-privacy/tipwell/',
  seedColor: Color(0xFF2E7D32),
  accentColor: gold,
  gradientEndColor: Color(0xFF00695C),
  paywallScene: proScene,
  logo: tipLogo,
  privacyNote:
      'Everything you enter stays on this device. There is no account and no server, so there is nothing to log in to or get locked out of.',
  onboarding: [
    OnboardingPage(
      icon: Icons.savings_outlined,
      scene: fillJarScene,
      title: 'Log a shift in seconds',
      body: 'Hours, cash and card tips. Only the hours are required, so cash-only or no-tip nights are fine.',
    ),
    OnboardingPage(
      icon: Icons.call_split,
      scene: tipOutScene,
      title: 'Tip-out worked out for you',
      body: 'Set your rule once, like 3% of sales to the bar. Change it for one night when you need to.',
    ),
    OnboardingPage(
      icon: Icons.shield_outlined,
      scene: safeJarScene,
      title: 'Never lose a night',
      body: 'No account to get locked out of. A backup is made every day, and you can save one anywhere.',
    ),
  ],
  tour: [
    TourStep(
      target: 'add-shift',
      icon: Icons.add_card,
      title: 'Log a shift',
      body: 'Tap here at the end of every shift. The tip-out and your real hourly rate work themselves out.',
    ),
    TourStep(
      target: 'tab-stats',
      icon: Icons.insights_outlined,
      title: 'Your numbers',
      body: 'Week, month and year on one page, and which night of the week pays best.',
    ),
    TourStep(
      target: 'tab-jobs',
      icon: Icons.work_outline,
      title: 'Your jobs',
      body: 'Each job has its own wage and tip-out rule. Archive an old job without losing its shifts.',
    ),
    TourStep(
      target: 'tab-settings',
      icon: Icons.shield_outlined,
      title: 'Backups live here',
      body: 'See when the last backup was made, save one to Drive or email, or restore one.',
    ),
  ],
  proFeatures: [
    ProFeature(id: featureExport, title: 'Export', description: 'CSV and PDF reports for any week, month or year.'),
    ProFeature(id: featureMultipleJobs, title: 'More than one job', description: 'Separate wage and tip-out for each job.'),
  ],
);

class TipApp extends StatelessWidget {
  const TipApp({super.key});

  @override
  Widget build(BuildContext context) => const CoreApp(home: LaunchGate(child: HomeScreen()));
}

/// Checks the database is healthy before showing anything, then makes the
/// day's automatic backup in the background.
class LaunchGate extends ConsumerStatefulWidget {
  const LaunchGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<LaunchGate> {
  List<String>? _problems;
  bool _skipCheck = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    List<String> problems;
    try {
      problems = await ref.read(tipsDbProvider).healthProblems();
    } catch (e) {
      problems = ['The database could not be opened ($e)'];
    }
    if (!mounted) return;
    setState(() => _problems = problems);
    if (problems.isEmpty && ref.read(tipSettingsProvider).autoBackup) {
      try {
        await ref.read(backupServiceProvider).maybeAutoBackup();
        ref.invalidate(backupListProvider);
      } catch (_) {
        // Shown on the Backup screen as "last backup" not moving; never block launch.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _problems;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (p.isNotEmpty && !_skipCheck) {
      return RepairScreen(problems: p, onRepaired: _check, onContinue: () => setState(() => _skipCheck = true));
    }
    return widget.child;
  }
}
