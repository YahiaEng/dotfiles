# Phase 17: Ambient Extras - Pattern Map

**Mapped:** 2026-08-09
**Files analyzed:** 11 (new/modified)
**Analogs found:** 11 / 11

**Correction inherited from RESEARCH.md (overrides CONTEXT.md canonical_refs):** `install.sh`'s `verify_packages()` (§~600-660) is explicitly **hard-fail-only** ("No warn-and-continue path" — its own comment) and is **NOT** the D-33 precedent. The real warn-and-continue precedent is the standalone `command || echo "  ⚠ ..." >&2` guard shape at `install.sh:484,498,581,691` (swayosd-libinput-backend, ollama, linux-modules-cleanup, kernel-module-verify). D-33's guarded hyprpm block must copy that shape and must **never** be added to `VERIFY_PKGS`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `hypr/.config/hypr/scripts/wallpaper-visibility.sh` (new) | controller / state-owner script | event-driven (intent arbitration) | `hypr/.config/hypr/scripts/waybar-visibility.sh` | exact |
| `hypr/.config/hypr/scripts/wallpaper-fullscreen-watch.sh` (new, D-27 fallback only) | service / long-running listener | streaming (socket2 IPC) | `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` | exact (explicit template, not host, per D-27) |
| `theme-engine/.config/theme-engine/lib/wallpaper.sh` (modified — extend autoset, add `live/` pass, widen validator) | service / utility | CRUD (state file read/write) + file-I/O | itself (existing file, extend in place) | exact |
| new frame-extraction function (D-08/09/10), likely `theme-engine/.config/theme-engine/lib/wallpaper.sh` or sibling `lib/wallpaper-frame.sh` | utility | file-I/O (subprocess: ffmpeg) | `wallpaper.sh`'s `theme_engine_wallpaper_autoset` (best-effort `\|\| true` idiom) + RESEARCH.md's verified `extract_frame()` code example | exact (idiom), new capability (no direct ffmpeg analog in repo) |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` (modified — merged live/ enumeration, marker glyph, hover-debounce, Esc-restore-via-owner) | controller / interactive picker | request-response (fzf) + event-driven (hover) | itself (existing file, extend in place); enumeration sub-pattern from `wp-enum.sh` block inside it | exact |
| `theme-engine/.config/theme-engine/contract.json` (modified — add engine-owned frame entry) | config / manifest | CRUD | itself (existing file, extend `engine_owned_files` array) | exact |
| `theme-engine/.config/theme-engine/lib/contract.sh` (read-only reference, no change expected — `contract_engine_owned_files()` already generic) | service / library | CRUD | itself | exact (no modification needed, just consumption) |
| `hypr/.config/hypr/hypridle.conf` (modified — extend existing 300s listener's `on-timeout`/`on-resume`) | config | event-driven | itself, `waybar-visibility.sh idle hide/show` binding already at the 120s listener (lines 51-55) | exact |
| `install.sh` (modified — `PACMAN_PKGS` += cmake/cpio; `AUR_PKGS` += mpvpaper (hard), rose-pine-hyprcursor; new guarded hyprpm block) | config / install script | batch (provisioning) | itself — `AUR_PKGS` array (§270-342) for the hard deps; `install.sh:484/498/581/691` guard shape for the soft hyprpm block | exact |
| new post-login completion helper (D-33, e.g. `hypr/.config/hypr/scripts/hyprpm-complete.sh` or systemd user unit) | service | batch (one-shot, idempotent) | `theme-init.sh` (thin login-caller shape) for placement/invocation convention; no direct behavioral analog (novel: `hyprpm reload`) | role-match |
| new guarded Lua config module (D-35, e.g. `hypr/.config/hypr/config/dynamic-cursors.lua`) | config / provider | event-driven (config-load-time) | `hypr/.config/hypr/config/env.lua` (small, single-purpose Lua config module) + RESEARCH.md's verified skeleton | role-match |
| `theme-engine/.config/theme-engine/lib/generate.sh` (modified — cursor-theme pin, lines 166,171) | service / render function | CRUD (template render) | itself (existing file, extend in place) | exact |
| `hypr/.config/hypr/config/env.lua` (modified — `XCURSOR_THEME` pin, line 9, Pitfall 6) | config | CRUD (static env declaration) | itself (existing file, one-line edit) | exact |

## Pattern Assignments

### `hypr/.config/hypr/scripts/wallpaper-visibility.sh` (new owner script)

**Analog:** `hypr/.config/hypr/scripts/waybar-visibility.sh` (copy wholesale per D-14; full file already read above — 337 lines)

**Structural pattern to copy verbatim:**
- CLI contract as a comment block up top: `<source> <hide|show>` verbs, `reassert`, `status` — same shape, sources become `{picker, theme-apply, idle, gaming, motion}` instead of `{idle, fullscreen, gaming, keybind}`.
- Per-source intent files under a `~/.cache/<owner>.d/` dir, one atomic file per source:
```bash
_write_intent() {
    local source="$1" value="$2"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.$source.XXXXXX")"
    printf '%s\n' "$value" > "$tmp" && mv -f "$tmp" "$INTENT_DIR/$source"
}
_read_intent() {
    local source="$1"
    cat "$INTENT_DIR/$source" 2>/dev/null || echo "show"
}
```
- Blocking `flock` around the whole compute→actuate critical section (`_acquire_lock`, fd 8), so concurrent intents from picker/idle/gaming/motion never interleave:
```bash
_acquire_lock() {
    exec 8>"$LOCK_FILE" || return 0
    flock 8 2>/dev/null || true
}
```
- Compute → actuate split: `_compute` derives a `BASE_UNION`/`STATUS` purely from intent files (missing file defaults to "show" = safe), `_actuate` only signals/spawns when the target differs from `.actuated` (absorb redundant calls), except `reassert` which always re-actuates.
- **Deviation required by D-29:** unlike waybar-visibility.sh's SIGUSR1/SIGUSR2 signal actuation, this owner's actuation is process start/stop of `mpvpaper` via `uwsm app --` (D-15) — it must **never** touch mpv's `pause` IPC property (there is none — D-29 removes the IPC socket entirely). Model actuation states as `{running, stopped}` (mapped from D-25's hide semantics: hide happens *inside* mpvpaper via `-p -a full`, this owner's own hide/show verbs are for the harder states: theme-switch restart, idle, gaming, reduced-motion — D-28/D-30/D-31).
- The `reassert` verb has a direct reuse: `theme-apply`'s wallpaper step should call `reassert` the same way `reload.sh` calls waybar-visibility's `reassert` after SIGUSR2, so a theme switch can never desync the owner's process state from the newly-selected wallpaper.

---

### `hypr/.config/hypr/scripts/wallpaper-fullscreen-watch.sh` (new, D-27 fallback only — build only if the `-p -a full` runtime probe in RESEARCH.md Deep-Dive #1 fails)

**Analog:** `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` (full file above — 85 lines) — **explicit template per D-27, do not host inside a waybar-named file.**

**Copy verbatim:**
- Headless/no-session guard before touching the socket:
```bash
if [[ -z "${XDG_RUNTIME_DIR:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    exit 0
fi
SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
if [[ ! -S "$SOCKET_PATH" ]]; then
    exit 0
fi
```
- Inline python3-stdlib-only socket listener (no `socat` — confirmed not installed by both CONTEXT.md discretion note and RESEARCH.md Environment Availability):
```python
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
```
- **Security-critical, copy exactly:** every `subprocess.run()` call uses an argv **list**, never a shell string — compositor-supplied payloads must never reach a shell (T-08-20, restated in RESEARCH.md's Security Domain table).
- Owner target changes from `VISIBILITY_OWNER="$HOME/.config/hypr/scripts/waybar-visibility.sh"` to the new `wallpaper-visibility.sh`, verbs become `fullscreen hide`/`fullscreen show` against that owner instead.

---

### `theme-engine/.config/theme-engine/lib/wallpaper.sh` (modify — extend, don't replace)

**Analog:** itself, `theme_engine_wallpaper_autoset` (full function read above — 86 lines)

**Patterns to extend, not replace:**
- Enumeration idiom (D-03's separate `live/` pass, keep image pool at maxdepth 1 unchanged):
```bash
local images
images=$(find "$theme_dir" -maxdepth 1 \
    -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
    ! -name "current.jpg" \
    -printf "%f\n" 2>/dev/null | sort)
# NEW: separate pass, D-03 — live/ gets its own maxdepth-1 enumeration under
# "$theme_dir/live", merged into the picker's list but never folded into
# $images above (that would defeat D-03's still-vs-live separation).
```
- **T-05-07 validator — widen precisely per D-12, do not remove:**
```bash
# BEFORE (current code, line 52):
if [[ -n "$recorded" && "$recorded" != */* && -f "$theme_dir/$recorded" ]]; then
# AFTER (D-12 + Security Domain V5 — admit exactly `live/<name>`, single
# component, no traversal — RESEARCH.md's own recommended shape):
if [[ -n "$recorded" ]] && \
   { [[ "$recorded" != */* && -f "$theme_dir/$recorded" ]] || \
     [[ "$recorded" =~ ^live/[^/]+$ && -f "$theme_dir/$recorded" ]]; } ; then
```
- Best-effort `|| true` on every step, never fail `theme-apply`'s exit code — copy this discipline into the new frame-extraction call site and D-13's dead-entry fallback (mirrors the function's own existing "fall back to first sorted image" logic, D-13 extends this to live wallpapers).
- Atomic temp+mv write-back idiom (`last_used_file.tmp` → `mv`) — reuse for any new state write this phase adds (e.g. per-video seek-offset override, D-09).

---

### Frame extraction (D-08/09/10) — new capability inside `wallpaper.sh` or a sibling lib file

**Analog:** no direct repo analog (novel ffmpeg subprocess) — use RESEARCH.md's locally-verified code example directly, wrapped in the repo's best-effort idiom from `wallpaper.sh` above.

```bash
# Source: RESEARCH.md Code Examples section, verified locally this session
# (ffmpeg 9.0) — -ss MUST come after -i, existence+size is the only
# trustworthy success signal (ffmpeg exits 0 on empty output).
extract_frame() {
    local source="$1" dest="$2" offset="${3:-}"
    local ok=0
    if [[ -n "$offset" ]]; then
        ffmpeg -y -i "$source" -ss "$offset" -frames:v 1 -update 1 "$dest" &>/dev/null
        [[ -s "$dest" ]] && ok=1
    fi
    if [[ "$ok" -ne 1 ]]; then
        ffmpeg -y -i "$source" -frames:v 1 -update 1 "$dest" &>/dev/null
        [[ -s "$dest" ]] && ok=1
    fi
    [[ "$ok" -eq 1 ]]
}
```
D-07's `ln -sfr` repoint mirrors `wallpaper.sh`'s existing `ln -sfr "$theme_dir/$chosen" "$WALLPAPER_DIR/current.jpg"` line verbatim — same idiom, new target (the extracted PNG under `~/.local/state/theme/`, not a wallpaper file directly).

---

### `theme-engine/.config/theme-engine/contract.json` (modify)

**Analog:** itself — `engine_owned_files` array (lines 35-47)

```json
"engine_owned_files": [
    "logs",
    "last-wallpaper",
    "current-theme",
    ".last-render-error.log",
    "icon-theme",
    "font-choice",
    "walker-relaunch.log",
    "waybar-visibility.css",
    "motion-scale",
    "weather.json",
    "weather-cache.json"
    // ADD (D-07): the extracted-frame filename, e.g. "wallpaper-frame.png"
]
```
This is the exact bucket D-07 specifies — confirmed by `contract.sh`'s own comment: "files/directories written by something OTHER than a matugen render pass ... that must survive commit.sh's rsync --delete." No changes needed to `contract.sh` itself — `contract_engine_owned_files()` (lines 51-53) is already generic and will pick up the new entry automatically; `commit.sh`'s `--exclude` flags and `theme-doctor`'s state-manifest gate both read this same array by design (D-07's whole rationale).

---

### `hypr/.config/hypr/hypridle.conf` (modify — D-30, hook the existing 300s listener)

**Analog:** itself — the 120s waybar-idle listener (lines 51-55) as the structural template, extended onto the existing 300s dim listener (lines 57-62)

```
# EXISTING (300s dim listener, lines 57-62):
listener {
    timeout = 300
    on-timeout = brightnessctl -s set 30%
    on-resume = brightnessctl -r
}
# D-30: add a second command per direction (Hyprland supports one
# on-timeout/on-resume string per listener block — CONTEXT.md doesn't
# specify multi-command chaining; verify hypridle's on-timeout accepts
# `cmd1 ; cmd2` shell chaining, or add a small wrapper script, at
# implementation time). Mirrors the 120s block's direct owner-script call:
on-timeout = ~/.config/hypr/scripts/wallpaper-visibility.sh idle hide
on-resume = ~/.config/hypr/scripts/wallpaper-visibility.sh idle show
```
Note D-30's own reasoning: do NOT use the 120s listener (owner *stops* the process, not merely pauses — a 2-minute threshold would cause thrashing on brief typing pauses).

---

### `install.sh` (modify — three separate concerns)

**Analog:** itself — `AUR_PKGS` array (lines 270-342, full block read above) for hard deps; the standalone guard shape at lines 484/498/581/691 for the soft hyprpm block.

**1. `PACMAN_PKGS` additions (toolchain gap, RESEARCH.md-verified):**
```bash
# ADD to PACMAN_PKGS (not currently declared — verified via grep of the
# full array this session):
cmake
cpio
```

**2. `AUR_PKGS` additions (hard, D-23/D-32 — copy the array's existing comment-header-per-group convention):**
```bash
AUR_PKGS=(
    # Rice
    matugen-bin
    mpvpaper          # D-23: hard dependency — live wallpaper playback
    ...
    # Cursor theme (D-32)
    rose-pine-hyprcursor
    ...
)
```

**3. Guarded hyprpm block (D-33/D-34 — copy this exact shape, verbatim structure, from the real precedent, NOT from `verify_packages()`):**
```bash
# Source: install.sh:484 (swayosd precedent) — the actual warn-and-continue
# idiom this repo uses, corrected from CONTEXT.md's wrong citation of
# verify_packages() (which is hard-fail-only, per its own comment at
# install.sh:619-625).
sudo -v   # RESEARCH.md A3: refresh sudo timestamp immediately before, to
          # avoid an unattended interactive password prompt if the earlier
          # sudo timestamp has expired by this point in the script.
echo "Installing hypr-dynamic-cursors plugin (optional)..."
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors || echo "  ⚠ hyprpm add dynamic-cursors failed" >&2
hyprpm enable dynamic-cursors || echo "  ⚠ hyprpm enable dynamic-cursors failed" >&2
hyprpm update || echo "  ⚠ hyprpm update (dynamic-cursors) failed — see above" >&2
```
**Must NOT be added to `VERIFY_PKGS`** (RESEARCH.md's explicit correction — that would turn a soft/optional failure into a hard install-abort, defeating AMB-02's own criterion).

---

### Post-login completion helper (D-33 — new file, placement per Claude's Discretion)

**Analog:** `hypr/.config/hypr/scripts/theme-init.sh` (full file read above, 21 lines) — thin, single-purpose login-time caller shape (read state → conditionally act → exec next stage).

```bash
#!/usr/bin/env bash
# Mirrors theme-init.sh's "thin caller" shape: read state, best-effort act,
# never block startup. Idempotency per RESEARCH.md Pitfall 4: use
# `hyprpm reload` (its own stated purpose is "ensure loaded" — idempotent
# by design), NEVER a raw `hyprctl plugin load` on an already-loaded
# plugin (times out per the live-verified finding in RESEARCH.md Deep-Dive #4).
hyprpm reload 2>/dev/null || true
```
Invocation point (autostart.lua carries a documented no-new-entries prohibition per D-15/D-35, so this must be wired as a systemd `--user` oneshot unit or chained from an already-permitted entry point — resolve at implementation time).

---

### New guarded Lua config module (D-35 — e.g. `hypr/.config/hypr/config/dynamic-cursors.lua`)

**Analog:** `hypr/.config/hypr/config/env.lua` (full file read above, 12 lines) for the small-single-purpose-module shape + placement convention (`hypr/.config/hypr/config/*.lua`); RESEARCH.md's own live-verified skeleton for the load/idempotency logic (call-signature UNVERIFIED — flag at implementation time per A2).

```lua
-- Structural convention from env.lua: short, single-concern module, no
-- execution guard beyond what hl.* itself requires.
local user = os.getenv("USER") or os.getenv("LOGNAME")
if user then
    local plugin_path = "/var/cache/hyprpm/" .. user .. "/dynamic-cursors/dynamic-cursors.so"
    local already_loaded = false
    for _, p in ipairs(hl.get_loaded_plugins()) do
        if p.name == "dynamic-cursors" then already_loaded = true end
    end
    if not already_loaded then
        pcall(hl.plugin.load, plugin_path)  -- pcall: never abort config load
    end
end

-- D-35: mandatory upstream guard, config errors otherwise when unloaded
if hl.plugin.dynamic_cursors then
    hl.config({
        plugin = {
            dynamic_cursors = {
                enabled = true,
                mode = "tilt",                  -- D-37: fixed at load time
                shake = { enabled = false },    -- D-36: ships disabled
            },
        },
    })
end
```
**Caveat carried forward from RESEARCH.md A2:** `hl.plugin.load()`'s exact argument shape (string vs table) is unverified — the `pcall` wrapper already degrades gracefully (AMB-02's own requirement) if wrong, but budget a real `hyprctl eval` test before trusting this skeleton verbatim, with the plugin first unloaded (double-load-timeout risk, Pitfall 4).

---

### `theme-engine/.config/theme-engine/lib/generate.sh` (modify, lines 166,171 — D-32)

**Analog:** itself (both `printf` lines already read above)

```bash
# BEFORE (line 166, gtk-3.0):
printf '[Settings]\ngtk-application-prefer-dark-theme=%s\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=Bibata-Modern-Classic\ngtk-cursor-theme-size=24\ngtk-font-name=%s 11\n' ...
# AFTER: gtk-cursor-theme-name=rose-pine-hyprcursor
# BEFORE (line 171, gtk-4.0): same hardcode, same fix.
```
Note RESEARCH.md Pitfall 6: `env.lua:9` is a **third, undocumented** hardcode site missed by CONTEXT.md's D-32 citation (which names only `generate.sh:166,171`) — must be fixed in the same commit or GTK apps and native Wayland/XWayland clients split-brain on cursor theme.

---

### `hypr/.config/hypr/config/env.lua` (modify, line 9 — Pitfall 6)

**Analog:** itself (full file read above)

```lua
-- BEFORE:
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
-- AFTER:
hl.env("XCURSOR_THEME", "rose-pine-hyprcursor")
```

## Shared Patterns

### Single-owner intent arbitration (D-14)
**Source:** `hypr/.config/hypr/scripts/waybar-visibility.sh` (whole file, pattern proven in Phase 8)
**Apply to:** `wallpaper-visibility.sh` (new owner), every intent source that calls it (picker, theme-apply, hypridle listener, gaming-mode-toggle, motion-switch) — none of those callers may ever start/stop mpvpaper directly, only write an intent and invoke the owner.

### Atomic state-file writes (unique-mktemp + mv)
**Source:** `waybar-visibility.sh`'s `_write_intent`/`_write_override`/`_write_actuated`/`_write_css`; `wallpaper.sh`'s `last_used_file.tmp && mv` write-back
**Apply to:** every new state file this phase writes — per-video seek-offset override (D-09), recorded live-wallpaper choice widened validator target (D-12), the owner's intent/actuated files.

### Best-effort, never-block error handling (`|| true`)
**Source:** `theme_engine_wallpaper_autoset` (every external call guarded)
**Apply to:** `wallpaper.sh`'s extended autoset logic, the new frame-extraction call site inside `theme-apply`'s wallpaper step — cosmetic failures must never fail `theme-apply`'s exit code.

### Argv-list subprocess discipline for compositor-supplied payloads
**Source:** `waybar-fullscreen-watch.sh`'s `subprocess.run([...], check=False)` — never `shell=True`, never string interpolation
**Apply to:** the D-27 fallback watcher, if built (T-08-20).

### Warn-and-continue install guard (`command || echo "  ⚠ ..." >&2`)
**Source:** `install.sh:484,498,581,691` (swayosd/ollama/linux-modules-cleanup/kernel-module-verify) — **NOT** `verify_packages()` (RESEARCH.md correction)
**Apply to:** D-33's guarded hyprpm block exclusively; must never be folded into `VERIFY_PKGS`.

### `engine_owned_files` manifest bucket
**Source:** `theme-engine/.config/theme-engine/contract.json` + `contract.sh`'s generic `contract_engine_owned_files()` reader
**Apply to:** D-07's extracted-frame state file — add one array entry, no code change needed in `contract.sh`, `commit.sh`, or `theme-doctor` (they already consume the array generically).

## No Analog Found

None — every file in scope has at least a role-match analog. Two items are genuinely novel capability (no prior repo precedent) but reuse established idioms:

| File/Capability | Role | Data Flow | Reason no direct behavioral analog exists |
|---|---|---|---|
| ffmpeg frame-extraction subprocess wrapper | utility | file-I/O | No prior ffmpeg/video-decode subprocess anywhere in this repo — pattern is composed from `wallpaper.sh`'s best-effort idiom + RESEARCH.md's locally-verified command shape, not copied from an existing repo file |
| `hyprpm reload` post-login completion helper | service | batch | No prior hyprpm/plugin-lifecycle script exists in this repo — placement/invocation convention borrowed from `theme-init.sh`, but the actual logic (`hyprpm reload`) is new |

## Metadata

**Analog search scope:** `hypr/.config/hypr/scripts/`, `hypr/.config/hypr/config/`, `theme-engine/.config/theme-engine/lib/`, `theme-engine/.config/theme-engine/contract.json`, `install.sh`, `hypr/.config/hypr/hypridle.conf`, `hypr/.config/hypr/hyprlock.conf`
**Files scanned:** 11 read in full or targeted sections (`waybar-visibility.sh`, `waybar-fullscreen-watch.sh`, `wallpaper.sh`, `contract.sh`, `contract.json`, `theme-init.sh`, `generate.sh` §150-173, `env.lua`, `hypridle.conf`, `gaming-mode-toggle.sh` §1-40, `install.sh` §270-500, `wallpaper-picker.sh` §38-300, `hyprlock.conf` grep)
**Pattern extraction date:** 2026-08-09
