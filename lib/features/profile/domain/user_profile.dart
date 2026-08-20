import 'package:flutter/material.dart';
import '../../../core/theme/ny_colors.dart';

class UserProfile {
  const UserProfile({
    this.name = 'Vikram',
    this.phone = '+91 98400 12345',
    this.email = 'vikram@example.com',
    this.city = 'Chennai',
    this.preferredLanguage = 'en-IN',
    this.avatarId = 'user',
    this.is2DayAlertsEnabled = true,
    this.isWhatsAppEnabled = true,
    this.isOnboardingCompleted = false,
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
        return Colors.purple;
      case 'user':
      default:
        return NyColors.accentLight;
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
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Vikram',
    phone: json['phone'] as String? ?? '+91 98400 12345',
    email: json['email'] as String? ?? 'vikram@example.com',
    city: json['city'] as String? ?? 'Chennai',
    preferredLanguage: json['preferred_language'] as String? ?? 'en-IN',
    avatarId: json['avatar_id'] as String? ?? 'user',
    is2DayAlertsEnabled: json['is_2day_alerts_enabled'] as bool? ?? true,
    isWhatsAppEnabled: json['is_whatsapp_enabled'] as bool? ?? true,
    isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
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
  };
}