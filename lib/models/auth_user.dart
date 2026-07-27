class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.account,
    required this.role,
    required this.roleLabel,
    required this.isEnabled,
    required this.features,
    required this.hasFullAccess,
    this.walletBalance,
    this.timezone,
    this.cloudNotificationEmail,
    this.preferredNotificationEmail,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      account: json['account'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      roleLabel: json['role_label'] as String? ?? 'Customer',
      isEnabled: json['is_enabled'] as bool? ?? true,
      features: (json['features'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      hasFullAccess: json['has_full_access'] as bool? ?? false,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble(),
      timezone: json['timezone'] as String?,
      cloudNotificationEmail: json['cloud_notification_email'] as String?,
      preferredNotificationEmail: json['preferred_notification_email'] as String?,
    );
  }

  final int id;
  final String name;
  final String email;
  final String account;
  final String role;
  final String roleLabel;
  final bool isEnabled;
  final List<String> features;
  final bool hasFullAccess;
  final double? walletBalance;
  final String? timezone;
  final String? cloudNotificationEmail;
  final String? preferredNotificationEmail;

  bool canAccess(String feature) => hasFullAccess || features.contains(feature);
}
