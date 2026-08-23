---
created: 2026-08-23T01:20:00.000Z
title: steamwebhelper crash loop on NVIDIA + XWayland
area: general
severity: minor
files:
  - ~/.local/share/Steam/logs/cef_log.txt (evidence)
  - ~/.local/share/Steam/logs/webhelper.txt
---

## Problem

Steam's `steamwebhelper` (CEF/Chromium 126) crash-loops on this host. The renderer
is killed with `bad_message.cc(29) Terminating renderer for bad IPC message,
reason 213`, Steam respawns the browser process, and the client window reappears
showing a blank page.

**Measured 2026-08-23 04:19, whole-log:**

- 37 × `Crash reporting enabled for process: browser` (webhelper respawns)
- 22 × `bad IPC message` / `Tab Killed`
- Respawn timestamps cluster irregularly — 02:37:11, 02:37:22, 02:43:50,
  02:46:32, then 04:18:24 and 04:18:34 ten seconds apart. **The period is
  minutes to hours, not seconds.**
- 38 × `atom_cache.cc` adding `STEAM_GAME` / `_NET_WM_STATE_KEEP_ABOVE` — X11
  atoms, so the webhelper is running under **XWayland**, not native Wayland.

This is Steam-side. It reproduces with Steam launched directly from a terminal
(`steam` → parent chain `bash → fish → kitty → Hyprland`), with no quickshell,
no `uwsm`, and no launcher involvement.

**NOT the cause, ruled out:** the `data:text/html,%3Cbody%3E%3C%2Fbody%3E` URL is
a red herring — `webhelper.txt` shows Steam's own client window is internally
named `SteamBrowser-'data:text/'`. Also ruled out: cgroup death (Steam gets its
own `app-Hyprland-steam-*.scope`), MIME associations (`text/html` and
`http` both map to `zen.desktop`), XDG autostart (no entry), and anything in
this repo re-invoking it.

**Separate, do not conflate:** Steam also cannot be closed from its own window,
because this desktop has no system tray to minimise into — see
[[add-system-tray-capsule-to-the-quickshell-bar]]. That is our gap and is
independently fixable. This one is not.

## Solution

TBD — **two remedies have already been tried and BOTH FAILED**; do not repeat
them as if new:

1. Clearing `~/.local/share/Steam/config/htmlcache` (125 MB → rebuilt clean).
2. Launching with `-cef-disable-gpu`.

Crashes continued after both. A false "fixed" claim was recorded at the time and
later corrected; it came from sampling a ~1-minute window of a loop that fires
minutes-to-hours apart. **Any future fix attempt must be judged over hours, and
by counting `bad IPC message` occurrences across the whole log — not by a short
quiet window.**

Untried angles, roughly in order of cost:

- Identify what `bad_message` reason 213 actually is in Chromium 126 — it is a
  specific mojo validation failure and naming it would narrow the search a lot.
- Force the webhelper off XWayland, or conversely pin it there deliberately, and
  compare crash rates over a matched window.
- Check whether it correlates with a specific Steam UI surface (store, library,
  friends) rather than firing at random.
- Test against a different NVIDIA driver branch — this host has a documented
  history of NVIDIA-specific graphics faults (see
  [[nvidia-dkms-black-screen]] and [[screenshot-crashes-hyprland]]).
- Search Valve's tracker for `reason 213` + NVIDIA + Wayland before spending
  local effort; this is very likely not unique to this machine.

**Workaround meanwhile:** `steam -shutdown` reliably quits Steam (the window
close button does not, for the separate tray reason above). If Steam is wedged,
`systemctl --user stop app-Hyprland-steam-*.scope` kills the whole cgroup.

Severity is `minor` rather than `major`: Steam remains usable and games launch;
the loop makes the client window reappear and reload, which is disruptive but
has a working workaround.
