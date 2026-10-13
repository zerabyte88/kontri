# GitPulse Mobile

<p align="center">
  <img src="assets/icons/app_icon.jpg" alt="Phantek Icon" width="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />
</p>

<div align="center">
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android&color=059669&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Architecture&message=arm64-v8a&color=7c3aed&style=for-the-badge&logo=arm&logoColor=white&labelColor=0f172a" alt="Architecture" />
  <img src="https://img.shields.io/static/v1?label=Application%20ID&message=com.phantek.orion.rigel&color=6366f1&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Application ID" />
  <a href="https://github.com/zerabyte88/gitpulse_mobile/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.4.3&color=2563eb&style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" /></a>
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
  - **Dark Mode (Midnight Cyber Aurora 🌌):** Undulating multi-layered aurora curtains, micro cosmic stars, and continuous upward-streaming stardust embers with 100% seamless mathematical loop continuity.
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

### 9. Customizable Surface Opacity & Adaptive Glassmorphism
- **Real-Time Surface Opacity Slider:** Interactive slider (50% – 100%, default 100%) in Settings with a live percentage badge, giving users full control over background bleed-through.
- **Hardware-Accelerated Frosted Glass (`GlassCard`):** Custom reusable glassmorphism component featuring GPU-accelerated `BackdropFilter` (`10px` gaussian blur) when opacity is below 1.0, and automatically bypassing blur filtering at 1.0 (Solid) for smooth, zero-overhead rendering.
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
| **Release Signing** | Android Signing Config | Standard release pipeline with safe fallback |
| **CI/CD Automation** | GitHub Actions (`workflow_dispatch`) | Manual-only automated release compilation and SHA-256 verification |
| **Typography** | Native Material 3 System Typeface | Instant cold start, zero HTTP network font fetch, adaptive platform typography |
| **Local Persistence** | `shared_preferences` (v2.5.5) | On-device sandboxed key-value store for bookmarks, themes, & preferences |
| **Internationalization** | `intl` (v0.20.3) | Reactive 22-language global localization & date/number formatting |
| **Verification Suite** | `flutter_test` | Comprehensive test coverage (69/69 passing unit and widget tests) |

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

# Version History

* ### v2.4.3
  - **Phantek-Gallery Continuous Sliding Capsule Tab Bar (`HomeScreen`):**
    - *Continuous Sliding Capsule Indicator:* Replaced discrete ChoiceChips with a smooth horizontal pill tab bar featuring a hardware-accelerated continuous sliding capsule indicator. Directly driven by `_newsPageController`, the capsule glides and morphs width in real time as the user swipes through categories or taps a tab.
    - *280ms Fluid Tap Motion:* Tap transitions smoothly animate the active category capsule, text cross-fading, and news feed page simultaneously over **280ms `Curves.easeOutCubic`**.
    - *Automatic Center Tracking:* Seamlessly auto-scrolls the horizontal tab bar to keep the selected category centered on screen during page swipes and tab taps.
  - **Theme Typography Restoration & Token Input Anti-Truncation:**
    - *Title Case Theme Branding:* Restored theme identifiers to clean Title Case (`Snowfall`, `Midnight`, `Sakura`, `Daylight`) across all 22 supported languages.
    - *Token Input Anti-Truncation:* Shortened token hint text (`Tempel token (ghp_...)` / `Paste token (ghp_...)`), eliminating text truncation (`...`) on narrow mobile displays while maintaining clear input guidance.
  - **Complete 22 Global Languages Support & A–Z Sorting:**
    - *Full Translation Dictionaries for All 22 Languages:* Implemented complete native translations across all 22 languages (`id, ms, da, de, en, es, fr, it, nl, no, pt, fi, sv, vi, ru, ar, hi, th, ja, zh_Hans, zh_Hant, ko`), resolving untranslated fallback issues when selecting non-primary languages.
    - *Universal Developer Terminology:* Preserved universal Git technical standards (`Repository`, `Commit`, `Fork`, `Stars`, `Branch`, `Pull Request`) across all language packs.
    - *Alphabetical Language Grid:* Sorted the language selection grid alphabetically (A–Z) by English name in Settings for effortless navigation.
  - **Minimalist & Professional Copywriting Refinement:**
    - *Zero-Emoji UI Strings:* Purged informal emojis from app localization text across all 22 languages, establishing clean, distraction-free, and professional interface copy.

