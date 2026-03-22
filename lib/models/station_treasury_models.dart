double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '0') ?? 0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;

  try {
    return DateTime.parse(value.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

class StationTreasuryStationInfo {
  final String id;
  final String stationName;
  final String stationCode;

  const StationTreasuryStationInfo({
    required this.id,
    required this.stationName,
    required this.stationCode,
  });

  factory StationTreasuryStationInfo.fromJson(Map<String, dynamic> json) {
    return StationTreasuryStationInfo(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? '',
      stationCode: json['stationCode']?.toString() ?? '',
    );
  }
}

class StationTreasurySummary {
  final int closedSessionsCount;
  final int vouchersCount;
  final double cashSales;
  final double cardSales;
  final double madaSales;
  final double otherSales;
  final double networkSales;
  final double salesExpenses;
  final double disbursedCash;
  final double cashBalance;
  final double networkBalance;
  final double totalBalance;
  final double totalSales;
  final DateTime? lastSessionAt;
  final DateTime? lastVoucherAt;
  final DateTime? computedAt;

  const StationTreasurySummary({
    required this.closedSessionsCount,
    required this.vouchersCount,
    required this.cashSales,
    required this.cardSales,
    required this.madaSales,
    required this.otherSales,
    required this.networkSales,
    required this.salesExpenses,
    required this.disbursedCash,
    required this.cashBalance,
    required this.networkBalance,
    required this.totalBalance,
    required this.totalSales,
    this.lastSessionAt,
    this.lastVoucherAt,
    this.computedAt,
  });

  factory StationTreasurySummary.fromJson(Map<String, dynamic> json) {
    return StationTreasurySummary(
      closedSessionsCount: _asInt(json['closedSessionsCount']),
      vouchersCount: _asInt(json['vouchersCount']),
      cashSales: _asDouble(json['cashSales']),
      cardSales: _asDouble(json['cardSales']),
      madaSales: _asDouble(json['madaSales']),
      otherSales: _asDouble(json['otherSales']),
      networkSales: _asDouble(json['networkSales']),
      salesExpenses: _asDouble(json['salesExpenses']),
      disbursedCash: _asDouble(json['disbursedCash']),
      cashBalance: _asDouble(json['cashBalance']),
      networkBalance: _asDouble(json['networkBalance']),
      totalBalance: _asDouble(json['totalBalance']),
      totalSales: _asDouble(json['totalSales']),
      lastSessionAt: _asDateTime(json['lastSessionAt']),
      lastVoucherAt: _asDateTime(json['lastVoucherAt']),
      computedAt: _asDateTime(json['computedAt']),
    );
  }
}

class StationTreasuryOverview {
  final StationTreasuryStationInfo station;
  final StationTreasurySummary summary;

  const StationTreasuryOverview({
    required this.station,
    required this.summary,
  });

  factory StationTreasuryOverview.fromJson(Map<String, dynamic> json) {
    return StationTreasuryOverview(
      station: StationTreasuryStationInfo.fromJson(
        Map<String, dynamic>.from(json['station'] ?? const {}),
      ),
      summary: StationTreasurySummary.fromJson(
        Map<String, dynamic>.from(json['summary'] ?? const {}),
      ),
    );
  }
}

class StationTreasuryVoucherRecord {
  final String id;
  final String voucherNumber;
  final String stationId;
  final String stationName;
  final String stationCode;
  final String recipientName;
  final double amount;
  final String notes;
  final String sourceType;
  final String status;
  final double cashBalanceBefore;
  final double cashBalanceAfter;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StationTreasuryVoucherRecord({
    required this.id,
    required this.voucherNumber,
    required this.stationId,
    required this.stationName,
    required this.stationCode,
    required this.recipientName,
    required this.amount,
    required this.notes,
    required this.sourceType,
    required this.status,
    required this.cashBalanceBefore,
    required this.cashBalanceAfter,
    required this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory StationTreasuryVoucherRecord.fromJson(Map<String, dynamic> json) {
    return StationTreasuryVoucherRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      voucherNumber: json['voucherNumber']?.toString() ?? '',
      stationId: json['stationId'] is Map<String, dynamic>
          ? json['stationId']['_id']?.toString() ?? ''
          : json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? '',
      stationCode: json['stationCode']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      notes: json['notes']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'cash',
      status: json['status']?.toString() ?? '',
      cashBalanceBefore: _asDouble(json['cashBalanceBefore']),
      cashBalanceAfter: _asDouble(json['cashBalanceAfter']),
      createdByName: json['createdByName']?.toString() ?? '',
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }
}
