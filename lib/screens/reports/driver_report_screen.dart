import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/report_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/reports/driver_stats_chart.dart';
import 'package:order_tracker/widgets/reports/export_options.dart';
import 'package:order_tracker/widgets/reports/report_filters.dart';
import 'package:order_tracker/widgets/reports/report_summary.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DriverReportScreen extends StatefulWidget {
  static const routeName = '/reports/drivers';

  const DriverReportScreen({super.key});

  @override
  State<DriverReportScreen> createState() => _DriverReportScreenState();
}

class _DriverReportScreenState extends State<DriverReportScreen> {
  final ReportProvider _reportProvider = ReportProvider();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _filters = {};
  List<dynamic> _drivers = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
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
      final response = await _reportProvider.driverReports(
        filters: _filters,
        page: 1,
      );

      setState(() {
        _drivers = response['drivers'] ?? [];
        _summary = response['summary'] ?? {};
        _isLoading = false;
        _page = 2;
        _hasMore = _drivers.length >= 20;
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
      final response = await _reportProvider.driverReports(
        filters: _filters,
        page: _page,
      );

      final newDrivers = response['drivers'] ?? [];
      setState(() {
        _drivers.addAll(newDrivers);
        _isLoading = false;
        _page++;
        _hasMore = newDrivers.length >= 20;
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
    try {
      final pdfBytes = await _reportProvider.exportPDF(
        reportType: 'drivers', // أو customers / drivers
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
        reportType: 'drivers',
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
        title: const Text('تقارير السائقين'),
        actions: [
          if (isLargeScreen) ...[
            _buildViewToggleButton(isLargeScreen),
            const SizedBox(width: 8),
            _buildDesktopExportButton(),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterSheet,
            tooltip: 'فلاتر',
          ),
          if (!isLargeScreen) ...[
            _buildViewToggleButton(isLargeScreen),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _showExportOptions,
              tooltip: 'تصدير',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filters Summary
          if (_filters.isNotEmpty) _buildFiltersSummary(isLargeScreen),

          // Report Summary
          ReportSummary(
            title: 'ملخص تقرير السائقين',
            statistics: _summary,
            period: _filters,
          ),

          // Toggle View for mobile/tablet
          if (!isLargeScreen)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMediumScreen ? 24 : 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showChart ? Icons.list : Icons.bar_chart,
                          size: 16,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(width: 8),
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
            ),

          // Content
          Expanded(
            child: _isLoading && _drivers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _drivers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 64,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بيانات للسائقين',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showChart
                ? DriverStatsChart(
                    drivers: _drivers,
                    isLargeScreen: isLargeScreen,
                  )
                : _buildDriversView(isLargeScreen, isMediumScreen),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: _showDriverAnalytics,
              child: const Icon(Icons.analytics),
              backgroundColor: AppColors.secondaryTeal,
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

  Widget _buildViewToggleButton(bool isLargeScreen) {
    if (isLargeScreen) {
      return ToggleButtons(
        isSelected: [!_showChart, _showChart],
        onPressed: (index) {
          setState(() => _showChart = index == 1);
        },
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        fillColor: AppColors.secondaryTeal,
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

  Widget _buildDriversView(bool isLargeScreen, bool isMediumScreen) {
    if (isLargeScreen) {
      return _buildDriversGrid();
    } else if (isMediumScreen) {
      return _buildDriversTabletGrid();
    } else {
      return _buildDriversList();
    }
  }

  Widget _buildDriversList() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _drivers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final driver = _drivers[index];
          return _buildDriverCard(driver);
        },
      ),
    );
  }

  Widget _buildDriversTabletGrid() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _drivers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final driver = _drivers[index];
          return _buildDriverCard(driver, isTablet: true);
        },
      ),
    );
  }

  Widget _buildDriversGrid() {
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
        itemCount: _drivers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _drivers.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }

          final driver = _drivers[index];
          return _buildDriverCard(driver, isDesktop: true);
        },
      ),
    );
  }

  Widget _buildDriverCard(
    Map<String, dynamic> driver, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final totalEarnings = driver['totalEarnings'] ?? 0;
    final totalOrders = driver['totalOrders'] ?? 0;
    final successRate = driver['successRate'] ?? 0;
    final onTimeRate = driver['onTimeRate'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= Header =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['driverName'] ?? 'غير معروف',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 18 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver['licenseNumber'] ?? '--',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(driver['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      driver['status'] ?? 'نشط',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 14 : 10),

              /// ================= Contact =================
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: isDesktop ? 18 : 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      driver['driverPhone'] ?? '--',
                      style: TextStyle(fontSize: isDesktop ? 15 : 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.directions_car,
                    size: isDesktop ? 18 : 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    driver['vehicleNumber'] ?? '--',
                    style: TextStyle(fontSize: isDesktop ? 15 : 14),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 10 : 8),

              /// ================= Vehicle & City =================
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: isDesktop ? 18 : 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      driver['vehicleType'] ?? 'غير محدد',
                      style: TextStyle(fontSize: isDesktop ? 15 : 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    size: isDesktop ? 18 : 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    driver['driverCity'] ?? '--',
                    style: TextStyle(fontSize: isDesktop ? 15 : 14),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 16 : 12),

              /// ================= Stats =================
              if (isDesktop) _buildDesktopDriverStats(driver),
              if (isTablet) _buildTabletDriverStats(driver),
              if (!isDesktop && !isTablet) _buildMobileDriverStats(driver),

              SizedBox(height: isDesktop ? 16 : 12),

              /// ================= Performance =================
              if (isDesktop || isTablet)
                _buildDesktopPerformanceIndicators(driver),
              if (!isDesktop && !isTablet)
                _buildMobilePerformanceIndicators(driver),

              SizedBox(height: isDesktop ? 16 : 12),

              /// ================= Timeline =================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          'أول مهمة: ${_formatDate(driver['firstAssignment'])}',
                          style: TextStyle(fontSize: isDesktop ? 14 : 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'آخر مهمة: ${_formatDate(driver['lastAssignment'])}',
                          style: TextStyle(fontSize: isDesktop ? 14 : 12),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showDriverOptions(driver),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDriverStats(Map<String, dynamic> driver) {
    final totalEarnings = driver['totalEarnings'] ?? 0;
    final totalOrders = driver['totalOrders'] ?? 0;
    final successRate = driver['successRate'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _buildStatItem(
          'الأرباح',
          '${_formatNumber(totalEarnings)} ريال',
          Icons.monetization_on,
          AppColors.successGreen,
          isDesktop: false,
        ),
        _buildStatItem(
          'الطلبات',
          totalOrders.toString(),
          Icons.shopping_cart,
          AppColors.primaryBlue,
          isDesktop: false,
        ),
        _buildStatItem(
          'النسبة',
          '${_formatNumber(successRate)}%',
          Icons.check_circle,
          AppColors.successGreen,
          isDesktop: false,
        ),
      ],
    );
  }

  Widget _buildTabletDriverStats(Map<String, dynamic> driver) {
    final totalEarnings = driver['totalEarnings'] ?? 0;
    final totalOrders = driver['totalOrders'] ?? 0;
    final successRate = driver['successRate'] ?? 0;
    final onTimeRate = driver['onTimeRate'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3.5,
      children: [
        _buildStatItem(
          'إجمالي الأرباح',
          '${_formatNumber(totalEarnings)} ريال',
          Icons.monetization_on,
          AppColors.successGreen,
          isDesktop: true,
        ),
        _buildStatItem(
          'عدد الطلبات',
          totalOrders.toString(),
          Icons.shopping_cart,
          AppColors.primaryBlue,
          isDesktop: true,
        ),
        _buildStatItem(
          'نسبة النجاح',
          '${_formatNumber(successRate)}%',
          Icons.check_circle,
          AppColors.successGreen,
          isDesktop: true,
        ),
        _buildStatItem(
          'التوقيت',
          '${_formatNumber(onTimeRate)}%',
          Icons.timer,
          AppColors.infoBlue,
          isDesktop: true,
        ),
      ],
    );
  }

  Widget _buildDesktopDriverStats(Map<String, dynamic> driver) {
    final totalEarnings = driver['totalEarnings'] ?? 0;
    final totalOrders = driver['totalOrders'] ?? 0;
    final successRate = driver['successRate'] ?? 0;
    final onTimeRate = driver['onTimeRate'] ?? 0;
    final avgDeliveryTime = driver['avgDeliveryTime'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'إجمالي الأرباح',
            '${_formatNumber(totalEarnings)} ريال',
            Icons.monetization_on,
            AppColors.successGreen,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'عدد الطلبات',
            totalOrders.toString(),
            Icons.shopping_cart,
            AppColors.primaryBlue,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'نسبة النجاح',
            '${_formatNumber(successRate)}%',
            Icons.check_circle,
            AppColors.successGreen,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'متوسط وقت التوصيل',
            '${_formatNumber(avgDeliveryTime)} دقيقة',
            Icons.timer,
            AppColors.infoBlue,
            isDesktop: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isDesktop ? 16 : 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
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
              ),
            ],
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

  Widget _buildMobilePerformanceIndicators(Map<String, dynamic> driver) {
    final onTimeRate = driver['onTimeRate'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التوقيت:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        _buildPerformanceIndicator(
          'النسبة: ${onTimeRate.toStringAsFixed(1)}%',
          onTimeRate,
          AppColors.infoBlue,
          isDesktop: false,
        ),
      ],
    );
  }

  Widget _buildDesktopPerformanceIndicators(Map<String, dynamic> driver) {
    final onTimeRate = driver['onTimeRate'] ?? 0;
    final avgDeliveryTime = driver['avgDeliveryTime'] != null
        ? (100 - ((driver['avgDeliveryTime'] as num) / 60 * 10))
              .clamp(0, 100)
              .toDouble()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildPerformanceIndicator(
            'التوقيت (${onTimeRate.toStringAsFixed(1)}%)',
            onTimeRate,
            AppColors.infoBlue,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 16),
        // Expanded(
        //   child: _buildPerformanceIndicator(
        //     'الكفاءة (${avgDeliveryTime.toStringAsFixed(0)}%)',
        //     avgDeliveryTime,
        //     AppColors.secondaryTeal,
        //     isDesktop: true,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildPerformanceIndicator(
    String label,
    double percentage,
    Color color, {
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: isDesktop ? 14 : 12)),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: isDesktop ? 10 : 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: isDesktop ? 10 : 8,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'نشط':
        return AppColors.successGreen;
      case 'في إجازة':
        return AppColors.warningOrange;
      case 'معلق':
        return AppColors.errorRed;
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
      'vehicleType': 'نوع المركبة',
      'status': 'الحالة',
      'city': 'المدينة',
      'driverId': 'السائق',
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

  void _showDriverOptions(Map<String, dynamic> driver) {
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
                  _showDriverDetails(driver);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('سجل المهام'),
                onTap: () {
                  Navigator.pop(context);
                  _showDriverHistory(driver);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('تصدير البيانات'),
                onTap: () {
                  Navigator.pop(context);
                  _exportDriverData(driver);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    // عرض تفاصيل السائق
  }

  void _showDriverHistory(Map<String, dynamic> driver) {
    // عرض سجل مهام السائق
  }

  void _showDriverAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحليلات السائقين'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsItem('أفضل 5 سائقين حسب الأرباح'),
              _buildAnalyticsItem('أعلى نسبة إنجاز في الوقت'),
              _buildAnalyticsItem('أكثر السائقين نشاطاً'),
              _buildAnalyticsItem('توزيع السائقين حسب المدينة'),
              _buildAnalyticsItem('متوسط المسافة المقطوعة'),
            ],
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

  Widget _buildAnalyticsItem(String title) {
    return ListTile(
      leading: const Icon(Icons.analytics, color: AppColors.secondaryTeal),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        // سيتم تطويرها
      },
    );
  }

  void _exportDriverData(Map<String, dynamic> driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ تصدير بيانات ${driver['driverName']}...'),
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
