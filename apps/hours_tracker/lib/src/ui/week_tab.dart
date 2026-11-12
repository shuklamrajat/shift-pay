import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/repository.dart';
import '../domain/pay_engine.dart';
import '../domain/time_format.dart';
import 'scenes.dart';
import 'shift_edit_screen.dart';

/// Offset in weeks from the current week.
class WeekOffset extends Notifier<int> {
  @override
  int build() => 0;
  void move(int by) => state += by;
  void reset() => state = 0;
}

final weekOffsetProvider = NotifierProvider<WeekOffset, int>(WeekOffset.new);

class WeekTab extends ConsumerWidget {
  const WeekTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(currentJobProvider);
    if (job == null) return const SizedBox.shrink();
    final offset = ref.watch(weekOffsetProvider);
    final now = ref.watch(clockProvider)();
    final rules = rulesFor(job);
    final thisWeek = weekStartOf(workdayOf(now, rules.workdayStartMinute), rules.weekStartsOn);
    final from = DateTime(thisWeek.year, thisWeek.month, thisWeek.day + 7 * offset);
    final to = DateTime(from.year, from.month, from.day + 7);
    final key = (jobId: job.id, from: from, toExclusive: to);
    final pay = ref.watch(payProvider(key));
    final rows = ref.watch(weekShiftsProvider(key)).value ?? const <Shift>[];
    final currency = ref.watch(coreSettingsProvider).currency;
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;

    final byId = {for (final x in pay.value?.$1.shifts ?? const <ShiftPay>[]) x.id: x};
    final summary = pay.value?.$2;
    // Group rows by workday.
    final days = <DateTime, List<Shift>>{};
    for (final s in rows) {
      final wd = workdayOf(s.start, rules.workdayStartMinute);
      if (wd.isBefore(from) || !wd.isBefore(to)) continue;
      days.putIfAbsent(wd, () => []).add(s);
    }

