# GitPulse Mobile

<p align="center">
  <img src="assets/icons/app_icon.jpg" alt="Phantek Icon" width="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />
</p>

<div align="center">
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android&color=059669&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Architecture&message=arm64-v8a&color=7c3aed&style=for-the-badge&logo=arm&logoColor=white&labelColor=0f172a" alt="Architecture" />
  <img src="https://img.shields.io/static/v1?label=Application%20ID&message=com.phantek.orion.rigel&color=6366f1&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Application ID" />
  <a href="https://github.com/zerabyte88/gitpulse_mobile/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.4.4&color=2563eb&style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=MIT&color=475569&style=for-the-badge&logo=open-source-initiative&logoColor=white&labelColor=0f172a" alt="License" /></a>
</div>

<br/>

**GitPulse Mobile** is an on-device developer telemetry, 24-hour activity rhythm, and GitHub productivity analytics application for Android. Built with Flutter and powered by hardware-accelerated charting via `fl_chart`, it transforms raw GitHub REST API v3 payloads into intuitive developer rhythms, cumulative portfolio impact telemetry, and habit-based commit tiers. Engineered for performance and privacy, all data processing, charting, and storage occur **100% on-device** with zero intermediary proxy servers.

---

## Key Features

### 1. 24-Hour Productivity Rhythm & Diurnal Analytics
- **Local Timezone Binning:** Converts UTC event timestamps from the GitHub API into the user's local device timezone (00:00–23:00).
- **Hardware-Accelerated Histogram:** Renders an interactive 24-bar activity histogram using `fl_chart` to reveal peak engineering hours and temporal workflow patterns.
- **Diurnal Distribution Analysis:** Identifies whether a developer operates as an early bird, mid-day builder, or late-night committer based on live event frequency.

### 2. Language Footprint & Portfolio Analytics
- **Weighted Language Distribution:** Multi-language donut chart weighted by repository codebase volume with authentic GitHub language colors.
- **Portfolio Telemetry Aggregation:** Real-time summation of cumulative stargazers, forks, repository counts (original vs. forked), and follower ratios.
- **Sliver Virtualization:** Butter-smooth fluid scrolling across 100+ repositories using `CustomScrollView` and `SliverList.builder`.

### 3. Native In-App Repository Explorer & Code Viewer
- **Instant In-App Inspection:** Tap any repository from a user's portfolio or the news feed to open it directly inside the app—no external browser redirect required.
- **Dual-Tab Experience:** Seamlessly toggle between **README** documentation and the **Files** codebase tree.
- **Interactive Directory Tree:** Browse nested folders and subdirectories with custom breadcrumbs and type-specific folder/file iconography (`GitHubContentItem`).
- **Syntax-Highlighted In-App File Viewer:** Inspect source files directly with line numbering, file size metadata, character counts, and quick actions to copy code or open on GitHub (`FileViewerScreen`).

### 4. Rich Markdown Engine with Theme-Adaptive Assets
- **Automatic Relative Asset Resolution:** Automatically resolves relative paths (e.g., `./assets/preview.png`, `docs/architecture.svg`) against GitHub's raw CDN (`raw.githubusercontent.com/<owner>/<repo>/<branch>/`).
- **Dark/Light Theme Adaptive Images:** Supports GitHub context markers such as `#gh-dark-mode-only` and `#gh-light-mode-only` matching the user's active theme.
- **Precision Typography:** Renders badges, tables, task lists, blockquotes, and fenced code blocks with pixel-perfect on-device typography.

