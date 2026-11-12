import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';
import 'entitlements.dart';

/// Returns true when the person has Pro. Otherwise opens the paywall
/// (highlighting [featureId]) and returns whether they upgraded there.
Future<bool> requirePro(BuildContext context, WidgetRef ref, String featureId) async {
  if (isProNow(ref)) return true;
  final upgraded = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => PaywallScreen(highlightFeatureId: featureId)),
  );
  return upgraded ?? false;
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.highlightFeatureId});
  final String? highlightFeatureId;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<ProOffer>? _offers;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    ref.read(entitlementServiceProvider).offers().then((o) {
      if (mounted) setState(() => _offers = o);
    });
  }

  Future<void> _buy(ProOffer offer) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await ref.read(entitlementServiceProvider).purchase(offer);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        Navigator.of(context).pop(true);
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.unavailable:
        setState(() => _message = 'Purchases are not available yet in this build.');
      case PurchaseOutcome.failed:
        setState(() => _message = 'The purchase did not go through. You were not charged.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final ok = await ref.read(entitlementServiceProvider).restore();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = ok ? null : 'No previous purchase found for this store account.';
    });
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('paywall'),
      appBar: AppBar(title: Text('${config.appName} Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Unlock everything', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          for (final f in config.proFeatures)
            ListTile(
              leading: Icon(
                f.id == widget.highlightFeatureId ? Icons.star : Icons.check_circle_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(f.title,
                  style: f.id == widget.highlightFeatureId
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null),
              subtitle: Text(f.description),
            ),
          const SizedBox(height: 16),
          if (_offers == null) const Center(child: CircularProgressIndicator()),
          for (final o in _offers ?? const <ProOffer>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                key: Key('offer-${o.id}'),
                onPressed: _busy ? null : () => _buy(o),
                child: Text('${o.title}  ·  ${o.priceLabel}${o.note == null ? '' : '  ·  ${o.note}'}'),
              ),
            ),
          TextButton(onPressed: _busy ? null : _restore, child: const Text('Restore purchase')),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 8),
          Text(config.privacyNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
