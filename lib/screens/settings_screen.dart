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
import '../widgets/glass_card.dart';

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

  bool _obscureToken = true;
  bool _isLoadingRateLimit = false;
  GitHubRateLimit? _rateLimit;

  @override
  void initState() {
    super.initState();
    final savedToken = widget.storageService.getToken() ?? '';
    _tokenController = TextEditingController(text: savedToken);
    _rateLimit = widget.apiService.lastRateLimit;
    _refreshRateLimit();
  }

  @override
  void dispose() {
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

  Widget _buildModernCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return GlassCard(
      padding: padding,
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
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
    final hasToken =
        widget.storageService.getToken() != null &&
        widget.storageService.getToken()!.trim().isNotEmpty;
    final rateLimit =
        _rateLimit ?? GitHubRateLimit.defaultLimit(hasToken: hasToken);

    final themeOptions = [
      {
        'id': AppThemeMode.amoledSnowfall,
        'title': loc.themeDark,
        'icon': Icons.ac_unit_rounded,
        'accent': const Color(0xFF38BDF8),
        'badge': 'AMOLED',
      },
      {
        'id': AppThemeMode.amoled,
        'title': loc.themeAmoled,
        'icon': Icons.nightlight_round,
        'accent': const Color(0xFFA78BFA),
        'badge': 'AMOLED',
      },
      {
        'id': AppThemeMode.amoledJapanese,
        'title': loc.themeAmoledJapanese,
        'icon': Icons.local_florist_rounded,
        'accent': const Color(0xFFF472B6),
        'badge': 'AMOLED',
      },
      {
        'id': AppThemeMode.amoledPure,
        'title': loc.themeAmoledPure,
        'icon': Icons.brightness_2_outlined,
        'accent': const Color(0xFF60A5FA),
        'badge': 'STATIC',
      },
      {
        'id': AppThemeMode.light,
        'title': loc.themeLight,
        'icon': Icons.light_mode_outlined,
        'accent': const Color(0xFF0284C7),
        'badge': 'LIGHT',
      },
      {
        'id': AppThemeMode.cleanLight,
        'title': loc.themeCleanLight,
        'icon': Icons.wb_sunny_outlined,
        'accent': const Color(0xFF0EA5E9),
        'badge': 'STATIC',
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
            // Appearance and visual effects
            _buildAppearanceCard(context, loc, currentTheme, themeOptions),
            const SizedBox(height: 12),

            // Interface language
            _buildLanguageCard(context, loc, currentLang),
            const SizedBox(height: 12),

            // GitHub token and rate limit
            _buildTokenCard(context, loc, hasToken, rateLimit),
            const SizedBox(height: 12),

            // About, developer, and updates
            _buildAboutCard(context, loc),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // Appearance card
  Widget _buildAppearanceCard(
    BuildContext context,
    AppLocalizations loc,
    AppThemeMode currentTheme,
    List<Map<String, dynamic>> themeOptions,
  ) {
    final theme = Theme.of(context);

    return _buildModernCard(
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 76,
            ),
            itemCount: themeOptions.length,
            itemBuilder: (context, index) {
              final item = themeOptions[index];
              final mode = item['id'] as AppThemeMode;
              final isSelected = currentTheme == mode;
              final accent = item['accent'] as Color;
              final badge = item['badge'] as String;

              return Material(
                color: isSelected
                    ? accent.withAlpha(25)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    AppThemeService.changeTheme(mode, widget.storageService);
                    widget.onSettingsChanged?.call();
                    if (mounted) setState(() {});
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
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                item['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
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
                                  borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.border.withAlpha(40)),
          const SizedBox(height: 14),

          // Surface Opacity Slider
          ValueListenableBuilder<double>(
            valueListenable: AppThemeService.surfaceOpacityNotifier,
            builder: (context, opacity, _) {
              final pct = (opacity * 100).round();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.opacity_rounded,
                            size: 15,
                            color: AppTheme.primaryCyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            loc.themeOpacityTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
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
                            fontSize: 11.5,
                            color: AppTheme.primaryCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryCyan,
                      inactiveTrackColor: AppTheme.border,
                      thumbColor: AppTheme.primaryCyan,
                      overlayColor: AppTheme.primaryCyan.withAlpha(30),
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
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
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: AppTheme.border.withAlpha(40)),
          const SizedBox(height: 12),

          // Background Animation Switch
          ValueListenableBuilder<bool>(
            valueListenable: AppThemeService.bgAnimationEnabledNotifier,
            builder: (context, animEnabled, _) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.animation_rounded,
                      size: 15,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        const SizedBox(height: 1),
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
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
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
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Interface language card
  Widget _buildLanguageCard(
    BuildContext context,
    AppLocalizations loc,
    AppLanguage currentLang,
  ) {
    return _buildModernCard(
      child: InkWell(
        onTap: () => _showLanguagePicker(context, loc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: AppTheme.primaryCyan,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
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
                color: AppTheme.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // GitHub token card
  Widget _buildTokenCard(
    BuildContext context,
    AppLocalizations loc,
    bool hasToken,
    GitHubRateLimit rateLimit,
  ) {
    final remainingPct = rateLimit.remainingPercentage;
    final isGood = remainingPct > 30;

    return _buildModernCard(
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

          // Slim Quota indicator
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
                  color: isGood ? AppTheme.accentGreen : AppTheme.accentAmber,
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
                isGood ? AppTheme.accentGreen : AppTheme.accentAmber,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),

          // Token Input Field
          TextField(
            controller: _tokenController,
            obscureText: _obscureToken,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: loc.tokenHint,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureToken
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasToken) ...[
                TextButton(
                  onPressed: () => _clearToken(loc),
                  child: Text(
                    loc.deleteToken,
                    style: TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () => _saveToken(loc),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: Text(
                  loc.saveToken,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buttonPrimaryBackground,
                  foregroundColor: AppTheme.buttonPrimaryForeground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // About and updates card
  Widget _buildAboutCard(BuildContext context, AppLocalizations loc) {
    return _buildModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.info_outline_rounded,
            title: loc.aboutApp,
            subtitle: loc.appDescriptionLabel,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.border.withAlpha(40)),
          const SizedBox(height: 8),

          _buildAboutRow(loc.appVersionLabel, AppConfig.appVersion),
          _buildAboutRow(
            loc.buildNumberLabel,
            AppConfig.buildNumber,
          ),
          _buildAboutRow(loc.architectureLabel, AppConfig.architecture),
          _buildAboutRow(
            loc.licenseLabel,
            AppConfig.license,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConfig.appName,
                applicationVersion:
                    '${AppConfig.appVersion} Build ${AppConfig.buildNumber}',
                applicationIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(height: 10),
          Divider(height: 1, color: AppTheme.border.withAlpha(40)),
          const SizedBox(height: 14),

          // Developer profile
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF06B6D4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withAlpha(40),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    AppConfig.developerAvatarUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 100,
                    cacheHeight: 100,
                    headers: const {
                      'Accept': 'image/*,*/*;q=0.8',
                      'User-Agent': 'Kontri/1.0',
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 44,
                        height: 44,
                        color: AppTheme.surface,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF06B6D4),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.developerLabel}: ${AppConfig.developerUsername}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loc.developerRole,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
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
                    final uri = Uri.parse(AppConfig.developerGithubUrl);
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.35),
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

        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value, {VoidCallback? onTap}) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
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
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: rowContent,
      );
    }
    return rowContent;
  }
}
