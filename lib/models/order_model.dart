import 'package:intl/intl.dart';
import 'package:order_tracker/models/models.dart';
import 'customer_model.dart';

class Order {
  final String id;
  final DateTime orderDate;

  /// 🔴 مصدر الطلب (عميل | مورد)
  final String? orderSource;

  /// 🔴 حالة الدمج
  final String? mergeStatus;

  final String supplierName;

  /// ✅ نوع العملية (شراء | نقل)
  final String requestType;

  final String orderNumber;
  final String? supplierOrderNumber;

  final DateTime loadingDate;
  final String loadingTime;
  final DateTime arrivalDate;
  final String arrivalTime;
  final String status;

  // ===== بيانات المورد =====
  final String? supplierId;
  final bool isSupplierOrder;
  final String? supplierContactPerson;
  final String? supplierPhone;
  final String? supplierAddress;
  final String? supplierCompany;

  // ===== 📍 موقع الطلب =====
  final String? city;
  final String? area;
  final String? address;

  // ===== بيانات السائق =====
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;

  // ===== بيانات الطلب =====
  final String? fuelType;
  final double? quantity;
  final String? unit;
  final String? notes;
  final String? companyLogo;

  final List<Attachment> attachments;

  final String createdById;
  final String? createdByName;

  final Customer? customer;

  final DateTime? notificationSentAt;
  final DateTime? arrivalNotificationSentAt;
  final DateTime? loadingCompletedAt;
  final String? actualArrivalTime;
  final int? loadingDuration;
  final String? delayReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  // =========================
  // Constructor (ثابت وآمن)
  // =========================
  const Order({
    required this.id,
    required this.orderDate,
    this.orderSource,
    this.mergeStatus,
    required this.supplierName,
    required this.requestType,
    required this.orderNumber,
    this.supplierOrderNumber,
    required this.loadingDate,
    required this.loadingTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.status,

    // المورد
    this.supplierId,
    this.isSupplierOrder = false,
    this.supplierContactPerson,
    this.supplierPhone,
    this.supplierAddress,
    this.supplierCompany,

    // الموقع
    this.city,
    this.area,
    this.address,

    // السائق
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,

    // الطلب
    this.fuelType,
    this.quantity,
    this.unit,
    this.notes,
    this.companyLogo,

    required this.attachments,
    required this.createdById,
    this.createdByName,
    this.customer,

    this.notificationSentAt,
    this.arrivalNotificationSentAt,
    this.loadingCompletedAt,
    this.actualArrivalTime,
    this.loadingDuration,
    this.delayReason,

    required this.createdAt,
    required this.updatedAt,
  });