* ### v2.4.2
  - **Synchronized Fluid Tab Choreography & Direct Navigation (`HomeScreen`):**
    - Unified category tab switching, chip centering (`Scrollable.ensureVisible`), and dynamic card height adjustments (`ExpandablePageView`) with ease curves.
    - Removed intermediate jumping when tapping distant category tabs, transitioning directly and seamlessly to the target category.
  - **GitHub Token Security & Quota Guidance:**
    - Added dedicated token guidance clarifying 5,000 req/hour rate limit and 100% on-device local storage.

* ### v2.4.1
  - **Phantek Ambient Visuals & Engine Unification:**
    - *Snowfall Village Night (Dark Mode):* 1:1 ambient canvas rendering from Phantek featuring distant rolling snow hills, 3-tier snow-capped pine trees (`_drawSnowyPine`), warm glowing cabins with chimney smoke puffs and window halo pulses (`_drawSnowyCabin`), and 3 varieties of crystalline snowflakes (cross-crystal, soft halo, and snow dots).
    - *Sunlight Flare & Daylight Breeze (Light Mode):* 1:1 ambient canvas rendering from Phantek featuring radiant top-right sunlight flare bloom (`#F59E0B` & `#FBBF24`) and 34 upward-drifting sunlight motes and fresh breeze particles.
    - *100% Seamless Continuous Looping Dynamics:* All particle and celestial trajectories (Snowflakes, Sunlight motes, Sakura petals, Meteors) calibrated with strict integer cycles, eliminating any loop seam, pop-in, or trajectory jump at boundary wrapping.
    - *Buttery Smooth Motion & 12-Second Majestic Pacing:* Extended cycle duration to 12.0 seconds with quantized pacing (`720` steps), ensuring fluid motion and smooth operation while preserving battery life.

* ### v2.4.0
  - **Phantek-Inspired Modern Aesthetics & Global Language Expansion:**
    - *22 Global Languages Support:* Expanded localization engine from 6 to 22 global languages (`id, ms, da, de, en, es, fr, it, nl, no, pt, fi, sv, vi, ru, ar, hi, th, ja, zh_Hans, zh_Hant, ko`), complete with native names, region flags, dynamic fallback keys, and an A–Z sorted selection interface.
    - *Phantek Slate Dark & Slate Light Theme Engine:* Transformed color palettes to match Phantek's modern Slate Dark (`#0F172A` / `#1E293B`) and Slate Light (`#F8FAFC` / `#FFFFFF`) themes alongside AMOLED Pitch Black (`#000000`) and AMOLED Sakura Blossom (`#140D13` / `#F472B6`).
    - *Full-Screen Dedicated Settings Screen (`SettingsScreen`):* Replaced bottom sheet with a dedicated full-screen layout featuring `centerTitle: true`, centered 2-column theme cards with categorized badges (`DARK`, `AMOLED`, `LIGHT`), surface opacity controls, language selector, GitHub API token manager, and about section.
    - *Route Occlusion Animation Pause:* Background canvas animations automatically pause when entering the settings screen, ensuring 0% GPU waste while configuring options.
    - *Zero-Network System Typography Switch:* Completely removed external `google_fonts` network dependency in favor of native Material 3 system typefaces (Roboto / SF Pro), achieving zero-HTTP cold boots and faster initial frame rendering.
    - *Shader Bypass at 100% Surface Opacity:* Default surface opacity updated to 1.0 (Solid), automatically bypassing GPU `BackdropFilter` passes for pristine, smooth rasterization.
    - *Continuous Ambient Background Flow (Scroll & Idle):* Enhanced background canvas to flow seamlessly without stopping during scroll gestures or when idle, leveraging isolated `RepaintBoundary` layers for jitter-free, fluid compositing.

