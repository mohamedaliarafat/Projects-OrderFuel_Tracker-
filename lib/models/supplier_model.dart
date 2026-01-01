// supplier_model.dart
class Supplier {
  final String id;
  final String name;
  final String company;
  final String contactPerson;
  final String? email;
  final String phone;
  final String? secondaryPhone;
  final String? address;
  final String? city;
  final String? country;
  final String? taxNumber;
  final String? commercialNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? iban;
  final String supplierType;
  final double rating;
  final String? notes;
  final bool isActive;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final List<SupplierDocument> documents;
  final String createdById;
  final String? createdByName;
  final String? updatedById;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.company,
    required this.contactPerson,
    this.email,
    required this.phone,
    this.secondaryPhone,
    this.address,
    this.city,
    this.country,
    this.taxNumber,
    this.commercialNumber,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.iban,
    required this.supplierType,
    required this.rating,
    this.notes,
    required this.isActive,
    this.contractStartDate,
    this.contractEndDate,
    required this.documents,
    required this.createdById,
    this.createdByName,
    this.updatedById,
    this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  // دالة لإنشاء مورد فارغ
  factory Supplier.empty() {
    return Supplier(
      id: '',
      name: '',
      company: '',
      contactPerson: '',
      phone: '',
      supplierType: 'وقود',
      rating: 3.0,
      isActive: true,
      documents: [],
      createdById: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      secondaryPhone: json['secondaryPhone'],
      address: json['address'],
      city: json['city'],
      country: json['country'] ?? 'السعودية',
      taxNumber: json['taxNumber'],
      commercialNumber: json['commercialNumber'],
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      bankAccountName: json['bankAccountName'],
      iban: json['iban'],
      supplierType: json['supplierType'] ?? 'وقود',
      rating: (json['rating'] ?? 3).toDouble(),
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      contractStartDate: json['contractStartDate'] != null
          ? DateTime.parse(json['contractStartDate'])
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.parse(json['contractEndDate'])
          : null,
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((e) => SupplierDocument.fromJson(e))
          .toList(),
      createdById: json['createdBy'] is String
          ? (json['createdBy'] ?? '')
          : json['createdBy']?['_id'] ?? '',
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['name']
          : null,
      updatedById: json['updatedBy'] is String
          ? (json['updatedBy'] ?? '')
          : json['updatedBy']?['_id'] ?? '',
      updatedByName: json['updatedBy'] is Map
          ? json['updatedBy']['name']
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
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'company': company,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'address': address,
      'city': city,
      'country': country,
      'taxNumber': taxNumber,
      'commercialNumber': commercialNumber,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountName': bankAccountName,
      'iban': iban,
      'supplierType': supplierType,
      'rating': rating,
      'notes': notes,
      'isActive': isActive,
      'contractStartDate': contractStartDate?.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
    };
  }

  // دوال مساعدة
  String get displayName => '$name ($company)';

  bool get hasDocuments => documents.isNotEmpty;

  bool get isFuelSupplier => supplierType == 'وقود';

  bool get isUnderContract {
    final now = DateTime.now();
    return contractStartDate != null &&
        contractEndDate != null &&
        now.isAfter(contractStartDate!) &&
        now.isBefore(contractEndDate!);
  }
}

class SupplierDocument {
  final String id;
  final String filename;
  final String path;
  final String documentType;
  final DateTime uploadedAt;

  SupplierDocument({
    required this.id,
    required this.filename,
    required this.path,
    required this.documentType,
    required this.uploadedAt,
  });

  factory SupplierDocument.fromJson(Map<String, dynamic> json) {
    return SupplierDocument(
      id: json['_id'] ?? json['id'] ?? '',
      filename: json['filename'] ?? '',
      path: json['path'] ?? '',
      documentType: json['documentType'] ?? 'أخرى',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'filename': filename, 'path': path, 'documentType': documentType};
  }
}

// Enum for supplier types
enum SupplierType {
  fuel('وقود'),
  maintenance('صيانة'),
  logistics('خدمات لوجستية'),
  other('أخرى');

  final String arabicName;

  const SupplierType(this.arabicName);

  static SupplierType fromString(String value) {
    return SupplierType.values.firstWhere(
      (e) => e.arabicName == value,
      orElse: () => SupplierType.fuel,
    );
  }
}
