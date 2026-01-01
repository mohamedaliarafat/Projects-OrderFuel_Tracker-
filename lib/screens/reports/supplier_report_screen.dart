import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/report_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/reports/export_options.dart';
import 'package:order_tracker/widgets/reports/report_filters.dart';
import 'package:order_tracker/widgets/reports/report_summary.dart';
import 'package:order_tracker/widgets/reports/supplier_rating_chart.dart';
import 'package:printing/printing.dart';

class SupplierReportScreen extends StatefulWidget {
  static const routeName = '/reports/suppliers';

  const SupplierReportScreen({super.key});

  @override
  State<SupplierReportScreen> createState() => _SupplierReportScreenState();
}

class _SupplierReportScreenState extends State<SupplierReportScreen> {
  final ReportProvider _reportProvider = ReportProvider();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _filters = {};
  List<dynamic> _suppliers = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _sortBy = 'totalAmount';
  bool _sortAscending = false;
  bool _showChart = false;

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
      final response = await _reportProvider.supplierReports(
        filters: _filters,
        page: 1,
      );

      setState(() {
        _suppliers = response['suppliers'] ?? [];
        _summary = response['summary'] ?? {};
        _isLoading = false;
        _page = 2;
        _hasMore = _suppliers.length >= 20;
        _sortSuppliers();
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
      final response = await _reportProvider.supplierReports(
        filters: _filters,
        page: _page,
      );

      final newSuppliers = response['suppliers'] ?? [];
      setState(() {
        _suppliers.addAll(newSuppliers);
        _isLoading = false;
        _page++;
        _hasMore = newSuppliers.length >= 20;
        _sortSuppliers();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _sortSuppliers() {
    _suppliers.sort((a, b) {
      dynamic aValue = a[_sortBy] ?? 0;
      dynamic bValue = b[_sortBy] ?? 0;

      if (aValue is String) aValue = aValue.toLowerCase();
      if (bValue is String) bValue = bValue.toLowerCase();

      int comparison = 0;
      if (aValue is Comparable && bValue is Comparable) {
        comparison = aValue.compareTo(bValue);
      }

      return _sortAscending ? comparison : -comparison;
    });
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
    try {
      final pdfBytes = await _reportProvider.exportPDF(
        reportType: 'suppliers', // أو customers / drivers
        filters: _filters,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'suppliers_report.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تصدير PDF: $e')));
    }
  }


  Future<void> _exportToExcel() async {
    try {
      await _reportProvider.exportExcel(
        reportType: 'suppliers',
        filters: _filters,
      );
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
        title: const Text('تقارير الموردين'),
        actions: [
          if (isLargeScreen) ...[
            _buildDesktopSortButton(),
            const SizedBox(width: 8),
            _buildViewToggleButton(isLargeScreen),
            const SizedBox(width: 8),
            _buildDesktopExportButton(),
            const SizedBox(width: 8),
          ],
          if (!isLargeScreen) ...[
            _buildViewToggleButton(isLargeScreen),
            _buildMobileSortButton(),
          ],
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterSheet,
            tooltip: 'فلاتر',
          ),
          if (!isLargeScreen)
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
          if (_filters.isNotEmpty) _buildFiltersSummary(isLargeScreen),

          // Report Summary
          ReportSummary(
            title: 'ملخص تقرير الموردين',
            statistics: _summary,
            period: _filters,
          ),

          // Sorting Info and View Toggle
          _buildHeaderSection(isLargeScreen, isMediumScreen, isSmallScreen),

          // Content
          Expanded(
            child: _isLoading && _suppliers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _suppliers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business,
                          size: 64,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بيانات للموردين',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showChart
                ? SupplierRatingChart(
                    suppliers: _suppliers,
                    isLargeScreen: isLargeScreen,
                  )
                : _buildSuppliersView(isLargeScreen, isMediumScreen),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton.extended(
              onPressed: () => _showSupplierAnalysis(),
              icon: const Icon(Icons.trending_up),
              label: const Text('تحليل'),
              backgroundColor: AppColors.successGreen,
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

  Widget _buildDesktopSortButton() {
    return PopupMenuButton<String>(
      onSelected: _changeSortOption,
      icon: const Icon(Icons.sort),
      tooltip: 'ترتيب',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'totalAmount',
          child: Row(
            children: [
              Icon(
                Icons.attach_money,
                color: _sortBy == 'totalAmount' ? AppColors.primaryBlue : null,
              ),
              const SizedBox(width: 8),
              const Text('ترتيب حسب إجمالي المبلغ'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'totalOrders',
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: _sortBy == 'totalOrders'
                    ? AppColors.secondaryTeal
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('ترتيب حسب عدد الطلبات'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rating',
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: _sortBy == 'rating' ? AppColors.warningOrange : null,
              ),
              const SizedBox(width: 8),
              const Text('ترتيب حسب التقييم'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'successRate',
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: _sortBy == 'successRate' ? AppColors.successGreen : null,
              ),
              const SizedBox(width: 8),
              const Text('ترتيب حسب نسبة النجاح'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSortButton() {
    return PopupMenuButton<String>(
      onSelected: _changeSortOption,
      icon: const Icon(Icons.sort),
      tooltip: 'ترتيب',
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'totalAmount', child: Text('إجمالي المبلغ')),
        const PopupMenuItem(value: 'totalOrders', child: Text('عدد الطلبات')),
        const PopupMenuItem(value: 'rating', child: Text('التقييم')),
        const PopupMenuItem(value: 'successRate', child: Text('نسبة النجاح')),
      ],
    );
  }

  Widget _buildViewToggleButton(bool isLargeScreen) {
    if (isLargeScreen) {
      return ToggleButtons(
        isSelected: [!_showChart, _showChart],
        onPressed: (index) {
          setState(() => _showChart = index == 1);
        },
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        fillColor: AppColors.successGreen,
        constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.list, size: 18),
                SizedBox(width: 8),
                Text('القائمة'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.bar_chart, size: 18),
                SizedBox(width: 8),
                Text('الرسوم'),
              ],
            ),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: Icon(_showChart ? Icons.list : Icons.bar_chart),
        onPressed: () => setState(() => _showChart = !_showChart),
        tooltip: _showChart ? 'عرض القائمة' : 'عرض الرسوم',
      );
    }
  }

  Widget _buildHeaderSection(
    bool isLargeScreen,
    bool isMediumScreen,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen
            ? 24
            : isMediumScreen
            ? 16
            : 12,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_suppliers.length} مورد',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLargeScreen ? 16 : 14,
              color: AppColors.mediumGray,
            ),
          ),
          if (isLargeScreen)
            Row(
              children: [
                Text(
                  _getSortLabel(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                  color: AppColors.mediumGray,
                ),
              ],
            ),
          if (!isLargeScreen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _showChart ? Icons.list : Icons.bar_chart,
                    size: 14,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showChart ? 'عرض القائمة' : 'عرض الرسوم',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersSummary(bool isLargeScreen) {
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

  Widget _buildSuppliersView(bool isLargeScreen, bool isMediumScreen) {
    if (isLargeScreen) {
      return _buildSuppliersGrid();
    } else if (isMediumScreen) {
      return _buildSuppliersTabletGrid();
    } else {
      return _buildSuppliersList();
    }
  }

  Widget _buildSuppliersList() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _suppliers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _suppliers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final supplier = _suppliers[index];
          return _buildSupplierCard(supplier);
        },
      ),
    );
  }

  Widget _buildSuppliersTabletGrid() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _suppliers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _suppliers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final supplier = _suppliers[index];
          return _buildSupplierCard(supplier, isTablet: true);
        },
      ),
    );
  }

