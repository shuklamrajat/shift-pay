import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

import 'ui/home_screen.dart';
import 'ui/logo.dart';
import 'ui/scenes.dart';

const featureMultipleJobs = 'multiple_jobs';
const featureExport = 'export';

const hoursConfig = AppConfig(
  appName: 'Wagebird',
  tagline: 'Hours and overtime, worked out for you',
  privacyPolicyUrl: 'https://shuklamrajat.github.io/widdle-privacy/wagebird/',
  seedColor: Color(0xFF00897B),
  accentColor: Color(0xFFFFB300),
  gradientEndColor: Color(0xFF01579B),
  paywallScene: timesheetProScene,
  logo: wagebirdLogo,
  onboarding: [
    OnboardingPage(
      icon: Icons.schedule,
      scene: clockScene,
      title: 'Log every shift',
      body: 'Clock in and out, or type your hours in after. Night shifts and split shifts are fine.',
    ),
    OnboardingPage(
      icon: Icons.trending_up,
      scene: overtimeScene,
      title: 'Overtime done right',
      body: 'Set your daily and weekly limits once. Wagebird works out regular, overtime and double time.',
    ),
    OnboardingPage(
      icon: Icons.lock_outline,
      scene: privacyScene,
      title: 'Private by default',
      body: 'Your hours stay on your phone. No account, no cloud.',
    ),
  ],
  tour: [
    TourStep(
      target: 'add-shift',
      icon: Icons.add_alarm,
      title: 'Log a shift',
      body: 'Tap here after each shift. Enter when you started, finished and took a break, and the pay works itself out.',
    ),
    TourStep(
      target: 'tab-week',
      icon: Icons.view_week_outlined,
      title: 'Your week',
      body: 'Hours for this week so far, with overtime counted as it builds up.',
    ),
    TourStep(
      target: 'tab-pay',
      icon: Icons.payments_outlined,
      title: 'Pay, before payday',
      body: 'What you have earned this pay period, and timesheets you can export as a spreadsheet or PDF.',
    ),
    TourStep(
      target: 'tab-jobs',
      icon: Icons.work_outline,
      title: 'More than one job?',
      body: 'Add each job with its own rate and overtime rules, and switch between them at the top.',
    ),
    TourStep(
      target: 'open-settings',
      icon: Icons.tune,
      title: 'Settings and Pro',
      body: 'Currency, theme and Pro features live here. You can take this tour again from Settings any time.',
    ),
  ],
  proFeatures: [
    ProFeature(
      id: featureExport,
      title: 'Timesheet export',
      description: 'CSV for spreadsheets and PDF for your boss or payroll.',
    ),
    ProFeature(
      id: featureMultipleJobs,
      title: 'More than one job',
      description: 'Separate rates and overtime rules for each job.',
    ),
  ],
);

class HoursApp extends StatelessWidget {
  const HoursApp({super.key});

  @override
  Widget build(BuildContext context) => const CoreApp(home: HomeScreen());
}
