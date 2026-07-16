import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_resource_list.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';

final couponsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchCoupons();
});

final lotteriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchLotteries();
});

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(couponsProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(couponsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(couponsProvider),
          emptyTitle: 'No coupons',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['name'] as String? ?? 'Coupon'),
              subtitle: Text('Min ${currency.format((item['purchase_amount'] as num?)?.toDouble() ?? 0)}'),
              trailing: VmfsStatusPill(
                label: '${item['code_count'] ?? 0} codes',
                color: VmfsColors.info,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LotteriesScreen extends ConsumerWidget {
  const LotteriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lotteriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lotteries')),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(lotteriesProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(lotteriesProvider),
          emptyTitle: 'No lotteries',
          itemBuilder: (item) {
            final active = item['is_active'] as bool? ?? false;
            return Card(
              child: ListTile(
                title: Text(item['name'] as String? ?? 'Lottery'),
                subtitle: Text('${item['product_name'] ?? ''} · Machine ${item['machine_no'] ?? ''}'),
                trailing: VmfsStatusPill(
                  label: active ? 'Active' : 'Inactive',
                  color: active ? VmfsColors.success : VmfsColors.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
