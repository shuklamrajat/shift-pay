import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entitlements/entitlements.dart';
import '../entitlements/paywall.dart';
import 'settings.dart';

/// Shared settings screen. Apps pass their own tiles in [appSection].
class CoreSettingsScreen extends ConsumerWidget {
  const CoreSettingsScreen({super.key, this.appSection = const []});
  final List<Widget> appSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(coreSettingsProvider);
    final config = ref.watch(appConfigProvider);
    final pro = ref.watch(isProProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(
          key: const Key('settings-pro'),
          leading: Icon(pro ? Icons.verified : Icons.workspace_premium_outlined),
          title: Text(pro ? '${config.appName} Pro is active' : 'Upgrade to Pro'),
          subtitle: Text(pro ? 'Thanks for supporting the app.' : 'Unlock exports and more'),
          onTap: pro
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        ),
        const Divider(),
        ...appSection,
        if (appSection.isNotEmpty) const Divider(),
        ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: const Text('Currency'),
          trailing: DropdownButton<String>(
            key: const Key('settings-currency'),
            value: s.currency,
            items: [for (final c in supportedCurrencies) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => v == null ? null : ref.read(coreSettingsProvider.notifier).setCurrency(v),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Theme'),
          trailing: DropdownButton<ThemeMode>(
            value: s.themeMode,
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (v) => v == null ? null : ref.read(coreSettingsProvider.notifier).setThemeMode(v),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Privacy'),
          subtitle: Text(config.privacyNote),
        ),
      ]),
    );
  }
}
