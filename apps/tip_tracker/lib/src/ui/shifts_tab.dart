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

/// The shift just saved, so its row can glow once in the list.
class JustSaved extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? id) => state = id;
}

final justSavedProvider = NotifierProvider<JustSaved, int?>(JustSaved.new);

/// Opens the shift editor and reacts to how it closed: saved (maybe a
/// celebration), deleted (Undo), or backed out (nothing).
Future<void> openShiftEditor(BuildContext context, WidgetRef ref, {Shift? shift, Shift? prefill}) async {
  ref.read(justSavedProvider.notifier).set(null);
  final r = await Navigator.of(context).push<Object?>(
    MaterialPageRoute(builder: (_) => ShiftEditScreen(shift: shift, prefill: prefill)),
  );
  if (!context.mounted) return;
  if (r is ShiftSaved) {
    ref.read(justSavedProvider.notifier).set(r.id);
    // A filter on another job would hide the row that was just saved.
    final f = ref.read(shiftFilterProvider);
    if (f != null && f != r.jobId) ref.read(shiftFilterProvider.notifier).set(null);
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
    final jobById = {for (final j in jobs) j.id: j};
    if (all == null) return const Center(child: CircularProgressIndicator());
    if (all.isEmpty) {
      return EmptyState(
        key: const Key('shifts-empty'),
        icon: Icons.savings_outlined,
        scene: emptyJarScene,
        title: 'No shifts yet',
        body: 'Log one at the end of your next shift. Only the hours are needed.',
        action: FilledButton.icon(
          key: const Key('empty-add-shift'),
          icon: const Icon(Icons.add),
          label: const Text('Log your first shift'),
          onPressed: () => openShiftEditor(context, ref),
        ),
      );
    }
    final shifts = filter == null ? all : all.where((s) => s.jobId == filter).toList();
    final week = Period.containing(PeriodKind.week, now, weekStartsOn: settings.weekStartsOn);
    // The pay period follows the job picked in the filter: each job can be
    // paid on its own cycle. With all jobs shown it's the Settings default.
    final pay = payPeriodFor(jobById[filter], settings, now);
    final weekTotals = Totals(shifts.where((s) => week.containsKey(s.day)).map(mathOf));
    final payTotals = Totals(shifts.where((s) => pay.containsKey(s.day)).map(mathOf));

    // Group by week, newest first (the list is already newest first).
    final groups = <DateTime, List<Shift>>{};
    for (final s in shifts) {
      groups.putIfAbsent(weekStart(parseDay(s.day), settings.weekStartsOn), () => []).add(s);
    }
    final justSaved = ref.watch(justSavedProvider);
    final offDevice = ref.watch(lastOffDeviceProvider);
    final nudge = all.length >= 5 && (offDevice == null || now.difference(offDevice).inDays >= 30);

    return ListView(
      key: const Key('shift-list'),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _WeekHero(
          week: weekTotals,
          pay: payTotals,
          money: money,
          payLabel: _payLabel(pay),
          payKind: payKindFor(jobById[filter], settings),
        ),
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
          for (final s in e.value)
            _ShiftRow(shift: s, job: jobById[s.jobId], money: money, showJob: jobs.length > 1, justSaved: s.id == justSaved),
        ],
      ],
    );
  }

  static String _payLabel(Period p) {
    final f = DateFormat('d MMM');
    return '${f.format(p.from)} to ${f.format(addDays(p.to, -1))}';
  }
}

class _WeekHero extends StatelessWidget {
  const _WeekHero({required this.week, required this.pay, required this.money, required this.payLabel, required this.payKind});
  final Totals week;
  final Totals pay;
  final String Function(int) money;
  final String payLabel;
  final PayPeriodKind payKind;

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
                const SizedBox(height: 10),
                // The pay-period chip: what this paycheck should cover.
                Container(
                  key: const Key('pay-period-chip'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: on.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined, size: 14, color: on),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${payKindLabel(payKind)} pay $payLabel: ${money(pay.takeHome)}',
                          key: const Key('pay-period-total'),
                          style: TextStyle(color: on, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
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
  const _ShiftRow({required this.shift, required this.job, required this.money, required this.showJob, this.justSaved = false});
  final Shift shift;
  final Job? job;
  final String Function(int) money;
  final bool showJob;
  final bool justSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = _tile(context, ref);
    if (!justSaved) return row;
    return _JustSavedGlow(key: Key('shift-row-saved-${shift.id}'), color: jobColor(job?.colorIndex ?? 0), child: row);
  }

  Widget _tile(BuildContext context, WidgetRef ref) {
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


/// The row of the shift just saved: scrolled into view and lit up in its
/// job colour, fading out (or staying lit when the phone asks for no motion).
class _JustSavedGlow extends StatefulWidget {
  const _JustSavedGlow({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  State<_JustSavedGlow> createState() => _JustSavedGlowState();
}

class _JustSavedGlowState extends State<_JustSavedGlow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context, alignment: 0.3, duration: Motion.of(context, 300));
    });
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.color.withValues(alpha: 0.22);
    // A Material, not a ColoredBox, so the row's own ink still shows.
    if (Motion.reduced(context)) return Material(color: lit, child: widget.child);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0.25),
      duration: const Duration(milliseconds: 2400),
      curve: Curves.easeOut,
      builder: (_, v, child) => Material(color: widget.color.withValues(alpha: 0.22 * v), child: child),
      child: widget.child,
    );
  }
}
