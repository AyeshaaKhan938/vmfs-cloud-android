import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../dashboard/dashboard_screen.dart';
import '../machines/machines_screen.dart';
import '../menu/menu_hub_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../support/support_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final Set<int> _loadedTabs = {0};
  final List<Widget?> _tabs = List<Widget?>.filled(5, null);

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

  void _onTabSelected(int index) {
    setState(() {
      _loadedTabs.add(index);
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
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
      body: IndexedStack(
        index: _index,
        children: List.generate(
          _tabsMeta.length,
          (index) => _loadedTabs.contains(index) ? _tabWidget(index) : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: [
          for (final tab in _tabsMeta)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
