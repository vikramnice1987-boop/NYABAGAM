import 'package:flutter/material.dart';

import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';
import 'ny_button.dart';
import 'ny_empty_state.dart';
import 'ny_scaffold.dart';

class NyErrorState extends StatelessWidget {
  const NyErrorState({
    required this.message,
    this.onRetry,
    this.title = 'Something went wrong',
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NySpacing.space28),
        child: NyReveal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NyMedallion(
                icon: Icons.error_outline_rounded,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: NySpacing.space24),
              Text(
                title,
                style: NyTypography.headlineSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NySpacing.space8),
              Text(
                message,
                style: NyTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: NySpacing.space24),
                NyButton(
                  label: 'Retry',
                  onPressed: onRetry,
                  isFullWidth: false,
                  variant: NyButtonVariant.secondary,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
