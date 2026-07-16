import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/product.dart';

final productsProvider = FutureProvider.family<List<ProductSummary>, String>((ref, search) async {
  return ref.watch(repositoryProvider).fetchProducts(search: search);
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider(_search));
    final currency = NumberFormat.simpleCurrency();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: products.when(
            loading: () => const VmfsLoadingView(),
            error: (e, _) => VmfsErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(productsProvider(_search)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const VmfsEmptyState(
                  title: 'No products',
                  message: 'Your product catalog is empty.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(productsProvider(_search)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: VmfsColors.primaryLight,
                          child: Icon(Icons.shopping_bag_outlined, color: VmfsColors.primaryDark),
                        ),
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('SKU ${product.sku.isEmpty ? '—' : product.sku} · ${product.machineCount} machines'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(product.price), style: const TextStyle(fontWeight: FontWeight.w700)),
                            VmfsStatusPill(
                              label: product.isActive ? 'Active' : 'Inactive',
                              color: product.isActive ? VmfsColors.success : VmfsColors.textSecondary,
                            ),
                          ],
                        ),
                        onTap: () => context.push('/products/${product.id}'),
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
