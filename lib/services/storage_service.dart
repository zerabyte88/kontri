import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmarked_user.dart';
import '../models/tech_news.dart';

class StorageService {
  static const String _keyBookmarks = 'gitpulse_bookmarks';
  static const String _keyBookmarkAvatars = 'gitpulse_bookmark_avatars';
  static const String _keyBookmarkDetails = 'gitpulse_bookmark_details';
  static const String _keyFavoriteGridColumns = 'gitpulse_fav_grid_columns';
  static const String _keyHistory = 'gitpulse_recent_searches';
  static const String _keyToken = 'gitpulse_github_token';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Bookmarks
  List<String> getBookmarks() {
    return _prefs.getStringList(_keyBookmarks) ?? [];
  }

  Map<String, String> _getAvatarMap() {
    final raw = _prefs.getString(_keyBookmarkAvatars);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key.toLowerCase(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAvatarMap(Map<String, String> map) async {
    await _prefs.setString(_keyBookmarkAvatars, jsonEncode(map));
  }

  Map<String, Map<String, dynamic>> _getDetailsMap() {
    final raw = _prefs.getString(_keyBookmarkDetails);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key.toLowerCase(), value);
        }
        return MapEntry(key.toLowerCase(), <String, dynamic>{});
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveDetailsMap(Map<String, Map<String, dynamic>> map) async {
    await _prefs.setString(_keyBookmarkDetails, jsonEncode(map));
  }

  List<BookmarkedUser> getBookmarkedUsers() {
    final usernames = getBookmarks();
    final avatars = _getAvatarMap();
    final details = _getDetailsMap();
    return usernames.map((username) {
      final clean = username.trim().toLowerCase();
      final avatar = avatars[clean];
      final userDetail = details[clean] ?? {};
      return BookmarkedUser(
        username: username,
        avatarUrl: (avatar != null && avatar.isNotEmpty)
            ? avatar
            : (userDetail['avatar_url'] as String? ??
                  'https://github.com/$username.png'),
        name: userDetail['name'] as String?,
        bio: userDetail['bio'] as String?,
        location: userDetail['location'] as String?,
      );
    }).toList();
  }

  Future<void> toggleBookmark(
    String username, {
    String? avatarUrl,
    String? name,
    String? bio,
    String? location,
  }) async {
    final list = getBookmarks();
    final clean = username.trim().toLowerCase();
    final avatars = _getAvatarMap();
    final details = _getDetailsMap();

    if (list.contains(clean)) {
      list.remove(clean);
      avatars.remove(clean);
      details.remove(clean);
    } else {
      list.add(clean);
      final finalAvatar = (avatarUrl != null && avatarUrl.isNotEmpty)
          ? avatarUrl
          : 'https://github.com/$clean.png';
      avatars[clean] = finalAvatar;
      details[clean] = {
        'avatar_url': finalAvatar,
        'name': ?name,
        'bio': ?bio,
        'location': ?location,
      };
    }

    await _prefs.setStringList(_keyBookmarks, list);
    await _saveAvatarMap(avatars);
    await _saveDetailsMap(details);
  }

  Future<void> updateBookmarkDetails(
    String username, {
    String? avatarUrl,
    String? name,
    String? bio,
    String? location,
  }) async {
    final clean = username.trim().toLowerCase();
    final details = _getDetailsMap();
    final current = details[clean] ?? {};
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      current['avatar_url'] = avatarUrl;
      final avatars = _getAvatarMap();
      avatars[clean] = avatarUrl;
      await _saveAvatarMap(avatars);
    }
    if (name != null) current['name'] = name;
    if (bio != null) current['bio'] = bio;
    if (location != null) current['location'] = location;
    details[clean] = current;
    await _saveDetailsMap(details);
  }

  Future<void> removeBookmark(String username) async {
    final list = getBookmarks();
    final clean = username.trim().toLowerCase();
    final avatars = _getAvatarMap();
    final details = _getDetailsMap();

    list.remove(clean);
    avatars.remove(clean);
    details.remove(clean);

    await _prefs.setStringList(_keyBookmarks, list);
    await _saveAvatarMap(avatars);
    await _saveDetailsMap(details);
  }

  bool isBookmarked(String username) {
    final list = getBookmarks();
    return list.contains(username.trim().toLowerCase());
  }

  int getFavoriteGridColumns() {
    final cols = _prefs.getInt(_keyFavoriteGridColumns) ?? 2;
    if (cols < 1 || cols > 2) return 2;
    return cols;
  }

  Future<void> setFavoriteGridColumns(int columns) async {
    final clamped = columns.clamp(1, 2);
    await _prefs.setInt(_keyFavoriteGridColumns, clamped);
  }

  // Recent History
  List<String> getRecentSearches() {
    return _prefs.getStringList(_keyHistory) ?? [];
  }

  Future<void> addRecentSearch(String username) async {
    final clean = username.trim();
    if (clean.isEmpty) return;

    final list = getRecentSearches();
    list.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    list.insert(0, clean);

    // Keep max 10
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await _prefs.setStringList(_keyHistory, list);
  }

