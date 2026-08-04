import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../models/product.dart';
import '../auth/auth_provider.dart';
import '../../core/widgets/vmfs_interactive.dart';

class MachineSlotFormScreen extends ConsumerStatefulWidget {
  const MachineSlotFormScreen({
    super.key,
    required this.machineId,
    this.slotId,
  });

  final int machineId;
  final int? slotId;

  bool get isEditing => slotId != null;

  @override
  ConsumerState<MachineSlotFormScreen> createState() => _MachineSlotFormScreenState();
}

class _MachineSlotFormScreenState extends ConsumerState<MachineSlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lineController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _alarmController = TextEditingController(text: '3');
  int? _productId;
  bool _isActive = true;
  bool _isFault = false;
  bool _loading = false;
  bool _initialized = false;
  List<ProductSummary> _products = const [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ref.read(repositoryProvider).fetchProducts();
    if (!mounted) return;

    if (widget.slotId != null) {
      final machine = await ref.read(repositoryProvider).fetchMachine(widget.machineId);
      final slot = machine.slots.firstWhere((s) => s.id == widget.slotId);
      setState(() {
        _products = products;
        _lineController.text = '${slot.lineNumber}';
        _priceController.text = slot.price.toStringAsFixed(2);
        _maxStockController.text = '${slot.maxStock}';
        _currentStockController.text = '${slot.currentStock}';
        _alarmController.text = '${slot.stockAlarmThreshold}';
        _productId = slot.productId;
        _isActive = slot.isActive;
        _isFault = slot.isFault;
        _initialized = true;
      });
      return;
    }

    setState(() => _products = products);
  }

  @override
  void dispose() {
    _lineController.dispose();
    _priceController.dispose();
    _maxStockController.dispose();
    _currentStockController.dispose();
    _alarmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      final line = int.parse(_lineController.text.trim());
      final price = double.parse(_priceController.text.trim());
      final maxStock = int.parse(_maxStockController.text.trim());
      final currentStock = int.parse(_currentStockController.text.trim());
      final alarm = int.parse(_alarmController.text.trim());

      if (widget.isEditing) {
        await repo.updateMachineSlot(
          machineId: widget.machineId,
          slotId: widget.slotId!,
          lineNumber: line,
          productId: _productId,
          clearProduct: _productId == null,
          price: price,
          maxStock: maxStock,
          currentStock: currentStock,
          stockAlarmThreshold: alarm,
          isActive: _isActive,
          isFault: _isFault,
        );
      } else {
        await repo.createMachineSlot(
          machineId: widget.machineId,
          lineNumber: line,
          productId: _productId,
          price: price,
          maxStock: maxStock,
          currentStock: currentStock,
          stockAlarmThreshold: alarm,
          isActive: _isActive,
          isFault: _isFault,
        );
      }

      if (mounted) context.pop(true);
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
        title: const Text('Delete slot?'),
        content: const Text('This removes the slot from the machine.'),
        actions: [
          VmfsTextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          VmfsFilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).deleteMachineSlot(
            machineId: widget.machineId,
            slotId: widget.slotId!,
          );
      if (mounted) context.pop(true);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit slot' : 'Add slot')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _lineController,
              decoration: const InputDecoration(labelText: 'Slot line number *'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _productId,
              decoration: const InputDecoration(labelText: 'Product'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Empty slot')),
                for (final product in _products)
                  DropdownMenuItem<int?>(
                    value: product.id,
                    child: Text(product.name),
                  ),
              ],
              onChanged: (v) => setState(() => _productId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxStockController,
              decoration: const InputDecoration(labelText: 'Max stock *'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentStockController,
              decoration: const InputDecoration(labelText: 'Current stock *'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alarmController,
              decoration: const InputDecoration(labelText: 'Low stock alert at *'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            SwitchListTile(
              title: const Text('Fault'),
              value: _isFault,
              onChanged: (v) => setState(() => _isFault = v),
            ),
            const SizedBox(height: 24),
            VmfsFilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(widget.isEditing ? 'Save slot' : 'Create slot'),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              VmfsOutlinedButton(
                onPressed: _loading ? null : _delete,
                child: const Text('Delete slot'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
