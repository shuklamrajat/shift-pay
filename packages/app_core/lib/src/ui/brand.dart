import 'package:flutter/material.dart';

/// Each app's own colours on top of the Material scheme: a two-stop hero
/// gradient, an accent for highlights and the colour of text on the
/// gradient. Light and dark each get their own set.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.gradient,
    required this.accent,
    required this.onBrand,
    required this.success,
    required this.warning,
  });

  final List<Color> gradient;
  final Color accent;
  final Color onBrand;
  final Color success;
  final Color warning;

  static BrandColors of(BuildContext context) =>
      Theme.of(context).extension<BrandColors>() ?? fallback(Theme.of(context).colorScheme, null);

  /// Works out a brand set from the scheme and an optional accent hue.
  static BrandColors fallback(ColorScheme s, Color? accent, {Color? gradientEnd}) {
    final dark = s.brightness == Brightness.dark;
    final a = accent ?? s.tertiary;
    // Light mode: deep, saturated gradient with white text. Dark mode: the
    // gradient sits a little above the surface so it glows without glare.
    final start = dark
        ? Color.lerp(s.primaryContainer, Colors.black, 0.25)!
        : Color.lerp(s.primary, Colors.black, 0.18)!;
    final g = gradientEnd;
    final end = g != null
        ? (dark ? Color.lerp(g, Colors.black, 0.45)! : g)
        : dark
        ? Color.lerp(Color.lerp(s.primaryContainer, a, 0.35)!, Colors.black, 0.35)!
        : Color.lerp(Color.lerp(s.primary, a, 0.45)!, Colors.black, 0.08)!;
    return BrandColors(
      gradient: [start, end],
      accent: dark ? Color.lerp(a, Colors.white, 0.2)! : a,
      onBrand: Colors.white,
      success: dark ? const Color(0xFF7DDC9C) : const Color(0xFF1E8E4E),
      warning: dark ? const Color(0xFFFFB86B) : const Color(0xFFC25E00),
    );
  }

  LinearGradient get linear => LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight);

  @override
  BrandColors copyWith({List<Color>? gradient, Color? accent, Color? onBrand, Color? success, Color? warning}) =>
      BrandColors(
        gradient: gradient ?? this.gradient,
        accent: accent ?? this.accent,
        onBrand: onBrand ?? this.onBrand,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      gradient: [for (var i = 0; i < gradient.length; i++) Color.lerp(gradient[i], other.gradient[i], t)!],
      accent: Color.lerp(accent, other.accent, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
