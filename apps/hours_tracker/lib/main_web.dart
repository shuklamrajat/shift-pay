// Entry point for the browser test build only:
//   flutter build web -t lib/main_web.dart --no-web-resources-cdn
// Same app as lib/main.dart, plus the web platform layer (in-memory files,
// downloads instead of the share sheet). Ads stay off: there is no ad SDK on web.
import 'package:app_core/app_core.dart';
import 'package:app_core/web_e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installWebPlatform();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        appConfigProvider.overrideWithValue(hoursConfig),
        ...webPlatformOverrides(),
      ],
      child: const HoursApp(),
    ),
  );
}
