import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/config/app_environment.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';

class NyabagamApp extends StatelessWidget {
  const NyabagamApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'NYABAGAM',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    routerConfig: appRouter,
    builder: (context, child) => AppEnvironment.current.isSupabaseConfigured
        ? AuthGate(child: child ?? const SizedBox.shrink())
        : child ?? const SizedBox.shrink(),
  );
}
