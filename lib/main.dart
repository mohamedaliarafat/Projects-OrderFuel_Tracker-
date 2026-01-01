import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/customer_provider.dart';
import 'package:order_tracker/providers/driver_provider.dart';
import 'package:order_tracker/providers/notification_provider.dart';
import 'package:order_tracker/providers/order_provider.dart';
import 'package:order_tracker/providers/supplier_provider.dart';
import 'package:order_tracker/providers/theme_provider.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // ⭐⭐⭐ أهم تعديل هنا ⭐⭐⭐
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),

        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'نظام متابعة طلبات الوقود',
      debugShowCheckedModeBanner: false,

      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,

      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,

      builder: (context, child) {
        return _AppWithNotifications(child: child!);
      },
    );
  }
}

// ================= Notifications Wrapper =================

class _AppWithNotifications extends StatefulWidget {
  final Widget child;
  const _AppWithNotifications({required this.child});

  @override
  State<_AppWithNotifications> createState() => _AppWithNotificationsState();
}

class _AppWithNotificationsState extends State<_AppWithNotifications> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (authProvider.isAuthenticated && authProvider.user != null) {
      notificationProvider.setCurrentUserId(authProvider.user!.id);
      notificationProvider.fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<AuthChangeNotification>(
      onNotification: (notification) {
        final authProvider = context.read<AuthProvider>();
        final notificationProvider = context.read<NotificationProvider>();

        if (notification.isLoggedIn && authProvider.user != null) {
          notificationProvider.setCurrentUserId(authProvider.user!.id);
          notificationProvider.fetchNotifications();
        } else {
          notificationProvider.setCurrentUserId('');
          notificationProvider.clearAllNotifications();
        }
        return true;
      },
      child: widget.child,
    );
  }
}

// ================= Auth Notification =================

class AuthChangeNotification extends Notification {
  final bool isLoggedIn;
  AuthChangeNotification(this.isLoggedIn);
}
