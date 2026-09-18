import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_motion.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_aurora_background.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/user_profile_controller.dart';

/// First frame the user sees.
///
/// Does the small amount of startup work that must not block `main()` —
/// notification init and rebuilding scheduled alarms — then routes to
/// onboarding or home. The Android launch theme paints the same near-black, so
/// there is no white flash before this appears.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// Held so it can be cancelled on dispose. An uncancelled timer would keep
  /// the widget alive past teardown and fires after the tree is gone.
  Timer? _minDisplay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _minDisplay?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final controller = UserProfileController.instance;
    await controller.init();
    if (!mounted) return;

    if (controller.isOnboardingCompleted) {
      // Deliberately not awaited. Rebuilding alarms must never gate first
      // paint: if the notification plugin stalls — which it does on platforms
      // without an implementation — awaiting it strands the user on the splash
      // screen indefinitely.
      unawaited(_restoreReminders());
    }

    // Hold the brand frame briefly so the app does not appear to flicker on a
    // fast device. Long enough to read, short enough not to annoy.
    _minDisplay = Timer(const Duration(milliseconds: 900), _go);
  }

  /// Alarms do not survive reboot or reinstall, so they are rebuilt each launch.
  Future<void> _restoreReminders() async {
    try {
      await NotificationService.instance
          .init()
          .timeout(const Duration(seconds: 5));
      await UserProfileController.instance
          .rescheduleReminders()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Splash] reminder restore skipped: $e');
    }
  }

  void _go() {
    if (!mounted) return;
    final isAuth = AuthController.instance.isAuthenticated;
    final isDone = UserProfileController.instance.isOnboardingCompleted;

    if (isAuth && isDone) {
      context.go('/');
    } else if (isDone) {
      context.go('/');
    } else {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NyColors.wallpaperBaseDark,
      body: NyAuroraBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.86, end: 1),
                duration: NyMotion.slow,
                curve: NyMotion.spring,
                builder: (context, t, child) => Transform.scale(
                  scale: t,
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                ),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: NyColors.accentGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: NyRadius.borderXl,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: NyColors.accentGradient[1].withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: NySpacing.space28),
              Text(
                'NYABAGAM',
                style: NyTypography.displaySmall.copyWith(
                  color: NyColors.textPrimaryDark,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: NySpacing.space8),
              Text(
                'Your memory, with context.',
                style: NyTypography.bodyMedium.copyWith(
                  color: NyColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
