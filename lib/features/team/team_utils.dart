class TeamFeatureOption {
  const TeamFeatureOption({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

const teamFeatureOptions = <TeamFeatureOption>[
  TeamFeatureOption(
    key: 'machines_view',
    label: 'View machines',
    description: 'See the machine list and open slot inventory.',
  ),
  TeamFeatureOption(
    key: 'machines_create',
    label: 'Add machines',
    description: 'Register new vending machines on the account.',
  ),
  TeamFeatureOption(
    key: 'products',
    label: 'Manage products',
    description: 'Create and edit products in the catalog.',
  ),
  TeamFeatureOption(
    key: 'machine_slots',
    label: 'Assign products to slots',
    description: 'Assign products, prices, and stock to machine slots.',
  ),
  TeamFeatureOption(
    key: 'advertising',
    label: 'Advertising',
    description: 'Manage advertisements and ad groups.',
  ),
  TeamFeatureOption(
    key: 'sales',
    label: 'Sales & orders',
    description: 'View orders, refunds, and sales history.',
  ),
  TeamFeatureOption(
    key: 'reports',
    label: 'Reports & analytics',
    description: 'Open income and business analytics reports.',
  ),
  TeamFeatureOption(
    key: 'wallet',
    label: 'Wallet & payments',
    description: 'Access wallet balance, recharge, and payment settings.',
  ),
  TeamFeatureOption(
    key: 'work_orders',
    label: 'Support tickets',
    description: 'Submit support tickets, track status, and request live chat.',
  ),
];
