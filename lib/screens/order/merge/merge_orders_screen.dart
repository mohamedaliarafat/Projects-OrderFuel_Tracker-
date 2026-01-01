import 'dart:async';
import 'package:flutter/material.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/providers/order_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/gradient_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MergeOrdersScreen extends StatefulWidget {
  const MergeOrdersScreen({super.key});

  @override
  State<MergeOrdersScreen> createState() => _MergeOrdersScreenState();
}

class _MergeOrdersScreenState extends State<MergeOrdersScreen> {
  // ============================================
  // 📌 متغيرات الطلبات
  // ============================================
  Order? _selectedSupplierOrder;
  Order? _selectedCustomerOrder;

  String? _selectedCustomerId;
  String? _selectedSupplierId;

  // ============================================
  // 📌 بيانات التصفية
  // ============================================
  String _fuelTypeFilter = 'جميع الأنواع';
  String _quantityFilter = 'جميع الكميات';

  // ============================================
  // 📌 قوائم البيانات
  // ============================================
  List<Order> _supplierOrders = [];
  List<Order> _customerOrders = [];
  List<Order> _filteredCustomerOrders = [];

  // ============================================
  // 📌 أنواع الوقود والكميات
  // ============================================
  final List<String> _fuelTypes = [
    'جميع الأنواع',
    'بنزين 91',
    'بنزين 95',
    'ديزل',
    'كيروسين',
  ];

  final List<String> _quantityRanges = [
    'جميع الكميات',
    '1000 - 5000 لتر',
    '5000 - 10000 لتر',
    '10000 - 20000 لتر',
    '20000 - 30000 لتر',
    '30000+ لتر',
  ];

  // ============================================
  // 📌 دوال جلب البيانات
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.fetchOrders(silent: true);

      final allOrders = orderProvider.orders;

      // =========================
      // طلبات المورد (مورد فقط + غير مدموجة)
      // =========================
      _supplierOrders = allOrders.where((order) {
        return order.orderSource == 'مورد' &&
            order.mergeStatus == 'منفصل' &&
            order.status == 'في انتظار عمل طلب جديد';
      }).toList();

      // =========================
      // طلبات العملاء (عميل فقط + غير مدموجة)
      // =========================
      _customerOrders = allOrders.where((order) {
        return order.orderSource == 'عميل' &&
            order.mergeStatus == 'منفصل' &&
            order.status == 'في انتظار عمل طلب جديد';
      }).toList();

