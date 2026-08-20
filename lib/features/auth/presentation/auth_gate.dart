import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.child, super.key});
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Session? _session;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    final auth = SupabaseService.client.auth;
    _session = auth.currentSession;
    _subscription = auth.onAuthStateChange.listen((state) {
      if (mounted) setState(() => _session = state.session);
    }, onError: (_, _) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _session == null ? const SignInPage() : widget.child;
}
