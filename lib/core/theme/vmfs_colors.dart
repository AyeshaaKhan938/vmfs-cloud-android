import 'package:flutter/material.dart';

/// VMFS brand blues — matches the login brand panel gradient.
abstract final class VmfsColors {
  static const Color brandNavy = Color(0xFF002244);
  static const Color brandBlue = Color(0xFF003D7A);
  static const Color brandBright = Color(0xFF0066CC);

  static const Color primary = brandBright;
  static const Color primaryDark = brandBlue;
  static const Color primaryLight = Color(0xFFE6F0FA);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEA580C);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0066CC);

  static const List<Color> brandGradient = [
    brandNavy,
    brandBlue,
    brandBright,
  ];
}
