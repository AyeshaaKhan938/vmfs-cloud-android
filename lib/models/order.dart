class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.productName,
    required this.machineNo,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int,
      productName: json['product_name'] as String? ?? 'Order',
      machineNo: json['machine_no'] as String? ?? '',
      amount: (json['prize_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final int id;
  final String productName;
  final String machineNo;
  final double amount;
  final String status;
  final String createdAt;
}

class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.paymentMethod,
    required this.completedAt,
    required this.slotLineNumber,
    required this.productSku,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'] as Map<String, dynamic>;
    return OrderDetail(
      summary: OrderSummary.fromJson(orderJson),
      paymentMethod: orderJson['payment_method'] as String? ?? '—',
      completedAt: orderJson['completed_at'] as String? ?? '',
      slotLineNumber: orderJson['slot_line_number'] as int?,
      productSku: orderJson['product_sku'] as String? ?? '',
    );
  }

  final OrderSummary summary;
  final String paymentMethod;
  final String completedAt;
  final int? slotLineNumber;
  final String productSku;
}
