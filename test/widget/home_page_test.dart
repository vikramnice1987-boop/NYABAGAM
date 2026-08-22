import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/home/presentation/home_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';

void main() {
  group('HomePage Dashboard Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders HomePage with title and quick capture tiles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NYABAGAM'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Warranty'), findsOneWidget);
      expect(find.text('Ask'), findsOneWidget);
      expect(find.text('Context Bridge'), findsOneWidget);
    });

    testWidgets('renders urgent warranty alert banner when 2-day reminder exists', (tester) async {
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
      });
      await repo.confirm(candidate);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warranty expiring in 2 days'), findsOneWidget);
      expect(find.text('Recent memories'), findsOneWidget);
      expect(find.text('AC Service by Ravi'), findsOneWidget);
    });
  });
}