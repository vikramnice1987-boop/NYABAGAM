import 'package:flutter/material.dart';

/// NYABAGAM Liquid Glass colour system.
///
/// The palette is built in three layers:
///  1. [wallpaper] gradient orbs that live behind everything.
///  2. Translucent glass fills/borders that float above the wallpaper.
///  3. Saturated accents borrowed from the wallpaper itself.
///
/// Legacy token names are preserved so existing screens keep compiling while
/// they migrate onto the glass primitives.
class NyColors {
  const NyColors._();

  // ---------------------------------------------------------------------
  // Wallpaper (the vivid wash the glass refracts)
  // ---------------------------------------------------------------------
  static const wallpaperBaseDark = Color(0xFF05060E);
  static const wallpaperBaseLight = Color(0xFFEDF0FF);

  static const orbIndigo = Color(0xFF4F46E5);
  static const orbViolet = Color(0xFF8B5CF6);
  static const orbCyan = Color(0xFF06B6D4);
  static const orbMagenta = Color(0xFFD946EF);

  // ---------------------------------------------------------------------
  // Glass materials
  // ---------------------------------------------------------------------
  /// Fill tints layered over the wallpaper. Alpha is intentionally low; the
  /// blur behind the surface supplies most of the perceived opacity.
  static const glassFillDark = Color(0x1AFFFFFF); // white @ 10%
  static const glassFillRaisedDark = Color(0x26FFFFFF); // white @ 15%
  static const glassFillSunkenDark = Color(0x0DFFFFFF); // white @ 5%

  static const glassFillLight = Color(0x8CFFFFFF); // white @ 55%
  static const glassFillRaisedLight = Color(0xB3FFFFFF); // white @ 70%
  static const glassFillSunkenLight = Color(0x4DFFFFFF); // white @ 30%

  /// Top-lit edge: brighter at the top, fading toward the bottom.
  static const glassEdgeTopDark = Color(0x40FFFFFF); // white @ 25%
  static const glassEdgeBottomDark = Color(0x14FFFFFF); // white @ 8%

  static const glassEdgeTopLight = Color(0xE6FFFFFF); // white @ 90%
  static const glassEdgeBottomLight = Color(0x66FFFFFF); // white @ 40%

  /// Inner highlight painted just inside the top edge of a glass surface.
  static const glassSpecularDark = Color(0x33FFFFFF);
  static const glassSpecularLight = Color(0xF2FFFFFF);

  // ---------------------------------------------------------------------
  // Accents
  // ---------------------------------------------------------------------
  static const primaryLight = Color(0xFF5B54E8);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLightTint = Color(0xFFE9E8FF);

  static const aiPurple = Color(0xFF9333EA);
  static const memoryCyan = Color(0xFF0891B2);
  static const insightAmber = Color(0xFFE08307);

  static const primaryDarkTheme = Color(0xFF8B92FF);
  static const aiPurpleDark = Color(0xFFC084FC);
  static const memoryCyanDark = Color(0xFF3DDCF5);

  // ---------------------------------------------------------------------
  // Canvas + surfaces (legacy names, retuned for glass)
  // ---------------------------------------------------------------------
  static const backgroundLight = wallpaperBaseLight;
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceSecondaryLight = Color(0xFFF2F4FF);
  static const borderLight = Color(0x1F0B1020);

  static const backgroundDark = wallpaperBaseDark;
  static const surfaceDark = Color(0xFF0D1020);
  static const surfaceSecondaryDark = Color(0xFF161A2E);
  static const borderDark = Color(0x2EFFFFFF);

  // ---------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------
  static const textPrimaryLight = Color(0xFF0B1020);
  static const textSecondaryLight = Color(0xFF454F73);
  static const textTertiaryLight = Color(0xFF6B7599);
  static const disabledLight = Color(0xFF98A0BC);

  static const textPrimaryDark = Color(0xFFF5F7FF);
  static const textSecondaryDark = Color(0xFFC2C9E4);
  static const textTertiaryDark = Color(0xFF919ABC);
  static const disabledDark = Color(0xFF5A6285);

  // ---------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------
  static const statusSuccess = Color(0xFF12B76A);
  static const statusWarning = Color(0xFFF79009);
  static const statusError = Color(0xFFF04438);
  static const statusInfo = Color(0xFF22D3EE);

  // ---------------------------------------------------------------------
  // Entity identity
  // ---------------------------------------------------------------------
  static const entityPerson = Color(0xFF60A5FA);
  static const entityOrg = Color(0xFFC084FC);
  static const entityThing = Color(0xFF34D399);
  static const entityPlace = Color(0xFFFBBF24);
  static const entityEvent = Color(0xFFF472B6);

  // ---------------------------------------------------------------------
  // Backwards-compatibility aliases
  // ---------------------------------------------------------------------
  static const accentLight = memoryCyan;
  static const accentDark = memoryCyanDark;
  static const primaryContainerLight = primaryLightTint;
  static const primaryContainerDark = surfaceSecondaryDark;

  /// The signature accent sweep used on primary actions and hero text.
  static const List<Color> accentGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
  ];

  static const List<Color> memoryGradient = [
    Color(0xFF22D3EE),
    Color(0xFF6366F1),
  ];
}
