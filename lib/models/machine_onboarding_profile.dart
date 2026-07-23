import 'package:flutter/material.dart';

class MachineOnboardingProfile {
  const MachineOnboardingProfile({
    required this.profileKey,
    required this.machineNumber,
    required this.label,
    required this.description,
    required this.steps,
  });

  factory MachineOnboardingProfile.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List<dynamic>? ?? [];

    return MachineOnboardingProfile(
      profileKey: json['profile_key'] as String? ?? 'standard_vending',
      machineNumber: json['machine_number'] as String? ?? '',
      label: json['label'] as String? ?? 'VMFS kiosk',
      description: json['description'] as String? ?? '',
      steps: stepsJson
          .map((step) => MachineOnboardingStep.fromJson(step as Map<String, dynamic>))
          .toList(),
    );
  }

  final String profileKey;
  final String machineNumber;
  final String label;
  final String description;
  final List<MachineOnboardingStep> steps;
}

class MachineOnboardingStep {
  const MachineOnboardingStep({
    required this.title,
    required this.body,
    required this.icon,
    this.kicker,
  });

  factory MachineOnboardingStep.fromJson(Map<String, dynamic> json) {
    return MachineOnboardingStep(
      kicker: json['kicker'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      icon: json['icon'] as String? ?? 'memory',
    );
  }

  final String? kicker;
  final String title;
  final String body;
  final String icon;
}

IconData machineOnboardingIcon(String name) {
  return switch (name) {
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
