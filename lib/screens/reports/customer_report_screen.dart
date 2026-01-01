import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/report_provider.dart';
import 'package:order_tracker/providers/order_provider.dart'; // أضف هذا الاستيراد
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/reports/export_options.dart';
import 'package:order_tracker/widgets/reports/report_filters.dart';
import 'package:order_tracker/widgets/reports/report_summary.dart';
import 'package:printing/printing.dart';

class CustomerReportScreen extends StatefulWidget {
  static const routeName = '/reports/customers';

  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  final ReportProvider _reportProvider = ReportProvider();
  final OrderProvider _orderProvider = OrderProvider(); // أضف هذا
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _filters = {};
  List<dynamic> _customers = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _reportProvider.customerReports(
        filters: _filters,
        page: 1,
      );

      setState(() {
        _customers = response['customers'] ?? [];
        _summary = response['summary'] ?? {};
        _isLoading = false;
        _page = 2;
        _hasMore = _customers.length >= 20;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final response = await _reportProvider.customerReports(
        filters: _filters,
        page: _page,
      );

      final newCustomers = response['customers'] ?? [];
      setState(() {
        _customers.addAll(newCustomers);
        _isLoading = false;
        _page++;
        _hasMore = newCustomers.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFilters(Map<String, dynamic> filters) async {
    setState(() {
      _filters = filters;
      _page = 1;
      _hasMore = true;
    });
    await _loadInitialData();
  }

  Future<void> _exportToPDF() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final pdfBytes = await _reportProvider.exportPDF(
        reportType: 'customers',
        filters: _filters,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'customers_report.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تصدير PDF: $e')));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final bytes = await _reportProvider.exportExcel(
        reportType: 'customers',
        filters: _filters,
      );

      await Printing.sharePdf(bytes: bytes, filename: 'customers_report.xlsx');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تصدير التقرير إلى Excel')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200;
    final isMediumScreen = screenWidth >= 600;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterSheet,
            tooltip: 'فلاتر',
          ),
          if (isLargeScreen)
            _buildDesktopExportButton()
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _showExportOptions,
              tooltip: 'تصدير',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters Summary
          if (_filters.isNotEmpty) _buildFiltersSummary(),

          // Report Summary
          ReportSummary(
            title: 'ملخص تقرير العملاء',
            statistics: _summary,
            period: _filters,
          ),

          // Statistics Cards for Desktop
          if (isLargeScreen) _buildDesktopStatisticsCards(),

          // Customers List/Grid
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 64,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بيانات للعرض',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildCustomersView(isLargeScreen, isMediumScreen),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: _showCustomerDetailsDialog,
              child: const Icon(Icons.analytics),
              backgroundColor: AppColors.primaryBlue,
            )
          : null,
    );
  }

  Widget _buildDesktopExportButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'تصدير',
      onSelected: (value) {
        if (value == 'pdf') {
          _exportToPDF();
        } else if (value == 'excel') {
          _exportToExcel();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text('تصدير إلى PDF'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green),
              SizedBox(width: 8),
              Text('تصدير إلى Excel'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSummary() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200;

    final filtersList = _filters.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '${_getFilterLabel(e.key)}: ${e.value}')
        .toList();

    if (filtersList.isEmpty) return const SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 24 : 16,
        vertical: isLargeScreen ? 12 : 8,
      ),
      color: AppColors.backgroundGray,
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: AppColors.mediumGray),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filtersList
                    .map(
                      (filter) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: Text(
                          filter,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () => _applyFilters({}),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatisticsCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isExtraLargeScreen = screenWidth >= 1400;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isExtraLargeScreen ? 6 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // ⬇️ أهم تعديل (يقلل الارتفاع)
          childAspectRatio: 3.4,
        ),
        itemCount: _buildDesktopStats().length,
        itemBuilder: (context, index) {
          final stat = _buildDesktopStats()[index];
          return _buildDesktopStatCard(stat);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _buildDesktopStats() {
    return [
      {
        'title': 'إجمالي العملاء',
        'value': _summary['totalCustomers'] ?? 0,
        'icon': Icons.people,
        'color': AppColors.primaryBlue,
      },
      {
        'title': 'إجمالي الطلبات',
        'value': _summary['totalOrders'] ?? 0,
        'icon': Icons.shopping_cart,
        'color': AppColors.secondaryTeal,
      },
      {
        'title': 'إجمالي المبلغ',
        'value': '${_formatNumber(_summary['totalAmount'] ?? 0)} ريال',
        'icon': Icons.attach_money,
        'color': AppColors.successGreen,
      },
      {
        'title': 'متوسط الطلبات',
        'value': _summary['avgOrdersPerCustomer'] ?? 0,
        'icon': Icons.trending_up,
        'color': AppColors.warningOrange,
      },
      {
        'title': 'نسبة النجاح',
        'value': '${_summary['successRate'] ?? 0}%',
        'icon': Icons.check_circle,
        'color': AppColors.infoBlue,
      },
    ];
  }

  Widget _buildDesktopStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat['color'].withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // أيقونة أصغر
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stat['color'].withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'], color: stat['color'], size: 18),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان أصغر
                Text(
                  stat['title'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 4),
                // القيمة أوضح لكن أقل ارتفاع
                Text(
                  stat['value'].toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersView(bool isLargeScreen, bool isMediumScreen) {
    if (isLargeScreen) {
      return _buildCustomersGrid();
    } else if (isMediumScreen) {
      return _buildCustomersTabletGrid();
    } else {
      return _buildCustomersList();
    }
  }

  Widget _buildCustomersList() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _customers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final customer = _customers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomersTabletGrid() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _customers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final customer = _customers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomersGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isExtraLargeScreen = screenWidth >= 1600;
    final crossAxisCount = isExtraLargeScreen ? 4 : 3;

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        padding: const EdgeInsets.all(24),
        itemCount: _customers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _customers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final customer = _customers[index];
          return _buildCustomerCard(customer, isDesktop: true);
        },
      ),
    );
  }

  Widget _buildCustomerCard(
    Map<String, dynamic> customer, {
    bool isDesktop = false,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showCustomerDetailsDialog(customer),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customer['customerName'] ?? 'غير معروف',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 18 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${customer['totalOrders'] ?? 0} طلب',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  Icon(
                    Icons.code,
                    size: isDesktop ? 18 : 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer['customerCode'] ?? '--',
                      style: TextStyle(fontSize: isDesktop ? 15 : 14),
                    ),
                  ),
                  if (customer['customerPhone'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: isDesktop ? 18 : 16,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer['customerPhone']!,
                          style: TextStyle(fontSize: isDesktop ? 15 : 14),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Location
              if (customer['customerCity'] != null ||
                  customer['customerArea'] != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: isDesktop ? 18 : 16,
                      color: AppColors.mediumGray,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${customer['customerCity'] ?? ''} ${customer['customerArea'] != null ? '- ${customer['customerArea']}' : ''}',
                        style: TextStyle(fontSize: isDesktop ? 15 : 14),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Stats Grid/Row
              if (isDesktop) _buildDesktopCustomerStats(customer),
              if (!isDesktop) _buildMobileCustomerStats(customer),

              const SizedBox(height: 16),

              // Timeline
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isDesktop ? 16 : 14,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أول طلب: ${_formatDate(customer['firstOrderDate'])}',
                          style: TextStyle(fontSize: isDesktop ? 14 : 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'آخر طلب: ${_formatDate(customer['lastOrderDate'])}',
                          style: TextStyle(fontSize: isDesktop ? 14 : 12),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    IconButton(
                      icon: Icon(Icons.more_vert, color: AppColors.mediumGray),
                      onPressed: () => _showCustomerOptions(customer),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCustomerStats(Map<String, dynamic> customer) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _buildStatItem(
          'الإجمالي',
          '${_formatNumber(customer['totalAmount'] ?? 0)} ريال',
          isDesktop: false,
        ),
        _buildStatItem(
          'الكمية',
          '${_formatNumber(customer['totalQuantity'] ?? 0)}',
          isDesktop: false,
        ),
        _buildStatItem(
          'النسبة',
          '${_formatNumber(customer['successRate'] ?? 0)}%',
          isDesktop: false,
        ),
      ],
    );
  }

  Widget _buildDesktopCustomerStats(Map<String, dynamic> customer) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'إجمالي المبلغ',
            '${_formatNumber(customer['totalAmount'] ?? 0)} ريال',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'الكمية الكلية',
            '${_formatNumber(customer['totalQuantity'] ?? 0)}',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'نسبة النجاح',
            '${_formatNumber(customer['successRate'] ?? 0)}%',
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'متوسط الطلب',
            '${_formatNumber(customer['avgOrderValue'] ?? 0)} ريال',
            isDesktop: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {bool isDesktop = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(isDesktop ? 12 : 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 16 : 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 10,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(double.tryParse(number.toString()) ?? 0);
  }

  String _formatDate(dynamic date) {
    if (date == null) return '--/--/----';
    try {
      return DateFormat('yyyy/MM/dd').format(DateTime.parse(date.toString()));
    } catch (e) {
      return '--/--/----';
    }
  }

  String _getFilterLabel(String key) {
    final labels = {
      'startDate': 'من تاريخ',
      'endDate': 'إلى تاريخ',
      'city': 'المدينة',
      'area': 'المنطقة',
      'status': 'الحالة',
      'customerId': 'العميل',
    };
    return labels[key] ?? key;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ReportFilters(initialFilters: _filters, onApply: _applyFilters);
      },
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
          onExportExcel: _exportToExcel,
        );
      },
    );
  }

  void _showCustomerOptions(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('عرض التفاصيل'),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomerDetailsDialog(customer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('سجل الطلبات'),
                onTap: () {
                  Navigator.pop(context);
                  _showOrderHistory(customer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('تصدير البيانات'),
                onTap: () {
                  Navigator.pop(context);
                  _exportCustomerData(customer);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomerDetailsDialog([Map<String, dynamic>? customer]) {
    final selectedCustomer = customer ?? _customers.firstOrNull;
    if (selectedCustomer == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل العميل: ${selectedCustomer['customerName']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('الكود', selectedCustomer['customerCode']),
              _buildDetailItem('الهاتف', selectedCustomer['customerPhone']),
              _buildDetailItem('المدينة', selectedCustomer['customerCity']),
              _buildDetailItem('المنطقة', selectedCustomer['customerArea']),
              const Divider(),
              _buildDetailItem(
                'إجمالي الطلبات',
                '${selectedCustomer['totalOrders'] ?? 0} طلب',
              ),
              _buildDetailItem(
                'إجمالي المبلغ',
                '${_formatNumber(selectedCustomer['totalAmount'] ?? 0)} ريال',
              ),
              _buildDetailItem(
                'نسبة النجاح',
                '${selectedCustomer['successRate'] ?? 0}%',
              ),
              _buildDetailItem(
                'أول طلب',
                _formatDate(selectedCustomer['firstOrderDate']),
              ),
              _buildDetailItem(
                'آخر طلب',
                _formatDate(selectedCustomer['lastOrderDate']),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportCustomerData(selectedCustomer);
            },
            child: const Text('تصدير'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? '--',
              style: const TextStyle(color: AppColors.mediumGray),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderHistory(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سجل طلبات: ${customer['customerName']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: _fetchCustomerOrders(customer['id']), // غيرنا هذا
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Text('لا توجد بيانات لسجل الطلبات'));
              }

              final orders = snapshot.data as List<dynamic>;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var order in orders.take(10))
                    ListTile(
                      title: Text('طلب #${order['orderNumber']}'),
                      subtitle: Text(
                        '${_formatDate(order['orderDate'])} - ${order['status']}',
                      ),
                      trailing: Text('${order['total']} ريال'),
                    ),
                  if (orders.length > 10)
                    TextButton(
                      onPressed: () {},
                      child: const Text('عرض المزيد...'),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // دالة جديدة لجلب طلبات العميل من OrderProvider
  Future<List<dynamic>> _fetchCustomerOrders(String? customerId) async {
    if (customerId == null) return [];

    try {
      // نستخدم fetchOrders من OrderProvider مع فلتر العميل
      await _orderProvider.fetchOrders(
        page: 1,
        filters: {'customerId': customerId},
        silent: true,
      );

      // إرجاع الطلبات التي تطابق العميل
      return _orderProvider.orders
          .where((order) => order.customer?.id == customerId)
          .map(
            (order) => {
              'orderNumber': order.orderNumber,
              'orderDate': order.orderDate.toIso8601String(),
              'status': order.status,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching customer orders: $e');
      return [];
    }
  }

  void _exportCustomerData(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ تصدير بيانات ${customer['customerName']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