* ### v2.3.2
  - **Bespoke Fluid Page Transitions Engine (`GitPulsePageTransitionsBuilder`):**
    - *Eliminated Transparent Scaffold Ghosting & Text Collision:* Replaced rigid default page transitions with a tailored transition builder engineered specifically for persistent canvas backgrounds and transparent Scaffolds.
    - *Synchronized Fade & Micro-Glide Choreography:* Entering routes fade in smoothly (`0.0 -> 1.0`) with an organic forward glide (`Offset(0.05, 0.0) -> Offset.zero`) using `Curves.easeOutCubic`, while exiting routes cleanly fade out (`1.0 -> 0.0`) with a subtle retreat (`Offset(-0.03, 0.0)`) using `Curves.easeInCubic`.
    - *Seamless Route Switching Across Entire App:* Completely resolves card clashing, text double-exposure, and sudden pop-in glitches when transitioning between Home and Favorite Profiles, Profile Details and Repository Details, and Repository and File Viewer.
  - **High-Refresh-Rate Ambient Background Pacing & GPU Optimization:**
    - *Quantized Frame Pacing (`~30 FPS`):* Quantized `shouldRepaint` ticks in `AnimatedAppBackground` to ~30 FPS intervals over the 8-second animation loop. Skips up to 75% of background canvas repaints, allowing Skia/Impeller to reuse cached Picture layers with zero trigonometrics and zero CPU overhead.
    - *Static Shader Caching:* Cached all dynamic gradient shaders (`_cachedCurtain1-3Shader`, `_cachedRibbon1-3Shader`, `_cachedMoonShader`) by display `Size`. Eliminates up to 360 native shader allocations per second, eliminating GC pauses and preventing thermal throttling.
    - *Trigonometric Path Optimization:* Precomputed top wave coordinates (`yTops`) in aurora curtains, eliminating redundant `math.sin` and `math.cos` calculations for the bottom wave pass.
    - *Foreground RepaintBoundary Layer Isolation:* Wrapped foreground UI tree with `RepaintBoundary` inside `AnimatedAppBackground`, isolating interactive widget tree compositing from the ambient canvas background layer.
    - *Scroll Idle Reset Fix:* Ensured scroll tracking count resets to zero on idle notifications, guaranteeing instant controller pause during active fling/drag gestures for buttery-smooth scrolling.
    - *Settings Sheet BackdropFilter Elimination:* Replaced heavyweight `BackdropFilter` on `SettingsSheet` with optimized `ClipRRect`, and updated switch thumb theming (`activeThumbColor`) to resolve deprecation warnings.

* ### v2.3.1
  - **Comprehensive GPU & Rendering Performance Patch:**
    - *Eliminated BackdropFilter Bottlenecks on Content Cards:* Disabled expensive GPU blur passes (`enableBlur: false`) across `StatCard`, `LanguageChart`, `ActivityChart`, repository Markdown containers, image preview, and detail toolbars while maintaining sleek, translucent glassmorphism aesthetics.
    - *RepaintBoundary Layer Isolation:* Wrapped stat cards and blur-enabled glass surfaces with `RepaintBoundary` to prevent unnecessary canvas repainting during page scroll.
    - *User-Facing Background Animation Toggle:* Added persistent settings toggle in `SettingsSheet` to enable or disable ambient background animations, reducing battery consumption and frame latency on lower-end devices. Fully localized in Indonesian, English, Japanese, Simplified Chinese, Traditional Chinese, and Korean.
    - *Canvas Shader Caching & Trigonometric Loop Reduction:* Cached static linear gradients (`_cachedMidnightBgShader`, `_cachedLightBgShader`) and reduced aurora curtain segment density from 28 to 16 and horizon ribbons from 24 to 14, decreasing trigonometric calculations by ~45% per frame.
    - *Real-Time Scroll Pause Logic:* Enhanced scroll notification listeners to pause background animations immediately on touch scroll updates.
    - *Search Keystroke Rebuild Scoping:* Isolated search field typing via `ValueListenableBuilder<TextEditingValue>`, completely eliminating full-screen re-renders of the home feed, app bar, and news carousel during keyboard typing.

* ### v2.3.0
  - **Zero-Quota Caching & HTTP Conditional Requests Engine:**
    - *10-Minute Persistent Smart Cache:* Implemented intelligent local caching with a 10-minute TTL for GitHub user profiles (`/users/:username`), repositories (`/users/:username/repos`), public events (`/users/:username/events/public`), and aggregated language footprints via `StorageService`. Repeated profile visits within 10 minutes load instantly with zero API calls.
    - *ETag Conditional Requests (`304 Not Modified`):* Persists HTTP `ETag` headers for every queried endpoint. On cache expiration, requests are dispatched with `If-None-Match: <etag>`. When GitHub responds with `304 Not Modified`, local cached data is reused seamlessly and cache TTL is refreshed without reducing the user's GitHub API quota (`x-ratelimit-remaining` remains completely untouched).
    - *Language Aggregation API Bypass:* Skips 8–25 repetitive repository language API requests completely whenever repository endpoints return `304 Not Modified`, drastically preserving rate limits.
    - *Graceful Offline Resilience:* Seamlessly falls back to cached profile telemetry when the device loses network connectivity, preventing error screens and ensuring uninterrupted analytics.
  - **Manual Profile Refresh & Native Pull-to-Refresh:**
    - Added an AppBar reload action button (`Icons.refresh_rounded`) with an active loading spinner in `StatsDetailScreen`.
    - Integrated native full-screen `RefreshIndicator` pull-to-refresh swipe gesture on profile detail views.
    - Added feedback SnackBars across all 6 supported languages notifying users whether profile telemetry was updated (`profileRefreshed`) or verified already up-to-date with zero quota consumption (`profileUpToDate`).

