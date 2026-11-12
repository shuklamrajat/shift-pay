import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding/onboarding.dart';
import 'settings/settings.dart';
import 'theme/app_theme.dart';

/// Root widget every app uses: theme from settings, onboarding on first run,
/// then the app's own home screen.
class CoreApp extends ConsumerWidget {
  const CoreApp({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final settings = ref.watch(coreSettingsProvider);
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(config.seedColor, Brightness.light),
      darkTheme: buildAppTheme(config.seedColor, Brightness.dark),
      themeMode: settings.themeMode,
      home: settings.onboardingDone ? home : const OnboardingScreen(),
    );
  }
}
