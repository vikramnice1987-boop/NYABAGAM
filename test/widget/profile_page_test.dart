import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyabagam/features/profile/presentation/profile_page.dart';
import 'package:nyabagam/core/theme/app_theme.dart';
import 'package:nyabagam/features/profile/presentation/user_profile_controller.dart';

void main() {
  group('ProfilePage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      UserProfileController.instance.init();
    });

    testWidgets('renders ProfilePage with user details, theme options, and privacy controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ProfilePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Speech & Language Preferences'), findsOneWidget);
      expect(find.text('2-Day Early Warranty Alerts'), findsOneWidget);
      expect(find.text('WhatsApp 1-Tap Assistant'), findsOneWidget);
      expect(find.text('Export All Memories (JSON)'), findsOneWidget);
    });
  });
}