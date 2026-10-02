import 'package:flutter/material.dart';

enum AppLanguage {
  indonesian(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩',
    locale: Locale('id'),
  ),
  english(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    locale: Locale('en'),
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
    if (code == null || code.isEmpty) return AppLanguage.indonesian;

    for (final lang in AppLanguage.values) {
      if (lang.code.toLowerCase() == code.toLowerCase()) {
        return lang;
      }
    }

    final lower = code.toLowerCase();
    if (lower.startsWith('zh_hant') || lower.contains('tw') || lower.contains('hk')) {
      return AppLanguage.chineseTraditional;
    }
    if (lower.startsWith('zh') || lower.contains('cn') || lower.contains('hans')) {
      return AppLanguage.chineseSimplified;
    }
    if (lower.startsWith('ja')) return AppLanguage.japanese;
    if (lower.startsWith('ko')) return AppLanguage.korean;
    if (lower.startsWith('en')) return AppLanguage.english;

    return AppLanguage.indonesian;
  }

  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((e) => e.locale).toList();
}
