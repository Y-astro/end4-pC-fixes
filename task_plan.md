# Task Plan: Porting Customizations from ii-p3drovfx to end4-pC

## Overview
Port requested features from `P3DROVFX/ii-p3drovfx` into `end4-pC`:
1. Desktop Background Widgets & Media Mode (as add-ons, preserving existing custom widgets).
2. Power-User Search Launcher & Overview (math/unit converter, 2-step confirmation, all sub-panels).
3. Bar Management & Full Customizability (styles, layouts, appearances, scroll actions, popups).
4. Redesigned Granular Settings Center (40+ configuration categories, hiding skipped dock/overlays).

## User Preferences & Constraints
- Keep all existing user widgets and modifications intact (WuWa visualizer shaders, IslandFiller, etc.). Add new widgets as non-destructive addons.
- Skip Docks entirely (User dislikes docks).
- Skip Overlays entirely.
- Skip Hardware/Audio/Ecosystem bridges (earbuds daemon, local-send, etc.).
- Maintain Quickshell runtime compatibility and safety guards.

---

## Phases

### [x] Phase 1: Architecture Mapping & Setup
- [x] Create directory backup & git backup branch (`backup-pre-snatch`, `integrate-vynx-features`, and `~/.config/quickshell/end4-pC-backup-20261006_160052`).
- [x] Map required shared JS helpers, icons, and services needed by widgets, launcher, bar, and settings.
- [x] Ensure non-destructive addon structure for widgets.

### [x] Phase 2: Desktop Background Widgets & Media Mode (#1)
- [x] Port clock widgets (Nothing Wheel/Digital, WearOS Arc/Ring, Nagasaki, Scallop, Concentric, Cookie, Flex, Word, etc.).
- [x] Port utility widgets (Nothing CPU/RAM/Disk dials, resource pills, At-A-Glance, Android search pill, Water reminder, Quote, 2x1 notes/email).
- [x] Port alternative media widgets (CD spinning disc, Circular, Compact, Nothing Ring, Android).
- [x] Port `MediaMode` (immersive backdrop, synced lyrics, queue, cover art, side panels) with multi-monitor IPC/hotkey controls.
- [x] Register new widgets in `WidgetsRegistry.qml` and `WidgetsLoader.qml` as addons while maintaining custom visualizers (`VisualizerWidget.qml`, `wuwa.frag`, `fluid_wuwa.frag`). Added `VisualizerWidgetConfig.qml` for configuring both desktop visualizers in Settings.

### [x] Phase 3: Power-User Search Launcher & Overview (#2)
- [x] Port calculator / unit & currency converter into search engine (instant JS evaluation + `libqalculate` / `qalc`).
- [x] Port 2-step power action confirmation safeguard.
- [x] Port launcher micro-apps & panels (TypingTest, SpeedTest, Grammar, MediaDownloader, MaterialSymbols, Emoji, FileBrowser, Tools, etc.).
- [x] Wire up sub-panels into `Overview.qml` / `SearchWidget.qml`.

### [x] Phase 4: Bar Customizability & Modular Management (#4)
- [x] Port bar styling options (Float, Hug, Rect styles, appearance customization, scroll actions, tooltips).
- [x] Port bar configuration controls (`BarAppearanceConfig`, `BarLayoutConfig`, `BarPopupsConfig`, `BarScrollActionsConfig`, `BarTooltipsConfig`).
- [x] Ensure user's custom `IslandFiller.qml` and existing bar widgets integrate cleanly with brightness/volume scroll and sidebar click-to-open.

### [x] Phase 5: Redesigned Granular Settings Center (#7)
- [x] Port the granular `modules/settings/configs/` suite (40+ category pages).
- [x] Exclude/hide dock, overlay, and phone bridge settings tabs to keep settings clean and aligned with user preferences.
- [x] Ensure SettingsWindow / Settings launcher connects seamlessly to `GlobalStates.qml` via IPC and global shortcuts.

### [x] Phase 6: Verification & Polish
- [x] Run QML syntax check / inspect for missing imports or dead references.
- [x] Test live with `qs -c end4-pC` via IPC (`settings openPage`, `search setQuery`, `mediaMode toggle`).
- [x] Confirm user's custom features (WuWa visualizer, IslandFiller, etc.) continue functioning flawlessly.
- [x] Clean up temporary files and commit all work to git branch `integrate-vynx-features`.
