import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/brand.dart';
import '../ui/motion.dart';
import 'ads.dart';

/// Wraps a screen's bottom navigation and docks one banner ad above it.
///
/// Rules (docs/ads-failure-modes.md): one banner on the main screen only,
/// never over entry forms; nothing takes space until an ad has loaded; a
/// failed load leaves no gap; the banner slides open once and stays still
/// when the phone asks for reduced motion; it is loaded once per width and
/// disposed with the screen.
class AdDock extends ConsumerStatefulWidget {
  const AdDock({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AdDock> createState() => _AdDockState();
}

class _AdDockState extends ConsumerState<AdDock> {
  LoadedBanner? _banner;
  int? _requestedWidth;
  bool _loading = false;

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load(int width) async {
    _loading = true;
    _requestedWidth = width;
    final banner = await ref.read(adsPlatformProvider).loadBanner(adUnitId: bannerAdUnitId(), width: width);
    _loading = false;
    if (!mounted || !ref.read(showAdsProvider)) {
      banner?.dispose();
      return;
    }
    setState(() {
      _banner?.dispose();
      _banner = banner;
    });
  }

  void _drop() {
    final old = _banner;
    if (old == null) return;
    setState(() => _banner = null);
    old.dispose();
    _requestedWidth = null;
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showAdsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.truncate();
            if (show && !_loading && width > 0 && width != _requestedWidth) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _load(width);
              });
            } else if (!show && _banner != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _drop();
              });
            }
            final banner = show ? _banner : null;
            return AnimatedSize(
              duration: Motion.of(context, 420),
              curve: Curves.easeOutBack,
              alignment: Alignment.bottomCenter,
              child: banner == null ? const SizedBox(width: double.infinity) : _BannerFrame(banner: banner),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// The banner in a frame that belongs to the app: a brand-gradient seam that
/// sweeps once when the ad arrives, and a small "Ad" tag so nobody mistakes
/// the ad for part of the app.
class _BannerFrame extends StatelessWidget {
  const _BannerFrame({required this.banner});
  final LoadedBanner banner;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('ad-banner'),
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seam(colors: [...brand.gradient, brand.accent]),
          Stack(
            children: [
              Center(
                child: SizedBox(height: banner.height, child: banner.widget),
              ),
              Positioned(
                left: 6,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text('Ad', style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Seam extends StatelessWidget {
  const _Seam({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, 1100),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) => Container(
        height: 3,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [...colors, colors.first],
            // The highlight travels left to right once, then rests.
            begin: Alignment(-1 - 2 * (1 - t), 0),
            end: Alignment(1 + 2 * (1 - t), 0),
          ),
        ),
      ),
    );
  }
}
