# Phase 17: Ambient Extras - Research

**Researched:** 2026-08-09
**Domain:** Wayland layer-shell video wallpapers (mpvpaper), ffmpeg frame extraction, Hyprland 0.56.2 Lua plugin loading (hyprpm/hyprland-dynamic-cursors)
**Confidence:** MEDIUM-HIGH — every named open question in the task brief was resolved by reading upstream source (mpvpaper, mpv, Hyprland at the exact installed commit) and/or a live, non-mutating probe on this machine, not by websearch alone. The one item that stays genuinely open (frame-callback occlusion behavior under bare `-p`) is scoped precisely below rather than guessed at.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All 38 decisions (D-01..D-38) in `17-CONTEXT.md` are locked. This research does not re-litigate any of them. The full text is canonical and must be read directly from `17-CONTEXT.md` by the planner; the load-bearing subset this research directly informs is repeated inline in the relevant sections below (D-26, D-27, D-33, D-34, D-35, D-16, D-08/09/10, D-32).

### Claude's Discretion

- The owner script's name and placement (`waybar-visibility.sh` naming convention suggests `wallpaper-visibility.sh` under `hypr/.config/hypr/scripts/`).
- The IPC/socket client implementation shape — `socat` is **not installed** (confirmed again this session), `python3` and `jq` are; `waybar-fullscreen-watch.sh`'s inline-python3-stdlib-only idiom is the established convention.
- Exact seek-offset default in D-09 and the debounce interval in D-19 (~250ms is a starting point, not a locked value).
- Which `live/` marker glyph the picker uses in D-17.

### Deferred Ideas (OUT OF SCOPE)

- `gaming-mode-toggle.sh` possibly dead since the 13.1 Lua cutover — file as its own `/gsd-debug`, not folded into this phase.
- Wallpaper parallax on workspace switch — v4.0.
- mpvpaper slideshow mode (`-n/--slideshow`) — v4.0 candidate, not asked for by AMB-01.
- Removing `rose-pine-hyprcursor` if D-32 is reverted.
- Per-video audio opt-in — rejected under D-16.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AMB-01 | A video wallpaper plays beneath the desktop and hides itself when a fullscreen client is focused | mpvpaper CLI/source verified (namespace, hide mechanism, loop flag, hwdec); Hyprland's `wlr-foreign-toplevel-management-unstable-v1` implementation verified at the exact installed commit; ffmpeg frame-extraction command shape verified locally for mp4/gif/webp |
| AMB-02 | Dynamic cursors installed as an optional guarded dependency — missing/unbuilt/ABI-broken plugin degrades gracefully, never fails an unattended install | hyprpm toolchain dependency list extracted directly from the installed binary; `install.sh`'s actual warn-and-continue precedent located (correcting a wrong canonical-ref citation); `hl.plugin.load()`/`hl.get_loaded_plugins()` stub confirmed; runtime path resolution proven live via `os.getenv` |
</phase_requirements>

## Summary

