import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/order.dart';

final ordersProvider = FutureProvider<List<OrderSummary>>((ref) async {
  return ref.watch(repositoryProvider).fetchOrders();
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final currency = NumberFormat.simpleCurrency();

    return orders.when(
      loading: () => const VmfsLoadingView(),
      error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(ordersProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const VmfsEmptyState(
            title: 'No orders yet',
            message: 'Sales from your machines will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(ordersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = items[index];
              return Card(
                child: ListTile(
                  title: Text(order.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Machine ${order.machineNo} · ${order.createdAt}'),
                  trailing: Text(currency.format(order.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => context.push('/orders/${order.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
