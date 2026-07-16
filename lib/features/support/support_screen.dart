import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/machine.dart';
import '../../models/support_ticket.dart';

final supportTicketsProvider = FutureProvider<List<SupportTicketSummary>>((ref) async {
  return ref.watch(repositoryProvider).fetchSupportTickets();
});

final machinesForTicketProvider = FutureProvider<List<MachineSummary>>((ref) async {
  return ref.watch(repositoryProvider).fetchMachines();
});

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTicket(context, ref),
        backgroundColor: VmfsColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: tickets.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(supportTicketsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const VmfsEmptyState(
              title: 'No support tickets',
              message: 'Submit a ticket when a machine needs help.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supportTicketsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ticket = items[index];
                return Card(
                  child: ListTile(
                    title: Text(ticket.workOrderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${ticket.machineName}\n${ticket.issueDescription}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    trailing: VmfsStatusPill(label: ticket.statusLabel, color: VmfsColors.warning),
                    onTap: () => context.push('/support/${ticket.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateTicket(BuildContext context, WidgetRef ref) async {
    final machines = await ref.read(machinesForTicketProvider.future);
    if (!context.mounted || machines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a machine before submitting a ticket.')),
      );
      return;
    }

    var selectedMachineId = machines.first.id;
    final descriptionController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New support ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedMachineId,
              decoration: const InputDecoration(labelText: 'Machine'),
              items: machines
                  .map((m) => DropdownMenuItem(value: m.id, child: Text(m.machineName)))
                  .toList(),
              onChanged: (v) => selectedMachineId = v ?? selectedMachineId,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Describe the issue'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );

    if (created == true && descriptionController.text.trim().isNotEmpty) {
      await ref.read(repositoryProvider).createSupportTicket(
            machineId: selectedMachineId,
            issueDescription: descriptionController.text.trim(),
          );
      ref.invalidate(supportTicketsProvider);
    }

    descriptionController.dispose();
  }
}