* ### v2.2.0
  - **Complete Modern & Minimalist UI Redesign:**
    - *Stats Detail & Profile Screen (`StatsDetailScreen`):* Overhauled header profile layout with avatar halo glow ring, sleek metadata chips (company, location, blog), minimalist quote bio typography, and custom themed filter dropdown.
    - *Favorite Profiles Screen (`FavoriteProfilesScreen`):* Clean segmented pill control for 1-2 column switching, refined developer ID card layout with ripple touch feedback and anti-truncation, and centered radial empty state illustration.
    - *Settings Sheet (`SettingsSheet`):* Re-engineered Cards 1 through 5 with modern minimalist glassmorphism, accent borders, and clean typography, while preserving the foundational Card 6 About APK card untouched.
  - **Language & Localization Integrity:**
    - Configured English (`en`) as the default language for new app installations.
    - Full localization dictionary audit across all 6 supported languages, ensuring UI headers, buttons, and "Favorite Profile" strings render cleanly without clipping or text truncation across all screen densities.
  - **Customizable Surface Opacity & Adaptive Glassmorphism:**
    - Added a surface opacity slider (50% – 100%, default 85%) with a live percentage badge in the Theme settings card, persisted to device storage.
    - Built reusable `GlassCard` with dynamic `BackdropFilter` (frosted blur `10px`), providing transparent glassmorphism for modal sheets, profile metric cards, charts, and repository file explorer when opacity < 1.0, and automatically bypassing blur filtering at 1.0 for GPU and battery efficiency.
  - **Persistent App-Wide Ambient Canvas Animations:**
    - Background animations (Sakura petals, meteors, rain/lightning, sunny grove) now persist continuously across all screens (Settings, User Profile, Favorite Profiles, Repository Detail, Code Viewer) instead of freezing during in-app navigation.
    - Lifecycle-aware pause via `WidgetsBindingObserver`: canvas animations pause only when the app is placed in the background OS (`AppLifecycleState.paused` / `hidden`), instantly resuming on foreground return.
  - **Fluid News Tab Auto-Centering & Transitions:**
    - Tech news category tab bar dynamically auto-centers the active chip to the exact middle (50%) of the screen upon tapping or swiping with `Scrollable.ensureVisible` and smooth easing curves.
    - Replaced jumpy tab switching with a fluid, synchronized `PageView` experience.

* ### v2.1.0
  - **Overhauled Ambient Canvas Background Animations Across All 4 Themes:**
    - *AMOLED Sakura (Radiant Pink 🌸):* Replaced the thin tree with an organic, majestic Sakura tree with natural bark grain lines and volumetric cherry blossom canopy masses (`volumetric blossom clouds`) featuring layered spring green leaves, rich magenta petal base, soft pink blooms, and sunlit highlight puffs.
    - *AMOLED Night (Starry Cosmos 🌌):* Enhanced diagonal shooting stars into a continuous full-screen multi-meteor shower (6 staggered meteors) crossing edge-to-edge from outside the upper-right canvas completely off the bottom-left boundary without vanishing mid-screen, with radiant glowing heads and smooth tapered gradient trails.
    - *Dark Mode (Thunderstorm ⛈️):* Revamped atmospheric storm visuals with multi-tiered drifting storm clouds, realistic forked branching lightning strikes with dual-stage flashes and ambient illumination, and wind-swept angled rain streaks (~15° tilt) with impact splash ripples.
    - *Light Mode (Sunny Grove 🍃):* Added a fruit tree on the left side with lush canopy foliage, branches, and glossy ripe red apples/cherries with specular shine dots, rolling green grass foothills at the footer with wind-swayed grass tufts, and soft white cumulus clouds drifting across the upper sky.
  - **Global Poppins Typography Migration:** Migrated the app-wide font family from Plus Jakarta Sans to Google Fonts' Poppins across all screens, cards, headers, code detail views, and modal sheets for modern geometric balance and crisp numbers.
  - **Favorite Profiles UI Polish & Interaction Feedback:**
    - Added interactive cyan ripple touch feedback (`splashColor` & `highlightColor`) to favorite profile cards across both `FavoriteProfilesScreen` and `HomeScreen`.
    - Added an inline mini avatar loading spinner overlay when a favorite profile card is tapped while fetching telemetry data before navigating to `StatsDetailScreen`.
    - Streamlined grid layout options to strictly 1 and 2 columns per row with optimized card aspect ratios (`2.9` for single column, `0.88` for double column), removing the crowded 4-column layout.
    - Polished favorite profiles header alignment and wrapped titles in `Flexible` with ellipsis to prevent text overflow across various localized languages and screen sizes.
  - **About GitPulse Card Cleanup:** Removed redundant green version badge in the top right of the About card in `SettingsSheet`, streamlining header presentation while preserving full application version, release build, architecture, and license metadata below.
  - **Smooth PageView Tech News Carousel:** Replaced abrupt animated switcher in home screen tech news with interactive, physics-based `PageView` featuring smooth drag transitions and synchronized active category chip snapping.
  - **Light Theme Header Contrast:** Darkened GitPulse logo title text in light theme mode to crisp high-contrast black (`#1F2328`) for optimal clarity against light surfaces.

