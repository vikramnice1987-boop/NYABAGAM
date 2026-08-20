import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_environment.dart';

abstract final class SupabaseService {
  static Future<void> initialize(AppEnvironment environment) =>
      Supabase.initialize(
        url: environment.supabaseUrl,
        publishableKey: environment.supabaseAnonKey,
      );
  static SupabaseClient get client => Supabase.instance.client;
}
