import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_chip_bar.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/ny_elevation.dart';
import '../../../core/theme/ny_typography.dart';
import '../../auth/presentation/otp_verification_page.dart';
import '../../auth/presentation/auth_controller.dart';
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
  /// Re-runs OTP for the stored number.
  Future<void> _verifyPhone(String phone) async {
    if (phone.isEmpty) return;
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OtpVerificationPage(phoneE164: phone),
      ),
    );
    if (verified == null || !mounted) return;

    await UserProfileController.instance.updateProfile(isPhoneVerified: verified);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verified
              ? 'Phone verified.'
              : 'Code accepted locally, but the number stays unverified until a backend is connected.',
        ),
      ),
    );
  }

  /// Enabling alerts is meaningless without the OS permission, so ask for it
  /// at the moment the user opts in rather than failing silently later.
  Future<void> _onAlertsToggled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are blocked for NYABAGAM. Enable them in Android settings for reminders to arrive.',
            ),
          ),
        );
      }
      await NotificationService.instance.requestExactAlarmPermission();
    }

    await UserProfileController.instance
        .updateProfile(is2DayAlertsEnabled: enabled);

    if (!mounted) return;
    if (enabled && NotificationService.instance.usesInexactFallback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Exact alarms are off, so reminders may arrive a few minutes late.',
          ),
        ),
      );
    }
  }

  Future<void> _pickReminderTime(TimeOfDay current) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;

    final count = await UserProfileController.instance.updateProfile(
      reminderHour: picked.hour,
      reminderMinute: picked.minute,
    ).then((_) => UserProfileController.instance.rescheduleReminders());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'Reminder time saved. Nothing is scheduled yet - add a warranty date to a memory.'
              : 'Reminder time saved. $count reminder(s) rescheduled.',
        ),
      ),
    );
  }

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
            style: ElevatedButton.styleFrom(backgroundColor: NyColors.accentGradient[0], foregroundColor: Colors.white),
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

    return NyScaffold(
      title: 'Profile',
      padBottomForNav: true,
      body: ListenableBuilder(
        listenable: UserProfileController.instance,
        builder: (context, _) {
          final profile = UserProfileController.instance.profile;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: 12),
            children: [
              // 1. User Profile Header Card
              NyCard(
                level: NyGlassLevel.floating,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Initials avatar, falling back to the chosen icon
                        // before a name exists.
                        Container(
                          width: 62,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                profile.avatarColor.withValues(alpha: 0.34),
                                profile.avatarColor.withValues(alpha: 0.10),
                              ],
                            ),
                            border: Border.all(
                              color: profile.avatarColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: profile.initials.isEmpty
                              ? Icon(profile.avatarIcon, size: 28, color: profile.avatarColor)
                              : Text(
                                  profile.initials,
                                  style: NyTypography.headlineMedium.copyWith(
                                    color: profile.avatarColor,
                                  ),
                                ),
                        ),
                        const SizedBox(width: NySpacing.space14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.hasProfile ? profile.name : 'Set up your profile',
                                style: NyTypography.headlineSmall.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (profile.phone.isNotEmpty) ...[
                                const SizedBox(height: NySpacing.space4),
                                Text(
                                  profile.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NyTypography.numeric.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (profile.city.isNotEmpty) ...[
                                const SizedBox(height: NySpacing.space2),
                                Text(
                                  profile.city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NyTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: NySpacing.space8),
                              _VerificationChip(
                                verified: profile.isPhoneVerified,
                                hasPhone: profile.phone.isNotEmpty,
                                onVerify: () => _verifyPhone(profile.phone),
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
                            padding: const EdgeInsets.only(right: NySpacing.space8),
                            child: NyFilterPill(
                              label: lang['label']!,
                              selected: isSel,
                              onTap: () => UserProfileController.instance
                                  .updateProfile(preferredLanguage: lang['code']),
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
                      subtitle: const Text('Notifies you two days before a warranty or service date.', style: TextStyle(fontSize: 11)),
                      value: profile.is2DayAlertsEnabled,
                      activeTrackColor: NyColors.accentGradient[0],
                      onChanged: _onAlertsToggled,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: profile.is2DayAlertsEnabled,
                      leading: Icon(
                        Icons.schedule_rounded,
                        color: profile.is2DayAlertsEnabled
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Reminder time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text(
                        'Alerts arrive at ${profile.reminderTime.format(context)}.',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        profile.reminderTime.format(context),
                        style: NyTypography.numeric.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      onTap: profile.is2DayAlertsEnabled
                          ? () => _pickReminderTime(profile.reminderTime)
                          : null,
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
                      leading: const Icon(Icons.logout_rounded, color: NyColors.accentLight),
                      title: const Text('Sign Out / Switch Gmail Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Sign out and return to the Gmail Sign-In / OTP screen.', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        await AuthController.instance.signOut();
                        if (context.mounted) {
                          context.go('/sign-in');
                        }
                      },
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
/// Shows whether the stored number has actually been proven.
///
/// The offline dev OTP flow never sets verified, so this deliberately reads
/// "Not verified" rather than implying a security guarantee that does not exist.
class _VerificationChip extends StatelessWidget {
  const _VerificationChip({
    required this.verified,
    required this.hasPhone,
    required this.onVerify,
  });

  final bool verified;
  final bool hasPhone;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    if (!hasPhone) return const SizedBox.shrink();

    final color = verified ? NyColors.statusSuccess : NyColors.statusWarning;

    return GestureDetector(
      onTap: verified ? null : onVerify,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NySpacing.space10,
          vertical: NySpacing.space4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: NyRadius.borderPill,
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verified ? Icons.verified_rounded : Icons.error_outline_rounded,
              size: 13,
              color: color,
            ),
            const SizedBox(width: NySpacing.space6),
            Text(
              verified ? 'Verified' : 'Not verified - tap to verify',
              style: NyTypography.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
