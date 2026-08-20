import 'package:flutter/material.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';

class NyCard extends StatelessWidget {
  const NyCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(NySpacing.space16),
    this.backgroundColor,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color,
        borderRadius: NyRadius.borderMd,
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outline,
          width: 1,
        ),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: NyRadius.borderMd,
        child: card,
      );
    }

    return card;
  }
}