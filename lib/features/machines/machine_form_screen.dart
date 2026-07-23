import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/utils/debouncer.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../models/machine_onboarding_profile.dart';
import '../auth/auth_provider.dart';

class MachineFormScreen extends ConsumerStatefulWidget {
  const MachineFormScreen({super.key, this.machineId});

  final int? machineId;

  bool get isEditing => machineId != null;

  @override
  ConsumerState<MachineFormScreen> createState() => _MachineFormScreenState();
}

class _MachineFormScreenState extends ConsumerState<MachineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarksController = TextEditingController();
  final _profileDebouncer = Debouncer();
  bool _isEnabled = true;
  bool _ageVerification = false;
  int? _groupId;
  bool _loading = false;
  bool _initialized = false;
  bool _profileLoading = false;
  List<Map<String, dynamic>> _groups = const [];
  MachineOnboardingProfile? _detectedProfile;

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_onMachineNumberChanged);
    _loadLookups();
  }

  void _onMachineNumberChanged() {
    if (widget.isEditing) {
      return;
    }

    final number = _numberController.text.trim();
    if (number.length < 6) {
      setState(() => _detectedProfile = null);
      return;
    }

    setState(() => _profileLoading = true);
    _profileDebouncer.run(() async {
      try {
        final profile = await ref.read(repositoryProvider).fetchMachineOnboardingProfile(number);
        if (!mounted || _numberController.text.trim() != number) {
          return;
        }
        setState(() {
          _detectedProfile = profile;
          _profileLoading = false;
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _detectedProfile = null;
            _profileLoading = false;
          });
        }
      }
    });
  }

  Future<void> _loadLookups() async {
    final groups = await ref.read(repositoryProvider).fetchMachineGroups();
    if (!mounted) return;
    setState(() => _groups = groups);

    if (widget.machineId != null) {
      await _loadMachine();
    }
  }

  Future<void> _loadMachine() async {
    final machine = await ref.read(repositoryProvider).fetchMachine(widget.machineId!);
    if (!mounted) return;
    setState(() {
      _numberController.text = machine.machineNumber;
      _nameController.text = machine.machineName;
      _addressController.text = machine.address;
      _remarksController.text = machine.remarks ?? '';
      _isEnabled = machine.isEnabled;
      _ageVerification = machine.ageVerificationEnabled;
      _groupId = machine.machineGroupId;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _numberController.removeListener(_onMachineNumberChanged);
    _profileDebouncer.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      if (widget.isEditing) {
        await repo.updateMachine(
          id: widget.machineId!,
          machineNumber: _numberController.text.trim(),
          machineName: _nameController.text.trim(),
          detailedAddress: _addressController.text.trim(),
          machineGroupId: _groupId,
          isEnabled: _isEnabled,
          ageVerificationEnabled: _ageVerification,
          remarks: _remarksController.text.trim(),
        );
        if (mounted) context.pop(true);
      } else {
        final created = await repo.createMachine(
          machineNumber: _numberController.text.trim(),
          machineName: _nameController.text.trim(),
          detailedAddress: _addressController.text.trim(),
          machineGroupId: _groupId,
          isEnabled: _isEnabled,
          ageVerificationEnabled: _ageVerification,
          remarks: _remarksController.text.trim(),
        );
        if (mounted) {
          context.go('/machines/${created.id}?onboarding=1');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_initialized) {
      return const Scaffold(body: VmfsLoadingView());
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit machine' : 'Add machine')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!widget.isEditing) ...[
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Machine number *',
                  helperText: 'Enter the kiosk serial — guided setup depends on this number.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              if (_profileLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_detectedProfile != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: VmfsColors.primaryLight.withValues(alpha: 0.35),
                  child: ListTile(
                    leading: const Icon(Icons.memory_rounded, color: VmfsColors.primaryDark),
                    title: Text(
                      _detectedProfile!.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_detectedProfile!.description),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ] else ...[
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Machine number *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Machine name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _groupId,
              decoration: const InputDecoration(labelText: 'Machine group'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                for (final group in _groups)
                  DropdownMenuItem<int?>(
                    value: group['id'] as int,
                    child: Text(group['name']?.toString() ?? 'Group'),
                  ),
              ],
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              maxLines: 2,
            ),
            SwitchListTile(
              title: const Text('Enabled'),
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
            ),
            SwitchListTile(
              title: const Text('Age verification'),
              value: _ageVerification,
              onChanged: (v) => setState(() => _ageVerification = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Save changes' : 'Create machine'),
            ),
          ],
        ),
      ),
    );
  }
}
