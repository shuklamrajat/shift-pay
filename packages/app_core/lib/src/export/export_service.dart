import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a finished file to the OS share sheet.
abstract class FileSharer {
  Future<void> share(File file, {required String mimeType, String? subject});
}

class SystemFileSharer implements FileSharer {
  @override
  Future<void> share(File file, {required String mimeType, String? subject}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: mimeType)],
      subject: subject,
    ));
  }
}

class ExportedFile {
  const ExportedFile(this.file, this.mimeType);
  final File file;
  final String mimeType;
}

class ExportService {
  ExportService(this._sharer, this._dir);
  final FileSharer _sharer;
  final Future<Directory> Function() _dir;

  static String safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_').replaceAll(RegExp('_+'), '_');

  Future<ExportedFile> write(String fileName, Uint8List bytes, String mimeType) async {
    final base = await _dir();
    final dir = Directory(p.join(base.path, 'exports'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, safeName(fileName)));
    await file.writeAsBytes(bytes, flush: true);
    return ExportedFile(file, mimeType);
  }

  Future<ExportedFile> writeCsv(String fileName, String csv) =>
      write(fileName, Uint8List.fromList(utf8.encode(csv)), 'text/csv');

  Future<ExportedFile> writePdf(String fileName, Uint8List bytes) =>
      write(fileName, bytes, 'application/pdf');

  Future<void> share(ExportedFile f, {String? subject}) =>
      _sharer.share(f.file, mimeType: f.mimeType, subject: subject);
}

final fileSharerProvider = Provider<FileSharer>((ref) => SystemFileSharer());
final exportDirProvider =
    Provider<Future<Directory> Function()>((ref) => getApplicationDocumentsDirectory);
final exportServiceProvider = Provider<ExportService>(
    (ref) => ExportService(ref.watch(fileSharerProvider), ref.watch(exportDirProvider)));
