import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/repository.dart';
import '../domain/pay_engine.dart';
import '../domain/time_format.dart';
import '../export/timesheet_export.dart';
import 'fields.dart';

enum Period { thisWeek, lastWeek, lastTwoWeeks, thisMonth, custom }

class PayTab extends ConsumerStatefulWidget {
  const PayTab({super.key});

  @override
  ConsumerState<PayTab> createState() => _PayTabState();
}

class _PayTabState extends ConsumerState<PayTab> {
  Period _period = Period.thisWeek;
  final _from = TextEditingController();
  final _to = TextEditingController();
  (DateTime, DateTime)? _custom;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  (DateTime, DateTime)? _range(Job job) {
    final rules = rulesFor(job);
    final now = ref.read(clockProvider)();
    final wk = weekStartOf(workdayOf(now, rules.workdayStartMinute), rules.weekStartsOn);
    DateTime add(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);
    return switch (_period) {
      Period.thisWeek => (wk, add(wk, 7)),
      Period.lastWeek => (add(wk, -7), wk),
      Period.lastTwoWeeks => (add(wk, -14), wk),
      Period.thisMonth => (DateTime(now.year, now.month), DateTime(now.year, now.month + 1)),
      Period.custom => _custom,
    };
  }

  void _applyCustom() {
    final f = parseIsoDate(_from.text), t = parseIsoDate(_to.text);
    if (f == null || t == null || t.isBefore(f)) {
      showSnack(context, 'Enter a start and end date, end on or after start.');
      return;
    }
    setState(() => _custom = (f, DateTime(t.year, t.month, t.day + 1)));
  }

  Future<void> _export(Job job, PaySummary s, DateTime from, DateTime to, {required bool pdf}) async {
    if (!await requirePro(context, ref, featureExport)) return;
    final exporter = ref.read(exportServiceProvider);
    final base = timesheetFileBase(job, from, to);
    final ExportedFile file;
    if (pdf) {
      final bytes = await buildTimesheetPdf(
        job,
        s,
        from,
        to,
        ref.read(coreSettingsProvider).currency,
        ref.read(clockProvider)(),
      );
      file = await exporter.writePdf('$base.pdf', bytes);
    } else {
      final rows = await ref
          .read(repositoryProvider)
          .watchShifts(job.id, DateTime(from.year, from.month, from.day - 1), DateTime(to.year, to.month, to.day + 1))
          .first;
      final notes = {for (final r in rows) '${r.id}': r.note};
      file = await exporter.writeCsv('$base.csv', buildTimesheetCsv(job, s, from, to, notes));
    }
    await exporter.share(file, subject: 'Timesheet ${job.name} ${periodText(from, to)}');
    await ref.read(ratingPrompterProvider).recordCompletedTask();
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(currentJobProvider);
    if (job == null) return const SizedBox.shrink();
    final currency = ref.watch(coreSettingsProvider).currency;
    final range = _range(job);
    final pay = range == null ? null : ref.watch(payProvider((jobId: job.id, from: range.$1, toExclusive: range.$2)));
    final s = pay?.value?.$2;
    String m(int c) => Money.format(c, currency: currency);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (p, label) in const [
                (Period.thisWeek, 'This week'),
                (Period.lastWeek, 'Last week'),
                (Period.lastTwoWeeks, 'Last 2 weeks'),
                (Period.thisMonth, 'This month'),
                (Period.custom, 'Custom'),
              ])
                ChoiceChip(
                  key: Key('period-${p.name}'),
                  label: Text(label),
                  selected: _period == p,
                  onSelected: (_) => setState(() => _period = p),
                ),
            ],
          ),
        ),
        if (_period == Period.custom)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DateField(controller: _from, label: 'From', fieldKey: const Key('custom-from')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DateField(controller: _to, label: 'To (inclusive)', fieldKey: const Key('custom-to')),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(key: const Key('custom-apply'), onPressed: _applyCustom, child: const Text('Show')),
                ),
              ],
            ),
          ),
        if (range != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(periodText(range.$1, range.$2), key: const Key('pay-period')),
          ),
        if (s != null) _PayHero(s: s, money: m),
        if (s != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(
                    'Regular',
                    s.regularMin,
                    s.regularPayCents,
                    m,
                    'pay-regular',
                    Theme.of(context).colorScheme.primary,
                  ),
                  _line('Overtime', s.overtimeMin, s.overtimePayCents, m, 'pay-ot', BrandColors.of(context).accent),
                  _line('Double time', s.doubleMin, s.doublePayCents, m, 'pay-dt', BrandColors.of(context).warning),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${hm(s.workedMin)} over ${s.shifts.length} ${s.shifts.length == 1 ? 'shift' : 'shifts'}',
                        key: const Key('pay-hours'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (s != null && range != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('export-csv'),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('CSV'),
                    onPressed: s.shifts.isEmpty ? null : () => _export(job, s, range.$1, range.$2, pdf: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('export-pdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF timesheet'),
                    onPressed: s.shifts.isEmpty ? null : () => _export(job, s, range.$1, range.$2, pdf: true),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _line(String label, int min, int cents, String Function(int) m, String key, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text('${decimalHours(min)} h', key: Key('$key-hours')),
        const SizedBox(width: 16),
        SizedBox(
          width: 110,
          child: Text(
            m(cents),
            key: Key('$key-pay'),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Total pay counting up, with a bar showing how it splits between regular,
/// overtime and double time.
class _PayHero extends StatelessWidget {
  const _PayHero({required this.s, required this.money});
  final PaySummary s;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BrandColors.of(context);
    final regular = theme.colorScheme.primaryContainer;
    return BrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PAY',
            style: TextStyle(
              color: brand.onBrand.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          CountUpText(
            value: s.payCents.toDouble(),
            format: (v) => money(v.round()),
            textKey: const Key('pay-total'),
            style: theme.textTheme.displaySmall?.copyWith(color: brand.onBrand, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          AnimatedSplitBar(
            key: const Key('pay-split'),
            parts: [
              ChartPart(s.regularPayCents.toDouble(), regular),
              ChartPart(s.overtimePayCents.toDouble(), brand.accent),
              ChartPart(s.doublePayCents.toDouble(), Color.lerp(brand.warning, Colors.white, 0.15)!),
            ],
            semanticsLabel:
                'Pay split. Regular ${money(s.regularPayCents)}, '
                'overtime ${money(s.overtimePayCents)}, double time ${money(s.doublePayCents)}.',
          ),
        ],
      ),
    );
  }
}
