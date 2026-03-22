import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:order_tracker/models/station_maintenance_models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/station_maintenance_provider.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/stations/service_card.dart';

class StationMaintenanceDashboardScreen extends StatefulWidget {
  const StationMaintenanceDashboardScreen({super.key});

  @override
  State<StationMaintenanceDashboardScreen> createState() =>
      _StationMaintenanceDashboardScreenState();
}

class _StationMaintenanceDashboardScreenState
    extends State<StationMaintenanceDashboardScreen> {
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _entryTypeFilter = 'all';
  bool _autoOpened = false;

  static const List<Map<String, String>> _statusOptions = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'assigned', 'label': 'مسند'},
    {'key': 'in_progress', 'label': 'قيد التنفيذ'},
    {'key': 'under_review', 'label': 'تحت المراجعة'},
    {'key': 'needs_revision', 'label': 'رد بملاحظة'},
    {'key': 'approved', 'label': 'مقبول'},
    {'key': 'rejected', 'label': 'مرفوض'},
    {'key': 'closed', 'label': 'مغلق'},
  ];

  static const List<Map<String, String>> _typeOptions = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'maintenance', 'label': 'صيانة محطة'},
    {'key': 'development', 'label': 'تطوير محطة'},
    {'key': 'other', 'label': 'أخرى'},
  ];

  static const List<Map<String, String>> _entryTypeOptions = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'manager_request', 'label': 'طلبات الإدارة'},
    {'key': 'technician_report', 'label': 'تقارير الفني'},
  ];

  bool _isTechnicianRole(String? role) {
    return role == 'maintenance_technician' ||
        role == 'Maintenance_Technician' ||
        role == 'maintenance_station';
  }

  bool _isManagerRole(String? role) {
    return role == 'admin' ||
        role == 'owner' ||
        role == 'manager' ||
        role == 'supervisor' ||
        role == 'maintenance' ||
        role == 'maintenance_car_management';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _autoOpenTechnicianRequest();
    });
  }

  Future<void> _autoOpenTechnicianRequest() async {
    if (_autoOpened) return;

    final authProvider = context.read<AuthProvider>();
    if (!_isTechnicianRole(authProvider.user?.role)) return;

    final provider = context.read<StationMaintenanceProvider>();
    final active = await provider.fetchMyActiveRequest();
    if (!mounted) return;

    if (active != null &&
        active.entryType != 'technician_report' &&
        active.status != 'under_review') {
      _autoOpened = true;
      Navigator.pushNamed(
        context,
        AppRoutes.stationMaintenanceDetails,
        arguments: active.id,
      );
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<StationMaintenanceProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final technicianId = _isTechnicianRole(user?.role) ? user?.id : null;

    await provider.fetchRequests(
      status: _statusFilter == 'all' ? null : _statusFilter,
      type: _typeFilter == 'all' ? null : _typeFilter,
      technicianId: technicianId,
      entryType: _entryTypeFilter == 'all' ? null : _entryTypeFilter,
    );
  }

  bool _canReviewRequest(StationMaintenanceRequest request) {
    final role = context.read<AuthProvider>().user?.role;
    return _isManagerRole(role) &&
        (request.status == 'under_review' ||
            request.status == 'needs_revision');
  }

  Future<void> _openReviewDialog(
    StationMaintenanceRequest request,
    String decision,
  ) async {
    final controller = TextEditingController(
      text: decision == 'needs_revision' ? request.review?.notes ?? '' : '',
    );

    try {
      final note = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${_reviewDecisionLabel(decision)} التقرير'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: decision == 'needs_revision',
            decoration: InputDecoration(
              labelText: decision == 'needs_revision'
                  ? 'ملاحظة الإدارة'
                  : 'ملاحظة إضافية',
              hintText: decision == 'needs_revision'
                  ? 'اكتب الملاحظة التي ستظهر للفني'
                  : 'اختياري',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(_reviewDecisionLabel(decision)),
            ),
          ],
        ),
      );

      if (!mounted || note == null) return;

      if (decision == 'needs_revision' && note.trim().isEmpty) {
        _showSnack('يرجى كتابة ملاحظة قبل إرسال الرد', isError: true);
        return;
      }

      final provider = context.read<StationMaintenanceProvider>();
      final updated = await provider.reviewRequest(
        id: request.id,
        decision: decision,
        notes: note.trim(),
      );

      if (!mounted) return;

      if (updated != null) {
        _showSnack('تم حفظ قرار المراجعة');
        await _loadData();
      } else {
        _showSnack(provider.error ?? 'تعذر حفظ قرار المراجعة', isError: true);
      }
    } finally {
      controller.dispose();
    }
  }

  void _openDetails(StationMaintenanceRequest request) {
    Navigator.pushNamed(
      context,
      AppRoutes.stationMaintenanceDetails,
      arguments: request.id,
    ).then((_) => _loadData());
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationMaintenanceProvider>();
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.user?.role;
    final isTechnician = _isTechnicianRole(role);
    final isManager = _isManagerRole(role);
    final requests = provider.requests;

    final technicianReports = requests
        .where((request) => request.entryType == 'technician_report')
        .toList();
    final managerRequests = requests
        .where((request) => request.entryType != 'technician_report')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تطوير وصيانة المحطات'),
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
      ),
      body: Stack(
        children: [
          const _DashboardBackground(),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;
                final maxWidth = constraints.maxWidth < 1100
                    ? constraints.maxWidth
                    : 1100.0;
                final horizontalPadding = isCompact ? 16.0 : 24.0;

                final content = <Widget>[
                  if (isManager) ...[
                    _buildManagerActions(
                      context,
                      isCompact: isCompact,
                      maxContentWidth: maxWidth,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSummaryBanner(
                    managerRequestsCount: managerRequests.length,
                    reportsCount: technicianReports.length,
                    pendingReviewCount: requests
                        .where(
                          (request) =>
                              request.status == 'under_review' ||
                              request.status == 'needs_revision',
                        )
                        .length,
                  ),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (requests.isEmpty)
                    _buildEmptyState(isTechnician, isManager: isManager)
                  else if (_entryTypeFilter == 'all') ...[
                    if (technicianReports.isNotEmpty) ...[
                      _buildSectionTitle('تقارير الزيارة الميدانية'),
                      const SizedBox(height: 12),
                      ...technicianReports.map(_buildRequestCard),
                      const SizedBox(height: 20),
                    ],
                    if (managerRequests.isNotEmpty) ...[
                      _buildSectionTitle('طلبات الصيانة والتطوير'),
                      const SizedBox(height: 12),
                      ...managerRequests.map(_buildRequestCard),
                    ],
                  ] else
                    ...requests.map(_buildRequestCard),
                ];

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.stationMaintenanceForm,
                  arguments: const {'type': 'maintenance'},
                );
                if (!mounted) return;
                await _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('طلب جديد'),
            )
          : null,
    );
  }

  Widget _buildSummaryBanner({
    required int managerRequestsCount,
    required int reportsCount,
    required int pendingReviewCount,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -110,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ملخص السجلات',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يعرض هذا القسم طلبات الإدارة وتقارير الفني الميدانية مع حالة المراجعة الحالية.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMetricChip(
                        icon: Icons.assignment_outlined,
                        label: 'طلبات الإدارة',
                        value: managerRequestsCount.toString(),
                      ),
                      _buildMetricChip(
                        icon: Icons.fact_check_outlined,
                        label: 'تقارير الفني',
                        value: reportsCount.toString(),
                      ),
                      _buildMetricChip(
                        icon: Icons.rate_review_outlined,
                        label: 'بانتظار مراجعة',
                        value: pendingReviewCount.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildManagerActions(
    BuildContext context, {
    required bool isCompact,
    required double maxContentWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الإنشاء السريع'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isCompact ? maxContentWidth : (maxContentWidth - 12) / 2,
              child: ServiceCard(
                title: 'إنشاء صيانة محطة',
                subtitle: 'تعيين فني وفتح طلب صيانة جديد',
                icon: Icons.build_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primaryBlue, AppColors.appBarWaterBright],
                ),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.stationMaintenanceForm,
                    arguments: const {'type': 'maintenance'},
                  );
                  if (!mounted) return;
                  await _loadData();
                },
              ),
            ),
            SizedBox(
              width: isCompact ? maxContentWidth : (maxContentWidth - 12) / 2,
              child: ServiceCard(
                title: 'إنشاء تطوير محطة',
                subtitle: 'تعيين فني لطلبات التطوير',
                icon: Icons.home_repair_service_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.successGreen, AppColors.secondaryTeal],
                ),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.stationMaintenanceForm,
                    arguments: const {'type': 'development'},
                  );
                  if (!mounted) return;
                  await _loadData();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 20,
                color: Color(0xFF0F172A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'التصفية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _filtersAreActive ? _resetFilters : null,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('إعادة تعيين'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterGroup(
            label: 'الحالة',
            child: _buildChoiceWrap(
              options: _statusOptions,
              selectedValue: _statusFilter,
              onSelect: (value) {
                setState(() => _statusFilter = value);
                _loadData();
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterGroup(
            label: 'النوع',
            child: _buildChoiceWrap(
              options: _typeOptions,
              selectedValue: _typeFilter,
              onSelect: (value) {
                setState(() => _typeFilter = value);
                _loadData();
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterGroup(
            label: 'المصدر',
            child: _buildChoiceWrap(
              options: _entryTypeOptions,
              selectedValue: _entryTypeFilter,
              onSelect: (value) {
                setState(() => _entryTypeFilter = value);
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _filtersAreActive {
    return _statusFilter != 'all' ||
        _typeFilter != 'all' ||
        _entryTypeFilter != 'all';
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = 'all';
      _typeFilter = 'all';
      _entryTypeFilter = 'all';
    });
    _loadData();
  }

  Widget _buildFilterGroup({required String label, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildChoiceWrap({
    required List<Map<String, String>> options,
    required String selectedValue,
    required ValueChanged<String> onSelect,
  }) {
    final theme = Theme.of(context);
    const labelColor = Color(0xFF0F172A);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final value = option['key']!;
        final selected = selectedValue == value;
        return ChoiceChip(
          label: Text(option['label']!),
          selected: selected,
          showCheckmark: false,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? AppColors.primaryBlue : labelColor,
          ),
          backgroundColor: const Color(0xFFF8FAFC),
          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.10),
          side: BorderSide(
            color: selected
                ? AppColors.primaryBlue.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.07),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onSelected: (_) => onSelect(value),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(bool isTechnician, {required bool isManager}) {
    final theme = Theme.of(context);
    final accent = isTechnician
        ? AppColors.secondaryTeal
        : AppColors.primaryBlue;

    final title = isTechnician
        ? 'لا توجد طلبات أو تقارير حاليًا'
        : 'لا توجد سجلات صيانة حاليًا';

    final subtitle = isTechnician
        ? 'سيتم إظهار الطلبات المسندة والتقارير التي أنشأتها هنا.'
        : isManager
        ? 'ابدأ بإنشاء طلب جديد من الأعلى، أو استخدم الفلاتر لمتابعة السجلات.'
        : 'يمكنك متابعة تقارير الفنيين هنا عند توفرها.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  accent,
                  Color.lerp(accent, Colors.white, 0.35) ?? accent,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(StationMaintenanceRequest request) {
    final canReview = _canReviewRequest(request);
    final theme = Theme.of(context);

    final isReport = request.entryType == 'technician_report';
    final statusColor = _statusColor(request.status);
    final typeColor = isReport
        ? AppColors.secondaryTeal
        : AppColors.primaryBlue;
    final title = request.title.isNotEmpty
        ? request.title
        : request.entryType == 'technician_report'
        ? 'تقرير زيارة محطة'
        : _typeLabel(request.type);

    final badgeGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        typeColor,
        Color.lerp(typeColor, statusColor, 0.35) ?? typeColor,
      ],
    );

    final stripeOnRight = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  theme.colorScheme.surface,
                  Color.lerp(theme.colorScheme.surface, typeColor, 0.03) ??
                      theme.colorScheme.surface,
                ],
              ),
            ),
            child: InkWell(
              onTap: () => _openDetails(request),
              splashColor: typeColor.withValues(alpha: 0.08),
              highlightColor: typeColor.withValues(alpha: 0.04),
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    bottom: 14,
                    right: stripeOnRight ? 0 : null,
                    left: stripeOnRight ? null : 0,
                    width: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: badgeGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isReport
                                    ? Icons.fact_check_outlined
                                    : Icons.handyman_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                          height: 1.15,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildTag(
                                        isReport ? 'تقرير فني' : 'طلب إدارة',
                                        typeColor,
                                      ),
                                      if (isReport)
                                        _buildTag(
                                          request.needsMaintenance
                                              ? 'تحتاج صيانة'
                                              : 'لا تحتاج صيانة',
                                          request.needsMaintenance
                                              ? AppColors.warningOrange
                                              : AppColors.successGreen,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(request.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          children: [
                            _buildMeta(
                              icon: Icons.local_gas_station_outlined,
                              label: 'المحطة',
                              value: request.stationName.isNotEmpty
                                  ? request.stationName
                                  : 'غير محدد',
                            ),
                            _buildMeta(
                              icon: Icons.person_outline,
                              label: 'الفني',
                              value: request.assignedToName ?? 'غير محدد',
                            ),
                          ],
                        ),
                        if (request.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            request.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (request.review?.notes?.trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGray,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ملاحظة الإدارة: ${request.review!.notes!.trim()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF334155),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openDetails(request),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('التفاصيل'),
                            ),
                            if (canReview)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _openReviewDialog(request, 'approved'),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('قبول'),
                              ),
                            if (canReview)
                              OutlinedButton.icon(
                                onPressed: () => _openReviewDialog(
                                  request,
                                  'needs_revision',
                                ),
                                icon: const Icon(Icons.reply_outlined),
                                label: const Text('ملاحظة'),
                              ),
                            if (canReview)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openReviewDialog(request, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.errorRed,
                                ),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('رفض'),
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
        ),
      ),
    );
  }

  Widget _buildMeta({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF475569),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'مسند';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'under_review':
        return 'تحت المراجعة';
      case 'needs_revision':
        return 'رد بملاحظة';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'closed':
        return 'مغلق';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blueGrey;
      case 'in_progress':
        return Colors.orange;
      case 'under_review':
        return Colors.amber;
      case 'needs_revision':
        return AppColors.infoBlue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      case 'closed':
        return Colors.grey;
      default:
        return AppColors.mediumGray;
    }
  }

  String _typeLabel(String type) {
    if (type == 'development') {
      return 'تطوير محطة';
    }
    if (type == 'other') {
      return 'أخرى';
    }
    return 'صيانة محطة';
  }

  String _reviewDecisionLabel(String decision) {
    switch (decision) {
      case 'approved':
        return 'قبول';
      case 'rejected':
        return 'رفض';
      case 'needs_revision':
        return 'رد بملاحظة';
      default:
        return decision;
    }
  }
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [const Color(0xFFF8FAFF), AppColors.backgroundGray],
            ),
          ),
          child: const Stack(
            children: [
              Positioned(
                top: -170,
                left: -150,
                child: _SoftBlob(
                  size: 420,
                  colors: [Color(0x3342E8E0), Color(0x001A2980)],
                ),
              ),
              Positioned(
                bottom: -220,
                right: -170,
                child: _SoftBlob(
                  size: 520,
                  colors: [Color(0x33FF9800), Color(0x00000000)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _SoftBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
