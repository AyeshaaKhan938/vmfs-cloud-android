import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/legal/legal_content.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_brand_panel.dart';
import '../legal/legal_document_screen.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    final result = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

    if (!mounted || result == null) {
      return;
    }

    context.go('/register/pending', extra: result.email);
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VmfsLoginBrandPanel(),
                  const SizedBox(height: 16),
                  const Text(
                    'Register as a VMFS Cloud customer. An administrator will review your account before you can sign in.',
                    style: TextStyle(color: VmfsColors.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password required';
                            if (v.length < 8) return 'Use at least 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirm your password';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
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
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
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
