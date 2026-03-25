enum PermissionCategory { page, action, stats }

class PermissionDefinition {
  final String key;
  final String label;
  final PermissionCategory category;

  const PermissionDefinition({
    required this.key,
    required this.label,
    required this.category,
  });
}

class PermissionSection {
  final String title;
  final List<PermissionDefinition> permissions;

  const PermissionSection({required this.title, required this.permissions});
}

const List<PermissionDefinition> pagePermissions = [
  PermissionDefinition(
    key: 'orders_view',
    label: 'عرض الطلبات',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'orders_view_assigned_only',
    label: 'عرض الطلبات المعيّنة فقط',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'customers_view',
    label: 'عرض العملاء',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'drivers_view',
    label: 'عرض السائقين',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'suppliers_view',
    label: 'عرض الموردين',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'reports_view',
    label: 'عرض التقارير',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'settings_access',
    label: 'الدخول إلى الإعدادات',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'tracking_view',
    label: 'عرض المتابعة',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'inventory_view',
    label: 'عرض المخزون',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'activities_view',
    label: 'عرض الأنشطة',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'tasks_view',
    label: 'عرض المهام الخاصة بالمستخدم',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'tasks_view_all',
    label: 'عرض جميع المهام',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'station_maintenance_view',
    label: 'عرض صيانة المحطات',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'maintenance_periodic_view',
    label: 'عرض الصيانة الدورية',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'fuel_sales_view',
    label: 'عرض مبيعات المحطات',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'marketing_stations_view',
    label: 'عرض تسويق المحطات',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'qualification_view',
    label: 'عرض مواقع المحطات',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'hr_view',
    label: 'عرض الموارد البشرية',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'contracts_view',
    label: 'عرض العقود',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'archive_view',
    label: 'عرض الأرشفة',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'custody_documents_view',
    label: 'عرض سندات العهدة',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'users_view',
    label: 'عرض المستخدمين',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'blocked_devices_view',
    label: 'عرض الأجهزة المحظورة',
    category: PermissionCategory.page,
  ),
  PermissionDefinition(
    key: 'auth_devices_view',
    label: 'عرض إدارة الأجهزة',
    category: PermissionCategory.page,
  ),
];

const List<PermissionDefinition> actionPermissions = [
  PermissionDefinition(
    key: 'orders_create_customer',
    label: 'إضافة طلب عميل',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'orders_create_supplier',
    label: 'إضافة طلب مورد',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'orders_merge',
    label: 'دمج الطلبات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'orders_edit',
    label: 'تعديل الطلبات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'orders_delete',
    label: 'حذف الطلبات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'orders_manage',
    label: 'إدارة كاملة للطلبات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'customers_create',
    label: 'إضافة العملاء',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'customers_edit',
    label: 'تعديل العملاء',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'customers_delete',
    label: 'حذف العملاء',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'customers_manage',
    label: 'إدارة كاملة للعملاء',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'drivers_create',
    label: 'إضافة السائقين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'drivers_edit',
    label: 'تعديل السائقين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'drivers_delete',
    label: 'حذف السائقين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'drivers_manage',
    label: 'إدارة كاملة للسائقين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'suppliers_create',
    label: 'إضافة الموردين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'suppliers_edit',
    label: 'تعديل الموردين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'suppliers_delete',
    label: 'حذف الموردين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'suppliers_manage',
    label: 'إدارة كاملة للموردين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'users_create',
    label: 'إنشاء مستخدمين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'users_edit',
    label: 'تعديل المستخدمين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'users_delete',
    label: 'حذف المستخدمين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'users_block',
    label: 'حظر وفك حظر المستخدمين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'users_manage',
    label: 'إدارة كاملة للمستخدمين',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'tasks_create',
    label: 'إنشاء المهام',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'tasks_edit',
    label: 'تعديل المهام',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'tasks_approve',
    label: 'اعتماد ورفض المهام',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'tasks_extend',
    label: 'تمديد المهام',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'tasks_penalty',
    label: 'تطبيق خصم على المهام',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'tasks_manage_participants',
    label: 'إدارة المشاركين في المهام',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'inventory_manage',
    label: 'إدارة المخزون',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'station_maintenance_manage',
    label: 'إدارة صيانة المحطات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'maintenance_periodic_manage',
    label: 'إدارة الصيانة الدورية',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'fuel_sales_manage',
    label: 'إدارة مبيعات المحطات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'marketing_stations_manage',
    label: 'إدارة تسويق المحطات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'qualification_manage',
    label: 'إدارة مواقع المحطات',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'hr_manage',
    label: 'إدارة الموارد البشرية',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'contracts_manage',
    label: 'إدارة العقود',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'archive_manage',
    label: 'إدارة الأرشفة',
    category: PermissionCategory.action,
  ),
  PermissionDefinition(
    key: 'custody_documents_manage',
    label: 'إدارة سندات العهدة',
    category: PermissionCategory.action,
  ),
];

