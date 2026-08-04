import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import '../../models/machine.dart';
import 'support_screen.dart';
import 'support_utils.dart';
import '../../core/widgets/vmfs_interactive.dart';

final machinesForSupportFormProvider = FutureProvider<List<MachineSummary>>((ref) async {
  return ref.watch(repositoryProvider).fetchMachines();
});

class SupportTicketFormScreen extends ConsumerStatefulWidget {
  const SupportTicketFormScreen({super.key, this.initialIssueType});

  final String? initialIssueType;

  @override
  ConsumerState<SupportTicketFormScreen> createState() => _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState extends ConsumerState<SupportTicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late String _issueType;
  String _priority = 'normal';
  int? _machineId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _issueType = widget.initialIssueType ?? SupportTicketCatalog.issueTypes.first.value;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  SupportIssueTypeOption get _selectedIssue =>
      SupportTicketCatalog.issueTypeFor(_issueType);

  String _machineLabel(MachineSummary machine) =>
      SupportTicketUi.machineLabel(machine.machineName, machine.machineNumber);

  Future<void> _pickMachine(List<MachineSummary> machines) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      'Select affected machine',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: machines.length,
                      itemBuilder: (context, index) {
                        final machine = machines[index];
                        final selected = machine.id == _machineId;

                        return ListTile(
                          leading: Icon(
                            Icons.memory_rounded,
                            color: selected ? VmfsColors.primary : VmfsColors.textSecondary,
                          ),
                          title: Text(machine.machineName),
                          subtitle: Text(
                            machine.machineNumber,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: VmfsColors.primary)
                              : null,
                          onTap: () => Navigator.pop(context, machine.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _machineId = picked);
    }
  }

  void _applyTemplate(String template) {
    _descriptionController.text = template;
    setState(() {});
  }

  Future<void> _submit(List<MachineSummary> machines) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final machineId = _machineId ?? machines.first.id;

    setState(() => _submitting = true);
    try {
      final ticket = await ref.read(repositoryProvider).createSupportTicket(
            machineId: machineId,
            issueDescription: _descriptionController.text.trim(),
            priority: _priority,
            issueType: _issueType,
          );
      ref.invalidate(supportTicketsProvider);
      if (!mounted) {
        return;
      }
      context.go('/support/${ticket.id}');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final machinesAsync = ref.watch(machinesForSupportFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New support ticket')),
      body: machinesAsync.when(
        loading: () => const VmfsLoadingView(),
        error: (error, _) => VmfsErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(machinesForSupportFormProvider),
        ),
        data: (machines) {
          if (machines.isEmpty) {
            return VmfsEmptyState(
              title: 'No machines yet',
              message: 'Register a vending machine first, then you can open a support ticket for it.',
              action: VmfsOutlinedButton(
                onPressed: () => context.go('/machines/new'),
                child: const Text('Add machine'),
              ),
            );
          }

          _machineId ??= machines.first.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'What do you need help with?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...SupportTicketCatalog.issueTypes.map((option) {
                  final selected = _issueType == option.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _issueType = option.value),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? VmfsColors.primary : VmfsColors.border,
                            width: selected ? 2 : 1,
                          ),
                          color: selected ? VmfsColors.primaryLight.withValues(alpha: 0.45) : VmfsColors.surface,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(option.icon, color: VmfsColors.primaryDark),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(option.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.description,
                                    style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle, color: VmfsColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                FormField<int>(
                  initialValue: _machineId,
                  validator: (value) => value == null ? 'Select a machine' : null,
                  builder: (field) {
                    final selectedId = field.value ?? _machineId ?? machines.first.id;
                    final selectedMachine = machines.firstWhere((machine) => machine.id == selectedId);

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await _pickMachine(machines);
                        field.didChange(_machineId);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Affected machine',
                          prefixIcon: const Icon(Icons.memory_rounded),
                          errorText: field.errorText,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _machineLabel(selectedMachine),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SupportTicketCatalog.priorities.map((option) {
                    final selected = _priority == option.value;
                    return ChoiceChip(
                      label: Text(option.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _priority = option.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  SupportTicketCatalog.priorities.firstWhere((p) => p.value == _priority).description,
                  style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Describe the issue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedIssue.templates.map((template) {
                    return ActionChip(
                      label: Text(template, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applyTemplate(template),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  minLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Include what happened, when it started, and any error messages…',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Please enter at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _submit(machines),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'Submitting…' : 'Submit ticket'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
