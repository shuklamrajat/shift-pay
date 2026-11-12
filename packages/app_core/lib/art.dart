/// Renders an app's drawn-in-code illustrations to PNG files for store art
/// (icons, mascot cut-outs, feature graphics). Used by each app's
/// tool/art_test.dart; not part of the shipped app.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_core.dart';

/// Paints one frame of [paint] at [size] with [config]'s theme and writes a
/// PNG (transparent wherever the scene paints nothing).
Future<void> writeScenePng(
  String path,
  ScenePaint paint,
  Size size,
  AppConfig config, {
  Brightness brightness = Brightness.light,
  double loop = 0.2,
}) async {
  final theme = buildAppTheme(
    config.seedColor,
    brightness,
    accent: config.accentColor,
    gradientEnd: config.gradientEndColor,
  );
  final frame = SceneFrame(
    intro: 1,
    loop: loop,
    scheme: theme.colorScheme,
    brand: theme.extension<BrandColors>() ?? BrandColors.fallback(theme.colorScheme, config.accentColor),
  );
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, Offset.zero & size);
  paint(canvas, size, frame);
  final image = await rec.endRecording().toImage(size.width.round(), size.height.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// A full-bleed square app icon: the brand gradient, a soft glow and the
/// mascot drawn by [mascot] into the middle of the square.
ScenePaint iconPaint(ScenePaint mascot) => (c, s, f) {
  final r = Offset.zero & s;
  c.drawRect(r, Paint()..shader = f.brand.linear.createShader(r));
  Ink2.glow(
    c,
    s.center(Offset(-s.width * 0.1, -s.height * 0.12)),
    s.width * 0.55,
    Colors.white.withValues(alpha: 0.22),
  );
  mascot(c, s, f);
};
