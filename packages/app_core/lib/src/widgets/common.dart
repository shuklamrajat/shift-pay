import 'package:flutter/material.dart';

import '../ui/core_scenes.dart';
import '../ui/motion.dart';
import '../ui/scene.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action, this.scene});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  /// Animated illustration shown above the title. Falls back to [icon].
  final ScenePaint? scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 220,
              child: scene == null ? Center(child: IconBlob(icon: icon)) : AnimatedScene(paint: scene!),
            ),
            const SizedBox(height: 16),
            Appear(
              child: Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            Appear(
              index: 1,
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), Appear(index: 2, child: action!)],
          ],
        ),
      ),
    );
  }
}

/// Label above a big number. Used on summary cards.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.valueKey});
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(value, key: valueKey, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String body, {String confirm = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(key: const Key('confirm-ok'), onPressed: () => Navigator.pop(c, true), child: Text(confirm)),
      ],
    ),
  );
  return r ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
