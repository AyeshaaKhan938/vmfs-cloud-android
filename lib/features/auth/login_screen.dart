import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/legal/legal_content.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_brand_panel.dart';
import '../legal/help_screen.dart';
import '../legal/legal_document_screen.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Privacy Policy to continue.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((state) => state.isLoading));
    final error = ref.watch(authProvider.select((state) => state.error));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VmfsLoginBrandPanel(),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
                          ),
                        ],
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedTerms,
                      onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Wrap(
                        children: [
                          const Text('I agree to the '),
                          GestureDetector(
                            onTap: () => _openLegal('Terms & conditions', LegalContent.termsOfService),
                            child: const Text(
                              'Terms',
                              style: TextStyle(color: VmfsColors.primaryDark, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Text(' and '),
                          GestureDetector(
                            onTap: () => _openLegal('Privacy policy', LegalContent.privacyPolicy),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(color: VmfsColors.primaryDark, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error, style: const TextStyle(color: VmfsColors.danger)),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
                      ),
                      child: const Text('Help & support'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: isLoading ? null : () => context.go('/register'),
                      child: const Text('Create customer account'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'New customers register here. Accounts require admin approval before sign-in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: VmfsColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version ${AppConfig.appVersion}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: VmfsColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
