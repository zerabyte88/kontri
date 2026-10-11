import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/bookmarked_user.dart';
import '../theme/app_theme.dart';
import '../services/github_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/animated_app_header.dart';
import '../widgets/glass_card.dart';
import 'stats_detail_screen.dart';

class FavoriteProfilesScreen extends StatefulWidget {
  final StorageService storageService;
  final GitHubApiService apiService;

  const FavoriteProfilesScreen({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  State<FavoriteProfilesScreen> createState() => _FavoriteProfilesScreenState();
}

class _FavoriteProfilesScreenState extends State<FavoriteProfilesScreen> {
  late int _columns;
  List<BookmarkedUser> _bookmarks = [];
  String? _loadingUsername;

  @override
  void initState() {
    super.initState();
    _columns = widget.storageService.getFavoriteGridColumns();
    _loadData();
    _fetchMissingDetails();
  }

  void _loadData() {
    setState(() {
      _bookmarks = widget.storageService.getBookmarkedUsers();
    });
  }

  Future<void> _fetchMissingDetails() async {
    for (final user in _bookmarks) {
      if (user.name == null && user.bio == null && user.location == null) {
        try {
          final profile = await widget.apiService.fetchUserProfile(user.username);
          if (profile != null && mounted) {
            await widget.storageService.updateBookmarkDetails(
              user.username,
              avatarUrl: profile.avatarUrl,
              name: profile.name,
              bio: profile.bio,
              location: profile.location,
            );
            if (mounted) {
              setState(() {
                _bookmarks = widget.storageService.getBookmarkedUsers();
              });
            }
          }
        } catch (_) {
          // Ignore network errors during silent background enrichment
        }
      }
    }
  }

  void _setColumns(int cols) {
    if (_columns == cols) return;
    setState(() {
      _columns = cols;
    });
    widget.storageService.setFavoriteGridColumns(cols);
  }

  Future<void> _openUser(String username) async {
    if (_loadingUsername != null) return;
    setState(() {
      _loadingUsername = username;
    });

    final loc = AppLocalizations.of(context);
    try {
      final stats = await widget.apiService.fetchUserStats(username);
      if (!mounted) return;
      setState(() {
        _loadingUsername = null;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StatsDetailScreen(
            stats: stats,
            storageService: widget.storageService,
          ),
        ),
      );

      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingUsername = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is GitHubApiException ? e.message : loc.networkError,
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.border),
          ),
        ),
      );
    }
  }

  void _removeBookmark(BookmarkedUser user) async {
    final loc = AppLocalizations.of(context);
    final removed = user;

    await widget.storageService.removeBookmark(user.username);
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.removedFromFavoritesWithUser(removed.username),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        ),
        action: SnackBarAction(
          label: loc.undo,
          textColor: AppTheme.primaryCyan,
          onPressed: () async {
            await widget.storageService.toggleBookmark(
              removed.username,
              avatarUrl: removed.avatarUrl,
              name: removed.name,
              bio: removed.bio,
              location: removed.location,
            );
            _loadData();
          },
        ),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const AnimatedHeaderBackground(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_rounded,
              color: AppTheme.accentAmber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              loc.favoriteProfiles,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border, width: 0.8),
              ),
              child: Text(
                '${_bookmarks.length}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar with Column count selector
            _buildToolbar(loc),
            Expanded(
              child: _bookmarks.isEmpty
                  ? _buildEmptyState(loc)
                  : _buildGridContent(loc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations loc) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 16,
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(width: 8),
          Text(
            loc.gridColumnsLabel,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 1 to 2 Modern Segmented Control Pill
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.border.withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [1, 2].map((col) {
                final isSelected = _columns == col;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: InkWell(
                    key: ValueKey('col_btn_$col'),
                    borderRadius: BorderRadius.circular(7),
                    onTap: () => _setColumns(col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 32,
                      height: 25,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryCyan
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$col',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0D1117)
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentAmber.withValues(alpha: 0.14),
                    AppTheme.surfaceElevated.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.accentAmber.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 42,
                color: AppTheme.accentAmber,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              loc.favoriteProfiles,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.emptyBookmarks,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent(AppLocalizations loc) {
    final double childAspectRatio = _columns == 1 ? 2.9 : 0.88;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final user = _bookmarks[index];
        return _buildProfileCard(loc, user);
      },
    );
  }

  Widget _buildProfileCard(AppLocalizations loc, BookmarkedUser user) {
    final isLoading = _loadingUsername == user.username;

    return RepaintBoundary(
      child: GlassCard(
        enableBlur: false,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: AppTheme.primaryCyan.withValues(alpha: 0.12),
            highlightColor: AppTheme.primaryCyan.withValues(alpha: 0.05),
            onTap: () => _openUser(user.username),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(_columns == 1 ? 12 : 8),
                  child: _buildAdaptiveCardBody(loc, user),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveCardBody(AppLocalizations loc, BookmarkedUser user) {
    if (_columns == 1) {
      return _buildSingleColumnCard(loc, user);
    }
    return _buildTwoColumnCard(loc, user);
  }

  Widget _buildSingleColumnCard(AppLocalizations loc, BookmarkedUser user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(user.avatarUrl, size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.name != null && user.name!.trim().isNotEmpty
                          ? user.name!
                          : user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.primaryCyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildRemoveButton(user, size: 17),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                user.bio != null && user.bio!.trim().isNotEmpty
                    ? user.bio!.trim()
                    : loc.noBio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: user.location != null && user.location!.trim().isNotEmpty
                        ? AppTheme.accentAmber
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.location != null && user.location!.trim().isNotEmpty
                          ? user.location!.trim()
                          : loc.noLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnCard(AppLocalizations loc, BookmarkedUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(user.avatarUrl, size: 40),
            _buildRemoveButton(user, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.name != null && user.name!.trim().isNotEmpty
              ? user.name!
              : user.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.primaryCyan,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Text(
            user.bio != null && user.bio!.trim().isNotEmpty
                ? user.bio!.trim()
                : loc.noBio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10.5,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 12,
              color: user.location != null && user.location!.trim().isNotEmpty
                  ? AppTheme.accentAmber
                  : AppTheme.textMuted,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                user.location != null && user.location!.trim().isNotEmpty
                    ? user.location!.trim()
                    : loc.noLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(String avatarUrl, {required double size}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryCyan.withValues(alpha: 0.7),
            AppTheme.primaryViolet.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withValues(alpha: 0.12),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: size - 3,
          height: size - 3,
          cacheWidth: 100,
          cacheHeight: 100,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppTheme.surfaceElevated,
              child: Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
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
              size: size * 0.5,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BookmarkedUser user, {required double size}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _removeBookmark(user),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          Icons.bookmark_rounded,
          size: size,
          color: AppTheme.accentAmber,
        ),
      ),
    );
  }
}
