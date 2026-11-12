// End-to-end: Wagebird's first-run tour, across four launches, for a person
// in the EEA/UK on a slow network (Google's consent step answers late).
// The numbers refer to packages/app_core/docs/tour-failure-modes.md.
//
//   Launch 1: onboarding and the first job happen while consent is still
//             pending; no tour yet. Consent answers, then the tour starts,
//             spotlighting each real control. Taps on the scrim press nothing.
//             The app is closed on stop 3.
//   Launch 2: the tour comes back from stop 1; Back and Next work; it is
//             finished. Only then does the banner appear.
//   Launch 3: no tour. Settings replays it over the home screen; the banner
//             leaves while it runs and the spotlight follows the add button
//             as the layout moves; skipped, the banner returns.
//   Launch 4: no tour. Replayed from the Pay tab: the add button is
//             not on screen there, so stop 1 is a plain card with no spotlight.
//
// Artifacts: result.json, ad_events.txt and a PNG of each tour stop in
// $ARTIFACT_DIR/tour. Run: tool/run_e2e.sh
import 'dart:async';
import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:app_core/testing.dart';
import 'package:drift/native.dart';
import 'package:e2e_driver/e2e_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hours_tracker/src/app.dart';
import 'package:hours_tracker/src/data/repository.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const artifactRoot = String.fromEnvironment('ARTIFACT_DIR', defaultValue: 'test-artifacts/manual-tour');
const dir = '$artifactRoot/tour';
const addKey = 'add-shift';
const replayTab = 'tab-pay';
const addHiddenOnReplayTab = true;
const formKey = 'shift-date';
const homeTab = 'tab-week';

final expectedStops = [for (final s in hoursConfig.tour) (s.target, s.title)];

