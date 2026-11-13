// Wagebird's illustrations, drawn in code so they scale, theme and move.
import 'dart:math' as math;

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

const _amber = Color(0xFFFFB300);
const _amberDark = Color(0xFFC77C02);

void _clockFace(Canvas c, Offset o, double r, SceneFrame f, {required double minuteTurns, double second = 0}) {
  final s = f.scheme;
  c.drawCircle(o.translate(0, r * 0.08), r, Ink2.fill(Colors.black.withValues(alpha: f.dark ? 0.35 : 0.12)));
  c.drawCircle(o, r, Ink2.fill(f.dark ? s.surfaceContainerHigh : Colors.white));
  c.drawCircle(o, r, Ink2.stroke(s.primary, r * 0.1));
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    final len = i % 3 == 0 ? r * 0.16 : r * 0.08;
    final p1 = o + Offset(math.sin(a), -math.cos(a)) * (r * 0.78);
    final p2 = o + Offset(math.sin(a), -math.cos(a)) * (r * 0.78 - len);
    c.drawLine(p1, p2, Ink2.stroke(s.onSurfaceVariant.withValues(alpha: 0.6), i % 3 == 0 ? 3 : 2));
  }
  final ma = minuteTurns * 2 * math.pi;
  final ha = minuteTurns * 2 * math.pi / 12 + 10 * math.pi / 6;
  c.drawLine(o, o + Offset(math.sin(ha), -math.cos(ha)) * (r * 0.45), Ink2.stroke(s.onSurface, r * 0.09));
  c.drawLine(o, o + Offset(math.sin(ma), -math.cos(ma)) * (r * 0.66), Ink2.stroke(s.primary, r * 0.065));
  final sa = second * 2 * math.pi;
  c.drawLine(o, o + Offset(math.sin(sa), -math.cos(sa)) * (r * 0.7), Ink2.stroke(_amber, r * 0.03));
  c.drawCircle(o, r * 0.07, Ink2.fill(_amber));
}

/// Wagebird's mascot: a round little bird. [flap] is 0 (wing folded) to 1
/// (wing up); [facing] -1 turns it to look left.
void wagebird(Canvas c, Offset o, double size, SceneFrame f, {double flap = 0, double facing = 1, double bob = 0}) {
  if (size <= 1) return;
  final body = f.dark ? const Color(0xFF4DD0C1) : const Color(0xFF00897B);
  final deep = Color.lerp(body, Colors.black, 0.25)!;
  c.save();
  c.translate(o.dx, o.dy + bob);
  c.scale(facing * size / 100, size / 100);
  // Legs.
  final leg = Ink2.stroke(_amberDark, 4);
  c.drawLine(const Offset(-8, 30), const Offset(-10, 44), leg);
  c.drawLine(const Offset(8, 30), const Offset(10, 44), leg);
  // Tail.
  c.drawPath(
    Path()
      ..moveTo(-34, 4)
      ..lineTo(-58, -8)
      ..lineTo(-54, 14)
      ..close(),
    Ink2.fill(deep),
  );
  // Body and belly.
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: 80, height: 70), Ink2.fill(body));
  c.drawOval(Rect.fromCenter(center: const Offset(10, 12), width: 48, height: 40), Ink2.fill(const Color(0xFFFFF3D6)));
  // Wing, hinged at the shoulder.
  c.save();
  c.translate(-6, -4);
  c.rotate(-flap * 1.1);
  c.drawPath(
    Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-30, 2, -36, 22)
      ..quadraticBezierTo(-10, 24, 6, 10)
      ..close(),
    Ink2.fill(deep),
  );
  c.restore();
  // Eye and beak.
  c.drawCircle(const Offset(20, -12), 8, Ink2.fill(Colors.white));
  c.drawCircle(const Offset(22, -12), 4.5, Ink2.fill(const Color(0xFF1B1B1F)));
  c.drawCircle(const Offset(23.5, -13.5), 1.5, Ink2.fill(Colors.white));
  c.drawPath(
    Path()
      ..moveTo(36, -8)
      ..lineTo(52, -2)
      ..lineTo(36, 4)
      ..close(),
    Ink2.fill(_amber),
  );
  // Cheek.
  c.drawCircle(const Offset(26, 4), 5, Ink2.fill(const Color(0xFFFF8A80).withValues(alpha: 0.6)));
  c.restore();
}

