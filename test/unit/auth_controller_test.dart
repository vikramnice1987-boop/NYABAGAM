import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/features/auth/presentation/auth_controller.dart';

void main() {
  group('AuthController Unit Tests', () {
    test('initial state validates unconfigured or local state', () async {
      final auth = AuthController.instance;
      await auth.init();

      expect(auth.isLoading, isFalse);
      expect(auth.errorMessage, isNull);
    });

    test('validates email format before sending magic link', () async {
      final auth = AuthController.instance;
      
      final invalidResult = await auth.sendMagicLink('invalid-email');
      expect(invalidResult, isFalse);
      expect(auth.errorMessage, equals('Please enter a valid email address.'));

      auth.clearError();
      expect(auth.errorMessage, isNull);
    });

    test('validates 6-digit OTP format before verification', () async {
      final auth = AuthController.instance;

      final shortOtpResult = await auth.verifyOtp(email: 'test@example.com', token: '123');
      expect(shortOtpResult, isFalse);
      expect(auth.errorMessage, equals('Please enter a valid 6-digit verification code.'));
    });

    test('handles sign out cleanly', () async {
      final auth = AuthController.instance;
      await auth.signOut();

      expect(auth.currentUser, isNull);
      expect(auth.currentSession, isNull);
      expect(auth.isMagicLinkSent, isFalse);
      expect(auth.isLoading, isFalse);
    });
  });
}