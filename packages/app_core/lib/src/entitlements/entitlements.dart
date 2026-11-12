import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings.dart';

class ProOffer {
  const ProOffer({required this.id, required this.title, required this.priceLabel, this.note});
  final String id;
  final String title;
  final String priceLabel;
  final String? note;
}

enum PurchaseOutcome { purchased, cancelled, failed, unavailable }

/// What the app knows about the paid tier. The real implementation will wrap
/// RevenueCat (purchases_flutter): `isPro` maps to the "pro" entitlement in
/// CustomerInfo, `offers` to the current Offering's packages, `purchase` to
/// Purchases.purchasePackage and `restore` to Purchases.restorePurchases.
/// It is not wired yet because it needs RevenueCat and store accounts.
abstract class EntitlementService {
  bool get isPro;
  Stream<bool> watchIsPro();
  Future<List<ProOffer>> offers();
  Future<PurchaseOutcome> purchase(ProOffer offer);
  Future<bool> restore();
}

/// Stand-in until RevenueCat is connected. Purchases are unavailable in
/// release builds; in debug builds a purchase flips a local flag so the paid
/// paths can be exercised end to end.
class LocalEntitlementService implements EntitlementService {
  LocalEntitlementService(this._prefs, {required this.allowDebugPurchase});

  static const _key = 'core.debugPro';
  final SharedPreferences _prefs;
  final bool allowDebugPurchase;
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isPro => _prefs.getBool(_key) ?? false;

  @override
  Stream<bool> watchIsPro() async* {
    yield isPro;
    yield* _controller.stream;
  }

  @override
  Future<List<ProOffer>> offers() async => const [
    ProOffer(id: 'pro_annual', title: 'Pro yearly', priceLabel: '\$19.99 / year', note: '7-day free trial'),
    ProOffer(id: 'pro_lifetime', title: 'Pro lifetime', priceLabel: '\$39.99 once'),
  ];

  @override
  Future<PurchaseOutcome> purchase(ProOffer offer) async {
    if (!allowDebugPurchase) return PurchaseOutcome.unavailable;
    await setPro(true);
    return PurchaseOutcome.purchased;
  }

  @override
  Future<bool> restore() async => isPro;

  Future<void> setPro(bool value) async {
    await _prefs.setBool(_key, value);
    _controller.add(value);
  }
}

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  var debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  return LocalEntitlementService(ref.watch(sharedPrefsProvider), allowDebugPurchase: debug);
});

final isProProvider = StreamProvider<bool>((ref) => ref.watch(entitlementServiceProvider).watchIsPro());

/// Synchronous read for gating decisions; falls back to the service value
/// while the stream warms up.
bool isProNow(WidgetRef ref) => ref.read(isProProvider).value ?? ref.read(entitlementServiceProvider).isPro;
