import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart' show featureExport;
import '../data/repository.dart';
import '../domain/periods.dart';
import '../domain/tip_math.dart';
import '../export/tip_export.dart';
import 'fields.dart';
import 'scenes.dart';

class StatsPeriod extends Notifier<(PeriodKind, int)> {
  @override
  (PeriodKind, int) build() => (PeriodKind.week, 0);
  void kind(PeriodKind k) => state = (k, 0);
  void step(int d) => state = (state.$1, state.$2 + d);
}

final statsPeriodProvider = NotifierProvider<StatsPeriod, (PeriodKind, int)>(StatsPeriod.new);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allShiftsProvider).value ?? const <Shift>[];
    final jobs = ref.watch(allJobsProvider).value ?? const <Job>[];
    final settings = ref.watch(tipSettingsProvider);
    final money = ref.watch(moneyFmtProvider);
    final now = ref.watch(clockProvider)();
    final (kind, offset) = ref.watch(statsPeriodProvider);
    final period = Period.containing(kind, now, weekStartsOn: settings.weekStartsOn).shift(offset, weekStartsOn: settings.weekStartsOn);
    final shifts = all.where((s) => period.containsKey(s.day)).toList();
    final t = Totals(shifts.map(mathOf));
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);

    if (all.isEmpty) {
      return const EmptyState(
        key: Key('stats-empty'),
        icon: Icons.insights_outlined,
        scene: emptyJarScene,
        title: 'Your numbers show up here',
        body: 'Log a shift and you’ll see your week, your real hourly rate and your best nights.',
      );
    }

    return ListView(
      key: const Key('stats-list'),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<PeriodKind>(
            key: const Key('stats-kind'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: PeriodKind.week, label: Text('Week')),
              ButtonSegment(value: PeriodKind.month, label: Text('Month')),
              ButtonSegment(value: PeriodKind.year, label: Text('Year')),
              ButtonSegment(value: PeriodKind.all, label: Text('All')),
            ],
            selected: {kind},
            onSelectionChanged: (s) => ref.read(statsPeriodProvider.notifier).kind(s.first),
          ),
        ),
        Row(
          children: [
            IconButton(
              key: const Key('stats-prev'),
              tooltip: 'Earlier',
              onPressed: kind == PeriodKind.all ? null : () => ref.read(statsPeriodProvider.notifier).step(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(periodTitle(period), key: const Key('stats-period'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              key: const Key('stats-next'),
              tooltip: 'Later',
              onPressed: kind == PeriodKind.all || offset >= 0 ? null : () => ref.read(statsPeriodProvider.notifier).step(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        BrandPanel(
          key: const Key('stats-hero'),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: brand.onBrand),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Take-home'),
                CountUpText(
                  value: t.takeHome.toDouble(),
                  format: (v) => money(v.round()),
                  textKey: const Key('stats-takehome'),
                  style: TextStyle(color: brand.onBrand, fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _HeroStat('Per hour', '${money(t.perHourCents)}/h', 'stats-rate')),
                    Expanded(child: _HeroStat('Hours', hoursLabel(t.minutes), 'stats-hours')),
                    Expanded(child: _HeroStat('Shifts', '${t.count}', 'stats-count')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (t.count == 0)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No shifts in this period.', key: Key('stats-none'), textAlign: TextAlign.center),
          )
        else ...[
          SectionHeader(kind == PeriodKind.week ? 'Take-home by day' : kind == PeriodKind.month ? 'Take-home by week' : kind == PeriodKind.year ? 'Take-home by month' : 'Take-home by year'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBarChart(
              key: ValueKey('chart-${period.from}-${period.kind}'),
              bars: _bars(period, shifts, settings.weekStartsOn, scheme.primary, brand.accent, now),
              valueLabel: (v) => money((v * 100).round()),
              semanticsLabel: 'Tips kept and wages in ${periodTitle(period)}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Wrap(
              spacing: 16,
              children: [_Legend(scheme.primary, 'Tips kept'), _Legend(brand.accent, 'Wages')],
            ),
          ),
          const SectionHeader('Where it came from'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSplitBar(
              parts: [
                ChartPart(t.cash.toDouble(), billGreen),
                ChartPart(t.card.toDouble(), scheme.primary),
                ChartPart(t.tipIn.toDouble(), scheme.tertiary),
                ChartPart(t.wages.toDouble(), brand.accent),
              ],
              semanticsLabel: 'Cash ${money(t.cash)}, card ${money(t.card)}, wages ${money(t.wages)}',
            ),
          ),
          _row('Cash tips', money(t.cash), 'stats-cash', dot: billGreen),
          _row('Card tips', money(t.card), 'stats-card', dot: scheme.primary),
          if (t.tipIn > 0) _row('Tip-in', money(t.tipIn), 'stats-tipin', dot: scheme.tertiary),
          _row('Wages', money(t.wages), 'stats-wages', dot: brand.accent),
          _row('Tipped out', '− ${money(t.tipOut)}', 'stats-tipout'),
          _row(
            'Set aside for tax (est. ${formatPct(settings.taxBp)})',
            money(applyBp(t.tipsKept + t.wages, settings.taxBp)),
            'stats-tax',
          ),
          ..._bestNight(shifts, money, context),
          if (jobs.length > 1) ..._byJob(shifts, jobs, money),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton.icon(
              key: const Key('stats-export'),
              icon: const Icon(Icons.ios_share),
              label: const Text('Export this period'),
              onPressed: () => _export(context, ref, period, shifts, jobs, money, settings.taxBp),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String a, String b, String key, {Color? dot}) => ListTile(
    dense: true,
    leading: dot == null ? const SizedBox(width: 12) : CircleAvatar(radius: 6, backgroundColor: dot),
    minLeadingWidth: 12,
    title: Text(a),
    trailing: Text(b, key: Key(key), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
  );

  /// Best night of the week by real hourly rate. Needs two shifts on a
  /// weekday to count, so one lucky night doesn't win.
  List<Widget> _bestNight(List<Shift> shifts, String Function(int) money, BuildContext context) {
    final by = <int, List<Shift>>{};
    for (final s in shifts) {
      by.putIfAbsent(parseDay(s.day).weekday, () => []).add(s);
    }
    final eligible = by.entries.where((e) => e.value.length >= 2).toList();
    if (eligible.length < 2) return const [];
    eligible.sort((a, b) => Totals(b.value.map(mathOf)).perHourCents.compareTo(Totals(a.value.map(mathOf)).perHourCents));
    final best = eligible.first;
    final rate = Totals(best.value.map(mathOf)).perHourCents;
    return [
      const SectionHeader('Best night'),
      ListTile(
        key: const Key('stats-best-night'),
        leading: const Icon(Icons.star_rounded, color: gold, size: 32),
        title: Text('${weekdayNames[best.key - 1]}s pay best', key: const Key('stats-best-day')),
        subtitle: Text('${money(rate)}/h over ${best.value.length} shifts'),
      ),
    ];
  }

  List<Widget> _byJob(List<Shift> shifts, List<Job> jobs, String Function(int) money) {
    final by = <int, List<Shift>>{};
    for (final s in shifts) {
      by.putIfAbsent(s.jobId, () => []).add(s);
    }
    if (by.length < 2) return const [];
    return [
      const SectionHeader('By job'),
      for (final j in jobs.where((j) => by.containsKey(j.id)))
        () {
          final jt = Totals(by[j.id]!.map(mathOf));
          return ListTile(
            key: Key('stats-job-${j.id}'),
            leading: CircleAvatar(radius: 8, backgroundColor: jobColor(j.colorIndex)),
            title: Text(j.name),
            subtitle: Text('${jt.count} shifts · ${hoursLabel(jt.minutes)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(jt.takeHome), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${money(jt.perHourCents)}/h', key: Key('stats-job-rate-${j.id}')),
              ],
            ),
          );
        }(),
    ];
  }

  static List<BarDatum> _bars(Period p, List<Shift> shifts, int weekStartsOn, Color tips, Color wages, DateTime now) {
    BarDatum bar(String label, Iterable<Shift> ss, {bool hi = false}) {
      final t = Totals(ss.map(mathOf));
      return BarDatum(label, [ChartPart(t.tipsKept / 100, tips), ChartPart(t.wages / 100, wages)], highlight: hi);
    }

    switch (p.kind) {
      case PeriodKind.week:
        return [
          for (var i = 0; i < 7; i++)
            () {
              final d = addDays(p.from, i);
              final k = dayKey(d);
              return bar(weekdayShort[d.weekday - 1], shifts.where((s) => s.day == k), hi: k == dayKey(now));
            }(),
        ];
      case PeriodKind.month:
        final bars = <BarDatum>[];
        var s = weekStart(p.from, weekStartsOn);
        while (s.isBefore(p.to)) {
          final e = addDays(s, 7);
          final from = s.isBefore(p.from) ? p.from : s;
          bars.add(bar('${from.day}', shifts.where((x) {
            final d = parseDay(x.day);
            return !d.isBefore(s) && d.isBefore(e);
          })));
          s = e;
        }
        return bars;
      case PeriodKind.year:
        return [for (var m = 1; m <= 12; m++) bar(_months[m - 1][0], shifts.where((s) => parseDay(s.day).month == m))];
      case PeriodKind.all:
        final years = shifts.map((s) => parseDay(s.day).year).toSet().toList()..sort();
        return [for (final y in years) bar('$y', shifts.where((s) => parseDay(s.day).year == y))];
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref, Period p, List<Shift> shifts, List<Job> jobs, String Function(int) money, int taxBp) async {
    if (!await requirePro(context, ref, featureExport)) return;
    if (!context.mounted) return;
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(key: const Key('export-csv'), leading: const Icon(Icons.table_view_outlined), title: const Text('Spreadsheet (CSV)'), onTap: () => Navigator.pop(c, 'csv')),
            ListTile(key: const Key('export-pdf'), leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Report (PDF)'), onTap: () => Navigator.pop(c, 'pdf')),
          ],
        ),
      ),
    );
    if (kind == null) return;
    final jobMap = {for (final j in jobs) j.id: j};
    final exp = ref.read(exportServiceProvider);
    final name = 'tips-${dayKey(p.from)}';
    final title = periodTitle(p);
    final f = kind == 'csv'
        ? await exp.writeCsv('$name.csv', shiftsCsv(shifts, jobMap))
        : await exp.writePdf(
            '$name.pdf',
            await shiftsPdf(appName: ref.read(appConfigProvider).appName, period: p, shifts: shifts, jobs: jobMap, money: money, taxBp: taxBp),
          );
    await exp.share(f, subject: 'Tips: $title');
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.label, this.value, this.k);
  final String label;
  final String value;
  final String k;

  @override
  Widget build(BuildContext context) {
    final on = BrandColors.of(context).onBrand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: on.withValues(alpha: 0.8), fontSize: 12)),
        Text(value, key: Key(k), style: TextStyle(color: on, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [CircleAvatar(radius: 5, backgroundColor: color), const SizedBox(width: 6), Text(label)],
  );
}
