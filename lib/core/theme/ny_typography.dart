import 'package:flutter/material.dart';

/// NYABAGAM type scale.
///
/// No font binaries are bundled: [fontFamily] names the face already loaded by
/// `web/index.html`, and every other platform falls back to the system UI
/// face. The scale — sizes, weights, tracking and line height — is what
/// carries the design, so it holds up on the fallback face too.
class NyTypography {
  const NyTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';

  static const List<String> fallback = <String>[
    'Plus Jakarta Sans',
    'Inter',
    'SF Pro Text',
    '-apple-system',
    'Segoe UI',
    'Roboto',
    'Noto Sans Tamil',
    'sans-serif',
  ];

  static TextStyle _s({
    required double size,
    required double height,
    required FontWeight weight,
    double tracking = 0,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fallback,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: tracking,
  );

  // Display — hero statements only, one per screen.
  static final displayLarge = _s(size: 34, height: 38, weight: FontWeight.w700, tracking: -0.8);
  static final displayMedium = _s(size: 28, height: 33, weight: FontWeight.w700, tracking: -0.6);
  static final displaySmall = _s(size: 24, height: 29, weight: FontWeight.w600, tracking: -0.4);

  // Headline — section and screen titles.
  static final headlineLarge = _s(size: 22, height: 28, weight: FontWeight.w600, tracking: -0.3);
  static final headlineMedium = _s(size: 19, height: 25, weight: FontWeight.w600, tracking: -0.2);
  static final headlineSmall = _s(size: 17, height: 23, weight: FontWeight.w600, tracking: -0.1);

  // Title — card headers.
  static final titleLarge = _s(size: 16, height: 22, weight: FontWeight.w600);
  static final titleMedium = _s(size: 15, height: 21, weight: FontWeight.w600);
  static final titleSmall = _s(size: 14, height: 20, weight: FontWeight.w600);

  // Body.
  static final bodyLarge = _s(size: 16, height: 24, weight: FontWeight.w400);
  static final bodyMedium = _s(size: 14, height: 21, weight: FontWeight.w400);
  static final bodySmall = _s(size: 13, height: 19, weight: FontWeight.w400);

  // Label — buttons, chips, nav.
  static final labelLarge = _s(size: 15, height: 20, weight: FontWeight.w600, tracking: 0.1);
  static final labelMedium = _s(size: 13, height: 17, weight: FontWeight.w600, tracking: 0.1);
  static final labelSmall = _s(size: 11, height: 15, weight: FontWeight.w600, tracking: 0.2);

  /// All-caps eyebrow above a hero or section. Wide tracking is doing the
  /// work here, not size.
  static final overline = _s(size: 10, height: 14, weight: FontWeight.w700, tracking: 1.4);

  /// Tabular figures for amounts, dates and counters so they do not jitter.
  static final numeric = _s(size: 15, height: 21, weight: FontWeight.w600, tracking: -0.1)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextTheme themeFor(Color primary, Color secondary) => TextTheme(
    displayLarge: displayLarge.copyWith(color: primary),
    displayMedium: displayMedium.copyWith(color: primary),
    displaySmall: displaySmall.copyWith(color: primary),
    headlineLarge: headlineLarge.copyWith(color: primary),
    headlineMedium: headlineMedium.copyWith(color: primary),
    headlineSmall: headlineSmall.copyWith(color: primary),
    titleLarge: titleLarge.copyWith(color: primary),
    titleMedium: titleMedium.copyWith(color: primary),
    titleSmall: titleSmall.copyWith(color: primary),
    bodyLarge: bodyLarge.copyWith(color: primary),
    bodyMedium: bodyMedium.copyWith(color: secondary),
    bodySmall: bodySmall.copyWith(color: secondary),
    labelLarge: labelLarge.copyWith(color: primary),
    labelMedium: labelMedium.copyWith(color: secondary),
    labelSmall: labelSmall.copyWith(color: secondary),
  );
}