This phase's risk is concentrated in a small number of load-bearing mechanisms, and every one of them was checkable without installing mpv/mpvpaper on this machine — by reading upstream source at pinned versions/commits and by running non-mutating local probes (`ffprobe`, `ffmpeg`, `hyprctl eval` writing to `/tmp`, reading the already-installed `dynamic-cursors.so` and its `hyprpm` state). The single biggest correction to carry into planning: **D-26's own framing undersells how strong the evidence for `-p -a full` actually is.** mpvpaper's `-a`/`--auto-mode` does **not** use the frame-callback "hack" upstream's README warns about — that hack is what bare `-p` alone uses. `-a` switches to a completely different, protocol-based code path (`wlr-foreign-toplevel-management-unstable-v1`), and Hyprland 0.56.2's own compiled headers/source (fetched at the exact installed commit `efb50993780079460b0cbed1363e2166a2de1d9f`) confirm it implements that protocol's FULLSCREEN and MAXIMIZED state events correctly. This is source-verified on both ends, not binary-tested end-to-end (mpvpaper itself isn't installed), so it lands at MEDIUM-HIGH rather than HIGH — but it is a materially stronger position than "unverified."

Second-biggest finding: **mpv's frame-extraction/looping behavior for animated GIF and WebP is fine, but the ffmpeg command shape for D-08/09/10's seek-to-offset step is NOT uniform across input types**, and this was missed by pure source-reading — it only showed up under a local `ffmpeg` test. Animated WebP (ffmpeg 9.0's `webp_anim` demuxer) reports no container duration and **silently produces zero output frames** when seeking with `-ss` placed *before* `-i` (fast input-seeking), while the identical command works fine for `.mp4` and `.gif`. Moving `-ss` to *after* `-i` (output/decode seeking) fixes it uniformly for all three input classes at negligible cost (these are short wallpaper loops, not long videos). ffmpeg also returns exit code 0 with an empty output file on out-of-range seeks — the D-08 "absent or zero-byte" repair check is not a nicety, it is the *only* way to detect this failure mode.

Third: this phase's install.sh work has two verified provisioning gaps: `cmake` and `cpio` are not declared anywhere in `PACMAN_PKGS`, yet hyprpm's own compiled binary states its hard toolchain requirement verbatim (`Hyprpm requires: cmake, cpio, pkg-config, git, g++, gcc`) — extracted directly via `strings /usr/bin/hyprpm`. And the CONTEXT.md canonical-refs citation for the warn-and-continue precedent is wrong: `verify_packages()` in `install.sh` is explicitly documented as hard-fail with **no** warn-and-continue path ("No warn-and-continue path" is a comment in the function itself) — the real precedent is the standalone `command || echo "  ⚠ ..." >&2` guard used for `swayosd-libinput-backend`, `ollama`, and `linux-modules-cleanup`. D-33's guarded hyprpm block must follow that shape and must **not** be added to `VERIFY_PKGS`.

Fourth: the `hl.plugin.load()` runtime-path-resolution question (open question #5) is answered and proven live, not merely reasoned about — `os.getenv("USER")` works inside Hyprland's Lua config-evaluation context (verified via a non-mutating `hyprctl eval` probe that wrote to a temp file and was immediately cleaned up), which is exactly what's needed to build `/var/cache/hyprpm/<user>/dynamic-cursors/dynamic-cursors.so` without hardcoding the username. Separately, and importantly for D-33's idempotency design: a live (accidental, safe) test showed that calling the raw IPC-level `hyprctl plugin load <path>` a second time on an already-loaded plugin **times out** rather than erroring cleanly — the guarded loader must check `hl.get_loaded_plugins()` before calling `hl.plugin.load()`, never call it unconditionally on every config reload.

**Primary recommendation:** Ship D-26's `-p -a full` as the primary hide mechanism (source-verified protocol path, not the hack path), keep D-27's fallback watcher scoped-but-not-built until a real fullscreen toggle is exercised against the installed `mpvpaper` binary at implementation time (exact probe specified below); fix the two `install.sh` toolchain gaps (`cmake`, `cpio`) and route AMB-02's guard through the `|| echo "⚠ ..." >&2` pattern, never through `verify_packages()`; extraction script must move `-ss` to after `-i` uniformly.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Video/GIF/WebP wallpaper playback | External process (mpvpaper, libmpv) | Compositor (Hyprland layer-shell background layer) | D-04: decoding must never happen inside QML/Quickshell; mpvpaper owns the wl_surface + EGL context on the `background` layer |
| Wallpaper visibility/lifecycle arbitration | Hyprland-scripts tier (new owner script) | — | Mirrors the already-proven single-owner pattern (`waybar-visibility.sh`); must be the sole writer of process start/stop |
| Wallpaper pause state | mpvpaper's own internal state machine (`-p`/`-a`) | Fallback watcher script (D-27, if needed) | D-29: the owner never touches the `pause` mpv property — two writers to one property is the exact bug class Phase 8 fixed |
| Fullscreen/maximize detection | Hyprland compositor, exposed via `wlr-foreign-toplevel-management-unstable-v1` | socket2 IPC (fallback watcher only) | Verified compiled into Hyprland 0.56.2 (`ForeignToplevelWlr.cpp`/`.hpp`) — a real protocol, not a polling hack, when `-a` is used |
| Frame extraction (video/GIF/WebP → PNG) | Hyprland-scripts tier (ffmpeg subprocess) | theme-engine (`theme-apply`'s wallpaper step calls it) | ffmpeg is a system dependency, not something to wrap in QML; theme-apply orchestrates *when* it runs (D-08's repair-on-missing guard) |
| Cursor plugin build/load | hyprpm (build) + Hyprland Lua config (`hl.plugin.load()`, runtime load) | install.sh (guarded provisioning attempt only) | hyprpm owns compilation against the exact Hyprland ABI; the repo's Lua config owns *declaring* the load so the cut sweep can see it (D-35) |
| GTK cursor-theme pin | theme-engine (`generate.sh`) + Hyprland Lua (`env.lua`) | — | Two independent render targets both hardcode the cursor name today — see the newly-found `env.lua:9` gap below |

## Standard Stack

### Core

| Package | Version (verified) | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `mpvpaper` | 1.9-1 (AUR) `[VERIFIED: paru -Si mpvpaper, this session]` | Video/GIF/WebP wallpaper player, layer-shell background surface | D-04 already locked; upstream README's own example usage matches this repo's intended flags almost verbatim (`-vs -a full -o "no-audio loop"`) `[CITED: github.com/GhostNaN/mpvpaper README/help text, fetched this session]` |
| `ffmpeg` | n9.0 (already installed, official repo) `[VERIFIED: ffmpeg -version, this session]` | Frame extraction (D-08/09/10), already the WebP/GIF demux/decode backend | Already a system dependency; no new package needed for extraction |
| `hyprpm` | ships inside `hyprland` 0.56.2-1 (already installed) `[VERIFIED: pacman -Qo /usr/bin/hyprpm, this session]` | Official Hyprland plugin build/load manager | The only supported plugin-loading path for Hyprland; no alternative exists |

### Supporting (toolchain, install.sh gap)

| Package | Purpose | When to Use |
|---------|---------|-------------|
| `cmake` | hyprpm's build system for plugin compilation | **Currently installed on this dev machine (4.4.2-1) but NOT declared anywhere in `install.sh`'s `PACMAN_PKGS`** `[VERIFIED: grep of full PACMAN_PKGS array, this session — no match]`. Must be added for a fresh machine to succeed. |
| `cpio` | Required by hyprpm's header-extraction step | **Currently installed (2.15-3) only as a transitive dependency of `debugedit`/`dracut`/`virt-install`, not declared by this repo** `[VERIFIED: pacman -Qi cpio → Required By, this session]`. Same gap as cmake. |
| `pkgconf` (provides `pkg-config`) | hyprpm build dependency | Already installed; not guaranteed on a fresh machine unless `base-devel` install path (conditional, only runs when no AUR helper is present) fires — worth an explicit unconditional declaration for the guarded step's own reliability |
| `git`, `gcc`/`g++` | hyprpm build dependencies | `gcc` provides both `gcc` and `g++` binaries on Arch `[VERIFIED: pacman -Qo $(which g++) → gcc, this session]`; `git` is almost certainly present (repo clone prerequisite) but not unconditionally declared either |

**Exact toolchain requirement, extracted directly from the installed `hyprpm` binary's embedded error strings (not a wiki, not training data):**
```
Hyprpm requires: cmake, cpio, pkg-config, git, g++, gcc
```
`[VERIFIED: strings /usr/bin/hyprpm | grep -i "Hyprpm requires", this session — the exact literal string the binary itself emits when a dependency is missing]`

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mpvpaper's native `-p -a full` | Independent fullscreen-watcher pausing mpvpaper (D-27) | D-27 stays scoped as fallback per the locked decision; this research strengthens the case that it should not be needed as the *primary* path, only a safety net |
| `hl.plugin.load()` from Lua config (D-35, locked) | `hyprpm reload` alone (no repo-visible load call) | hyprpm's own `reload` subcommand ("Ensure all enabled plugins are loaded") is a real alternative loading trigger, but D-35 deliberately wants the load declarative and inside the cut-sweep-visible repo — not reversed here, just noting hyprpm has its own idempotent-sounding path too |

**Installation (additions to `install.sh`):**
```bash
# PACMAN_PKGS additions (hyprpm toolchain — currently missing)
cmake
cpio

# AUR_PKGS additions
mpvpaper           # hard dependency, D-23 (already locked)
rose-pine-hyprcursor  # D-32 (already locked, already installed+verified this session: v0.3.2.r0.d2c0e680-1)
```
hyprpm's plugin repo itself (`hypr-dynamic-cursors`) is **not** an AUR/pacman package at all — `paru -Si hypr-dynamic-cursors` and `paru -Si dynamic-cursors` both fail `[VERIFIED: paru -Si, this session]`. It is installed purely via `hyprpm add https://github.com/virtcode/hypr-dynamic-cursors`, confirmed by the live `state.toml` at `/var/cache/hyprpm/aorus/dynamic-cursors/state.toml` (`url = 'https://github.com/virtcode/hypr-dynamic-cursors'`). The Package Legitimacy Audit below evaluates it as a git-repo dependency, not a registry package.

## Package Legitimacy Audit

> AUR is not covered by the automated `package-legitimacy check` seam (npm/pypi/crates only — confirmed by invoking it this session, it rejected `--ecosystem aur`). This audit follows this repo's own established convention for AUR/git dependencies (see `install.sh`'s existing "human package-legitimacy checkpoint" comments for prior AUR additions) — `paru -Si` output plus GitHub repo signals, gathered directly this session, not from training data.

| Package | Registry | Age | Votes/Stars | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `mpvpaper` | AUR | First submitted 2020-09-10, last modified 2026-07-19 | 19 votes, 0.44 popularity (AUR); 1561 GitHub stars, pushed 2026-07-25, not archived | github.com/GhostNaN/mpvpaper | OK | Approved (already locked D-23) |
| `rose-pine-hyprcursor` | AUR | First submitted 2024-03-14, last modified 2024-03-24 | 7 votes, 0.53 popularity | github.com/ndom91/rose-pine-hyprcursor | OK | Approved (already locked D-32; already installed and verified on this machine — `manifest.hl` confirms `name = rose-pine-hyprcursor`) |
| `hypr-dynamic-cursors` | Not a registry package — git-only via hyprpm | Repo created 2024-06-21, pushed 2026-08-06 (3 days before this research), not archived | 691 GitHub stars, 18 open issues, MIT license | github.com/virtcode/hypr-dynamic-cursors | OK | Approved (already locked D-33/D-35; already built and loaded on this machine, 15MB `.so`, matches `hyprctl plugin list` output) |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none — all three have multi-year-old accounts/maintainers, active recent commits, no red flags in `paru -Si`/GitHub metadata

*mpvpaper's AUR `PKGBUILD` was not read line-by-line this session (out of scope for a package already locked by D-23 with prior approval implied by the phase's own AUR_PKGS placement); if the planner wants a stronger guarantee, add a `checkpoint:human-verify` before the `AUR_PKGS` addition lands, consistent with this repo's existing convention for every other AUR package (see the D-16/D-25/D-28/D-33 comments already in `install.sh`).*

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  INTENT SOURCES (each fires an intent, never touches the player)     │
│  picker (commit/hover/Esc) │ theme-apply (login/switch) │ hypridle   │
│  (300s listener) │ gaming-mode-toggle │ motion-switch (motion-scale) │
└────────────────────────────┬───────────────────────────────────────┘
                              │ intent: show <path> | hide | restore
                              ▼
                 ┌─────────────────────────────┐
                 │ wallpaper-visibility.sh       │  ← SOLE owner (D-14)
                 │ (new script, mirrors           │    single-owner pattern
                 │  waybar-visibility.sh shape)   │    already proven in Phase 8
                 └───────────┬─────────────────┘
                              │ start/stop process only —
                              │ NEVER touches mpv's `pause` property (D-29)
                              ▼
                 ┌─────────────────────────────┐
                 │ mpvpaper (uwsm app --)         │
                 │  -p -a full -o "no-audio        │
                 │  loop-file=inf hwdec=auto-safe" │
                 │  layer=background (default)     │
                 │  namespace="mpvpaper" (fixed)   │
                 └───────────┬─────────────────┘
                              │ own internal state machine
                              │ (frame-callback deadman OR
                              │  wlr-foreign-toplevel-mgmt-v1)
                              ▼
                 ┌─────────────────────────────┐
                 │ Hyprland 0.56.2                 │
                 │  ForeignToplevelWlr (compiled-in)│
                 │  sends FULLSCREEN/MAXIMIZED       │
                 │  state via protocol event         │
                 └─────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  FRAME EXTRACTION (separate, synchronous, D-08 repair-on-missing)    │
│  theme-apply wallpaper step → stat() frame path → if absent/0-byte:  │
│  ffmpeg -i <source> -ss <offset> -frames:v 1 -update 1 <dest>.png    │
│  (falls back, no -ss, on failure — output file existence is the      │
│  only reliable success signal; ffmpeg exits 0 even on empty output)  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  DYNAMIC CURSORS (independent subsystem, AMB-02)                     │
│  install.sh: guarded hyprpm add/enable/update (|| echo "⚠..." )      │
│      ↓ (root-owned state store, /var/cache/hyprpm/<user>/...)        │
│  post-login completion helper: hyprpm reload (idempotent-by-design)  │
│      ↓                                                                │
│  hyprland.lua config module: if hl.plugin.dynamic_cursors then         │
│      hl.config({ plugin = { dynamic_cursors = {...} } }) end          │
│  (guarded by hl.get_loaded_plugins() check before hl.plugin.load(),   │
│   since a raw double-load via hyprctl plugin load times out — proven  │
│   live this session)                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | File(s) | Responsibility |
|-----------|---------|-----------------|
| Wallpaper visibility owner | new `hypr/.config/hypr/scripts/wallpaper-visibility.sh` | Single writer of mpvpaper process lifecycle; never touches mpv's `pause` property (D-29) |
| Fullscreen/hide mechanism | mpvpaper's own `-p -a full` flags | Primary hide path — protocol-based, not the frame-callback hack |
| Frame extractor | new script/function inside `theme-engine/lib/wallpaper.sh` or a sibling | ffmpeg invocation, D-08 repair-on-missing guard |
| Cursor plugin provisioning | `install.sh` (guarded block) | Best-effort hyprpm add/update/enable; must never abort the script |
| Cursor plugin completion | new post-login helper (systemd user unit or `theme-init.sh`-adjacent script, per D-33) | Actually finishes the build once a real session/sudo context exists |
| Cursor plugin load | new guarded Lua module under `hypr/.config/hypr/config/` | `hl.plugin.load()` + `if hl.plugin.dynamic_cursors then ... end` config block (D-35) |

### Pattern 1: Single-owner intent arbitration (D-14)

**What:** One script is the only process ever allowed to start/stop the player or send visibility signals; every other actor writes an *intent* file and calls the owner.
**When to use:** Any resource with more than one legitimate trigger for state change (idle, fullscreen, gaming mode, user action).
**Example (from the proven `waybar-visibility.sh`, full file read this session):**
```bash
# Source: hypr/.config/hypr/scripts/waybar-visibility.sh (this repo, read in full this session)
_write_intent() {
    local source="$1" value="$2"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.$source.XXXXXX")"
    printf '%s\n' "$value" > "$tmp" && mv -f "$tmp" "$INTENT_DIR/$source"
}
# CLI contract: waybar-visibility.sh <idle|fullscreen|gaming> <hide|show>
#               waybar-visibility.sh keybind toggle
#               waybar-visibility.sh reassert
#               waybar-visibility.sh status
```
Every publish is unique-temp+mv (atomic), the whole read-modify-write is serialized under a blocking `flock`, and a missing intent file defaults to the safe state ("show"). D-14's new `wallpaper-visibility.sh` should copy this shape wholesale — it is already fault-tested in production (Phase 8).

### Pattern 2: socket2 IPC listener template (D-27, if the fallback watcher becomes necessary)

**What:** A long-running Unix-socket listener translating Hyprland compositor events into owner-script intents.
**Example (from the proven `waybar-fullscreen-watch.sh`, full file read this session — 85 lines total):**
```bash
# Source: hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh (this repo)
SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
if [[ ! -S "$SOCKET_PATH" ]]; then exit 0; fi
exec python3 - "$SOCKET_PATH" "$VISIBILITY_OWNER" <<'PYEOF'
import socket, subprocess, sys
sock_path = sys.argv[1]; owner = sys.argv[2]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try: s.connect(sock_path)
except OSError: sys.exit(0)
...
if text.startswith("fullscreen>>"):
    payload = text[len("fullscreen>>"):]
    if payload == "1": subprocess.run([owner, "fullscreen", "hide"], check=False)
    elif payload == "0": subprocess.run([owner, "fullscreen", "show"], check=False)
PYEOF
```
Confirmed event framing (empirically, Phase 8): `fullscreen>>1` (enter) / `fullscreen>>0` (exit), no other payload. `subprocess.run()` always with an argv list, never a shell string (T-08-20 — compositor-supplied payloads must never reach a shell). If D-27's watcher is built, use this file verbatim as the template per the locked decision — do not host it inside a waybar-named file (D-27's own reasoning).