/// A quick double flap a few times per loop.
double _flapAt(double loop, [double offset = 0]) {
  final t = (loop * 3 + offset) % 1;
  return t < 0.2 ? math.sin(t / 0.2 * 2 * math.pi).abs() : 0;
}

/// Onboarding 1: a clock winds forward while coins drop onto a stack.
void clockScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  Ink2.glow(c, Offset(w * 0.45, h * 0.45), w * 0.48, f.scheme.primary.withValues(alpha: 0.18));
  paintSparkField(c, s, f, _amber, count: 6, seed: 2);
  final pop = phase(f.intro, 0, 0.45, Curves.easeOutBack);
  final o = Offset(w * 0.42, h * 0.44);
  final r = w * 0.27 * pop;
  if (r > 1) {
    _clockFace(
      c,
      o,
      r,
      f,
      minuteTurns: 1.5 * phase(f.intro, 0.1, 0.9, Curves.easeInOutCubic) + f.loop * 0.08,
      second: f.loop * 6 % 1,
    );
  }
  // The bird hops onto the top of the clock.
  final hop = phase(f.intro, 0.55, 0.85, Curves.easeOutBack);
  if (hop > 0) {
    final perch = o.translate(0, -w * 0.27 - w * 0.085);
    final from = perch.translate(w * 0.4, -h * 0.3);
    final p = Offset.lerp(from, perch, hop)!;
    wagebird(c, p, w * 0.2, f, flap: hop < 1 ? (1 - hop) : _flapAt(f.loop), bob: -2 * _flapAt(f.loop).abs());
  }
  // Timesheet card peeking from behind.
  final card = Rect.fromLTWH(w * 0.08, h * 0.66, w * 0.34, h * 0.22);
  final cardIn = phase(f.intro, 0.3, 0.7);
  if (cardIn > 0) {
    c.save();
    c.translate(0, (1 - cardIn) * h * 0.1);
    Ink2.rrect(c, card, 10, Ink2.fill(f.dark ? f.scheme.surfaceContainerHighest : f.scheme.primaryContainer));
    for (var i = 0; i < 3; i++) {
      final y = card.top + card.height * (0.28 + i * 0.24);
      final len = card.width * (0.7 - i * 0.12) * phase(f.intro, 0.45 + i * 0.08, 0.8 + i * 0.05);
      c.drawLine(Offset(card.left + 12, y), Offset(card.left + 12 + len, y), Ink2.stroke(f.scheme.primary, 4));
    }
    c.restore();
  }
  // Coins.
  final base = Offset(w * 0.76, h * 0.84);
  Ink2.shadow(c, base.translate(0, 6), w * 0.2, Colors.black);
  for (var i = 0; i < 4; i++) {
    final drop = phase(f.intro, 0.4 + i * 0.1, 0.65 + i * 0.1, Curves.bounceOut);
    if (drop <= 0) continue;
    final target = base.translate(0, -i * w * 0.045);
    final from = target.translate(0, -h * 0.6);
    final p = Offset.lerp(from, target, drop)!;
    c.drawOval(
      Rect.fromCenter(center: p.translate(0, w * 0.018), width: w * 0.2, height: w * 0.07),
      Ink2.fill(_amberDark),
    );
    c.drawOval(Rect.fromCenter(center: p, width: w * 0.2, height: w * 0.07), Ink2.fill(_amber));
  }
  // A spinning coin on top.
  final top = phase(f.intro, 0.85, 1, Curves.easeOutBack);
  if (top > 0) {
    Ink2.coin(c, base.translate(0, -w * 0.25 + 4 * f.wave()), w * 0.075 * top, _amber, _amberDark, turn: f.loop * 2);
  }
}

