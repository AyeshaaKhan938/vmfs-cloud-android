import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_resource_list.dart';
import '../../core/widgets/vmfs_widgets.dart';
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

class MachineGroupsScreen extends ConsumerWidget {
  const MachineGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(machineGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Machine groups')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(machineGroupsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(machineGroupsProvider),
          emptyTitle: 'No machine groups',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['name'] as String? ?? 'Group'),
              trailing: Text('${item['machine_count'] ?? 0} machines'),
            ),
          ),
        ),
      ),
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
              isThreeLine: true,
              trailing: VmfsStatusPill(
                label: item['severity'] as String? ?? 'alert',
                color: VmfsColors.danger,
              ),
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
        data: (list) {
          if (list.isEmpty) {
            return const VmfsEmptyState(
              title: 'No map data',
              message: 'Machines need latitude/longitude set on the web panel.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(machineMapProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = list[index];
                final lat = (item['latitude'] as num?)?.toDouble();
                final lng = (item['longitude'] as num?)?.toDouble();
                final online = item['is_online'] as bool? ?? false;

                return Card(
                  child: ListTile(
                    title: Text(item['machine_name'] as String? ?? 'Machine'),
                    subtitle: Text(
                      '#${item['machine_number']}\n${item['detailed_address'] ?? ''}\n$lat, $lng',
                    ),
                    isThreeLine: true,
                    trailing: VmfsStatusPill(
                      label: online ? 'Online' : 'Offline',
                      color: online ? VmfsColors.success : VmfsColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProductCategoriesScreen extends ConsumerWidget {
  const ProductCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(productCategoriesProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(productCategoriesProvider),
          emptyTitle: 'No categories',
          itemBuilder: (item) => Card(child: ListTile(title: Text(item['name'] as String? ?? 'Category'))),
        ),
      ),
    );
  }
}

class ProductTagsScreen extends ConsumerWidget {
  const ProductTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(productTagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product tags')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(productTagsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(productTagsProvider),
          emptyTitle: 'No product tags',
          itemBuilder: (item) => Card(child: ListTile(title: Text(item['name'] as String? ?? 'Tag'))),
        ),
      ),
    );
  }
}

class ProductTypesScreen extends ConsumerWidget {
  const ProductTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(productTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product types')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(productTypesProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(productTypesProvider),
          emptyTitle: 'No product types',
          itemBuilder: (item) => Card(child: ListTile(title: Text(item['name'] as String? ?? 'Type'))),
        ),
      ),
    );
  }
}
