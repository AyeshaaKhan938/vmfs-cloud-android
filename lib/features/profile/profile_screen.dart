import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../auth/auth_provider.dart';
import '../../core/widgets/vmfs_interactive.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _notificationEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      _nameController.text = user?.name ?? '';
      _timezoneController.text = user?.timezone ?? 'UTC';
      _notificationEmailController.text = user?.cloudNotificationEmail ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _timezoneController.dispose();
    _notificationEmailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final notificationEmail = _notificationEmailController.text.trim();
      await ref.read(repositoryProvider).updateProfile(
            name: _nameController.text.trim(),
            timezone: _timezoneController.text.trim(),
            cloudNotificationEmail: notificationEmail.isEmpty ? null : notificationEmail,
            clearCloudNotificationEmail: notificationEmail.isEmpty,
          );
      await ref.read(authProvider.notifier).refreshSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).updatePassword(
            currentPassword: _currentPasswordController.text,
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmController.text,
          );
      _currentPasswordController.clear();
      _passwordController.clear();
      _passwordConfirmController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Email'),
            subtitle: Text(user?.email ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: _timezoneController, decoration: const InputDecoration(labelText: 'Timezone')),
          const SizedBox(height: 24),
          const Text(
            'Cloud notification email',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional. Send support alerts here — new tickets, live chat requests, ticket replies, and resolved tickets. Leave blank to use your sign-in email (${user?.email ?? ''}).',
            style: TextStyle(color: VmfsColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notificationEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Preferred notification email',
              hintText: 'alerts@yourcompany.com',
            ),
          ),
          if ((user?.preferredNotificationEmail ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Currently sending to: ${user!.preferredNotificationEmail}',
              style: TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          VmfsFilledButton(onPressed: _loading ? null : _saveProfile, child: const Text('Save profile')),
          const Divider(height: 32),
          const Text('Change password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
          ),
          const SizedBox(height: 16),
          VmfsOutlinedButton(onPressed: _loading ? null : _savePassword, child: const Text('Update password')),
        ],
      ),
    );
  }
}
