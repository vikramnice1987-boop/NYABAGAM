import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/actions/presentation/action_approval_page.dart';
import 'package:nyabagam/features/outcomes/presentation/outcome_record_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/features/memory/domain/memory_models.dart';

void main() {
  group('Action Approval & Outcome Record Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders ActionApprovalPage with disclaimer and approval button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const proposal = ActionProposal(
        actionType: 'whatsapp',
        recipientName: 'Ravi',
        recipientContact: '+91 98400 12345',
        draftMessage: 'Hi Ravi, my AC needs service check.',
        title: 'Send WhatsApp to Ravi',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ActionApprovalPage(proposal: proposal),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Action Before Execution'), findsOneWidget);
      expect(find.text('NYABAGAM never sends messages without your explicit approval.'), findsOneWidget);
      expect(find.text('Approve & Send via WhatsApp'), findsOneWidget);
      expect(find.text('Cancel Action'), findsOneWidget);
    });

    testWidgets('renders OutcomeRecordPage with status dropdown and save button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const OutcomeRecordPage(thingName: 'AC'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record outcome'), findsOneWidget);
      expect(find.text('Complete the Memory Loop'), findsOneWidget);
      expect(find.text('Save Outcome & Update Memory'), findsOneWidget);
    });
  });
}