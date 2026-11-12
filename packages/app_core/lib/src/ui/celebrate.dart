import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';
import 'motion.dart';

/// Bursts confetti over the whole app for a moment, for wins like buying
/// Pro. It never blocks touches and is skipped when motion is reduced.
void celebrate(BuildContext context) {
  if (Motion.reduced(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final scheme = Theme.of(context).colorScheme;
  final brand = BrandColors.of(context);
  final colors = [scheme.primary, brand.accent, scheme.tertiary, brand.success, brand.gradient.first, scheme.secondary];
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _Confetti(key: const Key('celebration'), colors: colors, onDone: () => entry.remove()),
    ),
  );
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({super.key, required this.colors, required this.onDone});
  final List<Color> colors;
  final VoidCallback onDone;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  late final List<_Bit> _bits = () {
    final rnd = math.Random(11);
    return [
      for (var i = 0; i < 90; i++)
        _Bit(
          angle: -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 0.9,
          speed: 0.9 + rnd.nextDouble() * 0.9,
          spin: (rnd.nextDouble() - 0.5) * 18,
          size: 5 + rnd.nextDouble() * 7,
          color: widget.colors[i % widget.colors.length],
          round: rnd.nextBool(),
          fromLeft: i.isEven,
        ),
    ];
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_bits, _c.value)),
  );
}

class _Bit {
  const _Bit({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
    required this.fromLeft,
  });
  final double angle, speed, spin, size;
  final Color color;
  final bool round, fromLeft;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
    for (final b in bits) {
      // Two cannons in the bottom corners; gravity pulls the bits back down.
      final origin = Offset(b.fromLeft ? size.width * 0.1 : size.width * 0.9, size.height * 0.95);
      final tilt = b.fromLeft ? 0.35 : -0.35;
      final v = size.height * 1.25 * b.speed;
      final x = origin.dx + math.cos(b.angle + tilt) * v * t;
      final y = origin.dy + math.sin(b.angle + tilt) * v * t + size.height * 1.4 * t * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * t);
      final paint = Paint()..color = b.color.withValues(alpha: fade);
      if (b.round) {
        canvas.drawCircle(Offset.zero, b.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 0.45), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