  Widget _buildSuppliersGrid() {
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
          childAspectRatio: 1.8,
        ),
        padding: const EdgeInsets.all(24),
        itemCount: _suppliers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _suppliers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final supplier = _suppliers[index];
          return _buildSupplierCard(supplier, isDesktop: true);
        },
      ),
    );
  }

  Widget _buildSupplierCard(
    Map<String, dynamic> supplier, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final rating = (supplier['rating'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSupplierDetails(supplier),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ================= Header =================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier['supplierName'] ?? 'غير معروف',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 17 : 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            supplier['supplierCompany'] ?? '--',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isDesktop ? 13 : 12,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildRatingStars(rating, isDesktop: isDesktop),
                  ],
                ),

                SizedBox(height: isDesktop ? 10 : 8),

                /// ================= Contact =================
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.mediumGray),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        supplier['supplierContactPerson'] ?? '--',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: isDesktop ? 14 : 13),
                      ),
                    ),
                    if (supplier['supplierPhone'] != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.phone, size: 16, color: AppColors.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        supplier['supplierPhone'],
                        style: TextStyle(fontSize: isDesktop ? 14 : 13),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: isDesktop ? 8 : 6),

                /// ================= Type & Contract =================
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          supplier['supplierType'],
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        supplier['supplierType'] ?? 'أخرى',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTypeColor(supplier['supplierType']),
                        ),
                      ),
                    ),
                    if (supplier['isUnderContract'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'تعاقد',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: isDesktop ? 12 : 10),

                /// ================= Stats =================
                if (isDesktop) _buildDesktopSupplierStats(supplier),
                if (isTablet) _buildTabletSupplierStats(supplier),
                if (!isDesktop && !isTablet)
                  _buildMobileSupplierStats(supplier),

                SizedBox(height: isDesktop ? 12 : 10),

                /// ================= Financial Summary =================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildFinancialSummary(supplier, isDesktop),
                ),

                if (isDesktop || isTablet) ...[
                  SizedBox(height: isDesktop ? 10 : 8),

                  /// ================= Contract Dates =================
                  if (supplier['contractStartDate'] != null ||
                      supplier['contractEndDate'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'العقد: ${_formatDate(supplier['contractStartDate'])} - ${_formatDate(supplier['contractEndDate'])}',
                            style: TextStyle(
                              fontSize: isDesktop ? 12 : 11,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],

                if (isDesktop)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showSupplierOptions(supplier),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSupplierStats(Map<String, dynamic> supplier) {
    final totalAmount = supplier['totalAmount'] ?? 0;
    final totalOrders = supplier['totalOrders'] ?? 0;
    final paymentPercentage = supplier['paymentPercentage'] ?? 0;
    final successRate = supplier['successRate'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.5,
      children: [
        _buildStatItem(
          'الإجمالي',
          '${_formatNumber(totalAmount)}',
          AppColors.primaryBlue,
          isDesktop: false,
        ),
        _buildStatItem(
          'الطلبات',
          totalOrders.toString(),
          AppColors.secondaryTeal,
          isDesktop: false,
        ),
        _buildStatItem(
          'السداد',
          '${_formatNumber(paymentPercentage)}%',
          AppColors.successGreen,
          isDesktop: false,
        ),
        _buildStatItem(
          'النجاح',
          '${_formatNumber(successRate)}%',
          AppColors.warningOrange,
          isDesktop: false,
        ),
      ],
    );
  }

  Widget _buildTabletSupplierStats(Map<String, dynamic> supplier) {
    final totalAmount = supplier['totalAmount'] ?? 0;
    final totalOrders = supplier['totalOrders'] ?? 0;
    final paymentPercentage = supplier['paymentPercentage'] ?? 0;
    final successRate = supplier['successRate'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildStatItem(
          'إجمالي المبلغ',
          '${_formatNumber(totalAmount)} ريال',
          AppColors.primaryBlue,
          isDesktop: true,
        ),
        _buildStatItem(
          'عدد الطلبات',
          totalOrders.toString(),
          AppColors.secondaryTeal,
          isDesktop: true,
        ),
        _buildStatItem(
          'نسبة السداد',
          '${_formatNumber(paymentPercentage)}%',
          AppColors.successGreen,
          isDesktop: true,
        ),
        _buildStatItem(
          'نسبة النجاح',
          '${_formatNumber(successRate)}%',
          AppColors.warningOrange,
          isDesktop: true,
        ),
      ],
    );
  }

  Widget _buildDesktopSupplierStats(Map<String, dynamic> supplier) {
    final totalAmount = supplier['totalAmount'] ?? 0;
    final totalOrders = supplier['totalOrders'] ?? 0;
    final paymentPercentage = supplier['paymentPercentage'] ?? 0;
    final successRate = supplier['successRate'] ?? 0;
    final avgOrderValue = supplier['avgOrderValue'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'إجمالي المبلغ',
            '${_formatNumber(totalAmount)} ريال',
            AppColors.primaryBlue,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'عدد الطلبات',
            totalOrders.toString(),
            AppColors.secondaryTeal,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'نسبة السداد',
            '${_formatNumber(paymentPercentage)}%',
            AppColors.successGreen,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'متوسط الطلب',
            '${_formatNumber(avgOrderValue)} ريال',
            AppColors.infoBlue,
            isDesktop: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary(Map<String, dynamic> supplier, bool isDesktop) {
    final paidAmount = supplier['paidAmount'] ?? 0;
    final pendingAmount = supplier['pendingAmount'] ?? 0;
    final avgOrderValue = supplier['avgOrderValue'] ?? 0;

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFinancialItem(
            'مدفوع',
            paidAmount,
            AppColors.successGreen,
            isDesktop: true,
          ),
          _buildFinancialItem(
            'معلق',
            pendingAmount,
            AppColors.warningOrange,
            isDesktop: true,
          ),
          _buildFinancialItem(
            'متوسط',
            avgOrderValue,
            AppColors.infoBlue,
            isDesktop: true,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinancialItem(
                'مدفوع',
                paidAmount,
                AppColors.successGreen,
                isDesktop: false,
              ),
              _buildFinancialItem(
                'معلق',
                pendingAmount,
                AppColors.warningOrange,
                isDesktop: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFinancialItem(
                'متوسط الطلب',
                avgOrderValue,
                AppColors.infoBlue,
                isDesktop: false,
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildRatingStars(double rating, {bool isDesktop = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor()
                ? Icons.star
                : index < rating
                ? Icons.star_half
                : Icons.star_border,
            color: AppColors.warningOrange,
            size: isDesktop ? 18 : 16,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color, {
    bool isDesktop = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(isDesktop ? 12 : 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 14 : 12,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 10,
              color: AppColors.mediumGray,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    String label,
    dynamic amount,
    Color color, {
    bool isDesktop = false,
  }) {
    return Column(
      children: [
        Text(
          '${_formatNumber(amount)} ريال',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 14 : 12,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : 10,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'وقود':
        return AppColors.primaryBlue;
      case 'صيانة':
        return AppColors.secondaryTeal;
      case 'خدمات لوجستية':
        return AppColors.successGreen;
      case 'توصيل':
        return AppColors.infoBlue;
      default:
        return AppColors.mediumGray;
    }
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
      'supplierType': 'نوع المورد',
      'productType': 'نوع المنتج',
      'paymentStatus': 'حالة الدفع',
      'supplierId': 'المورد',
    };
    return labels[key] ?? key;
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'totalAmount':
        return 'إجمالي المبلغ';
      case 'totalOrders':
        return 'عدد الطلبات';
      case 'rating':
        return 'التقييم';
      case 'successRate':
        return 'نسبة النجاح';
      default:
        return 'الترتيب';
    }
  }

  void _changeSortOption(String option) {
    setState(() {
      if (_sortBy == option) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = option;
        _sortAscending = false;
      }
      _sortSuppliers();
    });
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

  void _showSupplierOptions(Map<String, dynamic> supplier) {
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
                  _showSupplierDetails(supplier);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('سجل التعاملات'),
                onTap: () {
                  Navigator.pop(context);
                  _showSupplierTransactions(supplier);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('تصدير البيانات'),
                onTap: () {
                  Navigator.pop(context);
                  _exportSupplierData(supplier);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupplierDetails(Map<String, dynamic> supplier) {
    // عرض تفاصيل المورد
  }

  void _showSupplierTransactions(Map<String, dynamic> supplier) {
    // عرض سجل تعاملات المورد
  }

  void _showSupplierAnalysis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SupplierRatingChart(suppliers: _suppliers, isLargeScreen: false);
      },
    );
  }

  void _exportSupplierData(Map<String, dynamic> supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ تصدير بيانات ${supplier['supplierName']}...'),
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
