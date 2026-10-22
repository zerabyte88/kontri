import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_language.dart';
import 'app_translations_data.dart';

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations? _current;

  static AppLocalizations get current {
    _current ??= AppLocalizations(AppLanguage.english);
    return _current!;
  }

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    return localizations ?? current;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Helper string translation lookup
  String _t(String key) {
    return appTranslations[language]?[key] ??
        appTranslations[AppLanguage.english]?[key] ??
        appTranslations[AppLanguage.indonesian]?[key] ??
        key;
  }

  // App & General
  String get appTitle => 'Kontri';
  String get close => _t('close');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get refresh => _t('refresh');
  String get retry => _t('retry');
  String get openInGithub => _t('openInGithub');
  String get aboutApp => _t('aboutApp');
  String get appVersionLabel => _t('appVersionLabel');
  String get buildNumberLabel => _t('buildNumberLabel');
  String get appDescriptionLabel => _t('appDescriptionLabel');
  String get licenseLabel => _t('licenseLabel');

  String cannotOpenLink(String url) {
    final template = _t('cannotOpenLink');
    return template.contains('{url}')
        ? template.replaceAll('{url}', url)
        : '$template: $url';
  }

  String failedToOpenLink(String error) {
    final template = _t('failedToOpenLink');
    return template.contains('{error}')
        ? template.replaceAll('{error}', error)
        : '$template: $error';
  }

  String get searchHint => _t('searchHint');
  String get recentSearches => _t('recentSearches');
  String get clearAll => _t('clearAll');
  String get noRecentSearches => _t('noRecentSearches');
  String get favoriteProfiles => _t('favoriteProfiles');
  String get favoriteProfile => favoriteProfiles;
  String get viewAllFavorites => _t('viewAllFavorites');
  String get gridColumnsLabel => _t('gridColumnsLabel');
  String get undo => _t('undo');

  String removedFromFavoritesWithUser(String username) {
    final template = _t('removedFromFavoritesWithUser');
    return template.contains('{username}')
        ? template.replaceAll('{username}', username)
        : '@$username $template';
  }

  String get emptyBookmarks => _t('emptyBookmarks');
  String get userNotFound => _t('userNotFound');
  String get networkError => _t('networkError');
  String get rateLimitExceeded => _t('rateLimitExceeded');

  // Tech News
  String get techNewsTitle => _t('techNewsTitle');
  String get categoryAi => _t('categoryAi');
  String get categoryTech => _t('categoryTech');
  String get categoryOpenSource => _t('categoryOpenSource');
  String get categoryTrending => _t('categoryTrending');
  String get categoryGithub => _t('categoryGithub');
  String get categoryWebDev => _t('categoryWebDev');
  String get noNewsFound => _t('noNewsFound');
  String get offlineCached => _t('offlineCached');
  String get minRead => _t('minRead');

  // Settings & Theme
  String get settingsTitle => _t('settingsTitle');
  String get settingsSubtitle => _t('settingsSubtitle');
  String get languageSectionTitle => _t('languageSectionTitle');
  String get languageSectionSubtitle => _t('languageSectionSubtitle');
  String get languageChangedToast => _t('languageChangedToast');
  String get themeSectionTitle => _t('themeSectionTitle');
  String get themeSectionSubtitle => _t('themeSectionSubtitle');
  String get themeOpacityTitle => _t('themeOpacityTitle');
  String get themeOpacitySubtitle => _t('themeOpacitySubtitle');
  String get bgAnimationTitle => _t('bgAnimationTitle');
  String get bgAnimationSubtitle => _t('bgAnimationSubtitle');
  String get themeDark => _t('themeDark');
  String get themeDarkSubtitle => _t('themeDarkSubtitle');
  String get themeAmoled => _t('themeAmoled');
  String get themeAmoledSubtitle => _t('themeAmoledSubtitle');
  String get themeAmoledJapanese => _t('themeAmoledJapanese');
  String get themeAmoledJapaneseSubtitle => _t('themeAmoledJapaneseSubtitle');
  String get themeLight => _t('themeLight');
  String get themeLightSubtitle => _t('themeLightSubtitle');
  String get themeAmoledPure => _t('themeAmoledPure');
  String get themeAmoledPureSubtitle => _t('themeAmoledPureSubtitle');
  String get themeCleanLight => _t('themeCleanLight');
  String get themeCleanLightSubtitle => _t('themeCleanLightSubtitle');
  String get settingsBypassShaderNotice => _t('settingsBypassShaderNotice');
  String get activeLanguageBadge => _t('activeLanguageBadge');
  String get resetLabel => _t('resetLabel');

  String t(String key) {
    switch (key) {
      case 'card_opacity':
      case 'settings_card_opacity':
        return themeOpacityTitle;
      case 'card_opacity_desc':
      case 'settings_card_opacity_desc':
        return themeOpacitySubtitle;
      case 'bypass_shader':
      case 'bypass_shader_notice':
        return settingsBypassShaderNotice;
      case 'reset':
        return resetLabel;
      case 'active':
      case 'active_language_badge':
        return activeLanguageBadge;
      case 'theme_dark':
        return themeDark;
      case 'theme_oled':
        return themeAmoled;
      case 'theme_sakura':
        return themeAmoledJapanese;
      case 'theme_light':
        return themeLight;
      case 'theme_oled_pure':
        return themeAmoledPure;
      case 'theme_light_clean':
        return themeCleanLight;
      default:
        return key;
    }
  }


  // Updates & About
  String get openInBrowser => _t('openInBrowser');
  String get developerLabel => _t('developerLabel');
  String get developerRole => _t('developerRole');

  // Rate Limit Status
  String get rateLimitStatus => _t('rateLimitStatus');
  String get personalTokenActive => _t('personalTokenActive');
  String get standardMode => _t('standardMode');
  String get requestsUsed => _t('requestsUsed');
  String get remainingQuota => _t('remainingQuota');
  String get resetIn => _t('resetIn');
  String get resetting => _t('resetting');

  String formatCountdown(Duration diff) {
    if (diff.isNegative || diff.inSeconds <= 0) {
      return resetting;
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    if (hours > 0) {
      final h = _t('unitHourShort');
      final m = _t('unitMinuteShort');
      return '$hours $h $minutes $m';
    }
    if (minutes > 0) {
      final m = _t('unitMinuteLong');
      return '$minutes $m';
    }
    final s = _t('unitSecondLong');
    return '$seconds $s';
  }

  // Token Section
  String get githubTokenTitle => 'GitHub Personal Token';
  String get optionalBadge => _t('optionalBadge');
  String get tokenActiveBadge => _t('tokenActiveBadge');
  String get tokenSubtitle => tokenDescription;
  String get tokenDescription => _t('tokenDescription');
  String get tokenHint => _t('tokenHint');
  String get howToCreateToken => _t('howToCreateToken');
  String get tokenGuideContent => _t('tokenGuideContent');
  String get deleteToken => _t('deleteToken');
  String get saveToken => _t('saveToken');
  String get tokenSavedToast => _t('tokenSavedToast');
  String get tokenDeletedToast => _t('tokenDeletedToast');

  // Developer Profile & Stats Detail
  String get noBio => _t('noBio');
  String get noLocation => _t('noLocation');
  String get publicRepos => _t('publicRepos');
  String get totalStars => _t('totalStars');
  String get totalForks => _t('totalForks');
  String get followers => _t('followers');
  String get following => _t('following');

  // Activity & Rhythm
  String get activityRhythmTitle => _t('activityRhythmTitle');
  String get activityRhythmSubtitle => _t('activityRhythmSubtitle');
  String get peakLabel => _t('peakLabel');
  String get eventsUnit => _t('eventsUnit');
  String get streakStatsTitle => _t('streakStatsTitle');
  String get currentStreak => _t('currentStreak');
  String get longestStreak => _t('longestStreak');
  String get thisYearContributions => _t('thisYearContributions');
  String get totalContributions => _t('totalContributions');
  String get allYearsContributions => _t('allYearsContributions');
  String get daysUnit => _t('daysUnit');

  // Top Languages
  String get topLanguagesTitle => _t('topLanguagesTitle');
  String get languageDistribution => _t('languageDistribution');
  String get otherLanguages => _t('otherLanguages');
  String get noLanguageData => _t('noLanguageData');

  // Repositories List
  String get repositoriesTitle => _t('repositoriesTitle');
  String get totalCountBadge => _t('totalCountBadge');
  String get filterRepositories => _t('filterRepositories');
  String get filterPopular => _t('filterPopular');
  String get filterPopularDesc => _t('filterPopularDesc');
  String get filterNewest => _t('filterNewest');
  String get filterNewestDesc => _t('filterNewestDesc');
  String get filterOldest => _t('filterOldest');
  String get filterOldestDesc => _t('filterOldestDesc');
  String get noPublicRepos => _t('noPublicRepos');

  String showAllReposCount(int count) {
    final template = _t('showAllReposCount');
    return template.contains('{count}')
        ? template.replaceAll('{count}', '$count')
        : '$template ($count)';
  }

  String get showFewerRepos => _t('showFewerRepos');

  // Repository Details Page
  String get readmeTitle => _t('readmeTitle');
  String get loadingReadme => _t('loadingReadme');
  String get noReadmeFound => _t('noReadmeFound');
  String get searchRepoFiles => _t('searchRepoFiles');
  String get noFilesFound => _t('noFilesFound');
  String get loadingFiles => _t('loadingFiles');
  String get filesTab => _t('filesTab');
  String get loadingContents => _t('loadingContents');
  String get emptyDirectory => _t('emptyDirectory');
  String get loadingFile => _t('loadingFile');
  String get cannotPreviewBinary => _t('cannotPreviewBinary');
  String get copyCode => _t('copyCode');
  String get codeCopied => _t('codeCopied');

  // Profile Action Toast
  String get shareProfile => _t('shareProfile');
  String get saveFavorite => _t('saveFavorite');
  String get removeFavorite => _t('removeFavorite');

  String profileSavedToFavorites(String username) {
    final template = _t('profileSavedToFavorites');
    return template.contains('{username}')
        ? template.replaceAll('{username}', username)
        : '@$username $template';
  }

  String get profileRemovedFromFavorites => _t('profileRemovedFromFavorites');
  String get refreshProfile => _t('refreshProfile');
  String get profileRefreshed => _t('profileRefreshed');
  String get profileUpToDate => _t('profileUpToDate');
  String get summaryCopiedToast => _t('summaryCopiedToast');

  // Hero Card Subtitles
  String get activeNowBadge => _t('activeNowBadge');
  String get notActiveYetBadge => _t('notActiveYetBadge');
  String get consistencyRecord => _t('consistencyRecord');
  String get thisYearSubtitle => _t('thisYearSubtitle');
  String get allTimeSubtitle => _t('allTimeSubtitle');
  String get accountOverviewTitle => _t('accountOverviewTitle');
  String get acrossAllRepos => _t('acrossAllRepos');
  String get registeredReposSubtitle => _t('registeredReposSubtitle');

  String formatRelativeTime(DateTime? date) {
    if (date == null) {
      return _t('timeNoActivity');
    }

    final diff = DateTime.now().difference(date);
    if (diff.isNegative || diff.inMinutes < 1) {
      return _t('timeJustNow');
    } else if (diff.inHours < 1) {
      return _t('timeMinAgo').replaceAll('{min}', '${diff.inMinutes}');
    } else if (diff.inHours < 24) {
      return _t('timeHourAgo').replaceAll('{hour}', '${diff.inHours}');
    } else if (diff.inDays < 30) {
      return _t('timeDayAgo').replaceAll('{day}', '${diff.inDays}');
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return _t('timeMonthAgo').replaceAll('{month}', '$months');
    } else {
      final years = (diff.inDays / 365).floor();
      return _t('timeYearAgo').replaceAll('{year}', '$years');
    }
  }


  String getCommitTierLevelName(int tier) {
    switch (tier) {
      case 1:
        return _t('tierLevel1');
      case 2:
        return _t('tierLevel2');
      case 3:
        return _t('tierLevel3');
      case 4:
        return _t('tierLevel4');
      case 5:
        return _t('tierLevel5');
      case 6:
      default:
        return _t('tierLevel6');
    }
  }

  String getCommitTierCleanTitle(int tier) {
    switch (tier) {
      case 1:
        return _t('tierClean1');
      case 2:
        return _t('tierClean2');
      case 3:
        return _t('tierClean3');
      case 4:
        return _t('tierClean4');
      case 5:
        return _t('tierClean5');
      case 6:
      default:
        return _t('tierClean6');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final language = AppLanguage.fromCode(
      locale.scriptCode != null && locale.scriptCode!.isNotEmpty
          ? '${locale.languageCode}_${locale.scriptCode}'
          : locale.languageCode,
    );
    final localizations = AppLocalizations(language);
    AppLocalizations._current = localizations;
    return SynchronousFuture<AppLocalizations>(localizations);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
