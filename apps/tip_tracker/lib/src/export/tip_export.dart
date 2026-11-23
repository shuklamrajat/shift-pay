import 'dart:typed_data';

import 'package:app_core/app_core.dart';

import '../data/repository.dart';
import '../domain/periods.dart';
import '../domain/tip_math.dart';

/// Plain numbers in CSV (no currency sign) so spreadsheets can add them up.
String _n(int cents) => Money.plain(cents);

String shiftsCsv(List<Shift> shifts, Map<int, Job> jobs) {
  final w = CsvWriter()
    ..row([
      'Date',
      'Job',
      'Start',
      'End',
      'Break (min)',
      'Hours',
      'Cash tips',
      'Card tips',
      'Tip-in',
      'Sales',
      'Tip-out',
      'Tip-out edited',
      'Tips kept',
      'Hourly wage',
      'Wages',
      'Take-home',
      'Per hour',
      'Notes',
    ]);
  final sorted = [...shifts]..sort((a, b) => a.day.compareTo(b.day) != 0 ? a.day.compareTo(b.day) : a.id.compareTo(b.id));
  for (final s in sorted) {
    final m = mathOf(s);
    String hm(int? v) => v == null ? '' : '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';
    w.row([
      s.day,
      jobs[s.jobId]?.name ?? '',
      hm(s.startMinute),
      hm(s.endMinute),
      s.startMinute == null ? '' : s.breakMinutes,
      (s.minutes / 60).toStringAsFixed(2),
      _n(s.cashCents),
      _n(s.cardCents),
      _n(s.tipInCents),
      s.salesCents == null ? '' : _n(s.salesCents!),
      _n(m.tipOut),
      s.tipOutEdited ? 'yes' : '',
      _n(m.tipsKept),
      _n(s.rateCents),
      _n(m.wages),
      _n(m.takeHome),
      _n(m.perHourCents),
      s.note,
    ]);
  }
  final t = Totals(sorted.map(mathOf));
  w
    ..blank()
    ..row([
      'Total',
      '',
      '',
      '',
      '',
      (t.minutes / 60).toStringAsFixed(2),
      _n(t.cash),
      _n(t.card),
      _n(t.tipIn),
      '',
      _n(t.tipOut),
      '',
      _n(t.tipsKept),
      '',
      _n(t.wages),
      _n(t.takeHome),
      _n(t.perHourCents),
      '',
    ]);
  return w.build();
}

String periodTitle(Period p) => switch (p.kind) {
  PeriodKind.all => 'All time',
  PeriodKind.year => '${p.from.year}',
  PeriodKind.month => '${_months[p.from.month - 1]} ${p.from.year}',
  PeriodKind.week => '${_short(p.from)} to ${_short(addDays(p.to, -1))}',
};

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
String _short(DateTime d) => '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';

Future<Uint8List> shiftsPdf({
  required String appName,
  required Period period,
  required List<Shift> shifts,
  required Map<int, Job> jobs,
  required String Function(int) money,
  required int taxBp,
}) {
  final sorted = [...shifts]..sort((a, b) => a.day.compareTo(b.day));
  final t = Totals(sorted.map(mathOf));
  final byJob = <int, List<Shift>>{};
  for (final s in sorted) {
    byJob.putIfAbsent(s.jobId, () => []).add(s);
  }
  return buildPdfReport(
    title: '$appName report: ${periodTitle(period)}',
    meta: ['${t.count} shifts, ${hoursLabel(t.minutes)}'],
    summary: [
      ('Take-home', money(t.takeHome)),
      ('Per hour', money(t.perHourCents)),
      ('Tips kept', money(t.tipsKept)),
      ('Cash tips', money(t.cash)),
      ('Card tips', money(t.card)),
      if (t.tipIn > 0) ('Tip-in', money(t.tipIn)),
      ('Tipped out', money(t.tipOut)),
      ('Wages', money(t.wages)),
      ('Set aside for tax (est. ${formatPct(taxBp)})', money(applyBp(t.tipsKept + t.wages, taxBp))),
    ],
    tables: [
      PdfTableSection(
        heading: 'Shifts',
        headers: const ['Date', 'Job', 'Hours', 'Cash', 'Card', 'Tip-out', 'Wages', 'Take-home', 'Per hour'],
        columnAlignRight: const {2, 3, 4, 5, 6, 7, 8},
        rows: [
          for (final s in sorted)
            () {
              final m = mathOf(s);
              return [
                s.day,
                jobs[s.jobId]?.name ?? '',
                hoursLabel(s.minutes),
                money(s.cashCents),
                money(s.cardCents),
                money(m.tipOut),
                money(m.wages),
                money(m.takeHome),
                money(m.perHourCents),
              ];
            }(),
        ],
        footer: ['Total take-home ${money(t.takeHome)} over ${hoursLabel(t.minutes)}'],
      ),
      if (byJob.length > 1)
        PdfTableSection(
          heading: 'By job',
          headers: const ['Job', 'Shifts', 'Hours', 'Take-home', 'Per hour'],
          columnAlignRight: const {1, 2, 3, 4},
          rows: [
            for (final e in byJob.entries)
              () {
                final jt = Totals(e.value.map(mathOf));
                return [jobs[e.key]?.name ?? '', '${jt.count}', hoursLabel(jt.minutes), money(jt.takeHome), money(jt.perHourCents)];
              }(),
          ],
        ),
    ],
    footerNote: 'Tax set-aside is a rough estimate, not tax advice.',
  );
}
