import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_crud_screen.dart';
import '../../core/widgets/vmfs_resource_list.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';

final machineGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchMachineGroups();
});

final machineAlarmsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchMachineAlarms();
});

final machineMapProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchMachineMap();
});

final productCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchProductCategories();
});

final productTagsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchProductTags();
});

final productTypesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchProductTypes();
});

final financeGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchFinanceGroups();
});

final labelGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchLabelGroups();
});

class MachineGroupsScreen extends ConsumerWidget {
  const MachineGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('machines_view') ?? false));
    final repo = ref.read(repositoryProvider);

    return VmfsCrudScreen(
      title: 'Machine groups',
      provider: machineGroupsProvider,
      emptyTitle: 'No machine groups',
      canManage: canManage,
      fields: const [VmfsCrudField(key: 'name', label: 'Group name', required: true)],
      itemTitle: (item) => item['name'] as String? ?? 'Group',
      itemSubtitle: (item) => '${item['machine_count'] ?? 0} machines',
      onCreate: repo.createMachineGroup,
      onUpdate: repo.updateMachineGroup,
      onDelete: repo.deleteMachineGroup,
    );
  }
}

class MachineAlarmsScreen extends ConsumerWidget {
  const MachineAlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(machineAlarmsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(machineAlarmsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(machineAlarmsProvider),
          emptyTitle: 'No alarms',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['title'] as String? ?? 'Alarm'),
              subtitle: Text('${item['machine_name'] ?? ''}\n${item['message'] ?? ''}'),
              trailing: Text(item['severity']?.toString() ?? ''),
            ),
          ),
        ),
      ),
    );
  }
}

class MachineMapScreen extends ConsumerWidget {
  const MachineMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(machineMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Machine map')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(machineMapProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(machineMapProvider),
          emptyTitle: 'No mapped machines',
          emptyMessage: 'Add latitude and longitude on machines to see them here.',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['machine_name'] as String? ?? 'Machine'),
              subtitle: Text(
                '${item['detailed_address'] ?? ''}\n${item['latitude']}, ${item['longitude']}',
              ),
              trailing: VmfsStatusPill(
                label: (item['is_online'] as bool? ?? false) ? 'Online' : 'Offline',
                color: (item['is_online'] as bool? ?? false) ? VmfsColors.success : VmfsColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCategoriesScreen extends ConsumerWidget {
  const ProductCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('products') ?? false));
    final repo = ref.read(repositoryProvider);

    return VmfsCrudScreen(
      title: 'Categories',
      provider: productCategoriesProvider,
      emptyTitle: 'No categories',
      canManage: canManage,
      fields: const [
        VmfsCrudField(key: 'name', label: 'Category name', required: true),
        VmfsCrudField(key: 'value', label: 'Value'),
      ],
      itemTitle: (item) => item['name'] as String? ?? 'Category',
      itemSubtitle: (item) => item['value']?.toString() ?? '—',
      onCreate: repo.createProductCategory,
      onUpdate: repo.updateProductCategory,
      onDelete: repo.deleteProductCategory,
    );
  }
}

class ProductTagsScreen extends ConsumerWidget {
  const ProductTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('products') ?? false));
    final repo = ref.read(repositoryProvider);

    return VmfsCrudScreen(
      title: 'Product tags',
      provider: productTagsProvider,
      emptyTitle: 'No tags',
      canManage: canManage,
      fields: const [VmfsCrudField(key: 'name', label: 'Tag name', required: true)],
      itemTitle: (item) => item['name'] as String? ?? 'Tag',
      itemSubtitle: (_) => 'Product tag',
      onCreate: repo.createProductTag,
      onUpdate: repo.updateProductTag,
      onDelete: repo.deleteProductTag,
    );
  }
}

class ProductTypesScreen extends ConsumerWidget {
  const ProductTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('products') ?? false));
    final repo = ref.read(repositoryProvider);

    return VmfsCrudScreen(
      title: 'Product types',
      provider: productTypesProvider,
      emptyTitle: 'No product types',
      canManage: canManage,
      fields: const [VmfsCrudField(key: 'name', label: 'Type name', required: true)],
      itemTitle: (item) => item['name'] as String? ?? 'Type',
      itemSubtitle: (_) => 'Specification type',
      onCreate: repo.createProductType,
      onUpdate: repo.updateProductType,
      onDelete: repo.deleteProductType,
    );
  }
}

class FinanceGroupsScreen extends ConsumerWidget {
  const FinanceGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('machines_view') ?? false));
    final repo = ref.read(repositoryProvider);

    return VmfsCrudScreen(
      title: 'Finance groups',
      provider: financeGroupsProvider,
      emptyTitle: 'No finance groups',
      canManage: canManage,
      fields: const [VmfsCrudField(key: 'name', label: 'Group name', required: true)],
      itemTitle: (item) => item['name'] as String? ?? 'Group',
      itemSubtitle: (item) => '${item['machine_count'] ?? 0} machines',
      onCreate: repo.createFinanceGroup,
      onUpdate: repo.updateFinanceGroup,
      onDelete: repo.deleteFinanceGroup,
    );
  }
}

class LabelGroupsScreen extends ConsumerWidget {
  const LabelGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(authProvider.select((s) => s.user?.canAccess('machines_view') ?? false));
    final repo = ref.read(repositoryProvider);

    return VmfsCrudScreen(
      title: 'Label groups',
      provider: labelGroupsProvider,
      emptyTitle: 'No label groups',
      canManage: canManage,
      fields: const [VmfsCrudField(key: 'name', label: 'Group name', required: true)],
      itemTitle: (item) => item['name'] as String? ?? 'Group',
      itemSubtitle: (item) => '${item['machine_count'] ?? 0} machines',
      onCreate: repo.createLabelGroup,
      onUpdate: repo.updateLabelGroup,
      onDelete: repo.deleteLabelGroup,
    );
  }
}
