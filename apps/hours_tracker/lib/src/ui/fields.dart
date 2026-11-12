import 'package:flutter/material.dart';

import '../domain/time_format.dart';

/// Date typed as YYYY-MM-DD, or picked from the calendar button.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.controller, required this.label, this.fieldKey});
  final TextEditingController controller;
  final String label;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final initial = parseIsoDate(controller.text) ?? DateTime.now();
            final d = await showDatePicker(
                context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (d != null) controller.text = isoDate(d);
          },
        ),
      ),
      validator: (v) => parseIsoDate(v ?? '') == null ? 'Use a date like 2026-11-02' : null,
    );
  }
}

/// Time typed as 18:30 / 6:30pm, or picked from the clock button.
class TimeField extends StatelessWidget {
  const TimeField({super.key, required this.controller, required this.label, this.fieldKey, this.optional = false});
  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: optional ? 'Still working' : '09:00',
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () async {
            final m = parseTimeOfDay(controller.text) ?? 9 * 60;
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
            if (t != null) {
              controller.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
            }
          },
        ),
      ),
      validator: (v) {
        if (optional && (v == null || v.trim().isEmpty)) return null;
        return parseTimeOfDay(v ?? '') == null ? 'Use a time like 18:30 or 6:30 pm' : null;
      },
    );
  }
}
