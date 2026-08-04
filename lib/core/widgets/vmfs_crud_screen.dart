import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'vmfs_interactive.dart';
import 'vmfs_resource_list.dart';
import 'vmfs_widgets.dart';

typedef VmfsFieldBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> values,
  void Function(String key, dynamic value) onChanged,
);

class VmfsCrudField {
  const VmfsCrudField({
    required this.key,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.initialValue,
  });

  final String key;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final String? initialValue;
}

class VmfsCrudScreen extends ConsumerStatefulWidget {
  const VmfsCrudScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.emptyTitle,
    required this.fields,
    required this.canManage,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    this.itemTrailing,
  });

  final String title;
  final FutureProvider<List<Map<String, dynamic>>> provider;
  final String emptyTitle;
  final List<VmfsCrudField> fields;
  final bool canManage;
  final String Function(Map<String, dynamic> item) itemTitle;
  final String Function(Map<String, dynamic> item) itemSubtitle;
  final String? Function(Map<String, dynamic> item)? itemTrailing;
  final Future<void> Function(Map<String, dynamic> values) onCreate;
  final Future<void> Function(int id, Map<String, dynamic> values) onUpdate;
  final Future<void> Function(int id) onDelete;

  @override
  ConsumerState<VmfsCrudScreen> createState() => _VmfsCrudScreenState();
}

class _VmfsCrudScreenState extends ConsumerState<VmfsCrudScreen> {
  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final values = <String, dynamic>{
      for (final field in widget.fields)
        field.key: item?[field.key]?.toString() ?? field.initialValue ?? '',
    };

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item == null ? 'Add' : 'Edit',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      for (final field in widget.fields) ...[
                        TextFormField(
                          initialValue: values[field.key]?.toString() ?? '',
                          decoration: InputDecoration(labelText: field.label),
                          keyboardType: field.keyboardType,
                          onChanged: (v) => values[field.key] = v,
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      VmfsFilledButton(
                        onPressed: () async {
                          for (final field in widget.fields) {
                            if (field.required && (values[field.key]?.toString().trim().isEmpty ?? true)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${field.label} is required')),
                              );
                              return;
                            }
                          }
                          Navigator.pop(context, true);
                        },
                        child: Text(item == null ? 'Create' : 'Save'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (saved != true || !mounted) return;

    try {
      if (item == null) {
        await widget.onCreate(values);
      } else {
        await widget.onUpdate(item['id'] as int, values);
      }
      ref.invalidate(widget.provider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          VmfsTextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          VmfsFilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await widget.onDelete(id);
      ref.invalidate(widget.provider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(widget.provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.canManage)
            VmfsIconButton(
              tooltip: 'Add',
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: items.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(widget.provider),
        ),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(widget.provider),
          emptyTitle: widget.emptyTitle,
          itemBuilder: (item) => VmfsTappableCard(
            onTap: widget.canManage ? () => _openForm(item: item) : null,
            onLongPress: widget.canManage ? () => _confirmDelete(item['id'] as int) : null,
            child: ListTile(
              title: Text(widget.itemTitle(item)),
              subtitle: Text(widget.itemSubtitle(item)),
              trailing: widget.itemTrailing != null ? Text(widget.itemTrailing!(item) ?? '') : null,
            ),
          ),
        ),
      ),
    );
  }
}
