class ReportsSummary {
  const ReportsSummary({
    required this.periodFrom,
    required this.periodTo,
    required this.machineCount,
    required this.totalOrders,
    required this.totalRevenue,
    required this.grossProfit,
    required this.profitMargin,
    required this.avgOrderValue,
    required this.activeMachines,
    required this.perUnit,
  });

  factory ReportsSummary.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};
    return ReportsSummary(
      periodFrom: period['from'] as String? ?? '',
      periodTo: period['to'] as String? ?? '',
      machineCount: json['machine_count'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0,
      avgOrderValue: (json['avg_order_value'] as num?)?.toDouble() ?? 0,
      activeMachines: json['active_machines'] as int? ?? 0,
      perUnit: (json['per_unit'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  final String periodFrom;
  final String periodTo;
  final int machineCount;
  final int totalOrders;
  final double totalRevenue;
  final double grossProfit;
  final double profitMargin;
  final double avgOrderValue;
  final int activeMachines;
  final List<Map<String, dynamic>> perUnit;
}
