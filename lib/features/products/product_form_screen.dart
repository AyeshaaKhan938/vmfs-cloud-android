import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import '../products/products_screen.dart';
import '../../core/widgets/vmfs_interactive.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _ageVerification = false;
  int? _categoryId;
  int? _tagId;
  bool _loading = false;
  bool _initialized = false;
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _tags = const [];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final repo = ref.read(repositoryProvider);
    final categories = await repo.fetchProductCategories();
    final tags = await repo.fetchProductTags();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _tags = tags;
    });

    if (widget.productId != null) {
      await _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final product = await ref.read(repositoryProvider).fetchProduct(widget.productId!);
    if (!mounted) return;
    setState(() {
      _nameController.text = product.summary.name;
      _costController.text = product.cost.toStringAsFixed(2);
      _priceController.text = product.summary.price.toStringAsFixed(2);
      _barcodeController.text = product.barcode;
      _descriptionController.text = product.description;
      _isActive = product.summary.isActive;
      _ageVerification = product.requiresAgeVerification;
      _categoryId = product.specificationId;
      _tagId = product.productTagId;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      final name = _nameController.text.trim();
      final cost = double.parse(_costController.text.trim());
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final description = _descriptionController.text.trim();
      final barcode = _barcodeController.text.trim();

      if (widget.isEditing) {
        await repo.updateProduct(
          id: widget.productId!,
          name: name,
          cost: cost,
          price: price,
          description: description,
          barcode: barcode,
          specificationId: _categoryId,
          productTagId: _tagId,
          isActive: _isActive,
          requiresAgeVerification: _ageVerification,
        );
        if (mounted) context.pop(true);
      } else {
        final created = await repo.createProduct(
          name: name,
          cost: cost,
          price: price,
          description: description,
          barcode: barcode,
          specificationId: _categoryId,
          productTagId: _tagId,
          isActive: _isActive,
          requiresAgeVerification: _ageVerification,
        );
        ref.invalidate(productsProvider(''));
        if (mounted) context.go('/products/${created.id}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This permanently removes the product from your catalog.'),
        actions: [
          VmfsTextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          VmfsFilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).deleteProduct(widget.productId!);
      ref.invalidate(productsProvider(''));
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_initialized) {
      return const Scaffold(body: VmfsLoadingView());
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit product' : 'Add product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(labelText: 'Cost price *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Sale price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(labelText: 'Barcode'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                for (final category in _categories)
                  DropdownMenuItem<int?>(
                    value: category['id'] as int,
                    child: Text(category['name']?.toString() ?? 'Category'),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _tagId,
              decoration: const InputDecoration(labelText: 'Tag'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                for (final tag in _tags)
                  DropdownMenuItem<int?>(
                    value: tag['id'] as int,
                    child: Text(tag['name']?.toString() ?? 'Tag'),
                  ),
              ],
              onChanged: (v) => setState(() => _tagId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            SwitchListTile(
              title: const Text('Age verification required'),
              value: _ageVerification,
              onChanged: (v) => setState(() => _ageVerification = v),
            ),
            const SizedBox(height: 24),
            VmfsFilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(widget.isEditing ? 'Save product' : 'Create product'),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              VmfsOutlinedButton(
                onPressed: _loading ? null : _delete,
                child: const Text('Delete product'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
