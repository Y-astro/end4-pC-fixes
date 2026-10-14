pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.modules.common

/**
 * The ii right-click menus as data: which menus exist, the entries each one
 * can carry, and how the user arranged them (Config.options.contextMenu).
 *
 * A menu still decides at runtime which of its entries apply - an origin, a
 * family, a clipboard holding files - and hands those live entries to
 * `arrange()`. That puts them in the user's order, drops the hidden ones,
 * splits off the icon bar in the compact style and adds the user's own
 * command entries. Separators are entries too ("separator", "separator-2"…),
 * so a group break is something the user can move or remove like any row.
 *
 * A new menu joins by adding a declaration to `menus` and passing its live
 * entries through `arrange(id, entries)`; the style, the editor in Settings
 * and the custom entries then work for it with nothing else to wire.
 */
Singleton {
    id: root

    readonly property var cfg: Config.options.contextMenu
    readonly property bool compact: (root.cfg?.style ?? "comfortable") === "compact"
    readonly property bool cascade: (root.cfg?.submenus ?? "inline") === "cascade"
    // The user's size for every menu (50-200 %). A menu applies it as a scale
    // on its card, and sizes its window/clamps by the scaled extent.
    readonly property real scale: Math.max(0.5, Math.min(2, Number(root.cfg?.scale ?? 1) || 1))

    // ── Dismissal ────────────────────────────────────────────────────────────
    // A menu is about what was under the pointer on THIS workspace. When the
    // workspace changes (Super+number, a touchpad swipe, a special workspace)
    // every open menu closes and lets go of its focus grab, instead of
    // floating over windows it has nothing to do with. Menus whose state
    // lives in GlobalStates are closed here; the rest listen for
    // `dismissAllRequested`.
    signal dismissAllRequested()
    function dismissAll(): void {
        GlobalStates.desktopMenuOpen = false;
        root.dismissAllRequested();
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecialv2") {
                root.dismissAll();
                return;
            }
            if (event.name !== "workspacev2")
                return;
            // Focus moving to a monitor whose workspace is already on screen
            // (the click that opened a menu there) is not a switch. Read before
            // HyprlandData refreshes: its update is an async hyprctl call.
            const id = parseInt(String(event.data).split(",")[0]);
            const onScreen = (HyprlandData.monitors ?? []).some(m => m?.activeWorkspace?.id === id);
            if (!onScreen)
                root.dismissAll();
        }
    }

    // ── Metrics ──────────────────────────────────────────────────────────────
    // Compact: the card fits its content between these, the rows are 34 px.
    // A strip of wallpapers takes the full width.
    readonly property real compactMaxWidth: 220
    readonly property real compactMinWidth: 200
    // A page with a grid on it (colors, presets) needs more than a row does.
    readonly property real compactPageWidth: 260
    // Between the menu and a cascaded submenu card.
    readonly property real cascadeGap: 6
    readonly property real compactPadding: 6
    readonly property real comfortablePadding: 8
    // The icon bar: buttons 36 px tall, as wide as the row shares out.
    readonly property real barButtonSize: 36
    readonly property real barButtonMinWidth: 30
    readonly property real barSpacing: 4

    /** What the icon bar needs to sit on one row at full size. */
    function barNaturalWidth(count: int): real {
        return count * root.barButtonSize + Math.max(0, count - 1) * root.barSpacing;
    }

    /**
     * How `count` icon buttons share `width`: one row while every button keeps
     * barButtonMinWidth, else as few rows as fit, the buttons dealt evenly
     * (7 → 4 + 3). Each row's buttons fill its width.
     */
    function barLayout(count: int, width: real): var {
        if (count <= 0)
            return { "rows": [], "height": 0 };
        const perRow = width > 0 ? Math.max(1, Math.floor((width + root.barSpacing) / (root.barButtonMinWidth + root.barSpacing))) : count;
        const rowCount = Math.ceil(count / perRow);
        const rows = [];
        for (let r = 0, left = count; r < rowCount; r++) {
            const n = Math.ceil(left / (rowCount - r));
            rows.push(n);
            left -= n;
        }
        return { "rows": rows, "height": rowCount * root.barButtonSize + (rowCount - 1) * root.barSpacing };
    }

    // ── Declarations ─────────────────────────────────────────────────────────
    // `groups` (menu): the comfortable style draws its separators as gaps
    // between groups; without it comfortable is one run and only compact
    // draws them.
    // `bar`: placed in the compact icon bar unless the user moved it.
    // `submenu`: opens a page (a chevron in the list, the page in a bar icon).
    // `block`: a run of entries supplied at runtime (an app's own actions);
    // it moves and hides as one, its rows are not editable one by one.
    // `families`: the panel families the entry can appear in; absent is all.
    // The editor labels the others ("Tablet only") instead of hiding them.
    // `header`: drawn above the entries rather than among them (the
    // wallpaper strip); it can only be shown or hidden (isShown).
    readonly property var menus: [
        { id: "desktop", name: "Desktop", icon: "desktop_windows", entries: [
            { id: "recents", symbol: "photo_library", title: "Recent wallpapers", header: true },
            { id: "style", symbol: "wallpaper", title: "Wallpaper & style", submenu: true },
            { id: "widgets", symbol: "widgets", title: "Desktop widgets", bar: true },
            { id: "edit", symbol: "edit", title: "Edit layout", bar: true },
            { id: "bar", symbol: "view_stream", title: "Arrange bar" },
            { id: "dropShelf", symbol: "stacks", title: "DropShelf" },
            { id: "liveWallpaper", symbol: "video_template", title: "Live wallpaper" },
            { id: "separator", separator: true },
            { id: "settings", symbol: "settings", title: "Settings", bar: true },
            { id: "customize", symbol: "tune", title: "Customize menu" }
        ] },
        { id: "editWidget", name: "Desktop widget", icon: "widgets", entries: [
            { id: "options", symbol: "tune", title: "Widget options" },
            { id: "duplicate", symbol: "content_copy", title: "Duplicate", bar: true },
            { id: "pin", symbol: "keep", title: "Pin position" },
            { id: "separator", separator: true },
            { id: "remove", symbol: "delete", title: "Remove from desktop", bar: true }
        ] },
        { id: "bar", name: "Bar", icon: "view_stream", entries: [
            { id: "edit", symbol: "edit", title: "Arrange bar", bar: true },
            { id: "settings", symbol: "settings", title: "Bar settings" },
            { id: "customize", symbol: "tune", title: "Customize menu" }
        ] }
    ]

    function definition(menuId: string): var {
        return root.menus.find(m => m.id === menuId) ?? null;
    }

    function isSeparator(id: string): bool {
        return id === "separator" || id.startsWith("separator-");
    }

    function customEntriesFor(menuId: string): var {
        return (root.cfg?.customEntries ?? []).filter(e => e && e.menu === menuId);
    }

    // What the menu looks like with nothing changed: declared order, the
    // declared bar entries, the entries that ship hidden.
    function defaultLayout(menuId: string): var {
        const def = root.definition(menuId);
        const entries = def ? def.entries : [];
        return {
            "menu": menuId,
            "order": entries.map(e => e.id),
            "bar": entries.filter(e => e.bar).map(e => e.id),
            "hidden": entries.filter(e => e.defaultHidden).map(e => e.id)
        };
    }

    function storedLayout(menuId: string): var {
        return (root.cfg?.layouts ?? []).find(l => l && l.menu === menuId) ?? null;
    }

    // For entries a menu draws on its own terms (a header): not hidden.
    function isShown(menuId: string, id: string): bool {
        return root.layoutFor(menuId).hidden.indexOf(id) < 0;
    }

    function isCustomised(menuId: string): bool {
        return root.storedLayout(menuId) !== null;
    }

    // The user's layout with every id the menu can carry placed somewhere:
    // an entry declared after the layout was saved (a newer shell) lands
    // after its declared predecessor, a custom entry missing from the order
    // goes last, and ids that no longer exist are dropped.
    function layoutFor(menuId: string): var {
        const base = root.defaultLayout(menuId);
        const stored = root.storedLayout(menuId);
        const customIds = root.customEntriesFor(menuId).map(e => e.id);
        const known = new Set(base.order.concat(customIds));
        if (!stored) {
            return {
                "menu": menuId,
                "order": base.order.concat(customIds),
                "bar": base.bar,
                "hidden": base.hidden
            };
        }
        const order = (stored.order ?? []).filter(id => known.has(id) || root.isSeparator(id));
        const seen = new Set(order);
        for (let i = 0; i < base.order.length; i++) {
            const id = base.order[i];
            if (seen.has(id))
                continue;
            let at = 0;
            for (let j = i - 1; j >= 0; j--) {
                const k = order.indexOf(base.order[j]);
                if (k >= 0) {
                    at = k + 1;
                    break;
                }
            }
            order.splice(at, 0, id);
            seen.add(id);
        }
        for (const id of customIds) {
            if (!seen.has(id))
                order.push(id);
        }
        return {
            "menu": menuId,
            "order": order,
            "bar": (stored.bar ?? []).filter(id => known.has(id)),
            "hidden": (stored.hidden ?? []).filter(id => known.has(id))
        };
    }

    /**
     * live: [{ id, symbol, title, ... }] - the entries that apply right now.
     * An entry with `items` is a block and expands in place.
     * Returns { bar: [...], rows: [...] }; rows may hold { separator: true },
     * never two in a row, never first or last.
     */
    function arrange(menuId: string, live: var): var {
        const layout = root.layoutFor(menuId);
        const byId = {};
        for (const e of live)
            byId[e.id] = e;
        for (const c of root.customEntriesFor(menuId)) {
            byId[c.id] = {
                "id": c.id,
                "symbol": c.symbol || "terminal",
                "title": c.title || c.command,
                "custom": true,
                "command": c.command
            };
        }
        const hidden = new Set(layout.hidden);
        const inBar = new Set(root.compact ? layout.bar : []);
        const bar = [];
        const rows = [];
        for (const id of layout.order) {
            if (hidden.has(id))
                continue;
            if (root.isSeparator(id)) {
                if (rows.length > 0 && !rows[rows.length - 1].separator)
                    rows.push({ "id": id, "separator": true });
                continue;
            }
            const entry = byId[id];
            if (!entry)
                continue;
            if (entry.items) {
                for (const item of entry.items)
                    rows.push(item);
                continue;
            }
            if (inBar.has(id))
                bar.push(entry);
            else
                rows.push(entry);
        }
        while (rows.length > 0 && rows[rows.length - 1].separator)
            rows.pop();
        return { "bar": bar, "rows": rows };
    }

    // Rows split at the separators, for hosts that draw groups.
    function groupsOf(rows: var): var {
        const groups = [[]];
        for (const r of rows) {
            if (r.separator)
                groups.push([]);
            else
                groups[groups.length - 1].push(r);
        }
        return groups.filter(g => g.length > 0);
    }

    // ── Writing ──────────────────────────────────────────────────────────────
    function setLayout(menuId: string, layout: var): void {
        const next = (root.cfg.layouts ?? []).filter(l => l && l.menu !== menuId);
        next.push({
            "menu": menuId,
            "order": layout.order.slice(),
            "bar": layout.bar.slice(),
            "hidden": layout.hidden.slice()
        });
        root.cfg.layouts = next;
    }

    function resetLayout(menuId: string): void {
        root.cfg.layouts = (root.cfg.layouts ?? []).filter(l => l && l.menu !== menuId);
        root.cfg.customEntries = (root.cfg.customEntries ?? []).filter(e => e && e.menu !== menuId);
    }

    function addCustom(menuId: string, symbol: string, title: string, command: string): string {
        const id = "custom-" + Date.now().toString(36);
        const list = (root.cfg.customEntries ?? []).slice();
        list.push({ "id": id, "menu": menuId, "symbol": symbol, "title": title, "command": command });
        root.cfg.customEntries = list;
        const layout = root.layoutFor(menuId);
        if (layout.order.indexOf(id) < 0)
            layout.order.push(id);
        root.setLayout(menuId, layout);
        return id;
    }

    function updateCustom(id: string, symbol: string, title: string, command: string): void {
        root.cfg.customEntries = (root.cfg.customEntries ?? []).map(e => e && e.id === id
            ? { "id": id, "menu": e.menu, "symbol": symbol, "title": title, "command": command } : e);
    }

    function removeCustom(id: string): void {
        const entry = (root.cfg.customEntries ?? []).find(e => e && e.id === id);
        root.cfg.customEntries = (root.cfg.customEntries ?? []).filter(e => e && e.id !== id);
        if (!entry)
            return;
        const layout = root.layoutFor(entry.menu);
        layout.order = layout.order.filter(x => x !== id);
        layout.bar = layout.bar.filter(x => x !== id);
        layout.hidden = layout.hidden.filter(x => x !== id);
        root.setLayout(entry.menu, layout);
    }

    function runCustom(entry: var, target: string): void {
        if (!entry || !entry.command)
            return;
        Quickshell.execDetached(["env", "II_CONTEXT_TARGET=" + (target ?? ""), "bash", "-c", entry.command]);
    }
}
