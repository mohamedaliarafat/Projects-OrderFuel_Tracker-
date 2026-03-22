import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginDeviceMetadata {
  const LoginDeviceMetadata({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final String deviceId;
  final String deviceName;
  final String platform;

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
    };
  }
}

class LoginDeviceUtil {
  static const String _deviceIdKey = 'login_device_id';

  static Future<LoginDeviceMetadata> resolve() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey) ?? '';

    if (deviceId.trim().isEmpty) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    final platform = _platformLabel();
    return LoginDeviceMetadata(
      deviceId: deviceId,
      deviceName: 'order-tracker-$platform',
      platform: platform,
    );
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final randomPart = List<String>.generate(
      24,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '$timestamp-$randomPart';
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'desktop';
      case TargetPlatform.fuchsia:
        return 'desktop';
    }
  }
}
