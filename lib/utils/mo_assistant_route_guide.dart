import 'package:order_tracker/models/mo_assistant_route_context.dart';
import 'package:order_tracker/utils/app_routes.dart';

const Map<String, MoAssistantRouteContext>
_routeGuide = <String, MoAssistantRouteContext>{
  AppRoutes.dashboard: MoAssistantRouteContext(
    route: AppRoutes.dashboard,
    title: 'لوحة التحكم',
    section: 'المتابعة العامة',
    summary:
        'تعرض ملخصًا سريعًا للحالة العامة للنظام مثل الإحصائيات والتنبيهات وأهم المؤشرات.',
    availableActions: <String>[
      'مراجعة الإحصائيات الرئيسية',
      'فتح الطلبات أو المهام أو الإشعارات',
      'متابعة الحالات المتأخرة',
    ],
    keywords: <String>['لوحة التحكم', 'dashboard', 'إحصائيات', 'ملخص'],
  ),
  AppRoutes.orders: MoAssistantRouteContext(
    route: AppRoutes.orders,
    title: 'الطلبات',
    section: 'إدارة الطلبات',
    summary:
        'هذه الشاشة مخصصة لعرض الطلبات والبحث فيها ومتابعة حالتها وفتح التفاصيل.',
    availableActions: <String>[
      'البحث عن طلب',
      'فتح تفاصيل الطلب',
      'متابعة الحالة الحالية',
      'إنشاء طلب جديد إذا كانت الصلاحية متاحة',
    ],
    keywords: <String>['طلبات', 'order', 'tracking', 'حالة الطلب'],
  ),
  AppRoutes.orderDetails: MoAssistantRouteContext(
    route: AppRoutes.orderDetails,
    title: 'تفاصيل الطلب',
    section: 'إدارة الطلبات',
    summary:
        'تعرض كل بيانات الطلب المحدد مثل الحالة والمرفقات والأنشطة والتحديثات المرتبطة به.',
    availableActions: <String>[
      'قراءة حالة الطلب',
      'مراجعة الأنشطة',
      'مراجعة المرفقات',
      'متابعة التعديلات على الطلب',
    ],
    keywords: <String>['تفاصيل الطلب', 'order details', 'مرفقات', 'أنشطة'],
  ),
  AppRoutes.customers: MoAssistantRouteContext(
    route: AppRoutes.customers,
    title: 'العملاء',
    section: 'إدارة العملاء',
    summary:
        'تعرض قائمة العملاء مع إمكانية البحث وفتح التفاصيل أو إضافة عميل جديد حسب الصلاحية.',
    availableActions: <String>[
      'البحث عن عميل',
      'فتح بيانات العميل',
      'إضافة عميل جديد',
    ],
    keywords: <String>['العملاء', 'customer', 'عميل'],
  ),
  AppRoutes.suppliers: MoAssistantRouteContext(
    route: AppRoutes.suppliers,
    title: 'الموردون',
    section: 'إدارة الموردين',
    summary:
        'هذه الشاشة لإدارة الموردين والبحث عنهم ومراجعة بياناتهم وفتح التفاصيل أو التعديل حسب الصلاحية.',
    availableActions: <String>[
      'البحث عن مورد',
      'فتح تفاصيل المورد',
      'إضافة مورد جديد',
    ],
    keywords: <String>['الموردين', 'suppliers', 'مورد'],
  ),
  AppRoutes.drivers: MoAssistantRouteContext(
    route: AppRoutes.drivers,
    title: 'السائقون',
    section: 'إدارة السائقين',
    summary:
        'تعرض بيانات السائقين مع البحث والإضافة والتعديل ومراجعة ملفاتهم حسب الصلاحية.',
    availableActions: <String>[
      'البحث عن سائق',
      'فتح بيانات السائق',
      'إضافة سائق جديد',
    ],
    keywords: <String>['السائقين', 'drivers', 'سائق'],
  ),
  AppRoutes.tasks: MoAssistantRouteContext(
    route: AppRoutes.tasks,
    title: 'المهام',
    section: 'إدارة المهام',
    summary:
        'مخصصة لمتابعة المهام وتوزيعها وفتح التفاصيل والحالة الحالية والرسائل المرتبطة بها.',
    availableActions: <String>[
      'مراجعة المهام الحالية',
      'فتح تفاصيل المهمة',
      'متابعة التنفيذ أو الاعتماد',
    ],
    keywords: <String>['المهام', 'tasks', 'task'],
  ),
  AppRoutes.chat: MoAssistantRouteContext(
    route: AppRoutes.chat,
    title: 'المحادثات',
    section: 'التواصل الداخلي',
    summary:
        'تعرض المحادثات الداخلية بين الموظفين ويمكن من خلالها فتح محادثة أو متابعة الرسائل والتنبيهات.',
    availableActions: <String>[
      'فتح محادثة',
      'متابعة الرسائل الجديدة',
      'البحث عن مستخدم أو محادثة',
    ],
    keywords: <String>['المحادثات', 'chat', 'messages', 'رسائل'],
  ),
  AppRoutes.reports: MoAssistantRouteContext(
    route: AppRoutes.reports,
    title: 'التقارير',
    section: 'التقارير والتحليل',
    summary:
        'تجمع أنواع التقارير المختلفة مثل العملاء والموردين والسائقين والفواتير والمستخدمين.',
    availableActions: <String>[
      'اختيار نوع التقرير',
      'تطبيق فلترة',
      'تصدير التقرير أو مراجعته',
    ],
    keywords: <String>['التقارير', 'reports', 'تقرير'],
  ),
  AppRoutes.inventoryDashboard: MoAssistantRouteContext(
    route: AppRoutes.inventoryDashboard,
    title: 'لوحة المخزون',
    section: 'المخزون',
    summary:
        'تعرض مؤشرات المخزون والفروع والمستودعات والفواتير والحالة العامة للأصناف.',
    availableActions: <String>[
      'متابعة حالة المخزون',
      'فتح شاشة الفواتير',
      'فتح شاشة المخزون التفصيلية',
    ],
    keywords: <String>['المخزون', 'inventory', 'أصناف', 'مستودع'],
  ),
  AppRoutes.inventoryStock: MoAssistantRouteContext(
    route: AppRoutes.inventoryStock,
    title: 'المخزون التفصيلي',
    section: 'المخزون',
    summary:
        'تعرض الأصناف والكميات والتوافر ويمكن استخدامها للمراجعة والبحث والمتابعة.',
    availableActions: <String>[
      'البحث عن صنف',
      'مراجعة الكمية الحالية',
      'متابعة حالة التوفر',
    ],
    keywords: <String>['stock', 'مخزون', 'كمية', 'صنف'],
  ),
  AppRoutes.maintenanceDashboard: MoAssistantRouteContext(
    route: AppRoutes.maintenanceDashboard,
    title: 'لوحة الصيانة',
    section: 'الصيانة',
    summary:
        'تعرض أعمال الصيانة الدورية والحالات الحالية وسجلات الصيانة الخاصة بالمركبات أو المعدات.',
    availableActions: <String>[
      'متابعة سجلات الصيانة',
      'فتح تفاصيل سجل',
      'إضافة سجل صيانة جديد',
    ],
    keywords: <String>['الصيانة', 'maintenance', 'دورية'],
  ),
  AppRoutes.workshopFuelDashboard: MoAssistantRouteContext(
    route: AppRoutes.workshopFuelDashboard,
    title: 'ورشة الوقود',
    section: 'صيانة ووقود',
    summary:
        'تعرض بيانات توريد وصرف الوقود داخل الورشة وتقارير الاستهلاك والحركة.',
    availableActions: <String>[
      'متابعة التوريدات',
      'تسجيل تعبئة',
      'فتح تقرير الورشة',
    ],
    keywords: <String>['ورشة الوقود', 'fuel workshop', 'توريد', 'تعبئة'],
  ),
  AppRoutes.mainHome: MoAssistantRouteContext(
    route: AppRoutes.mainHome,
    title: 'الرئيسية للمحطات',
    section: 'إدارة المحطات',
    summary:
        'هذه الشاشة الرئيسية الخاصة بالمحطات ومنها يتم الوصول إلى الجلسات والجرد والتقارير والمحطات.',
    availableActions: <String>[
      'فتح الجلسات',
      'فتح المحطات',
      'فتح الجرد أو التقارير',
    ],
    keywords: <String>['المحطات', 'stations', 'main home'],
  ),
  AppRoutes.sessionsList: MoAssistantRouteContext(
    route: AppRoutes.sessionsList,
    title: 'الجلسات',
    section: 'إدارة المحطات',
    summary:
        'تعرض جلسات العمل الخاصة بالمحطة ويمكن منها مراجعة الجلسات المفتوحة أو المغلقة وفتح التفاصيل.',
    availableActions: <String>[
      'فتح جلسة جديدة',
      'مراجعة جلسة حالية',
      'فتح تفاصيل الجلسة',
    ],
    keywords: <String>['الجلسات', 'sessions', 'session'],
  ),
  AppRoutes.stationMaintenanceDashboard: MoAssistantRouteContext(
    route: AppRoutes.stationMaintenanceDashboard,
    title: 'تطوير وصيانة المحطات',
    section: 'صيانة المحطات',
    summary:
        'تعرض طلبات صيانة وتطوير المحطات وتساعد في المتابعة والتعيين والمراجعة حسب الصلاحية.',
    availableActions: <String>[
      'مراجعة الطلبات',
      'فتح التفاصيل',
      'تعيين فني أو متابعة التنفيذ',
    ],
    keywords: <String>['station maintenance', 'صيانة المحطات', 'تطوير المحطات'],
  ),
  AppRoutes.marketingStations: MoAssistantRouteContext(
    route: AppRoutes.marketingStations,
    title: 'تسويق المحطات',
    section: 'المحطات',
    summary:
        'تعرض بيانات محطات التسويق ومتابعة العقود والمضخات والملفات المرتبطة بها.',
    availableActions: <String>[
      'فتح بيانات محطة',
      'متابعة العقد',
      'متابعة المضخات',
    ],
    keywords: <String>['تسويق المحطات', 'marketing stations'],
  ),
  AppRoutes.qualificationDashboard: MoAssistantRouteContext(
    route: AppRoutes.qualificationDashboard,
    title: 'تأهيل المحطات',
    section: 'المحطات',
    summary: 'تعرض طلبات أو حالات تأهيل المحطات مع التفاصيل والموقع والمراجعة.',
    availableActions: <String>[
      'فتح حالة تأهيل',
      'مراجعة التفاصيل',
      'متابعة الخريطة أو الحالة',
    ],
    keywords: <String>['تأهيل المحطات', 'qualification'],
  ),
  AppRoutes.archiveDocuments: MoAssistantRouteContext(
    route: AppRoutes.archiveDocuments,
    title: 'الأرشفة',
    section: 'الأرشيف',
    summary:
        'هذه الشاشة مخصصة للأرشفة وحفظ المستندات ومتابعة السجلات والبحث داخلها.',
    availableActions: <String>[
      'إضافة مستند',
      'البحث في الأرشيف',
      'فتح تفاصيل مستند',
    ],
    keywords: <String>['أرشفة', 'archive', 'مستندات'],
  ),
  AppRoutes.contractsManagement: MoAssistantRouteContext(
    route: AppRoutes.contractsManagement,
    title: 'العقود',
    section: 'العقود',
    summary:
        'تعرض إدارة العقود ومتابعة حالتها وتفاصيلها والمستندات المرتبطة بها.',
    availableActions: <String>[
      'مراجعة العقود',
      'فتح بيانات عقد',
      'متابعة حالة العقد',
    ],
    keywords: <String>['العقود', 'contracts', 'عقد'],
  ),
  AppRoutes.hrDashboard: MoAssistantRouteContext(
    route: AppRoutes.hrDashboard,
    title: 'لوحة شؤون الموظفين',
    section: 'شؤون الموظفين',
    summary:
        'تعرض مؤشرات الموارد البشرية مثل الموظفين والحضور والرواتب والتنبيهات والأحداث القادمة.',
    availableActions: <String>[
      'مراجعة إحصائيات الموظفين',
      'فتح الحضور أو الرواتب أو السلف',
      'متابعة التنبيهات',
    ],
    keywords: <String>['شؤون الموظفين', 'hr', 'الموظفين'],
  ),
  AppRoutes.employees: MoAssistantRouteContext(
    route: AppRoutes.employees,
    title: 'الموظفون',
    section: 'شؤون الموظفين',
    summary:
        'تعرض قائمة الموظفين مع البحث والتصفية وفتح التفاصيل والإضافة والتعديل حسب الصلاحية.',
    availableActions: <String>[
      'البحث عن موظف',
      'فتح الملف الوظيفي',
      'إضافة موظف جديد',
    ],
    keywords: <String>['الموظفين', 'employees', 'employee'],
  ),
  AppRoutes.attendance: MoAssistantRouteContext(
    route: AppRoutes.attendance,
    title: 'الحضور والانصراف',
    section: 'شؤون الموظفين',
    summary:
        'تعرض سجلات الحضور والانصراف والتقارير اليومية ويمكن استخدامها للمراجعة والمتابعة.',
    availableActions: <String>[
      'مراجعة الحضور',
      'التصفية حسب التاريخ أو الموظف',
      'فتح التقارير',
    ],
    keywords: <String>['الحضور', 'attendance', 'انصراف'],
  ),
  AppRoutes.salaries: MoAssistantRouteContext(
    route: AppRoutes.salaries,
    title: 'الرواتب',
    section: 'شؤون الموظفين',
    summary:
        'تعرض مسيرات الرواتب وحالتها وتفاصيلها واعتمادها أو متابعتها حسب الصلاحية.',
    availableActions: <String>[
      'مراجعة الرواتب',
      'فتح تفاصيل مسير',
      'متابعة الاعتماد أو الصرف',
    ],
    keywords: <String>['الرواتب', 'salaries', 'salary'],
  ),
  AppRoutes.advances: MoAssistantRouteContext(
    route: AppRoutes.advances,
    title: 'السلف',
    section: 'شؤون الموظفين',
    summary:
        'تعرض طلبات السلف وحالتها ويمكن متابعة الموافقة أو الرفض أو السداد.',
    availableActions: <String>[
      'مراجعة طلبات السلف',
      'فتح تفاصيل الطلب',
      'متابعة الحالة أو السداد',
    ],
    keywords: <String>['السلف', 'advances', 'advance'],
  ),
  AppRoutes.penalties: MoAssistantRouteContext(
    route: AppRoutes.penalties,
    title: 'الجزاءات',
    section: 'شؤون الموظفين',
    summary:
        'تعرض الجزاءات والمخالفات الخاصة بالموظفين ويمكن مراجعتها ومتابعة القرار المرتبط بها.',
    availableActions: <String>[
      'مراجعة الجزاءات',
      'فتح تفاصيل الجزاء',
      'متابعة الحالة أو القرار',
    ],
    keywords: <String>['الجزاءات', 'penalties', 'penalty'],
  ),
  AppRoutes.locations: MoAssistantRouteContext(
    route: AppRoutes.locations,
    title: 'المواقع',
    section: 'شؤون الموظفين',
    summary:
        'تعرض مواقع العمل ونطاقاتها الزمنية والمكانية لاستخدامها في الحضور والانصراف والمتابعة.',
    availableActions: <String>[
      'مراجعة المواقع',
      'فتح بيانات موقع',
      'متابعة الإعدادات المرتبطة بالموقع',
    ],
    keywords: <String>['المواقع', 'locations', 'location'],
  ),
  AppRoutes.settings: MoAssistantRouteContext(
    route: AppRoutes.settings,
    title: 'الإعدادات',
    section: 'النظام',
    summary:
        'تعرض إعدادات النظام أو الحساب أو التفضيلات حسب ما هو متاح للمستخدم.',
    availableActions: <String>['مراجعة الإعدادات', 'تعديل التفضيلات'],
    keywords: <String>['الإعدادات', 'settings'],
  ),
  AppRoutes.notifications: MoAssistantRouteContext(
    route: AppRoutes.notifications,
    title: 'الإشعارات',
    section: 'التنبيهات',
    summary:
        'تعرض الإشعارات والتنبيهات الحديثة المرتبطة بالطلبات أو المهام أو النظام.',
    availableActions: <String>[
      'قراءة الإشعارات',
      'فتح التنبيه المرتبط بالعنصر',
    ],
    keywords: <String>['الإشعارات', 'notifications', 'تنبيهات'],
  ),
  AppRoutes.profile: MoAssistantRouteContext(
    route: AppRoutes.profile,
    title: 'الملف الشخصي',
    section: 'الحساب',
    summary:
        'تعرض بيانات المستخدم الحالية مثل الاسم والبريد والدور وبعض تفاصيل الحساب.',
    availableActions: <String>[
      'مراجعة بيانات الحساب',
      'متابعة المعلومات الشخصية',
    ],
    keywords: <String>['الملف الشخصي', 'profile'],
  ),
};

MoAssistantRouteContext? describeMoAssistantRoute(String? rawRoute) {
  if (rawRoute == null || rawRoute.trim().isEmpty) return null;
  final normalized = Uri.tryParse(rawRoute)?.path ?? rawRoute.trim();
  return _routeGuide[normalized];
}