### 5. Commit Activity Tier Engine & Dynamic Visuals
- **6-Level Animated Tier Badges:** Continuous streak and annual contribution volume ranking with custom canvas shaders (`Mythic Archmage`, `Diamond Vanguard`, `Platinum Artisan`, `Gold Adventurer`, `Silver Explorer`, `Bronze Novice`).
- **Full-Screen Dynamic Ambient Background:** GPU-accelerated continuous looping canvas across the entire application viewport tailored to each active theme:
  - **Dark Mode (Snowfall & Winter Village Night ❄️):** Rolling winter snow hills, pine silhouettes, warm illuminated cabin windows, and continuous floating snowfall particles with 100% seamless mathematical loop continuity.
  - **AMOLED (Pure Black Cosmos 🌌):** Starry cosmos with twinkling diamond stars, glowing crescent moon, and continuous full-screen staggered meteor shower (6 meteors crossing edge-to-edge).
  - **AMOLED Sakura (Radiant Pink 🌸):** Artistic sumi-e sakura boughs, drifting cherry blossom petals, and an ethereal full moon repositioned below the header to guarantee crystal-clear title readability.
  - **Light Mode (Solar Horizon & Prismatic Breeze ☀️):** Luminous ceramic dawn sky with flowing topographic horizon ribbons, drifting prismatic daylight motes, and soft breathing komorebi sunbeams.
- **Bespoke GitPulse Vector Logo:** Intertwines Git branch topology, cardiac ECG heartbeat waveform, and a traveling electric energy spark (`GitPulseLogo`).
- **Developer Easter Egg:** Tap the AMOLED card **10 times in rapid succession** in Settings to unlock the hidden AMOLED Sakura mode.

### 6. Over-The-Air (OTA) Updates & Safe Storage Cleanup
- **Automated GitHub Releases Updater:** In-app version verification, background APK download with live progress bar via `ota_update`, and automated installation dispatch via Android `PackageInstaller`.
- **Targeted Safe Deletion Guard:** Scans `/Download/GitPulse/` upon startup and purges only matching GitPulse APKs where `fileVersion <= currentVersion`. User photos, documents, and other downloads remain completely untouched.

### 7. Multi-Language Internationalization & Privacy
- **22 Supported Global Languages:** Complete translation coverage switchable on-the-fly without app restarts, sorted alphabetically (A–Z) in the settings selector:
  - 🇺🇸 English (`en`) - Default on first install
  - 🇮🇩 Indonesian (`id`)
  - 🇲🇾 Malay (`ms`)
  - 🇩🇰 Danish (`da`)
  - 🇩🇪 German (`de`)
  - 🇪🇸 Spanish (`es`)
  - 🇫🇷 French (`fr`)
  - 🇮🇹 Italian (`it`)
  - 🇳🇱 Dutch (`nl`)
  - 🇳🇴 Norwegian (`no`)
  - 🇵🇹 Portuguese (`pt`)
  - 🇫🇮 Finnish (`fi`)
  - 🇸🇪 Swedish (`sv`)
  - 🇻🇳 Vietnamese (`vi`)
  - 🇷🇺 Russian (`ru`)
  - 🇸🇦 Arabic (`ar`)
  - 🇮🇳 Hindi (`hi`)
  - 🇹🇭 Thai (`th`)
  - 🇯🇵 Japanese (`ja`)
  - 🇨🇳 Simplified Chinese (`zh_Hans`)
  - 🇹🇼 Traditional Chinese (`zh_Hant`)
  - 🇰🇷 Korean (`ko`)
- **Default English Language:** Initializes with English (`en`) on fresh installation for international accessibility, while respecting user manual language selection across sessions.
- **Anti-Truncation & Localization Integrity:** Complete dictionary audits across all 22 supported locales ensuring UI labels, buttons, headers, and "Favorite Profile" strings render cleanly without clipping or ellipsis cutoff across all screen densities.
- **Smart Rate-Limit Interceptor:** Strongly-typed handler for HTTP 403, 429, and exhausted rate limits with optional Personal Access Token (PAT) support stored in Android's private app sandbox.
- **Zero Intermediary Servers & Total Privacy:** Direct device-to-GitHub TLS 1.3 queries with zero analytics SDKs, trackers, or telemetry scripts.

### 8. Dedicated Favorite Profiles Grid & Adaptive Layout
- **Streamlined 1–2 Column Density:** Modern interactive segmented control pill enabling instant switching between 1 column (wide developer ID banner) and 2 columns (balanced dual-card grid) with optimized aspect ratios (`2.9` and `0.88`).
- **Persistent Grid Layout Preferences:** User-selected column density is saved automatically to device storage via `SharedPreferences`.
- **Modern Developer ID Cards & Visual States:** Displays developer avatar, full name, GitHub handle, bio, location, and follower counts with clean minimalist styling, ripple touch feedback, and inline mini loading spinners.
- **Direct Telemetry Inspection & Undo Action:** Tap any favorited card to instantly load full analytics in `StatsDetailScreen`, or remove with an undoable floating SnackBar action.
- **Silent Background Enrichment:** Automatically fetches missing location and bio details from GitHub REST API in the background for older bookmarks.
- **Radial Empty State Illustration:** Polished centered illustration and welcoming prompt when no profiles are currently favorited.

