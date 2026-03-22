import 'package:flutter/material.dart';
import 'package:order_tracker/screens/reports/customer_report_screen.dart';
import 'package:order_tracker/screens/reports/driver_report_screen.dart';
import 'package:order_tracker/screens/reports/supplier_report_screen.dart';
import 'package:order_tracker/screens/reports/user_report_screen.dart';
import 'package:order_tracker/screens/reports/invoice_report_screen.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_soft_background.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
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
  String _query = '';

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

    final query = _query.trim().toLowerCase();
    final categories = query.isEmpty
        ? _reportCategories
        : _reportCategories.where((c) {
            final haystack = '${c.title} ${c.description}'.trim().toLowerCase();
            return haystack.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
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
      body: Stack(
        children: [
          const AppSoftBackground(),
          Positioned.fill(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop
                            ? 28
                            : isTablet
                            ? 18
                            : 16,
                        vertical: isDesktop ? 22 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isDesktop),
                          const SizedBox(height: 16),
                          _buildSearchBar(),
                          const SizedBox(height: 18),
                          if (categories.isEmpty)
                            _buildEmptyState()
                          else
                            _buildReportsGrid(screenType, categories),
                          const SizedBox(height: 18),
                          _buildQuickStats(screenType),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 64 : 56,
            height: isDesktop ? 64 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.appBarWaterGlow,
                  AppColors.appBarWaterBright,
                  AppColors.appBarWaterDeep,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.appBarWaterDeep.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.assessment_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظام التقارير المتكامل',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    fontSize: isDesktop ? 30 : 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر نوع التقرير للبدء',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop)
            FilledButton.icon(
              onPressed: _exportAllReports,
              icon: const Icon(Icons.download_rounded),
              label: const Text('تصدير الجميع'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث في التقارير...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: const Color(0xFF0F172A).withValues(alpha: 0.60),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
              onChanged: _searchReports,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'خيارات',
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.tune_rounded),
            color: const Color(0xFF0F172A).withValues(alpha: 0.70),
          ),
          if (_query.trim().isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'مسح البحث',
              onPressed: () {
                setState(() => _query = '');
                _searchController.clear();
              },
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF0F172A).withValues(alpha: 0.60),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportsGrid(
    ScreenType screenType,
    List<ReportCategory> categories,
  ) {
    int crossAxisCount;
    double aspectRatio;

    switch (screenType) {
      case ScreenType.desktop:
        crossAxisCount = 3;
        aspectRatio = 1.55;
        break;
      case ScreenType.tablet:
        crossAxisCount = 2;
        aspectRatio = 1.35;
        break;
      case ScreenType.mobile:
        crossAxisCount = 1;
        aspectRatio = 1.20;
        break;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildReportCard(
          categories[index],
          screenType == ScreenType.desktop,
        );
      },
    );
  }

  Widget _buildReportCard(ReportCategory category, bool isDesktop) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      onTap: () => Navigator.pushNamed(context, category.route),
      padding: EdgeInsets.all(isDesktop ? 18 : 16),
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.55),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(22),
                  bottomStart: Radius.circular(22),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isDesktop ? 52 : 46,
                      height: isDesktop ? 52 : 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: category.color.withValues(alpha: 0.14),
                        border: Border.all(
                          color: category.color.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(category.icon, color: category.color),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, category.route),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('فتح'),
                      style: FilledButton.styleFrom(
                        backgroundColor: category.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  category.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    fontSize: isDesktop ? 20 : 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.40),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'افتح التقرير',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
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

  Widget _buildQuickStats(ScreenType screenType) {
    final theme = Theme.of(context);
    final isMobile = screenType == ScreenType.mobile;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'حالة النظام',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.insights_rounded,
                color: const Color(0xFF0F172A).withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statTile(
                value: '٥٠',
                label: 'جاهز',
                icon: Icons.check_circle_rounded,
                color: AppColors.successGreen,
                wide: !isMobile,
              ),
              _statTile(
                value: '١٠',
                label: 'قيد الإنشاء',
                icon: Icons.schedule_rounded,
                color: AppColors.warningOrange,
                wide: !isMobile,
              ),
              _statTile(
                value: '٢',
                label: 'يحتاج تحديث',
                icon: Icons.warning_rounded,
                color: AppColors.errorRed,
                wide: !isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool wide,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: wide ? 220 : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
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

  void _searchReports(String query) {
    setState(() => _query = query);
  }

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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primaryBlue,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد نتائج',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'جرّب البحث بكلمة مختلفة أو امسح البحث.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
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
