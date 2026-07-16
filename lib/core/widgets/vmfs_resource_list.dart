import 'package:flutter/material.dart';

import 'vmfs_widgets.dart';

Widget buildVmfsResourceList({
  required List<Map<String, dynamic>> list,
  required Future<void> Function() onRefresh,
  required Widget Function(Map<String, dynamic>) itemBuilder,
  required String emptyTitle,
  String emptyMessage = 'Nothing configured yet.',
}) {
  if (list.isEmpty) {
    return VmfsEmptyState(title: emptyTitle, message: emptyMessage);
  }

  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => itemBuilder(list[index]),
    ),
  );
}
