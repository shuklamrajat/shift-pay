// End-to-end: banner ads and Google's consent flow in Wagebird, across five
// launches of the app, with a fake ad network standing in for the Google SDK
// (it has no desktop build). The failure modes this covers are listed in
// packages/app_core/docs/ads-failure-modes.md; the numbers below refer to it.
//
// Scenario A, a person in the EEA/UK:
//   1. First launch, the consent form fails (closed without an answer): no ad
//      is requested, the app works, no gap above the navigation.
//   2. Next launch the form is answered: consent, then SDK start, then one
//      banner, docked on the navigation bar, clear of the add button, never on
//      the shift form, loaded once however much the person moves around.
//      Privacy choices: the SDK withdraws ads, the banner goes and is freed;
//      allows them again, it comes back.
//   3. Offline launch: last session's consent stands, no second form.
//   4. Billing is live and the person hasn't paid: ads; they buy Pro: the
//      banner leaves at once.
// Scenario B, outside the EEA/UK: no form, no privacy row, and a banner that
// fails to load leaves no gap; it shows on the next launch.
//
// Run: tool/run_e2e.sh (passes a non-test ADMOB_BANNER_ID to prove debug
// builds still use Google's test unit).
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

const artifactRoot = String.fromEnvironment('ARTIFACT_DIR', defaultValue: 'test-artifacts/manual-ads');
const definedBannerId = String.fromEnvironment('ADMOB_BANNER_ID');
const testUnit = 'banner:${TestAdIds.androidBanner}';

class _Run {
  _Run(this.tester, this.name, this.ads) : log = E2eLog('hours_tracker: $name', '$artifactRoot/$name');
  final WidgetTester tester;
  final String name;
  final FakeAdsPlatform ads;
  final E2eLog log;
  late final Directory tmp;
  late final SharedPreferences prefs;
  late final HoursDb db;
  final clock = TestClock(DateTime(2026, 11, 10, 8));
  EntitlementService entitlements = const FreeForNowEntitlementService();

  Future<void> setUp() async {
    tmp = await Directory.systemTemp.createTemp('hours_tracker_ads');
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    db = HoursDb(NativeDatabase(File('${tmp.path}/app.sqlite')));
  }

  Widget app() => ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      appConfigProvider.overrideWithValue(hoursConfig),
      hoursDbProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock.call),
      fileSharerProvider.overrideWithValue(RecordingFileSharer()),
      exportDirProvider.overrideWithValue(() async => tmp),
      reviewRequesterProvider.overrideWithValue(RecordingReviewRequester()),
      linkOpenerProvider.overrideWithValue(RecordingLinkOpener()),
      adsPlatformProvider.overrideWithValue(ads),
      entitlementServiceProvider.overrideWithValue(entitlements),
    ],
    child: const HoursApp(),
  );

  Future<void> launch() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  Future<void> finish() async {
    File('$artifactRoot/$name/ad_events.txt').writeAsStringSync('${ads.events.join('\n')}\n');
    log.files['ad_events.txt'] = '$artifactRoot/$name/ad_events.txt';
    log.write();
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close().timeout(const Duration(seconds: 5), onTimeout: () {});
  }
}

Future<void> _firstRunSetup(E2eDriver d) async {
  for (var i = 0; i < 3; i++) {
    await d.tapKey('onboarding-next');
  }
  await d.tapKey('add-first-job');
  await d.type('job-name', 'Warehouse');
  await d.type('job-rate', '20.00');
  await d.tapKey('save-job');
  await d.waitFor(find.byKey(const Key('add-shift')));
  await d.skipTour();
}

Future<void> _logShift(E2eDriver d, String date, String start, String end) async {
  await d.tapKey('add-shift');
  await d.waitFor(find.byKey(const Key('shift-date')));
  await d.type('shift-date', date);
  await d.type('shift-start', start);
  await d.type('shift-end', end);
  await d.type('shift-break', '0');
  await d.tapKey('save-shift');
  await d.waitFor(find.byKey(const Key('week-hours')));
}

