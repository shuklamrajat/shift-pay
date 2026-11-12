import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads.dart';

/// AdMob through google_mobile_ads, with Google's User Messaging Platform for
/// consent, following https://developers.google.com/admob/flutter/privacy.
class GoogleAdsPlatform implements AdsPlatform {
  @override
  bool get supported => true;

  @override
  Future<ConsentResult> gatherConsent() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(),
      // On failure the SDK falls back to the consent from the last session.
      (FormError e) {
        debugPrint('Consent update failed: ${e.errorCode} ${e.message}');
        updated.complete();
      },
    );
    await updated.future;
    final shown = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
      if (e != null) debugPrint('Consent form failed: ${e.errorCode} ${e.message}');
      shown.complete();
    });
    await shown.future;
    return _read();
  }

  @override
  Future<ConsentResult> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? e) {
      if (e != null) debugPrint('Privacy options failed: ${e.errorCode} ${e.message}');
      done.complete();
    });
    await done.future;
    return _read();
  }

  Future<ConsentResult> _read() async {
    final can = await ConsentInformation.instance.canRequestAds();
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return ConsentResult(
      canRequestAds: can,
      privacyOptionsRequired: status == PrivacyOptionsRequirementStatus.required,
    );
  }

  @override
  Future<void> initialize() async {
    // The apps are rated for everyone, so keep ads to general audiences with
    // parental guidance at most.
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
    );
    await MobileAds.instance.initialize();
  }

  @override
  Future<LoadedBanner?> loadBanner({required String adUnitId, required int width}) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null) return null;
    final result = Completer<LoadedBanner?>();
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => result.complete(
          LoadedBanner(
            widget: AdWidget(ad: ad),
            height: size.height.toDouble(),
            dispose: ad.dispose,
          ),
        ),
        onAdFailedToLoad: (failed, error) {
          debugPrint('Banner failed to load: ${error.code} ${error.message}');
          failed.dispose();
          result.complete(null);
        },
      ),
    );
    await ad.load();
    return result.future;
  }
}
