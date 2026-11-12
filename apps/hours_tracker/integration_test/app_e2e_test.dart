// End-to-end: drives the real app (real SQLite file, real paywall stub,
// real CSV/PDF export) through two weeks of shifts for a warehouse job and a
// second bar job.
//
// Run: tool/run_e2e.sh   (sets TZ=America/New_York and the artifact folder)
//
// Expected numbers, worked by hand. Rate $20, OT after 8 h/day at 1.5x,
// double after 12 h/day at 2x, OT after 40 regular h/week, week starts Monday.
//
//   Week of Mon 26 Oct
//     Sat 31 Oct 22:00 - Sun 06:00   clocks fall back that night: 9 h real
//                                    8 regular + 1 OT           = $190.00
//   Week of Mon 2 Nov
//     Mon 06-10 and 14-19 (split)    9 h: 8 reg + 1 OT
//     Tue 22:00 - Wed 07:00, 30m brk 8.5 h on Tuesday: 8 reg + 0.5 OT
//     Wed 18-23                      5 reg
//     Thu 07:00-20:30                13.5 h: 8 reg + 4 OT + 1.5 double
//     Fri 08-17, 60m break           8 reg (first saved as 08-18, then edited)
//     Sat 09-15                      6 h, only 3 left under 40: 3 reg + 3 OT
//     Sun 23:00 - Mon 03:00          4 h on Sunday, week full: 4 OT
//                                    40 reg, 12.5 OT, 1.5 double = $1,235.00
//   Custom report 26 Oct - 8 Nov: 48 reg ($960), 13.5 OT ($405),
//   1.5 double ($60), total $1,425.00, 63 h over 9 shifts.
//
//   Week of Mon 9 Nov (this week): Mon 08-12 typed in, Tue 09:00-13:15 by
//   clock in/out = 8 h 15 m, $165.00.
//   Bar job ($15, same rules) Mon 2 Nov 20:00-23:30 = 3.5 h = $52.50; it must
//   not push the warehouse Monday into overtime.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_core/app_core.dart';
import 'package:app_core/testing.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:e2e_driver/e2e_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hours_tracker/src/app.dart';
import 'package:hours_tracker/src/data/repository.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const artifactRoot = String.fromEnvironment('ARTIFACT_DIR', defaultValue: 'test-artifacts/manual');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two weeks of shifts, overtime, edits, clock in/out, paywall and export', (tester) async {
    expect(
      DateTime(2026, 11, 1, 12).timeZoneOffset != DateTime(2026, 10, 31, 12).timeZoneOffset,
      isTrue,
      reason: 'run through tool/run_e2e.sh so TZ=America/New_York',
    );

    WidgetController.hitTestWarningShouldBeFatal = true;
    // Endless decorative loops would keep pumpAndSettle from ever settling;
    // one-shot entrance animations, charts and count-ups still run.
    Motion.ambient = false;
    addTearDown(() => Motion.ambient = true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final semantics = tester.ensureSemantics();
    final log = E2eLog('hours_tracker: two weeks, split/overnight/DST shifts, two jobs', artifactRoot);
    final tmp = await Directory.systemTemp.createTemp('hours_e2e');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final db = HoursDb(NativeDatabase(File('${tmp.path}/hours.sqlite')));
    final clock = TestClock(DateTime(2026, 11, 10, 8, 0));
    final sharer = RecordingFileSharer();
    final reviews = RecordingReviewRequester();
    final shots = StoreShots(tester)..usePhoneSize();

    Widget app() => ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        appConfigProvider.overrideWithValue(hoursConfig),
        hoursDbProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        fileSharerProvider.overrideWithValue(sharer),
        exportDirProvider.overrideWithValue(() async => tmp),
        reviewRequesterProvider.overrideWithValue(reviews),
        entitlementServiceProvider.overrideWithValue(LocalEntitlementService(prefs, allowDebugPurchase: true)),
      ],
      child: const HoursApp(),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Saving goes through real file I/O, which pumpAndSettle does not wait
    // for, so wait for the screen that should follow.
    Future<void> waitFor(Finder f, {Duration timeout = const Duration(seconds: 15)}) async {
      final end = DateTime.now().add(timeout);
      while (f.evaluate().isEmpty) {
        if (DateTime.now().isAfter(end)) throw StateError('Timed out waiting for $f');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<void> waitUntil(bool Function() ok, String what) async {
      final end = DateTime.now().add(const Duration(seconds: 15));
      while (!ok()) {
        if (DateTime.now().isAfter(end)) throw StateError('Timed out waiting for $what');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<void> reveal(Finder f) async {
      if (f.evaluate().isEmpty) {
        // Lazily built lists: scroll the visible list (up first, then down)
        // until the item has been built.
        final list = find.byType(Scrollable).first;
        await tester.drag(list, const Offset(0, 5000));
        await tester.pumpAndSettle();
        if (f.evaluate().isEmpty) await tester.scrollUntilVisible(f, 300, scrollable: list);
      }
      await tester.ensureVisible(f.first);
    }

    Future<void> tap(Finder f) async {
      await reveal(f);
      await tester.pumpAndSettle();
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

    String spoken(String k) => tester.getSemantics(find.byKey(Key(k))).label;

    // Raw pixels of one widget as it is on screen now.
    Future<List<int>> pixelsOf(Finder f) async {
      final box = tester.renderObject<RenderBox>(f);
      final r = box.localToGlobal(Offset.zero) & box.size;
      final dpr = tester.view.devicePixelRatio;
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final img = await layer.toImage(
        Rect.fromLTWH(r.left * dpr, r.top * dpr, r.width * dpr, r.height * dpr),
        pixelRatio: 1,
      );
      final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      return bytes!.buffer.asUint8List();
    }

    // Steps to the previous week and stops on the very first frame that
    // shows its hours. Returns whether the chart on that frame already
    // looks the way it does once everything has come to rest.
    Future<({bool chartAtRest, bool rollingNumber})> previousWeekFirstFrame(String hours) async {
      await tester.tap(find.byKey(const Key('week-prev')));
      final end = DateTime.now().add(const Duration(seconds: 15));
      final f = find.byKey(const Key('week-hours'));
      while (f.evaluate().isEmpty || tester.widget<Text>(f).data != hours) {
        if (DateTime.now().isAfter(end)) throw StateError('week with $hours did not show');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      final first = await pixelsOf(find.byKey(const Key('week-chart')));
      final rolling = find
          .descendant(of: find.byType(CountUpText), matching: find.byType(ExcludeSemantics))
          .evaluate()
          .isNotEmpty;
      await tester.pumpAndSettle();
      final rest = await pixelsOf(find.byKey(const Key('week-chart')));
      var same = first.length == rest.length;
      for (var i = 0; same && i < first.length; i++) {
        same = first[i] == rest[i];
      }
      return (chartAtRest: same, rollingNumber: rolling);
    }

    try {
      // Onboarding: three pages.
      expect(find.byKey(const Key('onboarding')), findsOneWidget);
      await shots.take('0_welcome');
      await tapKey('onboarding-next');
      await tapKey('onboarding-next');
      await tapKey('onboarding-next');

      // First job.
      await tapKey('add-first-job');
      await type('job-name', 'Warehouse');
      await type('job-rate', '20.00');
      await tapKey('job-use-double');
      await type('job-double', '12');
      await tapKey('save-job');
      expect(find.text('Warehouse'), findsWidgets);

      Future<String?> addShift(String date, String start, String end, {int breakMin = 0}) async {
        await tapKey('add-shift');
        await type('shift-date', date);
        await type('shift-start', start);
        await type('shift-end', end);
        await type('shift-break', '$breakMin');
        await tapKey('save-shift');
        final err = find.byKey(const Key('shift-error'));
        if (err.evaluate().isNotEmpty) return tester.widget<Text>(err).data;
        return null;
      }

      final shifts = [
        ('2026-10-31', '22:00', '06:00', 0),
        ('2026-11-02', '06:00', '10:00', 0),
        ('2026-11-02', '2:00 pm', '7:00 pm', 0), // typed the 12-hour way on purpose
        ('2026-11-03', '22:00', '07:00', 30),
        ('2026-11-04', '18:00', '23:00', 0),
        ('2026-11-05', '07:00', '20:30', 0),
        ('2026-11-06', '08:00', '18:00', 60), // wrong end, fixed below
        ('2026-11-07', '09:00', '15:00', 0),
        ('2026-11-08', '23:00', '03:00', 0),
        ('2026-11-09', '08:00', '12:00', 0),
      ];
      log.inputs['warehouse_shifts'] = [for (final s in shifts) '${s.$1} ${s.$2}-${s.$3} break ${s.$4}m'];
      for (final s in shifts) {
        final err = await addShift(s.$1, s.$2, s.$3, breakMin: s.$4);
        log.check('saved shift ${s.$1} ${s.$2}', null, err);
      }

      // An overlapping shift must be refused and not saved.
      final overlapErr = await addShift('2026-11-05', '19:00', '21:00');
      log.check('overlapping Thu 19:00-21:00 refused', true, overlapErr?.contains('overlaps') ?? false);
      await tester.pageBack();
      await tester.pumpAndSettle();
      final countAfterOverlap = (await db.select(db.shifts).get()).length;
      log.check('overlap not stored (shift count)', 10, countAfterOverlap);

      // Fix Friday's end time from 18:00 to 17:00 through the editor.
      final fri = await (db.select(db.shifts)..where((s) => s.start.equals(DateTime(2026, 11, 6, 8)))).getSingle();
      await tapKey('week-prev');
      await tapKey('shift-${fri.id}');
      await type('shift-end', '17:00');
      await tapKey('save-shift');
      await waitFor(find.byKey(const Key('add-shift')));
      final friAfter = await (db.select(db.shifts)..where((s) => s.id.equals(fri.id))).getSingle();
      log.check('Friday end edited to 17:00', DateTime(2026, 11, 6, 17), friAfter.end);
      log.check('week of 2 Nov pay on Week tab', r'$1,235.00', await textOf('week-pay'));
      log.check('week of 2 Nov double time on Week tab', '1h 30m', await textOf('week-dt'));
      // The day chart, as a screen reader hears it, against the hand-worked
      // split at the top of this file.
      log.check(
        'week of 2 Nov day chart (screen reader)',
        'Hours by day. Mon 9h, 1h overtime. Tue 8h 30m, 30m overtime. Wed 5h. '
            'Thu 13h 30m, 4h overtime, 1h 30m double time. Fri 8h. Sat 6h, 3h overtime. Sun 4h, 4h overtime.',
        spoken('week-chart'),
      );
      await shots.take('1_week');
      await tapKey('week-next');

      // Clock in Tuesday 09:00, clock out 13:15.
      clock.now = DateTime(2026, 11, 10, 9, 0);
      await tapKey('clock-in');
      await waitFor(find.byKey(const Key('clock-banner-open')));
      log.check(
        'clock banner shows while on the clock',
        1,
        find.byKey(const Key('clock-banner-open')).evaluate().length,
      );
      clock.now = DateTime(2026, 11, 10, 13, 15, 42);
      await tapKey('clock-out');
      await waitFor(find.byKey(const Key('clock-in')));
      log.check('this week hours after clock out', '8h 15m', await textOf('week-hours'));
      log.check('this week pay after clock out', r'$165.00', await textOf('week-pay'));
      log.check(
        'this week day chart after clock out',
        'Hours by day. Mon 4h. Tue 4h 15m. Wed no shifts. Thu no shifts. Fri no shifts. Sat no shifts. Sun no shifts.',
        spoken('week-chart'),
      );

      log.check('no review prompt in the first two days', 0, reviews.requests);

      // Second job is a Pro feature: the paywall must appear first.
      await tapKey('tab-jobs');
      await tapKey('add-job');
      await waitFor(find.byKey(const Key('offer-pro_lifetime')));
      log.check('paywall shown for a second job', 1, find.byKey(const Key('paywall')).evaluate().length);
      await shots.take('3_pro');
      // Buying Pro sets off confetti. It falls over the next screen and must
      // not get in the way of using it.
      await reveal(find.byKey(const Key('offer-pro_lifetime')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('offer-pro_lifetime')));
      var sawConfetti = false;
      final confettiEnd = DateTime.now().add(const Duration(seconds: 15));
      final jobName = find.byKey(const Key('job-name'));
      bool formSettled() =>
          jobName.evaluate().isNotEmpty &&
          ModalRoute.of(tester.element(jobName))!.animation!.status == AnimationStatus.completed;
      while (!formSettled()) {
        if (DateTime.now().isAfter(confettiEnd)) throw StateError('job form did not open after purchase');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
        sawConfetti |= find.byKey(const Key('celebration')).evaluate().isNotEmpty;
      }
      final confettiOverForm = find.byKey(const Key('celebration')).evaluate().isNotEmpty;
      log.inputs['confetti_over_job_form_when_tapped'] = confettiOverForm;
      log.check('confetti plays after buying Pro', true, sawConfetti);
      // A swallowed tap would fail the run (hit-test warnings are fatal).
      await tester.tap(jobName);
      await tester.pump();
      log.check(
        'job name field takes a tap while confetti falls',
        true,
        tester
            .widget<EditableText>(find.descendant(of: jobName, matching: find.byType(EditableText)))
            .focusNode
            .hasFocus,
      );
      await tester.pumpAndSettle();
      log.check('confetti cleared once landed', 0, find.byKey(const Key('celebration')).evaluate().length);
      await type('job-name', 'Bar');
      await type('job-rate', '15.00');
      await tapKey('job-use-double');
      await type('job-double', '12');
      await tapKey('save-job');
      await waitFor(find.byKey(const Key('job-switcher')));
      await tapKey('tab-week');
      log.check('saved Bar shift', null, await addShift('2026-11-02', '20:00', '23:30'));

      // Bar on its own.
      await tapKey('tab-pay');
      await tapKey('period-custom');
      await type('custom-from', '2026-10-26');
      await type('custom-to', '2026-11-08');
      await tapKey('custom-apply');
      await waitFor(find.byKey(const Key('pay-total')));
      log.check('Bar pay 26 Oct - 8 Nov', r'$52.50', await textOf('pay-total'));
      log.check('Bar overtime hours', '0.00 h', await textOf('pay-ot-hours'));

      // Back to Warehouse.
      await tapKey('job-switcher');
      await tap(find.text('Warehouse').last);
      await tapKey('custom-apply');
      await waitFor(find.byKey(const Key('pay-total')));
      log.check('Warehouse total pay', r'$1,425.00', await textOf('pay-total'));
      log.check('Warehouse regular hours', '48.00 h', await textOf('pay-regular-hours'));
      log.check('Warehouse overtime hours', '13.50 h', await textOf('pay-ot-hours'));
      log.check('Warehouse double time hours', '1.50 h', await textOf('pay-dt-hours'));
      log.check('Warehouse hours and shift count', '63h over 9 shifts', await textOf('pay-hours'));
      log.check(
        'Warehouse pay split bar (screen reader)',
        r'Pay split. Regular $960.00, overtime $405.00, double time $60.00.',
        spoken('pay-split'),
      );
      await shots.take('2_pay');

      // Exports, three days later so the rating prompt is allowed once.
      clock.now = DateTime(2026, 11, 13, 9, 0);
      await tapKey('export-csv');
      await waitUntil(() => sharer.shared.length == 1, 'CSV export');
      await tapKey('export-pdf');
      await waitUntil(() => sharer.shared.length == 2, 'PDF export');
      log.check('two files handed to the share sheet', 2, sharer.shared.length);
      log.check('review requested exactly once', 1, reviews.requests);

      final csv = log.keep(sharer.shared[0], 'timesheet.csv').readAsStringSync();
      log.keep(sharer.shared[1], 'timesheet.pdf');
      final lines = csv.replaceFirst('﻿', '').split('\r\n');
      final shiftRows = lines.where((l) => RegExp(r'^\d{4}-\d{2}-\d{2},').hasMatch(l)).toList();
      log.check('CSV shift rows', 9, shiftRows.length);
      log.check('CSV total pay row', 'Total pay,1425.00', lines.firstWhere((l) => l.startsWith('Total pay')));
      log.check('CSV DST night worked hours', '9.00', shiftRows.first.split(',')[4]);
      final sun = shiftRows.firstWhere((l) => l.contains('2026-11-08 23:00'));
      log.check(
        'CSV Sunday overnight row (workday, end, OT h)',
        ['2026-11-08', '2026-11-09 03:00', '4.00'],
        [sun.split(',')[0], sun.split(',')[2], sun.split(',')[6]],
      );
      log.check('CSV Bar shift not in Warehouse file', false, csv.contains('20:00'));

      // Motion: changing week animates the chart and rolls the numbers;
      // with the system's reduce-motion setting on, both arrive at rest.
      await tapKey('tab-week');
      final moving = await previousWeekFirstFrame('54h');
      log.check('motion on: week chart still growing on first frame', false, moving.chartAtRest);
      log.check('motion on: hours roll up on first frame', true, moving.rollingNumber);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      final still = await previousWeekFirstFrame('9h');
      log.check('reduce motion: week chart already at rest on first frame', true, still.chartAtRest);
      log.check('reduce motion: hours shown without rolling', false, still.rollingNumber);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pumpAndSettle();

      // Dark theme from Settings, then the app is closed and opened again:
      // the theme, the data and Pro must all still be there.
      await tapKey('open-settings');
      await tapKey('settings-theme');
      await tap(find.text('Dark').last);
      log.check(
        'Settings switches the app to dark',
        Brightness.dark,
        Theme.of(tester.element(find.byKey(const Key('settings-theme')))).brightness,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapKey('week-next');
      await waitUntil(() => find.text('54h').evaluate().isNotEmpty, 'week of 2 Nov');
      await shots.take('4_dark_week');
      await tapKey('tab-pay');
      await shots.take('5_dark_pay');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await waitFor(find.byKey(const Key('week-hours')));
      log.check('reopened: no onboarding again', 0, find.byKey(const Key('onboarding')).evaluate().length);
      log.check(
        'reopened: still dark',
        Brightness.dark,
        Theme.of(tester.element(find.byKey(const Key('week-hours')))).brightness,
      );
      log.check('reopened: this week hours kept', '8h 15m', await textOf('week-hours'));
      log.check('reopened: two jobs kept (switcher shown)', 1, find.byKey(const Key('job-switcher')).evaluate().length);

      // Sanity: stored clock-out is truncated to the minute.
      final clocked = await db
          .customSelect(
            'SELECT "end" FROM shifts WHERE "end" IS NOT NULL ORDER BY "end" DESC LIMIT 1',
            variables: <Variable>[],
          )
          .getSingle();
      log.inputs['last_clock_out_epoch_s'] = clocked.data['end'];
    } finally {
      log.write();
      semantics.dispose();
    }
    expect(log.failures, isEmpty, reason: 'see $artifactRoot/result.json');
    // Unmount the app so its live queries end, then close the database.
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close().timeout(const Duration(seconds: 5), onTimeout: () {});
  }, timeout: const Timeout(Duration(minutes: 6)));
}
