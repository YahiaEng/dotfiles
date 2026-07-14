#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║       WAYBAR FULLSCREEN WATCHER (BAR-01/D-01)         ║
# ║  Long-running Hyprland socket2 listener. Translates    ║
# ║  fullscreen-enter/exit events into fullscreen          ║
# ║  hide/show INTENTS on waybar-visibility.sh — the sole  ║
# ║  owner of waybar visibility (D-03). This script never  ║
# ║  signals waybar directly.                              ║
# ╚══════════════════════════════════════════════════════╝
#
# Event format empirically confirmed live (Assumption A6, 08-04):
# connecting to .socket2.sock and fullscreening/un-fullscreening a real
# window produced the exact lines `fullscreen>>1` (enter) and
# `fullscreen>>0` (exit) — no other framing, no extra payload fields.
# Verbatim capture recorded in 08-04-SUMMARY.md.
#
# Headless/no-session safety (P7 D-34, container/VM gate): if
# XDG_RUNTIME_DIR or HYPRLAND_INSTANCE_SIGNATURE is unset, or the socket
# does not exist, exit 0 immediately — never block, never spin.

set -euo pipefail

VISIBILITY_OWNER="$HOME/.config/hypr/scripts/waybar-visibility.sh"

if [[ -z "${XDG_RUNTIME_DIR:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    exit 0
fi

SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ ! -S "$SOCKET_PATH" ]]; then
    exit 0
fi

# Inline python3 idiom (theme-doctor's established shape): stdlib
# networking only, zero new external binary dependency (the package gate
# stays honest). Every subprocess call is an argv LIST via
# subprocess.run(), a shell-interpreting invocation is never used —
# event payloads are compositor-supplied and must never reach a shell
# (T-08-20).
exec python3 - "$SOCKET_PATH" "$VISIBILITY_OWNER" <<'PYEOF'
import socket
import subprocess
import sys

sock_path = sys.argv[1]
owner = sys.argv[2]

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    s.connect(sock_path)
except OSError:
    sys.exit(0)

buf = b""
while True:
    try:
        chunk = s.recv(4096)
    except OSError:
        break
    if not chunk:
        # EOF: compositor closed the connection (session exit). Break and
        # exit cleanly rather than spin — an unconditional loop around a
        # dead read would peg a core at 100% for the rest of uptime.
        break
    buf += chunk
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        text = line.decode("utf-8", errors="replace")
        if not text.startswith("fullscreen>>"):
            # Ignore every other event name. Never parse window titles or
            # classes out of any payload here.
            continue
        payload = text[len("fullscreen>>"):]
        if payload == "1":
            subprocess.run([owner, "fullscreen", "hide"], check=False)
        elif payload == "0":
            subprocess.run([owner, "fullscreen", "show"], check=False)
        # Any other payload value: ignore. The owner absorbs redundant
        # re-declarations of the same intent (T-08-18), so a compositor
        # that fires this event twice per transition is harmless here.

sys.exit(0)
PYEOF
