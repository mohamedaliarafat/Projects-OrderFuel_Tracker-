import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/utils/constants.dart';
import '../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showActions;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDelete,
    this.showActions = true,
  });

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.add_circle_outline;
      case 'order_assigned':
        return Icons.person_add_outlined;
      case 'order_overdue':
        return Icons.warning_outlined;
      case 'order_updated':
        return Icons.update_outlined;
      case 'system':
        return Icons.notifications_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return AppColors.successGreen;
      case 'order_assigned':
        return AppColors.infoBlue;
      case 'order_overdue':
        return AppColors.errorRed;
      case 'order_updated':
        return AppColors.warningOrange;
      case 'system':
        return AppColors.primaryBlue;
      default:
        return AppColors.mediumGray;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'order_created':
        return 'طلب جديد';
      case 'order_assigned':
        return 'تعيين طلب';
      case 'order_overdue':
        return 'طلب متأخر';
      case 'order_updated':
        return 'تحديث طلب';
      case 'system':
        return 'نظام';
      default:
        return 'إشعار';
    }
  }

  bool get isRead {
    final currentUserRecipient = notification.recipients.firstWhere(
      (r) =>
          r.userId ==
          _getCurrentUserId(), // تحتاج لدالة للحصول على ID المستخدم الحالي
      orElse: () => NotificationRecipient(userId: '', read: true),
    );
    return currentUserRecipient.read;
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primaryBlue.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppColors.primaryBlue.withOpacity(0.3)
              : AppColors.lightGray.withOpacity(0.3),
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Type and title
                    Row(
                      children: [
                        // Notification icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(
                              notification.type,
                            ).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            size: 20,
                            color: _getNotificationColor(notification.type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(
                                  notification.type,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getNotificationTypeText(notification.type),
                                style: TextStyle(
                                  color: _getNotificationColor(
                                    notification.type,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Title
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isUnread
                                    ? AppColors.darkGray
                                    : AppColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Time and actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Time
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: AppColors.lightGray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Unread indicator and actions
                        Row(
                          children: [
                            // Unread indicator
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),

                            // Delete button
                            if (showActions && onDelete != null)
                              IconButton(
                                onPressed: onDelete,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.errorRed.withOpacity(0.7),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'حذف الإشعار',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Message
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 40),
                  child: Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),

                // Data details (if any)
                if (notification.data != null && notification.data!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.lightGray.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...notification.data!.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ${_formatDataKey(entry.key)}: ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mediumGray,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _formatDataValue(entry.value),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkGray,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                // Footer with sender and date
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 40),
                  child: Row(
                    children: [
                      // Sender
                      if (notification.createdByName != null)
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.lightGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.createdByName!,
                              style: TextStyle(
                                color: AppColors.lightGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // Full date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.lightGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'yyyy/MM/dd',
                            ).format(notification.createdAt),
                            style: TextStyle(
                              color: AppColors.lightGray,
                              fontSize: 12,
                            ),
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
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  String _formatDataKey(String key) {
    final translations = {
      'orderId': 'رقم الطلب',
      'orderNumber': 'رقم الطلب',
      'supplierName': 'اسم المورد',
      'customerName': 'اسم العميل',
      'customerId': 'رقم العميل',
      'loadingDate': 'تاريخ التحميل',
      'createdAt': 'تاريخ الإنشاء',
    };

    return translations[key] ?? key;
  }

  String _formatDataValue(dynamic value) {
    if (value is DateTime) {
      return DateFormat('yyyy/MM/dd HH:mm').format(value);
    }
    return value.toString();
  }

  // دالة للحصول على ID المستخدم الحالي
  String _getCurrentUserId() {
    // TODO: يجب استبدال هذا بمزود المصادقة الفعلي
    return 'current_user_id';
  }
}

// Notification Badge للاستخدام في AppBar
class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  final bool showCount;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.onPressed,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'الإشعارات',
        ),
        if (count > 0 && showCount)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Notification List Tile للاستخدام في Drawer أو ListView
class NotificationListTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final bool showTimeAgo;

  const NotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.showTimeAgo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !_isRead();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getNotificationColor(notification.type).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _getNotificationIcon(notification.type),
            size: 20,
            color: _getNotificationColor(notification.type),
          ),
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if (showTimeAgo)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(notification.createdAt),
                style: TextStyle(color: AppColors.lightGray, fontSize: 10),
              ),
            ),
        ],
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  bool _isRead() {
    final currentUserRecipient = notification.recipients.firstWhere(
      (r) => r.userId == _getCurrentUserId(),
      orElse: () => NotificationRecipient(userId: '', read: true),
    );
    return currentUserRecipient.read;
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.add_circle_outline;
      case 'order_assigned':
        return Icons.person_add_outlined;
      case 'order_overdue':
        return Icons.warning_outlined;
      case 'order_updated':
        return Icons.update_outlined;
      case 'system':
        return Icons.notifications_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return AppColors.successGreen;
      case 'order_assigned':
        return AppColors.infoBlue;
      case 'order_overdue':
        return AppColors.errorRed;
      case 'order_updated':
        return AppColors.warningOrange;
      case 'system':
        return AppColors.primaryBlue;
      default:
        return AppColors.mediumGray;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} س';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  String _getCurrentUserId() {
    // TODO: يجب استبدال هذا بمزود المصادقة الفعلي
    return 'current_user_id';
  }
}
