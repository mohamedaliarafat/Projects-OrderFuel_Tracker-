import 'package:flutter/material.dart';
import 'package:order_tracker/models/notification_model.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1024;
        final bool isDesktop = width >= 1024;

        final double maxWidth = isDesktop ? 1000 : double.infinity;

        return Scaffold(
          appBar: AppBar(
            title: const Text('الإشعارات'),
            actions: [
              if (notificationProvider.unreadCount > 0)
                Badge(
                  label: Text(notificationProvider.unreadCount.toString()),
                  child: IconButton(
                    onPressed: () {
                      notificationProvider.markAllAsRead();
                    },
                    icon: const Icon(Icons.mark_email_read),
                    tooltip: 'تحديد الكل كمقروء',
                  ),
                ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  /// ===== Statistics =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.backgroundGray,
                    child: isMobile
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'إجمالي الإشعارات',
                                notificationProvider.notifications.length
                                    .toString(),
                                Icons.notifications,
                                AppColors.primaryBlue,
                              ),
                              _buildStatItem(
                                'غير مقروء',
                                notificationProvider.unreadCount.toString(),
                                Icons.markunread,
                                AppColors.warningOrange,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatItem(
                                'إجمالي الإشعارات',
                                notificationProvider.notifications.length
                                    .toString(),
                                Icons.notifications,
                                AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 48),
                              _buildStatItem(
                                'غير مقروء',
                                notificationProvider.unreadCount.toString(),
                                Icons.markunread,
                                AppColors.warningOrange,
                              ),
                            ],
                          ),
                  ),

                  /// ===== Notifications List =====
                  Expanded(
                    child: notificationProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : notificationProvider.notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد إشعارات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  notificationProvider.notifications.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final notification =
                                    notificationProvider.notifications[index];
                                return NotificationItem(
                                  notification: notification,
                                  onTap: () {
                                    _handleNotificationTap(notification);
                                  },
                                  onDelete: () {
                                    notificationProvider.deleteNotification(
                                      notification.id,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsRead(notification.id);

    if (notification.type == 'order_created' ||
        notification.type == 'order_assigned' ||
        notification.type == 'order_overdue') {
      final orderId = notification.data?['orderId'];
      if (orderId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.orderDetails,
          arguments: orderId,
        );
      }
    }
  }
}
