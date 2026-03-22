import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/report_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/reports/export_options.dart';
import 'package:order_tracker/widgets/app_soft_background.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceReportScreen extends StatefulWidget {
  static const routeName = '/reports/invoice';

  const InvoiceReportScreen({super.key});

  @override
  State<InvoiceReportScreen> createState() => _InvoiceReportScreenState();
}

class _InvoiceReportScreenState extends State<InvoiceReportScreen> {
  final ReportProvider _reportProvider = ReportProvider();
  final TextEditingController _orderIdController = TextEditingController();

  Map<String, dynamic>? _invoiceData;
  bool _isLoading = false;
  String? _error;
  bool _isPrinting = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoice(String orderId) async {
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال رقم الطلب')));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _invoiceData = null;
    });

    try {
      final response = await _reportProvider.invoiceReport(orderId);
      setState(() {
        _invoiceData = response['invoice'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToPDF() async {
    if (_invoiceData == null) return;

    try {
      final pdfData = await _reportProvider.exportPDF(
        reportType: 'invoice',
        filters: {'orderId': _invoiceData!['order']['_id']},
      );

      await Printing.layoutPdf(onLayout: (format) => pdfData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء الفاتورة')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل إنشاء الفاتورة: $e')));
    }
  }

  Future<void> _printInvoice() async {
    if (_invoiceData == null) return;

    setState(() => _isPrinting = true);

    try {
      final pdf = await _generatePDF();
      await Printing.layoutPdf(onLayout: (format) => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الفاتورة للطباعة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الطباعة: $e')));
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final invoice = _invoiceData!;
    final order = invoice['order'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'فاتورة ضريبية',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('رقم الفاتورة: ${invoice['invoiceNumber']}'),
                      pw.Text(
                        'تاريخ الفاتورة: ${_formatDate(invoice['invoiceDate'])}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('نظام متابعة طلبات الوقود'),
                      pw.Text('السعودية'),
                      pw.Text('الرقم الضريبي: 123456789'),
                    ],
                  ),
                ],
              ),

              pw.Divider(),

              // Order Info
              pw.SizedBox(height: 20),
              pw.Text(
                'معلومات الطلب',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('رقم الطلب: ${order['orderNumber']}'),
                      pw.Text(
                        'تاريخ الطلب: ${_formatDate(order['orderDate'])}',
                      ),
                      pw.Text('حالة الطلب: ${order['status']}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('نوع الطلب: ${order['orderSource']}'),
                      pw.Text('وقت التحميل: ${order['loadingTime']}'),
                      pw.Text('وقت الوصول: ${order['arrivalTime']}'),
                    ],
                  ),
                ],
              ),

              // Supplier & Customer Info
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Supplier Info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'بيانات المورد',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text('الاسم: ${order['supplierName']}'),
                        pw.Text('الشركة: ${order['supplierCompany']}'),
                        pw.Text(
                          'جهة الاتصال: ${order['supplierContactPerson']}',
                        ),
                        pw.Text('الهاتف: ${order['supplierPhone']}'),
                        if (order['supplierAddress'] != null)
                          pw.Text('العنوان: ${order['supplierAddress']}'),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 20),

                  // Customer Info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'بيانات العميل',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text('الاسم: ${order['customerName']}'),
                        pw.Text('الكود: ${order['customerCode']}'),
                        if (order['customerPhone'] != null)
                          pw.Text('الهاتف: ${order['customerPhone']}'),
                        if (order['customerEmail'] != null)
                          pw.Text('البريد: ${order['customerEmail']}'),
                        if (order['address'] != null)
                          pw.Text('العنوان: ${order['address']}'),
                      ],
                    ),
                  ),
                ],
              ),

              // Driver Info
              if (order['driverName'] != null) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'بيانات السائق',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text('اسم السائق: ${order['driverName']}'),
                    pw.SizedBox(width: 20),
                    pw.Text('رقم المركبة: ${order['vehicleNumber']}'),
                    pw.SizedBox(width: 20),
                    if (order['driverPhone'] != null)
                      pw.Text('الهاتف: ${order['driverPhone']}'),
                  ],
                ),
              ],

              // Products Table
              pw.SizedBox(height: 20),
              pw.Text(
                'تفاصيل المنتجات',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('الوصف', textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'الكمية',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('السعر', textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'المجموع',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${order['fuelType'] ?? 'وقود'}'),
                            if (order['productType'] != null)
                              pw.Text(
                                'نوع المنتج: ${order['productType']}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            if (order['unit'] != null)
                              pw.Text(
                                'الوحدة: ${order['unit']}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${order['quantity'] ?? 0}',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${order['unitPrice'] ?? 0} ريال',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${order['totalPrice'] ?? 0} ريال',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Totals
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('المبلغ الإجمالي'),
                        pw.Text(
                          '${invoice['subtotal']?.toStringAsFixed(2) ?? '0.00'} ريال',
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('الضريبة (${invoice['taxRate']})'),
                        pw.Text(
                          '${invoice['tax']?.toStringAsFixed(2) ?? '0.00'} ريال',
                        ),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'المبلغ الإجمالي شامل الضريبة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${invoice['total']?.toStringAsFixed(2) ?? '0.00'} ريال',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Payment Info
              pw.SizedBox(height: 20),
              pw.Text(
                'معلومات الدفع',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Text(
                    'طريقة الدفع: ${order['paymentMethod'] ?? 'غير محدد'}',
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'حالة الدفع: ${order['paymentStatus'] ?? 'غير مدفوع'}',
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'تاريخ الاستحقاق: ${_formatDate(invoice['paymentDetails']['dueDate'])}',
                  ),
                ],
              ),

              // Footer
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('توقيع العميل'),
                      pw.Container(
                        width: 200,
                        height: 2,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('توقيع المورد'),
                      pw.Container(
                        width: 200,
                        height: 2,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),

              // Notes
              if (order['notes'] != null) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'ملاحظات',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(order['notes']!),
              ],
            ],
          );
        },
      ),
    );

    return pdf;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '--/--/----';
    try {
      return DateFormat('yyyy/MM/dd').format(DateTime.parse(date.toString()));
    } catch (e) {
      return '--/--/----';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الفواتير'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
        actions: [
          if (_invoiceData != null) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _isPrinting ? null : _printInvoice,
              tooltip: 'طباعة',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showExportOptions(),
              tooltip: 'مشاركة',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          const AppSoftBackground(),
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                            ? Center(
                                child: AppSurfaceCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.errorRed.withValues(
                                            alpha: 0.10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.errorRed
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.error_outline_rounded,
                                          size: 34,
                                          color: AppColors.errorRed,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF7F1D1D),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _invoiceData == null
                            ? Center(
                                child: AppSurfaceCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 44,
                                        color: AppColors.primaryBlue,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'ادخل رقم الطلب لعرض الفاتورة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _buildInvoiceContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'بحث عن فاتورة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.search_rounded,
                color: const Color(0xFF0F172A).withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;

              final field = TextField(
                controller: _orderIdController,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم الطلب',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF0F172A).withValues(alpha: 0.55),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.6,
                    ),
                  ),
                ),
                onSubmitted: (value) => _fetchInvoice(value),
              );

              final button = FilledButton.icon(
                onPressed: () => _fetchInvoice(_orderIdController.text),
                icon: const Icon(Icons.search_rounded),
                label: const Text('بحث'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 12), button],
                );
              }

              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 12),
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'مثال: CUS-20241231-0001, SUP-20241231-0001, MIX-20241231-0001',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceContent() {
    final invoice = _invoiceData!;
    final order = invoice['order'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Header
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.appBarGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.appBarWaterDeep.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'فاتورة ضريبية',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (invoice['invoiceNumber'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(invoice['invoiceDate']),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Order Info
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معلومات الطلب',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('رقم الطلب', order['orderNumber']),
                          _buildInfoItem(
                            'تاريخ الطلب',
                            _formatDate(order['orderDate']),
                          ),
                          _buildInfoItem('حالة الطلب', order['status']),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('نوع الطلب', order['orderSource']),
                          _buildInfoItem('وقت التحميل', order['loadingTime']),
                          _buildInfoItem('وقت الوصول', order['arrivalTime']),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Supplier & Customer Info
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              final supplierCard = AppSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات المورد',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('الاسم', order['supplierName']),
                    _buildInfoItem('الشركة', order['supplierCompany']),
                    _buildInfoItem(
                      'جهة الاتصال',
                      order['supplierContactPerson'],
                    ),
                    _buildInfoItem('الهاتف', order['supplierPhone']),
                    if (order['supplierAddress'] != null)
                      _buildInfoItem('العنوان', order['supplierAddress']),
                  ],
                ),
              );

              final customerCard = AppSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات العميل',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('الاسم', order['customerName']),
                    _buildInfoItem('الكود', order['customerCode']),
                    if (order['customerPhone'] != null)
                      _buildInfoItem('الهاتف', order['customerPhone']),
                    if (order['customerEmail'] != null)
                      _buildInfoItem('البريد', order['customerEmail']),
                    if (order['address'] != null)
                      _buildInfoItem('العنوان', order['address']),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    supplierCard,
                    const SizedBox(height: 16),
                    customerCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: supplierCard),
                  const SizedBox(width: 16),
                  Expanded(child: customerCard),
                ],
              );
            },
          ),

          // Driver Info
          if (order['driverName'] != null) ...[
            const SizedBox(height: 16),
            AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات السائق',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoItem('اسم السائق', order['driverName']),
                      const SizedBox(width: 20),
                      _buildInfoItem('رقم المركبة', order['vehicleNumber']),
                      const SizedBox(width: 20),
                      if (order['driverPhone'] != null)
                        _buildInfoItem('الهاتف', order['driverPhone']),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Products Table
          const SizedBox(height: 16),
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفاصيل المنتجات',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('الوصف')),
                      DataColumn(label: Text('الكمية')),
                      DataColumn(label: Text('السعر')),
                      DataColumn(label: Text('المجموع')),
                    ],
                    rows: [
                      DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['fuelType'] ?? 'وقود'),
                                if (order['productType'] != null)
                                  Text(
                                    'نوع المنتج: ${order['productType']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (order['unit'] != null)
                                  Text(
                                    'الوحدة: ${order['unit']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(Text('${order['quantity'] ?? 0}')),
                          DataCell(Text('${order['unitPrice'] ?? 0} ريال')),
                          DataCell(Text('${order['totalPrice'] ?? 0} ريال')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Totals
          const SizedBox(height: 16),
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإجماليات',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTotalRow(
                  'المبلغ الإجمالي',
                  '${invoice['subtotal']?.toStringAsFixed(2) ?? '0.00'} ريال',
                ),
                _buildTotalRow(
                  'الضريبة (${invoice['taxRate']})',
                  '${invoice['tax']?.toStringAsFixed(2) ?? '0.00'} ريال',
                ),
                const Divider(),
                _buildTotalRow(
                  'المبلغ الإجمالي شامل الضريبة',
                  '${invoice['total']?.toStringAsFixed(2) ?? '0.00'} ريال',
                  isBold: true,
                ),
              ],
            ),
          ),

          // Payment Info
          const SizedBox(height: 16),
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معلومات الدفع',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(
                      'طريقة الدفع',
                      order['paymentMethod'] ?? 'غير محدد',
                    ),
                    const SizedBox(width: 20),
                    _buildInfoItem(
                      'حالة الدفع',
                      order['paymentStatus'] ?? 'غير مدفوع',
                    ),
                    const SizedBox(width: 20),
                    _buildInfoItem(
                      'تاريخ الاستحقاق',
                      _formatDate(invoice['paymentDetails']['dueDate']),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notes
          if (order['notes'] != null) ...[
            const SizedBox(height: 16),
            AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملاحظات',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order['notes']!,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Signatures
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Container(width: 200, height: 1, color: Colors.black),
                  const SizedBox(height: 4),
                  const Text('توقيع العميل'),
                ],
              ),
              Column(
                children: [
                  Container(width: 200, height: 1, color: Colors.black),
                  const SizedBox(height: 4),
                  const Text('توقيع المورد'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '--',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ExportOptions(
          onExportPDF: _exportToPDF,
          onExportExcel: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سيتم إضافة تصدير Excel قريباً')),
            );
          },
        );
      },
    );
  }
}
