import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:order_tracker/models/station_maintenance_models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/notification_provider.dart';
import 'package:order_tracker/providers/station_maintenance_provider.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';

class StationMaintenanceTechnicianScreen extends StatefulWidget {
  const StationMaintenanceTechnicianScreen({super.key});

  @override
  State<StationMaintenanceTechnicianScreen> createState() =>
      _StationMaintenanceTechnicianScreenState();
}

class _StationMaintenanceTechnicianScreenState
    extends State<StationMaintenanceTechnicianScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<StationMaintenanceProvider>();
    final authProvider = context.read<AuthProvider>();
    await provider.fetchRequests(technicianId: authProvider.user?.id);
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final provider = context.watch<StationMaintenanceProvider>();
    final requests = provider.requests;

    final assignedRequests = requests
        .where(
          (request) =>
              request.entryType != 'technician_report' &&
              (request.status == 'assigned' || request.status == 'in_progress'),
        )
        .toList();

    final fieldReports = requests
        .where((request) => request.entryType == 'technician_report')
        .toList();

    final followUpRequests = requests
        .where(
          (request) =>
              request.entryType != 'technician_report' &&
              request.status != 'assigned' &&
              request.status != 'in_progress',
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصيانة الميدانية'),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (notificationProvider.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notificationProvider.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'المهام',
            icon: const Icon(Icons.task_alt),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.tasks);
            },
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReport,
        icon: const Icon(Icons.note_alt_outlined),
        label: const Text('تقرير جديد'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(
              assignedCount: assignedRequests.length,
              reportsCount: fieldReports.length,
              pendingReviews: fieldReports
                  .where(
                    (report) =>
                        report.status == 'under_review' ||
                        report.status == 'needs_revision',
                  )
                  .length,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('الطلبات المسندة'),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (assignedRequests.isEmpty)
              _buildEmptyState('لا توجد طلبات مسندة حالياً')
            else
              ...assignedRequests.map(_buildRequestCard),
            const SizedBox(height: 24),
            _buildSectionTitle('تقارير الزيارة'),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (fieldReports.isEmpty)
              _buildEmptyState('لا توجد تقارير ميدانية بعد')
            else
              ...fieldReports.map(_buildRequestCard),
            const SizedBox(height: 24),
            _buildSectionTitle('سجل المتابعة'),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (followUpRequests.isEmpty)
              _buildEmptyState('لا يوجد سجل متابعة بعد')
            else
              ...followUpRequests.map(_buildRequestCard),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateReport() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.stationMaintenanceForm,
      arguments: const {'mode': 'technician_report'},
    );
    if (!mounted) return;
    await _loadData();
  }

  Widget _buildSummaryCard({
    required int assignedCount,
    required int reportsCount,
    required int pendingReviews,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة الفني',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أنشئ تقرير زيارة جديد أو تابع الطلبات الحالية وحالة مراجعتها.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricChip('طلبات نشطة', assignedCount.toString()),
              _buildMetricChip('تقارير', reportsCount.toString()),
              _buildMetricChip('بانتظار مراجعة', pendingReviews.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.92))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Text(text, style: TextStyle(color: AppColors.mediumGray)),
    );
  }

  Widget _buildRequestCard(StationMaintenanceRequest request) {
    final isAssigned = request.status == 'assigned';
    final title = request.title.isNotEmpty
        ? request.title
        : request.entryType == 'technician_report'
        ? 'تقرير زيارة محطة'
        : _typeLabel(request.type);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  request.entryType == 'technician_report'
                      ? 'تقرير ميداني'
                      : 'طلب عمل',
                  request.entryType == 'technician_report'
                      ? AppColors.secondaryTeal
                      : AppColors.primaryBlue,
                ),
                if (request.entryType == 'technician_report')
                  _buildInfoBadge(
                    request.needsMaintenance ? 'تحتاج صيانة' : 'لا تحتاج صيانة',
                    request.needsMaintenance
                        ? AppColors.warningOrange
                        : AppColors.successGreen,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'المحطة: ${request.stationName.isNotEmpty ? request.stationName : 'غير محدد'}',
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.mediumGray),
              ),
            ],
            if (request.review?.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ملاحظة الإدارة: ${request.review!.notes!.trim()}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _openDetails(request),
                  child: const Text('التفاصيل'),
                ),
                const SizedBox(width: 8),
                if (isAssigned)
                  ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    child: const Text('قبول الطلب'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _acceptRequest(StationMaintenanceRequest request) async {
    final provider = context.read<StationMaintenanceProvider>();
    final started = await provider.startRequest(request.id);
    if (!mounted) return;

    if (started == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'تعذر قبول الطلب'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    _openDetails(started);
  }

  void _openDetails(StationMaintenanceRequest request) {
    Navigator.pushNamed(
      context,
      AppRoutes.stationMaintenanceDetails,
      arguments: request.id,
    ).then((_) => _loadData());
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
}
