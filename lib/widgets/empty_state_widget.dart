import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? action;
  final String actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor = Colors.grey,
    this.action,
    this.actionText = 'إضافة جديد',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// أنواع محددة للـ Empty State
class EmptyOrdersWidget extends StatelessWidget {
  final VoidCallback? onCreateOrder;

  const EmptyOrdersWidget({super.key, this.onCreateOrder});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'لا توجد طلبات',
      message: 'لم تقم بإنشاء أي طلبات بعد. ابدأ بإنشاء طلبك الأول.',
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.primaryBlue,
      action: onCreateOrder,
      actionText: 'إنشاء طلب جديد',
    );
  }
}

class EmptyCustomersWidget extends StatelessWidget {
  final VoidCallback? onCreateCustomer;

  const EmptyCustomersWidget({super.key, this.onCreateCustomer});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'لا توجد عملاء',
      message: 'لم تقم بإضافة أي عملاء بعد. ابدأ بإضافة عميلك الأول.',
      icon: Icons.people_outline,
      iconColor: AppColors.secondaryTeal,
      action: onCreateCustomer,
      actionText: 'إضافة عميل جديد',
    );
  }
}

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'لا توجد إشعارات',
      message: 'ليس لديك أي إشعارات حالياً. ستظهر هنا عند وجود نشاط جديد.',
      icon: Icons.notifications_none,
      iconColor: AppColors.warningOrange,
    );
  }
}

class EmptyActivitiesWidget extends StatelessWidget {
  const EmptyActivitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'لا توجد حركات',
      message: 'لم يتم تسجيل أي حركات بعد. ستظهر هنا عند وجود نشاط على النظام.',
      icon: Icons.history_toggle_off,
      iconColor: AppColors.infoBlue,
    );
  }
}
