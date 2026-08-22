import 'package:flutter/material.dart';

import '../../core/theme/ny_colors.dart';
import '../../core/theme/ny_spacing.dart';
import '../../core/theme/ny_typography.dart';

/// Heading above a group of cards.
class NySectionHeader extends StatelessWidget {
  const NySectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: NySpacing.space4,
        right: NySpacing.space4,
        bottom: NySpacing.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 17, color: theme.colorScheme.secondary),
            const SizedBox(width: NySpacing.space8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: NyTypography.headlineSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: NySpacing.space2),
                  Text(
                    subtitle!,
                    style: NyTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Text filled with the accent sweep. Reserved for one hero phrase per screen
/// — the gradient stops meaning anything if everything wears it.
class NyGradientText extends StatelessWidget {
  const NyGradientText(
    this.text, {
    this.style,
    this.textAlign,
    this.colors = NyColors.accentGradient,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final effective = style ?? NyTypography.displayMedium;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: effective.copyWith(color: Colors.white),
        textAlign: textAlign,
      ),
    );
  }
}

/// Key/value row used inside detail cards.
class NyDetailRow extends StatelessWidget {
  const NyDetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NySpacing.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: NySpacing.space10),
          ],
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: NyTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: NySpacing.space8),
          Expanded(
            child: Text(
              value,
              style: NyTypography.titleSmall.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
