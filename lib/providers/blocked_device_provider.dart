import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:order_tracker/models/blocked_login_device.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';

class BlockedDeviceProvider with ChangeNotifier {
  final List<BlockedLoginDevice> _devices = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<BlockedLoginDevice> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> fetchDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiEndpoints.blockedDevices);
      final body = json.decode(utf8.decode(response.bodyBytes));
      final rawDevices = body['devices'] as List<dynamic>? ?? const [];
      _devices
        ..clear()
        ..addAll(
          rawDevices.whereType<Map>().map(
            (item) =>
                BlockedLoginDevice.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unblockDevice(String deviceRecordId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.patch(
        '${ApiEndpoints.blockedDevices}/$deviceRecordId/unblock',
        const {},
      );
      _devices.removeWhere((device) => device.id == deviceRecordId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
