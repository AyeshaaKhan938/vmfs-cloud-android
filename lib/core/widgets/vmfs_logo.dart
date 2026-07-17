import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/vmfs_colors.dart';

class VmfsLogo extends StatelessWidget {
  const VmfsLogo({
    super.key,
    this.height = 72,
    this.showTitle = false,
    this.showSubtitle = false,
    this.compact = false,
  });

  static const String assetPath = 'assets/images/vmfs-logo.jpg';

  final double height;
  final bool showTitle;
  final bool showSubtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Image.asset(
        assetPath,
        height: height,
        width: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallbackIcon(height),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallbackIcon(height),
        ),
        if (showTitle) ...[
          const SizedBox(height: 12),
          Text(
            AppConfig.appName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            AppConfig.appTagline,
            style: const TextStyle(color: VmfsColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _fallbackIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: VmfsColors.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: VmfsColors.border),
      ),
      child: Icon(Icons.cloud_queue_rounded, color: VmfsColors.primaryDark, size: size * 0.5),
    );
  }
}
