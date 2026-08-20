class AppEnvironment {
  const AppEnvironment._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.aiFunctionName,
  });
  static const current = AppEnvironment._(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    aiFunctionName: String.fromEnvironment(
      'AI_FUNCTION_NAME',
      defaultValue: 'ai-memory',
    ),
  );
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String aiFunctionName;
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
