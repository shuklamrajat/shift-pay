import 'dart:convert';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/repository.dart';
import '../domain/periods.dart';
import '../domain/time_format.dart';
import '../domain/tip_math.dart';
import 'fields.dart';
import 'job_edit_screen.dart';

/// What the list does after a save: highlight, celebrate.
class ShiftSaved {
  const ShiftSaved(this.id, {this.firstEver = false, this.bestRate = false});
  final int id;
  final bool firstEver;
  final bool bestRate;
}

/// New shift, edit shift, or a duplicate ([prefill] with no [shift]).
class ShiftEditScreen extends ConsumerStatefulWidget {
  const ShiftEditScreen({super.key, this.shift, this.prefill});
  final Shift? shift;
  final Shift? prefill;

  @override
  ConsumerState<ShiftEditScreen> createState() => _ShiftEditScreenState();
}

class _ShiftEditScreenState extends ConsumerState<ShiftEditScreen> {
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _break = TextEditingController();
  final _hours = TextEditingController();
  final _cash = TextEditingController();
  final _card = TextEditingController();
  final _tipIn = TextEditingController();
  final _sales = TextEditingController();
  final _tipOut = TextEditingController();
  final _note = TextEditingController();
  int? _jobId;
  late DateTime _day;
  bool _useTimes = true;
  bool _tipOutEdited = false;
  bool _showMore = false;
  String? _error;
  bool _saving = false;
  String _startSnapshot = '';
  bool get _isNew => widget.shift == null;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final settings = ref.read(tipSettingsProvider);
    final src = widget.shift ?? widget.prefill;
    _day = widget.shift != null ? parseDay(widget.shift!.day) : defaultShiftDay(now);
    _useTimes = settings.useTimes;
    final jobs = (ref.read(allJobsProvider).value ?? const <Job>[]).where((j) => !j.archived).toList();
    final fallback = jobs.any((j) => j.id == settings.lastJobId) ? settings.lastJobId : jobs.firstOrNull?.id;
    if (src != null) {
      // A duplicate of an archived job's shift goes to an active job.
      _jobId = widget.shift != null || jobs.any((j) => j.id == src.jobId) ? src.jobId : fallback;
      _fillFrom(src, copyMoney: widget.shift != null);
    } else {
      _jobId = fallback;
    }
    _startSnapshot = _snapshot();
    for (final c in _controllers) {
      c.addListener(_changed);
    }
    if (_isNew && widget.prefill == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraft());
    }
  }

  List<TextEditingController> get _controllers => [_start, _end, _break, _hours, _cash, _card, _tipIn, _sales, _tipOut, _note];

  void _fillFrom(Shift s, {required bool copyMoney}) {
    _useTimes = s.startMinute != null;
    if (s.startMinute != null) {
      _start.text = _hhmm(s.startMinute!);
      _end.text = _hhmm(s.endMinute!);
      _break.text = s.breakMinutes == 0 ? '' : '${s.breakMinutes}';
    } else {
      _hours.text = _hoursText(s.minutes);
    }
    if (copyMoney) {
      _cash.text = centsToInput(s.cashCents);
      _card.text = centsToInput(s.cardCents);
      _tipIn.text = centsToInput(s.tipInCents);
      _sales.text = centsToInput(s.salesCents);
      _note.text = s.note;
      _tipOutEdited = s.tipOutEdited;
      if (s.tipOutEdited) _tipOut.text = centsToInput(s.tipOutCents);
      _showMore = s.tipInCents > 0;
    }
  }

  static String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  static String _hoursText(int m) => m % 60 == 0 ? '${m ~/ 60}' : '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- draft (kept if the app is killed mid-entry) ----

  String _snapshot() => jsonEncode({
    'job': _jobId,
    'day': dayKey(_day),
    'times': _useTimes,
    'start': _start.text,
    'end': _end.text,
    'break': _break.text,
    'hours': _hours.text,
    'cash': _cash.text,
    'card': _card.text,
    'tipIn': _tipIn.text,
    'sales': _sales.text,
    'tipOut': _tipOutEdited ? _tipOut.text : null,
    'note': _note.text,
  });

  bool get _dirty => _snapshot() != _startSnapshot;

  void _changed() {
    setState(() {});
    if (_isNew) {
      final prefs = ref.read(sharedPrefsProvider);
      if (_dirty) {
        prefs.setString(TipPrefs.draftKey, _snapshot());
      } else {
        prefs.remove(TipPrefs.draftKey);
      }
    }
  }

  Future<void> _offerDraft() async {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString(TipPrefs.draftKey);
    if (raw == null || !mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Finish the shift you started?'),
        content: const Text('You were logging a shift and didn’t save it.'),
        actions: [
          TextButton(key: const Key('draft-discard'), onPressed: () => Navigator.pop(c, false), child: const Text('Discard')),
          FilledButton(key: const Key('draft-resume'), onPressed: () => Navigator.pop(c, true), child: const Text('Resume')),
        ],
      ),
    );
    if (resume != true) {
      await prefs.remove(TipPrefs.draftKey);
      return;
    }
    final d = jsonDecode(raw) as Map<String, dynamic>;
    final jobs = (ref.read(allJobsProvider).value ?? const <Job>[]).where((j) => !j.archived).toList();
    setState(() {
      if (jobs.any((j) => j.id == d['job'])) _jobId = d['job'] as int;
      _day = parseDay(d['day'] as String);
      _useTimes = d['times'] as bool;
      _start.text = d['start'] as String;
      _end.text = d['end'] as String;
      _break.text = d['break'] as String;
      _hours.text = d['hours'] as String;
      _cash.text = d['cash'] as String;
      _card.text = d['card'] as String;
      _tipIn.text = d['tipIn'] as String;
      _sales.text = d['sales'] as String;
      _tipOutEdited = d['tipOut'] != null;
      _tipOut.text = (d['tipOut'] as String?) ?? '';
      _note.text = d['note'] as String;
      _showMore = _tipIn.text.isNotEmpty;
    });
  }

  // ---- reading the form ----

  int _money(TextEditingController c) => c.text.trim().isEmpty ? 0 : (Money.parse(c.text) ?? -1);

  ShiftDraft _draft() {
    int? start, end;
    var brk = 0;
    int? typed;
    if (_useTimes) {
      start = _start.text.trim().isEmpty ? null : parseTimeOfDay(_start.text) ?? -1;
      end = _end.text.trim().isEmpty ? null : parseTimeOfDay(_end.text) ?? -1;
      brk = _break.text.trim().isEmpty ? 0 : (int.tryParse(_break.text.trim()) ?? -1);
    } else {
      typed = parseHours(_hours.text);
    }
    return ShiftDraft(
      id: widget.shift?.id,
      jobId: _jobId ?? -1,
      day: _day,
      startMinute: start,
      endMinute: end,
      breakMinutes: brk,
      typedMinutes: typed,
      cashCents: _money(_cash),
      cardCents: _money(_card),
      tipInCents: _money(_tipIn),
      salesCents: _sales.text.trim().isEmpty ? null : _money(_sales),
      tipOutOverrideCents: _tipOutEdited ? _money(_tipOut) : null,
      note: _note.text,
    );
  }

  Job? _job(List<Job> jobs) => jobs.where((j) => j.id == _jobId).firstOrNull;

  /// The wage and rule this shift uses: its own when editing on the same job.
  (int, TipOutRule) _terms(Job job) {
    final s = widget.shift;
    if (s != null && s.jobId == job.id) return (s.rateCents, ruleOfShift(s));
    return (job.rateCents, ruleOfJob(job));
  }

  String? _formatError(ShiftDraft d) {
    if (_useTimes) {
      if (d.startMinute == -1 || d.endMinute == -1) return 'Use a time like 18:30 or 6:30 pm.';
      if (d.breakMinutes < 0) return 'Enter the break in minutes, like 30.';
    } else if (_hours.text.trim().isNotEmpty && d.typedMinutes == null) {
      return 'Enter hours like 6, 6.5 or 6:30.';
    }
    for (final v in [d.cashCents, d.cardCents, d.tipInCents, d.salesCents ?? 0, d.tipOutOverrideCents ?? 0]) {
      if (v < 0) return 'Check the amounts.';
    }
    return null;
  }

  Future<void> _save() async {
    final d = _draft();
    final fmt = _formatError(d);
    if (fmt != null) return setState(() => _error = fmt);
    if (d.jobId < 0) return setState(() => _error = 'Pick a job first.');
    setState(() {
      _saving = true;
      _error = null;
    });
    final before = ref.read(allShiftsProvider).value ?? const <Shift>[];
    final now = ref.read(clockProvider)();
    final r = await ref.read(repositoryProvider).saveShift(d, now: now);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!r.ok) return setState(() => _error = r.error);
    await ref.read(sharedPrefsProvider).remove(TipPrefs.draftKey);
    await ref.read(tipSettingsProvider.notifier).setLastJob(d.jobId);
    await ref.read(tipSettingsProvider.notifier).setUseTimes(_useTimes);
    final saved = await ref.read(repositoryProvider).shift(r.id!);
    final rate = saved == null ? 0 : mathOf(saved).perHourCents;
    final others = before.where((s) => s.id != r.id);
    final best = others.length >= 3 && others.every((s) => mathOf(s).perHourCents < rate);
    if (!mounted) return;
    Navigator.of(context).pop(ShiftSaved(r.id!, firstEver: before.isEmpty, bestRate: best));
  }

  Future<void> _delete() async {
    final s = widget.shift!;
    final ok = await confirmDialog(context, 'Delete this shift?', 'You can undo this right after.');
    if (!ok || !mounted) return;
    await ref.read(repositoryProvider).deleteShift(s.id);
    if (!mounted) return;
    Navigator.of(context).pop(s); // the list offers Undo with the old row
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_isNew ? 'Discard this shift?' : 'Discard changes?'),
        content: Text(_isNew ? 'It hasn’t been saved.' : 'Your edits to this shift won’t be saved.'),
        actions: [
          TextButton(key: const Key('keep-editing'), onPressed: () => Navigator.pop(c, false), child: const Text('Keep editing')),
          FilledButton(key: const Key('discard'), onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
        ],
      ),
    );
    if (r == true) await ref.read(sharedPrefsProvider).remove(TipPrefs.draftKey);
    return r ?? false;
  }

  Future<void> _pickDay() async {
    final today = dateOnly(ref.read(clockProvider)());
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(2000), lastDate: today);
    if (d != null) setState(() => _day = d);
    _changed();
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allJobs = ref.watch(allJobsProvider).value ?? const <Job>[];
    final jobs = allJobs.where((j) => !j.archived).toList();
    // An archived job stays pickable for the shift that already uses it.
    final pickable = [...jobs, ...allJobs.where((j) => j.archived && j.id == widget.shift?.jobId)];
    final job = _job(pickable);
    final money = ref.watch(moneyFmtProvider);
    final symbol = money(0).replaceAll(RegExp(r'[\d.,\s]'), '');
    final today = dateOnly(ref.watch(clockProvider)());
    final d = _draft();
    final terms = job == null ? (0, const TipOutRule.none()) : _terms(job);
    final showSales = job != null && (job.tracksSales || terms.$2.needsSales || d.salesCents != null);
    final minutes = d.minutes;
    final math = minutes == null || minutes <= 0 ? null : computeShift(d.input(minutes, rateCents: terms.$1, rule: terms.$2));
    final ruleOut = ruleTipOutFor(terms.$2, tipsEarned: d.cashCents.clamp(0, 1 << 30) + d.cardCents.clamp(0, 1 << 30), salesCents: d.salesCents);
    final check = job == null || minutes == null
        ? null
        : checkShift(
            day: _day,
            today: today,
            startMinute: d.startMinute,
            endMinute: d.endMinute,
            breakMinutes: d.breakMinutes,
            typedMinutes: d.typedMinutes,
            build: (m) => d.input(m, rateCents: terms.$1, rule: terms.$2),
          );

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Log shift' : 'Edit shift'),
          actions: [
            if (!_isNew)
              PopupMenuButton<String>(
                key: const Key('shift-menu'),
                onSelected: (v) {
                  if (v == 'delete') {
                    _delete();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => ShiftEditScreen(prefill: widget.shift)),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(key: Key('shift-duplicate'), value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(key: Key('shift-delete'), value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
        body: ListView(
          key: const Key('shift-form'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Job
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final j in pickable)
                  ChoiceChip(
                    key: Key('shift-job-${j.id}'),
                    avatar: CircleAvatar(backgroundColor: jobColor(j.colorIndex), radius: 7),
                    label: Text(j.name),
                    selected: j.id == _jobId,
                    onSelected: (_) {
                      setState(() => _jobId = j.id);
                      _changed();
                    },
                  ),
                ActionChip(
                  key: const Key('shift-new-job'),
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('New job'),
                  onPressed: () async {
                    final id = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => const JobEditScreen()));
                    if (id != null) {
                      setState(() => _jobId = id);
                      _changed();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('shift-date'),
                    onPressed: _pickDay,
                    icon: const Icon(Icons.event),
                    label: Text(DateFormat(_day.year == today.year ? 'EEE d MMM' : 'EEE d MMM yyyy').format(_day), key: const Key('shift-date-label')),
                  ),
                ),
                const SizedBox(width: 8),
                for (final (label, dd) in [('Today', today), ('Yesterday', addDays(today, -1))])
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      key: Key('day-${label.toLowerCase()}'),
                      label: Text(label),
                      selected: _day == dd,
                      onSelected: (_) {
                        setState(() => _day = dd);
                        _changed();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Hours
            Row(
              children: [
                Text('Hours', style: theme.textTheme.titleMedium),
                const Spacer(),
                SegmentedButton<bool>(
                  key: const Key('hours-mode'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('Start / end'), icon: Icon(Icons.schedule)),
                    ButtonSegment(value: false, label: Text('Total'), icon: Icon(Icons.timelapse)),
                  ],
                  selected: {_useTimes},
                  onSelectionChanged: (s) {
                    setState(() => _useTimes = s.first);
                    _changed();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_useTimes)
              Row(
                children: [
                  Expanded(child: TimeField(controller: _start, label: 'Started', fieldKey: const Key('shift-start'))),
                  const SizedBox(width: 8),
                  Expanded(child: TimeField(controller: _end, label: 'Finished', fieldKey: const Key('shift-end'))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 92,
                    child: TextField(
                      key: const Key('shift-break'),
                      controller: _break,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Break', suffixText: 'min'),
                    ),
                  ),
                ],
              )
            else
              TextField(
                key: const Key('shift-hours'),
                controller: _hours,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Hours worked', hintText: '6.5 or 6:30', prefixIcon: Icon(Icons.timelapse)),
              ),
            if (_useTimes && d.startMinute != null && d.endMinute != null && d.endMinute! >= 0 && d.startMinute! >= 0 && d.endMinute! <= d.startMinute!)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Finishes the next morning', key: const Key('overnight-note'), style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 20),
            // Tips
            Text('Tips', style: theme.textTheme.titleMedium),
            Text('Fill in only what you got. Cash only or card only is fine.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: MoneyField(controller: _cash, fieldKey: const Key('shift-cash'), label: 'Cash', icon: Icons.payments_outlined, symbol: symbol)),
                const SizedBox(width: 8),
                Expanded(child: MoneyField(controller: _card, fieldKey: const Key('shift-card'), label: 'Card', icon: Icons.credit_card, symbol: symbol)),
              ],
            ),
            if (showSales) ...[
              const SizedBox(height: 8),
              MoneyField(
                controller: _sales,
                fieldKey: const Key('shift-sales'),
                label: 'Sales',
                icon: Icons.receipt_long_outlined,
                symbol: symbol,
                helper: terms.$2.needsSales ? 'Your tip-out is ${terms.$2.describe(money)}' : null,
              ),
            ],
            if (_showMore || job?.role == 'bartender') ...[
              const SizedBox(height: 8),
              MoneyField(
                controller: _tipIn,
                fieldKey: const Key('shift-tipin'),
                label: 'Tip-in from coworkers',
                icon: Icons.move_down,
                symbol: symbol,
                helper: 'What servers tipped out to you',
              ),
            ] else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('shift-more'),
                  onPressed: () => setState(() => _showMore = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Add tip-in from coworkers'),
                ),
              ),
            const SizedBox(height: 12),
            // Tip-out
            if (terms.$2.kind != TipOutKind.none || _tipOutEdited)
              Card(
                key: const Key('tipout-card'),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: _tipOutEdited
                      ? Row(
                          children: [
                            Expanded(
                              child: MoneyField(
                                controller: _tipOut,
                                fieldKey: const Key('shift-tipout'),
                                label: 'Tip-out tonight (edited)',
                                icon: Icons.call_split,
                                symbol: symbol,
                              ),
                            ),
                            TextButton(
                              key: const Key('tipout-reset'),
                              onPressed: () {
                                setState(() {
                                  _tipOutEdited = false;
                                  _tipOut.clear();
                                });
                                _changed();
                              },
                              child: const Text('Use rule'),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.call_split),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tip-out ${money(ruleOut)}', key: const Key('tipout-auto'), style: theme.textTheme.titleSmall),
                                  Text(terms.$2.describe(money), style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            TextButton(
                              key: const Key('tipout-edit'),
                              onPressed: () {
                                setState(() {
                                  _tipOutEdited = true;
                                  _tipOut.text = centsToInput(ruleOut);
                                });
                                _changed();
                              },
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('tipout-add'),
                  onPressed: () {
                    setState(() => _tipOutEdited = true);
                    _changed();
                  },
                  icon: const Icon(Icons.call_split),
                  label: const Text('I tipped out tonight'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('shift-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes', hintText: 'Section, drawer count, anything to remember', prefixIcon: Icon(Icons.edit_note)),
            ),
            const SizedBox(height: 8),
            _SummaryCard(math: math, money: money),
            if (check != null && check.warnings.isNotEmpty && _error == null)
              for (final w in check.warnings)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(w, key: const Key('shift-warning'))),
                    ],
                  ),
                ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, key: const Key('shift-error'), style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              key: const Key('shift-save'),
              onPressed: _saving || pickable.isEmpty ? null : _save,
              icon: const Icon(Icons.savings_outlined),
              label: Text(_isNew ? 'Save shift' : 'Save changes'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Live breakdown of tonight: updates as the person types.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.math, required this.money});
  final ShiftMath? math;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final m = math;
    return BrandPanel(
      key: const Key('shift-summary'),
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
          style: TextStyle(color: brand.onBrand),
          child: m == null
              ? const Text('Enter your hours to see what you made tonight.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('You made'),
                              Text(
                                money(m.takeHome),
                                key: const Key('summary-total'),
                                style: TextStyle(color: brand.onBrand, fontSize: 30, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${money(m.perHourCents)}/h',
                              key: const Key('summary-rate'),
                              style: TextStyle(color: brand.onBrand, fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            Text(hoursLabel(m.minutes), key: const Key('summary-hours')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _line('Tips', money(m.tipsTotal)),
                    if (m.tipOut != 0) _line('Tip-out', '− ${money(m.tipOut)}', key: 'summary-tipout'),
                    _line('Wages', money(m.wages)),
                    Divider(color: brand.onBrand.withValues(alpha: 0.3)),
                    _line('Cash in pocket tonight', money(m.cashInPocket), key: 'summary-cash'),
                    if (m.cardCents > 0) _line('Card tips (on your paycheck)', money(m.cardCents)),
                  ],
                ),
      ),
    );
  }

  Widget _line(String a, String b, {String? key}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(a)),
        Text(b, key: key == null ? null : Key(key), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
