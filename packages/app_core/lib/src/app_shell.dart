import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ads/ads.dart';
import 'onboarding/onboarding.dart';
import 'settings/settings.dart';
import 'theme/app_theme.dart';
import 'tour/tour.dart';

/// Root widget every app uses: theme from settings, onboarding on first run,
/// then the app's own home screen with its guided tour on top. Starts the ads consent check on launch,
/// as Google asks (consent info is refreshed on every app start).
class CoreApp extends ConsumerStatefulWidget {
  const CoreApp({super.key, required this.home});
  final Widget home;

  @override
  ConsumerState<CoreApp> createState() => _CoreAppState();
}

class _CoreAppState extends ConsumerState<CoreApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adsControllerProvider.notifier).start());
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.home;
    final config = ref.watch(appConfigProvider);
    final settings = ref.watch(coreSettingsProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) => TourLayer(navigatorKey: _navigatorKey, child: child!),
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        config.seedColor,
        Brightness.light,
        accent: config.accentColor,
        gradientEnd: config.gradientEndColor,
      ),
      darkTheme: buildAppTheme(
        config.seedColor,
        Brightness.dark,
        accent: config.accentColor,
        gradientEnd: config.gradientEndColor,
      ),
      themeMode: settings.themeMode,
      home: settings.onboardingDone ? home : const OnboardingScreen(),
    );
  }
}
