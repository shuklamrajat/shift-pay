// Tipwell's illustrations, drawn in code so they scale, theme and move.
// Gradients stay at two stops (more stops have crashed emulator GPUs).
import 'dart:math' as math;

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

const gold = Color(0xFFFFC107);
const goldDeep = Color(0xFFB8860B);
const billGreen = Color(0xFF43A047);
const billDeep = Color(0xFF1B5E20);

double _ease(double t) => Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

/// The tip jar mascot. [fill] 0..1 is how full it is; [wobble] tilts it.
void tipJar(Canvas c, Offset o, double size, SceneFrame f, {double fill = 0.5, double wobble = 0, int coins = 7}) {
  if (size <= 1) return;
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(wobble * 0.06);
  c.scale(size / 100);
  final glass = f.dark ? const Color(0x5590CAF9) : const Color(0x66BBDEFB);
  final rim = f.dark ? const Color(0xFF90CAF9) : const Color(0xFF1E88E5);
  // Shadow.
  c.drawOval(Rect.fromCenter(center: const Offset(0, 54), width: 84, height: 12), Ink2.fill(Colors.black.withValues(alpha: f.dark ? 0.4 : 0.14)));
  final body = RRect.fromRectAndCorners(
    Rect.fromCenter(center: const Offset(0, 10), width: 80, height: 86),
    topLeft: const Radius.circular(14),
    topRight: const Radius.circular(14),
    bottomLeft: const Radius.circular(22),
    bottomRight: const Radius.circular(22),
  );
  // Contents, clipped to the jar.
  c.save();
  c.clipRRect(body);
  final level = 52 - 80 * fill.clamp(0.0, 1.0);
  c.drawRect(Rect.fromLTRB(-40, level, 40, 60), Ink2.fill(billGreen.withValues(alpha: 0.85)));
  // Folded bills peeking out of the pile.
  for (var i = 0; i < 3; i++) {
    final x = -22.0 + i * 20;
    c.save();
    c.translate(x, level + 6);
    c.rotate(-0.4 + i * 0.35);
    Ink2.rrect(c, const Rect.fromLTWH(-12, -6, 24, 12), 2, Ink2.fill(i.isEven ? const Color(0xFF66BB6A) : billDeep));
    c.drawCircle(Offset.zero, 3, Ink2.stroke(Colors.white.withValues(alpha: 0.6), 1.2));
    c.restore();
  }
  final rnd = math.Random(7);
  for (var i = 0; i < coins; i++) {
    final x = -30 + rnd.nextDouble() * 60;
    final y = level + 10 + rnd.nextDouble() * (52 - level - 6).clamp(0, 60);
    Ink2.coin(c, Offset(x, y), 7, gold, goldDeep, turn: rnd.nextDouble() * 0.15);
  }
  c.restore();
  c.drawRRect(body, Ink2.fill(glass));
  c.drawRRect(body, Ink2.stroke(rim, 3));
  // Shine.
  c.drawLine(const Offset(-28, -18), const Offset(-28, 30), Ink2.stroke(Colors.white.withValues(alpha: 0.7), 4));
  // Neck and lid with a coin slot.
  Ink2.rrect(c, const Rect.fromLTWH(-32, -44, 64, 14), 6, Ink2.fill(rim));
  Ink2.rrect(c, const Rect.fromLTWH(-14, -40, 28, 5), 2.5, Ink2.fill(Colors.black.withValues(alpha: 0.45)));
  // Label: TIPS.
  Ink2.rrect(c, const Rect.fromLTWH(-24, 0, 48, 20), 5, Ink2.fill(Colors.white.withValues(alpha: 0.92)));
  final tp = TextPainter(
    text: const TextSpan(text: 'TIPS', style: TextStyle(fontFamily: 'Roboto', color: billDeep, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, Offset(-tp.width / 2, 10 - tp.height / 2));
  c.restore();
}

/// A coin falling along a little arc into a point, at progress t (0..1).
void _fallingCoin(Canvas c, Offset from, Offset to, double t, double r) {
  if (t <= 0 || t >= 1) return;
  final p = Offset.lerp(from, to, t)! + Offset(0, -math.sin(t * math.pi) * 30);
  Ink2.coin(c, p, r, gold, goldDeep, turn: t * 2);
}

void _bill(Canvas c, Offset o, double w, double angle, {Color color = billGreen}) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(angle);
  final r = Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.48);
  Ink2.rrect(c, r, w * 0.06, Ink2.fill(color));
  Ink2.rrect(c, r.deflate(w * 0.06), w * 0.04, Ink2.stroke(Colors.white.withValues(alpha: 0.55), w * 0.025));
  c.drawCircle(Offset.zero, w * 0.13, Ink2.stroke(Colors.white.withValues(alpha: 0.75), w * 0.03));
  c.restore();
}

