import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/supabase/supabase_service.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/profile/presentation/user_profile_controller.dart';
import 'shared/components/ny_glass.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureGlassQuality();
  await UserProfileController.instance.init();
  if (AppEnvironment.current.isSupabaseConfigured) {
    await SupabaseService.initialize(AppEnvironment.current);
  }
  await AuthController.instance.init();
  runApp(const NyabagamApp());
}

/// `BackdropFilter` is the one genuinely expensive part of the glass system.
///
/// It stays on everywhere, including web, because the cost is bounded by
/// design: blur is confined to the single [NyGlass] primitive, layers are
/// never nested, and dense list rows opt out via `blur: false`. Flipping this
/// to false is the escape hatch for a low-end device — the gradient fills,
/// luminous edges and specular highlights all still render without it, so
/// surfaces degrade to flat translucency rather than breaking.
void _configureGlassQuality() {
  NyGlass.blurEnabled = true;
}
