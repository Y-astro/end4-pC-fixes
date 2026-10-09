#!/usr/bin/env python3
"""
kdeconnect_adb_tunnel.py
Bridges KDE Connect over ADB (USB Debugging) when Wi-Fi is unavailable or isolated.

Architecture:
1. Sets up `adb forward tcp:1740 tcp:1716` (maps local port 1740 over USB to phone's KDE Connect).
2. Sets up `adb reverse tcp:1739 tcp:1716` (maps phone's port 1739 back to host KDE Connect).
3. Listens on TCP 0.0.0.0:1739 and proxies connections bidirectionally to 127.0.0.1:1740.
4. If device is not reachable, announces phone identity via UDP on port 1716 with tcpPort=1739
   from a local non-loopback IP (e.g. docker0 / USB tethering interface) so host kdeconnectd
   initiates the TLS connection directly through the USB tunnel.
"""

import sys
import os
import time
import json
import socket
import select
import signal
import threading
import subprocess
import configparser

CONFIG_PATH = os.path.expanduser("~/.config/kdeconnect")
TRUSTED_PATH = os.path.join(CONFIG_PATH, "trusted_devices")

PROXY_PORT = 1739
ADB_FORWARD_PORT = 1740
PHONE_KDE_PORT = 1716

running = True

def log(msg):
    print(f"[KdeConnect-ADB-Tunnel] {msg}", flush=True)

def get_paired_device_info():
    """Reads trusted_devices to find the paired phone deviceId and name."""
    if not os.path.exists(TRUSTED_PATH):
        return None, None
    cp = configparser.ConfigParser()
    try:
        cp.read(TRUSTED_PATH)
        for section in cp.sections():
            dtype = cp.get(section, "type", fallback="")
            if dtype == "phone" or not dtype:
                dname = cp.get(section, "name", fallback="Android Phone")
                return section, dname
    except Exception as e:
        log(f"Error reading trusted_devices: {e}")
    return None, None

def get_adb_device():
    """Returns active adb device serial if reachable."""
    try:
        res = subprocess.run(["adb", "get-state"], capture_output=True, text=True, timeout=3)
        if res.returncode == 0 and "device" in res.stdout:
            out = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=3)
            for line in out.stdout.splitlines()[1:]:
                parts = line.strip().split()
                if len(parts) >= 2 and parts[1] == "device":
                    return parts[0]
    except Exception:
        pass
    return None

def is_device_reachable_in_kde(dev_id):
    """Checks if the device is already marked reachable by kdeconnect."""
    if not dev_id:
        return False
    try:
        res = subprocess.run([
            "gdbus", "call", "--session",
            "--dest", "org.kde.kdeconnect",
            "--object-path", f"/modules/kdeconnect/devices/{dev_id}",
            "--method", "org.freedesktop.DBus.Properties.Get",
            "org.kde.kdeconnect.device", "isReachable"
        ], capture_output=True, text=True, timeout=2)
        return "<true>" in res.stdout
    except Exception:
        return False

def get_non_loopback_ips():
    """Finds non-loopback IPv4 addresses on the host (e.g. docker0, enp0s20f0u1)."""
    ips = []
    try:
        out = subprocess.run(["ip", "-4", "-br", "addr", "show"], capture_output=True, text=True, timeout=2)
        for line in out.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] != "lo":
                ip_cidr = parts[2]
                ip = ip_cidr.split("/")[0]
                if ip and not ip.startswith("127."):
                    ips.append(ip)
    except Exception:
        pass
    return ips

def send_discovery_packet(dev_id, dev_name, source_ip):
    """Sends UDP identity packet from source_ip to kdeconnectd on 1716."""
    packet = {
        "id": int(time.time() * 1000),
        "type": "kdeconnect.identity",
        "body": {
            "deviceId": dev_id,
            "deviceName": dev_name,
            "deviceType": "phone",
            "protocolVersion": 8,
            "incomingCapabilities": [
                "kdeconnect.notification", "kdeconnect.ping", "kdeconnect.findmyphone",
                "kdeconnect.battery", "kdeconnect.connectivity_report", "kdeconnect.mpris",
                "kdeconnect.runcommand", "kdeconnect.share", "kdeconnect.clipboard"
            ],
            "outgoingCapabilities": [
                "kdeconnect.notification", "kdeconnect.ping", "kdeconnect.findmyphone",
                "kdeconnect.battery", "kdeconnect.connectivity_report", "kdeconnect.mpris",
                "kdeconnect.runcommand", "kdeconnect.share", "kdeconnect.clipboard"
            ],
            "tcpPort": PROXY_PORT
        }
    }
    data = (json.dumps(packet) + "\n").encode("utf-8")
    targets = ["127.0.0.1", source_ip, "255.255.255.255"]
    for tgt in targets:
        try:
            udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            udp.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            udp.bind((source_ip, 0))
            udp.sendto(data, (tgt, 1716))
            udp.close()
        except Exception:
            pass

