import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/ny_motion.dart';
import '../../auth/data/phone_number.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/otp_verification_page.dart';
import '../../profile/presentation/user_profile_controller.dart';

class AvatarOption {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  const AvatarOption(this.id, this.icon, this.label, this.color);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedLanguage = 'en-IN';
  String _selectedAvatarId = 'user';
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final authEmail = AuthController.instance.currentEmail;
    if (authEmail != null && authEmail.isNotEmpty && !authEmail.startsWith('guest@')) {
      _emailController.text = authEmail;
      if (_nameController.text.isEmpty) {
        _nameController.text = authEmail.split('@').first;
      }
    }
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
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final isEmailValid = email.contains('@') && email.contains('.');
    final phone = _phoneController.text.trim().isEmpty
        ? ''
        : PhoneNumber.normalise(_phoneController.text);

    setState(() {
      _nameError = name.isEmpty ? 'Enter your name' : null;
      _emailError = !isEmailValid ? 'Enter a valid Gmail address' : null;
      _phoneError = (_phoneController.text.trim().isNotEmpty && phone == null)
          ? 'Enter a valid mobile number'
          : null;
    });
    return _nameError == null && _emailError == null && _phoneError == null;
  }

  Future<void> _verifyWithGoogleInOnboarding() async {
    setState(() => _saving = true);
    final success = await AuthController.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      final user = AuthController.instance.currentUser;
      final email = user?.email ?? '';
      final displayName = user?.displayName ?? (email.isNotEmpty ? email.split('@').first : '');
      if (email.isNotEmpty) {
        setState(() {
          _emailController.text = email;
          if (_nameController.text.isEmpty && displayName.isNotEmpty) {
            _nameController.text = displayName;
          }
          _emailError = null;
        });
      }
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_validate()) {
      _pageController.animateToPage(
        3,
        duration: NyMotion.normal,
        curve: NyMotion.settle,
      );
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim().isEmpty
        ? ''
        : (PhoneNumber.normalise(_phoneController.text) ?? _phoneController.text.trim());

    setState(() => _saving = true);

    // If user is already authenticated with this email via Google/OTP, skip verification screen
    final isAlreadyVerified = AuthController.instance.isAuthenticated &&
        AuthController.instance.currentEmail?.toLowerCase() == email;

    bool verified = isAlreadyVerified;
    if (!isAlreadyVerified) {
      final res = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => OtpVerificationPage(
            destination: email,
            isEmail: true,
          ),
        ),
      );
      if (!mounted) return;
      if (res == null) {
        setState(() => _saving = false);
        return;
      }
      verified = res;
    }

    await UserProfileController.instance.completeOnboarding(
      name: _nameController.text.trim(),
      email: email,
      phone: phone,
      city: _cityController.text.trim(),
      preferredLanguage: _selectedLanguage,
      avatarId: _selectedAvatarId,
      isEmailVerified: verified,
      isPhoneVerified: false,
    );

    // Ask for notification access now
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.requestExactAlarmPermission();
    await UserProfileController.instance.rescheduleReminders();

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NyScaffold(
      body: Column(
          children: [
            // Top Skip / Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: NyColors.accentLight.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: NyColors.accentLight, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'NYABAGAM',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  if (_currentPage < 3)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        _pageController.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Skip to Setup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                ],
              ),
            ),

            // Page View with 4 Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomeSlide(theme),
                  _buildVoiceScanSlide(theme),
                  _buildRemindersSlide(theme),
                  _buildProfileSetupSlide(theme),
                ],
              ),
            ),

            // Bottom Navigation Indicators & Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isCurrent = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isCurrent ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isCurrent ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  if (_currentPage < 3)
                    NyButton(
                      label: 'Next Step',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                    )
                  else
                    NyButton(
                      label: 'Verify Gmail & Complete Setup',
                      icon: Icons.check_circle_rounded,
                      isLoading: _saving,
                      onPressed: _saving ? null : _completeOnboarding,
                    ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildWelcomeSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NyColors.accentLight.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: NyColors.accentLight.withAlpha(80)),
            ),
            child: const Icon(Icons.psychology_rounded, size: 72, color: NyColors.accentLight),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to NYABAGAM',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal AI memory loop with instant context.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: NyColors.accentLight,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Never forget a service date, warranty period, doctor visit, or technician contact again. NYABAGAM listens, understands in Tamil & English, and connects your past facts to future needs.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, color: theme.colorScheme.onSurface.withAlpha(180)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeaturePill(Icons.mic_rounded, 'Voice Capture'),
              _buildFeaturePill(Icons.shield_rounded, '2-Day Alerts'),
              _buildFeaturePill(Icons.chat_rounded, 'WhatsApp Ready'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceScanSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NyColors.entityPerson.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: NyColors.entityPerson.withAlpha(80)),
            ),
            child: const Icon(Icons.record_voice_over_rounded, size: 72, color: NyColors.entityPerson),
          ),
          const SizedBox(height: 24),
          Text(
            'Multi-Language Voice & Scan',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Speak naturally in Tamil or English.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: NyColors.entityPerson,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Simply say "Ravi serviced my AC today for Rs. 800 and gave 6-month warranty" or upload a photo of your receipt. AI automatically structures the people, costs, and dates.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, color: theme.colorScheme.onSurface.withAlpha(180)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          NyCard(
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: NyColors.accentLight, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Built-in Deduplication', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('Clean, multi-phrase deduplicated speech recognition on mobile and web.', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NyColors.statusError.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: NyColors.statusError.withAlpha(80)),
            ),
            child: const Icon(Icons.notification_important_rounded, size: 72, color: NyColors.statusError),
          ),
          const SizedBox(height: 24),
          Text(
            'Proactive 2-Day Early Alerts',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Never miss a machine warranty lapse.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: NyColors.statusError,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Track ACs, Washing Machines, Cars, Laptops, RO Water Purifiers, and Batteries. NYABAGAM sends a 2-day early reminder with a 1-tap WhatsApp technician dispatch button.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, color: theme.colorScheme.onSurface.withAlpha(180)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NyColors.statusError.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NyColors.statusError.withAlpha(100)),
            ),
            child: Row(
              children: const [
                Icon(Icons.alarm_on_rounded, color: NyColors.statusError, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Alert: Machine warranty expires in 2 days. 1-tap WhatsApp message to technician ready.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetupSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Profile',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Personalize your NYABAGAM experience. Your details stay private and local.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: 14),

          // 1-Tap Google Verify Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
              side: BorderSide(color: NyColors.accentLight.withAlpha(120)),
              backgroundColor: NyColors.accentLight.withAlpha(15),
            ),
            icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: NyColors.accentLight),
            label: const Text('1-Tap Verify with Google', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            onPressed: _saving ? null : _verifyWithGoogleInOnboarding,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: Divider(color: theme.colorScheme.outline.withAlpha(50))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR ENTER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
              ),
              Expanded(child: Divider(color: theme.colorScheme.outline.withAlpha(50))),
            ],
          ),
          const SizedBox(height: 12),

          // Choose Avatar
          const Text('Choose Your Avatar:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 10,
            runSpacing: 10,
            children: _avatars.map((av) {
              final isSel = _selectedAvatarId == av.id;
              return InkWell(
                onTap: () => setState(() => _selectedAvatarId = av.id),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSel ? av.color.withAlpha(50) : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? av.color : theme.colorScheme.outline.withAlpha(60),
                      width: isSel ? 2.5 : 1,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: av.color.withAlpha(60),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    av.icon,
                    size: 24,
                    color: isSel ? av.color : theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Name Input
          const Text('Full Name:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_rounded, size: 18),
              hintText: 'Your full name',
              errorText: _nameError,
              border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Gmail Address Input
          const Text('Gmail Address (Live OTP / Account):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_rounded, size: 18),
              hintText: 'yourname@gmail.com',
              helperText: 'We send a 6-digit OTP code to verify your profile in real time.',
              errorText: _emailError,
              border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Phone / WhatsApp Input (Optional)
          const Text('WhatsApp Phone Number (Optional):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
              hintText: '98400 12345',
              helperText: 'Used for 1-tap WhatsApp technician dispatch and alerts.',
              errorText: _phoneError,
              border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // City Input
          const Text('City / Location:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
              hintText: 'Your city (optional)',
              border: OutlineInputBorder(borderRadius: NyRadius.borderMd),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Preferred Language Selector
          const Text('Default Speech Language:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _languages.map((lang) {
                final isSel = _selectedLanguage == lang['code'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedLanguage = lang['code']!),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? NyColors.accentLight : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? NyColors.accentLight : theme.colorScheme.outline.withAlpha(80),
                        ),
                      ),
                      child: Text(
                        lang['label']!,
                        style: TextStyle(
                          fontSize: 11,
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
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NyColors.accentLight.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NyColors.accentLight.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NyColors.accentLight),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}