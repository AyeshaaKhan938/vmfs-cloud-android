import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/utils/debouncer.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/bulk_edit_sheet.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/product.dart';

final productsProvider = FutureProvider.family<List<ProductSummary>, String>((ref, search) async {
  if (search.isEmpty) {
    ref.keepAlive();
  }
  return ref.read(repositoryProvider).fetchProducts(search: search);
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
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

    final changed = await showProductBulkEditSheet(
      context,
      onSubmit: (payload) => ref.read(repositoryProvider).bulkUpdateProducts(ids, payload),
    );

    if (changed && mounted) {
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
      ref.invalidate(productsProvider(_search));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider(_search));
    final currency = NumberFormat.simpleCurrency();
    final canCreate = ref.watch(authProvider.select((s) => s.user?.canAccess('products') ?? false));
    final canBulkEdit = canCreate;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
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
                  tooltip: 'Add product',
                  onPressed: () => context.push('/products/new'),
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
                  cacheExtent: 400,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return RepaintBoundary(
                      child: Card(
                        color: _selectedIds.contains(product.id) ? VmfsColors.primaryLight.withValues(alpha: 0.35) : null,
                        child: ListTile(
                        leading: _selectionMode
                            ? Checkbox(
                                value: _selectedIds.contains(product.id),
                                onChanged: (_) => _toggleSelection(product.id),
                              )
                            : const CircleAvatar(
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
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(product.id);
                          } else {
                            context.push('/products/${product.id}');
                          }
                        },
                        onLongPress: canBulkEdit && !_selectionMode
                            ? () => setState(() {
                                _selectionMode = true;
                                _selectedIds.add(product.id);
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
