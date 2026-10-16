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

  static CommitTitleInfo getInfoForTier(int tier) {
    switch (tier) {
      case 1:
        return const CommitTitleInfo(
          title: 'Mythic Archmage',
          levelName: 'Sangat Rajin (Master)',
          badgeText: 'Tier: Mythic',
          tier: 1,
          description:
              'Kekuatan magis kode tak tertandingi! Konsistensi mutlak tanpa putus.',
        );
      case 2:
        return const CommitTitleInfo(
          title: 'Diamond Vanguard',
          levelName: 'Sangat Rajin',
          badgeText: 'Tier: Diamond',
          tier: 2,
          description:
              'Garda terdepan pengembangan perangkat lunak, aktif meluncurkan commit.',
        );
      case 3:
        return const CommitTitleInfo(
          title: 'Platinum Artisan',
          levelName: 'Rajin & Stabil',
          badgeText: 'Tier: Platinum',
          tier: 3,
          description:
              'Mahir menempa karya kode dengan ritme yang konsisten dan stabil.',
        );
      case 4:
        return const CommitTitleInfo(
          title: 'Gold Adventurer',
          levelName: 'Commit Terkadang',
          badgeText: 'Tier: Gold',
          tier: 4,
          description:
              'Menjelajah berbagai proyek kode di sela petualangan dan waktu senggang.',
        );
      case 5:
        return const CommitTitleInfo(
          title: 'Silver Explorer',
          levelName: 'Jarang Commit',
          badgeText: 'Tier: Silver',
          tier: 5,
          description:
              'Penjelajah santai yang mencatat commit saat menemukan inspirasi baru.',
        );
      case 6:
      default:
        return const CommitTitleInfo(
          title: 'Bronze Novice',
          levelName: 'Belum Aktif',
          badgeText: 'Tier: Bronze',
          tier: 6,
          description:
              'Petualang baru di dunia open source. Nyalakan streak pertamamu!',
        );
    }
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
  final int rolling365Contributions;
  final int rolling365ActiveDays;
  final CommitTitleInfo peakTitle;
  final double nextTierProgress;
  final String? nextTierLaggingMetric;
  final int nextTierContributionsRequired;
  final int nextTierActiveDaysRequired;
  final String? nextTierName;

  const ContributionStats({
    required this.thisYearContributions,
    required this.lastYearContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalContributions,
    required this.commitTitle,
    required this.yearlyTotals,
    this.rolling365Contributions = 0,
    this.rolling365ActiveDays = 0,
    CommitTitleInfo? peakTitle,
    this.nextTierProgress = 1.0,
    this.nextTierLaggingMetric,
    this.nextTierContributionsRequired = 0,
    this.nextTierActiveDaysRequired = 0,
    this.nextTierName,
  }) : peakTitle = peakTitle ?? commitTitle;

  ContributionStats copyWith({
    int? thisYearContributions,
    int? lastYearContributions,
    int? currentStreak,
    int? longestStreak,
    int? totalContributions,
    CommitTitleInfo? commitTitle,
    Map<String, int>? yearlyTotals,
    int? rolling365Contributions,
    int? rolling365ActiveDays,
    CommitTitleInfo? peakTitle,
    double? nextTierProgress,
    String? nextTierLaggingMetric,
    int? nextTierContributionsRequired,
    int? nextTierActiveDaysRequired,
    String? nextTierName,
  }) {
    return ContributionStats(
      thisYearContributions:
          thisYearContributions ?? this.thisYearContributions,
      lastYearContributions:
          lastYearContributions ?? this.lastYearContributions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalContributions: totalContributions ?? this.totalContributions,
      commitTitle: commitTitle ?? this.commitTitle,
      yearlyTotals: yearlyTotals ?? this.yearlyTotals,
      rolling365Contributions:
          rolling365Contributions ?? this.rolling365Contributions,
      rolling365ActiveDays: rolling365ActiveDays ?? this.rolling365ActiveDays,
      peakTitle: peakTitle ?? this.peakTitle,
      nextTierProgress: nextTierProgress ?? this.nextTierProgress,
      nextTierLaggingMetric:
          nextTierLaggingMetric ?? this.nextTierLaggingMetric,
      nextTierContributionsRequired:
          nextTierContributionsRequired ?? this.nextTierContributionsRequired,
      nextTierActiveDaysRequired:
          nextTierActiveDaysRequired ?? this.nextTierActiveDaysRequired,
      nextTierName: nextTierName ?? this.nextTierName,
    );
  }

  /// Calculates progress towards next tier using dual conditions.
  static ({
    double progress,
    String? laggingMetric,
    int contribRequired,
    int activeRequired,
    String? nextTierName,
  }) calculateNextTierProgress({
    required int currentTier,
    required int rollingContributions,
    required int rollingActiveDays,
  }) {
    if (currentTier <= 1) {
      return (
        progress: 1.0,
        laggingMetric: null,
        contribRequired: 1000,
        activeRequired: 200,
        nextTierName: null,
      );
    }

    final targetTier = currentTier - 1;
    final int targetContrib;
    final int targetActive;
    final String targetName;

    switch (targetTier) {
      case 1:
        targetContrib = 1000;
        targetActive = 200;
        targetName = 'Mythic Archmage';
        break;
      case 2:
        targetContrib = 500;
        targetActive = 130;
        targetName = 'Diamond Vanguard';
        break;
      case 3:
        targetContrib = 250;
        targetActive = 70;
        targetName = 'Platinum Artisan';
        break;
      case 4:
        targetContrib = 125;
        targetActive = 35;
        targetName = 'Gold Adventurer';
        break;
      case 5:
      default:
        targetContrib = 50;
        targetActive = 10;
        targetName = 'Silver Explorer';
        break;
    }

    final contribRatio =
        (rollingContributions / targetContrib).clamp(0.0, 1.0);
    final activeRatio =
        (rollingActiveDays / targetActive).clamp(0.0, 1.0);
    final double progress =
        contribRatio < activeRatio ? contribRatio : activeRatio;

    String? lagging;
    if (progress < 1.0) {
      if (contribRatio < activeRatio) {
        lagging = 'contributions';
      } else if (activeRatio < contribRatio) {
        lagging = 'activeDays';
      } else {
        lagging = 'contributions';
      }
    }

    return (
      progress: progress,
      laggingMetric: lagging,
      contribRequired: targetContrib,
      activeRequired: targetActive,
      nextTierName: targetName,
    );
  }

  /// Evaluates commit titles based on a rolling 365-day window:
  /// Both contributions and active days criteria must be met.
  static CommitTitleInfo determineTitle({
    int currentStreak = 0,
    int longestStreak = 0,
    int thisYearContributions = 0,
    int totalContributions = 0,
    int? rollingContributions,
    int? rollingActiveDays,
  }) {
    final rContrib = rollingContributions ?? thisYearContributions;
    final rActive = rollingActiveDays ??
        (rContrib >= 1000 && (currentStreak >= 30 || longestStreak >= 60)
            ? 200
            : rContrib >= 500 && (currentStreak >= 21 || longestStreak >= 45)
                ? 130
                : rContrib >= 250 && (currentStreak >= 7 || longestStreak >= 14)
                    ? 70
                    : rContrib >= 125
                        ? 35
                        : rContrib >= 50
                            ? 10
                            : 0);

    if (rContrib >= 1000 && rActive >= 200) {
      return CommitTitleInfo.getInfoForTier(1);
    } else if (rContrib >= 500 && rActive >= 130) {
      return CommitTitleInfo.getInfoForTier(2);
    } else if (rContrib >= 250 && rActive >= 70) {
      return CommitTitleInfo.getInfoForTier(3);
    } else if (rContrib >= 125 && rActive >= 35) {
      return CommitTitleInfo.getInfoForTier(4);
    } else if (rContrib >= 50 && rActive >= 10) {
      return CommitTitleInfo.getInfoForTier(5);
    } else {
      return CommitTitleInfo.getInfoForTier(6);
    }
  }

  /// Computes current and longest consecutive daily contribution streaks.
  /// Handles multi-year arrays, leap years, timezone offsets, and non-chronological lists.
  static ({int current, int longest}) calculateStreaks(
    Map<DateTime, int> dayCounts,
  ) {
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
    final todayLocal = DateTime.utc(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );

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

    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final windowStart = todayUtc.subtract(const Duration(days: 364));

    int rollingContrib = 0;
    int rollingActive = 0;
    final Map<int, ({int contrib, int active})> yearlyBreakdown = {};

    for (final entry in dayCounts.entries) {
      final date = entry.key;
      final count = entry.value;

      if (!date.isBefore(windowStart) && !date.isAfter(todayUtc)) {
        rollingContrib += count;
        if (count > 0) {
          rollingActive++;
        }
      }

      final y = date.year;
      final existing = yearlyBreakdown[y] ?? (contrib: 0, active: 0);
      yearlyBreakdown[y] = (
        contrib: existing.contrib + count,
        active: existing.active + (count > 0 ? 1 : 0),
      );
    }

    final title = determineTitle(
      currentStreak: current,
      longestStreak: longest,
      thisYearContributions: thisYear,
      totalContributions: total,
      rollingContributions: rollingContrib,
      rollingActiveDays: rollingActive,
    );

    int peakTierNum = title.tier;
    for (final entry in yearlyBreakdown.entries) {
      final yearTier = determineTitle(
        rollingContributions: entry.value.contrib,
        rollingActiveDays: entry.value.active,
      );
      if (yearTier.tier < peakTierNum) {
        peakTierNum = yearTier.tier;
      }
    }
    final peakTitle = CommitTitleInfo.getInfoForTier(peakTierNum);

    final progressInfo = calculateNextTierProgress(
      currentTier: title.tier,
      rollingContributions: rollingContrib,
      rollingActiveDays: rollingActive,
    );

    return ContributionStats(
      thisYearContributions: thisYear,
      lastYearContributions: lastYear,
      currentStreak: current,
      longestStreak: longest,
      totalContributions: total,
      commitTitle: title,
      yearlyTotals: yearly,
      rolling365Contributions: rollingContrib,
      rolling365ActiveDays: rollingActive,
      peakTitle: peakTitle,
      nextTierProgress: progressInfo.progress,
      nextTierLaggingMetric: progressInfo.laggingMetric,
      nextTierContributionsRequired: progressInfo.contribRequired,
      nextTierActiveDaysRequired: progressInfo.activeRequired,
      nextTierName: progressInfo.nextTierName,
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
        final commitCount =
            (payload?['commits'] as List?)?.length ??
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

    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final windowStart = todayUtc.subtract(const Duration(days: 364));

    int rollingContrib = 0;
    int rollingActive = 0;
    for (final entry in dayCounts.entries) {
      if (!entry.key.isBefore(windowStart) && !entry.key.isAfter(todayUtc)) {
        rollingContrib += entry.value;
        if (entry.value > 0) rollingActive++;
      }
    }

    if (rollingContrib == 0 && thisYearCount > 0) {
      rollingContrib = thisYearCount;
      rollingActive = (thisYearCount / 3).round().clamp(1, 365);
    }

    final title = determineTitle(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      thisYearContributions: thisYearCount,
      totalContributions: total,
      rollingContributions: rollingContrib,
      rollingActiveDays: rollingActive,
    );

    final progressInfo = calculateNextTierProgress(
      currentTier: title.tier,
      rollingContributions: rollingContrib,
      rollingActiveDays: rollingActive,
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
      rolling365Contributions: rollingContrib,
      rolling365ActiveDays: rollingActive,
      peakTitle: title,
      nextTierProgress: progressInfo.progress,
      nextTierLaggingMetric: progressInfo.laggingMetric,
      nextTierContributionsRequired: progressInfo.contribRequired,
      nextTierActiveDaysRequired: progressInfo.activeRequired,
      nextTierName: progressInfo.nextTierName,
    );
  }
}