  Future<void> removeRecentSearch(String username) async {
    final clean = username.trim();
    final list = getRecentSearches();
    list.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    await _prefs.setStringList(_keyHistory, list);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyHistory);
  }

  // Token
  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  Future<void> setToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _prefs.remove(_keyToken);
    } else {
      await _prefs.setString(_keyToken, token.trim());
    }
  }

  // Language
  static const String _keyLanguage = 'gitpulse_app_language';

  String getLanguageCode() {
    return _prefs.getString(_keyLanguage) ?? 'en';
  }

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(_keyLanguage, code);
  }

  // Theme Settings
  static const String _keyThemeMode = 'gitpulse_theme_mode';
  static const String _keyJapaneseEasterEgg =
      'gitpulse_japanese_theme_unlocked';

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  bool isJapaneseThemeUnlocked() {
    return _prefs.getBool(_keyJapaneseEasterEgg) ?? false;
  }

  Future<void> setJapaneseThemeUnlocked(bool unlocked) async {
    await _prefs.setBool(_keyJapaneseEasterEgg, unlocked);
  }

  // Surface Opacity & Glassmorphism Setting
  static const String _keySurfaceOpacity = 'gitpulse_surface_opacity';

  double getSurfaceOpacity() {
    return _prefs.getDouble(_keySurfaceOpacity) ?? 1.0;
  }

  Future<void> setSurfaceOpacity(double opacity) async {
    await _prefs.setDouble(_keySurfaceOpacity, opacity.clamp(0.50, 1.00));
  }

  // Background Animation Performance Setting
  static const String _keyBgAnimationEnabled = 'gitpulse_bg_animation_enabled';

  bool isBackgroundAnimationEnabled() {
    return _prefs.getBool(_keyBgAnimationEnabled) ?? true;
  }

  Future<void> setBackgroundAnimationEnabled(bool enabled) async {
    await _prefs.setBool(_keyBgAnimationEnabled, enabled);
  }

  // Cached Tech News & Trending Repos
  static const String _keyCachedNewsPrefix = 'gitpulse_cached_news_';
  static const String _keyCachedNewsTimePrefix = 'gitpulse_cached_news_time_';

  Future<void> saveCachedNews(String tag, List<TechNews> news) async {
    final rawJson = jsonEncode(news.map((n) => n.toJson()).toList());
    await _prefs.setString('$_keyCachedNewsPrefix$tag', rawJson);
    await _prefs.setInt(
      '$_keyCachedNewsTimePrefix$tag',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<TechNews>? getCachedNews(String tag) {
    final raw = _prefs.getString('$_keyCachedNewsPrefix$tag');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) => TechNews.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  DateTime? getCachedNewsTimestamp(String tag) {
    final epoch = _prefs.getInt('$_keyCachedNewsTimePrefix$tag');
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  // HTTP & ETag Response Cache
  static const String _keyHttpCachePrefix = 'gitpulse_http_cache_';
  static const String _keyHttpEtagPrefix = 'gitpulse_http_etag_';
  static const String _keyHttpTimePrefix = 'gitpulse_http_time_';

  Future<void> saveHttpCache({
    required String key,
    required String body,
    String? etag,
    DateTime? timestamp,
  }) async {
    final cleanKey = key.trim().toLowerCase();
    await _prefs.setString('$_keyHttpCachePrefix$cleanKey', body);
    if (etag != null && etag.trim().isNotEmpty) {
      await _prefs.setString('$_keyHttpEtagPrefix$cleanKey', etag.trim());
    }
    await _prefs.setInt(
      '$_keyHttpTimePrefix$cleanKey',
      (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  String? getHttpCacheBody(String key) {
    final cleanKey = key.trim().toLowerCase();
    return _prefs.getString('$_keyHttpCachePrefix$cleanKey');
  }

  String? getHttpCacheEtag(String key) {
    final cleanKey = key.trim().toLowerCase();
    return _prefs.getString('$_keyHttpEtagPrefix$cleanKey');
  }

  DateTime? getHttpCacheTimestamp(String key) {
    final cleanKey = key.trim().toLowerCase();
    final epoch = _prefs.getInt('$_keyHttpTimePrefix$cleanKey');
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  bool isHttpCacheValid(
    String key, {
    Duration ttl = const Duration(minutes: 10),
  }) {
    final cleanKey = key.trim().toLowerCase();
    final hasBody = _prefs.containsKey('$_keyHttpCachePrefix$cleanKey');
    if (!hasBody) return false;
    final timestamp = getHttpCacheTimestamp(cleanKey);
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < ttl;
  }

  Future<void> updateHttpCacheTimestamp(
    String key, [
    DateTime? timestamp,
  ]) async {
    final cleanKey = key.trim().toLowerCase();
    await _prefs.setInt(
      '$_keyHttpTimePrefix$cleanKey',
      (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  Future<void> clearHttpCache(String key) async {
    final cleanKey = key.trim().toLowerCase();
    await _prefs.remove('$_keyHttpCachePrefix$cleanKey');
    await _prefs.remove('$_keyHttpEtagPrefix$cleanKey');
    await _prefs.remove('$_keyHttpTimePrefix$cleanKey');
  }

  // Peak Contribution Tier Persistence
  static const String _keyPeakTierPrefix = 'gitpulse_peak_tier_';

  int getPeakTier(String username) {
    final clean = username.trim().toLowerCase();
    return _prefs.getInt('$_keyPeakTierPrefix$clean') ?? 6;
  }

  Future<void> savePeakTier(String username, int tier) async {
    final clean = username.trim().toLowerCase();
    final current = getPeakTier(clean);
    if (tier < current) {
      await _prefs.setInt('$_keyPeakTierPrefix$clean', tier);
    }
  }
}
