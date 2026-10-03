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

class SettingsSheet extends StatefulWidget {
  final StorageService storageService;
  final GitHubApiService apiService;
  final VoidCallback? onSettingsChanged;

  const SettingsSheet({
    super.key,
    required this.storageService,
    required this.apiService,
    this.onSettingsChanged,
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
      builder: (context) => SettingsSheet(
        storageService: storageService,
        apiService: apiService,
        onSettingsChanged: onSettingsChanged,
      ),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _tokenController;
  late final UpdateService _updateService;

  bool _obscureToken = true;
  bool _isLoadingRateLimit = false;
  bool _showTokenGuide = false;
  GitHubRateLimit? _rateLimit;

  // App Update State
  AppUpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  bool _isDownloadingUpdate = false;
  String _downloadProgress = '';
  String? _updateError;
  String? _downloadedApkPath;
  StreamSubscription<OtaEvent>? _otaSubscription;

  // Cached update check state across bottom sheet opens
  static DateTime? _lastUpdateCheckTime;
  static AppUpdateInfo? _cachedUpdateInfo;

  // Easter Egg State
  int _amoledTapCount = 0;
  DateTime? _lastAmoledTap;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.storageService.getToken() ?? '',
    );
    _updateService = UpdateService();
    _rateLimit = widget.apiService.lastRateLimit;
    _updateInfo = _cachedUpdateInfo;

    // Defer network requests until after modal slide-in animation finishes
    // so the sheet opens with zero frame-drops or setState interruptions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        if (_rateLimit == null) {
          _refreshRateLimit();
        }
        _checkUpdateSilently();
      });
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _otaSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkUpdateSilently() async {
    // Avoid hammering the GitHub API if already checked recently
    if (_lastUpdateCheckTime != null &&
        DateTime.now().difference(_lastUpdateCheckTime!) < const Duration(minutes: 15) &&
        _cachedUpdateInfo != null) {
      return;
    }

    final info = await _updateService.checkForUpdate(
      personalAccessToken: widget.storageService.getToken(),
    );
    _lastUpdateCheckTime = DateTime.now();
    _cachedUpdateInfo = info;
    if (mounted) {
      setState(() {
        _updateInfo = info;
      });
    }
  }

  Future<void> _checkUpdateManually() async {
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
    _otaSubscription = _updateService.startOtaUpdate(apkUrl).listen(
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
            ).then((path) {
              if (path != null && mounted) {
                setState(() {
                  _downloadedApkPath = path;
                });
              }
            });
          } else if (event.status == OtaStatus.INSTALLATION_DONE) {
            _downloadProgress = loc.alreadyLatestVersion;
            _isDownloadingUpdate = false;
            UpdateService.cleanDownloadedApk();
            UpdateService.cleanInstalledBackupApk();
          } else {
            _isDownloadingUpdate = false;
            _updateError = loc.updateFailed;
            UpdateService.saveApkToDownloads(
              versionTag: _updateInfo?.latestVersion,
            ).then((path) {
              if (path != null && mounted) {
                setState(() {
                  _downloadedApkPath = path;
                });
              }
            });
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
          backgroundColor: token.isEmpty ? AppTheme.surfaceElevated : AppTheme.accentGreen,
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

    // Normal theme switch to AMOLED if not already
    if (AppThemeService.currentTheme != AppThemeMode.amoled) {
      await AppThemeService.changeTheme(AppThemeMode.amoled, widget.storageService);
      widget.onSettingsChanged?.call();
      if (mounted) setState(() {});
    }

    // Easter Egg: 10 Taps unlock AMOLED Jejepangan
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

  Widget _buildAboutInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasToken = widget.storageService.getToken() != null &&
        widget.storageService.getToken()!.trim().isNotEmpty;
    final rateLimit = _rateLimit ??
        GitHubRateLimit.defaultLimit(hasToken: hasToken);

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
    final isJapaneseUnlocked = AppThemeService.isJapaneseUnlocked(widget.storageService);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1.2),
          left: BorderSide(color: AppTheme.border, width: 1),
          right: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

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
                      border: Border.all(color: AppTheme.border, width: 0.8),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CARD 1: Theme Selection (Dark, AMOLED, Japanese AMOLED Easter Egg, Light)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: AppTheme.primaryCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.themeSectionTitle,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppTheme.border, width: 0.8),
                          ),
                          child: Text(
                            switch (currentTheme) {
                              AppThemeMode.dark => loc.themeDark,
                              AppThemeMode.amoled => loc.themeAmoled,
                              AppThemeMode.amoledJapanese => loc.themeAmoledJapanese,
                              AppThemeMode.light => loc.themeLight,
                            },
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.themeSectionSubtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Theme Options Grid
                    Column(
                      children: [
                        Row(
                          children: [
                            // 1. Gelap
                            Expanded(
                              child: _buildOptionCard(
                              title: loc.themeDark,
                              subtitle: loc.themeDarkSubtitle,
                              leading: Icon(
                                Icons.dark_mode_outlined,
                                size: 17,
                                color: currentTheme == AppThemeMode.dark
                                    ? AppTheme.primaryCyan
                                    : AppTheme.textMuted,
                              ),
                              isSelected: currentTheme == AppThemeMode.dark,
                              onTap: () async {
                                await AppThemeService.changeTheme(
                                  AppThemeMode.dark,
                                  widget.storageService,
                                );
                                widget.onSettingsChanged?.call();
                                if (mounted) setState(() {});
                              },
                            ),
                            ),
                            const SizedBox(width: 8),

                            // 2. AMOLED (With Easter Egg tap listener)
                            Expanded(
                              child: _buildOptionCard(
                              title: loc.themeAmoled,
                              subtitle: loc.themeAmoledSubtitle,
                              leading: Icon(
                                Icons.brightness_2_rounded,
                                size: 17,
                                color: currentTheme == AppThemeMode.amoled
                                    ? AppTheme.primaryCyan
                                    : AppTheme.textMuted,
                              ),
                              isSelected: currentTheme == AppThemeMode.amoled,
                              onTap: () => _onAmoledTapped(loc),
                            ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // 3. Terang
                            Expanded(
                              child: _buildOptionCard(
                              title: loc.themeLight,
                              subtitle: loc.themeLightSubtitle,
                              leading: Icon(
                                Icons.light_mode_outlined,
                                size: 17,
                                color: currentTheme == AppThemeMode.light
                                    ? AppTheme.primaryCyan
                                    : AppTheme.textMuted,
                              ),
                              isSelected: currentTheme == AppThemeMode.light,
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

                            // 4. AMOLED Sakura (Shown if unlocked or currently active)
                            if (isJapaneseUnlocked || currentTheme == AppThemeMode.amoledJapanese)
                              Expanded(
                                child: _buildOptionCard(
                                  title: loc.themeAmoledJapanese,
                                  subtitle: loc.themeAmoledJapaneseSubtitle,
                                  leading: Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 17,
                                    color: currentTheme == AppThemeMode.amoledJapanese
                                        ? const Color(0xFFFF5C8A)
                                        : AppTheme.textMuted,
                                  ),
                                  isSelected: currentTheme == AppThemeMode.amoledJapanese,
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
                              )
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CARD 2: Language Selection
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          color: AppTheme.primaryCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.languageSectionTitle,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppTheme.border, width: 0.8),
                          ),
                          child: Text(
                            '${currentLang.flag} ${currentLang.nativeName}',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.languageSectionSubtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid of 6 Languages
                    Column(
                      children: [
                        for (int i = 0; i < AppLanguage.values.length; i += 2) ...[
                          if (i > 0) const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLanguageOptionCard(
                                  lang: AppLanguage.values[i],
                                  currentLang: currentLang,
                                  loc: loc,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (i + 1 < AppLanguage.values.length)
                                Expanded(
                                  child: _buildLanguageOptionCard(
                                    lang: AppLanguage.values[i + 1],
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CARD 3: GitHub API Rate Limit Tracker
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          color: AppTheme.primaryCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.rateLimitStatus,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
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
                            icon: Icon(Icons.refresh_rounded, size: 16, color: AppTheme.textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: loc.refresh,
                            onPressed: _refreshRateLimit,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasToken ? loc.personalTokenActive : loc.standardMode,
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
                        value: (totalLimit > 0) ? (remainingPercent / 100).clamp(0.0, 1.0) : 1.0,
                        backgroundColor: AppTheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
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
                    ...[
                    const SizedBox(height: 4),
                    Text(
                      '${loc.resetIn}: ${loc.formatCountdown(rateLimit.resetTime.difference(DateTime.now()))}',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CARD 4: GitHub Personal Access Token
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          color: AppTheme.primaryCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.githubTokenTitle,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasToken
                                ? AppTheme.accentGreen.withValues(alpha: 0.12)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: hasToken ? AppTheme.accentGreen.withValues(alpha: 0.3) : AppTheme.border,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            hasToken ? loc.tokenActiveBadge : loc.optionalBadge,
                            style: TextStyle(
                              color: hasToken ? AppTheme.accentGreen : AppTheme.textMuted,
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
                        color: AppTheme.textSecondary,
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
                        hintText: loc.tokenHint,
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
                      onTap: () {
                        setState(() {
                          _showTokenGuide = !_showTokenGuide;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                                fontWeight: FontWeight.w500,
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
                          border: Border.all(color: AppTheme.border, width: 0.8),
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
                        if (hasToken) ...[
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, size: 15),
                            label: Text(loc.deleteToken),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _clearToken(loc),
                          ),
                          const SizedBox(width: 12),
                        ],
                        ElevatedButton(
                          onPressed: () => _saveToken(loc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCyan,
                            foregroundColor: const Color(0xFF0D1117),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CARD 5: App Updates & OTA In-App Installation
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.system_update_alt_rounded,
                          color: AppTheme.primaryCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.updateSectionTitle,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_isCheckingUpdate)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTheme.primaryCyan,
                            ),
                          )
                        else if (_updateInfo?.hasUpdate == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _updateInfo!.latestVersion,
                              style: TextStyle(
                                color: AppTheme.accentGreen,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_updateInfo != null && _updateInfo!.hasUpdate) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.new_releases_rounded, size: 15, color: AppTheme.accentGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${loc.updateAvailable}: ${_updateInfo!.latestVersion}',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_updateInfo!.releaseNotes.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                _updateInfo!.releaseNotes.trim(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_isDownloadingUpdate) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${loc.downloadingUpdate} $_downloadProgress',
                                style: TextStyle(
                                  color: AppTheme.primaryCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_updateInfo!.apkDownloadUrl != null) ...[
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.download_rounded, size: 16),
                                  label: Text(
                                    loc.updateNow,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _runOtaUpdate(
                                    _updateInfo!.apkDownloadUrl!,
                                    loc,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_browser_rounded, size: 15),
                                label: Text(
                                  loc.openInBrowser,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryCyan,
                                  side: BorderSide(color: AppTheme.border, width: 1.0),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => UpdateService.openReleaseInBrowser(
                                  _updateInfo!.releaseUrl,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              _updateInfo != null
                                  ? loc.alreadyLatestVersion
                                  : '${AppConfig.appName} ${AppConfig.appVersion}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: Text(loc.checkForUpdates),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryCyan,
                                side: BorderSide(color: AppTheme.border, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              ),
                              onPressed: _isCheckingUpdate ? null : _checkUpdateManually,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_updateError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$_updateError. ${loc.openInBrowser}',
                        style: TextStyle(color: AppTheme.accentRed, fontSize: 11),
                      ),
                    ],

                    if (_downloadedApkPath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.download_done_rounded, size: 15, color: AppTheme.accentGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'File APK tersimpan di: $_downloadedApkPath',
                                style: TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CARD 6: About GitPulse & Build Version Info & Developer
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppTheme.accentGreen.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            AppConfig.appVersion,
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 10.5,
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
                    _buildAboutInfoRow(loc.appVersionLabel, AppConfig.appVersion),
                    const SizedBox(height: 6),
                    _buildAboutInfoRow(loc.buildNumberLabel, '${AppConfig.buildNumber} (Release APK)'),
                    const SizedBox(height: 6),
                    _buildAboutInfoRow(loc.architectureLabel, loc.architectureValue),
                    const SizedBox(height: 6),
                    _buildAboutInfoRow(loc.licenseLabel, AppConfig.license),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 10),

                    // Developer Item with Live Auto-Updating Profile Picture
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(AppConfig.developerGithubUrl);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryCyan, width: 1.2),
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
                                    if (progress == null) return child;
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
                                          AppTheme.primaryCyan.withValues(alpha: 0.25),
                                          AppTheme.primaryCyan.withValues(alpha: 0.08),
                                        ],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      AppConfig.developerUsername.isNotEmpty
                                          ? AppConfig.developerUsername[0].toUpperCase()
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
                            Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primaryCyan),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 13),
                        label: Text(
                          loc.viewOnGitHub,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryCyan,
                          side: BorderSide(color: AppTheme.border, width: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(AppConfig.githubRepoUrl);
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
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
      leading: Text(
        lang.flag,
        style: const TextStyle(fontSize: 16),
      ),
      isSelected: isSelected,
      onTap: () async {
        if (lang == currentLang) return;
        final messenger = ScaffoldMessenger.of(context);
        final toastText =
            '${loc.languageChangedToast}: ${lang.nativeName} (${lang.name})';
        await AppLanguageService.changeLanguage(
          lang,
          widget.storageService,
        );
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
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accent : AppTheme.border,
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
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? accent : AppTheme.textPrimary,
                            fontSize: 12.0,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            height: 1.15,
                          ),
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
                                  ? accent.withValues(alpha: 0.8)
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
