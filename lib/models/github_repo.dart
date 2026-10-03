class GitHubRepo {
  final String name;
  final String? description;
  final String htmlUrl;
  final String? language;
  final int stargazersCount;
  final int forksCount;
  final bool isFork;
  final int size; // Size in KB
  final DateTime? updatedAt;
  final DateTime? pushedAt;
  final DateTime? createdAt;
  final String? defaultBranch;
  final int openIssuesCount;
  final List<String> topics;
  final String? license;

  GitHubRepo({
    required this.name,
    this.description,
    required this.htmlUrl,
    this.language,
    required this.stargazersCount,
    required this.forksCount,
    required this.isFork,
    this.size = 0,
    this.updatedAt,
    this.pushedAt,
    this.createdAt,
    this.defaultBranch,
    this.openIssuesCount = 0,
    this.topics = const [],
    this.license,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'] as List<dynamic>?;
    final List<String> topics = rawTopics != null
        ? rawTopics.map((e) => e.toString()).toList()
        : const [];
    final licenseObj = json['license'] as Map<String, dynamic>?;
    final licenseName = licenseObj?['spdx_id'] as String? ?? licenseObj?['name'] as String?;

    return GitHubRepo(
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      htmlUrl: json['html_url'] as String? ?? '',
      language: json['language'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      isFork: json['fork'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
      pushedAt: json['pushed_at'] != null
          ? DateTime.tryParse(json['pushed_at'] as String)?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      defaultBranch: json['default_branch'] as String?,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      topics: topics,
      license: (licenseName != null && licenseName != 'NOASSERTION') ? licenseName : null,
    );
  }

  /// Extracts repository owner from htmlUrl (e.g., https://github.com/torvalds/linux -> torvalds)
  String? get owner {
    try {
      final uri = Uri.tryParse(htmlUrl);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments[0];
      }
    } catch (_) {}
    return null;
  }

  /// Formatted repository size string (e.g. 512 KB, 14.2 MB)
  String get formattedSize {
    if (size < 1024) {
      return '$size KB';
    } else {
      return '${(size / 1024).toStringAsFixed(1)} MB';
    }
  }

  /// The timestamp of the latest commit pushed or repo update
  DateTime? get latestActivityDate => pushedAt ?? updatedAt ?? createdAt;

  /// Returns user-friendly Indonesian relative time (e.g., '2 jam lalu', '3 hari lalu')
  String get relativeTimeAgo {
    final date = latestActivityDate;
    if (date == null) return 'Tidak ada aktivitas';
    final diff = DateTime.now().difference(date);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} mnt lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 30) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months bln lalu';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years thn lalu';
    }
  }

  /// Whether there was commit activity within the past 14 days
  bool get isRecentlyActive {
    final date = latestActivityDate;
    if (date == null) return false;
    return DateTime.now().difference(date).inDays <= 14;
  }
}

