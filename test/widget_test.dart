import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitpulse_mobile/localization/app_language.dart';
import 'package:gitpulse_mobile/localization/app_localizations.dart';
import 'package:gitpulse_mobile/models/bookmarked_user.dart';
import 'package:gitpulse_mobile/models/contribution_stats.dart';
import 'package:gitpulse_mobile/models/github_rate_limit.dart';
import 'package:gitpulse_mobile/models/github_repo.dart';
import 'package:gitpulse_mobile/models/github_user.dart';
import 'package:gitpulse_mobile/models/tech_news.dart';
import 'package:gitpulse_mobile/models/user_stats.dart';
import 'package:gitpulse_mobile/screens/stats_detail_screen.dart';
import 'package:gitpulse_mobile/services/storage_service.dart';
import 'package:gitpulse_mobile/services/app_theme_service.dart';
import 'package:gitpulse_mobile/services/tech_news_service.dart';
import 'package:gitpulse_mobile/services/update_service.dart';
import 'package:gitpulse_mobile/theme/app_theme.dart';
import 'package:flutter/rendering.dart';
import 'package:gitpulse_mobile/widgets/animated_app_header.dart';
import 'package:gitpulse_mobile/widgets/animated_tier_title.dart';
import 'package:gitpulse_mobile/widgets/language_chart.dart';
import 'package:gitpulse_mobile/widgets/stat_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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
      // 1. Sangat Rajin Ekstrem (Mythic)
      final mythic = ContributionStats.determineTitle(
        currentStreak: 15,
        longestStreak: 35,
        thisYearContributions: 400,
        totalContributions: 600,
      );
      expect(mythic.title, contains('Code Titan'));
      expect(mythic.levelName, contains('Sangat Rajin'));

      // 2. Sangat Rajin (Diamond)
      final diamond = ContributionStats.determineTitle(
        currentStreak: 6,
        longestStreak: 15,
        thisYearContributions: 120,
        totalContributions: 200,
      );
      expect(diamond.title, contains('Relentless Committer'));
      expect(diamond.levelName, contains('Sangat Rajin'));

      // 3. Rajin & Stabil (Platinum)
      final platinum = ContributionStats.determineTitle(
        currentStreak: 3,
        longestStreak: 8,
        thisYearContributions: 45,
        totalContributions: 60,
      );
      expect(platinum.title, contains('Consistent Builder'));

      // 4. Terkadang Commit (Gold)
      final gold = ContributionStats.determineTitle(
        currentStreak: 1,
        longestStreak: 3,
        thisYearContributions: 15,
        totalContributions: 30,
      );
      expect(gold.title, contains('Weekend Warrior'));
      expect(gold.levelName, contains('Commit Terkadang'));

      // 5. Jarang Commit (Silver)
      final silver = ContributionStats.determineTitle(
        currentStreak: 0,
        longestStreak: 1,
        thisYearContributions: 3,
        totalContributions: 5,
      );
      expect(silver.title, contains('Dormant Explorer'));
      expect(silver.levelName, contains('Jarang Commit'));

      // 6. Belum Aktif (Bronze)
      final bronze = ContributionStats.determineTitle(
        currentStreak: 0,
        longestStreak: 0,
        thisYearContributions: 0,
        totalContributions: 0,
      );
      expect(bronze.title, contains('Fresh Sprout'));
      expect(bronze.levelName, contains('Belum Aktif'));
    });

    test('ContributionStats calculates active and longest streaks accurately across dates', () {
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      final yesterday = DateTime.utc(now.year, now.month, now.day - 1);
      final twoDaysAgo = DateTime.utc(now.year, now.month, now.day - 2);
      final threeDaysAgo = DateTime.utc(now.year, now.month, now.day - 3);

      // Scenario 1: Active streak including today (today and yesterday consecutive, gap on twoDaysAgo)
      final counts = {
        today: 5,
        yesterday: 2,
        twoDaysAgo: 0,
        threeDaysAgo: 10,
      };
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
      final streaksYesterday = ContributionStats.calculateStreaks(countsYesterday);
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
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yest = now.subtract(const Duration(days: 1));
      final yestStr = '${yest.year}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';

      final mockApi = {
        'total': {
          '${now.year}': 15,
          '${now.year - 1}': 50,
        },
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

    test('BookmarkedUser parses correctly and provides avatar fallback', () {
      final userWithAvatar = BookmarkedUser.fromJson({
        'username': 'octocat',
        'avatar_url': 'https://avatars.githubusercontent.com/u/583231',
      });
      expect(userWithAvatar.username, 'octocat');
      expect(userWithAvatar.avatarUrl, 'https://avatars.githubusercontent.com/u/583231');

      final userDefault = BookmarkedUser.fromJson({
        'username': 'torvalds',
      });
      expect(userDefault.username, 'torvalds');
      expect(userDefault.avatarUrl, 'https://github.com/torvalds.png');
    });

    test('StorageService persists bookmarks with avatar and manages recent searches', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      // Add bookmark with custom avatar
      await storage.toggleBookmark('linus', avatarUrl: 'https://avatars.githubusercontent.com/linus');
      expect(storage.isBookmarked('linus'), true);

      final bookmarks = storage.getBookmarkedUsers();
      expect(bookmarks.length, 1);
      expect(bookmarks.first.username, 'linus');
      expect(bookmarks.first.avatarUrl, 'https://avatars.githubusercontent.com/linus');

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

    test('GitHubRateLimit metrics and percentage calculations behave as expected', () {
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
        }
      };
      final fromJson = GitHubRateLimit.fromJson(json);
      expect(fromJson.limit, 60);
      expect(fromJson.remaining, 45);
      expect(fromJson.used, 15);
    });

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

    test('AppLanguage parses and maps all 6 languages accurately', () {
      expect(AppLanguage.fromCode('id'), AppLanguage.indonesian);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('ja'), AppLanguage.japanese);
      expect(AppLanguage.fromCode('zh_Hans'), AppLanguage.chineseSimplified);
      expect(AppLanguage.fromCode('zh_CN'), AppLanguage.chineseSimplified);
      expect(AppLanguage.fromCode('zh_Hant'), AppLanguage.chineseTraditional);
      expect(AppLanguage.fromCode('zh_TW'), AppLanguage.chineseTraditional);
      expect(AppLanguage.fromCode('ko'), AppLanguage.korean);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.indonesian);

      expect(AppLanguage.values.length, 6);
      for (final lang in AppLanguage.values) {
        expect(lang.code, isNotEmpty);
        expect(lang.name, isNotEmpty);
        expect(lang.nativeName, isNotEmpty);
        expect(lang.flag, isNotEmpty);
      }
    });

    test('AppLocalizations renders expected translations for all 6 languages', () {
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

      // Theme options (Gelap, AMOLED, Terang, AMOLED Sakura)
      expect(idLoc.themeDark, 'Gelap');
      expect(idLoc.themeAmoled, 'AMOLED');
      expect(idLoc.themeLight, 'Terang');
      expect(idLoc.themeAmoledJapanese, 'AMOLED Sakura');
      expect(enLoc.themeDark, 'Dark');
      expect(enLoc.themeAmoled, 'AMOLED');
      expect(enLoc.themeLight, 'Light');
      expect(enLoc.themeAmoledJapanese, 'AMOLED Sakura');

      // Filter labels
      expect(idLoc.filterPopular, 'Terpopuler');
      expect(enLoc.filterPopular, 'Most Popular');
      expect(jaLoc.filterPopular, '人気順');
      expect(zhHansLoc.filterPopular, '最受欢迎');
      expect(zhHantLoc.filterPopular, '最受歡迎');
      expect(koLoc.filterPopular, '인기순');

      // Commit tier clean titles
      expect(idLoc.getCommitTierCleanTitle(1), 'Code Titan');
      expect(jaLoc.getCommitTierCleanTitle(1), 'コードタイタン');
      expect(zhHansLoc.getCommitTierCleanTitle(1), '代码泰坦');
      expect(zhHantLoc.getCommitTierCleanTitle(1), '代碼泰坦');
      expect(koLoc.getCommitTierCleanTitle(1), '코드 타이탄');

      // Relative time formatting
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
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
    });

    test('StorageService persists and retrieves language preference correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      // Default is Indonesian (id)
      expect(storage.getLanguageCode(), 'id');

      // Update to Japanese
      await storage.setLanguageCode('ja');
      expect(storage.getLanguageCode(), 'ja');

      // Update to Korean
      await storage.setLanguageCode('ko');
      expect(storage.getLanguageCode(), 'ko');
    });

    testWidgets('StatsDetailScreen renders user full name clearly without being truncated by title', (tester) async {
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
          home: StatsDetailScreen(
            stats: stats,
            storageService: storage,
          ),
        ),
      );

      // Verify that full name 'Nanda Alexander' is rendered
      expect(find.text('Nanda Alexander'), findsOneWidget);
      expect(find.text('@zerabyte88'), findsAtLeastNWidgets(1));
      expect(find.text('Planet Earth, Solar System'), findsOneWidget);
      expect(find.text('GitPulse Team'), findsOneWidget);

      // Verify that AnimatedTierTitle exists in the commit habit banner
      expect(find.byType(AnimatedTierTitle), findsOneWidget);

      // Verify all years total contributions card is rendered
      expect(find.text('Total Kontribusi (Semua Tahun)'), findsOneWidget);
      expect(find.text('Sepanjang waktu'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });

    test('AppConfig provides accurate release and version telemetry for v1.0.9', () {
      expect(AppConfig.appName, 'GitPulse');
      expect(AppConfig.appVersion, 'v1.0.9');
      expect(AppConfig.buildNumber, '10');
      expect(AppConfig.fullVersion, 'v1.0.9 (Build 10)');
      expect(AppConfig.releaseTag, 'v1.0.9');
      expect(AppConfig.license, 'MIT License');
      expect(AppConfig.githubRepoUrl, contains('github.com'));
    });

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

    test('UpdateService compareVersions handles semantic versions correctly', () {
      expect(UpdateService.compareVersions('v1.0.2', 'v1.0.1'), 1);
      expect(UpdateService.compareVersions('1.0.1', 'v1.0.1'), 0);
      expect(UpdateService.compareVersions('v1.0.1', 'v1.0.2'), -1);
      expect(UpdateService.compareVersions('v1.0.10', 'v1.0.2'), 1);
      expect(UpdateService.compareVersions('v2.0.0', 'v1.9.9'), 1);
    });

    test('UpdateService cleanDownloadedApk removes leftover apk files successfully', () async {
      final tempDir = await Directory.systemTemp.createTemp('gitpulse_ota_test');
      try {
        final apkFile = File('${tempDir.path}/gitpulse-test.apk');
        await apkFile.writeAsString('dummy apk content');
        expect(await apkFile.exists(), true);

        final nonApkFile = File('${tempDir.path}/important_notes.txt');
        await nonApkFile.writeAsString('keep me');
        expect(await nonApkFile.exists(), true);

        final deleted = await UpdateService.cleanDownloadedApk(customPath: tempDir.path);
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

    test('UpdateService backupApkToDownloads handles missing files safely without throwing', () async {
      final result = await UpdateService.backupApkToDownloads(versionTag: 'v1.0.3');
      // In unit test environment (not Android or source file not present), should safely return null
      expect(result, isNull);
    });

    test('UpdateService cleanInstalledBackupApk deletes only installed GitPulse APK and preserves user data', () async {
      final tempDir = await Directory.systemTemp.createTemp('gitpulse_download_test');
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
      final tempDir = await Directory.systemTemp.createTemp('gitpulse_subfolder_test');
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

    testWidgets('LanguageChart renders percentage without KB bytes and aligns in 2-column layout', (tester) async {
      final languageCounts = {
        'Dart': 7000,
        'JavaScript': 2000,
        'HTML': 1000,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageChart(languageCounts: languageCounts),
          ),
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
    });

    test('AppTheme generates distinct, harmonious palettes for dark, amoled, and sakura modes', () {
      final darkTheme = AppTheme.getTheme(AppThemeMode.dark);
      final amoledTheme = AppTheme.getTheme(AppThemeMode.amoled);
      final sakuraTheme = AppTheme.getTheme(AppThemeMode.amoledJapanese);
      final lightTheme = AppTheme.getTheme(AppThemeMode.light);

      // Verify scaffolds backgrounds
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0D1117));
      expect(amoledTheme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(sakuraTheme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF6F8FA));

      // Verify distinct primary accents
      expect(darkTheme.primaryColor, const Color(0xFF58A6FF));
      expect(amoledTheme.primaryColor, const Color(0xFF00E5FF));
      expect(sakuraTheme.primaryColor, const Color(0xFFFF5C8A));
      expect(lightTheme.primaryColor, const Color(0xFF0969DA));

      // Verify card surfaces
      expect(darkTheme.cardTheme.color, const Color(0xFF161B22));
      expect(amoledTheme.cardTheme.color, const Color(0xFF101012));
      expect(sakuraTheme.cardTheme.color, const Color(0xFF150C18));
    });

    test('AppLocalizations renders beautiful copy profile and favorite toast messages', () {
      final idLoc = AppLocalizations(AppLanguage.indonesian);
      final enLoc = AppLocalizations(AppLanguage.english);

      expect(idLoc.summaryCopiedToast, contains('Profil berhasil disalin'));
      expect(enLoc.summaryCopiedToast, contains('Profile copied to clipboard'));

      expect(idLoc.profileSavedToFavorites('zerabyte88'), contains('Profil @zerabyte88 ditambahkan ke favorit!'));
      expect(enLoc.profileSavedToFavorites('zerabyte88'), contains('Profile @zerabyte88 added to favorites!'));
    });

    test('Typography and Developer Avatar assets conform to updater standards', () {
      for (final lang in AppLanguage.values) {
        final loc = AppLocalizations(lang);
        // Exclamation mark must not be present in updateAvailable string
        expect(loc.updateAvailable.contains('!'), isFalse,
            reason: 'Language ${lang.code} should not have an exclamation mark in updateAvailable');
      }

      // Indonesian language has both nativeName and English name for grid consistency
      expect(AppLanguage.indonesian.nativeName, 'Bahasa Indonesia');
      expect(AppLanguage.indonesian.name, 'Indonesian');

      // Developer avatar URL points to avatars.githubusercontent.com for reliable CDN delivery
      expect(AppConfig.developerAvatarUrl, 'https://avatars.githubusercontent.com/zerabyte88');
    });

    test('TechNews.sanitizeImageUrl unwraps Dev.to proxy URLs to direct AWS S3 URLs', () {
      const proxyUrl = 'https://media2.dev.to/dynamic/image/width=1000,fit=scale/https%3A%2F%2Fdev-to-uploads.s3.us-east-2.amazonaws.com%2Fuploads%2Farticles%2Fsample.png';
      final sanitized = TechNews.sanitizeImageUrl(proxyUrl);
      expect(sanitized, 'https://dev-to-uploads.s3.us-east-2.amazonaws.com/uploads/articles/sample.png');

      const regularUrl = 'https://example.com/image.jpg';
      expect(TechNews.sanitizeImageUrl(regularUrl), 'https://example.com/image.jpg');

      expect(TechNews.sanitizeImageUrl(null), isNull);
      expect(TechNews.sanitizeImageUrl(''), isNull);
    });

    testWidgets('AnimatedAppHeader renders terminal icon, GitPulse title, and version badge', (tester) async {
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
      expect(find.byType(AnimatedHeaderBackground), findsOneWidget);
      expect(find.text('GitPulse'), findsOneWidget);
      expect(find.text(AppConfig.appVersion), findsOneWidget);

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
    });

    testWidgets('StatCard renders long English and multi-language contribution titles without truncation', (tester) async {
      final currentYear = DateTime.now().year;

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final lang in [AppLanguage.english, AppLanguage.indonesian, AppLanguage.japanese]) {
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
                          label: '${loc.thisYearContributions} ($currentYear)',
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

        final leftLabelFinder = find.text('${loc.thisYearContributions} ($currentYear)');
        final rightLabelFinder = find.text(loc.allYearsContributions);
        expect(leftLabelFinder, findsOneWidget);
        expect(rightLabelFinder, findsOneWidget);

        // Verify that neither label exceeded maxLines (i.e. did not truncate with ellipsis)
        final leftParagraph = tester.renderObject<RenderParagraph>(leftLabelFinder);
        final rightParagraph = tester.renderObject<RenderParagraph>(rightLabelFinder);
        expect(leftParagraph.didExceedMaxLines, isFalse,
            reason: 'Left card label for ${lang.code} should not be truncated');
        expect(rightParagraph.didExceedMaxLines, isFalse,
            reason: 'Right card label for ${lang.code} should not be truncated');
      }
    });
  });
}

