import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Reusable markdown viewer tailored for GitHub READMEs.
///
/// Features automatic badge/SVG detection, HTML badge parsing,
/// relative URL normalization, and theme-conforming styling.
class ReadmeMarkdownView extends StatelessWidget {
  final String markdown;
  final String owner;
  final String repo;
  final String branch;
  final void Function(String url)? onOpenUrl;

  const ReadmeMarkdownView({
    super.key,
    required this.markdown,
    required this.owner,
    required this.repo,
    this.branch = 'main',
    this.onOpenUrl,
  });

  /// Normalizes relative or GitHub blob image URLs to raw.githubusercontent.com.
  static String normalizeImageUrl(
    String url,
    String owner,
    String repo,
    String branch,
  ) {
    var cleanUrl = url.trim();
    if (cleanUrl.startsWith('./')) {
      cleanUrl = cleanUrl.substring(2);
    }
    if (cleanUrl.startsWith('/') && !cleanUrl.startsWith('//')) {
      cleanUrl = cleanUrl.substring(1);
    }

    // Relative path: resolve against raw.githubusercontent.com
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      if (owner.isNotEmpty && repo.isNotEmpty) {
        return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$cleanUrl';
      }
      return cleanUrl;
    }

    // GitHub webpage blob: convert to raw content URL
    if (cleanUrl.contains('github.com') && cleanUrl.contains('/blob/')) {
      cleanUrl = cleanUrl
          .replaceFirst('github.com', 'raw.githubusercontent.com')
          .replaceFirst('/blob/', '/');
    }

