import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_language.dart';
import 'localization/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_language_service.dart';
import 'services/app_theme_service.dart';
import 'services/github_api_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();
  AppLanguageService.init(storageService);
  AppThemeService.init(storageService);
  final apiService = GitHubApiService(
    personalAccessToken: storageService.getToken(),
    storageService: storageService,
  );

  runApp(KontriApp(storageService: storageService, apiService: apiService));
}

class KontriApp extends StatelessWidget {
  final StorageService storageService;
  final GitHubApiService apiService;

  const KontriApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageService.currentLanguageNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<AppThemeMode>(
          valueListenable: AppThemeService.currentThemeNotifier,
          builder: (context, currentThemeMode, _) {
            return MaterialApp(
              title: 'Kontri',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getTheme(currentThemeMode),
              themeAnimationDuration: const Duration(milliseconds: 350),
              themeAnimationCurve: Curves.easeInOut,
              locale: currentLang.locale,
              supportedLocales: AppLanguage.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return AnimatedAppBackground(child: child ?? const SizedBox());
              },
              home: HomeScreen(
                storageService: storageService,
                apiService: apiService,
              ),
            );
          },
        );
      },
    );
  }
}
