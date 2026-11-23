/// Pure money and time rules for one shift. No Flutter, no database.
///
/// Money is whole cents. Percentages are basis points (300 = 3%).
library;

enum TipOutKind { none, pctSales, pctTips, flat }

TipOutKind tipOutKindFromName(String s) =>
    TipOutKind.values.firstWhere((k) => k.name == s, orElse: () => TipOutKind.none);

/// A job's tip-out rule, copied onto every shift when it is saved so a later
/// change never rewrites old nights.
class TipOutRule {
  const TipOutRule(this.kind, this.value);
  const TipOutRule.none() : kind = TipOutKind.none, value = 0;
  final TipOutKind kind;

  /// Basis points for the % kinds, cents for flat.
  final int value;

  bool get needsSales => kind == TipOutKind.pctSales;

  String describe(String Function(int cents) money) => switch (kind) {
    TipOutKind.none => 'No tip-out',
    TipOutKind.pctSales => '${formatPct(value)} of sales',
    TipOutKind.pctTips => '${formatPct(value)} of tips',
    TipOutKind.flat => '${money(value)} each shift',
  };

  @override
  bool operator ==(Object other) => other is TipOutRule && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
}

String formatPct(int bp) {
  final whole = bp ~/ 100;
  final frac = bp % 100;
  if (frac == 0) return '$whole%';
  final f = frac.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
  return '$whole.$f%';
}

/// Parses "3", "3.5", "2.25" (percent) into basis points, 0..10000.
int? parsePct(String input) {
  final s = input.trim().replaceAll('%', '');
  final m = RegExp(r'^(\d{1,3})(?:\.(\d{0,2}))?$').firstMatch(s);
  if (m == null) return null;
  final v = int.parse(m.group(1)!) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
  return v > 10000 ? null : v;
}

/// a * bp / 10000, rounded half up, for non-negative a.
int applyBp(int cents, int bp) => (cents * bp + 5000) ~/ 10000;

const maxMoneyCents = 9999999; // $99,999.99 in one field
const maxShiftMinutes = 24 * 60;
const longShiftMinutes = 16 * 60;

/// Minutes worked from a start and end minute of the day. An end at or
/// before the start means the shift ran past midnight.
int spanMinutes(int startMinute, int endMinute) {
  var end = endMinute;
  if (end <= startMinute) end += 24 * 60;
  return end - startMinute;
}

class ShiftInput {
  const ShiftInput({
    required this.minutes,
    this.cashCents = 0,
    this.cardCents = 0,
    this.tipInCents = 0,
    this.salesCents,
    required this.rateCents,
    required this.rule,
    this.tipOutOverrideCents,
  });

  final int minutes;
  final int cashCents;
  final int cardCents;
  final int tipInCents;
  final int? salesCents;
  final int rateCents;
  final TipOutRule rule;

  /// Set when the person typed tonight's tip-out themselves.
  final int? tipOutOverrideCents;
}

class ShiftMath {
  const ShiftMath({
    required this.tipsEarned,
    required this.tipsTotal,
    required this.ruleTipOut,
    required this.tipOut,
    required this.tipsKept,
    required this.wages,
    required this.takeHome,
    required this.perHourCents,
    required this.minutes,
    required this.cardCents,
    required this.cashInPocket,
  });

  /// Cash + card, the tips this person earned from guests.
  final int tipsEarned;

  /// Tips earned plus tip-in received from coworkers.
  final int tipsTotal;
  final int ruleTipOut;
  final int tipOut;
  final int tipsKept;
  final int wages;
  final int takeHome;

  /// Take-home per hour, cents, rounded.
  final int perHourCents;
  final int minutes;

  /// Card tips usually arrive on the paycheck.
  final int cardCents;

  /// Cash tips + tip-in - tip-out, assuming tip-out is paid in cash.
  final int cashInPocket;
}

int ruleTipOutFor(TipOutRule rule, {required int tipsEarned, int? salesCents}) => switch (rule.kind) {
  TipOutKind.none => 0,
  TipOutKind.pctSales => applyBp(salesCents ?? 0, rule.value),
  TipOutKind.pctTips => applyBp(tipsEarned, rule.value),
  TipOutKind.flat => rule.value,
};

ShiftMath computeShift(ShiftInput s) {
  final earned = s.cashCents + s.cardCents;
  final total = earned + s.tipInCents;
  final ruleOut = ruleTipOutFor(s.rule, tipsEarned: earned, salesCents: s.salesCents);
  final out = s.tipOutOverrideCents ?? ruleOut;
  final kept = total - out;
  final wages = (s.rateCents * s.minutes + 30) ~/ 60;
  final take = wages + kept;
  final perHour = s.minutes <= 0 ? 0 : _divRound(take * 60, s.minutes);
  return ShiftMath(
    tipsEarned: earned,
    tipsTotal: total,
    ruleTipOut: ruleOut,
    tipOut: out,
    tipsKept: kept,
    wages: wages,
    takeHome: take,
    perHourCents: perHour,
    minutes: s.minutes,
    cardCents: s.cardCents,
    cashInPocket: s.cashCents + s.tipInCents - out,
  );
}

