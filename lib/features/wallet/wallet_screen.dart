import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../core/widgets/vmfs_interactive.dart';

final walletDetailProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(repositoryProvider).fetchWallet();
});

final rechargeRecordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(repositoryProvider).fetchRechargeRecords();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Future<void> _recharge(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: '100');
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wallet top-up'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (min \$100)'),
        ),
        actions: [
          VmfsTextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          VmfsFilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;

    try {
      await ref.read(repositoryProvider).rechargeWallet(amount);
      ref.invalidate(walletDetailProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Top-up request recorded.')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletDetailProvider);
    final records = ref.watch(rechargeRecordsProvider);
    final currency = NumberFormat.simpleCurrency();
    final canRecharge = ref.watch(authProvider.select((s) => s.user?.canAccess('wallet') ?? false));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          if (canRecharge)
            VmfsIconButton(
              tooltip: 'Top up',
              onPressed: () => _recharge(context, ref),
              icon: const Icon(Icons.add_card_outlined),
            ),
        ],
      ),
      body: wallet.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(walletDetailProvider)),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(walletDetailProvider);
              ref.invalidate(rechargeRecordsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VmfsHeroBanner(
                  kicker: 'Balance',
                  title: currency.format((data['balance'] as num?)?.toDouble() ?? 0),
                  subtitle: 'Available wallet funds',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Pending recharge'),
                        trailing: Text(currency.format((data['recharge_pending'] as num?)?.toDouble() ?? 0)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Accumulated recharge'),
                        trailing: Text(currency.format((data['accumulated_recharge'] as num?)?.toDouble() ?? 0)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Withdrawal pending'),
                        trailing: Text(currency.format((data['withdrawal_pending'] as num?)?.toDouble() ?? 0)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Recharge records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                records.when(
                  loading: () => const Padding(padding: EdgeInsets.all(24), child: VmfsLoadingView()),
                  error: (e, _) => Text(e.toString()),
                  data: (items) {
                    if (items.isEmpty) {
                      return const VmfsEmptyState(
                        title: 'No recharge records',
                        message: 'Wallet top-ups will appear here.',
                      );
                    }

                    return Column(
                      children: items
                          .map(
                            (record) => Card(
                              child: ListTile(
                                title: Text(currency.format((record['amount'] as num?)?.toDouble() ?? 0)),
                                subtitle: Text(
                                  '${record['service_type'] ?? 'Recharge'} · ${record['ordered_at'] ?? ''}',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
