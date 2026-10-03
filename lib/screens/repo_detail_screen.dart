import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/github_content_item.dart';
import '../models/github_repo.dart';
import '../services/github_api_service.dart';
import '../theme/app_theme.dart';
import 'file_viewer_screen.dart';

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

  // Tab State: 0 = README, 1 = Files
  int _selectedTab = 0;

  // README State
  bool _isLoadingReadme = true;
  String? _readmeContent;
  String? _readmeError;

  // Repository Contents State
  bool _isLoadingContents = false;
  String _currentPath = '';
  final List<String> _pathStack = [];
  List<GitHubContentItem> _contents = [];
  String? _contentsError;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? GitHubApiService();
    _fetchReadme();
  }

  String get _repoOwner {
    return widget.repo.owner ?? widget.username ?? '';
  }

  String get _defaultBranch {
    return widget.repo.defaultBranch ?? 'main';
  }

  Future<void> _fetchReadme() async {
    setState(() {
      _isLoadingReadme = true;
      _readmeError = null;
    });

    final owner = _repoOwner;
    if (owner.isEmpty) {
      setState(() {
        _isLoadingReadme = false;
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
          _isLoadingReadme = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _readmeError = e.toString();
          _isLoadingReadme = false;
        });
      }
    }
  }

  Future<void> _fetchContents([String path = '']) async {
    setState(() {
      _isLoadingContents = true;
      _contentsError = null;
    });

    final owner = _repoOwner;
    if (owner.isEmpty) {
      setState(() {
        _isLoadingContents = false;
        _contents = [];
      });
      return;
    }

    try {
      final items = await _apiService.fetchRepositoryContents(
        owner: owner,
        repo: widget.repo.name,
        path: path,
        ref: _defaultBranch,
      );
      if (mounted) {
        setState(() {
          _contents = items;
          _currentPath = path;
          _isLoadingContents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contentsError = e.toString();
          _isLoadingContents = false;
        });
      }
    }
  }

  void _navigateToDir(String dirPath) {
    _pathStack.add(_currentPath);
    _fetchContents(dirPath);
  }

  void _navigateUp() {
    if (_pathStack.isNotEmpty) {
      final prev = _pathStack.removeLast();
      _fetchContents(prev);
    } else if (_currentPath.isNotEmpty) {
      final segments = _currentPath.split('/');
      segments.removeLast();
      final parent = segments.join('/');
      _fetchContents(parent);
    }
  }

  void _openFile(GitHubContentItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerScreen(
          item: item,
          owner: _repoOwner,
          repo: widget.repo.name,
          ref: _defaultBranch,
          apiService: _apiService,
        ),
      ),
    );
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

  /// Normalizes image URLs from markdown or HTML tags into raw direct URLs
  String _normalizeImageUrl(String url, String owner, String repo, String branch) {
    var cleanUrl = url.trim();
    if (cleanUrl.startsWith('./')) {
      cleanUrl = cleanUrl.substring(2);
    }
    if (cleanUrl.startsWith('/') && !cleanUrl.startsWith('//')) {
      cleanUrl = cleanUrl.substring(1);
    }

    // Relative path: resolve against raw.githubusercontent.com
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$cleanUrl';
    }

    // GitHub webpage blob: convert to raw content URL
    if (cleanUrl.contains('github.com') && cleanUrl.contains('/blob/')) {
      cleanUrl = cleanUrl
          .replaceFirst('github.com', 'raw.githubusercontent.com')
          .replaceFirst('/blob/', '/');
    }

    return cleanUrl;
  }

  /// Preprocesses raw README markdown: converts HTML <img> tags and normalizes relative image paths
  String _preprocessReadme(String rawMarkdown, String owner, String repo, String branch) {
    var text = rawMarkdown;

    // 1. Convert HTML <img ... src="..." alt="..."> to Markdown ![alt](src)
    final imgRegex = RegExp(r'<img\s+[^>]*src=["'']([^"'']+)["''][^>]*>', caseSensitive: false);
    text = text.replaceAllMapped(imgRegex, (match) {
      final src = match.group(1) ?? '';
      final altMatch = RegExp(r'alt=["'']([^"'']*)["'']', caseSensitive: false).firstMatch(match.group(0) ?? '');
      final alt = altMatch?.group(1) ?? '';
      final normalizedSrc = _normalizeImageUrl(src, owner, repo, branch);
      return '![$alt]($normalizedSrc)';
    });

    // 2. Normalize standard Markdown images ![alt](src)
    final mdImgRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    text = text.replaceAllMapped(mdImgRegex, (match) {
      final alt = match.group(1) ?? '';
      var src = (match.group(2) ?? '').trim();

      String? title;
      if (src.contains(' "')) {
        final parts = src.split(' "');
        src = parts[0];
        title = parts.sublist(1).join(' "').replaceAll('"', '');
      }

      src = _normalizeImageUrl(src, owner, repo, branch);
      return title != null ? '![$alt]($src "$title")' : '![$alt]($src)';
    });

    return text;
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
            const SizedBox(height: 16),

            // 2. Navigation Segments: README vs Files
            _buildSegmentedTabBar(loc),
            const SizedBox(height: 14),

            // 3. Active Tab Content
            if (_selectedTab == 0)
              _buildReadmeSection(loc, repoUrl)
            else
              _buildFilesSection(loc),
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

  Widget _buildSegmentedTabBar(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              icon: Icons.article_outlined,
              label: loc.readmeTitle,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              index: 1,
              icon: Icons.folder_open_rounded,
              label: loc.filesTab,
              onTapAdditional: () {
                if (_contents.isEmpty && !_isLoadingContents) {
                  _fetchContents(_currentPath);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTapAdditional,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        if (onTapAdditional != null) {
          onTapAdditional();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppTheme.border, width: 0.8)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 0: README SECTION ---
  Widget _buildReadmeSection(AppLocalizations loc, String repoUrl) {
    if (_isLoadingReadme) {
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

    if (_readmeError != null) {
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
              _readmeError!,
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

    final branch = _defaultBranch;
    final owner = _repoOwner;
    final processedMarkdown = _preprocessReadme(
      _readmeContent!,
      owner,
      widget.repo.name,
      branch,
    );
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
        data: processedMarkdown,
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
          final url = config.uri.toString();
          final isSvg = url.toLowerCase().contains('.svg') || url.contains('img.shields.io');

          if (isSvg) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SvgPicture.network(
                url,
                width: config.width,
                height: config.height,
                placeholderBuilder: (_) => Container(
                  width: config.width ?? 80,
                  height: config.height ?? 20,
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
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

  // --- TAB 1: REPOSITORY FILES & CONTENTS SECTION ---
  Widget _buildFilesSection(AppLocalizations loc) {
    if (_isLoadingContents) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
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
              loc.loadingContents,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_contentsError != null) {
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
              _contentsError!,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _fetchContents(_currentPath),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.primaryCyan,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(loc.retry),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb header
            _buildBreadcrumbsBar(),
            Divider(height: 1, color: AppTheme.border),

            // File / Directory list
            if (_contents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Text(
                    loc.emptyDirectory,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contents.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppTheme.border.withValues(alpha: 0.5),
                  indent: 44,
                ),
                itemBuilder: (context, index) {
                  final item = _contents[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    leading: Icon(
                      item.iconData,
                      size: 19,
                      color: item.iconColor,
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: item.isDirectory
                            ? AppTheme.primaryCyan
                            : AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: item.isDirectory ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item.isDirectory
                        ? Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          )
                        : Text(
                            item.formattedSize,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                    onTap: () {
                      if (item.isDirectory) {
                        _navigateToDir(item.path);
                      } else {
                        _openFile(item);
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbsBar() {
    final segments = _currentPath.isEmpty ? <String>[] : _currentPath.split('/');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
      child: Row(
        children: [
          if (_currentPath.isNotEmpty)
            InkWell(
              onTap: _navigateUp,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ),
          InkWell(
            onTap: _currentPath.isNotEmpty ? () => _fetchContents('') : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_copy_outlined,
                    size: 14,
                    color: _currentPath.isEmpty
                        ? AppTheme.primaryCyan
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.repo.name,
                    style: TextStyle(
                      color: _currentPath.isEmpty
                          ? AppTheme.primaryCyan
                          : AppTheme.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (int i = 0; i < segments.length; i++) ...[
            Text(
              ' / ',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            InkWell(
              onTap: i == segments.length - 1
                  ? null
                  : () {
                      final path = segments.sublist(0, i + 1).join('/');
                      _fetchContents(path);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  segments[i],
                  style: TextStyle(
                    color: i == segments.length - 1
                        ? AppTheme.primaryCyan
                        : AppTheme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: i == segments.length - 1
                        ? FontWeight.w600
                        : FontWeight.w400,
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
