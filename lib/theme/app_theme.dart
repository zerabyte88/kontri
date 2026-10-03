import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  static const String appName = 'GitPulse';
  static const String appVersion = 'v1.0.12';
  static const String buildNumber = '13';
  static const String fullVersion = 'v1.0.12 (Build 13)';
  static const String releaseTag = 'v1.0.12';
  static const String githubRepoUrl = 'https://github.com/zerabyte88/gitpulse_mobile';
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
        AppThemeMode.amoled => const Color(0xFF101012),
        AppThemeMode.amoledJapanese => const Color(0xFF150C18),
        AppThemeMode.light => const Color(0xFFFFFFFF),
        AppThemeMode.dark => const Color(0xFF161B22),
      };

  static Color get surfaceElevated => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF1A1A1E),
        AppThemeMode.amoledJapanese => const Color(0xFF221327),
        AppThemeMode.light => const Color(0xFFEEF2F6),
        AppThemeMode.dark => const Color(0xFF21262D),
      };

  static Color get border => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF2B2B33),
        AppThemeMode.amoledJapanese => const Color(0xFF452452),
        AppThemeMode.light => const Color(0xFFD0D7DE),
        AppThemeMode.dark => const Color(0xFF30363D),
      };

  static Color get borderSubtle => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF1E1E24),
        AppThemeMode.amoledJapanese => const Color(0xFF2D1736),
        AppThemeMode.light => const Color(0xFFE6E8EB),
        AppThemeMode.dark => const Color(0xFF21262D),
      };

  // Semantic Accents
  static Color get primaryCyan => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFF00E5FF),
        AppThemeMode.amoledJapanese => const Color(0xFFFF5C8A), // Radiant Sakura Blossom
        AppThemeMode.light => const Color(0xFF0969DA),
        AppThemeMode.dark => const Color(0xFF58A6FF), // Electric GitHub Blue
      };

  static Color get primaryViolet => switch (currentMode) {
        AppThemeMode.amoled => const Color(0xFFA855F7),
        AppThemeMode.amoledJapanese => const Color(0xFFD946EF), // Fuji Wisteria
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

    final bg = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF000000),
      AppThemeMode.amoledJapanese => const Color(0xFF000000),
      AppThemeMode.light => const Color(0xFFF6F8FA),
      AppThemeMode.dark => const Color(0xFF0D1117),
    };

    final surf = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF101012),
      AppThemeMode.amoledJapanese => const Color(0xFF150C18),
      AppThemeMode.light => const Color(0xFFFFFFFF),
      AppThemeMode.dark => const Color(0xFF161B22),
    };

    final brd = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF2B2B33),
      AppThemeMode.amoledJapanese => const Color(0xFF452452),
      AppThemeMode.light => const Color(0xFFD0D7DE),
      AppThemeMode.dark => const Color(0xFF30363D),
    };

    final prim = switch (mode) {
      AppThemeMode.amoled => const Color(0xFF00E5FF),
      AppThemeMode.amoledJapanese => const Color(0xFFFF5C8A),
      AppThemeMode.light => const Color(0xFF0969DA),
      AppThemeMode.dark => const Color(0xFF58A6FF),
    };

    final sec = switch (mode) {
      AppThemeMode.amoled => const Color(0xFFA855F7),
      AppThemeMode.amoledJapanese => const Color(0xFFD946EF),
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

    final interTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: txtPrim,
      displayColor: txtPrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isLightMode ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: bg,
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
      textTheme: interTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
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
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
