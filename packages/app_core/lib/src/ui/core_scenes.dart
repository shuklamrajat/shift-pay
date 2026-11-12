import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'scene.dart';

/// Shared paywall art: a gem rising out of a glowing ring, with sparkles.
void proGemScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  final center = Offset(w / 2, h * 0.5);
  final rise = phase(f.intro, 0, 0.7, Curves.easeOutBack);
  final r = math.min(w, h) * 0.26;
  Ink2.glow(c, center, r * 2.1, f.brand.accent.withValues(alpha: 0.35 * rise));
  // Orbit ring.
  final ring = Rect.fromCenter(center: center.translate(0, r * 0.75), width: r * 3.2, height: r * 0.9);
  c.drawOval(ring, Ink2.stroke(f.scheme.primary.withValues(alpha: 0.35 * rise), 3));
  final orbit = f.loop * 2 * math.pi + f.intro * math.pi;
  for (var i = 0; i < 3; i++) {
    final a = orbit + i * 2 * math.pi / 3;
    final p = Offset(ring.center.dx + ring.width / 2 * math.cos(a), ring.center.dy + ring.height / 2 * math.sin(a));
    c.drawCircle(p, 5 * rise, Ink2.fill(i == 0 ? f.brand.accent : f.scheme.primary));
  }
  // Gem.
  final gy = center.dy - r * 0.25 + (1 - rise) * h * 0.4 + 5 * f.wave();
  final top = gy - r * 0.8, mid = gy - r * 0.2, bottom = gy + r;
  final gem = Path()
    ..moveTo(center.dx - r * 0.55, top)
    ..lineTo(center.dx + r * 0.55, top)
    ..lineTo(center.dx + r, mid)
    ..lineTo(center.dx, bottom)
    ..lineTo(center.dx - r, mid)
    ..close();
  c.drawPath(
    gem,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [f.brand.accent, f.scheme.primary, f.brand.gradient.last],
      ).createShader(Rect.fromLTRB(center.dx - r, top, center.dx + r, bottom)),
  );
  final facet = Ink2.stroke(Colors.white.withValues(alpha: 0.55), 2);
  c.drawLine(Offset(center.dx - r, mid), Offset(center.dx + r, mid), facet);
  c.drawLine(Offset(center.dx - r * 0.55, top), Offset(center.dx - r * 0.25, mid), facet);
  c.drawLine(Offset(center.dx + r * 0.55, top), Offset(center.dx + r * 0.25, mid), facet);
  c.drawLine(Offset(center.dx - r * 0.25, mid), Offset(center.dx, bottom), facet);
  c.drawLine(Offset(center.dx + r * 0.25, mid), Offset(center.dx, bottom), facet);
  // Shine sweeping across.
  final sweep = (f.loop * 1.6) % 1.6;
  if (sweep < 1) {
    c.save();
    c.clipPath(gem);
    final x = center.dx - r + sweep * 2 * r;
    c.drawRect(Rect.fromLTWH(x - 10, top, 20, bottom - top), Paint()..color = Colors.white.withValues(alpha: 0.28));
    c.restore();
  }
  paintSparkField(c, s, f, f.brand.accent, count: 9, seed: 5);
}

/// Fallback empty-state art: the icon floating on a soft blob.
class IconBlob extends StatelessWidget {
  const IconBlob({super.key, required this.icon, this.size = 120});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Float(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [scheme.primaryContainer, scheme.primaryContainer.withValues(alpha: 0.2)]),
        ),
        child: Icon(icon, size: size * 0.46, color: scheme.primary),
      ),
    );
  }
}
