// Isolated scenarios for the pay engine, written from
// docs/pay-engine-failure-modes.md before the engine existed.
// Expected numbers are worked out by hand in the comments.
//
// Run with: TZ=America/New_York flutter test test/pay_engine_scenarios_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hours_tracker/src/domain/pay_engine.dart';

const h = 60; // minutes per hour

ShiftInput s(String id, DateTime start, DateTime end, {int breakMin = 0, int rate = 2000}) =>
    ShiftInput(id: id, start: start, end: end, unpaidBreakMin: breakMin, rateCents: rate);

const standard = PayRules(
  dailyRegularLimitMin: 8 * h,
  dailyDoubleLimitMin: 12 * h,
  weeklyRegularLimitMin: 40 * h,
  otMultiplierPct: 150,
  doubleMultiplierPct: 200,
  weekStartsOn: DateTime.monday,
  workdayStartMinute: 0,
);

/// Week of Mon 2 Nov 2026 plus the next Monday. Rate $20.00.
List<ShiftInput> scenarioA() => [
      s('mon-a', DateTime(2026, 11, 2, 6), DateTime(2026, 11, 2, 10)), // 4h
      s('mon-b', DateTime(2026, 11, 2, 14), DateTime(2026, 11, 2, 19)), // 5h -> day 9h
      s('tue', DateTime(2026, 11, 3, 22), DateTime(2026, 11, 4, 7), breakMin: 30), // 8.5h on Tue
      s('wed', DateTime(2026, 11, 4, 18), DateTime(2026, 11, 4, 23)), // 5h
      s('thu', DateTime(2026, 11, 5, 7), DateTime(2026, 11, 5, 20, 30)), // 13.5h
      s('fri', DateTime(2026, 11, 6, 8), DateTime(2026, 11, 6, 17), breakMin: 60), // 8h
      s('sat', DateTime(2026, 11, 7, 9), DateTime(2026, 11, 7, 15)), // 6h
      s('sun', DateTime(2026, 11, 8, 23), DateTime(2026, 11, 9, 3)), // 4h, Sunday's workday
      s('mon2', DateTime(2026, 11, 9, 8), DateTime(2026, 11, 9, 12)), // 4h, new week
    ];

