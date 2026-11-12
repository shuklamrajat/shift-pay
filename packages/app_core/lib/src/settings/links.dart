import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page outside the app. Returns false when nothing could open it.
abstract class LinkOpener {
  Future<bool> open(Uri uri);
}

class SystemLinkOpener implements LinkOpener {
  const SystemLinkOpener();
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final linkOpenerProvider = Provider<LinkOpener>((ref) => const SystemLinkOpener());
