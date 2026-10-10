import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final String releaseUrl;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.apkDownloadUrl,
    required this.releaseUrl,
  });
}

class UpdateService {
  static const String _releasesUrl =
      'https://api.github.com/repos/zerabyte88/gitpulse_mobile/releases/latest';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Compares semantic version strings like "v1.0.2" vs "v1.0.1"
  /// Returns 1 if vA > vB, -1 if vA < vB, 0 if equal.
  static int compareVersions(String vA, String vB) {
    List<int> parse(String v) {
      final clean = v.toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '');
      return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    }

    final pA = parse(vA);
    final pB = parse(vB);
    final maxLen = pA.length > pB.length ? pA.length : pB.length;

    for (int i = 0; i < maxLen; i++) {
      final numA = i < pA.length ? pA[i] : 0;
      final numB = i < pB.length ? pB[i] : 0;
      if (numA > numB) return 1;
      if (numA < numB) return -1;
    }
    return 0;
  }

  /// Checks latest GitHub release for GitPulse
  Future<AppUpdateInfo> checkForUpdate({String? personalAccessToken}) async {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitPulseMobile/${AppConfig.appVersion}',
    };
    if (personalAccessToken != null && personalAccessToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${personalAccessToken.trim()}';
    }

    try {
      final response = await _client
          .get(Uri.parse(_releasesUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final tagName = (json['tag_name'] as String?)?.trim() ?? '';
        final releaseName = (json['name'] as String?) ?? tagName;
        final body = (json['body'] as String?) ?? '';
        final htmlUrl = (json['html_url'] as String?) ??
            '${AppConfig.githubRepoUrl}/releases';

        String? apkUrl;
        if (json['assets'] is List) {
          final assets = json['assets'] as List;
          for (final asset in assets) {
            if (asset is Map) {
              final name = (asset['name'] as String?)?.toLowerCase() ?? '';
              if (name.endsWith('.apk')) {
                apkUrl = asset['browser_download_url'] as String?;
                break;
              }
            }
          }
        }

        final current = AppConfig.appVersion;
        final hasUpdate = compareVersions(tagName, current) > 0;

        return AppUpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: current,
          latestVersion: tagName.isNotEmpty ? tagName : current,
          releaseName: releaseName,
          releaseNotes: body,
          apkDownloadUrl: apkUrl,
          releaseUrl: htmlUrl,
        );
      }
    } catch (_) {
      // Offline or network error
    }

    return const AppUpdateInfo(
      hasUpdate: false,
      currentVersion: AppConfig.appVersion,
      latestVersion: AppConfig.appVersion,
      releaseName: AppConfig.appVersion,
      releaseNotes: '',
      apkDownloadUrl: null,
      releaseUrl: '${AppConfig.githubRepoUrl}/releases',
    );
  }

  /// Initiates in-app OTA APK download and triggers native Android package installer
  Stream<OtaEvent> startOtaUpdate(String downloadUrl) {
    try {
      return OtaUpdate().execute(
        downloadUrl,
        destinationFilename: 'gitpulse-latest.apk',
        androidProviderAuthority:
            'com.phantek.orion.rigel.ota_update_provider',
      );
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Opens APK or release page in external browser as fallback
  static Future<bool> openReleaseInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Cleans up any leftover or completed APK files in the OTA update folder
  /// to save internal storage space after download/installation.
  static Future<bool> cleanDownloadedApk({String? customPath}) async {
    if (customPath == null && !Platform.isAndroid) return false;
    bool deletedAny = false;
    try {
      final candidates = <String>{};
      if (customPath != null) {
        candidates.add(customPath);
      }

      // App internal data directory via systemTemp parent
      try {
        final parentDir = Directory.systemTemp.parent.path;
        candidates.add('$parentDir/files/ota_update');
      } catch (_) {}

      // Standard Android internal data directory paths
      candidates.add('/data/user/0/com.phantek.orion.rigel/files/ota_update');
      candidates.add('/data/data/com.phantek.orion.rigel/files/ota_update');
      candidates.add('/data/user/0/com.gitpulse.gitpulse_mobile/files/ota_update');
      candidates.add('/data/data/com.gitpulse.gitpulse_mobile/files/ota_update');

      for (final dirPath in candidates) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final entries = await dir.list().toList();
          for (final entry in entries) {
            if (entry is File && entry.path.toLowerCase().endsWith('.apk')) {
              await entry.delete();
              deletedAny = true;
            }
          }
        }
      }
    } catch (_) {
      // Ignore cleanup errors
    }
    return deletedAny;
  }

  /// Saves the downloaded update APK to standard Android public downloads directory
  /// (/storage/emulated/0/Download/GitPulse) as the primary downloaded APK file for installation.
  static Future<String?> saveApkToDownloads({String? versionTag}) async {
    if (!Platform.isAndroid) return null;
    try {
      final sourceCandidates = <String>[];
      try {
        final parentDir = Directory.systemTemp.parent.path;
        sourceCandidates.add('$parentDir/files/ota_update/gitpulse-latest.apk');
      } catch (_) {}
      sourceCandidates.addAll([
        '/data/user/0/com.phantek.orion.rigel/files/ota_update/gitpulse-latest.apk',
        '/data/data/com.phantek.orion.rigel/files/ota_update/gitpulse-latest.apk',
        '/data/user/0/com.gitpulse.gitpulse_mobile/files/ota_update/gitpulse-latest.apk',
        '/data/data/com.gitpulse.gitpulse_mobile/files/ota_update/gitpulse-latest.apk',
      ]);

      File? sourceFile;
      for (final p in sourceCandidates) {
        final f = File(p);
        if (await f.exists() && await f.length() > 0) {
          sourceFile = f;
          break;
        }
      }

      if (sourceFile == null) return null;

      final apkName = 'GitPulse-${versionTag ?? AppConfig.appVersion}.apk';
      final targetDirs = [
        '/storage/emulated/0/Download/GitPulse',
        '/storage/emulated/0/downloads/GitPulse',
        '/sdcard/Download/GitPulse',
      ];

      for (final dirPath in targetDirs) {
        try {
          final dir = Directory(dirPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          final targetFile = File('$dirPath/$apkName');
          await sourceFile.copy(targetFile.path);
          if (await targetFile.exists()) {
            return targetFile.path;
          }
        } catch (_) {
          // Continue to next candidate directory
        }
      }
    } catch (_) {
      // Ignore copy error
    }
    return null;
  }

  /// Backward-compatible alias for [saveApkToDownloads].
  static Future<String?> backupApkToDownloads({String? versionTag}) =>
      saveApkToDownloads(versionTag: versionTag);

  /// Downloads the APK directly and saves a copy in /storage/emulated/0/Download/GitPulse
  static Future<String?> downloadApkToDownloads(
    String downloadUrl, {
    String? versionTag,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      final apkName = 'GitPulse-${versionTag ?? AppConfig.appVersion}.apk';
      final targetDirs = [
        '/storage/emulated/0/Download/GitPulse',
        '/storage/emulated/0/downloads/GitPulse',
        '/sdcard/Download/GitPulse',
      ];

      final client = http.Client();
      final response = await client
          .get(Uri.parse(downloadUrl))
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        for (final dirPath in targetDirs) {
          try {
            final dir = Directory(dirPath);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
            final targetFile = File('$dirPath/$apkName');
            await targetFile.writeAsBytes(response.bodyBytes);
            if (await targetFile.exists()) {
              return targetFile.path;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }

  /// Automatically removes GitPulse update APKs from the Android public downloads
  /// directory (/storage/emulated/0/Download/GitPulse and /storage/emulated/0/Download)
  /// once they have been successfully installed.
  ///
  /// STRICT SAFETY GUARD:
  /// - Only targets files whose filename strictly starts with "gitpulse-" or "gitpulse_"
  ///   and ends with ".apk".
  /// - ONLY deletes the file if its version is <= the installed [currentVersion].
  /// - NEVER deletes or modifies any user files, documents, pictures, or other APKs in the folder.
  static Future<bool> cleanInstalledBackupApk({
    String? currentVersion,
    String? customPath,
  }) async {
    if (customPath == null && !Platform.isAndroid) return false;
    bool deletedAny = false;
    final activeVersion = currentVersion ?? AppConfig.appVersion;

    try {
      final targetDirs = <String>[];
      if (customPath != null) {
        targetDirs.add(customPath);
        targetDirs.add('$customPath/GitPulse');
      } else {
        targetDirs.addAll([
          '/storage/emulated/0/Download/GitPulse',
          '/storage/emulated/0/downloads/GitPulse',
          '/sdcard/Download/GitPulse',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/downloads',
          '/sdcard/Download',
        ]);
      }

      for (final dirPath in targetDirs) {
        try {
          final dir = Directory(dirPath);
          if (!await dir.exists()) continue;

          final entries = await dir.list().toList();
          for (final entry in entries) {
            if (entry is! File) continue;

            final fileName = entry.uri.pathSegments.isNotEmpty
                ? entry.uri.pathSegments.last
                : entry.path.split(Platform.pathSeparator).last;
            final lowerName = fileName.toLowerCase();

            // Strict safety check: must end with .apk
            if (!lowerName.endsWith('.apk')) {
              continue;
            }

            // Strict safety check: must start with gitpulse- or gitpulse_
            if (!lowerName.startsWith('gitpulse-') &&
                !lowerName.startsWith('gitpulse_')) {
              continue;
            }

            // Extract version from filename: e.g. "GitPulse-v1.0.2.apk" -> "1.0.2"
            final match = RegExp(
              r'^gitpulse[-_]v?([0-9]+(?:\.[0-9]+)*).*\.apk$',
              caseSensitive: false,
            ).firstMatch(fileName);

            if (match != null) {
              final fileVersion = match.group(1);
              if (fileVersion != null) {
                // If the file version is <= the currently installed app version,
                // it has been successfully installed, so safely delete the backup APK!
                if (compareVersions(fileVersion, activeVersion) <= 0) {
                  await entry.delete();
                  deletedAny = true;
                }
              }
            } else if (lowerName == 'gitpulse-latest.apk') {
              await entry.delete();
              deletedAny = true;
            }
          }

          // If this is the dedicated GitPulse subfolder and now empty, delete it
          if (dirPath.toLowerCase().endsWith('gitpulse')) {
            try {
              final remaining = await dir.list().toList();
              if (remaining.isEmpty) {
                await dir.delete();
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
    } catch (_) {}

    return deletedAny;
  }
}
