// Stub auth screen — redirects immediately to main
import 'package:flutter/material.dart';
import 'package:wayfinder/presentation/screens/main_shell.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    });
    return const SizedBox.shrink();
  }
}
