import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'GitPulse';
  static const String appVersion = 'v2.5.0';
  static const String buildNumber = '27';
  static const String fullVersion = 'v2.5.0 (Build 27)';
  static const String releaseTag = 'v2.5.0';
  static const String githubRepoUrl =
      'https://github.com/zerabyte88/gitpulse-mobile';
  static const String developerUsername = 'zerabyte88';
  static const String developerGithubUrl = 'https://github.com/zerabyte88';
  static const String developerAvatarUrl =
      'https://avatars.githubusercontent.com/zerabyte88';
  static const String license = 'MIT License';
}

enum AppThemeMode {
  amoledSnowfall('oled_snowfall'),
  amoled('amoled'),
  amoledJapanese('amoled_japanese'),
  amoledPure('oled_pure'),
  light('light'),
  cleanLight('light_clean');

  final String key;
  const AppThemeMode(this.key);

  static const AppThemeMode dark = amoledSnowfall;

  static AppThemeMode fromKey(String? key) {
    if (key == 'dark' || key == 'oled_snowfall') {
      return AppThemeMode.amoledSnowfall;
    }
    if (key == 'oled_pure' || key == 'pure_oled') {
      return AppThemeMode.amoledPure;
    }
    if (key == 'light_clean' || key == 'clean_light') {
      return AppThemeMode.cleanLight;
    }
    return AppThemeMode.values.firstWhere(
      (m) => m.key == key,
      orElse: () => AppThemeMode.amoledSnowfall,
    );
  }
}

class AppTheme {
  static AppThemeMode currentMode = AppThemeMode.amoledSnowfall;
  static double cardOpacity = 1.0;

