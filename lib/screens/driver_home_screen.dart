import 'dart:async';

import 'package:flutter/material.dart';
import 'package:order_tracker/localization/app_localizations.dart' as loc;
import 'package:order_tracker/models/notification_model.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/language_provider.dart';
import 'package:order_tracker/providers/notification_provider.dart';
import 'package:order_tracker/providers/order_provider.dart';
import 'package:order_tracker/screens/tracking/driver_delivery_tracking_screen.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/driver_background_location_permission.dart';
import 'package:order_tracker/widgets/app_soft_background.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
import 'package:order_tracker/widgets/notification_item.dart';
import 'package:order_tracker/widgets/tracking/tracking_page_shell.dart';
import 'package:provider/provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const List<loc.AppLanguage> _driverLanguageOptions = [
    loc.AppLanguage.english,
    loc.AppLanguage.arabic,
    loc.AppLanguage.hindi,
    loc.AppLanguage.bengali,
    loc.AppLanguage.filipino,
    loc.AppLanguage.urdu,
    loc.AppLanguage.pashto,
  ];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshAll();
      await _requestBackgroundLocationIfNeeded();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _refreshAll(silent: true),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll({bool silent = false}) async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final notifications = context.read<NotificationProvider>();
    if (auth.user != null) {
      notifications.setCurrentUserId(auth.user!.id);
    }
    await Future.wait([
      context.read<OrderProvider>().fetchOrders(silent: silent),
      notifications.fetchNotifications(),
    ]);
  }

  Future<void> _requestBackgroundLocationIfNeeded() async {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await DriverBackgroundLocationPermission.maybePromptOnFirstLaunch(
      context,
      userId: user.id,
      isDriver: user.role == 'driver',
    );
  }

  bool _isLoadingStationStage(Order order) {
    const delivered = <String>{
      'تم التحميل',
      'في الطريق',
      'تم التسليم',
      'تم التنفيذ',
      'مكتمل',
      'ملغى',
    };
    return !delivered.contains(order.status.trim());
  }

  String _destinationText(Order order) {
    if (_isLoadingStationStage(order)) {
      if (order.supplierAddress?.trim().isNotEmpty == true) {
        return order.supplierAddress!.trim();
      }
      if (order.loadingStationName?.trim().isNotEmpty == true) {
        return order.loadingStationName!.trim();
      }
      if (order.supplierName.trim().isNotEmpty) {
        return order.supplierName.trim();
      }
      return context.tr(loc.AppStrings.driverLoadingStationDefault);
    }
    if (order.address?.trim().isNotEmpty == true) return order.address!.trim();
    if (order.customerAddress?.trim().isNotEmpty == true) {
      return order.customerAddress!.trim();
    }
    final parts = <String>[
      if (order.city?.trim().isNotEmpty == true) order.city!.trim(),
      if (order.area?.trim().isNotEmpty == true) order.area!.trim(),
    ];
    return parts.isEmpty
        ? context.tr(loc.AppStrings.driverCurrentClientFallback)
        : parts.join(' - ');
  }

  String _stageLabel(Order order) {
    return _isLoadingStationStage(order)
        ? context.tr(loc.AppStrings.driverHeadingToLoadingStation)
        : context.tr(loc.AppStrings.driverHeadingToCustomer);
  }

  Future<void> _openOrder(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverDeliveryTrackingScreen(initialOrder: order),
      ),
    );
    if (!mounted) return;
    await _refreshAll(silent: true);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(loc.AppStrings.driverLogoutConfirmTitle)),
        content: Text(context.tr(loc.AppStrings.driverLogoutConfirmMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr(loc.AppStrings.cancelAction)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr(loc.AppStrings.logout)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.front,
      (route) => false,
    );
  }

  void _showLanguageSelector() {
    final languageProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  context.tr(loc.AppStrings.languageDialogTitle),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ..._driverLanguageOptions.map((language) {
                final isSelected = languageProvider.language == language;
                return ListTile(
                  leading: isSelected ? const Icon(Icons.check) : null,
                  title: Text(language.nativeName),
                  onTap: () {
                    languageProvider.setLanguage(language);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _localizedStatus(String status) {
    switch (status.trim()) {
      case 'تم التحميل':
        return context.tr(loc.AppStrings.driverStatusLoaded);
      case 'في الطريق':
        return context.tr(loc.AppStrings.driverStatusOnWay);
      case 'تم التسليم':
        return context.tr(loc.AppStrings.driverStatusDelivered);
      case 'تم التنفيذ':
        return context.tr(loc.AppStrings.driverStatusExecuted);
      case 'مكتمل':
        return context.tr(loc.AppStrings.driverStatusCompleted);
      case 'ملغى':
        return context.tr(loc.AppStrings.driverStatusCanceled);
      default:
        return status;
    }
  }

  String _localizedFuelType(String? fuelType) {
    final value = fuelType?.trim();
    if (value == null || value.isEmpty) {
      return context.tr(loc.AppStrings.driverUnknownFuel);
    }

    switch (value) {
      case 'بنزين 91':
        return context.tr(loc.AppStrings.filterFuelType91);
      case 'بنزين 95':
        return context.tr(loc.AppStrings.filterFuelType95);
      case 'ديزل':
        return context.tr(loc.AppStrings.filterFuelTypeDiesel);
      case 'غاز':
        return context.tr(loc.AppStrings.filterFuelTypeGas);
      default:
        return value;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    final provider = context.read<NotificationProvider>();
    provider.markAsRead(notification.id);
    final orderId = _extractOrderId(notification);
    if (orderId != null && orderId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDeliveryTrackingScreen(orderId: orderId),
        ),
      );
    }
  }

  String? _extractOrderId(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return null;
    final direct = _extractEntityId(data['orderId'] ?? data['order_id']);
    if (direct != null) return direct;
    final order = data['order'];
    if (order is Map) {
      return _extractEntityId(order['id'] ?? order['_id']);
    }
    return null;
  }

  String? _extractEntityId(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }
    if (raw is Map) {
      final map = raw.cast<dynamic, dynamic>();
      final nested =
          map['_id'] ?? map['id'] ?? map[r'$oid'] ?? map['oid'] ?? map['value'];
      if (nested != null) {
        final value = nested.toString().trim();
        return value.isEmpty ? null : value;
      }
    }
    final fallback = raw.toString().trim();
    return fallback.isEmpty ? null : fallback;
  }

  Color _statusColor(String status) {
    switch (status.trim()) {
      case 'تم التحميل':
      case 'في الطريق':
        return AppColors.primaryBlue;
      case 'تم التسليم':
      case 'تم التنفيذ':
      case 'مكتمل':
        return AppColors.successGreen;
      case 'ملغى':
        return AppColors.errorRed;
      default:
        return AppColors.statusGold;
    }
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}/${_two(local.month)}/${_two(local.day)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatQuantity(Order order) {
    if (order.quantity == null) {
      return context.tr(loc.AppStrings.driverNotSpecified);
    }
    final quantity = order.quantity!;
    final decimals = quantity % 1 == 0 ? 0 : 2;
    return '${quantity.toStringAsFixed(decimals)} '
        '${order.unit ?? context.tr(loc.AppStrings.driverLitersUnit)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name.trim().isNotEmpty == true
        ? auth.user!.name.trim()
        : context.tr(loc.AppStrings.driverUserFallback);

    return DefaultTabController(
      length: 2,
      child: Consumer2<OrderProvider, NotificationProvider>(
        builder: (context, orderProvider, notificationProvider, _) {
          final orders = orderProvider.orders;
          final unreadCount = notificationProvider.unreadCount;
          final loadingCount = orders.where(_isLoadingStationStage).length;
          final deliveringCount = orders
              .where(
                (o) =>
                    const {'تم التحميل', 'في الطريق'}.contains(o.status.trim()),
              )
              .length;
          final completedCount = orders
              .where(
                (o) => const {
                  'تم التسليم',
                  'تم التنفيذ',
                  'مكتمل',
                }.contains(o.status.trim()),
              )
              .length;

          return Scaffold(
            appBar: _buildAppBar(unreadCount),
            body: Stack(
              children: [
                const AppSoftBackground(),
                Positioned.fill(
                  child: TabBarView(
                    children: [
                      _buildOrdersTab(
                        userName: userName,
                        orders: orders,
                        unreadCount: unreadCount,
                        loadingCount: loadingCount,
                        deliveringCount: deliveringCount,
                        completedCount: completedCount,
                        orderProvider: orderProvider,
                      ),
                      _buildNotificationsTab(
                        userName: userName,
                        ordersCount: orders.length,
                        unreadCount: unreadCount,
                        loadingCount: loadingCount,
                        deliveringCount: deliveringCount,
                        completedCount: completedCount,
                        notificationProvider: notificationProvider,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int unreadCount) {
    return AppBar(
      leading: IconButton(
        tooltip: context.tr(loc.AppStrings.logoutTooltip),
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(context.tr(loc.AppStrings.driverDashboardTitle)),
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
          tooltip: context.tr(loc.AppStrings.languageTooltip),
          onPressed: _showLanguageSelector,
          icon: const Icon(Icons.language_rounded),
        ),
        IconButton(
          tooltip: context.tr(loc.AppStrings.refreshTooltip),
          onPressed: () => _refreshAll(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x66FFFFFF), Color(0x33FFFFFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.70),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: context.tr(loc.AppStrings.driverTabOrders)),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.tr(loc.AppStrings.driverTabNotifications)),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab({
    required String userName,
    required List<Order> orders,
    required int unreadCount,
    required int loadingCount,
    required int deliveringCount,
    required int completedCount,
    required OrderProvider orderProvider,
  }) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: _buildScrollableContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(
              userName: userName,
              ordersCount: orders.length,
              unreadCount: unreadCount,
              loadingCount: loadingCount,
              deliveringCount: deliveringCount,
              completedCount: completedCount,
              isOrdersTab: true,
            ),
            const SizedBox(height: 16),
            _DriverSectionCard(
              title: context.tr(loc.AppStrings.driverAssignedOrdersTitle),
              subtitle: context.tr(
                loc.AppStrings.driverAssignedOrdersSubtitle,
              ),
              badge: TrackingStatusBadge(
                label: context.tr(
                  loc.AppStrings.driverOrdersCount,
                  {'count': '${orders.length}'},
                ),
                color: AppColors.primaryBlue,
                icon: Icons.assignment_outlined,
              ),
              child: _buildOrdersSectionContent(orderProvider, orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab({
    required String userName,
    required int ordersCount,
    required int unreadCount,
    required int loadingCount,
    required int deliveringCount,
    required int completedCount,
    required NotificationProvider notificationProvider,
  }) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: _buildScrollableContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(
              userName: userName,
              ordersCount: ordersCount,
              unreadCount: unreadCount,
              loadingCount: loadingCount,
              deliveringCount: deliveringCount,
              completedCount: completedCount,
              isOrdersTab: false,
            ),
            const SizedBox(height: 16),
            _DriverSectionCard(
              title: context.tr(loc.AppStrings.driverNotificationsTitle),
              subtitle: context.tr(
                loc.AppStrings.driverNotificationsSubtitle,
              ),
              badge: TrackingStatusBadge(
                label: context.tr(
                  loc.AppStrings.driverUnreadCount,
                  {'count': '$unreadCount'},
                ),
                color: AppColors.errorRed,
                icon: Icons.notifications_active_outlined,
              ),
              action: unreadCount > 0
                  ? FilledButton.tonalIcon(
                      onPressed: notificationProvider.markAllAsRead,
                      icon: const Icon(Icons.done_all_rounded),
                      label: Text(context.tr(loc.AppStrings.driverMarkAllRead)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue.withValues(
                          alpha: 0.10,
                        ),
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  : null,
              child: _buildNotificationsSectionContent(notificationProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 760;
        final horizontalPadding = isDesktop ? 28.0 : (isTablet ? 20.0 : 16.0);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isDesktop ? 22 : 18,
            horizontalPadding,
            96,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required String userName,
    required int ordersCount,
    required int unreadCount,
    required int loadingCount,
    required int deliveringCount,
    required int completedCount,
    required bool isOrdersTab,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final chips = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  TrackingStatusBadge(
                    label: isOrdersTab
                        ? context.tr(loc.AppStrings.driverAutoRefreshChip)
                        : context.tr(loc.AppStrings.driverNotificationLiveChip),
                    color: AppColors.secondaryTeal,
                    icon: isOrdersTab
                        ? Icons.schedule_rounded
                        : Icons.notifications_active_outlined,
                  ),
                  TrackingStatusBadge(
                    label: context.tr(
                      loc.AppStrings.driverUnreadCount,
                      {'count': '$unreadCount'},
                    ),
                    color: AppColors.errorRed,
                    icon: Icons.mark_email_unread_outlined,
                  ),
                ],
              );

              final content = _buildWelcomeContent(userName, isOrdersTab);
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 16),
                    chips,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [content, const SizedBox(height: 16), chips],
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1240 ? 4 : (width >= 760 ? 2 : 1);
              final cardWidth = columns == 1
                  ? width
                  : (width - ((columns - 1) * 12)) / columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _DriverStatCard(
                      label: context.tr(loc.AppStrings.driverCurrentOrdersLabel),
                      value: '$ordersCount',
                      icon: Icons.assignment_outlined,
                      color: AppColors.primaryBlue,
                      helper: context.tr(
                        loc.AppStrings.driverCurrentOrdersHelper,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DriverStatCard(
                      label: context.tr(loc.AppStrings.driverWaitingLoadLabel),
                      value: '$loadingCount',
                      icon: Icons.local_gas_station_outlined,
                      color: AppColors.statusGold,
                      helper: context.tr(
                        loc.AppStrings.driverWaitingLoadHelper,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DriverStatCard(
                      label: context.tr(loc.AppStrings.driverDeliveringLabel),
                      value: '$deliveringCount',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.secondaryTeal,
                      helper: context.tr(
                        loc.AppStrings.driverDeliveringHelper,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DriverStatCard(
                      label: context.tr(loc.AppStrings.driverCompletedLabel),
                      value: '$completedCount',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.successGreen,
                      helper: context.tr(
                        loc.AppStrings.driverCompletedHelper,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(String userName, bool isOrdersTab) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
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
                color: AppColors.primaryBlue.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.drive_eta_rounded, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  loc.AppStrings.driverWelcomeTemplate,
                  {'name': userName},
                ),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOrdersTab
                    ? context.tr(loc.AppStrings.driverWelcomeOrdersSubtitle)
                    : context.tr(
                        loc.AppStrings.driverWelcomeNotificationsSubtitle,
                      ),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSectionContent(
    OrderProvider orderProvider,
    List<Order> orders,
  ) {
    if (orderProvider.isLoading && orders.isEmpty) {
      return TrackingStateCard(
        icon: Icons.sync_rounded,
        title: context.tr(loc.AppStrings.driverLoadingOrdersTitle),
        message: context.tr(loc.AppStrings.driverLoadingOrdersMessage),
        color: AppColors.infoBlue,
        action: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    }

    if (orderProvider.error != null && orders.isEmpty) {
      return TrackingStateCard(
        icon: Icons.error_outline_rounded,
        title: context.tr(loc.AppStrings.driverLoadOrdersErrorTitle),
        message:
            orderProvider.error ??
            context.tr(loc.AppStrings.driverLoadingOrdersMessage),
        color: AppColors.errorRed,
        action: FilledButton.icon(
          onPressed: _refreshAll,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.tr(loc.AppStrings.driverRetry)),
        ),
      );
    }

    if (orders.isEmpty) {
      return TrackingStateCard(
        icon: Icons.assignment_outlined,
        title: context.tr(loc.AppStrings.driverNoOrdersTitle),
        message: context.tr(loc.AppStrings.driverNoOrdersMessage),
        color: AppColors.primaryBlue,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1320 ? 2 : 1;
        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: orders
              .map(
                (order) =>
                    SizedBox(width: cardWidth, child: _buildOrderCard(order)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final color = _statusColor(order.status);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      color: Colors.white.withValues(alpha: 0.82),
      border: Border.all(color: color.withValues(alpha: 0.16)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.route_rounded, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        loc.AppStrings.driverOrderNumberTemplate,
                        {'number': '${order.orderNumber}'},
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stageLabel(order),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TrackingStatusBadge(
                label: _localizedStatus(order.status),
                color: color,
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.local_gas_station_outlined,
                label: _localizedFuelType(order.fuelType),
                color: AppColors.statusGold,
              ),
              _InfoChip(
                icon: Icons.scale_outlined,
                label: _formatQuantity(order),
                color: AppColors.infoBlue,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DriverOrderInfoRow(
            label: context.tr(loc.AppStrings.driverCurrentDestinationLabel),
            value: _destinationText(order),
          ),
          _DriverOrderInfoRow(
            label: context.tr(loc.AppStrings.driverArrivalTimeLabel),
            value: '${_formatDate(order.arrivalDate)} • ${order.arrivalTime}',
          ),
          _DriverOrderInfoRow(
            label: context.tr(loc.AppStrings.driverLoadingTimeLabel),
            value: '${_formatDate(order.loadingDate)} • ${order.loadingTime}',
          ),
          if (order.actualLoadedLiters != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(loc.AppStrings.driverActualLoadingDataTitle),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${order.actualLoadedLiters!.toStringAsFixed(order.actualLoadedLiters! % 1 == 0 ? 0 : 2)} '
                    '${context.tr(loc.AppStrings.driverLitersUnit)} • '
                    '${_localizedFuelType(order.actualFuelType)}',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openOrder(order),
              icon: const Icon(Icons.navigation_outlined),
              label: Text(context.tr(loc.AppStrings.driverOpenExecutionPage)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSectionContent(
    NotificationProvider notificationProvider,
  ) {
    if (notificationProvider.isLoading &&
        notificationProvider.notifications.isEmpty) {
      return TrackingStateCard(
        icon: Icons.notifications_active_outlined,
        title: context.tr(loc.AppStrings.driverLoadingNotificationsTitle),
        message: context.tr(loc.AppStrings.driverLoadingNotificationsMessage),
        color: AppColors.infoBlue,
        action: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    }

    if (notificationProvider.error != null &&
        notificationProvider.notifications.isEmpty) {
      return TrackingStateCard(
        icon: Icons.error_outline_rounded,
        title: context.tr(loc.AppStrings.driverLoadNotificationsErrorTitle),
        message:
            notificationProvider.error ??
            context.tr(loc.AppStrings.driverLoadingNotificationsMessage),
        color: AppColors.errorRed,
        action: FilledButton.icon(
          onPressed: _refreshAll,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.tr(loc.AppStrings.driverRetry)),
        ),
      );
    }

    if (notificationProvider.notifications.isEmpty) {
      return TrackingStateCard(
        icon: Icons.notifications_none,
        title: context.tr(loc.AppStrings.driverNoNotificationsTitle),
        message: context.tr(loc.AppStrings.driverNoNotificationsMessage),
        color: AppColors.primaryBlue,
      );
    }

    return Column(
      children: notificationProvider.notifications
          .map(
            (notification) => NotificationItem(
              notification: notification,
              currentUserId: notificationProvider.getCurrentUserId(),
              onTap: () => _handleNotificationTap(notification),
              onDelete: () =>
                  notificationProvider.deleteNotification(notification.id),
            ),
          )
          .toList(),
    );
  }
}

class _DriverSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? badge;
  final Widget? action;

  const _DriverSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final header = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );

              final trailing = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (badge != null) badge!,
                  if (action != null) action!,
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, const SizedBox(width: 12), trailing],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 14), trailing],
              );
            },
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DriverStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String helper;

  const _DriverStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.72),
      border: Border.all(color: color.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverOrderInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DriverOrderInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
