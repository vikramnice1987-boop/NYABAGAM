import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/home/presentation/home_page.dart';
import 'package:nyabagam/features/capture/presentation/capture_page.dart';
import 'package:nyabagam/features/ask/presentation/ask_page.dart';
import 'package:nyabagam/features/reminders/presentation/reminders_page.dart';
import 'package:nyabagam/features/profile/presentation/profile_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';

void main() {
  group('Accessibility & Responsive Viewport Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    final viewports = <String, Size>{
      'Compact Mobile (360x640)': const Size(360, 640),
      'Standard Mobile (390x844)': const Size(390, 844),
      'Tablet Portrait (768x1024)': const Size(768, 1024),
      'Desktop / Web Wide (1440x900)': const Size(1440, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('renders HomePage cleanly on ${entry.key} without overflows', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('NYABAGAM'), findsOneWidget);
      });

      testWidgets('renders CapturePage cleanly on ${entry.key} without overflows', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const CapturePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Capture Memory'), findsOneWidget);
      });

      testWidgets('renders AskPage cleanly on ${entry.key} without overflows', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const AskPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Ask NYABAGAM'), findsOneWidget);
      });

      testWidgets('renders RemindersPage cleanly on ${entry.key} without overflows', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const RemindersPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Warranties & Reminders'), findsOneWidget);
      });

      testWidgets('renders ProfilePage cleanly on ${entry.key} without overflows', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProfilePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Profile & Settings'), findsOneWidget);
      });
    }
  });
}