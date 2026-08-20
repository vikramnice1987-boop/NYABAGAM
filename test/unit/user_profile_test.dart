import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/profile/domain/user_profile.dart';
import 'package:nyabagam/features/profile/presentation/user_profile_controller.dart';

void main() {
  group('User Profile & Onboarding Controller Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('UserProfile domain model serializes and deserializes correctly', () {
      const profile = UserProfile(
        name: 'Vikram',
        phone: '+91 98400 12345',
        email: 'vikram@example.com',
        city: 'Chennai',
        preferredLanguage: 'ta-IN',
        avatarEmoji: '⚡',
        is2DayAlertsEnabled: true,
        isWhatsAppEnabled: true,
        isOnboardingCompleted: true,
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.name, equals('Vikram'));
      expect(restored.phone, equals('+91 98400 12345'));
      expect(restored.city, equals('Chennai'));
      expect(restored.preferredLanguage, equals('ta-IN'));
      expect(restored.avatarEmoji, equals('⚡'));
      expect(restored.is2DayAlertsEnabled, isTrue);
      expect(restored.isOnboardingCompleted, isTrue);
    });

    test('UserProfileController updates and persists profile data', () async {
      final controller = UserProfileController.instance;
      await controller.init();

      await controller.updateProfile(
        name: 'Vikram B',
        phone: '+91 99999 88888',
        city: 'Bangalore',
        preferredLanguage: 'en-IN',
      );

      expect(controller.profile.name, equals('Vikram B'));
      expect(controller.profile.phone, equals('+91 99999 88888'));
      expect(controller.profile.city, equals('Bangalore'));
    });

    test('UserProfileController completes onboarding flow', () async {
      final controller = UserProfileController.instance;
      await controller.init();

      await controller.completeOnboarding(
        name: 'Alex',
        phone: '+91 91234 56789',
        city: 'Coimbatore',
        preferredLanguage: 'ta-IN',
      );

      expect(controller.isOnboardingCompleted, isTrue);
      expect(controller.profile.name, equals('Alex'));
      expect(controller.profile.preferredLanguage, equals('ta-IN'));
    });

    test('UserProfileController exports memories as JSON backup', () async {
      final controller = UserProfileController.instance;
      await controller.init();

      final jsonBackup = await controller.exportMemoriesJson();
      expect(jsonBackup, contains('user_profile'));
      expect(jsonBackup, contains('memories'));
      expect(jsonBackup, contains('version'));
    });
  });
}