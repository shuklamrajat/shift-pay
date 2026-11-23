import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/tip_math.dart';
import 'backup_screen.dart';
import 'fields.dart';
import 'scenes.dart';

const roles = [
  ('server', 'Server', Icons.restaurant),
  ('bartender', 'Bartender', Icons.local_bar),
  ('delivery', 'Delivery', Icons.delivery_dining),
  ('other', 'Other', Icons.work_outline),
];

IconData roleIcon(String role) => roles.firstWhere((r) => r.$1 == role, orElse: () => roles.last).$3;

/// New job, edit job, and the first-run "set up your job" screen.
/// Back with unsaved changes asks first. Returns the saved job id.
class JobEditScreen extends ConsumerStatefulWidget {
  const JobEditScreen({super.key, this.job, this.firstRun = false});
  final Job? job;
  final bool firstRun;

  @override
  ConsumerState<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends ConsumerState<JobEditScreen> {
  late final _name = TextEditingController(text: widget.job?.name ?? '');
  late final _wage = TextEditingController(text: centsToInput(widget.job?.rateCents));
  late final _ruleValue = TextEditingController(text: _initialRuleText());
  late String _role = widget.job?.role ?? 'server';
  late TipOutKind _kind = tipOutKindFromName(widget.job?.tipOutKind ?? 'none');
  late bool _tracksSales = widget.job?.tracksSales ?? false;
  late int _color = widget.job?.colorIndex ?? 0;
  String? _error;
  bool _saving = false;
  late final String _start = _snapshot();

  String _initialRuleText() {
    final j = widget.job;
    if (j == null || j.tipOutKind == 'none') return '';
    if (j.tipOutKind == 'flat') return centsToInput(j.tipOutValue);
    return formatPct(j.tipOutValue).replaceAll('%', '');
  }

  String _snapshot() => [_name.text, _wage.text, _ruleValue.text, _role, _kind, _tracksSales, _color].join('|');
  bool get _dirty => _snapshot() != _start;

  @override
  void initState() {
    super.initState();
    if (widget.job == null) {
      final n = ref.read(allJobsProvider).value?.length ?? 0;
      _color = n % jobColors.length;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _wage.dispose();
    _ruleValue.dispose();
    super.dispose();
  }

  int? _ruleNumber() => switch (_kind) {
    TipOutKind.none => 0,
    TipOutKind.flat => Money.parse(_ruleValue.text),
    _ => parsePct(_ruleValue.text),
  };

  Future<void> _save() async {
    final wage = _wage.text.trim().isEmpty ? 0 : Money.parse(_wage.text);
    if (wage == null) return setState(() => _error = 'Check the hourly wage.');
    final v = _ruleNumber();
    if (v == null) {
      return setState(() => _error = _kind == TipOutKind.flat ? 'Check the tip-out amount.' : 'Use a percentage like 3 or 2.5.');
    }
    setState(() => _saving = true);
    final r = await ref
        .read(repositoryProvider)
        .saveJob(
          id: widget.job?.id,
          name: _name.text,
          role: _role,
          rateCents: wage,
          rule: TipOutRule(_kind, v),
          tracksSales: _tracksSales,
          colorIndex: _color,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!r.ok) return setState(() => _error = r.error);
    await ref.read(tipSettingsProvider.notifier).setLastJob(r.id!);
    // First run is the home screen itself: the job list updating swaps it out.
    if (mounted && !widget.firstRun) Navigator.of(context).pop(r.id);
  }

  Future<void> _skip() async {
    final r = await ref
        .read(repositoryProvider)
        .saveJob(name: 'My job', role: 'other', rateCents: 0, rule: const TipOutRule.none(), tracksSales: false, colorIndex: 0);
    if (r.ok) await ref.read(tipSettingsProvider.notifier).setLastJob(r.id!);
  }

  Future<void> _archive(bool archived) async {
    final j = widget.job!;
    await ref.read(repositoryProvider).setArchived(j.id, archived);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(repositoryProvider);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(archived ? '${j.name} archived. Its shifts are kept.' : '${j.name} is back in your jobs.'),
        action: SnackBarAction(key: const Key('undo-archive'), label: 'Undo', onPressed: () => repo.setArchived(j.id, !archived)),
      ),
    );
  }

