import 'package:flutter/material.dart';

enum AppLanguage {
  indonesian(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩',
    locale: Locale('id'),
  ),
  malay(
    code: 'ms',
    name: 'Malay',
    nativeName: 'Bahasa Melayu',
    flag: '🇲🇾',
    locale: Locale('ms'),
  ),
  danish(
    code: 'da',
    name: 'Danish',
    nativeName: 'Dansk',
    flag: '🇩🇰',
    locale: Locale('da'),
  ),
  german(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
    flag: '🇩🇪',
    locale: Locale('de'),
  ),
  english(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    locale: Locale('en'),
  ),
  spanish(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
    locale: Locale('es'),
  ),
  french(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
    locale: Locale('fr'),
  ),
  italian(
    code: 'it',
    name: 'Italian',
    nativeName: 'Italiano',
    flag: '🇮🇹',
    locale: Locale('it'),
  ),
  dutch(
    code: 'nl',
    name: 'Dutch',
    nativeName: 'Nederlands',
    flag: '🇳🇱',
    locale: Locale('nl'),
  ),
  norwegian(
    code: 'no',
    name: 'Norwegian',
    nativeName: 'Norsk',
    flag: '🇳🇴',
    locale: Locale('no'),
  ),
  portuguese(
    code: 'pt',
    name: 'Portuguese',
    nativeName: 'Português',
    flag: '🇵🇹',
    locale: Locale('pt'),
  ),
  finnish(
    code: 'fi',
    name: 'Finnish',
    nativeName: 'Suomi',
    flag: '🇫🇮',
    locale: Locale('fi'),
  ),
  swedish(
    code: 'sv',
    name: 'Swedish',
    nativeName: 'Svenska',
    flag: '🇸🇪',
    locale: Locale('sv'),
  ),
  vietnamese(
    code: 'vi',
    name: 'Vietnamese',
    nativeName: 'Tiếng Việt',
    flag: '🇻🇳',
    locale: Locale('vi'),
  ),
  russian(
    code: 'ru',
    name: 'Russian',
    nativeName: 'Русский',
    flag: '🇷🇺',
    locale: Locale('ru'),
  ),
  arabic(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    flag: '🇸🇦',
    locale: Locale('ar'),
  ),
  hindi(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    flag: '🇮🇳',
    locale: Locale('hi'),
  ),
  thai(
    code: 'th',
    name: 'Thai',
    nativeName: 'ไทย',
    flag: '🇹🇭',
    locale: Locale('th'),
  ),
  japanese(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    flag: '🇯🇵',
    locale: Locale('ja'),
  ),
  chineseSimplified(
    code: 'zh_Hans',
    name: 'Chinese (Simplified)',
    nativeName: '简体中文',
    flag: '🇨🇳',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ),
  chineseTraditional(
    code: 'zh_Hant',
    name: 'Chinese (Traditional)',
    nativeName: '繁體中文',
    flag: '🇹🇼',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ),
  korean(
    code: 'ko',
    name: 'Korean',
    nativeName: '한국어',
    flag: '🇰🇷',
    locale: Locale('ko'),
  );

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final Locale locale;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.locale,
  });

  static AppLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return AppLanguage.english;

    for (final lang in AppLanguage.values) {
      if (lang.code.toLowerCase() == code.toLowerCase()) {
        return lang;
      }
    }

    final lower = code.toLowerCase();
    if (lower.startsWith('zh_hant') ||
        lower.contains('tw') ||
        lower.contains('hk')) {
      return AppLanguage.chineseTraditional;
    }
    if (lower.startsWith('zh') ||
        lower.contains('cn') ||
        lower.contains('hans')) {
      return AppLanguage.chineseSimplified;
    }
    if (lower.startsWith('ja')) return AppLanguage.japanese;
    if (lower.startsWith('ko')) return AppLanguage.korean;
    if (lower.startsWith('id')) return AppLanguage.indonesian;
    if (lower.startsWith('ms')) return AppLanguage.malay;
    if (lower.startsWith('da')) return AppLanguage.danish;
    if (lower.startsWith('de')) return AppLanguage.german;
    if (lower.startsWith('es')) return AppLanguage.spanish;
    if (lower.startsWith('fr')) return AppLanguage.french;
    if (lower.startsWith('it')) return AppLanguage.italian;
    if (lower.startsWith('nl')) return AppLanguage.dutch;
    if (lower.startsWith('no')) return AppLanguage.norwegian;
    if (lower.startsWith('pt')) return AppLanguage.portuguese;
    if (lower.startsWith('fi')) return AppLanguage.finnish;
    if (lower.startsWith('sv')) return AppLanguage.swedish;
    if (lower.startsWith('vi')) return AppLanguage.vietnamese;
    if (lower.startsWith('ru')) return AppLanguage.russian;
    if (lower.startsWith('ar')) return AppLanguage.arabic;
    if (lower.startsWith('hi')) return AppLanguage.hindi;
    if (lower.startsWith('th')) return AppLanguage.thai;
    if (lower.startsWith('en')) return AppLanguage.english;

    return AppLanguage.english;
  }

  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((e) => e.locale).toList();

  static List<AppLanguage> get sortedAlphabetically {
    final list = List<AppLanguage>.from(AppLanguage.values);
    list.sort((a, b) => a.nativeName.compareTo(b.nativeName));
    return list;
  }
}
