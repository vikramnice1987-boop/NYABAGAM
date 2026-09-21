import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ny_colors.dart';
import '../../../core/theme/ny_elevation.dart';
import '../../../core/theme/ny_radius.dart';
import '../../../core/theme/ny_spacing.dart';
import '../../../core/theme/ny_typography.dart';
import '../../../shared/components/ny_button.dart';
import '../../../shared/components/ny_card.dart';
import '../../../shared/components/ny_empty_state.dart';
import '../../../shared/components/ny_scaffold.dart';
import '../../profile/presentation/user_profile_controller.dart';
import '../data/phone_auth_service.dart';
import 'auth_controller.dart';

/// Six-digit verification for Gmail OTP or Phone.
class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    this.destination,
    this.phoneE164,
    this.isEmail,
    super.key,
  });

  /// Compatibility constructor for phone verification.
  const OtpVerificationPage.phone({
    required String phoneE164,
    super.key,
  }) : destination = phoneE164,
       phoneE164 = phoneE164,
       isEmail = false;

  final String? destination;
  final String? phoneE164;
  final bool? isEmail;

  String get targetDestination => destination ?? phoneE164 ?? '';

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _phoneService = PhoneAuthService.current;
  final _auth = AuthController.instance;

  String get _destination => widget.targetDestination;
  bool get _isEmail => widget.isEmail ?? _destination.contains('@');

  bool _sending = false;
  bool _verifying = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    OtpResult res;
    if (_isEmail) {
      res = await _auth.sendGmailOtp(_destination);
    } else {
      res = await _phoneService.sendCode(_destination);
    }

    if (!mounted) return;

    setState(() {
      _sending = false;
      _error = res.success ? null : res.message;
    });

    if (res.success) {
      _startResendCountdown();
      _focus.requestFocus();
    }
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    OtpResult res;
    if (_isEmail) {
      res = await _auth.verifyGmailOtp(
        email: _destination,
        otp: code,
      );
    } else {
      res = await _phoneService.verifyCode(_destination, code);
    }

    if (!mounted) return;
    setState(() => _verifying = false);

    if (!res.success) {
      setState(() => _error = res.message ?? 'That code did not work.');
      return;
    }

    if (_isEmail) {
      final profile = UserProfileController.instance;
      final existingName = profile.profile.name;
      final derivedName = existingName.isNotEmpty && existingName != 'Vikram'
          ? existingName
          : _destination.split('@').first;
      await profile.updateProfile(
        name: derivedName,
        email: _destination,
        isEmailVerified: true,
      );
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/');
      }
    } else {
      Navigator.of(context).pop(res.verified);
    }
  }

  Future<void> _verifyWithGoogle() async {
    setState(() {
      _verifying = true;
      _error = null;
    });

    final success = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _verifying = false);

    if (success) {
      final user = _auth.currentUser;
      final profile = UserProfileController.instance;
      final email = user?.email ?? _destination;
      final name = user?.displayName ?? email.split('@').first;

      await profile.updateProfile(
        name: name,
        email: email,
        isEmailVerified: true,
      );

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/');
      }
    } else {
      setState(() {
        _error = _auth.errorMessage ?? 'Google verification was cancelled or failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NyScaffold(
      title: _isEmail ? 'Verify Gmail OTP' : 'Verify number',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          NySpacing.gutter,
          NySpacing.space8,
          NySpacing.gutter,
          NySpacing.space32,
        ),
        children: <Widget>[
          NyReveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: NyMedallion(
                    icon: _isEmail ? Icons.mark_email_read_rounded : Icons.sms_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: NySpacing.space24),
                Text(
                  'Enter 6-digit code',
                  style: NyTypography.displaySmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: NySpacing.space8),
                Text(
                  _isEmail
                      ? 'We sent a 6-digit verification code to $_destination. Please check your inbox and spam folder.'
                      : 'We sent a 6-digit code to $_destination.',
                  style: NyTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          NyCard(
            level: NyGlassLevel.floating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'VERIFICATION CODE',
                  style: NyTypography.overline.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: NySpacing.space10),
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  autofillHints: const <String>[AutofillHints.oneTimeCode],
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: NyTypography.displaySmall.copyWith(
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 12,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (val) {
                    if (_error != null) setState(() => _error = null);
                    if (val.trim().length == 6) _verify();
                  },
                  onSubmitted: (_) => _verify(),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '------',
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: NySpacing.space10),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: NyColors.statusError,
                      ),
                      const SizedBox(width: NySpacing.space6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: NyTypography.bodySmall.copyWith(
                            color: NyColors.statusError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space20),

          NyButton(
            label: 'Verify & Sign In',
            icon: Icons.check_rounded,
            isLoading: _verifying,
            onPressed: _verifying ? null : _verify,
          ),
          const SizedBox(height: NySpacing.space12),
          NyButton(
            label: _resendIn > 0 ? 'Resend code in ${_resendIn}s' : 'Resend code',
            variant: NyButtonVariant.outline,
            isLoading: _sending,
            onPressed: (_resendIn > 0 || _sending) ? null : _send,
          ),
          if (_isEmail) ...[
            const SizedBox(height: NySpacing.space20),
            Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outline.withAlpha(50))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outline.withAlpha(50))),
              ],
            ),
            const SizedBox(height: NySpacing.space16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
                side: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
              ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: NyColors.accentLight),
              label: const Text('Verify with Google (1-Tap)', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _verifying ? null : _verifyWithGoogle,
            ),
          ],
        ],
      ),
    );
  }
}