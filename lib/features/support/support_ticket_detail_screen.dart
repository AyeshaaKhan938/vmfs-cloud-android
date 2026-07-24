import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import '../../models/support_ticket.dart';
import 'support_screen.dart';
import 'support_utils.dart';

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
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  var _sending = false;
  var _requestingLiveChat = false;
  var _lastMessageCount = 0;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _configurePolling(bool liveChatActive) {
    _pollTimer?.cancel();
    if (!liveChatActive) {
      return;
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(supportTicketDetailProvider(widget.ticketId));
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
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
      ref.invalidate(supportTicketsProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _requestLiveChat({required bool agentsAvailable}) async {
    if (_requestingLiveChat) {
      return;
    }

    if (!agentsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No support agents are online for live chat right now. Your ticket stays in the queue and support will reply here.',
          ),
        ),
      );
      return;
    }

    setState(() => _requestingLiveChat = true);
    try {
      await ref.read(repositoryProvider).requestSupportLiveChat(widget.ticketId);
      ref.invalidate(supportTicketDetailProvider(widget.ticketId));
      ref.invalidate(supportTicketsProvider);
      ref.invalidate(supportLiveChatStatusProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live chat connected. A VMFS support agent has been notified.')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _requestingLiveChat = false);
      }
    }
  }

  Future<void> _cancelTicket(SupportTicketSummary ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel ticket?'),
        content: Text(
          'Cancel ${ticket.workOrderNumber}? This removes the ticket from the open queue.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: VmfsColors.danger),
            child: const Text('Cancel ticket'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(repositoryProvider).deleteSupportTicket(widget.ticketId);
      ref.invalidate(supportTicketsProvider);
      if (!mounted) {
        return;
      }
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(supportTicketDetailProvider(widget.ticketId));
    final liveChatStatus = ref.watch(supportLiveChatStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.maybeWhen(data: (value) => value.summary.workOrderNumber, orElse: () => 'Support ticket')),
        actions: [
          if (detail.maybeWhen(data: (value) => value.summary.liveChatActive, orElse: () => false))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: VmfsStatusPill(label: 'Live', color: VmfsColors.success),
              ),
            ),
          IconButton(
            onPressed: () {
              ref.invalidate(supportTicketDetailProvider(widget.ticketId));
              ref.invalidate(supportLiveChatStatusProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: detail.when(
        loading: () => const VmfsLoadingView(),
        error: (error, _) => VmfsErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(supportTicketDetailProvider(widget.ticketId)),
        ),
        data: (ticket) {
          _configurePolling(ticket.summary.liveChatActive);
          if (ticket.messages.length != _lastMessageCount) {
            _lastMessageCount = ticket.messages.length;
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: _lastMessageCount > 1));
          }

          final summary = ticket.summary;
          final issue = SupportTicketCatalog.issueTypeFor(summary.issueType);
          final canCancel = summary.isOpen && summary.status == 'unprocessed';
          final agentsAvailable = liveChatStatus.maybeWhen(
            data: (status) => status.agentsAvailable,
            orElse: () => false,
          );
          final agentsOnlineCount = liveChatStatus.maybeWhen(
            data: (status) => status.agentsOnlineCount,
            orElse: () => 0,
          );

          return Column(
            children: [
              if (summary.liveChatActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: VmfsColors.success.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_rounded, color: VmfsColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live chat connected — stay on this screen. New replies appear automatically.',
                          style: TextStyle(color: VmfsColors.success.withValues(alpha: 0.95), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    VmfsHeroBanner(
                      kicker: summary.issueTypeLabel,
                      title: summary.machineName,
                      subtitle: summary.issueDescription,
                      leading: Icon(issue.icon, color: VmfsColors.primaryDark, size: 28),
                      trailing: VmfsStatusPill(
                        label: summary.statusLabel,
                        color: SupportTicketUi.statusColor(summary.status),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        VmfsStatusPill(
                          label: summary.priorityLabel,
                          color: SupportTicketUi.priorityColor(summary.priority),
                        ),
                        if (summary.liveChatActive)
                          const VmfsStatusPill(label: 'Live chat active', color: VmfsColors.success),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _MetaRow(label: 'Submitted', value: SupportTicketUi.formatDateTime(summary.submittedAt)),
                            if (summary.resolvedAt.isNotEmpty)
                              _MetaRow(label: 'Resolved', value: SupportTicketUi.formatDateTime(summary.resolvedAt)),
                            if (summary.lastMessageAt.isNotEmpty)
                              _MetaRow(label: 'Last update', value: SupportTicketUi.formatDateTime(summary.lastMessageAt)),
                            _MetaRow(label: 'Messages', value: '${ticket.messages.length}'),
                          ],
                        ),
                      ),
                    ),
                    if (summary.isOpen && !summary.liveChatActive) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    agentsAvailable ? Icons.circle : Icons.circle_outlined,
                                    size: 10,
                                    color: agentsAvailable ? VmfsColors.success : VmfsColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      agentsAvailable
                                          ? '$agentsOnlineCount agent${agentsOnlineCount == 1 ? '' : 's'} online for live chat'
                                          : 'No agents online — async support only',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _requestingLiveChat
                                    ? null
                                    : () => _requestLiveChat(agentsAvailable: agentsAvailable),
                                icon: _requestingLiveChat
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.videocam_rounded),
                                label: Text(_requestingLiveChat ? 'Connecting…' : 'Start live chat'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (canCancel) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _cancelTicket(summary),
                        icon: const Icon(Icons.cancel_outlined, color: VmfsColors.danger),
                        label: const Text('Cancel ticket', style: TextStyle(color: VmfsColors.danger)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Conversation',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (summary.liveChatActive)
                          Text(
                            'Live · 3s refresh',
                            style: TextStyle(color: VmfsColors.success.withValues(alpha: 0.9), fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ticket.messages.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No messages yet. Add details below or request live chat for faster help.',
                            style: TextStyle(color: VmfsColors.textSecondary, height: 1.4),
                          ),
                        ),
                      )
                    else
                      ...ticket.messages.map((message) => _MessageBubble(message: message)),
                    if (summary.isOpen) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Quick replies',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VmfsColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SupportTicketCatalog.quickReplies.map((reply) {
                          return ActionChip(
                            label: Text(reply, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _messageController.text = reply;
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (summary.isOpen)
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: const BoxDecoration(
                      color: VmfsColors.surface,
                      border: Border(top: BorderSide(color: VmfsColors.border)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: summary.liveChatActive
                                  ? 'Message support agent…'
                                  : 'Write a message to support…',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _sendMessage,
                          tooltip: 'Send message',
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: VmfsColors.primaryLight.withValues(alpha: 0.35),
                    child: Text(
                      'This ticket is ${summary.statusLabel.toLowerCase()}. Open a new ticket if you need more help.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: VmfsColors.textSecondary),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 13)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportTicketMessage message;

  @override
  Widget build(BuildContext context) {
    final isStaff = message.isStaffReply;

    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: isStaff ? VmfsColors.primaryLight : VmfsColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isStaff ? 4 : 14),
            bottomRight: Radius.circular(isStaff ? 14 : 4),
          ),
          border: Border.all(color: isStaff ? VmfsColors.primary.withValues(alpha: 0.15) : VmfsColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isStaff ? Icons.support_agent_rounded : Icons.person_outline,
                  size: 14,
                  color: isStaff ? VmfsColors.primaryDark : VmfsColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isStaff ? VmfsColors.primaryDark : VmfsColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  SupportTicketUi.formatDateTime(message.createdAt),
                  style: const TextStyle(fontSize: 11, color: VmfsColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message.body, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
