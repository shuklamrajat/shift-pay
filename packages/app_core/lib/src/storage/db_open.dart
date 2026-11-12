// Native builds use SQLite through drift_flutter. Web builds (only used to run
// the browser end-to-end tests) use SQLite compiled to WebAssembly (sql.js),
// kept in IndexedDB so data survives a page reload.
export 'db_open_native.dart' if (dart.library.js_interop) 'db_open_web.dart';
