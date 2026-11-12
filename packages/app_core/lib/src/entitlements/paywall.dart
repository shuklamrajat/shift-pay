import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';
import '../ui/brand.dart';
import '../ui/celebrate.dart';
import '../ui/core_scenes.dart';
import '../ui/motion.dart';
import '../ui/scene.dart';
import 'entitlements.dart';

/// Returns true when the person has Pro. Otherwise opens the paywall
/// (highlighting [featureId]) and returns whether they upgraded there.
Future<bool> requirePro(BuildContext context, WidgetRef ref, String featureId) async {
  if (isProNow(ref)) return true;
  final upgraded = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => PaywallScreen(highlightFeatureId: featureId)));
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
        celebrate(context);
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
    if (ok) {
      celebrate(context);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);
    final brand = BrandColors.of(context);
    final offers = _offers ?? const <ProOffer>[];
    // The one-time purchase is the hero offer; the rest are quieter.
    final best = offers.where((o) => o.id.contains('lifetime')).firstOrNull ?? offers.firstOrNull;
    return Scaffold(
      key: const Key('paywall'),
      appBar: AppBar(title: Text('${config.appName} Pro')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [brand.accent.withValues(alpha: 0.16), brand.gradient.first.withValues(alpha: 0.04)],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                SizedBox(
                  height: 190,
                  child: AnimatedScene(paint: config.paywallScene ?? proGemScene, aspectRatio: 1.6),
                ),
                Text('Unlock everything', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'One small purchase, every feature, no ads.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, f) in config.proFeatures.indexed)
            Appear(
              index: i,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: f.id == widget.highlightFeatureId ? brand.linear : null,
                    color: f.id == widget.highlightFeatureId ? null : theme.colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    f.id == widget.highlightFeatureId ? Icons.star_rounded : Icons.check_rounded,
                    color: f.id == widget.highlightFeatureId ? brand.onBrand : theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  f.title,
                  style: f.id == widget.highlightFeatureId
                      ? const TextStyle(fontWeight: FontWeight.w800)
                      : const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(f.description),
              ),
            ),
          const SizedBox(height: 16),
          if (_offers == null) const Center(child: CircularProgressIndicator()),
          for (final o in offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: o == best
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: brand.linear,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: brand.gradient.last.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        key: Key('offer-${o.id}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: brand.onBrand,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: _busy ? null : () => _buy(o),
                        child: Text(_label(o)),
                      ),
                    )
                  : FilledButton.tonal(
                      key: Key('offer-${o.id}'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _busy ? null : () => _buy(o),
                      child: Text(_label(o)),
                    ),
            ),
          TextButton(onPressed: _busy ? null : _restore, child: const Text('Restore purchase')),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(config.privacyNote, style: theme.textTheme.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }

  String _label(ProOffer o) => '${o.title}  ·  ${o.priceLabel}${o.note == null ? '' : '  ·  ${o.note}'}';
}
