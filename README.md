<div align="center">
  <img src="assets/icons/app_icon.png" alt="Kontri Logo" width="130" height="130" />

  <h1>Kontri</h1>

  <p>
    <strong>Android application for GitHub analytics, contribution streaks, and repository exploration.</strong>
  </p>

  <p>
    <a href="https://github.com/zerabyte88/kontri/releases/latest"><img src="https://img.shields.io/badge/Release-v1.2.0-06b6d4?style=flat-square&logo=github&logoColor=white" alt="Release" /></a>
    <img src="https://img.shields.io/badge/Platform-Android-10b981?style=flat-square&logo=android&logoColor=white" alt="Platform" />
    <img src="https://img.shields.io/badge/Arch-arm64--v8a-8b5cf6?style=flat-square&logo=arm&logoColor=white" alt="Architecture" />
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.13+-02569b?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-64748b?style=flat-square&logo=open-source-initiative&logoColor=white" alt="License" /></a>
  </p>

  <p>
    <a href="https://github.com/zerabyte88/kontri/releases/latest"><b>Download APK</b></a> •
    <a href="#overview">Overview</a> •
    <a href="#key-features">Key Features</a> •
    <a href="#contribution-tiers">Contribution Tiers</a> •
    <a href="#architecture--stack">Architecture</a> •
    <a href="#build-from-source">Build</a>
  </p>
</div>

---

## Overview

**Kontri** is a lightweight, high-performance Android application built with Flutter that provides comprehensive GitHub telemetry, commit analytics, gamified contribution tiers, and repository code viewing directly from your mobile device.

Designed with an AMOLED-first philosophy and responsive glassmorphism aesthetic, Kontri enables developers to keep tabs on development velocity, inspect source trees across branches, and celebrate open-source consistency.

---

## Key Features

- **Activity Telemetry**: Total contributions, active streaks, language distributions, and a 24-hour activity chart synced to your timezone.
- **Repository Explorer**: Inspect repositories, navigate branches and nested directory trees, read source code with line counts, and view Markdown docs.
- **Commit Timeline**: Inspect recent commit messages, authors, and timestamps with direct repository references.
- **Rolling Tiers**: Six gamified consistency badges measured over a continuous 365-day rolling window without seasonal resets.
- **Favorite Profiles**: Pin and monitor multiple GitHub profiles with adaptive 1- or 2-column dashboard views.
- **Curated Tech Feed**: Trending repositories and industry news curated live from GitHub and Dev.to.
- **AMOLED Themes**: 6 distinct visual themes (*Snowfall*, *Sakura*, *Midnight Slate*, *Light*, *AMOLED Pure*, *Clean Light*) with customizable surface translucency.
- **Multilingual Support**: Fully localized in 22 languages including English, Indonesian, Japanese, Chinese, German, Spanish, French, and more.
- **Quota Saver & PAT Auth**: Smart local persistence and HTTP `ETag` (304 Not Modified) conditional queries to preserve rate limits, with optional GitHub Personal Access Token support for elevated quotas (up to 5,000 req/hr).

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
| **Localization** | `intl` & `flutter_localizations` | 22 supported languages |
| **Assets & Icons** | `flutter_svg` | Vector icons and brand assets |

---

## Build from Source

### Prerequisites

- Flutter SDK 3.13+
- Android SDK & NDK configured
- Java 17+

### Build Steps

```bash
# Clone the repository
git clone https://github.com/zerabyte88/kontri.git
cd kontri

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
