import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/pay_engine.dart';
import '../domain/time_format.dart';
import 'fields.dart';

class ShiftEditScreen extends ConsumerStatefulWidget {
  const ShiftEditScreen({super.key, required this.job, this.shift});
  final Job job;
  final Shift? shift;

  @override
  ConsumerState<ShiftEditScreen> createState() => _ShiftEditScreenState();
}

class _ShiftEditScreenState extends ConsumerState<ShiftEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _date, _start, _end, _break, _rate, _note;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    final now = ref.read(clockProvider)();
    _date = TextEditingController(text: isoDate(s?.start ?? now));
    _start = TextEditingController(text: s == null ? '' : hhmm(s.start));
    _end = TextEditingController(text: s?.end == null ? '' : hhmm(s!.end!));
    _break = TextEditingController(text: '${s?.unpaidBreakMin ?? 0}');
    _rate = TextEditingController(text: Money.plain(s?.rateCents ?? widget.job.rateCents));
    _note = TextEditingController(text: s?.note ?? '');
    for (final c in [_date, _start, _end, _break]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_date, _start, _end, _break, _rate, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Start and end as moments. An end at or before the start is the next day.
  (DateTime, DateTime?)? _times() {
    final d = parseIsoDate(_date.text);
    final sm = parseTimeOfDay(_start.text);
    if (d == null || sm == null) return null;
    final start = DateTime(d.year, d.month, d.day, sm ~/ 60, sm % 60);
    if (_end.text.trim().isEmpty) return (start, null);
    final em = parseTimeOfDay(_end.text);
    if (em == null) return null;
    var end = DateTime(d.year, d.month, d.day, em ~/ 60, em % 60);
    if (!end.isAfter(start)) end = DateTime(d.year, d.month, d.day + 1, em ~/ 60, em % 60);
    return (start, end);
  }

  bool get _isOpen => widget.shift != null && widget.shift!.end == null;

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final t = _times();
    if (t == null) return;
    if (t.$2 == null && !_isOpen) {
      setState(() => _error = 'Add an end time, or use Clock in for a shift that is still going.');
      return;
    }
    setState(() => _saving = true);
    final wasClosed = widget.shift?.end != null;
    final r = await ref
        .read(repositoryProvider)
        .saveShift(
          id: widget.shift?.id,
          jobId: widget.job.id,
          start: t.$1,
          end: t.$2,
          unpaidBreakMin: int.parse(_break.text.trim()),
          rateCents: Money.parse(_rate.text)!,
          note: _note.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!r.ok) {
      setState(() => _error = r.error);
      return;
    }
    if (!wasClosed && t.$2 != null) {
      await ref.read(ratingPrompterProvider).recordCompletedTask();
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context, 'Delete shift?', 'This removes the shift and its pay.')) return;
    await ref.read(repositoryProvider).deleteShift(widget.shift!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = _times();
    String? hint;
    if (t != null && t.$2 != null) {
      final span = t.$2!.difference(t.$1).inMinutes - (int.tryParse(_break.text.trim()) ?? 0);
      final nextDay = dateOnly(t.$2!) != dateOnly(t.$1);
      hint = '${nextDay ? 'Ends the next day · ' : ''}${hm(span < 0 ? 0 : span)} worked';
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shift == null ? 'Add shift' : 'Edit shift'),
        actions: [
          TextButton(key: const Key('save-shift'), onPressed: _saving ? null : _save, child: const Text('Save')),
          if (widget.shift != null)
            IconButton(key: const Key('delete-shift'), icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.job.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DateField(controller: _date, label: 'Date the shift starts', fieldKey: const Key('shift-date')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TimeField(controller: _start, label: 'Start', fieldKey: const Key('shift-start')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TimeField(controller: _end, label: 'End', fieldKey: const Key('shift-end'), optional: _isOpen),
                ),
              ],
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(hint, key: const Key('shift-hint')),
              ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('shift-break'),
              controller: _break,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Unpaid break (minutes)'),
              validator: (v) => int.tryParse(v?.trim() ?? '') == null ? 'Whole minutes, e.g. 30' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('shift-rate'),
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Hourly rate for this shift'),
              validator: (v) => Money.parse(v ?? '') == null ? 'An amount like 18.50' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('shift-note'),
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  key: const Key('shift-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('save-shift-bottom'),
              onPressed: _saving ? null : _save,
              child: const Text('Save shift'),
            ),
          ],
        ),
      ),
    );
  }
}
