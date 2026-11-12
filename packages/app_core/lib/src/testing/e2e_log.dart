import 'dart:convert';
import 'dart:io';

/// Collects expected-vs-observed checks from an end-to-end run and writes
/// them as result.json next to the exported files. Failing checks are kept
/// (not thrown immediately) so one run shows every mismatch.
class E2eLog {
  E2eLog(this.scenario, this.dir) {
    Directory(dir).createSync(recursive: true);
  }

  final String scenario;
  final String dir;
  final checks = <Map<String, Object?>>[];
  final inputs = <String, Object?>{};
  final files = <String, String>{};

  void check(String name, Object? expected, Object? observed, {String? why}) {
    checks.add({
      'name': name,
      'expected': expected,
      'observed': observed,
      'pass': _same(expected, observed),
      'why': ?why,
    });
  }

  static String _canon(Object? v) => jsonEncode(v, toEncodable: (o) => o.toString());
  static bool _same(Object? a, Object? b) => _canon(a) == _canon(b);

  /// Copies an exported file into the artifact folder under [as].
  File keep(File f, String as) {
    final out = f.copySync('$dir/$as');
    files[as] = out.path;
    return out;
  }

  List<Map<String, Object?>> get failures => checks.where((c) => c['pass'] != true).toList();

  void write() {
    final json = JsonEncoder.withIndent('  ', (o) => o.toString()).convert({
      'scenario': scenario,
      'timeZone': Platform.environment['TZ'] ?? DateTime.now().timeZoneName,
      'inputs': inputs,
      'files': files.keys.toList(),
      'passed': failures.isEmpty,
      'checks': checks,
    });
    File('$dir/result.json').writeAsStringSync(json);
  }
}
