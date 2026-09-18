import 'package:flutter/material.dart';

import '../../../core/theme/ny_colors.dart';

/// The signed-in person.
///
/// Every field defaults to empty. The previous version defaulted to a demo
/// identity ("Vikram", "+91 98400 12345", "Chennai"), which meant a brand-new
/// install already looked like a populated account before the user typed
/// anything — and `fromJson` re-applied those same fallbacks, so the demo data
/// could not be cleared.
class UserProfile {
  const UserProfile({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.city = '',
    this.preferredLanguage = 'en-IN',
    this.avatarId = 'user',
    this.is2DayAlertsEnabled = true,
    this.isWhatsAppEnabled = true,
    this.isOnboardingCompleted = false,
    this.isPhoneVerified = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.createdAt,
  });

  final String name;
  final String phone;
  final String email;
  final String city;
  final String preferredLanguage;
  final String avatarId;
  final bool is2DayAlertsEnabled;
  final bool isWhatsAppEnabled;
  final bool isOnboardingCompleted;

  /// True only after a real backend confirmed the OTP. The offline dev flow
  /// deliberately leaves this false so an unverified number can never be
  /// mistaken for a verified one.
  final bool isPhoneVerified;

  /// Default time of day used when scheduling a warranty reminder.
  final int reminderHour;
  final int reminderMinute;

  final DateTime? createdAt;

  bool get hasProfile => name.trim().isNotEmpty;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  TimeOfDay get reminderTime => TimeOfDay(hour: reminderHour, minute: reminderMinute);

  IconData get avatarIcon {
    switch (avatarId) {
      case 'tech':
        return Icons.engineering_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'badge':
        return Icons.workspace_premium_rounded;
      case 'user':
      default:
        return Icons.person_rounded;
    }
  }

  Color get avatarColor {
    switch (avatarId) {
      case 'tech':
        return NyColors.entityPerson;
      case 'bolt':
        return NyColors.entityThing;
      case 'star':
        return NyColors.statusSuccess;
      case 'shield':
        return NyColors.statusError;
      case 'badge':
        return NyColors.entityOrg;
      case 'user':
      default:
        return NyColors.memoryCyanDark;
    }
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? preferredLanguage,
    String? avatarId,
    bool? is2DayAlertsEnabled,
    bool? isWhatsAppEnabled,
    bool? isOnboardingCompleted,
    bool? isPhoneVerified,
    int? reminderHour,
    int? reminderMinute,
    DateTime? createdAt,
  }) => UserProfile(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    city: city ?? this.city,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    avatarId: avatarId ?? this.avatarId,
    is2DayAlertsEnabled: is2DayAlertsEnabled ?? this.is2DayAlertsEnabled,
    isWhatsAppEnabled: isWhatsAppEnabled ?? this.isWhatsAppEnabled,
    isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    createdAt: createdAt ?? this.createdAt,
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    city: json['city'] as String? ?? '',
    preferredLanguage: json['preferred_language'] as String? ?? 'en-IN',
    avatarId: json['avatar_id'] as String? ?? 'user',
    is2DayAlertsEnabled: json['is_2day_alerts_enabled'] as bool? ?? true,
    isWhatsAppEnabled: json['is_whatsapp_enabled'] as bool? ?? true,
    isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
    isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
    reminderHour: json['reminder_hour'] as int? ?? 9,
    reminderMinute: json['reminder_minute'] as int? ?? 0,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.tryParse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
    'preferred_language': preferredLanguage,
    'avatar_id': avatarId,
    'is_2day_alerts_enabled': is2DayAlertsEnabled,
    'is_whatsapp_enabled': isWhatsAppEnabled,
    'is_onboarding_completed': isOnboardingCompleted,
    'is_phone_verified': isPhoneVerified,
    'reminder_hour': reminderHour,
    'reminder_minute': reminderMinute,
    'created_at': createdAt?.toIso8601String(),
  };
}
