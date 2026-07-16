import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../../models/product.dart';
import '../auth/auth_provider.dart';

final productDetailProvider = FutureProvider.family<ProductDetail, int>((ref, id) async {
  return ref.watch(repositoryProvider).fetchProduct(id);
});

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: detail.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VmfsHeroBanner(
                kicker: 'Product hub',
                title: product.summary.name,
                subtitle: 'SKU ${product.summary.sku.isEmpty ? '—' : product.summary.sku}',
                trailing: VmfsStatusPill(
                  label: product.summary.isActive ? 'Active' : 'Inactive',
                  color: product.summary.isActive ? VmfsColors.success : VmfsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  VmfsStatCard(label: 'Price', value: currency.format(product.summary.price)),
                  VmfsStatCard(label: 'Cost', value: currency.format(product.cost)),
                  VmfsStatCard(label: 'Machines', value: '${product.summary.machineCount}'),
                  VmfsStatCard(label: 'Category', value: product.categoryName),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(product.description),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Machine deployments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...product.deployments.map(
                (d) => Card(
                  child: ListTile(
                    title: Text(d.machineName),
                    subtitle: Text('Slot #${d.lineNumber} · Stock ${d.currentStock}'),
                    trailing: Text(currency.format(d.price)),
                  ),
                ),
              ),
              if (product.lotteries.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Lotteries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ...product.lotteries.map(
                  (l) => Card(
                    child: ListTile(
                      title: Text(l['name'] as String? ?? 'Lottery'),
                      subtitle: Text('Machine ${l['machine_no'] ?? ''}'),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
