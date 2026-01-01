import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1A2980);
  static const Color primaryDarkBlue = Color(0xFF0F1A5C);
  static const Color accentBlue = Color(0xFF4A6EE0);
  static const Color glassBlue = Color(0x664A6EE0);

  // Secondary Colors
  static const Color secondaryTeal = Color(0xFF26D0CE);
  static const Color lightTeal = Color(0xFF6DF5F4);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color pendingYellow = Color(0xFFFFC107);

  // Neutral Colors
  static const Color darkGray = Color(0xFF333333);
  static const Color mediumGray = Color(0xFF666666);
  static const Color lightGray = Color(0xFF999999);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primaryBlue, primaryDarkBlue],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentBlue, secondaryTeal],
  );
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryBlue,
    primaryColorDark: AppColors.primaryDarkBlue,
    primaryColorLight: AppColors.accentBlue,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.secondaryTeal,
      background: AppColors.backgroundGray,
      surface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundGray,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
      elevation: 4,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14),
      bodySmall: TextStyle(fontFamily: 'Cairo', fontSize: 12),
      labelLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(fontFamily: 'Cairo', fontSize: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.mediumGray),
      labelStyle: const TextStyle(color: AppColors.primaryBlue),
      errorStyle: const TextStyle(color: AppColors.errorRed),
    ),
    buttonTheme: const ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightGray,
      thickness: 1,
      space: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryBlue,
    primaryColorDark: AppColors.primaryDarkBlue,
    primaryColorLight: AppColors.accentBlue,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryBlue,
      secondary: AppColors.secondaryTeal,
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: AppColors.white,
      elevation: 4,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: AppColors.white,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        color: AppColors.white,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 10,
        color: AppColors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
      labelStyle: const TextStyle(color: AppColors.primaryBlue),
      errorStyle: const TextStyle(color: AppColors.errorRed),
    ),

    buttonTheme: const ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF404040),
      thickness: 1,
      space: 1,
    ),
  );
}

class AppStrings {
  static const String appName = 'نظام متابعة طلبات الوقود';
  static const String login = 'تسجيل الدخول';
  static const String register = 'تسجيل حساب جديد';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String name = 'الاسم الكامل';
  static const String suppliers = 'الموردين';
  static const String newSupplier = 'مورد جديد';
  static const String supplierDetails = 'تفاصيل المورد';
  static const String supplierType = 'نوع المورد';
  static const String contactPerson = 'جهة الاتصال';
  static const String company = 'الشركة';
  static const String phone = 'رقم الهاتف';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String dontHaveAccount = 'ليس لديك حساب؟';
  static const String alreadyHaveAccount = 'لديك حساب بالفعل؟';
  static const String loginNow = 'تسجيل الدخول الآن';
  static const String registerNow = 'إنشاء حساب جديد';
  static const String dashboard = 'لوحة التحكم';
  static const String orders = 'الطلبات';
  static const String newOrder = 'طلب جديد';
  static const String editOrder = 'تعديل طلب';
  static const String orderDetails = 'تفاصيل الطلب';
  static const String activities = 'الحركات';
  static const String reports = 'التقارير';
  static const String settings = 'الإعدادات';
  static const String profile = 'الملف الشخصي';
  static const String logout = 'تسجيل الخروج';
  static const String search = 'بحث...';
  static const String filter = 'تصفية';
  static const String clearFilter = 'مسح الفلاتر';
  static const String export = 'تصدير';
  static const String print = 'طباعة';
  static const String pdf = 'PDF';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String view = 'عرض';
  static const String add = 'إضافة';
  static const String update = 'تحديث';
  static const String create = 'إنشاء';
  static const String submit = 'إرسال';
  static const String back = 'رجوع';
  static const String next = 'التالي';
  static const String previous = 'السابق';
  static const String loading = 'جاري التحميل...';
  static const String noData = 'لا توجد بيانات';
  static const String error = 'حدث خطأ';
  static const String success = 'تم بنجاح';
  static const String warning = 'تحذير';
  static const String info = 'معلومة';
  static const String confirm = 'تأكيد';
  static const String areYouSure = 'هل أنت متأكد؟';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String ok = 'موافق';
  static const String close = 'إغلاق';
  static const String select = 'اختر';
  static const String date = 'التاريخ';
  static const String time = 'الوقت';
  static const String from = 'من';
  static const String to = 'إلى';
  static const String all = 'الكل';
  static const String status = 'الحالة';
  static const String type = 'النوع';
  static const String quantity = 'الكمية';
  static const String unit = 'الوحدة';
  static const String notes = 'ملاحظات';
  static const String attachment = 'مرفق';
  static const String attachments = 'المرفقات';
  static const String upload = 'رفع';
  static const String download = 'تحميل';
  static const String preview = 'معاينة';
  static const String deleteAttachment = 'حذف المرفق';
  static const String logo = 'الشعار';
  static const String uploadLogo = 'رفع شعار';
  static const String changeLogo = 'تغيير الشعار';
  static const String removeLogo = 'إزالة الشعار';
  static const String driver = 'السائق';
  static const String driverName = 'اسم السائق';
  static const String driverPhone = 'هاتف السائق';
  static const String vehicle = 'المركبة';
  static const String vehicleNumber = 'رقم المركبة';
  static const String fuelType = 'نوع الوقود';
  static const String orderNumber = 'رقم الطلب';
  static const String orderDate = 'تاريخ الطلب';
  static const String supplier = 'المورد';
  static const String supplierName = 'اسم المورد';
  static const String requestType = 'نوع الطلب';
  static const String loadingDate = 'تاريخ التحميل';
  static const String orderStatus = 'حالة الطلب';
  static const String createdBy = 'تم الإنشاء بواسطة';
  static const String createdAt = 'تاريخ الإنشاء';
  static const String updatedAt = 'تاريخ التحديث';
  static const String activityLog = 'سجل الحركات';
  static const String activityType = 'نوع الحركة';
  static const String activityDescription = 'وصف الحركة';
  static const String performedBy = 'تمت بواسطة';
  static const String performedAt = 'تاريخ التنفيذ';
  static const String changes = 'التغييرات';
  static const String exportToPdf = 'تصدير إلى PDF';
  static const String exportToExcel = 'تصدير إلى Excel';
  static const String printReport = 'طباعة التقرير';
  static const String totalOrders = 'إجمالي الطلبات';
  static const String pendingOrders = 'الطلبات المعلقة';
  static const String completedOrders = 'الطلبات المكتملة';
  static const String todayOrders = 'طلبات اليوم';
  static const String thisWeekOrders = 'طلبات هذا الأسبوع';
  static const String thisMonthOrders = 'طلبات هذا الشهر';
  static const String statistics = 'إحصائيات';
  static const String charts = 'الرسوم البيانية';
  static const String summary = 'ملخص';
  static const String details = 'تفاصيل';
  static const String actions = 'الإجراءات';
}