### 9. Customizable Surface Opacity & Pure Alpha Transparency
- **Real-Time Surface Opacity Slider:** Interactive slider (50% – 100%, default 100%) in Settings with a live percentage badge, giving users full control over background bleed-through.
- **Pure Alpha Color Transparency (`GlassCard`):** Custom reusable container component utilizing direct alpha color calculation (`withValues(alpha: opacity)`) with zero `BackdropFilter` or `saveLayer` overhead. Completely eliminates GPU offscreen render-pass bottlenecks, guaranteeing butter-smooth 60/120 FPS scrolling across all opacity levels.
- **App-Wide Ambient Persistence:** Background particle loops persist continuously across all screens (Settings, User Profile, Favorite Profiles, Repository Detail, Code Viewer) with lifecycle-aware pausing when minimized to the OS background.

### 10. Modern & Minimalist UI Redesign
- **Stats Detail Screen (`StatsDetailScreen`):** Overhauled with avatar halo glow ring, sleek metadata chips (company, location, blog), minimalist quote bio typography, and custom themed filter dropdown.
- **Favorite Profiles Screen (`FavoriteProfilesScreen`):** Clean segmented pill controls, uncluttered card architecture, and polished developer badges.
- **Dedicated Settings Screen (`SettingsScreen`):** Re-engineered full-screen experience with centered app bar (`centerTitle: true`), symmetrical 2-column theme selection cards with category badges (`DARK`, `AMOLED`, `LIGHT`), surface opacity controls, 22-language A–Z grid, GitHub token manager, and OTA updater telemetry.
- **Route Occlusion Animation Pause:** Ambient canvas background animations automatically pause when entering the settings screen, eliminating unnecessary GPU drawing while configuring preferences.

### 11. Smart Zero-Quota Caching & Conditional Requests Engine
- **Persistent 10-Minute Smart Cache:** Eliminates redundant GitHub API round-trips by caching user profiles, repositories, activity events, and language aggregates in local storage (`StorageService`). Returning to a profile within 10 minutes loads instantaneously with 0 API calls.
- **Conditional HTTP Requests (`ETag` & `304 Not Modified`):** Attaches `If-None-Match: <etag>` headers upon cache expiration. If profile telemetry is unchanged, GitHub responds with `304 Not Modified` without debiting API rate limits (`x-ratelimit-remaining` remains completely untouched).
- **Intelligent Language Query Bypass:** Skips 8–25 repetitive language breakdown calls whenever repositories return 304, protecting the 60 req/hr unauthenticated rate limit.
- **Manual Profile Reload & Pull-to-Refresh:** Includes an AppBar refresh button with loading spinner and full-screen `RefreshIndicator` pull-to-refresh gesture, accompanied by status SnackBars indicating whether updates were pulled or verified up-to-date with zero quota cost.
- **Graceful Offline Fallback:** When network connectivity is lost, cached profiles load immediately with full analytics.

### 12. Real-Time Tech & Open-Source News Feed
- **Multi-Source Developer News (`TechNewsService`):** Curates real-time trending repositories and developer articles directly from GitHub and the Dev.to REST API across 6 distinct categories: **Trending**, **GitHub**, **AI**, **Technology**, **Open Source**, and **Web Dev**.
- **Continuous Sliding Category Capsule Bar:** Interactive horizontal navigation bar with a smooth mathematical sliding indicator capsule (`_calculateCategoryMetrics`) and synchronized swipeable `PageView` transitions.
- **Local Cache & Offline Continuity:** In-memory and disk caching with 15-minute TTL (`StorageService`), providing instant article loading and seamless offline viewing with cached visual status indicators.
- **In-App Article Inspection & External Redirection:** Directly launch repository explorations or read full articles via `url_launcher`.

