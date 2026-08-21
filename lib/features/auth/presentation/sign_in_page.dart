import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../shared/components/ny_button.dart';
import 'auth_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = AuthController.instance;
  bool _showOtpInput = false;

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
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMagicLink() async {
    final success = await _auth.sendMagicLink(_emailController.text);
    if (success && mounted) {
      setState(() => _showOtpInput = true);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final success = await _auth.verifyOtp(
      email: _emailController.text,
      token: _otpController.text,
    );
    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: NySpacing.space24, vertical: NySpacing.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo & Header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: NyColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: NyColors.primaryLight.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bubble_chart_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: NySpacing.space20),
                  Text(
                    'NYABAGAM',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your private, trustworthy personal memory companion.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: NySpacing.space32),

                  // Error Banner
                  if (_auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NyColors.statusError.withAlpha(20),
                        borderRadius: NyRadius.borderMd,
                        border: Border.all(color: NyColors.statusError.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: NyColors.statusError, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _auth.errorMessage!,
                              style: const TextStyle(fontSize: 12, color: NyColors.statusError, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NySpacing.space16),
                  ],

                  // Success Magic Link Notification Banner
                  if (_auth.isMagicLinkSent) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NyColors.statusSuccess.withAlpha(20),
                        borderRadius: NyRadius.borderMd,
                        border: Border.all(color: NyColors.statusSuccess.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_read_rounded, color: NyColors.statusSuccess, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign-in link dispatched!',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NyColors.statusSuccess),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Check ${_emailController.text.trim()} to confirm your session or enter code below.',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(180)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NySpacing.space20),
                  ],

                  // Email Input Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_auth.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    onSubmitted: (_) => _handleSendMagicLink(),
                  ),
                  const SizedBox(height: NySpacing.space16),

                  // Send Magic Link Button
                  NyButton(
                    label: _auth.isMagicLinkSent ? 'Resend Magic Link' : 'Continue with Email',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _auth.isLoading && !_showOtpInput,
                    onPressed: _auth.isLoading ? null : _handleSendMagicLink,
                  ),

                  // Optional 6-digit verification code input
                  if (_showOtpInput || _auth.isMagicLinkSent) ...[
                    const SizedBox(height: NySpacing.space24),
                    const Divider(),
                    const SizedBox(height: NySpacing.space16),
                    Text(
                      'Or enter 6-digit confirmation code:',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: '------',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    NyButton(
                      label: 'Verify & Enter NYABAGAM',
                      variant: NyButtonVariant.secondary,
                      isLoading: _auth.isLoading && _showOtpInput,
                      onPressed: _auth.isLoading ? null : _handleVerifyOtp,
                    ),
                  ],

                  const SizedBox(height: NySpacing.space32),
                  // Privacy & Security note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: theme.colorScheme.onSurface.withAlpha(120)),
                      const SizedBox(width: 6),
                      Text(
                        'Zero-knowledge personal memory architecture',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(120)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}