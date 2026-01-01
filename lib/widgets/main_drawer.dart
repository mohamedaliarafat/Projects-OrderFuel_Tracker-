import 'package:flutter/material.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/notification_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.name
                            .split(' ')
                            .map((n) => n.isNotEmpty ? n[0] : '')
                            .take(2)
                            .join('')
                            .toUpperCase() ??
                        'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('لوحة التحكم'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/dashboard');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('الطلبات'),
                  trailing: Badge.count(
                    count: 0, // TODO: Add notification count
                    textColor: Colors.white,
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/orders');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('العملاء'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/customers');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('الموردين'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/suppliers');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car_outlined),
                  title: const Text('السائقين'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/drivers');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('طلب جديد'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/order/form');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('سجل الحركات'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/activities');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('الإشعارات'),
                  trailing: notificationProvider.unreadCount > 0
                      ? Badge.count(
                          count: notificationProvider.unreadCount,
                          textColor: Colors.white,
                          backgroundColor: AppColors.errorRed,
                        )
                      : null,
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/notifications');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('الملف الشخصي'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('الإعدادات'),
                  onTap: () {
                    Navigator.popAndPushNamed(context, '/settings');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('المساعدة'),
                  onTap: () {
                    // TODO: Help page
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('حول التطبيق'),
                  onTap: () {
                    // TODO: About page
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تسجيل الخروج'),
                        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await authProvider.logout();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('تسجيل الخروج'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
