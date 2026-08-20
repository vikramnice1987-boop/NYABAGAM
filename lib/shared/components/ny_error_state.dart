import 'package:flutter/material.dart';
import '../../core/theme/ny_spacing.dart';
import 'ny_button.dart';

class NyErrorState extends StatelessWidget {
  const NyErrorState({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NySpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
            const SizedBox(height: NySpacing.space16),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: NySpacing.space8),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: NySpacing.space20),
              NyButton(
                label: 'Retry',
                onPressed: onRetry,
                isFullWidth: false,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}