* ### v2.0.0
  - **Full-Screen Seamless Animated App Background:** Replaced isolated header animations with a continuous, looping ambient canvas across the entire application from top to bottom (status bar down to navigation bar), tailored per theme:
    - *AMOLED Sakura (Radiant Pink 🌸):* Drifting cherry blossom petals with an elegant sakura tree trunk, branches, and blossom clusters on pure AMOLED black.
    - *AMOLED Night (Starry Cosmos 🌌):* Full-height starry cosmos with twinkling diamond stars, glowing crescent moon, and diagonal shooting stars / meteors crossing the screen.
    - *Dark Mode (Thunderstorm ⛈️):* Atmospheric dark rain with animated rain streaks, brooding storm clouds, and periodic electric-blue jagged lightning strikes with ambient flash lighting.
    - *Light Mode (Autumn Leaves 🍃):* Gentle swirling green and autumn breeze leaves with natural drift.
  - **RPG Arcane Aura Commit Tier Engine & Overhauled Matrix:** Complete overhaul of the 6-level Commit Activity Tier Matrix with strictly calibrated seasonal streak/commit thresholds and custom GPU canvas shader animations:
    - *Tier 1 (Mythic Archmage):* Multi-hue arcane dragonflame gradient (Ruby, Violet, Gold, Starfire) with orbital floating rune embers.
    - *Tier 2 (Diamond Vanguard):* Glacial diamond crystal cyan and electric blue lightning arc with high-frequency micro-crackle.
    - *Tier 3 (Platinum Artisan):* Sacred emerald blade reflection sweep with jade-platinum dual-hue sheen.
    - *Tier 4 (Gold Adventurer):* Sunburst guild crest radiance with warm golden solar flare gleam.
    - *Tier 5 (Silver Explorer):* Moonlit silver mist wave with soft twilight stardust drift.
    - *Tier 6 (Bronze Novice):* Rustic bronze casing with living green sprout breathing rhythm and morning dewdrop shimmer.
  - **Dedicated Favorite Profiles Grid:** Brand-new `FavoriteProfilesScreen` featuring dynamic 1 to 4 columns per row density slider, enriched developer cards (avatar, full name, GitHub handle, bio, location), unfavorite with floating SnackBar undo, and persistent on-device storage.
  - **Glassmorphism Theme System:** Scaffold and AppBar backgrounds rendered transparent with subtly translucent card surfaces (`~92%` opacity) allowing the live animated background to shine through seamlessly.
  - **Plus Jakarta Sans Typography:** Upgraded core application font to Google Fonts' Plus Jakarta Sans for razor-sharp telemetry numbers, higher readability, and modern tech aesthetics, while preserving fixed monospace for code viewers and technical data.
  - **Radiant Sakura Pink Palette Refinement:** Replaced coral/reddish tones in AMOLED Sakura mode with authentic radiant cherry blossom pink (`#FF65A3`), harmonizing card borders, dark wisteria surfaces, and ambient canvas petals.
  - **Running Text (Marquee) for Repository Titles:** Added reusable `RunningText` widget supporting smooth ping-pong auto-scroll for long repository and file titles in AppBars, and interactive touch-scrollable text in overview cards to prevent text truncation.
  - **Horizontally Scrollable Folder Breadcrumbs:** Replaced static breadcrumb bar in `RepoDetailScreen` with a smooth horizontally scrollable trail, featuring a pinned parent navigation button and auto-scroll to the active deep directory without clipping.
  - **Dynamic GitHub Trending & Tech News:** Overhauled trending repository algorithm to query active projects created in the past 14 to 30 days sorted by stars, with 15-minute in-memory TTL caching, persistent offline storage fallback, and subtle offline mode indicator badge.
  - **New Phantek Visual Identity:** Replaced legacy launcher icon with official high-resolution Phantek icon across all mipmap density tiers (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) and in-app asset catalogs.
  - **Clean Header Identity:** Removed logo tap animation for a static, elegant header identity with synchronized animation lifecycle pause/resume during modal navigation to conserve battery and GPU.
  - **Silent Profile Background Enrichment:** Automatically fetches missing location and bio details from GitHub REST API in the background for existing bookmarks.
  - **Streamlined Search UX:** Simplified search placeholder hint across all 6 supported languages to clean action verbs (`Search...`, `Cari...`, `検索...`, etc.) removing verbose examples.
  - **Application Package Identifier Migration:** Standardized Android namespace and application package identifier to `com.phantek.orion.rigel`.

