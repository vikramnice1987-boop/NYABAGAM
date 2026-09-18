import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_elevation.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../profile/presentation/user_profile_controller.dart';
import 'auth_controller.dart';
import 'otp_verification_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _auth = AuthController.instance;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _localError = null);
    final success = await _auth.signInWithGoogle();
    if (success && mounted) {
      final email = _auth.currentEmail ?? 'user@gmail.com';
      await UserProfileController.instance.updateProfile(
        email: email,
        name: _auth.currentUser?.displayName ?? email.split('@').first,
      );
      await UserProfileController.instance.completeOnboarding();
      if (mounted) context.go('/');
    }
  }

  void _proceedToGmailOtp() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _localError = 'Please enter a valid Gmail address.');
      return;
    }

    setState(() => _localError = null);
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => OtpVerificationPage(destination: email),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    await _auth.setGuestSession();
    await UserProfileController.instance.completeOnboarding();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedError = _localError ?? _auth.errorMessage;

    return NyScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: NySpacing.space24,
            vertical: NySpacing.space32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: NyColors.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: NyColors.primaryLight.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: NySpacing.space20),
                Text(
                  'NYABAGAM',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Context-First Long-Term Personal Memory Companion',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: NySpacing.space32),

                if (displayedError != null) ...<Widget>[
                  _MessageBanner(
                    icon: Icons.error_outline_rounded,
                    color: NyColors.statusError,
                    message: displayedError,
                  ),
                  const SizedBox(height: NySpacing.space16),
                ],

                // 1. Continue with Google
                NyButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  isLoading: _auth.isLoading,
                  onPressed: _auth.isLoading ? null : _continueWithGoogle,
                ),
                const SizedBox(height: NySpacing.space20),

                // Divider
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or sign in with Gmail OTP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: NySpacing.space20),

                // 2. Gmail OTP Input Field
                NyCard(
                  level: NyGlassLevel.sunken,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR GMAIL ADDRESS',
                        style: NyTypography.overline.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: NySpacing.space8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enabled: !_auth.isLoading,
                        decoration: const InputDecoration(
                          hintText: 'e.g. alex@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        onSubmitted: (_) => _proceedToGmailOtp(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NySpacing.space16),

                // Get OTP Button
                NyButton(
                  label: 'Get 6-Digit OTP',
                  icon: Icons.mark_email_read_outlined,
                  variant: NyButtonVariant.secondary,
                  isLoading: _auth.isLoading,
                  onPressed: _auth.isLoading ? null : _proceedToGmailOtp,
                ),

                const SizedBox(height: NySpacing.space24),

                // 3. Guest / Demo Mode
                Center(
                  child: TextButton.icon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Explore as Guest (Offline Demo)'),
                  ),
                ),

                const SizedBox(height: NySpacing.space24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Your memories are private and scoped to your Gmail',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space12,
        vertical: NySpacing.space10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: NyRadius.borderMd,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: NySpacing.space8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}