/// Onboarding 2: a week of bars rises; long days glow into overtime.
void overtimeScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  Ink2.glow(c, Offset(w * 0.6, h * 0.4), w * 0.5, _amber.withValues(alpha: 0.16));
  final base = h * 0.8;
  const days = [0.45, 0.55, 0.5, 0.82, 0.48, 0.95, 0.35];
  const otAt = 0.6, dtAt = 0.85;
  final slot = w * 0.8 / days.length;
  final x0 = w * 0.1;
  c.drawLine(Offset(x0 - 6, base), Offset(w * 0.92, base), Ink2.stroke(f.scheme.outlineVariant, 3));
  final tops = <Offset>[];
  for (var i = 0; i < days.length; i++) {
    final grow = phase(f.intro, 0.05 + i * 0.07, 0.5 + i * 0.07, Curves.easeOutBack);
    final full = days[i] * h * 0.62;
    final hh = full * grow;
    final left = x0 + slot * i + slot * 0.18;
    final bw = slot * 0.64;
    final reg = math.min(hh, otAt * h * 0.62);
    Ink2.rrect(c, Rect.fromLTWH(left, base - reg, bw, reg), 6, Ink2.fill(f.scheme.primary));
    if (hh > otAt * h * 0.62) {
      final ot = math.min(hh, dtAt * h * 0.62) - otAt * h * 0.62;
      Ink2.rrect(c, Rect.fromLTWH(left, base - reg - ot, bw, ot + 4), 6, Ink2.fill(_amber));
      if (hh > dtAt * h * 0.62) {
        final dt = hh - dtAt * h * 0.62;
        Ink2.rrect(c, Rect.fromLTWH(left, base - reg - ot - dt, bw, dt + 4), 6, Ink2.fill(f.brand.warning));
      }
    }
    tops.add(Offset(left + bw / 2, base - hh - 14));
  }
  // The overtime line, traced after the bars land.
  final limitY = base - otAt * h * 0.62;
  final dash = phase(f.intro, 0.55, 0.85);
  for (var x = x0; x < x0 + (w * 0.82) * dash; x += 14) {
    c.drawLine(Offset(x, limitY), Offset(x + 7, limitY), Ink2.stroke(_amber, 2.5));
  }
  // Badges on the long days.
  final tp = TextPainter(textDirection: TextDirection.ltr);
  for (final (i, label, col) in [(3, '1.5×', _amber), (5, '2×', f.brand.warning)]) {
    final b = phase(f.intro, 0.7 + i * 0.03, 0.95, Curves.easeOutBack);
    if (b <= 0) continue;
    final p = tops[i].translate(0, -10 + 3 * f.wave(i / 7));
    c.drawCircle(p, 17 * b, Ink2.fill(col));
    tp.text = TextSpan(
      text: label,
      style: TextStyle(color: Colors.white, fontSize: 12 * b, fontWeight: FontWeight.w800),
    );
    tp.layout();
    tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
  }
  paintSparkField(c, s, f, _amber, count: 5, seed: 9);
}

