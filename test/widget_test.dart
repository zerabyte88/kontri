import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gitpulse_mobile/localization/app_language.dart';
import 'package:gitpulse_mobile/localization/app_localizations.dart';
import 'package:gitpulse_mobile/models/bookmarked_user.dart';
import 'package:gitpulse_mobile/models/contribution_stats.dart';
import 'package:gitpulse_mobile/models/github_content_item.dart';
import 'package:gitpulse_mobile/models/github_rate_limit.dart';
import 'package:gitpulse_mobile/models/github_repo.dart';
import 'package:gitpulse_mobile/models/github_user.dart';
import 'package:gitpulse_mobile/models/tech_news.dart';
import 'package:gitpulse_mobile/models/user_stats.dart';
import 'package:gitpulse_mobile/screens/favorite_profiles_screen.dart';
import 'package:gitpulse_mobile/screens/home_screen.dart';
import 'package:gitpulse_mobile/screens/file_viewer_screen.dart';
import 'package:gitpulse_mobile/screens/repo_detail_screen.dart';
import 'package:gitpulse_mobile/screens/stats_detail_screen.dart';
import 'package:gitpulse_mobile/services/github_api_service.dart';
import 'package:gitpulse_mobile/services/storage_service.dart';
import 'package:gitpulse_mobile/services/app_theme_service.dart';
import 'package:gitpulse_mobile/services/app_language_service.dart';
import 'package:gitpulse_mobile/services/tech_news_service.dart';
import 'package:gitpulse_mobile/services/update_service.dart';
import 'package:gitpulse_mobile/theme/app_theme.dart';
import 'package:flutter/rendering.dart';
import 'package:gitpulse_mobile/widgets/animated_app_background.dart';
import 'package:gitpulse_mobile/widgets/animated_app_header.dart';
import 'package:gitpulse_mobile/widgets/animated_tier_title.dart';
import 'package:gitpulse_mobile/widgets/language_chart.dart';
import 'package:gitpulse_mobile/widgets/repo_tile.dart';
import 'package:gitpulse_mobile/widgets/stat_card.dart';
import 'package:gitpulse_mobile/widgets/running_text.dart';
import 'package:gitpulse_mobile/widgets/glass_card.dart';
import 'package:gitpulse_mobile/widgets/settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GitPulse Model Tests', () {
    test('GitHubUser fromJson parses correctly', () {
      final json = {
        'login': 'octocat',
        'id': 1,
        'avatar_url': 'https://github.com/images/error/octocat_happy.gif',
        'html_url': 'https://github.com/octocat',
        'name': 'The Octocat',
        'public_repos': 8,
        'followers': 20,
        'following': 0,
      };

      final user = GitHubUser.fromJson(json);

      expect(user.login, 'octocat');
      expect(user.id, 1);
      expect(user.publicRepos, 8);
      expect(user.followers, 20);
    });

    test('ContributionStats determines commit titles correctly for different frequencies', () {
      // 1. Sangat Rajin Ekstrem (Mythic Archmage)
      final mythic = ContributionStats.determineTitle(
        currentStreak: 32,
        longestStreak: 65,
        thisYearContributions: 520,
        totalContributions: 800,
      );
      expect(mythic.title, contains('Mythic Archmage'));
      expect(mythic.levelName, contains('Sangat Rajin'));

      // 2. Sangat Rajin (Diamond Vanguard)
      final diamond = ContributionStats.determineTitle(
        currentStreak: 16,
        longestStreak: 32,
        thisYearContributions: 210,
        totalContributions: 300,
      );
      expect(diamond.title, contains('Diamond Vanguard'));
      expect(diamond.levelName, contains('Sangat Rajin'));

      // 3. Rajin & Stabil (Platinum Artisan)
      final platinum = ContributionStats.determineTitle(
        currentStreak: 8,
        longestStreak: 15,
        thisYearContributions: 75,
        totalContributions: 100,
      );
      expect(platinum.title, contains('Platinum Artisan'));

      // 4. Terkadang Commit (Gold Adventurer)
      final gold = ContributionStats.determineTitle(
        currentStreak: 4,
        longestStreak: 8,
        thisYearContributions: 25,
        totalContributions: 40,
      );
      expect(gold.title, contains('Gold Adventurer'));
      expect(gold.levelName, contains('Commit Terkadang'));

      // 5. Jarang Commit (Silver Explorer)
      final silver = ContributionStats.determineTitle(
        currentStreak: 0,
        longestStreak: 1,
        thisYearContributions: 3,
        totalContributions: 5,
      );
      expect(silver.title, contains('Silver Explorer'));
      expect(silver.levelName, contains('Jarang Commit'));

      // 6. Belum Aktif (Bronze Novice)
      final bronze = ContributionStats.determineTitle(
        currentStreak: 0,
        longestStreak: 0,
        thisYearContributions: 0,
        totalContributions: 0,
      );
      expect(bronze.title, contains('Bronze Novice'));
      expect(bronze.levelName, contains('Belum Aktif'));
    });

    test('ContributionStats calculates active and longest streaks accurately across dates', () {
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      final yesterday = DateTime.utc(now.year, now.month, now.day - 1);
      final twoDaysAgo = DateTime.utc(now.year, now.month, now.day - 2);
      final threeDaysAgo = DateTime.utc(now.year, now.month, now.day - 3);

      // Scenario 1: Active streak including today (today and yesterday consecutive, gap on twoDaysAgo)
      final counts = {today: 5, yesterday: 2, twoDaysAgo: 0, threeDaysAgo: 10};
      final streaks = ContributionStats.calculateStreaks(counts);
      expect(streaks.current, 2); // today and yesterday
      expect(streaks.longest, 2);

      // Scenario 2: Active streak from yesterday (not yet committed today)
      final countsYesterday = {
        today: 0,
        yesterday: 4,
        twoDaysAgo: 1,
        threeDaysAgo: 2,
      };
      final streaksYesterday = ContributionStats.calculateStreaks(
        countsYesterday,
      );
      expect(streaksYesterday.current, 3);
      expect(streaksYesterday.longest, 3);

      // Scenario 3: Broken streak (last commit was 2 days ago)
      final countsBroken = {
        today: 0,
        yesterday: 0,
        twoDaysAgo: 5,
        threeDaysAgo: 6,
      };
      final streaksBroken = ContributionStats.calculateStreaks(countsBroken);
      expect(streaksBroken.current, 0);
      expect(streaksBroken.longest, 2);
    });

    test('ContributionStats.fromContributionsApi correctly parses multi-year list with future dates', () {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yest = now.subtract(const Duration(days: 1));
      final yestStr =
          '${yest.year}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';

      final mockApi = {
        'total': {'${now.year}': 15, '${now.year - 1}': 50},
        'contributions': [
          // Current year with future date
          {'date': '${now.year}-12-31', 'count': 0},
          {'date': todayStr, 'count': 5},
          {'date': yestStr, 'count': 10},
          // Last year
          {'date': '${now.year - 1}-12-31', 'count': 0},
        ],
      };

      final stats = ContributionStats.fromContributionsApi(mockApi);
      expect(stats.currentStreak, 2);
      expect(stats.longestStreak, 2);
      expect(stats.thisYearContributions, 15);
      expect(stats.totalContributions, 65);
    });

    test('GitHubRepo relative time formatting handles hours and days', () {
      final now = DateTime.now();

      final recentRepo = GitHubRepo(
        name: 'recent-repo',
        htmlUrl: 'https://github.com/test/recent-repo',
        stargazersCount: 5,
        forksCount: 1,
        isFork: false,
        pushedAt: now.subtract(const Duration(hours: 3)),
      );
      expect(recentRepo.relativeTimeAgo, '3 jam lalu');
      expect(recentRepo.isRecentlyActive, true);

      final daysAgoRepo = GitHubRepo(
        name: 'days-repo',
        htmlUrl: 'https://github.com/test/days-repo',
        stargazersCount: 0,
        forksCount: 0,
        isFork: false,
        pushedAt: now.subtract(const Duration(days: 4)),
      );
      expect(daysAgoRepo.relativeTimeAgo, '4 hari lalu');
      expect(daysAgoRepo.isRecentlyActive, true);

      final oldRepo = GitHubRepo(
        name: 'old-repo',
        htmlUrl: 'https://github.com/test/old-repo',
        stargazersCount: 0,
        forksCount: 0,
        isFork: false,
        pushedAt: now.subtract(const Duration(days: 120)),
      );
      expect(oldRepo.relativeTimeAgo, '4 bln lalu');
      expect(oldRepo.isRecentlyActive, false);
    });

    test('UserStats calculates stars and languages accurately', () {
      final user = GitHubUser(
        login: 'octocat',
        id: 1,
        avatarUrl: 'https://github.com/avatar.png',
        htmlUrl: 'https://github.com/octocat',
        publicRepos: 2,
        followers: 10,
        following: 2,
      );

      final repos = [
        GitHubRepo(
          name: 'repo1',
          htmlUrl: 'https://github.com/octocat/repo1',
          language: 'Dart',
          stargazersCount: 45,
          forksCount: 5,
          isFork: false,
        ),
        GitHubRepo(
          name: 'repo2',
          htmlUrl: 'https://github.com/octocat/repo2',
          language: 'Python',
          stargazersCount: 60,
          forksCount: 10,
          isFork: false,
        ),
      ];

      final contribStats = ContributionStats.determineTitle(
        currentStreak: 5,
        longestStreak: 10,
        thisYearContributions: 50,
        totalContributions: 100,
      );

      final stats = UserStats.calculate(
        user: user,
        repos: repos,
        publicEvents: [],
        contributionStats: ContributionStats(
          thisYearContributions: 50,
          lastYearContributions: 50,
          currentStreak: 5,
          longestStreak: 10,
          totalContributions: 100,
          commitTitle: contribStats,
          yearlyTotals: {'2026': 50, '2025': 50},
        ),
      );

      expect(stats.totalStars, 105);
      expect(stats.totalForks, 15);
      expect(stats.languageCounts['Dart'], 1);
      expect(stats.languageCounts['Python'], 1);
      expect(stats.developerPersona, contains('Star Magnet'));
    });

    test('UserStats uses aggregatedLanguages bytes with high fidelity', () {
      final user = GitHubUser(
        login: 'zerabyte88',
        id: 1,
        avatarUrl: 'https://github.com/avatar.png',
        htmlUrl: 'https://github.com/zerabyte88',
        publicRepos: 3,
        followers: 5,
        following: 1,
      );

      final repos = [
        GitHubRepo(
          name: 'repo1',
          htmlUrl: 'https://github.com/zerabyte88/repo1',
          language: 'Dart',
          stargazersCount: 0,
          forksCount: 0,
          isFork: false,
          size: 87,
        ),
      ];

      final aggregated = {
        'Dart': 66038,
        'HTML': 38404,
        'PHP': 210388,
        'CSS': 18771,
      };

      final contribStats = ContributionStats.determineTitle(
        currentStreak: 0,
        longestStreak: 0,
        thisYearContributions: 0,
        totalContributions: 0,
      );

      final stats = UserStats.calculate(
        user: user,
        repos: repos,
        publicEvents: [],
        contributionStats: ContributionStats(
          thisYearContributions: 0,
          lastYearContributions: 0,
          currentStreak: 0,
          longestStreak: 0,
          totalContributions: 0,
          commitTitle: contribStats,
          yearlyTotals: {},
        ),
        aggregatedLanguages: aggregated,
      );

      expect(stats.languageCounts['PHP'], 210388);
      expect(stats.languageCounts['Dart'], 66038);
      expect(stats.languageCounts['HTML'], 38404);
      expect(stats.languageCounts['CSS'], 18771);
    });

    test('BookmarkedUser parses correctly and provides avatar fallback and profile details', () {
      final userWithAvatar = BookmarkedUser.fromJson({
        'username': 'octocat',
        'avatar_url': 'https://avatars.githubusercontent.com/u/583231',
        'name': 'The Octocat',
        'bio': 'GitHub mascot and feline developer',
        'location': 'San Francisco, CA',
      });
      expect(userWithAvatar.username, 'octocat');
      expect(
        userWithAvatar.avatarUrl,
        'https://avatars.githubusercontent.com/u/583231',
      );
      expect(userWithAvatar.name, 'The Octocat');
      expect(userWithAvatar.bio, 'GitHub mascot and feline developer');
      expect(userWithAvatar.location, 'San Francisco, CA');

      final userDefault = BookmarkedUser.fromJson({'username': 'torvalds'});
      expect(userDefault.username, 'torvalds');
      expect(userDefault.avatarUrl, 'https://github.com/torvalds.png');
      expect(userDefault.name, isNull);
      expect(userDefault.bio, isNull);
      expect(userDefault.location, isNull);

      final copied = userDefault.copyWith(
        name: 'Linus Torvalds',
        bio: 'Creator of Linux & Git',
        location: 'Portland, Oregon',
      );
      expect(copied.name, 'Linus Torvalds');
      expect(copied.bio, 'Creator of Linux & Git');
      expect(copied.location, 'Portland, Oregon');
      expect(copied.toJson()['name'], 'Linus Torvalds');
    });

    test('StorageService persists bookmarks with avatar and manages recent searches', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      // Test default and setting grid columns (clamped to 1-2)
      expect(storage.getFavoriteGridColumns(), 2);
      await storage.setFavoriteGridColumns(1);
      expect(storage.getFavoriteGridColumns(), 1);
      await storage.setFavoriteGridColumns(4);
      expect(storage.getFavoriteGridColumns(), 2);

      // Add bookmark with full details
      await storage.toggleBookmark(
        'linus',
        avatarUrl: 'https://avatars.githubusercontent.com/linus',
        name: 'Linus Torvalds',
        bio: 'Linux Kernel Developer',
        location: 'Portland, OR',
      );
      expect(storage.isBookmarked('linus'), true);

      final bookmarks = storage.getBookmarkedUsers();
      expect(bookmarks.length, 1);
      expect(bookmarks.first.username, 'linus');
      expect(
        bookmarks.first.avatarUrl,
        'https://avatars.githubusercontent.com/linus',
      );
      expect(bookmarks.first.name, 'Linus Torvalds');
      expect(bookmarks.first.bio, 'Linux Kernel Developer');
      expect(bookmarks.first.location, 'Portland, OR');

      // Update details
      await storage.updateBookmarkDetails('linus', bio: 'Creator of Git');
      expect(storage.getBookmarkedUsers().first.bio, 'Creator of Git');

      // Add recent searches and verify removal
      await storage.addRecentSearch('flutter');
      await storage.addRecentSearch('dart');
      expect(storage.getRecentSearches(), ['dart', 'flutter']);

      await storage.removeRecentSearch('dart');
      expect(storage.getRecentSearches(), ['flutter']);

      // Remove bookmark
      await storage.removeBookmark('linus');
      expect(storage.isBookmarked('linus'), false);
      expect(storage.getBookmarkedUsers().isEmpty, true);
    });

    test('TechNews fromJson parses correctly with tags and user info', () {
      final json = {
        'id': 1234,
        'title': 'AI Breakthrough in 2026',
        'description': 'Exploring latest advancements in LLM models.',
        'url': 'https://dev.to/article/ai-breakthrough',
        'readable_publish_date': 'Sep 27',
        'reading_time_minutes': 5,
        'tag_list': ['ai', 'machinelearning'],
        'user': {
          'name': 'Ada Lovelace',
          'profile_image_90': 'https://avatar.test/ada.png',
        },
      };

      final news = TechNews.fromJson(json);
      expect(news.id, 1234);
      expect(news.title, 'AI Breakthrough in 2026');
      expect(news.authorName, 'Ada Lovelace');
      expect(news.authorAvatar, 'https://avatar.test/ada.png');
      expect(news.tags, ['ai', 'machinelearning']);
      expect(news.readingTimeMinutes, 5);
    });

    test(
      'GitHubRateLimit metrics and percentage calculations behave as expected',
      () {
        // 1. Untouched / never run: remaining == limit -> 100%
        final untouched = GitHubRateLimit(
          limit: 60,
          remaining: 60,
          used: 0,
          resetTime: DateTime.now().add(const Duration(minutes: 50)),
        );
        expect(untouched.remainingRatio, 1.0);
        expect(untouched.remainingPercentage, 100.0);
        expect(untouched.used, 0);

        // 2. Partial usage: 28 used, 32 remaining of 60
        final partial = GitHubRateLimit(
          limit: 60,
          remaining: 32,
          used: 28,
          resetTime: DateTime.now().add(const Duration(minutes: 30)),
        );
        expect(partial.used, 28);
        expect(partial.remaining, 32);
        expect(partial.remainingPercentage, closeTo(53.33, 0.1));

        // 3. Exhausted: 60 used, 0 remaining -> 0%
        final exhausted = GitHubRateLimit(
          limit: 60,
          remaining: 0,
          used: 60,
          resetTime: DateTime.now().add(const Duration(minutes: 5)),
        );
        expect(exhausted.remainingRatio, 0.0);
        expect(exhausted.remainingPercentage, 0.0);
        expect(exhausted.used, 60);

        // 4. Personal Token usage: 1001 used of 5000
        final tokenLimit = GitHubRateLimit(
          limit: 5000,
          remaining: 3999,
          used: 1001,
          resetTime: DateTime.now().add(const Duration(minutes: 45)),
        );
        expect(tokenLimit.limit, 5000);
        expect(tokenLimit.used, 1001);
        expect(tokenLimit.remaining, 3999);
        expect(tokenLimit.remainingPercentage, closeTo(79.98, 0.1));

        // 5. From JSON parsing
        final json = {
          'rate': {
            'limit': 60,
            'remaining': 45,
            'used': 15,
            'reset': 1790499958,
          },
        };
        final fromJson = GitHubRateLimit.fromJson(json);
        expect(fromJson.limit, 60);
        expect(fromJson.remaining, 45);
        expect(fromJson.used, 15);
      },
    );

    test('CommitTitleInfo cleanTitle strips icons and emojis cleanly', () {
      const info1 = CommitTitleInfo(
        title: '🌱 Fresh Sprout',
        levelName: 'Belum Aktif',
        badgeText: 'Tier: Bronze',
        tier: 6,
        description: '',
      );
      expect(info1.cleanTitle, 'Fresh Sprout');

      const info2 = CommitTitleInfo(
        title: '🔥 Code Titan',
        levelName: 'Sangat Rajin',
        badgeText: 'Tier: Mythic',
        tier: 1,
        description: '',
      );
      expect(info2.cleanTitle, 'Code Titan');

      const info3 = CommitTitleInfo(
        title: '⚡ Relentless Committer',
        levelName: 'Sangat Rajin',
        badgeText: 'Tier: Diamond',
        tier: 2,
        description: '',
      );
      expect(info3.cleanTitle, 'Relentless Committer');
    });

    test('AppLanguage parses and maps all 22 languages accurately', () {
      expect(AppLanguage.fromCode('id'), AppLanguage.indonesian);
      expect(AppLanguage.fromCode('ms'), AppLanguage.malay);
      expect(AppLanguage.fromCode('da'), AppLanguage.danish);
      expect(AppLanguage.fromCode('de'), AppLanguage.german);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('es'), AppLanguage.spanish);
      expect(AppLanguage.fromCode('fr'), AppLanguage.french);
      expect(AppLanguage.fromCode('it'), AppLanguage.italian);
      expect(AppLanguage.fromCode('nl'), AppLanguage.dutch);
      expect(AppLanguage.fromCode('no'), AppLanguage.norwegian);
      expect(AppLanguage.fromCode('pt'), AppLanguage.portuguese);
      expect(AppLanguage.fromCode('fi'), AppLanguage.finnish);
      expect(AppLanguage.fromCode('sv'), AppLanguage.swedish);
      expect(AppLanguage.fromCode('vi'), AppLanguage.vietnamese);
      expect(AppLanguage.fromCode('ru'), AppLanguage.russian);
      expect(AppLanguage.fromCode('ar'), AppLanguage.arabic);
      expect(AppLanguage.fromCode('hi'), AppLanguage.hindi);
      expect(AppLanguage.fromCode('th'), AppLanguage.thai);
      expect(AppLanguage.fromCode('ja'), AppLanguage.japanese);
      expect(AppLanguage.fromCode('zh_Hans'), AppLanguage.chineseSimplified);
      expect(AppLanguage.fromCode('zh_CN'), AppLanguage.chineseSimplified);
      expect(AppLanguage.fromCode('zh_Hant'), AppLanguage.chineseTraditional);
      expect(AppLanguage.fromCode('zh_TW'), AppLanguage.chineseTraditional);
      expect(AppLanguage.fromCode('ko'), AppLanguage.korean);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.english);

      expect(AppLanguage.values.length, 22);
      for (final lang in AppLanguage.values) {
        expect(lang.code, isNotEmpty);
        expect(lang.name, isNotEmpty);
        expect(lang.nativeName, isNotEmpty);
        expect(lang.flag, isNotEmpty);
      }
    });

    test(
      'AppLocalizations renders expected translations for all 6 languages',
      () {
        final idLoc = AppLocalizations(AppLanguage.indonesian);
        final enLoc = AppLocalizations(AppLanguage.english);
        final jaLoc = AppLocalizations(AppLanguage.japanese);
        final zhHansLoc = AppLocalizations(AppLanguage.chineseSimplified);
        final zhHantLoc = AppLocalizations(AppLanguage.chineseTraditional);
        final koLoc = AppLocalizations(AppLanguage.korean);

        // App Title / Repositories
        expect(idLoc.repositoriesTitle, 'Repositori');
        expect(enLoc.repositoriesTitle, 'Repositories');
        expect(jaLoc.repositoriesTitle, 'リポジトリ');
        expect(zhHansLoc.repositoriesTitle, '代码仓库');
        expect(zhHantLoc.repositoriesTitle, '代碼倉庫');
        expect(koLoc.repositoriesTitle, '리포지토리');

        // Search hint
        expect(idLoc.searchHint, 'Cari...');
        expect(enLoc.searchHint, 'Search...');
        expect(jaLoc.searchHint, '検索...');
        expect(zhHansLoc.searchHint, '搜索...');
        expect(zhHantLoc.searchHint, '搜尋...');
        expect(koLoc.searchHint, '검색...');

        // Theme options (Snowfall, Midnight, Daylight, Sakura)
        expect(idLoc.themeDark, 'Snowfall');
        expect(idLoc.themeAmoled, 'Midnight');
        expect(idLoc.themeLight, 'Daylight');
        expect(idLoc.themeAmoledJapanese, 'Sakura');
        expect(enLoc.themeDark, 'Snowfall');
        expect(enLoc.themeAmoled, 'Midnight');
        expect(enLoc.themeLight, 'Daylight');
        expect(enLoc.themeAmoledJapanese, 'Sakura');

        // Filter labels
        expect(idLoc.filterPopular, 'Terpopuler');
        expect(enLoc.filterPopular, 'Most Popular');
        expect(jaLoc.filterPopular, '人気順');
        expect(zhHansLoc.filterPopular, '最受欢迎');
        expect(zhHantLoc.filterPopular, '最受歡迎');
        expect(koLoc.filterPopular, '인기순');

        // Commit tier clean titles
        expect(idLoc.getCommitTierCleanTitle(1), 'Mythic Archmage');
        expect(jaLoc.getCommitTierCleanTitle(1), 'ミシック・アークメイジ');
        expect(zhHansLoc.getCommitTierCleanTitle(1), '秘法大法师');
        expect(zhHantLoc.getCommitTierCleanTitle(1), '秘法大法師');
        expect(koLoc.getCommitTierCleanTitle(1), '신화의 아크메이지');

        // Relative time formatting
        final tenMinutesAgo = DateTime.now().subtract(
          const Duration(minutes: 10),
        );
        expect(idLoc.formatRelativeTime(tenMinutesAgo), contains('mnt lalu'));
        expect(enLoc.formatRelativeTime(tenMinutesAgo), contains('m ago'));
        expect(jaLoc.formatRelativeTime(tenMinutesAgo), contains('分前'));
        expect(zhHansLoc.formatRelativeTime(tenMinutesAgo), contains('分钟前'));
        expect(zhHantLoc.formatRelativeTime(tenMinutesAgo), contains('分鐘前'));
        expect(koLoc.formatRelativeTime(tenMinutesAgo), contains('분 전'));

        // Rate limit countdown without leakage
        final fortyMinutes = const Duration(minutes: 40);
        expect(idLoc.formatCountdown(fortyMinutes), '40 menit');
        expect(enLoc.formatCountdown(fortyMinutes), '40 min');
        expect(jaLoc.formatCountdown(fortyMinutes), '40 分');
        expect(zhHansLoc.formatCountdown(fortyMinutes), '40 分钟');
        expect(zhHantLoc.formatCountdown(fortyMinutes), '40 分鐘');
        expect(koLoc.formatCountdown(fortyMinutes), '40 분');

        // Activity rhythm chart labels
        expect(idLoc.activityRhythmTitle, 'Ritme Jam Produktif');
        expect(enLoc.activityRhythmTitle, 'Productive Hours Rhythm');
        expect(jaLoc.activityRhythmTitle, '生産的時間のリズム');

        // Favorite profile labels
        expect(idLoc.favoriteProfiles, 'Profil Favorit');
        expect(enLoc.favoriteProfiles, 'Favorite Profile');
        expect(jaLoc.favoriteProfiles, 'お気に入りプロフィール');
        expect(zhHansLoc.favoriteProfiles, '收藏个人资料');
        expect(zhHantLoc.favoriteProfiles, '收藏個人檔案');
        expect(koLoc.favoriteProfiles, '즐겨찾는 프로필');
      },
    );

    test(
      'AppLocalizations covers all 22 global languages and sortedAlphabetically is correct',
      () {
        expect(AppLanguage.values.length, 22);

        // Verify sortedAlphabetically orders all 22 languages A-Z by English name
        final sorted = AppLanguage.sortedAlphabetically;
        expect(sorted.length, 22);
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].name.compareTo(sorted[i + 1].name) <= 0, isTrue);
        }

        // Verify all 22 languages return non-empty strings and pass quality standards
        for (final lang in AppLanguage.values) {
          final loc = AppLocalizations(lang);
          expect(loc.repositoriesTitle.isNotEmpty, isTrue);
          expect(loc.searchHint.isNotEmpty, isTrue);
          expect(loc.settingsTitle.isNotEmpty, isTrue);
          expect(loc.close.isNotEmpty, isTrue);
          expect(loc.save.isNotEmpty, isTrue);
          expect(loc.filterPopular.isNotEmpty, isTrue);
          expect(loc.filterNewest.isNotEmpty, isTrue);
          expect(loc.techNewsTitle.isNotEmpty, isTrue);
          expect(loc.updateAvailable.contains('!'), isFalse);
          expect(loc.getCommitTierCleanTitle(1).isNotEmpty, isTrue);
        }
      },
    );

    test(
      'StorageService persists and retrieves language preference correctly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);

        // Default is English (en)
        expect(storage.getLanguageCode(), 'en');

        // Update to Japanese
        await storage.setLanguageCode('ja');
        expect(storage.getLanguageCode(), 'ja');

        // Update to Korean
        await storage.setLanguageCode('ko');
        expect(storage.getLanguageCode(), 'ko');
      },
    );

    testWidgets(
      'StatsDetailScreen renders user full name clearly without being truncated by title',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final user = GitHubUser(
          login: 'zerabyte88',
          id: 12345,
          avatarUrl: '',
          htmlUrl: 'https://github.com/zerabyte88',
          name: 'Nanda Alexander',
          location: 'Planet Earth, Solar System',
          company: 'GitPulse Team',
          publicRepos: 10,
          followers: 50,
          following: 20,
        );

        final stats = UserStats(
          user: user,
          repos: [],
          totalStars: 42,
          totalForks: 12,
          languageCounts: {'Dart': 80, 'TypeScript': 20},
          hourlyActivity: {14: 10, 15: 15},
          developerPersona: 'Fullstack Explorer',
          personaDescription: 'Passionate developer',
          contributionStats: ContributionStats(
            thisYearContributions: 50,
            lastYearContributions: 100,
            currentStreak: 0,
            longestStreak: 6,
            totalContributions: 150,
            commitTitle: ContributionStats.determineTitle(
              currentStreak: 0,
              longestStreak: 6,
              thisYearContributions: 50,
              totalContributions: 150,
            ),
            yearlyTotals: {'2026': 50, '2025': 100},
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: StatsDetailScreen(stats: stats, storageService: storage),
          ),
        );

        // Verify that full name 'Nanda Alexander' is rendered
        expect(find.text('Nanda Alexander'), findsOneWidget);
        expect(find.text('@zerabyte88'), findsAtLeastNWidgets(1));
        expect(find.text('Planet Earth, Solar System'), findsOneWidget);
        expect(find.text('GitPulse Team'), findsOneWidget);

        // Verify that AnimatedTierTitle exists in the commit habit banner
        expect(find.byType(AnimatedTierTitle), findsOneWidget);

        // Verify all years total contributions card is rendered (in default English)
        expect(find.text('Total Contributions (All Years)'), findsOneWidget);
        expect(find.text('All time'), findsOneWidget);
        expect(find.text('150'), findsOneWidget);
      },
    );

    test(
      'AppConfig provides accurate release and version telemetry for v2.4.4',
      () {
        expect(AppConfig.appName, 'GitPulse');
        expect(AppConfig.appVersion, 'v2.4.4');
        expect(AppConfig.buildNumber, '25');
        expect(AppConfig.fullVersion, 'v2.4.4 (Build 25)');
        expect(AppConfig.releaseTag, 'v2.4.4');
        expect(AppConfig.license, 'MIT License');
        expect(AppConfig.githubRepoUrl, contains('github.com'));
      },
    );

    test('AppLocalizations provides expected translations for About and Version info', () {
      final idLoc = AppLocalizations(AppLanguage.indonesian);
      final enLoc = AppLocalizations(AppLanguage.english);

      expect(idLoc.aboutApp, 'Tentang GitPulse');
      expect(enLoc.aboutApp, 'About GitPulse');
      expect(idLoc.appVersionLabel, 'Versi Aplikasi');
      expect(enLoc.appVersionLabel, 'App Version');
      expect(idLoc.buildNumberLabel, 'Build');
      expect(enLoc.buildNumberLabel, 'Build');
      expect(idLoc.architectureLabel, 'Arsitektur');
      expect(enLoc.architectureLabel, 'Architecture');
      expect(idLoc.architectureValue, 'Clean Layered (Flutter 3)');
      expect(idLoc.licenseLabel, 'Lisensi');
      expect(enLoc.licenseLabel, 'License');
      expect(idLoc.viewOnGitHub, 'Lihat Repositori di GitHub');
      expect(enLoc.viewOnGitHub, 'View Repository on GitHub');
    });

    test(
      'UpdateService compareVersions handles semantic versions correctly',
      () {
        expect(UpdateService.compareVersions('v1.0.2', 'v1.0.1'), 1);
        expect(UpdateService.compareVersions('1.0.1', 'v1.0.1'), 0);
        expect(UpdateService.compareVersions('v1.0.1', 'v1.0.2'), -1);
        expect(UpdateService.compareVersions('v1.0.10', 'v1.0.2'), 1);
        expect(UpdateService.compareVersions('v2.1.0', 'v2.0.0'), 1);
      },
    );

    test('UpdateService cleanDownloadedApk removes leftover apk files successfully', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'gitpulse_ota_test',
      );
      try {
        final apkFile = File('${tempDir.path}/gitpulse-test.apk');
        await apkFile.writeAsString('dummy apk content');
        expect(await apkFile.exists(), true);

        final nonApkFile = File('${tempDir.path}/important_notes.txt');
        await nonApkFile.writeAsString('keep me');
        expect(await nonApkFile.exists(), true);

        final deleted = await UpdateService.cleanDownloadedApk(
          customPath: tempDir.path,
        );
        expect(deleted, true);
        expect(await apkFile.exists(), false);
        expect(await nonApkFile.exists(), true);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('TechNewsService caches results in-memory to prevent duplicate network calls', () async {
      final service = TechNewsService();
      // First fetch gets fallback or trending news
      final firstFetch = await service.fetchNews(tag: 'ai');
      expect(firstFetch.isNotEmpty, true);

      // Second fetch should return identical cached list instance without network call
      final secondFetch = await service.fetchNews(tag: 'ai');
      expect(identical(firstFetch, secondFetch), true);

      // clearCache should reset the cache
      service.clearCache();
      final thirdFetch = await service.fetchNews(tag: 'ai');
      expect(thirdFetch.isNotEmpty, true);
    });

    test(
      'TechNews toJson and fromJson roundtrip serialization works correctly',
      () {
        const original = TechNews(
          id: 999,
          title: '⭐ author/hot-repo (1200 stars)',
          description: 'A newly created viral open source project',
          url: 'https://github.com/author/hot-repo',
          coverImage: 'https://images.unsplash.com/photo-1',
          authorName: 'author',
          authorAvatar: 'https://avatars.githubusercontent.com/u/999',
          publishedDate: 'Trending Rust',
          readingTimeMinutes: 4,
          tags: ['trending', 'github', 'rust'],
        );

        final json = original.toJson();
        final restored = TechNews.fromJson(json);

        expect(restored.id, 999);
        expect(restored.title, '⭐ author/hot-repo (1200 stars)');
        expect(
          restored.description,
          'A newly created viral open source project',
        );
        expect(restored.url, 'https://github.com/author/hot-repo');
        expect(restored.authorName, 'author');
        expect(restored.publishedDate, 'Trending Rust');
        expect(restored.readingTimeMinutes, 4);
        expect(restored.tags, ['trending', 'github', 'rust']);
      },
    );

    test(
      'StorageService persists and restores cached news per tag with timestamp',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);

        expect(storage.getCachedNews('trending'), isNull);
        expect(storage.getCachedNewsTimestamp('trending'), isNull);

        final mockList = [
          const TechNews(
            id: 1,
            title: 'Trending Repo A',
            description: 'Desc A',
            url: 'https://github.com/a/a',
            authorName: 'a',
            authorAvatar: null,
            publishedDate: 'Trending Python',
            readingTimeMinutes: 3,
            tags: ['trending'],
          ),
        ];

        await storage.saveCachedNews('trending', mockList);

        final retrieved = storage.getCachedNews('trending');
        final timestamp = storage.getCachedNewsTimestamp('trending');

        expect(retrieved, isNotNull);
        expect(retrieved!.length, 1);
        expect(retrieved.first.title, 'Trending Repo A');
        expect(timestamp, isNotNull);
        expect(DateTime.now().difference(timestamp!).inSeconds < 5, true);
      },
    );

    test('TechNewsService falls back to persisted storage news when offline and sets offline flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final offlineNews = [
        const TechNews(
          id: 88,
          title: '⭐ persisted/project (500 stars)',
          description: 'Previously cached repo',
          url: 'https://github.com/persisted/project',
          authorName: 'persisted',
          authorAvatar: null,
          publishedDate: 'Trending Go',
          readingTimeMinutes: 3,
          tags: ['trending'],
        ),
      ];
      await storage.saveCachedNews('trending', offlineNews);

      // Create service with a failing client
      final client = MockClient((request) async {
        return http.Response('Rate limit exceeded', 403);
      });

      final service = TechNewsService(client: client, storageService: storage);
      final result = await service.fetchNews(
        tag: 'trending',
        forceRefresh: true,
      );

      expect(result.length, 1);
      expect(result.first.title, '⭐ persisted/project (500 stars)');
      expect(service.isTagCachedOrOffline('trending'), true);
    });

    test('UpdateService backupApkToDownloads handles missing files safely without throwing', () async {
      final result = await UpdateService.backupApkToDownloads(
        versionTag: 'v1.0.3',
      );
      // In unit test environment (not Android or source file not present), should safely return null
      expect(result, isNull);
    });

    test('UpdateService cleanInstalledBackupApk deletes only installed GitPulse APK and preserves user data', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'gitpulse_download_test',
      );
      try {
        final installedApk = File('${tempDir.path}/GitPulse-v1.0.3.apk');
        final newerApk = File('${tempDir.path}/GitPulse-v1.0.4.apk');
        final otherApk = File('${tempDir.path}/OtherApp.apk');
        final userDocument = File('${tempDir.path}/important_document.pdf');
        final userPhoto = File('${tempDir.path}/family_photo.jpg');

        await installedApk.writeAsString('mock apk 1.0.3');
        await newerApk.writeAsString('mock apk 1.0.4');
        await otherApk.writeAsString('mock other apk');
        await userDocument.writeAsString('mock user pdf document');
        await userPhoto.writeAsString('mock user photo');

        final deleted = await UpdateService.cleanInstalledBackupApk(
          currentVersion: '1.0.3',
          customPath: tempDir.path,
        );

        expect(deleted, true);
        // The installed APK must be deleted
        expect(await installedApk.exists(), false);
        // Newer APK (not yet installed) must be preserved
        expect(await newerApk.exists(), true);
        // Other app APK must NEVER be touched
        expect(await otherApk.exists(), true);
        // User personal documents and photos must NEVER be touched
        expect(await userDocument.exists(), true);
        expect(await userPhoto.exists(), true);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('UpdateService cleanInstalledBackupApk cleans GitPulse subfolder and removes empty directory', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'gitpulse_subfolder_test',
      );
      try {
        final subDir = Directory('${tempDir.path}/GitPulse');
        await subDir.create();

        final installedSubApk = File('${subDir.path}/GitPulse-v1.0.3.apk');
        await installedSubApk.writeAsString('mock apk 1.0.3');

        final deleted = await UpdateService.cleanInstalledBackupApk(
          currentVersion: '1.0.3',
          customPath: tempDir.path,
        );

        expect(deleted, true);
        expect(await installedSubApk.exists(), false);
        // The empty GitPulse subfolder should also be deleted
        expect(await subDir.exists(), false);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    testWidgets(
      'LanguageChart renders percentage without KB bytes and aligns in 2-column layout',
      (tester) async {
        final languageCounts = {'Dart': 7000, 'JavaScript': 2000, 'HTML': 1000};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LanguageChart(languageCounts: languageCounts)),
          ),
        );

        // Verify percentages are rendered
        expect(find.textContaining('70.0%'), findsWidgets);
        expect(find.textContaining('20.0%'), findsWidgets);
        expect(find.textContaining('10.0%'), findsWidgets);

        // Verify that KB or MB bytes text is NOT present
        expect(find.textContaining('KB'), findsNothing);
        expect(find.textContaining('MB'), findsNothing);
        expect(find.textContaining('·'), findsNothing);
      },
    );

    test('AppTheme generates distinct, harmonious palettes for dark, amoled, and sakura modes', () {
      final darkTheme = AppTheme.getTheme(AppThemeMode.dark);
      final amoledTheme = AppTheme.getTheme(AppThemeMode.amoled);
      final sakuraTheme = AppTheme.getTheme(AppThemeMode.amoledJapanese);
      final lightTheme = AppTheme.getTheme(AppThemeMode.light);

      // Verify scaffolds backgrounds are transparent for animated background canvas
      expect(darkTheme.scaffoldBackgroundColor, Colors.transparent);
      expect(amoledTheme.scaffoldBackgroundColor, Colors.transparent);
      expect(sakuraTheme.scaffoldBackgroundColor, Colors.transparent);
      expect(lightTheme.scaffoldBackgroundColor, Colors.transparent);

      // Verify theme mode background palette
      AppTheme.currentMode = AppThemeMode.dark;
      expect(AppTheme.background, const Color(0xFF0F172A));
      AppTheme.currentMode = AppThemeMode.amoled;
      expect(AppTheme.background, const Color(0xFF000000));
      AppTheme.currentMode = AppThemeMode.amoledJapanese;
      expect(AppTheme.background, const Color(0xFF000000));
      AppTheme.currentMode = AppThemeMode.light;
      expect(AppTheme.background, const Color(0xFFF8FAFC));
      AppTheme.currentMode = AppThemeMode.dark;

      // Verify distinct primary accents
      expect(darkTheme.primaryColor, const Color(0xFF38BDF8));
      expect(amoledTheme.primaryColor, const Color(0xFF00E5FF));
      expect(sakuraTheme.primaryColor, const Color(0xFFF472B6));
      expect(lightTheme.primaryColor, const Color(0xFF2563EB));

      // Verify card surfaces
      expect(darkTheme.cardTheme.color, const Color(0xFF0B132B));
      expect(amoledTheme.cardTheme.color, const Color(0xFF101012));
      expect(sakuraTheme.cardTheme.color, const Color(0xFF140D13));

      // Verify native system font typography is configured
      expect(darkTheme.textTheme.bodyMedium, isNotNull);
    });

    test('AppLocalizations renders beautiful copy profile and favorite toast messages', () {
      final idLoc = AppLocalizations(AppLanguage.indonesian);
      final enLoc = AppLocalizations(AppLanguage.english);

      expect(idLoc.summaryCopiedToast, contains('Profil berhasil disalin'));
      expect(enLoc.summaryCopiedToast, contains('Profile copied to clipboard'));

      expect(
        idLoc.profileSavedToFavorites('zerabyte88'),
        contains('Profil @zerabyte88 ditambahkan ke favorit!'),
      );
      expect(
        enLoc.profileSavedToFavorites('zerabyte88'),
        contains('Profile @zerabyte88 added to favorites!'),
      );
    });

    test('Typography and Developer Avatar assets conform to updater standards', () {
      for (final lang in AppLanguage.values) {
        final loc = AppLocalizations(lang);
        // Exclamation mark must not be present in updateAvailable string
        expect(
          loc.updateAvailable.contains('!'),
          isFalse,
          reason:
              'Language ${lang.code} should not have an exclamation mark in updateAvailable',
        );
      }

      // Indonesian language has both nativeName and English name for grid consistency
      expect(AppLanguage.indonesian.nativeName, 'Bahasa Indonesia');
      expect(AppLanguage.indonesian.name, 'Indonesian');

      // Developer avatar URL points to avatars.githubusercontent.com for reliable CDN delivery
      expect(
        AppConfig.developerAvatarUrl,
        'https://avatars.githubusercontent.com/zerabyte88',
      );
    });

    test('TechNews.sanitizeImageUrl unwraps Dev.to proxy URLs to direct AWS S3 URLs', () {
      const proxyUrl =
          'https://media2.dev.to/dynamic/image/width=1000,fit=scale/https%3A%2F%2Fdev-to-uploads.s3.us-east-2.amazonaws.com%2Fuploads%2Farticles%2Fsample.png';
      final sanitized = TechNews.sanitizeImageUrl(proxyUrl);
      expect(
        sanitized,
        'https://dev-to-uploads.s3.us-east-2.amazonaws.com/uploads/articles/sample.png',
      );

      const regularUrl = 'https://example.com/image.jpg';
      expect(
        TechNews.sanitizeImageUrl(regularUrl),
        'https://example.com/image.jpg',
      );

      expect(TechNews.sanitizeImageUrl(null), isNull);
      expect(TechNews.sanitizeImageUrl(''), isNull);
    });

    testWidgets(
      'AnimatedAppHeader renders terminal icon, GitPulse title, and version badge',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                flexibleSpace: const AnimatedHeaderBackground(),
                title: const AnimatedAppHeader(),
              ),
            ),
          ),
        );

        // Verify GitPulse logo, background, title, and version are rendered
        expect(find.byType(GitPulseLogo), findsOneWidget);
        final imageFinder = find.descendant(
          of: find.byType(GitPulseLogo),
          matching: find.byType(Image),
        );
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Image>(imageFinder);
        expect(
          (imageWidget.image as AssetImage).assetName,
          'assets/icons/app_icon.png',
        );
        expect(find.byType(AnimatedHeaderBackground), findsOneWidget);
        expect(find.text('GitPulse'), findsOneWidget);
        expect(find.text(AppConfig.appVersion), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AnimatedAppHeader),
            matching: find.byType(GestureDetector),
          ),
          findsNothing,
        );

        // Test theme mode toggling
        await AppThemeService.changeTheme(AppThemeMode.amoledJapanese, storage);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('GitPulse'), findsOneWidget);

        await AppThemeService.changeTheme(AppThemeMode.amoled, storage);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('GitPulse'), findsOneWidget);

        await AppThemeService.changeTheme(AppThemeMode.light, storage);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('GitPulse'), findsOneWidget);
      },
    );

    testWidgets(
      'StatCard renders long English and multi-language contribution titles without truncation',
      (tester) async {
        final currentYear = DateTime.now().year;

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final lang in [
          AppLanguage.english,
          AppLanguage.indonesian,
          AppLanguage.japanese,
        ]) {
          final loc = AppLocalizations(lang);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatCard(
                            label:
                                '${loc.thisYearContributions} ($currentYear)',
                            value: '370',
                            icon: Icons.calendar_today_rounded,
                            accentColor: Colors.cyan,
                            subtitle: loc.thisYearSubtitle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            label: loc.allYearsContributions,
                            value: '371',
                            icon: Icons.all_inclusive_rounded,
                            accentColor: Colors.purple,
                            subtitle: loc.allTimeSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          final leftLabelFinder = find.text(
            '${loc.thisYearContributions} ($currentYear)',
          );
          final rightLabelFinder = find.text(loc.allYearsContributions);
          expect(leftLabelFinder, findsOneWidget);
          expect(rightLabelFinder, findsOneWidget);

          // Verify that neither label exceeded maxLines (i.e. did not truncate with ellipsis)
          final leftParagraph = tester.renderObject<RenderParagraph>(
            leftLabelFinder,
          );
          final rightParagraph = tester.renderObject<RenderParagraph>(
            rightLabelFinder,
          );
          expect(
            leftParagraph.didExceedMaxLines,
            isFalse,
            reason: 'Left card label for ${lang.code} should not be truncated',
          );
          expect(
            rightParagraph.didExceedMaxLines,
            isFalse,
            reason: 'Right card label for ${lang.code} should not be truncated',
          );
        }
      },
    );

    testWidgets(
      'RepoTile renders repo details, link icon, and handles tap to open',
      (tester) async {
        final repo = GitHubRepo(
          name: 'flutter_gitpulse',
          description: 'Developer telemetry mobile app',
          htmlUrl: 'https://github.com/zerabyte88/flutter_gitpulse',
          language: 'Dart',
          stargazersCount: 42,
          forksCount: 7,
          isFork: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RepoTile(repo: repo)),
          ),
        );

        expect(find.text('flutter_gitpulse'), findsOneWidget);
        expect(find.text('Dart'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);

        await tester.tap(find.byType(RepoTile));
        await tester.pump();
      },
    );

    test('GitHubRepo parses extended fields, owner, and formattedSize', () {
      final json = {
        'name': 'gitpulse_mobile',
        'description': 'Mobile telemetry',
        'html_url': 'https://github.com/zerabyte88/gitpulse_mobile',
        'language': 'Dart',
        'stargazers_count': 100,
        'forks_count': 15,
        'fork': false,
        'size': 2048,
        'default_branch': 'main',
        'open_issues_count': 3,
        'topics': ['flutter', 'github', 'dart'],
        'license': {'spdx_id': 'MIT', 'name': 'MIT License'},
      };

      final repo = GitHubRepo.fromJson(json);
      expect(repo.name, 'gitpulse_mobile');
      expect(repo.owner, 'zerabyte88');
      expect(repo.defaultBranch, 'main');
      expect(repo.openIssuesCount, 3);
      expect(repo.topics, contains('flutter'));
      expect(repo.license, 'MIT');
      expect(repo.formattedSize, '2.0 MB');
    });

    test('GitHubApiService fetchRepositoryReadme decodes base64 markdown and handles 404', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/repos/testowner/testrepo/readme') {
          const readmeMarkdown = '# Hello GitPulse\nThis is a test readme.';
          final base64Content = base64Encode(utf8.encode(readmeMarkdown));
          return http.Response(
            jsonEncode({
              'name': 'README.md',
              'encoding': 'base64',
              'content': base64Content,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = GitHubApiService(client: mockClient);
      final readme = await api.fetchRepositoryReadme(
        owner: 'testowner',
        repo: 'testrepo',
      );
      expect(readme, contains('# Hello GitPulse'));
      expect(readme, contains('This is a test readme.'));

      final missing = await api.fetchRepositoryReadme(
        owner: 'testowner',
        repo: 'unknown',
      );
      expect(missing, isNull);
    });

    testWidgets(
      'RepoDetailScreen displays repository details and markdown README',
      (tester) async {
        final repo = GitHubRepo(
          name: 'flutter_gitpulse',
          description: 'Developer telemetry mobile app',
          htmlUrl: 'https://github.com/zerabyte88/flutter_gitpulse',
          language: 'Dart',
          stargazersCount: 42,
          forksCount: 7,
          isFork: false,
          topics: ['flutter', 'mobile'],
          defaultBranch: 'main',
          license: 'MIT',
        );

        final mockClient = MockClient((request) async {
          final content = base64Encode(
            utf8.encode('### Welcome to GitPulse\n- Fast\n- Beautiful'),
          );
          return http.Response(
            jsonEncode({
              'name': 'README.md',
              'encoding': 'base64',
              'content': content,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiService = GitHubApiService(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: RepoDetailScreen(
              repo: repo,
              username: 'zerabyte88',
              apiService: apiService,
            ),
          ),
        );

        expect(find.text('flutter_gitpulse'), findsAtLeastNWidgets(1));
        expect(find.text('zerabyte88'), findsAtLeastNWidgets(1));
        expect(find.text('Developer telemetry mobile app'), findsOneWidget);
        expect(find.text('flutter'), findsOneWidget);
        expect(find.text('mobile'), findsOneWidget);
        expect(find.text('MIT'), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.byType(MarkdownBody), findsOneWidget);
        expect(find.textContaining('Welcome to GitPulse'), findsOneWidget);
      },
    );

    test('GitHubContentItem parses directory and file correctly', () {
      final dirJson = {
        'name': 'lib',
        'path': 'lib',
        'sha': '123456',
        'size': 0,
        'type': 'dir',
        'html_url': 'https://github.com/zerabyte88/gitpulse/tree/main/lib',
      };
      final dirItem = GitHubContentItem.fromJson(dirJson);
      expect(dirItem.name, 'lib');
      expect(dirItem.isDirectory, true);
      expect(dirItem.formattedSize, '');

      final fileJson = {
        'name': 'main.dart',
        'path': 'lib/main.dart',
        'sha': '789012',
        'size': 2048,
        'type': 'file',
        'download_url': 'https://raw.githubusercontent.com/.../main.dart',
        'html_url':
            'https://github.com/zerabyte88/gitpulse/blob/main/lib/main.dart',
      };
      final fileItem = GitHubContentItem.fromJson(fileJson);
      expect(fileItem.name, 'main.dart');
      expect(fileItem.isDirectory, false);
      expect(fileItem.formattedSize, '2.0 KB');
      expect(fileItem.isImage, false);

      final imgJson = {
        'name': 'logo.png',
        'path': 'assets/logo.png',
        'sha': 'abcde',
        'size': 512,
        'type': 'file',
      };
      final imgItem = GitHubContentItem.fromJson(imgJson);
      expect(imgItem.isImage, true);
    });

    test('GitHubApiService fetchRepositoryContents and fetchFileContent work correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/contents/lib/main.dart')) {
          final content = base64Encode(
            utf8.encode('void main() { runApp(MyApp()); }'),
          );
          return http.Response(
            jsonEncode({
              'name': 'main.dart',
              'encoding': 'base64',
              'content': content,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.endsWith('/contents/lib')) {
          return http.Response(
            jsonEncode([
              {
                'name': 'main.dart',
                'path': 'lib/main.dart',
                'type': 'file',
                'size': 1200,
              },
              {
                'name': 'screens',
                'path': 'lib/screens',
                'type': 'dir',
                'size': 0,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = GitHubApiService(client: mockClient);
      final items = await service.fetchRepositoryContents(
        owner: 'zerabyte88',
        repo: 'gitpulse',
        path: 'lib',
      );

      // Verify directories sorted first
      expect(items.length, 2);
      expect(items.first.name, 'screens');
      expect(items.first.isDirectory, true);
      expect(items.last.name, 'main.dart');
      expect(items.last.isDirectory, false);

      final fileContent = await service.fetchFileContent(
        owner: 'zerabyte88',
        repo: 'gitpulse',
        path: 'lib/main.dart',
      );
      expect(fileContent, contains('void main()'));
    });

    testWidgets('FileViewerScreen renders code and lines correctly', (
      WidgetTester tester,
    ) async {
      final item = GitHubContentItem(
        name: 'sample.dart',
        path: 'lib/sample.dart',
        sha: 'abc',
        size: 50,
        type: 'file',
        downloadUrl: 'https://example.com/sample.dart',
        htmlUrl: 'https://github.com/sample.dart',
      );

      final mockClient = MockClient((request) async {
        return http.Response('line 1\nline 2\nline 3', 200);
      });

      final apiService = GitHubApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: FileViewerScreen(
            item: item,
            repo: 'gitpulse',
            owner: 'zerabyte88',
            apiService: apiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('sample.dart'), findsOneWidget);
      expect(find.text('lib/sample.dart'), findsOneWidget);
      expect(find.textContaining('3 lines'), findsOneWidget);
      expect(find.textContaining('line 1'), findsOneWidget);
    });

    testWidgets('RepoDetailScreen tab switching renders files explorer', (
      WidgetTester tester,
    ) async {
      final repo = GitHubRepo(
        name: 'flutter_gitpulse',
        description: 'Developer telemetry mobile app',
        htmlUrl: 'https://github.com/zerabyte88/flutter_gitpulse',
        language: 'Dart',
        stargazersCount: 128,
        forksCount: 34,
        openIssuesCount: 3,
        isFork: false,
        topics: ['flutter', 'mobile'],
        defaultBranch: 'main',
        license: 'MIT',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/readme')) {
          return http.Response(
            jsonEncode({
              'name': 'README.md',
              'encoding': 'base64',
              'content': base64Encode(utf8.encode('# Readme Title')),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/contents')) {
          return http.Response(
            jsonEncode([
              {'name': 'lib', 'path': 'lib', 'type': 'dir', 'size': 0},
              {
                'name': 'pubspec.yaml',
                'path': 'pubspec.yaml',
                'type': 'file',
                'size': 500,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = GitHubApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: RepoDetailScreen(
            repo: repo,
            username: 'zerabyte88',
            apiService: apiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // README tab is default
      expect(find.text('README.md'), findsAtLeastNWidgets(1));

      // Tap Files tab
      final filesTabFinder = find.text('Files');
      expect(filesTabFinder, findsOneWidget);
      await tester.tap(filesTabFinder);
      await tester.pumpAndSettle();

      // Should show directory contents
      expect(find.text('lib'), findsOneWidget);
      expect(find.text('pubspec.yaml'), findsOneWidget);
    });

    testWidgets(
      'FavoriteProfilesScreen renders grid with 1 to 4 columns and displays user details',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        await storage.toggleBookmark(
          'zerabyte88',
          name: 'Zerabyte Dev',
          bio: 'Mobile & Cloud Engineer',
          location: 'Jakarta, Indonesia',
        );

        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({}), 200);
        });
        final apiService = GitHubApiService(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FavoriteProfilesScreen(
              storageService: storage,
              apiService: apiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check header and user details
        expect(find.text('Profil Favorit'), findsOneWidget);
        expect(find.text('Zerabyte Dev'), findsOneWidget);
        expect(find.text('Jakarta, Indonesia'), findsOneWidget);

        // Check column control buttons 1 and 2 via ValueKey
        expect(find.byKey(const ValueKey('col_btn_1')), findsOneWidget);
        expect(find.byKey(const ValueKey('col_btn_2')), findsOneWidget);
        expect(find.byKey(const ValueKey('col_btn_3')), findsNothing);
        expect(find.byKey(const ValueKey('col_btn_4')), findsNothing);

        // Tap 1 column
        await tester.tap(find.byKey(const ValueKey('col_btn_1')));
        await tester.pumpAndSettle();
        expect(storage.getFavoriteGridColumns(), 1);

        // Tap 2 column
        await tester.tap(find.byKey(const ValueKey('col_btn_2')));
        await tester.pumpAndSettle();
        expect(storage.getFavoriteGridColumns(), 2);
      },
    );

    testWidgets(
      'FavoriteProfilesScreen renders Favorite Profile in English without truncation',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        final mockClient = MockClient(
          (request) async => http.Response('{}', 200),
        );
        final apiService = GitHubApiService(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FavoriteProfilesScreen(
              storageService: storage,
              apiService: apiService,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Favorite Profile'), findsWidgets);
      },
    );

    testWidgets(
      'RunningText renders static text when content fits constraints',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: RunningText(text: 'Short Repo', autoScroll: true),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Short Repo'), findsOneWidget);
      },
    );

    testWidgets(
      'RunningText renders scrollable text for long text in manual mode',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                child: RunningText(
                  text: 'very_long_repository_name_that_exceeds_screen_width_significantly',
                  autoScroll: false,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(
          find.text(
            'very_long_repository_name_that_exceeds_screen_width_significantly',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SettingsSheet can be dismissed by swiping down from top to bottom',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        AppLanguageService.init(storage);
        AppThemeService.init(storage);
        final client = MockClient((request) async => http.Response('{}', 200));
        final api = GitHubApiService(client: client);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLanguage.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SettingsSheet.show(
                    context,
                    storageService: storage,
                    apiService: api,
                  ),
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSheet), findsOneWidget);

        // Drag down from top area
        await tester.drag(find.byType(SettingsSheet), const Offset(0, 400));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSheet), findsNothing);
      },
    );

    testWidgets('SettingsSheet can be closed using the X button', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      AppLanguageService.init(storage);
      AppThemeService.init(storage);
      final client = MockClient((request) async => http.Response('{}', 200));
      final api = GitHubApiService(client: client);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SettingsSheet.show(
                  context,
                  storageService: storage,
                  apiService: api,
                ),
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsSheet), findsOneWidget);

      // Verify the close button exists and tap it
      final closeButtonFinder = find.byIcon(Icons.close_rounded);
      expect(closeButtonFinder, findsOneWidget);
      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsSheet), findsNothing);
    });

    testWidgets(
      'SettingsSheet dragging down from top drag indicator dismisses sheet',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        AppLanguageService.init(storage);
        AppThemeService.init(storage);
        final client = MockClient((request) async => http.Response('{}', 200));
        final api = GitHubApiService(client: client);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLanguage.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SettingsSheet.show(
                    context,
                    storageService: storage,
                    apiService: api,
                  ),
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSheet), findsOneWidget);

        // Find top of SettingsSheet and drag down from near the top
        final sheetTopLeft = tester.getTopLeft(find.byType(SettingsSheet));
        await tester.dragFrom(
          sheetTopLeft + const Offset(100, 20),
          const Offset(0, 350),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSheet), findsNothing);
      },
    );

    testWidgets(
      'HomeScreen news section allows tapping category chips and switches category',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        AppLanguageService.init(storage);
        AppThemeService.init(storage);
        final client = MockClient((request) async {
          if (request.url.path.contains('rate_limit')) {
            return http.Response(
              jsonEncode({
                'resources': {
                  'core': {'limit': 60, 'remaining': 59, 'reset': 0, 'used': 1},
                },
              }),
              200,
            );
          }
          return http.Response('[]', 200);
        });
        final api = GitHubApiService(client: client);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLanguage.supportedLocales,
            home: HomeScreen(storageService: storage, apiService: api),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initially trending category is active
        expect(find.byKey(const ValueKey('trending')), findsOneWidget);

        // Tap on GitHub category tab (label is 'GitHub Digest')
        final githubTab = find.text('GitHub Digest');
        expect(githubTab, findsOneWidget);
        await tester.tap(githubTab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Category switches to github
        expect(find.byKey(const ValueKey('github')), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen news section allows swiping left and right to switch categories',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        AppLanguageService.init(storage);
        AppThemeService.init(storage);
        final client = MockClient((request) async {
          if (request.url.path.contains('rate_limit')) {
            return http.Response(
              jsonEncode({
                'resources': {
                  'core': {'limit': 60, 'remaining': 59, 'reset': 0, 'used': 1},
                },
              }),
              200,
            );
          }
          return http.Response('[]', 200);
        });
        final api = GitHubApiService(client: client);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLanguage.supportedLocales,
            home: HomeScreen(storageService: storage, apiService: api),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initially trending category is active
        expect(find.byKey(const ValueKey('trending')), findsOneWidget);

        // Swipe left on the news content area with velocity
        await tester.fling(
          find.byKey(const ValueKey('trending')),
          const Offset(-400, 0),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Category should switch to github
        expect(find.byKey(const ValueKey('github')), findsOneWidget);

        // Swipe right on the news content area with velocity
        await tester.fling(
          find.byKey(const ValueKey('github')),
          const Offset(400, 0),
          1000,
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Category should switch back to trending
        expect(find.byKey(const ValueKey('trending')), findsOneWidget);
      },
    );
  });

  group('AnimatedAppBackground Tests', () {
    Future<void> pumpBackground(WidgetTester tester, AppThemeMode mode) async {
      AppTheme.currentMode = mode;
      AppThemeService.currentThemeNotifier.value = mode;
      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedAppBackground(child: Scaffold(body: Container())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders without error in AMOLED Sakura mode', (tester) async {
      await pumpBackground(tester, AppThemeMode.amoledJapanese);
      expect(find.byType(AnimatedAppBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders without error in Midnight mode', (tester) async {
      await pumpBackground(tester, AppThemeMode.amoled);
      expect(find.byType(AnimatedAppBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders without error in Snowfall mode', (tester) async {
      await pumpBackground(tester, AppThemeMode.dark);
      expect(find.byType(AnimatedAppBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders without error in Light mode', (tester) async {
      await pumpBackground(tester, AppThemeMode.light);
      expect(find.byType(AnimatedAppBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Surface Opacity & Glassmorphism Tests', () {
    test(
      'StorageService persists and clamps surface opacity correctly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);

        // Default is 1.0 (100% Solid / 60 FPS Shader Bypass)
        expect(storage.getSurfaceOpacity(), 1.0);

        // Set valid opacity
        await storage.setSurfaceOpacity(0.65);
        expect(storage.getSurfaceOpacity(), 0.65);

        // Clamp low (min 0.50)
        await storage.setSurfaceOpacity(0.30);
        expect(storage.getSurfaceOpacity(), 0.50);

        // Clamp high (max 1.00)
        await storage.setSurfaceOpacity(1.20);
        expect(storage.getSurfaceOpacity(), 1.00);
      },
    );

    test(
      'AppThemeService updates surface opacity notifier and saves to storage',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        expect(AppThemeService.surfaceOpacity, 1.0);

        await AppThemeService.changeSurfaceOpacity(0.70, storage);
        expect(AppThemeService.surfaceOpacity, 0.70);
        expect(storage.getSurfaceOpacity(), 0.70);
      },
    );

    testWidgets(
      'GlassCard uses pure alpha color transparency and never spawns BackdropFilter',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassCard(
                enableBlur: true,
                child: const Text('Glass Test Content'),
              ),
            ),
          ),
        );

        // Default opacity is 1.00 -> pure surface color, no BackdropFilter
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('Glass Test Content'), findsOneWidget);

        // Change opacity to 0.85 -> uses pure alpha color blending, zero BackdropFilter
        await AppThemeService.changeSurfaceOpacity(0.85, storage);
        await tester.pump();
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('Glass Test Content'), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsSheet displays surface opacity slider and percentage badge',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: SettingsSheet(
                storageService: storage,
                apiService: GitHubApiService(),
              ),
            ),
          ),
        );

        // Verify opacity slider and badge render (default 100%)
        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);

        // Drag/change slider
        final slider = find.byType(Slider);
        await tester.tap(slider);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'GlassCard respects enableBlur: false and bypasses BackdropFilter even when translucent',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        // Pastikan opacity < 1.0 (translucent)
        await AppThemeService.changeSurfaceOpacity(0.85, storage);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GlassCard(
                enableBlur: false,
                child: Text('Performance List Item'),
              ),
            ),
          ),
        );

        await tester.pump();
        // BackdropFilter harus dilewati (0 widget) demi performa 60/120fps
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('Performance List Item'), findsOneWidget);
      },
    );

    testWidgets(
      'AnimatedAppBackground continues rendering smoothly during scroll and idle',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedAppBackground(
                child: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Item 0'), findsOneWidget);

        // Scroll list
        await tester.fling(find.byType(ListView), const Offset(0, -300), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AnimatedAppBackground), findsOneWidget);
      },
    );

    test('StorageService persists and retrieves background animation enabled state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      // Default is true
      expect(storage.isBackgroundAnimationEnabled(), isTrue);

      // Save false
      await storage.setBackgroundAnimationEnabled(false);
      expect(storage.isBackgroundAnimationEnabled(), isFalse);

      // Save true again
      await storage.setBackgroundAnimationEnabled(true);
      expect(storage.isBackgroundAnimationEnabled(), isTrue);
    });

    test('AppThemeService toggles background animation and pauses HeaderAnimationState', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      AppThemeService.init(storage);
      expect(AppThemeService.bgAnimationEnabledNotifier.value, isTrue);
      expect(HeaderAnimationState.isPausedNotifier.value, isFalse);

      // Disable background animation
      AppThemeService.setBackgroundAnimation(false, storage);
      expect(AppThemeService.bgAnimationEnabledNotifier.value, isFalse);
      expect(HeaderAnimationState.isPausedNotifier.value, isTrue);
      expect(storage.isBackgroundAnimationEnabled(), isFalse);

      // Re-enable
      AppThemeService.setBackgroundAnimation(true, storage);
      expect(AppThemeService.bgAnimationEnabledNotifier.value, isTrue);
      expect(HeaderAnimationState.isPausedNotifier.value, isFalse);
      expect(storage.isBackgroundAnimationEnabled(), isTrue);
    });

    testWidgets(
      'SettingsSheet renders background animation switch and responds to toggle',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppThemeService.init(storage);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLanguage.supportedLocales,
            home: Scaffold(
              body: SettingsSheet(
                storageService: storage,
                apiService: GitHubApiService(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find switch
        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);

        // Toggle switch off
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(AppThemeService.bgAnimationEnabledNotifier.value, isFalse);
        expect(HeaderAnimationState.isPausedNotifier.value, isTrue);
        expect(storage.isBackgroundAnimationEnabled(), isFalse);
      },
    );
  });

  group('HTTP Cache, ETag (304), & Manual Reload Tests', () {
    test('StorageService persists and validates HTTP cache and ETag headers correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      expect(storage.isHttpCacheValid('user_octocat'), isFalse);
      expect(storage.getHttpCacheEtag('user_octocat'), isNull);

      await storage.saveHttpCache(
        key: 'user_octocat',
        body: '{"login":"octocat","id":1}',
        etag: 'W/"12345"',
      );

      expect(storage.isHttpCacheValid('user_octocat'), isTrue);
      expect(
        storage.getHttpCacheBody('user_octocat'),
        '{"login":"octocat","id":1}',
      );
      expect(storage.getHttpCacheEtag('user_octocat'), 'W/"12345"');
      expect(storage.getHttpCacheTimestamp('user_octocat'), isNotNull);

      // Updating timestamp
      await storage.updateHttpCacheTimestamp('user_octocat');
      expect(storage.isHttpCacheValid('user_octocat'), isTrue);

      // Clearing cache
      await storage.clearHttpCache('user_octocat');
      expect(storage.isHttpCacheValid('user_octocat'), isFalse);
      expect(storage.getHttpCacheBody('user_octocat'), isNull);
      expect(storage.getHttpCacheEtag('user_octocat'), isNull);
    });

    test('GitHubApiService uses 10-minute cache without executing HTTP requests when fresh', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (request.url.path.contains('/users/octocat/repos')) {
          return http.Response('[]', 200, headers: {'etag': 'W/"repos1"'});
        } else if (request.url.path.contains('/users/octocat/events')) {
          return http.Response('[]', 200, headers: {'etag': 'W/"events1"'});
        } else if (request.url.path.contains('/users/octocat')) {
          return http.Response(
            '{"login":"octocat","id":1,"avatar_url":"","html_url":"","public_repos":0,"followers":0,"following":0}',
            200,
            headers: {'etag': 'W/"user1"'},
          );
        }
        return http.Response('{}', 200);
      });

      final api = GitHubApiService(client: client, storageService: storage);

      // First call -> network request
      final stats1 = await api.fetchUserStats('octocat');
      expect(stats1.user.login, 'octocat');
      expect(requestCount, greaterThan(0));

      final countAfterFirst = requestCount;

      // Second call within 10 minutes -> served from cache, zero network calls!
      final stats2 = await api.fetchUserStats('octocat');
      expect(stats2.user.login, 'octocat');
      expect(requestCount, countAfterFirst); // No new requests!
    });

    test('GitHubApiService sends If-None-Match header and handles 304 Not Modified correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      // Pre-seed storage with initial data and ETags
      await storage.saveHttpCache(
        key: 'user_octocat',
        body: '{"login":"octocat","id":1,"avatar_url":"","html_url":"","public_repos":5,"followers":10,"following":2}',
        etag: 'W/"user_etag_1"',
      );
      await storage.saveHttpCache(
        key: 'repos_octocat',
        body: '[{"name":"Hello-World","html_url":"https://github.com/octocat/Hello-World","stargazers_count":10,"forks_count":2,"fork":false,"size":100}]',
        etag: 'W/"repos_etag_1"',
      );
      await storage.saveHttpCache(
        key: 'events_octocat',
        body: '[]',
        etag: 'W/"events_etag_1"',
      );
      await storage.saveHttpCache(
        key: 'languages_octocat',
        body: '{"Dart": 1000}',
      );

      final capturedHeaders = <String, String>{};
      final client = MockClient((request) async {
        capturedHeaders[request.url.path] =
            request.headers['If-None-Match'] ?? '';
        return http.Response('', 304);
      });

      final api = GitHubApiService(client: client, storageService: storage);

      // Force refresh -> sends If-None-Match and gracefully reconstructs UserStats from cache
      final stats = await api.fetchUserStats('octocat', forceRefresh: true);
      expect(stats.user.login, 'octocat');
      expect(stats.repos.length, 1);
      expect(stats.repos.first.name, 'Hello-World');
      expect(capturedHeaders['/users/octocat'], 'W/"user_etag_1"');
      expect(capturedHeaders['/users/octocat/repos'], 'W/"repos_etag_1"');
      expect(
        capturedHeaders['/users/octocat/events/public'],
        'W/"events_etag_1"',
      );
      expect(api.isLastResponseNotModified, isTrue);
    });

    testWidgets(
      'StatsDetailScreen refresh button triggers profile reload and displays feedback toast',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        AppLanguageService.init(storage);
        AppThemeService.init(storage);

        final user = GitHubUser(
          login: 'octocat',
          id: 1,
          avatarUrl: '',
          htmlUrl: 'https://github.com/octocat',
          publicRepos: 1,
          followers: 10,
          following: 5,
        );
        final repo = GitHubRepo(
          name: 'test-repo',
          htmlUrl: 'https://github.com/octocat/test-repo',
          stargazersCount: 5,
          forksCount: 1,
          isFork: false,
        );
        final stats = UserStats.calculate(
          user: user,
          repos: [repo],
          publicEvents: [],
          contributionStats: ContributionStats(
            commitTitle: ContributionStats.determineTitle(
              currentStreak: 1,
              longestStreak: 5,
              thisYearContributions: 10,
              totalContributions: 50,
            ),
            currentStreak: 1,
            longestStreak: 5,
            thisYearContributions: 10,
            lastYearContributions: 5,
            totalContributions: 50,
            yearlyTotals: const {'2025': 5, '2026': 10},
          ),
        );

        int refreshCalled = 0;
        final client = MockClient((request) async {
          refreshCalled++;
          if (request.url.path.contains('/users/octocat/repos')) {
            return http.Response('[]', 200);
          } else if (request.url.path.contains('/users/octocat/events')) {
            return http.Response('[]', 200);
          } else if (request.url.path.contains('/users/octocat')) {
            return http.Response(
              '{"login":"octocat","id":1,"avatar_url":"","html_url":"","public_repos":2,"followers":12,"following":5}',
              200,
            );
          }
          return http.Response('{}', 200);
        });

        final api = GitHubApiService(client: client, storageService: storage);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLanguage.supportedLocales,
            home: StatsDetailScreen(
              stats: stats,
              storageService: storage,
              apiService: api,
            ),
          ),
        );

        await tester.pump();
        expect(find.widgetWithText(AppBar, '@octocat'), findsOneWidget);

        // Verify refresh button exists in AppBar actions
        final refreshBtn = find.byIcon(Icons.refresh_rounded);
        expect(refreshBtn, findsOneWidget);

        // Tap refresh button
        await tester.tap(refreshBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(refreshCalled, greaterThan(0));

        // Verify pull-to-refresh widget is mounted
        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'GitPulsePageTransitionsBuilder executes smooth slide and fade transitions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: GitPulsePageTransitionsBuilder(),
                },
              ),
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) =>
                            const Scaffold(body: Text('Destination Screen')),
                      ),
                    );
                  },
                  child: const Text('Go to Destination'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Go to Destination'), findsOneWidget);

        await tester.tap(find.text('Go to Destination'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byType(SlideTransition), findsWidgets);
        expect(find.byType(FadeTransition), findsWidgets);

        await tester.pumpAndSettle();
        expect(find.text('Destination Screen'), findsOneWidget);

        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        expect(find.text('Go to Destination'), findsOneWidget);
      },
    );
  });
}
