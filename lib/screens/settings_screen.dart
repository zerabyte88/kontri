import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../localization/app_localizations.dart';
import '../models/github_rate_limit.dart';
import '../services/app_language_service.dart';
import '../services/app_theme_service.dart';
import '../services/github_api_service.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final GitHubApiService apiService;
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.apiService,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _tokenController;
  late final UpdateService _updateService;
  StreamSubscription<OtaEvent>? _otaSubscription;

  bool _obscureToken = true;
  bool _isLoadingRateLimit = false;
  GitHubRateLimit? _rateLimit;

  bool _isCheckingUpdate = false;
  AppUpdateInfo? _updateInfo;
  bool _isDownloadingUpdate = false;
  String? _downloadProgress;
  String? _updateError;

  int _amoledTapCount = 0;
  DateTime? _lastAmoledTap;

  @override
  void initState() {
    super.initState();
    final savedToken = widget.storageService.getToken() ?? '';
    _tokenController = TextEditingController(text: savedToken);
    _updateService = UpdateService();
    _rateLimit = widget.apiService.lastRateLimit;
    _refreshRateLimit();
  }

  @override
  void dispose() {
    _otaSubscription?.cancel();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _refreshRateLimit() async {
    setState(() => _isLoadingRateLimit = true);
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

  void _onAmoledTapped(AppLocalizations loc) async {
    final now = DateTime.now();
    if (_lastAmoledTap == null ||
        now.difference(_lastAmoledTap!) > const Duration(seconds: 4)) {
      _amoledTapCount = 1;
    } else {
      _amoledTapCount++;
    }
    _lastAmoledTap = now;

    if (AppThemeService.currentTheme != AppThemeMode.amoled) {
      await AppThemeService.changeTheme(
        AppThemeMode.amoled,
        widget.storageService,
      );
      widget.onSettingsChanged?.call();
      if (mounted) setState(() {});
    }

    // 10 Taps unlock AMOLED Sakura
    if (_amoledTapCount >= 10) {
      _amoledTapCount = 0;
      await AppThemeService.unlockJapaneseTheme(widget.storageService);
      await AppThemeService.changeTheme(
        AppThemeMode.amoledJapanese,
        widget.storageService,
      );
      widget.onSettingsChanged?.call();
      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🌸 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  loc.easterEggJapaneseToast,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D1838),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _checkForUpdates(AppLocalizations loc) async {
    setState(() {
      _isCheckingUpdate = true;
      _updateError = null;
    });

    final info = await _updateService.checkForUpdate(
      personalAccessToken: widget.storageService.getToken(),
    );

    if (mounted) {
      setState(() {
        _updateInfo = info;
        _isCheckingUpdate = false;
      });
      if (!info.hasUpdate) {
        UpdateService.cleanDownloadedApk();
        UpdateService.cleanInstalledBackupApk();
      }
    }
  }

  void _runOtaUpdate(String apkUrl, AppLocalizations loc) {
    setState(() {
      _isDownloadingUpdate = true;
      _downloadProgress = '0%';
      _updateError = null;
    });

    _otaSubscription?.cancel();
    _otaSubscription = _updateService
        .startOtaUpdate(apkUrl)
        .listen(
          (OtaEvent event) {
            if (!mounted) return;
            setState(() {
              if (event.status == OtaStatus.DOWNLOADING) {
                _downloadProgress = '${event.value}%';
              } else if (event.status == OtaStatus.INSTALLING) {
                _downloadProgress = loc.installingUpdate;
                _isDownloadingUpdate = false;
                UpdateService.saveApkToDownloads(
                  versionTag: _updateInfo?.latestVersion,
                );
              } else if (event.status == OtaStatus.INSTALLATION_DONE) {
                _downloadProgress = loc.alreadyLatestVersion;
                _isDownloadingUpdate = false;
                UpdateService.cleanDownloadedApk();
                UpdateService.cleanInstalledBackupApk();
              } else {
                _isDownloadingUpdate = false;
                _updateError = loc.updateFailed;
                UpdateService.cleanDownloadedApk();
              }
            });
          },
          onError: (err) {
            if (!mounted) return;
            setState(() {
              _isDownloadingUpdate = false;
              _updateError = loc.updateFailed;
            });
            UpdateService.cleanDownloadedApk();
          },
        );
  }

  Widget _buildModernCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.0),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryCyan, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations loc) {
    final currentLang = AppLanguageService.currentLanguage;
    final sortedLanguages = AppLanguage.sortedAlphabetically;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.languageSectionTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = sortedLanguages[index];
                    final isSelected = lang == currentLang;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 2,
                      ),
                      leading: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryCyan
                              : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        lang.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryCyan.withAlpha(100),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                loc.activeLanguageBadge,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryCyan,
                                ),
                              ),
                            )
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await AppLanguageService.changeLanguage(
                          lang,
                          widget.storageService,
                        );
                        widget.onSettingsChanged?.call();
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLang = AppLanguageService.currentLanguage;
    final currentTheme = AppThemeService.currentTheme;
    final isJapaneseUnlocked = AppThemeService.isJapaneseUnlocked(
      widget.storageService,
    );
    final hasToken =
        widget.storageService.getToken() != null &&
        widget.storageService.getToken()!.trim().isNotEmpty;
    final rateLimit =
        _rateLimit ?? GitHubRateLimit.defaultLimit(hasToken: hasToken);

    final themeOptions = [
      {
        'id': AppThemeMode.dark,
        'title': loc.themeDark,
        'icon': Icons.ac_unit_rounded,
        'accent': const Color(0xFF38BDF8),
        'badge': 'DARK',
      },
      {
        'id': AppThemeMode.amoled,
        'title': loc.themeAmoled,
        'icon': Icons.nightlight_round,
        'accent': const Color(0xFFA78BFA),
        'badge': 'AMOLED',
      },
      if (isJapaneseUnlocked)
        {
          'id': AppThemeMode.amoledJapanese,
          'title': loc.themeAmoledJapanese,
          'icon': Icons.local_florist_rounded,
          'accent': const Color(0xFFF472B6),
          'badge': 'AMOLED',
        },
      {
        'id': AppThemeMode.light,
        'title': loc.themeLight,
        'icon': Icons.light_mode_rounded,
        'accent': const Color(0xFFFBBF24),
        'badge': 'LIGHT',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.settingsTitle,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ───────────────── CARD 1: THEME SELECTOR (Phantek Symmetrical Alignment) ─────────────────
            _buildModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.palette_outlined,
                    title: loc.themeSectionTitle,
                    subtitle: loc.themeSectionSubtitle,
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 74,
                        ),
                    itemCount: themeOptions.length,
                    itemBuilder: (context, index) {
                      final item = themeOptions[index];
                      final mode = item['id'] as AppThemeMode;
                      final isSelected = currentTheme == mode;
                      final accent = item['accent'] as Color;
                      final badge = item['badge'] as String;
                      final theme = Theme.of(context);

                      return Material(
                        color: isSelected
                            ? accent.withAlpha(25)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (mode == AppThemeMode.amoled) {
                              _onAmoledTapped(loc);
                            } else {
                              AppThemeService.changeTheme(
                                mode,
                                widget.storageService,
                              );
                              widget.onSettingsChanged?.call();
                              if (mounted) setState(() {});
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? accent
                                    : theme.colorScheme.outline.withAlpha(30),
                                width: isSelected ? 1.6 : 1.0,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: 18,
                                      color: isSelected
                                          ? accent
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? accent
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withAlpha(20),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: accent.withAlpha(120),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          badge,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: accent,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ───────────────── CARD 2: CARD OPACITY & PERFORMANCE (60 FPS Optimized) ─────────────────
            ValueListenableBuilder<double>(
              valueListenable: AppThemeService.surfaceOpacityNotifier,
              builder: (context, opacity, _) {
                final pct = (opacity * 100).round();
                final isMax = opacity >= 0.999;

                return _buildModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.blur_on_rounded,
                        title: loc.themeOpacityTitle,
                        subtitle: loc.themeOpacitySubtitle,
                        trailing: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            AppThemeService.changeSurfaceOpacity(
                              1.0,
                              widget.storageService,
                            );
                            widget.onSettingsChanged?.call();
                            if (mounted) setState(() {});
                          },
                          child: Text(
                            loc.resetLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryCyan,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isMax)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.withAlpha(100),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    loc.settingsBypassShaderNotice,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primaryCyan,
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: AppTheme.primaryCyan,
                          overlayColor: AppTheme.primaryCyan.withAlpha(30),
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                        ),
                        child: Slider(
                          value: opacity,
                          min: 0.50,
                          max: 1.00,
                          divisions: 10,
                          onChanged: (val) {
                            AppThemeService.changeSurfaceOpacity(
                              val,
                              widget.storageService,
                            );
                            widget.onSettingsChanged?.call();
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                      const Divider(height: 16),
                      // Background Animation Switch
                      ValueListenableBuilder<bool>(
                        valueListenable:
                            AppThemeService.bgAnimationEnabledNotifier,
                        builder: (context, animEnabled, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.bgAnimationTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      loc.bgAnimationSubtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: animEnabled,
                                activeThumbColor: AppTheme.primaryCyan,
                                onChanged: (val) {
                                  AppThemeService.setBackgroundAnimation(
                                    val,
                                    widget.storageService,
                                  );
                                  widget.onSettingsChanged?.call();
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ───────────────── CARD 3: LANGUAGE SELECTOR (22 Global Languages) ─────────────────
            _buildModernCard(
              child: InkWell(
                onTap: () => _showLanguagePicker(context, loc),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          color: AppTheme.primaryCyan,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.languageSectionTitle,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentLang.flag}  ${currentLang.nativeName} (${currentLang.name})',
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
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ───────────────── CARD 4: GITHUB TOKEN & RATE LIMIT ─────────────────
            _buildModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.key_rounded,
                    title: loc.githubTokenTitle,
                    subtitle: loc.tokenSubtitle,
                    trailing: IconButton(
                      icon: _isLoadingRateLimit
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppTheme.primaryCyan,
                            ),
                      onPressed: _isLoadingRateLimit ? null : _refreshRateLimit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rate limit progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loc.requestsUsed}: ${rateLimit.used} / ${rateLimit.limit}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${loc.remainingQuota}: ${rateLimit.remaining}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: rateLimit.remainingPercentage > 30
                              ? AppTheme.accentGreen
                              : AppTheme.accentAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: rateLimit.limit > 0
                          ? (rateLimit.remaining / rateLimit.limit)
                          : 0.0,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rateLimit.remainingPercentage > 30
                            ? AppTheme.accentGreen
                            : AppTheme.accentAmber,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Input field
                  TextField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: loc.tokenHint,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscureToken = !_obscureToken),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasToken)
                        TextButton(
                          onPressed: () => _clearToken(loc),
                          child: Text(
                            loc.deleteToken,
                            style: TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _saveToken(loc),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          loc.saveToken,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ───────────────── CARD 5: ABOUT APP & UPDATES ─────────────────
            _buildModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.info_outline_rounded,
                    title: loc.aboutApp,
                    subtitle: loc.appDescriptionLabel,
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 10),
                  _buildAboutRow(loc.appVersionLabel, AppConfig.appVersion),
                  _buildAboutRow(
                    loc.buildNumberLabel,
                    '${AppConfig.buildNumber} (Release APK)',
                  ),
                  _buildAboutRow(loc.architectureLabel, loc.architectureValue),
                  _buildAboutRow(loc.licenseLabel, AppConfig.license),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 10),

                  // Developer Item with Live Auto-Updating Profile Picture
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(AppConfig.developerGithubUrl);
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
                                  'User-Agent': 'GitPulseMobile/1.0',
                                },
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppTheme.primaryCyan,
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
                                        AppTheme.primaryCyan.withValues(
                                          alpha: 0.25,
                                        ),
                                        AppTheme.primaryCyan.withValues(
                                          alpha: 0.08,
                                        ),
                                      ],
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppConfig.developerUsername.isNotEmpty
                                        ? AppConfig.developerUsername[0]
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: AppTheme.primaryCyan,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 14),

                  // ───────────────── SUB-BAGIAN: APP UPDATES ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCyan.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.system_update_alt_rounded,
                              color: AppTheme.primaryCyan,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.updateSectionTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (_updateInfo != null)
                                Text(
                                  _updateInfo!.hasUpdate
                                      ? '${loc.updateAvailable}: ${_updateInfo!.latestVersion}'
                                      : loc.alreadyLatestVersion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _updateInfo!.hasUpdate
                                        ? AppTheme.accentGreen
                                        : AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      _isCheckingUpdate
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              onPressed: () => _checkForUpdates(loc),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                side: BorderSide(color: AppTheme.border),
                              ),
                              child: Text(
                                loc.checkForUpdates,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                    ],
                  ),
                  if (_updateInfo != null &&
                      _updateInfo!.hasUpdate &&
                      !_isDownloadingUpdate) ...[
                    const SizedBox(height: 10),
                    if (_updateInfo!.releaseNotes.trim().isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _updateInfo!.releaseNotes.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 15),
                        onPressed: () =>
                            _runOtaUpdate(_updateInfo!.apkDownloadUrl!, loc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: Text(
                          '${loc.updateNow} (${_updateInfo!.latestVersion})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  if (_isDownloadingUpdate) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${loc.downloadingUpdate} ${_downloadProgress ?? ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_updateError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _updateError!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.accentRed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          GestureDetector(
            onTap: onTap,
            child: Row(
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
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: AppTheme.primaryCyan,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
