import 'package:flutter/material.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfigured = AppEnvironment.current.isSupabaseConfigured;
    final user = isConfigured ? SupabaseService.client.auth.currentUser : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NySpacing.space20),
        children: [
          NyCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.person, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email ?? 'Local User (Offline Mode)',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConfigured ? 'Secured by Supabase RLS' : 'In-Memory Development Mode',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          Text('Appearance & Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          NyCard(
            child: ListenableBuilder(
              listenable: ThemeController.instance,
              builder: (context, _) {
                final currentMode = ThemeController.instance.themeMode;
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark Mode (Default)'),
                      secondary: const Icon(Icons.dark_mode),
                      value: ThemeMode.dark,
                      groupValue: currentMode,
                      onChanged: (mode) => ThemeController.instance.setThemeMode(mode!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light Mode'),
                      secondary: const Icon(Icons.light_mode),
                      value: ThemeMode.light,
                      groupValue: currentMode,
                      onChanged: (mode) => ThemeController.instance.setThemeMode(mode!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('System Default'),
                      secondary: const Icon(Icons.settings_brightness),
                      value: ThemeMode.system,
                      groupValue: currentMode,
                      onChanged: (mode) => ThemeController.instance.setThemeMode(mode!),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          Text('Privacy & Data Controls', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          NyCard(
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline),
                  title: Text('Zero-Data Model Retention'),
                  subtitle: Text('OpenAI calls run with store: false. AI keys never enter the app.'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export My Memories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memory export prepared.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          if (user != null)
            NyButton(
              label: 'Sign Out',
              variant: NyButtonVariant.destructive,
              icon: Icons.logout,
              onPressed: () async {
                await SupabaseService.client.auth.signOut();
              },
            ),
        ],
      ),
    );
  }
}