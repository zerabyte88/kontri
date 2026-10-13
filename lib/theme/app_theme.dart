import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'GitPulse';
  static const String appVersion = 'v2.4.3';
  static const String buildNumber = '24';
  static const String fullVersion = 'v2.4.3 (Build 24)';
  static const String releaseTag = 'v2.4.3';
  static const String githubRepoUrl =
      'https://github.com/zerabyte88/gitpulse-mobile';
  static const String developerUsername = 'zerabyte88';
  static const String developerGithubUrl = 'https://github.com/zerabyte88';
  static const String developerAvatarUrl =
      'https://avatars.githubusercontent.com/zerabyte88';
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
  static double cardOpacity = 1.0;

  // Dynamic Backgrounds & Surfaces (Phantek Slate Engine)
  static Color get background => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF000000),
    AppThemeMode.amoledJapanese => const Color(0xFF000000),
    AppThemeMode.light => const Color(0xFFF8FAFC), // Slate 50
    AppThemeMode.dark => const Color(0xFF0F172A), // Slate 900
  };

  static Color get surface {
    final base = switch (currentMode) {
      AppThemeMode.amoled => const Color(0xFF101012),
      AppThemeMode.amoledJapanese => const Color(0xFF140D13),
      AppThemeMode.light => const Color(0xFFFFFFFF),
      AppThemeMode.dark => const Color(0xFF1E293B), // Slate 800
    };
    if (cardOpacity < 0.999) {
      final alpha = (255 * cardOpacity.clamp(0.50, 1.00)).round().clamp(0, 255);
      return base.withAlpha(alpha);
    }
    return base;
  }

  static Color get surfaceElevated {
    final base = switch (currentMode) {
      AppThemeMode.amoled => const Color(0xFF1A1A1E),
      AppThemeMode.amoledJapanese => const Color(0xFF251228),
      AppThemeMode.light => const Color(0xFFF1F5F9), // Slate 100
      AppThemeMode.dark => const Color(0xFF334155), // Slate 700
    };
    if (cardOpacity < 0.999) {
      final alpha = (255 * cardOpacity.clamp(0.50, 1.00)).round().clamp(0, 255);
      return base.withAlpha(alpha);
    }
    return base;
  }

  static Color get border => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF2B2B33),
    AppThemeMode.amoledJapanese => const Color(0xFF381525),
    AppThemeMode.light => const Color(0xFFE2E8F0), // Slate 200
    AppThemeMode.dark => const Color(0xFF334155), // Slate 700
  };

  static Color get borderSubtle => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF1E1E24),
    AppThemeMode.amoledJapanese => const Color(0xFF220C17),
    AppThemeMode.light => const Color(0xFFF1F5F9), // Slate 100
    AppThemeMode.dark => const Color(0xFF1E293B), // Slate 800
  };

  // Semantic Accents (Modern Cobalt & Harmonious Accents)
  static Color get primaryCyan => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF00E5FF),
    AppThemeMode.amoledJapanese => const Color(
      0xFFF472B6,
    ), // Radiant Sakura Blossom
    AppThemeMode.light => const Color(0xFF2563EB), // Modern Cobalt Blue
    AppThemeMode.dark => const Color(0xFF2563EB), // Modern Cobalt Blue
  };

  static Color get primaryViolet => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFA855F7),
    AppThemeMode.amoledJapanese => const Color(
      0xFFFDA4AF,
    ), // Rose Quartz Sakura Accent
    AppThemeMode.light => const Color(0xFF0284C7), // Sky Accent
    AppThemeMode.dark => const Color(0xFF0284C7), // Sky Accent
  };

  static Color get accentGreen => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF00E676),
    AppThemeMode.amoledJapanese => const Color(0xFF34D399),
    AppThemeMode.light => const Color(0xFF16A34A),
    AppThemeMode.dark => const Color(0xFF22C55E),
  };

  static Color get accentAmber => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFFB300),
    AppThemeMode.amoledJapanese => const Color(0xFFFBBF24),
    AppThemeMode.light => const Color(0xFFD97706),
    AppThemeMode.dark => const Color(0xFFF59E0B),
  };

  static Color get accentRed => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFF3366),
    AppThemeMode.amoledJapanese => const Color(0xFFFB7185),
    AppThemeMode.light => const Color(0xFFDC2626),
    AppThemeMode.dark => const Color(0xFFEF4444),
  };

  static Color get accentOrange => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFF6D00),
    AppThemeMode.amoledJapanese => const Color(0xFFFB923C),
    AppThemeMode.light => const Color(0xFFEA580C),
    AppThemeMode.dark => const Color(0xFFF97316),
  };

  // Typography Monochromatic Hierarchy
  static Color get textPrimary => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFFFFFF),
    AppThemeMode.amoledJapanese => const Color(0xFFFFF1F2),
    AppThemeMode.light => const Color(0xFF0F172A), // Slate 900
    AppThemeMode.dark => const Color(0xFFF8FAFC), // Slate 50
  };

  static Color get textSecondary => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFA1A1AA),
    AppThemeMode.amoledJapanese => const Color(0xFFD4A5B8),
    AppThemeMode.light => const Color(0xFF475569), // Slate 600
    AppThemeMode.dark => const Color(0xFF94A3B8), // Slate 400
  };

  static Color get textMuted => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF71717A),
    AppThemeMode.amoledJapanese => const Color(0xFFA07FA8),
    AppThemeMode.light => const Color(0xFF94A3B8), // Slate 400
    AppThemeMode.dark => const Color(0xFF64748B), // Slate 500
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
      AppThemeMode.amoled => const Color(0xFF101012),
      AppThemeMode.amoledJapanese => const Color(0xFF140D13),
      AppThemeMode.light => const Color(0xFFFFFFFF),
      AppThemeMode.dark => const Color(0xFF1E293B),
    };

    final effectiveSurf = cardOpacity < 0.999
        ? surf.withAlpha(
            (255 * cardOpacity.clamp(0.50, 1.00)).round().clamp(0, 255),
          )
        : surf;

    final brd = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF2B2B33),
      AppThemeMode.amoledJapanese => const Color(0xFF381525),
      AppThemeMode.light => const Color(0xFFE2E8F0),
      AppThemeMode.dark => const Color(0xFF334155),
    };

    final prim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF00E5FF),
      AppThemeMode.amoledJapanese => const Color(0xFFF472B6),
      AppThemeMode.light => const Color(0xFF2563EB),
      AppThemeMode.dark => const Color(0xFF2563EB),
    };

    final sec = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFA855F7),
      AppThemeMode.amoledJapanese => const Color(0xFFFDA4AF),
      AppThemeMode.light => const Color(0xFF0284C7),
      AppThemeMode.dark => const Color(0xFF0284C7),
    };

    final txtPrim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFFFFFFF),
      AppThemeMode.amoledJapanese => const Color(0xFFFFF1F2),
      AppThemeMode.light => const Color(0xFF0F172A),
      AppThemeMode.dark => const Color(0xFFF8FAFC),
    };

    final txtMuted = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF71717A),
      AppThemeMode.amoledJapanese => const Color(0xFFA07FA8),
      AppThemeMode.light => const Color(0xFF94A3B8),
      AppThemeMode.dark => const Color(0xFF64748B),
    };

    final appTextTheme = baseTextTheme.apply(
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
              surface: effectiveSurf,
              onSurface: txtPrim,
              outline: brd,
              outlineVariant: const Color(0xFFF1F5F9),
              error: const Color(0xFFDC2626),
            )
          : ColorScheme.dark(
              primary: prim,
              secondary: sec,
              surface: effectiveSurf,
              onSurface: txtPrim,
              outline: brd,
              outlineVariant: const Color(0xFF1E293B),
              error: const Color(0xFFEF4444),
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
        color: effectiveSurf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: brd, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: effectiveSurf,
        hintStyle: TextStyle(color: txtMuted, fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          foregroundColor: Colors.white,
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
      dividerTheme: DividerThemeData(color: brd, thickness: 1, space: 1),
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
    final primarySlide =
        Tween<Offset>(begin: const Offset(0.05, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: primaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    final primaryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: primaryAnimation,
        curve: const Interval(0.05, 0.90, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.10, 0.95, curve: Curves.easeInCubic),
      ),
    );

    final secondarySlide =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.03, 0.0),
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    final secondaryFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInCubic),
        reverseCurve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return SlideTransition(
      position: primarySlide,
      child: FadeTransition(
        opacity: primaryFade,
        child: SlideTransition(
          position: secondarySlide,
          child: FadeTransition(opacity: secondaryFade, child: child),
        ),
      ),
    );
  }
}