  Future<void> _delete() async {
    final j = widget.job!;
    final count = await ref.read(repositoryProvider).shiftCountForJob(j.id);
    if (!mounted) return;
    if (count > 0) {
      final archive = await confirmDialog(
        context,
        'Archive instead?',
        '${j.name} has $count shift${count == 1 ? '' : 's'}. Deleting it would lose them, so archive it: it leaves your job list and every shift is kept.',
        confirm: 'Archive',
      );
      if (archive) await _archive(true);
      return;
    }
    final ok = await confirmDialog(context, 'Delete ${j.name}?', 'It has no shifts, so nothing else is lost.');
    if (!ok) return;
    await ref.read(repositoryProvider).deleteJob(j.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('What you typed for this job won’t be saved.'),
        actions: [
          TextButton(key: const Key('keep-editing'), onPressed: () => Navigator.pop(c, false), child: const Text('Keep editing')),
          FilledButton(key: const Key('discard'), onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final j = widget.job;
    final money = ref.watch(moneyFmtProvider);
    final symbol = money(0).replaceAll(RegExp(r'[\d.,\s]'), '');
    final previewRule = TipOutRule(_kind, _ruleNumber() ?? 0);
    return PopScope(
      canPop: !_dirty || widget.firstRun,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.firstRun,
          title: Text(widget.firstRun ? 'Set up your job' : (j == null ? 'New job' : 'Edit job')),
          actions: [
            if (widget.firstRun) TextButton(key: const Key('job-skip'), onPressed: _skip, child: const Text('Skip')),
            if (j != null)
              PopupMenuButton<String>(
                key: const Key('job-menu'),
                onSelected: (v) => switch (v) {
                  'archive' => _archive(!j.archived),
                  _ => _delete(),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(key: const Key('job-archive'), value: 'archive', child: Text(j.archived ? 'Restore' : 'Archive')),
                  const PopupMenuItem(key: Key('job-delete'), value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (widget.firstRun) ...[
              const SizedBox(height: 160, child: AnimatedScene(paint: jobScene)),
              Text(
                'Where do you work? Your wage and tip-out rule go here, and you can change them any time.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              Center(
                child: TextButton.icon(
                  key: const Key('first-run-restore'),
                  icon: const Icon(Icons.restore),
                  label: const Text('New phone? Restore your backup'),
                  onPressed: () async {
                    final bytes = await ref.read(backupFilePickerProvider)();
                    if (bytes != null && context.mounted) await restoreFlow(context, ref, bytes);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              key: const Key('job-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Job name', hintText: 'e.g. The Oak Room', prefixIcon: Icon(Icons.storefront)),
            ),
            const SizedBox(height: 16),
            Text('Your role', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final (id, label, icon) in roles)
                  ChoiceChip(
                    key: Key('role-$id'),
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selected: _role == id,
                    onSelected: (_) => setState(() {
                      _role = id;
                      if (widget.job == null) _tracksSales = id == 'server' || id == 'bartender';
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            MoneyField(
              controller: _wage,
              fieldKey: const Key('job-wage'),
              label: 'Hourly wage (before tips)',
              icon: Icons.schedule,
              symbol: symbol,
              helper: 'Leave empty if you only earn tips',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text('Tip-out', style: theme.textTheme.titleMedium),
            Text('What you pay the bar, bussers or kitchen each shift.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<TipOutKind>(
              key: const Key('tipout-kind'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: TipOutKind.none, label: Text('None')),
                ButtonSegment(value: TipOutKind.pctSales, label: Text('% sales')),
                ButtonSegment(value: TipOutKind.pctTips, label: Text('% tips')),
                ButtonSegment(value: TipOutKind.flat, label: Text('Flat')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _ruleValue.clear();
                if (_kind == TipOutKind.pctSales) _tracksSales = true;
              }),
            ),
            // AnimatedSize animates inside layout; with system animations off its
            // zero-length animation re-dirties it mid-layout, so skip it then.
            _GrowIn(
              child: _kind == TipOutKind.none
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _kind == TipOutKind.flat
                          ? MoneyField(
                              controller: _ruleValue,
                              fieldKey: const Key('tipout-value'),
                              label: 'Amount each shift',
                              symbol: symbol,
                              onChanged: (_) => setState(() {}),
                            )
                          : TextField(
                              key: const Key('tipout-value'),
                              controller: _ruleValue,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: _kind == TipOutKind.pctSales ? 'Percent of sales' : 'Percent of tips',
                                suffixText: '%',
                                helperText: _kind == TipOutKind.pctSales ? 'Many restaurants use 2% to 5%' : 'Often 10% to 20%',
                              ),
                            ),
                    ),
            ),
            if (_kind != TipOutKind.none && (_ruleNumber() ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Pill(icon: Icons.call_split, text: 'Tip-out ${previewRule.describe(money)}', textKey: const Key('rule-preview')),
              ),
            SwitchListTile(
              key: const Key('tracks-sales'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Track my sales'),
              subtitle: Text(_kind == TipOutKind.pctSales ? 'Needed for a % of sales tip-out' : 'Shows your tip % of sales'),
              value: _tracksSales || _kind == TipOutKind.pctSales,
              onChanged: _kind == TipOutKind.pctSales ? null : (v) => setState(() => _tracksSales = v),
            ),
            const SizedBox(height: 8),
            Text('Colour', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (var i = 0; i < jobColors.length; i++)
                  InkWell(
                    key: Key('job-color-$i'),
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = i),
                    child: AnimatedContainer(
                      duration: Motion.of(context, 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: jobColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: _color == i ? theme.colorScheme.onSurface : Colors.transparent, width: 3),
                      ),
                      child: _color == i ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, key: const Key('job-error'), style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              key: const Key('job-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(widget.firstRun ? 'Start logging' : 'Save job'),
            ),
          ),
        ),
      ),
    );
  }
}


/// Grows and shrinks with its child, or just swaps it when the phone asks
/// for no animations.
class _GrowIn extends StatelessWidget {
  const _GrowIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Motion.reduced(context) ? child : AnimatedSize(duration: const Duration(milliseconds: 220), child: child);
}
