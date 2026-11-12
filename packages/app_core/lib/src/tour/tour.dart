import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads.dart';
import '../settings/settings.dart';
import '../ui/brand.dart';
import '../ui/motion.dart';

/// One stop on the guided tour. [target] is the key of a real control on the
/// home screen (a Key('...') the app already uses). When that control is not
/// on screen the stop shows as a card in the middle, with no spotlight.
class TourStep {
  const TourStep({required this.target, required this.icon, required this.title, required this.body});
  final String target;
  final IconData icon;
  final String title;
  final String body;
}

@immutable
class TourState {
  const TourState({this.active = false, this.step = 0, this.done = false});
  final bool active;
  final int step;

  /// Finished or skipped at least once (kept across restarts).
  final bool done;

  TourState copyWith({bool? active, int? step, bool? done}) =>
      TourState(active: active ?? this.active, step: step ?? this.step, done: done ?? this.done);
}

/// Runs the tour. It starts by itself once per install, after onboarding,
/// once Google's consent step is out of the way and the home screen shows its
/// first step's control; Settings can replay it any time.
class TourController extends Notifier<TourState> {
  static const doneKey = 'core.tourDone';

  @override
  TourState build() => TourState(done: ref.watch(sharedPrefsProvider).getBool(doneKey) ?? false);

  int get _count => ref.read(appConfigProvider).tour.length;

  void start() {
    if (_count == 0) return;
    state = state.copyWith(active: true, step: 0);
  }