/// Onboarding 1: coins and bills drop into the jar as it fills.
void fillJarScene(Canvas c, Size s, SceneFrame f) {
  final cx = s.width / 2, cy = s.height * 0.58, u = s.shortestSide;
  Ink2.glow(c, Offset(cx, cy), u * 0.45, f.scheme.primary.withValues(alpha: 0.25));
  final fill = 0.25 + 0.45 * _ease(f.intro) + 0.05 * f.wave();
  tipJar(c, Offset(cx, cy), u * 0.55, f, fill: fill, wobble: f.wave(0.3));
  for (var i = 0; i < 3; i++) {
    final t = (f.loop * 1.0 + i / 3) % 1.0;
    _fallingCoin(c, Offset(cx + (i - 1) * u * 0.28, cy - u * 0.5), Offset(cx, cy - u * 0.22), t, u * 0.045);
  }
  _bill(c, Offset(cx - u * 0.32, cy - u * 0.32 + f.wave() * 6), u * 0.2, -0.3 + f.wave(0.2) * 0.1);
  Ink2.sparkle(c, Offset(cx + u * 0.34, cy - u * 0.36), u * 0.04 * (0.6 + 0.4 * f.wave(0.5).abs()), gold);
}

/// Onboarding 2: tip-out. Coins hop from the big jar into two small cups.
void tipOutScene(Canvas c, Size s, SceneFrame f) {
  final u = s.shortestSide, cy = s.height * 0.62;
  final big = Offset(s.width * 0.33, cy), cupA = Offset(s.width * 0.72, cy - u * 0.12), cupB = Offset(s.width * 0.78, cy + u * 0.16);
  tipJar(c, big, u * 0.5, f, fill: 0.6, wobble: f.wave() * 0.5);
  for (final (o, label) in [(cupA, 'BAR'), (cupB, 'BUS')]) {
    final r = Rect.fromCenter(center: o, width: u * 0.18, height: u * 0.16);
    Ink2.rrect(c, r, u * 0.03, Ink2.fill(f.dark ? f.scheme.surfaceContainerHighest : Colors.white));
    Ink2.rrect(c, r, u * 0.03, Ink2.stroke(f.scheme.primary, 2.5));
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontFamily: 'Roboto', color: f.scheme.primary, fontSize: u * 0.045, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }
  _fallingCoin(c, big - Offset(0, u * 0.2), cupA - Offset(0, u * 0.09), f.loop, u * 0.04);
  _fallingCoin(c, big - Offset(0, u * 0.2), cupB - Offset(0, u * 0.09), (f.loop + 0.5) % 1, u * 0.04);
  // Percent badge.
  final b = Offset(s.width * 0.55, s.height * 0.2);
  c.drawCircle(b, u * 0.09 * _ease(f.intro), Ink2.fill(gold));
  final tp = TextPainter(
    text: TextSpan(text: '%', style: TextStyle(fontFamily: 'Roboto', color: billDeep, fontSize: u * 0.1 * _ease(f.intro), fontWeight: FontWeight.w900)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, b - Offset(tp.width / 2, tp.height / 2));
}

/// Onboarding 3 and Backup screen: the jar safe inside a shield, with a
/// circular arrow turning round it (copies being made).
void safeJarScene(Canvas c, Size s, SceneFrame f) {
  final u = s.shortestSide, o = Offset(s.width / 2, s.height * 0.54);
  final shield = Path()
    ..moveTo(o.dx, o.dy - u * 0.42)
    ..quadraticBezierTo(o.dx + u * 0.3, o.dy - u * 0.36, o.dx + u * 0.34, o.dy - u * 0.3)
    ..quadraticBezierTo(o.dx + u * 0.34, o.dy + u * 0.18, o.dx, o.dy + u * 0.4)
    ..quadraticBezierTo(o.dx - u * 0.34, o.dy + u * 0.18, o.dx - u * 0.34, o.dy - u * 0.3)
    ..quadraticBezierTo(o.dx - u * 0.3, o.dy - u * 0.36, o.dx, o.dy - u * 0.42)
    ..close();
  final grow = _ease(f.intro);
  c.save();
  c.translate(o.dx, o.dy);
  c.scale(0.6 + 0.4 * grow);
  c.translate(-o.dx, -o.dy);
  c.drawPath(
    shield,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [f.scheme.primary, f.brand.gradient.last],
      ).createShader(shield.getBounds()),
  );
  c.restore();
  tipJar(c, o + Offset(0, u * 0.02), u * 0.36, f, fill: 0.55, wobble: f.wave() * 0.3, coins: 5);
  // Turning arrow.
  final r = u * 0.46;
  final start = f.loop * 2 * math.pi;
  c.drawArc(Rect.fromCircle(center: o, radius: r), start, math.pi * 1.4 * grow, false, Ink2.stroke(gold, u * 0.025)..strokeCap = StrokeCap.round);
  final end = start + math.pi * 1.4 * grow;
  final tip = o + Offset(math.cos(end), math.sin(end)) * r;
  final dir = Offset(-math.sin(end), math.cos(end));
  final side = Offset(math.cos(end), math.sin(end));
  c.drawPath(
    Path()
      ..moveTo(tip.dx + dir.dx * u * 0.05, tip.dy + dir.dy * u * 0.05)
      ..lineTo(tip.dx + side.dx * u * 0.035, tip.dy + side.dy * u * 0.035)
      ..lineTo(tip.dx - side.dx * u * 0.035, tip.dy - side.dy * u * 0.035)
      ..close(),
    Ink2.fill(gold),
  );
}

