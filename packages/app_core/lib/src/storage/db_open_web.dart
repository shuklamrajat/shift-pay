// The browser test build is the only web build, so the older sql.js backend
// is fine here: it is real SQLite compiled to WebAssembly, served from the
// app's own web folder (no CDN).
import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor openAppDatabase(String name) => WebDatabase.withStorage(
  // ignore: experimental_member_use
  DriftWebStorage.indexedDb(name),
  logStatements: false,
);
