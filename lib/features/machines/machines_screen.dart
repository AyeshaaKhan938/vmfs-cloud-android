import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/debouncer.dart';
import '../../core/onboarding/machine_onboarding.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/bulk_edit_sheet.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import '../../models/machine.dart';

final machinesProvider = FutureProvider.family<List<MachineSummary>, String>((ref, search) async {
  if (search.isEmpty) {
    ref.keepAlive();
  }
  return ref.read(repositoryProvider).fetchMachines(search: search);
});

class MachinesScreen extends ConsumerStatefulWidget {
  const MachinesScreen({super.key});

  @override
  ConsumerState<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends ConsumerState<MachinesScreen> {
  String _search = '';
  final _debouncer = Debouncer();
  final _selectedIds = <int>{};
  bool _selectionMode = false;
  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _bulkEdit() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;

    final changed = await showMachineBulkEditSheet(
      context,
      onSubmit: (payload) => ref.read(repositoryProvider).bulkUpdateMachines(ids, payload),
    );

    if (changed && mounted) {
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
      ref.invalidate(machinesProvider(_search));
    }
  }

  @override
  Widget build(BuildContext context) {
    final machines = ref.watch(machinesProvider(_search));
    final canCreate = ref.watch(authProvider.select((s) => s.user?.canAccess('machines_create') ?? false));
    final canBulkEdit = ref.watch(authProvider.select((s) => s.user?.canAccess('machines_create') ?? false));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search machines...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => _debouncer.run(() => setState(() => _search = v.trim())),
                ),
              ),
              if (canBulkEdit) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _selectionMode ? 'Cancel selection' : 'Select for bulk edit',
                  onPressed: () => setState(() {
                    _selectionMode = !_selectionMode;
                    _selectedIds.clear();
                  }),
                  icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
                ),
              ],
              if (canCreate) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Add machine',
                  onPressed: () => context.push('/machines/new'),
                  icon: const Icon(Icons.add),
                ),
              ],
            ],
          ),
        ),
        if (_selectionMode && _selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _bulkEdit,
                icon: const Icon(Icons.edit_note_outlined),
                label: Text('Bulk edit (${_selectedIds.length})'),
              ),
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
                  cacheExtent: 400,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final machine = items[index];
                    return RepaintBoundary(
                      child: Card(
                        color: _selectedIds.contains(machine.id) ? VmfsColors.primaryLight.withValues(alpha: 0.35) : null,
                        child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: _selectionMode
                            ? Checkbox(
                                value: _selectedIds.contains(machine.id),
                                onChanged: (_) => _toggleSelection(machine.id),
                              )
                            : CircleAvatar(
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
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(machine.id);
                          } else {
                            context.push('/machines/${machine.id}');
                          }
                        },
                        onLongPress: canBulkEdit && !_selectionMode
                            ? () => setState(() {
                                _selectionMode = true;
                                _selectedIds.add(machine.id);
                              })
                            : null,
                      ),
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

class MachineDetailScreen extends ConsumerStatefulWidget {
  const MachineDetailScreen({
    super.key,
    required this.machineId,
    this.showOnboardingOnOpen = false,
  });

  final int machineId;
  final bool showOnboardingOnOpen;

  @override
  ConsumerState<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends ConsumerState<MachineDetailScreen> {
  bool _restocking = false;
  bool _onboardingQueued = false;

  Future<void> _runMachineOnboarding(MachineDetail machine, {bool force = false}) async {
    final profile = await ref.read(repositoryProvider).fetchMachineOnboardingProfile(machine.machineNumber);
    if (!mounted) return;

    await maybeShowMachineOnboarding(
      context: context,
      ref: ref,
      machineId: machine.id,
      profile: profile,
      force: force,
    );
  }

  void _queueMachineOnboarding(MachineDetail machine) {
    if (_onboardingQueued) {
      return;
    }

    _onboardingQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runMachineOnboarding(machine, force: widget.showOnboardingOnOpen);
    });
  }

  Future<void> _restockAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restock all slots?'),
        content: const Text('Set current stock to max stock for every slot on this machine.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restock all')),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _restocking = true);
    try {
      await ref.read(repositoryProvider).restockAllSlots(widget.machineId);
      ref.invalidate(machineDetailProvider(widget.machineId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All slots restocked to max capacity')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _restocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(machineDetailProvider(widget.machineId));
    final user = ref.watch(authProvider.select((s) => s.user));
    final canEdit = user?.canAccess('machines_create') == true || user?.canAccess('machine_slots') == true;
    final canManageSlots = user?.canAccess('machine_slots') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine'),
        actions: [
          IconButton(
            tooltip: 'Machine setup guide',
            onPressed: detail.maybeWhen(
              data: (machine) => () => _runMachineOnboarding(machine, force: true),
              orElse: () => null,
            ),
            icon: const Icon(Icons.help_outline),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Edit machine',
              onPressed: () async {
                final changed = await context.push<bool>('/machines/${widget.machineId}/edit');
                if (changed == true) ref.invalidate(machineDetailProvider(widget.machineId));
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canManageSlots)
            IconButton(
              tooltip: 'Add slot',
              onPressed: () async {
                final changed = await context.push<bool>('/machines/${widget.machineId}/slots/new');
                if (changed == true) ref.invalidate(machineDetailProvider(widget.machineId));
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: detail.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(machineDetailProvider(widget.machineId)),
        ),
        data: (machine) {
          _queueMachineOnboarding(machine);

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Slots & products',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (canManageSlots)
                    FilledButton.tonalIcon(
                      onPressed: _restocking ? null : _restockAll,
                      icon: _restocking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.inventory_2_outlined),
                      label: const Text('Restock all'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...machine.slots.map(
                (slot) => Card(
                  child: ListTile(
                    title: Text('Slot #${slot.lineNumber}'),
                    subtitle: Text('${slot.productName} · ${slot.currentStock}/${slot.maxStock}'),
                    trailing: Text('\$${slot.price.toStringAsFixed(2)}'),
                    onTap: canManageSlots
                        ? () async {
                            final changed = await context.push<bool>(
                              '/machines/${widget.machineId}/slots/${slot.id}/edit',
                            );
                            if (changed == true) ref.invalidate(machineDetailProvider(widget.machineId));
                          }
                        : null,
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
