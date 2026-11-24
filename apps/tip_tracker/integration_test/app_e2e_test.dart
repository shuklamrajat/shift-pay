// End-to-end: drives the real app (real SQLite files, real backup files,
// real CSV/PDF export) through two weeks of a server's life, then loses the
// phone, restores on a new one, and recovers from damaged data.
//
// Run: tool/run_e2e.sh   (sets TZ=America/Chicago and the artifact folder)
//
// Expected numbers, worked by hand (cents rounded half up).
// Luna Bistro: server, $2.13/h, tip-out 3% of sales. Dock Bar: bartender,
// $5.00/h, no tip-out. Week starts Monday.
//
//   s1 Mon 9 Nov   16:00-23:00, 30m break = 6h30m. Cash 82, card 141.50,
//                  sales 1,240 -> tip-out 37.20, wages 13.85,
//                  take-home 200.15, 30.79/h. Later card fixed to 151.50:
//                  take-home 210.15, 32.33/h.
//   s2 Tue 10 Nov  logged at 1:30 AM Wednesday, so the day defaults to
//                  Tuesday. 6:00 pm-01:15 overnight = 7h15m. Cash 120,
//                  card 95, sales 980 -> tip-out 29.40, wages 15.44,
//                  take-home 201.04, 27.73/h.
//   s3 Fri 13 Nov  typed as 5.5 hours, cash only 64, sales 610 (rule says
//                  18.30) but tip-out changed to 10.00. Wages 11.72,
//                  take-home 65.72, 11.95/h.
//   s4 Fri 13 Nov  Dock Bar, logged 3:10 AM Saturday. 20:00-02:30 = 6h30m.
//                  Cash 210, card 180, tip-in 40, wages 32.50,
//                  take-home 462.50, 71.15/h: best rate, celebrated.
//   s5 Mon 16 Nov  6 hours, cash 100, card 100, sales 1,000 -> 30.00 out,
//                  wages 12.78, take-home 182.78.
//   s6 Fri 20 Nov  logged Saturday morning with "Yesterday". 6 hours, cash
//                  150, card 150, sales 1,500 -> 45.00 out, take-home 267.78.
//
//   Week 9-15 Nov: 939.41, 25h 45m, 36.48/h, tipped out 76.60, cash 476.00,
//                  card 426.50, tip-in 40.00, wages 73.51, tax 15% 140.91.
//   Week 16-22 Nov: 450.56, 12h, 37.55/h.
//   November: 1,389.97, 37h 45m, 36.82/h, tax 208.50.
//   Best night (weekdays with 2+ shifts): Fridays 796.00 over 18h = 44.22/h
//   beat Mondays 392.93 over 12h 30m = 31.43/h.
//   By job: Luna 927.47 over 31h 15m = 29.68/h; Dock 71.15/h.
//   Luna is paid every 2 weeks from the default anchor Mon 5 Jan 2026, so
//   its pay period on 14 Nov is 9 Nov to 22 Nov: s1+s2+s3 = 466.91. The
//   Settings default stays weekly: 9 to 15 Nov, 929.41 on 14 Nov.
//   Tapping Fri 13 Nov on the week chart: s3+s4 = 528.22 over 12h = 44.02/h.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:app_core/testing.dart';
import 'package:drift/native.dart';
import 'package:e2e_driver/e2e_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tip_tracker/src/app.dart';
import 'package:tip_tracker/src/backup/backup_service.dart';
import 'package:tip_tracker/src/data/repository.dart';
import 'package:tip_tracker/src/ui/backup_screen.dart';

const artifactRoot = String.fromEnvironment('ARTIFACT_DIR', defaultValue: 'test-artifacts/manual');

/// One phone: its own database file, backup folder and export folder.
class Phone {
  Phone(this.dir) : db = TipsDb(NativeDatabase(File('${dir.path}/tips.sqlite')));
  final Directory dir;
  final TipsDb db;
  Directory get backups => Directory('${dir.path}/backups');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two weeks of shifts, edits, stats, export, backup, new phone restore, damaged data', (tester) async {
    expect(DateTime(2026, 11, 9).timeZoneName, isNot('UTC'), reason: 'run through tool/run_e2e.sh so TZ is set');
    WidgetController.hitTestWarningShouldBeFatal = true;
    Motion.ambient = false;
    addTearDown(() => Motion.ambient = true);
    // Phones in the emulator gate run with system animations off, so this run
    // does too (that once broke a zero-length AnimatedSize mid-layout).
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final log = E2eLog('tipwell: two weeks, two jobs, backup and restore', artifactRoot);
    final root = await Directory.systemTemp.createTemp('tips_e2e');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final clock = TestClock(DateTime(2026, 11, 9, 23, 40));
    final sharer = RecordingFileSharer();
    final shots = StoreShots(tester);
    Uint8List? nextPick; // what the file picker hands back
    var diskFull = false; // acts out a phone with no free storage
    var phone = Phone(await Directory('${root.path}/phone1').create());
    var launch = 0;

