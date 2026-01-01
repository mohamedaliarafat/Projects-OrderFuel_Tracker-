import 'package:flutter/material.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/customer_model.dart';
import 'package:order_tracker/models/order_model.dart';

import 'package:order_tracker/screens/activities_screen.dart';
import 'package:order_tracker/screens/order/costomer_order/customer_form_screen.dart';
import 'package:order_tracker/screens/order/costomer_order/customer_order_form.dart';
import 'package:order_tracker/screens/order/costomer_order/customers_screen.dart';
import 'package:order_tracker/screens/dashboard_screen.dart';
import 'package:order_tracker/screens/driver_form_screen.dart';
import 'package:order_tracker/screens/drivers_screen.dart';
import 'package:order_tracker/screens/login_screen.dart';
import 'package:order_tracker/screens/notifications_screen.dart';
import 'package:order_tracker/screens/order/merge/merge_orders_screen.dart';
import 'package:order_tracker/screens/order/supplier_order/supplier_order_form_screen.dart';
import 'package:order_tracker/screens/order_details_screen.dart';
import 'package:order_tracker/screens/order_form_screen.dart';
import 'package:order_tracker/screens/orders_screen.dart';
import 'package:order_tracker/screens/profile_screen.dart';
import 'package:order_tracker/screens/register_screen.dart';
import 'package:order_tracker/screens/reports/customer_report_screen.dart';
import 'package:order_tracker/screens/reports/driver_report_screen.dart';
import 'package:order_tracker/screens/reports/invoice_report_screen.dart';
import 'package:order_tracker/screens/reports/reports_screen.dart';
import 'package:order_tracker/screens/reports/supplier_report_screen.dart';
import 'package:order_tracker/screens/reports/user_report_screen.dart';
import 'package:order_tracker/screens/settings_screen.dart';
import 'package:order_tracker/screens/splash_screen.dart';
import 'package:order_tracker/screens/suppliers_screen/supplier_details_screen.dart';
import 'package:order_tracker/screens/suppliers_screen/supplier_form_screen.dart';
import 'package:order_tracker/screens/suppliers_screen/suppliers_screen.dart';

class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Main
  static const dashboard = '/dashboard';

  // Orders
  static const orders = '/orders';
  static const orderForm = '/orders/form';
  static const orderDetails = '/orders/details';

  // Customers
  static const customerForm = '/customer/form';
  static const customers = '/customers';

  static const String driverForm = '/driver/form';
  static const String drivers = '/drivers';

  static const String reports = '/reports';
  static const String customerReport = '/reports/customers';
  static const String driverReport = '/reports/drivers';
  static const String supplierReport = '/reports/suppliers';
  static const String userReport = '/reports/users';
  static const String invoiceReport = '/reports/invoice';
  static const String advancedFilter = '/reports/filter';


  // Other
  static const activities = '/activities';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const String suppliers = '/suppliers';
  static const String supplierForm = '/supplier/form';
  static const String supplierOrderForm = '/supplier/order/form';
  static const String customerOrderForm = '/customer/order/form';
  static const String supplierDetails = '/supplier/details';
  static const String mergeOrders = '/merge-orders';

  /// Routes بدون arguments
  static final Map<String, Widget Function(BuildContext)> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    driverForm: (context) => const DriverFormScreen(),
    drivers: (context) => const DriversScreen(),
    mergeOrders: (context) => const MergeOrdersScreen(),

    dashboard: (_) => const DashboardScreen(),
    suppliers: (context) => const SuppliersScreen(),
    supplierForm: (context) => const SupplierFormScreen(),
    supplierOrderForm: (context) => const SupplierOrderFormScreen(),
    supplierDetails: (context) => const SupplierDetailsScreen(supplierId: ''),

    orders: (_) => const OrdersScreen(),
    customers: (_) => const CustomersScreen(),

    activities: (_) => const ActivitiesScreen(),
    profile: (_) => const ProfileScreen(),
    settings: (_) => const SettingsScreen(),
    notifications: (_) => const NotificationsScreen(),
    customerOrderForm: (_) => const CustomerOrderFormScreen(),

     reports: (_) => const ReportsScreen(),
    customerReport: (_) => const CustomerReportScreen(),
    driverReport: (_) => const DriverReportScreen(),
    supplierReport: (_) => const SupplierReportScreen(),
    userReport: (_) => const UserReportScreen(),
    invoiceReport: (_) => const InvoiceReportScreen(),
  };

  /// Routes اللي تعتمد على arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      /// ➕ إنشاء طلب / ✏️ تعديل طلب
      case orderForm:
        final Order? order = settings.arguments as Order?;
        return MaterialPageRoute(
          builder: (_) => OrderFormScreen(orderToEdit: order),
        );

      /// 📄 تفاصيل الطلب
      case orderDetails:
        final String orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        );

      /// ➕ إنشاء عميل / ✏️ تعديل عميل
      case customerForm:
        final Customer? customer = settings.arguments as Customer?;
        return MaterialPageRoute(
          builder: (_) => CustomerFormScreen(customerToEdit: customer),
        );

      default:
        return null;
    }
  }
}