* ### v1.0.13
  - **Settings Sheet Visual Polish:** Refined settings sheet layout and theme option cards with responsive layout geometry and smooth touch states.
  - **Header Canvas Fine-Tuning:** Polished particle physics parameters and alpha blending across all 4 theme modes.

* ### v1.0.12
  - **Native In-App Repository Explorer:** Added dual-tab repository screen toggling between README documentation and interactive file tree without external browser redirects.
  - **Syntax-Highlighted File Viewer:** Added `FileViewerScreen` with line numbering, file metadata, character count, and copy action.
  - **Relative Asset Resolution:** Automatic resolution of relative image paths in README files against GitHub raw CDN with dark/light mode image marker support.
  - **Expanded Multi-Language Dictionary:** Full localization dictionary coverage for repository explorer, file viewer, and directory navigation across all 6 languages.

* ### v1.0.11
  - *Internal test build and hotfix staging.*

* ### v1.0.10
  - **Header Animation Pause on Modals:** Implemented `HeaderAnimationState` to suspend background Canvas particle loops when settings or modals open, reducing idle background GPU/CPU usage to 0%.
  - **Zero-saveLayer Optimization:** Replaced offscreen GPU `ShaderMask` allocations with native concentric GPU alpha rings to prevent frame drops on low-tier devices.

* ### v1.0.9
  - **Curated Tech News & Ecosystem Feed:** Aggregated trending GitHub repositories and dev.to articles with category filtering chips and constrained thumbnail cache decoding (`cacheWidth: 450`).

* ### v1.0.8
  - **6-Language Internationalization Overhaul:** Added complete dictionary translations for Bahasa Indonesia, English, Japanese, Simplified Chinese, Traditional Chinese, and Korean.

* ### v1.0.7
  - *Internal test build and localization verification.*

* ### v1.0.6
  - **In-App OTA Updater & Safe Storage Pipeline:** Integrated background APK downloading via `ota_update` with automated startup cleanup of installed update binaries in `/Download/GitPulse/`.
  - **Android PackageInstaller Integration:** Configured secure `FileProvider` and Android permissions for seamless in-place APK installation.

* ### v1.0.5
  - *Internal test build and OTA pipeline verification.*

* ### v1.0.4
  - **Commit Activity Tier Engine:** Added 6-tier continuous animated badges (Code Titan, Relentless Committer, Consistent Builder, Weekend Warrior, Dormant Explorer, Fresh Sprout) with physics-based shaders.
  - **4 Dynamic Theme Modes:** Introduced Dark (Navy), Pure Black AMOLED, Clean Light, and hidden AMOLED Sakura mode unlocked via 10-tap gesture.

* ### v1.0.3
  - *Internal test build and theme asset tuning.*

* ### v1.0.2
  - *Internal test build and analytics layout adjustments.*

* ### v1.0.1
  - **24-Hour Activity Rhythm & Portfolio Analytics:** 24-bar diurnal activity histogram, language footprint donut chart, and cumulative stargazer/fork portfolio telemetry.
  - **Sliver Virtualization:** `CustomScrollView` and `SliverList.builder` for smooth 60fps scrolling across 100+ repositories.

* ### v1.0.0
  - **Initial Release:** Initial project setup, base architecture, and GitHub API connection pipeline.

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
