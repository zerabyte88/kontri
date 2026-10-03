import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/github_repo.dart';
import '../screens/repo_detail_screen.dart';
import '../services/github_api_service.dart';
import '../theme/app_theme.dart';

class RepoTile extends StatelessWidget {
  final GitHubRepo repo;
  final String? username;
  final GitHubApiService? apiService;
  final VoidCallback? onTap;

  const RepoTile({
    super.key,
    required this.repo,
    this.username,
    this.apiService,
    this.onTap,
  });

  void _openRepoDetails(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepoDetailScreen(
          repo: repo,
          username: username,
          apiService: apiService,
        ),
      ),
    );
  }

  Future<void> _openRepoExternal(BuildContext context) async {
    final targetUrl = repo.htmlUrl.isNotEmpty
        ? repo.htmlUrl
        : 'https://github.com/${repo.name}';
    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      final loc = AppLocalizations.of(context);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.cannotOpenLink(targetUrl)),
              backgroundColor: AppTheme.accentRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.failedToOpenLink(e.toString())),
              backgroundColor: AppTheme.accentRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Authentic language color mapper for common programming languages
  Color _getLanguageColor(String? language) {
    switch (language?.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'flutter':
        return const Color(0xFF02569B);
      case 'javascript':
        return const Color(0xFFF1E05A);
      case 'typescript':
        return const Color(0xFF3178C6);
      case 'python':
        return const Color(0xFF3572A5);
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
        return const Color(0xFF563D7C);
      case 'kotlin':
        return const Color(0xFFA97BFF);
      case 'swift':
        return const Color(0xFFF05138);
      case 'rust':
        return const Color(0xFFDEA584);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'c++':
      case 'cpp':
        return const Color(0xFFF34B7D);
      case 'c':
        return const Color(0xFF555555);
      case 'java':
        return const Color(0xFFB07219);
      case 'php':
        return const Color(0xFF4F5D95);
      case 'ruby':
        return const Color(0xFF701516);
      case 'shell':
      case 'bash':
        return const Color(0xFF89E051);
      default:
        return AppTheme.primaryCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langColor = _getLanguageColor(repo.language);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openRepoDetails(context),
            splashColor: AppTheme.primaryCyan.withValues(alpha: 0.10),
            highlightColor: AppTheme.primaryCyan.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repo.name,
                          style: TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (repo.isFork)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border, width: 0.8),
                          ),
                          child: Text(
                            'Fork',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      InkResponse(
                        radius: 16,
                        onTap: () => _openRepoExternal(context),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
          if (repo.description != null && repo.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              repo.description!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (repo.language != null && repo.language!.isNotEmpty) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: langColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        repo.language!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.star_outline_rounded,
                    size: 15,
                    color: AppTheme.accentAmber,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${repo.stargazersCount}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.call_split_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${repo.forksCount}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: repo.isRecentlyActive
                      ? AppTheme.accentGreen.withValues(alpha: 0.10)
                      : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: repo.isRecentlyActive
                        ? AppTheme.accentGreen.withValues(alpha: 0.25)
                        : AppTheme.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        repo.isRecentlyActive
                            ? Icons.update_rounded
                            : Icons.history_rounded,
                        size: 11,
                        color: repo.isRecentlyActive
                            ? AppTheme.accentGreen
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context).formatRelativeTime(repo.latestActivityDate),
                          style: TextStyle(
                            color: repo.isRecentlyActive
                                ? AppTheme.accentGreen
                                : AppTheme.textMuted,
                            fontSize: 10.5,
                            fontWeight: repo.isRecentlyActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
),
);
  }
}