    Future<void> start() async {
      launch++;
      final p = phone;
      await tester.pumpWidget(
        KeyedSubtree(
          key: ValueKey(launch),
          child: ProviderScope(
            overrides: [
              sharedPrefsProvider.overrideWithValue(prefs),
              appConfigProvider.overrideWithValue(tipsConfig),
              tipsDbProvider.overrideWithValue(p.db),
              clockProvider.overrideWithValue(clock.call),
              fileSharerProvider.overrideWithValue(sharer),
              exportDirProvider.overrideWithValue(() async => p.dir),
              backupDirProvider.overrideWithValue(() async => p.backups.create(recursive: true)),
              backupFilePickerProvider.overrideWithValue(() async => nextPick),
              backupFileWriterProvider.overrideWithValue((f, bytes) async {
                if (diskFull) {
                  // What Android throws when the disk is full mid-write: a
                  // half-written file is left behind.
                  await f.writeAsBytes(bytes.sublist(0, bytes.length ~/ 3));
                  throw FileSystemException('Write failed', f.path, const OSError('No space left on device', 28));
                }
                await f.writeAsBytes(bytes, flush: true);
              }),
              reviewRequesterProvider.overrideWithValue(RecordingReviewRequester()),
              entitlementServiceProvider.overrideWithValue(const FreeForNowEntitlementService()),
              // No real banner: on a phone it would load and move the layout mid-test.
              adsPlatformProvider.overrideWithValue(const NoAdsPlatform()),
            ],
            child: const TipApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final d = E2eDriver(tester);
    Future<void> tapKey(String k) => d.tapKey(k);
    Future<void> type(String k, String v) => d.type(k, v);
    Future<String> text(String k) => d.textOf(k);
    Future<void> back() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    Future<void> tapIn(String key, String label) =>
        d.tap(find.descendant(of: find.byKey(Key(key)), matching: find.text(label)));

    Future<String?> error() async {
      final f = find.byKey(const Key('shift-error'));
      return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
    }

    Future<void> save() async {
      await tapKey('shift-save');
      // The save does real I/O; wait for either the list or an error.
      try {
        await d.waitUntil(
          () => find.byKey(const Key('shift-form')).evaluate().isEmpty || find.byKey(const Key('shift-error')).evaluate().isNotEmpty,
          'shift save',
        );
      } on StateError {
        // What was on screen, for the emulator gate's log.
        final btn = find.byKey(const Key('shift-save'));
        debugPrint('SAVE-DIAG save button: ${btn.evaluate().length}, enabled: '
            '${btn.evaluate().isEmpty ? '-' : tester.widget<ButtonStyleButton>(btn).enabled}, '
            'view insets: ${tester.view.viewInsets}, size: ${tester.view.physicalSize}');
        final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toSet();
        debugPrint('SAVE-DIAG texts: ${texts.join(' | ')}');
        final fields = find.byType(EditableText).evaluate().map((e) => (e.widget as EditableText).controller.text);
        debugPrint('SAVE-DIAG fields: ${fields.join(' | ')}; error: ${await error()}');
        rethrow;
      }
    }

    Future<void> skipTourIfShown() async {
      final end = DateTime.now().add(const Duration(seconds: 4));
      while (DateTime.now().isBefore(end)) {
        if (find.byKey(const Key('tour-skip')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('tour-skip')));
          await tester.pumpAndSettle();
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    }

    Future<String> snackText() async {
      final f = find.descendant(of: find.byType(SnackBar), matching: find.byType(Text));
      return f.evaluate().map((e) => (e.widget as Text).data ?? '').join(' | ');
    }

    try {
      // ---------------- First run ----------------
      await start();
      expect(find.byKey(const Key('onboarding')), findsOneWidget);
      await shots.take('01_welcome');
      await tapKey('onboarding-next');
      await back();
      log.check('Back on the welcome goes to the previous page', true,
          d.exists('onboarding') && find.text('Log a shift in seconds').hitTestable().evaluate().isNotEmpty);
      for (var i = 0; i < 3; i++) {
        await tapKey('onboarding-next');
      }
      await d.waitFor(find.byKey(const Key('job-name')));
      log.check('first run opens job setup with a restore option', true, d.exists('first-run-restore'));
      log.check('Server role starts with a usual tip-out', 'Tip-out 3% of sales', await text('rule-preview'));
      await tapKey('role-delivery');
      log.check('Delivery role drops the tip-out and sales', true,
          !d.exists('rule-preview') && !tester.widget<SwitchListTile>(find.byKey(const Key('tracks-sales'))).value);
      await tapKey('role-server');
      await type('job-name', 'Luna Bistro');
      await type('job-wage', '2.13');
      await tapIn('tipout-kind', '% sales');
      await type('tipout-value', '3');
      await tester.pumpAndSettle();
      log.check('rule preview while typing', 'Tip-out 3% of sales', await text('rule-preview'));
      await tapIn('job-pay-kind', 'Every 2 wks');
      log.check('pay period starts from the Settings anchor', 'Mon 5 Jan 2026', await text('job-pay-anchor-label'));
      await shots.take('02_job_setup');
      await tapKey('job-save');
      await d.waitFor(find.byKey(const Key('add-shift')));
      await skipTourIfShown();
      log.check('empty shifts state', true, d.exists('shifts-empty'));

      // ---------------- s1: a normal Monday ----------------
      await tapKey('empty-add-shift'); // the empty state's own button
      log.check('s1 date defaults to today', 'Mon 9 Nov', await text('shift-date-label'));
      await type('shift-start', '16:00');
      await type('shift-end', '23:00');
      await type('shift-break', '30');
      await type('shift-cash', '82');
      await type('shift-card', '141.50');
      await type('shift-sales', '1240');
      await tester.pumpAndSettle();
      log.check('s1 tip-out worked out from the rule', r'Tip-out $37.20', await text('tipout-auto'));
      log.check('s1 live take-home', r'$200.15', await text('summary-total'));
      log.check('s1 live hourly', r'$30.79/h', await text('summary-rate'));
      log.check('s1 hours', '6h 30m', await text('summary-hours'));
      log.check('s1 cash in pocket (cash minus tip-out)', r'$44.80', await text('summary-cash'));
      log.check('s1 tips kept (tips minus tip-out)', r'$186.30', await text('summary-kept'));
      await shots.take('03_log_shift');
      await save();
      log.check('first shift is celebrated', true, (await snackText()).contains('First shift logged'));
      log.check('s1 row take-home', r'$200.15', await text('shift-row-total-1'));
      log.check('the saved shift is lit up in the list', true, d.exists('shift-row-saved-1'));
      final firstBackup = phone.backups.listSync().whereType<File>().where((f) => f.path.contains('tips-auto-20261109')).toList();
      log.check(
        'the first save made the day’s backup, holding that shift',
        1,
        firstBackup.length == 1 ? (jsonDecode(firstBackup.single.readAsStringSync())['counts'] as Map)['shifts'] : -1,
      );

      // ---------------- s2: overnight, logged after midnight, with mistakes ----------------
      clock.now = DateTime(2026, 11, 11, 1, 30);
      await tapKey('add-shift');
      log.check('after midnight the day defaults to last night', 'Tue 10 Nov', await text('shift-date-label'));
      await type('shift-start', '10:00');
      await type('shift-end', '10:20');
      await type('shift-break', '30');
      await save();
      log.check('break longer than the shift is refused', 'The break is as long as the whole shift.', await error());
      await type('shift-start', '6:00 pm');
      await type('shift-end', '01:15');
      await type('shift-break', '');
      await type('shift-cash', '120');
      await type('shift-card', '95');
      await save();
      log.check('% of sales rule without sales is refused', 'Enter your sales so the tip-out can be worked out.', await error());
      await tester.drag(find.byKey(const Key('shift-form')), const Offset(0, 3000)); // back to the top of the form
      await tester.pumpAndSettle();
      log.check('overnight shift is explained', true, d.exists('overnight-note'));
      await type('shift-sales', '980');
      await save();
      log.check('s2 saved with Tuesday date', r'$201.04', await text('shift-row-total-2'));
      log.check('only the newest save is lit', true, d.exists('shift-row-saved-2') && !d.exists('shift-row-saved-1'));

      // ---------------- s3: hours only, cash only, tip-out changed ----------------
      clock.now = DateTime(2026, 11, 13, 22, 30);
      await tapKey('add-shift');
      await tapIn('hours-mode', 'Total');
      await type('shift-hours', '17');
      await type('shift-cash', '64');
      await type('shift-sales', '610');
      await tester.pumpAndSettle();
      log.check('17 hours gets a warning', 'That’s a long shift. Is the time right?', await text('shift-warning'));
      await type('shift-hours', '5');
      await tapKey('hours-plus');
      await tapKey('hours-plus');
      await tapKey('hours-plus');
      final stepped = tester.widget<TextField>(find.byKey(const Key('shift-hours'))).controller!.text;
      await tapKey('hours-minus');
      log.check('+ and − move the hours a quarter at a time', '5.75 then 5.5',
          '$stepped then ${tester.widget<TextField>(find.byKey(const Key('shift-hours'))).controller!.text}');
      await tester.pumpAndSettle();
      log.check('s3 rule tip-out', r'Tip-out $18.30', await text('tipout-auto'));
      await tapKey('tipout-edit');
      await type('shift-tipout', '10');
      await tester.pumpAndSettle();
      log.check('s3 take-home with changed tip-out', r'$65.72', await text('summary-total'));
      await save();
      log.check('s3 row', r'$65.72', await text('shift-row-total-3'));

      // ---------------- second job, s4: best night ----------------
      await tapKey('tab-jobs');
      await tapKey('add-job');
      await type('job-name', 'luna bistro');
      await tapKey('role-bartender');
      log.check('Bartender role starts with a usual tip-out', 'Tip-out 10% of tips', await text('rule-preview'));
      await tapIn('tipout-kind', 'None'); // this bar keeps all its tips
      await type('job-wage', '5');
      await tapKey('job-save');
      await d.waitFor(find.byKey(const Key('job-error')));
      log.check('a second job with the same name is refused', 'You already have a job with that name.', await text('job-error'));
      final errBox = tester.getRect(find.byKey(const Key('job-error')));
      final saveBox = tester.getRect(find.byKey(const Key('job-save')));
      log.check('the reason sits right above Save, on screen', true,
          errBox.bottom <= saveBox.top && saveBox.top - errBox.bottom < 40 && errBox.top >= 0);
      await type('job-name', 'Dock Bar');
      await tapKey('job-save');
      await d.waitFor(find.byKey(const Key('job-2')));
      await tapKey('tab-shifts');
      clock.now = DateTime(2026, 11, 14, 3, 10);
      await tapKey('add-shift');
      log.check('new shift picks the last job used', true, tester.widget<ChoiceChip>(find.byKey(const Key('shift-job-2'))).selected);
      log.check('hours mode remembered (Total)', true, d.exists('shift-hours'));
      await tapIn('hours-mode', 'Start / end');
      await type('shift-start', '20:00');
      await type('shift-end', '02:30');
      await type('shift-cash', '210');
      await type('shift-card', '180');
      await type('shift-tipin', '40');
      await save();
      log.check('best hourly rate is celebrated', true, (await snackText()).contains('best hourly rate'));
      log.check('s4 row', r'$462.50', await text('shift-row-total-4'));
      log.check('this week on the Shifts tab', r'$929.41', await text('week-total'));
      log.check('all jobs: the Settings pay period (weekly)', r'Weekly pay 9 Nov to 15 Nov: $929.41', await text('pay-period-total'));
      await tapKey('filter-job-1');
      log.check('Luna picked: its own every-2-weeks pay period', r'Every 2 weeks pay 9 Nov to 22 Nov: $466.91', await text('pay-period-total'));
      await tapKey('filter-all');

      // ---------------- edit, discard, delete + undo ----------------
      await tapKey('shift-row-1');
      log.check('edit shows saved card amount', '141.50', tester.widget<TextField>(find.byKey(const Key('shift-card'))).controller!.text);
      await type('shift-card', '151.50');
      await save();
      log.check('s1 after fixing card tips', r'$210.15', await text('shift-row-total-1'));

      await tapKey('shift-row-2');
      await type('shift-cash', '125');
      await back();
      log.check('Back with changes asks first', true, d.exists('keep-editing'));
      await tapKey('keep-editing');
      log.check('Keep editing stays on the shift', true, d.exists('shift-form'));
      await back();
      await tapKey('discard');
      log.check('Discard leaves s2 as it was', r'$201.04', await text('shift-row-total-2'));

      await tapKey('shift-row-3');
      await tapKey('shift-menu');
      await tapKey('shift-delete');
      await tapKey('confirm-ok');
      await d.waitUntil(() => find.byKey(const Key('shift-row-3')).evaluate().isEmpty, 's3 gone');
      await tester.tap(find.byKey(const Key('undo-delete')));
      await d.waitFor(find.byKey(const Key('shift-row-3')));
      log.check('Undo brings the deleted shift back intact', r'$65.72', await text('shift-row-total-3'));

      // ---------------- app killed mid-entry, draft resumes ----------------
      clock.now = DateTime(2026, 11, 15, 12, 0);
      await tapKey('add-shift');
      await type('shift-start', '17:00');
      await type('shift-cash', '50');
      await tester.pumpAndSettle();
      await start(); // the phone killed the app; it opens again
      await d.waitFor(find.byKey(const Key('add-shift')));
      await tapKey('add-shift');
      await d.waitFor(find.byKey(const Key('draft-resume')));
      await tapKey('draft-resume');
      log.check('draft brings back the start time', '17:00', tester.widget<TextField>(find.byKey(const Key('shift-start'))).controller!.text);
      log.check('draft brings back the cash', '50', tester.widget<TextField>(find.byKey(const Key('shift-cash'))).controller!.text);
      await back();
      await tapKey('discard');
      log.check('discarded draft is gone', null, prefs.getString(TipPrefs.draftKey));
      final autoDays = phone.backups
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('tips-auto-'))
          .map((n) => n.substring('tips-auto-'.length, 'tips-auto-'.length + 8))
          .toList()
        ..sort();
      log.check('one backup on each day with a save or a launch, never two', '20261109 20261111 20261113 20261114 20261115', autoDays.join(' '));

      // ---------------- week two ----------------
      clock.now = DateTime(2026, 11, 16, 23, 0);
      await tapKey('add-shift');
      await tapKey('shift-job-1');
      await tapIn('hours-mode', 'Total');
      await type('shift-hours', '6');
      await type('shift-cash', '100');
      await type('shift-card', '100');
      await type('shift-sales', '1000');
      await save();
      log.check('s5 row', r'$182.78', await text('shift-row-total-5'));

      clock.now = DateTime(2026, 11, 21, 11, 0);
      await tapKey('add-shift');
      log.check('job stays Luna after a Luna shift', true, tester.widget<ChoiceChip>(find.byKey(const Key('shift-job-1'))).selected);
      await tapKey('day-yesterday');
      log.check('Yesterday chip sets Friday', 'Fri 20 Nov', await text('shift-date-label'));
      await type('shift-hours', '6');
      await type('shift-cash', '150');
      await type('shift-card', '150');
      await type('shift-sales', '1500');
      await save();
      log.check('s6 row', r'$267.78', await text('shift-row-total-6'));

      // ---------------- stats ----------------
      clock.now = DateTime(2026, 11, 22, 10, 0);
      await start(); // a new day: open the app again
      await d.waitFor(find.byKey(const Key('add-shift')));
      await shots.take('04_shifts');
      await tapKey('tab-stats');
      log.check('this week take-home', r'$450.56', await text('stats-takehome'));
      log.check('this week hourly', r'$37.55/h', await text('stats-rate'));
      log.check('this week hours', '12h', await text('stats-hours'));
      await tapKey('stats-prev');
      log.check('last week title', '9 Nov 2026 to 15 Nov 2026', await text('stats-period'));
      log.check('last week take-home', r'$939.41', await text('stats-takehome'));
      log.check('last week hourly', r'$36.48/h', await text('stats-rate'));
      log.check('last week hours', '25h 45m', await text('stats-hours'));
      log.check('last week shifts', '4', await text('stats-count'));
      log.check('last week tipped out', r'− $76.60', await text('stats-tipout'));
      log.check('last week cash', r'$476.00', await text('stats-cash'));
      log.check('last week card', r'$426.50', await text('stats-card'));
      log.check('last week tip-in', r'$40.00', await text('stats-tipin'));
      log.check('last week wages', r'$73.51', await text('stats-wages'));
      log.check('last week tax set-aside 15%', r'$140.91', await text('stats-tax'));
      await tapKey('stats-bar-4'); // Friday's bar
      log.check('tapping a day’s bar names it', 'Fri 13 Nov', await text('stats-bar-title'));
      log.check('and shows its numbers', r'$528.22 take-home · 12h · $44.02/h · 2 shifts', (await text('stats-bar-numbers')).replaceAll('\u2060', ''));
      {
        // Readable: WCAG asks 4.5:1 for body text.
        double lum(Color c) {
          double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
          return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
        }
        final bg = tester.widget<Card>(find.byKey(const Key('stats-bar-detail'))).color!;
        final fg = tester.renderObject<RenderParagraph>(find.byKey(const Key('stats-bar-numbers'))).text.style!.color!;
        final l1 = lum(bg), l2 = lum(fg);
        final ratio = (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
        log.check('bar detail text is readable on its card (contrast at least 4.5)', true, ratio >= 4.5, why: 'contrast ${ratio.toStringAsFixed(1)}:1');
      }
      await shots.take('08_stats_week_bar');
      await tapKey('stats-bar-4');
      log.check('tapping it again closes it', false, d.exists('stats-bar-detail'));
      await tapIn('stats-kind', 'Month');
      log.check('month title', 'November 2026', await text('stats-period'));
      log.check('November take-home', r'$1,389.97', await text('stats-takehome'));
      log.check('November hourly', r'$36.82/h', await text('stats-rate'));
      log.check('November hours', '37h 45m', await text('stats-hours'));
      log.check('November tax set-aside', r'$208.50', await text('stats-tax'));
      await tapKey('stats-bar-2');
      log.check('a month’s week bar', r'9 Nov to 15 Nov: $939.41 take-home · 25h 45m · $36.48/h · 4 shifts',
          '${await text('stats-bar-title')}: ${(await text('stats-bar-numbers')).replaceAll('\u2060', '')}');
      await tapKey('stats-bar-close');
      log.check('best night', 'Fridays pay best', await text('stats-best-day'));
      log.check('best night detail', true, (await d.textsIn('stats-best-night')).contains(r'$44.22/h over 3 shifts'));
      log.check('Luna hourly in November', r'$29.68/h', await text('stats-job-rate-1'));
      log.check('Dock hourly in November', r'$71.15/h', await text('stats-job-rate-2'));
      await shots.take('05_stats_month');

      await tapKey('stats-export');
      await tapKey('export-pdf');
      await d.waitUntil(() => sharer.shared.isNotEmpty, 'pdf shared');
      log.keep(sharer.shared.last, 'november.pdf');
      await tapKey('stats-export');
      await tapKey('export-csv');
      await d.waitUntil(() => sharer.shared.length == 2, 'csv shared');
      final csv = log.keep(sharer.shared.last, 'november.csv').readAsStringSync();
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();
      log.check('CSV has header, 6 shifts and a total', 8, lines.length);
      log.check('CSV total take-home', true, lines.last.startsWith('Total') && lines.last.contains(',1389.97,'));
      log.check('CSV marks the changed tip-out', true, lines.any((l) => l.startsWith('2026-11-13,Luna Bistro') && l.contains(',10.00,yes,')));

      // Back from any tab but Shifts goes to Shifts.
      await back();
      log.check('Back on Stats goes to Shifts', true, d.exists('add-shift'));

      // ---------------- archive a job: its shifts still count ----------------
      await tapKey('tab-jobs');
      log.check('Luna tile: this month’s take-home', r'$927.47', await text('job-month-1'));
      log.check('Dock tile: this month’s take-home', r'$462.50', await text('job-month-2'));
      log.check('Luna tile says how it pays', true, (await text('job-sub-1')).contains('every 2 weeks pay'));
      await tapKey('job-2');
      await tapKey('job-menu');
      await tapKey('job-archive');
      await d.waitFor(find.byKey(const Key('archived-jobs')));
      await tapKey('tab-stats');
      log.check('archived job still counts in November', r'$1,389.97', await text('stats-takehome'));

      // ---------------- backup: save off the phone ----------------
      await tapKey('tab-settings');
      log.check('About names the version and the maker', true,
          (await text('settings-about-text')).endsWith('Version 0.1.0 · Made by Devs at Widdle Studios'));
      await tapKey('settings-backup');
      log.check('last backup is the daily one from today', true, (await text('backup-last')).startsWith('Today'));
      log.check('never saved off the phone yet', 'Never saved off this phone', await text('backup-offdevice'));
      // A full phone: the backup fails, says why, and leaves nothing behind.
      List<String> files() => phone.backups.listSync().map((f) => f.uri.pathSegments.last).toList()..sort();
      final before = files();
      diskFull = true;
      await tapKey('backup-now');
      await d.waitFor(find.textContaining('storage is full'));
      log.check('storage full: the backup says so', true, (await snackText()).contains('Your shifts are safe and unchanged'));
      log.check('storage full: no half-written file left', before, files());
      log.check('storage full: nothing was shared', 2, sharer.shared.length);
      diskFull = false;
      await tapKey('backup-now');
      await d.waitUntil(() => sharer.shared.length == 3, 'backup shared');
      final backupFile = log.keep(sharer.shared.last, 'tips-backup.json');
      final backupBytes = backupFile.readAsBytesSync();
      log.check('off-phone save is shown', true, (await text('backup-offdevice')).contains('Today'));
      await shots.take('06_backup');

      // ---------------- files that must be refused ----------------
      Future<String> refusal(Uint8List bytes) async {
        nextPick = bytes;
        await tapKey('backup-restore-file');
        await d.waitFor(find.byKey(const Key('restore-refused')));
        final why = await text('restore-refused-reason');
        await d.tap(find.text('OK'));
        return why;
      }

      final good = utf8.decode(backupBytes);
      log.check(
        'a spreadsheet is not a backup',
        'This isn’t a Tipwell backup file.',
        await refusal(Uint8List.fromList(utf8.encode(csv))),
      );
      log.check(
        'a cut-off download is refused',
        'This isn’t a Tipwell backup file.',
        await refusal(Uint8List.sublistView(backupBytes, 0, backupBytes.length ~/ 2)),
      );
      log.check(
        'an edited amount fails the checksum',
        'This backup file was changed or is incomplete, so it can’t be trusted.',
        await refusal(Uint8List.fromList(utf8.encode(good.replaceFirst('"cashCents": 8200', '"cashCents": 9200')))),
      );
      log.check(
        'a backup from a newer version is refused',
        'This backup was made by a newer version. Update the app to restore it.',
        await refusal(Uint8List.fromList(utf8.encode(good.replaceFirst('"formatVersion": 1', '"formatVersion": 2')))),
      );
      log.check('refused files changed nothing', 6, (await phone.db.select(phone.db.shifts).get()).length);

      // ---------------- restore an older daily backup, then undo it ----------------
      final daily = phone.backups.listSync().firstWhere((f) => f.path.contains('tips-auto-20261115')) as File;
      // First with the phone full: the safety copy can't be written, so the
      // restore must not start.
      diskFull = true;
      await tapKey('backup-row-${daily.uri.pathSegments.last}');
      await d.waitFor(find.byKey(const Key('restore-preview')));
      await tapKey('restore-confirm');
      await d.waitFor(find.textContaining('Nothing was changed'));
      log.check('storage full: a restore changes nothing', 6, (await phone.db.select(phone.db.shifts).get()).length);
      diskFull = false;
      await tapKey('backup-row-${daily.uri.pathSegments.last}');
      await d.waitFor(find.byKey(const Key('restore-preview')));
      log.check('preview of the 15 Nov backup', '4 shifts and 2 jobs, 9 Nov 2026 to 13 Nov 2026', await text('restore-preview-counts'));
      await shots.take('07_restore_preview');
      await tapKey('restore-confirm');
      await d.waitFor(find.textContaining('Restored 4 shifts'));
      log.check('restore replaced the data', 4, (await phone.db.select(phone.db.shifts).get()).length);
      final safety = phone.backups.listSync().firstWhere((f) => f.path.contains('tips-safety-')) as File;
      await tapKey('backup-row-${safety.uri.pathSegments.last}');
      await d.waitFor(find.byKey(const Key('restore-preview')));
      log.check('the safety copy holds what was replaced', '6 shifts and 2 jobs, 9 Nov 2026 to 20 Nov 2026', await text('restore-preview-counts'));
      await tapKey('restore-confirm');
      await d.waitFor(find.textContaining('Restored 6 shifts'));
      log.check('each restore kept a safety copy', 2, phone.backups.listSync().where((f) => f.path.contains('tips-safety-')).length);
      log.check('undoing the restore brings all 6 shifts back', 6, (await phone.db.select(phone.db.shifts).get()).length);
      await back();
      await tapKey('tab-shifts');
      log.check('edited s1 survived both restores', r'$210.15', await text('shift-row-total-1'));

      // ---------------- lost phone: fresh install restores the saved file ----------------
      phone = Phone(await Directory('${root.path}/phone2').create());
      await prefs.clear();
      await start();
      for (var i = 0; i < 3; i++) {
        await tapKey('onboarding-next');
      }
      await d.waitFor(find.byKey(const Key('first-run-restore')));
      nextPick = backupBytes;
      await tapKey('first-run-restore');
      await d.waitFor(find.byKey(const Key('restore-preview')));
      log.check('new phone preview', '6 shifts and 2 jobs, 9 Nov 2026 to 20 Nov 2026', await text('restore-preview-counts'));
      await tapKey('restore-confirm');
      await d.waitFor(find.byKey(const Key('add-shift')));
      await skipTourIfShown();
      log.check('new phone has every shift', r'$267.78', await text('shift-row-total-6'));
      await tapKey('tab-stats');
      await tapIn('stats-kind', 'Month');
      log.check('new phone November take-home', r'$1,389.97', await text('stats-takehome'));
      await tapKey('tab-jobs');
      log.check('archived job is still archived', true, d.exists('archived-jobs'));
      await shots.take('09_jobs');

      // ---------------- dark theme from Settings ----------------
      await tapKey('tab-settings');
      await tapKey('settings-theme');
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      log.check('Settings switches the app to dark', Brightness.dark,
          Theme.of(tester.element(find.byKey(const Key('settings-theme')))).brightness);
      await tapKey('tab-shifts');
      log.check('dark: shifts still all there', r'$267.78', await text('shift-row-total-6'));
      await shots.take('10_dark_shifts');
      await tapKey('tab-stats');
      await shots.take('11_dark_stats');
      await start();
      await d.waitFor(find.byKey(const Key('add-shift')));
      log.check('reopened: still dark', Brightness.dark,
          Theme.of(tester.element(find.byKey(const Key('add-shift')))).brightness);

      // ---------------- damaged data: an orphan shift ----------------
      int autoBackups() => phone.backups.existsSync() ? phone.backups.listSync().where((f) => f.path.contains('auto')).length : 0;
      // Reopening in dark above made today's daily backup; clear it so this
      // check sees whether damaged data would make one.
      for (final f in phone.backups.listSync().where((f) => f.path.contains('auto'))) {
        f.deleteSync();
      }
      await phone.db.customStatement('PRAGMA foreign_keys = OFF');
      await phone.db.customStatement(
        "INSERT INTO shifts (id, job_id, day, break_minutes, minutes, cash_cents, card_cents, tip_in_cents, tip_out_cents, "
        "tip_out_edited, rate_cents, rule_kind, rule_value, note, created_at, updated_at) "
        "VALUES (99, 999, '2026-11-21', 0, 60, 100, 0, 0, 0, 0, 0, 'none', 0, '', 0, 0)",
      );
      await phone.db.customStatement('PRAGMA foreign_keys = ON');
      await start();
      await d.waitFor(find.byKey(const Key('repair-screen')));
      log.check('damaged data opens the repair screen', true, d.exists('repair-restore-file'));
      log.check('no daily backup is made of damaged data', 0, autoBackups());
      final sharedBefore = sharer.shared.length;
      await tapKey('repair-export');
      await d.waitUntil(() => sharer.shared.length == sharedBefore + 1, 'readable shifts shared');
      final rescued = const LineSplitter()
          .convert(log.keep(sharer.shared.last, 'rescued-from-damaged-data.csv').readAsStringSync())
          .where((l) => l.isNotEmpty)
          .toList();
      log.check('Export what’s readable: header, 7 shifts (6 + the orphan), total', 9, rescued.length);
      log.check('Export what’s readable changed nothing', 7, (await phone.db.select(phone.db.shifts).get()).length);
      nextPick = backupBytes;
      await tapKey('repair-restore-file');
      await d.waitFor(find.byKey(const Key('restore-preview')));
      await tapKey('restore-confirm');
      await d.waitFor(find.byKey(const Key('add-shift')));
      log.check('repaired: orphan gone, 6 shifts left', 6, (await phone.db.select(phone.db.shifts).get()).length);
      log.check('health check is clean after repair', <String>[], await phone.db.healthProblems());
    } finally {
      log.inputs['shifts'] = [
        's1 Mon 9 Nov 16:00-23:00 break 30, cash 82, card 141.50 then 151.50, sales 1240',
        's2 Tue 10 Nov 6:00 pm-01:15, cash 120, card 95, sales 980',
        's3 Fri 13 Nov 5.5 h, cash 64, sales 610, tip-out changed to 10',
        's4 Fri 13 Nov Dock Bar 20:00-02:30, cash 210, card 180, tip-in 40',
        's5 Mon 16 Nov 6 h, cash 100, card 100, sales 1000',
        's6 Fri 20 Nov 6 h, cash 150, card 150, sales 1500',
      ];
      log.write();
      await shots.take('99_last_screen').catchError((_) {});
    }
    for (final f in log.failures) {
      debugPrint('FAILED: ${f['name']}: expected ${f['expected']}, saw ${f['observed']}');
    }
    expect(log.failures, isEmpty);
  });
}
