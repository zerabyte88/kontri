<div align="center">
  <img src="assets/icons/app_icon.png" alt="Kontri Logo" width="120" />

  # Kontri

  **Minimalist GitHub analytics, contribution streaks, and repository explorer for Android.**

  [![Release](https://img.shields.io/badge/Release-v1.2.4-24292f?style=flat-square&logo=github)](https://github.com/zerabyte88/kontri/releases/latest)
  [![Platform](https://img.shields.io/badge/Platform-Android-24292f?style=flat-square&logo=android)](https://github.com/zerabyte88/kontri/releases/latest)
  [![Architecture](https://img.shields.io/badge/Arch-arm64--v8a-24292f?style=flat-square&logo=arm)](https://github.com/zerabyte88/kontri/releases/latest)
  [![Flutter](https://img.shields.io/badge/Flutter-3.13+-24292f?style=flat-square&logo=flutter)](https://flutter.dev)
  [![License](https://img.shields.io/badge/License-MIT-24292f?style=flat-square)](LICENSE)

  [Download APK](https://github.com/zerabyte88/kontri/releases/latest) • [Features](#features) • [Contribution Tiers](#contribution-tiers) • [Tech Stack](#tech-stack) • [Build](#build-from-source)
</div>

---

## Features

- **Activity Telemetry** : Track total contributions, streak counters, language breakdown, and 24-hour activity distribution.
- **Repository Browser** : Inspect repositories, switch branches, browse directory trees, and view source code or Markdown files.
- **Commit Timeline** : View commit history with author info, timestamps, and commit hashes.
- **Contribution Tiers** : 6 badges evaluated over a rolling 365-day active window.
- **Multi-Profile Dashboard** : Pin multiple GitHub user profiles.
- **Tech Feed** : Trending repositories and developer articles from GitHub and Dev.to.
- **AMOLED Themes** : 6 visual themes (*AMOLED Pure*, *Midnight*, *Snowfall*, *Sakura*, *Light*, *Clean Light*) with adjustable glassmorphism translucency.
- **Efficient Caching** : Conditional HTTP querying (`ETag` / 304 Not Modified) with optional Personal Access Token (PAT) support to increase rate limits to 5,000 req/hr.

---

## Contribution Tiers

Evaluated across a rolling **365-day window**. Both thresholds must be met to unlock a tier:

<div align="center">

| Tier | Title | Contributions | Active Days |
| :---: | :---: | :---: | :---: |
| **Tier 1** | Mythic Archmage | ≥ 1,000 | ≥ 200 |
| **Tier 2** | Diamond Vanguard | ≥ 500 | ≥ 130 |
| **Tier 3** | Platinum Artisan | ≥ 250 | ≥ 70 |
| **Tier 4** | Gold Adventurer | ≥ 125 | ≥ 35 |
| **Tier 5** | Silver Explorer | ≥ 50 | ≥ 10 |
| **Tier 6** | Bronze Novice | Default | Default |

</div>

---

## Tech Stack

<div align="center">

| Layer | Package / Tool | Role |
| :---: | :---: | :---: |
| **Framework** | Flutter (Dart SDK `^3.13`) | Core mobile framework |
| **Charts** | `fl_chart` | Activity charts and language distribution |
| **Markdown** | `flutter_markdown` | In-app document and README rendering |
| **Networking** | `http` | GitHub REST v3 & Dev.to API clients |
| **Storage** | `shared_preferences` | Local persistence and query caching |
| **Localization** | `intl`, `flutter_localizations` | Multi-language translation engine |
| **Graphics** | `flutter_svg` | SVG vector icon rendering |

</div>

---

## Build from Source

### Prerequisites

- Flutter SDK `^3.13`
- Android SDK & Java 17+

### Steps

```bash
# Clone repository
git clone https://github.com/zerabyte88/kontri.git
cd kontri

# Install dependencies
flutter pub get

# Build release APK (arm64-v8a)
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Compiled binary: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## License

Distributed under the [MIT License](LICENSE).