/// Empty Shifts tab: an empty jar with a single coin bobbing above.
void emptyJarScene(Canvas c, Size s, SceneFrame f) {
  final u = s.shortestSide, o = Offset(s.width / 2, s.height * 0.6);
  tipJar(c, o, u * 0.55, f, fill: 0.04, coins: 0, wobble: f.wave() * 0.4);
  final y = o.dy - u * 0.42 + f.wave() * u * 0.03;
  Ink2.coin(c, Offset(o.dx, y), u * 0.06, gold, goldDeep, turn: f.loop);
  Ink2.sparkle(c, Offset(o.dx + u * 0.12, y - u * 0.05), u * 0.025, gold);
}

/// Jobs: an apron with a pocket of bills and a tray.
void jobScene(Canvas c, Size s, SceneFrame f) {
  final u = s.shortestSide, o = Offset(s.width / 2, s.height * 0.55);
  final apron = Path()
    ..moveTo(o.dx - u * 0.18, o.dy - u * 0.3)
    ..lineTo(o.dx + u * 0.18, o.dy - u * 0.3)
    ..lineTo(o.dx + u * 0.26, o.dy + u * 0.32)
    ..lineTo(o.dx - u * 0.26, o.dy + u * 0.32)
    ..close();
  c.drawPath(apron, Ink2.fill(f.dark ? const Color(0xFF37474F) : const Color(0xFF263238)));
  c.drawLine(o + Offset(-u * 0.32, -u * 0.12), o + Offset(u * 0.32, -u * 0.12), Ink2.stroke(gold, u * 0.03));
  final pocket = Rect.fromCenter(center: o + Offset(0, u * 0.12), width: u * 0.3, height: u * 0.16);
  final rise = _ease(f.intro) * u * 0.08 + f.wave() * u * 0.01;
  _bill(c, pocket.topCenter + Offset(-u * 0.05, -rise * 0.6), u * 0.18, -0.25);
  _bill(c, pocket.topCenter + Offset(u * 0.04, -rise), u * 0.18, 0.2, color: const Color(0xFF66BB6A));
  Ink2.rrect(c, pocket, u * 0.02, Ink2.fill(f.dark ? const Color(0xFF455A64) : const Color(0xFF37474F)));
  // Tray.
  final t = o + Offset(u * 0.3, -u * 0.34 + f.wave(0.25) * u * 0.02);
  c.drawOval(Rect.fromCenter(center: t, width: u * 0.3, height: u * 0.07), Ink2.fill(const Color(0xFFB0BEC5)));
  c.drawCircle(t - Offset(u * 0.05, u * 0.06), u * 0.045, Ink2.fill(const Color(0xFFFFE082)));
  c.drawRect(Rect.fromCenter(center: t + Offset(u * 0.06, -u * 0.07), width: u * 0.05, height: u * 0.11), Ink2.fill(const Color(0xFFEF9A9A)));
}

