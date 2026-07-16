import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../../models/support_ticket.dart';
import '../auth/auth_provider.dart';

final supportTicketDetailProvider = FutureProvider.family<SupportTicketDetail, int>((ref, id) async {
  return ref.watch(repositoryProvider).fetchSupportTicket(id);
});

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends ConsumerState<SupportTicketDetailScreen> {
  final _messageController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(repositoryProvider).sendSupportMessage(ticketId: widget.ticketId, body: body);
      _messageController.clear();
      ref.invalidate(supportTicketDetailProvider(widget.ticketId));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(supportTicketDetailProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(title: const Text('Support ticket')),
      body: detail.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(supportTicketDetailProvider(widget.ticketId)),
        ),
        data: (ticket) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    VmfsHeroBanner(
                      kicker: ticket.summary.workOrderNumber,
                      title: ticket.summary.machineName,
                      subtitle: ticket.summary.issueDescription,
                      trailing: VmfsStatusPill(label: ticket.summary.statusLabel, color: VmfsColors.warning),
                    ),
                    if (ticket.liveChatActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: VmfsStatusPill(label: 'Live chat active', color: VmfsColors.success),
                      ),
                    const SizedBox(height: 16),
                    const Text('Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...ticket.messages.map(
                      (message) => Align(
                        alignment: message.isStaffReply ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                          decoration: BoxDecoration(
                            color: message.isStaffReply ? VmfsColors.primaryLight : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(message.body),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(hintText: 'Reply to support...'),
                          minLines: 1,
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendMessage,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