/// Onboarding 3: a phone with a shield; the cloud is crossed out.
void privacyScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  final o = Offset(w * 0.5, h * 0.5);
  Ink2.glow(c, o, w * 0.45, f.scheme.primary.withValues(alpha: 0.2));
  final up = phase(f.intro, 0, 0.5, Curves.easeOutBack);
  final phone = Rect.fromCenter(center: o.translate(0, (1 - up) * h * 0.3), width: w * 0.36, height: h * 0.62);
  Ink2.rrect(c, phone.shift(const Offset(0, 6)), 26, Ink2.fill(Colors.black.withValues(alpha: 0.15)));
  Ink2.rrect(c, phone, 26, Ink2.fill(f.dark ? f.scheme.surfaceContainerHighest : f.scheme.onSurface));
  final screen = phone.deflate(8);
  Ink2.rrect(c, screen, 20, Paint()..shader = f.brand.linear.createShader(screen));
  // Shield and lock.
  final sh = phase(f.intro, 0.35, 0.75, Curves.easeOutBack);
  final sc = screen.center.translate(0, 2 * f.wave());
  final r = screen.width * 0.32 * sh;
  if (r > 1) {
    final shield = Path()
      ..moveTo(sc.dx, sc.dy - r)
      ..quadraticBezierTo(sc.dx + r * 0.9, sc.dy - r * 0.85, sc.dx + r * 0.9, sc.dy - r * 0.55)
      ..quadraticBezierTo(sc.dx + r * 0.8, sc.dy + r * 0.6, sc.dx, sc.dy + r)
      ..quadraticBezierTo(sc.dx - r * 0.8, sc.dy + r * 0.6, sc.dx - r * 0.9, sc.dy - r * 0.55)
      ..quadraticBezierTo(sc.dx - r * 0.9, sc.dy - r * 0.85, sc.dx, sc.dy - r)
      ..close();
    c.drawPath(shield, Ink2.fill(Colors.white.withValues(alpha: 0.95)));
    Ink2.rrect(
      c,
      Rect.fromCenter(center: sc.translate(0, r * 0.15), width: r * 0.8, height: r * 0.6),
      4,
      Ink2.fill(f.scheme.primary),
    );
    c.drawArc(
      Rect.fromCenter(center: sc.translate(0, -r * 0.15), width: r * 0.5, height: r * 0.6),
      math.pi,
      math.pi,
      false,
      Ink2.stroke(f.scheme.primary, r * 0.12),
    );
  }
  // Orbiting dots.
  for (var i = 0; i < 3; i++) {
    final a = (f.loop + i / 3) * 2 * math.pi;
    final p = o + Offset(math.cos(a) * w * 0.36, math.sin(a) * h * 0.12);
    c.drawCircle(p, 5 * up, Ink2.fill(i == 0 ? _amber : f.scheme.primary.withValues(alpha: 0.6)));
  }
  final perch = phase(f.intro, 0.5, 0.8, Curves.easeOutBack);
  if (perch > 0) {
    wagebird(
      c,
      Offset(phone.right - w * 0.02, phone.top - w * 0.06),
      w * 0.15 * perch,
      f,
      facing: -1,
      flap: _flapAt(f.loop, 0.5),
    );
  }
  // Crossed-out cloud.
  final cl = phase(f.intro, 0.6, 0.95);
  if (cl > 0) {
    final cc = Offset(w * 0.8, h * 0.18);
    final p = Ink2.fill(f.scheme.outline.withValues(alpha: 0.5 * cl));
    c.drawCircle(cc, w * 0.06, p);
    c.drawCircle(cc.translate(-w * 0.06, w * 0.025), w * 0.045, p);
    c.drawCircle(cc.translate(w * 0.06, w * 0.025), w * 0.045, p);
    c.drawRect(Rect.fromLTRB(cc.dx - w * 0.06, cc.dy, cc.dx + w * 0.06, cc.dy + w * 0.07), p);
    c.drawLine(
      cc.translate(-w * 0.1, -w * 0.07),
      cc.translate(-w * 0.1 + w * 0.2 * cl, -w * 0.07 + w * 0.17 * cl),
      Ink2.stroke(f.brand.warning, 5),
    );
  }
}

