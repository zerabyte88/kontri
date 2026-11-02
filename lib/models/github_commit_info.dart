class GitHubCommitInfo {
  final String sha;
  final String message;
  final DateTime? date;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? authorLogin;

  const GitHubCommitInfo({
    required this.sha,
    required this.message,
    this.date,
    this.authorName,
    this.authorAvatarUrl,
    this.authorLogin,
  });

  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  String get firstLineMessage {
    final firstLine = message.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : 'commit';
  }

  /// User-friendly relative time ago
  String get relativeTimeAgo {
    if (date == null) return 'Tidak ada aktivitas';
    final diff = DateTime.now().difference(date!);

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

  factory GitHubCommitInfo.fromJson(Map<String, dynamic> json) {
    final commitObj = json['commit'] as Map<String, dynamic>? ?? {};
    final committerObj = commitObj['committer'] as Map<String, dynamic>?;
    final authorCommitObj = commitObj['author'] as Map<String, dynamic>?;

    final dateStr =
        (committerObj?['date'] ?? authorCommitObj?['date']) as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final authorUserObj = json['author'] as Map<String, dynamic>?;
    final authorLogin = authorUserObj?['login'] as String?;
    final authorAvatarUrl = authorUserObj?['avatar_url'] as String?;
    final authorName = (authorCommitObj?['name'] as String?) ?? authorLogin;

    return GitHubCommitInfo(
      sha: json['sha'] as String? ?? '',
      message: commitObj['message'] as String? ?? '',
      date: date?.toLocal(),
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorLogin: authorLogin,
    );
  }
}
