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
  String? _devCode;
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
      _devCode = null;
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
      _devCode = res.devCode;
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
      );
      await profile.completeOnboarding();
      if (mounted) {
        context.go('/');
      }
    } else {
      Navigator.of(context).pop(res.verified);
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
                      ? 'We sent a 6-digit verification code to ${widget.destination}.'
                      : 'We sent a 6-digit code to ${widget.destination}.',
                  style: NyTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NySpacing.space24),

          if (_devCode != null) ...<Widget>[
            _DevCodeBanner(code: _devCode!),
            const SizedBox(height: NySpacing.space16),
          ],

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
        ],
      ),
    );
  }
}

/// Shown in test/dev flow so testers can immediately see the code to verify.
class _DevCodeBanner extends StatelessWidget {
  const _DevCodeBanner({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NySpacing.space16,
        vertical: NySpacing.space12,
      ),
      decoration: BoxDecoration(
        color: NyColors.statusWarning.withValues(alpha: 0.15),
        borderRadius: NyRadius.borderMd,
        border: Border.all(
          color: NyColors.statusWarning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.vpn_key_rounded,
            size: 20,
            color: NyColors.statusWarning,
          ),
          const SizedBox(width: NySpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Your 6-Digit OTP Code:',
                  style: NyTypography.labelSmall.copyWith(
                    color: NyColors.statusWarning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: NyTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}