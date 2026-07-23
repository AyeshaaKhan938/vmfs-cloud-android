import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/onboarding_storage.dart';
import '../widgets/vmfs_tutorial_sheet.dart';
import '../../models/machine_onboarding_profile.dart';
import 'tutorial_step.dart';

List<TutorialStep> tutorialStepsFromProfile(MachineOnboardingProfile profile) {
  return profile.steps
      .map(
        (step) => TutorialStep(
          kicker: step.kicker ?? profile.label,
          title: step.title,
          body: step.body,
          icon: machineOnboardingIcon(step.icon),
        ),
      )
      .toList();
}

Future<void> maybeShowMachineOnboarding({
  required BuildContext context,
  required WidgetRef ref,
  required int machineId,
  required MachineOnboardingProfile profile,
  bool force = false,
}) async {
  final storage = ref.read(onboardingStorageProvider);

  if (!force && await storage.hasCompletedMachineOnboarding(machineId, profile.profileKey)) {
    return;
  }
  if (!context.mounted || profile.steps.isEmpty) {
    return;
  }

  await showVmfsTutorialSheet(
    context,
    title: 'Setup: ${profile.label}',
    steps: tutorialStepsFromProfile(profile),
    onFinished: () => storage.markMachineOnboardingCompleted(machineId, profile.profileKey),
  );
}

Future<void> showMachineOnboarding({
  required BuildContext context,
  required WidgetRef ref,
  required int machineId,
  required MachineOnboardingProfile profile,
}) {
  return maybeShowMachineOnboarding(
    context: context,
    ref: ref,
    machineId: machineId,
    profile: profile,
    force: true,
  );
}
