class UserProfile {
  const UserProfile({
    this.name = 'Vikram',
    this.phone = '+91 98400 12345',
    this.email = 'vikram@example.com',
    this.city = 'Chennai',
    this.preferredLanguage = 'en-IN',
    this.avatarEmoji = '👨‍💼',
    this.is2DayAlertsEnabled = true,
    this.isWhatsAppEnabled = true,
    this.isOnboardingCompleted = false,
  });

  final String name;
  final String phone;
  final String email;
  final String city;
  final String preferredLanguage;
  final String avatarEmoji;
  final bool is2DayAlertsEnabled;
  final bool isWhatsAppEnabled;
  final bool isOnboardingCompleted;

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? preferredLanguage,
    String? avatarEmoji,
    bool? is2DayAlertsEnabled,
    bool? isWhatsAppEnabled,
    bool? isOnboardingCompleted,
  }) => UserProfile(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    city: city ?? this.city,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
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
    avatarEmoji: json['avatar_emoji'] as String? ?? '👨‍💼',
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
    'avatar_emoji': avatarEmoji,
    'is_2day_alerts_enabled': is2DayAlertsEnabled,
    'is_whatsapp_enabled': isWhatsAppEnabled,
    'is_onboarding_completed': isOnboardingCompleted,
  };
}