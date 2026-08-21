import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/supabase/supabase_service.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/profile/presentation/user_profile_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserProfileController.instance.init();
  if (AppEnvironment.current.isSupabaseConfigured) {
    await SupabaseService.initialize(AppEnvironment.current);
  }
  await AuthController.instance.init();
  runApp(const NyabagamApp());
}