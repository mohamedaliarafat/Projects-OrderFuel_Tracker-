import 'package:order_tracker/models/driver_model.dart';

class DriverLocationSnapshot {
  final String id;
  final String driverId;
  final String? orderId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const DriverLocationSnapshot({
    required this.id,
    required this.driverId,
    this.orderId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  factory DriverLocationSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is DateTime) return value;
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? fallback ?? DateTime.now();
    }

    return DriverLocationSnapshot(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      driverId: (json['driverId'] ?? json['driver'] ?? json['driver_id'] ?? '')
          .toString(),
      orderId: json['orderId']?.toString() ?? json['order']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      timestamp: parseDate(json['timestamp'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'orderId': orderId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TrackedOrderSummary {
  final String id;
  final String orderNumber;
  final String status;
  final String? orderSource;
  final String? supplierName;
  final String? customerName;
  final String? city;
  final String? area;
  final String? address;

  const TrackedOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.orderSource,
    this.supplierName,
    this.customerName,
    this.city,
    this.area,
    this.address,
  });

  factory TrackedOrderSummary.fromJson(Map<String, dynamic> json) {
    return TrackedOrderSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      orderSource: json['orderSource']?.toString(),
      supplierName: json['supplierName']?.toString(),
      customerName: json['customerName']?.toString(),
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      address: json['address']?.toString(),
    );
  }

  String get destinationText {
    if (address != null && address!.trim().isNotEmpty) {
      return address!.trim();
    }
    final parts = <String>[];
    if (city != null && city!.trim().isNotEmpty) parts.add(city!.trim());
    if (area != null && area!.trim().isNotEmpty) parts.add(area!.trim());
    return parts.join(' - ');
  }
}

class DriverTrackingSummary {
  final Driver driver;
  final bool hasActiveOrder;
  final TrackedOrderSummary? activeOrder;
  final DriverLocationSnapshot? lastLocation;

  const DriverTrackingSummary({
    required this.driver,
    required this.hasActiveOrder,
    this.activeOrder,
    this.lastLocation,
  });

  factory DriverTrackingSummary.fromJson(Map<String, dynamic> json) {
    final rawDriver = json['driver'];
    final driverMap = rawDriver is Map
        ? Map<String, dynamic>.from(rawDriver)
        : Map<String, dynamic>.from(json);

    final rawOrder = json['activeOrder'] ?? json['order'];
    final order = rawOrder is Map
        ? TrackedOrderSummary.fromJson(Map<String, dynamic>.from(rawOrder))
        : null;

    final rawLocation = json['lastLocation'] ?? json['location'];
    final location = rawLocation is Map
        ? DriverLocationSnapshot.fromJson(
            Map<String, dynamic>.from(rawLocation),
          )
        : null;

    final hasActiveOrder = json.containsKey('hasActiveOrder')
        ? json['hasActiveOrder'] == true
        : order != null;

    return DriverTrackingSummary(
      driver: Driver.fromJson(driverMap),
      hasActiveOrder: hasActiveOrder,
      activeOrder: order,
      lastLocation: location,
    );
  }
}

class DriverTrackingDetail {
  final DriverTrackingSummary summary;
  final List<DriverLocationSnapshot> history;

  const DriverTrackingDetail({required this.summary, required this.history});

  factory DriverTrackingDetail.fromJson(Map<String, dynamic> json) {
    final rawDriver = json['driver'];
    final summary = rawDriver is Map
        ? DriverTrackingSummary.fromJson(Map<String, dynamic>.from(rawDriver))
        : DriverTrackingSummary.fromJson(json);

    final rawHistory = json['history'];
    final history = rawHistory is Iterable
        ? rawHistory
              .whereType<Map>()
              .map(
                (item) => DriverLocationSnapshot.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : const <DriverLocationSnapshot>[];

    return DriverTrackingDetail(summary: summary, history: history);
  }
}
