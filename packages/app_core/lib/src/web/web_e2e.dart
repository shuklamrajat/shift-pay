// Platform pieces for the browser test build (flutter build web). Phones and
// desktop never import this file.
//
// The apps keep photos and exports as files. Browsers have no file system, so
// this installs a small in-memory one (IOOverrides) that persists the
// attachments folder in localStorage, so photos survive a reload like they do
// on a phone. Exports are handed to the browser as downloads, which the
// Playwright tests capture and check byte for byte.
import 'dart:convert';
import 'dart:io';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

import '../export/export_service.dart';

const _persistPrefix = 'memfs:';

final Map<String, Uint8List> _files = {};
final Set<String> _dirs = {'/'};

bool _persisted(String path) => path.contains('/attachments/');

void _loadPersisted() {
  final s = web.window.localStorage;
  for (var i = 0; i < s.length; i++) {
    final k = s.key(i);
    if (k == null || !k.startsWith(_persistPrefix)) continue;
    final path = k.substring(_persistPrefix.length);
    _files[path] = base64Decode(s.getItem(k)!);
    _dirs.add(p.dirname(path));
  }
}

void _put(String path, Uint8List bytes) {
  _files[path] = bytes;
  _dirs.add(p.dirname(path));
  if (_persisted(path)) {
    web.window.localStorage.setItem('$_persistPrefix$path', base64Encode(bytes));
  }
}

void _remove(String path) {
  _files.remove(path);
  if (_persisted(path)) {
    web.window.localStorage.removeItem('$_persistPrefix$path');
  }
}

/// Number of attachment files currently stored (used by the browser tests to
/// check that deleting an item also deletes its photos).
int attachmentFileCount() => _files.keys.where(_persisted).length;

class _MemFile implements File {
  _MemFile(this.path);
  @override
  final String path;

  @override
  File get absolute => this;
  @override
  Directory get parent => _MemDir(p.dirname(path));
  @override
  Future<bool> exists() async => _files.containsKey(path);
  @override
  bool existsSync() => _files.containsKey(path);
  @override
  Future<int> length() async => _need().length;
  @override
  int lengthSync() => _need().length;
  @override
  Future<Uint8List> readAsBytes() async => _need();
  @override
  Uint8List readAsBytesSync() => _need();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      encoding.decode(_need());
  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      encoding.decode(_need());
  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    final old = mode == FileMode.append
        ? (_files[path] ?? Uint8List(0))
        : Uint8List(0);
    _put(path, Uint8List.fromList([...old, ...bytes]));
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => writeAsBytes(encoding.encode(contents), mode: mode, flush: flush);
  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    _files.putIfAbsent(path, () => Uint8List(0));
    return this;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    if (!_files.containsKey(path)) {
      throw PathNotFoundException(path, const OSError('No such file', 2));
    }
    _remove(path);
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) => _remove(path);

  Uint8List _need() {
    final b = _files[path];
    if (b == null) {
      throw PathNotFoundException(path, const OSError('No such file', 2));
    }
    return b;
  }

  @override
  String toString() => "File: '$path'";

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'In-memory web file: ${invocation.memberName} is not supported',
  );
}

class _MemDir implements Directory {
  _MemDir(this.path);
  @override
  final String path;
  @override
  Directory get absolute => this;
  @override
  Future<Directory> create({bool recursive = false}) async {
    _dirs.add(path);
    return this;
  }

  @override
  void createSync({bool recursive = false}) => _dirs.add(path);
  @override
  Future<bool> exists() async => _dirs.contains(path);
  @override
  bool existsSync() => _dirs.contains(path);
  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => Stream.fromIterable([
    for (final f in _files.keys)
      if (recursive ? p.isWithin(path, f) : p.dirname(f) == path) _MemFile(f),
  ]);
  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) => [
    for (final f in _files.keys)
      if (recursive ? p.isWithin(path, f) : p.dirname(f) == path) _MemFile(f),
  ];
  @override
  String toString() => "Directory: '$path'";
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'In-memory web directory: ${invocation.memberName} is not supported',
  );
}

final class _MemFsOverrides extends IOOverrides {
  @override
  File createFile(String path) => _MemFile(path);
  @override
  Directory createDirectory(String path) => _MemDir(path);
}

/// Hands exports to the browser as a download (the share sheet's job on a phone).
class BrowserDownloadSharer implements FileSharer {
  @override
  Future<void> share(
    File file, {
    required String mimeType,
    String? subject,
  }) async {
    final bytes = await file.readAsBytes();
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = p.basename(file.path);
    web.document.body!.append(a);
    a.click();
    a.remove();
  }
}

/// Call before runApp in the web entry point.
void installWebPlatform() {
  _loadPersisted();
  IOOverrides.global = _MemFsOverrides();
}

/// Provider overrides every app's web entry point adds.
List<Override> webPlatformOverrides() => [
  fileSharerProvider.overrideWithValue(BrowserDownloadSharer()),
  exportDirProvider.overrideWithValue(
    () async => Directory('/web/documents').create(recursive: true),
  ),
];

/// Attachments folder for apps that keep photos.
Future<Directory> webAttachmentsDir() =>
    Directory('/web/support/attachments').create(recursive: true);
