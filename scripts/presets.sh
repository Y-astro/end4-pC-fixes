#!/usr/bin/env bash

LOCAL_PRESETS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/presets"
ONLINE_PRESETS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/presets"
IMPORTED_PRESETS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/presets_imported"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCHWALL="$SCRIPT_DIR/colors/switchwall.sh"

mkdir -p "$LOCAL_PRESETS_DIR" "$ONLINE_PRESETS_DIR" "$IMPORTED_PRESETS_DIR"

BLACKLIST_FILTER='del(._presetMeta)
  | del(.time, .battery, .audio, .sounds, .language, .workSafety)
  | del(.ai, .networking, .musicRecognition, .search, .screenRecord, .screenSnip, .updates)
  | del(.bar.weather)
  | del(.hyprland.input, .hyprland.autostartApps, .hyprland.general.layout)'

raw_action="$1"
shift

action="${raw_action#--}"
case "$action" in
    load) action="apply" ;;
    delete) action="remove" ;;
    export) action="export-zip" ;;
    import) action="import-zip" ;;
esac

online=false
imported=false
args=()
for arg in "$@"; do
    if [ "$arg" = "--online" ]; then
        online=true
    elif [ "$arg" = "--imported" ]; then
        imported=true
    else
        args+=("$arg")
    fi
done

name="${args[0]}"
description="${args[1]}"