class ApiEndpoints {
  // static const String baseUrl = 'http://192.168.8.126:6030/api';
  static const String baseUrl = 'https://backend-ordertrack.onrender.com/api';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String orders = '/orders';
  static const String activities = '/activities';
  static const String suppliers = '/suppliers';
  static const String suppliersSearch = '/suppliers/search';
  static const String suppliersStatistics = '/suppliers/statistics';

  static String orderById(String id) => '/orders/$id';
  static String orderPdf(String id) => '/orders/$id/export/pdf';
  static String deleteAttachment(String orderId, String attachmentId) =>
      '/orders/$orderId/attachments/$attachmentId';

  static String supplierById(String id) => '/suppliers/$id';
  static String deleteSupplierDocument(String supplierId, String documentId) =>
      '/suppliers/$supplierId/documents/$documentId';
}

class AppIcons {
  static const String home = 'assets/icons/home.svg';
  static const String orders = 'assets/icons/orders.svg';
  static const String add = 'assets/icons/add.svg';
  static const String edit = 'assets/icons/edit.svg';
  static const String delete = 'assets/icons/delete.svg';
  static const String view = 'assets/icons/view.svg';
  static const String search = 'assets/icons/search.svg';
  static const String supplier = 'assets/icons/supplier.svg';
  static const String filter = 'assets/icons/filter.svg';
  static const String export = 'assets/icons/export.svg';
  static const String print = 'assets/icons/print.svg';
  static const String pdf = 'assets/icons/pdf.svg';
  static const String excel = 'assets/icons/excel.svg';
  static const String attachment = 'assets/icons/attachment.svg';
  static const String download = 'assets/icons/download.svg';
  static const String upload = 'assets/icons/upload.svg';
  static const String logo = 'assets/icons/logo.svg';
  static const String profile = 'assets/icons/profile.svg';
  static const String settings = 'assets/icons/settings.svg';
  static const String logout = 'assets/icons/logout.svg';
  static const String notification = 'assets/icons/notification.svg';
  static const String calendar = 'assets/icons/calendar.svg';
  static const String clock = 'assets/icons/clock.svg';
  static const String location = 'assets/icons/location.svg';
  static const String phone = 'assets/icons/phone.svg';
  static const String email = 'assets/icons/email.svg';
  static const String company = 'assets/icons/company.svg';
  static const String driver = 'assets/icons/driver.svg';
  static const String vehicle = 'assets/icons/vehicle.svg';
  static const String fuel = 'assets/icons/fuel.svg';
  static const String quantity = 'assets/icons/quantity.svg';
  static const String status = 'assets/icons/status.svg';
  static const String type = 'assets/icons/type.svg';
  static const String supplie = 'assets/icons/supplier.svg';
  static const String activity = 'assets/icons/activity.svg';
  static const String report = 'assets/icons/report.svg';
  static const String statistics = 'assets/icons/statistics.svg';
  static const String chart = 'assets/icons/chart.svg';
  static const String summary = 'assets/icons/summary.svg';
  static const String details = 'assets/icons/details.svg';
  static const String actions = 'assets/icons/actions.svg';
}

class AppImages {
  static const String logo = 'assets/images/logo.png';
  static const String splash = 'assets/images/splash.png';
  static const String loginBg = 'assets/images/login_bg.png';
  static const String noData = 'assets/images/no_data.png';
  static const String error = 'assets/images/error.png';
  static const String success = 'assets/images/success.png';
  static const String placeholder = 'assets/images/placeholder.png';
}
