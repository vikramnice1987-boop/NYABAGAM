import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nyabagam/core/notifications/reminder_scheduler.dart';
import 'package:nyabagam/features/auth/data/phone_auth_service.dart';
import 'package:nyabagam/features/auth/data/phone_number.dart';
import 'package:nyabagam/features/profile/domain/user_profile.dart';
import 'package:nyabagam/features/profile/presentation/user_profile_controller.dart';

void main() {
  group('Real-user onboarding', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('a new profile carries no demo identity', () {
      const profile = UserProfile();
      expect(profile.name, isEmpty);
      expect(profile.phone, isEmpty);
      expect(profile.email, isEmpty);
      expect(profile.city, isEmpty);
      expect(profile.hasProfile, isFalse);
      expect(profile.isOnboardingCompleted, isFalse);
      expect(profile.isPhoneVerified, isFalse);
    });

    test('deserialising a sparse record does not resurrect demo defaults', () {
      // The old fromJson fell back to 'Vikram' / '+91 98400 12345' / 'Chennai',
      // so a cleared profile silently repopulated itself.
      final profile = UserProfile.fromJson(const <String, dynamic>{});
      expect(profile.name, isEmpty);
      expect(profile.phone, isEmpty);
      expect(profile.city, isEmpty);
    });

    test('profile survives a save/load round trip', () async {
      final ctrl = UserProfileController.instance;
      await ctrl.init();
      await ctrl.completeOnboarding(
        name: 'Anita Raman',
        phone: '+919840012345',
        city: 'Madurai',
        isPhoneVerified: true,
      );

      expect(ctrl.profile.name, equals('Anita Raman'));
      expect(ctrl.profile.isOnboardingCompleted, isTrue);
      expect(ctrl.profile.isPhoneVerified, isTrue);
      expect(ctrl.profile.createdAt, isNotNull);

      final restored = UserProfile.fromJson(ctrl.profile.toJson());
      expect(restored.name, equals('Anita Raman'));
      expect(restored.phone, equals('+919840012345'));
      expect(restored.isPhoneVerified, isTrue);
    });

    test('changing the phone number clears verification', () async {
      final ctrl = UserProfileController.instance;
      await ctrl.init();
      await ctrl.completeOnboarding(
        name: 'Anita',
        phone: '+919840012345',
        isPhoneVerified: true,
      );
      expect(ctrl.profile.isPhoneVerified, isTrue);

      await ctrl.updateProfile(phone: '+919999911111');
      expect(ctrl.profile.isPhoneVerified, isFalse,
          reason: 'a new number has not been proven');
    });

    test('initials derive from the name', () {
      expect(const UserProfile(name: 'Anita Raman').initials, equals('AR'));
      expect(const UserProfile(name: 'Anita').initials, equals('A'));
      expect(const UserProfile().initials, isEmpty);
    });
  });

  group('Phone normalisation', () {
    test('accepts the shapes users actually type', () {
      expect(PhoneNumber.normalise('9840012345'), equals('+919840012345'));
      expect(PhoneNumber.normalise('98400 12345'), equals('+919840012345'));
      expect(PhoneNumber.normalise('098400-12345'), equals('+919840012345'));
      expect(PhoneNumber.normalise('919840012345'), equals('+919840012345'));
      expect(PhoneNumber.normalise('+91 98400 12345'), equals('+919840012345'));
    });

    test('rejects input that cannot be a number', () {
      expect(PhoneNumber.normalise(''), isNull);
      expect(PhoneNumber.normalise('12345'), isNull);
      expect(PhoneNumber.normalise('abcdefghij'), isNull);
      expect(PhoneNumber.normalise('+'), isNull);
      expect(PhoneNumber.isValid('98400123456789012'), isFalse);
    });

    test('keeps non-Indian international numbers intact', () {
      expect(PhoneNumber.normalise('+14155550172'), equals('+14155550172'));
    });
  });

  group('Offline OTP is never treated as real verification', () {
    test('a locally accepted code does not mark the number verified', () async {
      final auth = DevPhoneAuth.instance;
      final sent = await auth.sendCode('+919840012345');

      expect(sent.success, isTrue);
      expect(sent.devCode, isNotNull, reason: 'dev mode shows the code instead of sending SMS');

      final result = await auth.verifyCode('+919840012345', sent.devCode!);
      expect(result.success, isTrue);
      expect(result.verified, isFalse,
          reason: 'nothing was proven, so the profile must stay unverified');
    });

    test('a wrong code is rejected', () async {
      final auth = DevPhoneAuth.instance;
      await auth.sendCode('+919840012345');
      final result = await auth.verifyCode('+919840012345', '000000');
      expect(result.success, isFalse);
    });
  });

  group('Reminder timing', () {
    test('fires two days before the date at the chosen time', () {
      final moment = ReminderScheduler.alertMomentFor(
        DateTime(2026, 8, 24, 17, 30),
        9,
        0,
      );
      expect(moment, equals(DateTime(2026, 8, 22, 9, 0)));
    });

    test('crosses a month boundary correctly', () {
      final moment = ReminderScheduler.alertMomentFor(
        DateTime(2026, 9, 1),
        7,
        45,
      );
      expect(moment, equals(DateTime(2026, 8, 30, 7, 45)));
    });
  });
}
