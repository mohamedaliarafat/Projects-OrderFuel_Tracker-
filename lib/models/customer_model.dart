class Customer {
  final String id;
  final String name;
  final String code;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final String? contactPersonPhone;
  final String? notes;
  final bool isActive;
  final String createdById;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.code,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    this.contactPersonPhone,
    this.notes,
    required this.isActive,
    required this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      contactPerson: json['contactPerson'],
      contactPersonPhone: json['contactPersonPhone'],
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      createdById: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id']?.toString() ?? '',
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['name']
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'phone': phone,
      'email': email,
      'address': address,
      'contactPerson': contactPerson,
      'contactPersonPhone': contactPersonPhone,
      'notes': notes,
      'isActive': isActive,
    };
  }

  /// ✅ الاسم المعروض
  String get displayName => '$name ($code)';

  /// ✅ الحل الذهبي
  @override
  String toString() {
    return displayName;
  }
}
