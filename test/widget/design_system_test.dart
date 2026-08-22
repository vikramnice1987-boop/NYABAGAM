import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/shared/components/ny_button.dart';
import 'package:nyabagam/shared/components/ny_entity_chip.dart';
import 'package:nyabagam/shared/components/ny_evidence_card.dart';
import 'package:nyabagam/shared/components/ny_status_chip.dart';

void main() {
  group('Design System Components Widget Tests', () {
    testWidgets('NyButton renders and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NyButton(
              label: 'Click Me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      expect(tapped, isTrue);
    });

    testWidgets('NyEntityChip renders entity label and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: NyEntityChip(
              label: 'Ravi',
              type: NyEntityType.person,
            ),
          ),
        ),
      );

      expect(find.text('Ravi'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('NyEvidenceCard renders snippet and date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NyEvidenceCard(
              title: 'AC Service',
              snippet: 'Ravi serviced the AC for 800.',
              date: DateTime(2026, 8, 20),
            ),
          ),
        ),
      );

      expect(find.textContaining('AC Service'), findsOneWidget);
      expect(find.textContaining('Ravi serviced the AC for 800'), findsOneWidget);
    });

    testWidgets('NyStatusChip renders formatted status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: NyStatusChip(status: 'resolved'),
          ),
        ),
      );

      expect(find.text('RESOLVED'), findsOneWidget);
    });
  });
}