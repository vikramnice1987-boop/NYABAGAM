import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/capture/presentation/capture_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';

void main() {
  group('CapturePage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders CapturePage with 3 tabs and input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const CapturePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Capture Memory'), findsOneWidget);
      expect(find.text('Text Note'), findsOneWidget);
      expect(find.text('Voice Note'), findsOneWidget);
      expect(find.text('Scan / Photo'), findsOneWidget);
      expect(find.text('Review Memory Candidate'), findsOneWidget);
    });

    testWidgets('switches to Voice Note tab and shows language selector', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const CapturePage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voice Note'));
      await tester.pumpAndSettle();

      expect(find.text('Speech Language:'), findsOneWidget);
      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('switches to Scan / Photo tab and shows camera and upload buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const CapturePage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan / Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload File'), findsOneWidget);
    });
  });
}