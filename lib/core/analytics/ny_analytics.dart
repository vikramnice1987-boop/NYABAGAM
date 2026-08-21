import 'package:flutter/foundation.dart';

class NyAnalytics {
  NyAnalytics._();
  static final NyAnalytics instance = NyAnalytics._();

  final List<Map<String, dynamic>> _eventHistory = [];
  static const int _maxEvents = 100;

  List<Map<String, dynamic>> get recentEvents => List.unmodifiable(_eventHistory);

  void clear() => _eventHistory.clear();

  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    try {
      final sanitized = _sanitize(parameters ?? {});
      final record = {
        'event': name,
        'timestamp': DateTime.now().toIso8601String(),
        'parameters': sanitized,
      };

      _eventHistory.insert(0, record);
      if (_eventHistory.length > _maxEvents) {
        _eventHistory.removeLast();
      }

      if (kDebugMode) {
        debugPrint('[NyAnalytics] $name: $sanitized');
      }
    } catch (_) {
      // Non-blocking, never throw or interrupt UI
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> params) {
    final clean = <String, dynamic>{};
    const sensitiveKeys = {'phone', 'password', 'token', 'otp', 'secret', 'email', 'card', 'raw_audio'};

    params.forEach((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        clean[key] = '[REDACTED]';
      } else if (value is String && value.length > 80) {
        clean[key] = '${value.substring(0, 80)}...';
      } else {
        clean[key] = value;
      }
    });

    return clean;
  }
}