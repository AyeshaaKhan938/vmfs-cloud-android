import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/vmfs_resource_list.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';

final advertisementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchAdvertisements();
});

final advertisementGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchAdvertisementGroups();
});

final advertisementTagsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchAdvertisementTags();
});

class AdvertisementsScreen extends ConsumerWidget {
  const AdvertisementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(advertisementsProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Advertisements')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(advertisementsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(advertisementsProvider),
          emptyTitle: 'No advertisements',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['title'] as String? ?? 'Ad'),
              subtitle: Text('${item['type_label'] ?? item['type']} · ${item['advertiser_name'] ?? ''}'),
              trailing: Text(currency.format((item['cost'] as num?)?.toDouble() ?? 0)),
            ),
          ),
        ),
      ),
    );
  }
}

class AdvertisementGroupsScreen extends ConsumerWidget {
  const AdvertisementGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(advertisementGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Advertisement groups')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(advertisementGroupsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(advertisementGroupsProvider),
          emptyTitle: 'No advertisement groups',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['name'] as String? ?? 'Group'),
              trailing: Text('${item['advertisement_count'] ?? 0} ads'),
            ),
          ),
        ),
      ),
    );
  }
}

class AdvertisementTagsScreen extends ConsumerWidget {
  const AdvertisementTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(advertisementTagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Advertisement tags')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(advertisementTagsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(advertisementTagsProvider),
          emptyTitle: 'No tags',
          itemBuilder: (item) => Card(
            child: ListTile(title: Text(item['name'] as String? ?? 'Tag')),
          ),
        ),
      ),
    );
  }
}
