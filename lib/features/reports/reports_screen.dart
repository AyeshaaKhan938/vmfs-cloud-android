import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../../models/reports.dart';
import '../auth/auth_provider.dart';

final reportsProvider = FutureProvider<ReportsSummary>((ref) async {
  return ref.watch(repositoryProvider).fetchReportsSummary();
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Sales & profit')),
      body: reports.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(reportsProvider)),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reportsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VmfsHeroBanner(
                  kicker: 'Reports',
                  title: '${stats.periodFrom} → ${stats.periodTo}',
                  subtitle: '${stats.machineCount} machines in scope',
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
                    VmfsStatCard(label: 'Orders', value: '${stats.totalOrders}', icon: Icons.receipt_long),
                    VmfsStatCard(label: 'Revenue', value: currency.format(stats.totalRevenue), color: VmfsColors.primaryDark),
                    VmfsStatCard(label: 'Gross profit', value: currency.format(stats.grossProfit), color: VmfsColors.success),
                    VmfsStatCard(label: 'Margin', value: '${stats.profitMargin.toStringAsFixed(1)}%', icon: Icons.percent),
                    VmfsStatCard(label: 'Avg order', value: currency.format(stats.avgOrderValue)),
                    VmfsStatCard(label: 'Active machines', value: '${stats.activeMachines}', icon: Icons.memory_rounded),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Per machine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...stats.perUnit.map(
                  (row) => Card(
                    child: ListTile(
                      title: Text(row['machine_name'] as String? ?? 'Machine'),
                      subtitle: Text('#${row['machine_number']} · ${row['total_orders']} orders'),
                      trailing: Text(currency.format((row['total_revenue'] as num?)?.toDouble() ?? 0)),
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
