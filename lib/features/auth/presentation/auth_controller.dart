import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/supabase/supabase_service.dart';

class AuthController extends ChangeNotifier {
  AuthController._();
  static final AuthController instance = AuthController._();

  User? _currentUser;
  Session? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMagicLinkSent = false;
  StreamSubscription<AuthState>? _authSubscription;

  User? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null || !AppEnvironment.current.isSupabaseConfigured;
  bool get isSupabaseConfigured => AppEnvironment.current.isSupabaseConfigured;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMagicLinkSent => _isMagicLinkSent;

  Future<void> init() async {
    if (!AppEnvironment.current.isSupabaseConfigured) {
      notifyListeners();
      return;
    }

    try {
      final client = SupabaseService.client;
      _currentSession = client.auth.currentSession;
      _currentUser = client.auth.currentUser;

      _authSubscription?.cancel();
      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        _currentSession = data.session;
        _currentUser = data.session?.user;
        notifyListeners();
      }, onError: (err) {
        _errorMessage = _translateError(err);
        notifyListeners();
      });
    } catch (_) {
      // Graceful fallback for offline / unconfigured
    }
    notifyListeners();
  }

  Future<bool> sendMagicLink(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _isMagicLinkSent = false;
    notifyListeners();

    try {
      if (!AppEnvironment.current.isSupabaseConfigured) {
        // Local simulation for offline/dev
        await Future.delayed(const Duration(milliseconds: 500));
        _isMagicLinkSent = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await SupabaseService.client.auth.signInWithOtp(
        email: cleanEmail,
        emailRedirectTo: kIsWeb ? null : 'nyabagam://auth-callback',
      );
      _isMagicLinkSent = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _translateError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String token}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    if (cleanToken.length < 6) {
      _errorMessage = 'Please enter a valid 6-digit verification code.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!AppEnvironment.current.isSupabaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 500));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final res = await SupabaseService.client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.magiclink,
      );
      _currentSession = res.session;
      _currentUser = res.user;
      _isLoading = false;
      notifyListeners();
      return res.session != null;
    } catch (e) {
      _errorMessage = _translateError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (AppEnvironment.current.isSupabaseConfigured) {
        await SupabaseService.client.auth.signOut();
      }
    } catch (_) {}
    _currentSession = null;
    _currentUser = null;
    _isMagicLinkSent = false;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _translateError(dynamic error) {
    if (error is AuthException) {
      if (error.message.toLowerCase().contains('rate limit')) {
        return 'Too many login attempts. Please wait a minute and try again.';
      }
      if (error.message.toLowerCase().contains('invalid email')) {
        return 'Please enter a valid email address.';
      }
      if (error.message.toLowerCase().contains('network') || error.message.toLowerCase().contains('failed host lookup')) {
        return 'Network connection issue. Please check your internet.';
      }
      return error.message;
    }
    final str = error.toString().toLowerCase();
    if (str.contains('network') || str.contains('socketexception') || str.contains('failed host lookup')) {
      return 'Network connection issue. Please check your internet.';
    }
    return 'Authentication error. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}