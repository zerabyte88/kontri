import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/tech_news.dart';
import '../theme/app_theme.dart';

class TechNewsCard extends StatelessWidget {
  final TechNews news;

  const TechNewsCard({
    super.key,
    required this.news,
  });

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.tryParse(news.url);
    if (uri != null) {
      final loc = AppLocalizations.of(context);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.cannotOpenLink(news.url)),
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

  @override
  Widget build(BuildContext context) {
    final hasCover = news.coverImage != null && news.coverImage!.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openArticle(context),
            splashColor: AppTheme.primaryCyan.withValues(alpha: 0.08),
            highlightColor: AppTheme.primaryCyan.withValues(alpha: 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCover)
                  Stack(
                    children: [
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: Image.network(
                          news.coverImage!,
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                          headers: const {
                            'User-Agent':
                                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 130,
                              color: AppTheme.surfaceElevated,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryCyan.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackThumbnail(),
                        ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.surface.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags row
                    if (news.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: news.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: AppTheme.border,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                color: AppTheme.primaryCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    if (news.description.isNotEmpty)
                      Text(
                        news.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Meta footer
                    Row(
                      children: [
                        if (news.authorAvatar != null && news.authorAvatar!.isNotEmpty)
                          ClipOval(
                            child: Image.network(
                              news.authorAvatar!,
                              width: 18,
                              height: 18,
                              cacheWidth: 60,
                              cacheHeight: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person_outline_rounded,
                                size: 15,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.person_outline_rounded,
                            size: 15,
                            color: AppTheme.textMuted,
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            news.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${news.readingTimeMinutes} ${AppLocalizations.of(context).minRead}',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFallbackThumbnail() {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceElevated,
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            child: Icon(
              Icons.terminal_rounded,
              size: 90,
              color: AppTheme.primaryCyan.withValues(alpha: 0.05),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.article_rounded,
                  size: 22,
                  color: AppTheme.primaryCyan,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'GitPulse Tech Digest',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
