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

### [ ] Phase 1: Architecture Mapping & Setup
- [x] Create directory backup & git backup branch.
- [ ] Map required shared JS helpers, icons, and services needed by widgets, launcher, bar, and settings.
- [ ] Ensure non-destructive addon structure for widgets.

### [ ] Phase 2: Desktop Background Widgets & Media Mode (#1)
- [ ] Port clock widgets (Nothing Wheel/Digital, WearOS Arc/Ring, Nagasaki, Scallop, Concentric, Cookie, Flex, Word, etc.).
- [ ] Port utility widgets (Nothing CPU/RAM/Disk dials, resource pills, At-A-Glance, Android search pill, Water reminder, Quote, 2x1 notes/email).
- [ ] Port alternative media widgets (CD spinning disc, Circular, Compact, Nothing Ring, Android).
- [ ] Port `MediaMode` (immersive backdrop, synced lyrics, queue, cover art, side panels).
- [ ] Register new widgets in `WidgetsRegistry.qml` / `WidgetsLoader.qml` as addons without altering existing widgets.

### [ ] Phase 3: Power-User Search Launcher & Overview (#2)
- [ ] Port calculator / unit & currency converter into search engine.
- [ ] Port 2-step power action confirmation safeguard.
- [ ] Port launcher micro-apps & panels (TypingTest, SpeedTest, Grammar, MediaDownloader, MaterialSymbols, Emoji, FileBrowser, Tools, etc.).
- [ ] Wire up sub-panels into `Overview.qml` / `SearchWidget.qml`.

### [ ] Phase 4: Bar Customizability & Modular Management (#4)
- [ ] Port bar styling options (Float, Hug, Rect styles, appearance customization, scroll actions, tooltips).
- [ ] Port bar configuration controls (`BarAppearanceConfig`, `BarLayoutConfig`, `BarPopupsConfig`, `BarScrollActionsConfig`, `BarTooltipsConfig`).
- [ ] Ensure user's custom `IslandFiller.qml` and existing bar widgets integrate cleanly.

### [ ] Phase 5: Redesigned Granular Settings Center (#7)
- [ ] Port the granular `modules/settings/configs/` suite (40+ category pages).
- [ ] Exclude/hide dock and overlay settings tabs to keep settings clean and aligned with user preferences.
- [ ] Ensure SettingsWindow / Settings launcher connects seamlessly to `GlobalStates.qml`.

### [ ] Phase 6: Verification & Polish
- [ ] Run QML syntax check / inspect for missing imports or dead references.
- [ ] Test live with `qs -c end4-pC`.
- [ ] Confirm user's custom features (WuWa visualizer, etc.) continue functioning flawlessly.
