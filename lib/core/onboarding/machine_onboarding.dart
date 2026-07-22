import 'package:flutter/material.dart';

import '../storage/onboarding_storage.dart';
import '../widgets/vmfs_tutorial_sheet.dart';
import 'tutorial_step.dart';

List<TutorialStep> machineDetailOnboardingSteps({required bool canManageSlots}) {
  return [
    const TutorialStep(
      icon: Icons.dashboard_customize_outlined,
      title: 'Machine overview',
      body: 'See the machine name, number, and online status. Offline means the kiosk has not checked in recently.',
    ),
    const TutorialStep(
      icon: Icons.analytics_outlined,
      title: 'Stock summary',
      body: 'Total, Stocked, Low, Empty, and Fault counts help you spot problems before you open each slot.',
    ),
    if (canManageSlots)
      const TutorialStep(
        icon: Icons.inventory_2_outlined,
        title: 'Restock all',
        body: 'Use Restock all to set every slot’s current stock to its max capacity in one tap — great after a refill visit.',
      ),
    const TutorialStep(
      icon: Icons.grid_view_rounded,
      title: 'Slots & products',
      body: 'Each row is a physical slot. Tap a slot to change product, price, stock, or fault status.',
    ),
    TutorialStep(
      icon: Icons.tune,
      title: 'Toolbar actions',
      body: canManageSlots
          ? 'Edit updates machine settings (groups, age verification, location). + adds a new slot to this machine.'
          : 'Edit opens machine settings such as groups, age verification, and location.',
    ),
  ];
}

Future<void> maybeShowMachineDetailOnboarding(
  BuildContext context,
  OnboardingStorage storage, {
  required bool canManageSlots,
  bool force = false,
}) async {
  if (!context.mounted) return;
  if (!force && await storage.hasCompleted(OnboardingStorage.machineDetailTutorialKey)) return;
  if (!context.mounted) return;

  await showVmfsTutorialSheet(
    context,
    title: 'Inside a machine',
    steps: machineDetailOnboardingSteps(canManageSlots: canManageSlots),
    onFinished: () => storage.markCompleted(OnboardingStorage.machineDetailTutorialKey),
  );
}