/// Empty state before the first job: a briefcase with a clock badge.
void jobScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  final o = Offset(w * 0.5, h * 0.55 + 4 * f.wave());
  Ink2.glow(c, o, w * 0.45, f.scheme.primary.withValues(alpha: 0.18));
  final pop = phase(f.intro, 0, 0.55, Curves.easeOutBack);
  Ink2.shadow(c, Offset(w * 0.5, h * 0.86), w * 0.5 * pop, Colors.black);
  final body = Rect.fromCenter(center: o, width: w * 0.6 * pop, height: h * 0.4 * pop);
  if (body.width < 2) return;
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: body.topCenter, width: body.width * 0.36, height: body.height * 0.3),
      const Radius.circular(10),
    ),
    Ink2.stroke(f.scheme.primary, 7 * pop),
  );
  Ink2.rrect(c, body, 18, Paint()..shader = f.brand.linear.createShader(body));
  c.drawLine(
    Offset(body.left, body.center.dy - 6),
    Offset(body.right, body.center.dy - 6),
    Ink2.stroke(Colors.white.withValues(alpha: 0.35), 3),
  );
  Ink2.rrect(
    c,
    Rect.fromCenter(center: body.center.translate(0, -6), width: 22 * pop, height: 16 * pop),
    4,
    Ink2.fill(_amber),
  );
  final badge = phase(f.intro, 0.45, 0.9, Curves.easeOutBack);
  if (badge > 0) {
    _clockFace(
      c,
      Offset(body.right - 6, body.top + 4),
      w * 0.12 * badge,
      f,
      minuteTurns: phase(f.intro, 0.5, 1) + f.loop * 0.2,
      second: f.loop * 3 % 1,
    );
  }
  paintSparkField(c, s, f, _amber, count: 5, seed: 4);
}

/// Empty week: the sun and moon take turns crossing over a week strip.
void quietWeekScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  final base = h * 0.78;
  final strip = phase(f.intro, 0, 0.6);
  for (var i = 0; i < 7; i++) {
    final x = w * 0.14 + i * w * 0.12;
    final hh = h * 0.12 * phase(f.intro, i * 0.05, 0.5 + i * 0.05, Curves.easeOutBack);
    Ink2.rrect(
      c,
      Rect.fromCenter(center: Offset(x, base - hh / 2), width: w * 0.07, height: math.max(hh, 2)),
      4,
      Ink2.fill(f.scheme.primary.withValues(alpha: 0.25 + 0.1 * (i % 2))),
    );
  }
  c.drawLine(
    Offset(w * 0.08, base + 4),
    Offset(w * 0.08 + w * 0.84 * strip, base + 4),
    Ink2.stroke(f.scheme.outlineVariant, 3),
  );
  // Arc path across the sky.
  final t = (phase(f.intro, 0.2, 1) * 0.5 + f.loop) % 1;
  final day = t < 0.5;
  final k = day ? t * 2 : (t - 0.5) * 2;
  final a = math.pi * (1 - k);
  final p = Offset(w / 2 + math.cos(a) * w * 0.36, base - 10 - math.sin(a) * h * 0.52);
  if (day) {
    Ink2.glow(c, p, w * 0.12, _amber.withValues(alpha: 0.4));
    c.drawCircle(p, w * 0.055, Ink2.fill(_amber));
  } else {
    c.drawCircle(p, w * 0.05, Ink2.fill(f.dark ? Colors.white : const Color(0xFF5C6BC0)));
    c.drawCircle(
      p.translate(w * 0.022, -w * 0.012),
      w * 0.045,
      Ink2.fill(f.dark ? f.scheme.surface : f.scheme.surface),
    );
    paintSparkField(c, Size(w, h * 0.5), f, f.dark ? Colors.white : const Color(0xFF5C6BC0), count: 5, seed: 8);
  }
}

