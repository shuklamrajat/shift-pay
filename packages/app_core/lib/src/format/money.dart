import 'package:intl/intl.dart';

/// Money is always held as integer minor units (cents) to avoid float drift.
class Money {
  Money._();

  static String format(int cents, {String currency = 'USD', String? locale}) {
    final f = NumberFormat.simpleCurrency(name: currency, locale: locale);
    return f.format(cents / 100);
  }

  /// Plain "1234.50" form, used in CSV so spreadsheets can sum the column.
  static String plain(int cents) {
    final neg = cents < 0;
    final abs = cents.abs();
    final s = '${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
    return neg ? '-$s' : s;
  }

  /// Parses what a person types: "12", "12.5", "12.50", "1,234.56", "\$12".
  /// Returns null for anything that is not a non-negative amount with at most
  /// two decimals.
  static int? parse(String input) {
    var s = input.trim().replaceAll(RegExp(r'[\s,$€£₹]'), '');
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(s);
    if (m == null) return null;
    final whole = int.parse(m.group(1)!);
    final frac = (m.group(2) ?? '').padRight(2, '0');
    return whole * 100 + int.parse(frac);
  }
}

/// Parses a decimal like "12.345" into thousandths (12345). Used for fuel
/// volumes and prices per unit, which commonly carry three decimals.
int? parseMilli(String input) {
  final s = input.trim().replaceAll(',', '');
  final m = RegExp(r'^(\d+)(?:\.(\d{0,3}))?$').firstMatch(s);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 1000 + int.parse((m.group(2) ?? '').padRight(3, '0'));
}

String formatMilli(int milli, {int decimals = 3}) {
  return (milli / 1000).toStringAsFixed(decimals);
}
