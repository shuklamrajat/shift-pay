import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

/// Payday Swoop: a W that is also a gull in flight, crossing a gold coin.
/// The same artwork as brand/logo.svg. The bird swoops in, then flaps.
void wagebirdLogo(Canvas c, Size size, SceneFrame f) {
  onLogoGrid(c, size, (c) {
    c.drawRect(
      const Rect.fromLTWH(0, 0, 512, 512),
      Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(512, 512), const [Color(0xFF0FA394), Color(0xFF014B85)]),
    );
    final intro = Curves.easeOutBack.transform(f.intro.clamp(0.0, 1.0));
    c.save();
    c.translate(256, 256);
    c.scale(0.92);
    c.translate(-256, -256);

    // Coin, rising in, then bobbing a little.
    final bob = math.sin(f.loop * 2 * math.pi) * 4;
    c.save();
    c.translate(0, (1 - intro) * 60 + bob);
    const coin = Offset(338, 178);
    c.drawCircle(
      coin,
      96,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(309.2, 139.6),
          153.6,
          const [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFF57C00)],
          const [0, .6, 1],
        ),
    );
    c.drawCircle(
      coin,
      74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFFFFF3C4).withValues(alpha: .9),
    );
    c.drawPath(
      Path()
        ..moveTo(300, 140)
        ..arcToPoint(const Offset(360, 128), radius: const Radius.circular(54)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .7),
    );
    c.restore();

    // Speed lines, drawn out as the bird arrives.
    final lines = Paint()
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB2EBF2).withValues(alpha: .45);
    for (final (y, x0, len) in const [(360.0, 120.0, 52.0), (392.0, 140.0, 64.0), (424.0, 176.0, 40.0)]) {
      c.drawLine(Offset(x0 + len * (1 - intro.clamp(0.0, 1.0)), y), Offset(x0 + len, y), lines);
    }

    // The bird: swoops in from the left, then flaps (wings up at rest).
    final flap = (1 - math.cos(f.loop * 4 * 2 * math.pi)) / 2;
    final wings = _wings(flap);
    c.save();
    c.translate(-(1 - intro) * 120, (1 - intro) * 40);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(
      wings.shift(const Offset(6, 10)),
      stroke
        ..strokeWidth = 52
        ..color = const Color(0xFF06343A).withValues(alpha: .25),
    );
    c.drawPath(
      wings,
      stroke
        ..strokeWidth = 48
        ..color = Colors.white,
    );
    final beakY = ui.lerpDouble(262, 268, flap)!;
    c.drawPath(
      Path()
        ..moveTo(246, beakY)
        ..lineTo(256, beakY - 16)
        ..lineTo(266, beakY)
        ..close(),
      Paint()..color = const Color(0xFFFFB300),
    );
    c.restore();
    c.restore();
  });
}

// The wing stroke, from wings up (t = 0) to wings down (t = 1).
const _up = [96.0, 206, 150, 226, 192, 296, 214, 338, 232, 294, 250, 270, 256, 264, 262, 270, 280, 294, 298, 338, 320, 296, 362, 226, 416, 206];
const _down = [100.0, 262, 150, 262, 192, 306, 214, 338, 232, 300, 250, 276, 256, 270, 262, 276, 280, 300, 298, 338, 320, 306, 362, 262, 412, 262];

Path _wings(double t) {
  final p = [for (var i = 0; i < _up.length; i++) ui.lerpDouble(_up[i], _down[i], t)!];
  final path = Path()..moveTo(p[0], p[1]);
  for (var i = 2; i < p.length; i += 6) {
    path.cubicTo(p[i], p[i + 1], p[i + 2], p[i + 3], p[i + 4], p[i + 5]);
  }
  return path;
}
