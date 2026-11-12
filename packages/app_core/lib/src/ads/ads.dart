import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entitlements/entitlements.dart';
import '../tour/tour.dart';
import 'google_ads_platform.dart';

/// Google's published demo ad units. They always fill with a labelled test
/// ad and never earn money, so they are safe in development.
abstract final class TestAdIds {
  static const androidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const iosBanner = 'ca-app-pub-3940256099942544/2435281174';
}

/// The banner ad unit for this build. Real ids come in at build time with
/// `--dart-define=ADMOB_BANNER_ID=...` (the Android workflow reads it from the
/// repo variable of that name). Debug builds always use the test unit, so a
/// real unit is never hit during development.
String bannerAdUnitId() {
  const configured = String.fromEnvironment('ADMOB_BANNER_ID');
  final test = !kIsWeb && Platform.isIOS ? TestAdIds.iosBanner : TestAdIds.androidBanner;
  if (!kReleaseMode || configured.isEmpty) return test;
  return configured;
}

/// What the consent step found out.
class ConsentResult {
  const ConsentResult({required this.canRequestAds, required this.privacyOptionsRequired});
  final bool canRequestAds;
  final bool privacyOptionsRequired;
}

/// A banner that has loaded and can be shown.
class LoadedBanner {
  LoadedBanner({required this.widget, required this.height, required this.dispose});
  final Widget widget;
  final double height;
  final VoidCallback dispose;
}

/// Everything the app needs from an ad network. The Google implementation
/// wraps google_mobile_ads and its User Messaging Platform; tests use a fake.
abstract class AdsPlatform {
  /// Whether this device can show ads at all (phones yes, desktop no).
  bool get supported;

  /// Refreshes consent info and shows Google's consent form when the SDK says
  /// it is required (EEA/UK). Called on every launch, as Google asks. Must not
  /// throw: on failure it reports what the last session's consent allows.
  Future<ConsentResult> gatherConsent();

  /// Opens Google's privacy options form so the person can change their answer.
  Future<ConsentResult> showPrivacyOptions();

  /// Starts the ad SDK. Only called once consent allows ad requests.
  Future<void> initialize();

  /// Loads one banner [width] logical pixels wide. Null when no ad came back.
  Future<LoadedBanner?> loadBanner({required String adUnitId, required int width});
}

/// Used where there is no ad SDK (desktop builds, the main end-to-end runs).
class NoAdsPlatform implements AdsPlatform {
  const NoAdsPlatform();
  @override
  bool get supported => false;
  @override
  Future<ConsentResult> gatherConsent() async =>
      const ConsentResult(canRequestAds: false, privacyOptionsRequired: false);
  @override
  Future<ConsentResult> showPrivacyOptions() => gatherConsent();
  @override
  Future<void> initialize() async {}
  @override
  Future<LoadedBanner?> loadBanner({required String adUnitId, required int width}) async => null;
}

final adsPlatformProvider = Provider<AdsPlatform>((ref) {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) return GoogleAdsPlatform();
  return const NoAdsPlatform();
});

enum AdsPhase { notStarted, gatheringConsent, ready, unavailable }

@immutable
class AdsState {
  const AdsState({this.phase = AdsPhase.notStarted, this.canRequestAds = false, this.privacyOptionsRequired = false});
  final AdsPhase phase;
  final bool canRequestAds;
  final bool privacyOptionsRequired;

  /// The SDK is started and consent allows requests.
  bool get adsAllowed => phase == AdsPhase.ready && canRequestAds;

  AdsState copyWith({AdsPhase? phase, bool? canRequestAds, bool? privacyOptionsRequired}) => AdsState(
    phase: phase ?? this.phase,
    canRequestAds: canRequestAds ?? this.canRequestAds,
    privacyOptionsRequired: privacyOptionsRequired ?? this.privacyOptionsRequired,
  );
}

/// Runs consent first, then starts the SDK only if consent allows it.
class AdsController extends Notifier<AdsState> {
  bool _sdkStarted = false;

  @override
  AdsState build() => const AdsState();

  AdsPlatform get _platform => ref.read(adsPlatformProvider);

  /// Safe to call more than once; only the first call does anything.
  Future<void> start() async {
    if (state.phase != AdsPhase.notStarted) return;
    if (!_platform.supported) {
      state = state.copyWith(phase: AdsPhase.unavailable);
      return;
    }
    state = state.copyWith(phase: AdsPhase.gatheringConsent);
    final result = await _platform.gatherConsent();
    await _apply(result);
  }

  /// Lets the person change their consent answer.
  Future<void> openPrivacyOptions() async {
    final result = await _platform.showPrivacyOptions();
    await _apply(result);
  }

  Future<void> _apply(ConsentResult result) async {
    if (result.canRequestAds && !_sdkStarted) {
      _sdkStarted = true;
      await _platform.initialize();
    }
    state = state.copyWith(
      phase: AdsPhase.ready,
      canRequestAds: result.canRequestAds,
      privacyOptionsRequired: result.privacyOptionsRequired,
    );
  }
}

final adsControllerProvider = NotifierProvider<AdsController, AdsState>(AdsController.new);

/// True when the person paid to remove ads. While Pro is given away for free
/// (billing not live) nobody has paid, so ads still show; once billing is
/// live, owning Pro removes them.
final adsRemovedProvider = Provider<bool>((ref) {
  final service = ref.watch(entitlementServiceProvider);
  if (service.proIsFreeForNow) return false;
  return ref.watch(isProProvider).value ?? service.isPro;
});

/// Whether the banner should be on screen now.
final showAdsProvider = Provider<bool>((ref) {
  if (ref.watch(adsRemovedProvider)) return false;
  if (ref.watch(tourHoldsAdsProvider)) return false;
  return ref.watch(adsControllerProvider).adsAllowed;
});
