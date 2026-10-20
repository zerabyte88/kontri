import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../localization/app_localizations.dart';
import '../models/github_rate_limit.dart';
import '../services/app_language_service.dart';
import '../services/app_theme_service.dart';
import '../services/github_api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsSheet extends StatefulWidget {
  final StorageService storageService;
  final GitHubApiService apiService;
  final VoidCallback? onSettingsChanged;
  final ScrollController? scrollController;

  const SettingsSheet({
    super.key,
    required this.storageService,
    required this.apiService,
    this.onSettingsChanged,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    required StorageService storageService,
    required GitHubApiService apiService,
    VoidCallback? onSettingsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.25,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SettingsSheet(
          scrollController: scrollController,
          storageService: storageService,
          apiService: apiService,
          onSettingsChanged: onSettingsChanged,
        ),
      ),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _tokenController;

  bool _isDismissing = false;

  void _dismissSheet() {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  bool _obscureToken = true;
  bool _isLoadingRateLimit = false;
  bool _showTokenGuide = false;
  GitHubRateLimit? _rateLimit;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.storageService.getToken() ?? '',
    );
    _rateLimit = widget.apiService.lastRateLimit;

    // Defer network requests until after modal slide-in animation finishes
    // so the sheet opens with zero frame-drops or setState interruptions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        if (_rateLimit == null) {
          _refreshRateLimit();
        }
      });
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }



  Future<void> _refreshRateLimit() async {
    setState(() {
      _isLoadingRateLimit = true;
    });

    final rateLimit = await widget.apiService.fetchRateLimit();

    if (mounted) {
      setState(() {
        _rateLimit = rateLimit;
        _isLoadingRateLimit = false;
      });
    }
  }

  Future<void> _saveToken(AppLocalizations loc) async {
    final token = _tokenController.text.trim();
    await widget.storageService.setToken(token.isEmpty ? null : token);
    widget.apiService.personalAccessToken = token.isEmpty ? null : token;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            token.isEmpty ? loc.tokenDeletedToast : loc.tokenSavedToast,
          ),
          backgroundColor: token.isEmpty
              ? AppTheme.surfaceElevated
              : AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    widget.onSettingsChanged?.call();
    await _refreshRateLimit();
  }

  Future<void> _clearToken(AppLocalizations loc) async {
    _tokenController.clear();
    await widget.storageService.setToken(null);
    widget.apiService.personalAccessToken = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.tokenDeletedToast),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    widget.onSettingsChanged?.call();
    await _refreshRateLimit();
  }

  Widget _buildAboutInfoRow(String label, String value, {VoidCallback? onTap}) {
    final rowContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: onTap != null
                    ? AppTheme.primaryCyan
                    : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppTheme.primaryCyan,
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: rowContent,
        ),
      );
    }
    return rowContent;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasToken =
        widget.storageService.getToken() != null &&
        widget.storageService.getToken()!.trim().isNotEmpty;
    final rateLimit =
        _rateLimit ?? GitHubRateLimit.defaultLimit(hasToken: hasToken);

    final remainingPercent = rateLimit.remainingPercentage;
    final usedCount = rateLimit.used;
    final totalLimit = rateLimit.limit;

    Color progressColor;
    if (remainingPercent > 40) {
      progressColor = AppTheme.accentGreen;
    } else if (remainingPercent > 15) {
      progressColor = AppTheme.accentAmber;
    } else {
      progressColor = AppTheme.accentRed;
    }

    final currentLang = AppLanguageService.currentLanguage;
    final currentTheme = AppThemeService.currentTheme;

    return RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: AppThemeService.surfaceOpacityNotifier,
        builder: (context, surfaceOpacity, _) {
          final isGlass = surfaceOpacity < 0.999;
          final cardOpacity = isGlass
              ? (0.45 + 0.55 * surfaceOpacity).clamp(0.0, 1.0)
              : 1.0;
          const sheetRadius = BorderRadius.vertical(top: Radius.circular(20));

          Widget sheetContent = AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isGlass
                  ? AppTheme.surface.withValues(alpha: surfaceOpacity)
                  : AppTheme.surface,
              borderRadius: sheetRadius,
              border: Border(
                top: BorderSide(
                  color: AppTheme.border.withValues(alpha: isGlass ? 0.7 : 1.0),
                  width: 1.2,
                ),
                left: BorderSide(
                  color: AppTheme.border.withValues(alpha: isGlass ? 0.7 : 1.0),
                  width: 1,
                ),
                right: BorderSide(
                  color: AppTheme.border.withValues(alpha: isGlass ? 0.7 : 1.0),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (notification.metrics.pixels <= 0 &&
                        (notification.scrollDelta ?? 0) < -8) {
                      _dismissSheet();
                      return true;
                    }
                  } else if (notification is OverscrollNotification) {
                    if (notification.overscroll < -6) {
                      _dismissSheet();
                      return true;
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top drag indicator and header with swipe-to-dismiss gesture support
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if ((details.primaryDelta ?? 0) > 8) {
                            _dismissSheet();
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if ((details.primaryVelocity ?? 0) > 80) {
                            _dismissSheet();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top drag indicator
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Sheet Header
                            Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.border,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: AppTheme.primaryCyan,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.settingsTitle,
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        loc.settingsSubtitle,
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: _dismissSheet,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CARD 1: Theme Selection (Dark, AMOLED, Japanese AMOLED Easter Egg, Light)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isGlass
                              ? AppTheme.surfaceElevated.withValues(
                                  alpha: cardOpacity,
                                )
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.border.withValues(
                              alpha: isGlass ? 0.65 : 1.0,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.palette_outlined,
                                    color: AppTheme.primaryCyan,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    loc.themeSectionTitle,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryCyan.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    switch (currentTheme) {
                                      AppThemeMode.amoledSnowfall =>
                                        loc.themeDark,
                                      AppThemeMode.amoled => loc.themeAmoled,
                                      AppThemeMode.amoledJapanese =>
                                        loc.themeAmoledJapanese,
                                      AppThemeMode.amoledPure =>
                                        loc.themeAmoledPure,
                                      AppThemeMode.light => loc.themeLight,
                                      AppThemeMode.cleanLight =>
                                        loc.themeCleanLight,
                                    },
                                    style: TextStyle(
                                      color: AppTheme.primaryCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.themeSectionSubtitle,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Theme Options Grid (6 themes in 3 rows)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    // 1. Snowfall
                                    Expanded(
                                      child: _buildOptionCard(
                                        title: loc.themeDark,
                                        subtitle: loc.themeDarkSubtitle,
                                        badge: 'AMOLED',
                                        leading: Icon(
                                          Icons.ac_unit_rounded,
                                          size: 17,
                                          color:
                                              currentTheme ==
                                                  AppThemeMode.amoledSnowfall
                                              ? AppTheme.primaryCyan
                                              : AppTheme.textMuted,
                                        ),
                                        isSelected:
                                            currentTheme ==
                                            AppThemeMode.amoledSnowfall,
                                        onTap: () async {
                                          await AppThemeService.changeTheme(
                                            AppThemeMode.amoledSnowfall,
                                            widget.storageService,
                                          );
                                          widget.onSettingsChanged?.call();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 2. Night
                                    Expanded(
                                      child: _buildOptionCard(
                                        title: loc.themeAmoled,
                                        subtitle: loc.themeAmoledSubtitle,
                                        badge: 'AMOLED',
                                        leading: Icon(
                                          Icons.brightness_2_rounded,
                                          size: 17,
                                          color:
                                              currentTheme ==
                                                  AppThemeMode.amoled
                                              ? AppTheme.primaryCyan
                                              : AppTheme.textMuted,
                                        ),
                                        isSelected:
                                            currentTheme == AppThemeMode.amoled,
                                        onTap: () async {
                                          await AppThemeService.changeTheme(
                                            AppThemeMode.amoled,
                                            widget.storageService,
                                          );
                                          widget.onSettingsChanged?.call();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // 3. Sakura
                                    Expanded(
                                      child: _buildOptionCard(
                                        title: loc.themeAmoledJapanese,
                                        subtitle:
                                            loc.themeAmoledJapaneseSubtitle,
                                        badge: 'AMOLED',
                                        leading: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 17,
                                          color:
                                              currentTheme ==
                                                  AppThemeMode.amoledJapanese
                                              ? const Color(0xFFFF5C8A)
                                              : AppTheme.textMuted,
                                        ),
                                        isSelected:
                                            currentTheme ==
                                            AppThemeMode.amoledJapanese,
                                        activeColor: const Color(0xFFFF5C8A),
                                        onTap: () async {
                                          await AppThemeService.changeTheme(
                                            AppThemeMode.amoledJapanese,
                                            widget.storageService,
                                          );
                                          widget.onSettingsChanged?.call();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 4. Pure Black
                                    Expanded(
                                      child: _buildOptionCard(
                                        title: loc.themeAmoledPure,
                                        subtitle: loc.themeAmoledPureSubtitle,
                                        badge: 'STATIC',
                                        activeColor: const Color(0xFF60A5FA),
                                        leading: Icon(
                                          Icons.brightness_2_outlined,
                                          size: 17,
                                          color:
                                              currentTheme ==
                                                  AppThemeMode.amoledPure
                                              ? const Color(0xFF60A5FA)
                                              : AppTheme.textMuted,
                                        ),
                                        isSelected:
                                            currentTheme ==
                                            AppThemeMode.amoledPure,
                                        onTap: () async {
                                          await AppThemeService.changeTheme(
                                            AppThemeMode.amoledPure,
                                            widget.storageService,
                                          );
                                          widget.onSettingsChanged?.call();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // 5. Daylight
                                    Expanded(
                                      child: _buildOptionCard(
                                        title: loc.themeLight,
                                        subtitle: loc.themeLightSubtitle,
                                        badge: 'LIGHT',
                                        leading: Icon(
                                          Icons.light_mode_outlined,
                                          size: 17,
                                          color:
                                              currentTheme == AppThemeMode.light
                                              ? AppTheme.primaryCyan
                                              : AppTheme.textMuted,
                                        ),
                                        isSelected:
                                            currentTheme == AppThemeMode.light,
                                        onTap: () async {
                                          await AppThemeService.changeTheme(
                                            AppThemeMode.light,
                                            widget.storageService,
                                          );
                                          widget.onSettingsChanged?.call();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 6. Clean Light
                                    Expanded(
                                      child: _buildOptionCard(
                                        title: loc.themeCleanLight,
                                        subtitle: loc.themeCleanLightSubtitle,
                                        badge: 'STATIC',
                                        activeColor: const Color(0xFF0EA5E9),
                                        leading: Icon(
                                          Icons.wb_sunny_outlined,
                                          size: 17,
                                          color:
                                              currentTheme ==
                                                  AppThemeMode.cleanLight
                                              ? const Color(0xFF0EA5E9)
                                              : AppTheme.textMuted,
                                        ),
                                        isSelected:
                                            currentTheme ==
                                            AppThemeMode.cleanLight,
                                        onTap: () async {
                                          await AppThemeService.changeTheme(
                                            AppThemeMode.cleanLight,
                                            widget.storageService,
                                          );
                                          widget.onSettingsChanged?.call();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(
                              color: AppTheme.border.withValues(alpha: 0.4),
                              height: 1,
                            ),
                            const SizedBox(height: 14),

                            // Surface Opacity Slider
                            ValueListenableBuilder<double>(
                              valueListenable:
                                  AppThemeService.surfaceOpacityNotifier,
                              builder: (context, opacity, _) {
                                final percent = (opacity * 100).round();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryCyan
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.opacity_rounded,
                                            size: 14,
                                            color: AppTheme.primaryCyan,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            loc.themeOpacityTitle,
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryCyan
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryCyan
                                                  .withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            '$percent%',
                                            style: TextStyle(
                                              color: AppTheme.primaryCyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.themeOpacitySubtitle,
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppTheme.primaryCyan,
                                        inactiveTrackColor: AppTheme.border
                                            .withValues(alpha: 0.5),
                                        thumbColor: AppTheme.primaryCyan,
                                        overlayColor: AppTheme.primaryCyan
                                            .withValues(alpha: 0.15),
                                        trackHeight: 3.5,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                      ),
                                      child: Slider(
                                        value: opacity,
                                        min: 0.50,
                                        max: 1.00,
                                        divisions: 50,
                                        onChanged: (val) {
                                          AppThemeService.changeSurfaceOpacity(
                                            val,
                                            widget.storageService,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              color: AppTheme.border.withValues(alpha: 0.4),
                              height: 1,
                            ),
                            const SizedBox(height: 12),

                            // Background Animation Toggle
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  AppThemeService.bgAnimationEnabledNotifier,
                              builder: (context, bgAnimEnabled, _) {
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryCyan.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome_motion_rounded,
                                        size: 14,
                                        color: AppTheme.primaryCyan,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.bgAnimationTitle,
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            loc.bgAnimationSubtitle,
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: bgAnimEnabled,
                                      activeThumbColor: AppTheme.primaryCyan,
                                      onChanged: (val) {
                                        AppThemeService.setBackgroundAnimation(
                                          val,
                                          widget.storageService,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CARD 2: Language Selection
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isGlass
                              ? AppTheme.surfaceElevated.withValues(
                                  alpha: cardOpacity,
                                )
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.border.withValues(
                              alpha: isGlass ? 0.65 : 1.0,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.translate_rounded,
                                    color: AppTheme.primaryCyan,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    loc.languageSectionTitle,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryCyan.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${currentLang.flag} ${currentLang.nativeName}',
                                    style: TextStyle(
                                      color: AppTheme.primaryCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.languageSectionSubtitle,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Grid of Languages
                            Builder(
                              builder: (context) {
                                final sortedLangs =
                                    AppLanguage.sortedAlphabetically;
                                return Column(
                                  children: [
                                    for (
                                      int i = 0;
                                      i < sortedLangs.length;
                                      i += 2
                                    ) ...[
                                      if (i > 0) const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildLanguageOptionCard(
                                              lang: sortedLangs[i],
                                              currentLang: currentLang,
                                              loc: loc,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (i + 1 < sortedLangs.length)
                                            Expanded(
                                              child: _buildLanguageOptionCard(
                                                lang: sortedLangs[i + 1],
                                                currentLang: currentLang,
                                                loc: loc,
                                              ),
                                            )
                                          else
                                            const Expanded(child: SizedBox()),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CARD 3: GitHub API Rate Limit Tracker
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isGlass
                              ? AppTheme.surfaceElevated.withValues(
                                  alpha: cardOpacity,
                                )
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.border.withValues(
                              alpha: isGlass ? 0.65 : 1.0,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.speed_rounded,
                                    color: AppTheme.primaryCyan,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    loc.rateLimitStatus,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (_isLoadingRateLimit)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppTheme.primaryCyan,
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                      color: AppTheme.textMuted,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: loc.refresh,
                                    onPressed: _refreshRateLimit,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasToken
                                  ? loc.personalTokenActive
                                  : loc.standardMode,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (totalLimit > 0)
                                    ? (remainingPercent / 100).clamp(0.0, 1.0)
                                    : 1.0,
                                backgroundColor: AppTheme.surface,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${loc.requestsUsed}: $usedCount / $totalLimit',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                                Text(
                                  '${loc.remainingQuota}: ${rateLimit.remaining}',
                                  style: TextStyle(
                                    color: progressColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${loc.resetIn}: ${loc.formatCountdown(rateLimit.resetTime.difference(DateTime.now()))}',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CARD 4: GitHub Personal Access Token
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isGlass
                              ? AppTheme.surfaceElevated.withValues(
                                  alpha: cardOpacity,
                                )
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.border.withValues(
                              alpha: isGlass ? 0.65 : 1.0,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.vpn_key_outlined,
                                    color: AppTheme.primaryCyan,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    loc.githubTokenTitle,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasToken
                                        ? AppTheme.accentGreen.withValues(
                                            alpha: 0.12,
                                          )
                                        : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: hasToken
                                          ? AppTheme.accentGreen.withValues(
                                              alpha: 0.35,
                                            )
                                          : AppTheme.border,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    hasToken
                                        ? loc.tokenActiveBadge
                                        : loc.optionalBadge,
                                    style: TextStyle(
                                      color: hasToken
                                          ? AppTheme.accentGreen
                                          : AppTheme.textMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.tokenSubtitle,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _tokenController,
                              obscureText: _obscureToken,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.surface,
                                hintText: loc.tokenHint,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppTheme.border,
                                    width: 0.8,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppTheme.border,
                                    width: 0.8,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryCyan,
                                    width: 1.2,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureToken
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureToken = !_obscureToken;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                setState(() {
                                  _showTokenGuide = !_showTokenGuide;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showTokenGuide
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppTheme.primaryCyan,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.howToCreateToken,
                                      style: TextStyle(
                                        color: AppTheme.primaryCyan,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_showTokenGuide) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  loc.tokenGuideContent,
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _saveToken(loc),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.buttonPrimaryBackground,
                                    foregroundColor: AppTheme.buttonPrimaryForeground,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    loc.saveToken,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (hasToken) ...[
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 15,
                                    ),
                                    label: Text(loc.deleteToken),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.accentRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _clearToken(loc),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),


                      // About & App Version
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isGlass
                              ? AppTheme.surfaceElevated.withValues(
                                  alpha: cardOpacity,
                                )
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.border.withValues(
                              alpha: isGlass ? 0.65 : 1.0,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.primaryCyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.aboutApp,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.appDescriptionLabel,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppTheme.border),
                            const SizedBox(height: 10),
                            _buildAboutInfoRow(
                              loc.appVersionLabel,
                              AppConfig.appVersion,
                            ),
                            const SizedBox(height: 6),
                            _buildAboutInfoRow(
                              loc.buildNumberLabel,
                              AppConfig.buildNumber,
                            ),
                            const SizedBox(height: 6),
                            _buildAboutInfoRow(
                              loc.architectureLabel,
                              AppConfig.architecture,
                            ),
                            const SizedBox(height: 6),
                            _buildAboutInfoRow(
                              loc.licenseLabel,
                              AppConfig.license,
                              onTap: () {
                                showLicensePage(
                                  context: context,
                                  applicationName: AppConfig.appName,
                                  applicationVersion:
                                      '${AppConfig.appVersion} Build ${AppConfig.buildNumber}',
                                  applicationIcon: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Image.asset(
                                      'assets/icons/app_icon.png',
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                  applicationLegalese:
                                      'Copyright © 2026 ${AppConfig.developerUsername}\nLicensed under the ${AppConfig.license}',
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppTheme.border),
                            const SizedBox(height: 10),

                            // Developer Item with Live Auto-Updating Profile Picture
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(
                                  AppConfig.developerGithubUrl,
                                );
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(1.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primaryCyan,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          AppConfig.developerAvatarUrl,
                                          width: 30,
                                          height: 30,
                                          cacheWidth: 80,
                                          cacheHeight: 80,
                                          headers: const {
                                            'Accept': 'image/*,*/*;q=0.8',
                                            'User-Agent': 'Kontri/1.0',
                                          },
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: 30,
                                                  height: 30,
                                                  color: AppTheme.surface,
                                                  alignment: Alignment.center,
                                                  child: SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 1.5,
                                                          color: AppTheme
                                                              .primaryCyan,
                                                        ),
                                                  ),
                                                );
                                              },
                                          errorBuilder: (_, _, _) => Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppTheme.primaryCyan
                                                      .withValues(alpha: 0.25),
                                                  AppTheme.primaryCyan
                                                      .withValues(alpha: 0.08),
                                                ],
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              AppConfig
                                                      .developerUsername
                                                      .isNotEmpty
                                                  ? AppConfig
                                                        .developerUsername[0]
                                                        .toUpperCase()
                                                  : 'Z',
                                              style: TextStyle(
                                                color: AppTheme.primaryCyan,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${loc.developerLabel}: ${AppConfig.developerUsername}',
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            loc.developerRole,
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          final uri = Uri.parse(
                                            AppConfig.developerGithubUrl,
                                          );
                                          try {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } catch (_) {}
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryCyan
                                                .withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryCyan
                                                  .withValues(alpha: 0.35),
                                              width: 0.9,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.open_in_new_rounded,
                                                size: 13,
                                                color: AppTheme.primaryCyan,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'GitHub',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primaryCyan,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );

          return ClipRRect(borderRadius: sheetRadius, child: sheetContent);
        },
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required AppLanguage lang,
    required AppLanguage currentLang,
    required AppLocalizations loc,
  }) {
    final isSelected = lang == currentLang;
    return _buildOptionCard(
      title: lang.nativeName,
      subtitle: lang == AppLanguage.english
          ? 'Global'
          : (lang.name != lang.nativeName ? lang.name : null),
      leading: Text(lang.flag, style: const TextStyle(fontSize: 16)),
      isSelected: isSelected,
      onTap: () async {
        if (lang == currentLang) return;
        final messenger = ScaffoldMessenger.of(context);
        final toastText =
            '${loc.languageChangedToast}: ${lang.nativeName} (${lang.name})';
        await AppLanguageService.changeLanguage(lang, widget.storageService);
        widget.onSettingsChanged?.call();
        if (!mounted) return;
        setState(() {});
        messenger.showSnackBar(
          SnackBar(
            content: Text(toastText),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    double? width,
    required Widget leading,
    required String title,
    String? subtitle,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final accent = activeColor ?? AppTheme.primaryCyan;
    return SizedBox(
      width: width,
      height: 56.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : AppTheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accent
                    : AppTheme.border.withValues(alpha: 0.7),
                width: isSelected ? 1.4 : 0.8,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(child: leading),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? accent
                                      : AppTheme.textPrimary,
                                  fontSize: 12.0,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.5),
                                    width: 0.7,
                                  ),
                                ),
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 1.5),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.85)
                                  : AppTheme.textMuted,
                              fontSize: 9.8,
                              letterSpacing: -0.2,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
