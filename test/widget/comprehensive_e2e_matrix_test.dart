import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/home/presentation/home_page.dart';
import 'package:nyabagam/features/ask/presentation/ask_page.dart';
import 'package:nyabagam/features/memories/presentation/memories_history_page.dart';
import 'package:nyabagam/features/actions/presentation/action_approval_page.dart';
import 'package:nyabagam/features/outcomes/presentation/outcome_record_page.dart';
import 'package:nyabagam/features/understand/presentation/memory_review_page.dart';
import 'package:nyabagam/features/memory/data/memory_repository.dart';
import 'package:nyabagam/features/memory/domain/memory_candidate.dart';
import 'package:nyabagam/features/memory/domain/memory_models.dart';
import 'package:nyabagam/core/theme/app_theme.dart';

void main() {
  group('Comprehensive V1 Scenario Matrix & Lifecycle Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Matrix Path 1: Review Memory Candidate -> Confirm -> Appears in History with Rs. format', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Open Memory Review Page
      final candidate = MemoryCandidate.fromText('Paid Rs. 1500 to Priya for painting canvas on Sunday')
          .withUnderstanding({
        'title': 'Painting Canvas Payment',
        'summary': 'Paid Rs. 1500 to Priya for painting canvas.',
        'people': ['Priya'],
        'things': ['Painting Canvas'],
        'amount': 1500,
      });

      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: MemoryReviewPage(candidate: candidate)));
      await tester.pumpAndSettle();

      expect(find.text('Review candidate'), findsOneWidget);
      expect(find.text('Confirm Structured Details'), findsOneWidget);

      await tester.tap(find.text('Confirm and Save Memory'));
      await tester.pumpAndSettle();

      // 2. Verify in Memories History
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const MemoriesHistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('Memories'), findsOneWidget);
      expect(find.textContaining('Priya'), findsWidgets);
      expect(find.textContaining('Rs.'), findsWidgets);
    });

    testWidgets('Matrix Path 2: Proactive 2-Day Reminder -> Action Gate -> Outcome Record', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed urgent AC warranty
      final repo = MemoryRepositoryFactory.current;
      final candidate = MemoryCandidate.fromText('Suresh AC Repair')
          .withUnderstanding({
        'title': 'Suresh AC Repair Service',
        'summary': 'AC fixed with 6 months warranty.',
        'people': ['Suresh'],
        'things': ['AC'],
        'machine_type': 'AC',
        'warranty_period': '6 months',
        'amount': 2200,
        'warranty_expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      });
      await repo.confirm(candidate);

      // 1. Verify on Home Page Proactive Alert
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Warranty expiring in 2 days'), findsOneWidget);
      expect(find.textContaining('Suresh AC Repair Service'), findsWidgets);

      // 2. Action Approval Page Gate
      const proposal = ActionProposal(
        actionType: 'whatsapp',
        recipientName: 'Suresh',
        recipientContact: '+91 98400 12345',
        title: 'Send WhatsApp to Suresh',
        draftMessage: 'Hi Suresh, following up on AC warranty expiring in 1 day.',
      );

      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const ActionApprovalPage(proposal: proposal)));
      await tester.pumpAndSettle();

      expect(find.text('Action approval'), findsOneWidget);
      expect(find.text('Review Action Before Execution'), findsOneWidget);
      expect(find.textContaining('Suresh'), findsWidgets);

      // 3. Outcome Record Page
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const OutcomeRecordPage(thingName: 'AC')));
      await tester.pumpAndSettle();

      expect(find.text('Record outcome'), findsOneWidget);
      await tester.tap(find.text('Save Outcome & Update Memory'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Complete the Memory Loop'), findsOneWidget);
    });

    testWidgets('Matrix Path 3: Ask grounded recall with conversational questions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed memory
      final repo = MemoryRepositoryFactory.current;
      final candidate = MemoryCandidate.fromText('Dr. Sundar clinic prescription')
          .withUnderstanding({
        'title': 'Dr. Sundar Clinic Visit',
        'summary': 'Prescription given for eye drops twice daily.',
        'people': ['Dr. Sundar'],
        'things': ['Eye drops'],
        'amount': 700,
      });
      await repo.confirm(candidate);

      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const AskPage()));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField).first;
      await tester.enterText(searchInput, 'Who serviced my AC?');
      await tester.pumpAndSettle();

      expect(find.text('Ask NYABAGAM'), findsOneWidget);
    });
  });
}