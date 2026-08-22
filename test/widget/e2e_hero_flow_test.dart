import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/app/app.dart';

void main() {
  group('Flagship AC / Ravi End-to-End Acceptance Journey', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('full lifecycle: Capture -> Understand -> Remember -> Ask -> Context -> Action -> Outcome', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Launch App
      await tester.pumpWidget(const NyabagamApp());
      await tester.pumpAndSettle();

      // Verify Home Screen
      expect(find.text('NYABAGAM'), findsOneWidget);
      expect(find.text('Capture a thought'), findsOneWidget);

      // 2. Open Capture Page
      await tester.tap(find.text('Capture a thought'));
      await tester.pumpAndSettle();

      expect(find.text('Capture memory'), findsOneWidget);

      // Enter capture: "Ravi serviced my AC today for 800."
      await tester.enterText(find.byType(TextField).first, 'Ravi serviced my AC today for 800.');
      await tester.tap(find.text('Review Memory Candidate'));
      await tester.pumpAndSettle();

      // 3. Review Candidate Page
      expect(find.text('Review candidate'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('AC'), findsWidgets);

      // Confirm Memory
      await tester.scrollUntilVisible(
        find.text('Confirm and Save Memory'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm and Save Memory'));
      await tester.pumpAndSettle();

      // 4. Memory Remembered Page
      expect(find.text('Memory saved'), findsOneWidget);

      // Go to Ask Screen
      await tester.tap(find.text('Ask about this'));
      await tester.pumpAndSettle();

      // 5. Ask Screen
      expect(find.text('Ask NYABAGAM'), findsOneWidget);
      await tester.tap(find.text('Who serviced my AC?'));
      await tester.pumpAndSettle();

      // Verify grounded answer
      expect(find.text('GROUNDED ANSWER'), findsOneWidget);
      expect(find.textContaining('Ravi'), findsWidgets);

      // 6. Test Context Bridge - Tap Home Tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // The redesigned home surface is taller, so the Context Bridge triggers
      // sit below the fold on a small viewport. Scroll them into view first,
      // otherwise the tap lands on the floating nav bar instead.
      final acTrigger = find.text('My AC is not working');
      await tester.ensureVisible(acTrigger);
      await tester.pumpAndSettle();
      await tester.tap(acTrigger);
      await tester.pumpAndSettle();

      expect(find.text('Context Bridge'), findsOneWidget);
      expect(find.text('Relevant Historical Memory'), findsOneWidget);
      expect(find.textContaining('Ravi'), findsWidgets);

      // 7. Action Proposal & Approval
      expect(find.text('Review and Approve'), findsWidgets);
      await tester.tap(find.text('Review and Approve').first);
      await tester.pumpAndSettle();

      expect(find.text('Review Action Before Execution'), findsOneWidget);
      expect(find.text('Approve & Send via WhatsApp'), findsOneWidget);

      await tester.tap(find.text('Approve & Send via WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.text('Record Service Outcome (When Done)'), findsOneWidget);

      // 8. Outcome Logging
      await tester.tap(find.text('Record Service Outcome (When Done)'));
      await tester.pumpAndSettle();

      expect(find.text('Record outcome'), findsOneWidget);
      await tester.tap(find.text('Save Outcome & Update Memory'));
      await tester.pumpAndSettle();

      // Returned to Home with updated memory
      expect(find.text('NYABAGAM'), findsOneWidget);
    });
  });
}