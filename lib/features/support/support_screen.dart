import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal/legal_content.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import '../legal/help_screen.dart';
import '../../models/support_ticket.dart';
import 'support_utils.dart';

final supportLiveChatStatusProvider = FutureProvider<SupportLiveChatStatus>((ref) async {
  return ref.watch(repositoryProvider).fetchSupportLiveChatStatus();
});

final supportTicketsProvider = FutureProvider<List<SupportTicketSummary>>((ref) async {
  return ref.watch(repositoryProvider).fetchSupportTickets();
});

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  SupportTicketFilter _filter = SupportTicketFilter.all;
  String _query = '';

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $uri')),
      );
    }
  }

  List<SupportTicketSummary> _filteredTickets(List<SupportTicketSummary> tickets) {
    final normalizedQuery = _query.trim().toLowerCase();

    return tickets.where((ticket) {
      final matchesFilter = switch (_filter) {
        SupportTicketFilter.all => true,
        SupportTicketFilter.open => ticket.isOpen,
        SupportTicketFilter.resolved => !ticket.isOpen,
      };

      if (!matchesFilter) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return ticket.workOrderNumber.toLowerCase().contains(normalizedQuery) ||
          ticket.machineName.toLowerCase().contains(normalizedQuery) ||
          ticket.issueDescription.toLowerCase().contains(normalizedQuery) ||
          ticket.issueTypeLabel.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
            ),
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Help & FAQ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/new'),
        backgroundColor: VmfsColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          'New ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: tickets.when(
        loading: () => const VmfsLoadingView(),
        error: (error, _) => VmfsErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(supportTicketsProvider),
        ),
        data: (items) {
          final filtered = _filteredTickets(items);
          final liveChatStatus = ref.watch(supportLiveChatStatusProvider);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(supportTicketsProvider);
              ref.invalidate(supportLiveChatStatusProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                liveChatStatus.when(
                  data: (status) => _LiveChatAvailabilityBanner(status: status),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'How can we help?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _SupportActionGrid(
                  onNewTicket: () => context.push('/support/new'),
                  onMachineIssue: () => context.push('/support/new?issue_type=machine_issue'),
                  onPricingIssue: () => context.push('/support/new?issue_type=pricing_issue'),
                  onEmailSupport: () => _launch(Uri.parse('mailto:${LegalContent.supportEmail}')),
                  onHelpFaq: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
                  ),
                  onWebAdmin: () => _launch(Uri.parse('${LegalContent.websiteUrl}/admin')),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your tickets',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${items.length} total',
                      style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tickets, machines, issues…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(() => _query = ''),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: SupportTicketFilter.values.map((filter) {
                    final selected = _filter == filter;
                    final label = switch (filter) {
                      SupportTicketFilter.all => 'All',
                      SupportTicketFilter.open => 'Open',
                      SupportTicketFilter.resolved => 'Resolved',
                    };
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = filter),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  VmfsEmptyState(
                    title: items.isEmpty ? 'No support tickets yet' : 'No matching tickets',
                    message: items.isEmpty
                        ? 'Choose an option above or create a ticket when a machine needs help.'
                        : 'Try another filter or search term.',
                    action: items.isEmpty
                        ? ElevatedButton(
                            onPressed: () => context.push('/support/new'),
                            child: const Text('Create first ticket'),
                          )
                        : null,
                  )
                else
                  ...filtered.map(
                    (ticket) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SupportTicketCard(
                        ticket: ticket,
                        onTap: () => context.push('/support/${ticket.id}'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LiveChatAvailabilityBanner extends StatelessWidget {
  const _LiveChatAvailabilityBanner({required this.status});

  final SupportLiveChatStatus status;

  @override
  Widget build(BuildContext context) {
    final online = status.agentsAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: online ? VmfsColors.success.withValues(alpha: 0.1) : VmfsColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: online ? VmfsColors.success.withValues(alpha: 0.35) : VmfsColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.circle : Icons.circle_outlined,
            color: online ? VmfsColors.success : VmfsColors.textSecondary,
            size: 12,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online
                      ? '${status.agentsOnlineCount} support agent${status.agentsOnlineCount == 1 ? '' : 's'} online'
                      : 'No live chat agents online',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  online
                      ? 'Request live chat on a ticket for real-time help from VMFS support.'
                      : 'You can still submit tickets — support will reply in the thread when available.',
                  style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportActionGrid extends StatelessWidget {
  const _SupportActionGrid({
    required this.onNewTicket,
    required this.onMachineIssue,
    required this.onPricingIssue,
    required this.onEmailSupport,
    required this.onHelpFaq,
    required this.onWebAdmin,
  });

  final VoidCallback onNewTicket;
  final VoidCallback onMachineIssue;
  final VoidCallback onPricingIssue;
  final VoidCallback onEmailSupport;
  final VoidCallback onHelpFaq;
  final VoidCallback onWebAdmin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 720 ? 3 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _SupportActionCard(
              icon: Icons.add_comment_rounded,
              title: 'New ticket',
              subtitle: 'Full form with priority',
              onTap: onNewTicket,
              emphasized: true,
            ),
            _SupportActionCard(
              icon: Icons.memory_rounded,
              title: 'Machine problem',
              subtitle: 'Offline, jam, screen',
              onTap: onMachineIssue,
            ),
            _SupportActionCard(
              icon: Icons.payments_outlined,
              title: 'Pricing & pay',
              subtitle: 'Wrong price, refunds',
              onTap: onPricingIssue,
            ),
            _SupportActionCard(
              icon: Icons.mail_outline,
              title: 'Email support',
              subtitle: LegalContent.supportEmail,
              onTap: onEmailSupport,
            ),
            _SupportActionCard(
              icon: Icons.quiz_outlined,
              title: 'Help & FAQ',
              subtitle: 'Common answers',
              onTap: onHelpFaq,
            ),
            _SupportActionCard(
              icon: Icons.language,
              title: 'Web admin',
              subtitle: 'Full cloud panel',
              onTap: onWebAdmin,
            ),
          ],
        );
      },
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized ? VmfsColors.primaryLight.withValues(alpha: 0.55) : VmfsColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emphasized ? VmfsColors.primary.withValues(alpha: 0.35) : VmfsColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: VmfsColors.primaryDark),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({required this.ticket, required this.onTap});

  final SupportTicketSummary ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final issue = SupportTicketCatalog.issueTypeFor(ticket.issueType);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: VmfsColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(issue.icon, color: VmfsColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.workOrderNumber,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ticket.machineName,
                          style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      VmfsStatusPill(
                        label: ticket.statusLabel,
                        color: SupportTicketUi.statusColor(ticket.status),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        SupportTicketUi.relativeSubmitted(ticket.submittedAt),
                        style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.issueDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  VmfsStatusPill(
                    label: ticket.issueTypeLabel,
                    color: VmfsColors.primaryDark,
                  ),
                  VmfsStatusPill(
                    label: ticket.priorityLabel,
                    color: SupportTicketUi.priorityColor(ticket.priority),
                  ),
                  if (ticket.liveChatActive)
                    const VmfsStatusPill(label: 'Live chat', color: VmfsColors.success),
                  if (ticket.messagesCount > 0)
                    VmfsStatusPill(
                      label: '${ticket.messagesCount} msg',
                      color: VmfsColors.textSecondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
