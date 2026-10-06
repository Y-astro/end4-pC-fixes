# Integration Findings & Technical Discoveries

## Architecture & Compatibility
- Both `end4-pC` and `ii-p3drovfx` share the same upstream codebase (`end-4/dots-hyprland` / `illogical-impulse`).
- Both store configuration in `~/.config/illogical-impulse/config.json`.
- The user has modified `end4-pC` locally:
  - Added WuWa visualizer shader (`wuwa.frag`, `fluid_wuwa.frag`) in `modules/ii/background/widgets/visualizer/`.
  - Added `IslandFiller.qml` in `modules/ii/bar/`.
  - Added astronomy / moon phase helpers in `modules/ii/background/widgets/weather/`.
- All integration must preserve these additions.

## Source Paths
- Source: `/home/astro/.gemini/antigravity-cli/brain/ea539705-cb7e-4616-9eff-e7eeb7f047bd/scratch/ii-p3drovfx`
- Target: `/home/astro/.config/quickshell/end4-pC`

## Scope Decisions
- #1 Desktop Widgets & Media Mode: Included. Widgets registered additively.
- #2 Search Launcher & Overview: Included in full.
- #3 Dock: Skipped.
- #4 Bar Customizability: Included for the bar itself.
- #5 Overlays: Skipped.
- #6 Bridges/Daemons: Skipped.
- #7 Granular Settings: Included in full (with dock/overlay sections filtered out).
