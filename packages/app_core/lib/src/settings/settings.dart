import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Must be overridden in main() / tests with a loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// Must be overridden with the app's config.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

/// Clock seam so tests can pin "now" (reminders, rating prompt spacing).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

@immutable
class CoreSettings {
  const CoreSettings({
    required this.themeMode,
    required this.onboardingDone,
    required this.currency,
    required this.firstOpenedAt,
  });

  final ThemeMode themeMode;
  final bool onboardingDone;
  final String currency;
  final DateTime firstOpenedAt;

  CoreSettings copyWith({ThemeMode? themeMode, bool? onboardingDone, String? currency}) =>
      CoreSettings(
        themeMode: themeMode ?? this.themeMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        currency: currency ?? this.currency,
        firstOpenedAt: firstOpenedAt,
      );
}

class CoreSettingsNotifier extends Notifier<CoreSettings> {
  static const _kTheme = 'core.themeMode';
  static const _kOnboarding = 'core.onboardingDone';
  static const _kCurrency = 'core.currency';
  static const _kFirstOpen = 'core.firstOpenedAt';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  CoreSettings build() {
    final p = ref.watch(sharedPrefsProvider);
    var first = p.getInt(_kFirstOpen);
    if (first == null) {
      first = ref.read(clockProvider)().millisecondsSinceEpoch;
      p.setInt(_kFirstOpen, first);
    }
    return CoreSettings(
      themeMode: ThemeMode.values[(p.getInt(_kTheme) ?? 0).clamp(0, 2)],
      onboardingDone: p.getBool(_kOnboarding) ?? false,
      currency: p.getString(_kCurrency) ?? 'USD',
      firstOpenedAt: DateTime.fromMillisecondsSinceEpoch(first),
    );
  }

  Future<void> setThemeMode(ThemeMode m) async {
    await _p.setInt(_kTheme, m.index);
    state = state.copyWith(themeMode: m);
  }

  Future<void> completeOnboarding() async {
    await _p.setBool(_kOnboarding, true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> setCurrency(String code) async {
    await _p.setString(_kCurrency, code);
    state = state.copyWith(currency: code);
  }
}

final coreSettingsProvider =
    NotifierProvider<CoreSettingsNotifier, CoreSettings>(CoreSettingsNotifier.new);

/// Small typed key/value helper apps use for their own preferences
/// (units, workday start hour, etc.).
class PrefValue<T> {
  PrefValue(this.key, this.defaultValue);
  final String key;
  final T defaultValue;

  T read(SharedPreferences p) {
    final v = p.get(key);
    return v is T ? v : defaultValue;
  }

  Future<void> write(SharedPreferences p, T value) async {
    switch (value) {
      case final int v:
        await p.setInt(key, v);
      case final bool v:
        await p.setBool(key, v);
      case final String v:
        await p.setString(key, v);
      case final double v:
        await p.setDouble(key, v);
      default:
        throw ArgumentError('Unsupported pref type for $key');
    }
  }
}

const supportedCurrencies = ['USD', 'CAD', 'GBP', 'EUR', 'AUD', 'NZD', 'INR'];
