import 'dart:math';

/// Legacy phone-verification surface retained for profile flows.
///
/// NYABAGAM V1 now uses Firebase Google Sign-In and Firebase email links for
/// authentication. Phone OTP is deliberately not silently substituted for
/// Gmail login, and needs a separately approved Firebase phone-auth rollout.
class OtpResult {
  const OtpResult._({
    required this.success,
    this.message,
    this.devCode,
    this.verified = false,
  });

  const OtpResult.sent({String? message, String? devCode})
      : this._(success: true, message: message, devCode: devCode);

  const OtpResult.verified({String? message})
      : this._(success: true, message: message, verified: true);

  const OtpResult.failure(String message)
      : this._(success: false, message: message);

  final bool success;
  final String? message;
  final String? devCode;
  final bool verified;
}

abstract class PhoneAuthService {
  static PhoneAuthService get current => const DisabledPhoneAuth();

  bool get isLive;
  Future<OtpResult> sendCode(String phoneE164);
  Future<OtpResult> verifyCode(String phoneE164, String code);
}

class DisabledPhoneAuth implements PhoneAuthService {
  const DisabledPhoneAuth();

  static const _message =
      'Phone OTP is not enabled. Use Google or email-link sign-in.';

  @override
  bool get isLive => false;

  @override
  Future<OtpResult> sendCode(String phoneE164) async =>
      const OtpResult.failure(_message);

  @override
  Future<OtpResult> verifyCode(String phoneE164, String code) async =>
      const OtpResult.failure(_message);
}

/// Local-only test double. It is not selected by the app and never reports a
/// number as verified. This retains offline profile-flow coverage without
/// making a phone login appear available in production.
class DevPhoneAuth implements PhoneAuthService {
  DevPhoneAuth._();
  static final DevPhoneAuth instance = DevPhoneAuth._();

  String? _issuedCode;

  @override
  bool get isLive => false;

  @override
  Future<OtpResult> sendCode(String phoneE164) async {
    _issuedCode = (Random().nextInt(900000) + 100000).toString();
    return OtpResult.sent(
      message: 'No SMS was sent in local test mode.',
      devCode: _issuedCode,
    );
  }

  @override
  Future<OtpResult> verifyCode(String phoneE164, String code) async {
    if (_issuedCode == null || code != _issuedCode) {
      return const OtpResult.failure('That code did not match.');
    }
    _issuedCode = null;
    return const OtpResult.sent(message: 'Code accepted locally.');
  }
}
