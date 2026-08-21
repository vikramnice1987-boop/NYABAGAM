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
    final borderRadius = NyRadius.borderMd;
    final cardColor = backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final bColor = borderColor ?? theme.colorScheme.outline;

    return Material(
      color: cardColor,
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: bColor, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}