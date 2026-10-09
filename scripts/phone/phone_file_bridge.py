#!/usr/bin/env python3
"""
Phone File Bridge Helper
Handles querying remote Android filesystem directories, creating folders,
pushing files over ADB, and broadcasting MediaScanner intents.
"""

import sys
import os
import json
import subprocess
import shlex
import urllib.parse

def get_adb_device():
    """Returns active adb device serial if reachable."""
    try:
        res = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=3)
        lines = res.stdout.strip().splitlines()
        for line in lines[1:]:
            parts = line.strip().split()
            if len(parts) >= 2 and parts[1] == "device":
                return parts[0]
    except Exception:
        pass
    return None

def cmd_is_ready():
    dev = get_adb_device()
    print(json.dumps({"ready": dev is not None, "device": dev or ""}))

def cmd_list(remote_path):
    remote_path = remote_path.rstrip('/') or '/'
    dev = get_adb_device()
    if not dev:
        print(json.dumps({"status": "error", "message": "ADB device not reachable", "folders": []}))
        return

    # Use ls -1 -p to list folders with trailing slash
    cmd = ["adb", "-s", dev, "shell", f"ls -1 -p {shlex.quote(remote_path)} 2>/dev/null"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        lines = res.stdout.splitlines()
        folders = []
        for line in lines:
            line = line.strip()
            if line.endswith('/') and not line.startswith('.'):
                folder_name = line.rstrip('/')
                folders.append(folder_name)
        folders.sort(key=str.lower)
        print(json.dumps({"status": "ok", "path": remote_path, "folders": folders}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e), "folders": []}))

def cmd_mkdir(remote_path):
    dev = get_adb_device()
    if not dev:
        print(json.dumps({"status": "error", "message": "ADB device not reachable"}))
        return

    cmd = ["adb", "-s", dev, "shell", f"mkdir -p {shlex.quote(remote_path)}"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if res.returncode == 0:
            print(json.dumps({"status": "ok", "path": remote_path}))
        else:
            print(json.dumps({"status": "error", "message": res.stderr.strip()}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))

def cmd_push(destination, file_paths):
    dev = get_adb_device()
    if not dev:
        print(json.dumps({"event": "error", "message": "ADB device not reachable"}))
        return

    # Ensure destination folder exists
    subprocess.run(["adb", "-s", dev, "shell", f"mkdir -p {shlex.quote(destination)}"],
                   capture_output=True, timeout=5)

    total = len(file_paths)
    success_count = 0
    failed_files = []

    for idx, raw_path in enumerate(file_paths, start=1):
        local_file = raw_path
        if local_file.startswith("file://"):
            local_file = local_file[7:]
        local_file = urllib.parse.unquote(local_file).rstrip('/')
        
        if not os.path.exists(local_file):
            err_msg = "File does not exist locally"
            failed_files.append({"file": local_file, "message": err_msg})
            print(json.dumps({
                "event": "file_error",
                "file": local_file,
                "message": err_msg
            }), flush=True)
            continue

        file_name = os.path.basename(local_file)
        dest_file_path = f"{destination.rstrip('/')}/{file_name}"

        # Run adb push
        push_cmd = ["adb", "-s", dev, "push", local_file, dest_file_path]
        try:
            push_res = subprocess.run(push_cmd, capture_output=True, text=True, timeout=120)
            if push_res.returncode == 0:
                success_count += 1
                # Trigger media scanner for media indexing on Android
                subprocess.run(
                    ["adb", "-s", dev, "shell",
                     f"am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d {shlex.quote('file://' + dest_file_path)}"],
                    capture_output=True, timeout=5
                )

                print(json.dumps({
                    "event": "progress",
                    "index": idx,
                    "total": total,
                    "file": file_name,
                    "destination": dest_file_path
                }), flush=True)
            else:
                err_msg = push_res.stderr.strip() or "adb push failed"
                failed_files.append({"file": file_name, "message": err_msg})
                print(json.dumps({
                    "event": "file_error",
                    "file": file_name,
                    "message": err_msg
                }), flush=True)
        except Exception as e:
            err_msg = str(e)
            failed_files.append({"file": file_name, "message": err_msg})
            print(json.dumps({
                "event": "file_error",
                "file": file_name,
                "message": err_msg
            }), flush=True)

    print(json.dumps({
        "event": "complete",
        "total": total,
        "success": success_count,
        "failed": len(failed_files),
        "failed_files": failed_files,
        "destination": destination
    }), flush=True)

def main():
    if len(sys.argv) < 2:
        print("Usage: phone_file_bridge.py <is-ready|list|mkdir|push> [args...]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "is-ready":
        cmd_is_ready()
    elif cmd == "list":
        remote_path = sys.argv[2] if len(sys.argv) > 2 else "/sdcard"
        cmd_list(remote_path)
    elif cmd == "mkdir":
        if len(sys.argv) < 3:
            print(json.dumps({"status": "error", "message": "Missing path"}))
            return
        cmd_mkdir(sys.argv[2])
    elif cmd == "push":
        if len(sys.argv) < 4:
            print(json.dumps({"event": "error", "message": "Usage: push <destination> <files...>"}))
            return
        destination = sys.argv[2]
        files = sys.argv[3:]
        cmd_push(destination, files)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
