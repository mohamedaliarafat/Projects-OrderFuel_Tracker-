import 'dart:async';

import 'package:flutter/material.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/task_model.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/task_provider.dart';
import 'package:order_tracker/screens/tasks/task_detail_screen.dart';
import 'package:order_tracker/screens/tasks/task_form_screen.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_soft_background.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
import 'package:provider/provider.dart';

class TasksScreen extends StatefulWidget {
  final String? initialTaskCode;

  const TasksScreen({super.key, this.initialTaskCode});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  Timer? _ticker;
  Timer? _pollingTimer;

  String _statusFilter = 'all';
  bool _isLoading = false;
  bool _handledInitialCode = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadTasks();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTasks();
      await _handleInitialTaskCode();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pollingTimer?.cancel();
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final provider = context.read<TaskProvider>();
    final canViewAllTasks =
        auth.user?.hasPermission('tasks_view_all') ?? false;

    final filters = <String, dynamic>{};
    if (_searchController.text.trim().isNotEmpty) {
      filters['search'] = _searchController.text.trim();
    }
    if (_statusFilter != 'all') {
      filters['status'] = _statusFilter;
    }

    await provider.fetchTasks(mine: !canViewAllTasks, filters: filters);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleInitialTaskCode() async {
    if (_handledInitialCode) return;
    final code = widget.initialTaskCode?.trim();
    if (code == null || code.isEmpty) return;
    _handledInitialCode = true;

    final provider = context.read<TaskProvider>();
    final task = await provider.lookupTaskByCode(code);
    if (!mounted || task == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    ).then((_) => _loadTasks());
  }

