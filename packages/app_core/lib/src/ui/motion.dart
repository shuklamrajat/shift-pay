import 'package:flutter/material.dart';

/// App-wide motion switches.
abstract final class Motion {
  /// Endless decorative loops (floating, twinkling, pulsing). End-to-end runs
  /// turn these off, because pumpAndSettle must see the screen come to rest.
  /// One-shot entrance animations still play there.
  static bool ambient = true;

  /// True when the person asked the system to reduce or remove motion.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [ms] milliseconds, or zero when motion is reduced.
  static Duration of(BuildContext context, int ms) => reduced(context) ? Duration.zero : Duration(milliseconds: ms);
}

/// Eased progress of [t] through the window [a]..[b] (0 before, 1 after).
double phase(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

/// Fades and slides its child in once, after a short stagger by [index].
/// Shows the child at rest straight away when motion is reduced.
class Appear extends StatefulWidget {
  const Appear({super.key, required this.child, this.index = 0, this.from = const Offset(0, 0.12)});
  final Widget child;
  final int index;
  final Offset from;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    // The stagger is part of the controller's own run (not a timer), so a
    // test's pumpAndSettle waits for it.
    final delay = 55 * widget.index.clamp(0, 8);
    const run = 420;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: delay + run),
    );
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(delay / (delay + run), 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else if (_c.status == AnimationStatus.dismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: SlideTransition(
      position: Tween(begin: widget.from, end: Offset.zero).animate(_a),
      child: widget.child,
    ),
  );
}

/// A number that counts up to [value] when shown and glides to each new
/// value after. The keyed [Text] always holds the final value, so screen
/// readers and tests read the real figure while the digits roll.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.textKey,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Key? textKey;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final settled = Text(format(value), key: textKey, style: style, maxLines: 1);
    if (Motion.reduced(context)) return settled;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        if (v == value) return settled;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(opacity: 0, alwaysIncludeSemantics: true, child: settled),
            Positioned(
              left: 0,
              top: 0,
              child: ExcludeSemantics(child: Text(format(v), style: style, maxLines: 1)),
            ),
          ],
        );
      },
    );
  }
}

/// Gently bobs its child up and down while ambient motion is on.
class Float extends StatefulWidget {
  const Float({super.key, required this.child, this.amplitude = 6, this.period = const Duration(seconds: 3)});
  final Widget child;
  final double amplitude;
  final Duration period;

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.ambient && !Motion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, widget.amplitude * (Curves.easeInOut.transform(_c.value) * 2 - 1)),
      child: child,
    ),
    child: widget.child,
  );
}
