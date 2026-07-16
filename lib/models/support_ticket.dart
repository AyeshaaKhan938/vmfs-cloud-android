class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.workOrderNumber,
    required this.status,
    required this.statusLabel,
    required this.priority,
    required this.issueDescription,
    required this.submittedAt,
    required this.machineName,
  });

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) {
    return SupportTicketSummary(
      id: json['id'] as int,
      workOrderNumber: json['work_order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      statusLabel: json['status_label'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'normal',
      issueDescription: json['issue_description'] as String? ?? '',
      submittedAt: json['submitted_at'] as String? ?? '',
      machineName: json['machine_name'] as String? ?? '—',
    );
  }

  final int id;
  final String workOrderNumber;
  final String status;
  final String statusLabel;
  final String priority;
  final String issueDescription;
  final String submittedAt;
  final String machineName;
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
      isStaffReply: json['is_staff_reply'] as bool? ?? false,
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
    required this.liveChatActive,
    required this.messages,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'] as Map<String, dynamic>;
    return SupportTicketDetail(
      summary: SupportTicketSummary.fromJson(ticketJson),
      liveChatActive: ticketJson['live_chat_active'] as bool? ?? false,
      messages: (ticketJson['messages'] as List<dynamic>? ?? [])
          .map((e) => SupportTicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final SupportTicketSummary summary;
  final bool liveChatActive;
  final List<SupportTicketMessage> messages;
}