    final theme = Theme.of(context);
    final brand = BrandColors.of(context);
    final today = workdayOf(now, rules.workdayStartMinute);
    final sortedDays = days.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    var item = 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('week-prev'),
              tooltip: 'Previous week',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => ref.read(weekOffsetProvider.notifier).move(-1),
            ),
            TextButton(
              onPressed: () => ref.read(weekOffsetProvider.notifier).reset(),
              child: Text(
                '${dayLabel(from)} – ${dayLabel(DateTime(to.year, to.month, to.day - 1))}',
                key: const Key('week-label'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              key: const Key('week-next'),
              tooltip: 'Next week',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => ref.read(weekOffsetProvider.notifier).move(1),
            ),
          ],
        ),
        if (summary != null)
          BrandPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offset == 0 ? 'HOURS THIS WEEK' : 'HOURS', style: _overline(brand)),
                          CountUpText(
                            value: summary.workedMin.toDouble(),
                            format: (v) => hm(v.round()),
                            textKey: const Key('week-hours'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: brand.onBrand,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('PAY', style: _overline(brand)),
                        CountUpText(
                          value: summary.payCents.toDouble(),
                          format: (v) => Money.format(v.round(), currency: currency),
                          textKey: const Key('week-pay'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: brand.onBrand,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: 'Overtime', value: hm(summary.overtimeMin), valueKey: const Key('week-ot')),
                    if (summary.doubleMin > 0)
                      _Chip(label: 'Double', value: hm(summary.doubleMin), valueKey: const Key('week-dt')),
                    _Chip(label: 'Shifts', value: '${summary.shifts.length}'),
                  ],
                ),
              ],
            ),
          ),
        if (summary != null && summary.shifts.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('By day', style: theme.textTheme.titleSmall),
                  ),
                  _WeekChart(from: from, today: today, pay: summary.shifts),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    children: [
                      _Legend(color: theme.colorScheme.primary, label: 'Regular'),
                      _Legend(color: brand.accent, label: 'Overtime'),
                      _Legend(color: brand.warning, label: 'Double time'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
            child: Column(
              children: [
                const SizedBox(height: 150, child: AnimatedScene(paint: quietWeekScene, aspectRatio: 1.8)),
                const SizedBox(height: 8),
                Text('No shifts this week yet.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        for (final entry in sortedDays) ...[
          SectionHeader(
            dayLabel(entry.key),
            trailing: entry.key == today ? Pill(text: 'Today', color: brand.accent) : null,
          ),
          for (final s in entry.value)
            Appear(
              index: item++,
              child: Card(
                child: ListTile(
                  key: Key('shift-${s.id}'),
                  leading: _DayNightBadge(start: s.start),
                  title: Text(
                    s.end == null
                        ? '${clock(s.start, use24h: use24)} – now'
                        : '${clock(s.start, use24h: use24)} – ${clock(s.end!, use24h: use24)}'
                              '${dateOnly(s.end!) != dateOnly(s.start) ? ' (+1)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_breakdown(byId['${s.id}'], s)),
                  trailing: byId['${s.id}'] == null
                      ? null
                      : Text(
                          Money.format(byId['${s.id}']!.payCents, currency: currency),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftEditScreen(job: job, shift: s),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  TextStyle _overline(BrandColors brand) => TextStyle(
    color: brand.onBrand.withValues(alpha: 0.75),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  String _breakdown(ShiftPay? p, Shift s) {
    if (p == null) return s.end == null ? 'On the clock' : '';
    final parts = <String>[hm(p.workedMin)];
    if (p.overtimeMin > 0) parts.add('OT ${hm(p.overtimeMin)}');
    if (p.doubleMin > 0) parts.add('2x ${hm(p.doubleMin)}');
    if (s.unpaidBreakMin > 0) parts.add('break ${hm(s.unpaidBreakMin)}');
    if (s.note.isNotEmpty) parts.add(s.note);
    return parts.join(' · ');
  }
}

/// Bars for each day of the week, split into regular, overtime and double
/// time. Its screen-reader label reads every day out.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.from, required this.today, required this.pay});
  final DateTime from;
  final DateTime today;
  final List<ShiftPay> pay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final bars = <BarDatum>[];
    final spoken = <String>[];
    for (var i = 0; i < 7; i++) {
      final d = DateTime(from.year, from.month, from.day + i);
      var reg = 0, ot = 0, dt = 0;
      for (final p in pay.where((p) => p.workday == d)) {
        reg += p.regularMin;
        ot += p.overtimeMin;
        dt += p.doubleMin;
      }
      final name = DateFormat.E().format(d);
      bars.add(
        BarDatum(name, [
          ChartPart(reg / 60, scheme.primary),
          ChartPart(ot / 60, brand.accent),
          ChartPart(dt / 60, brand.warning),
        ], highlight: d == today),
      );
      spoken.add(
        reg + ot + dt == 0
            ? '$name no shifts'
            : [
                '$name ${hm(reg + ot + dt)}',
                if (ot > 0) '${hm(ot)} overtime',
                if (dt > 0) '${hm(dt)} double time',
              ].join(', '),
      );
    }
    return AnimatedBarChart(
      key: const Key('week-chart'),
      bars: bars,
      valueLabel: (h) => h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1),
      semanticsLabel: 'Hours by day. ${spoken.join('. ')}.',
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, this.valueKey});
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: brand.onBrand.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: TextStyle(color: brand.onBrand.withValues(alpha: 0.8), fontSize: 12)),
          Text(
            value,
            key: valueKey,
            style: TextStyle(color: brand.onBrand, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// Sun for day shifts, moon for nights, so the week reads at a glance.
class _DayNightBadge extends StatelessWidget {
  const _DayNightBadge({required this.start});
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final night = start.hour >= 19 || start.hour < 5;
    return IconBadge(
      icon: night ? Icons.nightlight_round : Icons.wb_sunny_rounded,
      color: night ? const Color(0xFF5C6BC0) : const Color(0xFFF59E0B),
      size: 40,
    );
  }
}
