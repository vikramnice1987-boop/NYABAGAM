import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/supabase/supabase_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnvironment.current.isSupabaseConfigured) {
    await SupabaseService.initialize(AppEnvironment.current);
  }
  runApp(const NyabagamApp());
}
