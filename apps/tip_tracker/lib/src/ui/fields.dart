import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/time_format.dart';

/// Digits and one decimal point, two decimals at most, $99,999.99 at most.
class MoneyInputFormatter extends TextInputFormatter {
  static final _ok = RegExp(r'^\d{0,5}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.replaceAll(',', '');
    if (_ok.hasMatch(t)) return newValue.copyWith(text: t, selection: TextSelection.collapsed(offset: t.length));
    return oldValue;
  }
}

/// Gives a field a stable id in Android's accessibility tree (its
/// resource-id), taken from its key. Accessibility tools and the on-device
/// check find the field by it even when Android leaves the label out.
class FieldId extends StatelessWidget {
  const FieldId({super.key, required this.fieldKey, required this.child});
  final Key fieldKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = fieldKey;
    return Semantics(container: true, identifier: k is ValueKey<String> ? k.value : null, child: child);
  }
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.fieldKey,
    this.icon,
    this.helper,
    this.onChanged,
    this.symbol = r'$',
  });
  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final IconData? icon;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return FieldId(fieldKey: fieldKey, child: TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [MoneyInputFormatter()],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '$symbol ',
        prefixIcon: icon == null ? null : Icon(icon),
        helperText: helper,
        hintText: '0',
      ),
    ));
  }
}

/// A time typed (18:30, 6:30pm) or picked from the clock button.
class TimeField extends StatelessWidget {
  const TimeField({super.key, required this.controller, required this.label, required this.fieldKey, this.onChanged});
  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return FieldId(fieldKey: fieldKey, child: TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.datetime,
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        labelText: label,
        hintText: '18:30',
        suffixIcon: IconButton(
          tooltip: 'Pick a time',
          icon: const Icon(Icons.access_time),
          onPressed: () async {
            final m = parseTimeOfDay(controller.text) ?? 17 * 60;
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
            if (t != null) {
              controller.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              onChanged?.call();
            }
          },
        ),
      ),
    ));
  }
}

const jobColors = [
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFFEF6C00),
  Color(0xFFC62828),
  Color(0xFF00838F),
  Color(0xFF4E342E),
  Color(0xFFAD1457),
];

Color jobColor(int i) => jobColors[i % jobColors.length];

String centsToInput(int? c) {
  if (c == null || c == 0) return '';
  if (c % 100 == 0) return '${c ~/ 100}';
  return '${c ~/ 100}.${(c % 100).toString().padLeft(2, '0')}';
}

/// A short floating message.
void snack(BuildContext context, String text, {SnackBarAction? action, Duration duration = const Duration(seconds: 4)}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(text), action: action, duration: duration));
}
