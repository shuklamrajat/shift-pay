import 'package:app_core/app_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/time_format.dart';

class JobEditScreen extends ConsumerStatefulWidget {
  const JobEditScreen({super.key, this.job});
  final Job? job;

  @override
  ConsumerState<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends ConsumerState<JobEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _rate, _daily, _double, _weekly, _ot, _dt, _workdayStart;
  late bool _useDaily, _useDouble, _useWeekly;
  late int _weekStart;

  static String _hours(int? min, String fallback) =>
      min == null ? fallback : (min % 60 == 0 ? '${min ~/ 60}' : (min / 60).toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _name = TextEditingController(text: j?.name ?? '');
    _rate = TextEditingController(text: j == null ? '' : Money.plain(j.rateCents));
    _useDaily = j == null ? true : j.dailyLimitMin != null;
    _useDouble = j?.dailyDoubleMin != null;
    _useWeekly = j == null ? true : j.weeklyLimitMin != null;
    _daily = TextEditingController(text: _hours(j?.dailyLimitMin, '8'));
    _double = TextEditingController(text: _hours(j?.dailyDoubleMin, '12'));
    _weekly = TextEditingController(text: _hours(j?.weeklyLimitMin, '40'));
    _ot = TextEditingController(text: ((j?.otPct ?? 150) / 100).toString());
    _dt = TextEditingController(text: ((j?.doublePct ?? 200) / 100).toString());
    final ws = j?.workdayStartMinute ?? 0;
    _workdayStart = TextEditingController(
      text: '${(ws ~/ 60).toString().padLeft(2, '0')}:${(ws % 60).toString().padLeft(2, '0')}',
    );
    _weekStart = j?.weekStartsOn ?? DateTime.monday;
  }

  int? _hoursToMin(String s) {
    final v = double.tryParse(s.trim());
    if (v == null || v <= 0 || v > 168) return null;
    return (v * 60).round();
  }

  int? _pct(String s) {
    final v = double.tryParse(s.trim());
    if (v == null || v < 1 || v > 5) return null;
    return (v * 100).round();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final daily = _useDaily ? _hoursToMin(_daily.text) : null;
    final dbl = _useDouble ? _hoursToMin(_double.text) : null;
    final c = JobsCompanion(
      id: widget.job == null ? const Value.absent() : Value(widget.job!.id),
      name: Value(_name.text.trim()),
      rateCents: Value(Money.parse(_rate.text)!),
      dailyLimitMin: Value(daily),
      dailyDoubleMin: Value(dbl),
      weeklyLimitMin: Value(_useWeekly ? _hoursToMin(_weekly.text) : null),
      otPct: Value(_pct(_ot.text)!),
      doublePct: Value(_pct(_dt.text)!),
      weekStartsOn: Value(_weekStart),
      workdayStartMinute: Value(parseTimeOfDay(_workdayStart.text)!),
    );
    final id = await ref.read(repositoryProvider).saveJob(c);
    await ref.read(selectedJobIdProvider.notifier).select(id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    String? hoursValidator(String? v) => _hoursToMin(v ?? '') == null ? 'Hours, e.g. 8' : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job == null ? 'New job' : 'Edit job'),
        actions: [TextButton(key: const Key('save-job'), onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('job-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Job name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Give the job a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('job-rate'),
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Hourly rate'),
              validator: (v) => Money.parse(v ?? '') == null ? 'An amount like 18.50' : null,
            ),
            const SizedBox(height: 16),
            Text('Overtime rules', style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile(
              key: const Key('job-use-daily'),
              title: const Text('Daily overtime'),
              value: _useDaily,
              onChanged: (v) => setState(() => _useDaily = v),
            ),
            if (_useDaily)
              TextFormField(
                key: const Key('job-daily'),
                controller: _daily,
                decoration: const InputDecoration(labelText: 'Overtime after this many hours in a day'),
                validator: hoursValidator,
              ),
            SwitchListTile(
              key: const Key('job-use-double'),
              title: const Text('Daily double time'),
              value: _useDouble,
              onChanged: (v) => setState(() => _useDouble = v),
            ),
            if (_useDouble)
              TextFormField(
                key: const Key('job-double'),
                controller: _double,
                decoration: const InputDecoration(labelText: 'Double time after this many hours in a day'),
                validator: (v) {
                  final e = hoursValidator(v);
                  if (e != null) return e;
                  if (_useDaily && (_hoursToMin(v!) ?? 0) <= (_hoursToMin(_daily.text) ?? 0)) {
                    return 'Has to be more than the overtime hours';
                  }
                  return null;
                },
              ),
            SwitchListTile(
              key: const Key('job-use-weekly'),
              title: const Text('Weekly overtime'),
              value: _useWeekly,
              onChanged: (v) => setState(() => _useWeekly = v),
            ),
            if (_useWeekly)
              TextFormField(
                key: const Key('job-weekly'),
                controller: _weekly,
                decoration: const InputDecoration(labelText: 'Overtime after this many regular hours in a week'),
                validator: hoursValidator,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('job-ot-mult'),
                    controller: _ot,
                    decoration: const InputDecoration(labelText: 'Overtime multiplier'),
                    validator: (v) => _pct(v ?? '') == null ? 'e.g. 1.5' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('job-dt-mult'),
                    controller: _dt,
                    decoration: const InputDecoration(labelText: 'Double time multiplier'),
                    validator: (v) => _pct(v ?? '') == null ? 'e.g. 2' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('job-week-start'),
              initialValue: _weekStart,
              decoration: const InputDecoration(labelText: 'Work week starts on'),
              items: const [
                DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
              ],
              onChanged: (v) => setState(() => _weekStart = v ?? DateTime.monday),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('job-workday-start'),
              controller: _workdayStart,
              decoration: const InputDecoration(
                labelText: 'Workday starts at',
                helperText: 'Night shift? Set 04:00 so a 2 am start counts toward the day before.',
              ),
              validator: (v) => parseTimeOfDay(v ?? '') == null ? 'A time like 04:00' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'A shift counts toward the workday it starts in. Hours already paid as daily overtime '
              'do not count again toward the weekly limit. Seventh-day rules are not supported yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton(key: const Key('save-job-bottom'), onPressed: _save, child: const Text('Save job')),
          ],
        ),
      ),
    );
  }
}