  // =========================
  // 🧪 Order فارغ (آمن)
  // =========================
  factory Order.empty() {
    return Order(
      id: '',
      orderDate: DateTime.now(),
      supplierName: '',
      requestType: 'شراء',
      orderNumber: '',
      loadingDate: DateTime.now(),
      loadingTime: '08:00',
      arrivalDate: DateTime.now(),
      arrivalTime: '10:00',
      status: 'في انتظار عمل طلب جديد',
      attachments: const [],
      createdById: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // =========================
  // fromJson (محمي)
  // =========================
  factory Order.fromJson(Map<String, dynamic> json) {
    Customer? customer;
    if (json['customer'] is Map<String, dynamic>) {
      customer = Customer.fromJson(json['customer']);
    }

    // ===== السائق =====
    String? driverId;
    String? driverName;
    String? driverPhone;
    String? vehicleNumber;

    if (json['driver'] is Map<String, dynamic>) {
      driverId = json['driver']['_id']?.toString();
      driverName = json['driver']['name']?.toString();
      driverPhone = json['driver']['phone']?.toString();
      vehicleNumber = json['driver']['vehicleNumber']?.toString();
    } else if (json['driver'] is String) {
      driverId = json['driver'];
    }

    // ===== المورد =====
    String? supplierId;
    bool isSupplierOrder = false;

    if (json['supplier'] is Map<String, dynamic>) {
      supplierId = json['supplier']['_id']?.toString();
      isSupplierOrder = true;
    } else if (json['supplier'] is String) {
      supplierId = json['supplier'];
      isSupplierOrder = true;
    }

    return Order(
      id: json['_id']?.toString() ?? '',
      orderDate:
          DateTime.tryParse(json['orderDate']?.toString() ?? '') ??
          DateTime.now(),

      orderSource: json['orderSource']?.toString(),
      mergeStatus: json['mergeStatus']?.toString(),

      supplierName: json['supplierName']?.toString() ?? '',
      requestType: json['requestType']?.toString() ?? 'شراء',
      orderNumber: json['orderNumber']?.toString() ?? '',
      supplierOrderNumber: json['supplierOrderNumber']?.toString(),

      loadingDate:
          DateTime.tryParse(json['loadingDate']?.toString() ?? '') ??
          DateTime.now(),
      loadingTime: json['loadingTime']?.toString() ?? '08:00',
      arrivalDate:
          DateTime.tryParse(json['arrivalDate']?.toString() ?? '') ??
          DateTime.now(),
      arrivalTime: json['arrivalTime']?.toString() ?? '10:00',

      status: json['status']?.toString() ?? '',

      supplierId: supplierId,
      isSupplierOrder: isSupplierOrder,

      city: json['city']?.toString(),
      area: json['area']?.toString(),
      address: json['address']?.toString(),

      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      vehicleNumber: vehicleNumber,

      fuelType: json['fuelType']?.toString(),
      quantity: json['quantity'] != null
          ? double.tryParse(json['quantity'].toString())
          : null,
      unit: json['unit']?.toString(),
      notes: json['notes']?.toString(),
      companyLogo: json['companyLogo']?.toString(),

      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => Attachment.fromJson(e))
          .toList(),

      createdById: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id']?.toString() ?? '',
      createdByName: json['createdByName']?.toString(),

      customer: customer,

      notificationSentAt: DateTime.tryParse(
        json['notificationSentAt']?.toString() ?? '',
      ),
      arrivalNotificationSentAt: DateTime.tryParse(
        json['arrivalNotificationSentAt']?.toString() ?? '',
      ),
      loadingCompletedAt: DateTime.tryParse(
        json['loadingCompletedAt']?.toString() ?? '',
      ),
      actualArrivalTime: json['actualArrivalTime']?.toString(),
      loadingDuration: json['loadingDuration'],
      delayReason: json['delayReason']?.toString(),

      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // =========================
  // toJson (بدون تغيير)
  // =========================
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'orderDate': orderDate.toIso8601String(),
      'orderSource': orderSource,
      'mergeStatus': mergeStatus,
      'supplierName': supplierName,
      'requestType': requestType,
      'orderNumber': orderNumber,
      'supplierOrderNumber': supplierOrderNumber,
      'loadingDate': loadingDate.toIso8601String(),
      'loadingTime': loadingTime,
      'arrivalDate': arrivalDate.toIso8601String(),
      'arrivalTime': arrivalTime,
      'status': status,
      'supplier': supplierId,
      'supplierContactPerson': supplierContactPerson,
      'supplierPhone': supplierPhone,
      'supplierAddress': supplierAddress,
      'supplierCompany': supplierCompany,
      'city': city,
      'area': area,
      'address': address,
      'driver': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'fuelType': fuelType,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'companyLogo': companyLogo,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'createdBy': createdById,
      'createdByName': createdByName,
      'customer': customer?.id,
      'notificationSentAt': notificationSentAt?.toIso8601String(),
      'arrivalNotificationSentAt': arrivalNotificationSentAt?.toIso8601String(),
      'loadingCompletedAt': loadingCompletedAt?.toIso8601String(),
      'actualArrivalTime': actualArrivalTime,
      'loadingDuration': loadingDuration,
      'delayReason': delayReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // =========================
  // Helpers (كما هي)
  // =========================
  bool get isCustomerOrder => orderSource == 'عميل';
  bool get isSupplierSource => orderSource == 'مورد';
  bool get isMerged => mergeStatus == 'مدمج';

  String get formattedLoadingDateTime =>
      '${DateFormat('yyyy/MM/dd').format(loadingDate)} $loadingTime';

  String get formattedArrivalDateTime =>
      '${DateFormat('yyyy/MM/dd').format(arrivalDate)} $arrivalTime';
}
