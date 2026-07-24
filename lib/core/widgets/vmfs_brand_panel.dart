import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/vmfs_colors.dart';
import 'vmfs_logo.dart';

/// Matches the VMFS web admin login brand panel styling.
class VmfsLoginBrandPanel extends StatelessWidget {
  const VmfsLoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: VmfsColors.brandGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                padding: const EdgeInsets.all(8),
                child: const VmfsLogo(height: 40, compact: true),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ADMIN PORTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.2,
                        color: Color(0x80FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Vending Machine\nManagement Platform',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Machines, inventory, lottery, advertising, orders, wallet, and support — same cloud data as the web admin.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class VmfsAppBarTitle extends StatelessWidget {
  const VmfsAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: VmfsColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VmfsColors.border),
          ),
          padding: const EdgeInsets.all(4),
          child: const VmfsLogo(height: 24, compact: true),
        ),
        const SizedBox(width: 10),
        const Text(AppConfig.appName),
      ],
    );
  }
}
