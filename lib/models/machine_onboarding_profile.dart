import 'package:flutter/material.dart';

class MachineOnboardingPhase {
  const MachineOnboardingPhase({
    required this.key,
    required this.label,
    required this.stepNumbers,
  });

  factory MachineOnboardingPhase.fromJson(Map<String, dynamic> json) {
    final numbers = json['step_numbers'] as List<dynamic>? ?? [];

    return MachineOnboardingPhase(
      key: json['key'] as String? ?? 'setup',
      label: json['label'] as String? ?? 'Setup',
      stepNumbers: numbers.map((n) => (n as num).toInt()).toList(),
    );
  }

  final String key;
  final String label;
  final List<int> stepNumbers;
}

class MachineOnboardingProfile {
  const MachineOnboardingProfile({
    required this.profileKey,
    required this.machineNumber,
    required this.label,
    required this.description,
    required this.steps,
    this.manualUrl,
    this.manualLabel,
    this.stepCount,
    this.phases = const [],
  });

  factory MachineOnboardingProfile.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List<dynamic>? ?? [];
    final phasesJson = json['phases'] as List<dynamic>? ?? [];

    return MachineOnboardingProfile(
      profileKey: json['profile_key'] as String? ?? 'standard_vending',
      machineNumber: json['machine_number'] as String? ?? '',
      label: json['label'] as String? ?? 'VMFS kiosk',
      description: json['description'] as String? ?? '',
      manualUrl: json['manual_url'] as String?,
      manualLabel: json['manual_label'] as String?,
      stepCount: json['step_count'] as int? ?? stepsJson.length,
      phases: phasesJson
          .map((phase) => MachineOnboardingPhase.fromJson(phase as Map<String, dynamic>))
          .toList(),
      steps: stepsJson
          .map((step) => MachineOnboardingStep.fromJson(step as Map<String, dynamic>))
          .toList(),
    );
  }

  final String profileKey;
  final String machineNumber;
  final String label;
  final String description;
  final String? manualUrl;
  final String? manualLabel;
  final int? stepCount;
  final List<MachineOnboardingPhase> phases;
  final List<MachineOnboardingStep> steps;

  bool get isSmartCombo => profileKey == 'smart_combo_vmfs';
}

class MachineOnboardingStep {
  const MachineOnboardingStep({
    required this.title,
    required this.body,
    required this.icon,
    this.kicker,
    this.stepNumber,
  });

  factory MachineOnboardingStep.fromJson(Map<String, dynamic> json) {
    return MachineOnboardingStep(
      kicker: json['kicker'] as String?,
      stepNumber: json['step_number'] as int?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      icon: json['icon'] as String? ?? 'memory',
    );
  }

  final String? kicker;
  final int? stepNumber;
  final String title;
  final String body;
  final String icon;
}

IconData machineOnboardingIcon(String name) {
  return switch (name) {
    'local_shipping' => Icons.local_shipping_outlined,
    'build' => Icons.build_outlined,
    'key' => Icons.key_outlined,
    'power' => Icons.power_outlined,
    'straighten' => Icons.straighten,
    'check_circle' => Icons.check_circle_outline,
    'settings' => Icons.settings_outlined,
    'touch_app' => Icons.touch_app_outlined,
    'shopping_cart' => Icons.shopping_cart_outlined,
    'shopping_bag' => Icons.shopping_bag_outlined,
    'grid_view' => Icons.grid_view_rounded,
    'inventory' => Icons.inventory_2_outlined,
    'campaign' => Icons.campaign_outlined,
    'verified_user' => Icons.verified_user_outlined,
    'add_circle' => Icons.add_circle_outline,
    'tune' => Icons.tune,
    'analytics' => Icons.analytics_outlined,
    'link' => Icons.link_rounded,
    'groups' => Icons.groups_outlined,
    _ => Icons.memory_rounded,
  };
}
