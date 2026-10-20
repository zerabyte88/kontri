import 'package:flutter/foundation.dart';
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

  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Kontri'],
      '''MIT License

Copyright (c) 2026 zerabyte88

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''',
    );
  });

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