### Pattern 3: mpvpaper CLI shape — verified via upstream source, not assumption

**What:** Exact flag composition for the mpvpaper invocation, read from `src/main.c` (fetched this session, GhostNaN/mpvpaper, current `master`).

```c
// Source: https://github.com/GhostNaN/mpvpaper/blob/master/src/main.c (fetched this session)
"Example: mpvpaper -vs -a full -o \"no-audio loop\" DP-2 /path/to/video\n"
...
"--auto-pause   -p              Automagically* pause mpv when the wallpaper is hidden\n"
"--auto-mode    -a <mode>       Extend auto-pause/stop to trigger when any window is\n"
"                               <FULL>(fullscreen) | <MAX>(fullscreen/maximized) | <ACTIVE>(currently active)\n"
"--layer        -l <layer>      Specifies shell surface <layer> to run on (default: background)\n"
```

Key facts extracted directly from source, not the man page summary:
- **The layer-shell namespace is the fixed literal string `"mpvpaper"`**, set unconditionally regardless of `--layer` or output `[VERIFIED: src/main.c:932-933, GhostNaN/mpvpaper master, fetched this session — zwlr_layer_shell_v1_get_layer_surface(..., "mpvpaper")]`. This is what `quickshell-doctor`'s `hyprctl layers -j` coexistence assertion (standing constraint #4) should check for.
- **mpvpaper does NOT set `loop`/`loop-file` by default** for a single video — only in slideshow mode (`SLIDESHOW_TIME != 0` auto-sets `loop=yes loop-playlist=yes`) `[VERIFIED: src/main.c:487-489, same fetch]`. The owner's mpvpaper invocation **must** pass `loop` or `loop-file=inf` explicitly via `-o`, or the wallpaper plays once and freezes on the last frame. This matches upstream's own example usage (`-o "no-audio loop"`).
- `-a` requires `-p` (or `-s`) to already be set; passing `-a` alone without `-p`/`-s` is a hard error (`exit(EXIT_FAILURE)`) `[VERIFIED: src/main.c:1330-1339]`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fullscreen/maximize detection for wallpaper hiding | A custom Hyprland IPC poller (D-27's own scope, if needed) | mpvpaper's `-a full`/`-a max`, which consumes the standard `wlr-foreign-toplevel-management-unstable-v1` protocol | Confirmed compiled into Hyprland 0.56.2 (`src/protocols/ForeignToplevelWlr.{hpp,cpp}`) — reinventing this with `hyprctl activewindow` polling duplicates a protocol the compositor already speaks natively |
| Animated-image → static-frame extraction | A GIF/WebP-specific decoder or ImageMagick pipeline | `ffmpeg -i <file> -frames:v 1 -update 1 <out>.png`, uniform across mp4/gif/webp (see Pitfall below) | ffmpeg's libavformat already demuxes all three; a bespoke per-format tool duplicates functionality already in a system dependency this repo already ships |
| Cursor-plugin ABI/build management | A custom compile wrapper around dynamic-cursors' CMake build | `hyprpm` (official, ships inside `hyprland` package) | hyprpm already encodes the exact ABI-pinning hash (commit + 5 library versions) needed to know when a rebuild is required — reimplementing that hash logic is exactly the kind of "deceptively complex problem" this table exists for |

**Key insight:** Every mechanism this phase needs (fullscreen detection, plugin ABI pinning, single-owner arbitration) already exists either upstream (protocol, hyprpm) or in this repo (waybar-visibility.sh's pattern) — the actual engineering work is composition and idempotency guarding, not novel logic.

## Deep-Dive: The Named Open Questions

### 1. D-26 — does mpvpaper's `-p`/`-a` actually pause under Hyprland 0.56.2?

**Two genuinely different mechanisms exist inside mpvpaper, and the CONTEXT.md framing conflates them:**

**Mechanism A — bare `-p` (no `-a`), the "hack" upstream warns about.** A background pthread (`handle_auto_pause`) runs a 2-second deadman-switch timer against `wl_surface` frame-callback delivery (`frame_handle_done`). If the compositor stops calling the frame-callback for 2+ seconds, mpvpaper assumes it's occluded/hidden and pauses `[VERIFIED: src/main.c:159-224 (frame callback wiring), 364-387 (handle_auto_pause), GhostNaN/mpvpaper master, fetched this session]`. Whether Hyprland actually stops scheduling frame callbacks for a fully-occluded background-layer surface is a compositor-internal damage-tracking/occlusion-culling decision this research could **not** verify without a running mpvpaper process — genuinely unverified, matches CONTEXT.md's own caution.

**Mechanism B — `-a full`/`-a max`, combined with `-p`.** This is a **completely separate code path**: it binds `zwlr_foreign_toplevel_manager_v1` and listens for `toplevel_state` events carrying `ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_FULLSCREEN`/`_MAXIMIZED` `[VERIFIED: src/main.c:764-795, same fetch]`. This is a **protocol event**, not a frame-callback heuristic. `check_handle_blocking()` then pauses when any tracked window transitions to blocking `[VERIFIED: src/main.c:732-762]`.

**Hyprland's own side of that protocol was verified at the exact installed commit**, not a generic "wlroots implements this" assumption:
```cpp
// Source: hyprwm/Hyprland src/protocols/ForeignToplevelWlr.cpp
// at commit efb50993780079460b0cbed1363e2166a2de1d9f (== installed v0.56.2, confirmed
// via `hyprctl version`), fetched this session
void CForeignToplevelHandleWlr::sendState() {
    ...
    if (Fullscreen::controller()->isFullscreen(PWINDOW)) {
        if (Fullscreen::controller()->getFullscreenModes(PWINDOW).internal == Fullscreen::FSMODE_FULLSCREEN)
            *p = ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_FULLSCREEN;
        else
            *p = ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_MAXIMIZED;
    }
    m_resource->sendState(&state);
}
```
The header confirming this class is compiled into the installed binary was also read directly: `/usr/include/hyprland/src/protocols/ForeignToplevelWlr.hpp` `[VERIFIED: read this session, ships with the installed hyprland 0.56.2-1 package]`.

**Verdict for the planner:** ship `-p -a full` as the primary/shipping mechanism (source-verified protocol path on both ends, MEDIUM-HIGH confidence — not HIGH, because mpvpaper itself was never run against the live compositor this session). Do **not** carry forward the framing that D-26's whole mechanism is "at best a hack" — that description applies specifically to bare `-p`, which this repo does not need to rely on once `-a full` is added. D-27's fallback watcher stays scoped exactly as locked, as a safety net, not because the primary path is unverified guesswork.

**The exact runtime probe the plan must still run** (this cannot be fully closed without the binary): after `mpvpaper` is installed, launch it with `-p -a full -o "no-audio loop-file=inf"` against a real output and a short test video, then toggle a real window through fullscreen (`hyprctl dispatch fullscreen`) and confirm via `hyprctl plugin`-adjacent introspection or simple visual/CPU observation (`hyprctl clients -j` won't show mpv's pause state — use `ps`/`top` CPU drop, or run mpvpaper with `-v` and watch its own log line `"Pause triggered by: <title>"` which the source prints at `update_mpv_pause_state()`, `src/main.c:296`).

### 2. Animated GIF/WebP end-to-end through mpv

**mpv's image-vs-video classification is not extension-based — it hinges on a single function, read directly from mpv's own demuxer:**
```c
// Source: https://github.com/mpv-player/mpv/blob/master/demux/demux_lavf.c (fetched this session)
static bool is_image(AVStream *st, bool attached_picture, const AVInputFormat *avif)
{
    return st->nb_frames <= 1 && (
        attached_picture ||
        bstr_endswith0(bstr0(avif->name), "_pipe") ||
        strcmp(avif->name, "alias_pix") == 0 ||
        strcmp(avif->name, "gif") == 0 ||
        strcmp(avif->name, "ico") == 0 ||
        strcmp(avif->name, "image2pipe") == 0 ||
        ((st->codecpar->codec_id == AV_CODEC_ID_HEVC || st->codecpar->codec_id == AV_CODEC_ID_AV1)
         && st->nb_frames == 1)
    );
}
```
This was cross-checked locally by generating real multi-frame test files and probing them with the same libavformat mpv links against:
```
$ ffmpeg -f lavfi -i "testsrc=duration=1:size=32x32:rate=5" test.mp4
$ ffmpeg -i test.mp4 test.gif && ffmpeg -i test.mp4 -loop 0 test.webp
$ ffprobe -show_entries stream=nb_frames -of json test.gif   # → "nb_frames": "5"
$ ffprobe -show_entries stream=nb_frames -of json test.webp  # → key ABSENT (unset in AVStream)
$ ffprobe -show_format test.webp                             # → format_name=webp_anim
```
`[VERIFIED: local ffmpeg 9.0 output, this session, scratchpad files at /tmp/claude-1000/.../scratchpad/test.{gif,webp,mp4}]`

Applying `is_image()` to these two real results:
- **Animated GIF**: format name **is** `"gif"` (in the special-case list), but `nb_frames = 5 > 1`, so `nb_frames <= 1` is false → the whole expression is false → **not** classified as an image. Plays as a normal looping video.
- **Animated WebP**: format name is `"webp_anim"` — **not** in the special-case list at all (only `"webp_pipe"`, the single-still-image demuxer, would match the `_pipe` suffix check). The OR expression is unconditionally false regardless of `nb_frames` → **not** classified as an image, unconditionally.

**Verdict:** both animated GIF and animated WebP should be correctly recognized as video streams by mpv (not misclassified into the `--image-display-duration` 5-second-then-stop path), independent of the `-a`/`-p` question above. This is MEDIUM-HIGH confidence — verified via mpv's current `master` source plus a locally-reproduced ffprobe result, but not run through an actual `mpv`/`mpvpaper` binary (not installed this session). **Required plan-time probe:** drop a real animated GIF and a real animated WebP into a `live/` folder and run `mpvpaper -p -a full -o "no-audio loop-file=inf" <output> <file>` for each, watching for continued frame advancement past the first ~1-2 seconds (the exact failure mode this question worries about would look like a frozen first frame).

### 3. Frame extraction (D-08/09/10) — one command shape, verified, with a real divergence found

**The single command shape that works uniformly across mp4/gif/webp, verified locally this session:**
```bash
# Primary attempt (seek to offset — MUST come AFTER -i, not before)
ffmpeg -y -i "<source>" -ss <offset_seconds> -frames:v 1 -update 1 "<dest>.png"

# Fallback (D-09: frame 0)
ffmpeg -y -i "<source>" -frames:v 1 -update 1 "<dest>.png"
```
**The divergence this research found and CONTEXT.md's open question specifically asked about:** placing `-ss` **before** `-i` (the common "fast input-seek" idiom, and the first form tried this session) works for `.mp4` and `.gif` but **silently fails** for animated WebP:
```
$ ffmpeg -ss 0.4 -i test.webp -frames:v 1 -update 1 frame_webp.png
...
Input #0, webp_anim, from 'test.webp':
  Duration: N/A, start: 0.000000, bitrate: N/A
...
[out#0/image2 @ ...] Output file is empty, nothing was encoded(check -ss / -t / -frames parameters if used)
```
`webp_anim` reports `Duration: N/A` — it has no seekable duration for ffmpeg's fast input-seek to target. Moving `-ss` to **after** `-i` (output/decode seeking — ffmpeg decodes from the start and discards frames until the target timestamp) produces a correct PNG for all three input types, reproduced 3× this session (mp4/gif/webp all succeeded with the after-`-i` form).

**A second, independently important finding:** an out-of-range seek offset (past the end of a short clip) **exits 0** with **no output file created** for both mp4 and webp — ffmpeg does not signal failure via exit code for this case:
```
$ ffmpeg -i test.mp4 -ss 10 -frames:v 1 -update 1 frame.png; echo "exit=$?"
exit=0
$ file frame.png
frame.png: cannot open `frame.png' (No such file or directory)
```
`[VERIFIED: local reproduction, this session]`. **This means D-08's "absent or zero-byte" repair-on-missing check is not a defensive nicety — it is the only reliable way to detect this exact silent-failure mode**, since ffmpeg's own exit code cannot be trusted here. The extraction wrapper must check for the destination file's existence and non-zero size after every ffmpeg invocation, and re-run without `-ss` on failure, exactly as D-09 already specifies.

**One command shape suffices** (contrary to the open question's framing that a two-shape split might be needed) — the fix is positional (`-ss` after `-i`), not a per-format branch.

### 4. hyprpm under `install.sh` — toolchain, guard shape, idempotency

**Exact toolchain dependency, extracted verbatim from the installed binary:**
```
$ strings /usr/bin/hyprpm | grep -i "Hyprpm requires"
Hyprpm requires: cmake, cpio, pkg-config, git, g++, gcc
```
`[VERIFIED: this session, /usr/bin/hyprpm is owned by the installed hyprland 0.56.2-1 package]`. Mapped to Arch package names: `cmake`, `cpio`, `pkgconf` (provides `pkg-config`), `git`, `gcc` (provides both `gcc` and `g++`). **`cmake` and `cpio` are the two genuinely missing declarations** — confirmed absent from the full `PACMAN_PKGS` array (read in full, lines 59-218) and from the conditional `git base-devel rustup` bootstrap line (line 374, itself only conditionally run when no AUR helper is already present).

**Correction to `17-CONTEXT.md`'s canonical_refs citation:** the doc cites "`install.sh` §~600-660 — `verify_packages`' hard-fail design and the `|| echo "  ⚠ …"` warn-and-continue precedent D-33 follows" as if both live in the same place. They do not, and `verify_packages()` is explicitly the *opposite* of what D-33 needs:
```bash
# Source: install.sh:619-625 (read in full this session)
# ── verify_packages ───────────────────────────────────
# Hard-fail post-install verification (D-63/D-64/D-65): ... exits nonzero the
# instant any package in the verified set is missing — exactly what would
# have caught the adw-gtk3 ghost. No warn-and-continue path.
verify_packages() { ... exit 1 ... }
```
The **real** warn-and-continue precedent, matching D-33's needs exactly, is the standalone-guard shape used three other places in the same file:
```bash
# Source: install.sh:484, 498, 581, 691 (grepped and read this session)
sudo systemctl enable --now swayosd-libinput-backend.service || echo "  ⚠ swayosd-libinput-backend enable failed" >&2
sudo systemctl enable --now ollama.service || echo "  ⚠ ollama enable failed" >&2
... || echo "  ⚠ linux-modules-cleanup enable failed" >&2
... || echo "  ⚠ kernel module verification FAILED — see above before rebooting" >&2
```
**D-33's guarded hyprpm block must use this `command || echo "  ⚠ ..." >&2` shape as a standalone block, and must NOT be added to `VERIFY_PKGS`** (which would turn a soft, optional-guarded failure into a hard install-abort, defeating criterion 2 entirely).

**Root/sudo requirement, confirmed via live filesystem inspection (not the error message alone):**
```
$ stat /var/cache/hyprpm/aorus       # (and every subdirectory beneath it)
Uid: (    0/    root)   Gid: (    0/    root)   Access: (0755/drwxr-xr-x)
```
`[VERIFIED: this session — the entire hyprpm state tree, including the per-user-named subdirectory, is root-owned]`. hyprpm shells out to `sudo` internally for this. Because `install.sh` already runs many `sudo pacman`/`sudo systemctl` calls before reaching this point, the guarded hyprpm block will very likely inherit a live sudo timestamp — but the plan should place it after another recent `sudo` call (or call `sudo -v` immediately before it) rather than as the very first privileged action, to avoid an unexpected interactive password prompt breaking the "never fails an unattended install" guarantee.

**Idempotency / "already built" detection for the post-login completion helper (D-33):** do **not** re-invoke `hyprctl plugin load <path>` blindly — a live (safe, non-destructive) test this session showed that loading an already-loaded plugin via the raw IPC command **times out** (`Hyprland IPC didn't respond in time`) rather than failing cleanly, though the plugin and compositor remained healthy afterward (`hyprctl plugin list` and `hyprctl monitors` both still responded correctly). **Use `hyprpm reload`** instead — its own stated purpose is exactly "Ensure all enabled plugins are loaded" (i.e., it is designed to be idempotent), rather than a raw `hyprctl plugin load` call.

**ABI-mismatch detection, also extracted verbatim from the binary — a maintenance pitfall not previously documented anywhere in this repo's planning docs:**
```
$ strings /usr/bin/hyprpm | grep -iE "outdated|mismatch|ABI"
Headers version mismatch. Please run hyprpm update to fix those.
ABI is mismatched. Please run hyprpm update to fix that.
Hyprland's ABI changed and some repositories failed to update: no plugins will be loaded until every repository updates successfully.
[hyprpm] Failed to load plugins: Outdated headers. Please run hyprpm update manually.
```
`[VERIFIED: this session]`. **Every Hyprland version bump (even a patch release) risks silently breaking the plugin** until `hyprpm update` is re-run — confirmed by the state-store's own pinning key format, read live: `hash = 'efb50993780079460b0cbed1363e2166a2de1d9f_aq_0.14_hu_0.14_hg_0.5_hc_0.1_hlg_0.6'` (Hyprland commit + aquamarine/hyprutils/hyprgraphics/hyprcursor/hyprlang versions, all five, concatenated) `[VERIFIED: cat /var/cache/hyprpm/aorus/state.toml, this session]`. The completion helper's idempotency check should therefore be "is the plugin loaded AND was it built against the currently-running hash" — not merely "is it loaded" — though implementing an automatic re-provision-on-Hyprland-upgrade path may be more than criterion 2 strictly requires; flagging this as a design input for the planner, not a mandate.

**D-34's forced-failure fault injection** (pointing hyprpm at a bad plugin URL) is directly supported by the `add` subcommand's stated behavior ("Install a new plugin repository from git") — a nonexistent/unresolvable URL fails at the git-clone step inside hyprpm and returns nonzero, which the `|| echo "⚠..."` guard catches cleanly. Not run live this session (would pollute the already-working plugin state on this exact machine), but the mechanism is a plain `git clone` failure, not a special code path — low risk of surprising behavior.

### 5. `hl.plugin.load()` runtime path resolution — proven live

**The Lua config's runtime environment has `os.getenv`/`io` available and working**, proven via a non-mutating probe (writes to `/tmp`, immediately read back and deleted — no config/state touched):
```bash
$ hyprctl eval 'local f = io.open("/tmp/hypr-lua-probe.txt", "w"); f:write(os.getenv("USER") or "NIL"); f:close(); return "done"'
ok
$ cat /tmp/hypr-lua-probe.txt
aorus
```
`[VERIFIED: this session, live probe against the running Hyprland 0.56.2 instance, file cleaned up immediately after]`. This directly answers the open question: **`os.getenv("USER")` resolves the per-user hyprpm cache path correctly** — `/var/cache/hyprpm/" .. os.getenv("USER") .. "/dynamic-cursors/dynamic-cursors.so"` requires no hardcoded username. (Note: `hyprctl eval` always replies `ok` regardless of the actual Lua return value or errors inside the chunk — CONTEXT.md's specifics item #4 already established this; the file-write side-channel is what makes this verifiable at all, not the `ok` reply.)

**The exact path structure, confirmed via live filesystem inspection, not inference:**
```
/var/cache/hyprpm/<username>/<repo-name>/<plugin-artifact-name>.so
# concretely on this machine:
/var/cache/hyprpm/aorus/dynamic-cursors/dynamic-cursors.so
```
`[VERIFIED: find /var/cache/hyprpm/aorus, this session]`. The artifact filename (`dynamic-cursors.so`) is also recorded inside the plugin's own `state.toml` (`filename = 'dynamic-cursors.so'`) if a more robust runtime lookup than string-concatenation is wanted (parse the TOML rather than assume the filename).

**`hl.plugin.load()`'s type signature is intentionally untyped** in the stub — `---@field load fun(...): any` `[VERIFIED: /usr/share/hypr/stubs/hl.meta.lua:950, read this session]` — the Lua-language-server stub gives no argument-shape guidance beyond variadic. No example usage exists anywhere on this machine (`grep -rn "plugin" /usr/share/hypr/*.lua` found nothing beyond the stub itself), and the currently-loaded `dynamic-cursors` plugin on this machine was loaded via `hyprpm` directly (its state shows `enabled = true` with no corresponding `hl.plugin.load()` call anywhere in this repo's config — confirmed via `grep -rln "dynamic.cursor\|hl.plugin" hypr/.config/hypr/` returning nothing). **This means D-35's exact call signature for `hl.plugin.load(path)` is unverified against a real invocation** — the stub confirms the function exists and accepts variadic args, and `hl.get_loaded_plugins()` exists as the companion idempotency check `[VERIFIED: /usr/share/hypr/stubs/hl.meta.lua:843]`, but the plan should budget a real `hyprctl eval` (or config-reload) test of `hl.plugin.load("/var/cache/hyprpm/" .. os.getenv("USER") .. "/dynamic-cursors/dynamic-cursors.so")` at implementation time before trusting the call shape. Given the live double-load timeout risk documented above, this test should be run with the plugin first fully unloaded (`hyprctl plugin unload <path>`, tested clean) — not attempted against the currently-loaded instance again.

### 6. mpvpaper MPRIS suppression — a non-issue, not a suppression job

**mpv has no built-in MPRIS support at all.** MPRIS/D-Bus registration for mpv is provided exclusively through third-party plugins (e.g., `mpv-mpris`), never mpv core `[CITED: web search cross-referencing github.com/hoyon/mpv-mpris and multiple MPRIS-plugin forks, this session — consistent, no contradicting source found]`. Neither `mpvpaper`'s AUR dependency list (`libmpv.so`, `libwayland-client.so`, `libwayland-egl.so`) nor anything else this phase installs pulls in an MPRIS plugin. **D-16's "no MPRIS identity at all" is satisfied automatically by not installing a separate MPRIS script — there is nothing to suppress.**

**Media-key capture is also a non-issue on this platform**, confirmed by reading mpv's own option docs:
```
--input-media-keys=<yes|no>
    ...
    Default: yes (except for libmpv). macOS and Windows only, because elsewhere
    mpv doesn't have a choice - the system decides whether to send media keys
    to mpv. For instance, on X11 or Wayland, system-wide media keys are not
    implemented.
```
`[CITED: mpv-player/mpv DOCS/man/options.rst, master branch, fetched this session]`. `mpvpaper` links `libmpv` (confirmed via `paru -Si mpvpaper`'s `Depends On`), and this option defaults to **no** for libmpv builds regardless of platform. Media keys are handled entirely by the compositor/SwayOSD keybind layer already in this repo, never by mpv.

**Concrete flag composition for D-16, unchanged from the locked decision, now source-confirmed:** `-o "no-audio loop-file=inf hwdec=auto-safe"` — `no-audio` matches upstream's own example usage verbatim; `hwdec=auto-safe` is confirmed a real, documented mpv option value (`"exactly the same as auto"`, safe software fallback) `[CITED: mpv-player/mpv DOCS/man/options.rst line 1391, fetched this session]`.

### 7. mpvpaper layer namespace — for `quickshell-doctor`'s coexistence assertion

**The namespace is the fixed literal string `"mpvpaper"`**, set once in `create_output()` regardless of the `--layer`/`-l` value chosen or which output it runs on:
```c
// Source: src/main.c:932-933, GhostNaN/mpvpaper master, fetched this session
output->layer_surface = zwlr_layer_shell_v1_get_layer_surface(
    output->state->layer_shell, output->surface, output->wl_output, output->state->surface_layer, "mpvpaper");
```
`quickshell-doctor`'s `hyprctl layers -j` coexistence check can assert on the literal namespace `"mpvpaper"` directly — it does not vary per-output (D-22 plays on `'*'`, so multiple layer-surface instances will all share this same namespace string, one per output).

## Runtime State Inventory

> This phase is additive scaffolding, not a rename/refactor/migration — the trigger condition for this section does not apply. Included here only to flag one adjacent, already-known risk: the `/var/cache/hyprpm/<user>/` tree is genuinely host-only, root-owned state that the reproducibility constraint would normally disallow — D-38 already accepts this in spirit ("removal needs sudo, so the sweep warns or prompts rather than acts"). No new host-only state beyond what D-38 already scopes.

## Common Pitfalls

### Pitfall 1: `-ss` before `-i` silently breaks animated WebP frame extraction
**What goes wrong:** ffmpeg exits 0 and produces an empty/missing output file when seeking into an animated WebP with `-ss` placed before `-i`.
**Why it happens:** ffmpeg 9.0's `webp_anim` demuxer reports `Duration: N/A` — no container-level duration for fast input-seeking to target.
**How to avoid:** always place `-ss <offset>` **after** `-i <source>` (output/decode seeking) — verified uniform across mp4/gif/webp this session.
**Warning signs:** a `live/` WebP entry whose extracted frame is always the theme's fallback still, or a lock-screen background that never changes when that WebP is selected.

### Pitfall 2: ffmpeg's exit code 0 on a failed/out-of-range extraction
**What goes wrong:** treating `ffmpeg`'s exit code as the success signal for the extraction step.
**Why it happens:** an out-of-range `-ss` offset produces a genuinely empty output stream, but ffmpeg still exits 0.
**How to avoid:** D-08's "absent or zero-byte" repair-on-missing check is load-bearing, not optional — always verify the destination file exists and has nonzero size after the ffmpeg call, and re-run without `-ss` on failure.
**Warning signs:** a `live/` entry with a per-video seek override recorded past its actual duration would silently degrade with no error anywhere in the pipeline.

### Pitfall 3: mpvpaper does not loop by default
**What goes wrong:** a single-video wallpaper plays once and freezes on the last frame.
**Why it happens:** mpvpaper only auto-sets `loop=yes` in slideshow mode (`-n`); a plain single-file invocation has no default loop behavior.
**How to avoid:** always include `loop` or `loop-file=inf` in the `-o` mpv-options string for every mpvpaper invocation this phase makes.
**Warning signs:** a video wallpaper that "works" during the first watch but is frozen an hour later.

### Pitfall 4: re-invoking `hyprctl plugin load` on an already-loaded plugin can hang the IPC call
**What goes wrong:** a naive "just call load every time" idempotency strategy for D-33's completion helper risks an IPC timeout.
**Why it happens:** observed live this session — loading an already-loaded plugin path a second time via raw `hyprctl plugin load <path>` returned `Hyprland IPC didn't respond in time` rather than a clean "already loaded" error (though the compositor itself remained healthy afterward).
**How to avoid:** check `hl.get_loaded_plugins()` (from Lua) or `hyprctl plugin list` (from the shell completion helper) before ever calling load; prefer `hyprpm reload` (its own stated purpose is idempotent "ensure loaded") over a raw `hyprctl plugin load`.
**Warning signs:** a post-login helper that "usually works" but occasionally hangs the compositor's IPC socket for other callers momentarily.

### Pitfall 5: hyprpm's plugin build silently breaks on every Hyprland version bump
**What goes wrong:** dynamic-cursors works today, then silently stops loading after a routine `pacman -Syu` that bumps `hyprland`.
**Why it happens:** hyprpm pins plugin builds to an exact hash of the Hyprland commit + 5 library versions (`aquamarine`, `hyprutils`, `hyprgraphics`, `hyprcursor`, `hyprlang`) — any change to that hash requires `hyprpm update` to rebuild, and the binary's own error strings confirm this fails silently until then ("no plugins will be loaded until every repository updates successfully").
**How to avoid:** this is a genuine maintenance-burden design question for the planner (an automatic post-upgrade `hyprpm update` hook is more than criterion 2 strictly requires) — at minimum, document that a stale-plugin symptom after a system update is expected, not a regression, and the fix is `hyprpm update`.
**Warning signs:** dynamic cursor deformation stops working after any `pacman -Syu` that touches `hyprland`, with no error visible anywhere except `journalctl`/Hyprland's own log.

### Pitfall 6: `env.lua:9` is a third, previously undocumented cursor-theme hardcode site
**What goes wrong:** D-32 (context) names only `theme-engine/lib/generate.sh:166,171` as needing the cursor-theme rename; a third site was missed.
**Why it happens:** `hypr/.config/hypr/config/env.lua:9` independently hardcodes `hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")` — this is the actual runtime `XCURSOR_THEME` environment variable Hyprland exports to every client (and which `autostart.lua:20-21` re-exports into `systemctl --user import-environment`/`dbus-update-activation-environment`), independent of the two GTK `settings.ini` render targets.
**How to avoid:** D-32's implementation must update all three sites: `generate.sh:166`, `generate.sh:171`, and `env.lua:9`.
**Warning signs:** GTK apps correctly show the new cursor theme (from `generate.sh`'s render) while native Wayland/XWayland clients reading `$XCURSOR_THEME` directly still show Bibata — a split-brain cursor theme.
`[VERIFIED: hypr/.config/hypr/config/env.lua:9, read this session — verbatim: hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")]`

### Pitfall 7: `theme-init.sh`'s unconditional `awww img` call at login
**What goes wrong:** at login, `theme-init.sh` always calls `awww img "$WALLPAPER"` (line 14-19) before `theme-apply` runs — if `current.jpg` at that moment points at a live wallpaper's extracted frame (per D-06/D-07), this briefly shows the static frame via awww before theme-apply's wallpaper step later swaps in the live mpvpaper player.
**Why it happens:** `theme-init.sh` predates this phase and is documented as the thin D-21 caller; its own `awww img` call was written when `current.jpg` only ever pointed at genuinely static images.
**How to avoid:** not a functional bug (the sequence self-corrects within theme-apply's own wallpaper step, matching D-21's design) — but the planner/executor should expect and not be alarmed by a brief static-frame flash before the video wallpaper starts at login, and should confirm this ordering explicitly during the phase's render-and-look gate rather than treating it as a regression.
**Warning signs:** a login screenshot taken too early "looks wrong" (static frame instead of playing video) when the pipeline is actually working correctly and just hasn't reached theme-apply's wallpaper step yet.
`[VERIFIED: hypr/.config/hypr/scripts/theme-init.sh, read in full this session]`

## Code Examples

### ffmpeg frame extraction (D-08/09/10), uniform across all input types
```bash
# Source: verified locally this session (ffmpeg 9.0, official Arch package)
extract_frame() {
    local source="$1" dest="$2" offset="${3:-}"
    local ok=0

    if [[ -n "$offset" ]]; then
        ffmpeg -y -i "$source" -ss "$offset" -frames:v 1 -update 1 "$dest" &>/dev/null
        [[ -s "$dest" ]] && ok=1   # existence + nonzero size — ffmpeg's exit code is NOT trustworthy here
    fi

    if [[ "$ok" -ne 1 ]]; then
        ffmpeg -y -i "$source" -frames:v 1 -update 1 "$dest" &>/dev/null
        [[ -s "$dest" ]] && ok=1
    fi

    [[ "$ok" -eq 1 ]]
}
```

### mpvpaper invocation composed from every locked decision + this session's findings
```bash
# Source: composed from D-15/16/22/24/29 (locked) + this session's verified findings
# (loop-file required explicitly; -a full is the protocol-based hide path, not the hack)
uwsm app -- mpvpaper -p -a full -o "no-audio loop-file=inf hwdec=auto-safe" '*' "$LIVE_WALLPAPER_PATH"
```

### hl.plugin.load guarded module skeleton (D-35) — call shape flagged unverified, structure is not
```lua
-- Illustrative skeleton only — hl.plugin.load()'s exact argument shape (path string vs.
-- table) was not verified live this session (see Deep-Dive #5); confirm at implementation
-- time with the plugin first unloaded, per the double-load timeout risk documented above.
local user = os.getenv("USER") or os.getenv("LOGNAME")
if user then
    local plugin_path = "/var/cache/hyprpm/" .. user .. "/dynamic-cursors/dynamic-cursors.so"
    local already_loaded = false
    for _, p in ipairs(hl.get_loaded_plugins()) do
        if p.name == "dynamic-cursors" then already_loaded = true end
    end
    if not already_loaded then
        pcall(hl.plugin.load, plugin_path)  -- pcall: never let a missing/broken plugin abort config load
    end
end

if hl.plugin.dynamic_cursors then
    hl.config({
        plugin = {
            dynamic_cursors = {
                enabled = true,
                mode = "tilt",       -- D-37: fixed at plugin load time, not runtime-switchable
                shake = { enabled = false },  -- D-36: ships disabled, default threshold too sensitive
            },
        },
    })
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `hyprctl keyword` for runtime Hyprland config changes | `hyprctl eval` (Lua `hl.config()`/dispatchers) | Already migrated in this repo (Phase 13.1) | Not new to this phase, but relevant: any wallpaper-owner script that needs to touch compositor state at runtime must use `eval`, never `keyword` (already-known repo convention, re-confirmed applicable here) |
| Assuming Walker/mpv-adjacent tools register MPRIS by default | mpv core ships with zero MPRIS; requires an explicit third-party plugin | N/A — has always been true of mpv, just newly confirmed for this phase | D-16 is satisfied by omission, not suppression |

**Deprecated/outdated:** none directly relevant to this phase's stack — mpvpaper, ffmpeg 9.0, and hyprpm/Hyprland 0.56.2 are all current.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | mpv's `is_image()` classification logic (verified against `master` branch) matches whatever mpv version `mpvpaper`'s AUR build actually links against | Deep-Dive #2 | If mpvpaper pins an older/vendored mpv or libmpv with different classification logic, animated WebP could still misclassify as a static image — mitigated by the required runtime probe already specified |
| A2 | `hl.plugin.load()`'s exact argument shape (bare path string vs. a table) | Deep-Dive #5, Code Examples | If the real signature differs, the guarded Lua module's `pcall` wrapper prevents a config-load crash, but the plugin simply won't load — degrades gracefully per AMB-02's own requirement, but needs a real test before being trusted |
| A3 | Placing the guarded hyprpm block in `install.sh` after another `sudo`-requiring step is sufficient to avoid an unattended password prompt | Deep-Dive #4 | If the sudo timestamp has expired by the time the block runs (long-running earlier sections), the hyprpm sudo call could hang/prompt — mitigated by an explicit `sudo -v` immediately before the block, which the planner should add regardless |
| A4 | mpv has zero built-in MPRIS support (no core registration path at all, confirmed via websearch cross-referencing multiple third-party plugin project pages, not mpv's own source) | Deep-Dive #6 | If a distro-patched or AUR-vendored mpv/libmpv build enables an undocumented MPRIS path, D-16 would need an explicit suppression flag rather than relying on omission — low risk, but not source-verified the way the other findings are |

**Note:** every other substantive claim in this document is tagged `[VERIFIED: ...]` or `[CITED: ...]` inline at the point of use, per this phase's own "verify against the installed binary, not memory" method discipline.

## Open Questions

1. **`hl.plugin.load()`'s exact call signature**
   - What we know: the function exists, accepts variadic args, and `hl.get_loaded_plugins()` exists as its idempotency companion.
   - What's unclear: whether it takes a bare path string, a table, or something else — no example exists anywhere on this machine or in this repo.
   - Recommendation: budget a real `hyprctl eval` test at implementation time (plugin unloaded first, to sidestep the double-load timeout risk), before trusting the skeleton in Code Examples above.

2. **Whether bare `-p` (no `-a`) is ever needed as a distinct fallback tier**
   - What we know: `-a full` uses the protocol path, not the frame-callback hack.
   - What's unclear: whether there's a scenario (e.g., a window covering the wallpaper without being fullscreen/maximized, i.e. a normal floating/tiled window) where D-26 wants *some* pause behavior and only bare `-p`'s frame-callback heuristic could provide it — CONTEXT.md itself flags "base auto-pause misses a normal window fully covering the wallpaper" as a known gap of `-a` alone.
   - Recommendation: confirm with the user during planning whether "a normal window covering the wallpaper" needs to pause it too (out of AMB-01's literal fullscreen-only wording, but worth a discretion check) — if yes, `-a max` (not `full`) plus D-27's fallback watcher become more load-bearing; if the literal fullscreen-only wording is authoritative, `-a full` alone is sufficient and D-27 stays a pure safety net.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mpvpaper` | AMB-01 (D-04, D-23 hard dependency) | ✗ (AUR-only, confirmed `pacman -Si` fails) | — | None — D-23 already accepts this as a hard `AUR_PKGS` dependency; no fallback player in scope |
| `mpv`/`libmpv` | AMB-01 (mpvpaper's runtime dependency) | ✗ | — | Pulled in transitively by `mpvpaper`'s AUR `Depends On: libmpv.so` |
| `ffmpeg` | AMB-01 (D-08/09/10 frame extraction) | ✓ | n9.0 | — |
| `socat` | Discretion item (IPC client, D-27 if built) | ✗ | — | `python3` (installed, 3.14.6-1) + stdlib sockets — already the established convention |
| `cmake` | AMB-02 (hyprpm build toolchain) | ✓ (already installed, likely a side effect of this project's own prior live verification, not `install.sh`) | 4.4.2-1 | None — must be added to `PACMAN_PKGS` for reproducibility on a fresh machine |
| `cpio` | AMB-02 (hyprpm build toolchain) | ✓ (present only as a transitive dep of `debugedit`/`dracut`/`virt-install`) | 2.15-3 | None — must be added to `PACMAN_PKGS` for reproducibility |
| `hyprpm` | AMB-02 | ✓ (ships inside `hyprland` package) | bundled with hyprland 0.56.2-1 | — |
| `rose-pine-hyprcursor` | D-32 (folded scope) | ✓ (already installed this project's own prior session) | v0.3.2.r0.d2c0e680-1 | — |
| `hypr-dynamic-cursors` plugin | AMB-02 | ✓ (already built and loaded on this dev machine) | 0.1 (per `hyprctl plugin list`) | Graceful degradation to stock cursor is the entire point of AMB-02 |

**Missing dependencies with no fallback:** `mpvpaper`/`libmpv` — already accepted as a hard AUR dependency by the already-locked D-23; no action needed beyond ensuring `install.sh` actually adds it.

**Missing dependencies with fallback:** none beyond what's already noted above (socat → python3, already the established pattern).

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1` (from `.planning/config.json`) — included per the mandatory trigger.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth surface in this phase |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Yes | `wallpaper.sh`'s existing T-05-07 path validator (`"$recorded" != */*`) must be **widened, not removed**, per D-12's own instruction, to admit exactly `live/<name>` while still rejecting arbitrary path traversal — see Pitfall below |
| V6 Cryptography | No | — |
| V10 Malicious Code (supply chain) | Yes | Package Legitimacy Audit above (mpvpaper, rose-pine-hyprcursor, hypr-dynamic-cursors) — all three cross-checked against `paru -Si`/GitHub metadata this session, all clean |
| V12 File and Resources | Yes | Frame-extraction script writes to a fixed, engine-owned path under `~/.local/state/theme/` (D-07) — never derives the destination path from wallpaper-selection user input beyond the already-validated recorded choice |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via a crafted `last-wallpaper` state-file entry (e.g. `live/../../etc/passwd` or an absolute path) once D-12 widens the `*/*` rejection to admit `live/<name>` | Tampering / Information Disclosure | The widened validator must still reject `..` segments and anything not matching `^live/[^/]+$` exactly (a single path component after the `live/` prefix, no further nesting) — do not merely relax the existing `*/*` check to "starts with live/", validate the full shape |
| Compositor-supplied event payloads reaching a shell (D-27's fallback watcher, if built) | Tampering / Elevation of Privilege | Already the established, proven mitigation in `waybar-fullscreen-watch.sh`: every `subprocess.run()` call uses an argv list, never `shell=True` or string interpolation — the new watcher must copy this verbatim, not re-derive it |
| A malicious/typosquatted git URL substituted for `hypr-dynamic-cursors` during D-34's fault-injection testing, if the "bad URL" used for testing is ever left live in a committed config | Spoofing / Tampering | D-34's fault-injection URL must be a plan-time-only test value, never committed as the real plugin source; the real `hl.config` plugin block must reference the verified `github.com/virtcode/hypr-dynamic-cursors` URL only |
| Root-owned `/var/cache/hyprpm/<user>/*.so` artifact loaded at runtime via `hl.plugin.load()` | Tampering | Standard hyprpm trust model (already accepted by using hyprpm at all) — no additional mitigation in scope beyond what D-38's cut-sweep already covers (sweep warns/prompts on host-only sudo-owned state rather than silently leaving it) |

## Sources

### Primary (HIGH confidence — read directly this session, exact installed versions/commits)
- `hypr/.config/hypr/scripts/waybar-visibility.sh` (this repo, read in full)
- `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` (this repo, read in full)
- `hypr/.config/hypr/scripts/theme-init.sh` (this repo, read in full)
- `hypr/.config/hypr/config/env.lua` (this repo, grepped and confirmed)
- `hypr/.config/hypr/hyprland.lua` (this repo, read for cursor block context)
- `theme-engine/.config/theme-engine/lib/wallpaper.sh` (this repo, read in full)
- `theme-engine/.config/theme-engine/lib/contract.sh` (this repo, read §1-70)
- `theme-engine/.config/theme-engine/contract.json` (this repo, read in full)
- `theme-engine/.config/theme-engine/lib/generate.sh` §155-173 (this repo)
- `install.sh` §59-342 (PACMAN_PKGS/AUR_PKGS), §590-672 (verify_packages, warn-and-continue precedents) (this repo)
- `stow.sh` §440-464 (current.jpg seed) (this repo)
- `hypr/.config/hypr/hyprlock.conf` (grepped for `current.jpg`)
- `hypr/.config/hypr/hypridle.conf` (grepped for listener thresholds)
- `theme-engine/.config/theme-engine/lib/motion.sh` (grepped for motion-scale state path)
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` (grepped for state file)
- `/usr/share/hypr/stubs/hl.meta.lua` (installed with hyprland 0.56.2-1; read §480-960, §1314-1335)
- `/usr/include/hyprland/src/protocols/ForeignToplevelWlr.hpp` (installed with hyprland 0.56.2-1, read in full)
- `github.com/hyprwm/Hyprland` `src/protocols/ForeignToplevelWlr.cpp` at commit `efb50993780079460b0cbed1363e2166a2de1d9f` (== installed v0.56.2, fetched this session)
- `github.com/GhostNaN/mpvpaper` `src/main.c` (master branch, fetched this session, ~1517 lines, read in relevant full sections)
- `github.com/mpv-player/mpv` `demux/demux_lavf.c` and `DOCS/man/options.rst` (master branch, fetched this session)
- Live, non-mutating system probes this session: `pacman -Si`/`paru -Si` for mpvpaper/rose-pine-hyprcursor/hypr-dynamic-cursors; `strings /usr/bin/hyprpm`; `stat`/`find` on `/var/cache/hyprpm/aorus`; `cat` on live `state.toml` files; `hyprctl version`/`plugin list`/`eval` (one write-then-cleanup probe, one accidental double-load timeout, both non-destructive); local `ffmpeg`/`ffprobe` generation and probing of synthetic mp4/gif/webp test files

### Secondary (MEDIUM confidence)
- GitHub API repo metadata for `virtcode/hypr-dynamic-cursors` and `GhostNaN/mpvpaper` (stars, last-push date, archived status) — fetched this session via `api.github.com`

### Tertiary (LOW confidence)
- WebSearch cross-referencing mpv's lack of built-in MPRIS support (no single authoritative mpv-project statement found, but consistent across every third-party MPRIS-plugin project's own README framing) — see Assumption A4

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every package version/existence claim verified via `pacman`/`paru`/`ffmpeg -version` this session
- Architecture (mechanism selection): MEDIUM-HIGH — source-verified on both mpvpaper's and Hyprland's side at the exact installed versions, but never run end-to-end against a live `mpvpaper` process (not installed)
- Pitfalls: HIGH — every pitfall in this document was either reproduced locally this session (ffmpeg seek behavior, ffmpeg exit-code-0 failure, plugin double-load timeout) or read directly from source at the exact installed version

**Research date:** 2026-08-09
**Valid until:** 2026-09-08 (30 days) for the repo-internal findings; the mpvpaper/Hyprland protocol findings should be re-checked if either `hyprland` or `mpvpaper` receives a version bump before implementation, since they were verified at exact pinned versions/commits, not against a version range
