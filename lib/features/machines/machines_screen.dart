import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/machine.dart';

final machinesProvider = FutureProvider.family<List<MachineSummary>, String>((ref, search) async {
  return ref.watch(repositoryProvider).fetchMachines(search: search);
});

class MachinesScreen extends ConsumerStatefulWidget {
  const MachinesScreen({super.key});

  @override
  ConsumerState<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends ConsumerState<MachinesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final machines = ref.watch(machinesProvider(_search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search machines...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: machines.when(
            loading: () => const VmfsLoadingView(),
            error: (e, _) => VmfsErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(machinesProvider(_search)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const VmfsEmptyState(
                  title: 'No machines',
                  message: 'No machines are linked to this account yet.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(machinesProvider(_search)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final machine = items[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: VmfsColors.primaryLight,
                          child: Icon(
                            Icons.memory_rounded,
                            color: machine.isOnline ? VmfsColors.success : VmfsColors.textSecondary,
                          ),
                        ),
                        title: Text(machine.machineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('#${machine.machineNumber} · ${machine.slotCount} slots'),
                        trailing: VmfsStatusPill(
                          label: machine.isOnline ? 'Online' : 'Offline',
                          color: machine.isOnline ? VmfsColors.success : VmfsColors.textSecondary,
                        ),
                        onTap: () => context.push('/machines/${machine.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final machineDetailProvider = FutureProvider.family<MachineDetail, int>((ref, id) async {
  return ref.watch(repositoryProvider).fetchMachine(id);
});

class MachineDetailScreen extends ConsumerWidget {
  const MachineDetailScreen({super.key, required this.machineId});

  final int machineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(machineDetailProvider(machineId));

    return Scaffold(
      appBar: AppBar(title: const Text('Machine')),
      body: detail.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(machineDetailProvider(machineId)),
        ),
        data: (machine) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VmfsHeroBanner(
                kicker: 'Machine overview',
                title: machine.machineName,
                subtitle: '#${machine.machineNumber}',
                trailing: VmfsStatusPill(
                  label: machine.isOnline ? 'Online' : 'Offline',
                  color: machine.isOnline ? VmfsColors.success : VmfsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  VmfsStatCard(label: 'Total', value: '${machine.slotSummary.total}'),
                  VmfsStatCard(label: 'Stocked', value: '${machine.slotSummary.stocked}', color: VmfsColors.success),
                  VmfsStatCard(label: 'Low', value: '${machine.slotSummary.lowStock}', color: VmfsColors.warning),
                  VmfsStatCard(label: 'Empty', value: '${machine.slotSummary.empty}', color: VmfsColors.danger),
                  VmfsStatCard(label: 'Fault', value: '${machine.slotSummary.fault}', color: VmfsColors.danger),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Slots & products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...machine.slots.map(
                (slot) => Card(
                  child: ListTile(
                    title: Text('Slot #${slot.lineNumber}'),
                    subtitle: Text('${slot.productName} · ${slot.currentStock}/${slot.maxStock}'),
                    trailing: Text('\$${slot.price.toStringAsFixed(2)}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
