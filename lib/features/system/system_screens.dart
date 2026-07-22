import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/vmfs_resource_list.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../../data/vmfs_repository.dart';
import '../auth/auth_provider.dart';

final ageVerificationSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchAgeVerificationSessions();
});

final refundsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchRefunds();
});

final pushRecordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchPushRecords();
});

final informationStorageProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchInformationStorageRecords();
});

final paymentGatewaysProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchPaymentGateways();
});

final renewalCenterProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(repositoryProvider).fetchRenewalCenter();
});

final brandSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(repositoryProvider).fetchBrandSettings();
});

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchAdminUsers();
});

class AgeVerificationSessionsScreen extends ConsumerWidget {
  const AgeVerificationSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(ageVerificationSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Age verification')),
      body: sessions.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(ageVerificationSessionsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(ageVerificationSessionsProvider),
          emptyTitle: 'No verification sessions',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text('Machine ${item['machine_no'] ?? '—'}'),
              subtitle: Text('${item['status_label'] ?? item['status']} · ${item['message'] ?? ''}'),
              trailing: VmfsStatusPill(
                label: item['age_verified'] == true ? 'Verified' : 'Pending',
                color: item['age_verified'] == true ? VmfsColors.success : VmfsColors.warning,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RefundRecordsScreen extends ConsumerWidget {
  const RefundRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refunds = ref.watch(refundsProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Refund records')),
      body: refunds.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(refundsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(refundsProvider),
          emptyTitle: 'No refunds',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['product_name']?.toString() ?? 'Refund'),
              subtitle: Text('Machine ${item['machine_no']} · ${item['payment_method']}'),
              trailing: Text(currency.format((item['prize_amount'] as num?)?.toDouble() ?? 0)),
            ),
          ),
        ),
      ),
    );
  }
}

class PushRecordsScreen extends ConsumerWidget {
  const PushRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(pushRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Push records')),
      body: records.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(pushRecordsProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(pushRecordsProvider),
          emptyTitle: 'No push records',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['message_title']?.toString() ?? 'Push'),
              subtitle: Text('${item['push_method_label'] ?? item['push_method']} · ${item['publisher_account'] ?? ''}'),
            ),
          ),
        ),
      ),
    );
  }
}

class InformationStorageScreen extends ConsumerWidget {
  const InformationStorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(informationStorageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Information storage')),
      body: records.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(informationStorageProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(informationStorageProvider),
          emptyTitle: 'No records',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['user_name']?.toString() ?? item['account']?.toString() ?? 'Record'),
              subtitle: Text('${item['collection_method_label'] ?? item['collection_method']} · ${item['email'] ?? ''}'),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentGatewaysScreen extends ConsumerWidget {
  const PaymentGatewaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateways = ref.watch(paymentGatewaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment gateways')),
      body: gateways.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(paymentGatewaysProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(paymentGatewaysProvider),
          emptyTitle: 'No gateways',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['title']?.toString() ?? item['slug']?.toString() ?? 'Gateway'),
              subtitle: Text(item['slug']?.toString() ?? ''),
              trailing: VmfsStatusPill(
                label: item['is_configured'] == true ? 'Configured' : 'Not set',
                color: item['is_configured'] == true ? VmfsColors.success : VmfsColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RenewalCenterScreen extends ConsumerWidget {
  const RenewalCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renewal = ref.watch(renewalCenterProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Renewal center')),
      body: renewal.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(renewalCenterProvider)),
        data: (data) {
          final equipment = (data['equipment'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final history = (data['history'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(renewalCenterProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Renewal list', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (equipment.isEmpty) const Text('No equipment due for renewal'),
                ...equipment.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item['device_name']?.toString() ?? 'Device'),
                      subtitle: Text('${item['equipment_number']} · expires ${item['expires_at'] ?? '—'}'),
                      trailing: Text(currency.format((item['yearly_renewal_amount'] as num?)?.toDouble() ?? 0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Renewal history', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (history.isEmpty) const Text('No renewal history'),
                ...history.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item['order_number']?.toString() ?? 'Renewal'),
                      subtitle: Text('${item['renewal_progress_label'] ?? item['renewal_progress']} · ${item['renew_equipment'] ?? ''}'),
                      trailing: Text(currency.format((item['amount'] as num?)?.toDouble() ?? 0)),
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

class BrandSettingsScreen extends ConsumerWidget {
  const BrandSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(brandSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Brand settings')),
      body: settings.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(brandSettingsProvider)),
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoTile(label: 'Webpage title', value: item['default_webpage_title']?.toString()),
            _InfoTile(label: 'Logo jump link', value: item['homepage_logo_jump_link']?.toString()),
            _InfoTile(label: 'Homepage logo', value: item['homepage_logo_path']?.toString()),
            _InfoTile(label: 'Homepage icon', value: item['homepage_icon_path']?.toString()),
            _InfoTile(label: 'Promotion image', value: item['homepage_promotion_image_path']?.toString()),
            _InfoTile(label: 'Background image', value: item['homepage_background_image_path']?.toString()),
            _InfoTile(label: 'Startup animation', value: item['device_startup_animation_path']?.toString()),
            _InfoTile(label: 'Footer HTML', value: item['homepage_footer_html']?.toString()),
          ],
        ),
      ),
    );
  }
}

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform users')),
      body: users.when(
        loading: () => const VmfsLoadingView(),
        error: (e, _) => VmfsErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (list) => buildVmfsResourceList(
          list: list,
          onRefresh: () async => ref.invalidate(adminUsersProvider),
          emptyTitle: 'No users',
          itemBuilder: (item) => Card(
            child: ListTile(
              title: Text(item['name']?.toString() ?? item['account']?.toString() ?? 'User'),
              subtitle: Text('${item['email']} · ${item['role_label'] ?? item['role']}'),
              trailing: VmfsStatusPill(
                label: item['is_enabled'] == true ? 'Active' : 'Disabled',
                color: item['is_enabled'] == true ? VmfsColors.success : VmfsColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value?.isNotEmpty == true ? value! : '—'),
      ),
    );
  }
}
