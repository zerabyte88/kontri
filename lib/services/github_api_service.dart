import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/contribution_stats.dart';
import '../models/github_content_item.dart';
import '../models/github_rate_limit.dart';
import '../models/github_repo.dart';
import '../models/github_user.dart';
import '../models/user_stats.dart';
import 'storage_service.dart';

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
  final StorageService? storageService;
  GitHubRateLimit? _lastRateLimit;
  final Map<String, UserStats> _statsCache = {};
  bool _isLastResponseNotModified = false;

  GitHubApiService({
    http.Client? client,
    this.personalAccessToken,
    this.storageService,
  }) : _client = client ?? http.Client();

  GitHubRateLimit? get lastRateLimit => _lastRateLimit;
  bool get isLastResponseNotModified => _isLastResponseNotModified;

  void clearCache() => _statsCache.clear();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitPulse-App',
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
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
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
          hasToken:
              personalAccessToken != null &&
              personalAccessToken!.trim().isNotEmpty,
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
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(_timeoutDuration);
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

  Future<List<GitHubContentItem>> fetchRepositoryContents({
    required String owner,
    required String repo,
    String path = '',
    String? ref,
  }) async {
    final cleanOwner = owner.trim();
    final cleanRepo = repo.trim();
    final cleanPath = path.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    if (cleanOwner.isEmpty || cleanRepo.isEmpty) return [];

    try {
      final endpoint = cleanPath.isEmpty
          ? '$_baseUrl/repos/$cleanOwner/$cleanRepo/contents'
          : '$_baseUrl/repos/$cleanOwner/$cleanRepo/contents/$cleanPath';
      final uri = Uri.parse(
        ref != null && ref.trim().isNotEmpty
            ? '$endpoint?ref=${Uri.encodeComponent(ref.trim())}'
            : endpoint,
      );

      final res = await _client
          .get(uri, headers: _headers)
          .timeout(_timeoutDuration);
      _updateRateLimitFromHeaders(res.headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          final List<GitHubContentItem> items = [];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              items.add(GitHubContentItem.fromJson(item));
            }
          }
          items.sort((a, b) {
            if (a.isDirectory && !b.isDirectory) return -1;
            if (!a.isDirectory && b.isDirectory) return 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return items;
        }
      } else if (res.statusCode == 404) {
        return [];
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
      throw GitHubApiException('Koneksi timeout saat memuat isi repositori.');
    } catch (e) {
      if (e is GitHubApiException) rethrow;
      return [];
    }
    return [];
  }

  Future<String?> fetchFileContent({
    required String owner,
    required String repo,
    required String path,
    String? ref,
    String? downloadUrl,
  }) async {
    final cleanOwner = owner.trim();
    final cleanRepo = repo.trim();
    final cleanPath = path.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    try {
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        final uri = Uri.parse(downloadUrl);
        final res = await _client.get(uri).timeout(_timeoutDuration);
        if (res.statusCode == 200) {
          return utf8.decode(res.bodyBytes, allowMalformed: true);
        }
      }

      final endpoint =
          '$_baseUrl/repos/$cleanOwner/$cleanRepo/contents/$cleanPath';
      final uri = Uri.parse(
        ref != null && ref.trim().isNotEmpty
            ? '$endpoint?ref=${Uri.encodeComponent(ref.trim())}'
            : endpoint,
      );

      final res = await _client
          .get(uri, headers: _headers)
          .timeout(_timeoutDuration);
      _updateRateLimitFromHeaders(res.headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final content = data['content'] as String?;
        final encoding = data['encoding'] as String?;

        if (content != null && encoding == 'base64') {
          final cleanBase64 = content.replaceAll(RegExp(r'\s+'), '');
          return utf8.decode(base64.decode(cleanBase64), allowMalformed: true);
        } else if (content != null) {
          return content;
        }
      }
    } catch (e) {
      if (e is GitHubApiException) rethrow;
      return null;
    }
    return null;
  }

  Future<ContributionStats?> _fetchContributionsWithCache(
    String username,
    String cacheKey,
  ) async {
    try {
      final uri = Uri.parse(
        'https://github-contributions-api.jogruber.de/v4/$username',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        storageService?.saveHttpCache(key: 'contrib_$cacheKey', body: res.body);
        return ContributionStats.fromContributionsApi(data);
      }
    } catch (_) {
      // Ignored: will fallback to cached or event-based calculation
    }

    final cached = storageService?.getHttpCacheBody('contrib_$cacheKey');
    if (cached != null) {
      try {
        return ContributionStats.fromContributionsApi(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return null;
  }

  Future<GitHubUser?> fetchUserProfile(String username) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) return null;
    final cacheKey = cleanUsername.toLowerCase();
    try {
      final userUri = Uri.parse('$_baseUrl/users/$cleanUsername');
      final headers = Map<String, String>.from(_headers);
      final etag = storageService?.getHttpCacheEtag('user_$cacheKey');
      if (etag != null && etag.isNotEmpty) {
        headers['If-None-Match'] = etag;
      }

      final res = await _client
          .get(userUri, headers: headers)
          .timeout(_timeoutDuration);
      _updateRateLimitFromHeaders(res.headers);

      if (res.statusCode == 304) {
        final cached = storageService?.getHttpCacheBody('user_$cacheKey');
        if (cached != null && cached.isNotEmpty) {
          return GitHubUser.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          );
        }
      } else if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        storageService?.saveHttpCache(
          key: 'user_$cacheKey',
          body: res.body,
          etag: res.headers['etag'],
        );
        return GitHubUser.fromJson(data);
      }
    } catch (_) {
      final cached = storageService?.getHttpCacheBody('user_$cacheKey');
      if (cached != null && cached.isNotEmpty) {
        return GitHubUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    }
    return null;
  }

  UserStats? _tryLoadOfflineStats(String cacheKey) {
    if (storageService == null) return null;
    final userBody = storageService!.getHttpCacheBody('user_$cacheKey');
    final reposBody = storageService!.getHttpCacheBody('repos_$cacheKey');
    final eventsBody = storageService!.getHttpCacheBody('events_$cacheKey');
    if (userBody == null || reposBody == null || eventsBody == null) {
      return null;
    }

    try {
      final user = GitHubUser.fromJson(
        jsonDecode(userBody) as Map<String, dynamic>,
      );
      final List<GitHubRepo> repos = (jsonDecode(reposBody) as List)
          .map((e) => GitHubRepo.fromJson(e as Map<String, dynamic>))
          .toList();
      final List<Map<String, dynamic>> events = (jsonDecode(eventsBody) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final langBody = storageService!.getHttpCacheBody('languages_$cacheKey');
      final Map<String, int> languages = langBody != null
          ? (jsonDecode(langBody) as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            )
          : {};
      final contribBody = storageService!.getHttpCacheBody('contrib_$cacheKey');
      var contrib = contribBody != null
          ? ContributionStats.fromContributionsApi(
              jsonDecode(contribBody) as Map<String, dynamic>,
            )
          : ContributionStats.fromEvents(events);

      final storedPeak = storageService!.getPeakTier(user.login);
      if (storedPeak < contrib.peakTitle.tier) {
        contrib = contrib.copyWith(
          peakTitle: CommitTitleInfo.getInfoForTier(storedPeak),
        );
      } else if (contrib.peakTitle.tier < storedPeak) {
        unawaited(
          storageService!.savePeakTier(user.login, contrib.peakTitle.tier),
        );
      }

      return UserStats.calculate(
        user: user,
        repos: repos,
        publicEvents: events,
        contributionStats: contrib,
        aggregatedLanguages: languages,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserStats> fetchUserStats(
    String username, {
    bool forceRefresh = false,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      throw GitHubApiException('Username GitHub tidak boleh kosong.');
    }

    final cacheKey = cleanUsername.toLowerCase();
    _isLastResponseNotModified = false;

    // In-memory cache (10-minute TTL)
    if (!forceRefresh && _statsCache.containsKey(cacheKey)) {
      final cachedTime = storageService?.getHttpCacheTimestamp(
        'user_stats_$cacheKey',
      );
      if (cachedTime == null ||
          DateTime.now().difference(cachedTime) < const Duration(minutes: 10)) {
        return _statsCache[cacheKey]!;
      }
    }

    // Persistent disk cache (10-minute TTL)
    if (!forceRefresh &&
        storageService != null &&
        storageService!.isHttpCacheValid(
          'user_stats_$cacheKey',
          ttl: const Duration(minutes: 10),
        )) {
      final cachedStats = _tryLoadOfflineStats(cacheKey);
      if (cachedStats != null) {
        _statsCache[cacheKey] = cachedStats;
        return cachedStats;
      }
    }

    try {
      // Background contributions fetch
      final contribFuture = _fetchContributionsWithCache(
        cleanUsername,
        cacheKey,
      );

      final userUri = Uri.parse('$_baseUrl/users/$cleanUsername');
      final reposUri = Uri.parse(
        '$_baseUrl/users/$cleanUsername/repos?per_page=100&sort=updated',
      );
      final eventsUri = Uri.parse(
        '$_baseUrl/users/$cleanUsername/events/public?per_page=100',
      );

      // Conditional request ETags (304 Not Modified)
      final userEtag = storageService?.getHttpCacheEtag('user_$cacheKey');
      final reposEtag = storageService?.getHttpCacheEtag('repos_$cacheKey');
      final eventsEtag = storageService?.getHttpCacheEtag('events_$cacheKey');

      final userHeaders = Map<String, String>.from(_headers);
      if (userEtag != null && userEtag.isNotEmpty) {
        userHeaders['If-None-Match'] = userEtag;
      }

      final reposHeaders = Map<String, String>.from(_headers);
      if (reposEtag != null && reposEtag.isNotEmpty) {
        reposHeaders['If-None-Match'] = reposEtag;
      }

      final eventsHeaders = Map<String, String>.from(_headers);
      if (eventsEtag != null && eventsEtag.isNotEmpty) {
        eventsHeaders['If-None-Match'] = eventsEtag;
      }

      final responses = await Future.wait([
        _client.get(userUri, headers: userHeaders).timeout(_timeoutDuration),
        _client.get(reposUri, headers: reposHeaders).timeout(_timeoutDuration),
        _client
            .get(eventsUri, headers: eventsHeaders)
            .timeout(_timeoutDuration),
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
      }

      // Flag when all responses are 304 Not Modified (zero quota consumed)
      _isLastResponseNotModified =
          (userRes.statusCode == 304 &&
          reposRes.statusCode == 304 &&
          eventsRes.statusCode == 304);

      // 1. User profile (200 OK or 304 Not Modified)
      Map<String, dynamic> userData;
      if (userRes.statusCode == 304) {
        final cached = storageService?.getHttpCacheBody('user_$cacheKey');
        if (cached == null) {
          throw GitHubApiException(
            'Gagal memuat profil: cache lokal tidak ditemukan.',
          );
        }
        userData = jsonDecode(cached) as Map<String, dynamic>;
      } else if (userRes.statusCode == 200) {
        userData = jsonDecode(userRes.body) as Map<String, dynamic>;
        storageService?.saveHttpCache(
          key: 'user_$cacheKey',
          body: userRes.body,
          etag: userRes.headers['etag'],
        );
      } else {
        throw GitHubApiException(
          'Gagal memuat profil (${userRes.statusCode}): ${userRes.reasonPhrase}',
          statusCode: userRes.statusCode,
        );
      }
      final user = GitHubUser.fromJson(userData);

      // 2. Repositories (200 OK or 304 Not Modified)
      final List<GitHubRepo> repos = [];
      bool reposUpdated = false;
      if (reposRes.statusCode == 304) {
        final cached = storageService?.getHttpCacheBody('repos_$cacheKey');
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached) as List<dynamic>;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              repos.add(GitHubRepo.fromJson(item));
            }
          }
        }
      } else if (reposRes.statusCode == 200) {
        reposUpdated = true;
        final List<dynamic> reposData =
            jsonDecode(reposRes.body) as List<dynamic>;
        for (final item in reposData) {
          if (item is Map<String, dynamic>) {
            repos.add(GitHubRepo.fromJson(item));
          }
        }
        storageService?.saveHttpCache(
          key: 'repos_$cacheKey',
          body: reposRes.body,
          etag: reposRes.headers['etag'],
        );
      }
      repos.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));

      // 3. Public events (200 OK or 304 Not Modified)
      final List<Map<String, dynamic>> events = [];
      if (eventsRes.statusCode == 304) {
        final cached = storageService?.getHttpCacheBody('events_$cacheKey');
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached) as List<dynamic>;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              events.add(item);
            }
          }
        }
      } else if (eventsRes.statusCode == 200) {
        final List<dynamic> eventsData =
            jsonDecode(eventsRes.body) as List<dynamic>;
        for (final item in eventsData) {
          if (item is Map<String, dynamic>) {
            events.add(item);
          }
        }
        storageService?.saveHttpCache(
          key: 'events_$cacheKey',
          body: eventsRes.body,
          etag: eventsRes.headers['etag'],
        );
      }

      // 4. Language distribution (reuse cached breakdown on 304)
      final nonForkRepos = repos.where((r) => !r.isFork).toList();
      Map<String, int> aggregatedLanguages = {};
      final cachedLang = storageService?.getHttpCacheBody(
        'languages_$cacheKey',
      );

      if (!reposUpdated && cachedLang != null) {
        try {
          final Map<String, dynamic> langData =
              jsonDecode(cachedLang) as Map<String, dynamic>;
          aggregatedLanguages = langData.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          );
        } catch (_) {}
      } else if (nonForkRepos.isNotEmpty) {
        final prioritizedRepos = List<GitHubRepo>.from(nonForkRepos)
          ..sort((a, b) => b.size.compareTo(a.size));
        final maxRepoQueries = personalAccessToken != null ? 25 : 8;
        final targetRepos = prioritizedRepos.take(maxRepoQueries).toList();

        final futures = targetRepos.map((repo) async {
          try {
            final langUri = Uri.parse(
              '$_baseUrl/repos/$cleanUsername/${repo.name}/languages',
            );
            final langRes = await _client
                .get(langUri, headers: _headers)
                .timeout(const Duration(seconds: 8));
            _updateRateLimitFromHeaders(langRes.headers);
            if (langRes.statusCode == 200) {
              final Map<String, dynamic> data =
                  jsonDecode(langRes.body) as Map<String, dynamic>;
              return data.map((k, v) => MapEntry(k, (v as num).toInt()));
            }
          } catch (_) {}
          return <String, int>{};
        });

        final results = await Future.wait(futures);
        for (final repoLangs in results) {
          repoLangs.forEach((lang, bytes) {
            aggregatedLanguages[lang] =
                (aggregatedLanguages[lang] ?? 0) + bytes;
          });
        }

        storageService?.saveHttpCache(
          key: 'languages_$cacheKey',
          body: jsonEncode(aggregatedLanguages),
        );
      }

      // Resolve contributions
      final fetchedContributions = await contribFuture;
      var contributionStats =
          fetchedContributions ?? ContributionStats.fromEvents(events);

      if (storageService != null) {
        final storedPeak = storageService!.getPeakTier(user.login);
        if (storedPeak < contributionStats.peakTitle.tier) {
          contributionStats = contributionStats.copyWith(
            peakTitle: CommitTitleInfo.getInfoForTier(storedPeak),
          );
        } else if (contributionStats.peakTitle.tier < storedPeak) {
          await storageService!.savePeakTier(
            user.login,
            contributionStats.peakTitle.tier,
          );
        }
      }

      final calculated = UserStats.calculate(
        user: user,
        repos: repos,
        publicEvents: events,
        contributionStats: contributionStats,
        aggregatedLanguages: aggregatedLanguages,
      );

      // Persist cache timestamp (10-minute TTL)
      await storageService?.saveHttpCache(
        key: 'user_stats_$cacheKey',
        body: 'valid',
        timestamp: DateTime.now(),
      );

      _statsCache[cacheKey] = calculated;
      return calculated;
    } on SocketException catch (e) {
      final offlineCached = _tryLoadOfflineStats(cacheKey);
      if (offlineCached != null) {
        _statsCache[cacheKey] = offlineCached;
        return offlineCached;
      }
      if (e.osError?.errorCode == 13 ||
          e.message.toLowerCase().contains('permission')) {
        throw GitHubApiException(
          'Izin akses internet belum diaktifkan pada sistem aplikasi.',
        );
      }
      throw GitHubApiException(
        'Tidak ada koneksi internet. Periksa jaringan kamu.',
      );
    } on TimeoutException {
      final offlineCached = _tryLoadOfflineStats(cacheKey);
      if (offlineCached != null) {
        _statsCache[cacheKey] = offlineCached;
        return offlineCached;
      }
      throw GitHubApiException(
        'Koneksi timeout. Server GitHub tidak merespons tepat waktu.',
      );
    } on http.ClientException {
      final offlineCached = _tryLoadOfflineStats(cacheKey);
      if (offlineCached != null) {
        _statsCache[cacheKey] = offlineCached;
        return offlineCached;
      }
      throw GitHubApiException('Gagal berkomunikasi dengan server GitHub.');
    } catch (e) {
      if (e is GitHubApiException) rethrow;
      final offlineCached = _tryLoadOfflineStats(cacheKey);
      if (offlineCached != null) {
        _statsCache[cacheKey] = offlineCached;
        return offlineCached;
      }
      throw GitHubApiException('Terjadi kesalahan tak terduga: $e');
    }
  }
}
