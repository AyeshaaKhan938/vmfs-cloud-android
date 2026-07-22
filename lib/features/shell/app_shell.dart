import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/onboarding/app_onboarding.dart';
import '../../core/widgets/vmfs_brand_panel.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../machines/machines_screen.dart';
import '../menu/menu_hub_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../support/support_screen.dart';

final appShellTabIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final List<Widget?> _tabs = List<Widget?>.filled(5, null);
  bool _appTourQueued = false;

  static const _tabsMeta = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (icon: Icons.memory_rounded, label: 'Machines'),
    (icon: Icons.shopping_bag_outlined, label: 'Products'),
    (icon: Icons.receipt_long_outlined, label: 'Orders'),
    (icon: Icons.more_horiz, label: 'More'),
  ];

  Widget _tabWidget(int index) {
    return _tabs[index] ??= switch (index) {
      0 => const DashboardScreen(),
      1 => const MachinesScreen(),
      2 => const ProductsScreen(),
      3 => const OrdersScreen(),
      4 => const MenuHubScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _queueAppGuidedTour());
  }

  Future<void> _queueAppGuidedTour() async {
    if (_appTourQueued || !mounted) return;
    _appTourQueued = true;
    final user = ref.read(authProvider).user;
    await showAppGuidedTour(context, ref, user: user);
  }

  void _onTabSelected(int index) {
    if (ref.read(appShellTabIndexProvider) == index) return;
    ref.read(appShellTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(appShellTabIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: const VmfsAppBarTitle(),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
            ),
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'Support',
          ),
        ],
      ),
      body: _tabWidget(index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTabSelected,
        destinations: [
          for (final tab in _tabsMeta)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
