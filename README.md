# GitPulse Mobile

<p align="center">
  <img src="assets/icons/app_icon.jpg" alt="GitPulse Icon" width="100" style="border-radius: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.2);" />
</p>

<p align="center">
  <a href="https://github.com/zerabyte88/gitpulse-mobile/releases"><img src="https://img.shields.io/badge/version-v2.5.0-00e5ff?style=flat&logo=github&logoColor=white&labelColor=0d1117" alt="Version" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/flutter-%5E3.13-02569b?style=flat&logo=flutter&logoColor=white&labelColor=0d1117" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/dart-%5E3.5-0175c2?style=flat&logo=dart&logoColor=white&labelColor=0d1117" alt="Dart" /></a>
  <img src="https://img.shields.io/badge/platform-Android-3ddc84?style=flat&logo=android&logoColor=white&labelColor=0d1117" alt="Platform" />
  <img src="https://img.shields.io/badge/arch-arm64--v8a-8b5cf6?style=flat&logo=arm&logoColor=white&labelColor=0d1117" alt="Architecture" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-64748b?style=flat&logo=open-source-initiative&logoColor=white&labelColor=0d1117" alt="License" /></a>
</p>

<br/>

**GitPulse Mobile** is an Android application built with Flutter that provides GitHub profile statistics, contribution analytics, and repository exploration directly from your mobile device.

---

## Features

- **Profile & Activity Analytics**: Displays total contributions, current and longest commit streaks, language distribution, and a 24-hour activity chart adjusted to your local timezone.
- **Repository Explorer & Code Viewer**: Inspect public repositories, browse nested folder trees, view Markdown README files with image support, and read source files with line numbers.
- **Contribution Tiers**: Gamified achievement badges based on annual contributions and streak consistency.
- **Favorite Profiles**: Bookmark GitHub accounts for quick access, with customizable 1- or 2-column layouts.
- **Tech News Feed**: Read trending GitHub repositories and tech articles curated from GitHub and Dev.to.
- **Theme Customization**: 6 themes including AMOLED Snowfall (pure #000000), AMOLED Sakura, Midnight Slate, Light, AMOLED Pure, and Clean Light with adjustable surface transparency and static power-saving mode.
- **API Quota Optimization**: Utilizes local caching (`SharedPreferences`) and HTTP `ETag` conditional requests to conserve GitHub rate limits.
- **In-App Updates (OTA)**: Check and download latest APK releases directly via GitHub Releases.
- **Multi-Language Support**: Supports 22 interface languages, including English and Indonesian.

---

## Contribution Tiers

| Tier | Badge Title | Criteria |
| :--- | :--- | :--- |
| **Tier 1** | Mythic Archmage | $\ge$ 1,000 contributions this year **and** (Streak $\ge$ 30d or Longest Streak $\ge$ 60d) |
| **Tier 2** | Diamond Vanguard | $\ge$ 500 contributions this year **and** (Streak $\ge$ 21d or Longest Streak $\ge$ 45d) |
| **Tier 3** | Platinum Artisan | $\ge$ 250 contributions this year **and** (Streak $\ge$ 7d or Longest Streak $\ge$ 14d) |
| **Tier 4** | Gold Adventurer | $\ge$ 125 contributions this year **or** Streak $\ge$ 14d **or** Longest Streak $\ge$ 21d |
| **Tier 5** | Silver Explorer | $\ge$ 20 contributions this year **or** $\ge$ 30 total contributions |
| **Tier 6** | Bronze Novice | Default status / fewer contributions than Tier 5 |

---

## Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.13) | Cross-platform mobile UI framework |
| **Charts** | `fl_chart` | 24-hour activity histogram and language distribution charts |
| **Markdown** | `flutter_markdown` | In-app README rendering |
| **Networking** | `http` | Communication with GitHub REST API v3 and Dev.to |
| **Local Storage** | `shared_preferences` | On-device key-value persistence for settings and cache |
| **OTA Delivery** | `ota_update` | In-app release downloading and package installation |
| **Vector Graphics** | `flutter_svg` | SVG icons and asset rendering |

---

## Building from Source

### Prerequisites
* [Flutter SDK](https://flutter.dev) (v3.13 or higher)
* Android SDK & NDK configured
* Java 17 or higher

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/zerabyte88/gitpulse-mobile.git
cd gitpulse-mobile

# Fetch dependencies
flutter pub get

# Build release APK for 64-bit ARM devices
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a></sub>
</div>
