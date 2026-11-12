/// RFC 4180 CSV writer.
///
/// Cells that start with = + - @ (or tab / carriage return) are prefixed with
/// an apostrophe so a spreadsheet does not run them as formulas (CSV
/// injection), except plain numbers like "-12.50", which stay numeric.
class CsvWriter {
  final _rows = <List<String>>[];

  void row(List<Object?> cells) => _rows.add(cells.map(_cell).toList());

  void blank() => _rows.add(const []);

  static final _number = RegExp(r'^-?\d+(\.\d+)?$');

  static String _cell(Object? v) {
    var s = v?.toString() ?? '';
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0]) && !_number.hasMatch(s)) {
      s = "'$s";
    }
    if (s.contains(RegExp('[",\n\r]'))) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// CRLF line endings and a UTF-8 BOM so Excel opens accents correctly.
  String build({bool bom = true}) {
    final body = _rows.map((r) => r.join(',')).join('\r\n');
    return '${bom ? '﻿' : ''}$body\r\n';
  }
}
