class TechNews {
  final int id;
  final String title;
  final String description;
  final String url;
  final String? coverImage;
  final String authorName;
  final String? authorAvatar;
  final String publishedDate;
  final int readingTimeMinutes;
  final List<String> tags;

  const TechNews({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.coverImage,
    required this.authorName,
    this.authorAvatar,
    required this.publishedDate,
    required this.readingTimeMinutes,
    required this.tags,
  });

  factory TechNews.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final tagList = json['tag_list'];
    List<String> tags = [];
    if (tagList is List) {
      tags = tagList.map((e) => e.toString()).toList();
    } else if (json['tags'] is String) {
      tags = (json['tags'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final rawCover = json['cover_image'] as String? ?? json['social_image'] as String?;

    return TechNews(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      coverImage: sanitizeImageUrl(rawCover),
      authorName: user?['name'] as String? ?? user?['username'] as String? ?? 'Tech Contributor',
      authorAvatar: user?['profile_image_90'] as String? ?? user?['profile_image'] as String?,
      publishedDate: json['readable_publish_date'] as String? ?? 'Terbaru',
      readingTimeMinutes: json['reading_time_minutes'] as int? ?? 3,
      tags: tags,
    );
  }

  /// Extracts direct CDN / S3 URLs from dev.to dynamic proxy wrappers
  /// preventing image timeouts and 403 blocks.
  static String? sanitizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    final match = RegExp(
      r'/https(?:%3A|:)(?:%2F|/)(?:%2F|/)(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match != null) {
      final inner = match.group(1);
      if (inner != null) {
        try {
          final decoded = Uri.decodeFull('https://$inner');
          if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
            return decoded;
          }
        } catch (_) {}
      }
    }
    return trimmed;
  }
}
