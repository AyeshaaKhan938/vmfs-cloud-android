import 'package:flutter/material.dart';

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    required this.icon,
    this.kicker,
    this.tabIndex,
  });

  final String? kicker;
  final String title;
  final String body;
  final IconData icon;

  /// Switches the bottom navigation tab while this slide is visible.
  final int? tabIndex;
}