  Future<void> _acceptByCode() async {
    final provider = context.read<TaskProvider>();
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final task = await provider.acceptTaskByCode(code);
    if (!mounted) return;

    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر استلام المهمة، تحقق من الرقم')),
      );
      return;
    }

    _codeController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    ).then((_) => _loadTasks());
  }

  bool _isOverdue(TaskModel task) {
    return task.status == 'overdue' || task.isDeadlineExpired;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'بدون مهلة';
    final absolute = duration.isNegative ? duration.abs() : duration;
    final days = absolute.inDays;
    final hours = absolute.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = absolute.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = absolute.inSeconds.remainder(60).toString().padLeft(2, '0');
    return days > 0
        ? '$days يوم $hours:$minutes:$seconds'
        : '$hours:$minutes:$seconds';
  }

  String _countdownText(TaskModel task) {
    final remaining = task.deadlineRemaining;
    if (remaining == null) return 'بدون مهلة';
    if (remaining.isNegative) return 'متأخرة منذ ${_formatDuration(remaining)}';
    return 'متبقي ${_formatDuration(remaining)}';
  }

  String _statusLabel(TaskModel task) {
    if (_isOverdue(task)) return 'انتهت المهلة';
    switch (task.status) {
      case 'assigned':
        return 'تم الإسناد';
      case 'accepted':
        return 'تم الاستلام';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتملة';
      case 'approved':
        return 'معتمدة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return task.status;
    }
  }

  Color _statusColor(TaskModel task) {
    if (_isOverdue(task)) return AppColors.errorRed;
    switch (task.status) {
      case 'accepted':
        return AppColors.primaryBlue;
      case 'in_progress':
        return AppColors.infoBlue;
      case 'completed':
      case 'approved':
        return AppColors.successGreen;
      case 'assigned':
        return AppColors.warningOrange;
      case 'rejected':
        return AppColors.errorRed;
      default:
        return AppColors.mediumGray;
    }
  }

  IconData _statusIcon(TaskModel task) {
    if (_isOverdue(task)) return Icons.timer_off_rounded;
    switch (task.status) {
      case 'accepted':
        return Icons.inventory_2_rounded;
      case 'in_progress':
        return Icons.autorenew_rounded;
      case 'completed':
      case 'approved':
        return Icons.task_alt_rounded;
      case 'assigned':
        return Icons.assignment_ind_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  int _gridColumns(double width) {
    if (width >= 1280) return 3;
    if (width >= 780) return 2;
    return 1;
  }

  void _openTaskDetails(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    ).then((_) => _loadTasks());
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.88),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.appBarWaterBright.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.appBarWaterBright,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildTopSummary(List<TaskModel> tasks, bool canViewAllTasks) {
    final overdueCount = tasks.where(_isOverdue).length;
    final activeCount = tasks.where((task) => !task.isDone).length;
    final doneCount = tasks.where((task) => task.isDone).length;
    final extensionCount = tasks
        .where((task) => task.extensionRequest?.isPending ?? false)
        .length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF22C1C3)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canViewAllTasks ? 'لوحة إدارة المهام' : 'لوحة مهامي اليومية',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canViewAllTasks
                    ? 'متابعة سريعة للمهام المكلفة، الحالات الحرجة، وتمديدات المهلة من مكان واحد.'
                    : 'كل المهام الموكلة لك مع العدّ التنازلي، التحديثات، وإمكانية الاستلام السريع من رقم المهمة.',
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1120
                ? 4
                : (constraints.maxWidth >= 720 ? 2 : 1);
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - ((columns - 1) * 12)) / columns;

            final items = [
              _SummaryTileData(
                label: 'مهام نشطة',
                value: '$activeCount',
                icon: Icons.bolt_rounded,
                color: AppColors.primaryBlue,
              ),
              _SummaryTileData(
                label: 'مكتملة',
                value: '$doneCount',
                icon: Icons.task_alt_rounded,
                color: AppColors.successGreen,
              ),
              _SummaryTileData(
                label: 'متأخرة',
                value: '$overdueCount',
                icon: Icons.warning_amber_rounded,
                color: AppColors.errorRed,
              ),
              _SummaryTileData(
                label: 'تمديد معلق',
                value: '$extensionCount',
                icon: Icons.update_rounded,
                color: AppColors.warningOrange,
              ),
            ];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map(
                    (item) =>
                        SizedBox(width: width, child: _buildSummaryTile(item)),
                  )
                  .toList(),
            );
          },
        ),
        if (!canViewAllTasks) ...[
          const SizedBox(height: 16),
          _buildAcceptByCodeCard(),
        ],
      ],
    );
  }

  Widget _buildSummaryTile(_SummaryTileData item) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: item.color.withValues(alpha: 0.12)),
      color: Colors.white.withValues(alpha: 0.76),
      boxShadow: [
        BoxShadow(
          color: item.color.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptByCodeCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 820;

          final field = TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _fieldDecoration(
              label: 'استلام مهمة عبر رقم المهمة',
              hintText: 'أدخل رقم المهمة المكوّن من 6 أرقام',
              icon: Icons.pin_outlined,
            ).copyWith(counterText: ''),
            onSubmitted: (_) => _acceptByCode(),
          );

          final button = FilledButton.icon(
            onPressed: _acceptByCode,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('استلام المهمة'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الاستلام السريع',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'إذا وصلك رقم مهمة مباشر يمكنك استلامها من هنا والدخول إلى تفاصيلها فورًا.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (horizontal)
                Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 12),
                    button,
                  ],
                )
              else ...[
                field,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: button),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 980;

          final searchField = TextField(
            controller: _searchController,
            decoration: _fieldDecoration(
              label: 'بحث',
              hintText: 'ابحث بالعنوان أو رقم المهمة أو اسم المسؤول',
              icon: Icons.search_rounded,
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _loadTasks();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _loadTasks(),
          );

          final statusField = DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: _fieldDecoration(
              label: 'الحالة',
              hintText: 'اختر الحالة',
              icon: Icons.tune_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('الكل')),
              DropdownMenuItem(value: 'assigned', child: Text('تم الإسناد')),
              DropdownMenuItem(value: 'accepted', child: Text('تم الاستلام')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('قيد التنفيذ'),
              ),
              DropdownMenuItem(value: 'completed', child: Text('مكتملة')),
              DropdownMenuItem(value: 'approved', child: Text('معتمدة')),
              DropdownMenuItem(value: 'rejected', child: Text('مرفوضة')),
              DropdownMenuItem(value: 'overdue', child: Text('متأخرة')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _statusFilter = value);
              _loadTasks();
            },
          );

          final refreshButton = FilledButton(
            onPressed: _loadTasks,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(58, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(Icons.refresh_rounded),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تصفية المهام',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ابحث بسرعة عن المهمة المطلوبة أو ركّز على حالة تنفيذ محددة.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (horizontal)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: statusField),
                    const SizedBox(width: 12),
                    refreshButton,
                  ],
                )
              else ...[
                searchField,
                const SizedBox(height: 12),
                statusField,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: refreshButton),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool canViewAllTasks) {
    final statusColor = _statusColor(task);
    final description = task.description.trim();
    final workerNames = task.workerNames;
    final hasDeadline = task.dueDate != null;
    final penalty = task.overduePenalty;
    final extensionPending = task.extensionRequest?.isPending ?? false;

    return AppSurfaceCard(
      onTap: () => _openTaskDetails(task),
      padding: const EdgeInsets.all(18),
      border: Border.all(color: statusColor.withValues(alpha: 0.12)),
      color: Colors.white.withValues(alpha: 0.80),
      boxShadow: [
        BoxShadow(
          color: statusColor.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.department.trim().isNotEmpty
                          ? task.department
                          : 'بدون قسم محدد',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(task),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(
                icon: Icons.tag_rounded,
                text: 'رقم ${task.taskCode}',
                color: AppColors.primaryBlue,
              ),
              if (task.assignedToName.trim().isNotEmpty)
                _buildMetaChip(
                  icon: Icons.person_outline_rounded,
                  text:
                      '${canViewAllTasks ? 'المسؤول' : 'المكلّف'}: ${task.assignedToName}',
                  color: AppColors.infoBlue,
                ),
              if (workerNames.length > 1)
                _buildMetaChip(
                  icon: Icons.groups_rounded,
                  text: '${workerNames.length} مشاركين',
                  color: const Color(0xFF7C3AED),
                ),
              if (task.attachments.isNotEmpty)
                _buildMetaChip(
                  icon: Icons.attach_file_rounded,
                  text: '${task.attachments.length} مرفق',
                  color: const Color(0xFF0F766E),
                ),
              if (task.messages.isNotEmpty)
                _buildMetaChip(
                  icon: Icons.forum_outlined,
                  text: '${task.messages.length} رسالة',
                  color: const Color(0xFF475569),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (hasDeadline) ...[
            const SizedBox(height: 14),
            _buildDeadlinePanel(task, statusColor),
          ],
          if (extensionPending || (penalty?.enabled ?? false)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (extensionPending)
                  _buildNoticeChip(
                    icon: Icons.update_rounded,
                    text: 'يوجد طلب تمديد بانتظار القرار',
                    color: AppColors.warningOrange,
                  ),
                if (penalty?.enabled ?? false)
                  _buildNoticeChip(
                    icon: penalty!.isApplied
                        ? Icons.verified_rounded
                        : Icons.price_change_outlined,
                    text: penalty.isApplied
                        ? 'تم تطبيق استقطاع ${penalty.amount.toStringAsFixed(2)} ${penalty.currency}'
                        : 'استقطاع مجهز ${penalty.amount.toStringAsFixed(2)} ${penalty.currency}',
                    color: penalty.isApplied
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildFooterMeta('الإسناد', _formatDate(task.assignedAt)),
                      if (task.acceptedAt != null)
                        _buildFooterMeta(
                          'الاستلام',
                          _formatDate(task.acceptedAt),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'عرض التفاصيل',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: statusColor, size: 22),
              ],
            ),
          ),
          if (canViewAllTasks && extensionPending) ...[
            const SizedBox(height: 10),
            const Text(
              'يمكن اعتماد أو رفض التمديد من شاشة تفاصيل المهمة.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskModel task) {
    final color = _statusColor(task);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(task), color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            _statusLabel(task),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinePanel(TaskModel task, Color statusColor) {
    final isOverdue = _isOverdue(task);
    final accent = isOverdue ? AppColors.errorRed : AppColors.primaryBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOverdue ? Icons.timer_off_rounded : Icons.timer_outlined,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _countdownText(task),
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الموعد النهائي: ${_formatDate(task.dueDate)}',
                  style: TextStyle(
                    color: statusColor == AppColors.mediumGray
                        ? const Color(0xFF475569)
                        : const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTasksContent(
    List<TaskModel> tasks,
    bool canViewAllTasks,
    String? errorMessage,
  ) {
    if (_isLoading) {
      return const AppSurfaceCard(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'جارٍ تحميل المهام...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && tasks.isEmpty) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(18),
        color: AppColors.errorRed.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.18)),
        boxShadow: const [],
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Color(0xFF7F1D1D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return AppSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              size: 62,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            Text(
              canViewAllTasks
                  ? 'لا توجد مهام حالياً'
                  : 'لا توجد مهام مسندة لك حالياً',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'جرّب تعديل البحث أو الفلترة، أو أعد التحديث لاحقًا لعرض المهام الجديدة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _gridColumns(constraints.maxWidth);
        final spacing = 14.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tasks
              .map(
                (task) => SizedBox(
                  width: itemWidth,
                  child: _buildTaskCard(task, canViewAllTasks),
                ),
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final canViewTasks =
        auth.user?.hasAnyPermission(const ['tasks_view', 'tasks_view_all']) ??
        false;
    final canViewAllTasks =
        auth.user?.hasPermission('tasks_view_all') ?? false;
    final canCreateTasks =
        auth.user?.hasAnyPermission(const ['tasks_create', 'tasks_edit']) ??
        false;
    final tasks = canViewAllTasks ? taskProvider.tasks : taskProvider.myTasks;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700;
    final horizontalPadding = isDesktop ? 28.0 : (isTablet ? 20.0 : 16.0);

    if (!canViewTasks) {
      return Scaffold(
        appBar: AppBar(title: const Text('المهام')),
        body: const Center(
          child: Text('لا تملك صلاحية عرض صفحة المهام.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text('المهام'),
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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          if (canCreateTasks)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                    MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                );
                _loadTasks();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          const AppSoftBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: RefreshIndicator(
                onRefresh: _loadTasks,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    120,
                  ),
                  children: [
                    _buildTopSummary(tasks, canViewAllTasks),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    if (taskProvider.error != null && tasks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AppSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        color: AppColors.warningOrange.withValues(alpha: 0.10),
                        border: Border.all(
                          color: AppColors.warningOrange.withValues(
                            alpha: 0.18,
                          ),
                        ),
                        boxShadow: const [],
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.warningOrange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                taskProvider.error!,
                                style: const TextStyle(
                                  color: Color(0xFF7C2D12),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTasksContent(
                      tasks,
                      canViewAllTasks,
                      taskProvider.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTileData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
