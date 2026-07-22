import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_logo.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../models/dashboard.dart';
import '../auth/auth_provider.dart';
import '../shell/app_shell.dart';
import '../support/support_screen.dart';
import '../wallet/wallet_screen.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final auth = ref.read(authProvider);
  if (!auth.sessionReady || !auth.isAuthenticated) {
    throw Exception('Session is not ready.');
  }

  try {
    return await ref.read(repositoryProvider).fetchDashboard();
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await ref.read(authProvider.notifier).handleUnauthorized();
    }
    rethrow;
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isLoading || (auth.isAuthenticated && !auth.sessionReady)) {
      return const VmfsLoadingView();
    }

    final userName = auth.user?.name;
    final dashboard = ref.watch(dashboardProvider);
    final currency = NumberFormat.simpleCurrency();

    return dashboard.when(
      loading: () => const VmfsLoadingView(),
      error: (e, _) {
        final message = e is ApiException && e.statusCode == 401
            ? 'Session expired. Please sign in again.'
            : e.toString();
        return VmfsErrorView(
          message: message,
          onRetry: () => ref.invalidate(dashboardProvider),
        );
      },
      data: (stats) {
        void goToTab(int index) {
          ref.read(appShellTabIndexProvider.notifier).state = index;
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VmfsHeroBanner(
                kicker: stats.greeting,
                title: userName ?? 'VMFS Cloud',
                subtitle: '${stats.roleLabel} · ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                trailing: Chip(label: Text(stats.roleLabel)),
                leading: const VmfsLogo(height: 44, compact: true),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                children: [
                  VmfsStatCard(
                    label: 'Machines',
                    value: '${stats.machineCount}',
                    icon: Icons.memory_rounded,
                    color: VmfsColors.info,
                    onTap: () => goToTab(1),
                  ),
                  VmfsStatCard(
                    label: 'Online now',
                    value: '${stats.onlineMachines}',
                    icon: Icons.wifi,
                    color: VmfsColors.success,
                    onTap: () => goToTab(1),
                  ),
                  VmfsStatCard(
                    label: "Today's orders",
                    value: '${stats.todayOrders}',
                    icon: Icons.shopping_cart_outlined,
                    onTap: () => goToTab(3),
                  ),
                  VmfsStatCard(
                    label: "Today's revenue",
                    value: currency.format(stats.todayRevenue),
                    icon: Icons.payments_outlined,
                    color: VmfsColors.primaryDark,
                    onTap: () => goToTab(3),
                  ),
                  VmfsStatCard(
                    label: 'Open tickets',
                    value: '${stats.openTickets}',
                    icon: Icons.support_agent_outlined,
                    color: VmfsColors.warning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
                    ),
                  ),
                  VmfsStatCard(
                    label: 'Wallet',
                    value: currency.format(stats.walletBalance),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
                    ),
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
