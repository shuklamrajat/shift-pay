// Pay engine. See docs/pay-engine-failure-modes.md for what it guards against.
//
// Money: integer cents. A category's exact pay is minutes x rateCents x pct,
// in units of 1/6000 cent (60 minutes x 100 percent). It is rounded half-up
// only when shown, and totals are rounded once from the exact sum.

class PayRules {
  const PayRules({
    this.dailyRegularLimitMin,
    this.dailyDoubleLimitMin,
    this.weeklyRegularLimitMin,
    this.otMultiplierPct = 150,
    this.doubleMultiplierPct = 200,
    this.weekStartsOn = DateTime.monday,
    this.workdayStartMinute = 0,
  });

  /// Minutes per workday paid at the regular rate; null = no daily overtime.
  final int? dailyRegularLimitMin;

  /// Minutes per workday after which double time starts; null = no double time.
  final int? dailyDoubleLimitMin;

  /// Regular minutes per week before weekly overtime; null = no weekly overtime.
  final int? weeklyRegularLimitMin;
  final int otMultiplierPct;
  final int doubleMultiplierPct;

  /// DateTime.monday (1) .. DateTime.sunday (7).
  final int weekStartsOn;

  /// Workday boundary as minutes after midnight (e.g. 240 = 04:00).
  final int workdayStartMinute;
}

class ShiftInput {
  const ShiftInput({
    required this.id,
    required this.start,
    required this.end,
    required this.unpaidBreakMin,
    required this.rateCents,
  });
  final String id;
  final DateTime start;
  final DateTime end;
  final int unpaidBreakMin;
  final int rateCents;
}

class ShiftPay {
  ShiftPay({
    required this.input,
    required this.workday,
    required this.weekStart,
    required this.workedMin,
    required this.regularMin,
    required this.overtimeMin,
    required this.doubleMin,
    required this.exactPay,
  });
  final ShiftInput input;
  String get id => input.id;

  /// Local calendar date of the workday this shift belongs to.
  final DateTime workday;
  final DateTime weekStart;
  final int workedMin;
  final int regularMin;
  final int overtimeMin;
  final int doubleMin;

  /// Pay in 1/6000 cent.
  final int exactPay;
  int get payCents => roundExact(exactPay);
}

class PayResult {
  PayResult(this.shifts, this.rules);
  final List<ShiftPay> shifts;
  final PayRules rules;
}

class PaySummary {
  PaySummary({
    required this.shifts,
    required this.regularMin,
    required this.overtimeMin,
    required this.doubleMin,
    required this.exactRegular,
    required this.exactOvertime,
    required this.exactDouble,
  });
  final List<ShiftPay> shifts;
  final int regularMin;
  final int overtimeMin;
  final int doubleMin;
  final int exactRegular;
  final int exactOvertime;
  final int exactDouble;

  int get workedMin => regularMin + overtimeMin + doubleMin;
  int get regularPayCents => roundExact(exactRegular);
  int get overtimePayCents => roundExact(exactOvertime);
  int get doublePayCents => roundExact(exactDouble);
  int get payCents => roundExact(exactRegular + exactOvertime + exactDouble);
}

/// Half-up rounding from 1/6000 cent to whole cents.
int roundExact(int exact) => (exact + 3000) ~/ 6000;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The workday a moment belongs to, given the workday start.
DateTime workdayOf(DateTime start, int workdayStartMinute) {
  // Use wall-clock fields, not Duration subtraction, so a DST change between
  // midnight and the boundary does not move the shift to another day.
  final minuteOfDay = start.hour * 60 + start.minute;
  final d = dateOnly(start);
  return minuteOfDay < workdayStartMinute ? DateTime(d.year, d.month, d.day - 1) : d;
}

DateTime weekStartOf(DateTime workday, int weekStartsOn) {
  final back = (workday.weekday - weekStartsOn) % 7;
  return DateTime(workday.year, workday.month, workday.day - back);
}

int workedMinutes(DateTime start, DateTime end, int breakMin) {
  // Absolute instants: correct across DST changes.
  final span = end.difference(start).inMinutes;
  final w = span - breakMin;
  return w < 0 ? 0 : w;
}

