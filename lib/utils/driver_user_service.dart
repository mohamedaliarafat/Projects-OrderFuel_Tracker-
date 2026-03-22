import 'dart:convert';

import 'package:order_tracker/models/driver_model.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/utils/api_service.dart';

String normalizeDriverTruckUsername(String value) {
  final sanitized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  if (sanitized.isEmpty) {
    return 'driver_truck';
  }

  if (sanitized.startsWith('driver_truck')) {
    return sanitized;
  }

  return 'driver_truck_$sanitized';
}

String suggestedDriverTruckUsername({
  String? vehicleNumber,
  String? licenseNumber,
  String? phone,
}) {
  String sanitize(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .trim();
  }

  final phoneDigits = (phone ?? '').replaceAll(RegExp(r'[^0-9]+'), '').trim();
  final suffix = [
    sanitize(vehicleNumber),
    sanitize(licenseNumber),
    phoneDigits.length > 4 ? phoneDigits.substring(phoneDigits.length - 4) : phoneDigits,
  ].firstWhere((value) => value.isNotEmpty, orElse: () => '');

  if (suffix.isEmpty) {
    return 'driver_truck';
  }

  return 'driver_truck_$suffix';
}

String normalizeDriverAccountEmail(String value) {
  return value.trim().toLowerCase();
}

bool isValidDriverAccountEmail(String value) {
  final normalized = normalizeDriverAccountEmail(value);
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
}

Future<List<User>> fetchDriverUsers({int limit = 500}) async {
  final response = await ApiService.get('/users?role=driver&limit=$limit');
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  final rawUsers = decoded is Map<String, dynamic> ? decoded['users'] : decoded;

  if (rawUsers is! Iterable) {
    return const <User>[];
  }

  return rawUsers
      .whereType<Map>()
      .map((item) => User.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

Future<User?> findDriverUserByDriverId(String driverId, {int limit = 500}) async {
  final users = await fetchDriverUsers(limit: limit);
  for (final user in users) {
    if (user.driverId == driverId) {
      return user;
    }
  }
  return null;
}

Future<User> upsertDriverUser({
  required Driver driver,
  required String username,
  required String email,
  required String company,
  User? existingUser,
  String? password,
}) async {
  final normalizedUsername = normalizeDriverTruckUsername(username);
  final normalizedEmail = normalizeDriverAccountEmail(email);
  final trimmedPassword = password?.trim() ?? '';

  if (!isValidDriverAccountEmail(normalizedEmail)) {
    throw Exception('بريد حساب السائق غير صالح');
  }

  final payload = <String, dynamic>{
    'name': driver.name,
    'username': normalizedUsername,
    'email': normalizedEmail,
    'company': company,
    'phone': driver.phone,
    'role': 'driver',
    'driverId': driver.id,
    'permissions': const ['orders_view', 'orders_view_assigned_only'],
  };

  if (existingUser == null) {
    if (trimmedPassword.isEmpty) {
      throw Exception('كلمة مرور حساب السائق مطلوبة');
    }
    payload['password'] = trimmedPassword;
    final response = await ApiService.post('/users', payload);
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    return _extractUser(decoded);
  }

  if (trimmedPassword.isNotEmpty) {
    payload['password'] = trimmedPassword;
  }

  final response = await ApiService.put('/users/${existingUser.id}', payload);
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  return _extractUser(decoded);
}

User _extractUser(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    final rawUser = payload['user'] ?? payload['data'] ?? payload;
    if (rawUser is Map) {
      return User.fromJson(Map<String, dynamic>.from(rawUser));
    }
  }

  throw Exception('تعذر قراءة بيانات مستخدم السائق');
}