if [ "$action" = "list" ]; then
    mkdir -p "$LOCAL_PRESETS_DIR"
    for f in "$LOCAL_PRESETS_DIR"/*.json; do
        [ -f "$f" ] || continue
        bname=$(basename "$f" .json)
        desc=$(jq -r '._presetMeta.description // ""' "$f" 2>/dev/null || echo "")
        wall=$(jq -r '.background.wallpaperPath // ""' "$f" 2>/dev/null || echo "")
        wall="${wall/\$HOME/$HOME}"
        if [ -z "$wall" ] || [ ! -f "$wall" ]; then
            for ext in png jpg jpeg webp gif mp4; do
                if [ -f "$LOCAL_PRESETS_DIR/${bname}.${ext}" ]; then
                    wall="$LOCAL_PRESETS_DIR/${bname}.${ext}"
                    break
                fi
            done
        fi
        jq -n --arg name "$bname" --arg desc "$desc" --arg wall "$wall" \
            '{name: $name, description: $desc, wallpaper: $wall}'
    done
    exit 0
fi

if [ "$action" = "import-zip" ]; then
    if [ -z "$name" ]; then
        if command -v zenity >/dev/null 2>&1; then
            name=$(zenity --file-selection --file-filter="Presets (*.zip) | *.zip" 2>/dev/null)
        elif command -v kdialog >/dev/null 2>&1; then
            name=$(kdialog --getopenfilename "$HOME" "*.zip | Preset ZIP" 2>/dev/null)
        fi
    fi
    if [ -z "$name" ]; then
        echo "Error: missing zip path" >&2
        exit 1
    fi
    zip_path="${name#file://}"
    if [ ! -f "$zip_path" ]; then
        echo "Error: zip not found: $zip_path" >&2
        exit 1
    fi
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$zip_path" -d "$tmpdir"
    else
        python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_path" "$tmpdir"
    fi
    json_file=$(find "$tmpdir" -maxdepth 4 -name "*.json" ! -name "meta.json" | head -n1)
    if [ -z "$json_file" ]; then
        echo "Error: no preset json in zip" >&2
        exit 1
    fi
    base=$(basename "$json_file" .json)
    json_dir=$(dirname "$json_file")
    asset_files=$(find "$json_dir" -maxdepth 1 -type f ! -name "*.json" ! -name "meta.json" -exec basename {} \; | jq -R . | jq -s .)
    asset_cache="$IMPORTED_PRESETS_DIR/assets/$base"
    mkdir -p "$asset_cache"
    find "$json_dir" -maxdepth 1 -type f ! -name "*.json" ! -name "meta.json" -exec cp -L {} "$asset_cache/" \; 2>/dev/null || true
    jq --arg dir "$asset_cache" --argjson files "$asset_files" '
      $files as $files | walk(if type == "string" then ((split("/") | last) as $base | if ($files | index($base)) then ($dir + "/" + $base) else . end) else . end)
      | del(._presetMeta) | ._presetMeta.source = "imported"
    ' "$json_file" | jq "$BLACKLIST_FILTER" > "$IMPORTED_PRESETS_DIR/${base}.json"
    echo "Imported $base to $IMPORTED_PRESETS_DIR/${base}.json with assets in $asset_cache"
    trap - EXIT
    rm -rf "$tmpdir"
    exit 0
fi

if [ -z "$name" ]; then
    echo "Error: missing preset name" >&2
    exit 1
fi

if $imported; then
    PRESETS_DIR="$IMPORTED_PRESETS_DIR"
elif $online; then
    PRESETS_DIR="$ONLINE_PRESETS_DIR"
else
    PRESETS_DIR="$LOCAL_PRESETS_DIR"
fi

case "$action" in
    save)
        jq "$BLACKLIST_FILTER" "$CONFIG_FILE" > "$PRESETS_DIR/${name}.json"
        if [ -n "$description" ]; then
            jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
        fi
        current_wall=$(jq -r '.background.wallpaperPath // empty' "$CONFIG_FILE")
        current_wall="${current_wall/\$HOME/$HOME}"
        if [ -n "$current_wall" ] && [ -f "$current_wall" ]; then
            ext="${current_wall##*.}"
            cp -L "$current_wall" "$PRESETS_DIR/${name}.${ext}" 2>/dev/null || true
        fi
        echo "Saved preset $name"
        ;;
    remove)
        rm -f "$PRESETS_DIR/${name}.json"
        for ext in png jpg jpeg webp gif mp4; do
            rm -f "$PRESETS_DIR/${name}.${ext}" "$PRESETS_DIR/${name}_banner.${ext}" "$PRESETS_DIR/${name}_profile.${ext}"
        done
        if [ -f "$LOCAL_PRESETS_DIR/.active" ] && [ "$(cat "$LOCAL_PRESETS_DIR/.active" 2>/dev/null)" = "$name" ]; then
            rm -f "$LOCAL_PRESETS_DIR/.active"
        fi
        if $online; then
            rm -rf "$ONLINE_PRESETS_DIR/assets/${name}"
        elif $imported; then
            rm -rf "$IMPORTED_PRESETS_DIR/assets/${name}"
        fi
        echo "Removed preset $name"
        ;;
    apply)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi
        tmp=$(mktemp)
        jq "$BLACKLIST_FILTER" "$preset_file" > "$tmp"
        sed -i "s|\\\$HOME|$HOME|g" "$tmp"
        jq -s '.[0] * .[1] | del(._presetMeta)' "$CONFIG_FILE" "$tmp" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        rm -f "$tmp"
        wall=$(jq -r '.background.wallpaperPath // empty' "$CONFIG_FILE")
        if [ -z "$wall" ] || [ ! -f "$wall" ]; then
            for ext in png jpg jpeg webp gif mp4; do
                if [ -f "$PRESETS_DIR/${name}.${ext}" ]; then
                    jq --arg w "$PRESETS_DIR/${name}.${ext}" '.background.wallpaperPath = $w' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                    break
                fi
            done
        fi
        echo "$name" > "$LOCAL_PRESETS_DIR/.active"
        "$SWITCHWALL" --noswitch
        echo "Applied preset $name"
        ;;
    export-zip)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi
        tmpdir=$(mktemp -d)
        trap 'rm -rf "$tmpdir"' EXIT
        filtered="$tmpdir/${name}.json"
        jq "$BLACKLIST_FILTER" "$preset_file" > "$filtered"
        collect_asset() {
            local src="$1"; local key="$2"
            src="${src/\$HOME/$HOME}"
            if [ -n "$src" ] && [ -f "$src" ]; then
                cp -L "$src" "$tmpdir/" 2>/dev/null || true
                echo "$(basename "$src")"
            fi
        }
        wallpaper=$(jq -r '.background.wallpaperPath // empty' "$filtered")
        lockwall=$(jq -r '.background.lockWall // empty' "$filtered")
        banner=$(jq -r '.sidebar.bannerImage // empty' "$filtered")
        customImg=$(jq -r '.background.widgets.customImage.path // empty' "$filtered")
        avatar=$(jq -r '.profile.avatarPicture // .profile.avatarPath // empty' "$filtered")
        wallpapers="[]"
        if [ -n "$wallpaper" ]; then
            wallpaper="${wallpaper/\$HOME/$HOME}"
            if [ -f "$wallpaper" ]; then
                wallpapers=$(jq -n --arg b "$(basename "$wallpaper")" '[$b]')
            fi
        fi

        meta_avatar=""; meta_banner=""; meta_custom=""; meta_lock=""
        [ -n "$wallpaper" ] && collect_asset "$wallpaper" >/dev/null
        if [ -n "$lockwall" ]; then meta_lock=$(collect_asset "$lockwall"); fi
        if [ -n "$banner" ]; then meta_banner=$(collect_asset "$banner"); fi
        if [ -n "$customImg" ]; then meta_custom=$(collect_asset "$customImg"); fi
        if [ -n "$avatar" ]; then meta_avatar=$(collect_asset "$avatar"); fi

        jq -n --argjson w "$wallpapers" \
              --arg avatar "$meta_avatar" --arg banner "$meta_banner" \
              --arg custom "$meta_custom" --arg lock "$meta_lock" \
              '{preview: "", screenshots: [], wallpapers: $w} + (if $avatar != "" then {avatar: $avatar} else {} end)
               + (if $banner != "" then {banner: $banner} else {} end)
               + (if $custom != "" then {customImage: $custom} else {} end)
               + (if $lock != "" then {lockWall: $lock} else {} end)' > "$tmpdir/meta.json"
        zip_name="${name}.zip"
        if command -v zip >/dev/null 2>&1; then
            (cd "$tmpdir" && zip -r "$LOCAL_PRESETS_DIR/$zip_name" . >/dev/null)
        else
            python3 -c "import zipfile, pathlib, sys; z=zipfile.ZipFile(sys.argv[1],'w',zipfile.ZIP_DEFLATED); [z.write(str(p), arcname=p.name) for p in pathlib.Path(sys.argv[2]).iterdir()]; z.close()" "$LOCAL_PRESETS_DIR/$zip_name" "$tmpdir"
        fi
        echo "Exported $LOCAL_PRESETS_DIR/$zip_name"
        trap - EXIT
        rm -rf "$tmpdir"
        ;;
    *)
        echo "Error: unknown action: $action" >&2
        exit 1
        ;;
esac