/// Paywall / Pro: a crown of coins over the jar.
void proScene(Canvas c, Size s, SceneFrame f) {
  final u = s.shortestSide, o = Offset(s.width / 2, s.height * 0.62);
  tipJar(c, o, u * 0.5, f, fill: 0.85, wobble: f.wave() * 0.3);
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + (i - 2) * 0.42;
    final p = o + Offset(math.cos(a), math.sin(a)) * u * 0.42 * _ease(f.intro);
    Ink2.coin(c, p, u * 0.045, gold, goldDeep, turn: f.loop + i * 0.1);
  }
}

/// App logo on a 512 grid, drawn to match brand/logo.svg (the launcher
/// icon): a glass jar half full of gold, the tips swaying, and a gold coin
/// dropping into the lid's slot.
void tipLogo(Canvas c, Size size, SceneFrame f) {
  c.save();
  c.scale(size.width / 512, size.height / 512);
  c.drawRect(
    const Rect.fromLTWH(0, 0, 512, 512),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E7D32), Color(0xFF00695C)],
      ).createShader(const Rect.fromLTWH(0, 0, 512, 512)),
  );
  c.translate(256, 270);
  c.scale(0.92);
  c.translate(-256, -270);
  final jar = RRect.fromRectAndCorners(
    const Rect.fromLTWH(146, 196, 220, 236),
    topLeft: const Radius.circular(36),
    topRight: const Radius.circular(36),
    bottomLeft: const Radius.circular(62),
    bottomRight: const Radius.circular(62),
  );
  c.drawRRect(jar, Ink2.fill(Colors.white.withValues(alpha: 0.18)));
  c.save();
  c.clipRRect(jar);
  // The gold surface sways side to side; at rest it is the logo's wave.
  final sway = 12 * f.wave();
  final top = Path()
    ..moveTo(140, 318)
    ..cubicTo(190, 298 + sway, 230, 336 - sway, 270, 318)
    ..cubicTo(310, 300 + sway, 340, 330 - sway, 372, 316);
  final liquid = Path.from(top)
    ..lineTo(372, 440)
    ..lineTo(140, 440)
    ..close();
  c.drawPath(liquid, Ink2.fill(gold));
  c.drawPath(top, Ink2.stroke(const Color(0xFFFFE082), 8));
  final rise = 10 * f.wave(0.5);
  c.drawCircle(Offset(206, 380 - rise), 18, Ink2.fill(const Color(0xCCFFE082)));
  c.drawCircle(Offset(290, 398 + rise), 14, Ink2.fill(const Color(0x99FFE082)));
  c.restore();
  c.drawRRect(jar, Ink2.stroke(Colors.white, 18));
  Ink2.rrect(c, const Rect.fromLTWH(130, 150, 252, 46), 18, Ink2.fill(Colors.white));
  Ink2.rrect(c, const Rect.fromLTWH(206, 164, 100, 16), 8, Ink2.fill(const Color(0xFF1B5E20)));
  // The coin drops in on first show, then bobs over the slot.
  final drop = f.intro < 1 ? _ease(f.intro) : 1.0;
  final cy = 90 - 120 * (1 - drop) + 6 * f.wave(0.5);
  c.drawCircle(Offset(256, cy + 6), 48, Ink2.fill(goldDeep));
  c.drawCircle(
    Offset(256, cy),
    44,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.8,
        colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
      ).createShader(Rect.fromCircle(center: Offset(256, cy), radius: 44)),
  );
  c.drawCircle(Offset(256, cy), 32, Ink2.stroke(const Color(0xFFFFF3C4), 6));
  // A drawn dollar sign, so it looks the same with or without fonts.
  final ink = Ink2.stroke(const Color(0xFF1B5E20), 7)..strokeCap = StrokeCap.round;
  final dollar = Path()
    ..moveTo(268, cy - 12)
    ..cubicTo(264, cy - 20, 246, cy - 21, 244, cy - 11)
    ..cubicTo(242, cy - 2, 252, cy - 1, 257, cy + 1)
    ..cubicTo(264, cy + 3, 271, cy + 7, 268, cy + 14)
    ..cubicTo(265, cy + 22, 246, cy + 21, 243, cy + 13);
  c.drawPath(dollar, ink);
  c.drawLine(Offset(256, cy - 26), Offset(256, cy + 27), ink);
  c.restore();
}
