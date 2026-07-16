import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';

final teamMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchTeamMembers();
});

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team members')),
      body: members.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(teamMembersProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const VmfsEmptyState(
              title: 'No team members',
              message: 'Sub-accounts created on the web will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teamMembersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                    subtitle: Text('${member['email']}\n${member['role_label'] ?? ''}'),
                    isThreeLine: true,
                    trailing: VmfsStatusPill(
                      label: enabled ? 'Active' : 'Disabled',
                      color: enabled ? VmfsColors.success : VmfsColors.textSecondary,
                    ),
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