class TcpProxyServer:
    def __init__(self, listen_port, forward_port):
        self.listen_port = listen_port
        self.forward_port = forward_port
        self.server_sock = None
        self.running = False
        self.thread = None

    def start(self):
        self.server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_sock.bind(("0.0.0.0", self.listen_port))
        self.server_sock.listen(10)
        self.running = True
        self.thread = threading.Thread(target=self._accept_loop, daemon=True)
        self.thread.start()
        log(f"Proxy server listening on 0.0.0.0:{self.listen_port} -> 127.0.0.1:{self.forward_port}")

    def stop(self):
        self.running = False
        if self.server_sock:
            try:
                self.server_sock.close()
            except Exception:
                pass
            self.server_sock = None

    def _accept_loop(self):
        while self.running and self.server_sock:
            try:
                client_sock, addr = self.server_sock.accept()
                threading.Thread(target=self._handle_client, args=(client_sock, addr), daemon=True).start()
            except Exception:
                break

    def _handle_client(self, client_sock, addr):
        try:
            remote_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            remote_sock.connect(("127.0.0.1", self.forward_port))
            
            def pipe(src, dst):
                try:
                    while self.running:
                        data = src.recv(8192)
                        if not data:
                            break
                        dst.sendall(data)
                except Exception:
                    pass
                finally:
                    try: src.close()
                    except: pass
                    try: dst.close()
                    except: pass

            t1 = threading.Thread(target=pipe, args=(client_sock, remote_sock), daemon=True)
            t2 = threading.Thread(target=pipe, args=(remote_sock, client_sock), daemon=True)
            t1.start()
            t2.start()
            t1.join()
            t2.join()
        except Exception as e:
            try: client_sock.close()
            except: pass

def setup_adb_rules(serial):
    """Sets up ADB forward and reverse rules."""
    try:
        subprocess.run(["adb", "-s", serial, "forward", f"tcp:{ADB_FORWARD_PORT}", f"tcp:{PHONE_KDE_PORT}"],
                       capture_output=True, timeout=5)
        subprocess.run(["adb", "-s", serial, "reverse", f"tcp:{PROXY_PORT}", f"tcp:{PHONE_KDE_PORT}"],
                       capture_output=True, timeout=5)
        return True
    except Exception as e:
        log(f"Error setting up adb rules: {e}")
        return False

def teardown_adb_rules():
    """Cleans up forward/reverse rules."""
    try:
        subprocess.run(["adb", "forward", "--remove", f"tcp:{ADB_FORWARD_PORT}"],
                       capture_output=True, timeout=3)
        subprocess.run(["adb", "reverse", "--remove", f"tcp:{PROXY_PORT}"],
                       capture_output=True, timeout=3)
    except Exception:
        pass

def main():
    global running

    def sig_handler(signum, frame):
        global running
        running = False
        log("Received exit signal, stopping...")

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    log("Starting KDE Connect ADB Tunnel Daemon...")

    proxy = TcpProxyServer(PROXY_PORT, ADB_FORWARD_PORT)
    try:
        proxy.start()
    except Exception as e:
        log(f"Failed to start proxy: {e}")
        return 1

    last_device_serial = None
    last_announce_time = 0

    while running:
        serial = get_adb_device()
        dev_id, dev_name = get_paired_device_info()

        if serial:
            if serial != last_device_serial:
                log(f"Detected ADB device: {serial}. Establishing ADB tunnel...")
                setup_adb_rules(serial)
                last_device_serial = serial
                last_announce_time = 0  # Force immediate announcement

            now = time.time()
            if dev_id and (now - last_announce_time > 8):
                is_reachable = is_device_reachable_in_kde(dev_id)
                if not is_reachable:
                    non_loopbacks = get_non_loopback_ips()
                    if not non_loopbacks:
                        non_loopbacks = ["127.0.0.1"]
                    for source_ip in non_loopbacks:
                        send_discovery_packet(dev_id, dev_name or "Android Phone", source_ip)
                    last_announce_time = now
        else:
            if last_device_serial:
                log("ADB device disconnected.")
                last_device_serial = None

        time.sleep(2)

    proxy.stop()
    teardown_adb_rules()
    log("KDE Connect ADB Tunnel Daemon stopped.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
