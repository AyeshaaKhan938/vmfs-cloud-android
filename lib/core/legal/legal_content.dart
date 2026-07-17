abstract final class LegalContent {
  static const String companyName = 'VMFS USA';
  static const String supportEmail = 'support@vmfsusa.com';
  static const String websiteUrl = 'https://cloud.vmfsusa.com';
  static const String privacyPolicyUrl = 'https://cloud.vmfsusa.com/privacy';
  static const String termsUrl = 'https://cloud.vmfsusa.com/terms';

  static const String privacyPolicy = '''
Last updated: July 2026

$companyName ("we", "us") operates the VMFS Cloud mobile application for authorized vending operators and administrators.

Information we collect
• Account credentials (email) to authenticate you against your existing VMFS Cloud account.
• Business data you access through the app (machines, orders, products, support tickets) as permitted by your role.
• Device/network data needed to deliver the service (IP address, app version, crash diagnostics if enabled by your device OS).

How we use information
• To sign you in and keep your session secure.
• To display operational data from your VMFS Cloud account.
• To respond to support requests you submit through the app.

Data storage & security
• Authentication tokens are stored securely on your device.
• Data is transmitted over HTTPS to $websiteUrl.
• We do not sell personal information.

Account deletion
• This app uses accounts created in VMFS Cloud. To close an account or delete personal data, contact $supportEmail or your VMFS administrator.

Contact
• Email: $supportEmail
• Web: $websiteUrl
''';

  static const String termsOfService = '''
Last updated: July 2026

By using the VMFS Cloud mobile app you agree to these terms.

Eligibility
• You must have an authorized VMFS Cloud administrator or operator account.
• You are responsible for keeping your login credentials confidential.

Permitted use
• Use the app only for legitimate VMFS business operations.
• Do not attempt to bypass security, scrape data, or interfere with service availability.

Service availability
• The app depends on connectivity to $websiteUrl.
• Features may change as the VMFS Cloud platform evolves.

Disclaimer
• Operational data is provided "as is" for business monitoring; verify critical decisions using primary VMFS Cloud systems when required.

Termination
• We may suspend access for policy violations or at the request of your organization administrator.

Contact
• $supportEmail
''';

  static const List<({String question, String answer})> helpFaq = [
    (
      question: 'How do I sign in?',
      answer:
          'Use the same email and password as the VMFS Cloud web admin at cloud.vmfsusa.com/admin. This app does not create new accounts.',
    ),
    (
      question: 'Why do I see "Cannot reach VMFS Cloud"?',
      answer:
          'Check your internet connection and confirm cloud.vmfsusa.com opens in your phone browser. The server must be online and reachable.',
    ),
    (
      question: 'Who can see my data?',
      answer:
          'You only see machines, orders, and reports linked to your VMFS account role. Access is enforced by the VMFS Cloud backend.',
    ),
    (
      question: 'How do I get support?',
      answer:
          'Open Support from the top bar to view or create tickets. You can also email support@vmfsusa.com.',
    ),
    (
      question: 'How do I delete my account?',
      answer:
          'Contact your VMFS administrator or email support@vmfsusa.com. Account removal is handled through VMFS Cloud, not inside this app.',
    ),
  ];
}
