import 'package:flutter/material.dart';
import '../../core/theme/ny_spacing.dart';

class NyEmptyState extends StatelessWidget {
  const NyEmptyState({
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NySpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: NySpacing.space16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: NySpacing.space8),
            Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: NySpacing.space24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}