int _divRound(int a, int b) {
  if (a >= 0) return (a + b ~/ 2) ~/ b;
  return -((-a + b ~/ 2) ~/ b);
}

/// What the editor may say about a shift before saving. [error] blocks the
/// save; [warnings] are shown but let the person save.
class ShiftCheck {
  const ShiftCheck({this.error, this.warnings = const []});
  final String? error;
  final List<String> warnings;
  bool get ok => error == null;
}

ShiftCheck checkShift({
  required DateTime day,
  required DateTime today,
  required int? startMinute,
  required int? endMinute,
  required int breakMinutes,
  required int? typedMinutes,
  required ShiftInput Function(int minutes) build,
}) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d.isAfter(t)) return const ShiftCheck(error: 'That date is in the future.');
  final int minutes;
  if (startMinute != null || endMinute != null) {
    if (startMinute == null || endMinute == null) {
      return const ShiftCheck(error: 'Enter both when you started and when you finished.');
    }
    final span = spanMinutes(startMinute, endMinute);
    if (breakMinutes < 0) return const ShiftCheck(error: 'The break can’t be negative.');
    if (breakMinutes >= span) return const ShiftCheck(error: 'The break is as long as the whole shift.');
    minutes = span - breakMinutes;
  } else {
    if (typedMinutes == null || typedMinutes <= 0) {
      return const ShiftCheck(error: 'Enter how long you worked.');
    }
    minutes = typedMinutes;
  }
  if (minutes > maxShiftMinutes) return const ShiftCheck(error: 'A shift can’t be longer than 24 hours.');
  final input = build(minutes);
  for (final v in [input.cashCents, input.cardCents, input.tipInCents, input.salesCents ?? 0, input.rateCents]) {
    if (v < 0 || v > maxMoneyCents) return const ShiftCheck(error: 'One of the amounts is too large.');
  }
  final m = computeShift(input);
  if (input.rule.kind == TipOutKind.pctSales && input.salesCents == null && input.tipOutOverrideCents == null) {
    return const ShiftCheck(error: 'Enter your sales so the tip-out can be worked out.');
  }
  final warnings = <String>[];
  if (m.tipOut > m.tipsTotal) {
    if (input.rule.kind == TipOutKind.pctTips && input.tipOutOverrideCents == null) {
      return const ShiftCheck(error: 'Tip-out is more than your tips.');
    }
    warnings.add('Tip-out is more than your tips tonight.');
  }
  if (minutes > longShiftMinutes) warnings.add('That’s a long shift. Is the time right?');
  return ShiftCheck(warnings: warnings);
}

/// Totals for a set of shifts.
class Totals {
  Totals(Iterable<ShiftMath> shifts) {
    for (final s in shifts) {
      count++;
      minutes += s.minutes;
      takeHome += s.takeHome;
      wages += s.wages;
      tipsKept += s.tipsKept;
      tipOut += s.tipOut;
      card += s.cardCents;
      cash += s.tipsEarned - s.cardCents;
      tipIn += s.tipsTotal - s.tipsEarned;
    }
  }
  int count = 0;
  int minutes = 0;
  int takeHome = 0;
  int wages = 0;
  int tipsKept = 0;
  int tipOut = 0;
  int card = 0;
  int cash = 0;
  int tipIn = 0;

  int get perHourCents => minutes == 0 ? 0 : _divRound(takeHome * 60, minutes);
}

String hoursLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

/// Parses "6", "6.5", "6:30", "6h30" into minutes.
int? parseHours(String input) {
  final s = input.trim().toLowerCase().replaceAll(' ', '');
  if (s.isEmpty) return null;
  final colon = RegExp(r'^(\d{1,2})[:h](\d{1,2})m?$').firstMatch(s);
  if (colon != null) {
    final m = int.parse(colon.group(2)!);
    if (m >= 60) return null;
    return int.parse(colon.group(1)!) * 60 + m;
  }
  final dec = RegExp(r'^(\d{1,2})(?:\.(\d{1,2}))?h?$').firstMatch(s);
  if (dec == null) return null;
  final frac = dec.group(2);
  final fracMin = frac == null ? 0 : (int.parse(frac.padRight(2, '0')) * 60 + 50) ~/ 100;
  return int.parse(dec.group(1)!) * 60 + fracMin;
}
