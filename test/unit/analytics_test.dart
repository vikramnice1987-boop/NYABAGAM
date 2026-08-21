import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/core/analytics/ny_analytics.dart';

void main() {
  group('NyAnalytics Telemetry & Privacy Tests', () {
    setUp(() {
      NyAnalytics.instance.clear();
    });

    test('logs event and maintains recent history', () async {
      await NyAnalytics.instance.logEvent('app_launched', {'source': 'cold_boot'});
      expect(NyAnalytics.instance.recentEvents.length, equals(1));
      expect(NyAnalytics.instance.recentEvents.first['event'], equals('app_launched'));
      expect(NyAnalytics.instance.recentEvents.first['parameters']['source'], equals('cold_boot'));
    });

    test('automatically redacts sensitive keys to preserve user privacy', () async {
      await NyAnalytics.instance.logEvent('action_dispatched', {
        'action_type': 'whatsapp',
        'phone': '+91 98400 12345',
        'email': 'user@example.com',
        'token': 'secret_auth_token',
      });

      final logged = NyAnalytics.instance.recentEvents.first['parameters'];
      expect(logged['action_type'], equals('whatsapp'));
      expect(logged['phone'], equals('[REDACTED]'));
      expect(logged['email'], equals('[REDACTED]'));
      expect(logged['token'], equals('[REDACTED]'));
    });

    test('caps event history to max buffer limit', () async {
      for (int i = 0; i < 120; i++) {
        await NyAnalytics.instance.logEvent('ping_$i');
      }
      expect(NyAnalytics.instance.recentEvents.length, equals(100));
    });
  });
}