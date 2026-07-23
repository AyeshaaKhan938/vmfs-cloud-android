import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vmfs_colors.dart';

class RegistrationPendingScreen extends StatelessWidget {
  const RegistrationPendingScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration received')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 72, color: VmfsColors.primaryDark),
              const SizedBox(height: 24),
              const Text(
                'Pending admin approval',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We received your registration for $email.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Check your inbox — we sent a confirmation email. You will receive another email when an administrator approves your account. After that you can sign in to the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VmfsColors.textSecondary, height: 1.5),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
