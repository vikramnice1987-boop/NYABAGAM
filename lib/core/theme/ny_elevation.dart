import 'package:flutter/material.dart';
import 'ny_colors.dart';

/// Depth model for the glass system.
///
/// Glass reads as physical because of three simultaneous cues: a drop shadow
/// underneath, a bright refracted edge around it, and a specular highlight
/// just inside the top edge. [NyElevation] keeps those three in sync so a
/// surface can never be half-glass.
enum NyGlassLevel {
  /// Recessed wells: inputs, list rows, inactive segments.
  sunken,

  /// The default floating card.
  raised,

  /// Hero surfaces, sheets and the nav bar.
  floating,
}

class NyElevation {
  const NyElevation._();

  /// Blur sigma per level. Deliberately modest — see [maxConcurrentBlurs].
  static double blurFor(NyGlassLevel level) {
    switch (level) {
      case NyGlassLevel.sunken:
        return 12.0;
      case NyGlassLevel.raised:
        return 20.0;
      case NyGlassLevel.floating:
        return 32.0;
    }
  }

  /// `BackdropFilter` is the single most expensive thing in this design.
  /// Screens should stay at or under this many *stacked* blur layers; sibling
  /// blurs are fine, nesting them is not.
  static const int maxConcurrentBlurs = 3;

  static List<BoxShadow> shadow(NyGlassLevel level, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (level) {
      case NyGlassLevel.sunken:
        return const <BoxShadow>[];
      case NyGlassLevel.raised:
        return <BoxShadow>[
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x140B1020),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      case NyGlassLevel.floating:
        return <BoxShadow>[
          BoxShadow(
            color: isDark ? const Color(0x8C000000) : const Color(0x1F0B1020),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x0F0B1020),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
    }
  }

  /// Vertical fill gradient. Light enters from the top, so the surface is
  /// fractionally brighter up there.
  static LinearGradient fill(NyGlassLevel level, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final Color base;
    switch (level) {
      case NyGlassLevel.sunken:
        base = isDark ? NyColors.glassFillSunkenDark : NyColors.glassFillSunkenLight;
      case NyGlassLevel.raised:
        base = isDark ? NyColors.glassFillDark : NyColors.glassFillLight;
      case NyGlassLevel.floating:
        base = isDark ? NyColors.glassFillRaisedDark : NyColors.glassFillRaisedLight;
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        base.withValues(alpha: (base.a * 1.35).clamp(0.0, 1.0)),
        base,
      ],
    );
  }

  /// Top-lit border sweep.
  static LinearGradient edge(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const <Color>[NyColors.glassEdgeTopDark, NyColors.glassEdgeBottomDark]
          : const <Color>[NyColors.glassEdgeTopLight, NyColors.glassEdgeBottomLight],
    );
  }

  static Color specular(Brightness brightness) =>
      brightness == Brightness.dark
          ? NyColors.glassSpecularDark
          : NyColors.glassSpecularLight;
}
