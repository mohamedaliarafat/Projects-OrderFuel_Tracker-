import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:order_tracker/models/managed_auth_device.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/login_device_util.dart';

class ManagedDevicesProvider with ChangeNotifier {
  final List<ManagedAuthDevice> _devices = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _currentDeviceId;
  int _totalDevices = 0;
  int _activeSessions = 0;
  int _blockedDevices = 0;

  List<ManagedAuthDevice> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get currentDeviceId => _currentDeviceId;
  int get totalDevices => _totalDevices;
  int get activeSessions => _activeSessions;
  int get blockedDevices => _blockedDevices;

  bool isCurrentDevice(String deviceId) {
    return _currentDeviceId != null && _currentDeviceId == deviceId;
  }

  Future<void> fetchDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentDeviceId ??= (await LoginDeviceUtil.resolve()).deviceId;

      final response = await ApiService.get(ApiEndpoints.authDevices);
      final body = json.decode(utf8.decode(response.bodyBytes));
      final rawDevices = body['devices'] as List<dynamic>? ?? const [];
      final summary = body['summary'] as Map<dynamic, dynamic>? ?? const {};

      _devices
        ..clear()
        ..addAll(
          rawDevices.whereType<Map>().map(
            (item) =>
                ManagedAuthDevice.fromJson(Map<String, dynamic>.from(item)),
          ),
        );

      _totalDevices =
          int.tryParse(summary['totalDevices']?.toString() ?? '') ??
          _devices.length;
      _activeSessions =
          int.tryParse(summary['activeSessions']?.toString() ?? '') ??
          _devices.where((device) => device.isLoggedIn).length;
      _blockedDevices =
          int.tryParse(summary['blockedDevices']?.toString() ?? '') ??
          _devices.where((device) => device.blocked).length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ManagedAuthDevice> blockDevice(
    String deviceRecordId, {
    String? reason,
  }) async {
    return _updateDevice(
      request: () =>
          ApiService.patch(ApiEndpoints.authDeviceBlock(deviceRecordId), {
            if (reason != null && reason.trim().isNotEmpty)
              'reason': reason.trim(),
          }),
      deviceRecordId: deviceRecordId,
    );
  }

  Future<ManagedAuthDevice> unblockDevice(String deviceRecordId) async {
    return _updateDevice(
      request: () => ApiService.patch(
        ApiEndpoints.authDeviceUnblock(deviceRecordId),
        const {},
      ),
      deviceRecordId: deviceRecordId,
    );
  }

  Future<ManagedAuthDevice> logoutDevice(String deviceRecordId) async {
    return _updateDevice(
      request: () => ApiService.post(
        ApiEndpoints.authDeviceLogout(deviceRecordId),
        const {},
      ),
      deviceRecordId: deviceRecordId,
    );
  }

  Future<int> logoutDevices(Iterable<String> deviceRecordIds) async {
    final uniqueIds = deviceRecordIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (uniqueIds.isEmpty) {
      return 0;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      var affectedDevices = 0;

      for (final deviceRecordId in uniqueIds) {
        final response = await ApiService.post(
          ApiEndpoints.authDeviceLogout(deviceRecordId),
          const {},
        );
        final body = json.decode(utf8.decode(response.bodyBytes));
        final updatedDevice = ManagedAuthDevice.fromJson(
          Map<String, dynamic>.from(body['device'] as Map),
        );

        final deviceIndex = _devices.indexWhere(
          (device) => device.id == deviceRecordId,
        );
        if (deviceIndex >= 0) {
          _devices[deviceIndex] = updatedDevice;
        }

        affectedDevices += 1;
      }

      _recomputeSummary();
      return affectedDevices;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<int> logoutAllDevices() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        ApiEndpoints.logoutAllAuthDevices,
        const {},
      );
      final body = json.decode(utf8.decode(response.bodyBytes));
      final affectedDevices =
          int.tryParse(body['affectedDevices']?.toString() ?? '') ?? 0;
      final rawDevices = body['devices'] as List<dynamic>? ?? const [];
      final summary = body['summary'] as Map<dynamic, dynamic>? ?? const {};

      _devices
        ..clear()
        ..addAll(
          rawDevices.whereType<Map>().map(
            (item) =>
                ManagedAuthDevice.fromJson(Map<String, dynamic>.from(item)),
          ),
        );

      _totalDevices =
          int.tryParse(summary['totalDevices']?.toString() ?? '') ??
          _devices.length;
      _activeSessions =
          int.tryParse(summary['activeSessions']?.toString() ?? '') ??
          _devices.where((device) => device.isLoggedIn).length;
      _blockedDevices =
          int.tryParse(summary['blockedDevices']?.toString() ?? '') ??
          _devices.where((device) => device.blocked).length;
      return affectedDevices;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<ManagedAuthDevice> _updateDevice({
    required Future<dynamic> Function() request,
    required String deviceRecordId,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await request();
      final body = json.decode(utf8.decode(response.bodyBytes));
      final updatedDevice = ManagedAuthDevice.fromJson(
        Map<String, dynamic>.from(body['device'] as Map),
      );

      final deviceIndex = _devices.indexWhere(
        (device) => device.id == deviceRecordId,
      );
      if (deviceIndex >= 0) {
        _devices[deviceIndex] = updatedDevice;
      }

      _recomputeSummary();
      return updatedDevice;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _recomputeSummary() {
    _totalDevices = _devices.length;
    _activeSessions = _devices.where((device) => device.isLoggedIn).length;
    _blockedDevices = _devices.where((device) => device.blocked).length;
  }
}
