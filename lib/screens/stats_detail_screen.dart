import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/github_repo.dart';
import '../models/user_stats.dart';
import '../services/github_api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_chart.dart';
import '../widgets/animated_tier_title.dart';
import '../widgets/language_chart.dart';
import '../widgets/repo_tile.dart';
import '../widgets/stat_card.dart';

enum RepoSortFilter {
  popular,
  newest,
  oldest,
}

class StatsDetailScreen extends StatefulWidget {
  final UserStats stats;
  final StorageService storageService;
  final GitHubApiService? apiService;

  const StatsDetailScreen({
    super.key,
    required this.stats,
    required this.storageService,
    this.apiService,
  });

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  late bool _isBookmarked;
  RepoSortFilter _currentFilter = RepoSortFilter.popular;
  bool _showAllRepos = false;
  late List<GitHubRepo> _sortedRepos;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.storageService.isBookmarked(widget.stats.user.login);
    _sortRepos();
  }

  void _sortRepos() {
    final list = List<GitHubRepo>.from(widget.stats.repos);
    switch (_currentFilter) {
      case RepoSortFilter.popular:
        list.sort((a, b) {
          final starsCmp = b.stargazersCount.compareTo(a.stargazersCount);
          if (starsCmp != 0) return starsCmp;
          return b.forksCount.compareTo(a.forksCount);
        });
        break;
      case RepoSortFilter.newest:
        list.sort((a, b) {
          final dateA = a.latestActivityDate ?? DateTime(1970);
          final dateB = b.latestActivityDate ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        break;
      case RepoSortFilter.oldest:
        list.sort((a, b) {
          final dateA = a.latestActivityDate ?? DateTime(1970);
          final dateB = b.latestActivityDate ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
        break;
    }
    _sortedRepos = list;
  }

  void _showThemedSnackBar({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: iconColor.withValues(alpha: 0.38),
            width: 1.1,
          ),
        ),
        duration: const Duration(milliseconds: 2200),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBookmark() async {
    final loc = AppLocalizations.of(context);
    final username = widget.stats.user.login;
    await widget.storageService.toggleBookmark(
      username,
      avatarUrl: widget.stats.user.avatarUrl,
    );
    if (!mounted) return;
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    _showThemedSnackBar(
      icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      iconColor: _isBookmarked ? AppTheme.accentAmber : AppTheme.textMuted,
      message: _isBookmarked
          ? loc.profileSavedToFavorites(username)
          : loc.profileRemovedFromFavorites,
    );
  }

  void _shareSummary() {
    final loc = AppLocalizations.of(context);
    final u = widget.stats.user;
    final cStats = widget.stats.contributionStats;
    final topLang = widget.stats.languageCounts.entries.isNotEmpty
        ? (widget.stats.languageCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
        : 'N/A';

    final text = '''
--- GitPulse Profile Snapshot ---
Username: @${u.login} (${u.name ?? 'Developer'})
Title: ${cStats.commitTitle.cleanTitle} (${loc.getCommitTierLevelName(cStats.commitTitle.tier)})
Streak: ${cStats.currentStreak} ${loc.daysUnit} (Max: ${cStats.longestStreak} ${loc.daysUnit})
${loc.thisYearContributions}: ${cStats.thisYearContributions}
${loc.allYearsContributions}: ${cStats.totalContributions}
Persona: ${widget.stats.developerPersona}
${loc.totalStars}: ${widget.stats.totalStars}
${loc.repositoriesTitle}: ${u.publicRepos} | ${loc.followers}: ${u.followers}
${loc.topLanguagesTitle}: $topLang
GitHub: https://github.com/${u.login}
''';

    Clipboard.setData(ClipboardData(text: text));
    _showThemedSnackBar(
      icon: Icons.check_circle_rounded,
      iconColor: AppTheme.primaryCyan,
      message: loc.summaryCopiedToast,
    );
  }

  Future<void> _openUrl(String targetUrl) async {
    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      final loc = AppLocalizations.of(context);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          _showThemedSnackBar(
            icon: Icons.error_outline_rounded,
            iconColor: AppTheme.accentRed,
            message: loc.cannotOpenLink(targetUrl),
          );
        }
      } catch (e) {
        if (mounted) {
          _showThemedSnackBar(
            icon: Icons.error_outline_rounded,
            iconColor: AppTheme.accentRed,
            message: loc.failedToOpenLink(e.toString()),
          );
        }
      }
    }
  }

  void _openUserRepositories() {
    final login = widget.stats.user.login;
    final url = widget.stats.user.htmlUrl.isNotEmpty
        ? '${widget.stats.user.htmlUrl}?tab=repositories'
        : 'https://github.com/$login?tab=repositories';
    _openUrl(url);
  }

  void _openUserProfile() {
    final login = widget.stats.user.login;
    final url = widget.stats.user.htmlUrl.isNotEmpty
        ? widget.stats.user.htmlUrl
        : 'https://github.com/$login';
    _openUrl(url);
  }

  String _getFilterLabel(RepoSortFilter filter, AppLocalizations loc) {
    switch (filter) {
      case RepoSortFilter.popular:
        return loc.filterPopular;
      case RepoSortFilter.newest:
        return loc.filterNewest;
      case RepoSortFilter.oldest:
        return loc.filterOldest;
    }
  }

  PopupMenuItem<RepoSortFilter> _buildPopupMenuItem(
    RepoSortFilter filter,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _currentFilter == filter;
    return PopupMenuItem<RepoSortFilter>(
      value: filter,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryCyan : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_rounded, size: 15, color: AppTheme.primaryCyan),
          ],
        ],
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = widget.stats.user;
    final cStats = widget.stats.contributionStats;
    final titleInfo = cStats.commitTitle;
    final currentYear = DateTime.now().year;
    final repos = _sortedRepos;
    final displayedRepos = _showAllRepos ? repos : repos.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '@${user.login}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isBookmarked ? loc.removeFavorite : loc.saveFavorite,
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppTheme.accentAmber : AppTheme.textSecondary,
              size: 21,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            tooltip: loc.shareProfile,
            icon: Icon(Icons.share_outlined, size: 20, color: AppTheme.textSecondary),
            onPressed: _shareSummary,
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        // ignore: deprecated_member_use
        cacheExtent: 600.0,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.surfaceElevated,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? ResizeImage(
                                  NetworkImage(user.avatarUrl),
                                  width: 160,
                                  height: 160,
                                )
                              : null,
                          child: user.avatarUrl.isEmpty
                              ? Text(
                                  user.login.isNotEmpty
                                      ? user.login[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppTheme.primaryCyan,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 5,
                              children: [
                                Text(
                                  (user.name != null && user.name!.trim().isNotEmpty)
                                      ? user.name!
                                      : user.login,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                AnimatedTierTitle(
                                  titleInfo: titleInfo,
                                  fontSize: 11,
                                  showBadgeContainer: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: _openUserProfile,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '@${user.login}',
                                    style: TextStyle(
                                      color: AppTheme.primaryCyan,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 11,
                                    color: AppTheme.primaryCyan.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                            if (user.location != null && user.location!.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      user.location!.trim(),
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (user.company != null && user.company!.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      user.company!.trim(),
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border, width: 0.8),
                      ),
                      child: Text(
                        user.bio!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section: GitHub Contributions & Streak Statistics
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: AppTheme.accentOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.streakStatsTitle,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: loc.currentStreak,
                      value: '${cStats.currentStreak} ${loc.daysUnit}',
                      icon: Icons.whatshot_rounded,
                      accentColor: AppTheme.accentOrange,
                      subtitle: cStats.currentStreak > 0
                          ? loc.activeNowBadge
                          : loc.notActiveYetBadge,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: loc.longestStreak,
                      value: '${cStats.longestStreak} ${loc.daysUnit}',
                      icon: Icons.emoji_events_rounded,
                      accentColor: AppTheme.accentAmber,
                      subtitle: loc.consistencyRecord,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: '${loc.thisYearContributions} ($currentYear)',
                      value: '${cStats.thisYearContributions}',
                      icon: Icons.calendar_today_rounded,
                      accentColor: AppTheme.primaryCyan,
                      subtitle: loc.thisYearSubtitle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: loc.allYearsContributions,
                      value: '${cStats.totalContributions}',
                      icon: Icons.all_inclusive_rounded,
                      accentColor: AppTheme.primaryViolet,
                      subtitle: loc.allTimeSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics Grid
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 18,
                  color: AppTheme.primaryCyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.accountOverviewTitle,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: loc.totalStars,
                      value: '${widget.stats.totalStars}',
                      icon: Icons.star_outline_rounded,
                      accentColor: AppTheme.accentAmber,
                      subtitle: loc.acrossAllRepos,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: loc.publicRepos,
                      value: '${user.publicRepos}',
                      icon: Icons.folder_open_rounded,
                      accentColor: AppTheme.primaryCyan,
                      subtitle: loc.registeredReposSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: loc.followers,
                      value: '${user.followers}',
                      icon: Icons.people_outline_rounded,
                      accentColor: AppTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: loc.totalForks,
                      value: '${widget.stats.totalForks}',
                      icon: Icons.call_split_rounded,
                      accentColor: AppTheme.primaryViolet,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Language Chart
            LanguageChart(languageCounts: widget.stats.languageCounts),
            const SizedBox(height: 16),

            // Activity Chart
            ActivityChart(hourlyActivity: widget.stats.hourlyActivity),
            const SizedBox(height: 20),

            // Repositories Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_special_outlined,
                        size: 18,
                        color: AppTheme.primaryCyan,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          loc.repositoriesTitle,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border, width: 0.8),
                        ),
                        child: Text(
                          '${widget.stats.repos.length} ${loc.totalCountBadge}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<RepoSortFilter>(
                  initialValue: _currentFilter,
                  tooltip: loc.filterRepositories,
                  onSelected: (filter) {
                    setState(() {
                      _currentFilter = filter;
                      _sortRepos();
                    });
                  },
                  color: AppTheme.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.border, width: 1),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 14,
                          color: AppTheme.primaryCyan,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getFilterLabel(_currentFilter, loc),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    _buildPopupMenuItem(
                      RepoSortFilter.popular,
                      loc.filterPopular,
                      loc.filterPopularDesc,
                      Icons.star_outline_rounded,
                      AppTheme.accentAmber,
                    ),
                    _buildPopupMenuItem(
                      RepoSortFilter.newest,
                      loc.filterNewest,
                      loc.filterNewestDesc,
                      Icons.update_rounded,
                      AppTheme.primaryCyan,
                    ),
                    _buildPopupMenuItem(
                      RepoSortFilter.oldest,
                      loc.filterOldest,
                      loc.filterOldestDesc,
                      Icons.history_rounded,
                      AppTheme.primaryViolet,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
      if (repos.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                loc.noPublicRepos,
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ),
        )
      else ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => RepoTile(
                repo: displayedRepos[index],
                username: widget.stats.user.login,
                apiService: widget.apiService,
              ),
              childCount: displayedRepos.length,
            ),
          ),
        ),
        if (repos.length > 10)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllRepos = !_showAllRepos;
                        });
                      },
                      icon: Icon(
                        _showAllRepos
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppTheme.primaryCyan,
                      ),
                      label: Text(
                        _showAllRepos
                            ? loc.showFewerRepos
                            : loc.showAllReposCount(repos.length),
                        style: TextStyle(
                          color: AppTheme.primaryCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openUserRepositories,
                      icon: Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      label: Text(
                        loc.openInGithub,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              child: Center(
                child: TextButton.icon(
                  onPressed: _openUserRepositories,
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  label: Text(
                    loc.openInGithub,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ],
  ),
);
  }
}