    return cleanUrl;
  }

  /// Extracts width and height from HTML attributes and returns a markdown fragment (e.g. `#120x120`).
  static String _extractDimensions(String attrs) {
    final widthMatch = RegExp(
      r"""width=["']?(\d+)["']?""",
      caseSensitive: false,
    ).firstMatch(attrs);
    final heightMatch = RegExp(
      r"""height=["']?(\d+)["']?""",
      caseSensitive: false,
    ).firstMatch(attrs);
    final w = widthMatch?.group(1);
    final h = heightMatch?.group(1);
    if (w != null && h != null) return '#${w}x$h';
    if (w != null) return '#${w}x$w';
    if (h != null) return '#${h}x$h';
    return '';
  }

  /// Preprocesses markdown string: converts HTML <a><img/></a> badges and standalone <img>
  /// tags to Markdown format, strips HTML div/p align wrappers, and normalizes image paths.
  static String preprocessMarkdown(
    String raw,
    String owner,
    String repo,
    String branch,
  ) {
    var text = raw;

    // 1. Convert <a ... href="..."><img ... src="..." alt="..."></a> to [![alt](normalized_src)](href)
    final linkedImgRegex = RegExp(
      r"""<a\s+[^>]*href=["']([^"']+)["'][^>]*>\s*<img\s+([^>]+)>\s*<\/a>""",
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    text = text.replaceAllMapped(linkedImgRegex, (match) {
      final href = match.group(1) ?? '';
      final imgAttrs = match.group(2) ?? '';

      final srcMatch = RegExp(
        r"""src=["']([^"']+)["']""",
        caseSensitive: false,
      ).firstMatch(imgAttrs);
      if (srcMatch == null) return match.group(0)!;
      final src = srcMatch.group(1) ?? '';

      final altMatch = RegExp(
        r"""alt=["']([^"']*)["']""",
        caseSensitive: false,
      ).firstMatch(imgAttrs);
      final alt = altMatch?.group(1) ?? '';

      var normalizedSrc = normalizeImageUrl(src, owner, repo, branch);
      final dims = _extractDimensions(imgAttrs);
      if (dims.isNotEmpty && !normalizedSrc.contains('#')) {
        normalizedSrc = '$normalizedSrc$dims';
      }
      return '[![$alt]($normalizedSrc)]($href)';
    });

    // 2. Convert standalone HTML <img ...> to ![alt](normalized_src)
    final standaloneImgRegex = RegExp(
      r"""<img\s+([^>]+)>""",
      caseSensitive: false,
    );
    text = text.replaceAllMapped(standaloneImgRegex, (match) {
      final imgAttrs = match.group(1) ?? '';

      final srcMatch = RegExp(
        r"""src=["']([^"']+)["']""",
        caseSensitive: false,
      ).firstMatch(imgAttrs);
      if (srcMatch == null) return match.group(0)!;
      final src = srcMatch.group(1) ?? '';

      final altMatch = RegExp(
        r"""alt=["']([^"']*)["']""",
        caseSensitive: false,
      ).firstMatch(imgAttrs);
      final alt = altMatch?.group(1) ?? '';

      var normalizedSrc = normalizeImageUrl(src, owner, repo, branch);
      final dims = _extractDimensions(imgAttrs);
      if (dims.isNotEmpty && !normalizedSrc.contains('#')) {
        normalizedSrc = '$normalizedSrc$dims';
      }
      return '![$alt]($normalizedSrc)';
    });

    // 3. Convert remaining inline HTML tags to Markdown
    // 3a. <strong> and <b> to **text**
    text = text.replaceAllMapped(
      RegExp(
        r'<(?:strong|b)\b[^>]*>(.*?)<\/(?:strong|b)>',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '**${m.group(1)}**',
    );

    // 3b. <em> and <i> to *text*
    text = text.replaceAllMapped(
      RegExp(
        r'<(?:em|i)\b[^>]*>(.*?)<\/(?:em|i)>',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '*${m.group(1)}*',
    );

    // 3c. <code> to `code`
    text = text.replaceAllMapped(
      RegExp(r'<code\b[^>]*>(.*?)<\/code>', caseSensitive: false, dotAll: true),
      (m) => '`${m.group(1)}`',
    );

    // 3d. <a href="url">text</a> to [text](url)
    text = text.replaceAllMapped(
      RegExp(
        r"""<a\s+[^>]*href=["']([^"']*)["'][^>]*>(.*?)<\/a>""",
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '[${m.group(2)}](${m.group(1)})',
    );

    // 3e. <br> to markdown line break
    text = text.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '  \n');

    // 3f. GitHub Alert callouts: [!NOTE], [!WARNING], [!TIP], [!IMPORTANT], [!CAUTION]
    text = text.replaceAllMapped(
      RegExp(r'\[!(WARNING|CAUTION)\]', caseSensitive: false),
      (m) => '**⚠️ ${m.group(1)?.toUpperCase()}:**',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[!(NOTE|INFO)\]', caseSensitive: false),
      (m) => '**ℹ️ ${m.group(1)?.toUpperCase()}:**',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[!(TIP)\]', caseSensitive: false),
      (m) => '**💡 ${m.group(1)?.toUpperCase()}:**',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[!(IMPORTANT)\]', caseSensitive: false),
      (m) => '**❗ ${m.group(1)?.toUpperCase()}:**',
    );

    // 4. Strip <p align="...">, </p>, <div align="...">, </div>, <center>, </center> wrappers
    text = text.replaceAll(
      RegExp(r'<\/?(p|div|center)(\s+[^>]*)?>', caseSensitive: false),
      '',
    );

    // 5. Clean up leading spaces that would trigger accidental markdown codeblocks
    final lines = text.split('\n');
    final cleanedLines = lines.map((line) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') ||
          trimmed.startsWith('![') ||
          trimmed.startsWith('[') ||
          trimmed.startsWith('**') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('>') ||
          trimmed.startsWith('<')) {
        return trimmed;
      }
      return line;
    }).toList();
    text = cleanedLines.join('\n');

    // 6. Normalize standard Markdown images ![alt](src)
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

      src = normalizeImageUrl(src, owner, repo, branch);
      return title != null ? '![$alt]($src "$title")' : '![$alt]($src)';
    });

    return text;
  }

  /// Determines whether the given image URL points to an SVG, badge, or shields service.
  static bool isSvgOrBadgeUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.webp')) {
      return false;
    }
    const badgeDomains = [
      '.svg',
      'img.shields.io',
      'shields.io',
      'github-readme-stats',
      'badge.fury.io',
      'badgen.net',
      'komarev.com/ghpvc',
      'github-profile-trophy',
      'codecov.io',
      'codacy.com',
      'travis-ci',
      'camo.githubusercontent.com',
    ];
    for (final domain in badgeDomains) {
      if (lower.contains(domain)) return true;
    }
    return false;
  }

  /// Determines whether the given image URL is a badge from known services or endpoints.
  static bool isBadgeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('shields.io') ||
        lower.contains('badgen.net') ||
        lower.contains('badge.fury.io') ||
        lower.contains('/badge') ||
        lower.contains('badge.svg') ||
        lower.contains('komarev.com/ghpvc') ||
        lower.contains('codecov.io') ||
        lower.contains('codacy.com') ||
        lower.contains('travis-ci') ||
        lower.contains('circleci.com') ||
        lower.contains('style=flat') ||
        lower.contains('style=shield');
  }

  Widget _buildPlaceholder(double? width, double? height) {
    final isCompact = height != null && height <= 24;
    return Container(
      width: width ?? 80,
      height: height ?? 20,
      padding: EdgeInsets.all(isCompact ? 2 : 4),
      child: Center(
        child: SizedBox(
          width: isCompact ? 10 : 14,
          height: isCompact ? 10 : 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppTheme.primaryCyan,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
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
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) return;
    if (href.startsWith('#')) return;

    String resolvedUrl = href;
    if (!resolvedUrl.startsWith('http://') &&
        !resolvedUrl.startsWith('https://')) {
      if (owner.isNotEmpty && repo.isNotEmpty) {
        resolvedUrl = 'https://github.com/$owner/$repo/blob/$branch/$href';
      }
    }

    if (onOpenUrl != null) {
      onOpenUrl!(resolvedUrl);
      return;
    }

    final uri = Uri.tryParse(resolvedUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final processedMarkdown = preprocessMarkdown(markdown, owner, repo, branch);
    final imageBaseUrl = (owner.isNotEmpty && repo.isNotEmpty)
        ? 'https://raw.githubusercontent.com/$owner/$repo/$branch/'
        : null;

    return MarkdownBody(
      data: processedMarkdown,
      selectable: true,
      imageDirectory: imageBaseUrl,
      onTapLink: (text, href, title) => _handleLinkTap(href),
      sizedImageBuilder: (config) {
        final rawUrl = config.uri.toString();
        var url = rawUrl.split('#').first;

        // Shields.io SVG workaround: convert shields.io URLs to .png format
        // shields.io natively serves crisp pixel-perfect PNG badges, bypassing the flutter_svg text-scaling bug.
        if (url.contains('img.shields.io') ||
            url.contains('shields.io/badge/')) {
          if (url.contains('.svg')) {
            url = url.replaceFirst('.svg', '.png');
          } else if (!url.contains('.png')) {
            final qIdx = url.indexOf('?');
            if (qIdx != -1) {
              url = '${url.substring(0, qIdx)}.png${url.substring(qIdx)}';
            } else {
              url = '$url.png';
            }
          }
        }

        final isSvg = isSvgOrBadgeUrl(url);
        final isBadge = isBadgeUrl(url);
        final isIconOrLogo =
            !isBadge &&
            ((config.alt?.toLowerCase().contains('logo') ?? false) ||
                (config.alt?.toLowerCase().contains('icon') ?? false) ||
                (config.alt?.toLowerCase().contains('banner') ?? false) ||
                url.toLowerCase().contains('icon') ||
                url.toLowerCase().contains('logo') ||
                url.toLowerCase().contains('banner') ||
                rawUrl.contains('#center'));

        final double? targetWidth =
            config.width ?? (isIconOrLogo ? 100.0 : null);
        final double? targetHeight =
            config.height ?? (isBadge ? 20.0 : (isIconOrLogo ? 100.0 : null));

        final BoxConstraints constraints = isBadge
            ? BoxConstraints(
                maxHeight: config.height ?? 20.0,
                maxWidth: config.width ?? 220.0,
              )
            : isIconOrLogo
            ? BoxConstraints(
                maxHeight: config.height != null ? config.height! + 10 : 130.0,
                maxWidth: config.width != null ? config.width! + 10 : 130.0,
              )
            : BoxConstraints(
                maxHeight: config.height ?? 320.0,
                maxWidth: config.width ?? double.infinity,
              );

        final EdgeInsets padding = isBadge
            ? const EdgeInsets.only(right: 5, bottom: 6)
            : const EdgeInsets.symmetric(vertical: 6);

        final Widget imageWidget;
        if (isSvg) {
          imageWidget = SvgPicture.network(
            url,
            width: targetWidth,
            height: targetHeight,
            fit: BoxFit.contain,
            headers: const {'User-Agent': 'Kontri-App'},
            placeholderBuilder: (_) =>
                _buildPlaceholder(targetWidth, targetHeight),
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                url,
                width: targetWidth,
                height: targetHeight,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => _buildErrorWidget(),
              );
            },
          );
        } else {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(isBadge ? 3 : 8),
            child: Image.network(
              url,
              width: targetWidth,
              height: targetHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return SvgPicture.network(
                  url,
                  width: targetWidth,
                  height: targetHeight,
                  fit: BoxFit.contain,
                  headers: const {'User-Agent': 'Kontri-App'},
                  placeholderBuilder: (_) =>
                      _buildPlaceholder(targetWidth, targetHeight),
                  errorBuilder: (ctx, err, st) => _buildErrorWidget(),
                );
              },
            ),
          );
        }

        if (isIconOrLogo) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ConstrainedBox(
                constraints: constraints,
                child: imageWidget,
              ),
            ),
          );
        }

        return Padding(
          padding: padding,
          child: ConstrainedBox(constraints: constraints, child: imageWidget),
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
        tableBody: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
        ),
      ),
    );
  }
}
