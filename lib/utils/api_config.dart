import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String productionBaseUrl =
      'https://system-albuhairaalarabia.cloud/api';

  static const String _envKey = 'API_BASE_URL';

  static String get baseUrl {
    const override = String.fromEnvironment(_envKey, defaultValue: '');
    if (override.trim().isNotEmpty) {
      return _normalize(override);
    }

    if (kReleaseMode) {
      return productionBaseUrl;
    }

    return _defaultDevBaseUrl();
  }

  static String _defaultDevBaseUrl() {
    if (kIsWeb) return 'https://system-albuhairaalarabia.cloud/api';
    // if (kIsWeb) return 'http://localhost:6030/api';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:6030/api';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:6030/api';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:6030/api';
      default:
        return 'http://localhost:6030/api';
    }
  }

  static String _normalize(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    if (!url.endsWith('/api')) {
      url = '$url/api';
    }

    return url;
  }
}

