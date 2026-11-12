import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives a running app by widget keys. Waits for real I/O (SQLite, files)
/// that pumpAndSettle alone does not wait for, and scrolls lazily built lists.
class E2eDriver {
  E2eDriver(this.tester);
  final WidgetTester tester;

  Future<void> waitFor(Finder f, {Duration timeout = const Duration(seconds: 15)}) =>
      waitUntil(() => f.evaluate().isNotEmpty, '$f', timeout: timeout);

  Future<void> waitUntil(bool Function() ok, String what, {Duration timeout = const Duration(seconds: 15)}) async {
    final end = DateTime.now().add(timeout);
    while (!ok()) {
      if (DateTime.now().isAfter(end)) throw StateError('Timed out waiting for $what');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Waits for the first-run tour and skips it.
  Future<void> skipTour() async {
    final skip = find.byKey(const Key('tour-skip'));
    await waitFor(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }

  Future<void> reveal(Finder f) async {
    if (f.evaluate().isEmpty) {
      final list = find.byType(Scrollable).first;
      await tester.drag(list, const Offset(0, 5000));
      await tester.pumpAndSettle();
      if (f.evaluate().isEmpty) await tester.scrollUntilVisible(f, 300, scrollable: list);
    }
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder f) async {
    await reveal(f);
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(String k) => tap(find.byKey(Key(k)));

  Future<void> type(String k, String text) async {
    final f = find.byKey(Key(k));
    await reveal(f);
    await tester.enterText(f, text);
    await tester.pump();
  }

  Future<String> textOf(String k) async {
    final f = find.byKey(Key(k));
    if (f.evaluate().isEmpty) await reveal(f);
    return tester.widget<Text>(f).data!;
  }

  /// All Text strings inside the widget with key [k], joined by " | ".
  Future<String> textsIn(String k) async {
    final f = find.byKey(Key(k));
    if (f.evaluate().isEmpty) await reveal(f);
    return find
        .descendant(of: f, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .join(' | ');
  }

  /// Picks [label] from the open dropdown or menu.
  Future<void> pick(String label) => tap(find.text(label).last);

  bool exists(String k) => find.byKey(Key(k)).evaluate().isNotEmpty;
}

/// Where the docked banner ad sits relative to the bottom navigation and the
/// floating button. Works with any ad: it measures, it doesn't know the ad.
class BannerLayout {
  BannerLayout(this.tester);
  final WidgetTester tester;

  Finder get _banner => find.byKey(const Key('ad-banner'));
  Finder get _nav => find.byType(NavigationBar);
  Finder get _fab => find.byType(FloatingActionButton);

  bool get bannerShown => _banner.evaluate().isNotEmpty;

  /// Space the dock takes above the navigation bar (0 when no ad shows).
  double get spaceAboveNav {
    final dock = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'AdDock');
    return tester.getSize(dock).height - tester.getSize(_nav).height;
  }

  /// Top of the navigation bar, in logical pixels from the top of the screen.
  double get navTop => tester.getTopLeft(_nav).dy;

  /// The whole banner is above the navigation bar, touching it.
  bool get bannerSitsOnNav {
    if (!bannerShown) return false;
    return (tester.getRect(_banner).bottom - navTop).abs() < 0.5;
  }

  /// The banner and the floating add button share no pixels.
  bool get bannerClearOfFab {
    if (!bannerShown || _fab.evaluate().isEmpty) return true;
    return !tester.getRect(_banner).overlaps(tester.getRect(_fab.first));
  }
}

/// Folder for store screenshots, set with --dart-define=SHOTS=<dir>. Empty
/// means a normal test run: no phone-size surface and no pictures.
const shotsDir = String.fromEnvironment('SHOTS');

/// Saves what is on screen now as a PNG at [path] (an E2E artifact).
Future<void> saveScreen(WidgetTester tester, String path) async {
  await tester.pumpAndSettle();
  final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
  final image = await layer.toImage(Offset.zero & tester.view.physicalSize, pixelRatio: 1);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

/// Phone-size store screenshots taken at chosen moments of an E2E run.
/// 1080 x 1920 pixels (411 x 731 logical at 2.625x), a size both stores take
/// for phones. When enabled, the whole E2E run happens at phone size, so its
/// checks also prove the layout works on a phone screen.
class StoreShots {
  StoreShots(this.tester);
  final WidgetTester tester;
  final taken = <String>[];

  bool get enabled => shotsDir.isNotEmpty;

  void usePhoneSize() {
    if (!enabled) return;
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  /// Scrolls every visible list back to its top, then saves the screen.
  Future<void> take(String name) async {
    if (!enabled) return;
    // A passing snack bar from an earlier step would end up in the picture.
    for (final e in find.byType(ScaffoldMessenger).evaluate()) {
      ((e as StatefulElement).state as ScaffoldMessengerState).removeCurrentSnackBar();
    }
    for (final e in find.byType(Scrollable).evaluate()) {
      final pos = (e as StatefulElement).state as ScrollableState;
      if (pos.position.hasPixels) pos.position.jumpTo(pos.position.minScrollExtent);
    }
    await tester.pumpAndSettle();
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    // The root layer already carries the view's own transform to physical
    // pixels, so capture the physical rectangle at ratio 1.
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize, pixelRatio: 1);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$shotsDir/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
    taken.add(name);
  }
}
