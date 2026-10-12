import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../localization/app_localizations.dart';
import 'storage_service.dart';

class AppLanguageService {
  static ValueNotifier<AppLanguage>? _currentLanguageNotifier;

  static ValueNotifier<AppLanguage> get currentLanguageNotifier =>
      _currentLanguageNotifier ??= ValueNotifier<AppLanguage>(
        AppLanguage.english,
      );

  static void init(StorageService storageService) {
    final code = storageService.getLanguageCode();
    final lang = AppLanguage.fromCode(code);
    if (_currentLanguageNotifier == null) {
      _currentLanguageNotifier = ValueNotifier<AppLanguage>(lang);
    } else {
      _currentLanguageNotifier!.value = lang;
    }
    AppLocalizations(lang);
  }

  static AppLanguage get currentLanguage => currentLanguageNotifier.value;

  static Future<void> changeLanguage(
    AppLanguage language,
    StorageService storageService,
  ) async {
    await storageService.setLanguageCode(language.code);
    currentLanguageNotifier.value = language;
  }
}
