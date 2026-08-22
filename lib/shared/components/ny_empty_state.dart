import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';
import 'ny_scaffold.dart';

/// Empty states get a glass medallion rather than a grey icon, so a blank
/// screen still looks like part of the product.
class NyEmptyState extends StatelessWidget {
  const NyEmptyState({
    required this.title,
    required this.description,
    this.icon = Icons.inbox_rounded,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NySpacing.space32),
        child: NyReveal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NyMedallion(icon: icon),
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
                description,
                style: NyTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: NySpacing.space28),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular glass badge holding an icon, lit by a soft accent glow.
class NyMedallion extends StatelessWidget {
  const NyMedallion({
    required this.icon,
    this.size = 84,
    this.color,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = color ?? theme.colorScheme.secondary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tint.withValues(alpha: isDark ? 0.28 : 0.20),
            tint.withValues(alpha: isDark ? 0.06 : 0.05),
          ],
        ),
        border: Border.all(
          color: isDark ? NyColors.glassEdgeTopDark : NyColors.glassEdgeTopLight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.26 : 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.4, color: tint),
    );
  }
}