  // Background and surface colors
  static Color get background => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF000000),
    AppThemeMode.amoledJapanese => const Color(0xFF000000),
    AppThemeMode.light => const Color(0xFFF8FAFC),
    AppThemeMode.amoledSnowfall => const Color(0xFF000000),
    AppThemeMode.amoledPure => const Color(0xFF000000),
    AppThemeMode.cleanLight => const Color(0xFFF8FAFC),
  };

  static Color get surface {
    final base = switch (currentMode) {
      AppThemeMode.amoled => const Color(0xFF101012),
      AppThemeMode.amoledJapanese => const Color(0xFF140D13),
      AppThemeMode.light => const Color(0xFFFFFFFF),
      AppThemeMode.amoledSnowfall => const Color(0xFF0C1322),
      AppThemeMode.amoledPure => const Color(0xFF101012),
      AppThemeMode.cleanLight => const Color(0xFFFFFFFF),
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
      AppThemeMode.light => const Color(0xFFF1F5F9),
      AppThemeMode.amoledSnowfall => const Color(0xFF141F36),
      AppThemeMode.amoledPure => const Color(0xFF18181B),
      AppThemeMode.cleanLight => const Color(0xFFF1F5F9),
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
    AppThemeMode.light => const Color(0xFFE2E8F0),
    AppThemeMode.amoledSnowfall => const Color(0xFF1E293B),
    AppThemeMode.amoledPure => const Color(0xFF27272A),
    AppThemeMode.cleanLight => const Color(0xFFE2E8F0),
  };

  static Color get borderSubtle => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF1E1E24),
    AppThemeMode.amoledJapanese => const Color(0xFF220C17),
    AppThemeMode.light => const Color(0xFFF1F5F9),
    AppThemeMode.amoledSnowfall => const Color(0xFF151D2F),
    AppThemeMode.amoledPure => const Color(0xFF18181B),
    AppThemeMode.cleanLight => const Color(0xFFF1F5F9),
  };

  // Semantic accents
  static Color get primaryCyan => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF00E5FF),
    AppThemeMode.amoledJapanese => const Color(0xFFF472B6),
    AppThemeMode.light => const Color(0xFF2563EB),
    AppThemeMode.amoledSnowfall => const Color(0xFF38BDF8),
    AppThemeMode.amoledPure => const Color(0xFF60A5FA),
    AppThemeMode.cleanLight => const Color(0xFF0EA5E9),
  };

  static Color get primaryViolet => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFA855F7),
    AppThemeMode.amoledJapanese => const Color(0xFFFDA4AF),
    AppThemeMode.light => const Color(0xFF0284C7),
    AppThemeMode.amoledSnowfall => const Color(0xFF0EA5E9),
    AppThemeMode.amoledPure => const Color(0xFF3B82F6),
    AppThemeMode.cleanLight => const Color(0xFF0284C7),
  };

  static Color get accentGreen => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF00E676),
    AppThemeMode.amoledJapanese => const Color(0xFF34D399),
    AppThemeMode.light => const Color(0xFF16A34A),
    AppThemeMode.amoledSnowfall => const Color(0xFF22C55E),
    AppThemeMode.amoledPure => const Color(0xFF22C55E),
    AppThemeMode.cleanLight => const Color(0xFF16A34A),
  };

  static Color get accentAmber => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFFB300),
    AppThemeMode.amoledJapanese => const Color(0xFFFBBF24),
    AppThemeMode.light => const Color(0xFFD97706),
    AppThemeMode.amoledSnowfall => const Color(0xFFF59E0B),
    AppThemeMode.amoledPure => const Color(0xFFF59E0B),
    AppThemeMode.cleanLight => const Color(0xFFD97706),
  };

  static Color get accentRed => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFF3366),
    AppThemeMode.amoledJapanese => const Color(0xFFFB7185),
    AppThemeMode.light => const Color(0xFFDC2626),
    AppThemeMode.amoledSnowfall => const Color(0xFFEF4444),
    AppThemeMode.amoledPure => const Color(0xFFEF4444),
    AppThemeMode.cleanLight => const Color(0xFFDC2626),
  };

  static Color get accentOrange => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFF6D00),
    AppThemeMode.amoledJapanese => const Color(0xFFFB923C),
    AppThemeMode.light => const Color(0xFFEA580C),
    AppThemeMode.amoledSnowfall => const Color(0xFFF97316),
    AppThemeMode.amoledPure => const Color(0xFFF97316),
    AppThemeMode.cleanLight => const Color(0xFFEA580C),
  };

  // Typography Monochromatic Hierarchy
  static Color get textPrimary => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFFFFFFF),
    AppThemeMode.amoledJapanese => const Color(0xFFFFF1F2),
    AppThemeMode.light => const Color(0xFF0F172A), // Slate 900
    AppThemeMode.amoledSnowfall => const Color(0xFFF8FAFC), // Pure Snow White (Snowfall)
    AppThemeMode.amoledPure => const Color(0xFFF8FAFC),
    AppThemeMode.cleanLight => const Color(0xFF0F172A), // Slate 900
  };

  static Color get textSecondary => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFFA1A1AA),
    AppThemeMode.amoledJapanese => const Color(0xFFD4A5B8),
    AppThemeMode.light => const Color(0xFF475569), // Slate 600
    AppThemeMode.amoledSnowfall => const Color(0xFF94A3B8), // Slate 400 (Snowfall)
    AppThemeMode.amoledPure => const Color(0xFFA1A1AA),
    AppThemeMode.cleanLight => const Color(0xFF475569), // Slate 600
  };

  static Color get textMuted => switch (currentMode) {
    AppThemeMode.amoled => const Color(0xFF71717A),
    AppThemeMode.amoledJapanese => const Color(0xFFA07FA8),
    AppThemeMode.light => const Color(0xFF94A3B8), // Slate 400
    AppThemeMode.amoledSnowfall => const Color(0xFF94A3B8), // Slate 400 (Snowfall)
    AppThemeMode.amoledPure => const Color(0xFF71717A),
    AppThemeMode.cleanLight => const Color(0xFF94A3B8), // Slate 400
  };

  static bool get isLight =>
      currentMode == AppThemeMode.light ||
      currentMode == AppThemeMode.cleanLight;

  static ThemeData get currentThemeData => getTheme(currentMode);
  static ThemeData get darkTheme => getTheme(AppThemeMode.amoledSnowfall);

  static ThemeData getTheme(AppThemeMode mode) {
    final isLightMode =
        mode == AppThemeMode.light || mode == AppThemeMode.cleanLight;
    final baseTextTheme = isLightMode
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    final surf = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF101012),
      AppThemeMode.amoledJapanese => const Color(0xFF140D13),
      AppThemeMode.light => const Color(0xFFFFFFFF),
      AppThemeMode.amoledSnowfall => const Color(0xFF0C1322),
      AppThemeMode.amoledPure => const Color(0xFF101012),
      AppThemeMode.cleanLight => const Color(0xFFFFFFFF),
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
      AppThemeMode.amoledSnowfall => const Color(0xFF1E293B),
      AppThemeMode.amoledPure => const Color(0xFF27272A),
      AppThemeMode.cleanLight => const Color(0xFFE2E8F0),
    };

    final prim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF00E5FF),
      AppThemeMode.amoledJapanese => const Color(0xFFF472B6),
      AppThemeMode.light => const Color(0xFF2563EB),
      AppThemeMode.amoledSnowfall => const Color(0xFF38BDF8),
      AppThemeMode.amoledPure => const Color(0xFF60A5FA),
      AppThemeMode.cleanLight => const Color(0xFF0EA5E9),
    };

    final sec = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFA855F7),
      AppThemeMode.amoledJapanese => const Color(0xFFFDA4AF),
      AppThemeMode.light => const Color(0xFF0284C7),
      AppThemeMode.amoledSnowfall => const Color(0xFF0EA5E9),
      AppThemeMode.amoledPure => const Color(0xFF3B82F6),
      AppThemeMode.cleanLight => const Color(0xFF0284C7),
    };

    final txtPrim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFFFFFFF),
      AppThemeMode.amoledJapanese => const Color(0xFFFFF1F2),
      AppThemeMode.light => const Color(0xFF0F172A),
      AppThemeMode.amoledSnowfall => const Color(0xFFF8FAFC),
      AppThemeMode.amoledPure => const Color(0xFFF8FAFC),
      AppThemeMode.cleanLight => const Color(0xFF0F172A),
    };

    final txtMuted = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF71717A),
      AppThemeMode.amoledJapanese => const Color(0xFFA07FA8),
      AppThemeMode.light => const Color(0xFF94A3B8),
      AppThemeMode.amoledSnowfall => const Color(0xFF94A3B8),
      AppThemeMode.amoledPure => const Color(0xFF71717A),
      AppThemeMode.cleanLight => const Color(0xFF94A3B8),
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
              outlineVariant: const Color(0xFF151D2F),
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
          foregroundColor: mode == AppThemeMode.amoledSnowfall
              ? const Color(0xFF0F172A)
              : Colors.white,
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
