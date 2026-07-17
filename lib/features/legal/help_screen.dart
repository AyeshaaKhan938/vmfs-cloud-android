import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal/legal_content.dart';
import '../../core/theme/vmfs_colors.dart';
import 'legal_document_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: VmfsColors.primaryDark),
              title: const Text('VMFS Cloud web admin'),
              subtitle: Text(LegalContent.websiteUrl),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launch(Uri.parse('${LegalContent.websiteUrl}/admin')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline, color: VmfsColors.primaryDark),
              title: const Text('Email support'),
              subtitle: Text(LegalContent.supportEmail),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launch(Uri.parse('mailto:${LegalContent.supportEmail}')),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Frequently asked questions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: VmfsColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in LegalContent.helpFaq)
            Card(
              child: ExpansionTile(
                title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item.answer, style: const TextStyle(height: 1.45)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalDocumentScreen(
                  title: 'Privacy policy',
                  body: LegalContent.privacyPolicy,
                ),
              ),
            ),
            child: const Text('Read privacy policy'),
          ),
        ],
      ),
    );
  }
}
