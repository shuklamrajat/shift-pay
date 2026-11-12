import 'package:intl/intl.dart';

String hm(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m.toString().padLeft(2, '0')}m';
}

/// Decimal hours with two places, the form payroll sheets use: 450 -> "7.50".
String decimalHours(int minutes) {
  final hundredths = (minutes * 100 + 30) ~/ 60; // half-up
  return '${hundredths ~/ 100}.${(hundredths % 100).toString().padLeft(2, '0')}';
}

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String clock(DateTime d, {required bool use24h}) => use24h ? hhmm(d) : DateFormat.jm().format(d);

String dayLabel(DateTime d) => DateFormat('EEE d MMM').format(d);

DateTime? parseIsoDate(String s) {
  final m = RegExp(r'^\s*(\d{4})-(\d{1,2})-(\d{1,2})\s*$').firstMatch(s);
  if (m == null) return null;
  final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
  final dt = DateTime(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) return null; // e.g. 2026-02-30
  return dt;
}

/// Parses what people type for a time: "6", "06:00", "6:30", "1830",
/// "6am", "6:30 pm", "12am". Returns minutes after midnight or null.
int? parseTimeOfDay(String input) {
  final s = input.trim().toLowerCase().replaceAll('.', '').replaceAll(' ', '');
  final m = RegExp(r'^(\d{1,2})(?::?(\d{2}))?(am|pm|a|p)?$').firstMatch(s);
  if (m == null) return null;
  var h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2) ?? '0');
  final ap = m.group(3);
  if (min > 59) return null;
  if (ap != null) {
    if (h < 1 || h > 12) return null;
    final pm = ap.startsWith('p');
    if (h == 12) h = 0;
    if (pm) h += 12;
  } else if (h > 23) {
    return null;
  }
  return h * 60 + min;
}
