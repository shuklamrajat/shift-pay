// Renders store art from the app's own drawings: icon, mascot cut-outs and
// two illustrations. Run with tool/../../../tool/make_store_art.py, which
// frames them into the listing screenshots and feature graphic.
//   flutter test tool/art_test.dart --dart-define=ART_OUT=<dir>
import 'dart:io';

import 'package:app_core/art.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tip_tracker/src/app.dart';
import 'package:tip_tracker/src/ui/scenes.dart';

const out = String.fromEnvironment('ART_OUT', defaultValue: 'build/art');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('store art', () async {
    // Headless tests draw text in a box font. The scenes name Roboto (the
    // Android system font) for their labels, so load the store art's Inter
    // under that name and the jar's TIPS label reads properly.
    final bold = File('../../tool/fonts/InterDisplay-Black.otf').readAsBytesSync();
    await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bold)))).load();
    // The in-app logo at rest, checked against brand/logo-1024.png.
    await writeScenePng('$out/icon.png', tipLogo, const Size(1024, 1024), tipsConfig, loop: 0);
    await writeScenePng(
      '$out/mascot.png',
      (c, s, f) => tipJar(c, s.center(Offset.zero), s.width * 0.62, f, fill: 0.7, wobble: 0.4),
      const Size(800, 800),
      tipsConfig,
    );
    await writeScenePng(
      '$out/mascot_dark.png',
      (c, s, f) => tipJar(c, s.center(Offset.zero), s.width * 0.62, f, fill: 0.7, wobble: 0.4),
      const Size(800, 800),
      tipsConfig,
      brightness: Brightness.dark,
    );
    await writeScenePng('$out/hero.png', fillJarScene, const Size(900, 900), tipsConfig);
    await writeScenePng('$out/pro.png', proScene, const Size(1200, 700), tipsConfig);
  });
}
