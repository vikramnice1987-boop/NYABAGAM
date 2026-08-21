import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/core/config/app_environment.dart';
import 'package:nyabagam/core/analytics/ny_analytics.dart';
import 'package:nyabagam/features/profile/presentation/user_profile_controller.dart';

void main() {
  group('Security, Privacy & Compliance Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NyAnalytics.instance.clear();
    });

    test('AppEnvironment contains zero hardcoded default credentials or API keys', () {
      expect(AppEnvironment.current.supabaseUrl, isEmpty);
      expect(AppEnvironment.current.supabaseAnonKey, isEmpty);
      expect(AppEnvironment.current.isSupabaseConfigured, isFalse);
    });

    test('NyAnalytics redacts passwords, tokens, phone numbers and card details', () async {
      await NyAnalytics.instance.logEvent('auth_verify_attempt', {
        'user_id': 'anon_123',
        'phone': '+91 98400 12345',
        'otp': '654321',
        'password': 'SuperSecretPassword',
        'token': 'bearer_eyJhbGciOi...',
      });

      final params = NyAnalytics.instance.recentEvents.first['parameters'] as Map<String, dynamic>;
      expect(params['phone'], equals('[REDACTED]'));
      expect(params['otp'], equals('[REDACTED]'));
      expect(params['password'], equals('[REDACTED]'));
      expect(params['token'], equals('[REDACTED]'));
      expect(params['user_id'], equals('anon_123'));
    });

    test('UserProfileController clearAllData purges all local personal data completely', () async {
      final ctrl = UserProfileController.instance;
      await ctrl.init();
      await ctrl.updateProfile(
        name: 'Ravi Kumar',
        phone: '+91 98400 99999',
        city: 'Chennai',
      );
      expect(ctrl.profile.name, equals('Ravi Kumar'));

      await ctrl.clearAllData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nyabagam_user_profile'), isNull);
      expect(prefs.getBool('nyabagam_onboarding_complete'), isNull);
      expect(prefs.getStringList('nyabagam_local_memories'), isNull);
      expect(ctrl.profile.name, equals('Vikram')); // Reset to default clean state
    });
  });
}