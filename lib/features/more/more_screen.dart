import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_provider.dart';

final walletProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(repositoryProvider).fetchWallet();
});

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final wallet = ref.watch(walletProvider);
    final currency = NumberFormat.simpleCurrency();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        VmfsHeroBanner(
          kicker: 'Account',
          title: auth.user?.name ?? 'User',
          subtitle: auth.user?.email ?? '',
          trailing: Chip(label: Text(auth.user?.roleLabel ?? '')),
        ),
        const SizedBox(height: 16),
        wallet.when(
          loading: () => const VmfsLoadingView(),
          error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(walletProvider)),
          data: (data) {
            final balance = (data['balance'] as num?)?.toDouble() ?? auth.user?.walletBalance ?? 0;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Wallet balance'),
                subtitle: Text(currency.format(balance)),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Account ID'),
                subtitle: Text(auth.user?.account ?? '—'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Timezone'),
                subtitle: Text(auth.user?.timezone ?? 'UTC'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 24),
        const Text(
          'VMFS Cloud Mobile mirrors your web panel. Reports, ads, coupons, and team members are coming in the next update.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
