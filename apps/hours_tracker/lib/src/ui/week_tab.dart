import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/pay_engine.dart';
import '../domain/time_format.dart';
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                key: const Key('week-prev'),
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(weekOffsetProvider.notifier).move(-1)),
            TextButton(
              onPressed: () => ref.read(weekOffsetProvider.notifier).reset(),
              child: Text('${dayLabel(from)} – ${dayLabel(DateTime(to.year, to.month, to.day - 1))}',
                  key: const Key('week-label')),
            ),
            IconButton(
                key: const Key('week-next'),
                icon: const Icon(Icons.chevron_right),
                onPressed: () => ref.read(weekOffsetProvider.notifier).move(1)),
          ],
        ),
        if (summary != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(spacing: 24, runSpacing: 12, children: [
                StatTile(label: 'Hours', value: hm(summary.workedMin), valueKey: const Key('week-hours')),
                StatTile(label: 'Overtime', value: hm(summary.overtimeMin), valueKey: const Key('week-ot')),
                if (summary.doubleMin > 0)
                  StatTile(label: 'Double time', value: hm(summary.doubleMin), valueKey: const Key('week-dt')),
                StatTile(
                    label: 'Pay', value: Money.format(summary.payCents, currency: currency), valueKey: const Key('week-pay')),
              ]),
            ),
          ),
        if (days.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('No shifts this week yet.', textAlign: TextAlign.center),
          ),
        for (final entry in (days.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(dayLabel(entry.key), style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final s in entry.value)
            Card(
              child: ListTile(
                key: Key('shift-${s.id}'),
                title: Text(s.end == null
                    ? '${clock(s.start, use24h: use24)} – now'
                    : '${clock(s.start, use24h: use24)} – ${clock(s.end!, use24h: use24)}'
                        '${dateOnly(s.end!) != dateOnly(s.start) ? ' (+1)' : ''}'),
                subtitle: Text(_breakdown(byId['${s.id}'], s)),
                trailing: byId['${s.id}'] == null
                    ? null
                    : Text(Money.format(byId['${s.id}']!.payCents, currency: currency)),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ShiftEditScreen(job: job, shift: s))),
              ),
            ),
        ],
      ],
    );
  }

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
