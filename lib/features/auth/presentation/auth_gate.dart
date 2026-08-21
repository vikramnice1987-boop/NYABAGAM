import 'package:flutter/material.dart';
import 'auth_controller.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.child, super.key});
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthController.instance;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.isSupabaseConfigured && !_auth.isAuthenticated) {
      return const SignInPage();
    }
    return widget.child;
  }
}