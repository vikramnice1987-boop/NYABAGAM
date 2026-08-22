import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/ask/presentation/ask_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('AskPage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders AskPage with language pills, search bar, and suggestions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AskPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ask NYABAGAM'), findsOneWidget);
      expect(find.text('VOICE LANGUAGE'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('Who serviced my AC?'), findsOneWidget);
      expect(find.text('AC service cost?'), findsOneWidget);
    });

    testWidgets('answers query with grounded facts from memory repository', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryRepositoryFactory.current;
      final candidate = MemoryCandidate.fromText('Ravi serviced my AC today for Rs. 800.').withUnderstanding({
        'title': 'AC Service by Ravi',
        'summary': 'Ravi serviced the AC for Rs. 800.',
        'people': ['Ravi'],
        'things': ['AC'],
        'amount': 800,
        'contact_phone': '+91 98400 12345',
      });
      await repo.confirm(candidate);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AskPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Who serviced my AC?');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('GROUNDED ANSWER'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.textContaining('Ravi'), findsWidgets);
    });
  });
}