class GitHubCommitInfo {
  final String sha;
  final String message;
  final DateTime? date;

  const GitHubCommitInfo({
    required this.sha,
    required this.message,
    this.date,
  });

  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  String get firstLineMessage {
    final firstLine = message.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : 'commit';
  }

  factory GitHubCommitInfo.fromJson(Map<String, dynamic> json) {
    final commitObj = json['commit'] as Map<String, dynamic>? ?? {};
    final committerObj = commitObj['committer'] as Map<String, dynamic>?;
    final authorObj = commitObj['author'] as Map<String, dynamic>?;

    final dateStr = (committerObj?['date'] ?? authorObj?['date']) as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    return GitHubCommitInfo(
      sha: json['sha'] as String? ?? '',
      message: commitObj['message'] as String? ?? '',
      date: date?.toLocal(),
    );
  }
}
