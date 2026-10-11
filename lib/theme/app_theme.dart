import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  static const String appName = 'GitPulse';
  static const String appVersion = 'v2.3.2';
  static const String buildNumber = '20';
  static const String fullVersion = 'v2.3.2 (Build 20)';
  static const String releaseTag = 'v2.3.2';
  static const String githubRepoUrl = 'https://github.com/zerabyte88/gitpulse-mobile';
  static const String developerUsername = 'zerabyte88';
  static const String developerGithubUrl = 'https://github.com/zerabyte88';
  static const String developerAvatarUrl = 'https://avatars.githubusercontent.com/zerabyte88';
  static const String license = 'MIT License';
}

enum AppThemeMode {
  dark('dark'),
  amoled('amoled'),
  amoledJapanese('amoled_japanese'),
  light('light');

  final String key;
  const AppThemeMode(this.key);

  static AppThemeMode fromKey(String? key) {
    return AppThemeMode.values.firstWhere(
      (m) => m.key == key,
      orElse: () => AppThemeMode.dark,
    );
  }
}

class AppTheme {
  static AppThemeMode currentMode = AppThemeMode.dark;

  // Dynamic Backgrounds & Surfaces
  static Color get background => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF000000),
        AppThemeMode.amoledJapanese => const Color(0xFF000000),
        AppThemeMode.light => const Color(0xFFF6F8FA),
        AppThemeMode.dark => const Color(0xFF0D1117),
      };

  static Color get surface => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xEB101012),
        AppThemeMode.amoledJapanese => const Color(0xEB180C1A),
        AppThemeMode.light => const Color(0xF0FFFFFF),
        AppThemeMode.dark => const Color(0xEB161B22),
      };

  static Color get surfaceElevated => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xEE1A1A1E),
        AppThemeMode.amoledJapanese => const Color(0xEE251228),
        AppThemeMode.light => const Color(0xF2EEF2F6),
        AppThemeMode.dark => const Color(0xEE21262D),
      };

  static Color get border => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF2B2B33),
        AppThemeMode.amoledJapanese => const Color(0xFF4D2040),
        AppThemeMode.light => const Color(0xFFD0D7DE),
        AppThemeMode.dark => const Color(0xFF30363D),
      };

  static Color get borderSubtle => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF1E1E24),
        AppThemeMode.amoledJapanese => const Color(0xFF33142A),
        AppThemeMode.light => const Color(0xFFE6E8EB),
        AppThemeMode.dark => const Color(0xFF21262D),
      };

  // Semantic Accents
  static Color get primaryCyan => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF00E5FF),
        AppThemeMode.amoledJapanese => const Color(0xFFFF65A3), // Radiant Sakura Blossom
        AppThemeMode.light => const Color(0xFF0969DA),
        AppThemeMode.dark => const Color(0xFF58A6FF), // Electric GitHub Blue
      };

  static Color get primaryViolet => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFA855F7),
        AppThemeMode.amoledJapanese => const Color(0xFFF472B6), // Soft Sakura Secondary
        AppThemeMode.light => const Color(0xFF8250DF),
        AppThemeMode.dark => const Color(0xFFBC8CFF),
      };

  static Color get accentGreen => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF00E676),
        AppThemeMode.amoledJapanese => const Color(0xFF34D399),
        AppThemeMode.light => const Color(0xFF1A7F37),
        AppThemeMode.dark => const Color(0xFF3FB950),
      };

  static Color get accentAmber => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFFFB300),
        AppThemeMode.amoledJapanese => const Color(0xFFFBBF24),
        AppThemeMode.light => const Color(0xFF9A6700),
        AppThemeMode.dark => const Color(0xFFD29922),
      };

  static Color get accentRed => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFFF3366),
        AppThemeMode.amoledJapanese => const Color(0xFFFB7185),
        AppThemeMode.light => const Color(0xFFCF222E),
        AppThemeMode.dark => const Color(0xFFF85149),
      };

  static Color get accentOrange => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFFF6D00),
        AppThemeMode.amoledJapanese => const Color(0xFFFB923C),
        AppThemeMode.light => const Color(0xFFBC4C00),
        AppThemeMode.dark => const Color(0xFFDB6D28),
      };

  // Typography Monochromatic Hierarchy
  static Color get textPrimary => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFFFFFFF),
        AppThemeMode.amoledJapanese => const Color(0xFFFFF0F5),
        AppThemeMode.light => const Color(0xFF1F2328),
        AppThemeMode.dark => const Color(0xFFF0F6FC),
      };

  static Color get textSecondary => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFA1A1AA),
        AppThemeMode.amoledJapanese => const Color(0xFFE2C4E8),
        AppThemeMode.light => const Color(0xFF656D76),
        AppThemeMode.dark => const Color(0xFF8B949E),
      };

  static Color get textMuted => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF71717A),
        AppThemeMode.amoledJapanese => const Color(0xFFA07FA8),
        AppThemeMode.light => const Color(0xFF8C959F),
        AppThemeMode.dark => const Color(0xFF6E7681),
      };

  static bool get isLight => currentMode == AppThemeMode.light;

  static ThemeData get currentThemeData => getTheme(currentMode);
  static ThemeData get darkTheme => getTheme(AppThemeMode.dark);

  static ThemeData getTheme(AppThemeMode mode) {
    final isLightMode = mode == AppThemeMode.light;
    final baseTextTheme = isLightMode
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;


    final surf = switch (mode) {
      AppThemeMode.amoled => const Color(0xEB101012),
      AppThemeMode.amoledJapanese => const Color(0xEB180C1A),
      AppThemeMode.light => const Color(0xF0FFFFFF),
      AppThemeMode.dark => const Color(0xEB161B22),
    };

    final brd = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF2B2B33),
      AppThemeMode.amoledJapanese => const Color(0xFF4D2040),
      AppThemeMode.light => const Color(0xFFD0D7DE),
      AppThemeMode.dark => const Color(0xFF30363D),
    };

    final prim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF00E5FF),
      AppThemeMode.amoledJapanese => const Color(0xFFFF65A3),
      AppThemeMode.light => const Color(0xFF0969DA),
      AppThemeMode.dark => const Color(0xFF58A6FF),
    };

    final sec = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFA855F7),
      AppThemeMode.amoledJapanese => const Color(0xFFF472B6),
      AppThemeMode.light => const Color(0xFF8250DF),
      AppThemeMode.dark => const Color(0xFFBC8CFF),
    };

    final txtPrim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFFFFFFF),
      AppThemeMode.amoledJapanese => const Color(0xFFFFF0F5),
      AppThemeMode.light => const Color(0xFF1F2328),
      AppThemeMode.dark => const Color(0xFFF0F6FC),
    };

    final txtMuted = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF71717A),
      AppThemeMode.amoledJapanese => const Color(0xFFA07FA8),
      AppThemeMode.light => const Color(0xFF8C959F),
      AppThemeMode.dark => const Color(0xFF6E7681),
    };

    final appTextTheme = GoogleFonts.poppinsTextTheme(baseTextTheme).apply(
      bodyColor: txtPrim,
      displayColor: txtPrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isLightMode ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: prim,
      colorScheme: isLightMode
          ? ColorScheme.light(
              primary: prim,
              secondary: sec,
              surface: surf,
              onSurface: txtPrim,
              error: const Color(0xFFCF222E),
            )
          : ColorScheme.dark(
              primary: prim,
              secondary: sec,
              surface: surf,
              onSurface: txtPrim,
              error: const Color(0xFFF85149),
            ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: txtPrim),
        titleTextStyle: TextStyle(
          color: txtPrim,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: brd, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        hintStyle: TextStyle(color: txtMuted, fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: brd, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: brd, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: prim, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: prim,
          foregroundColor: isLightMode ? Colors.white : const Color(0xFF0D1117),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: brd,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GitPulsePageTransitionsBuilder(),
          TargetPlatform.iOS: GitPulsePageTransitionsBuilder(),
          TargetPlatform.fuchsia: GitPulsePageTransitionsBuilder(),
          TargetPlatform.linux: GitPulsePageTransitionsBuilder(),
          TargetPlatform.macOS: GitPulsePageTransitionsBuilder(),
          TargetPlatform.windows: GitPulsePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Bespoke fluid page transitions builder for GitPulse.
///
/// Designed specifically for unified ambient background applications with
/// translucent and transparent Scaffolds.
///
/// Eliminates rigid card collisions, visual tearing, and transparent ghosting:
/// - Entering route: fades in smoothly (0.0 -> 1.0) with subtle forward glide (Offset(0.05, 0.0) -> Offset.zero)
///   using [Curves.easeOutCubic].
/// - Exiting route: fades out cleanly (1.0 -> 0.0) with subtle retreat (Offset.zero -> Offset(-0.03, 0.0))
///   using [Curves.easeInCubic].
///
/// Prevents the jarring double-exposure when routes share an underlying canvas background.
class GitPulsePageTransitionsBuilder extends PageTransitionsBuilder {
  const GitPulsePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _GitPulsePageTransition(
      primaryAnimation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _GitPulsePageTransition extends StatelessWidget {
  final Animation<double> primaryAnimation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _GitPulsePageTransition({
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Primary transition (this screen entering / leaving foreground)
    final primarySlide = Tween<Offset>(
      begin: const Offset(0.05, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: primaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    final primaryFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: primaryAnimation,
      curve: const Interval(0.05, 0.90, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.10, 0.95, curve: Curves.easeInCubic),
    ));

    // 2. Secondary transition (another screen being pushed on top of this screen)
    final secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.03, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    final secondaryFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.65, curve: Curves.easeInCubic),
      reverseCurve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));

    return SlideTransition(
      position: primarySlide,
      child: FadeTransition(
        opacity: primaryFade,
        child: SlideTransition(
          position: secondarySlide,
          child: FadeTransition(
            opacity: secondaryFade,
            child: child,
          ),
        ),
      ),
    );
  }
}
