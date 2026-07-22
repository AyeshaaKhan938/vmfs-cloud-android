import 'package:flutter/material.dart';

import '../network/api_exception.dart';

Future<bool> showMachineBulkEditSheet(
  BuildContext context, {
  required Future<void> Function(Map<String, dynamic> payload) onSubmit,
}) {
  return showBulkEditSheet(
    context,
    title: 'Bulk edit machines',
    fields: const [
      BulkEditToggleField(key: 'is_enabled', label: 'Enabled'),
      BulkEditToggleField(key: 'age_verification_enabled', label: 'Age verification'),
      BulkEditNumberField(key: 'minimum_age', label: 'Minimum age'),
    ],
    onSubmit: onSubmit,
  );
}

Future<bool> showProductBulkEditSheet(
  BuildContext context, {
  required Future<void> Function(Map<String, dynamic> payload) onSubmit,
}) {
  return showBulkEditSheet(
    context,
    title: 'Bulk edit products',
    fields: const [
      BulkEditToggleField(key: 'is_active', label: 'Active'),
      BulkEditToggleField(key: 'requires_age_verification', label: 'Requires age verification'),
      BulkEditNumberField(key: 'minimum_age', label: 'Minimum age'),
    ],
    onSubmit: onSubmit,
  );
}

sealed class BulkEditField {
  const BulkEditField({required this.key, required this.label});

  final String key;
  final String label;
}

class BulkEditToggleField extends BulkEditField {
  const BulkEditToggleField({required super.key, required super.label});
}

class BulkEditNumberField extends BulkEditField {
  const BulkEditNumberField({required super.key, required super.label});
}

Future<bool> showBulkEditSheet(
  BuildContext context, {
  required String title,
  required List<BulkEditField> fields,
  required Future<void> Function(Map<String, dynamic> payload) onSubmit,
}) async {
  final selectedKeys = <String>{};
  final values = <String, dynamic>{};

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Choose fields to apply to all selected items.'),
                    const SizedBox(height: 12),
                    for (final field in fields) ...[
                      if (field is BulkEditToggleField)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(field.label),
                          value: selectedKeys.contains(field.key)
                              ? (values[field.key] as bool? ?? false)
                              : false,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked) {
                                selectedKeys.add(field.key);
                                values[field.key] = true;
                              } else {
                                selectedKeys.remove(field.key);
                                values.remove(field.key);
                              }
                            });
                          },
                          subtitle: selectedKeys.contains(field.key)
                              ? Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('On'),
                                      selected: values[field.key] == true,
                                      onSelected: (_) => setModalState(() => values[field.key] = true),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Off'),
                                      selected: values[field.key] == false,
                                      onSelected: (_) => setModalState(() => values[field.key] = false),
                                    ),
                                  ],
                                )
                              : const Text('Tap switch to include this field'),
                        ),
                      if (field is BulkEditNumberField)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(field.label),
                          value: selectedKeys.contains(field.key),
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                selectedKeys.add(field.key);
                                values[field.key] ??= '21';
                              } else {
                                selectedKeys.remove(field.key);
                                values.remove(field.key);
                              }
                            });
                          },
                          subtitle: selectedKeys.contains(field.key)
                              ? TextFormField(
                                  initialValue: values[field.key]?.toString() ?? '',
                                  decoration: const InputDecoration(labelText: 'Value'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => values[field.key] = int.tryParse(v),
                                )
                              : null,
                        ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (selectedKeys.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select at least one field to update')),
                          );
                          return;
                        }

                        final payload = <String, dynamic>{
                          for (final key in selectedKeys) key: values[key],
                        };

                        try {
                          await onSubmit(payload);
                          if (context.mounted) Navigator.pop(context, true);
                        } on ApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                          }
                        }
                      },
                      child: const Text('Apply to selected'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  return saved == true;
}