/// Computes pay for one job's closed shifts. Pass whole weeks (or more) so
/// weekly overtime sees every hour of each week.
PayResult computePay(List<ShiftInput> input, PayRules rules) {
  final sorted = [...input]..sort((a, b) => a.start.compareTo(b.start));
  final out = <ShiftPay>[];

  DateTime? currentDay;
  DateTime? currentWeek;
  var dayTotal = 0; // all minutes worked so far this workday
  var weekRegular = 0; // regular minutes so far this week

  for (final sh in sorted) {
    final workday = workdayOf(sh.start, rules.workdayStartMinute);
    final week = weekStartOf(workday, rules.weekStartsOn);
    if (currentWeek != week) {
      currentWeek = week;
      weekRegular = 0;
    }
    if (currentDay != workday) {
      currentDay = workday;
      dayTotal = 0;
    }

    final worked = workedMinutes(sh.start, sh.end, sh.unpaidBreakMin);

    // Daily bands for the minutes [dayTotal, dayTotal + worked).
    final from = dayTotal;
    final to = dayTotal + worked;
    final dailyLimit = rules.dailyRegularLimitMin;
    final doubleLimit = rules.dailyDoubleLimitMin;
    int band(int lo, int? hi) {
      final a = from > lo ? from : lo;
      final b = hi == null ? to : (to < hi ? to : hi);
      return b > a ? b - a : 0;
    }

    final regularCap = dailyLimit ?? doubleLimit;
    var regularCandidate = band(0, regularCap);
    var overtime = dailyLimit == null ? 0 : band(dailyLimit, doubleLimit);
    final dbl = doubleLimit == null ? 0 : band(doubleLimit, null);
    dayTotal = to;

    // Weekly limit applies only to regular minutes (no pyramiding).
    var regular = regularCandidate;
    final weeklyLimit = rules.weeklyRegularLimitMin;
    if (weeklyLimit != null) {
      final room = weeklyLimit - weekRegular;
      regular = regularCandidate < room ? regularCandidate : (room > 0 ? room : 0);
      overtime += regularCandidate - regular;
    }
    weekRegular += regular;
    regularCandidate = 0;

    final r = sh.rateCents;
    final exact = regular * r * 100 + overtime * r * rules.otMultiplierPct + dbl * r * rules.doubleMultiplierPct;
    out.add(ShiftPay(
      input: sh,
      workday: workday,
      weekStart: week,
      workedMin: worked,
      regularMin: regular,
      overtimeMin: overtime,
      doubleMin: dbl,
      exactPay: exact,
    ));
  }
  return PayResult(out, rules);
}

/// Picks the shifts whose workday is in [from, toExclusive) out of a result
/// computed on whole weeks, and totals them.
PaySummary summarize(PayResult result, {required DateTime from, required DateTime toExclusive}) {
  final picked = result.shifts
      .where((x) => !x.workday.isBefore(dateOnly(from)) && x.workday.isBefore(dateOnly(toExclusive)))
      .toList();
  var reg = 0, ot = 0, dbl = 0, eReg = 0, eOt = 0, eDbl = 0;
  for (final x in picked) {
    final r = x.input.rateCents;
    reg += x.regularMin;
    ot += x.overtimeMin;
    dbl += x.doubleMin;
    eReg += x.regularMin * r * 100;
    eOt += x.overtimeMin * r * result.rules.otMultiplierPct;
    eDbl += x.doubleMin * r * result.rules.doubleMultiplierPct;
  }
  return PaySummary(
    shifts: picked,
    regularMin: reg,
    overtimeMin: ot,
    doubleMin: dbl,
    exactRegular: eReg,
    exactOvertime: eOt,
    exactDouble: eDbl,
  );
}

/// Null when the shift can be saved, otherwise a message for the person.
String? validateShift(DateTime start, DateTime end, int breakMin) {
  final span = end.difference(start).inMinutes;
  if (span <= 0) return 'The shift has to end after it starts.';
  if (span > 24 * 60) return 'A single shift can be at most 24 hours. Split it into two shifts.';
  if (breakMin < 0) return 'The break cannot be negative.';
  if (breakMin >= span) return 'The break is as long as the shift.';
  return null;
}

typedef ShiftSpan = ({String id, DateTime start, DateTime end});

/// Id of an existing shift that overlaps [start, end), or null. Shifts that
/// only touch (one ends 13:00, next starts 13:00) do not overlap.
String? findOverlap(Iterable<ShiftSpan> existing, DateTime start, DateTime end, {String? ignoreId}) {
  for (final e in existing) {
    if (e.id == ignoreId) continue;
    if (start.isBefore(e.end) && e.start.isBefore(end)) return e.id;
  }
  return null;
}
