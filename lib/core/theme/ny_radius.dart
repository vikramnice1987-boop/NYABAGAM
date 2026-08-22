import 'package:flutter/material.dart';

/// Liquid Glass runs on a noticeably rounder geometry than flat Material.
/// Larger radii read as thicker, more physical glass.
class NyRadius {
  const NyRadius._();

  static const double xs = 10.0;
  static const double sm = 14.0;
  static const double md = 18.0;
  static const double lg = 22.0;
  static const double xl = 28.0;
  static const double xxl = 34.0;
  static const double pill = 999.0;

  static const borderXs = BorderRadius.all(Radius.circular(xs));
  static const borderSm = BorderRadius.all(Radius.circular(sm));
  static const borderMd = BorderRadius.all(Radius.circular(md));
  static const borderLg = BorderRadius.all(Radius.circular(lg));
  static const borderXl = BorderRadius.all(Radius.circular(xl));
  static const borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const borderPill = BorderRadius.all(Radius.circular(pill));

  /// Sheets and bottom-anchored surfaces round only their top corners.
  static const borderSheet = BorderRadius.vertical(top: Radius.circular(xxl));
}
