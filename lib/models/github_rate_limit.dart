class GitHubRateLimit {
  final int limit;
  final int remaining;
  final int used;
  final DateTime resetTime;

  const GitHubRateLimit({
    required this.limit,
    required this.remaining,
    required this.used,
    required this.resetTime,
  });

  /// Rasio sisa kuota (1.0 = 100% utuh, 0.0 = 0% habis)
  double get remainingRatio =>
      limit > 0 ? (remaining / limit).clamp(0.0, 1.0) : 0.0;

  /// Persentase sisa kuota (100% jika belum terpakai, 0% jika habis)
  double get remainingPercentage => remainingRatio * 100;

  /// Persentase kuota yang telah digunakan
  double get usedPercentage =>
      limit > 0 ? ((used / limit).clamp(0.0, 1.0)) * 100 : 0.0;

  /// Teks waktu relatif hingga reset kuota
  String get resetCountdown {
    final now = DateTime.now();
    final diff = resetTime.difference(now);
    if (diff.isNegative) return 'Sedang mereset...';
    if (diff.inMinutes >= 60) {
      return '${diff.inHours} jam ${diff.inMinutes % 60} menit';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit';
    } else {
      return '${diff.inSeconds} detik';
    }
  }

  factory GitHubRateLimit.fromJson(Map<String, dynamic> json) {
    final rate =
        json['rate'] as Map<String, dynamic>? ??
        (json['resources'] as Map<String, dynamic>?)?['core']
            as Map<String, dynamic>? ??
        {};

    final limit = rate['limit'] as int? ?? 60;
    final remaining = rate['remaining'] as int? ?? 60;
    final used = rate['used'] as int? ?? (limit - remaining).clamp(0, limit);
    final resetSeconds =
        rate['reset'] as int? ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);

    return GitHubRateLimit(
      limit: limit,
      remaining: remaining,
      used: used,
      resetTime: DateTime.fromMillisecondsSinceEpoch(resetSeconds * 1000),
    );
  }

  factory GitHubRateLimit.defaultLimit({bool hasToken = false}) {
    final limit = hasToken ? 5000 : 60;
    return GitHubRateLimit(
      limit: limit,
      remaining: limit,
      used: 0,
      resetTime: DateTime.now().add(const Duration(hours: 1)),
    );
  }
}
