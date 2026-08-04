import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';

String ageVerificationStatusLabel(Map<String, dynamic> session) {
  return session['status_label'] as String? ?? session['status']?.toString() ?? 'Unknown';
}

Color ageVerificationStatusColor(String? status) {
  return switch (status) {
    'verified' => VmfsColors.success,
    'rejected' => VmfsColors.danger,
    'expired' => VmfsColors.textSecondary,
    'processing' || 'uploaded' => VmfsColors.info,
    _ => VmfsColors.warning,
  };
}

String formatAgeVerificationTimestamp(String? value) {
  if (value == null || value.isEmpty) {
    return '—';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return DateFormat.yMMMd().add_jm().format(parsed.toLocal());
}
