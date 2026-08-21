import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  var _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await SupabaseService.client.auth.signInWithOtp(email: email);
      if (mounted) {
        setState(
          () => _message = 'Check your email for a secure sign-in link.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('NYABAGAM', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            const Text('Your memories stay tied to your account.'),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _sendMagicLink,
              child: Text(
                _isSubmitting ? 'Sending...' : 'Email me a sign-in link',
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    ),
  );
}
