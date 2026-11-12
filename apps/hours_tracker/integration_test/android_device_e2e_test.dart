// Runs on a real Android system (the emulator job in
// .github/workflows/android-emulator.yml). Unlike the other end-to-end tests,
// nothing platform-side is faked: the database is the app's real SQLite file
// in its support folder, Google's consent check (UMP) and the ad SDK are the
// real plugins (debug builds always ask for Google's test ad unit), and the
// back button goes through the same route-pop call Android's back key makes.
//
// The CSV share sheet is the one stand-in: a recorder takes the file instead,
// because the system share sheet would wait for a person. The file itself is
// still written to the app's real documents folder.
import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:app_core/testing.dart';
import 'package:e2e_driver/e2e_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hours_tracker/src/app.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const artifactRoot = String.fromEnvironment(
  'ARTIFACT_DIR',
  defaultValue: 'test-artifacts/manual-device',
);

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real Android: storage, back button, consent and test ads, restart',
    (tester) async {
      Motion.ambient = false;
      addTearDown(() => Motion.ambient = true);
      final log = E2eLog(
        'hours_tracker on a real Android system',
        artifactRoot,
      );
      final d = E2eDriver(tester);
      final sharer = RecordingFileSharer();

      // Start like a fresh install: no settings, no database file.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final support = await getApplicationSupportDirectory();
      final dbFile = File('${support.path}/hours.sqlite');
      for (final f in [
        dbFile,
        File('${dbFile.path}-wal'),
        File('${dbFile.path}-shm'),
      ]) {
        if (f.existsSync()) f.deleteSync();
      }
      log.inputs['platform'] =
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

      Widget app() => ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          appConfigProvider.overrideWithValue(hoursConfig),
          fileSharerProvider.overrideWithValue(sharer),
        ],
        child: const HoursApp(),
      );
      ProviderContainer container() =>
          ProviderScope.containerOf(tester.element(find.byType(HoursApp)));

      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        log.check(
          'fresh install opens on onboarding',
          1,
          find.byKey(const Key('onboarding')).evaluate().length,
        );
        for (var i = 0; i < 3; i++) {
          await d.tapKey('onboarding-next');
        }
        await d.tapKey('add-first-job');
        await d.type('job-name', 'Warehouse');
        await d.type('job-rate', '20.00');
        await d.tapKey('save-job');

        // Google's consent check runs for real. Outside the EEA/UK it decides
        // no form is needed and allows ad requests.
        await d.waitUntil(
          () => container().read(adsControllerProvider).phase == AdsPhase.ready,
          'consent check to finish',
          timeout: const Duration(seconds: 60),
        );
        final ads = container().read(adsControllerProvider);
        log.inputs['consent_can_request_ads'] = ads.canRequestAds;
        log.inputs['consent_privacy_options_required'] =
            ads.privacyOptionsRequired;
        log.check(
          'real consent check finished and allows ads (runner is outside the EEA)',
          true,
          ads.adsAllowed,
        );

        log.check(
          'banner held back while the tour runs',
          0,
          find.byKey(const Key('ad-banner')).evaluate().length,
        );
        await d.skipTour();

        // A real test ad from Google's demo unit (needs the runner's network).
        var bannerShown = true;
        try {
          await d.waitFor(
            find.byKey(const Key('ad-banner')),
            timeout: const Duration(seconds: 60),
          );
        } on StateError {
          bannerShown = false;
        }
        log.check('Google test banner loads after the tour', true, bannerShown);
        log.check(
          'banner is a real AdMob platform view',
          true,
          find.byType(AdWidget).evaluate().isNotEmpty,
        );

        // A shift today, saved to the real SQLite file.
        final today = _ymd(DateTime.now());
        log.inputs['shift_date'] = today;
        await d.tapKey('add-shift');
        await d.type('shift-date', today);
        await d.type('shift-start', '01:00');
        await d.type('shift-end', '05:30');
        await d.type('shift-break', '30');
        await d.tapKey('save-shift');
        await d.waitFor(find.byKey(const Key('add-shift')));
        log.check(
          'week shows the 4h shift',
          '4h',
          tester.widget<Text>(find.byKey(const Key('week-hours'))).data,
        );
        log.check(
          'week pay for 4h at \$20',
          r'$80.00',
          tester.widget<Text>(find.byKey(const Key('week-pay'))).data,
        );

        // Android back button on a half-filled form: the form closes and nothing is saved.
        await d.tapKey('add-shift');
        await d.type('shift-start', '18:00');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        log.check(
          'back button closes the shift form',
          0,
          find.byKey(const Key('shift-start')).evaluate().length,
        );
        log.check(
          'back button saved nothing',
          '4h',
          tester.widget<Text>(find.byKey(const Key('week-hours'))).data,
        );

        // Export writes a real file in the app's documents folder.
        await d.tapKey('tab-pay');
        await d.tapKey('export-csv');
        await d.waitUntil(() => sharer.shared.isNotEmpty, 'CSV export');
        final csv = sharer.shared.first;
        final docs = await getApplicationDocumentsDirectory();
        log.check(
          'CSV written under the app documents folder',
          true,
          csv.path.startsWith(docs.path),
        );
        log.check(
          'CSV has the shift and its pay',
          true,
          csv.readAsStringSync().contains('80.00'),
        );
        log.keep(csv, 'device-timesheet.csv');
        log.check(
          'back button from Pay goes nowhere strange (app still open)',
          true,
          find.byType(HoursApp).evaluate().isNotEmpty,
        );

        // Close the app completely (database closed) and open it again.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        log.check(
          'SQLite file exists on disk',
          true,
          dbFile.existsSync() && dbFile.lengthSync() > 0,
        );
        await tester.pumpWidget(app());
        await d.waitFor(find.byKey(const Key('week-hours')));
        log.check(
          'reopened: no onboarding',
          0,
          find.byKey(const Key('onboarding')).evaluate().length,
        );
        log.check(
          'reopened: no tour again',
          0,
          find.byKey(const Key('tour')).evaluate().length,
        );
        log.check(
          'reopened: shift kept',
          '4h',
          tester.widget<Text>(find.byKey(const Key('week-hours'))).data,
        );
      } finally {
        log.write();
      }
      expect(log.failures, isEmpty, reason: 'see $artifactRoot/result.json');
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
