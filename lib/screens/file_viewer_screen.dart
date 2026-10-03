import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../models/github_content_item.dart';
import '../services/github_api_service.dart';
import '../theme/app_theme.dart';

class FileViewerScreen extends StatefulWidget {
  final GitHubContentItem item;
  final String owner;
  final String repo;
  final String? ref;
  final GitHubApiService? apiService;

  const FileViewerScreen({
    super.key,
    required this.item,
    required this.owner,
    required this.repo,
    this.ref,
    this.apiService,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late final GitHubApiService _apiService;
  bool _isLoading = true;
  String? _content;
  String? _errorMessage;

  bool get _isImage => widget.item.isImage;
  bool get _isSvg => widget.item.isSvg;

  bool get _isBinary {
    if (_isImage) return false;
    final ext = widget.item.name.contains('.')
        ? widget.item.name.split('.').last.toLowerCase()
        : '';
    return [
      'zip', 'tar', 'gz', '7z', 'rar',
      'pdf', 'exe', 'dll', 'so', 'dylib',
      'bin', 'apk', 'aab', 'jar', 'class',
      'mp3', 'mp4', 'wav', 'mov', 'avi',
      'woff', 'woff2', 'ttf', 'otf', 'eot',
    ].contains(ext);
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? GitHubApiService();
    if (!_isImage && !_isBinary) {
      _loadFile();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.fetchFileContent(
        owner: widget.owner,
        repo: widget.repo,
        path: widget.item.path,
        ref: widget.ref,
        downloadUrl: widget.item.downloadUrl,
      );
      if (mounted) {
        setState(() {
          _content = res;
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

  void _copyContent(BuildContext context) {
    if (_content == null || _content!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _content!));
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.codeCopied),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final loc = AppLocalizations.of(context);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.cannotOpenLink(url)),
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
    final loc = AppLocalizations.of(context);
    final rawUrl = widget.item.downloadUrl ??
        'https://raw.githubusercontent.com/${widget.owner}/${widget.repo}/${widget.ref ?? 'main'}/${widget.item.path}';
    final githubWebUrl = widget.item.htmlUrl ??
        'https://github.com/${widget.owner}/${widget.repo}/blob/${widget.ref ?? 'main'}/${widget.item.path}';

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
              widget.item.name,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.item.path,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_content != null && _content!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              tooltip: loc.copyCode,
              color: AppTheme.textSecondary,
              onPressed: () => _copyContent(context),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            tooltip: loc.openInBrowser,
            color: AppTheme.primaryCyan,
            onPressed: () => _openExternal(context, githubWebUrl),
          ),
        ],
      ),
      body: _buildBody(loc, rawUrl, githubWebUrl),
    );
  }

  Widget _buildBody(AppLocalizations loc, String rawUrl, String githubWebUrl) {
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
              loc.loadingFile,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 36, color: AppTheme.accentRed),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceElevated,
                  foregroundColor: AppTheme.primaryCyan,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(loc.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_isImage) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(12),
                child: _isSvg
                    ? SvgPicture.network(
                        rawUrl,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      )
                    : Image.network(
                        rawUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              loc.failedToOpenLink(''),
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.item.name} (${widget.item.formattedSize})',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_isBinary) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                widget.item.name,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.formattedSize,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                loc.cannotPreviewBinary,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _openExternal(context, githubWebUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(loc.openInBrowser),
              ),
            ],
          ),
        ),
      );
    }

    final lines = (_content ?? '').split('\n');
    final totalLines = lines.length;

    return Column(
      children: [
        // File telemetry bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
          ),
          child: Row(
            children: [
              Icon(widget.item.iconData, size: 15, color: widget.item.iconColor),
              const SizedBox(width: 8),
              Text(
                '$totalLines lines • ${widget.item.formattedSize}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Code Viewer with line numbers
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers column
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(totalLines, (index) {
                        return SizedBox(
                          height: 20,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.6),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Divider between line numbers and code
                  Container(
                    width: 1,
                    height: (totalLines * 20).toDouble(),
                    color: AppTheme.border.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),

                  // Code lines column
                  SelectableText(
                    _content ?? '',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.37,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
