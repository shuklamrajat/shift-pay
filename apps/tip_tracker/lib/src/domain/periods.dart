/// Calendar helpers. Shift days are stored as "YYYY-MM-DD" text so a phone
/// changing time zone never moves a shift to another day.
library;

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDay(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// The day a shift being logged right now most likely belongs to: before
/// 5 AM it's last night's shift.
DateTime defaultShiftDay(DateTime now) => now.hour < 5 ? addDays(dateOnly(now), -1) : dateOnly(now);

DateTime weekStart(DateTime d, int weekStartsOn) {
  final day = dateOnly(d);
  final back = (day.weekday - weekStartsOn + 7) % 7;
  return addDays(day, -back);
}

enum PeriodKind { week, month, year, all }

/// A half-open range of days [from, to).
class Period {
  const Period(this.kind, this.from, this.to);
  final PeriodKind kind;
  final DateTime from;
  final DateTime to;

  bool containsKey(String key) {
    final d = parseDay(key);
    return !d.isBefore(from) && d.isBefore(to);
  }

  static Period containing(PeriodKind kind, DateTime d, {required int weekStartsOn}) => switch (kind) {
    PeriodKind.week => () {
      final s = weekStart(d, weekStartsOn);
      return Period(kind, s, addDays(s, 7));
    }(),
    PeriodKind.month => Period(kind, DateTime(d.year, d.month), DateTime(d.year, d.month + 1)),
    PeriodKind.year => Period(kind, DateTime(d.year), DateTime(d.year + 1)),
    PeriodKind.all => Period(kind, DateTime(1970), DateTime(3000)),
  };

  Period shift(int steps, {required int weekStartsOn}) => switch (kind) {
    PeriodKind.week => Period(kind, addDays(from, 7 * steps), addDays(to, 7 * steps)),
    PeriodKind.month => Period(kind, DateTime(from.year, from.month + steps), DateTime(from.year, from.month + steps + 1)),
    PeriodKind.year => Period(kind, DateTime(from.year + steps), DateTime(from.year + steps + 1)),
    PeriodKind.all => this,
  };
}

enum PayPeriodKind { weekly, biweekly, semimonthly }

PayPeriodKind payPeriodKindFromName(String s) =>
    PayPeriodKind.values.firstWhere((k) => k.name == s, orElse: () => PayPeriodKind.weekly);

/// The pay period that contains [d]. [anchor] is any day a pay period
/// started on (used by weekly and every-two-weeks).
Period payPeriodContaining(DateTime d, PayPeriodKind kind, DateTime anchor) {
  final day = dateOnly(d);
  switch (kind) {
    case PayPeriodKind.semimonthly:
      if (day.day <= 15) return Period(PeriodKind.week, DateTime(day.year, day.month), DateTime(day.year, day.month, 16));
      return Period(PeriodKind.week, DateTime(day.year, day.month, 16), DateTime(day.year, day.month + 1));
    case PayPeriodKind.weekly:
    case PayPeriodKind.biweekly:
      final len = kind == PayPeriodKind.weekly ? 7 : 14;
      final a = dateOnly(anchor);
      final diff = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
      final k = (diff / len).floor();
      final start = addDays(a, k * len);
      return Period(PeriodKind.week, start, addDays(start, len));
  }
}

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String payKindLabel(PayPeriodKind k) => switch (k) {
  PayPeriodKind.weekly => 'Weekly',
  PayPeriodKind.biweekly => 'Every 2 weeks',
  PayPeriodKind.semimonthly => 'Twice a month',
};