---

## Commit Activity Tier Matrix

Developers receive a continuous animated tier badge based on their commit streak and annual contribution volume (`ContributionStats.determineTitle`):

| Tier Level | Badge Title | Qualifying Criteria | Real-Time Canvas Shader Effect |
| :--- | :--- | :--- | :--- |
| **Tier 1** | **Mythic Archmage** | `Streak >= 30d` or `Max >= 60d` or `Year >= 500` | 🔮 **Arcane Dragonflame & Rune Sparks**: Multi-hue violet-crimson-gold heatwave shader with orbiting floating magic embers |
| **Tier 2** | **Diamond Vanguard** | `Streak >= 14d` or `Max >= 30d` or `Year >= 200` | ⚡ **Glacial Thunderstorm & Diamond Arc**: Diamond crystal cyan & electric blue lightning arc with high-frequency micro-crackle |
| **Tier 3** | **Platinum Artisan** | `Streak >= 7d` or `Max >= 14d` or `Year >= 60` | ⚔️ **Sacred Emerald Blade Sweep**: Gleaming holy blade light sweep with emerald forge glints and platinum sheen |
| **Tier 4** | **Gold Adventurer** | `Streak >= 3d` or `Max >= 7d` or `Year >= 20` | 🛡️ **Sunburst Guild Crest Radiance**: Warm golden sunfire sweep with radiant adventurer crest glow |
| **Tier 5** | **Silver Explorer** | `This Year > 0` or `Total Contributions > 0` | 🌌 **Moonlit Silver Mist**: Calm ethereal starlight mist wave with gentle cosmic lavender drift |
| **Tier 6** | **Bronze Novice** | *Default / 0 Contributions Recorded* | 🌿 **Living Verdant Dewdrop**: Earthy bronze casing with organic living sprout breath & morning dew gleam |

---

## Architecture and Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Application ID** | `com.phantek.orion.rigel` | Android package identifier |
| **UI Framework** | Flutter 3.24+ (Dart 3.5+) | High-performance cross-platform declarative UI framework |
| **Visual Charts** | `fl_chart` (v1.2.0) | Hardware-accelerated 24h activity histogram and language donut charts |
| **Markdown Engine** | `flutter_markdown` (v0.7.7+1) | Native in-app GitHub README markdown parsing with CDN asset resolution |
| **Networking** | `http` (v1.6.0) | Composable HTTP client for GitHub REST API v3 queries & rate limit tracking |
| **OTA Delivery** | `ota_update` (v7.1.0) | In-app background APK downloader & Android PackageInstaller integration |
| **External Links** | `url_launcher` (v6.3.2) | Seamless browser intents for articles, profiles, and external assets |
| **Vector Graphics** | `flutter_svg` (v2.3.0) | High-performance SVG asset and icon rendering |
| **Release Signing** | Android Signing Config | Standard release pipeline with safe fallback |
| **CI/CD Automation** | GitHub Actions (`workflow_dispatch`) | Manual-only automated release compilation and SHA-256 verification |
| **Typography** | Native Material 3 System Typeface | Instant cold start, zero HTTP network font fetch, adaptive platform typography |
| **Local Persistence** | `shared_preferences` (v2.5.5) | On-device sandboxed key-value store for bookmarks, themes, & preferences |
| **Internationalization** | `intl` (v0.20.3) | Reactive 22-language global localization & date/number formatting |
| **Verification Suite** | `flutter_test` | Comprehensive test coverage (70/70 passing unit and widget tests) |

---

## Build & Compilation

GitPulse Mobile is compiled specifically for modern **64-bit ARM (`arm64-v8a`)** architectures for peak memory and rendering efficiency, eliminating legacy 32-bit and heavy x86 binary overhead.

### Local APK Build Command

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The compiled release APK will be generated at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Signing Configuration
- **CI/CD Pipeline:** Automated release builds and APK generation via GitHub Actions with release signing.
- **Local Builds:** Standard debug signing fallback allows seamless local execution without manual configuration.

---

## License

This project is licensed under the **MIT License**. Please see the [LICENSE](LICENSE) file for full license terms.

---

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a> (Creator & Maintainer)</sub>
</div>
