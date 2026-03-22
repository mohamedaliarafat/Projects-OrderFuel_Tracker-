class Driver {
  final String id;
  final String name;
  final String licenseNumber;
  final String phone;
  final String? email;
  final String? address;
  final String vehicleType;
  final String? vehicleNumber;
  final String vehicleStatus;
  final DateTime? licenseExpiryDate;
  final String status;
  final bool isActive;
  final String? notes;
  final String createdById;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.phone,
    this.email,
    this.address,
    required this.vehicleType,
    this.vehicleNumber,
    this.vehicleStatus = 'فاضي',
    this.licenseExpiryDate,
    required this.status,
    required this.isActive,
    this.notes,
    required this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Constructor فارغ (آمن)
  factory Driver.empty() {
    return Driver(
      id: '',
      name: '',
      licenseNumber: '',
      phone: '',
      vehicleType: 'غير محدد',
      vehicleStatus: 'فاضي',
      status: 'نشط',
      isActive: true,
      createdById: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// ✅ fromJson آمن 100%
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      isActive: json['isActive'] ?? true,
      vehicleType: json['vehicleType']?.toString() ?? 'غير محدد',
      vehicleNumber: json['vehicleNumber']?.toString(),
      vehicleStatus: json['vehicleStatus']?.toString() ?? 'فاضي',
      licenseExpiryDate: json['licenseExpiryDate'] != null
          ? DateTime.tryParse(json['licenseExpiryDate'].toString())
          : null,
      status: json['status']?.toString() ?? 'نشط',
      notes: json['notes']?.toString(),
      createdById: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id']?.toString() ?? '',
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['name']?.toString()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// toJson للإرسال
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'licenseNumber': licenseNumber,
      'phone': phone,
      'email': email,
      'address': address,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'vehicleStatus': vehicleStatus,
      'licenseExpiryDate': licenseExpiryDate?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  /// Helpers
  String get displayName =>
      licenseNumber.isNotEmpty ? '$name ($licenseNumber)' : name;

  String get displayInfo {
    final parts = <String>[
      name,
      if (phone.isNotEmpty) phone,
      if (vehicleNumber != null && vehicleNumber!.isNotEmpty) vehicleNumber!,
    ];
    return parts.join(' - ');
  }

  bool get isEmpty => id.isEmpty && name.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
