class MachineSummary {
  const MachineSummary({
    required this.id,
    required this.machineName,
    required this.machineNumber,
    required this.isEnabled,
    required this.isOnline,
    required this.slotCount,
    required this.address,
  });

  factory MachineSummary.fromJson(Map<String, dynamic> json) {
    return MachineSummary(
      id: json['id'] as int,
      machineName: json['machine_name'] as String? ?? 'Machine',
      machineNumber: json['machine_number'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      slotCount: json['slot_count'] as int? ?? 0,
      address: json['detailed_address'] as String? ?? '',
    );
  }

  final int id;
  final String machineName;
  final String machineNumber;
  final bool isEnabled;
  final bool isOnline;
  final int slotCount;
  final String address;
}

class MachineDetail extends MachineSummary {
  const MachineDetail({
    required super.id,
    required super.machineName,
    required super.machineNumber,
    required super.isEnabled,
    required super.isOnline,
    required super.slotCount,
    required super.address,
    required this.groupName,
    required this.ownerAccount,
    required this.lastSeenAt,
    required this.slotSummary,
    required this.slots,
  });

  factory MachineDetail.fromJson(Map<String, dynamic> json) {
    final summary = json['machine'] as Map<String, dynamic>? ?? json;
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    final slotSummary = json['slot_summary'] as Map<String, dynamic>? ?? {};

    return MachineDetail(
      id: summary['id'] as int,
      machineName: summary['machine_name'] as String? ?? 'Machine',
      machineNumber: summary['machine_number'] as String? ?? '',
      isEnabled: summary['is_enabled'] as bool? ?? false,
      isOnline: summary['is_online'] as bool? ?? false,
      slotCount: slotSummary['total'] as int? ?? slotsJson.length,
      address: summary['detailed_address'] as String? ?? '',
      groupName: summary['group_name'] as String? ?? '—',
      ownerAccount: summary['owner_account'] as String? ?? '—',
      lastSeenAt: summary['last_seen_at'] as String?,
      slotSummary: SlotSummary.fromJson(slotSummary),
      slots: slotsJson.map((e) => MachineSlot.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  final String groupName;
  final String ownerAccount;
  final String? lastSeenAt;
  final SlotSummary slotSummary;
  final List<MachineSlot> slots;
}

class SlotSummary {
  const SlotSummary({
    required this.total,
    required this.stocked,
    required this.lowStock,
    required this.empty,
    required this.fault,
  });

  factory SlotSummary.fromJson(Map<String, dynamic> json) {
    return SlotSummary(
      total: json['total'] as int? ?? 0,
      stocked: json['stocked'] as int? ?? 0,
      lowStock: json['low_stock'] as int? ?? 0,
      empty: json['empty'] as int? ?? 0,
      fault: json['fault'] as int? ?? 0,
    );
  }

  final int total;
  final int stocked;
  final int lowStock;
  final int empty;
  final int fault;
}

class MachineSlot {
  const MachineSlot({
    required this.id,
    required this.lineNumber,
    required this.productName,
    required this.currentStock,
    required this.maxStock,
    required this.price,
    required this.status,
  });

  factory MachineSlot.fromJson(Map<String, dynamic> json) {
    return MachineSlot(
      id: json['id'] as int,
      lineNumber: json['line_number'] as int? ?? 0,
      productName: json['product_name'] as String? ?? '— empty —',
      currentStock: json['current_stock'] as int? ?? 0,
      maxStock: json['max_stock'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'ok',
    );
  }

  final int id;
  final int lineNumber;
  final String productName;
  final int currentStock;
  final int maxStock;
  final double price;
  final String status;
}
