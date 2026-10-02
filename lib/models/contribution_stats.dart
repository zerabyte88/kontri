class CommitTitleInfo {
  final String title;
  final String levelName;
  final String description;
  final String badgeText;
  final int tier; // 1 (Highest) to 6 (Lowest)

  const CommitTitleInfo({
    required this.title,
    required this.levelName,
    required this.description,
    required this.badgeText,
    required this.tier,
  });

  /// Nama title bersih tanpa ikon atau emoji
  String get cleanTitle {
    return title.replaceAll(RegExp(r'^[^\w\s]+\s*'), '').trim();
  }
}

class ContributionStats {
  final int thisYearContributions;
  final int lastYearContributions;
  final int currentStreak;
  final int longestStreak;
  final int totalContributions;
  final CommitTitleInfo commitTitle;
  final Map<String, int> yearlyTotals;

  const ContributionStats({
    required this.thisYearContributions,
    required this.lastYearContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalContributions,
    required this.commitTitle,
    required this.yearlyTotals,
  });

  /// Evaluates commit titles based on user's streak and contribution activity:
  /// - Rajin Commit (Tier 1 & 2)
  /// - Commit Terkadang (Tier 3 & 4)
  /// - Jarang Commit / Belum Aktif (Tier 5 & 6)
  static CommitTitleInfo determineTitle({
    required int currentStreak,
    required int longestStreak,
    required int thisYearContributions,
    required int totalContributions,
  }) {
    // Tier 1: Sangat Rajin Ekstrem (Mythic/Legendary)
    if (currentStreak >= 14 || longestStreak >= 30 || thisYearContributions >= 350) {
      return const CommitTitleInfo(
        title: 'Code Titan',
        levelName: 'Sangat Rajin (Master)',
        badgeText: 'Tier: Mythic',
        tier: 1,
        description: 'Komitmen baja! Tiada hari tanpa baris kode, konsistensi luar biasa.',
      );
    }
    // Tier 2: Rajin & Berkelanjutan
    else if (currentStreak >= 5 || longestStreak >= 14 || thisYearContributions >= 100) {
      return const CommitTitleInfo(
        title: 'Relentless Committer',
        levelName: 'Sangat Rajin',
        badgeText: 'Tier: Diamond',
        tier: 2,
        description: 'Sangat aktif commit dan membangun proyek hampir setiap hari.',
      );
    }
    // Tier 3: Rutin & Teratur
    else if (currentStreak >= 2 || longestStreak >= 7 || thisYearContributions >= 30) {
      return const CommitTitleInfo(
        title: 'Consistent Builder',
        levelName: 'Rajin & Stabil',
        badgeText: 'Tier: Platinum',
        tier: 3,
        description: 'Rutin memelihara ritme commit kode secara teratur dan stabil.',
      );
    }
    // Tier 4: Terkadang / Sewaktu-waktu (Casual)
    else if (currentStreak >= 1 || longestStreak >= 2 || thisYearContributions >= 8) {
      return const CommitTitleInfo(
        title: 'Weekend Warrior',
        levelName: 'Commit Terkadang',
        badgeText: 'Tier: Gold',
        tier: 4,
        description: 'Commit sewaktu-waktu di waktu senggang saat ada ide dan inspirasi.',
      );
    }
    // Tier 5: Jarang Commit (Low Activity)
    else if (thisYearContributions > 0 || totalContributions > 0) {
      return const CommitTitleInfo(
        title: 'Dormant Explorer',
        levelName: 'Jarang Commit',
        badgeText: 'Tier: Silver',
        tier: 5,
        description: 'Jarang mendorong commit ke publik, menikmati ritme santai.',
      );
    }
    // Tier 6: Belum Aktif / Newbie
    else {
      return const CommitTitleInfo(
        title: 'Fresh Sprout',
        levelName: 'Belum Aktif',
        badgeText: 'Tier: Bronze',
        tier: 6,
        description: 'Belum ada catatan commit tahun ini. Ayo mulai nyalakan streak pertamamu!',
      );
    }
  }

