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

  static const _tabs = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (icon: Icons.memory_rounded, label: 'Machines'),
    (icon: Icons.shopping_bag_outlined, label: 'Products'),
    (icon: Icons.receipt_long_outlined, label: 'Orders'),
    (icon: Icons.more_horiz, label: 'More'),
  ];

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
        children: const [
          DashboardScreen(),
          MachinesScreen(),
          ProductsScreen(),
          OrdersScreen(),
          MenuHubScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