      _filteredCustomerOrders = List.from(_customerOrders);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading orders for merge: $e');
    }
  }

  // ============================================
  // 🔍 دوال التصفية
  // ============================================
  void _filterCustomerOrders() {
    setState(() {
      _filteredCustomerOrders = _customerOrders.where((order) {
        // تصفية حسب نوع الوقود
        if (_fuelTypeFilter != 'جميع الأنواع' &&
            order.fuelType != _fuelTypeFilter) {
          return false;
        }

        // تصفية حسب نطاق الكمية
        if (_quantityFilter != 'جميع الكميات' && order.quantity != null) {
          final quantity = order.quantity!;
          switch (_quantityFilter) {
            case '1000 - 5000 لتر':
              if (quantity < 1000 || quantity > 5000) return false;
              break;
            case '5000 - 10000 لتر':
              if (quantity < 5000 || quantity > 10000) return false;
              break;
            case '10000 - 20000 لتر':
              if (quantity < 10000 || quantity > 20000) return false;
              break;
            case '20000 - 30000 لتر':
              if (quantity < 20000 || quantity > 30000) return false;
              break;
            case '30000+ لتر':
              if (quantity < 30000) return false;
              break;
          }
        }

        return true;
      }).toList();
    });
  }

  // ============================================
  // 🔗 دمج الطلبات
  // ============================================
  Future<void> _mergeOrders() async {
    if (_selectedSupplierOrder == null || _selectedCustomerOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى اختيار طلب مورد وطلب عميل للدمج'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // التحقق من التوافق
    if (!_areOrdersCompatible()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'الطلبات غير متوافقة (تختلف في نوع الوقود أو الكمية)',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final success = await orderProvider.mergeOrders(
        sourceOrderId: _selectedSupplierOrder!.id!,
        targetOrderId: _selectedCustomerOrder!.id!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم دمج الطلب ${_selectedSupplierOrder!.orderNumber} '
              'مع الطلب ${_selectedCustomerOrder!.orderNumber} بنجاح',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );

        // إعادة تعيين القيم
        setState(() {
          _selectedSupplierOrder = null;
          _selectedCustomerOrder = null;
          _selectedCustomerId = null;
          _selectedSupplierId = null;
        });

        // تحديث البيانات
        await _loadOrders();

        // العودة للشاشة السابقة
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الدمج: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  // ============================================
  // ✅ التحقق من التوافق
  // ============================================
  bool _areOrdersCompatible() {
    if (_selectedSupplierOrder == null || _selectedCustomerOrder == null) {
      return false;
    }

    final supplierQuantity = _selectedSupplierOrder!.quantity;
    final customerQuantity = _selectedCustomerOrder!.quantity;

    // لازم الكميتين موجودين
    if (supplierQuantity == null || customerQuantity == null) {
      return false;
    }

    // التوافق فقط: المورد >= العميل
    return supplierQuantity >= customerQuantity;
  }

  // ============================================
  // 📱 واجهة الجوال
  // ============================================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildSupplierOrderCard(),
          const SizedBox(height: 20),
          _buildCustomerOrderCard(),
          const SizedBox(height: 20),
          _buildMergeButton(),
          const SizedBox(height: 20),
          if (_selectedSupplierOrder != null && _selectedCustomerOrder != null)
            _buildCompatibilityInfo(),
        ],
      ),
    );
  }

  // ============================================
  // 💻 واجهة سطح المكتب
  // ============================================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العمود الأيسر: طلب المورد + معلومات التوافق
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildSupplierOrderCard(),
                const SizedBox(height: 20),
                if (_selectedSupplierOrder != null &&
                    _selectedCustomerOrder != null)
                  _buildCompatibilityInfo(),
              ],
            ),
          ),
        ),

        // الخط الفاصل
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 20),
          color: Colors.grey.shade300,
        ),

        // العمود الأيمن: طلب العميل + زر الدمج
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCustomerOrderCard(),
                const SizedBox(height: 20),
                _buildMergeButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // 🎴 مكونات الواجهة
  // ============================================
  Widget _buildHeaderCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.link, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'دمج الطلبات المتوافقة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'اختر طلب مورد وطلب عميل متوافقين للدمج',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierOrderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: AppColors.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'طلب المورد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                // 🔹 كارت الطلب المختار (لو موجود)
                if (_selectedSupplierOrder != null)
                  _buildSelectedOrderCard(
                    order: _selectedSupplierOrder!,
                    isSupplier: true,
                    onRemove: () {
                      setState(() {
                        _selectedSupplierOrder = null;
                        _selectedSupplierId = null;
                      });
                    },
                  ),

                // 🔹 قائمة الطلبات (تظهر دائمًا)
                _buildOrderSelectionList(
                  orders: _supplierOrders,
                  isSupplier: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerOrderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.secondaryTeal, size: 24),
                const SizedBox(width: 12),
                Text(
                  'طلب العميل',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // فلاتر البحث
            _buildFilterSection(),
            const SizedBox(height: 16),

            if (_selectedCustomerOrder == null)
              _buildOrderSelectionList(
                orders: _filteredCustomerOrders,
                isSupplier: false,
              )
            else
              _buildSelectedOrderCard(
                order: _selectedCustomerOrder!,
                isSupplier: false,
                onRemove: () {
                  setState(() {
                    _selectedCustomerOrder = null;
                    _selectedCustomerId = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تصفية الطلبات:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.mediumGray,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع الوقود',
                    style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: DropdownButton<String>(
                      value: _fuelTypeFilter,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _fuelTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fuelTypeFilter = value!;
                          _filterCustomerOrders();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نطاق الكمية',
                    style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: DropdownButton<String>(
                      value: _quantityFilter,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _quantityRanges.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _quantityFilter = value!;
                          _filterCustomerOrders();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_selectedSupplierOrder != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.infoBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يتم عرض الطلبات المتوافقة مع طلب المورد المحدد',
                    style: TextStyle(fontSize: 12, color: AppColors.infoBlue),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOrderSelectionList({
    required List<Order> orders,
    required bool isSupplier,
  }) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isSupplier ? Icons.business : Icons.person,
              size: 48,
              color: AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              isSupplier
                  ? 'لا توجد طلبات مورد متاحة للدمج'
                  : 'لا توجد طلبات عملاء مطابقة للتصفية',
              style: TextStyle(color: AppColors.mediumGray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderListItem(order, isSupplier);
        },
      ),
    );
  }

  Widget _simpleInfo({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryTeal),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildOrderListItem(Order order, bool isSupplier) {
    final bool isSelected =
        (isSupplier && _selectedSupplierId == order.id) ||
        (!isSupplier && _selectedCustomerId == order.id);

    final String orderBadge =
        (order.orderNumber.isNotEmpty && order.orderNumber.length >= 3)
        ? order.orderNumber.substring(0, 3)
        : order.orderNumber;

    final String locationText =
        '${order.city ?? 'مدينة غير محددة'} - ${order.area ?? 'منطقة غير محددة'}';

    return InkWell(
      onTap: () {
        setState(() {
          if (isSupplier) {
            _selectedSupplierOrder = order;
            _selectedSupplierId = order.id;

            if (order.fuelType != null) {
              _fuelTypeFilter = order.fuelType!;
              _filterCustomerOrders();
            }
          } else {
            _selectedCustomerOrder = order;
            _selectedCustomerId = order.id;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // Header
            // =========================
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSupplier
                        ? AppColors.primaryBlue.withOpacity(0.2)
                        : AppColors.secondaryTeal.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      orderBadge,
                      style: TextStyle(
                        color: isSupplier
                            ? AppColors.primaryBlue
                            : AppColors.secondaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم الطلب الأساسي
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      // اسم المورد / العميل
                      Text(
                        isSupplier
                            ? (order.supplierName ?? 'مورد')
                            : (order.customer?.name ?? 'عميل'),
                        style: TextStyle(
                          color: AppColors.mediumGray,
                          fontSize: 14,
                        ),
                      ),

                      // ✅ رقم طلب المورد (NEW)
                      if (isSupplier &&
                          order.supplierOrderNumber != null &&
                          order.supplierOrderNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'رقم طلب المورد: ${order.supplierOrderNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.infoBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.successGreen),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),

            // =========================
            // Fuel + Quantity
            // =========================
            Row(
              children: [
                const Icon(
                  Icons.local_gas_station,
                  size: 16,
                  color: AppColors.warningOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  order.fuelType ?? 'غير محدد',
                  style: const TextStyle(
                    color: AppColors.warningOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.scale, size: 16, color: AppColors.infoBlue),
                const SizedBox(width: 8),
                Text(
                  '${order.quantity?.toStringAsFixed(0) ?? '0'} لتر',
                  style: const TextStyle(
                    color: AppColors.infoBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // =========================
            // City + Area
            // =========================
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationText,
                    style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // =========================
            // Date + Time
            // =========================
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.secondaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat(
                    'yyyy/MM/dd',
                  ).format(isSupplier ? order.loadingDate : order.arrivalDate),
                  style: const TextStyle(
                    color: AppColors.secondaryTeal,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.secondaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  isSupplier ? order.loadingTime : order.arrivalTime,
                  style: const TextStyle(
                    color: AppColors.secondaryTeal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedOrderCard({
    required Order order,
    required bool isSupplier,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======================
                // رقم الطلب + اسم المورد
                // ======================
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                      child: Text(
                        order.orderNumber.substring(0, 3),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            order.supplierName ?? 'مورد',
                            style: TextStyle(
                              color: AppColors.mediumGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ======================
                // اسم السائق
                // ======================
                if (order.driverName != null)
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'السائق: ${order.driverName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // ======================
                // الوقود + الكمية
                // ======================
                Row(
                  children: [
                    _simpleInfo(
                      icon: Icons.local_gas_station,
                      text: order.fuelType ?? 'غير محدد',
                    ),
                    const SizedBox(width: 16),
                    _simpleInfo(
                      icon: Icons.scale,
                      text: '${order.quantity?.toStringAsFixed(0) ?? '0'} لتر',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ======================
                // التاريخ + الوقت
                // ======================
                Row(
                  children: [
                    _simpleInfo(
                      icon: Icons.calendar_today,
                      text: DateFormat('yyyy/MM/dd').format(order.loadingDate),
                    ),
                    const SizedBox(width: 16),
                    _simpleInfo(
                      icon: Icons.access_time,
                      text: order.loadingTime,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // زر الإزالة
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.errorRed),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityInfo() {
    if (_selectedSupplierOrder == null || _selectedCustomerOrder == null) {
      return Container();
    }

    final isCompatible = _areOrdersCompatible();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompatible ? Icons.check_circle : Icons.warning,
                  color: isCompatible
                      ? AppColors.successGreen
                      : AppColors.errorRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isCompatible ? 'الطلبات متوافقة' : 'الطلبات غير متوافقة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompatible
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // تفاصيل التوافق
            _buildCompatibilityDetail(
              label: 'نوع الوقود',
              supplierValue: _selectedSupplierOrder!.fuelType ?? 'غير محدد',
              customerValue: _selectedCustomerOrder!.fuelType ?? 'غير محدد',
              isCompatible:
                  _selectedSupplierOrder!.fuelType ==
                  _selectedCustomerOrder!.fuelType,
            ),

            _buildCompatibilityDetail(
              label: 'الكمية',
              supplierValue:
                  '${_selectedSupplierOrder!.quantity?.toStringAsFixed(0) ?? '0'} لتر',
              customerValue:
                  '${_selectedCustomerOrder!.quantity?.toStringAsFixed(0) ?? '0'} لتر',
              isCompatible:
                  (_selectedSupplierOrder!.quantity ?? 0) >=
                  (_selectedCustomerOrder!.quantity ?? 0),
            ),

            _buildCompatibilityDetail(
              label: 'وقت التحميل/الوصول',
              supplierValue:
                  '${DateFormat('yyyy/MM/dd').format(_selectedSupplierOrder!.loadingDate)} ${_selectedSupplierOrder!.loadingTime}',
              customerValue:
                  '${DateFormat('yyyy/MM/dd').format(_selectedCustomerOrder!.arrivalDate)} ${_selectedCustomerOrder!.arrivalTime}',
              isCompatible: !_selectedSupplierOrder!.loadingDate.isAfter(
                _selectedCustomerOrder!.arrivalDate,
              ),
            ),

            if (!isCompatible)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'ملاحظة: يجب أن تكون الكمية المتوفرة لدى المورد أكبر من أو تساوي كمية طلب العميل، وأن يكون وقت التحميل بعد وقت الوصول',
                  style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityDetail({
    required String label,
    required String supplierValue,
    required String customerValue,
    required bool isCompatible,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompatible ? Icons.check : Icons.close,
            color: isCompatible ? AppColors.successGreen : AppColors.errorRed,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'المورد: $supplierValue',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'العميل: $customerValue',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergeButton() {
    final isCompatible = _areOrdersCompatible();
    final orderProvider = Provider.of<OrderProvider>(context);

    return GradientButton(
      onPressed:
          (_selectedSupplierOrder != null &&
              _selectedCustomerOrder != null &&
              isCompatible &&
              !orderProvider.isLoading)
          ? _mergeOrders
          : null,
      text: orderProvider.isLoading ? 'جاري الدمج...' : 'دمج الطلبات',
      gradient: AppColors.accentGradient,
      isLoading: orderProvider.isLoading,
    );
  }

  // ============================================
  // 🏗️ بناء الواجهة الرئيسية
  // ============================================
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('دمج الطلبات'), centerTitle: true),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }
}