void main() {
  test('A: split shifts, overnight, double time, weekly overtime without pyramiding', () {
    final r = computePay(scenarioA(), standard);
    final by = {for (final x in r.shifts) x.id: x};
    void expectShift(String id, int reg, int ot, int dt) {
      final x = by[id]!;
      expect([x.regularMin, x.overtimeMin, x.doubleMin], [reg, ot, dt], reason: id);
    }

    // Mon: 4h then 5h. Day crosses 8h one hour into the second shift.
    expectShift('mon-a', 4 * h, 0, 0);
    expectShift('mon-b', 4 * h, 1 * h, 0);
    // Tue overnight with 30 min break: 8.5h worked, all on Tuesday.
    expectShift('tue', 8 * h, 30, 0);
    expect(by['tue']!.workday, DateTime(2026, 11, 3));
    // Wed: only its own 5h (Tuesday's overnight hours are not Wednesday's).
    expectShift('wed', 5 * h, 0, 0);
    // Thu 13.5h: 8 regular, 4 at 1.5x, 1.5 at 2x. Weekly regular so far 8+8+5+8 = 29.
    expectShift('thu', 8 * h, 4 * h, 90);
    // Fri 8h regular -> weekly regular 37.
    expectShift('fri', 8 * h, 0, 0);
    // Sat 6h: only 3h left under 40 -> 3 regular, 3 weekly overtime (the later hours).
    expectShift('sat', 3 * h, 3 * h, 0);
    // Sun 23:00-03:00 belongs to Sunday, week already at 40 regular -> all overtime.
    expectShift('sun', 0, 4 * h, 0);
    expect(by['sun']!.weekStart, DateTime(2026, 11, 2));
    // Next Monday starts a fresh week.
    expectShift('mon2', 4 * h, 0, 0);
    expect(by['mon2']!.weekStart, DateTime(2026, 11, 9));

    final week = summarize(r, from: DateTime(2026, 11, 2), toExclusive: DateTime(2026, 11, 9));
    expect(week.regularMin, 40 * h);
    expect(week.overtimeMin, 12 * h + 30);
    expect(week.doubleMin, 90);
    // 40 x 20 = 800, 12.5 x 30 = 375, 1.5 x 40 = 60
    expect(week.payCents, 123500);
  });

  test('B: daylight saving nights are paid for the hours actually worked', () {
    final fallBack = DateTime(2026, 11, 1, 12).timeZoneOffset != DateTime(2026, 10, 31, 12).timeZoneOffset;
    expect(fallBack, isTrue, reason: 'run with TZ=America/New_York so DST transitions exist');

    // Fall back 1 Nov 2026 02:00 -> 01:00: 22:00 Sat to 06:00 Sun is 9 real hours.
    final fall = computePay([s('fall', DateTime(2026, 10, 31, 22), DateTime(2026, 11, 1, 6))], standard);
    expect(fall.shifts.single.workedMin, 9 * h);
    expect(fall.shifts.single.regularMin, 8 * h);
    expect(fall.shifts.single.overtimeMin, 1 * h);

    // Spring forward 8 Mar 2026 02:00 -> 03:00: 22:00 Sat to 06:00 Sun is 7 real hours.
    final spring = computePay([s('spring', DateTime(2026, 3, 7, 22), DateTime(2026, 3, 8, 6))], standard);
    expect(spring.shifts.single.workedMin, 7 * h);
    expect(spring.shifts.single.overtimeMin, 0);
  });

  test('C: a 04:00 workday start keeps a 02:00 start on the previous workday', () {
    const rules = PayRules(dailyRegularLimitMin: 8 * h, workdayStartMinute: 4 * h);
    final r = computePay([
      s('mon', DateTime(2026, 11, 2, 15), DateTime(2026, 11, 2, 22)), // 7h Monday
      s('late', DateTime(2026, 11, 3, 2), DateTime(2026, 11, 3, 6)), // 4h, still Monday's workday
    ], rules);
    final late = r.shifts.firstWhere((x) => x.id == 'late');
    expect(late.workday, DateTime(2026, 11, 2));
    // Monday total 11h -> 1 regular hour left, then 3h overtime.
    expect([late.regularMin, late.overtimeMin], [1 * h, 3 * h]);
  });

  test('D: weekly-only rules with five 10-hour days', () {
    const rules = PayRules(weeklyRegularLimitMin: 40 * h);
    final shifts = [
      for (var d = 2; d <= 6; d++) s('d$d', DateTime(2026, 11, d, 8), DateTime(2026, 11, d, 18)),
    ];
    final r = computePay(shifts, rules);
    expect(r.shifts.map((x) => x.overtimeMin).toList(), [0, 0, 0, 0, 10 * h]);
    expect(r.shifts.every((x) => x.doubleMin == 0), isTrue);
  });

  test('E: week starting Sunday regroups the same shifts', () {
    const rules = PayRules(weeklyRegularLimitMin: 40 * h, weekStartsOn: DateTime.sunday);
    final r = computePay(scenarioA(), rules);
    final sun = r.shifts.firstWhere((x) => x.id == 'sun');
    // Sun 8 Nov starts a new Sunday-based week, so its 4h are regular.
    expect(sun.weekStart, DateTime(2026, 11, 8));
    expect(sun.overtimeMin, 0);
    // Mon 2 Nov belongs to the week that started Sun 1 Nov.
    expect(r.shifts.first.weekStart, DateTime(2026, 11, 1));
  });

  test('F: a Saturday-Sunday report keeps the weekly overtime earned by Mon-Fri', () {
    final r = computePay(scenarioA(), standard);
    final weekend = summarize(r, from: DateTime(2026, 11, 7), toExclusive: DateTime(2026, 11, 9));
    expect(weekend.regularMin, 3 * h);
    expect(weekend.overtimeMin, 7 * h);
    expect(weekend.payCents, 3 * 2000 + 7 * 3000);
  });

  test('G: each shift keeps its own rate; integer rounding', () {
    final r = computePay([
      s('old', DateTime(2026, 11, 2, 9), DateTime(2026, 11, 2, 17), rate: 2000),
      s('new', DateTime(2026, 11, 3, 9), DateTime(2026, 11, 3, 17), rate: 2200),
    ], standard);
    expect(r.shifts.map((x) => x.payCents).toList(), [16000, 17600]);

    // $17.33 x 1.5 for 7 minutes = 303.275 cents -> 303
    final odd = computePay([
      s('odd', DateTime(2026, 11, 2, 0), DateTime(2026, 11, 2, 8, 7), rate: 1733),
    ], const PayRules(dailyRegularLimitMin: 8 * h));
    final x = odd.shifts.single;
    expect(x.overtimeMin, 7);
    // 480 x 1733 / 60 = 13864 regular, plus 303
    expect(x.payCents, 13864 + 303);
  });

  test('H: a break as long as the shift never produces negative time', () {
    final r = computePay([s('b', DateTime(2026, 11, 2, 9), DateTime(2026, 11, 2, 10), breakMin: 90)], standard);
    expect(r.shifts.single.workedMin, 0);
    expect(r.shifts.single.payCents, 0);
    expect(validateShift(DateTime(2026, 11, 2, 9), DateTime(2026, 11, 2, 10), 90), isNotNull);
  });

  test('I: overlapping shifts are found, touching ones are not', () {
    final existing = [
      (id: 'a', start: DateTime(2026, 11, 2, 9), end: DateTime(2026, 11, 2, 13)),
      (id: 'b', start: DateTime(2026, 11, 2, 22), end: DateTime(2026, 11, 3, 6)),
    ];
    expect(findOverlap(existing, DateTime(2026, 11, 2, 13), DateTime(2026, 11, 2, 17)), isNull);
    expect(findOverlap(existing, DateTime(2026, 11, 2, 12), DateTime(2026, 11, 2, 14)), 'a');
    expect(findOverlap(existing, DateTime(2026, 11, 3, 5), DateTime(2026, 11, 3, 9)), 'b');
    // Editing shift 'a' itself must not collide with its old self.
    expect(findOverlap(existing, DateTime(2026, 11, 2, 8), DateTime(2026, 11, 2, 12), ignoreId: 'a'), isNull);
  });
}
