import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/repository.dart';
import '../domain/periods.dart';
import '../domain/tip_math.dart';
import 'backup_screen.dart';
import 'fields.dart';
import 'scenes.dart';
import 'shift_edit_screen.dart';

/// Job id the Shifts list is filtered to, or null for all jobs.
class ShiftFilter extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? id) => state = id;
}

final shiftFilterProvider = NotifierProvider<ShiftFilter, int?>(ShiftFilter.new);

/// Opens the shift editor and reacts to how it closed: saved (maybe a
/// celebration), deleted (Undo), or backed out (nothing).
Future<void> openShiftEditor(BuildContext context, WidgetRef ref, {Shift? shift, Shift? prefill}) async {
  final r = await Navigator.of(context).push<Object?>(
    MaterialPageRoute(builder: (_) => ShiftEditScreen(shift: shift, prefill: prefill)),
  );
  if (!context.mounted) return;
  if (r is ShiftSaved) {
    if (r.firstEver) {
      celebrate(context);
      snack(context, 'First shift logged. Nice!');
    } else if (r.bestRate) {
      celebrate(context);
      snack(context, 'Your best hourly rate yet!');
    } else {
      snack(context, shift == null ? 'Shift saved' : 'Changes saved');
    }
    await ref.read(ratingPrompterProvider).recordCompletedTask();
  } else if (r is Shift) {
    showUndoDelete(context, ref, r);
  }
}

void showUndoDelete(BuildContext context, WidgetRef ref, Shift s) {
  snack(
    context,
    'Shift deleted',
    duration: const Duration(seconds: 6),
    action: SnackBarAction(key: const Key('undo-delete'), label: 'Undo', onPressed: () => ref.read(repositoryProvider).restoreShift(s)),
  );
}

class ShiftsTab extends ConsumerWidget {
  const ShiftsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(allShiftsProvider);
    final jobs = ref.watch(allJobsProvider).value ?? const <Job>[];
    final filter = ref.watch(shiftFilterProvider);
    final settings = ref.watch(tipSettingsProvider);
    final money = ref.watch(moneyFmtProvider);
    final now = ref.watch(clockProvider)();
    final all = shiftsAsync.value;
    if (all == null) return const Center(child: CircularProgressIndicator());
    if (all.isEmpty) {
      return const EmptyState(
        key: Key('shifts-empty'),
        icon: Icons.savings_outlined,
        scene: emptyJarScene,
        title: 'No shifts yet',
        body: 'Tap Log shift at the end of your next shift. Only the hours are needed.',
      );
    }
    final jobById = {for (final j in jobs) j.id: j};
    final shifts = filter == null ? all : all.where((s) => s.jobId == filter).toList();
    final week = Period.containing(PeriodKind.week, now, weekStartsOn: settings.weekStartsOn);
    final pay = payPeriodContaining(now, settings.payKind, settings.payAnchor);
    final weekTotals = Totals(shifts.where((s) => week.containsKey(s.day)).map(mathOf));
    final payTotals = Totals(shifts.where((s) => pay.containsKey(s.day)).map(mathOf));

    // Group by week, newest first (the list is already newest first).
    final groups = <DateTime, List<Shift>>{};
    for (final s in shifts) {
      groups.putIfAbsent(weekStart(parseDay(s.day), settings.weekStartsOn), () => []).add(s);
    }
    final offDevice = ref.watch(lastOffDeviceProvider);
    final nudge = all.length >= 5 && (offDevice == null || now.difference(offDevice).inDays >= 30);

    return ListView(
      key: const Key('shift-list'),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _WeekHero(week: weekTotals, pay: payTotals, money: money, payLabel: _payLabel(pay)),
        if (nudge)
          Card(
            key: const Key('backup-nudge'),
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(offDevice == null ? 'Save a backup off this phone' : 'Time for a fresh backup'),
              subtitle: Text('${all.length} shifts are only on this phone. One tap saves them to Drive or email.'),
              trailing: FilledButton.tonal(
                key: const Key('backup-nudge-save'),
                onPressed: () => saveBackupOffDevice(context, ref),
                child: const Text('Save'),
              ),
            ),
          ),
        if (jobs.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('filter-all'),
                  label: const Text('All jobs'),
                  selected: filter == null,
                  onSelected: (_) => ref.read(shiftFilterProvider.notifier).set(null),
                ),
                for (final j in jobs.where((j) => !j.archived || all.any((s) => s.jobId == j.id)))
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      key: Key('filter-job-${j.id}'),
                      avatar: CircleAvatar(radius: 6, backgroundColor: jobColor(j.colorIndex)),
                      label: Text(j.name),
                      selected: filter == j.id,
                      onSelected: (_) => ref.read(shiftFilterProvider.notifier).set(filter == j.id ? null : j.id),
                    ),
                  ),
              ],
            ),
          ),
        if (shifts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('No shifts for this job yet.', textAlign: TextAlign.center),
          ),
        for (final e in groups.entries) ...[
          _WeekHeader(start: e.key, totals: Totals(e.value.map(mathOf)), money: money, now: now, weekStartsOn: settings.weekStartsOn),
          for (final s in e.value) _ShiftRow(shift: s, job: jobById[s.jobId], money: money, showJob: jobs.length > 1),
        ],
      ],
    );
  }

  static String _payLabel(Period p) {
    final f = DateFormat('d MMM');
    return 'Pay period ${f.format(p.from)} to ${f.format(addDays(p.to, -1))}';
  }
}

