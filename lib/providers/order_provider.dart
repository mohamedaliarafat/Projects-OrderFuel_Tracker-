import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  Order? _selectedOrder;
  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _filters = {};
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalOrders = 0;
  Map<String, Order> _ordersCache = {};

  List<Order> get orders =>
      _filteredOrders.isNotEmpty ? _filteredOrders : _orders;
  Order? get selectedOrder => _selectedOrder;
  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get filters => _filters;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalOrders => _totalOrders;

  Future<void> fetchOrders({
    int page = 1,
    Map<String, dynamic>? filters,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      String url = '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}?page=$page';

      if (filters != null) {
        _filters = {...filters};
        filters.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            url += '&$key=$value';
          }
        });
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> ordersData = [];
        if (data['orders'] is List) {
          ordersData = data['orders'];
        } else if (data['data'] is List) {
          ordersData = data['data'];
        } else if (data is List) {
          ordersData = data;
        }

        _orders = ordersData.map((e) => Order.fromJson(e)).toList();

        // تحديث الكاش
        for (var order in _orders) {
          _ordersCache[order.id] = order;
        }

        _currentPage = data['pagination']?['page'] ?? 1;
        _totalPages = data['pagination']?['pages'] ?? 1;
        _totalOrders = data['pagination']?['total'] ?? _orders.length;

        // Apply filters locally if needed
        _applyLocalFilters();

        if (!silent) {
          _isLoading = false;
          notifyListeners();
        }
      } else {
        throw Exception('فشل في جلب البيانات');
      }
    } catch (e) {
      _error = e.toString();
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _applyLocalFilters() {
    if (_filters.isEmpty) {
      _filteredOrders = _orders;
      return;
    }

    _filteredOrders = _orders.where((order) {
      bool matches = true;

      if (_filters['status'] != null && _filters['status'].isNotEmpty) {
        matches = matches && order.status == _filters['status'];
      }

      if (_filters['supplierName'] != null &&
          _filters['supplierName'].isNotEmpty) {
        matches =
            matches && order.supplierName.contains(_filters['supplierName']);
      }

      if (_filters['orderNumber'] != null &&
          _filters['orderNumber'].isNotEmpty) {
        matches =
            matches && order.orderNumber.contains(_filters['orderNumber']);
      }

      if (_filters['driverName'] != null && _filters['driverName'].isNotEmpty) {
        matches =
            matches &&
            (order.driverName?.contains(_filters['driverName']) ?? false);
      }

      if (_filters['customerName'] != null &&
          _filters['customerName'].isNotEmpty) {
        matches =
            matches &&
            (order.customer?.name?.contains(_filters['customerName']) ?? false);
      }

      if (_filters['startDate'] != null) {
        matches = matches && order.orderDate.isAfter(_filters['startDate']);
      }

      if (_filters['endDate'] != null) {
        matches = matches && order.orderDate.isBefore(_filters['endDate']);
      }

      if (_filters['requestType'] != null &&
          _filters['requestType'].isNotEmpty) {
        matches = matches && order.requestType == _filters['requestType'];
      }

      return matches;
    }).toList();
  }

  Future<void> fetchOrderById(String id, {bool silent = false}) async {
    // التحقق من الكاش أولاً
    if (_ordersCache.containsKey(id)) {
      _selectedOrder = _ordersCache[id];
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orderById(id)}'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Order order;
        if (data['order'] != null) {
          order = Order.fromJson(data['order']);
        } else if (data['data'] != null) {
          order = Order.fromJson(data['data']);
        } else {
          order = Order.fromJson(data);
        }

        _selectedOrder = order;
        _ordersCache[id] = order;

        List<dynamic> activitiesData = [];
        if (data['activities'] is List) {
          activitiesData = data['activities'];
        }

        _activities = activitiesData.map((e) => Activity.fromJson(e)).toList();

        if (!silent) {
          _isLoading = false;
          notifyListeners();
        }
      } else {
        throw Exception('فشل في جلب بيانات الطلب');
      }
    } catch (e) {
      _error = e.toString();
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createOrder(
    Order order,
    List<String>? attachmentPaths,
    String? customerId,
    String? driverId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orders}'),
      );

      // Headers
      request.headers.addAll(ApiService.headers);

      // =========================
      // الحقول الأساسية
      // =========================

      // 🔴 **الحل: لا ترسل supplier إذا كان فارغاً أو لطلب عميل**
      if (order.supplierId != null && order.supplierId!.isNotEmpty) {
        request.fields['supplier'] = order.supplierId!;
      }

      request.fields['supplierName'] = order.supplierName;
      request.fields['requestType'] = order.requestType;

      request.fields['orderDate'] = order.orderDate.toIso8601String();
      request.fields['loadingDate'] = order.loadingDate.toIso8601String();
      request.fields['loadingTime'] = order.loadingTime;
      request.fields['arrivalDate'] = order.arrivalDate.toIso8601String();
      request.fields['arrivalTime'] = order.arrivalTime;

      // =========================
      // 📍 موقع الطلب (الحل هنا 🔥)
      // =========================

      // 🟢 **المدينة والمنطقة** - مطلوبة من الباك إند
      request.fields['city'] = order.city ?? 'غير محدد';
      request.fields['area'] = order.area ?? 'غير محدد';

      // 🟢 **العنوان** - لا يمكن أن يكون null
      if (order.address != null && order.address!.isNotEmpty) {
        request.fields['address'] = order.address!;
      } else {
        // عنوان افتراضي
        request.fields['address'] = '${order.city ?? ''} - ${order.area ?? ''}';
      }

      // =========================
      // رقم طلب المورد (اختياري)
      // =========================
      if (order.supplierOrderNumber?.isNotEmpty == true) {
        request.fields['supplierOrderNumber'] = order.supplierOrderNumber!;
      }

      // =========================
      // العميل (اختياري)
      // =========================
      if (customerId?.isNotEmpty == true) {
        request.fields['customer'] = customerId!;
      }

      // =========================
      // السائق (اختياري)
      // =========================
      if (driverId?.isNotEmpty == true) {
        request.fields['driver'] = driverId!;
      }

      if (order.driverName?.isNotEmpty == true) {
        request.fields['driverName'] = order.driverName!;
      }

      if (order.driverPhone?.isNotEmpty == true) {
        request.fields['driverPhone'] = order.driverPhone!;
      }

      if (order.vehicleNumber?.isNotEmpty == true) {
        request.fields['vehicleNumber'] = order.vehicleNumber!;
      }

      // =========================
      // معلومات الوقود (اختياري)
      // =========================
      if (order.fuelType?.isNotEmpty == true) {
        request.fields['fuelType'] = order.fuelType!;
      }

      if (order.quantity != null) {
        request.fields['quantity'] = order.quantity!.toString();
      }

      if (order.unit?.isNotEmpty == true) {
        request.fields['unit'] = order.unit!;
      }

      // =========================
      // ملاحظات (اختياري)
      // =========================
      if (order.notes?.isNotEmpty == true) {
        request.fields['notes'] = order.notes!;
      }

      // =========================
      // لوجو الشركة (اختياري)
      // =========================
      if (order.companyLogo?.isNotEmpty == true) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'companyLogo',
              order.companyLogo!,
            ),
          );
        } catch (e) {
          debugPrint('⚠️ Error adding company logo: $e');
        }
      }

      // =========================
      // المرفقات (اختياري)
      // =========================
      if (attachmentPaths?.isNotEmpty == true) {
        for (final path in attachmentPaths!) {
          try {
            request.files.add(
              await http.MultipartFile.fromPath('attachments', path),
            );
          } catch (e) {
            debugPrint('⚠️ Error adding attachment $path: $e');
          }
        }
      }

      // =========================
      // DEBUG - للتحقق من البيانات
      // =========================
      debugPrint('🔴 DEBUG CREATE ORDER:');
      debugPrint('📍 CITY => ${request.fields['city']}');
      debugPrint('📍 AREA => ${request.fields['area']}');
      debugPrint('📍 ADDRESS => ${request.fields['address']}');
      debugPrint('🚚 SUPPLIER => ${request.fields['supplier'] ?? "NULL"}');
      debugPrint('👤 CUSTOMER => ${request.fields['customer'] ?? "NULL"}');
      debugPrint('📋 REQUEST TYPE => ${order.requestType}');

      // =========================
      // إرسال الطلب
      // =========================
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newOrder = Order.fromJson(data['order'] ?? data);

        // إضافة الطلب الجديد للقائمة
        _orders.insert(0, newOrder);
        _ordersCache[newOrder.id] = newOrder;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? 'فشل إنشاء الطلب';

        // عرض الخطأ بالتفصيل
        debugPrint('❌ ERROR CREATING ORDER:');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response: ${response.body}');

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'خطأ في الاتصال بالسيرفر: ${e.toString()}';
      debugPrint('❌ EXCEPTION IN CREATE ORDER: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تحديث الطلب مع الحقول المسموح بها فقط (للمستخدمين العاديين)
  Future<bool> updateOrderLimited(
    String id,
    Map<String, dynamic> updates,
    List<String>? newAttachmentPaths,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orderById(id)}'),
      );

      // Add headers
      request.headers.addAll(ApiService.headers);

      // إضافة الحقول المسموح بها فقط (كما في الباك إند)
      // الحقول المسموح بها للمستخدمين العاديين
      final allowedUpdates = [
        'driverName',
        'driverPhone',
        'vehicleNumber',
        'notes',
        'actualArrivalTime',
        'loadingDuration',
        'delayReason',
        'customer',
        'driver', // حقل السائق الجديد
        'status', // حالة الطلب
      ];

      updates.forEach((key, value) {
        if (allowedUpdates.contains(key) &&
            value != null &&
            value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      // Add new attachments
      if (newAttachmentPaths != null && newAttachmentPaths.isNotEmpty) {
        for (var path in newAttachmentPaths) {
          request.files.add(
            await http.MultipartFile.fromPath('attachments', path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Order updatedOrder;
        if (data['order'] != null) {
          updatedOrder = Order.fromJson(data['order']);
        } else if (data['data'] != null) {
          updatedOrder = Order.fromJson(data['data']);
        } else {
          updatedOrder = Order.fromJson(data);
        }

        // Update in list
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }

        // Update selected order if it's the same
        if (_selectedOrder?.id == id) {
          _selectedOrder = updatedOrder;
        }

        // Update cache
        _ordersCache[id] = updatedOrder;

        // تحديث filteredOrders إذا كانت موجودة
        if (_filteredOrders.isNotEmpty) {
          final filteredIndex = _filteredOrders.indexWhere((o) => o.id == id);
          if (filteredIndex != -1) {
            _filteredOrders[filteredIndex] = updatedOrder;
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error =
            errorData['error'] ??
            errorData['message'] ??
            'فشل تحديث الطلب - الرجاء التحقق من البيانات';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> mergeOrders({
    required String sourceOrderId,
    required String targetOrderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/orders/merge');

      final response = await http.post(
        url,
        headers: ApiService.headers,
        body: jsonEncode({
          'sourceOrderId': sourceOrderId,
          'targetOrderId': targetOrderId,
        }),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'فشل في دمج الطلبات';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تحديث حالة الطلب فقط (للإداريين)
  Future<bool> updateOrderStatus(String id, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.orderById(id)}/status',
        ),
        headers: ApiService.headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Order updatedOrder;
        if (data['order'] != null) {
          updatedOrder = Order.fromJson(data['order']);
        } else if (data['data'] != null) {
          updatedOrder = Order.fromJson(data['data']);
        } else {
          updatedOrder = Order.fromJson(data);
        }

        // Update in list
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }

        // Update selected order if it's the same
        if (_selectedOrder?.id == id) {
          _selectedOrder = updatedOrder;
        }

        // Update cache
        _ordersCache[id] = updatedOrder;

        // Update filteredOrders if exists
        if (_filteredOrders.isNotEmpty) {
          final filteredIndex = _filteredOrders.indexWhere((o) => o.id == id);
          if (filteredIndex != -1) {
            _filteredOrders[filteredIndex] = updatedOrder;
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error =
            errorData['error'] ??
            errorData['message'] ??
            'فشل تحديث حالة الطلب';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تحديث الطلب بالكامل (للإداريين فقط)
  Future<bool> updateOrderFull(
    String id,
    Order order,
    List<String>? newAttachmentPaths,
    String? customerId,
    String? driverId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orderById(id)}'),
      );

      // Add headers
      request.headers.addAll(ApiService.headers);

      // إضافة جميع الحقول
      request.fields['supplierName'] = order.supplierName;
      request.fields['requestType'] = order.requestType;
      request.fields['orderDate'] = order.orderDate.toIso8601String();
      request.fields['loadingDate'] = order.loadingDate.toIso8601String();
      request.fields['loadingTime'] = order.loadingTime ?? '08:00';
      request.fields['arrivalDate'] = order.arrivalDate.toIso8601String();
      request.fields['arrivalTime'] = order.arrivalTime ?? '10:00';
      request.fields['status'] = order.status;

      if (order.supplierOrderNumber != null &&
          order.supplierOrderNumber!.isNotEmpty) {
        request.fields['supplierOrderNumber'] = order.supplierOrderNumber!;
      }

      if (customerId != null && customerId.isNotEmpty) {
        request.fields['customer'] = customerId;
      }

      if (driverId != null && driverId.isNotEmpty) {
        request.fields['driver'] = driverId;
      }

      // معلومات السائق والمركبة (للتوافق مع الحقول القديمة)
      if (order.driverName != null && order.driverName!.isNotEmpty) {
        request.fields['driverName'] = order.driverName!;
      }
      if (order.driverPhone != null && order.driverPhone!.isNotEmpty) {
        request.fields['driverPhone'] = order.driverPhone!;
      }
      if (order.vehicleNumber != null && order.vehicleNumber!.isNotEmpty) {
        request.fields['vehicleNumber'] = order.vehicleNumber!;
      }
      if (order.fuelType != null && order.fuelType!.isNotEmpty) {
        request.fields['fuelType'] = order.fuelType!;
      }
      if (order.quantity != null) {
        request.fields['quantity'] = order.quantity!.toString();
      }
      if (order.unit != null && order.unit!.isNotEmpty) {
        request.fields['unit'] = order.unit!;
      }
      if (order.notes != null && order.notes!.isNotEmpty) {
        request.fields['notes'] = order.notes!;
      }

      // إضافة معلومات التتبع
      if (order.actualArrivalTime != null &&
          order.actualArrivalTime!.isNotEmpty) {
        request.fields['actualArrivalTime'] = order.actualArrivalTime!;
      }
      if (order.loadingDuration != null) {
        request.fields['loadingDuration'] = order.loadingDuration!.toString();
      }
      if (order.delayReason != null && order.delayReason!.isNotEmpty) {
        request.fields['delayReason'] = order.delayReason!;
      }

      // Add company logo if exists
      if (order.companyLogo != null && order.companyLogo!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('companyLogo', order.companyLogo!),
        );
      }

      // Add new attachments
      if (newAttachmentPaths != null && newAttachmentPaths.isNotEmpty) {
        for (var path in newAttachmentPaths) {
          request.files.add(
            await http.MultipartFile.fromPath('attachments', path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Order updatedOrder;
        if (data['order'] != null) {
          updatedOrder = Order.fromJson(data['order']);
        } else if (data['data'] != null) {
          updatedOrder = Order.fromJson(data['data']);
        } else {
          updatedOrder = Order.fromJson(data);
        }

        // Update in list
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }

        // Update selected order if it's the same
        if (_selectedOrder?.id == id) {
          _selectedOrder = updatedOrder;
        }

        // Update cache
        _ordersCache[id] = updatedOrder;

        if (_filteredOrders.isNotEmpty) {
          final filteredIndex = _filteredOrders.indexWhere((o) => o.id == id);
          if (filteredIndex != -1) {
            _filteredOrders[filteredIndex] = updatedOrder;
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error =
            errorData['error'] ?? errorData['message'] ?? 'فشل تحديث الطلب';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orderById(id)}'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from lists
        _orders.removeWhere((order) => order.id == id);
        _filteredOrders.removeWhere((order) => order.id == id);

        // Remove from cache
        _ordersCache.remove(id);

        if (_selectedOrder?.id == id) {
          _selectedOrder = null;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? errorData['message'] ?? 'فشل حذف الطلب';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttachment(String orderId, String attachmentId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.deleteAttachment(orderId, attachmentId)}',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        // Remove attachment from order
        final order = _orders.firstWhere((o) => o.id == orderId);
        order.attachments.removeWhere((a) => a.id == attachmentId);

        if (_selectedOrder?.id == orderId) {
          _selectedOrder!.attachments.removeWhere((a) => a.id == attachmentId);
        }

        // Update cache
        if (_ordersCache.containsKey(orderId)) {
          _ordersCache[orderId]!.attachments.removeWhere(
            (a) => a.id == attachmentId,
          );
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchActivities({String? orderId, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      String url = '${ApiEndpoints.baseUrl}${ApiEndpoints.activities}';
      if (orderId != null && orderId.isNotEmpty) {
        url += '?orderId=$orderId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> activitiesData = [];
        if (data['activities'] is List) {
          activitiesData = data['activities'];
        } else if (data['data'] is List) {
          activitiesData = data['data'];
        } else if (data is List) {
          activitiesData = data;
        }

        _activities = activitiesData.map((e) => Activity.fromJson(e)).toList();
      } else {
        throw Exception('فشل في جلب سجل الحركات');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // وظائف إضافية

  // جلب طلبات اليوم
  Future<List<Order>> fetchTodayOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/today/orders'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> ordersData = [];
        if (data is List) {
          ordersData = data;
        } else if (data['orders'] is List) {
          ordersData = data['orders'];
        } else if (data['data'] is List) {
          ordersData = data['data'];
        }

        return ordersData.map((e) => Order.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // جلب الطلبات العاجلة
  Future<List<Order>> fetchUrgentLoadingOrders() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/urgent/loading',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> ordersData = [];
        if (data is List) {
          ordersData = data;
        } else if (data['orders'] is List) {
          ordersData = data['orders'];
        } else if (data['data'] is List) {
          ordersData = data['data'];
        }

        return ordersData.map((e) => Order.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // إحصائيات الطلبات حسب الحالة
  Future<Map<String, int>> fetchStatusStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/stats/status'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, int> stats = {};

        List<dynamic> statsData = [];
        if (data is List) {
          statsData = data;
        } else if (data['stats'] is List) {
          statsData = data['stats'];
        } else if (data['data'] is List) {
          statsData = data['data'];
        }

        for (var item in statsData) {
          if (item is Map) {
            stats[item['_id'] ?? item['status'] ?? 'غير معروف'] =
                (item['count'] ?? 0).toInt();
          }
        }
        return stats;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<OrderTimer>> getOrdersWithTimers({
    Map<String, dynamic>? filters,
  }) async {
    try {
      String url = '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/with-timers';

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            url += '${url.contains('?') ? '&' : '?'}$key=$value';
          }
        });
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ordersData = data['orders'] as List<dynamic>;

        return ordersData.map((orderJson) {
          return OrderTimer(
            orderId: orderJson['_id'],
            arrivalDateTime: DateTime.parse(orderJson['arrivalDateTime']),
            loadingDateTime: DateTime.parse(orderJson['loadingDateTime']),
            orderNumber: orderJson['orderNumber'],
            supplierName: orderJson['supplierName'],
            customerName: orderJson['customer']?['name'],
            driverName: orderJson['driverName'],
            status: orderJson['status'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching orders with timers: $e');
      return [];
    }
  }

  Future<List<OrderTimer>> getUpcomingOrders() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/upcoming/orders',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        return data.map((orderJson) {
          return OrderTimer(
            orderId: orderJson['_id'],
            arrivalDateTime: DateTime.parse(orderJson['arrivalDateTime']),
            loadingDateTime: DateTime.parse(orderJson['loadingDateTime']),
            orderNumber: orderJson['orderNumber'],
            supplierName: orderJson['supplierName'],
            customerName: orderJson['customer']?['name'],
            driverName: orderJson['driverName'],
            status: orderJson['status'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching upcoming orders: $e');
      return [];
    }
  }

  Future<void> markOrderAsCompleted(String orderId) async {
    try {
      // =========================
      // 1️⃣ تحديث السيرفر
      // =========================
      final response = await http.patch(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/$orderId/status',
        ),
        headers: {...ApiService.headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'تم التحميل',
          'loadingCompletedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Failed to auto complete order [$orderId]: '
          '${response.statusCode} ${response.body}',
        );
        return;
      }

      // =========================
      // 2️⃣ تحديث محلي (Immutable)
      // =========================
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return;

      final oldOrder = _orders[index];

      _orders[index] = Order(
        id: oldOrder.id,
        orderDate: oldOrder.orderDate,
        supplierName: oldOrder.supplierName,
        requestType: oldOrder.requestType,
        orderNumber: oldOrder.orderNumber,
        supplierOrderNumber: oldOrder.supplierOrderNumber,
        loadingDate: oldOrder.loadingDate,
        loadingTime: oldOrder.loadingTime,
        arrivalDate: oldOrder.arrivalDate,
        arrivalTime: oldOrder.arrivalTime,
        status: 'تم التحميل', // ✅
        driverId: oldOrder.driverId,
        driverName: oldOrder.driverName,
        driverPhone: oldOrder.driverPhone,
        vehicleNumber: oldOrder.vehicleNumber,
        fuelType: oldOrder.fuelType,
        quantity: oldOrder.quantity,
        unit: oldOrder.unit,
        notes: oldOrder.notes,
        companyLogo: oldOrder.companyLogo,
        attachments: oldOrder.attachments,
        createdById: oldOrder.createdById,
        createdByName: oldOrder.createdByName,
        customer: oldOrder.customer,
        notificationSentAt: oldOrder.notificationSentAt,
        arrivalNotificationSentAt: oldOrder.arrivalNotificationSentAt,
        loadingCompletedAt: DateTime.now(), // ✅
        actualArrivalTime: oldOrder.actualArrivalTime,
        loadingDuration: oldOrder.loadingDuration,
        delayReason: oldOrder.delayReason,
        createdAt: oldOrder.createdAt,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Auto complete order failed: $e');
    }
  }

  // تصدير PDF
  Future<Uint8List?> exportOrderToPDF(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.orders}/$orderId/export/pdf',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // طريقة للحصول على طلب من الكاش
  Order? getOrderById(String id) {
    if (_ordersCache.containsKey(id)) {
      return _ordersCache[id];
    }

    final order = _orders.firstWhere(
      (order) => order.id == id,
      orElse: () => Order.empty(),
    );

    if (order.id.isNotEmpty) {
      _ordersCache[id] = order;
      return order;
    }

    return null;
  }

  // تحديث طلب محلياً (للاستخدام المؤقت)
  void updateOrderLocally(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
    }

    // تحديث الكاش
    _ordersCache[order.id] = order;

    if (_selectedOrder?.id == order.id) {
      _selectedOrder = order;
    }

    // تحديث الفلاتر
    if (_filteredOrders.isNotEmpty) {
      final filteredIndex = _filteredOrders.indexWhere((o) => o.id == order.id);
      if (filteredIndex != -1) {
        _filteredOrders[filteredIndex] = order;
      }
    }

    notifyListeners();
  }

  void clearFilters() {
    if (_filters.isEmpty) return;
    _filters.clear();
    _filteredOrders = List.from(_orders);
    notifyListeners();
  }

  void setFilters(Map<String, dynamic> filters) {
    _filters = Map.from(filters);
    _applyLocalFilters();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void clearSelectedOrder({bool silent = false}) {
    _selectedOrder = null;
    _activities.clear();

    if (!silent) {
      notifyListeners();
    }
  }

  void clearCache() {
    _ordersCache.clear();
  }

  // طريقة لتحميل طلب معين إذا لم يكن في الكاش
  Future<Order?> loadOrder(String id, {bool silent = false}) async {
    final cachedOrder = getOrderById(id);
    if (cachedOrder != null) {
      return cachedOrder;
    }

    await fetchOrderById(id, silent: silent);
    return _selectedOrder;
  }
}
