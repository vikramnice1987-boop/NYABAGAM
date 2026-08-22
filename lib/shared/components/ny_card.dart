import 'package:flutter/material.dart';

import '../../core/theme/ny_elevation.dart';
import '../../core/theme/ny_radius.dart';
import '../../core/theme/ny_spacing.dart';
import 'ny_glass.dart';

/// The default content surface: a raised sheet of glass.
///
/// Kept as a thin wrapper over [NyGlass] so the existing call sites keep
/// working. Pass `blur: false` for rows inside a long list — a blur per row is
/// the fastest way to make a scroll janky.
class NyCard extends StatelessWidget {
  const NyCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(NySpacing.space20),
    this.backgroundColor,
    this.borderColor,
    this.level = NyGlassLevel.raised,
    this.borderRadius = NyRadius.borderXl,
    this.blur = true,
    this.tint,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Opaque override. When supplied the surface stops being glass and becomes
  /// a solid card — used sparingly, e.g. for high-contrast alerts.
  final Color? backgroundColor;
  final Color? borderColor;

  final NyGlassLevel level;
  final BorderRadius borderRadius;
  final bool blur;
  final Gradient? tint;

  @override
  Widget build(BuildContext context) {
    if (backgroundColor != null) {
      final theme = Theme.of(context);
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor ?? theme.colorScheme.outline,
          ),
          boxShadow: NyElevation.shadow(level, theme.brightness),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

    return NyGlass(
      level: level,
      borderRadius: borderRadius,
      padding: padding,
      onTap: onTap,
      blur: blur,
      tint: tint,
      child: child,
    );
  }
}
