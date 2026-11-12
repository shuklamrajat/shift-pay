import 'package:flutter/material.dart';

import '../ui/scene.dart';

/// One onboarding page.
class OnboardingPage {
  const OnboardingPage({required this.icon, required this.title, required this.body, this.scene});
  final IconData icon;
  final String title;
  final String body;

  /// Animated illustration for the page. Falls back to [icon] when null.
  final ScenePaint? scene;
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
    required this.privacyPolicyUrl,
    this.accentColor,
    this.gradientEndColor,
    this.paywallScene,
    this.privacyNote =
        'Everything you enter stays on this device. Nothing is uploaded, '
        'and there is no account to create.',
  });

  final String appName;
  final String tagline;
  final Color seedColor;
  final List<OnboardingPage> onboarding;
  final List<ProFeature> proFeatures;

  /// Second brand colour, mixed into hero gradients and highlights.
  final Color? accentColor;

  /// Where hero gradients end (they start at [seedColor]). Null mixes in
  /// the accent.
  final Color? gradientEndColor;

  /// Illustration at the top of the paywall. Null uses the shared one.
  final ScenePaint? paywallScene;
  final String privacyNote;

  /// The public privacy policy. Play requires a link to it inside the app.
  final String privacyPolicyUrl;

  ProFeature feature(String id) => proFeatures.firstWhere((f) => f.id == id);
}
