import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules warranty and service reminders that fire while the app is closed.
///
/// Everything is local: no push service, no server, nothing leaves the device.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'nyabagam_reminders';
  static const String _channelName = 'Warranty reminders';
  static const String _channelDescription =
      'Alerts before a warranty or service date passes.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool _available = false;

  /// Set when scheduling had to fall back to an inexact alarm because the user
  /// declined the exact-alarm permission. Surfaced in the UI so a reminder that
  /// may drift is not silently presented as precise.
  bool usesInexactFallback = false;

  bool get isAvailable => _available;

  Future<bool> init() async {
    if (_initialised) return _available;
    _initialised = true;

    try {
      tzdata.initializeTimeZones();
      // Device-local scheduling. `tz.local` defaults to UTC until set, which
      // would fire reminders at the wrong hour.
      tz.setLocalLocation(tz.getLocation(await _deviceTimeZone()));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      _available = await _plugin.initialize(
            settings: const InitializationSettings(
              android: android,
              iOS: darwin,
              macOS: darwin,
            ),
          ) ??
          false;

      await _createAndroidChannel();
    } catch (e) {
      debugPrint('[Notifications] init failed: $e');
      _available = false;
    }
    return _available;
  }

  Future<String> _deviceTimeZone() async {
    try {
      // Bounded: on a platform with no implementation this channel never
      // answers, and an unbounded await would hang init() forever.
      final name = (await FlutterTimezone.getLocalTimezone()
              .timeout(const Duration(seconds: 3)))
          .identifier;
      // Guard against an unknown id: tz.getLocation throws on a bad name and
      // would take the whole init down with it.
      tz.getLocation(name);
      return name;
    } catch (e) {
      // Falling back to India Standard Time rather than UTC: this app's users
      // are in IST, and a UTC fallback would fire every reminder 5.5 hours off.
      debugPrint('[Notifications] timezone lookup failed, using Asia/Kolkata: $e');
      return 'Asia/Kolkata';
    }
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Asks for notification permission (Android 13+, iOS). Returns false when
  /// the user declines, so callers can explain why nothing will fire.
  Future<bool> requestPermissions() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission() ?? false;
        return granted;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (e) {
      debugPrint('[Notifications] permission request failed: $e');
    }
    return false;
  }

  /// Android 12+ requires a separate grant to fire alarms at an exact moment.
  Future<bool> requestExactAlarmPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      return await android.requestExactAlarmsPermission() ?? false;
    } catch (e) {
      debugPrint('[Notifications] exact-alarm request failed: $e');
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  /// Schedules a single reminder at an exact wall-clock time.
  ///
  /// Returns false when the time is in the past or scheduling failed, so the
  /// caller can tell the user instead of assuming it worked.
  Future<bool> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!await init()) return false;

    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('[Notifications] skipped id=$id, time already passed');
      return false;
    }

    Future<void> doSchedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: _details,
          androidScheduleMode: mode,
          payload: payload,
        );

    try {
      await doSchedule(AndroidScheduleMode.exactAllowWhileIdle);
      usesInexactFallback = false;
      return true;
    } catch (e) {
      // Thrown when SCHEDULE_EXACT_ALARM was refused. An inexact alarm still
      // fires, just not to the minute - better than nothing, but the UI says so.
      debugPrint('[Notifications] exact schedule refused, falling back: $e');
      try {
        await doSchedule(AndroidScheduleMode.inexactAllowWhileIdle);
        usesInexactFallback = true;
        return true;
      } catch (e2) {
        debugPrint('[Notifications] schedule failed: $e2');
        return false;
      }
    }
  }

  Future<void> cancel(int id) async {
    if (!_available) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[Notifications] cancel failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_available) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[Notifications] cancelAll failed: $e');
    }
  }

  Future<List<PendingNotificationRequest>> pending() async {
    if (!await init()) return const <PendingNotificationRequest>[];
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('[Notifications] pending lookup failed: $e');
      return const <PendingNotificationRequest>[];
    }
  }
}
