import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/onboarding/presentation/onboarding_page.dart';
import 'package:nyabagam/features/profile/presentation/user_profile_controller.dart';

void main() {
  group('OnboardingPage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      UserProfileController.instance.init();
    });

    testWidgets('renders Welcome slide and navigates to profile setup', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to NYABAGAM'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.text('Skip to Setup'), findsOneWidget);

      // Tap Skip to Setup to jump to Slide 4 (Profile Setup)
      await tester.tap(find.text('Skip to Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Profile'), findsOneWidget);
      expect(find.text('Full Name:'), findsOneWidget);
      expect(find.text('WhatsApp Phone Number:'), findsOneWidget);
      expect(find.text('Complete Setup & Launch NYABAGAM'), findsOneWidget);
    });
  });
}