class _WeekHero extends StatelessWidget {
  const _WeekHero({required this.week, required this.pay, required this.money, required this.payLabel});
  final Totals week;
  final Totals pay;
  final String Function(int) money;
  final String payLabel;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final on = brand.onBrand;
    return BrandPanel(
      key: const Key('week-hero'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week', style: TextStyle(color: on.withValues(alpha: 0.85))),
                CountUpText(
                  value: week.takeHome.toDouble(),
                  format: (v) => money(v.round()),
                  textKey: const Key('week-total'),
                  style: TextStyle(color: on, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                Text(
                  week.count == 0 ? 'No shifts yet this week' : '${hoursLabel(week.minutes)} · ${money(week.perHourCents)}/h',
                  key: const Key('week-rate'),
                  style: TextStyle(color: on, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('$payLabel: ${money(pay.takeHome)}', key: const Key('pay-period-total'), style: TextStyle(color: on.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 92,
            child: AnimatedScene(paint: fillJarScene),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.start, required this.totals, required this.money, required this.now, required this.weekStartsOn});
  final DateTime start;
  final Totals totals;
  final String Function(int) money;
  final DateTime now;
  final int weekStartsOn;

  @override
  Widget build(BuildContext context) {
    final thisWeek = weekStart(now, weekStartsOn);
    final label = start == thisWeek
        ? 'This week'
        : start == addDays(thisWeek, -7)
        ? 'Last week'
        : 'Week of ${DateFormat('d MMM').format(start)}';
    return SectionHeader(
      label,
      trailing: Text('${money(totals.takeHome)} · ${money(totals.perHourCents)}/h', style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _ShiftRow extends ConsumerWidget {
  const _ShiftRow({required this.shift, required this.job, required this.money, required this.showJob});
  final Shift shift;
  final Job? job;
  final String Function(int) money;
  final bool showJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = mathOf(shift);
    final d = parseDay(shift.day);
    final theme = Theme.of(context);
    final parts = <String>[
      hoursLabel(shift.minutes),
      if (shift.cashCents > 0) 'cash ${money(shift.cashCents)}',
      if (shift.cardCents > 0) 'card ${money(shift.cardCents)}',
      if (m.tipOut > 0) 'tip-out ${money(m.tipOut)}',
    ];
    return ListTile(
      key: Key('shift-row-${shift.id}'),
      leading: Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: jobColor(job?.colorIndex ?? 0).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat.E().format(d), style: theme.textTheme.labelSmall),
            Text('${d.day}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      title: Text(showJob ? (job?.name ?? 'Job') : DateFormat('EEEE d MMM').format(d)),
      subtitle: Text(parts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(money(m.takeHome), key: Key('shift-row-total-${shift.id}'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text('${money(m.perHourCents)}/h', style: theme.textTheme.bodySmall),
        ],
      ),
      onTap: () => openShiftEditor(context, ref, shift: shift),
      onLongPress: () => _actions(context, ref),
    );
  }

  Future<void> _actions(BuildContext context, WidgetRef ref) async {
    final v = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(key: const Key('row-duplicate'), leading: const Icon(Icons.copy), title: const Text('Duplicate'), subtitle: const Text('Same job and hours, today’s date'), onTap: () => Navigator.pop(c, 'dup')),
            ListTile(key: const Key('row-delete'), leading: const Icon(Icons.delete_outline), title: const Text('Delete'), onTap: () => Navigator.pop(c, 'del')),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (v == 'dup') {
      await openShiftEditor(context, ref, prefill: shift);
    } else if (v == 'del') {
      await ref.read(repositoryProvider).deleteShift(shift.id);
      if (context.mounted) showUndoDelete(context, ref, shift);
    }
  }
}
