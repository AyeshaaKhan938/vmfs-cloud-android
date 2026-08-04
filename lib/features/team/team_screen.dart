import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import 'team_member_form_screen.dart';
import 'team_utils.dart';
import '../../core/router/vmfs_page_transitions.dart';
import '../../core/widgets/vmfs_interactive.dart';

final teamMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchTeamMembers();
});

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Map<String, dynamic>? member}) async {
    final saved = await Navigator.of(context).push<bool>(vmfsSlideRoute<bool>(builder: (_) => TeamMemberFormScreen(member: member)));

    if (saved == true) {
      ref.invalidate(teamMembersProvider);
    }
  }

  String _featureSummary(Map<String, dynamic> member) {
    final enabled = (member['features'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet();
    if (enabled.isEmpty) {
      return 'No feature access assigned';
    }

    final labels = teamFeatureOptions
        .where((option) => enabled.contains(option.key))
        .map((option) => option.label)
        .toList();

    if (labels.length <= 2) {
      return labels.join(', ');
    }

    return '${labels.take(2).join(', ')} +${labels.length - 2} more';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider);
    final canManage = ref.watch(authProvider).user?.canManageTeamMembers ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team members'),
        actions: [
          if (canManage)
            VmfsIconButton(
              tooltip: 'Add team member',
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _openForm(context, ref),
            ),
        ],
      ),
      floatingActionButton: canManage
          ? VmfsFloatingActionButton.extended(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add member'),
            )
          : null,
      body: members.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(teamMembersProvider)),
        data: (items) {
          if (items.isEmpty) {
            return VmfsEmptyState(
              title: 'No team members',
              message: canManage
                  ? 'Create sub-accounts and choose which features each person can use.'
                  : 'Your account owner manages team members.',
              action: canManage
                  ? VmfsFilledButton.icon(
                      onPressed: () => _openForm(context, ref),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add team member'),
                    )
                  : null,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teamMembersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final member = items[index];
                final enabled = member['is_enabled'] as bool? ?? true;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: VmfsColors.primaryLight,
                      child: Text((member['name'] as String? ?? '?').substring(0, 1).toUpperCase()),
                    ),
                    title: Text(member['name'] as String? ?? 'Member'),
                    subtitle: Text(
                      '${member['account'] ?? member['email']}\n${_featureSummary(member)}',
                    ),
                    isThreeLine: true,
                    trailing: VmfsStatusPill(
                      label: enabled ? 'Active' : 'Disabled',
                      color: enabled ? VmfsColors.success : VmfsColors.textSecondary,
                    ),
                    onTap: canManage ? () => _openForm(context, ref, member: member) : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
