import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/features/auth/presentation/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    test('sends and verifies Gmail OTP in local test environment', () async {
      final auth = AuthController.instance;

      final invalidResult = await auth.sendGmailOtp('invalid-email');
      expect(invalidResult.success, isFalse);

      final sendResult = await auth.sendGmailOtp('vikram@gmail.com');
      expect(sendResult.success, isTrue);
      expect(sendResult.devCode, isNotNull);

      final devCode = sendResult.devCode!;
      final verifyResult = await auth.verifyGmailOtp(
        email: 'vikram@gmail.com',
        otp: devCode,
      );
      expect(verifyResult.success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentEmail, equals('vikram@gmail.com'));
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
