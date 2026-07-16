class DashboardStats {
  const DashboardStats({
    required this.greeting,
    required this.roleLabel,
    required this.machineCount,
    required this.onlineMachines,
    required this.todayOrders,
    required this.todayRevenue,
    required this.openTickets,
    required this.walletBalance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      greeting: json['greeting'] as String? ?? 'Welcome',
      roleLabel: json['role_label'] as String? ?? 'Customer',
      machineCount: json['machine_count'] as int? ?? 0,
      onlineMachines: json['online_machines'] as int? ?? 0,
      todayOrders: json['today_orders'] as int? ?? 0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0,
      openTickets: json['open_tickets'] as int? ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
    );
  }

  final String greeting;
  final String roleLabel;
  final int machineCount;
  final int onlineMachines;
  final int todayOrders;
  final double todayRevenue;
  final int openTickets;
  final double walletBalance;
}
