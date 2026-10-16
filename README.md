# GitPulse Mobile

<p align="center">
  <img src="assets/icons/app_icon.jpg" alt="GitPulse Icon" width="100" style="border-radius: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.2);" />
</p>

<div align="center">
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android&color=059669&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Architecture&message=arm64-v8a&color=7c3aed&style=for-the-badge&logo=arm&logoColor=white&labelColor=0f172a" alt="Architecture" />
  <img src="https://img.shields.io/static/v1?label=Application%20ID&message=com.phantek.orion.rigel&color=6366f1&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Application ID" />
  <a href="https://github.com/zerabyte88/gitpulse_mobile/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.4.5&color=2563eb&style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=MIT&color=475569&style=for-the-badge&logo=open-source-initiative&logoColor=white&labelColor=0f172a" alt="License" /></a>
</div>

<br/>

**GitPulse Mobile** is an Android application built with Flutter that provides GitHub profile statistics, contribution analytics, and repository exploration directly from your mobile device.

---

## Features

- **Profile & Activity Analytics**: Displays total contributions, current and longest commit streaks, language distribution, and a 24-hour activity chart adjusted to your local timezone.
- **Repository Explorer & Code Viewer**: Inspect public repositories, browse nested folder trees, view Markdown README files with image support, and read source files with line numbers.
- **Contribution Tiers**: Gamified achievement badges based on annual contributions and streak consistency.
- **Favorite Profiles**: Bookmark GitHub accounts for quick access, with customizable 1- or 2-column layouts.
- **Tech News Feed**: Read trending GitHub repositories and tech articles curated from GitHub and Dev.to.
- **Theme Customization**: Dark, AMOLED, Light, and AMOLED Sakura themes, with adjustable surface transparency.
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

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.13 or newer)
- Android SDK with command-line tools

### Build Command

Compile the release APK targeted for 64-bit ARM (`arm64-v8a`):

```bash
flutter pub get
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The compiled release APK will be located at:
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

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
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a> (Creator & Maintainer)</sub>
</div>
