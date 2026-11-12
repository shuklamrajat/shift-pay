import 'dart:typed_data';

import 'package:app_core/app_core.dart';

import '../data/database.dart';
import '../domain/pay_engine.dart';
import '../domain/time_format.dart';

String _rulesText(Job j) {
  final parts = <String>[];
  if (j.dailyLimitMin != null) parts.add('overtime after ${decimalHours(j.dailyLimitMin!)} h a day');
  if (j.dailyDoubleMin != null) parts.add('double time after ${decimalHours(j.dailyDoubleMin!)} h a day');
  if (j.weeklyLimitMin != null) parts.add('overtime after ${decimalHours(j.weeklyLimitMin!)} regular h a week');
  final rules = parts.isEmpty ? 'no overtime rules' : parts.join(', ');
  return 'Rules: $rules; overtime x${j.otPct / 100}, double x${j.doublePct / 100}.';
}

String periodText(DateTime from, DateTime toExclusive) =>
    '${isoDate(from)} to ${isoDate(DateTime(toExclusive.year, toExclusive.month, toExclusive.day - 1))}';

String timesheetFileBase(Job job, DateTime from, DateTime toExclusive) =>
    'timesheet_${job.name}_${isoDate(from)}_${isoDate(DateTime(toExclusive.year, toExclusive.month, toExclusive.day - 1))}';

String buildTimesheetCsv(Job job, PaySummary s, DateTime from, DateTime toExclusive, Map<String, String> notes) {
  final w = CsvWriter()
    ..row(['Timesheet', job.name])
    ..row(['Period', periodText(from, toExclusive)])
    ..blank()
    ..row([
      'Workday', 'Start', 'End', 'Unpaid break (min)', 'Worked (h)', 'Regular (h)', 'Overtime (h)',
      'Double time (h)', 'Rate', 'Pay', 'Note'
    ]);
  for (final x in s.shifts) {
    w.row([
      isoDate(x.workday),
      '${isoDate(x.input.start)} ${hhmm(x.input.start)}',
      '${isoDate(x.input.end)} ${hhmm(x.input.end)}',
      x.input.unpaidBreakMin,
      decimalHours(x.workedMin),
      decimalHours(x.regularMin),
      decimalHours(x.overtimeMin),
      decimalHours(x.doubleMin),
      Money.plain(x.input.rateCents),
      Money.plain(x.payCents),
      notes[x.id] ?? '',
    ]);
  }
  w
    ..blank()
    ..row(['Total hours', decimalHours(s.workedMin)])
    ..row(['Regular hours', decimalHours(s.regularMin)])
    ..row(['Overtime hours', decimalHours(s.overtimeMin)])
    ..row(['Double time hours', decimalHours(s.doubleMin)])
    ..row(['Regular pay', Money.plain(s.regularPayCents)])
    ..row(['Overtime pay', Money.plain(s.overtimePayCents)])
    ..row(['Double time pay', Money.plain(s.doublePayCents)])
    ..row(['Total pay', Money.plain(s.payCents)]);
  return w.build();
}

Future<Uint8List> buildTimesheetPdf(
    Job job, PaySummary s, DateTime from, DateTime toExclusive, String currency, DateTime generatedAt) {
  String m(int c) => Money.format(c, currency: currency);
  return buildPdfReport(
    title: 'Timesheet: ${job.name}',
    meta: [
      'Period: ${periodText(from, toExclusive)}',
      _rulesText(job),
      'Generated ${isoDate(generatedAt)} ${hhmm(generatedAt)}',
    ],
    summary: [
      ('Total hours', decimalHours(s.workedMin)),
      ('Regular', '${decimalHours(s.regularMin)} h  ${m(s.regularPayCents)}'),
      ('Overtime', '${decimalHours(s.overtimeMin)} h  ${m(s.overtimePayCents)}'),
      ('Double time', '${decimalHours(s.doubleMin)} h  ${m(s.doublePayCents)}'),
      ('Total pay', m(s.payCents)),
    ],
    tables: [
      PdfTableSection(
        heading: 'Shifts',
        headers: const ['Workday', 'Start', 'End', 'Break', 'Worked', 'Reg', 'OT', '2x', 'Pay'],
        columnAlignRight: const {3, 4, 5, 6, 7, 8},
        rows: [
          for (final x in s.shifts)
            [
              isoDate(x.workday),
              hhmm(x.input.start),
              '${hhmm(x.input.end)}${dateOnly(x.input.end) != dateOnly(x.input.start) ? ' +1' : ''}',
              '${x.input.unpaidBreakMin}m',
              decimalHours(x.workedMin),
              decimalHours(x.regularMin),
              decimalHours(x.overtimeMin),
              decimalHours(x.doubleMin),
              m(x.payCents),
            ],
        ],
        footer: ['Total pay ${m(s.payCents)}'],
      ),
    ],
    footerNote: 'Made with Shift Pay',
  );
}
