class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.isActive,
    required this.machineCount,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Product',
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      machineCount: json['machine_count'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String sku;
  final double price;
  final bool isActive;
  final int machineCount;
}

class ProductDeployment {
  const ProductDeployment({
    required this.machineName,
    required this.machineNumber,
    required this.lineNumber,
    required this.currentStock,
    required this.price,
  });

  factory ProductDeployment.fromJson(Map<String, dynamic> json) {
    return ProductDeployment(
      machineName: json['machine_name'] as String? ?? '—',
      machineNumber: json['machine_number'] as String? ?? '',
      lineNumber: json['line_number'] as int? ?? 0,
      currentStock: json['current_stock'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  final String machineName;
  final String machineNumber;
  final int lineNumber;
  final int currentStock;
  final double price;
}

class ProductDetail {
  const ProductDetail({
    required this.summary,
    required this.description,
    required this.categoryName,
    required this.tagName,
    required this.cost,
    required this.requiresAgeVerification,
    required this.deployments,
    required this.lotteries,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>;
    return ProductDetail(
      summary: ProductSummary.fromJson(productJson),
      description: productJson['description'] as String? ?? '',
      categoryName: productJson['category_name'] as String? ?? '—',
      tagName: productJson['tag_name'] as String? ?? '—',
      cost: (productJson['cost'] as num?)?.toDouble() ?? 0,
      requiresAgeVerification: productJson['requires_age_verification'] as bool? ?? false,
      deployments: (json['deployments'] as List<dynamic>? ?? [])
          .map((e) => ProductDeployment.fromJson(e as Map<String, dynamic>))
          .toList(),
      lotteries: (json['lotteries'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  final ProductSummary summary;
  final String description;
  final String categoryName;
  final String tagName;
  final double cost;
  final bool requiresAgeVerification;
  final List<ProductDeployment> deployments;
  final List<Map<String, dynamic>> lotteries;
}