/// Paywall: a timesheet fills in, gets a PDF tab and a star.
void timesheetProScene(Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  final o = Offset(w * 0.5, h * 0.52);
  Ink2.glow(c, o, h * 0.6, _amber.withValues(alpha: 0.22));
  final up = phase(f.intro, 0, 0.5, Curves.easeOutBack);
  final sheet = Rect.fromCenter(
    center: o.translate(0, (1 - up) * h * 0.4 + 3 * f.wave()),
    width: h * 0.62,
    height: h * 0.78,
  );
  c.save();
  c.translate(sheet.center.dx, sheet.center.dy);
  c.rotate(-0.06);
  c.translate(-sheet.center.dx, -sheet.center.dy);
  Ink2.rrect(c, sheet.shift(const Offset(0, 6)), 14, Ink2.fill(Colors.black.withValues(alpha: 0.12)));
  Ink2.rrect(c, sheet, 14, Ink2.fill(f.dark ? f.scheme.surfaceContainerHighest : Colors.white));
  final head = Rect.fromLTWH(sheet.left, sheet.top, sheet.width, sheet.height * 0.2);
  c.drawRRect(
    RRect.fromRectAndCorners(head, topLeft: const Radius.circular(14), topRight: const Radius.circular(14)),
    Paint()..shader = f.brand.linear.createShader(head),
  );
  for (var i = 0; i < 5; i++) {
    final y = sheet.top + sheet.height * (0.32 + i * 0.13);
    final fill = phase(f.intro, 0.3 + i * 0.08, 0.6 + i * 0.08);
    c.drawLine(
      Offset(sheet.left + 12, y),
      Offset(sheet.left + 12 + sheet.width * 0.45 * fill, y),
      Ink2.stroke(f.scheme.outlineVariant, 5),
    );
    c.drawLine(
      Offset(sheet.right - 12 - sheet.width * 0.22 * fill, y),
      Offset(sheet.right - 12, y),
      Ink2.stroke(i == 4 ? _amber : f.scheme.primary, 5),
    );
  }
  c.restore();
  final tab = phase(f.intro, 0.65, 0.95, Curves.easeOutBack);
  if (tab > 0) {
    final r = Rect.fromCenter(
      center: Offset(sheet.right + 4, sheet.top + sheet.height * 0.3),
      width: 56 * tab,
      height: 28 * tab,
    );
    Ink2.rrect(c, r, 8, Ink2.fill(f.brand.warning));
    final tp = TextPainter(
      text: TextSpan(
        text: 'PDF',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13 * tab),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, r.center - Offset(tp.width / 2, tp.height / 2));
  }
  final star = phase(f.intro, 0.8, 1, Curves.easeOutBack);
  Ink2.sparkle(c, Offset(sheet.left - 8, sheet.top + 10), 18 * star * (0.85 + 0.15 * f.wave()), _amber);
  Ink2.coin(c, Offset(sheet.left - 4, sheet.bottom - 12), 18 * star, _amber, _amberDark, turn: f.loop * 2);
  final fly = phase(f.intro, 0.55, 1, Curves.easeOutCubic);
  if (fly > 0) {
    final p = Offset.lerp(Offset(w * 1.1, h * 0.05), Offset(sheet.right + h * 0.32, sheet.top + h * 0.12), fly)!;
    final flap = (math.sin((f.loop * 8 + f.intro * 6) * 2 * math.pi) + 1) / 2;
    wagebird(c, p.translate(0, 4 * f.wave()), h * 0.26, f, facing: -1, flap: flap);
  }
  paintSparkField(c, s, f, _amber, count: 7, seed: 12);
}

