# Kontri

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Kontri Logo" width="100" height="100" style="border-radius: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.2);" />
</p>

<p align="center">
  <strong>Mobile GitHub Analytics, Streak Tracking, and Repository Exploration.</strong>
</p>

<p align="center">
  <a href="https://github.com/zerabyte88/gitpulse/releases"><img src="https://img.shields.io/badge/Release-v1.0.0-06b6d4?style=flat&logo=github&logoColor=white&labelColor=0d1117" alt="Release" height="22" /></a>
  <img src="https://img.shields.io/badge/Platform-Android-10b981?style=flat&logo=android&logoColor=white&labelColor=0d1117" alt="Platform" height="22" />
  <img src="https://img.shields.io/badge/Arch-arm64--v8a-8b5cf6?style=flat&logo=arm&logoColor=white&labelColor=0d1117" alt="Architecture" height="22" />
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.13+-02569b?style=flat&logo=flutter&logoColor=white&labelColor=0d1117" alt="Flutter" height="22" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-64748b?style=flat&logo=open-source-initiative&logoColor=white&labelColor=0d1117" alt="License" height="22" /></a>
</p>

---

## Overview

**Kontri** is a lightweight, high-performance Android application built with Flutter that provides comprehensive GitHub telemetry, commit analytics, gamified contribution tiers, and repository code viewing directly from your phone.

---

## Key Features

- **Activity Telemetry**: Total contributions, active streaks, language distributions, and a 24-hour activity chart synced to your timezone.
- **Repository Explorer**: Inspect repositories, navigate nested directory trees, read source files with syntax line counts, and view Markdown docs.
- **Rolling Tiers**: Six gamified consistency badges measured over a continuous 365-day rolling window without seasonal resets.
- **Favorite Profiles**: Pin and monitor multiple GitHub profiles with adaptive 1- or 2-column dashboard views.
- **Curated Tech Feed**: Trending repositories and industry news curated from GitHub and Dev.to.
- **AMOLED Themes**: 6 distinct visual themes (Snowfall, Sakura, Midnight Slate, Light, AMOLED Pure, Clean Light) with adjustable surface translucency.
- **Quota Saver**: Smart local persistence and HTTP `ETag` (304 Not Modified) conditional queries to preserve rate limits.
- **In-App Releases (OTA)**: Automatic update check with direct APK installation from GitHub Releases.
- **Full Localization**: Native support for 22 interface languages, including Indonesian and English.

---

## Contribution Tiers

Tiers evaluate your commitment over the past **365 calendar days**. Both metrics must be satisfied to earn a badge:

| Tier | Badge Title | Contributions (365d) | Active Days (365d) |
| :--- | :--- | ---: | ---: |
| **Tier 1** | Mythic Archmage | ≥ 1,000 | ≥ 200 |
| **Tier 2** | Diamond Vanguard | ≥ 500 | ≥ 130 |
| **Tier 3** | Platinum Artisan | ≥ 250 | ≥ 70 |
| **Tier 4** | Gold Adventurer | ≥ 125 | ≥ 35 |
| **Tier 5** | Silver Explorer | ≥ 50 | ≥ 10 |
| **Tier 6** | Bronze Novice | Default | Default |

> **Note**: Active days reward consistent development habits. Commit streaks are tracked independently on the dashboard and will not demote your tier progress if a single calendar day is missed.

---

## Architecture & Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.13) | Core cross-platform engine |
| **Visualization** | `fl_chart` | Activity histograms and language charts |
| **Document Parser** | `flutter_markdown` | In-app Markdown rendering |
| **Networking** | `http` | REST v3 communication & Dev.to API |
| **Storage** | `shared_preferences` | Key-value settings and telemetry cache |
| **OTA Delivery** | `ota_update` | In-app package installer |
| **Assets** | `flutter_svg` | Vector icons and brand assets |

---

## Build from Source

### Prerequisites

- Flutter SDK 3.13+
- Android SDK & NDK configured
- Java 17+

### Build Steps

```bash
# Clone the repository
git clone https://github.com/zerabyte88/gitpulse.git
cd gitpulse

# Install dependencies
flutter pub get

# Compile optimized 64-bit release APK
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Compiled APK destination:  
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## License

This project is open-source under the [MIT License](LICENSE).

---

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a></sub>
</div>
