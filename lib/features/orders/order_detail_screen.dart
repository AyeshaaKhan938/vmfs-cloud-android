import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../../models/order.dart';
import '../auth/auth_provider.dart';

final orderDetailProvider = FutureProvider.family<OrderDetail, int>((ref, id) async {
  return ref.watch(repositoryProvider).fetchOrder(id);
});

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(orderId));
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: detail.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VmfsHeroBanner(
                kicker: 'Order detail',
                title: order.summary.productName,
                subtitle: 'Machine ${order.summary.machineNo}',
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(title: const Text('Amount'), trailing: Text(currency.format(order.summary.amount))),
                    const Divider(height: 1),
                    ListTile(title: const Text('Status'), trailing: Text(order.summary.status)),
                    const Divider(height: 1),
                    ListTile(title: const Text('Payment'), trailing: Text(order.paymentMethod)),
                    if (order.slotLineNumber != null) ...[
                      const Divider(height: 1),
                      ListTile(title: const Text('Slot'), trailing: Text('#${order.slotLineNumber}')),
                    ],
                    if (order.productSku.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(title: const Text('SKU'), trailing: Text(order.productSku)),
                    ],
                    const Divider(height: 1),
                    ListTile(title: const Text('Created'), subtitle: Text(order.summary.createdAt)),
                    if (order.completedAt.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(title: const Text('Completed'), subtitle: Text(order.completedAt)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
