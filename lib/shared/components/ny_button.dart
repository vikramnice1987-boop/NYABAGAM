import 'package:flutter/material.dart';

enum NyButtonVariant { primary, secondary, outline, destructive }

class NyButton extends StatelessWidget {
  const NyButton({
    required this.label,
    required this.onPressed,
    this.variant = NyButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final NyButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case NyButtonVariant.primary:
        return FilledButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case NyButtonVariant.secondary:
        return FilledButton.tonal(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case NyButtonVariant.outline:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case NyButtonVariant.destructive:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: child,
        );
    }
  }
}