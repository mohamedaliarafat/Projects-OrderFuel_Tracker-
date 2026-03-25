import 'package:order_tracker/utils/app_routes.dart';

const String employeeRoleKey = 'employee';

const Set<String> employeeAllowedRoutePaths = <String>{
  AppRoutes.marketingStations,
  AppRoutes.tasks,
  AppRoutes.qualificationDashboard,
  AppRoutes.qualificationForm,
  AppRoutes.qualificationDetails,
  AppRoutes.qualificationMap,
  AppRoutes.chat,
  AppRoutes.chatConversation,
  AppRoutes.notifications,
  AppRoutes.profile,
  AppRoutes.settings,
  AppRoutes.support,
};

String normalizeRoutePath(String routeName) {
  final uri = Uri.tryParse(routeName);
  return uri?.path ?? routeName;
}

bool isEmployeeRole(String? role) {
  return role?.trim().toLowerCase() == employeeRoleKey;
}

bool isRouteAllowedForRole({required String? role, required String routeName}) {
  final path = normalizeRoutePath(routeName);
  if (isEmployeeRole(role)) {
    return employeeAllowedRoutePaths.contains(path);
  }
  return true;
}
