import 'package:flutter/material.dart';

class NyColors {
  const NyColors._();

  // Approved Light Theme Tokens
  static const primaryLight = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLightTint = Color(0xFFEEF2FF);

  static const aiPurple = Color(0xFF7C3AED);
  static const memoryCyan = Color(0xFF0891B2);
  static const insightAmber = Color(0xFFD97706);

  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceSecondaryLight = Color(0xFFF1F5F9);
  static const borderLight = Color(0xFFE2E8F0);

  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF475569);
  static const textTertiaryLight = Color(0xFF64748B);
  static const disabledLight = Color(0xFF94A3B8);

  // Approved Dark Theme Tokens
  static const backgroundDark = Color(0xFF0B1120);
  static const surfaceDark = Color(0xFF111827);
  static const surfaceSecondaryDark = Color(0xFF1E293B);

  static const primaryDarkTheme = Color(0xFF818CF8);
  static const aiPurpleDark = Color(0xFFA78BFA);
  static const memoryCyanDark = Color(0xFF22D3EE);

  static const borderDark = Color(0xFF334155);

  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFFCBD5E1);
  static const textTertiaryDark = Color(0xFF94A3B8);
  static const disabledDark = Color(0xFF475569);

  // Status Colors
  static const statusSuccess = Color(0xFF16A34A);
  static const statusWarning = Color(0xFFD97706);
  static const statusError = Color(0xFFDC2626);
  static const statusInfo = Color(0xFF0284C7);

  // Entity Identity Tokens (Mapped to Semantic Colors)
  static const entityPerson = Color(0xFF2563EB);
  static const entityOrg = Color(0xFF7C3AED);
  static const entityThing = Color(0xFF059669);
  static const entityPlace = Color(0xFFD97706);
  static const entityEvent = Color(0xFFDB2777);

  // Backwards compatibility alias getters
  static const accentLight = memoryCyan;
  static const accentDark = memoryCyanDark;
  static const primaryContainerLight = primaryLightTint;
  static const primaryContainerDark = surfaceSecondaryDark;
}