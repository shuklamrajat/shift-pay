// End-to-end on the build as it ships today: a new user sets up a warehouse job,
// logs a shift, adds a second job and exports a timesheet, all without a paywall.
//
// What could go wrong, written down before the code:
//   1. The shipped build still uses the locked stand-in, so a reviewer taps a
//      paid feature and lands on a paywall that cannot take a purchase.
//   2. Pro is unlocked, but Settings thanks the person for buying it, or its
//      Pro row still leads into the paywall.
//   3. Pro is only unlocked until the app restarts (it leans on a stored flag).
//   4. The privacy link opens another app's policy, or nothing at all, and a
//      phone with no browser gives no hint where the policy lives.
// Unlike app_e2e_test.dart, this run does NOT override the entitlement
// service: it uses exactly what a release build ships with.
//
// Run: tool/run_e2e.sh (runs this after app_e2e_test.dart)
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

const artifactRoot = String.fromEnvironment('ARTIFACT_DIR', defaultValue: 'test-artifacts/manual-free');
const policyUrl = 'https://shuklamrajat.github.io/widdle-privacy/wagebird/';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Wagebird as shipped now: every Pro feature free, privacy link', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    Motion.ambient = false; // endless decorative loops would block pumpAndSettle
    addTearDown(() => Motion.ambient = true);
    final semantics = tester.ensureSemantics();
    final log = E2eLog('hours_tracker: Wagebird as shipped now: every Pro feature free, privacy link', artifactRoot);
    final tmp = await Directory.systemTemp.createTemp('hours_tracker_free');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final db = HoursDb(NativeDatabase(File('${tmp.path}/app.sqlite')));
    final clock = TestClock(DateTime(2026, 11, 10, 8));
    final sharer = RecordingFileSharer();
    final links = RecordingLinkOpener();
    final d = E2eDriver(tester);

    // No entitlementServiceProvider override: this is the shipped default.
    Widget app() => ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        appConfigProvider.overrideWithValue(hoursConfig),
        hoursDbProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        fileSharerProvider.overrideWithValue(sharer),
        exportDirProvider.overrideWithValue(() async => tmp),
        reviewRequesterProvider.overrideWithValue(RecordingReviewRequester()),
        linkOpenerProvider.overrideWithValue(links),
      ],
      child: const HoursApp(),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    try {
      for (var i = 0; i < 3; i++) {
        await d.tapKey('onboarding-next');
      }
      await d.tapKey('add-first-job');
      await d.type('job-name', 'Warehouse');
      await d.type('job-rate', '20.00');
      await d.tapKey('save-job');
      await d.waitFor(find.byKey(const Key('add-shift')));
      await d.skipTour();
      log.check('desktop build shows no ad', false, d.exists('ad-banner'));
      await d.tapKey('add-shift');
      await d.type('shift-date', '2026-11-09');
      await d.type('shift-start', '08:00');
      await d.type('shift-end', '12:00');
      await d.type('shift-break', '0');
      await d.tapKey('save-shift');
      await d.waitFor(find.byKey(const Key('week-hours')));
      log.check('Monday 08:00-12:00 counted this week', '4h', await d.textOf('week-hours'));

      // A second job is a Pro feature: the form must open straight away.
      await d.tapKey('tab-jobs');
      await d.tapKey('add-job');
      await d.waitFor(find.byKey(const Key('job-name')));
      log.check('second job: no paywall', false, d.exists('paywall'));
      await d.type('job-name', 'Bar');
      await d.type('job-rate', '15.00');
      await d.tapKey('save-job');
      await d.waitFor(find.byKey(const Key('job-switcher')));
      log.check('two jobs saved', ['Warehouse', 'Bar'], [for (final j in await db.select(db.jobs).get()) j.name]);

      // Export is a Pro feature too.
      await d.tapKey('job-switcher');
      await d.pick('Warehouse');
      await d.tapKey('tab-pay');
      await d.tapKey('export-csv');
      await d.waitUntil(() => sharer.shared.length == 1, 'CSV export');
      log.check('export: no paywall', false, d.exists('paywall'));
      final csv = log.keep(sharer.shared.single, 'timesheet.csv').readAsStringSync();
      log.check('timesheet has the Monday shift at \$20/h', true, csv.contains('2026-11-09') && csv.contains('80.00'));

      // Settings: no thank-you for a purchase nobody made, no way into a
      // paywall, and the privacy policy opens at this app's own address.
      await d.tapKey('open-settings');
      log.check(
        'Settings says Pro is free for now',
        true,
        (await d.textsIn('settings-pro')).startsWith('Every Pro feature is free for now'),
      );
      await d.tapKey('settings-pro');
      log.check('tapping the Pro row opens no paywall', false, d.exists('paywall'));
      await d.tapKey('settings-privacy-policy');
      log.check("privacy policy opens this app's own page", [policyUrl], [for (final u in links.opened) '$u']);
      log.check('no error after the link opened', false, d.exists('privacy-link-failed'));
      links.works = false; // a phone with no browser
      await d.tapKey('settings-privacy-policy');
      await d.waitFor(find.byKey(const Key('privacy-link-failed')));
      log.check(
        'no browser: the address is shown instead',
        true,
        find
            .descendant(of: find.byKey(const Key('privacy-link-failed')), matching: find.textContaining(policyUrl))
            .evaluate()
            .isNotEmpty,
      );
      // About, at the foot of Settings: the new logo (the launcher icon's
      // artwork, drawn live) beside the app's name.
      log.check('About row names the app', 'Wagebird | ${hoursConfig.tagline}', await d.textsIn('settings-about'));
      log.check(
        'About row shows the drawn logo, not the plain brand dot',
        1,
        find
            .descendant(of: find.byKey(const Key('settings-about')), matching: find.byType(AnimatedScene))
            .evaluate()
            .length,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Close and reopen: Pro must not depend on anything stored.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await d.waitFor(find.byKey(const Key('week-hours')));
      await d.tapKey('tab-jobs');
      await d.tapKey('add-job');
      await d.waitFor(find.byKey(const Key('job-name')));
      log.check('after a restart: still no paywall for another job', false, d.exists('paywall'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      log.check('nothing about Pro was stored on the phone', <String>[], [
        for (final k in prefs.getKeys())
          if (k.toLowerCase().contains('pro')) k,
      ]);
    } finally {
      log.write();
      semantics.dispose();
    }
    expect(log.failures, isEmpty, reason: 'see $artifactRoot/result.json');
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close().timeout(const Duration(seconds: 5), onTimeout: () {});
  }, timeout: const Timeout(Duration(minutes: 4)));
}
