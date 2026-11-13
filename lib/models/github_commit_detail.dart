class GitHubCommitFile {
  final String filename;
  final String status; // modified, added, removed, renamed
  final int additions;
  final int deletions;
  final int changes;
  final String? patch;

  const GitHubCommitFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
    this.patch,
  });

  factory GitHubCommitFile.fromJson(Map<String, dynamic> json) {
    return GitHubCommitFile(
      filename: json['filename'] as String? ?? '',
      status: json['status'] as String? ?? 'modified',
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      changes: (json['changes'] as num?)?.toInt() ?? 0,
      patch: json['patch'] as String?,
    );
  }
}

class GitHubCommitDetail {
  final String sha;
  final String message;
  final String? authorName;
  final String? authorLogin;
  final String? authorAvatarUrl;
  final DateTime? date;
  final int additions;
  final int deletions;
  final int totalChanges;
  final List<GitHubCommitFile> files;

  const GitHubCommitDetail({
    required this.sha,
    required this.message,
    this.authorName,
    this.authorLogin,
    this.authorAvatarUrl,
    this.date,
    required this.additions,
    required this.deletions,
    required this.totalChanges,
    required this.files,
  });

  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  String get firstLineMessage {
    final firstLine = message.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : 'commit';
  }

  String get bodyMessage {
    final lines = message.split('\n');
    if (lines.length <= 1) return '';
    return lines.sublist(1).join('\n').trim();
  }

  factory GitHubCommitDetail.fromJson(Map<String, dynamic> json) {
    final commitObj = json['commit'] as Map<String, dynamic>? ?? {};
    final authorCommitObj = commitObj['author'] as Map<String, dynamic>?;
    final committerCommitObj = commitObj['committer'] as Map<String, dynamic>?;

    final dateStr =
        (committerCommitObj?['date'] ?? authorCommitObj?['date']) as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final authorUserObj = json['author'] as Map<String, dynamic>?;
    final authorLogin = authorUserObj?['login'] as String?;
    final authorAvatarUrl = authorUserObj?['avatar_url'] as String?;
    final authorName = (authorCommitObj?['name'] as String?) ?? authorLogin;

    final statsObj = json['stats'] as Map<String, dynamic>?;
    final additions = (statsObj?['additions'] as num?)?.toInt() ?? 0;
    final deletions = (statsObj?['deletions'] as num?)?.toInt() ?? 0;
    final totalChanges =
        (statsObj?['total'] as num?)?.toInt() ?? (additions + deletions);

    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final files = rawFiles
        .whereType<Map<String, dynamic>>()
        .map((f) => GitHubCommitFile.fromJson(f))
        .toList();

    return GitHubCommitDetail(
      sha: json['sha'] as String? ?? '',
      message: commitObj['message'] as String? ?? '',
      authorName: authorName,
      authorLogin: authorLogin,
      authorAvatarUrl: authorAvatarUrl,
      date: date?.toLocal(),
      additions: additions,
      deletions: deletions,
      totalChanges: totalChanges,
      files: files,
    );
  }
}
