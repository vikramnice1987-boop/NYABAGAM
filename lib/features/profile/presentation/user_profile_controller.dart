import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_profile.dart';
import '../../memory/data/memory_repository.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController._();
  static final UserProfileController instance = UserProfileController._();

  static const _storageKey = 'nyabagam_user_profile';
  UserProfile _profile = const UserProfile();
  bool _initialized = false;

  UserProfile get profile => _profile;
  bool get isOnboardingCompleted => _profile.isOnboardingCompleted;
  String get preferredLanguage => _profile.preferredLanguage;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(map);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_profile.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? preferredLanguage,
    String? avatarEmoji,
    bool? is2DayAlertsEnabled,
    bool? isWhatsAppEnabled,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      phone: phone,
      email: email,
      city: city,
      preferredLanguage: preferredLanguage,
      avatarEmoji: avatarEmoji,
      is2DayAlertsEnabled: is2DayAlertsEnabled,
      isWhatsAppEnabled: isWhatsAppEnabled,
    );
    await _persist();
  }

  Future<void> completeOnboarding({
    String? name,
    String? phone,
    String? city,
    String? preferredLanguage,
  }) async {
    _profile = _profile.copyWith(
      name: name ?? _profile.name,
      phone: phone ?? _profile.phone,
      city: city ?? _profile.city,
      preferredLanguage: preferredLanguage ?? _profile.preferredLanguage,
      isOnboardingCompleted: true,
    );
    await _persist();
  }

  Future<void> resetOnboarding() async {
    _profile = _profile.copyWith(isOnboardingCompleted: false);
    await _persist();
  }

  Future<String> exportMemoriesJson() async {
    final memories = await MemoryRepositoryFactory.current.confirmed();
    final data = {
      'user_profile': _profile.toJson(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.2.0',
      'memories_count': memories.length,
      'memories': memories.map((m) => m.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _profile = const UserProfile(isOnboardingCompleted: false);
    } catch (_) {}
    notifyListeners();
  }
}