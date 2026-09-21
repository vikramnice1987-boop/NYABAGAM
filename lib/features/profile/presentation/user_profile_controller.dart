import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_profile.dart';
import '../../memory/data/memory_repository.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/reminder_scheduler.dart';

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
    String? avatarId,
    bool? is2DayAlertsEnabled,
    bool? isWhatsAppEnabled,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final phoneChanged = phone != null && phone != _profile.phone;
    final emailChanged = email != null && email != _profile.email;

    _profile = _profile.copyWith(
      name: name,
      phone: phone,
      email: email,
      city: city,
      preferredLanguage: preferredLanguage,
      avatarId: avatarId,
      // Changing the number or email invalidates any previous verification unless explicitly overridden.
      isPhoneVerified: isPhoneVerified ?? (phoneChanged ? false : null),
      isEmailVerified: isEmailVerified ?? (emailChanged ? false : null),
      is2DayAlertsEnabled: is2DayAlertsEnabled,
      isWhatsAppEnabled: isWhatsAppEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    await _persist();

    // Alert preferences and reminder time both change when alarms should fire.
    if (is2DayAlertsEnabled != null ||
        reminderHour != null ||
        reminderMinute != null) {
      await rescheduleReminders();
    }
  }

  Future<void> completeOnboarding({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? preferredLanguage,
    String? avatarId,
    bool? isPhoneVerified,
    bool? isEmailVerified,
  }) async {
    _profile = _profile.copyWith(
      name: name ?? _profile.name,
      phone: phone ?? _profile.phone,
      email: email ?? _profile.email,
      city: city ?? _profile.city,
      preferredLanguage: preferredLanguage ?? _profile.preferredLanguage,
      avatarId: avatarId ?? _profile.avatarId,
      isPhoneVerified: isPhoneVerified ?? _profile.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? _profile.isEmailVerified,
      isOnboardingCompleted: true,
      createdAt: _profile.createdAt ?? DateTime.now(),
    );
    await _persist();
  }

  /// Rebuilds every scheduled alarm from the current memories and preferences.
  Future<int> rescheduleReminders() async {
    try {
      final memories = await MemoryRepositoryFactory.current.confirmed();
      return await ReminderScheduler.instance.rescheduleAll(
        memories,
        hour: _profile.reminderHour,
        minute: _profile.reminderMinute,
        enabled: _profile.is2DayAlertsEnabled,
      );
    } catch (e) {
      debugPrint('[UserProfileController] reschedule failed: $e');
      return 0;
    }
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
      // Cancel alarms first: they outlive the app data and would keep firing
      // for memories that no longer exist.
      await NotificationService.instance.cancelAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _profile = const UserProfile();
    } catch (e) {
      debugPrint('[UserProfileController] clear failed: $e');
    }
    notifyListeners();
  }
}