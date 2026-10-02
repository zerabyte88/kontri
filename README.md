# GitPulse Mobile

<div align="center">

<p align="center">
  <img src="https://raw.githubusercontent.com/tandpfun/skill-icons/main/icons/Flutter-Dark.svg" height="52" alt="Flutter" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/tandpfun/skill-icons/main/icons/Dart-Dark.svg" height="52" alt="Dart" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/tandpfun/skill-icons/main/icons/Github-Dark.svg" height="52" alt="GitHub" />
</p>

### Enterprise-Grade Developer Telemetry & Productivity Analytics

[![Release](https://img.shields.io/badge/Release-v1.0.7-blue?style=flat-square)](https://github.com/zerabyte88/gitpulse_mobile/releases)
[![Build](https://img.shields.io/badge/Build-8-brightgreen?style=flat-square)](pubspec.yaml)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.24.0-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5.0-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-10B981?style=flat-square&logo=android&logoColor=white)](https://developer.android.com)
[![CI/CD Status](https://img.shields.io/badge/CI%2FCD-Passing-brightgreen?style=flat-square&logo=githubactions&logoColor=white)](.github/workflows/main.yml)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(31%2F31)-success?style=flat-square)](test/widget_test.dart)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Layered-orange?style=flat-square)](#system-architecture--data-flow)
[![License](https://img.shields.io/badge/License-MIT-8B5CF6?style=flat-square)](LICENSE)

<p align="center">
  <b>GitPulse Mobile</b> is a modern developer telemetry and productivity analytics mobile application built with Flutter. It transforms raw GitHub REST API v3 payloads into 24-hour work rhythm visualizations, cumulative portfolio impact metrics, and deterministic developer persona classifications—processed entirely on-device without third-party intermediary servers.
</p>

<p align="center">
  <a href="#problem-statement--core-value">Problem Statement</a> •
  <a href="#key-features">Key Features</a> •
  <a href="#system-architecture--data-flow">Architecture & Data Flow</a> •
  <a href="#theme-system--secret-easter-egg">Themes & Sakura Mode</a> •
  <a href="#in-app-updater--dedicated-storage-pipeline">In-App Updater & Storage</a> •
  <a href="#developer-persona-classification-matrix">Persona Matrix</a> •
  <a href="#commit-activity-tier-matrix">Tier Animations</a> •
  <a href="#performance--lag-free-optimization">Performance Optimization</a> •
  <a href="#security--privacy-governance">Security</a> •
  <a href="#technology-stack">Tech Stack</a> •
  <a href="#installation--getting-started">Installation</a>
</p>

</div>

---

## Problem Statement & Core Value

The standard GitHub contribution graph ("green squares") displays daily activity frequency, but suffers from fundamental limitations:
- **Absence of Temporal Context**: It does not distinguish whether commits occur at midnight, early dawn, or during core business hours.
- **Fragmented Portfolio Impact**: Users must manually calculate aggregate stargazers and forks scattered across dozens of repositories.
- **Lack of Qualitative Profiling**: It fails to capture an engineer's architectural habits (e.g., deep focus within a single ecosystem vs. polyglot versatility).
- **Update Friction on Mobile**: Open-source APK users typically endure cumbersome manual uninstall and reinstall cycles to update their apps.

**GitPulse Mobile** solves these gaps by aggregating public repository metadata, user profiles, and event streams into a unified, privacy-first, on-device intelligence dashboard with built-in in-app OTA updates, dedicated storage management, smooth 60fps animations, and zero bloat.

---

## Key Features

<table>
  <thead>
    <tr>
      <th width="35%">Feature</th>
      <th width="65%">Technical Specification</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <b>In-App OTA Updater & Dedicated Storage</b><br/>
        <i>Direct Download to <code>/Download/GitPulse</code></i>
      </td>
      <td>
        Queries the GitHub Releases API for semantic version tags. Downloads APK assets in the background with live percentage streaming (<code>ota_update</code>) and saves the primary installer directly into <code>/storage/emulated/0/Download/GitPulse</code>. Triggers the Android Package Installer directly without requiring uninstall/reinstall, fully preserving user tokens, bookmarks, and settings.
      </td>
    </tr>
    <tr>
      <td>
        <b>Post-Install Storage Auto-Cleanup</b><br/>
        <i>Zero Storage Waste with Strict User Data Protection</i>
      </td>
      <td>
        Automatically purges internal update caches upon completion and safely cleans installed GitPulse update packages from <code>/storage/emulated/0/Download/GitPulse</code> once the newer version is launched. Cleans up empty folders automatically and uses strict name/version filters to ensure user documents, photos, and other files remain completely untouched.
      </td>
    </tr>
    <tr>
      <td>
        <b>Harmonized 4-Theme Engine</b><br/>
        <i>OLED, Dark Slate, Light & Sakura Mode</i>
      </td>
      <td>
        - <b>Dark:</b> Deep Midnight Navy/Slate (<code>#0E131F</code>) with Slate surfaces (<code>#171F30</code>) and Electric Sky Cyan (<code>#38BDF8</code>) & Iris Violet (<code>#A78BFA</code>) accents.<br/>
        - <b>AMOLED:</b> True OLED Pure Black (<code>#000000</code>) with obsidian onyx cards (<code>#0C0E12</code>) and vivid Ice Cyan (<code>#00D2FF</code>) accents.<br/>
        - <b>AMOLED Sakura:</b> Pure Black (<code>#000000</code>) with wisteria plum surfaces (<code>#0E0B14</code>), Sakura Blossom Rose (<code>#FF7597</code>), and spring bamboo jade (<code>#4ADE80</code>). Unlocked via 10-tap secret interaction.<br/>
        - <b>Light:</b> Crisp, high-contrast light palette engineered for bright outdoor environments.
      </td>
    </tr>
    <tr>
      <td>
        <b>Zero-Truncation Settings & Dynamic UI</b><br/>
        <i>Full Language & Theme Name Geometry</i>
      </td>
      <td>
        Redesigned language and theme option layouts in settings using a non-squeezing <code>Stack</code> architecture with <code>maxLines: 2</code> and <code>softWrap: true</code>. Language names (such as <i>Bahasa Indonesia</i>) always display 100% in full and are never truncated with ellipsis (<code>...</code>) when selected. All action buttons, theme buttons, and language options in settings feature center-aligned typography.
      </td>
    </tr>
    <tr>
      <td>
        <b>High-Performance Rendering Architecture</b><br/>
        <i>Jank-Free 60fps Scrolling & Transitions</i>
      </td>
      <td>
        - <b>Sliver Virtualization:</b> The repository list in <code>StatsDetailScreen</code> is migrated to <code>CustomScrollView</code> + <code>SliverList.builder</code>, eliminating frame drops on profiles with up to 100 repositories.<br/>
        - <b>Sorting Memoization:</b> Repository sorting routines are cached and only recalculated when filter options change.<br/>
        - <b>Repaint Boundary Isolation:</b> Repository cards are isolated with <code>RepaintBoundary</code> to eliminate unnecessary viewport repaints during scroll.<br/>
        - <b>Image Optimization:</b> Tech news image decoding is constrained to <code>cacheWidth: 450</code> with lightweight static placeholders.<br/>
        - <b>In-Memory Caching:</b> In-memory caching for bookmarks and search history in <code>HomeScreen</code> avoids repeated JSON decoding on every frame build.
      </td>
    </tr>
    <tr>
      <td>
        <b>Accurate Rate-Limit & Token Status Detection</b><br/>
        <i>Proactive Error Handling</i>
      </td>
      <td>
        <code>GitHubApiException</code> provides strongly-typed <code>isRateLimit</code> and <code>statusCode</code> flags. Precisely intercepts HTTP 403, 429, and <code>x-ratelimit-remaining == 0</code> to display clear, educational messages indicating that the token/API quota has expired, rather than erroneous network error prompts.
      </td>
    </tr>
    <tr>
      <td>
        <b>Continuous Tier Animation Engine</b><br/>
        <i>Seamless Organic Particle & Shimmer FX</i>
      </td>
      <td>
        - <b>Tier 1 (Code Titan):</b> Continuous organic flame particle physics with seamless glowing gradient waves.<br/>
        - <b>Tier 2 (Relentless Committer):</b> High-voltage electric plasma arc with continuous off-screen sweep shimmer.<br/>
        - <b>Tier 3 (Consistent Builder):</b> Emerald cyber matrix sweep with smooth continuous illumination.<br/>
        - <b>Tier 4 (Weekend Warrior):</b> Solar amber sunburst shimmer with continuous angular gleam.<br/>
        - <b>Tier 5 (Dormant Explorer):</b> Cosmic starlight nebula drift with gentle pulsing star dust.<br/>
        - <b>Tier 6 (Fresh Sprout):</b> Spring dewdrop bloom pulse with organic respiratory scale.
      </td>
    </tr>
    <tr>
      <td>
        <b>GitHub Trending & Curated Tech News</b><br/>
        <i>Ecosystem & Trending Repositories</i>
      </td>
      <td>
        Fetches top trending open-source GitHub repositories via GitHub Search API alongside curated engineering articles from dev.to. Supports category filter chips (<b>Trending</b>, <b>All</b>, <b>GitHub</b>, <b>Web Dev</b>) with offline fallback data and external browser navigation.
      </td>
    </tr>
    <tr>
      <td>
        <b>Multi-Language Localization (i18n)</b><br/>
        <i>6 International Languages</i>
      </td>
      <td>
        Full native translation coverage across 6 languages: <b>Bahasa Indonesia</b>, <b>English</b>, <b>日本語 (Japanese)</b>, <b>한국어 (Korean)</b>, <b>简体中文 (Simplified Chinese)</b>, and <b>繁體中文 (Traditional Chinese)</b>, switchable on-the-fly without restarting the app.
      </td>
    </tr>
    <tr>
      <td>
        <b>24-Hour Productivity Rhythm</b><br/>
        <i>Peak Coding Hours Detection</i>
      </td>
      <td>
        Maps public event streams into an interactive 24-bar histogram using <code>fl_chart</code>. Automatically converts UTC timestamps to local device time (00:00–23:00) to pinpoint when an engineer is most active in commits, PRs, and reviews.
      </td>
    </tr>
    <tr>
      <td>
        <b>Deterministic Developer Persona Engine</b><br/>
        <i>Rule-Based Qualitative Profiling</i>
      </td>
      <td>
        Evaluates quantitative telemetry against a deterministic heuristic matrix to classify developers into specialized professional personas (e.g., Star Magnet, Midnight Owl, Polyglot Architect).
      </td>
    </tr>
    <tr>
      <td>
        <b>Language Footprint Distribution</b><br/>
        <i>Interactive Multi-Language Donut Chart</i>
      </td>
      <td>
        Renders a donut chart illustrating primary programming languages across non-forked public repositories, weighted by repository size or codebase volume using authentic ecosystem colors.
      </td>
    </tr>
    <tr>
      <td>
        <b>Consolidated Portfolio Aggregator</b><br/>
        <i>Cross-Repository Impact Metrics</i>
      </td>
      <td>
        Aggregates cumulative stargazers, total forks, public repository counts (original vs. forked), and follower ratios without external database dependencies.
      </td>
    </tr>
  </tbody>
</table>

---

## System Architecture & Data Flow

GitPulse Mobile follows **Clean Layered Architecture** principles to separate concerns, enforce testability, and isolate business logic from presentation and transport protocols:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   PRESENTATION LAYER                                   │
│       (Flutter 3 • 4-Mode Reactive Theme • 6-Language i18n • Inter Google Fonts)       │
│                                                                                        │
│   ┌───────────────────────────┐                     ┌──────────────────────────────┐   │
│   │        HomeScreen         │                     │      StatsDetailScreen       │   │
│   ├───────────────────────────┤                     ├──────────────────────────────┤   │
│   │ • Search Input Field      │                     │ • Full Name & Tier Title Wrap│   │
│   │ • In-Memory Bookmarks     │                     │ • 24h Activity Histogram     │   │
│   │ • GitHub Token Modal      │                     │ • Language Distribution Donut│   │
│   │ • 4-Theme Selection Grid  │                     │ • Virtualized Sliver Repos   │   │
│   │ • In-App OTA Updater Card │                     │ • Memoized Repo Sorting      │   │
│   │ • Lightweight News Feed   │                     │ • Persona Badge & Telemetry  │   │
│   │ • Live Avatar Settings    │                     │ • Stargazer & Fork Metrics   │   │
│   └─────────────┬─────────────┘                     └──────────────▲───────────────┘   │
└─────────────────┼──────────────────────────────────────────────────┼───────────────────┘
                  │ 1. Search Query / Theme / Update Event           │ 5. Aggregated UI State
                  ▼                                                  │
┌────────────────────────────────────────────────────────────────────┴───────────────────┐
│                                   DOMAIN & LOGIC LAYER                                 │
│                                                                                        │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │                              UserStats Calculation Engine                      │   │
│   │  • Metric Aggregator (Total Stars, Forks, Repo Volume, Primary Languages)      │   │
│   │  • 24-Hour Event Binner (Converts ISO-8601 UTC to Local Time 00:00–23:00)      │   │
│   │  • Deterministic Persona Classifier (Star Magnet, Midnight Owl, Polyglot, etc.)│   │
│   ├────────────────────────────────────────────────────────────────────────────────┤   │
│   │                              UpdateService & OTA Engine                        │   │
│   │  • Semantic Version Comparator (e.g., v1.0.7 > v1.0.6)                         │   │
│   │  • PackageInstaller Stream & Primary APK in /Download/GitPulse                 │   │
│   │  • Safe Auto-Cleanup Routine for Installed APKs & Empty Directories            │   │
│   ├────────────────────────────────────────────────────────────────────────────────┤   │
│   │                              AppLanguageService & AppThemeService              │   │
│   │  • 6-Language Reactive Notifier & 4-Mode Theme State Machine                   │   │
│   │  • 10x Tap Secret Easter Egg Evaluator & Persistence Controller                │   │
│   └────────────────────────────────────────▲───────────────────────────────────────┘   │
└────────────────────────────────────────────┼───────────────────────────────────────────┘
                                             │ 4. Deserialized Models (User, Repos, Events)
┌────────────────────────────────────────────┴───────────────────────────────────────────┐
│                                  DATA & PERSISTENCE LAYER                              │
│                                                                                        │
│   ┌───────────────────────────────────┐            ┌───────────────────────────────┐   │
│   │    GitHubApiService & TechNews    │            │        StorageService         │   │
│   ├───────────────────────────────────┤            ├───────────────────────────────┤   │
│   │ • GET /users/{username}           │            │ • SharedPreferences Engine    │   │
│   │ • GET /users/{username}/repos     │            │ • Persistent Bookmark Cache   │   │
│   │ • GET /users/{username}/events    │            │ • Sandboxed GitHub PAT Secret │   │
│   │ • GET /repos/.../releases/latest  │            │ • Theme Preference Persistence│   │
│   │ • Trending Repositories API       │            │ • Sakura Theme Secret State   │   │
│   │ • Dual Rate Limit (60 vs 5,000/hr)│            │ • Selected Language Code (i18n│   │
│   │ • Strongly-Typed isRateLimit Flag │            │ • In-Memory Cache Optimization│   │
│   └─────────────────┬─────────────────┘            └───────────────▲───────────────┘   │
└─────────────────────┼──────────────────────────────────────────────┼───────────────────┘
                      │ 2. HTTPS / TLS 1.3 Requests                  │ 3. Read / Write Cache
                      ▼                                              ▼
┌───────────────────────────────────────────┐  ┌─────────────────────────────────────────┐
│          GitHub REST API v3               │  │           Device Local Storage          │
│       (api.github.com Endpoints)          │  │        (Android Sandbox / Files)        │
└───────────────────────────────────────────┘  └─────────────────────────────────────────┘
```

---

## Theme System & Secret Easter Egg

GitPulse Mobile features a centralized `AppThemeService` paired with dynamic color tokens in `AppTheme`, allowing instantaneous runtime switching without requiring an app restart:

1. **Dark (`dark`)**: Deep Midnight Navy/Slate (`#0E131F` background, `#171F30` cards, `#1E293B` elevated surfaces, Electric Sky Cyan `#38BDF8`, and Iris Violet `#A78BFA` accents).
2. **AMOLED (`amoled`)**: True OLED Pure Black (`#000000` background, `#0C0E12` surface) engineered for OLED/AMOLED power savings, vivid Ice Cyan (`#00D2FF`), and softened off-white text (`#F8FAFC`).
3. **Light (`light`)**: High-contrast GitHub Light palette (`#F6F8FA` background, `#FFFFFF` cards, GitHub Light Blue `#0969DA`).
4. **AMOLED Sakura (`amoledJapanese`)**: Aesthetic Japanese floral cyberpunk (`#000000` background, Wisteria Plum `#0E0B14`, Sakura Blossom Rose `#FF7597`, Spring Bamboo Jade `#4ADE80`, and Sakura Snow text `#FFF1F5`).

### 🌸 How to Unlock the Secret AMOLED Sakura Mode:
1. Open **Settings** (gear icon in the top-right corner).
2. Locate the **Theme** section.
3. Rapidly tap the **AMOLED** option **10 times**.
4. On the 10th tap:
   - Haptic vibration feedback triggers.
   - A celebratory toast appears: *"AMOLED Sakura Mode Activated! ✨"*.
   - The theme immediately switches and is permanently stored in device preferences.

---

## In-App Updater & Dedicated Storage Pipeline

```text
[Settings: "Check for Updates" or Auto-Check]
                    │
                    ▼
       1. GitHub Releases API Query
   (api.github.com/repos/zerabyte88/gitpulse_mobile/releases/latest)
                    │
                    ▼
       2. Semantic Version Comparator
         (Compares Tag e.g. v1.0.7 vs Installed v1.0.6)
                    │
       ┌────────────┴────────────┐
       ▼                         ▼
Already Up-to-Date       New Version Available!
 "Already up to date"            │
                                 ▼
                         3. Extract APK Asset URL
                         (e.g., GitPulse-v1.0.7.apk)
                                 │
                                 ▼
                         4. Background Download Stream
                            (Live Progress: 0% ──► 100%)
                                 │
                 ┌───────────────┼───────────────┐
                 ▼               ▼               ▼
       [Native PackageInstaller] [Direct Storage] [Fallback: Browser]
       Directly overwrites APK   Saves primary APK to Opens release asset in
       in-place (data preserved) /Download/GitPulse   external browser
                 │               │
                 └───────┬───────┘
                         ▼
             [Auto-Cleanup Routine]
             Automatically cleans internal cache & deletes
             installed GitPulse-*.apk on startup (user files safe)
```

- **In-Place Upgrade**: Directly upgrades the app without requiring an uninstall, keeping tokens, bookmarks, and preferences completely intact.
- **Dedicated `/Download/GitPulse` Folder**: The primary downloaded APK file is automatically saved into `/storage/emulated/0/Download/GitPulse/GitPulse-v1.0.7.apk`.
- **Post-Install Storage Auto-Cleanup**: Once the app launches on the updated version, installed APK packages are automatically purged and empty folders are removed, with zero risk to user documents or personal media.
- **Browser Fallback**: If system installer permissions are restricted by OEM device policies, a dedicated button opens the release asset directly in the system browser.

---

## Developer Persona Classification Matrix

| Persona | Evaluation Criteria | Characteristic Profile |
| :--- | :--- | :--- |
| **Star Magnet** | `Total Stars >= 100` | Exceptional community impact with widely acknowledged open-source repositories. |
| **Polyglot Architect** | `Unique Languages >= 4` | Broad technological breadth across distinct ecosystems, languages, and paradigms. |
| **Midnight Owl Coder** | `Night Events (22:00–04:59) > Morning & Afternoon` | Highest engineering focus and productivity occur during late-night hours. |
| **Early Bird Developer** | `Morning Events (05:00–11:59) > Afternoon & Night` | Consistent early-morning execution rhythm with high-clarity morning commits. |
| **Prolific Builder** | `Total Public Repositories > 20` | High-output builder continuously creating, prototyping, and shipping code. |
| **Dedicated Craftsman** | *Default Fallback Condition* | Consistent, methodical contributor dedicated to quality software craftsmanship. |

---

## Commit Activity Tier Matrix

Each developer profile is assigned an activity tier based on public commit volume over recent event history, with tailored particle physics and shader effects:

| Tier Level | Title Badge | Commits | Visual Animation FX | Motif |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | **Code Titan** | 100+ | Autonomous floating flame particle physics (`CustomPainter`) with radiant gradient sweep | 🔥 Blazing Fire & Magma |
| **Tier 2** | **Relentless Committer** | 50–99 | High-voltage electric plasma arc with lightning shockwave crackle & micro-sparkles | ⚡ Electric Plasma Arc |
| **Tier 3** | **Consistent Builder** | 25–49 | Emerald cyber matrix sweep with digital scanline data stream | 💻 Emerald Cyber Matrix |
| **Tier 4** | **Weekend Warrior** | 10–24 | Solar amber sunburst shimmer with rotating angular gleam | ☀️ Solar Amber Gleam |
| **Tier 5** | **Dormant Explorer** | 1–9 | Cosmic starlight nebula drift with gentle pulsing star dust | ✨ Starlight Nebula |
| **Tier 6** | **Fresh Sprout** | 0 | Spring dewdrop bloom pulse with gentle organic scale respiration | 🌱 Spring Dewdrop |

---

## Performance & Lag-Free Optimization

The application is engineered to maintain buttery-smooth responsiveness even on low-spec hardware:
1. **Sliver List Virtualization**: The repository list utilizes `CustomScrollView` + `SliverList.builder`. Repositories are instantiated and rendered only when entering the viewport, massively conserving memory.
2. **Memoized Repository Sorting**: Repository sorting routines are cached and recomputed only when the active filter or repository list changes, preventing redundant calculations during route transition animations.
3. **Repaint Boundary Isolation**: Each `RepoTile` card is isolated within a `RepaintBoundary` so that list scrolling does not trigger repaints across the surrounding screen tree.
4. **Tech News Image Optimization**: Feed image decoding is strictly clamped to `cacheWidth: 450` and rotating spinners are replaced with lightweight static icon placeholders, significantly reducing GPU pressure.
5. **In-Memory Caching**: Bookmarked profiles and recent searches are cached in memory after reading from disk, avoiding repeated JSON decoding passes on every `build()` frame.

---

## Security & Privacy Governance

GitPulse Mobile is engineered around a **Privacy-First** ethos:

1. **Direct Client-to-API Communication**: All HTTPS transactions occur directly between the user's device and official GitHub endpoints (`api.github.com`) using TLS 1.3. No third-party proxy or intermediary server is involved.
2. **Sandboxed Personal Access Token (PAT)**: Optional GitHub tokens are stored solely in the application's internal sandboxed storage (`shared_preferences`). Tokens are never sent to external telemetry servers.
3. **Least Privilege Enforcement**: The application operates exclusively with read permissions on public data. No write scopes or private repository permissions are requested.
4. **Zero Third-Party Telemetry**: Contains no third-party tracking scripts, advertising SDKs, or invasive user analytics.
5. **Safe In-App Updates**: APKs are fetched directly from GitHub Releases (`api.github.com`) over secure TLS connections and verified against Android package signatures.

---

## Technology Stack

| Category | Technology | Version | Architectural Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) | `>=3.24.0` | High-performance Ahead-Of-Time (AOT) cross-platform compilation for Android and Web |
| **Language** | [Dart](https://dart.dev) | `>=3.5.0` | Sound null-safety, pattern matching, and structured concurrency |
| **In-App Updater** | [ota_update](https://pub.dev/packages/ota_update) | `^7.1.0` | Background native Android PackageInstaller OTA update streaming |
| **Visualization** | [fl_chart](https://pub.dev/packages/fl_chart) | `^1.2.0` | Hardware-accelerated vector charting engine with touch interactions |
| **Networking** | [http](https://pub.dev/packages/http) | `^1.6.0` | Robust composable HTTP client for RESTful API communication |
| **Typography** | [google_fonts](https://pub.dev/packages/google_fonts) | `^8.2.1` | Professional, high-legibility Inter font family |
| **Persistence** | [shared_preferences](https://pub.dev/packages/shared_preferences) | `^2.5.5` | Platform-native encrypted key-value storage abstraction |
| **Formatting** | [intl](https://pub.dev/packages/intl) | `^0.20.3` | ISO 8601 timezone manipulation and localized number formatting |
| **Deep Linking** | [url_launcher](https://pub.dev/packages/url_launcher) | `^6.3.2` | External browser navigation for repository links and articles |
| **Code Quality** | [flutter_lints](https://pub.dev/packages/flutter_lints) | `^6.0.0` | Official Flutter linter ruleset for idiomatic Dart standards |

---

## Project Directory Structure

```text
gitpulse_mobile/
├── .github/
│   └── workflows/
│       └── main.yml                 # Unified CI/CD (Test, 64-bit APK Build & Release)
├── android/                         # Android platform host files (Gradle, Manifests)
├── lib/
│   ├── main.dart                    # Application entrypoint & auto-cleanup initialization
│   ├── localization/                # Multi-language internationalization support
│   │   ├── app_language.dart        # Supported language enums & locales (6 languages)
│   │   └── app_localizations.dart   # Comprehensive translation dictionaries
│   ├── models/                      # Domain entities & analytical computation engines
│   │   ├── bookmarked_user.dart     # Bookmarked profile serialization model
│   │   ├── contribution_stats.dart  # Event activity & commit habit tier models
│   │   ├── github_rate_limit.dart   # API rate-limit state tracking model
│   │   ├── github_repo.dart         # Repository schema deserializer
│   │   ├── github_user.dart         # User profile schema deserializer
│   │   ├── tech_news.dart           # Tech news & GitHub trending item model
│   │   └── user_stats.dart          # Core telemetry calculation & persona engine
│   ├── screens/                     # UI screens & controllers
│   │   ├── home_screen.dart         # Search, bookmarks, trending news & version badge
│   │   └── stats_detail_screen.dart # Interactive analytics dashboard (Virtualized Sliver)
│   ├── services/                    # Networking & persistent storage layer
│   │   ├── app_language_service.dart# Language preference manager (6 languages)
│   │   ├── app_theme_service.dart   # Reactive 4-mode theme notifier & easter egg unlocker
│   │   ├── github_api_service.dart  # GitHub REST API v3 client with error handling
│   │   ├── storage_service.dart     # SharedPreferences persistence wrapper
│   │   ├── tech_news_service.dart   # Curated tech news & GitHub trending fetcher
│   │   └── update_service.dart      # Semantic version check, OTA download & auto-cleanup
│   ├── theme/                       # Design system tokens & application metadata
│   │   └── app_theme.dart           # 4-theme color definitions, typography & AppConfig (v1.0.7)
│   └── widgets/                     # Modular reusable UI components
│       ├── activity_chart.dart      # 24-hour activity bar chart (fl_chart)
│       ├── animated_app_header.dart # Themed dynamic logo & title particle animations
│       ├── animated_tier_title.dart # Level-tailored animated status badge (Tiers 1-6)
│       ├── language_chart.dart      # Language distribution donut chart (fl_chart)
│       ├── repo_tile.dart           # GitHub native repository card (RepaintBoundary)
│       ├── settings_sheet.dart      # Modal sheet for theme, updates, PAT, & About
│       ├── stat_card.dart           # Summary metric card (stretch-aligned, auto-wrapped)
│       └── tech_news_card.dart      # Engineering digest & trending card widget
├── test/
│   └── widget_test.dart             # Complete unit, model, and OTA update test suite (31 tests)
├── web/                             # Web/PWA deployment entrypoint
└── pubspec.yaml                     # Dependency manifest & version metadata (v1.0.7+8)
```

---

## Installation & Getting Started

### Prerequisites
- **Flutter SDK**: Version `3.24.0` or higher
- **Dart SDK**: Version `3.5.0` or higher
- **Java Development Kit (JDK)**: OpenJDK 17
- **Target Device**: Physical Android device with USB debugging enabled, Android Emulator (API 28+), or Google Chrome

### Step-by-Step Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/zerabyte88/gitpulse_mobile.git
   cd gitpulse_mobile
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Static Analysis & Unit Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch the Application**:
   - For Google Chrome (Web):
     ```bash
     flutter run -d chrome
     ```
   - For Android Device / Emulator:
     ```bash
     flutter run -d android
     ```

5. **Build Release APK (64-bit ARM Only)**:
   ```bash
   flutter build apk --release --target-platform android-arm64
   # Compiled binary output: build/app/outputs/flutter-apk/app-release.apk
   ```

---

## CI/CD Pipeline & GitHub Releases

This repository utilizes a unified GitHub Actions pipeline (`.github/workflows/main.yml`):

1. **Automated Quality Gate & Binary Compilation**:
   - Triggers on every push and pull request to `main` and `master`.
   - Runs `flutter pub get`, `flutter analyze` (zero lint warnings), and `flutter test` (**24/24 tests passing**).
   - Compiles **strictly 64-bit ARM APK** (`--target-platform android-arm64`, with `arm64-v8a` ABI filter).
   - Generates SHA-256 checksums (`.sha256`) and attaches artifacts directly to the workflow run summary for immediate download.

2. **Automated & Manual Release Publishing**:
   - Triggered either **manually via `workflow_dispatch`** or automatically when pushing release tags (`v*`).
   - Packages and publishes the release bundle directly to **GitHub Releases**, ready for instant consumption by the In-App OTA Updater.

---

## License

This project is open-source software licensed under the [MIT License](LICENSE).

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a> (Creator & Maintainer)</sub>
</div>
