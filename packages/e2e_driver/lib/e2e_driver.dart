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

/// Folder for store screenshots, set with --dart-define=SHOTS=<dir>. Empty
/// means a normal test run: no phone-size surface and no pictures.
const shotsDir = String.fromEnvironment('SHOTS');

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
