bool _jsonBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }
  if (value is int) {
    return value != 0;
  }
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }

  return defaultValue;
}

class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.workOrderNumber,
    required this.status,
    required this.statusLabel,
    required this.priority,
    required this.priorityLabel,
    required this.issueType,
    required this.issueTypeLabel,
    required this.issueDescription,
    required this.submittedAt,
    required this.resolvedAt,
    required this.lastMessageAt,
    required this.machineName,
    required this.machineId,
    required this.liveChatActive,
    required this.isOpen,
    required this.messagesCount,
  });

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) {
    return SupportTicketSummary(
      id: json['id'] as int,
      workOrderNumber: json['work_order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'unprocessed',
      statusLabel: json['status_label'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'normal',
      priorityLabel: json['priority_label'] as String? ?? 'Normal',
      issueType: json['issue_type'] as String? ?? 'machine_issue',
      issueTypeLabel: json['issue_type_label'] as String? ?? 'Machine issue',
      issueDescription: json['issue_description'] as String? ?? '',
      submittedAt: json['submitted_at'] as String? ?? '',
      resolvedAt: json['resolved_at'] as String? ?? '',
      lastMessageAt: json['last_message_at'] as String? ?? '',
      machineName: json['machine_name'] as String? ?? '—',
      machineId: json['machine_id'] as int?,
      liveChatActive: _jsonBool(json['live_chat_active']),
      isOpen: _jsonBool(json['is_open'], defaultValue: true),
      messagesCount: json['messages_count'] as int? ?? 0,
    );
  }

  final int id;
  final String workOrderNumber;
  final String status;
  final String statusLabel;
  final String priority;
  final String priorityLabel;
  final String issueType;
  final String issueTypeLabel;
  final String issueDescription;
  final String submittedAt;
  final String resolvedAt;
  final String lastMessageAt;
  final String machineName;
  final int? machineId;
  final bool liveChatActive;
  final bool isOpen;
  final int messagesCount;
}

class SupportTicketMessage {
  const SupportTicketMessage({
    required this.id,
    required this.authorName,
    required this.body,
    required this.isStaffReply,
    required this.createdAt,
  });

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      id: json['id'] as int,
      authorName: json['author_name'] as String? ?? 'User',
      body: json['body'] as String? ?? '',
      isStaffReply: _jsonBool(json['is_staff_reply']),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final int id;
  final String authorName;
  final String body;
  final bool isStaffReply;
  final String createdAt;
}

class SupportTicketDetail {
  const SupportTicketDetail({
    required this.summary,
    required this.messages,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'] as Map<String, dynamic>;
    return SupportTicketDetail(
      summary: SupportTicketSummary.fromJson(ticketJson),
      messages: (ticketJson['messages'] as List<dynamic>? ?? [])
          .map((e) => SupportTicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final SupportTicketSummary summary;
  final List<SupportTicketMessage> messages;
}

class SupportLiveChatStatus {
  const SupportLiveChatStatus({
    required this.agentsAvailable,
    required this.agentsOnlineCount,
    required this.liveChatWaitingCount,
  });

  factory SupportLiveChatStatus.fromJson(Map<String, dynamic> json) {
    return SupportLiveChatStatus(
      agentsAvailable: _jsonBool(json['agents_available']),
      agentsOnlineCount: json['agents_online_count'] as int? ?? 0,
      liveChatWaitingCount: json['live_chat_waiting_count'] as int? ?? 0,
    );
  }

  final bool agentsAvailable;
  final int agentsOnlineCount;
  final int liveChatWaitingCount;
}
