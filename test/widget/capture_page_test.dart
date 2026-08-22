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

      expect(find.text('Capture memory'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
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

      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();

      expect(find.text('SPEECH LANGUAGE'), findsOneWidget);
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

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });
  });
}