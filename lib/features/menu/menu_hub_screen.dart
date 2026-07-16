import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_widgets.dart';
import '../auth/auth_provider.dart';
import '../advertising/advertising_screens.dart';
import '../catalog/catalog_screens.dart';
import '../coupons/coupons_screens.dart';
import '../reports/reports_screen.dart';
import '../team/team_screen.dart';
import '../wallet/wallet_screen.dart';

class MenuHubScreen extends ConsumerWidget {
  const MenuHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final currency = NumberFormat.simpleCurrency();

    bool can(String feature) => user?.canAccess(feature) ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        VmfsHeroBanner(
          kicker: 'VMFS Cloud',
          title: user?.name ?? 'Account',
          subtitle: user?.email ?? '',
          trailing: Chip(label: Text(user?.roleLabel ?? '')),
        ),
        const SizedBox(height: 16),
        if (can('reports')) ...[
          _Section(
            title: 'Reports & analytics',
            children: [
              _MenuTile(
                icon: Icons.bar_chart_rounded,
                title: 'Sales & profit',
                subtitle: '30-day business summary',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
                ),
              ),
            ],
          ),
        ],
        if (can('machines_view')) ...[
          _Section(
            title: 'Machines',
            children: [
              _MenuTile(
                icon: Icons.map_outlined,
                title: 'Machine map',
                subtitle: 'Locations with coordinates',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MachineMapScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.folder_copy_outlined,
                title: 'Machine groups',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MachineGroupsScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.warning_amber_outlined,
                title: 'Alarms',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MachineAlarmsScreen()),
                ),
              ),
            ],
          ),
        ],
        if (can('products')) ...[
          _Section(
            title: 'Products',
            children: [
              _MenuTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProductCategoriesScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.local_offer_outlined,
                title: 'Product tags',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProductTagsScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.style_outlined,
                title: 'Product types',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProductTypesScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.confirmation_number_outlined,
                title: 'Coupons',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CouponsScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.casino_outlined,
                title: 'Lotteries',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LotteriesScreen()),
                ),
              ),
            ],
          ),
        ],
        if (can('advertising')) ...[
          _Section(
            title: 'Advertising',
            children: [
              _MenuTile(
                icon: Icons.campaign_outlined,
                title: 'Advertisements',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdvertisementsScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.collections_outlined,
                title: 'Advertisement groups',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdvertisementGroupsScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.label_outline,
                title: 'Advertisement tags',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdvertisementTagsScreen()),
                ),
              ),
            ],
          ),
        ],
        if (can('wallet')) ...[
          _Section(
            title: 'Wallet',
            children: [
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallet overview',
                subtitle: currency.format(user?.walletBalance ?? 0),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
                ),
              ),
            ],
          ),
        ],
        _Section(
          title: 'Account',
          children: [
            _MenuTile(
              icon: Icons.groups_outlined,
              title: 'Team members',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TeamScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Account ID'),
              subtitle: Text(user?.account ?? '—'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Timezone'),
              subtitle: Text(user?.timezone ?? 'UTC'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: VmfsColors.primaryDark,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: VmfsColors.primaryDark),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
