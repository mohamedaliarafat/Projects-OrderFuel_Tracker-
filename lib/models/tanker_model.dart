class Tanker {
  final String id;
  final String number;
  final String status;
  final int? capacityLiters;
  final String? linkedDriverId;
  final String? linkedDriverName;
  final String? linkedVehicleNumber;
  final String? linkedVehicleType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tanker({
    required this.id,
    required this.number,
    required this.status,
    this.capacityLiters,
    this.linkedDriverId,
    this.linkedDriverName,
    this.linkedVehicleNumber,
    this.linkedVehicleType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tanker.empty() {
    final now = DateTime.now();
    return Tanker(
      id: '',
      number: '',
      status: 'فاضي',
      capacityLiters: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Tanker.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is DateTime) return value;
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? fallback ?? DateTime.now();
    }

    int? parseCapacity(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value.toString());
    }

    final rawDriver = json['linkedDriver'];
    final linkedDriver = rawDriver is Map<String, dynamic>
        ? rawDriver
        : rawDriver is Map
        ? Map<String, dynamic>.from(rawDriver)
        : null;

    return Tanker(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      number: (json['number'] ?? json['tankerNumber'] ?? '').toString(),
      status: (json['status'] ?? 'فاضي').toString(),
      capacityLiters: parseCapacity(json['capacityLiters'] ?? json['capacity']),
      linkedDriverId: linkedDriver?['_id']?.toString() ??
          linkedDriver?['id']?.toString() ??
          json['linkedDriverId']?.toString() ??
          json['driverId']?.toString(),
      linkedDriverName: linkedDriver?['name']?.toString() ??
          json['linkedDriverName']?.toString() ??
          json['driverName']?.toString(),
      linkedVehicleNumber:
          linkedDriver?['vehicleNumber']?.toString() ?? json['vehicleNumber']?.toString(),
      linkedVehicleType:
          linkedDriver?['vehicleType']?.toString() ?? json['vehicleType']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'status': status,
      'capacityLiters': capacityLiters,
      'linkedDriverId': linkedDriverId,
      'notes': notes,
    };
  }
}