  /// Computes current and longest consecutive daily contribution streaks.
  /// Handles multi-year arrays, leap years, timezone offsets, and non-chronological lists.
  static ({int current, int longest}) calculateStreaks(Map<DateTime, int> dayCounts) {
    if (dayCounts.isEmpty) return (current: 0, longest: 0);

    final sortedDates = dayCounts.keys.toList()..sort();
    int longest = 0;
    int running = 0;
    DateTime? prevDate;

    for (final date in sortedDates) {
      final count = dayCounts[date] ?? 0;
      if (count > 0) {
        if (prevDate != null && date.difference(prevDate).inDays == 1) {
          running++;
        } else {
          running = 1;
        }
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
      prevDate = date;
    }

    int current = 0;
    final nowLocal = DateTime.now();
    final todayLocal = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);

    DateTime? lastActiveDate;
    for (int i = sortedDates.length - 1; i >= 0; i--) {
      final date = sortedDates[i];
      if ((dayCounts[date] ?? 0) > 0) {
        lastActiveDate = date;
        break;
      }
    }

    if (lastActiveDate != null) {
      final diffLocal = todayLocal.difference(lastActiveDate).inDays;

      // Active streak: last commit is today (0), yesterday (1), or within 1 day timezone skew (-1)
      if (diffLocal >= -1 && diffLocal <= 1) {
        DateTime cur = lastActiveDate;
        while (true) {
          final count = dayCounts[cur] ?? 0;
          if (count > 0) {
            current++;
            cur = DateTime.utc(cur.year, cur.month, cur.day - 1);
          } else {
            break;
          }
        }
      }
    }

    if (current > longest) longest = current;
    return (current: current, longest: longest);
  }

  factory ContributionStats.fromContributionsApi(Map<String, dynamic> json) {
    final now = DateTime.now();
    final currentYearKey = now.year.toString();
    final lastYearKey = (now.year - 1).toString();

    final Map<String, int> yearly = {};
    if (json['total'] is Map) {
      (json['total'] as Map).forEach((k, v) {
        if (v is num) {
          yearly[k.toString()] = v.toInt();
        }
      });
    }

    final thisYear = yearly[currentYearKey] ?? 0;
    final lastYear = yearly[lastYearKey] ?? 0;
    final total = yearly.values.fold(0, (sum, count) => sum + count);

    // Parse daily contributions array
    final Map<DateTime, int> dayCounts = {};
    if (json['contributions'] is List) {
      final list = json['contributions'] as List;
      for (final item in list) {
        if (item is Map && item['date'] != null) {
          final dateStr = item['date'].toString();
          final count = (item['count'] as num?)?.toInt() ?? 0;
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              dayCounts[DateTime.utc(y, m, d)] = count;
            }
          }
        }
      }
    }

    final streaks = calculateStreaks(dayCounts);
    final current = streaks.current;
    final longest = streaks.longest;

    final title = determineTitle(
      currentStreak: current,
      longestStreak: longest,
      thisYearContributions: thisYear,
      totalContributions: total,
    );

    return ContributionStats(
      thisYearContributions: thisYear,
      lastYearContributions: lastYear,
      currentStreak: current,
      longestStreak: longest,
      totalContributions: total,
      commitTitle: title,
      yearlyTotals: yearly,
    );
  }

  /// Resilient fallback if third-party contributions API is unreachable:
  /// Uses public events (PushEvents) to estimate streaks and commits.
  factory ContributionStats.fromEvents(List<Map<String, dynamic>> events) {
    final now = DateTime.now();
    final currentYear = now.year;
    final lastYear = now.year - 1;

    int thisYearCount = 0;
    int lastYearCount = 0;
    final Map<DateTime, int> dayCounts = {};
    final Map<String, int> yearlyCounts = {};

    for (final event in events) {
      if (event['type'] == 'PushEvent') {
        final payload = event['payload'] as Map<String, dynamic>?;
        final commitCount = (payload?['commits'] as List?)?.length ??
            (payload?['size'] as num?)?.toInt() ??
            1;

        final createdAtStr = event['created_at'] as String?;
        if (createdAtStr != null) {
          final dt = DateTime.tryParse(createdAtStr)?.toLocal();
          if (dt != null) {
            if (dt.year == currentYear) {
              thisYearCount += commitCount;
            } else if (dt.year == lastYear) {
              lastYearCount += commitCount;
            }
            final yearKey = dt.year.toString();
            yearlyCounts[yearKey] = (yearlyCounts[yearKey] ?? 0) + commitCount;

            final dUtc = DateTime.utc(dt.year, dt.month, dt.day);
            dayCounts[dUtc] = (dayCounts[dUtc] ?? 0) + commitCount;
          }
        }
      }
    }

    final streaks = calculateStreaks(dayCounts);
    final currentStreak = streaks.current;
    final longestStreak = streaks.longest;
    final total = yearlyCounts.values.fold(0, (sum, count) => sum + count);

    final title = determineTitle(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      thisYearContributions: thisYearCount,
      totalContributions: total,
    );

    return ContributionStats(
      thisYearContributions: thisYearCount,
      lastYearContributions: lastYearCount,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalContributions: total,
      commitTitle: title,
      yearlyTotals: yearlyCounts.isNotEmpty
          ? yearlyCounts
          : {
              currentYear.toString(): thisYearCount,
              lastYear.toString(): lastYearCount,
            },
    );
  }
}
