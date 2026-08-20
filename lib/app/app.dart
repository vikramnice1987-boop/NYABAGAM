import 'package:flutter/material.dart';
import '../core/router/app_router.dart';
import '../core/config/app_environment.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/presentation/auth_gate.dart';

class NyabagamApp extends StatelessWidget {
  const NyabagamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'NYABAGAM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          routerConfig: appRouter,
          builder: (context, child) => AppEnvironment.current.isSupabaseConfigured
              ? AuthGate(child: child ?? const SizedBox.shrink())
              : child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}