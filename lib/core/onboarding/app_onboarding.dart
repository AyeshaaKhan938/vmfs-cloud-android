import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shell/app_shell.dart';
import '../../models/auth_user.dart';
import '../storage/onboarding_storage.dart';
import '../widgets/vmfs_tutorial_sheet.dart';
import 'tutorial_step.dart';

List<TutorialStep> buildAppGuidedTourSteps(AuthUser? user) {
  bool can(String feature) => user?.canAccess(feature) ?? false;

  final steps = <TutorialStep>[
    const TutorialStep(
      kicker: 'Welcome',
      icon: Icons.waving_hand_outlined,
      title: 'Welcome to VMFS Cloud',
      body: 'This guided tour walks through each tab — use Next and Previous to move at your own pace.',
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
      icon: Icons.grid_view_rounded,
      title: 'Slots & restock',
      body: 'Open any machine to see each slot’s product and stock. Use Restock all to fill every slot to max capacity.',
      tabIndex: 1,
    ),
    if (can('machines_create'))
      const TutorialStep(
        kicker: 'Machines tab',
        icon: Icons.checklist,
        title: 'Bulk edit machines',
        body: 'Use the checklist icon (or long-press a machine) to select several machines and update settings together.',
        tabIndex: 1,
      ),
    const TutorialStep(
      kicker: 'Products tab',
      icon: Icons.shopping_bag_outlined,
      title: 'Product catalog',
      body: 'All sellable items live here. Tap a product to see where it is deployed across your machines.',
      tabIndex: 2,
    ),
  ]);

  if (can('products')) {
    steps.add(
      const TutorialStep(
        kicker: 'Products tab',
        icon: Icons.add_shopping_cart,
        title: 'Add a product',
        body: 'Tap + to create a product with cost, price, SKU, and age-verification settings if needed.',
        tabIndex: 2,
      ),
    );
    steps.add(
      const TutorialStep(
        kicker: 'Products tab',
        icon: Icons.edit_note_outlined,
        title: 'Bulk edit products',
        body: 'Use the checklist icon to select multiple products and update active status or age rules in one go.',
        tabIndex: 2,
      ),
    );
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

  steps.add(
    const TutorialStep(
      kicker: 'Support',
      icon: Icons.support_agent_outlined,
      title: 'Need help?',
      body: 'The support icon in the top bar opens tickets and chat with VMFS support anytime.',
      tabIndex: 0,
    ),
  );

  steps.add(
    const TutorialStep(
      kicker: 'You’re ready',
      icon: Icons.check_circle_outline,
      title: 'Tour complete',
      body: 'Explore each tab on your own. Replay this tour anytime from More → Guided app tour.',
      tabIndex: 0,
    ),
  );

  return steps;
}

Future<void> showAppGuidedTour(
  BuildContext context,
  WidgetRef ref, {
  required AuthUser? user,
  bool force = false,
}) async {
  final storage = ref.read(onboardingStorageProvider);

  if (!force && await storage.hasCompleted(OnboardingStorage.appGuidedTourKey)) {
    return;
  }
  if (!context.mounted) return;

  await showVmfsTutorialSheet(
    context,
    title: 'Guided app tour',
    steps: buildAppGuidedTourSteps(user),
    onStepVisible: (step) {
      if (step.tabIndex != null) {
        ref.read(appShellTabIndexProvider.notifier).state = step.tabIndex!;
      }
    },
    onFinished: () => storage.markCompleted(OnboardingStorage.appGuidedTourKey),
  );
}
