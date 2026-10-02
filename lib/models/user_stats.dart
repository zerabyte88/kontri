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
  final String developerPersona;
  final String personaDescription;
  final ContributionStats contributionStats;

  UserStats({
    required this.user,
    required this.repos,
    required this.totalStars,
    required this.totalForks,
    required this.languageCounts,
    required this.hourlyActivity,
    required this.developerPersona,
    required this.personaDescription,
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

    final hasAggregated = aggregatedLanguages != null && aggregatedLanguages.isNotEmpty;
    if (hasAggregated) {
      langCounts.addAll(aggregatedLanguages);
    }

    for (final repo in repos) {
      totalStars += repo.stargazersCount;
      totalForks += repo.forksCount;

      if (!hasAggregated && !repo.isFork && repo.language != null && repo.language!.isNotEmpty) {
        final weight = repo.size > 0 ? repo.size : 1;
        langCounts[repo.language!] = (langCounts[repo.language!] ?? 0) + weight;
      }
    }

    final Map<int, int> hours = {for (var i = 0; i < 24; i++) i: 0};
    int nightEvents = 0; // 22:00 - 04:00
    int morningEvents = 0; // 05:00 - 11:00
    int afternoonEvents = 0; // 12:00 - 17:00

    for (final event in publicEvents) {
      if (event['created_at'] != null) {
        final dt = DateTime.tryParse(event['created_at'] as String)?.toLocal();
        if (dt != null) {
          hours[dt.hour] = (hours[dt.hour] ?? 0) + 1;
          if (dt.hour >= 22 || dt.hour < 5) {
            nightEvents++;
          } else if (dt.hour >= 5 && dt.hour < 12) {
            morningEvents++;
          } else if (dt.hour >= 12 && dt.hour < 18) {
            afternoonEvents++;
          }
        }
      }
    }

    // Determine Persona
    String persona;
    String description;

    if (totalStars >= 100) {
      persona = 'Star Magnet';
      description = 'Koleksi bintang repositorimu sangat memukau komunitas GitHub!';
    } else if (langCounts.length >= 4) {
      persona = 'Polyglot Architect';
      description = 'Menguasai dan aktif menggunakan beragam bahasa pemrograman.';
    } else if (nightEvents > morningEvents && nightEvents > afternoonEvents) {
      persona = 'Midnight Owl Coder';
      description = 'Fokus dan produktivitas tertinggi terpancar di keheningan malam.';
    } else if (morningEvents > afternoonEvents && morningEvents > nightEvents) {
      persona = 'Early Bird Developer';
      description = 'Memulai hari dengan commit segar dan pikiran jernih di pagi hari.';
    } else if (repos.length > 20) {
      persona = 'Prolific Builder';
      description = 'Sangat produktif dalam mengeksekusi dan merilis ide ke publik.';
    } else {
      persona = 'Dedicated Craftsman';
      description = 'Terus konsisten mengasah kode dan membangun karya bermutu.';
    }

    return UserStats(
      user: user,
      repos: repos,
      totalStars: totalStars,
      totalForks: totalForks,
      languageCounts: langCounts,
      hourlyActivity: hours,
      developerPersona: persona,
      personaDescription: description,
      contributionStats: contributionStats,
    );
  }
}
