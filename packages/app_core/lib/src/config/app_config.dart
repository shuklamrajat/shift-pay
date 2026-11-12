import 'package:flutter/material.dart';

/// One onboarding page.
class OnboardingPage {
  const OnboardingPage({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

/// A feature that needs the paid tier. [id] is what code checks against.
class ProFeature {
  const ProFeature({required this.id, required this.title, required this.description});
  final String id;
  final String title;
  final String description;
}

/// Everything that makes one app different from another at the shell level.
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.tagline,
    required this.seedColor,
    required this.onboarding,
    required this.proFeatures,
    this.privacyNote =
        'Everything you enter stays on this device. Nothing is uploaded, '
        'and there is no account to create.',
  });

  final String appName;
  final String tagline;
  final Color seedColor;
  final List<OnboardingPage> onboarding;
  final List<ProFeature> proFeatures;
  final String privacyNote;

  ProFeature feature(String id) => proFeatures.firstWhere((f) => f.id == id);
}
