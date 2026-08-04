import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../auth/auth_provider.dart';
import 'team_screen.dart';
import 'team_utils.dart';
import '../../core/widgets/vmfs_interactive.dart';

class TeamMemberFormScreen extends ConsumerStatefulWidget {
  const TeamMemberFormScreen({super.key, this.member});

  final Map<String, dynamic>? member;

  bool get isEditing => member != null;

  @override
  ConsumerState<TeamMemberFormScreen> createState() => _TeamMemberFormScreenState();
}

class _TeamMemberFormScreenState extends ConsumerState<TeamMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailsController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _timezoneController = TextEditingController();
  bool _isEnabled = true;
  bool _loading = false;
  final Set<String> _selectedFeatures = {};

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member != null) {
      _accountController.text = member['account'] as String? ?? '';
      _nameController.text = member['name'] as String? ?? '';
      _phoneController.text = member['phone'] as String? ?? '';
      _emailsController.text = member['email'] as String? ?? '';
      _timezoneController.text = member['timezone'] as String? ?? 'UTC';
      _isEnabled = member['is_enabled'] as bool? ?? true;
      _selectedFeatures.addAll(
        (member['features'] as List<dynamic>? ?? []).map((e) => e.toString()),
      );
    } else {
      _timezoneController.text = ref.read(authProvider).user?.timezone ?? 'UTC';
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailsController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'account': _accountController.text.trim(),
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'contact_emails': _emailsController.text.trim(),
      'timezone': _timezoneController.text.trim().isEmpty ? 'UTC' : _timezoneController.text.trim(),
      'is_enabled': _isEnabled,
      'feature_permissions': _selectedFeatures.toList(),
    };

    final password = _passwordController.text;
    if (!widget.isEditing || password.isNotEmpty) {
      payload['password'] = password;
      payload['password_confirmation'] = _passwordConfirmController.text;
    }

    return payload;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      final payload = _buildPayload();

      if (widget.isEditing) {
        await repo.updateTeamMember(widget.member!['id'] as int, payload);
      } else {
        await repo.createTeamMember(payload);
      }

      ref.invalidate(teamMembersProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove team member?'),
        content: Text(
          'This permanently removes ${_nameController.text.trim()} from your account.',
        ),
        actions: [
          VmfsTextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          VmfsFilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).deleteTeamMember(widget.member!['id'] as int);
      ref.invalidate(teamMembersProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleFeature(String key, bool selected) {
    setState(() {
      if (selected) {
        _selectedFeatures.add(key);
      } else {
        _selectedFeatures.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit team member' : 'Add team member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'Login account *',
                helperText: 'Used to sign in to VMFS Cloud.',
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name *'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone *'),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailsController,
              decoration: const InputDecoration(
                labelText: 'Contact email *',
                helperText: 'Primary email used for login and notifications.',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timezoneController,
              decoration: const InputDecoration(labelText: 'Timezone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: widget.isEditing ? 'New password' : 'Password *',
                helperText: widget.isEditing ? 'Leave blank to keep the current password.' : 'Minimum 8 characters.',
              ),
              obscureText: true,
              validator: (value) {
                if (!widget.isEditing && (value == null || value.length < 8)) {
                  return 'Password must be at least 8 characters';
                }
                if (widget.isEditing && value != null && value.isNotEmpty && value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordConfirmController,
              decoration: InputDecoration(
                labelText: widget.isEditing ? 'Confirm new password' : 'Confirm password *',
              ),
              obscureText: true,
              validator: (value) {
                final password = _passwordController.text;
                if (!widget.isEditing || password.isNotEmpty) {
                  if (value != password) {
                    return 'Passwords do not match';
                  }
                }
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Account enabled'),
              subtitle: const Text('Disabled members cannot sign in.'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 8),
            const Text(
              'Feature access',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose which parts of VMFS Cloud this person can use.',
              style: TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...teamFeatureOptions.map(
              (feature) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selectedFeatures.contains(feature.key),
                onChanged: (value) => _toggleFeature(feature.key, value ?? false),
                title: Text(feature.label),
                subtitle: Text(feature.description, style: const TextStyle(fontSize: 12)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 24),
            VmfsFilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(widget.isEditing ? 'Save changes' : 'Create team member'),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              VmfsOutlinedButton(
                onPressed: _loading ? null : _delete,
                child: const Text('Remove team member'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