/// The week's hero: a sky that runs from sunrise to sunset as the week's hours
/// add up ([progress] 0 to 1), the bird flapping along its flight path, and a
/// coin for each shift ([coins]) dropping into the nest with a bounce.
ScenePaint weekHeroScene({required double progress, required int coins}) => (Canvas c, Size s, SceneFrame f) {
  final w = s.width, h = s.height;
  final p = progress.clamp(0.0, 1.0) * phase(f.intro, 0, 0.6);
  // Sky: dawn blue and peach, through midday, to a warm sunset.
  const dawn = [Color(0xFF7FB3E8), Color(0xFFFFD1A6)];
  const noon = [Color(0xFF4FA3E0), Color(0xFFBFE6F5)];
  const dusk = [Color(0xFF6A4C93), Color(0xFFFF8A65)];
  Color mix(int i) => p < 0.5 ? Color.lerp(dawn[i], noon[i], p * 2)! : Color.lerp(noon[i], dusk[i], (p - 0.5) * 2)!;
  final sky = Offset.zero & s;
  c.drawRect(sky, Paint()..shader = LinearGradient(colors: [mix(0), mix(1)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(sky));
  // The sun climbs and sets along an arc.
  final sun = Offset(w * (0.08 + 0.84 * p), h * (0.78 - 0.55 * math.sin(p * math.pi)));
  Ink2.glow(c, sun, h * 0.5, const Color(0xFFFFE082).withValues(alpha: 0.7));
  c.drawCircle(sun, h * 0.12, Ink2.fill(Color.lerp(const Color(0xFFFFE082), const Color(0xFFFF7043), (p - 0.6).clamp(0, 0.4) / 0.4)!));
  // Drifting clouds.
  for (var i = 0; i < 2; i++) {
    final x = ((f.loop + i * 0.5) % 1) * (w + 80) - 40;
    final y = h * (0.2 + i * 0.18);
    final cl = Ink2.fill(Colors.white.withValues(alpha: 0.75));
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 46, height: 16), cl);
    c.drawCircle(Offset(x - 6, y - 6), 9, cl);
    c.drawCircle(Offset(x + 8, y - 4), 7, cl);
  }
  // Rolling hills.
  final hills = Path()
    ..moveTo(0, h)
    ..lineTo(0, h * 0.82)
    ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.5, h * 0.8)
    ..quadraticBezierTo(w * 0.75, h * 0.95, w, h * 0.74)
    ..lineTo(w, h)
    ..close();
  c.drawPath(hills, Paint()..shader = const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00695C)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(sky));
  // The nest, with a coin per shift dropping in.
  final nest = Offset(w * 0.86, h * 0.8);
  final shown = coins.clamp(0, 6);
  for (var i = 0; i < shown; i++) {
    final start = 0.45 + i * 0.07;
    final t = phase(f.intro, start, math.min(1, start + 0.2), Curves.bounceOut);
    final rest = nest + Offset((i % 3 - 1) * 9.0, -6.0 - (i ~/ 3) * 7);
    final pos = Offset(rest.dx, rest.dy - (1 - t) * h * 0.8);
    if (t <= 0) continue;
    final spin = math.cos((f.loop * 2 + i * 0.2) * 2 * math.pi);
    c.drawOval(Rect.fromCenter(center: pos, width: 12 * (0.35 + 0.65 * spin.abs()), height: 12),
        Paint()..shader = const RadialGradient(colors: [Color(0xFFFFE082), Color(0xFFFFA000)]).createShader(Rect.fromCircle(center: pos, radius: 6)));
  }
  final twig = Ink2.stroke(const Color(0xFF8D6E63), 3);
  c.drawArc(Rect.fromCenter(center: nest, width: 40, height: 22), 0.1, math.pi - 0.2, false, twig);
  c.drawArc(Rect.fromCenter(center: nest.translate(0, 2), width: 34, height: 16), 0.2, math.pi - 0.4, false, Ink2.stroke(const Color(0xFFA1887F), 2.5));
  // The bird follows a wavy path across the sky, then glides on its loop.
  final along = f.loop == 0 ? 0.42 : f.loop;
  final bx = -30 + (w + 60) * along;
  final by = h * 0.42 + math.sin(along * 4 * math.pi) * h * 0.12;
  final arrive = phase(f.intro, 0.1, 0.5, Curves.easeOutBack);
  wagebird(c, Offset(bx, by), h * 0.34 * arrive, f, flap: f.loop == 0 ? 0.6 : _flapAt(f.loop * 2));
};
