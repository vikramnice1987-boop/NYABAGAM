import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/components/ny_card.dart';
import '../presentation/user_profile_controller.dart';

class AvatarOption {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  const AvatarOption(this.id, this.icon, this.label, this.color);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const List<AvatarOption> _avatars = [
    AvatarOption('user', Icons.person_rounded, 'User', NyColors.accentLight),
    AvatarOption('tech', Icons.engineering_rounded, 'Tech', NyColors.entityPerson),
    AvatarOption('bolt', Icons.bolt_rounded, 'Pro', NyColors.entityThing),
    AvatarOption('star', Icons.star_rounded, 'Star', NyColors.statusSuccess),
    AvatarOption('shield', Icons.shield_rounded, 'Shield', NyColors.statusError),
    AvatarOption('badge', Icons.workspace_premium_rounded, 'Elite', Colors.purple),
  ];

  final List<Map<String, String>> _languages = const [
    {'code': 'en-IN', 'label': 'English'},
    {'code': 'ta-IN', 'label': 'Tamil'},
    {'code': 'hi-IN', 'label': 'Hindi'},
    {'code': 'te-IN', 'label': 'Telugu'},
  ];

  @override
  void initState() {
    super.initState();
    UserProfileController.instance.init();
  }

  void _showEditProfileDialog(BuildContext context) {
    final profile = UserProfileController.instance.profile;
    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final emailCtrl = TextEditingController(text: profile.email);
    final cityCtrl = TextEditingController(text: profile.city);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              const Text('WhatsApp Phone:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Email Address:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              const Text('City / Location:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: cityCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NyColors.accentLight, foregroundColor: Colors.white),
            onPressed: () async {
              await UserProfileController.instance.updateProfile(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                city: cityCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportMemories() async {
    final messenger = ScaffoldMessenger.of(context);
    final jsonString = await UserProfileController.instance.exportMemoriesJson();
    await Clipboard.setData(ClipboardData(text: jsonString));
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Success: Memories and profile exported to clipboard as JSON backup!'),
        backgroundColor: NyColors.statusSuccess,
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Local Data?', style: TextStyle(fontWeight: FontWeight.w800, color: NyColors.statusError)),
        content: const Text('This will clear your local stored memories and restart the onboarding flow. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NyColors.statusError, foregroundColor: Colors.white),
            onPressed: () async {
              await UserProfileController.instance.clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ctx.go('/onboarding');
              }
            },
            child: const Text('Reset & Restart', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: UserProfileController.instance,
        builder: (context, _) {
          final profile = UserProfileController.instance.profile;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: 12),
            children: [
              // 1. User Profile Header Card
              NyCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: profile.avatarColor.withAlpha(35),
                            shape: BoxShape.circle,
                            border: Border.all(color: profile.avatarColor.withAlpha(120), width: 2),
                          ),
                          child: Icon(profile.avatarIcon, size: 32, color: profile.avatarColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      profile.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: NyColors.statusSuccess.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Active', style: TextStyle(fontSize: 10, color: NyColors.statusSuccess, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile.phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(180), fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${profile.city} | ${profile.email}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(140)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Avatar Quick Selection Bar
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 8,
                      runSpacing: 8,
                      children: _avatars.map((av) {
                        final isSel = profile.avatarId == av.id;
                        return InkWell(
                          onTap: () => UserProfileController.instance.updateProfile(avatarId: av.id),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? av.color.withAlpha(45) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? av.color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(av.icon, size: 20, color: isSel ? av.color : theme.colorScheme.onSurface.withAlpha(150)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () => _showEditProfileDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // 2. Speech & Language Preferences
              Text('Speech & Language Preferences', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              NyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.language_rounded, size: 18, color: NyColors.accentLight),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Default Speech Language',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Preferred language for voice capture deduplication and query processing.',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(150)),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _languages.map((lang) {
                          final isSel = profile.preferredLanguage == lang['code'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => UserProfileController.instance.updateProfile(preferredLanguage: lang['code']),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? NyColors.accentLight : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSel ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                                    width: isSel ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  lang['label']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? Colors.white : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // 3. Proactive Reminders & WhatsApp Controls
              Text('Machine Reminders & WhatsApp Actions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              NyCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.alarm_on_rounded, color: NyColors.statusError),
                      title: const Text('2-Day Early Warranty Alerts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Proactively show alerts before machine warranties expire.', style: TextStyle(fontSize: 11)),
                      value: profile.is2DayAlertsEnabled,
                      activeTrackColor: NyColors.accentLight,
                      onChanged: (val) => UserProfileController.instance.updateProfile(is2DayAlertsEnabled: val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.chat_rounded, color: NyColors.statusSuccess),
                      title: const Text('WhatsApp 1-Tap Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Pre-fill technician service chats with historical context.', style: TextStyle(fontSize: 11)),
                      value: profile.isWhatsAppEnabled,
                      activeTrackColor: NyColors.statusSuccess,
                      onChanged: (val) => UserProfileController.instance.updateProfile(isWhatsAppEnabled: val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // 4. Appearance & Theme Settings
              Text('Appearance & Theme', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              NyCard(
                child: ListenableBuilder(
                  listenable: ThemeController.instance,
                  builder: (context, _) {
                    final currentMode = ThemeController.instance.themeMode;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Display Theme Mode:',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: SegmentedButton<ThemeMode>(
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                              ),
                              segments: const [
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.dark,
                                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                                  label: Text('Dark', style: TextStyle(fontSize: 12)),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.light,
                                  icon: Icon(Icons.light_mode_outlined, size: 16),
                                  label: Text('Light', style: TextStyle(fontSize: 12)),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.system,
                                  icon: Icon(Icons.settings_brightness_outlined, size: 16),
                                  label: Text('System', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                              selected: {currentMode},
                              onSelectionChanged: (Set<ThemeMode> newSelection) {
                                ThemeController.instance.setThemeMode(newSelection.first);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // 5. Privacy & Data Controls
              Text('Privacy & Data Management', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              NyCard(
                child: Column(
                  children: [
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline, color: NyColors.accentLight),
                      title: Text('Zero-Data Model Retention', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('Your memories are stored locally. AI entity extraction never trains on personal data.', style: TextStyle(fontSize: 11)),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download_rounded, color: NyColors.statusSuccess),
                      title: const Text('Export All Memories (JSON)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Copy full JSON backup of memories, warranties & profile.', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.copy_rounded, size: 18),
                      onTap: _exportMemories,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_forever_rounded, color: NyColors.statusError),
                      title: const Text('Reset All Local Data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NyColors.statusError)),
                      subtitle: const Text('Clear local memory database and restart setup.', style: TextStyle(fontSize: 11)),
                      onTap: () => _showResetConfirmDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NySpacing.space20),

              // 6. Onboarding Replay & Version Info
              NyCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.help_outline_rounded, color: NyColors.accentLight),
                      title: const Text('Replay Onboarding Guide', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('View the 4-step walkthrough and value guide.', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => context.push('/onboarding'),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'NYABAGAM - Version 1.2.0 (Production Release)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}