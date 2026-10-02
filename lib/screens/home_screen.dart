import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/bookmarked_user.dart';
import '../models/tech_news.dart';
import '../services/github_api_service.dart';
import '../services/storage_service.dart';
import '../services/tech_news_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_app_header.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/tech_news_card.dart';
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
  final TechNewsService _newsService = TechNewsService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSearchFocused = false;

  // News State
  String _selectedCategory = 'trending';
  List<TechNews> _newsList = [];
  bool _isNewsLoading = true;

  // Local Storage Cache
  List<BookmarkedUser> _bookmarkedUsers = [];
  List<String> _allRecents = [];

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
    _refreshLocalData();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _searchController.addListener(_onSearchTextChanged);
    _loadNews();
    widget.apiService.fetchRateLimit().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _onSearchTextChanged() {
    if (_isSearchFocused) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isNewsLoading = true;
      });
    }

    try {
      _newsService.personalAccessToken = widget.storageService.getToken();
      final news = await _newsService.fetchNews(
        tag: _selectedCategory,
        forceRefresh: refresh,
      );
      if (mounted) {
        setState(() {
          _newsList = news;
          _isNewsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isNewsLoading = false;
        });
      }
    }
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

  void _openSettingsSheet() {
    SettingsSheet.show(
      context,
      storageService: widget.storageService,
      apiService: widget.apiService,
      onSettingsChanged: () {
        _refreshLocalData();
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bookmarkedUsers = _bookmarkedUsers;
    final allRecents = _allRecents;

    // Filter recents based on input query when user is typing
    final query = _searchController.text.trim().toLowerCase();
    final recents = query.isEmpty
        ? allRecents
        : allRecents.where((u) => u.toLowerCase().contains(query)).toList();

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              icon: Icon(Icons.tune_rounded, size: 20, color: AppTheme.textSecondary),
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
              _loadNews(refresh: true),
              widget.apiService.fetchRateLimit(),
            ]);
            _refreshLocalData();
            setState(() {});
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            // ignore: deprecated_member_use
            cacheExtent: 600.0,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Input with integrated dropdown
                      _buildSearchBar(loc),

                      // Search History Dropdown (only visible when search field is focused/clicked)
                      if (_isSearchFocused) ...[
                        const SizedBox(height: 8),
                        _buildSearchHistoryPanel(loc, recents, allRecents),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
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
                      _buildTechNewsHeader(loc),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // News Content as virtualized sliver
              if (_isNewsLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            loc.loadingNews,
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_newsList.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
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
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TechNewsCard(news: _newsList[index]),
                        );
                      },
                      childCount: _newsList.length,
                    ),
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
          color: _isSearchFocused ? AppTheme.primaryCyan : AppTheme.textSecondary,
        ),
        suffixIcon: _isLoading
            ? Padding(padding: EdgeInsets.all(12), child: SizedBox(
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
                      icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                      tooltip: loc.close,
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.primaryCyan),
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
            padding: const EdgeInsets.only(left: 14, right: 8, top: 10, bottom: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      loc.clearAll,
                      style: TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 11,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppTheme.textMuted),
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
              leading: Icon(Icons.search_rounded, size: 16, color: AppTheme.primaryCyan),
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
              trailing: Icon(Icons.arrow_forward_rounded, size: 15, color: AppTheme.primaryCyan),
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
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
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
                          icon: Icon(Icons.north_west_rounded, size: 14, color: AppTheme.textMuted),
                          tooltip: filteredRecents[i],
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchController.text = filteredRecents[i];
                            _searchController.selection = TextSelection.fromPosition(
                              TextPosition(offset: filteredRecents[i].length),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 15, color: AppTheme.textMuted),
                          tooltip: loc.close,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            await widget.storageService.removeRecentSearch(filteredRecents[i]);
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

  Widget _buildBookmarksSection(AppLocalizations loc, List<BookmarkedUser> bookmarks) {
    if (bookmarks.isEmpty) {
      return Container(
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
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ],
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
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _searchController.text = user.username;
                  _searchUser(user.username);
                },
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Avatar Photo with subtle border
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
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppTheme.surfaceElevated,
                                child: Center(child: SizedBox(width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppTheme.primaryCyan,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
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
                          await widget.storageService.removeBookmark(user.username);
                          _refreshLocalData();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTechNewsHeader(AppLocalizations loc) {
    final categories = _getCategories(loc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.feed_outlined,
                  size: 18,
                  color: AppTheme.primaryCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.techNewsTitle,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textSecondary),
              tooltip: loc.refresh,
              onPressed: () => _loadNews(refresh: true),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat['id'] == _selectedCategory;
              return ChoiceChip(
                label: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryCyan : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryCyan.withValues(alpha: 0.12),
                backgroundColor: AppTheme.surface,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryCyan : AppTheme.border,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected && _selectedCategory != cat['id']) {
                    setState(() {
                      _selectedCategory = cat['id']!;
                    });
                    _loadNews();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
