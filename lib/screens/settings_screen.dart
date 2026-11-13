import 'package:material_ui/material_ui.dart';
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

    final staticThemes = [
      _ThemeGridItem(
        mode: AppThemeMode.system,
        title: loc.themeSystem,
        icon: Icons.brightness_auto_rounded,
        accent: const Color(0xFF2563EB),
        badge: 'Auto',
      ),
      _ThemeGridItem(
        mode: AppThemeMode.cleanLight,
        title: loc.themeCleanLight,
        icon: Icons.light_mode_rounded,
        accent: const Color(0xFF0EA5E9),
        badge: 'Static',
      ),
      _ThemeGridItem(
        mode: AppThemeMode.amoledPure,
        title: loc.themeAmoledPure,
        icon: Icons.dark_mode_rounded,
        accent: const Color(0xFF60A5FA),
        badge: 'Static',
      ),
    ];

    final animatedThemes = [
      _ThemeGridItem(
        mode: AppThemeMode.amoledSnowfall,
        title: loc.themeDark,
        icon: Icons.ac_unit_rounded,
        accent: const Color(0xFF38BDF8),
        badge: 'Live',
      ),
      _ThemeGridItem(
        mode: AppThemeMode.light,
        title: loc.themeLight,
        icon: Icons.wb_sunny_rounded,
        accent: const Color(0xFFFBBF24),
        badge: 'Live',
      ),
      _ThemeGridItem(
        mode: AppThemeMode.amoled,
        title: loc.themeAmoled,
        icon: Icons.nightlight_round,
        accent: const Color(0xFFA78BFA),
        badge: 'Live',
      ),
      _ThemeGridItem(
        mode: AppThemeMode.amoledJapanese,
        title: loc.themeAmoledJapanese,
        icon: Icons.local_florist_rounded,
        accent: const Color(0xFFF472B6),
        badge: 'Live',
      ),
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
            _buildAppearanceCard(
              context,
              loc,
              currentTheme,
              staticThemes,
              animatedThemes,
            ),
            const SizedBox(height: 12),
            _buildLanguageCard(context, loc, currentLang),
            const SizedBox(height: 12),
            _buildTokenCard(context, loc, hasToken, rateLimit),
            const SizedBox(height: 12),
            _buildAboutCard(context, loc),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(
    BuildContext context,
    AppLocalizations loc,
    AppThemeMode currentTheme,
    List<_ThemeGridItem> staticThemes,
    List<_ThemeGridItem> animatedThemes,
  ) {
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
          _buildThemeRow(context, staticThemes, currentTheme, gap: 8),
          const SizedBox(height: 8),
          _buildThemeRow(context, animatedThemes, currentTheme, gap: 6),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.border.withAlpha(40)),
          const SizedBox(height: 14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (hasToken)
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);

    return _buildModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF06B6D4),
              ),
              const SizedBox(width: 8),
              Text(
                loc.aboutApp,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(theme, loc.appVersionLabel, AppConfig.appVersion),
          const SizedBox(height: 6),
          _buildDetailRow(theme, loc.buildNumberLabel, AppConfig.buildNumber),
          const SizedBox(height: 6),
          _buildDetailRow(
            theme,
            loc.licenseLabel,
            AppConfig.license,
            onTap: () => _showAppLicensePage(context, theme),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(50),
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.8),
                    child: Image.asset(
                      'assets/icons/developer_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.primary.withAlpha(22),
                        child: Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
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
                        'Developer: ${AppConfig.developerUsername}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'github.com/${AppConfig.developerUsername}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(130),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
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
                        color: theme.colorScheme.primary.withAlpha(22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(70),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'GitHub',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
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
        ],
      ),
    );
  }

  void _showAppLicensePage(BuildContext context, ThemeData theme) {
    showLicensePage(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: '',
      applicationLegalese: '',
      applicationIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          Text(
            '${AppConfig.appVersion} (${AppConfig.buildNumber})',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              'Copyright © 2026 ${AppConfig.developerUsername}\n'
              'Licensed under the ${AppConfig.license}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ),
          _buildLicenseLinkTile(
            theme: theme,
            icon: Icons.code_rounded,
            label: 'Source code',
            url: AppConfig.githubRepoUrl,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLicenseLinkTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String url,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            try {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(35),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF06B6D4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        url,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: const Color(0xFF06B6D4),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF06B6D4)
                              .withAlpha(120),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurface.withAlpha(130),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onTap != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (showChevron && onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
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

  Widget _buildThemeRow(
    BuildContext context,
    List<_ThemeGridItem> items,
    AppThemeMode currentTheme, {
    required double gap,
  }) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _buildThemeCard(
              context,
              items[i],
              isSelected: currentTheme == items[i].mode,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    _ThemeGridItem item, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = item.accent;

    return Material(
      color: isSelected
          ? accent.withValues(alpha: isDark ? 0.16 : 0.10)
          : cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppThemeService.changeTheme(item.mode, widget.storageService);
          widget.onSettingsChanged?.call();
          if (mounted) setState(() {});
        },
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accent
                  : cs.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.25),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected ? accent : cs.onSurface,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? accent : cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.50 : 0.35),
                    width: 0.9,
                  ),
                ),
                child: Text(
                  item.badge,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeGridItem {
  const _ThemeGridItem({
    required this.mode,
    required this.title,
    required this.icon,
    required this.accent,
    required this.badge,
  });

  final AppThemeMode mode;
  final String title;
  final IconData icon;
  final Color accent;
  final String badge;
}
