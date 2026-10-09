# Design Spec: In-Sidebar Drag-to-Send Phone File Bridge

- **Date:** 2026-10-09
- **Author:** Antigravity & User
- **Status:** Approved
- **Target Repository:** `end4-pC` (`/home/astro/.config/quickshell/end4-pC`)
- **Target Device:** OnePlus Nord CE5 (Android 16, CPH2717IN)

---

## 1. Overview & Objectives

Provide a seamless, low-friction file transfer bridge directly inside the left sidebar (`Super + A`).
When files from the laptop are dragged over the sidebar, the sidebar dynamically transitions into a targeted drop hub featuring:
1. **4 Main Destination Zones:** Downloads, Documents, Pictures, and Audio/Music.
2. **Hover Sub-Zones:** Hovering over any of the 4 zones splits it into two distinct targets: **Direct Copy** and **+ New Folder**.
3. **Internal Storage Traversal (Zone 5):** A bottom zone that opens an in-sidebar filesystem browser starting at `/sdcard` with single-click selection, double-click folder navigation, breadcrumbs, and a "Use" confirmation button.
4. **High-Speed ADB Push with Media Scanner Broadcast:** Ultra-fast transfers via USB/Wireless ADB followed by Android `MediaScanner` indexing, with automatic failover to KDE Connect if ADB is offline.
5. **Fluid Animations & Micro-Interactions:** Staggered spring entrances, glassmorphic hover glows, smooth sub-zone splits, and pulsing progress feedback.

---

## 2. Architecture & Components

```
modules/ii/sidebarPolicies/phone/
 ├── Phone.qml                  (Host container, houses DropArea and loads PhoneFileBridge)
 └── PhoneFileBridge.qml        (Main visual UI: 4 zones, hover sub-zones, Zone 5 explorer, animations)

services/
 └── PhoneFileBridgeService.qml (Singleton service: ADB directory listing, adb push execution,
                                 MediaScanner trigger, KDE Connect fallback)
```

### Component Roles

### `PhoneFileBridgeService.qml` (Singleton Service)
- **State Properties:**
  - `isTransferring: bool`
  - `transferProgress: real` (0.0 to 1.0)
  - `transferSpeed: string` (e.g. `"85 MB/s"`)
  - `currentDestination: string`
  - `lastError: string`
- **Methods:**
  - `listDirectory(remotePath, callback)`: Executes `adb shell ls -F "<path>"` to return subdirectories on the phone in milliseconds.
  - `createDirectory(remotePath, callback)`: Executes `adb shell mkdir -p "<path>"`.
  - `pushFiles(fileUrls, destinationPath, callback)`:
    - If ADB is reachable (`KdeConnectService.adbReachable` or ADB device present):
      - Executes `adb push <localPath> <destinationPath>` for each file.
      - Upon completion, executes `adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://<destinationPath>/<filename>"` so Android gallery/music apps index the files immediately.
    - If ADB is not reachable:
      - Automatically calls `KdeConnectService.shareUrl(activeDeviceId, fileUrl)` (fallback to default Downloads folder).
      - Emits notification toast informing the user.

### `PhoneFileBridge.qml` (In-Sidebar UI)
- Hosted inside `modules/ii/sidebarPolicies/phone/Phone.qml`.
- Activated whenever `phoneDropArea.containsDrag` is true, or when files have been dropped and are awaiting folder confirmation (Zone 5 or New Folder mode).
- Sub-components:
  1. **Zone Grid (2×2):**
     - **Zone 1: Downloads** (`/sdcard/Download`)
     - **Zone 2: Documents** (`/sdcard/Documents`)
     - **Zone 3: Pictures** (`/sdcard/Pictures`)
     - **Zone 4: Audio / Music** (`/sdcard/Music`)
  2. **Hover Detection & Sub-Zones:**
     - Tracks cursor position inside each card (`DropArea.drag.x / y` or `MouseArea` hover during drag).
     - Renders the smooth transition revealing the two sub-zone pills:
       - **📥 Direct Copy**
       - **📁 + New Folder**
  3. **Zone 5: Internal Storage Explorer:**
     - Positioned at the bottom of the grid.
     - When clicked or dropped into, slides the in-sidebar browser up over the zones.
     - Breadcrumbs bar (`📱 /sdcard / Download / ...`).
     - Directory list:
       - Single-click: Highlights item as selected copy target.
       - Double-click: Navigates inside that directory and reloads contents via `PhoneFileBridgeService.listDirectory`.
       - Parent folder row (`.. (Go back up)`) when deeper than `/sdcard`.
     - Footer bar: Displays chosen path and **"Use"** button to execute push.
  4. **Inline New Folder Dialog:**
     - Sleek in-sidebar card with folder name input (`[ MyFolder ]`) and `[ Create & Copy ]` button.
  5. **Transfer Progress Bar & Toast:**
     - Replaces target zone with active progress bar, speed metric, and success badge.

