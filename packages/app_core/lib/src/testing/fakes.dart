import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../ads/ads.dart';

import '../export/export_service.dart';
import '../ratings/rating_prompter.dart';
import '../settings/links.dart';

/// Test double: remembers shared files instead of opening the share sheet.
class RecordingFileSharer implements FileSharer {
  final shared = <File>[];
  @override
  Future<void> share(File file, {required String mimeType, String? subject}) async => shared.add(file);
}

/// Test double: counts review requests instead of calling the store.
class RecordingReviewRequester implements ReviewRequester {
  int requests = 0;
  @override
  Future<void> request() async => requests++;
}

/// A clock the test moves by hand.
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
}

/// Test double: remembers the pages the app tried to open. [works] false acts
/// like a phone with no browser.
class RecordingLinkOpener implements LinkOpener {
  RecordingLinkOpener({this.works = true});
  bool works;
  final opened = <Uri>[];
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return works;
  }
}

/// Test double for the ad network and Google's consent SDK, modelled on how
/// the real User Messaging Platform behaves:
/// - outside the EEA/UK no form is needed and ads may be requested;
/// - in the EEA/UK the form shows until it has been answered, and once the
///   person answers (either way) ads may be requested; until then they may not;
/// - if the consent check fails, the answer from the last session stands.
/// One instance outlives app restarts in a test, like the SDK's own storage.
class FakeAdsPlatform implements AdsPlatform {
  FakeAdsPlatform({this.inEeaOrUk = false});

  bool inEeaOrUk;

  /// Next consent form: true = the person answers it, false = it fails to
  /// load or is closed without an answer.
  bool formWillBeAnswered = true;

  /// The next consent info update fails (no network).
  bool updateFails = false;

  /// When set, the consent step waits for it to complete.
  Completer<void>? holdConsent;

  /// The next banner request comes back empty.
  bool nextBannerFails = false;

  /// What the privacy options form leaves behind: null = unchanged.
  bool? privacyOptionsAllowAds;

  bool _answered = false;
  bool? _overrideCanRequest;

  /// Everything the app asked for, in order: 'consent', 'form', 'init',
  /// 'banner:UNIT_ID', 'privacy-options', 'dispose'.
  final events = <String>[];
  int disposed = 0;

  bool get _canRequest => _overrideCanRequest ?? (!inEeaOrUk || _answered);

  ConsentResult _result() => ConsentResult(canRequestAds: _canRequest, privacyOptionsRequired: inEeaOrUk && _answered);

  @override
  bool get supported => true;

  @override
  Future<ConsentResult> gatherConsent() async {
    events.add('consent');
    // A slow network: the consent step finishes when the test says so.
    final hold = holdConsent;
    if (hold != null) {
      await hold.future;
      holdConsent = null;
    }
    if (updateFails) {
      updateFails = false;
      return _result();
    }
    if (inEeaOrUk && !_answered) {
      events.add('form');
      _answered = formWillBeAnswered;
    }
    return _result();
  }

  @override
  Future<ConsentResult> showPrivacyOptions() async {
    events.add('privacy-options');
    if (privacyOptionsAllowAds != null) _overrideCanRequest = privacyOptionsAllowAds;
    return _result();
  }

  @override
  Future<void> initialize() async => events.add('init');

  @override
  Future<LoadedBanner?> loadBanner({required String adUnitId, required int width}) async {
    events.add('banner:$adUnitId');
    if (nextBannerFails) {
      nextBannerFails = false;
      return null;
    }
    return LoadedBanner(
      widget: const ColoredBox(
        key: Key('fake-ad-content'),
        color: Color(0xFFE0E0E0),
        child: Center(child: Text('Test ad')),
      ),
      height: 60,
      dispose: () {
        disposed++;
        events.add('dispose');
      },
    );
  }

  int get bannerRequests => events.where((e) => e.startsWith('banner:')).length;
}
