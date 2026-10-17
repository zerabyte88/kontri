import 'contribution_stats.dart';
import 'github_repo.dart';
import 'github_user.dart';

class UserStats {
  final GitHubUser user;
  final List<GitHubRepo> repos;
  final int totalStars;
  final int totalForks;
  final Map<String, int> languageCounts;
  final Map<int, int> hourlyActivity; // 0 to 23 -> count
  final ContributionStats contributionStats;

  UserStats({
    required this.user,
    required this.repos,
    required this.totalStars,
    required this.totalForks,
    required this.languageCounts,
    required this.hourlyActivity,
    required this.contributionStats,
  });

  factory UserStats.calculate({
    required GitHubUser user,
    required List<GitHubRepo> repos,
    required List<Map<String, dynamic>> publicEvents,
    required ContributionStats contributionStats,
    Map<String, int>? aggregatedLanguages,
  }) {
    int totalStars = 0;
    int totalForks = 0;
    final Map<String, int> langCounts = {};

    final hasAggregated =
        aggregatedLanguages != null && aggregatedLanguages.isNotEmpty;
    if (hasAggregated) {
      langCounts.addAll(aggregatedLanguages);
    }

    for (final repo in repos) {
      totalStars += repo.stargazersCount;
      totalForks += repo.forksCount;

      if (!hasAggregated &&
          !repo.isFork &&
          repo.language != null &&
          repo.language!.isNotEmpty) {
        final weight = repo.size > 0 ? repo.size : 1;
        langCounts[repo.language!] = (langCounts[repo.language!] ?? 0) + weight;
      }
    }

    final Map<int, int> hours = {for (var i = 0; i < 24; i++) i: 0};

    for (final event in publicEvents) {
      if (event['created_at'] != null) {
        final dt = DateTime.tryParse(event['created_at'] as String)?.toLocal();
        if (dt != null) {
          hours[dt.hour] = (hours[dt.hour] ?? 0) + 1;
        }
      }
    }

    return UserStats(
      user: user,
      repos: repos,
      totalStars: totalStars,
      totalForks: totalForks,
      languageCounts: langCounts,
      hourlyActivity: hours,
      contributionStats: contributionStats,
    );
  }
}
