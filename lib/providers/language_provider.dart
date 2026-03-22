import 'package:flutter/material.dart';
import 'package:order_tracker/localization/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  bool _hasManualSelection = false;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  void setLanguage(AppLanguage language, {bool manual = true}) {
    if (_language == language) return;

    _language = language;
    if (manual) {
      _hasManualSelection = true;
    }
    notifyListeners();
  }

  void updateDefaultForRole(String? role) {
    if (role == null) {
      _hasManualSelection = false;
      return setLanguage(AppLanguage.english, manual: false);
    }

    if (_hasManualSelection) return;

    final defaultLang = switch (role) {
      'station_boy' => AppLanguage.bengali,
      'driver' => AppLanguage.english,
      _ => AppLanguage.arabic,
    };
    setLanguage(defaultLang, manual: false);
  }
}
