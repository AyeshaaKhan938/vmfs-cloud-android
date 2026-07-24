import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';

enum SupportTicketFilter { all, open, resolved }

class SupportIssueTypeOption {
  const SupportIssueTypeOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.description,
    required this.templates,
  });

  final String value;
  final String label;
  final IconData icon;
  final String description;
  final List<String> templates;
}

class SupportPriorityOption {
  const SupportPriorityOption({
    required this.value,
    required this.label,
    required this.description,
  });

  final String value;
  final String label;
  final String description;
}

abstract final class SupportTicketCatalog {
  static const issueTypes = [
    SupportIssueTypeOption(
      value: 'machine_issue',
      label: 'Machine issue',
      icon: Icons.memory_rounded,
      description: 'Offline, jammed, screen errors, dispensing problems',
      templates: [
        'Machine is offline or not responding.',
        'Product stuck — not dispensing after payment.',
        'Screen frozen on payment or product selection.',
        'Coin/bill acceptor not working.',
      ],
    ),
    SupportIssueTypeOption(
      value: 'pricing_issue',
      label: 'Pricing & payments',
      icon: Icons.payments_outlined,
      description: 'Wrong prices, refunds, payment failures',
      templates: [
        'Wrong price showing on a slot.',
        'Customer charged but product did not dispense.',
        'Need help updating slot prices.',
      ],
    ),
    SupportIssueTypeOption(
      value: 'other_issue',
      label: 'Account & other',
      icon: Icons.help_outline_rounded,
      description: 'Wallet, access, advertising, general questions',
      templates: [
        'Need help with wallet balance or recharge.',
        'Question about team member access.',
        'Advertising or catalog setup help.',
      ],
    ),
  ];

  static const priorities = [
    SupportPriorityOption(
      value: 'low',
      label: 'Low',
      description: 'General question — no rush',
    ),
    SupportPriorityOption(
      value: 'normal',
      label: 'Normal',
      description: 'Standard support request',
    ),
    SupportPriorityOption(
      value: 'high',
      label: 'High',
      description: 'Machine down or losing sales',
    ),
    SupportPriorityOption(
      value: 'urgent',
      label: 'Urgent',
      description: 'Critical outage — needs immediate attention',
    ),
  ];

  static const quickReplies = [
    'Thanks for the update.',
    'Any progress on this ticket?',
    'The issue is still happening.',
    'You can reach me on this account email.',
  ];

  static SupportIssueTypeOption issueTypeFor(String? value) {
    return issueTypes.firstWhere(
      (option) => option.value == value,
      orElse: () => issueTypes.last,
    );
  }
}

abstract final class SupportTicketUi {
  static Color statusColor(String status) {
    return switch (status) {
      'unprocessed' => VmfsColors.warning,
      'processing' => VmfsColors.info,
      'completed' => VmfsColors.success,
      'closed' => VmfsColors.textSecondary,
      'cancelled' => VmfsColors.danger,
      _ => VmfsColors.textSecondary,
    };
  }

  static Color priorityColor(String priority) {
    return switch (priority) {
      'urgent' => VmfsColors.danger,
      'high' => VmfsColors.warning,
      'normal' => VmfsColors.info,
      'low' => VmfsColors.textSecondary,
      _ => VmfsColors.textSecondary,
    };
  }

  static String formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) {
      return '—';
    }

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return iso;
    }

    final local = parsed.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;

    if (sameDay) {
      return 'Today ${DateFormat.jm().format(local)}';
    }

    return DateFormat.yMMMd().add_jm().format(local);
  }

  static String relativeSubmitted(String? iso) {
    if (iso == null || iso.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return '';
    }

    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return DateFormat.yMMMd().format(parsed.toLocal());
  }
}
