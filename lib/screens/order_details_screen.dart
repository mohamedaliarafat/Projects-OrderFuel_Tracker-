// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_tracker/models/customer_model.dart';
import 'package:order_tracker/models/driver_model.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/models/supplier_model.dart';
import 'package:order_tracker/providers/order_provider.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/activity_item.dart';
import 'package:order_tracker/widgets/attachment_item.dart';
import 'package:order_tracker/widgets/order_status_timeline.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedTab = 0;
  pw.Font? _arabicFont;
  bool _isFontLoaded = false;
  Supplier? _supplier;

  Timer? _countdownTimer;
  Duration? _remainingLoadingTime;
  Uint8List? _companyLogo;
  pw.Font? _cairoRegular;
  pw.Font? _cairoBold;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
      _loadCompanyLogo();
      _loadSupplierDetails();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCompanyLogo() async {
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      _companyLogo = logoData.buffer.asUint8List();
    } catch (_) {
      _companyLogo = null;
    }
  }

  Future<void> _loadSupplierDetails() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.selectedOrder;

    if (order != null &&
        order.supplierId != null &&
        order.supplierId!.isNotEmpty) {
      // هنا يمكنك جلب تفاصيل المورد من الـ Provider الخاص بالموردين
      // هذا مثال افتراضي - قم بتعديله حسب بنية تطبيقك
      try {
        // قم بجلب المورد باستخدام الـ supplierId
        // _supplier = await supplierProvider.getSupplierById(order.supplierId!);
      } catch (e) {
        debugPrint('Error loading supplier: $e');
      }
    }
  }

  void _startCountdown(Order order) {
    _countdownTimer?.cancel();

    try {
      DateTime loadingDateTime = DateTime(
        order.loadingDate.year,
        order.loadingDate.month,
        order.loadingDate.day,
        int.parse(order.loadingTime.split(':')[0]),
        int.parse(order.loadingTime.split(':')[1]),
      );

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        final diff = loadingDateTime.difference(DateTime.now());

        if (diff.isNegative || order.status == 'تم التنفيذ') {
          timer.cancel();
          setState(() {
            _remainingLoadingTime = Duration.zero;
          });
        } else {
          setState(() {
            _remainingLoadingTime = diff;
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting countdown: $e');
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) {
      return 'انتهى الوقت';
    }

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final parts = <String>[];

    if (days > 0) parts.add('$days يوم');
    if (hours > 0 || days > 0) parts.add('$hours ساعة');
    if (minutes > 0 || hours > 0 || days > 0) parts.add('$minutes دقيقة');
    parts.add('$seconds ثانية');

    return parts.join(' ');
  }

  Future<void> _loadOrderDetails() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    await provider.fetchOrderById(widget.orderId);

    final order = provider.selectedOrder;
    if (order != null && order.status != 'تم التنفيذ') {
      _startCountdown(order);
    }
  }

  Future<void> _loadArabicFont() async {
    if (_cairoRegular != null && _cairoBold != null) return;

    try {
      final regularData = await rootBundle.load(
        'assets/fonts/Cairo-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

      _cairoRegular = pw.Font.ttf(regularData);
      _cairoBold = pw.Font.ttf(boldData);
    } catch (e) {
      debugPrint('❌ Error loading Cairo font: $e');
      _cairoRegular = pw.Font.courier();
      _cairoBold = pw.Font.courierBold();
    }
  }

  // تحديد نوع الطلب
  String _getOrderType(Order order) {
    if (order.mergeStatus == 'مدمج') return 'مدمج';
    if (order.requestType == 'مورد' || order.isSupplierOrder) return 'مورد';
    if (order.requestType == 'عميل') return 'عميل';
    if (order.customer != null) return 'عميل';
    return 'مورد';
  }

  String _safeOrderType([Order? order]) {
    final o = order ?? context.read<OrderProvider>().selectedOrder;
    if (o == null) return 'غير معروف';
    return _getOrderType(o);
  }

  // تحديد لون حسب نوع الطلب
  Color _getOrderTypeColor(String type) {
    switch (type) {
      case 'مورد':
        return AppColors.primaryBlue;
      case 'عميل':
        return AppColors.secondaryTeal;
      case 'مدمج':
        return AppColors.successGreen;
      default:
        return AppColors.mediumGray;
    }
  }

  pw.Widget _buildPdfHeader({
    required Uint8List? logo,
    required String crNumber,
    required String vatNumber,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // ================= LEFT SIDE (ENGLISH) =================
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Commercial Register',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  crNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'VAT Number',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  vatNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),

          // ================= CENTER (LOGO) =================
          pw.Container(
            width: 80,
            height: 80,
            alignment: pw.Alignment.center,
            child: logo != null
                ? pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain)
                : pw.Container(
                    width: 80,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Logo',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ),
                  ),
          ),

          // ================= RIGHT SIDE (ARABIC) =================
          pw.Expanded(
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'السجل التجاري',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    crNumber,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'الرقم الضريبي',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    vatNumber,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter({
    required String address,
    required String phone,
    required String email,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        margin: const pw.EdgeInsets.only(top: 30),
        padding: const pw.EdgeInsets.only(top: 16),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 1),
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              address,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'هاتف: $phone  |  Email: $email',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '© ${DateTime.now().year} جميع الحقوق محفوظة',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // عرض خيارات التصدير
  void _showExportOptions() {
    final order = Provider.of<OrderProvider>(
      context,
      listen: false,
    ).selectedOrder;
    if (order == null) return;

    final orderType = _safeOrderType(order); // ✅ مهم

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'خيارات التصدير',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),

              // بطاقة نوع التقرير
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        orderType == 'مورد'
                            ? Icons.business
                            : orderType == 'عميل'
                            ? Icons.person
                            : Icons.link,
                        color: _getOrderTypeColor(orderType),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير $orderType',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'رقم الطلب: ${order.orderNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getOrderTypeColor(orderType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getOrderTypeColor(orderType),
                          ),
                        ),
                        child: Text(
                          orderType,
                          style: TextStyle(
                            color: _getOrderTypeColor(orderType),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('تقرير تفصيلي (PDF)'),
                subtitle: const Text('تقرير كامل مع جميع التفاصيل'),
                onTap: () async {
                  Navigator.pop(context);
                  await _exportToDetailedPDF();
                },
              ),

              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                title: const Text('تقرير سريع (PDF)'),
                subtitle: const Text('ملخص الطلب الرئيسي فقط'),
                onTap: () async {
                  Navigator.pop(context);
                  await _exportToQuickPDF();
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.share, color: AppColors.successGreen),
                title: const Text('مشاركة التقرير'),
                onTap: () {
                  Navigator.pop(context);
                  _shareOrderDetails();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PDF Export Functions
  // ============================================

  Future<void> _exportToDetailedPDF() async {
    try {
      // ✅ جلب الطلب بدون listen
      final order = context.read<OrderProvider>().selectedOrder;
      if (order == null) return;

      // ✅ تحميل الخط العربي واللوجو (لو مش محمّلين)
      await _loadArabicFont();
      await _loadCompanyLogo();

      // ✅ تحديد نوع الطلب مرة واحدة
      final orderType = _safeOrderType(order);

      // ✅ إنشاء المستند
      final pdf = pw.Document();

      // صفحة الغلاف
      pdf.addPage(_buildCoverPage(order));

      // صفحة التفاصيل
      pdf.addPage(_buildDetailsPage(order));

      // ✅ مشاركة الـ PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            '${orderType}_طلب_${order.orderNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint('❌ Error exporting PDF: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير PDF'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _exportToQuickPDF() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.selectedOrder;
    final orderType = _safeOrderType(order);

    if (order == null) return;

    await _loadArabicFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: _cairoRegular!, bold: _cairoBold!),

        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // عنوان التقرير
                  pw.Text(
                    'ملخص طلب $orderType',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(AppColors.primaryBlue.value),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 30),

                  // معلومات الطلب الرئيسية
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(10),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        _buildPdfDetailRow('رقم الطلب', order.orderNumber),
                        pw.SizedBox(height: 10),
                        _buildPdfDetailRow('نوع الطلب', orderType),
                        _buildPdfDetailRow('نوع العملية', order.requestType),

                        pw.SizedBox(height: 10),
                        _buildPdfDetailRow('الحالة', order.status),
                        pw.SizedBox(height: 10),
                        _buildPdfDetailRow(
                          'تاريخ الطلب',
                          DateFormat('yyyy/MM/dd').format(order.orderDate),
                        ),
                        pw.SizedBox(height: 10),
                        if (order.supplierName != null)
                          _buildPdfDetailRow('المورد', order.supplierName!),
                        if (order.customer != null)
                          _buildPdfDetailRow('العميل', order.customer!.name),
                        if (order.fuelType != null)
                          _buildPdfDetailRow('نوع الوقود', order.fuelType!),
                        if (order.quantity != null)
                          _buildPdfDetailRow(
                            'الكمية',
                            '${order.quantity} ${order.unit ?? "لتر"}',
                          ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 30),

                  // تذييل الصفحة
                  _buildFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'ملخص_${orderType}_طلب_${order.orderNumber}.pdf',
      );
    } catch (e) {
      debugPrint('Error exporting quick PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير PDF: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // ============================================
  // Helper Functions for PDF Building
  // ============================================

  pw.Page _buildCoverPage(Order order) {
    final orderType = _safeOrderType(order);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: _cairoRegular!, bold: _cairoBold!),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ================= HEADER =================
                _buildPdfHeader(
                  logo: _companyLogo,
                  crNumber: '7011144750', // ← عدّلها بالقيمة الحقيقية
                  vatNumber: '313061665400003', // ← عدّلها بالقيمة الحقيقية
                ),

                pw.SizedBox(height: 40),

                // ================= TITLE =================
                pw.Center(
                  child: pw.Text(
                    'تقرير طلب $orderType',
                    style: pw.TextStyle(
                      color: PdfColor.fromInt(AppColors.primaryBlue.value),
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.SizedBox(height: 16),

                // ================= ORDER NUMBER =================
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(AppColors.primaryBlue.value),
                      borderRadius: pw.BorderRadius.circular(30),
                    ),
                    child: pw.Text(
                      order.orderNumber,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 40),

                // ================= ORDER INFO CARD =================
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(16),
                  ),
                  child: pw.Column(
                    children: [
                      _buildPdfDetailRow('نوع الطلب', orderType),
                      _buildPdfDetailRow('الحالة', order.status),
                      _buildPdfDetailRow(
                        'تاريخ الطلب',
                        DateFormat('yyyy/MM/dd').format(order.orderDate),
                      ),
                      if (order.customer != null)
                        _buildPdfDetailRow('العميل', order.customer!.name),
                      if (order.supplierName != null)
                        _buildPdfDetailRow('المورد', order.supplierName!),
                      _buildPdfDetailRow(
                        'تاريخ الإصدار',
                        DateFormat('yyyy/MM/dd').format(DateTime.now()),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ================= FOOTER =================
                _buildPdfFooter(
                  address: 'المملكة العربية السعودية - الرياض',
                  phone: '0555555555',
                  email: 'info@company.com',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  pw.Page _buildDetailsPage(Order order) {
    final orderType = _safeOrderType(order);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: _cairoRegular!, bold: _cairoBold!),

      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // عنوان الصفحة
                pw.Text(
                  'التفاصيل الكاملة للطلب',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(AppColors.primaryBlue.value),
                  ),
                ),

                pw.SizedBox(height: 30),

                // ====================================
                // 1️⃣ معلومات الطلب الأساسية
                // ====================================
                _buildPdfSection(
                  title: 'معلومات الطلب الأساسية',
                  children: [
                    _buildPdfDetailRow('رقم الطلب', order.orderNumber),
                    _buildPdfDetailRow('نوع الطلب', orderType),

                    // حالة الدمج
                    if (order.mergeStatus != null)
                      _buildPdfDetailRow('حالة الدمج', order.mergeStatus!),

                    _buildPdfDetailRow('الحالة', order.status),

                    // ✅ اسم العميل من الموديل الأساسي
                    if (order.customer != null &&
                        order.customer!.name.isNotEmpty)
                      _buildPdfDetailRow('اسم العميل', order.customer!.name),

                    // ✅ اسم السائق من الموديل الأساسي
                    if (order.driverName != null &&
                        order.driverName!.isNotEmpty)
                      _buildPdfDetailRow('اسم السائق', order.driverName!),

                    _buildPdfDetailRow(
                      'تاريخ الطلب',
                      DateFormat('yyyy/MM/dd').format(order.orderDate),
                    ),
                    _buildPdfDetailRow(
                      'تاريخ الإنشاء',
                      DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt),
                    ),
                    _buildPdfDetailRow(
                      'آخر تحديث',
                      DateFormat('yyyy/MM/dd HH:mm').format(order.updatedAt),
                    ),

                    // رقم طلب المورد
                    if (order.supplierOrderNumber != null &&
                        order.supplierOrderNumber!.isNotEmpty)
                      _buildPdfDetailRow(
                        'رقم طلب المورد',
                        order.supplierOrderNumber!,
                      ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // ====================================
                // 2️⃣ معلومات العميل (مفصلة)
                // ====================================
                if (order.customer != null && order.customer!.name.isNotEmpty)
                  _buildPdfSection(
                    title: 'معلومات العميل',
                    children: [
                      // ✅ اسم العميل مرة أخرى للتركيز
                      _buildPdfDetailRow('اسم العميل', order.customer!.name),

                      if (order.customer!.code != null &&
                          order.customer!.code!.isNotEmpty)
                        _buildPdfDetailRow('كود العميل', order.customer!.code!),

                      if (order.customer!.phone != null &&
                          order.customer!.phone!.isNotEmpty)
                        _buildPdfDetailRow(
                          'هاتف العميل',
                          order.customer!.phone!,
                        ),

                      if (order.customer!.email != null &&
                          order.customer!.email!.isNotEmpty)
                        _buildPdfDetailRow(
                          'البريد الإلكتروني',
                          order.customer!.email!,
                        ),

                      if (order.customer!.address != null &&
                          order.customer!.address!.isNotEmpty)
                        _buildPdfDetailRow('العنوان', order.customer!.address!),

                      if (order.customer!.contactPerson != null &&
                          order.customer!.contactPerson!.isNotEmpty)
                        _buildPdfDetailRow(
                          'جهة الاتصال',
                          order.customer!.contactPerson!,
                        ),

                      if (order.customer!.contactPersonPhone != null &&
                          order.customer!.contactPersonPhone!.isNotEmpty)
                        _buildPdfDetailRow(
                          'هاتف جهة الاتصال',
                          order.customer!.contactPersonPhone!,
                        ),

                      if (order.customer!.notes != null &&
                          order.customer!.notes!.isNotEmpty)
                        _buildPdfDetailRow(
                          'ملاحظات العميل',
                          order.customer!.notes!,
                        ),
                    ],
                  ),

                // ====================================
                // 3️⃣ معلومات المورد
                // ====================================
                if (order.supplierName != null &&
                    order.supplierName!.isNotEmpty)
                  _buildPdfSection(
                    title: 'معلومات المورد',
                    children: [
                      _buildPdfDetailRow('اسم المورد', order.supplierName!),

                      if (order.supplierContactPerson != null &&
                          order.supplierContactPerson!.isNotEmpty)
                        _buildPdfDetailRow(
                          'جهة الاتصال',
                          order.supplierContactPerson!,
                        ),

                      if (order.supplierPhone != null &&
                          order.supplierPhone!.isNotEmpty)
                        _buildPdfDetailRow('هاتف المورد', order.supplierPhone!),

                      if (order.supplierCompany != null &&
                          order.supplierCompany!.isNotEmpty)
                        _buildPdfDetailRow('الشركة', order.supplierCompany!),

                      // معلومات المورد الإضافية من كائن المورد
                      if (_supplier != null)
                        ..._buildSupplierDetails(_supplier!),
                    ],
                  ),

                pw.SizedBox(height: 20),

                // ====================================
                // 4️⃣ معلومات السائق (مفصلة)
                // ====================================
                if (order.driverName != null && order.driverName!.isNotEmpty)
                  _buildPdfSection(
                    title: 'معلومات السائق والمركبة',
                    children: [
                      // ✅ اسم السائق
                      _buildPdfDetailRow('اسم السائق', order.driverName!),

                      if (order.driverPhone != null &&
                          order.driverPhone!.isNotEmpty)
                        _buildPdfDetailRow('هاتف السائق', order.driverPhone!),

                      if (order.vehicleNumber != null &&
                          order.vehicleNumber!.isNotEmpty)
                        _buildPdfDetailRow('رقم المركبة', order.vehicleNumber!),
                    ],
                  ),

                pw.SizedBox(height: 20),

                // ====================================
                // 5️⃣ معلومات الموقع
                // ====================================
                _buildPdfSection(
                  title: 'معلومات الموقع',
                  children: [
                    _buildPdfDetailRow('المدينة', order.city ?? '-'),
                    _buildPdfDetailRow('المنطقة', order.area ?? '-'),
                    _buildPdfDetailRow('العنوان', order.address ?? '-'),
                  ],
                ),

                pw.SizedBox(height: 20),

                // ====================================
                // 6️⃣ معلومات الوقود
                // ====================================
                _buildPdfSection(
                  title: 'معلومات الوقود',
                  children: [
                    _buildPdfDetailRow('نوع الوقود', order.fuelType ?? '-'),
                    _buildPdfDetailRow(
                      'الكمية',
                      '${order.quantity?.toStringAsFixed(0) ?? '0'} ${order.unit ?? 'لتر'}',
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // ====================================
                // 7️⃣ معلومات التواريخ والأوقات
                // ====================================
                _buildPdfSection(
                  title: 'المواعيد والتواريخ',
                  children: [
                    _buildPdfDetailRow(
                      'تاريخ الطلب',
                      DateFormat('yyyy/MM/dd').format(order.orderDate),
                    ),
                    _buildPdfDetailRow(
                      'تاريخ الوصول',
                      DateFormat('yyyy/MM/dd').format(order.arrivalDate),
                    ),
                    _buildPdfDetailRow('وقت الوصول', order.arrivalTime),
                    _buildPdfDetailRow(
                      'تاريخ التحميل',
                      DateFormat('yyyy/MM/dd').format(order.loadingDate),
                    ),
                    _buildPdfDetailRow('وقت التحميل', order.loadingTime),

                    // معلومات التتبع
                    if (order.actualArrivalTime != null)
                      _buildPdfDetailRow(
                        'وقت الوصول الفعلي',
                        order.actualArrivalTime!,
                      ),

                    if (order.loadingDuration != null)
                      _buildPdfDetailRow(
                        'مدة التحميل',
                        '${order.loadingDuration} دقيقة',
                      ),

                    if (order.delayReason != null &&
                        order.delayReason!.isNotEmpty)
                      _buildPdfDetailRow('سبب التأخير', order.delayReason!),
                  ],
                ),

                // ====================================
                // 8️⃣ معلومات المنشئ
                // ====================================
                if (order.createdByName != null &&
                    order.createdByName!.isNotEmpty)
                  _buildPdfSection(
                    title: 'معلومات الإنشاء',
                    children: [
                      _buildPdfDetailRow(
                        'تم الإنشاء بواسطة',
                        order.createdByName!,
                      ),
                    ],
                  ),

                // ====================================
                // 9️⃣ الملاحظات
                // ====================================
                if (order.notes != null && order.notes!.isNotEmpty)
                  _buildPdfSection(
                    title: 'ملاحظات',
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          order.notes!,
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                // ====================================
                // 🔟 معلومات خاصة بالدمج
                // ====================================
                if (orderType == 'مدمج')
                  _buildPdfSection(
                    title: 'معلومات خاصة بالدمج',
                    children: [
                      _buildPdfDetailRow('نوع الطلب', 'طلب مدمج'),

                      // ✅ تظهر المورد والعميل معاً
                      if (order.supplierName != null && order.customer != null)
                        _buildPdfDetailRow(
                          'المورد والعميل',
                          '${order.supplierName!} ← ${order.customer!.name}',
                        ),

                      // ✅ تظهر معلومات السائق في قسم الدمج أيضاً
                      if (order.driverName != null)
                        _buildPdfDetailRow('السائق المسؤول', order.driverName!),

                      _buildPdfDetailRow('نوع العملية', order.requestType),

                      _buildPdfDetailRow(
                        'تاريخ الدمج',
                        DateFormat('yyyy/MM/dd HH:mm').format(order.updatedAt),
                      ),

                      // ملخص الدمج
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        margin: const pw.EdgeInsets.only(top: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ملخص الدمج:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            if (order.customer != null)
                              pw.Text(
                                '• العميل: ${order.customer!.name}',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            if (order.supplierName != null)
                              pw.Text(
                                '• المورد: ${order.supplierName!}',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            if (order.driverName != null)
                              pw.Text(
                                '• السائق: ${order.driverName!}',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            pw.Text(
                              '• رقم الطلب المدمج: ${order.orderNumber}',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // ====================================
                // 1️⃣1️⃣ المرفقات
                // ====================================
                if (order.attachments.isNotEmpty)
                  _buildPdfSection(
                    title: 'المرفقات',
                    children: [
                      pw.Text(
                        'عدد المرفقات: ${order.attachments.length}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 8),
                      for (var attachment in order.attachments)
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                '• ',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  attachment.filename,
                                  style: const pw.TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // دوال مساعدة لإضافة تفاصيل إضافية
  // ============================================

  List<pw.Widget> _buildSupplierDetails(Supplier supplier) {
    final widgets = <pw.Widget>[];

    if (supplier.city != null && supplier.city!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('مدينة المورد', supplier.city!));
    }

    if (supplier.address != null && supplier.address!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('عنوان المورد', supplier.address!));
    }

    if (supplier.email != null && supplier.email!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('بريد المورد', supplier.email!));
    }

    if (supplier.taxNumber != null && supplier.taxNumber!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('الرقم الضريبي', supplier.taxNumber!));
    }

    return widgets;
  }

  List<pw.Widget> _buildDriverDetails(Driver driver) {
    final widgets = <pw.Widget>[];

    if (driver.licenseNumber != null && driver.licenseNumber!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('رقم الرخصة', driver.licenseNumber!));
    }

    if (driver.email != null && driver.email!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('بريد السائق', driver.email!));
    }

    if (driver.address != null && driver.address!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('عنوان السائق', driver.address!));
    }

    if (driver.vehicleType != null && driver.vehicleType!.isNotEmpty) {
      widgets.add(_buildPdfDetailRow('نوع المركبة', driver.vehicleType!));
    }

    if (driver.licenseExpiryDate != null) {
      widgets.add(
        _buildPdfDetailRow(
          'تاريخ انتهاء الرخصة',
          DateFormat('yyyy/MM/dd').format(driver.licenseExpiryDate!),
        ),
      );
    }

    return widgets;
  }

  // ============================================
  // دالة _buildPdfDetailRow محسنة
  // ============================================
  pw.Widget _buildPdfDetailRow(String label, dynamic value) {
    final String displayValue = value == null
        ? '-'
        : value is String
        ? value
        : value is Customer
        ? value.name
        : value is Supplier
        ? value.name
        : value is Driver
        ? '${value.name} - ${value.phone}' // عرض اسم السائق وهاتفه
        : value.toString();

    return pw.Directionality(
      textDirection: pw.TextDirection.rtl, // ✅ مهم جدًا
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 🔹 العنوان (يمين)
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                '$label:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),

            // 🔹 القيمة (يسار العنوان)
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                displayValue,
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Helper Widgets for PDF
  // ============================================

  pw.Widget _buildPdfSection({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.darkGray.value),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(children: children),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl, // ✅ مهم
      child: pw.Container(
        margin: const pw.EdgeInsets.only(top: 30),
        padding: const pw.EdgeInsets.only(top: 16),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 1),
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              'تم إنشاء هذا التقرير بواسطة نظام متابعة طلبات الوقود',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'جميع الحقوق محفوظة © ${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Other Helper Functions
  // ============================================

  void _shareOrderDetails() {
    // يمكن استخدام حزمة share_plus هنا
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سيتم تفعيل المشاركة في تحديثات لاحقة'),
          backgroundColor: AppColors.infoBlue,
        ),
      );
    }
  }

  void _showDeleteDialog() {
    final order = Provider.of<OrderProvider>(
      context,
      listen: false,
    ).selectedOrder;
    if (order == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: Text(
          'هل أنت متأكد من حذف الطلب ${order.orderNumber}؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final orderProvider = Provider.of<OrderProvider>(
                context,
                listen: false,
              );
              final success = await orderProvider.deleteOrder(widget.orderId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الطلب بنجاح'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttachment(String attachmentId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.deleteAttachment(
      widget.orderId,
      attachmentId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المرفق بنجاح'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  // ============================================
  // UI Widgets
  // ============================================

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final order = orderProvider.selectedOrder;
    final activities = orderProvider.activities;

    if (orderProvider.isLoading && order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الطلب'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('الطلب غير موجود')),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 800;
    final orderType = _safeOrderType(order);
    final orderTypeColor = _getOrderTypeColor(orderType);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(isDesktop, order, orderType, orderTypeColor),
        body: isDesktop
            ? _buildDesktopLayout(
                context,
                order,
                activities,
                orderType,
                orderTypeColor,
              )
            : _buildMobileLayout(
                context,
                order,
                activities,
                orderType,
                orderTypeColor,
              ),
      ),
    );
  }

  AppBar _buildAppBar(
    bool isDesktop,
    Order order,
    String orderType,
    Color orderTypeColor,
  ) {
    return AppBar(
      title: isDesktop
          ? Row(
              children: [
                Text(
                  'تفاصيل الطلب - ${order.orderNumber}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: orderTypeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: orderTypeColor),
                  ),
                  child: Text(
                    orderType,
                    style: TextStyle(
                      color: orderTypeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    'الطلب ${order.orderNumber}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: orderTypeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: orderTypeColor),
                  ),
                  child: Text(
                    orderType,
                    style: TextStyle(
                      color: orderTypeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () {
            final orderType = _safeOrderType(order);

            Navigator.pushNamed(
              context,
              orderType == 'مورد'
                  ? AppRoutes.supplierOrderForm
                  : orderType == 'عميل'
                  ? AppRoutes.customerOrderForm
                  : AppRoutes.mergeOrders,
              arguments: order,
            );
          },
          icon: const Icon(Icons.edit),
          tooltip: 'تعديل',
        ),

        IconButton(
          onPressed: _showExportOptions,
          icon: const Icon(Icons.download),
          tooltip: 'تصدير',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog();
            }
          },
        ),
      ],
      bottom: TabBar(
        tabs: const [
          Tab(text: 'الملخص'),
          Tab(text: 'التفاصيل'),
          Tab(text: 'سجل الحركات'),
        ],
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Order order,
    List<Activity> activities,
    String orderType,
    Color orderTypeColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel for Order Details
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildOrderDetailsPanel(
              context,
              order,
              orderType,
              orderTypeColor,
            ),
          ),
        ),

        // Panel for Activities
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _buildActivitiesPanel(activities),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Order order,
    List<Activity> activities,
    String orderType,
    Color orderTypeColor,
  ) {
    return TabBarView(
      children: [
        _buildSummaryTab(context, order, orderType, orderTypeColor),
        _buildDetailsTab(context, order, orderType),
        _buildActivitiesTab(activities),
      ],
    );
  }

  Widget _buildSummaryTab(
    BuildContext context,
    Order order,
    String orderType,
    Color orderTypeColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Order Type Card - تم التعديل
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: orderTypeColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: orderTypeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          orderType == 'مورد'
                              ? Icons.business
                              : orderType == 'عميل'
                              ? Icons.person
                              : Icons.link,
                          color: orderTypeColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'طلب $orderType',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: orderTypeColor,
                              ),
                            ),
                            Text(
                              'رقم الطلب: ${order.orderNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.mediumGray,
                              ),
                            ),
                            // عرض رقم طلب المورد للطلبات المدمجة أو المورد
                            if ((orderType == 'مدمج' || orderType == 'مورد') &&
                                order.supplierOrderNumber != null &&
                                order.supplierOrderNumber!.isNotEmpty)
                              Text(
                                'رقم طلب المورد: ${order.supplierOrderNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.infoBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // إضافة معلومات إضافية للبطاقة
                  if (order.customer != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: orderTypeColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.customer!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (order.customer!.phone != null)
                                      Text(
                                        'هاتف: ${order.customer!.phone!}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    if (order.city != null)
                                      Text(
                                        'المدينة: ${order.city!}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    // عرض رقم طلب العميل إذا كان متوفراً
                                    if (order.orderNumber.startsWith('CUS-'))
                                      Text(
                                        'رقم طلب العميل: ${order.orderNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.successGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // إضافة معلومات المورد
                  if (order.supplierName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: orderTypeColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.supplierName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (order.supplierContactPerson != null)
                                      Text(
                                        'جهة الاتصال: ${order.supplierContactPerson!}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    if (order.supplierPhone != null)
                                      Text(
                                        'هاتف: ${order.supplierPhone!}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    if (_supplier?.city != null)
                                      Text(
                                        'المدينة: ${_supplier!.city!}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    if (order.city != null)
                                      Text(
                                        'موقع التسليم: ${order.city!}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    // عرض رقم طلب المورد
                                    if (order.supplierOrderNumber != null &&
                                        order.supplierOrderNumber!.isNotEmpty)
                                      Text(
                                        'رقم طلب المورد: ${order.supplierOrderNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    // أو عرض رقم الطلب إذا كان طلب مورد
                                    if (order.orderNumber.startsWith('SUP-'))
                                      Text(
                                        'رقم طلب المورد: ${order.orderNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Timeline
          OrderStatusTimeline(order: order),

          const SizedBox(height: 16),

          // Countdown Timer
          if (_remainingLoadingTime != null && order.status != 'تم التنفيذ')
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.successGreen),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.successGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الوقت المتبقي حتى التحميل',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGray,
                            ),
                          ),
                          Text(
                            _formatDuration(_remainingLoadingTime!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Quick Info Grid - تم التعديل
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildInfoCard(
                icon: orderType == 'مورد' ? Icons.business : Icons.person,
                title: orderType == 'مورد' ? 'المورد' : 'العميل',
                value: orderType == 'مورد'
                    ? (order.supplierName ?? 'غير محدد')
                    : (order.customer?.name ?? 'غير محدد'),
                color: orderTypeColor,
              ),
              _buildInfoCard(
                icon: Icons.local_gas_station,
                title: 'نوع الوقود',
                value: order.fuelType ?? 'غير محدد',
                color: AppColors.warningOrange,
              ),
              _buildInfoCard(
                icon: Icons.scale,
                title: 'الكمية',
                value:
                    '${order.quantity?.toStringAsFixed(0) ?? '0'} ${order.unit ?? 'لتر'}',
                color: AppColors.infoBlue,
              ),
              _buildInfoCard(
                icon: Icons.date_range,
                title: 'تاريخ التحميل',
                value: DateFormat('yyyy/MM/dd').format(order.loadingDate),
                color: AppColors.pendingYellow,
              ),
              if (order.city != null)
                _buildInfoCard(
                  icon: Icons.location_city,
                  title: 'مدينة التسليم',
                  value: order.city!,
                  color: AppColors.secondaryTeal,
                ),
              if (order.area != null)
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'منطقة التسليم',
                  value: order.area!,
                  color: AppColors.primaryBlue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, Order order, String orderType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الطلب الأساسية
          _buildInfoSection(
            title: 'معلومات الطلب الأساسية',
            icon: Icons.info,
            color: AppColors.primaryBlue,
            children: [
              _buildDetailRow('رقم الطلب', order.orderNumber),
              if (order.supplierOrderNumber != null &&
                  order.supplierOrderNumber!.isNotEmpty)
                _buildDetailRow('رقم طلب المورد', order.supplierOrderNumber!),
              _buildDetailRow('نوع الطلب', orderType),
              _buildDetailRow('نوع العملية', order.requestType),

              _buildDetailRow('الحالة', order.status),
              _buildDetailRow(
                'تاريخ الإنشاء',
                DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt),
              ),
              _buildDetailRow(
                'آخر تحديث',
                DateFormat('yyyy/MM/dd HH:mm').format(order.updatedAt),
              ),
              // عرض أرقام الطلبات حسب النوع
              if (orderType == 'مورد' && order.orderNumber.startsWith('SUP-'))
                _buildDetailRowWithIcon(
                  'رقم طلب المورد',
                  order.orderNumber,
                  Icons.business,
                  AppColors.primaryBlue,
                ),
              if (orderType == 'عميل' && order.orderNumber.startsWith('CUS-'))
                _buildDetailRowWithIcon(
                  'رقم طلب العميل',
                  order.orderNumber,
                  Icons.person,
                  AppColors.secondaryTeal,
                ),
              if (orderType == 'مدمج' && order.orderNumber.startsWith('MIX-'))
                _buildDetailRowWithIcon(
                  'رقم الطلب المدمج',
                  order.orderNumber,
                  Icons.link,
                  AppColors.successGreen,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Customer Information - تم التعديل
          if (order.customer != null)
            _buildInfoSection(
              title: 'معلومات العميل',
              icon: Icons.person,
              color: AppColors.secondaryTeal,
              children: [
                _buildDetailRow('اسم العميل', order.customer!.name),
                if (order.customer!.code != null)
                  _buildDetailRow('كود العميل', order.customer!.code),
                if (order.customer!.phone != null)
                  _buildDetailRow('هاتف العميل', order.customer!.phone!),
                if (order.customer!.email != null)
                  _buildDetailRow('البريد الإلكتروني', order.customer!.email!),
                if (order.customer!.address != null)
                  _buildDetailRow('العنوان', order.customer!.address!),
                if (order.city != null) _buildDetailRow('المدينة', order.city!),
                if (order.area != null) _buildDetailRow('المنطقة', order.area!),
                // عرض رقم طلب العميل بشكل مميز
                if (order.orderNumber.startsWith('CUS-'))
                  _buildDetailRowWithIcon(
                    'رقم طلب العميل',
                    order.orderNumber,
                    Icons.confirmation_number,
                    AppColors.successGreen,
                  ),
              ],
            ),

          if (order.customer != null) const SizedBox(height: 16),

          // Supplier Information - تم التحديث بإضافة المدينة والعنوان
          if (order.supplierName != null)
            _buildInfoSection(
              title: 'معلومات المورد',
              icon: Icons.business,
              color: AppColors.primaryBlue,
              children: [
                _buildDetailRow('اسم المورد', order.supplierName!),
                if (order.supplierContactPerson != null)
                  _buildDetailRow('جهة الاتصال', order.supplierContactPerson!),
                if (order.supplierPhone != null)
                  _buildDetailRow('هاتف المورد', order.supplierPhone!),
                if (order.supplierCompany != null)
                  _buildDetailRow('الشركة', order.supplierCompany!),
                if (_supplier?.city != null)
                  _buildDetailRow('المدينة', _supplier!.city!),
                if (_supplier?.address != null)
                  _buildDetailRow('العنوان', _supplier!.address!),
                // عرض رقم طلب المورد بشكل بارز
                if (order.supplierOrderNumber != null &&
                    order.supplierOrderNumber!.isNotEmpty)
                  _buildDetailRowWithIcon(
                    'رقم طلب المورد',
                    order.supplierOrderNumber!,
                    Icons.confirmation_number,
                    AppColors.primaryBlue,
                  )
                else if (order.orderNumber.startsWith('SUP-'))
                  _buildDetailRowWithIcon(
                    'رقم طلب المورد',
                    order.orderNumber,
                    Icons.confirmation_number,
                    AppColors.primaryBlue,
                  ),
                if (order.supplierOrderNumber != null &&
                    order.supplierOrderNumber!.isNotEmpty)
                  _buildDetailRow('رقم طلب المورد', order.supplierOrderNumber!),
                if (order.city != null && order.area != null)
                  _buildDetailRow(
                    'موقع التسليم',
                    '${order.city!} - ${order.area!}',
                  ),
              ],
            ),

          if (order.supplierName != null) const SizedBox(height: 16),

          // Fuel Information
          _buildInfoSection(
            title: 'معلومات الوقود',
            icon: Icons.local_gas_station,
            color: AppColors.warningOrange,
            children: [
              _buildDetailRow('نوع الوقود', order.fuelType ?? 'غير محدد'),
              _buildDetailRow(
                'الكمية',
                '${order.quantity?.toStringAsFixed(0) ?? '0'} ${order.unit ?? 'لتر'}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dates & Times
          _buildInfoSection(
            title: 'المواعيد',
            icon: Icons.access_time,
            color: AppColors.infoBlue,
            children: [
              _buildDetailRow(
                'تاريخ الطلب',
                DateFormat('yyyy/MM/dd').format(order.orderDate),
              ),
              _buildDetailRow(
                'تاريخ الوصول',
                DateFormat('yyyy/MM/dd').format(order.arrivalDate),
              ),
              _buildDetailRow('وقت الوصول', order.arrivalTime),
              _buildDetailRow(
                'تاريخ التحميل',
                DateFormat('yyyy/MM/dd').format(order.loadingDate),
              ),
              _buildDetailRow('وقت التحميل', order.loadingTime),
              if (order.actualArrivalTime != null)
                _buildDetailRow('وقت الوصول الفعلي', order.actualArrivalTime!),
              if (order.loadingDuration != null)
                _buildDetailRow(
                  'مدة التحميل',
                  '${order.loadingDuration} دقيقة',
                ),
              if (order.delayReason != null && order.delayReason!.isNotEmpty)
                _buildDetailRow('سبب التأخير', order.delayReason!),
            ],
          ),

          const SizedBox(height: 16),

          // Driver Information
          if (order.driverName != null)
            _buildInfoSection(
              title: 'معلومات السائق',
              icon: Icons.directions_car,
              color: AppColors.secondaryTeal,
              children: [
                _buildDetailRow('اسم السائق', order.driverName!),
                if (order.driverPhone != null)
                  _buildDetailRow('هاتف السائق', order.driverPhone!),
                if (order.vehicleNumber != null)
                  _buildDetailRow('رقم المركبة', order.vehicleNumber!),
              ],
            ),

          const SizedBox(height: 16),

          // Notes
          if (order.notes != null && order.notes!.isNotEmpty)
            _buildInfoSection(
              title: 'ملاحظات',
              icon: Icons.note,
              color: AppColors.mediumGray,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    order.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Attachments
          if (order.attachments.isNotEmpty)
            _buildInfoSection(
              title: 'المرفقات',
              icon: Icons.attach_file,
              color: AppColors.primaryBlue,
              children: [
                ...order.attachments.map(
                  (attachment) => AttachmentItem(
                    fileName: attachment.filename,
                    fileSize: 'موجود على السيرفر',
                    onDelete: () {
                      _deleteAttachment(attachment.id);
                    },
                    canDelete: true,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsPanel(
    BuildContext context,
    Order order,
    String orderType,
    Color orderTypeColor,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryTab(context, order, orderType, orderTypeColor),
          const SizedBox(height: 24),
          _buildDetailsTab(context, order, orderType),
        ],
      ),
    );
  }

  Widget _buildActivitiesPanel(List<Activity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'سجل الحركات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        if (activities.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد حركات مسجلة',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrderDetails,
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return ActivityItem(activity: activities[index]);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivitiesTab(List<Activity> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد حركات مسجلة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderDetails,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return ActivityItem(activity: activities[index]);
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.darkGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithIcon(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الانتظار':
      case 'في انتظار إنشاء طلب العميل':
      case 'في انتظار عمل طلب جديد':
        return AppColors.pendingYellow;
      case 'مخصص للعميل':
      case 'تم إنشاء الطلب':
        return AppColors.infoBlue;
      case 'في انتظار التحميل':
      case 'جاهز للتحميل':
        return AppColors.warningOrange;
      case 'تم التنفيذ':
      case 'تم التسليم':
        return AppColors.successGreen;
      case 'ملغى':
      case 'ملغي - تأخر التحميل':
        return AppColors.errorRed;
      case 'تأخير في الوصول':
        return Colors.orange;
      default:
        return AppColors.lightGray;
    }
  }
}
