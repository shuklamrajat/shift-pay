import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the app's on-device SQLite database. Stored in the app support
/// directory, which the OS excludes from shared storage. Nothing leaves the
/// device.
QueryExecutor openAppDatabase(String name) => driftDatabase(
      name: name,
      native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
    );
