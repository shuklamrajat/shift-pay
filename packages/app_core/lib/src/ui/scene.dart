import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';
import 'motion.dart';

/// What a scene painter gets for one frame.
class SceneFrame {
  const SceneFrame({required this.intro, required this.loop, required this.scheme, required this.brand});

  /// 0 to 1 once, when the scene first shows (1 when motion is reduced).
  final double intro;

  /// 0 to 1 over and over while ambient motion is on (0 otherwise).
  final double loop;
  final ColorScheme scheme;
  final BrandColors brand;

  bool get dark => scheme.brightness == Brightness.dark;

  /// A smooth wave of the loop, -1..1, shifted by [offset] turns.
  double wave([double offset = 0]) => math.sin((loop + offset) * 2 * math.pi);
}

/// Paints one frame of an illustration into [size].
typedef ScenePaint = void Function(Canvas canvas, Size size, SceneFrame frame);

/// A vector illustration drawn in code: plays its intro once, then idles in
/// a slow loop. Tapping it replays the intro. Holds still when the system
/// asks for reduced motion.
class AnimatedScene extends StatefulWidget {
  const AnimatedScene({
    super.key,
    required this.paint,
    this.aspectRatio = 1,
    this.intro = const Duration(milliseconds: 1600),
    this.loop = const Duration(seconds: 6),
    this.label,
  });

  final ScenePaint paint;
  final double aspectRatio;
  final Duration intro;
  final Duration loop;

  /// Read out by screen readers. Null marks the scene as decoration.
  final String? label;

  @override
  State<AnimatedScene> createState() => _AnimatedSceneState();
}

class _AnimatedSceneState extends State<AnimatedScene> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: widget.intro);
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _intro.value = 1;
      _loop
        ..stop()
        ..value = 0;
      return;
    }
    if (_intro.status == AnimationStatus.dismissed) _intro.forward();
    if (Motion.ambient && !_loop.isAnimating) _loop.repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final art = RepaintBoundary(
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: CustomPaint(painter: _ScenePainter(widget.paint, _intro, _loop, scheme, brand), size: Size.infinite),
      ),
    );
    final tappable = GestureDetector(onTap: Motion.reduced(context) ? null : () => _intro.forward(from: 0), child: art);
    return widget.label == null
        ? ExcludeSemantics(child: tappable)
        : Semantics(
            label: widget.label,
            image: true,
            child: ExcludeSemantics(child: tappable),
          );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.fn, this.intro, this.loop, this.scheme, this.brand)
    : super(repaint: Listenable.merge([intro, loop]));
  final ScenePaint fn;
  final Animation<double> intro;
  final Animation<double> loop;
  final ColorScheme scheme;
  final BrandColors brand;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    fn(canvas, size, SceneFrame(intro: intro.value, loop: loop.value, scheme: scheme, brand: brand));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.fn != fn || old.scheme != scheme || old.brand != brand;
}

/// Small drawing helpers shared by the apps' scenes.
abstract final class Ink2 {
  static Paint fill(Color c) => Paint()..color = c;
  static Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// A soft round glow behind a subject.
  static void glow(Canvas c, Offset center, double r, Color color) {
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  /// A four-point sparkle of radius [r] (0 draws nothing).
  static void sparkle(Canvas c, Offset o, double r, Color color) {
    if (r <= 0.2) return;
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(p, fill(color));
  }

  /// A coin seen from the front, squashed by [turn] (0..1 is one full spin).
  static void coin(Canvas c, Offset o, double r, Color face, Color rim, {double turn = 0}) {
    final w = r * (math.cos(turn * 2 * math.pi)).abs().clamp(0.12, 1.0);
    final rect = Rect.fromCenter(center: o, width: w * 2, height: r * 2);
    c.drawOval(rect.shift(Offset(0, r * 0.12)), fill(rim));
    c.drawOval(rect, fill(face));
    c.drawOval(rect.deflate(r * 0.22), stroke(rim.withValues(alpha: 0.55), r * 0.1));
  }

  /// Rounded rectangle helper.
  static void rrect(Canvas c, Rect r, double radius, Paint p) =>
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), p);

  /// Ground shadow under a subject.
  static void shadow(Canvas c, Offset center, double w, Color color) {
    c.drawOval(Rect.fromCenter(center: center, width: w, height: w * 0.16), fill(color.withValues(alpha: 0.18)));
  }
}

/// A floating spark field drawn behind scenes and hero panels.
void paintSparkField(Canvas c, Size s, SceneFrame f, Color color, {int count = 7, int seed = 3}) {
  final rnd = math.Random(seed);
  for (var i = 0; i < count; i++) {
    final x = rnd.nextDouble() * s.width;
    final y = rnd.nextDouble() * s.height;
    final ph = rnd.nextDouble();
    final pulse = 0.5 + 0.5 * math.sin((f.loop + ph) * 2 * math.pi);
    final appear = phase(f.intro, 0.3 + i * 0.05, 0.8 + i * 0.03);
    Ink2.sparkle(c, Offset(x, y), (3 + 4 * pulse) * appear, color.withValues(alpha: 0.35 + 0.5 * pulse));
  }
}
