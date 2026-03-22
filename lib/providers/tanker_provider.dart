import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:order_tracker/models/tanker_model.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';

class TankerProvider with ChangeNotifier {
  List<Tanker> _tankers = [];
  bool _isLoading = false;
  String? _error;

  List<Tanker> get tankers => _tankers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTankers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/tankers'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        List<dynamic> tankersData = [];
        if (data is List) {
          tankersData = data;
        } else if (data['tankers'] is List) {
          tankersData = data['tankers'];
        } else if (data['data'] is List) {
          tankersData = data['data'];
        }

        _tankers = tankersData
            .whereType<Map>()
            .map((e) => Tanker.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _isLoading = false;
        notifyListeners();
        return;
      }

      _error = 'فشل في جلب الصهاريج';
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTanker(Tanker tanker) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/tankers'),
        headers: ApiService.headers,
        body: json.encode(tanker.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final raw = data is Map && data['tanker'] != null
            ? data['tanker']
            : data is Map && data['data'] != null
            ? data['data']
            : data;
        final created = Tanker.fromJson(Map<String, dynamic>.from(raw));
        _tankers.insert(0, created);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final errorData = json.decode(utf8.decode(response.bodyBytes));
      _error =
          errorData['error'] ?? errorData['message'] ?? 'فشل إضافة الصهريج';
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateTanker(String id, Tanker tanker) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.baseUrl}/tankers/$id'),
        headers: ApiService.headers,
        body: json.encode(tanker.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final raw = data is Map && data['tanker'] != null
            ? data['tanker']
            : data is Map && data['data'] != null
            ? data['data']
            : data;
        final updated = Tanker.fromJson(Map<String, dynamic>.from(raw));

        final index = _tankers.indexWhere((t) => t.id == id);
        if (index != -1) {
          _tankers[index] = updated;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      final errorData = json.decode(utf8.decode(response.bodyBytes));
      _error =
          errorData['error'] ?? errorData['message'] ?? 'فشل تحديث الصهريج';
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteTanker(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/tankers/$id'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _tankers.removeWhere((t) => t.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final errorData = json.decode(utf8.decode(response.bodyBytes));
      _error = errorData['error'] ?? errorData['message'] ?? 'فشل حذف الصهريج';
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
