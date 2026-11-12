import 'dart:io';

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
