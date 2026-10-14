import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../models/bookmarked_user.dart';
import '../models/tech_news.dart';
import '../services/app_theme_service.dart';
import '../services/github_api_service.dart';
import '../services/storage_service.dart';
import '../services/tech_news_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_app_header.dart';
import '../widgets/tech_news_card.dart';
import 'favorite_profiles_screen.dart';
import 'settings_screen.dart';
import 'stats_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final GitHubApiService apiService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final TechNewsService _newsService;
  final ScrollController _categoryScrollController = ScrollController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSearchFocused = false;

  // News State & In-Memory Cache per Category
  String _selectedCategory = 'trending';
  late final PageController _newsPageController;
  final Map<String, List<TechNews>> _categoryNewsCache = {};
  final Map<String, bool> _categoryLoadingMap = {};

  // Local Storage Cache
  List<BookmarkedUser> _bookmarkedUsers = [];
  List<String> _allRecents = [];
  String? _loadingFavoriteUsername;

  void _refreshLocalData() {
    _bookmarkedUsers = widget.storageService.getBookmarkedUsers();
    _allRecents = widget.storageService.getRecentSearches();
  }

  List<Map<String, String>> _getCategories(AppLocalizations loc) => [
    {'id': 'trending', 'label': loc.categoryTrending},
    {'id': 'github', 'label': loc.categoryGithub},
    {'id': 'ai', 'label': loc.categoryAi},
    {'id': 'technology', 'label': loc.categoryTech},
    {'id': 'opensource', 'label': loc.categoryOpenSource},
    {'id': 'webdev', 'label': loc.categoryWebDev},
  ];

  @override
  void initState() {
    super.initState();
    _newsPageController = PageController();
    _newsService = TechNewsService(storageService: widget.storageService);
    _refreshLocalData();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadCategoryNews(_selectedCategory);
    widget.apiService.fetchRateLimit().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryNews(
    String category, {
    bool refresh = false,
  }) async {
    if (!refresh &&
        _categoryNewsCache.containsKey(category) &&
        _categoryNewsCache[category]!.isNotEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _categoryLoadingMap[category] = true;
      });
    }

    try {
      _newsService.personalAccessToken = widget.storageService.getToken();
      final news = await _newsService.fetchNews(
        tag: category,
        forceRefresh: refresh,
      );
      if (mounted) {
        setState(() {
          _categoryNewsCache[category] = news;
          _categoryLoadingMap[category] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categoryLoadingMap[category] = false;
        });
      }
    }
  }

  (List<double>, List<double>) _calculateCategoryMetrics(
    List<Map<String, String>> categories,
    BuildContext context,
  ) {
    const gap = 4.0;
    final widths = <double>[];
    final offsets = <double>[];
    double currentOffset = 0.0;

    for (int i = 0; i < categories.length; i++) {
      final label = categories[i]['label']!;
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();

      final w = math.max(76.0, textPainter.width + 26.0);
      widths.add(w);
      offsets.add(currentOffset);
      currentOffset += w + gap;
    }
    return (widths, offsets);
  }

  void _onCategoryChipTapped(int index, List<Map<String, String>> categories) {
    if (index < 0 || index >= categories.length) return;
    final targetCategory = categories[index]['id']!;
    if (targetCategory == _selectedCategory) return;

    setState(() {
      _selectedCategory = targetCategory;
    });

    _animateCategoryChipToView(index, categories);
    if (_newsPageController.hasClients) {
      _newsPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    _loadCategoryNews(targetCategory);
  }

  void _onPageChanged(int index, List<Map<String, String>> categories) {
    if (index < 0 || index >= categories.length) return;
    final targetCategory = categories[index]['id']!;
    if (targetCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = targetCategory;
      });
      _animateCategoryChipToView(index, categories);
      _loadCategoryNews(targetCategory);
    }
  }

  void _animateCategoryChipToView(
    int index,
    List<Map<String, String>> categories,
  ) {
    if (index < 0 || index >= categories.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_categoryScrollController.hasClients) return;
      final (widths, offsets) = _calculateCategoryMetrics(categories, context);
      if (index >= widths.length || index >= offsets.length) return;

      final screenWidth = MediaQuery.of(context).size.width;
      final tabCenter = offsets[index] + (widths[index] / 2);
      final maxScroll = _categoryScrollController.position.maxScrollExtent;
      final targetOffset = (tabCenter - (screenWidth / 2)).clamp(
        0.0,
        maxScroll,
      );
      _categoryScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _searchUser(String username) async {
    final clean = username.trim();
    if (clean.isEmpty) return;

    _searchFocusNode.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await widget.apiService.fetchUserStats(clean);
      await widget.storageService.addRecentSearch(clean);
      _refreshLocalData();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StatsDetailScreen(
            stats: stats,
            storageService: widget.storageService,
            apiService: widget.apiService,
          ),
        ),
      ).then((_) {
        _refreshLocalData();
        setState(() {});
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final loc = AppLocalizations.of(context);
      String displayErr;
      if (e is GitHubApiException && e.isNotFound) {
        displayErr = loc.userNotFound;
      } else if (e is GitHubApiException && e.isRateLimit) {
        displayErr = loc.rateLimitExceeded;
      } else if (msg.contains('not found') || msg.contains('404')) {
        displayErr = loc.userNotFound;
      } else if (msg.contains('rate limit') ||
          msg.contains('limit') ||
          msg.contains('403') ||
          msg.contains('429') ||
          msg.contains('kuota') ||
          msg.contains('habis')) {
        displayErr = loc.rateLimitExceeded;
      } else {
        displayErr = loc.networkError;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = displayErr;
      });
    }
  }

  Future<void> _openFavoriteProfile(String username) async {
    final clean = username.trim();
    if (clean.isEmpty || _loadingFavoriteUsername != null) return;

    _searchFocusNode.unfocus();
    setState(() {
      _loadingFavoriteUsername = clean;
    });

    try {
      final stats = await widget.apiService.fetchUserStats(clean);
      await widget.storageService.addRecentSearch(clean);
      _refreshLocalData();

      if (!mounted) return;
      setState(() {
        _loadingFavoriteUsername = null;
      });

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StatsDetailScreen(
            stats: stats,
            storageService: widget.storageService,
            apiService: widget.apiService,
          ),
        ),
      );
      _refreshLocalData();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final loc = AppLocalizations.of(context);
      String displayErr;
      if (e is GitHubApiException && e.isNotFound) {
        displayErr = loc.userNotFound;
      } else if (e is GitHubApiException && e.isRateLimit) {
        displayErr = loc.rateLimitExceeded;
      } else if (msg.contains('not found') || msg.contains('404')) {
        displayErr = loc.userNotFound;
      } else if (msg.contains('rate limit') ||
          msg.contains('limit') ||
          msg.contains('403') ||
          msg.contains('429') ||
          msg.contains('kuota') ||
          msg.contains('habis')) {
        displayErr = loc.rateLimitExceeded;
      } else {
        displayErr = loc.networkError;
      }
      setState(() {
        _loadingFavoriteUsername = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayErr),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSettingsSheet() async {
    HeaderAnimationState.pauseAnimation();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storageService: widget.storageService,
          apiService: widget.apiService,
          onSettingsChanged: () {
            _refreshLocalData();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (AppThemeService.isBgAnimationEnabled) {
      HeaderAnimationState.resumeAnimation();
    }
    _refreshLocalData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final categories = _getCategories(loc);
    final bookmarkedUsers = _bookmarkedUsers;
    final allRecents = _allRecents;

    final rateLimit = widget.apiService.lastRateLimit;

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: const AnimatedHeaderBackground(),
          title: const AnimatedAppHeader(),
          actions: [
            if (rateLimit != null)
              GestureDetector(
                onTap: _openSettingsSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 13,
                        color: rateLimit.remainingPercentage < 20
                            ? AppTheme.accentRed
                            : AppTheme.primaryCyan,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${rateLimit.used}/${rateLimit.limit}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              tooltip: loc.settingsTitle,
              icon: Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
              onPressed: _openSettingsSheet,
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppTheme.primaryCyan,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: () async {
            _refreshLocalData();
            await Future.wait([
              _loadCategoryNews(_selectedCategory, refresh: true),
              widget.apiService.fetchRateLimit(),
            ]);
            _refreshLocalData();
            setState(() {});
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            // ignore: deprecated_member_use
            cacheExtent: 600.0,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Input with integrated dropdown
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, searchValue, _) {
                          final query = searchValue.text.trim().toLowerCase();
                          final recents = query.isEmpty
                              ? allRecents
                              : allRecents
                                    .where(
                                      (u) => u.toLowerCase().contains(query),
                                    )
                                    .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(loc),
                              if (_isSearchFocused) ...[
                                const SizedBox(height: 8),
                                _buildSearchHistoryPanel(
                                  loc,
                                  recents,
                                  allRecents,
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.accentRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.accentRed,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppTheme.accentRed,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Bookmarks Section
                      _buildBookmarksSection(loc, bookmarkedUsers),

                      const SizedBox(height: 24),

                      // Latest Tech & AI News Header
                      _buildTechNewsHeader(loc, categories),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // News Content in Smooth Interactive PageView
              SliverToBoxAdapter(
                child: ExpandablePageView(
                  controller: _newsPageController,
                  itemCount: categories.length,
                  onPageChanged: (index) => _onPageChanged(index, categories),
                  itemBuilder: (context, index) {
                    final catId = categories[index]['id']!;
                    return KeyedSubtree(
                      key: ValueKey(catId),
                      child: _buildCategoryNewsPage(catId, loc),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: _searchUser,
      decoration: InputDecoration(
        hintText: loc.searchHint,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: _isSearchFocused
              ? AppTheme.primaryCyan
              : AppTheme.textSecondary,
        ),
        suffixIcon: _isLoading
            ? Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryCyan,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty || _isSearchFocused)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      tooltip: loc.close,
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppTheme.primaryCyan,
                    ),
                    tooltip: 'GitHub',
                    onPressed: () => _searchUser(_searchController.text),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchHistoryPanel(
    AppLocalizations loc,
    List<String> filteredRecents,
    List<String> allRecents,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 8,
              top: 10,
              bottom: 6,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.recentSearches,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (allRecents.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await widget.storageService.clearHistory();
                      _refreshLocalData();
                      setState(() {});
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      loc.clearAll,
                      style: TextStyle(color: AppTheme.accentRed, fontSize: 11),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  tooltip: loc.close,
                  onPressed: () => _searchFocusNode.unfocus(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),

          // Quick action if typed query does not exactly match
          if (_searchController.text.trim().isNotEmpty) ...[
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(
                Icons.search_rounded,
                size: 16,
                color: AppTheme.primaryCyan,
              ),
              title: RichText(
                text: TextSpan(
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '"${_searchController.text.trim()}"',
                      style: TextStyle(
                        color: AppTheme.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' > GitHub'),
                  ],
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: AppTheme.primaryCyan,
              ),
              onTap: () => _searchUser(_searchController.text),
            ),
            Divider(height: 1, color: AppTheme.border),
          ],

          // History items list
          if (filteredRecents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.noRecentSearches,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < filteredRecents.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppTheme.border),
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.only(left: 14, right: 6),
                    leading: Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    title: Text(
                      filteredRecents[i],
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.north_west_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          tooltip: filteredRecents[i],
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchController.text = filteredRecents[i];
                            _searchController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: filteredRecents[i].length),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: AppTheme.textMuted,
                          ),
                          tooltip: loc.close,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            await widget.storageService.removeRecentSearch(
                              filteredRecents[i],
                            );
                            _refreshLocalData();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _searchController.text = filteredRecents[i];
                      _searchUser(filteredRecents[i]);
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBookmarksSection(
    AppLocalizations loc,
    List<BookmarkedUser> bookmarks,
  ) {
    if (bookmarks.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavoriteProfilesScreen(
                storageService: widget.storageService,
                apiService: widget.apiService,
              ),
            ),
          );
          _refreshLocalData();
          if (mounted) setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border, width: 0.8),
                ),
                child: Icon(
                  Icons.star_outline_rounded,
                  color: AppTheme.accentAmber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.favoriteProfiles,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.emptyBookmarks,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoriteProfilesScreen(
                  storageService: widget.storageService,
                  apiService: widget.apiService,
                ),
              ),
            );
            _refreshLocalData();
            if (mounted) setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_outline_rounded,
                  size: 17,
                  color: AppTheme.accentAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.favoriteProfiles,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppTheme.border, width: 0.8),
                  ),
                  child: Text(
                    '${bookmarks.length}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Text(
                  loc.viewAllFavorites,
                  style: TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppTheme.primaryCyan,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final user = bookmarks[index];
              final isCardLoading = _loadingFavoriteUsername == user.username;
              return Container(
                width: 190,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCardLoading
                        ? AppTheme.primaryCyan.withValues(alpha: 0.6)
                        : AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    splashColor: AppTheme.primaryCyan.withValues(alpha: 0.12),
                    highlightColor: AppTheme.primaryCyan.withValues(
                      alpha: 0.05,
                    ),
                    onTap: isCardLoading
                        ? null
                        : () => _openFavoriteProfile(user.username),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Avatar Photo with subtle border & loading overlay
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      user.avatarUrl,
                                      width: 38,
                                      height: 38,
                                      cacheWidth: 100,
                                      cacheHeight: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              color: AppTheme.surfaceElevated,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: AppTheme
                                                            .primaryCyan,
                                                      ),
                                                ),
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: AppTheme.surfaceElevated,
                                                child: Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 18,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                if (isCardLoading)
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.background.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryCyan,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // User Info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'github.com',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Remove favorite button
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            visualDensity: VisualDensity.compact,
                            tooltip: loc.removeFavorite,
                            onPressed: () async {
                              await widget.storageService.removeBookmark(
                                user.username,
                              );
                              _refreshLocalData();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryNewsPage(String category, AppLocalizations loc) {
    final isLoading = _categoryLoadingMap[category] ?? false;
    final newsList = _categoryNewsCache[category] ?? [];

    if (isLoading && newsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TechNewsShimmerCard(),
            SizedBox(height: 12),
            TechNewsShimmerCard(),
            SizedBox(height: 12),
            TechNewsShimmerCard(),
          ],
        ),
      );
    }

    if (newsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Text(
            loc.noNewsFound,
            style: TextStyle(
              color: AppTheme.textMuted.withValues(alpha: 0.8),
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < newsList.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TechNewsCard(news: newsList[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildTechNewsHeader(
    AppLocalizations loc,
    List<Map<String, String>> categories,
  ) {
    final isCachedOffline = _newsService.isTagCachedOrOffline(
      _selectedCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.feed_outlined,
                    size: 18,
                    color: AppTheme.primaryCyan,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      loc.techNewsTitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isCachedOffline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.accentAmber.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 11,
                            color: AppTheme.accentAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loc.offlineCached,
                            style: TextStyle(
                              color: AppTheme.accentAmber,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              tooltip: loc.refresh,
              onPressed: () =>
                  _loadCategoryNews(_selectedCategory, refresh: true),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Phantek Gallery Continuous Sliding Capsule Category Bar
        Builder(
          builder: (context) {
            final (widths, offsets) = _calculateCategoryMetrics(
              categories,
              context,
            );
            final totalWidth = offsets.isNotEmpty
                ? offsets.last + widths.last
                : 0.0;
            final selectedIndex = categories.indexWhere(
              (c) => c['id'] == _selectedCategory,
            );
            final safeIndex = selectedIndex >= 0 ? selectedIndex : 0;

            return Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border, width: 1.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: SingleChildScrollView(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  height: 34,
                  child: Stack(
                    children: [
                      // Continuous sliding capsule indicator (Interpolated from PageController)
                      AnimatedBuilder(
                        animation: _newsPageController,
                        builder: (context, _) {
                          double page = safeIndex.toDouble();
                          if (_newsPageController.hasClients) {
                            page =
                                _newsPageController.page ??
                                safeIndex.toDouble();
                          }
                          page = page.clamp(
                            0.0,
                            (categories.length - 1).toDouble(),
                          );

                          final int from = page.floor().clamp(
                            0,
                            categories.length - 1,
                          );
                          final int to = page.ceil().clamp(
                            0,
                            categories.length - 1,
                          );
                          final double progress = page - from;

                          final double currentLeft = ui.lerpDouble(
                            offsets[from],
                            offsets[to],
                            progress,
                          )!;
                          final double currentWidth = ui.lerpDouble(
                            widths[from],
                            widths[to],
                            progress,
                          )!;

                          return Positioned(
                            left: currentLeft,
                            top: 0,
                            bottom: 0,
                            width: currentWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryCyan.withValues(
                                    alpha: 0.70,
                                  ),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.22,
                                    ),
                                    blurRadius: 8.0,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Category tab labels
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < categories.length; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            _buildCategoryTabItem(
                              i,
                              categories[i],
                              widths[i],
                              safeIndex,
                              categories,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTabItem(
    int index,
    Map<String, String> cat,
    double width,
    int activeIndex,
    List<Map<String, String>> categories,
  ) {
    return AnimatedBuilder(
      animation: _newsPageController,
      builder: (context, _) {
        double page = activeIndex.toDouble();
        if (_newsPageController.hasClients) {
          page = _newsPageController.page ?? activeIndex.toDouble();
        }
        final double distance = (page - index).abs();
        final double activeFactor = (1.0 - distance).clamp(0.0, 1.0);
        final color = Color.lerp(
          AppTheme.textSecondary,
          AppTheme.primaryCyan,
          activeFactor,
        )!;
        final fontWeight = activeFactor > 0.5
            ? FontWeight.w600
            : FontWeight.w500;

        return SizedBox(
          width: width,
          height: 34,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: AppTheme.primaryCyan.withValues(alpha: 0.12),
              highlightColor: AppTheme.primaryCyan.withValues(alpha: 0.05),
              onTap: () => _onCategoryChipTapped(index, categories),
              child: Center(
                child: Text(
                  cat['label']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: fontWeight,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dynamic-height PageView that measures its active page and animates container height smoothly.
class ExpandablePageView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final PageController controller;
  final ValueChanged<int>? onPageChanged;

  const ExpandablePageView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.controller,
    this.onPageChanged,
  });

  @override
  State<ExpandablePageView> createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView> {
  late List<double> _heights;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.controller.hasClients
        ? widget.controller.page?.round() ?? 0
        : 0;
    _heights = List.filled(widget.itemCount, 520.0);
    widget.controller.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final page = widget.controller.page;
    if (page != null) {
      final newPage = page.round();
      if (newPage != _currentPage &&
          newPage >= 0 &&
          newPage < widget.itemCount) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ExpandablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != _heights.length) {
      final newHeights = List.filled(widget.itemCount, 520.0);
      for (int i = 0; i < widget.itemCount && i < _heights.length; i++) {
        newHeights[i] = _heights[i];
      }
      _heights = newHeights;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight =
        (_currentPage < _heights.length && _heights[_currentPage] > 0)
        ? _heights[_currentPage]
        : 520.0;

    return TweenAnimationBuilder<double>(
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 320),
      tween: Tween<double>(begin: currentHeight, end: currentHeight),
      builder: (context, height, child) {
        return SizedBox(height: height, child: child);
      },
      child: PageView.builder(
        controller: widget.controller,
        itemCount: widget.itemCount,
        onPageChanged: widget.onPageChanged,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _KeepAlivePage(
            child: _PageMeasureWidget(
              onSizeChanged: (size) {
                if (index < _heights.length &&
                    (_heights[index] - size.height).abs() > 1.0) {
                  if (mounted) {
                    setState(() {
                      _heights[index] = size.height;
                    });
                  }
                }
              },
              child: widget.itemBuilder(context, index),
            ),
          );
        },
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _PageMeasureWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  const _PageMeasureWidget({required this.child, required this.onSizeChanged});

  @override
  State<_PageMeasureWidget> createState() => _PageMeasureWidgetState();
}

class _PageMeasureWidgetState extends State<_PageMeasureWidget> {
  final GlobalKey _key = GlobalKey();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _checkSize();
  }

  @override
  void didUpdateWidget(covariant _PageMeasureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkSize();
  }

  void _checkSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final size = renderBox.size;
        if (_lastSize != size) {
          _lastSize = size;
          widget.onSizeChanged(size);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: Container(key: _key, child: widget.child),
    );
  }
}
