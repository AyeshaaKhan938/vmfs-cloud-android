import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shell/app_shell.dart';
import '../../models/auth_user.dart';
import '../storage/onboarding_storage.dart';
import '../widgets/vmfs_tutorial_sheet.dart';
import 'tutorial_step.dart';

/// Single merged tour: app tabs + machine detail — shown once after first install.
List<TutorialStep> buildFirstInstallTutorialSteps(AuthUser? user) {
  bool can(String feature) => user?.canAccess(feature) ?? false;
  final canManageSlots = can('machine_slots');

  final steps = <TutorialStep>[
    const TutorialStep(
      kicker: 'Welcome',
      icon: Icons.waving_hand_outlined,
      title: 'Welcome to VMFS Cloud',
      body:
          'Thanks for installing the app. This one-time tour explains each tab — use Next and Previous to move at your own pace.',
      tabIndex: 0,
    ),
    const TutorialStep(
      kicker: 'Dashboard tab',
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      body: 'See today’s KPIs — machines online, orders, wallet balance, and quick health checks for your account.',
      tabIndex: 0,
    ),
    const TutorialStep(
      kicker: 'Machines tab',
      icon: Icons.memory_rounded,
      title: 'Machines list',
      body: 'Every card is a vending machine. Tap one to open slot inventory, stock levels, and restock tools.',
      tabIndex: 1,
    ),
  ];

  if (can('machines_create')) {
    steps.add(
      const TutorialStep(
        kicker: 'Machines tab',
        icon: Icons.add_circle_outline,
        title: 'Add a machine',
        body: 'Tap the orange + button next to search to register a new machine number, name, and location.',
        tabIndex: 1,
      ),
    );
  }

  steps.addAll([
    const TutorialStep(
      kicker: 'Inside a machine',
      icon: Icons.dashboard_customize_outlined,
      title: 'Machine overview',
      body:
          'After you tap a machine, see its name, number, and online status. Offline means the kiosk has not checked in recently.',
      tabIndex: 1,
    ),
    const TutorialStep(
      kicker: 'Inside a machine',
      icon: Icons.analytics_outlined,
      title: 'Stock summary',
      body: 'Total, Stocked, Low, Empty, and Fault counts help you spot problems before you open each slot.',
      tabIndex: 1,
    ),
  ]);

  if (canManageSlots) {
    steps.add(
      const TutorialStep(
        kicker: 'Inside a machine',
        icon: Icons.inventory_2_outlined,
        title: 'Restock all',
        body:
            'Use Restock all to set every slot’s current stock to its max capacity in one tap — great after a refill visit.',
        tabIndex: 1,
      ),
    );
  }

  steps.addAll([
    const TutorialStep(
      kicker: 'Inside a machine',
      icon: Icons.grid_view_rounded,
      title: 'Slots & products',
      body: 'Each row is a physical slot. Tap a slot to change product, price, stock, or fault status.',
      tabIndex: 1,
    ),
    TutorialStep(
      kicker: 'Inside a machine',
      icon: Icons.tune,
      title: 'Machine toolbar',
      body: canManageSlots
          ? 'Edit updates machine settings (groups, age verification, location). + adds a new slot to this machine.'
          : 'Edit opens machine settings such as groups, age verification, and location.',
      tabIndex: 1,
    ),
  ]);

  if (can('machines_create')) {
    steps.add(
      const TutorialStep(
        kicker: 'Machines tab',
        icon: Icons.checklist,
        title: 'Bulk edit machines',
        body: 'Use the checklist icon (or long-press a machine) to select several machines and update settings together.',
        tabIndex: 1,
      ),
    );
  }

  steps.add(
    const TutorialStep(
      kicker: 'Products tab',
      icon: Icons.shopping_bag_outlined,
      title: 'Product catalog',
      body: 'All sellable items live here. Tap a product to see where it is deployed across your machines.',
      tabIndex: 2,
    ),
  );

  if (can('products')) {
    steps.addAll([
      const TutorialStep(
        kicker: 'Products tab',
        icon: Icons.add_shopping_cart,
        title: 'Add a product',
        body: 'Tap + to create a product with cost, price, SKU, and age-verification settings if needed.',
        tabIndex: 2,
      ),
      const TutorialStep(
        kicker: 'Products tab',
        icon: Icons.edit_note_outlined,
        title: 'Bulk edit products',
        body: 'Use the checklist icon to select multiple products and update active status or age rules in one go.',
        tabIndex: 2,
      ),
    ]);
  }

  if (can('sales')) {
    steps.add(
      const TutorialStep(
        kicker: 'Orders tab',
        icon: Icons.receipt_long_outlined,
        title: 'Orders & sales',
        body: 'Review recent vending transactions, payment method, and amounts per machine.',
        tabIndex: 3,
      ),
    );
  }

  steps.add(
    const TutorialStep(
      kicker: 'More tab',
      icon: Icons.more_horiz,
      title: 'More menu',
      body: 'Reports, machine groups, finance groups, coupons, team, profile, and platform tools are organized here.',
      tabIndex: 4,
    ),
  );

  if (can('advertising')) {
    steps.addAll([
      const TutorialStep(
        kicker: 'More → Advertising',
        icon: Icons.campaign_outlined,
        title: 'Advertisements',
        body: 'Create ads with title, media path, cost, and tags under More → Advertisements.',
        tabIndex: 4,
      ),
      const TutorialStep(
        kicker: 'More → Advertising',
        icon: Icons.collections_outlined,
        title: 'Advertisement groups',
        body: 'Groups assign ads to kiosk screens: Screensaver, Top, and External screen slots — just like the web admin.',
        tabIndex: 4,
      ),
    ]);
  }

  if (can('reports')) {
    steps.add(
      const TutorialStep(
        kicker: 'More → Reports',
        icon: Icons.bar_chart_rounded,
        title: 'Reports',
        body: 'Open Sales & profit for a 30-day business summary from the More menu.',
        tabIndex: 4,
      ),
    );
  }

  if (can('wallet')) {
    steps.add(
      const TutorialStep(
        kicker: 'More → Wallet',
        icon: Icons.account_balance_wallet_outlined,
        title: 'Wallet & payments',
        body: 'Check balance, recharge, view payment gateway status, and renewal center from the More menu.',
        tabIndex: 4,
      ),
    );
  }

  steps.addAll([
    const TutorialStep(
      kicker: 'Support',
      icon: Icons.support_agent_outlined,
      title: 'Need help?',
      body: 'The support icon in the top bar opens tickets and chat with VMFS support anytime.',
      tabIndex: 0,
    ),
    const TutorialStep(
      kicker: 'You’re ready',
      icon: Icons.check_circle_outline,
      title: 'Tour complete',
      body: 'You’re all set. This tour won’t show again — explore the app and manage your machines.',
      tabIndex: 0,
    ),
  ]);

  return steps;
}

/// Shows the merged tutorial once per app install (first login after QR APK install).
Future<void> maybeShowFirstInstallTutorial(
  BuildContext context,
  WidgetRef ref, {
  required AuthUser? user,
}) async {
  final storage = ref.read(onboardingStorageProvider);

  if (await storage.hasCompletedFirstInstallTutorial()) {
    return;
  }
  if (!context.mounted) return;

  await showVmfsTutorialSheet(
    context,
    title: 'Getting started',
    steps: buildFirstInstallTutorialSteps(user),
    onStepVisible: (step) {
      if (step.tabIndex != null) {
        ref.read(appShellTabIndexProvider.notifier).state = step.tabIndex!;
      }
    },
    onFinished: storage.markFirstInstallTutorialCompleted,
  );
}
