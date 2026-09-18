import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/firebase/firebase_service.dart';
import '../data/gmail_otp_service.dart';
import '../data/phone_auth_service.dart';

/// Authentication state for Firebase Authentication.
///
/// Google is the primary sign-in route. Email is intentionally implemented as
/// a Firebase email-link flow, rather than pretending an email link is a
/// numeric OTP. A Gmail mailbox is not an authentication provider by itself.
class AuthController extends ChangeNotifier {
  AuthController._();
  static final AuthController instance = AuthController._();

  static const _emailForLinkKey = 'nyabagam_email_for_sign_in_link';
  static const _storedEmailKey = 'nyabagam_auth_email';

  User? _currentUser;
  String? _currentEmail;
  bool _isAuthenticatedManually = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMagicLinkSent = false;
  StreamSubscription<User?>? _authSubscription;

  User? get currentUser => _currentUser;
  String? get currentEmail => _currentUser?.email ?? _currentEmail;

  /// Compatibility surface for callers that only need a session identifier.
  String? get currentSession => _currentUser?.uid ?? (_currentEmail != null ? 'local_$_currentEmail' : null);

  bool get isAuthenticated => _currentUser != null || _isAuthenticatedManually;
  bool get isFirebaseConfigured => AppEnvironment.current.isFirebaseConfigured;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMagicLinkSent => _isMagicLinkSent;

  Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    _currentEmail = preferences.getString(_storedEmailKey);
    if (_currentEmail != null && _currentEmail!.isNotEmpty) {
      _isAuthenticatedManually = true;
    }

    if (!isFirebaseConfigured) {
      notifyListeners();
      return;
    }

    try {
      _currentUser = FirebaseService.auth.currentUser;
      await _authSubscription?.cancel();
      _authSubscription = FirebaseService.auth.authStateChanges().listen(
        (user) {
          _currentUser = user;
          notifyListeners();
        },
        onError: (Object error) {
          _errorMessage = _translateError(error);
          notifyListeners();
        },
      );
    } catch (error) {
      _errorMessage = _translateError(error);
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (!isFirebaseConfigured) return true;
    _beginRequest();

    try {
      if (kIsWeb) {
        await FirebaseService.auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final account = await GoogleSignIn(scopes: const <String>['email'])
            .signIn();
        if (account == null) {
          _finishRequest();
          return false;
        }
        final authentication = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: authentication.accessToken,
          idToken: authentication.idToken,
        );
        await FirebaseService.auth.signInWithCredential(credential);
      }
      _finishRequest();
      return true;
    } catch (error) {
      _finishRequest(error);
      return false;
    }
  }

  Future<bool> sendMagicLink(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_isValidEmail(cleanEmail)) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    _beginRequest();
    try {
      if (!isFirebaseConfigured) {
        _isMagicLinkSent = true;
        _finishRequest();
        return true;
      }
      final continueUrl = AppEnvironment.current.firebaseEmailLinkUrl;
      if (continueUrl.isEmpty) {
        throw StateError(
          'Email link is not configured. Set FIREBASE_EMAIL_LINK_URL first.',
        );
      }
      await FirebaseService.auth.sendSignInLinkToEmail(
        email: cleanEmail,
        actionCodeSettings: ActionCodeSettings(
          url: continueUrl,
          handleCodeInApp: true,
          androidPackageName: 'com.nyabagam.nyabagam',
          androidInstallApp: true,
          iOSBundleId: 'com.nyabagam.nyabagam',
        ),
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_emailForLinkKey, cleanEmail);
      _isMagicLinkSent = true;
      _finishRequest();
      return true;
    } catch (error) {
      _finishRequest(error);
      return false;
    }
  }

  /// Completes email-link sign-in after the platform delivers the deep link.
  Future<bool> completeEmailLink(String emailLink) async {
    if (!isFirebaseConfigured ||
        !FirebaseService.auth.isSignInWithEmailLink(emailLink)) {
      return false;
    }
    _beginRequest();
    try {
      final preferences = await SharedPreferences.getInstance();
      final email = preferences.getString(_emailForLinkKey);
      if (email == null || email.isEmpty) {
        throw StateError(
          'Open this link on the same device where you requested sign-in.',
        );
      }
      await FirebaseService.auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      await preferences.remove(_emailForLinkKey);
      _isMagicLinkSent = false;
      _finishRequest();
      return true;
    } catch (error) {
      _finishRequest(error);
      return false;
    }
  }

  /// Sends a 6-digit OTP code to the provided Gmail address.
  Future<OtpResult> sendGmailOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_isValidEmail(cleanEmail)) {
      _errorMessage = 'Please enter a valid Gmail address.';
      notifyListeners();
      return const OtpResult.failure('Please enter a valid Gmail address.');
    }

    _beginRequest();
    try {
      final res = await GmailOtpService.instance.sendOtp(cleanEmail);
      _finishRequest();
      if (!res.success) {
        _errorMessage = res.message;
        notifyListeners();
      }
      return res;
    } catch (error) {
      _finishRequest(error);
      return OtpResult.failure(_translateError(error));
    }
  }

  /// Verifies a 6-digit OTP code and signs in the user.
  Future<OtpResult> verifyGmailOtp({
    required String email,
    required String otp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    _beginRequest();
    try {
      final res = await GmailOtpService.instance.verifyOtp(cleanEmail, cleanOtp);
      if (res.success) {
        _currentEmail = cleanEmail;
        _isAuthenticatedManually = true;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_storedEmailKey, cleanEmail);
      }
      _finishRequest();
      if (!res.success) {
        _errorMessage = res.message;
        notifyListeners();
      }
      return res;
    } catch (error) {
      _finishRequest(error);
      return OtpResult.failure(_translateError(error));
    }
  }

  /// Sets guest session for immediate local exploration.
  Future<void> setGuestSession() async {
    _isAuthenticatedManually = true;
    _currentEmail = 'guest@nyabagam.app';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storedEmailKey, _currentEmail!);
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (isFirebaseConfigured) {
        await FirebaseService.auth.signOut();
        if (!kIsWeb) await GoogleSignIn().signOut();
      }
    } catch (_) {
      // Clear local state even when the network is unavailable.
    }
    _currentUser = null;
    _currentEmail = null;
    _isAuthenticatedManually = false;
    _isMagicLinkSent = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storedEmailKey);
    await preferences.remove(_emailForLinkKey);
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _beginRequest() {
    _isLoading = true;
    _errorMessage = null;
    _isMagicLinkSent = false;
    notifyListeners();
  }

  void _finishRequest([Object? error]) {
    _isLoading = false;
    if (error != null) _errorMessage = _translateError(error);
    notifyListeners();
  }

  bool _isValidEmail(String value) =>
      value.contains('@') && value.substring(value.indexOf('@')).contains('.');

  String _translateError(Object error) {
    final message = error is FirebaseAuthException
        ? error.message ?? error.code
        : error.toString();
    final normalized = message.toLowerCase();
    if (normalized.contains('rate') || normalized.contains('too-many')) {
      return 'Too many login attempts. Please wait a minute and try again.';
    }
    if (normalized.contains('email') && normalized.contains('invalid')) {
      return 'Please enter a valid email address.';
    }
    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('failed host lookup')) {
      return 'Network connection issue. Please check your internet.';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
