import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_localizations.dart';
import '../models/github_commit_detail.dart';
import '../models/github_commit_info.dart';
import '../models/github_repo.dart';
import '../services/github_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CommitDetailScreen extends StatefulWidget {
  final GitHubRepo repo;
  final String sha;
  final GitHubCommitInfo? initialCommitInfo;
  final GitHubApiService? apiService;

  const CommitDetailScreen({
    super.key,
    required this.repo,
    required this.sha,
    this.initialCommitInfo,
    this.apiService,
  });

  @override
  State<CommitDetailScreen> createState() => _CommitDetailScreenState();
}

class _CommitDetailScreenState extends State<CommitDetailScreen> {
  late final GitHubApiService _apiService;
  bool _isLoading = true;
  String? _error;
  GitHubCommitDetail? _detail;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? GitHubApiService();
    _fetchDetail();
  }

  String get _repoOwner => widget.repo.owner ?? '';

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final owner = _repoOwner;
    if (owner.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Repository owner not specified';
      });
      return;
    }

    try {
      final detail = await _apiService.fetchCommitDetail(
        owner,
        widget.repo.name,
        widget.sha,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copySha(String sha) {
    Clipboard.setData(ClipboardData(text: sha));
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primaryCyan.withValues(alpha: 0.38),
            width: 1.1,
          ),
        ),
        duration: const Duration(milliseconds: 2000),
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryCyan,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.shaCopied,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final repoFullName = _repoOwner.isNotEmpty
        ? '$_repoOwner/${widget.repo.name}'
        : widget.repo.name;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repoFullName,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              loc.commitDetailsTitle,
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
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: loc.copyCode,
            color: AppTheme.primaryCyan,
            onPressed: () => _copySha(widget.sha),
          ),
        ],
      ),
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.loadingContents,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppTheme.accentRed,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchDetail,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(loc.retry),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Center(
        child: Text(
          loc.noCommitsFound,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(detail, loc),
          const SizedBox(height: 14),
          _buildChangesMetricBar(detail, loc),
          const SizedBox(height: 14),
          for (final file in detail.files) ...[
            _buildFileDiffCard(file),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(GitHubCommitDetail detail, AppLocalizations loc) {
    return GlassCard(
      width: double.infinity,
      enableBlur: false,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.commit_rounded,
                        size: 15,
                        color: AppTheme.primaryCyan,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          detail.sha,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: AppTheme.primaryCyan,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copySha(detail.sha),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail.firstLineMessage,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (detail.bodyMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail.bodyMessage,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (detail.authorAvatarUrl != null &&
                  detail.authorAvatarUrl!.isNotEmpty)
                ClipOval(
                  child: Image.network(
                    detail.authorAvatarUrl!,
                    width: 26,
                    height: 26,
                    errorBuilder: (_, _, _) => CircleAvatar(
                      radius: 13,
                      backgroundColor: AppTheme.surfaceElevated,
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.authorName ?? detail.authorLogin ?? 'Author',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loc.formatRelativeTime(detail.date),
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangesMetricBar(
    GitHubCommitDetail detail,
    AppLocalizations loc,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 16,
                color: AppTheme.primaryCyan,
              ),
              const SizedBox(width: 8),
              Text(
                loc.filesChanged(detail.files.length),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${detail.additions}',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${detail.deletions}',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileDiffCard(GitHubCommitFile file) {
    Color statusBg;
    Color statusFg;
    String statusLabel;

    switch (file.status.toLowerCase()) {
      case 'added':
        statusBg = AppTheme.accentGreen.withValues(alpha: 0.15);
        statusFg = AppTheme.accentGreen;
        statusLabel = 'ADD';
        break;
      case 'removed':
        statusBg = AppTheme.accentRed.withValues(alpha: 0.15);
        statusFg = AppTheme.accentRed;
        statusLabel = 'DEL';
        break;
      case 'renamed':
        statusBg = AppTheme.primaryViolet.withValues(alpha: 0.15);
        statusFg = AppTheme.primaryViolet;
        statusLabel = 'REN';
        break;
      case 'modified':
      default:
        statusBg = AppTheme.accentAmber.withValues(alpha: 0.15);
        statusFg = AppTheme.accentAmber;
        statusLabel = 'MOD';
        break;
    }

    return GlassCard(
      width: double.infinity,
      enableBlur: false,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusFg,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.filename,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${file.additions} -${file.deletions}',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (file.patch != null && file.patch!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildDiffBox(file.patch!),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffBox(String patch) {
    final lines = patch.split('\n');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: lines.map((line) {
                Color textColor = AppTheme.textSecondary;
                Color? bgColor;

                if (line.startsWith('+') && !line.startsWith('+++')) {
                  textColor = AppTheme.accentGreen;
                  bgColor = AppTheme.accentGreen.withValues(alpha: 0.15);
                } else if (line.startsWith('-') && !line.startsWith('---')) {
                  textColor = AppTheme.accentRed;
                  bgColor = AppTheme.accentRed.withValues(alpha: 0.15);
                } else if (line.startsWith('@@')) {
                  textColor = AppTheme.primaryCyan;
                  bgColor = AppTheme.primaryCyan.withValues(alpha: 0.12);
                }

                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2.5,
                  ),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