Future<void> _openSettings(E2eDriver d) async {
  await d.tapKey('open-settings');
  await d.waitFor(find.byKey(const Key('settings-privacy-policy')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
    Motion.ambient = false;
  });
  tearDown(() => Motion.ambient = true);

  testWidgets('A: EEA/UK person, consent, banner placement, privacy choices, paid Pro', (tester) async {
    final semantics = tester.ensureSemantics();
    final ads = FakeAdsPlatform(inEeaOrUk: true)..formWillBeAnswered = false;
    final r = _Run(tester, 'eea', ads);
    final log = r.log;
    final d = E2eDriver(tester);
    final layout = BannerLayout(tester);
    log.inputs['ADMOB_BANNER_ID passed to this debug run'] = definedBannerId;
    await r.setUp();
    try {
      // Launch 1: the consent form is closed without an answer.
      await r.launch();
      await _firstRunSetup(d);
      await _logShift(d, '2026-11-09', '08:00', '12:00');
      log.check('launch 1: Monday shift logged with no consent given', '4h', await d.textOf('week-hours'));
      log.check('launch 1 (#1, #2): consent asked, nothing else requested', ['consent', 'form'], [...ads.events]);
      log.check(
        'launch 1 (#12): no banner and no gap above the navigation',
        [false, 0.0],
        [layout.bannerShown, layout.spaceAboveNav],
      );
      final navTopNoAds = layout.navTop;
      await _openSettings(d);
      log.check('launch 1 (#5): no privacy choices row before any answer', false, d.exists('settings-ad-privacy'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Launch 2: the form shows again and is answered.
      ads.formWillBeAnswered = true;
      await r.launch();
      await d.waitUntil(() => layout.bannerShown, 'banner after consent');
      await tester.pumpAndSettle();
      log.check(
        'launch 2 (#1): consent, then SDK start, then one banner',
        ['consent', 'form', 'consent', 'form', 'init', testUnit],
        [...ads.events],
      );
      log.check(
        'launch 2 (#17): debug build uses Google\'s test unit, not the one passed in',
        testUnit,
        ads.events.last,
      );
      log.check('launch 2 (#9): ads show while Pro is free for everyone', true, layout.bannerShown);
      log.check('launch 2 (#11): banner sits on top of the navigation bar', true, layout.bannerSitsOnNav);
      log.check('launch 2 (#11): banner is clear of the add button', true, layout.bannerClearOfFab);
      log.check('launch 2: the dock holds the banner (60) and its seam (3), nothing more', 63.0, layout.spaceAboveNav);
      log.check('launch 2: the navigation bar stays at the bottom edge', navTopNoAds, layout.navTop);
      log.check(
        'launch 2: banner carries an "Ad" tag',
        true,
        find.descendant(of: find.byKey(const Key('ad-banner')), matching: find.text('Ad')).evaluate().isNotEmpty,
      );

      // Normal use with the banner up: log a shift, visit tabs and Settings.
      await d.tapKey('add-shift');
      await d.waitFor(find.byKey(const Key('shift-date')));
      log.check('launch 2 (#11): no banner on the shift form', false, layout.bannerShown);
      await d.type('shift-date', '2026-11-10');
      await d.type('shift-start', '09:00');
      await d.type('shift-end', '17:30');
      await d.type('shift-break', '30');
      await d.tapKey('save-shift');
      await d.waitFor(find.byKey(const Key('week-hours')));
      log.check('launch 2: Tuesday shift logged with the banner showing', '12h', await d.textOf('week-hours'));
      await d.tapKey('tab-jobs');
      await d.tapKey('tab-pay');
      await d.tapKey('tab-week');
      await _openSettings(d);
      log.check(
        'launch 2: Settings says Pro is free for now and ads keep it free',
        true,
        (await d.textsIn('settings-pro')).contains('Ads keep it free'),
      );
      log.check(
        'launch 2 (#5): privacy choices row shown once the SDK needs it',
        true,
        d.exists('settings-ad-privacy'),
      );

      // Privacy choices: the SDK stops allowing ads after the form.
      ads.privacyOptionsAllowAds = false;
      await d.tapKey('settings-ad-privacy');
      await tester.pageBack();
      await tester.pumpAndSettle();
      log.check(
        'launch 2 (#7): banner leaves straight after the change',
        [false, 0.0],
        [layout.bannerShown, layout.spaceAboveNav],
      );
      log.check('launch 2 (#15): the banner was freed', 1, ads.disposed);
      log.check('launch 2 (#14): one banner request so far, despite moving around', 1, ads.bannerRequests);

      // And allows them again.
      ads.privacyOptionsAllowAds = true;
      await _openSettings(d);
      await d.tapKey('settings-ad-privacy');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await d.waitUntil(() => layout.bannerShown, 'banner after consent restored');
      log.check('launch 2 (#7): banner returns when ads are allowed again', 2, ads.bannerRequests);

      // Launch 3: offline. The consent update fails.
      ads.updateFails = true;
      await r.launch();
      await d.waitUntil(() => layout.bannerShown, 'banner on an offline launch');
      log.check('launch 3 (#3): last consent stands when the check fails', true, layout.bannerShown);
      log.check(
        'launch 3 (#4): the form never showed again after the answer',
        2,
        ads.events.where((e) => e == 'form').length,
      );
      log.check(
        'launch 3: the SDK started once on each launch that could request ads (2 and 3)',
        2,
        ads.events.where((e) => e == 'init').length,
      );

      // Launch 4: billing is live. Not paid yet, then paid.
      final billing = LocalEntitlementService(r.prefs, allowDebugPurchase: true);
      r.entitlements = billing;
      await r.launch();
      await d.waitUntil(() => layout.bannerShown, 'banner for someone who has not paid');
      log.check('launch 4 (#9): billing live, not paid: ads show', true, layout.bannerShown);
      final freedBefore = ads.disposed;
      await billing.setPro(true);
      await tester.pumpAndSettle();
      log.check(
        'launch 4 (#8): paid Pro removes the banner at once',
        [false, 0.0],
        [layout.bannerShown, layout.spaceAboveNav],
      );
      log.check('launch 4 (#15): that banner was freed', freedBefore + 1, ads.disposed);
      await _openSettings(d);
      log.check(
        'launch 4: Settings shows Pro as active',
        true,
        (await d.textsIn('settings-pro')).contains('Pro is active'),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    } finally {
      await r.finish();
      semantics.dispose();
    }
    expect(log.failures, isEmpty, reason: 'see $artifactRoot/eea/result.json');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('B: outside the EEA/UK, no form, a failed ad leaves no gap', (tester) async {
    final semantics = tester.ensureSemantics();
    final ads = FakeAdsPlatform()..nextBannerFails = true;
    final r = _Run(tester, 'outside_eea', ads);
    final log = r.log;
    final d = E2eDriver(tester);
    final layout = BannerLayout(tester);
    await r.setUp();
    try {
      await r.launch();
      await _firstRunSetup(d);
      await d.waitUntil(() => ads.bannerRequests == 1, 'the banner request');
      await tester.pumpAndSettle();
      log.check('(#6): no consent form outside the EEA/UK', ['consent', 'init', testUnit], [...ads.events]);
      log.check(
        '(#12): the failed banner leaves no gap and no spinner',
        [false, 0.0, false],
        [layout.bannerShown, layout.spaceAboveNav, find.byType(CircularProgressIndicator).evaluate().isNotEmpty],
      );
      await _logShift(d, '2026-11-09', '08:00', '12:00');
      log.check('(#14): no retry loop after the failure', 1, ads.bannerRequests);
      await _openSettings(d);
      log.check('(#6): no privacy choices row outside the EEA/UK', false, d.exists('settings-ad-privacy'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      await r.launch();
      await d.waitUntil(() => layout.bannerShown, 'banner on the next launch');
      log.check('next launch: the banner shows and sits on the navigation', true, layout.bannerSitsOnNav);
    } finally {
      await r.finish();
      semantics.dispose();
    }
    expect(log.failures, isEmpty, reason: 'see $artifactRoot/outside_eea/result.json');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
