import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'storage_service.dart';

class AppThemeService {
  static final ValueNotifier<AppThemeMode> currentThemeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.dark);
  static final ValueNotifier<double> surfaceOpacityNotifier =
      ValueNotifier<double>(0.85);

  static AppThemeMode get currentTheme => currentThemeNotifier.value;
  static double get surfaceOpacity => surfaceOpacityNotifier.value;

  static void init(StorageService storageService) {
    final savedKey = storageService.getThemeMode();
    final mode = AppThemeMode.fromKey(savedKey);
    AppTheme.currentMode = mode;
    currentThemeNotifier.value = mode;

    final savedOpacity = storageService.getSurfaceOpacity();
    surfaceOpacityNotifier.value = savedOpacity;
  }

  static Future<void> changeTheme(
    AppThemeMode mode,
    StorageService storageService,
  ) async {
    AppTheme.currentMode = mode;
    currentThemeNotifier.value = mode;
    await storageService.setThemeMode(mode.key);
  }

  static Future<void> changeSurfaceOpacity(
    double opacity,
    StorageService storageService,
  ) async {
    final clamped = opacity.clamp(0.50, 1.00);
    surfaceOpacityNotifier.value = clamped;
    await storageService.setSurfaceOpacity(clamped);
  }

  static bool isJapaneseUnlocked(StorageService storageService) {
    return storageService.isJapaneseThemeUnlocked();
  }

  static Future<void> unlockJapaneseTheme(StorageService storageService) async {
    await storageService.setJapaneseThemeUnlocked(true);
  }
}
