import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/contribution_stats.dart';
import '../models/github_rate_limit.dart';
import '../models/github_repo.dart';
import '../models/github_user.dart';
import '../models/user_stats.dart';

class GitHubApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRateLimit;
  final bool isNotFound;

  GitHubApiException(
    this.message, {
    this.statusCode,
    this.isRateLimit = false,
    this.isNotFound = false,
  });

  @override
  String toString() => message;
}

class GitHubApiService {
  static const String _baseUrl = 'https://api.github.com';
  static const Duration _timeoutDuration = Duration(seconds: 15);
  final http.Client _client;
  String? personalAccessToken;
  GitHubRateLimit? _lastRateLimit;
  final Map<String, UserStats> _statsCache = {};

  GitHubApiService({http.Client? client, this.personalAccessToken})
      : _client = client ?? http.Client();

  GitHubRateLimit? get lastRateLimit => _lastRateLimit;

  void clearCache() => _statsCache.clear();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitPulse-Mobile-App',
    };
    if (personalAccessToken != null && personalAccessToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${personalAccessToken!.trim()}';
    }
    return headers;
  }

  void _updateRateLimitFromHeaders(Map<String, String> headers) {
    final limitStr = headers['x-ratelimit-limit'];
    final remainingStr = headers['x-ratelimit-remaining'];
    final resetStr = headers['x-ratelimit-reset'];
    final usedStr = headers['x-ratelimit-used'];

    if (limitStr != null && remainingStr != null) {
      final limit = int.tryParse(limitStr) ?? 60;
      final remaining = int.tryParse(remainingStr) ?? 60;
      final used = usedStr != null
          ? (int.tryParse(usedStr) ?? (limit - remaining))
          : (limit - remaining);
      final resetSeconds = resetStr != null ? int.tryParse(resetStr) : null;
      final resetTime = resetSeconds != null
          ? DateTime.fromMillisecondsSinceEpoch(resetSeconds * 1000)
          : DateTime.now().add(const Duration(hours: 1));

      _lastRateLimit = GitHubRateLimit(
        limit: limit,
        remaining: remaining.clamp(0, limit),
        used: used.clamp(0, limit),
        resetTime: resetTime,
      );
    }
  }

  Future<GitHubRateLimit> fetchRateLimit() async {
    try {
      final uri = Uri.parse('$_baseUrl/rate_limit');
      final res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rateLimit = GitHubRateLimit.fromJson(data);
        _lastRateLimit = rateLimit;
        return rateLimit;
      }
    } catch (_) {
      // Ignored: fallback to cached or default
    }

    return _lastRateLimit ??
        GitHubRateLimit.defaultLimit(
          hasToken: personalAccessToken != null && personalAccessToken!.trim().isNotEmpty,
        );
  }

  Future<String?> fetchRepositoryReadme({
    required String owner,
    required String repo,
  }) async {
    final cleanOwner = owner.trim();
    final cleanRepo = repo.trim();
    if (cleanOwner.isEmpty || cleanRepo.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/repos/$cleanOwner/$cleanRepo/readme');
      final res = await _client.get(uri, headers: _headers).timeout(_timeoutDuration);
      _updateRateLimitFromHeaders(res.headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final content = data['content'] as String?;
        final encoding = data['encoding'] as String?;

        if (content != null && encoding == 'base64') {
          final cleanBase64 = content.replaceAll(RegExp(r'\s+'), '');
          return utf8.decode(base64.decode(cleanBase64));
        } else if (content != null) {
          return content;
        }
      } else if (res.statusCode == 404) {
        return null;
      } else if (res.statusCode == 403 || res.statusCode == 429) {
        throw GitHubApiException(
          'Batas kuota token / API telah habis.',
          statusCode: res.statusCode,
          isRateLimit: true,
        );
      }
    } on SocketException {
      throw GitHubApiException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw GitHubApiException('Koneksi timeout saat memuat README.');
    } catch (e) {
      if (e is GitHubApiException) rethrow;
      return null;
    }
    return null;
  }

  Future<ContributionStats?> _fetchContributions(String username) async {
    try {
      final uri = Uri.parse('https://github-contributions-api.jogruber.de/v4/$username');
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ContributionStats.fromContributionsApi(data);
      }
    } catch (_) {
      // Ignored: will fallback to event-based calculation
    }
    return null;
  }

  Future<UserStats> fetchUserStats(String username, {bool forceRefresh = false}) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      throw GitHubApiException('Username GitHub tidak boleh kosong.');
    }

    final cacheKey = cleanUsername.toLowerCase();
    if (!forceRefresh && _statsCache.containsKey(cacheKey)) {
      return _statsCache[cacheKey]!;
    }

    try {
      // Kick off contributions fetch in background early
      final contribFuture = _fetchContributions(cleanUsername);

      // Fetch User Profile, Repositories, and Public Events concurrently for maximum responsiveness
      final userUri = Uri.parse('$_baseUrl/users/$cleanUsername');
      final reposUri = Uri.parse(
          '$_baseUrl/users/$cleanUsername/repos?per_page=100&sort=updated');
      final eventsUri =
          Uri.parse('$_baseUrl/users/$cleanUsername/events/public?per_page=100');

      final responses = await Future.wait([
        _client.get(userUri, headers: _headers).timeout(_timeoutDuration),
        _client.get(reposUri, headers: _headers).timeout(_timeoutDuration),
        _client.get(eventsUri, headers: _headers).timeout(_timeoutDuration),
      ]);

      final userRes = responses[0];
      final reposRes = responses[1];
      final eventsRes = responses[2];

      _updateRateLimitFromHeaders(userRes.headers);
      _updateRateLimitFromHeaders(reposRes.headers);
      _updateRateLimitFromHeaders(eventsRes.headers);

      if (userRes.statusCode == 404) {
        throw GitHubApiException(
          'Pengguna "$cleanUsername" tidak ditemukan di GitHub.',
          statusCode: 404,
          isNotFound: true,
        );
      } else if (userRes.statusCode == 403 ||
          userRes.statusCode == 429 ||
          reposRes.statusCode == 403 ||
          reposRes.statusCode == 429 ||
          eventsRes.statusCode == 403 ||
          eventsRes.statusCode == 429 ||
          (_lastRateLimit != null && _lastRateLimit!.remaining == 0)) {
        final resetMsg = _lastRateLimit != null
            ? ' (Reset dalam ${_lastRateLimit!.resetCountdown})'
            : '';
        throw GitHubApiException(
          'Batas kuota token / API Anda telah habis$resetMsg. Masukkan atau ganti token di pengaturan.',
          statusCode: (userRes.statusCode == 403 || userRes.statusCode == 429)
              ? userRes.statusCode
              : 403,
          isRateLimit: true,
        );
      } else if (userRes.statusCode != 200) {
        throw GitHubApiException(
          'Gagal memuat profil (${userRes.statusCode}): ${userRes.reasonPhrase}',
          statusCode: userRes.statusCode,
        );
      }

      final userData = jsonDecode(userRes.body) as Map<String, dynamic>;
      final user = GitHubUser.fromJson(userData);

      // Process Repositories
      final List<GitHubRepo> repos = [];
      if (reposRes.statusCode == 200) {
        final List<dynamic> reposData = jsonDecode(reposRes.body) as List<dynamic>;
        for (final item in reposData) {
          if (item is Map<String, dynamic>) {
            repos.add(GitHubRepo.fromJson(item));
          }
        }
      }

      // Sort repos by stars descending
      repos.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));

      // Process Public Events for activity analysis
      final List<Map<String, dynamic>> events = [];
      if (eventsRes.statusCode == 200) {
        final List<dynamic> eventsData = jsonDecode(eventsRes.body) as List<dynamic>;
        for (final item in eventsData) {
          if (item is Map<String, dynamic>) {
            events.add(item);
          }
        }
      }

      // 4. Fetch Language breakdown from active repositories
      final nonForkRepos = repos.where((r) => !r.isFork).toList();
      final Map<String, int> aggregatedLanguages = {};

      if (nonForkRepos.isNotEmpty) {
        // Prioritize repositories by size so the most significant codebases are captured
        final prioritizedRepos = List<GitHubRepo>.from(nonForkRepos)
          ..sort((a, b) => b.size.compareTo(a.size));

        // Limit queries to avoid exhausting unauthenticated rate limits (max 8 unauthenticated, 25 authenticated)
        final maxRepoQueries = personalAccessToken != null ? 25 : 8;
        final targetRepos = prioritizedRepos.take(maxRepoQueries).toList();

        final futures = targetRepos.map((repo) async {
          try {
            final langUri = Uri.parse('$_baseUrl/repos/$cleanUsername/${repo.name}/languages');
            final langRes = await _client.get(langUri, headers: _headers).timeout(const Duration(seconds: 8));
            _updateRateLimitFromHeaders(langRes.headers);
            if (langRes.statusCode == 200) {
              final Map<String, dynamic> data = jsonDecode(langRes.body) as Map<String, dynamic>;
              return data.map((k, v) => MapEntry(k, (v as num).toInt()));
            }
          } catch (_) {
            // Silently ignore individual repo language fetch issues
          }
          return <String, int>{};
        });

        final results = await Future.wait(futures);
        for (final repoLangs in results) {
          repoLangs.forEach((lang, bytes) {
            aggregatedLanguages[lang] = (aggregatedLanguages[lang] ?? 0) + bytes;
          });
        }
      }

      // Await contribution stats or fallback to public events
      final fetchedContributions = await contribFuture;
      final contributionStats = fetchedContributions ?? ContributionStats.fromEvents(events);

      final calculated = UserStats.calculate(
        user: user,
        repos: repos,
        publicEvents: events,
        contributionStats: contributionStats,
        aggregatedLanguages: aggregatedLanguages,
      );
      _statsCache[cacheKey] = calculated;
      return calculated;
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission')) {
        throw GitHubApiException('Izin akses internet belum diaktifkan pada sistem aplikasi.');
      }
      throw GitHubApiException('Tidak ada koneksi internet. Periksa jaringan kamu.');
    } on TimeoutException {
      throw GitHubApiException('Koneksi timeout. Server GitHub tidak merespons tepat waktu.');
    } on http.ClientException {
      throw GitHubApiException('Gagal berkomunikasi dengan server GitHub.');
    } catch (e) {
      if (e is GitHubApiException) rethrow;
      throw GitHubApiException('Terjadi kesalahan tak terduga: $e');
    }
  }
}
