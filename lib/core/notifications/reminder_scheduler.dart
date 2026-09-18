import 'package:flutter/foundation.dart';

import '../../features/memory/domain/memory_models.dart';
import 'notification_service.dart';

/// Turns saved memories into scheduled alarms.
///
/// A memory can carry two dates: a warranty expiry and a next-service date.
/// Each gets its own reminder, fired [leadDays] before at the user's chosen
/// time of day.
class ReminderScheduler {
  ReminderScheduler._();
  static final ReminderScheduler instance = ReminderScheduler._();

  /// How far ahead of the date the alert fires.
  static const int leadDays = 2;

  /// Notification ids are derived from the memory id so a reschedule replaces
  /// the previous alarm rather than stacking a duplicate. The two offsets keep
  /// warranty and service alarms distinct for the same memory.
  static const int _warrantySalt = 1;
  static const int _serviceSalt = 2;

  int _idFor(String memoryId, int salt) {
    // Android notification ids must fit in a 32-bit int.
    return (memoryId.hashCode ^ (salt * 0x9E3779B1)).abs() % 0x7FFFFFFF;
  }

  /// The moment an alert for [target] should fire: [leadDays] earlier, at the
  /// user's chosen time of day. Public so the arithmetic is directly testable.
  static DateTime alertMomentFor(DateTime target, int hour, int minute) {
    final day = target.subtract(const Duration(days: leadDays));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  DateTime _alertMoment(DateTime target, int hour, int minute) =>
      alertMomentFor(target, hour, minute);

  /// Schedules (or reschedules) both reminders for one memory.
  ///
  /// Returns the number of alarms actually placed — zero means every relevant
  /// date is already in the past, which the caller should surface rather than
  /// reporting success.
  Future<int> syncMemory(
    MemoryModel memory, {
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    final warrantyId = _idFor(memory.id, _warrantySalt);
    final serviceId = _idFor(memory.id, _serviceSalt);

    // Always clear first: a date may have been edited or removed.
    await NotificationService.instance.cancel(warrantyId);
    await NotificationService.instance.cancel(serviceId);

    if (!enabled) return 0;

    final label = memory.machineType ?? memory.title;
    int placed = 0;

    final warrantyAt = memory.warrantyExpiresAt;
    if (warrantyAt != null) {
      final ok = await NotificationService.instance.scheduleReminder(
        id: warrantyId,
        title: 'Warranty ending soon',
        body: '$label warranty expires in $leadDays days. Tap to review or message the technician.',
        when: _alertMoment(warrantyAt, hour, minute),
        payload: 'memory:${memory.id}',
      );
      if (ok) placed++;
    }

    final serviceAt = memory.serviceDueAt;
    if (serviceAt != null) {
      final ok = await NotificationService.instance.scheduleReminder(
        id: serviceId,
        title: 'Service due soon',
        body: '$label is due for service in $leadDays days.',
        when: _alertMoment(serviceAt, hour, minute),
        payload: 'memory:${memory.id}',
      );
      if (ok) placed++;
    }

    return placed;
  }

  Future<void> cancelMemory(String memoryId) async {
    await NotificationService.instance.cancel(_idFor(memoryId, _warrantySalt));
    await NotificationService.instance.cancel(_idFor(memoryId, _serviceSalt));
  }

  /// Rebuilds every alarm from the current memory set.
  ///
  /// Android drops all scheduled alarms on reboot and on app reinstall, so this
  /// runs at startup rather than relying on alarms surviving.
  Future<int> rescheduleAll(
    List<MemoryModel> memories, {
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    await NotificationService.instance.cancelAll();
    if (!enabled) return 0;

    int placed = 0;
    for (final m in memories) {
      try {
        placed += await syncMemory(m, hour: hour, minute: minute, enabled: true);
      } catch (e) {
        debugPrint('[ReminderScheduler] failed for ${m.id}: $e');
      }
    }
    debugPrint('[ReminderScheduler] scheduled $placed reminder(s)');
    return placed;
  }
}