const List<PermissionDefinition> statsPermissions = [
  PermissionDefinition(
    key: 'stats_total_orders',
    label: 'عرض إجمالي الطلبات',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_supplier_pending',
    label: 'عرض طلبات المورد في الانتظار',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_supplier_merged',
    label: 'عرض طلبات المورد المدمجة',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_customer_waiting',
    label: 'عرض طلبات العميل في الانتظار',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_customer_assigned',
    label: 'عرض الطلبات المخصصة للعملاء',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_merged_orders',
    label: 'عرض الطلبات المدمجة',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_completed_orders',
    label: 'عرض الطلبات المكتملة',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_today_orders',
    label: 'عرض طلبات اليوم',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_week_orders',
    label: 'عرض طلبات الأسبوع',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_month_orders',
    label: 'عرض طلبات الشهر',
    category: PermissionCategory.stats,
  ),
  PermissionDefinition(
    key: 'stats_cancelled_orders',
    label: 'عرض الطلبات المرفوضة',
    category: PermissionCategory.stats,
  ),
];

const List<PermissionSection> permissionSections = [
  PermissionSection(title: 'صلاحيات الصفحات', permissions: pagePermissions),
  PermissionSection(title: 'صلاحيات الإجراءات', permissions: actionPermissions),
  PermissionSection(title: 'صلاحيات الإحصائيات', permissions: statsPermissions),
];

const List<PermissionDefinition> permissionDefinitions = [
  ...pagePermissions,
  ...actionPermissions,
  ...statsPermissions,
];

final Map<String, PermissionDefinition> _permissionLookup = Map.fromEntries(
  permissionDefinitions.map(
    (permission) => MapEntry(permission.key, permission),
  ),
);

String permissionLabel(String key) => _permissionLookup[key]?.label ?? key;

const List<String> permissionKeys = [
  'orders_view',
  'orders_view_assigned_only',
  'customers_view',
  'drivers_view',
  'suppliers_view',
  'reports_view',
  'settings_access',
  'tracking_view',
  'inventory_view',
  'activities_view',
  'tasks_view',
  'tasks_view_all',
  'station_maintenance_view',
  'maintenance_periodic_view',
  'fuel_sales_view',
  'marketing_stations_view',
  'qualification_view',
  'hr_view',
  'contracts_view',
  'archive_view',
  'custody_documents_view',
  'users_view',
  'blocked_devices_view',
  'auth_devices_view',
  'orders_create_customer',
  'orders_create_supplier',
  'orders_merge',
  'orders_edit',
  'orders_delete',
  'orders_manage',
  'customers_create',
  'customers_edit',
  'customers_delete',
  'customers_manage',
  'drivers_create',
  'drivers_edit',
  'drivers_delete',
  'drivers_manage',
  'suppliers_create',
  'suppliers_edit',
  'suppliers_delete',
  'suppliers_manage',
  'users_create',
  'users_edit',
  'users_delete',
  'users_block',
  'users_manage',
  'tasks_create',
  'tasks_edit',
  'tasks_approve',
  'tasks_extend',
  'tasks_penalty',
  'tasks_manage_participants',
  'inventory_manage',
  'station_maintenance_manage',
  'maintenance_periodic_manage',
  'fuel_sales_manage',
  'marketing_stations_manage',
  'qualification_manage',
  'hr_manage',
  'contracts_manage',
  'archive_manage',
  'custody_documents_manage',
  'stats_total_orders',
  'stats_supplier_pending',
  'stats_supplier_merged',
  'stats_customer_waiting',
  'stats_customer_assigned',
  'stats_merged_orders',
  'stats_completed_orders',
  'stats_today_orders',
  'stats_week_orders',
  'stats_month_orders',
  'stats_cancelled_orders',
];
