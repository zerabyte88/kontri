import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/github_repo.dart';
import '../services/github_api_service.dart';
import '../theme/app_theme.dart';

class RepoDetailScreen extends StatefulWidget {
  final GitHubRepo repo;
  final String? username;
  final GitHubApiService? apiService;

  const RepoDetailScreen({
    super.key,
    required this.repo,
    this.username,
    this.apiService,
  });

  @override
  State<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends State<RepoDetailScreen> {
  late final GitHubApiService _apiService;
  bool _isLoading = true;
  String? _readmeContent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? GitHubApiService();
    _fetchReadme();
  }

  String get _repoOwner {
    return widget.repo.owner ?? widget.username ?? '';
  }

  Future<void> _fetchReadme() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final owner = _repoOwner;
    if (owner.isEmpty) {
      setState(() {
        _isLoading = false;
        _readmeContent = null;
      });
      return;
    }

    try {
      final content = await _apiService.fetchRepositoryReadme(
        owner: owner,
        repo: widget.repo.name,
      );
      if (mounted) {
        setState(() {
          _readmeContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final loc = AppLocalizations.of(context);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.cannotOpenLink(url)),
              backgroundColor: AppTheme.accentRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  void _copyRepoUrl() {
    final url = widget.repo.htmlUrl.isNotEmpty
        ? widget.repo.htmlUrl
        : 'https://github.com/$_repoOwner/${widget.repo.name}';
    Clipboard.setData(ClipboardData(text: url));
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.repoUrlCopied),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
    final loc = AppLocalizations.of(context);
    final repoUrl = widget.repo.htmlUrl.isNotEmpty
        ? widget.repo.htmlUrl
        : 'https://github.com/$_repoOwner/${widget.repo.name}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.repo.name,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_repoOwner.isNotEmpty)
              Text(
                _repoOwner,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: loc.copyRepoUrl,
            color: AppTheme.textSecondary,
            onPressed: _copyRepoUrl,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            tooltip: loc.openInGithub,
            color: AppTheme.primaryCyan,
            onPressed: () => _openExternal(repoUrl),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Repo Overview Card
            _buildOverviewCard(loc, repoUrl),
            const SizedBox(height: 18),

            // 2. Readme Section Header
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: AppTheme.primaryCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.readmeTitle,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Readme Content Container
            _buildReadmeSection(loc, repoUrl),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(AppLocalizations loc, String repoUrl) {
    final langColor = _getLanguageColor(widget.repo.language);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book_outlined,
                  size: 20,
                  color: AppTheme.primaryCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.repo.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_repoOwner.isNotEmpty)
                      Text(
                        _repoOwner,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.repo.isFork)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border, width: 0.8),
                  ),
                  child: Text(
                    'Fork',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.repo.description != null &&
              widget.repo.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.repo.description!.trim(),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
          if (widget.repo.topics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.repo.topics.map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 14),

          // Metadata badges
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.repo.language != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: langColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.repo.language!,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppTheme.accentAmber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.repo.stargazersCount}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alt_route_rounded,
                    size: 15,
                    color: AppTheme.primaryViolet,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.repo.forksCount}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (widget.repo.openIssuesCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.adjust_rounded,
                      size: 14,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.repo.openIssuesCount}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              if (widget.repo.size > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.repo.formattedSize,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              if (widget.repo.license != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.balance_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.repo.license!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              if (widget.repo.defaultBranch != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fork_right_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.repo.defaultBranch!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.repo.relativeTimeAgo,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openExternal(repoUrl),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.4),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: AppTheme.primaryCyan,
              ),
              label: Text(
                loc.openInGithub,
                style: TextStyle(
                  color: AppTheme.primaryCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadmeSection(AppLocalizations loc, String repoUrl) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryCyan,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              loc.loadingReadme,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: AppTheme.accentOrange,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _fetchReadme,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.primaryCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(loc.retry),
            ),
          ],
        ),
      );
    }

    if (_readmeContent == null || _readmeContent!.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 36,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              loc.noReadmeFound,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => _openExternal(repoUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(loc.openInGithub),
            ),
          ],
        ),
      );
    }

    final branch = widget.repo.defaultBranch ?? 'main';
    final owner = _repoOwner;
    final imageBaseUrl = owner.isNotEmpty
        ? 'https://raw.githubusercontent.com/$owner/${widget.repo.name}/$branch/'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: MarkdownBody(
        data: _readmeContent!,
        selectable: true,
        imageDirectory: imageBaseUrl,
        onTapLink: (text, href, title) {
          if (href != null && href.isNotEmpty) {
            if (href.startsWith('#')) return;
            if (href.startsWith('http://') || href.startsWith('https://')) {
              _openExternal(href);
            } else if (owner.isNotEmpty) {
              final resolved = 'https://github.com/$owner/${widget.repo.name}/blob/$branch/$href';
              _openExternal(resolved);
            }
          }
        },
        sizedImageBuilder: (config) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                config.uri.toString(),
                width: config.width,
                height: config.height,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Image',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
          h1: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          h2: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          h3: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          h4: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          code: TextStyle(
            color: AppTheme.primaryCyan,
            backgroundColor: AppTheme.surfaceElevated,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          codeblockDecoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border, width: 0.8),
          ),
          codeblockPadding: const EdgeInsets.all(12),
          blockquote: TextStyle(
            color: AppTheme.textMuted,
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.primaryCyan, width: 3),
            ),
          ),
          a: TextStyle(
            color: AppTheme.primaryCyan,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.primaryCyan.withValues(alpha: 0.5),
          ),
          tableBorder: TableBorder.all(color: AppTheme.border, width: 0.8),
          tableHead: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
          tableBody: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.border, width: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
