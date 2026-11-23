import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../backup/backup_service.dart';
import '../data/repository.dart';
import '../domain/periods.dart';
import '../domain/tip_math.dart';
import 'backup_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tipSettingsProvider);
    final last = ref.watch(backupListProvider).value?.firstOrNull;
    final offDevice = ref.watch(lastOffDeviceProvider);
    final now = ref.watch(clockProvider)();
    final n = ref.read(tipSettingsProvider.notifier);
    return CoreSettingsScreen(
      appSection: [
        ListTile(
          key: const Key('settings-backup'),
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Backup & restore'),
          subtitle: Text(
            last == null
                ? 'No backup yet'
                : 'Last backup ${whenLabel(last.createdAt, now)}${offDevice == null ? ' · never saved off this phone' : ''}',
            key: const Key('settings-backup-sub'),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_view_week),
          title: const Text('Week starts on'),
          trailing: DropdownButton<int>(
            key: const Key('settings-week-start'),
            value: s.weekStartsOn,
            items: const [
              DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
              DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
              DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
            ],
            onChanged: (v) => v == null ? null : n.setWeekStart(v),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: const Text('Pay period'),
          subtitle: s.payKind == PayPeriodKind.semimonthly ? const Text('1st to 15th, 16th to month end') : null,
          trailing: DropdownButton<PayPeriodKind>(
            key: const Key('settings-pay-kind'),
            value: s.payKind,
            items: const [
              DropdownMenuItem(value: PayPeriodKind.weekly, child: Text('Weekly')),
              DropdownMenuItem(value: PayPeriodKind.biweekly, child: Text('Every 2 weeks')),
              DropdownMenuItem(value: PayPeriodKind.semimonthly, child: Text('Twice a month')),
            ],
            onChanged: (v) => v == null ? null : n.setPayPeriod(v, s.payAnchor),
          ),
        ),
        if (s.payKind != PayPeriodKind.semimonthly)
          ListTile(
            key: const Key('settings-pay-anchor'),
            leading: const SizedBox(width: 24),
            title: const Text('A pay period started on'),
            subtitle: Text(DateFormat('EEE d MMM yyyy').format(s.payAnchor)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: s.payAnchor, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) await n.setPayPeriod(s.payKind, d);
            },
          ),
        ListTile(
          key: const Key('settings-tax'),
          leading: const Icon(Icons.account_balance_outlined),
          title: const Text('Tax set-aside'),
          subtitle: const Text('A rough share of your income to put away. Not tax advice.'),
          trailing: Text(formatPct(s.taxBp), key: const Key('settings-tax-value'), style: const TextStyle(fontWeight: FontWeight.w700)),
          onTap: () async {
            final c = TextEditingController(text: formatPct(s.taxBp).replaceAll('%', ''));
            final v = await showDialog<int>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Tax set-aside'),
                content: TextField(
                  key: const Key('tax-input'),
                  controller: c,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(suffixText: '%'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                  FilledButton(
                    key: const Key('tax-save'),
                    onPressed: () {
                      final bp = parsePct(c.text);
                      if (bp != null && bp <= 6000) Navigator.pop(d, bp);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
            if (v != null) await n.setTaxBp(v);
          },
        ),
      ],
    );
  }
}