Future<void> setUpData(E2eDriver d) async {
  for (var i = 0; i < 3; i++) {
    await d.tapKey('onboarding-next');
  }
  await d.tapKey('add-first-job');
  await d.type('job-name', 'Warehouse');
  await d.type('job-rate', '20.00');
  await d.tapKey('save-job');
  await d.waitFor(find.byKey(const Key(addKey)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Wagebird tour: first launch, consent first, replay from Settings, ads held', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    Motion.ambient = false;
    addTearDown(() => Motion.ambient = true);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final log = E2eLog('hours_tracker: tour', dir);
    final tmp = await Directory.systemTemp.createTemp('hours_tracker_tour');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final db = HoursDb(NativeDatabase(File('${tmp.path}/app.sqlite')));
    final ads = FakeAdsPlatform(inEeaOrUk: true)..holdConsent = Completer<void>();
    final d = E2eDriver(tester);
    final layout = BannerLayout(tester);

    Widget app() => ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        appConfigProvider.overrideWithValue(hoursConfig),
        hoursDbProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(TestClock(DateTime(2026, 11, 10, 8)).call),
        fileSharerProvider.overrideWithValue(RecordingFileSharer()),
        exportDirProvider.overrideWithValue(() async => tmp),
        reviewRequesterProvider.overrideWithValue(RecordingReviewRequester()),
        linkOpenerProvider.overrideWithValue(RecordingLinkOpener()),
        adsPlatformProvider.overrideWithValue(ads),
      ],
      child: const HoursApp(),
    );
    Future<void> launch() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
    }

    bool tourShown() => d.exists('tour');
    String title() => tester.widget<Text>(find.byKey(const Key('tour-title'))).data!;
    String count() => tester.widget<Text>(find.byKey(const Key('tour-count'))).data!;
    Rect? spot() {
      final f = find.byKey(const Key('tour-spotlight'));
      return f.evaluate().isEmpty ? null : tester.getRect(f);
    }

    Rect target(String key) => tester.getRect(find.byKey(Key(key))).inflate(8);
    bool near(Rect? a, Rect b) =>
        a != null &&
        (a.left - b.left).abs() < 1 &&
        (a.top - b.top).abs() < 1 &&
        (a.right - b.right).abs() < 1 &&
        (a.bottom - b.bottom).abs() < 1;
    Future<void> tapTour(String key) async {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    Future<void> checkStop(int i, String launch) async {
      final (key, want) = expectedStops[i];
      log.check('$launch stop ${i + 1}: title', want, title());
      log.check('$launch stop ${i + 1}: count', '${i + 1} of ${expectedStops.length}', count());
      log.check(
        '$launch stop ${i + 1} (#6): spotlight on $key',
        true,
        near(spot(), target(key)),
        why: '${spot()} vs ${target(key)}',
      );
    }

    try {
      // ---- Launch 1: consent is slow.
      await launch();
      await setUpData(d);
      log.check('launch 1 (#1, #2): no tour while consent is pending', false, tourShown());
      log.check('launch 1: the consent step is still running', ['consent'], [...ads.events]);
      ads.holdConsent!.complete();
      await d.waitFor(find.byKey(const Key('tour')));
      log.check(
        'launch 1 (#2): consent form and SDK start came first, then the tour',
        ['consent', 'form', 'init'],
        [...ads.events],
      );
      log.check('launch 1 (#11): no ad requested while the tour has not been seen', 0, ads.bannerRequests);
      log.check('launch 1 (#11): no banner under the tour', false, layout.bannerShown);
      await checkStop(0, 'launch 1');
      await saveScreen(tester, '$dir/stop_1.png');
      log.files['stop_1.png'] = '$dir/stop_1.png';

      // A tap on the add button through the spotlight, and one on the scrim.
      await tester.tapAt(target(addKey).center);
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();
      log.check(
        'launch 1 (#10): taps on the tour press nothing underneath',
        [false, true],
        [d.exists(formKey), tourShown()],
      );
      await tapTour('tour-next');
      await checkStop(1, 'launch 1');
      await tapTour('tour-next');
      await checkStop(2, 'launch 1');

      // ---- Launch 2: the app was closed on stop 3.
      await launch();
      await d.waitFor(find.byKey(const Key('tour')));
      log.check('launch 2 (#4): the tour came back after closing mid-way', true, tourShown());
      await checkStop(0, 'launch 2');
      log.check('launch 2 (#9): no Back on the first stop', false, d.exists('tour-back'));
      await tapTour('tour-next');
      await tapTour('tour-back');
      log.check('launch 2 (#9): Back returns to stop 1', expectedStops[0].$2, title());
      for (var i = 1; i < expectedStops.length; i++) {
        await tapTour('tour-next');
        await checkStop(i, 'launch 2');
        await saveScreen(tester, '$dir/stop_${i + 1}.png');
        log.files['stop_${i + 1}.png'] = '$dir/stop_${i + 1}.png';
      }
      log.check(
        'launch 2 (#9): last stop has Got it and no Skip',
        [true, false, false],
        [d.exists('tour-finish'), d.exists('tour-skip'), d.exists('tour-next')],
      );
      await tapTour('tour-finish');
      log.check(
        'launch 2 (#3): finishing closes the tour and is stored',
        [false, true],
        [tourShown(), prefs.getBool(TourController.doneKey)],
      );
      await d.waitUntil(() => layout.bannerShown, 'banner after the tour');
      log.check(
        'launch 2 (#12): the banner arrives after the tour',
        [1, true],
        [ads.bannerRequests, layout.bannerSitsOnNav],
      );

      // ---- Launch 3: no tour; replay from Settings.
      await launch();
      await d.waitUntil(() => layout.bannerShown, 'banner on launch 3');
      log.check('launch 3 (#3): no tour after it was finished', false, tourShown());
      final addWithBanner = tester.getRect(find.byKey(const Key(addKey)));
      await d.tapKey('open-settings');
      await d.tapKey('settings-tour');
      await d.waitFor(find.byKey(const Key('tour')));
      log.check(
        'launch 3 (#5): Settings closed and the tour runs over home',
        [false, true],
        [d.exists('settings-privacy-policy'), d.exists(addKey)],
      );
      log.check(
        'launch 3 (#11): the banner left for the tour',
        [false, 0.0],
        [layout.bannerShown, layout.spaceAboveNav],
      );
      final addNow = tester.getRect(find.byKey(const Key(addKey)));
      log.check('launch 3: the add button moved down when the banner left', true, addNow.top > addWithBanner.top + 30);
      await checkStop(0, 'launch 3 (#7, after the move)');
      await tapTour('tour-skip');
      log.check('launch 3: skipping closes the tour', false, tourShown());
      await d.waitUntil(() => layout.bannerShown, 'banner after the replay');
      log.check('launch 3 (#12): the banner came back after the replay', true, layout.bannerSitsOnNav);

      // ---- Launch 4: replay from another tab.
      await launch();
      log.check('launch 4 (#3): still no tour after a skip', false, tourShown());
      await d.tapKey(replayTab);
      await d.tapKey('open-settings');
      await d.tapKey('settings-tour');
      await d.waitFor(find.byKey(const Key('tour')));
      if (addHiddenOnReplayTab) {
        final card = tester.getRect(find.byKey(const Key('tour-card')));
        final screen = tester.getRect(find.byKey(const Key('tour')));
        log.check(
          'launch 4 (#8): stop 1 has no spotlight when its control is off screen',
          [expectedStops[0].$2, null],
          [title(), spot()],
        );
        log.check('launch 4 (#8): its card sits in the middle', true, (card.center.dy - screen.center.dy).abs() < 2);
        await saveScreen(tester, '$dir/no_target.png');
        log.files['no_target.png'] = '$dir/no_target.png';
      } else {
        await checkStop(0, 'launch 4 (another tab)');
      }
      await tapTour('tour-next');
      await checkStop(1, 'launch 4');
      await tapTour('tour-skip');
      await d.tapKey(homeTab);
      log.check('launch 4: back to normal use', true, d.exists(addKey));
    } finally {
      File('$dir/ad_events.txt').writeAsStringSync('${ads.events.join('\n')}\n');
      log.files['ad_events.txt'] = '$dir/ad_events.txt';
      log.write();
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close().timeout(const Duration(seconds: 5), onTimeout: () {});
      semantics.dispose();
    }
    expect(log.failures, isEmpty, reason: 'see $dir/result.json');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