---

## 3. Interaction & Visual Flow

```
[User drags file over sidebar]
               │
               ▼
   [Sidebar transitions into Drag Overlay]
   ┌─────────────────────────────────────┐
   │  [Downloads]         [Documents]    │
   │  [Pictures]          [Audio]        │
   │─────────────────────────────────────│
   │      [Internal Storage Explorer]    │
   └─────────────────────────────────────┘
               │
       ┌───────┴──────────────────────────────┬─────────────────────────┐
       ▼                                      ▼                         ▼
[Hover over a zone]                 [Drop into Zone 5]         [Drop into Direct Copy]
       │                                      │                         │
[Card splits into sub-zones:        [In-sidebar storage        [Immediate ADB push
 📥 Direct Copy  &                   browser opens:             to /sdcard/...
 📁 + New Folder]                    Single-click to select,    MediaScanner scans,
       │                             Double-click to drill,     Success toast pops]
 ┌─────┴──────────────────┐          "Use" to push]
 ▼                        ▼
[Drop Direct]       [Drop New Folder]
Immediate Push      Prompt folder name ->
                    mkdir -p -> Push
```

---

## 4. Specific Phone Directory Mappings (OnePlus Nord CE5)

Verified on device (`SK7L7TDQKNBM9HW4`):
- Downloads: `/sdcard/Download`
- Documents: `/sdcard/Documents`
- Pictures: `/sdcard/Pictures` (and `/sdcard/DCIM` accessible via explorer)
- Audio: `/sdcard/Music`
- Storage Root: `/sdcard` (symlink to `/storage/self/primary`)

---

## 5. Animations & Motion Design

1. **Entrance (`containsDrag: true`):**
   - 4 main zones and Zone 5 stagger in using `Appearance.animation.elementMoveFast` with subtle scale (`0.94` to `1.0`) and opacity fade.
2. **Sub-Zone Reveal:**
   - On hover, the main card scales to `1.02`.
   - Default icon and label fade out (`opacity: 0.0`), sub-zone container fades in (`opacity: 1.0`, `scale: 1.0`), smoothly animating over 150ms.
3. **Storage Explorer Slide:**
   - Slides up from the bottom with `Easing.BezierSpline` (`Appearance.animationCurves.standardDecel`), taking up the full height of the file bridge card.
4. **Completion Pop:**
   - Target button pulses with an accent glow and displays a checkmark badge before the sidebar returns to normal idle state.

---

## 6. Error Handling & Edge Cases

- **ADB Disconnected:** Automatically falls back to `KdeConnectService.shareUrl(...)` and shows toast: `"ADB offline — sent via KDE Connect to Downloads"`.
- **Spaces & Special Characters:** All shell commands safely quote file names (`shlex.quote` in python or escaped double-quotes in bash).
- **Directory Permissions:** Confined to `/sdcard/` (`/storage/self/primary`), which is writable by ADB shell without root.
- **Drag Aborted:** If drag leaves the sidebar without dropping, cleanly animates back to normal sidebar content.

---

## 7. Verification & Testing

1. Drag single file over sidebar -> verify 4 zones appear with staggered animation.
2. Hover over "Downloads" -> verify sub-zones split ("Direct Copy" and "+ New Folder").
3. Drop onto "Direct Copy" -> verify file transfers to `/sdcard/Download` and Android gallery/files sees it.
4. Drop onto "+ New Folder" -> verify inline folder name input appears, creates folder, and pushes files.
5. Drop onto "Internal Storage Explorer" -> verify folder tree renders `/sdcard`, single-click selects, double-click navigates, "Use" pushes file.
6. Verify behavior when ADB cable is unplugged (KDE Connect fallback).
