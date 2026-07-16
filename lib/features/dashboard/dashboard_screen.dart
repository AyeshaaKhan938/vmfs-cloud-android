import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/dashboard.dart';
import '../auth/auth_provider.dart';

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(repositoryProvider).fetchDashboard();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final dashboard = ref.watch(dashboardProvider);
    final currency = NumberFormat.simpleCurrency();

    return dashboard.when(
      loading: () => const VmfsLoadingView(),
      error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(dashboardProvider)),
      data: (stats) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VmfsHeroBanner(
                kicker: stats.greeting,
                title: auth.user?.name ?? 'VMFS Cloud',
                subtitle: '${stats.roleLabel} · ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                trailing: Chip(label: Text(stats.roleLabel)),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  VmfsStatCard(
                    label: 'Machines',
                    value: '${stats.machineCount}',
                    icon: Icons.memory_rounded,
                    color: VmfsColors.info,
                  ),
                  VmfsStatCard(
                    label: 'Online now',
                    value: '${stats.onlineMachines}',
                    icon: Icons.wifi,
                    color: VmfsColors.success,
                  ),
                  VmfsStatCard(
                    label: "Today's orders",
                    value: '${stats.todayOrders}',
                    icon: Icons.shopping_cart_outlined,
                  ),
                  VmfsStatCard(
                    label: "Today's revenue",
                    value: currency.format(stats.todayRevenue),
                    icon: Icons.payments_outlined,
                    color: VmfsColors.primaryDark,
                  ),
                  VmfsStatCard(
                    label: 'Open tickets',
                    value: '${stats.openTickets}',
                    icon: Icons.support_agent_outlined,
                    color: VmfsColors.warning,
                  ),
                  VmfsStatCard(
                    label: 'Wallet',
                    value: currency.format(stats.walletBalance),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
