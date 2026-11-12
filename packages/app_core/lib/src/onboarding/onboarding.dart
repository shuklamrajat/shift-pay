import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../settings/settings.dart';
import '../ui/brand.dart';
import '../ui/core_scenes.dart';
import '../ui/motion.dart';
import '../ui/scene.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _pageValue =>
      _controller.hasClients && _controller.position.haveDimensions ? _controller.page ?? 0 : _page.toDouble();

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final pages = config.onboarding;
    final last = _page == pages.length - 1;
    final theme = Theme.of(context);
    final brand = BrandColors.of(context);
    return Scaffold(
      key: const Key('onboarding'),
      body: Stack(
        children: [
          // Backdrop: a wash of the brand colours that shifts as pages turn.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => CustomPaint(
                painter: _Backdrop(
                  progress: pages.length <= 1 ? 0 : _pageValue / (pages.length - 1),
                  a: brand.gradient.first,
                  b: brand.accent,
                  surface: theme.scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: brand.linear),
                      ),
                      const SizedBox(width: 8),
                      Text(config.appName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton(
                        key: const Key('onboarding-skip'),
                        onPressed: () => ref.read(coreSettingsProvider.notifier).completeOnboarding(),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        final delta = (_pageValue - i).clamp(-1.0, 1.0);
                        return _PageBody(page: pages[i], delta: delta);
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        duration: Motion.of(context, 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.all(4),
                        width: i == _page ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: i == _page ? brand.linear : null,
                          color: i == _page ? null : theme.colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('onboarding-next'),
                      style: FilledButton.styleFrom(
                        backgroundColor: brand.gradient.last,
                        foregroundColor: brand.onBrand,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (last) {
                          ref.read(coreSettingsProvider.notifier).completeOnboarding();
                        } else {
                          _controller.nextPage(duration: Motion.of(context, 450), curve: Curves.easeOutCubic);
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: Motion.of(context, 200),
                        child: Text(last ? 'Get started' : 'Next', key: ValueKey(last)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page, required this.delta});
  final OnboardingPage page;

  /// -1..1: how far this page is from the centre of the screen.
  final double delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = 1 - delta.abs();
    return LayoutBuilder(
      builder: (context, box) {
        final artSize = math.min(box.maxWidth - 48, box.maxHeight * 0.58).clamp(120.0, 340.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The art drifts slower than the page for a bit of depth.
              Transform.translate(
                offset: Offset(delta * -box.maxWidth * 0.35, 0),
                child: SizedBox.square(
                  dimension: artSize,
                  child: page.scene == null
                      ? Center(
                          child: IconBlob(icon: page.icon, size: artSize * 0.6),
                        )
                      : AnimatedScene(paint: page.scene!, label: page.title),
                ),
              ),
              const SizedBox(height: 28),
              Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(delta * -40, 0),
                  child: Column(
                    children: [
                      Text(page.title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        page.body,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Backdrop extends CustomPainter {
  _Backdrop({required this.progress, required this.a, required this.b, required this.surface});
  final double progress;
  final Color a, b, surface;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    final c1 = Offset(size.width * (0.15 + 0.7 * progress), size.height * 0.28);
    final c2 = Offset(size.width * (0.9 - 0.6 * progress), size.height * 0.62);
    for (final (c, col, r) in [(c1, a, size.width * 0.75), (c2, b, size.width * 0.6)]) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [col.withValues(alpha: 0.22), col.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_Backdrop old) => old.progress != progress || old.surface != surface || old.a != a;
}
