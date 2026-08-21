import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/context/presentation/context_bridge_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('ContextBridgePage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders ContextBridgePage with situation and relevant past memory', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryRepositoryFactory.current;
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC today for Rs. 800.').withUnderstanding({
        'title': 'AC Service by Ravi',
        'summary': 'Ravi serviced the AC for Rs. 800.',
        'people': ['Ravi'],
        'things': ['AC'],
        'contact_phone': '+91 98400 12345',
      });
      await repo.confirm(candidate);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ContextBridgePage(statement: 'My AC isn\'t working.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Context Bridge'), findsOneWidget);
      expect(find.text('Current Situation'), findsOneWidget);
      expect(find.text('My AC isn\'t working.'), findsOneWidget);
      expect(find.text('Relevant Historical Memory'), findsOneWidget);
      expect(find.text('Review and Approve'), findsWidgets);
    });
  });
}