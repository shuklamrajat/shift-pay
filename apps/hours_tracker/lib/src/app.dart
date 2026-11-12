import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

import 'ui/home_screen.dart';
import 'ui/scenes.dart';

const featureMultipleJobs = 'multiple_jobs';
const featureExport = 'export';

const hoursConfig = AppConfig(
  appName: 'Wagebird',
  tagline: 'Hours and overtime, worked out for you',
  seedColor: Color(0xFF00897B),
  accentColor: Color(0xFFFFB300),
  gradientEndColor: Color(0xFF01579B),
  paywallScene: timesheetProScene,
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
