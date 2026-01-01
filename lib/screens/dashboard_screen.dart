// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/models/customer_model.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/notification_provider.dart';
import 'package:order_tracker/providers/order_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/widgets/recent_orders_widget.dart';
import 'package:order_tracker/widgets/stat_card.dart';
import 'package:order_tracker/widgets/overdue_orders_widget.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<OrderTimer> _approachingTimers = [];
  bool _loadingTimers = false;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      await orderProvider.fetchOrders();
      await Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();

      await _loadApproachingTimers();

      _startLiveTimer(); // 🔥 تشغيل التايمر live
    });
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      bool hasActiveCountdown = false;

      for (final order in orderProvider.orders) {
        // تجاهل المكتمل والملغى
        if (order.status == 'تم التنفيذ' || order.status == 'ملغى') {
          continue;
        }

        final loadingDateTime = DateTime(
          order.loadingDate.year,
          order.loadingDate.month,
          order.loadingDate.day,
          int.parse(order.loadingTime.split(':')[0]),
          int.parse(order.loadingTime.split(':')[1]),
        );

        final remaining = loadingDateTime.difference(DateTime.now());

        if (remaining <= Duration.zero) {
          // ⛔ انتهى وقت التحميل → تحديث رسمي
          orderProvider.markOrderAsCompleted(order.id);
        } else {
          hasActiveCountdown = true;
        }
      }

      if (!hasActiveCountdown) {
        _liveTimer?.cancel();
        _liveTimer = null;
      }

      setState(() {});
    });
  }

  Future<void> _loadApproachingTimers() async {
    setState(() {
      _loadingTimers = true;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final orders = orderProvider.orders;

    final timers = orders
        // ✅ نعتمد على الحالة فقط
        .where(
          (order) => order.status != 'تم التنفيذ' && order.status != 'ملغى',
        )
        .map((order) {
          try {
            final arrivalDateTime = DateTime(
              order.arrivalDate.year,
              order.arrivalDate.month,
              order.arrivalDate.day,
              int.parse(order.arrivalTime.split(':')[0]),
              int.parse(order.arrivalTime.split(':')[1]),
            );

            final loadingDateTime = DateTime(
              order.loadingDate.year,
              order.loadingDate.month,
              order.loadingDate.day,
              int.parse(order.loadingTime.split(':')[0]),
              int.parse(order.loadingTime.split(':')[1]),
            );

            return OrderTimer(
              orderId: order.id,
              arrivalDateTime: arrivalDateTime,
              loadingDateTime: loadingDateTime,
              orderNumber: order.orderNumber,
              supplierName: order.supplierName,
              customerName: order.customer?.name,
              driverName: order.driverName,
              status: order.status,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<OrderTimer>()
        .toList();

    // ✅ لا فلترة على الوقت إطلاقًا
    setState(() {
      _approachingTimers = timers; // كل الطلبات النشطة
      _loadingTimers = false;
    });
  }

  // عنصر تنقل سريع
  Widget _navItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // دالة للحصول على الطلبات المتأخرة
  List<Map<String, dynamic>> _getOverdueOrders(List orders) {
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    return orders
        .where((order) {
          return order.status == 'في انتظار عمل طلب جديد' &&
              order.createdAt.isBefore(twoHoursAgo) &&
              order.notificationSentAt == null;
        })
        .map((order) {
          final hoursSinceCreation = DateTime.now()
              .difference(order.createdAt)
              .inHours;
          return {'order': order, 'hours': hoursSinceCreation};
        })
        .toList();
  }

  // دالة لتحديد عدد الأعمدة بناء على حجم الشاشة
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1200) {
      return 4; // شاشات كبيرة
    } else if (width > 800) {
      return 3; // شاشات متوسطة
    } else if (width > 600) {
      return 2; // تابلت
    } else {
      return 2; // جوال
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final orders = orderProvider.orders;
    final overdueOrders = _getOverdueOrders(orders);

    // تحديد إذا كنا في وضع الويب/كمبيوتر
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    // Statistics
    final totalOrders = orderProvider.totalOrders;
    final pendingOrders = orders
        .where((order) => order.status == 'في انتظار عمل طلب جديد')
        .length;
    final assignedOrders = orders
        .where((order) => order.status == 'تم دمجه')
        .length;
    final processingOrders = orders
        .where((order) => order.status == 'مدمج وجاهز للتنفيذ')
        .length;
    final readyOrders = orders
        .where((order) => order.status == 'جاهز للتحميل')
        .length;
    final completedOrders = orders
        .where((order) => order.status == 'تم التنفيذ')
        .length;
    final cancelledOrders = orders
        .where((order) => order.status == 'ملغى')
        .length;

    final today = DateTime.now();
    final todayOrders = orders.where((order) {
      final d = order.orderDate;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisWeekOrders = orders.where((order) {
      return order.orderDate.isAfter(weekStart);
    }).length;

    final monthStart = DateTime(today.year, today.month, 1);
    final thisMonthOrders = orders.where((order) {
      return order.orderDate.isAfter(monthStart);
    }).length;

    // Chart data
    final statusData = [
      {
        'status': 'في انتظار عمل طلب جديد',
        'count': pendingOrders,
        'color': AppColors.pendingYellow,
      },
      {
        'status': 'تم دمجه',
        'count': assignedOrders,
        'color': AppColors.infoBlue,
      },
      {
        'status': 'مدمج وجاهز للتنفيذ',
        'count': processingOrders,
        'color': AppColors.warningOrange,
      },
      {
        'status': 'جاهز للتحميل',
        'count': readyOrders,
        'color': AppColors.accentBlue,
      },
      {
        'status': 'تم التنفيذ',
        'count': completedOrders,
        'color': AppColors.successGreen,
      },
      {'status': 'ملغى', 'count': cancelledOrders, 'color': AppColors.errorRed},
    ];

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(AppStrings.dashboard),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
                  icon: Badge(
                    isLabelVisible: notificationProvider.unreadCount > 0,
                    label: Text(notificationProvider.unreadCount.toString()),
                    backgroundColor: AppColors.errorRed,
                    textColor: Colors.white,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: isDesktop
          ? _buildDesktopLayout(
              context,
              authProvider,
              orderProvider,
              notificationProvider,
              orders,
              overdueOrders,
              totalOrders,
              pendingOrders,
              assignedOrders,
              processingOrders,
              readyOrders,
              completedOrders,
              cancelledOrders,
              todayOrders,
              thisWeekOrders,
              thisMonthOrders,
              statusData,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await orderProvider.fetchOrders();
                await notificationProvider.fetchNotifications();
                await _loadApproachingTimers();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    _buildWelcomeCard(context, authProvider),
                    const SizedBox(height: 20),

                    // ⭐ Countdown Section for mobile
                    if (!_loadingTimers && _approachingTimers.isNotEmpty)
                      CountdownSection(
                        timers: _approachingTimers,
                        onViewAll: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.orders,
                            arguments: {'showCountdown': true},
                          );
                        },
                      ),

                    if (!_loadingTimers && _approachingTimers.isNotEmpty)
                      const SizedBox(height: 20),

                    // Overdue orders warning
                    if (overdueOrders.isNotEmpty)
                      OverdueOrdersWidget(
                        orders: orders,
                        onViewAll: () {
                          Navigator.pushNamed(context, AppRoutes.orders);
                        },
                      ),

                    if (overdueOrders.isNotEmpty) const SizedBox(height: 20),

                    // Statistics
                    _buildStatisticsSection(
                      context,
                      totalOrders,
                      pendingOrders,
                      assignedOrders,
                      completedOrders,
                      todayOrders,
                      thisWeekOrders,
                      thisMonthOrders,
                      cancelledOrders,
                    ),
                    const SizedBox(height: 30),

                    // Quick navigation
                    _buildQuickNavigation(context),
                    const SizedBox(height: 30),

                    // Chart
                    _buildChartSection(context, statusData),
                    const SizedBox(height: 30),

                    // Recent orders
                    _buildRecentOrdersSection(context, orders),
                    const SizedBox(height: 20),

                    // Additional info card
                    _buildPerformanceCard(
                      totalOrders,
                      completedOrders,
                      readyOrders,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================
  // واجهة سطح المكتب (Web/Desktop)
  // ============================================
  Widget _buildDesktopLayout(
    BuildContext context,
    AuthProvider authProvider,
    OrderProvider orderProvider,
    NotificationProvider notificationProvider,
    List orders,
    List<Map<String, dynamic>> overdueOrders,
    int totalOrders,
    int pendingOrders,
    int assignedOrders,
    int processingOrders,
    int readyOrders,
    int completedOrders,
    int cancelledOrders,
    int todayOrders,
    int thisWeekOrders,
    int thisMonthOrders,
    List<Map<String, dynamic>> statusData,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'طلبات البحيرة العربة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDesktopNavItem(
                      icon: Icons.dashboard,
                      title: 'لوحة التحكم',
                      isSelected: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.list_alt,
                      title: 'الطلبات',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.orders),
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.add_circle_outline,
                      title: 'إنشاء طلب توريد',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.supplierOrderForm,
                      ),
                    ),
                    _buildDesktopNavItem(
                      icon: Icons.add_circle_outline,
                      title: 'إنشاء طلب عميل',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.customerOrderForm,
                      ),
                    ),
                    _buildDesktopNavItem(
                      icon: Icons.add_circle_outline,
                      title: 'إنشاء طلب',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.mergeOrders),
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.people_outline,
                      title: 'العملاء',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.customers),
                    ),
                    _buildDesktopNavItem(
                      icon: Icons.people_outline,
                      title: 'الموردين',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.suppliers),
                    ),
                    _buildDesktopNavItem(
                      icon: Icons.people_outline,
                      title: 'السائقين',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.drivers),
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.local_activity,
                      title: 'الأنشطة',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.activities),
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.notifications_outlined,
                      title: 'الإشعارات',
                      badge: notificationProvider.unreadCount,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.notifications),
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.person,
                      title: 'الملف الشخصي',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                    ),
                    const SizedBox(height: 8),
                    _buildDesktopNavItem(
                      icon: Icons.settings,
                      title: 'الإعدادات',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                  ],
                ),
              ),
              // User info at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        authProvider.user?.name
                                .split(' ')
                                .map((n) => n.isNotEmpty ? n[0] : '')
                                .take(2)
                                .join('')
                                .toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.user?.name ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            authProvider.user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await orderProvider.fetchOrders();
              await notificationProvider.fetchNotifications();
              await _loadApproachingTimers();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar for desktop
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'شركة البحيرة العربية للنقليات',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.notifications,
                              );
                            },
                            icon: Badge(
                              isLabelVisible:
                                  notificationProvider.unreadCount > 0,
                              label: Text(
                                notificationProvider.unreadCount.toString(),
                              ),
                              backgroundColor: AppColors.errorRed,
                              textColor: Colors.white,
                              child: const Icon(Icons.notifications_outlined),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildDesktopDateInfo(),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ⭐ Countdown Banner for desktop (when approaching 2.5 hours)
                  if (!_loadingTimers && _approachingTimers.isNotEmpty)
                    _buildDesktopCountdownBanner(context, _approachingTimers),

                  // Welcome card for desktop
                  _buildDesktopWelcomeCard(context, authProvider),
                  const SizedBox(height: 24),

                  // Statistics grid for desktop
                  Text(
                    'الإحصائيات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        title: AppStrings.totalOrders,
                        value: totalOrders.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primaryBlue,
                        gradient: AppColors.primaryGradient,
                        isDesktop: true,
                      ),
                      StatCard(
                        title: 'في انتظار عمل طلب جديد',
                        value: pendingOrders.toString(),
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.pendingYellow,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.pendingYellow,
                            AppColors.pendingYellow.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                      StatCard(
                        title: 'تم دمجه',
                        value: assignedOrders.toString(),
                        icon: Icons.person_outline,
                        color: AppColors.infoBlue,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.infoBlue,
                            AppColors.infoBlue.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                      StatCard(
                        title: AppStrings.completedOrders,
                        value: completedOrders.toString(),
                        icon: Icons.check_circle_outline,
                        color: AppColors.successGreen,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.successGreen,
                            AppColors.successGreen.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                      StatCard(
                        title: 'طلبات اليوم',
                        value: todayOrders.toString(),
                        icon: Icons.today_outlined,
                        color: AppColors.accentBlue,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentBlue,
                            AppColors.accentBlue.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                      StatCard(
                        title: 'طلبات الأسبوع',
                        value: thisWeekOrders.toString(),
                        icon: Icons.calendar_view_week,
                        color: AppColors.secondaryTeal,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondaryTeal,
                            AppColors.secondaryTeal.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                      StatCard(
                        title: 'طلبات الشهر',
                        value: thisMonthOrders.toString(),
                        icon: Icons.calendar_month,
                        color: AppColors.warningOrange,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warningOrange,
                            AppColors.warningOrange.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                      StatCard(
                        title: 'مرفوضة',
                        value: cancelledOrders.toString(),
                        icon: Icons.cancel_outlined,
                        color: AppColors.errorRed,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.errorRed,
                            AppColors.errorRed.withOpacity(0.7),
                          ],
                        ),
                        isDesktop: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ⭐ Countdown Grid for desktop
                  if (!_loadingTimers && _approachingTimers.isNotEmpty)
                    _buildDesktopCountdownGrid(context, _approachingTimers),

                  // Chart and recent orders side by side for desktop
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chart
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'توزيع الطلبات حسب الحالة',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                    ),
                                    Icon(
                                      Icons.pie_chart_outline,
                                      color: AppColors.primaryBlue,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 350,
                                  child: SfCircularChart(
                                    legend: Legend(
                                      isVisible: true,
                                      position: LegendPosition.right,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                      ),
                                      overflowMode:
                                          LegendItemOverflowMode.scroll,
                                    ),
                                    tooltipBehavior: TooltipBehavior(
                                      enable: true,
                                      format: 'point.x : point.y طلب',
                                    ),
                                    series: <CircularSeries>[
                                      DoughnutSeries<
                                        Map<String, dynamic>,
                                        String
                                      >(
                                        dataSource: statusData,
                                        xValueMapper: (data, _) =>
                                            data['status'] as String,
                                        yValueMapper: (data, _) =>
                                            data['count'] as int,
                                        pointColorMapper: (data, _) =>
                                            data['color'] as Color,
                                        dataLabelSettings:
                                            const DataLabelSettings(
                                              isVisible: true,
                                              labelPosition:
                                                  ChartDataLabelPosition
                                                      .outside,
                                              textStyle: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 12,
                                              ),
                                              connectorLineSettings:
                                                  ConnectorLineSettings(
                                                    type: ConnectorType.curve,
                                                    length: '10%',
                                                  ),
                                            ),
                                        animationDuration: 1000,
                                        enableTooltip: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Recent orders
                      Expanded(
                        flex: 1,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'الطلبات الحديثة',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.orders,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        size: 20,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (orders.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 60,
                                          color: AppColors.primaryBlue
                                              .withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد طلبات حالياً',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.mediumGray,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (orders.length < 5)
                                  Column(
                                    children: [
                                      RecentOrdersWidget(
                                        orders: List<Order>.from(orders),
                                      ),
                                      const SizedBox(height: 16),
                                      if (orders.isEmpty)
                                        Center(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.orderForm,
                                              );
                                            },
                                            icon: const Icon(Icons.add),
                                            label: const Text('إنشاء طلب جديد'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryBlue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                else
                                  RecentOrdersWidget(
                                    orders: List<Order>.from(orders.take(5)),
                                    isDesktop: true,
                                  ),
                                const SizedBox(height: 16),
                                if (orders.isNotEmpty && orders.length > 5)
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.orders,
                                        );
                                      },
                                      child: const Text('عرض جميع الطلبات'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Performance metrics for desktop
                  _buildDesktopPerformanceCard(
                    totalOrders,
                    completedOrders,
                    readyOrders,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ⭐ Banner for desktop when approaching 2.5 hours
  Widget _buildDesktopCountdownBanner(
    BuildContext context,
    List<OrderTimer> approachingTimers,
  ) {
    final urgentTimers = approachingTimers.where((timer) {
      final arrivalRemaining = timer.remainingTimeToArrival;
      return arrivalRemaining <= const Duration(hours: 2, minutes: 30) &&
          arrivalRemaining > Duration.zero;
    }).toList();

    if (urgentTimers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.shade800,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلبات تقترب من وقت الوصول!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${urgentTimers.length} طلب سيصل خلال ساعتين ونصف',
                  style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.orders,
                arguments: {'showUrgent': true},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('عرض الطلبات'),
          ),
        ],
      ),
    );
  }

  // ⭐ Grid for countdown timers on desktop
  Widget _buildDesktopCountdownGrid(
    BuildContext context,
    List<OrderTimer> approachingTimers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الطلبات القريبة من وقتها',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.warningOrange,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.orders,
                  arguments: {'showCountdown': true},
                );
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.9,
          children: approachingTimers.take(6).map((timer) {
            return CountdownCard(
              timer: timer,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.orderDetails,
                  arguments: timer.orderId,
                );
              },
              isDesktop: true,
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildDesktopNavItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    int? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade700,
                ),
              ),
            ),
            if (badge != null && badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDateInfo() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMMM y', 'ar');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          dateFormat.format(now),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          DateFormat('hh:mm a').format(now),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildDesktopWelcomeCard(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  authProvider.user?.name
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .take(2)
                          .join('')
                          .toUpperCase() ??
                      'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً ${authProvider.user?.name ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.user?.company ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ),
            // Quick actions for desktop
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.orderForm);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('طلب جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.reports);
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('التقارير'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPerformanceCard(
    int totalOrders,
    int completedOrders,
    int readyOrders,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الأداء',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 2.5,
              children: [
                _buildDesktopPerformanceItem(
                  icon: Icons.timer_outlined,
                  title: 'متوسط وقت الاستجابة',
                  value: '2.5 ساعة',
                  color: AppColors.successGreen,
                ),
                _buildDesktopPerformanceItem(
                  icon: Icons.thumb_up_outlined,
                  title: 'معدل الإنجاز',
                  value:
                      '${totalOrders > 0 ? ((completedOrders / totalOrders) * 100).toStringAsFixed(1) : '0'}%',
                  color: AppColors.primaryBlue,
                ),
                _buildDesktopPerformanceItem(
                  icon: Icons.group_outlined,
                  title: 'العملاء النشطين',
                  value: '12',
                  color: AppColors.secondaryTeal,
                ),
                _buildDesktopPerformanceItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'طلبات التحميل',
                  value: readyOrders.toString(),
                  color: AppColors.warningOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPerformanceItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.mediumGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // المكونات المشتركة للموبايل والكمبيوتر
  // ============================================

  Widget _buildWelcomeCard(BuildContext context, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  authProvider.user?.name
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .take(2)
                          .join('')
                          .toUpperCase() ??
                      'U',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً ${authProvider.user?.name ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.user?.company ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    authProvider.user?.email ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.lightGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    int totalOrders,
    int pendingOrders,
    int assignedOrders,
    int completedOrders,
    int todayOrders,
    int thisWeekOrders,
    int thisMonthOrders,
    int cancelledOrders,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإحصائيات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 1.5,
          children: [
            StatCard(
              title: AppStrings.totalOrders,
              value: totalOrders.toString(),
              icon: Icons.inventory_2_outlined,
              color: AppColors.primaryBlue,
              gradient: AppColors.primaryGradient,
            ),
            StatCard(
              title: 'في انتظار عمل طلب جديد',
              value: pendingOrders.toString(),
              icon: Icons.pending_actions_outlined,
              color: AppColors.pendingYellow,
              gradient: LinearGradient(
                colors: [
                  AppColors.pendingYellow,
                  AppColors.pendingYellow.withOpacity(0.7),
                ],
              ),
            ),
            StatCard(
              title: 'تم دمجه',
              value: assignedOrders.toString(),
              icon: Icons.person_outline,
              color: AppColors.infoBlue,
              gradient: LinearGradient(
                colors: [
                  AppColors.infoBlue,
                  AppColors.infoBlue.withOpacity(0.7),
                ],
              ),
            ),
            StatCard(
              title: AppStrings.completedOrders,
              value: completedOrders.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.successGreen,
              gradient: LinearGradient(
                colors: [
                  AppColors.successGreen,
                  AppColors.successGreen.withOpacity(0.7),
                ],
              ),
            ),
            StatCard(
              title: 'طلبات اليوم',
              value: todayOrders.toString(),
              icon: Icons.today_outlined,
              color: AppColors.accentBlue,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue,
                  AppColors.accentBlue.withOpacity(0.7),
                ],
              ),
            ),
            StatCard(
              title: 'طلبات الأسبوع',
              value: thisWeekOrders.toString(),
              icon: Icons.calendar_view_week,
              color: AppColors.secondaryTeal,
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryTeal,
                  AppColors.secondaryTeal.withOpacity(0.7),
                ],
              ),
            ),
            StatCard(
              title: 'طلبات الشهر',
              value: thisMonthOrders.toString(),
              icon: Icons.calendar_month,
              color: AppColors.warningOrange,
              gradient: LinearGradient(
                colors: [
                  AppColors.warningOrange,
                  AppColors.warningOrange.withOpacity(0.7),
                ],
              ),
            ),
            StatCard(
              title: 'مرفوضة',
              value: cancelledOrders.toString(),
              icon: Icons.cancel_outlined,
              color: AppColors.errorRed,
              gradient: LinearGradient(
                colors: [
                  AppColors.errorRed,
                  AppColors.errorRed.withOpacity(0.7),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickNavigation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التنقل السريع',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.1 : 1.2,
          children: [
            _navItem(
              icon: Icons.list_alt,
              title: 'الطلبات',
              color: AppColors.primaryBlue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
            ),
            _navItem(
              icon: Icons.add_circle_outline,
              title: 'نشاء طلب مورد',
              color: AppColors.successGreen,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.supplierOrderForm),
            ),
            _navItem(
              icon: Icons.add_circle_outline,
              title: 'انشاء طلب عميل',
              color: AppColors.successGreen,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.customerOrderForm),
            ),
            _navItem(
              icon: Icons.add_circle_outline,
              title: 'انشاء طلب',
              color: AppColors.successGreen,
              onTap: () => Navigator.pushNamed(context, AppRoutes.mergeOrders),
            ),
            _navItem(
              icon: Icons.people_outline,
              title: 'العملاء',
              color: AppColors.secondaryTeal,
              onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
            ),
            _navItem(
              icon: Icons.people_outline,
              title: 'السائقين',
              color: AppColors.secondaryTeal,
              onTap: () => Navigator.pushNamed(context, AppRoutes.drivers),
            ),
            _navItem(
              icon: Icons.local_activity,
              title: 'الأنشطة',
              color: AppColors.warningOrange,
              onTap: () => Navigator.pushNamed(context, AppRoutes.activities),
            ),
            _navItem(
              icon: Icons.notifications_outlined,
              title: 'الإشعارات',
              color: AppColors.accentBlue,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            _navItem(
              icon: Icons.person,
              title: 'الملف الشخصي',
              color: AppColors.infoBlue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
            _navItem(
              icon: Icons.settings,
              title: 'الإعدادات',
              color: AppColors.mediumGray,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
            _navItem(
              icon: Icons.insert_chart_outlined,
              title: 'التقارير',
              color: AppColors.primaryDarkBlue,
              onTap: () {
                // TODO: Add reports screen
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    List<Map<String, dynamic>> statusData,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'توزيع الطلبات حسب الحالة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Icon(
                  Icons.pie_chart_outline,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : point.y طلب',
                ),
                series: <CircularSeries>[
                  DoughnutSeries<Map<String, dynamic>, String>(
                    dataSource: statusData,
                    xValueMapper: (data, _) => data['status'] as String,
                    yValueMapper: (data, _) => data['count'] as int,
                    pointColorMapper: (data, _) => data['color'] as Color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '10%',
                      ),
                    ),
                    animationDuration: 1000,
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, List orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الطلبات الحديثة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.orders);
              },
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('عرض الكل'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          EmptyOrdersWidget(
            onCreateOrder: () {
              Navigator.pushNamed(context, AppRoutes.mergeOrders);
            },
          )
        else if (orders.length < 5)
          Column(
            children: [
              RecentOrdersWidget(orders: orders as List<Order>),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: AppColors.primaryBlue.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد طلبات حالياً',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ابدأ بإنشاء طلبك الأول',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.orderForm);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إنشاء طلب جديد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )
        else
          RecentOrdersWidget(orders: List<Order>.from(orders.take(5))),
      ],
    );
  }

  Widget _buildPerformanceCard(
    int totalOrders,
    int completedOrders,
    int readyOrders,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الأداء',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    icon: Icons.timer_outlined,
                    title: 'متوسط وقت الاستجابة',
                    value: '2.5 ساعة',
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceItem(
                    icon: Icons.thumb_up_outlined,
                    title: 'معدل الإنجاز',
                    value:
                        '${totalOrders > 0 ? ((completedOrders / totalOrders) * 100).toStringAsFixed(1) : '0'}%',
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    icon: Icons.group_outlined,
                    title: 'العملاء النشطين',
                    value: '$Customer.fromJson(json)',
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'طلبات التحميل',
                    value: readyOrders.toString(),
                    color: AppColors.warningOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownCard extends StatelessWidget {
  final OrderTimer timer;
  final VoidCallback? onTap;
  final bool isDesktop;

  const CountdownCard({
    super.key,
    required this.timer,
    this.onTap,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgentArrival =
        timer.remainingTimeToArrival <= const Duration(hours: 2, minutes: 30);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgentArrival
              ? Colors.orange.shade400
              : timer.countdownColor.withOpacity(0.3),
          width: isUrgentArrival ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: isDesktop
              ? const EdgeInsets.all(20)
              : const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with urgent badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${timer.orderNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 18 : 16,
                            color: isUrgentArrival
                                ? Colors.orange.shade800
                                : AppColors.darkGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isUrgentArrival) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'قريب من وقت الوصول',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    timer.countdownIcon,
                    color: isUrgentArrival
                        ? Colors.orange.shade600
                        : timer.countdownColor,
                    size: isDesktop ? 24 : 20,
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 12 : 8),

              // Supplier and Customer
              Text(
                timer.supplierName,
                style: TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: isDesktop ? 15 : 14,
                ),
              ),
              if (timer.customerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'للعميل: ${timer.customerName!}',
                  style: TextStyle(
                    color: AppColors.darkGray,
                    fontSize: isDesktop ? 14 : 13,
                  ),
                ),
              ],
              SizedBox(height: isDesktop ? 16 : 12),

              // Countdown Timers
              _buildCountdownRow(
                icon: Icons.flag_outlined,
                label: 'وقت الوصول',
                countdown: timer.formattedArrivalCountdown,
                color: isUrgentArrival ? Colors.orange : Colors.blue,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              _buildCountdownRow(
                icon: Icons.local_shipping_outlined,
                label: 'وقت التحميل',
                countdown: timer.formattedLoadingCountdown,
                color: timer.isApproachingLoading
                    ? Colors.orange
                    : Colors.green,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isDesktop ? 16 : 12),

              // Status Badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: timer.countdownColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: timer.countdownColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isDesktop ? 16 : 14,
                        color: timer.countdownColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timer.status,
                        style: TextStyle(
                          color: timer.countdownColor,
                          fontSize: isDesktop ? 13 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownRow({
    required IconData icon,
    required String label,
    required String countdown,
    required Color color,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Icon(icon, size: isDesktop ? 18 : 16, color: color),
        SizedBox(width: isDesktop ? 12 : 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.mediumGray,
              fontSize: isDesktop ? 15 : 13,
            ),
          ),
        ),
        Text(
          countdown,
          style: TextStyle(
            color: color,
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Countdown Section Widget
class CountdownSection extends StatefulWidget {
  final List<OrderTimer> timers;
  final VoidCallback onViewAll;
  final String title;

  const CountdownSection({
    super.key,
    required this.timers,
    required this.onViewAll,
    this.title = 'الطلبات القريبة من وقتها',
  });

  @override
  State<CountdownSection> createState() => _CountdownSectionState();
}

class _CountdownSectionState extends State<CountdownSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.timers.isEmpty) {
      return const SizedBox.shrink();
    }

    final approachingTimers = widget.timers
        .where(
          (timer) => timer.isApproachingArrival || timer.isApproachingLoading,
        )
        .toList();

    if (approachingTimers.isEmpty) {
      return const SizedBox.shrink();
    }

    final urgentTimers = approachingTimers.where((timer) {
      return timer.remainingTimeToArrival <=
          const Duration(hours: 2, minutes: 30);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.warningOrange,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAll,
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Urgent Countdown Banner (when less than 2.5 hours)
        if (urgentTimers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade50],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${urgentTimers.length} طلب سيصل خلال ساعتين ونصف',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: approachingTimers.take(4).map((timer) {
            return CountdownCard(
              timer: timer,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.orderDetails,
                  arguments: timer.orderId,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Empty Orders Widget
class EmptyOrdersWidget extends StatelessWidget {
  final VoidCallback? onCreateOrder;

  const EmptyOrdersWidget({super.key, this.onCreateOrder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.primaryBlue.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات حالياً',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإنشاء طلبك الأول',
            style: TextStyle(fontSize: 14, color: AppColors.lightGray),
            textAlign: TextAlign.center,
          ),
          if (onCreateOrder != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateOrder,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء طلب جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Order Timer Model Extension
class OrderTimer {
  final String orderId;
  final DateTime arrivalDateTime;
  final DateTime loadingDateTime;
  final String orderNumber;
  final String supplierName;
  final String? customerName;
  final String? driverName;
  final String status;

  OrderTimer({
    required this.orderId,
    required this.arrivalDateTime,
    required this.loadingDateTime,
    required this.orderNumber,
    required this.supplierName,
    this.customerName,
    this.driverName,
    required this.status,
  });

  Duration get remainingTimeToArrival {
    final now = DateTime.now();
    return arrivalDateTime.difference(now);
  }

  Duration get remainingTimeToLoading {
    final now = DateTime.now();
    return loadingDateTime.difference(now);
  }

  bool get shouldShowCountdown {
    return status != 'تم التنفيذ' && status != 'ملغى';
  }

  bool get isApproachingArrival {
    return remainingTimeToArrival <= const Duration(hours: 2, minutes: 30) &&
        remainingTimeToArrival > Duration.zero;
  }

  bool get isApproachingLoading {
    return remainingTimeToLoading <= const Duration(hours: 2, minutes: 30) &&
        remainingTimeToLoading > Duration.zero;
  }

  bool get isOverdue {
    return remainingTimeToLoading < Duration.zero;
  }

  String get formattedArrivalCountdown {
    if (!shouldShowCountdown || remainingTimeToArrival < Duration.zero) {
      return 'تأخر';
    }

    if (remainingTimeToArrival <= Duration.zero) {
      return 'حان وقت الوصول';
    }

    return _formatDuration(remainingTimeToArrival);
  }

  String get formattedLoadingCountdown {
    if (!shouldShowCountdown || remainingTimeToLoading < Duration.zero) {
      return 'تأخر';
    }

    if (remainingTimeToLoading <= Duration.zero) {
      return 'حان وقت التحميل';
    }

    return _formatDuration(remainingTimeToLoading);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;

    if (totalSeconds <= 0) {
      return '0 ثانية';
    }

    final days = totalSeconds ~/ (24 * 3600);
    final hours = (totalSeconds % (24 * 3600)) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (days > 0) parts.add('$days يوم');
    if (hours > 0 || days > 0) parts.add('$hours ساعة');
    if (minutes > 0 || hours > 0 || days > 0) parts.add('$minutes دقيقة');

    parts.add('$seconds ثانية'); // ✅ دايمًا تظهر

    return parts.join(' ');
  }

  Color get countdownColor {
    if (isOverdue) return AppColors.errorRed;
    if (isApproachingArrival || isApproachingLoading) {
      return Colors.orange;
    }
    return AppColors.successGreen;
  }

  IconData get countdownIcon {
    if (isOverdue) return Icons.warning;
    if (isApproachingArrival || isApproachingLoading) {
      return Icons.access_time_filled;
    }
    return Icons.check_circle_outline;
  }
}