  void next() {
    if (!state.active) return;
    if (state.step + 1 >= _count) {
      finish();
    } else {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void back() {
    if (state.active && state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  /// Ends the tour, by finishing or skipping. Either way it won't start by
  /// itself again.
  Future<void> finish() async {
    state = state.copyWith(active: false, step: 0, done: true);
    await ref.read(sharedPrefsProvider).setBool(doneKey, true);
  }
}

final tourControllerProvider = NotifierProvider<TourController, TourState>(TourController.new);

/// Ads wait until the person has been through (or skipped) the tour once,
/// and stay off while it is open, so the scrim never sits over an ad and no
/// banner slides in under a spotlight.
final tourHoldsAdsProvider = Provider<bool>((ref) {
  if (ref.watch(appConfigProvider).tour.isEmpty) return false;
  final t = ref.watch(tourControllerProvider);
  return t.active || !t.done;
});

/// Sits above the app's navigator and draws the tour over the home screen.
class TourLayer extends ConsumerStatefulWidget {
  const TourLayer({super.key, required this.navigatorKey, required this.child});
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<TourLayer> createState() => _TourLayerState();
}

class _TourLayerState extends ConsumerState<TourLayer> {
  final _appKey = GlobalKey();
  final _layerKey = GlobalKey();
  Rect? _rect;
  bool _measuring = false;
  bool _autoChecked = false;

  /// The control with [key] on the screen now, in this layer's coordinates.
  Rect? _find(String key) {
    final root = _appKey.currentContext;
    final layer = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (root == null || layer == null || !layer.hasSize) return null;
    final wanted = ValueKey<String>(key);
    Rect? found;
    void visit(Element e) {
      if (found != null) return;
      if (e.widget.key == wanted) {
        final box = e.renderObject;
        if (box is RenderBox && box.attached && box.hasSize) {
          final topLeft = layer.globalToLocal(box.localToGlobal(Offset.zero));
          found = topLeft & box.size;
          return;
        }
      }
      e.visitChildren(visit);
    }

    root.visitChildElements(visit);
    return found;
  }

  bool get _homeOnTop => !(widget.navigatorKey.currentState?.canPop() ?? true);

  void _maybeAutoStart() {
    if (_autoChecked) return;
    final config = ref.read(appConfigProvider);
    final tour = ref.read(tourControllerProvider);
    final ads = ref.read(adsControllerProvider).phase;
    if (config.tour.isEmpty || tour.done || tour.active) return;
    if (!ref.read(coreSettingsProvider).onboardingDone) return;
    // Google's consent form goes first: it is a full-screen system form, and a
    // tour drawn under it would be half seen.
    if (ads == AdsPhase.notStarted || ads == AdsPhase.gatheringConsent) return;
    if (!_homeOnTop || _find(config.tour.first.target) == null) return;
    _autoChecked = true;
    ref.read(tourControllerProvider.notifier).start();
  }

  bool _watching = false;

  /// Until the tour has run once, look after every frame the app draws anyway
  /// (never asking for frames of its own) for the moment it can start: the
  /// home screen may only get its controls after the first job is saved.
  void _autoStartLoop() {
    if (_watching) return;
    _watching = true;
    void tick(Duration _) {
      final t = mounted ? ref.read(tourControllerProvider) : null;
      if (t == null || t.active || t.done || _autoChecked) {
        _watching = false;
        return;
      }
      _maybeAutoStart();
      WidgetsBinding.instance.addPostFrameCallback(tick);
    }

    WidgetsBinding.instance.addPostFrameCallback(tick);
  }

  /// While the tour is open, re-measure the spotlighted control after every
  /// frame the app draws anyway (it never asks for frames of its own), so the
  /// spotlight follows the control if the layout moves.
  void _measureLoop() {
    if (_measuring) return;
    _measuring = true;
    void tick(Duration _) {
      if (!mounted || !ref.read(tourControllerProvider).active) {
        _measuring = false;
        return;
      }
      final step = ref.read(tourControllerProvider).step;
      final steps = ref.read(appConfigProvider).tour;
      final r = step < steps.length && _homeOnTop ? _find(steps[step].target) : null;
      if (!_same(r, _rect)) setState(() => _rect = r);
      WidgetsBinding.instance.addPostFrameCallback(tick);
    }

    WidgetsBinding.instance.addPostFrameCallback(tick);
  }

  static bool _same(Rect? a, Rect? b) {
    if (a == null || b == null) return a == b;
    return (a.left - b.left).abs() < 0.5 &&
        (a.top - b.top).abs() < 0.5 &&
        (a.width - b.width).abs() < 0.5 &&
        (a.height - b.height).abs() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(tourControllerProvider);
    final steps = ref.watch(appConfigProvider).tour;
    // Rebuilds when any start condition changes.
    ref.watch(coreSettingsProvider.select((s) => s.onboardingDone));
    ref.watch(adsControllerProvider.select((s) => s.phase));
    if (!tour.active && !tour.done) _autoStartLoop();
    if (tour.active) _measureLoop();
    return Stack(
      key: _layerKey,
      children: [
        KeyedSubtree(key: _appKey, child: widget.child),
        if (tour.active && tour.step < steps.length)
          Positioned.fill(
            child: _TourOverlay(
              steps: steps,
              index: tour.step,
              target: _rect,
              onNext: () => ref.read(tourControllerProvider.notifier).next(),
              onBack: () => ref.read(tourControllerProvider.notifier).back(),
              onSkip: () => ref.read(tourControllerProvider.notifier).finish(),
            ),
          ),
      ],
    );
  }
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({
    required this.steps,
    required this.index,
    required this.target,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });
  final List<TourStep> steps;
  final int index;
  final Rect? target;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> with TickerProviderStateMixin {
  static const pad = 8.0;
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _enter.value = 1;
    } else if (_enter.status == AnimationStatus.dismissed) {
      _enter.forward();
    }
    if (Motion.ambient && !Motion.reduced(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final brand = BrandColors.of(context);
    final step = widget.steps[widget.index];
    final last = widget.index == widget.steps.length - 1;
    final full = Offset.zero & size;
    final hole = widget.target?.inflate(pad) ?? Rect.fromCenter(center: full.center, width: 0, height: 0);
    final below = widget.target == null || hole.center.dy < size.height / 2;

    return FadeTransition(
      opacity: _enter,
      child: Material(
        key: const Key('tour'),
        type: MaterialType.transparency,
        child: TweenAnimationBuilder<Rect?>(
          tween: RectTween(begin: full, end: hole),
          duration: Motion.of(context, 520),
          curve: Curves.easeInOutCubic,
          builder: (context, r, _) {
            final spot = r ?? hole;
            final centred = widget.target == null;
            final cardTop = centred ? 0.0 : (below ? hole.bottom + 44 : null);
            final cardBottom = centred ? 0.0 : (below ? null : size.height - hole.top + 44);
            return Stack(
              children: [
                // The scrim takes every tap outside the card, so nothing
                // under it is pressed by accident.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => CustomPaint(
                        painter: _ScrimPainter(
                          hole: spot,
                          hasTarget: widget.target != null,
                          pulse: _pulse.isAnimating ? _pulse.value : 0,
                          colors: [...brand.gradient, brand.accent],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.target != null)
                  Positioned.fromRect(
                    rect: spot,
                    child: const IgnorePointer(child: SizedBox.expand(key: Key('tour-spotlight'))),
                  ),
                if (widget.target != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('trail-${widget.index}'),
                        tween: Tween(begin: 0, end: 1),
                        duration: Motion.of(context, 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, _) => CustomPaint(
                          painter: _TrailPainter(
                            from: Offset(size.width / 2, below ? hole.bottom + 44 : hole.top - 44),
                            to: Offset(hole.center.dx, below ? hole.bottom + 4 : hole.top - 4),
                            t: t,
                            color: brand.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: cardTop,
                  bottom: cardBottom,
                  child: Align(
                    alignment: centred ? Alignment.center : Alignment.topCenter,
                    heightFactor: centred ? null : 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _TourCard(
                        step: step,
                        index: widget.index,
                        count: widget.steps.length,
                        last: last,
                        onNext: widget.onNext,
                        onBack: widget.onBack,
                        onSkip: widget.onSkip,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.index,
    required this.count,
    required this.last,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });
  final TourStep step;
  final int index;
  final int count;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('tour-card'),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: brand.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: Motion.of(context, 280),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
        child: Column(
          key: ValueKey(index),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StepBadge(icon: step.icon, colors: [...brand.gradient, brand.accent], onBrand: brand.onBrand),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1} of $count',
                        key: const Key('tour-count'),
                        style: text.labelMedium?.copyWith(color: scheme.primary),
                      ),
                      Text(
                        step.title,
                        key: const Key('tour-title'),
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(step.body, key: const Key('tour-body'), style: text.bodyMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                if (!last) TextButton(key: const Key('tour-skip'), onPressed: onSkip, child: const Text('Skip')),
                const Spacer(),
                _Dots(index: index, count: count, color: scheme.primary),
                const SizedBox(width: 6),
                if (index > 0)
                  IconButton(
                    key: const Key('tour-back'),
                    // No tooltip: the tour sits above the app's Overlay.
                    icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
                    onPressed: onBack,
                  ),
                FilledButton(
                  key: Key(last ? 'tour-finish' : 'tour-next'),
                  onPressed: onNext,
                  child: Text(last ? 'Got it' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count, required this.color});
  final int index;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: Motion.of(context, 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: i == index ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == index ? color : color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
    ],
  );
}

/// The step's icon on a brand-gradient disc, with a ring that draws itself in
/// and three sparks that orbit it while ambient motion is on.
class _StepBadge extends StatefulWidget {
  const _StepBadge({required this.icon, required this.colors, required this.onBrand});
  final IconData icon;
  final List<Color> colors;
  final Color onBrand;

  @override
  State<_StepBadge> createState() => _StepBadgeState();
}

class _StepBadgeState extends State<_StepBadge> with TickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _ring.value = 1;
    } else if (_ring.status == AnimationStatus.dismissed) {
      _ring.forward();
    }
    if (Motion.ambient && !Motion.reduced(context)) {
      if (!_orbit.isAnimating) _orbit.repeat();
    } else {
      _orbit.stop();
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 52,
    child: AnimatedBuilder(
      animation: Listenable.merge([_ring, _orbit]),
      builder: (_, child) => CustomPaint(
        painter: _BadgePainter(
          ring: Curves.easeOutCubic.transform(_ring.value),
          orbit: _orbit.value,
          colors: widget.colors,
        ),
        child: child,
      ),
      child: Icon(widget.icon, color: widget.onBrand, size: 24),
    ),
  );
}

class _BadgePainter extends CustomPainter {
  _BadgePainter({required this.ring, required this.orbit, required this.colors});
  final double ring;
  final double orbit;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 5;
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r * (0.7 + 0.3 * ring),
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(disc),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 3),
      -math.pi / 2,
      2 * math.pi * ring,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = colors.last.withValues(alpha: 0.8),
    );
    if (ring < 1) return;
    for (var i = 0; i < 3; i++) {
      final a = 2 * math.pi * (orbit + i / 3);
      final p = c + Offset(math.cos(a), math.sin(a)) * (r + 3);
      canvas.drawCircle(p, i == 0 ? 2.6 : 1.8, Paint()..color = colors[i % colors.length]);
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.ring != ring || old.orbit != orbit || old.colors != colors;
}

/// Dims everything but a rounded window over the control, rims the window in
/// the brand gradient and sends a soft ring out from it while ambient motion
/// is on.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.hasTarget, required this.pulse, required this.colors});
  final Rect hole;
  final bool hasTarget;
  final double pulse;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(math.min(18, hole.shortestSide / 2));
    final window = RRect.fromRectAndRadius(hole, radius);
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(window);
    canvas.drawPath(scrim, Paint()..color = const Color(0xB3000000));
    if (!hasTarget || hole.isEmpty) return;
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = SweepGradient(colors: [...colors, colors.first]).createShader(hole),
    );
    if (pulse > 0) {
      canvas.drawRRect(
        window.inflate(14 * pulse),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colors.last.withValues(alpha: 0.6 * (1 - pulse)),
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.pulse != pulse || old.hasTarget != hasTarget || old.colors != colors;
}

/// A dotted curve that traces itself from the card to the spotlight and ends
/// in an arrowhead.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.from, required this.to, required this.t, required this.color});
  final Offset from;
  final Offset to;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || (from - to).distance < 24) return;
    final bend = (to.dx - from.dx).abs() < 40 ? 60.0 : 0.0;
    final control = Offset((from.dx + to.dx) / 2 + bend, (from.dy + to.dy) / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    final PathMetric metric = path.computeMetrics().first;
    final drawn = metric.length * t;
    final dot = Paint()..color = color.withValues(alpha: 0.9);
    for (var d = 0.0; d < drawn; d += 9) {
      final tan = metric.getTangentForOffset(d);
      if (tan != null) canvas.drawCircle(tan.position, 1.8, dot);
    }
    if (t < 1) return;
    final end = metric.getTangentForOffset(metric.length)!;
    final dir = end.vector / end.vector.distance;
    final side = Offset(-dir.dy, dir.dx);
    final tip = end.position;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((tip - dir * 9 + side * 5).dx, (tip - dir * 9 + side * 5).dy)
      ..lineTo((tip - dir * 9 - side * 5).dx, (tip - dir * 9 - side * 5).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.t != t || old.from != from || old.to != to || old.color != color;
}
