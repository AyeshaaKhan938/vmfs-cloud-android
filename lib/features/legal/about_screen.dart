import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/legal/legal_content.dart';
import '../../core/theme/vmfs_colors.dart';
import '../../core/widgets/vmfs_logo.dart';
import 'legal_document_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: VmfsLogo(height: 88, showTitle: true)),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version ${AppConfig.appVersion} (${AppConfig.buildNumber})',
              style: const TextStyle(color: VmfsColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Official mobile companion for VMFS Cloud operators and administrators. '
            'Monitor machines, orders, products, wallet, and support tickets on the go.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(
                  title: 'Privacy policy',
                  body: LegalContent.privacyPolicy,
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(
                  title: 'Terms of service',
                  body: LegalContent.termsOfService,
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          Text(
            '© ${DateTime.now().year} ${LegalContent.companyName}. All rights reserved.',
            style: const TextStyle(fontSize: 12, color: VmfsColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
