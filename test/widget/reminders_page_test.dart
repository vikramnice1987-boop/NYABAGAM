import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/reminders/presentation/reminders_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('RemindersPage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders RemindersPage with urgent 2-day banner when memory expires soon', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryRepositoryFactory.current;
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC today for Rs. 800.').withUnderstanding({
        'title': 'AC Service by Ravi',
        'summary': 'Ravi serviced the AC with 2-day warranty alert.',
        'people': ['Ravi'],
        'things': ['AC'],
        'warranty_expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'machine_type': 'AC',
        'contact_phone': '+91 98400 12345',
      });
      await repo.confirm(candidate);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const RemindersPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warranties'), findsOneWidget);
      expect(find.text('Machine lifecycle'), findsOneWidget);
      expect(find.text('Action required (1 alert)'), findsOneWidget);
      expect(find.text('Expiring Soon (<= 2 Days)'), findsOneWidget);
      expect(find.text('Appliances'), findsOneWidget);
    });
  });
}