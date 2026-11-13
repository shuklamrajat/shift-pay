// Renders store art from the app's own drawings: icon, mascot cut-outs and
// two illustrations. Run with tool/../../../tool/make_store_art.py, which
// frames them into the Play icon, launcher icons and feature graphic.
//   flutter test tool/art_test.dart --dart-define=ART_OUT=<dir>
import 'package:app_core/art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hours_tracker/src/app.dart';
import 'package:hours_tracker/src/ui/logo.dart';
import 'package:hours_tracker/src/ui/scenes.dart';

const out = String.fromEnvironment('ART_OUT', defaultValue: 'build/art');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('store art', () async {
    // The in-app logo at rest, checked against brand/logo-1024.png.
    await writeScenePng('$out/icon.png', wagebirdLogo, const Size(1024, 1024), hoursConfig, loop: 0);
    await writeScenePng(
      '$out/mascot.png',
      (c, s, f) => wagebird(c, s.center(Offset.zero), s.width * 0.62, f, flap: 0.6),
      const Size(800, 800),
      hoursConfig,
    );
    await writeScenePng(
      '$out/mascot_dark.png',
      (c, s, f) => wagebird(c, s.center(Offset.zero), s.width * 0.62, f, flap: 0.6),
      const Size(800, 800),
      hoursConfig,
      brightness: Brightness.dark,
    );
    await writeScenePng('$out/hero.png', clockScene, const Size(900, 900), hoursConfig);
    await writeScenePng('$out/pro.png', timesheetProScene, const Size(1200, 700), hoursConfig);
  });
}
