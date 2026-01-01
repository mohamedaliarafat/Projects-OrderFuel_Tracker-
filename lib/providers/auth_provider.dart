// auth_provider.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // ================= GETTERS =================
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  // ================= INIT =================
  /// تُستدعى مرة واحدة عند تشغيل التطبيق
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');
      final userJson = prefs.getString('user');

      if (savedToken != null && userJson != null) {
        _token = savedToken;
        _user = User.fromJson(json.decode(userJson));

        // أهم سطر 👇
        ApiService.setToken(savedToken);

        notifyListeners();
        debugPrint('✅ AUTH INITIALIZED (TOKEN LOADED)');
      }
    } catch (e, s) {
      debugPrint('❌ INIT AUTH ERROR: $e');
      debugPrint('STACK: $s');
    }
  }

  // ================= LOGIN =================
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.login}'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final receivedToken = data['token'];
        final userData = data['user'];

        if (receivedToken == null || userData == null) {
          throw Exception('Token أو User غير موجودين في الاستجابة');
        }

        _token = receivedToken;
        _user = User.fromJson(userData);

        // حفظ دائم
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', receivedToken);
        await prefs.setString('user', json.encode(_user!.toJson()));

        // أهم سطر 👇
        ApiService.setToken(receivedToken);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? 'فشل تسجيل الدخول';
      }
    } on SocketException {
      _error = 'لا يوجد اتصال بالإنترنت';
    } catch (e, s) {
      debugPrint('❌ LOGIN ERROR: $e');
      debugPrint('STACK: $s');
      _error = 'حدث خطأ غير متوقع أثناء تسجيل الدخول';
    }

    _setLoading(false);
    notifyListeners();
    return false;
  }

  // ================= REGISTER =================
  Future<bool> register(
    String name,
    String email,
    String password,
    String company,
    String? phone,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.register}'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'company': company,
          'phone': phone,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        final receivedToken = data['token'];
        final userData = data['user'];

        if (receivedToken == null || userData == null) {
          throw Exception('Token أو User غير موجودين');
        }

        _token = receivedToken;
        _user = User.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', receivedToken);
        await prefs.setString('user', json.encode(_user!.toJson()));

        // مهم جدًا
        ApiService.setToken(receivedToken);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? 'فشل إنشاء الحساب';
      }
    } catch (e, s) {
      debugPrint('❌ REGISTER ERROR: $e');
      debugPrint('STACK: $s');
      _error = 'حدث خطأ غير متوقع أثناء التسجيل';
    }

    _setLoading(false);
    notifyListeners();
    return false;
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    _user = null;
    _token = null;

    // مهم جدًا
    ApiService.setToken(null);

    notifyListeners();
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile(User updatedUser) async {
    _user = updatedUser;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(updatedUser.toJson()));

    notifyListeners();
  }

  // ================= HELPERS =================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
