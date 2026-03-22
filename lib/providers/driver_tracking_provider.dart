import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:order_tracker/models/driver_tracking_models.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';

class DriverTrackingProvider with ChangeNotifier {
  List<DriverTrackingSummary> _drivers = [];
  DriverTrackingDetail? _selectedDetail;
  bool _isLoading = false;
  bool _isPublishingLocation = false;
  String? _error;

  List<DriverTrackingSummary> get drivers => _drivers;
  DriverTrackingDetail? get selectedDetail => _selectedDetail;
  bool get isLoading => _isLoading;
  bool get isPublishingLocation => _isPublishingLocation;
  String? get error => _error;

  Future<void> fetchTrackingDrivers({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.trackingDrivers}'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> raw = data is List
            ? List<dynamic>.from(data)
            : data is Map && data['drivers'] is List
            ? List<dynamic>.from(data['drivers'] as List)
            : data is Map && data['data'] is List
            ? List<dynamic>.from(data['data'] as List)
            : <dynamic>[];

        final summaries = <DriverTrackingSummary>[];
        for (final item in raw) {
          if (item is! Map) continue;
          try {
            summaries.add(
              DriverTrackingSummary.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (e) {
            debugPrint('Failed to parse tracking driver item: $e');
          }
        }

        _drivers = summaries;
        _error = null;
        if (_drivers.isEmpty && raw.isNotEmpty) {
          _error = 'تعذر قراءة بيانات المتابعة الحالية';
        }
      } else {
        _error = 'فشل في جلب متابعة السائقين';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<DriverTrackingDetail?> fetchDriverDetail(
    String driverId, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.trackingDriverById(driverId)}',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final detail = DriverTrackingDetail.fromJson(
          Map<String, dynamic>.from(data is Map ? data : const {}),
        );
        _selectedDetail = detail;
        _isLoading = false;
        notifyListeners();
        return detail;
      }

      _error = 'فشل في جلب بيانات السائق';
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> publishDriverLocation({
    required DriverLocationSnapshot snapshot,
  }) async {
    _isPublishingLocation = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.driverLocations}'),
        headers: ApiService.headers,
        body: json.encode(snapshot.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isPublishingLocation = false;
        notifyListeners();
        return true;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      _error = data['error']?.toString() ?? 'فشل في إرسال موقع السائق';
    } catch (e) {
      _error = e.toString();
    }

    _isPublishingLocation = false;
    notifyListeners();
    return false;
  }

  void clearDetail() {
    _selectedDetail = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
