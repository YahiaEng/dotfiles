#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           MEDIA POPUP CLOSE (BAR-04)                   ║
# ║  Closes BOTH the media popup and its click-away        ║
# ║  backdrop. Called by the backdrop's onclick and by the ║
# ║  popup's onkeypressed. Idempotent + silent — a missing ║
# ║  eww is a build concern, never a user-facing error.    ║
# ╚══════════════════════════════════════════════════════╝
command -v eww >/dev/null 2>&1 || exit 0
eww close media-popup   >/dev/null 2>&1 || true
eww close media-backdrop >/dev/null 2>&1 || true
exit 0
