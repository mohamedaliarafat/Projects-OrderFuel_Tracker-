import 'package:flutter/material.dart';
import 'package:order_tracker/screens/reports/customer_report_screen.dart';
import 'package:order_tracker/screens/reports/driver_report_screen.dart';
import 'package:order_tracker/screens/reports/supplier_report_screen.dart';
import 'package:order_tracker/screens/reports/user_report_screen.dart';
import 'package:order_tracker/screens/reports/invoice_report_screen.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/reports/advanced_filter_sheet.dart';

/// 🟢 أنواع الشاشات
enum ScreenType { mobile, tablet, desktop }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<ReportCategory> _reportCategories = [
    ReportCategory(
      title: 'تقارير العملاء',
      description: 'تقارير تفصيلية عن العملاء وطلباتهم',
      icon: Icons.people,
      color: AppColors.primaryBlue,
      route: CustomerReportScreen.routeName,
    ),
    ReportCategory(
      title: 'تقارير السائقين',
      description: 'تقارير أداء السائقين والتوصيلات',
      icon: Icons.directions_car,
      color: AppColors.secondaryTeal,
      route: DriverReportScreen.routeName,
    ),
    ReportCategory(
      title: 'تقارير الموردين',
      description: 'تقارير الموردين والمشتريات',
      icon: Icons.business,
      color: AppColors.successGreen,
      route: SupplierReportScreen.routeName,
    ),
    ReportCategory(
      title: 'تقارير المستخدمين',
      description: 'تقارير نشاط المستخدمين',
      icon: Icons.person,
      color: AppColors.warningOrange,
      route: UserReportScreen.routeName,
    ),
    ReportCategory(
      title: 'تقارير الفواتير',
      description: 'فواتير مفصلة للطلبات',
      icon: Icons.receipt,
      color: AppColors.infoBlue,
      route: InvoiceReportScreen.routeName,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();

  /// 🟢 تحديد نوع الشاشة
  ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return ScreenType.desktop;
    } else if (width >= 700) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);

    final bool isMobile = screenType == ScreenType.mobile;
    final bool isTablet = screenType == ScreenType.tablet;
    final bool isDesktop = screenType == ScreenType.desktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showAdvancedFilter,
            tooltip: 'بحث متقدم',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'مساعدة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? 40
                : isTablet
                ? 24
                : 16,
            vertical: isDesktop ? 32 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDesktop),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildReportsGrid(screenType),
              const SizedBox(height: 24),
              _buildQuickStats(screenType),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: _exportAllReports,
              icon: const Icon(Icons.download),
              label: const Text('تصدير جميع التقارير'),
              backgroundColor: AppColors.primaryBlue,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ===================== UI =====================

  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نظام التقارير المتكامل',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
            fontSize: isDesktop ? 32 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر نوع التقرير للبدء',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.mediumGray,
            fontSize: isDesktop ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث في التقارير...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterOptions,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: _searchReports,
      ),
    );
  }

  Widget _buildReportsGrid(ScreenType screenType) {
    int crossAxisCount;
    double aspectRatio;

    switch (screenType) {
      case ScreenType.desktop:
        crossAxisCount = 3;
        aspectRatio = 1.5;
        break;
      case ScreenType.tablet:
        crossAxisCount = 2;
        aspectRatio = 1.3;
        break;
      case ScreenType.mobile:
        crossAxisCount = 1;
        aspectRatio = 1.1;
        break;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: aspectRatio,
      ),
      itemCount: _reportCategories.length,
      itemBuilder: (context, index) {
        return _buildReportCard(
          _reportCategories[index],
          screenType == ScreenType.desktop,
        );
      },
    );
  }

  Widget _buildReportCard(ReportCategory category, bool isDesktop) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, category.route),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isDesktop ? 28 : 24,
                backgroundColor: category.color.withOpacity(0.2),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  category.description,
                  style: const TextStyle(color: AppColors.mediumGray),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, category.route),
                  child: const Text('فتح'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ScreenType screenType) {
    return screenType == ScreenType.mobile
        ? _buildQuickStatsVertical()
        : _buildQuickStatsHorizontal();
  }

  Widget _buildQuickStatsHorizontal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _stat('٥٠', 'جاهز', Icons.check_circle, AppColors.successGreen),
        _stat('١٠', 'قيد الإنشاء', Icons.schedule, AppColors.warningOrange),
        _stat('٢', 'يحتاج تحديث', Icons.warning, AppColors.errorRed),
      ],
    );
  }

  Widget _buildQuickStatsVertical() {
    return Column(
      children: [
        _stat('٥٠', 'جاهز', Icons.check_circle, AppColors.successGreen),
        const SizedBox(height: 12),
        _stat('١٠', 'قيد الإنشاء', Icons.schedule, AppColors.warningOrange),
        const SizedBox(height: 12),
        _stat('٢', 'يحتاج تحديث', Icons.warning, AppColors.errorRed),
      ],
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.mediumGray)),
      ],
    );
  }

  // ===================== Actions =====================

  void _showAdvancedFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AdvancedFilterSheet(),
    );
  }

  void _showFilterOptions() {}

  void _searchReports(String query) {}

  void _exportAllReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جارٍ تصدير جميع التقارير...')),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مساعدة'),
        content: const Text('اختر التقرير المناسب حسب نوع البيانات'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }
}

// ===================== Model =====================

class ReportCategory {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  ReportCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}
