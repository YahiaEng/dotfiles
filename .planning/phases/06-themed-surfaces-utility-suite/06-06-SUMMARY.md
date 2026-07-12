---
phase: 06-themed-surfaces-utility-suite
plan: 06
subsystem: theming-pipeline
tags: [swayosd, gtk-css, matugen, hyprland-keybinds, zen-browser, firefox-userchrome, bash, reload-fanout]

# Dependency graph
requires:
  - phase: 06-01
    provides: swayosd package scaffolding (stow.sh PACKAGES entry, swayosd-libinput-backend.service install.sh enable)
  - phase: 06-02
    provides: swayosd-colors.css / zen-userchrome.css / satty-colors.toml matugen templates + contract.json entries + config.toml registrations
provides:
  - swayosd stow package style.css that @imports the rendered swayosd.css palette and themes a bottom-center rounded pill (OSD-01)
  - Media keys (volume raise/lower/mute, mic-mute) routed through swayosd-client so the OSD shows on every change
  - reload.sh guarded swayosd-libinput-backend.service restart (headless-safe)
  - theme_engine_reload_zen: lazy Zen profile self-heal (installs.ini -> profiles.ini resolution, path validation, userChrome.css symlink, defensive user.js pref) + notify-only reload (THM-05)
affects: [phase-08-waybar-oled (OSD-01 groundwork), any-future-zen-theming-work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "New stow-package @import pattern reused for swayosd/style.css (mirrors swaync/wlogout style.css line-1 @import from state dir)"
    - "reload.sh guarded fan-out extension: pgrep -x <proc> gate + timeout-bounded systemctl call, inside the existing headless early-return guard"
    - "Firefox-family profile resolution: installs.ini (single-section, unconditional) first, profiles.ini ([General] Default= then ProfileN Default=1/Path=) fallback, both parsed with a found-flag-guarded awk state machine (no `exit` inside functions — see Deviations)"

key-files:
  created:
    - swayosd/.config/swayosd/style.css
  modified:
    - hypr/.config/hypr/config/keybinds.conf
    - theme-engine/.config/theme-engine/lib/reload.sh

key-decisions:
  - "D-25 descope exercised: ddcutil is not installed and no DDC-capable monitor was detected on this machine at execution time — DDC brightness wiring skipped per the pre-authorized fallback; existing brightnessctl binds kept unchanged"
  - "swayosd style.css re-reads on next OSD trigger with no explicit reload call — only the libinput backend service (caps-lock keyless path) is restarted, and only when swayosd-server is confirmed running"
  - "Zen profile resolution parses installs.ini before profiles.ini per Pitfall 5, validates the resolved path is a real existing subdirectory of ~/.zen before any symlink/write (T-06-10 mitigation)"

patterns-established:
  - "Any future reload.sh fan-out addition must live inside the existing headless early-return guard and be pgrep -x + timeout gated, per D-29"

requirements-completed: [OSD-01, THM-05]

coverage:
  - id: D1
    description: "SwayOSD stow style.css @imports the rendered swayosd.css palette and themes a bottom-center rounded pill (background 0.85 alpha fill, surface_variant 0.6 progress track, primary progress fill, on_background icon/label, 999px radius)"
    requirement: "OSD-01"
    verification:
      - kind: unit
        ref: "grep -q '@import url(\"../../.local/state/theme/swayosd.css\")' swayosd/.config/swayosd/style.css"
        status: pass
      - kind: integration
        ref: "theme-engine/.config/theme-engine/theme-parity (headless) — swayosd.css present for all 22 palette targets, 88/88 checks pass"
        status: pass
    human_judgment: true
    rationale: "Visual pill appearance (position, alpha blending, glyph rendering) requires a live Hyprland session with swayosd-server running and a real media-key trigger — cannot be verified headlessly on this container/dev machine"
  - id: D2
    description: "Media keys (XF86AudioRaiseVolume/LowerVolume/Mute/MicMute) rerouted through swayosd-client; caps-lock stays keyless via the already-enabled libinput backend service"
    requirement: "OSD-01"
    verification:
      - kind: unit
        ref: "grep -q 'swayosd-client' hypr/.config/hypr/config/keybinds.conf"
        status: pass
    human_judgment: true
    rationale: "Confirming the physical media keys actually trigger the themed OSD pill requires a live session and physical/virtual key press — not automatable from this environment"
  - id: D3
    description: "Brightness-via-DDC evaluated and descoped with evidence (D-25): ddcutil not installed, no DDC monitor probe possible on this machine"
    requirement: "OSD-01"
    verification:
      - kind: other
        ref: "command -v ddcutil (exit nonzero — not installed, confirmed this session)"
        status: pass
    human_judgment: false
  - id: D4
    description: "reload.sh guarded swayosd reload block (pgrep -x swayosd-server gated, timeout-bounded systemctl --user restart swayosd-libinput-backend.service) inside the headless guard"
    requirement: "OSD-01"
    verification:
      - kind: unit
        ref: "bash -n theme-engine/.config/theme-engine/lib/reload.sh && grep -q swayosd theme-engine/.config/theme-engine/lib/reload.sh"
        status: pass
    human_judgment: false
  - id: D5
    description: "theme_engine_reload_zen: resolves default Zen profile from installs.ini then profiles.ini, validates path under ~/.zen, symlinks chrome/userChrome.css to zen-userchrome.css, writes defensive user.js pref, notifies (never kills) when Zen is running; skips silently when ~/.zen is absent"
    requirement: "THM-05"
    verification:
      - kind: unit
        ref: "bash -n reload.sh + grep checks for theme_engine_reload_zen/installs.ini/zen-userchrome.css + zero pkill/killall/kill of zen"
        status: pass
      - kind: integration
        ref: "Functional test against synthetic installs.ini-only, profiles.ini-only, no-~/.zen, and path-traversal fixtures (see Deviations) — all four scenarios produced correct symlink/skip/reject behavior, exit 0"
        status: pass
    human_judgment: true
    rationale: "This machine has no live ~/.zen profile from an actually-launched Zen browser — the live-session UAT (theme switch with Zen running, confirming the restart-to-apply notification and post-restart chrome re-theme) requires a human to launch Zen and observe"
  - id: D6
    description: "Container gate stays green headless: theme-parity passes with all new reload.sh blocks never invoked (headless guard early-return verified)"
    requirement: "THM-05"
    verification:
      - kind: integration
        ref: "env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS theme-engine/.config/theme-engine/theme-parity"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-12
status: complete
---

# Phase 6 Plan 6: SwayOSD Media-Key Wiring & Zen Browser Self-Heal Summary

**Bottom-center themed SwayOSD pill wired to swayosd-client media keys, plus a lazy Zen browser profile self-heal (installs.ini/profiles.ini resolution + userChrome.css symlink + notify-only reload) added to reload.sh's single guarded fan-out.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-07-12
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- New `swayosd/.config/swayosd/style.css` stow package: @imports the 06-02-rendered `swayosd.css` palette, themes a bottom-center rounded pill per the UI-SPEC 60/30/10 mapping (background 0.85-alpha fill, surface_variant 0.6-alpha progress track, primary progress fill, on_background icon/label)
- `keybinds.conf` Audio controls block rerouted through `swayosd-client` (D-23) — volume raise/lower, mute, and mic-mute all now trigger the themed OSD; caps-lock stays keyless via the already-enabled `swayosd-libinput-backend.service`
- `reload.sh` extended with a guarded swayosd reload block (restart the libinput backend only when `swayosd-server` is running, timeout-bounded) and a new `theme_engine_reload_zen` function that lazily self-heals Zen's `userChrome.css` symlink and notifies (never kills) a running Zen process
- Container gate confirmed green headless: `theme-parity` passes 1542/1542 checks across 22 palette targets, including `swayosd.css` and `zen-userchrome.css` (88/88 each)

## Task Commits

Each task was committed atomically:

1. **Task 1: SwayOSD stow style.css + media-key wiring + reload hook** - `93759de` (feat)
2. **Task 2: reload.sh swayosd reload + Zen self-heal/notify blocks** - `3012a5d` (feat)
3. **Task 3: Verify container gate stays green + parity unaffected** - verification-only, no file changes (see below)

**Plan metadata:** committed with this summary

## Files Created/Modified
- `swayosd/.config/swayosd/style.css` - New stow-package CSS: @imports rendered swayosd.css, bottom-center pill structure (999px radius, 16px container padding, 6px progress track)
- `hypr/.config/hypr/config/keybinds.conf` - Audio controls block rerouted through `swayosd-client`; brightness binds unchanged (D-25 descope documented inline)
- `theme-engine/.config/theme-engine/lib/reload.sh` - Guarded swayosd libinput-backend restart block + new `theme_engine_reload_zen` function, both called from `theme_engine_reload` after the existing headless guard

## Decisions Made
- **D-25 descope exercised with evidence:** `ddcutil` is not installed on this machine (`command -v ddcutil` fails) and no DDC-capable monitor probe was possible. Per the plan's pre-authorized fallback, brightness-via-DDC is skipped entirely — the existing `brightnessctl` binds are left unchanged. This is documented inline in `keybinds.conf` and is not treated as a gap.
- **swayosd reload needs no explicit style-reload call:** swayosd re-reads `style.css` at the next OSD trigger (per its own CSS-on-launch model). Only the libinput backend service (which owns the keyless caps-lock path) is restarted, and only when `swayosd-server` is confirmed running via `pgrep -x`.
- **Zen profile resolution order:** `installs.ini` is parsed first (single install-hash section, `Default=` taken unconditionally when exactly one section exists), falling back to `profiles.ini`'s `[General] Default=` then any `[ProfileN]` section flagged `Default=1` (its `Path=`) — matching RESEARCH.md Pitfall 5's guidance that `installs.ini` is the modern authoritative source.
- **Path validation before any filesystem write:** the resolved profile path is `realpath -m`-resolved and checked to be a real, existing subdirectory of `~/.zen` before the symlink/`user.js` write ever happens (T-06-10 mitigation) — a malicious or malformed `installs.ini`/`profiles.ini` entry (e.g. `Default=../../../etc`) is rejected and logged, not blindly followed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed an awk double-flush bug in the Zen profiles.ini fallback parser**
- **Found during:** Task 2, functional testing of `theme_engine_reload_zen` against a synthetic `profiles.ini`-only fixture (no `installs.ini`) before committing
- **Issue:** The original `flush()` awk function called `exit` immediately after printing the resolved `Path=`. `exit` inside an awk function terminates the whole program immediately — skipping the caller's subsequent `path=""; def=0; next` reset — and then the `END { flush() }` block ran with `def`/`path` still holding the last section's values, printing the same profile path a second time on a separate line. This corrupted `profile_rel` into a two-line string (`"xyz.default-release\nxyz.default-release"`), which then failed the subsequent `realpath`/subdirectory validation and caused the entire profiles.ini-only fallback path to incorrectly skip self-healing.
- **Fix:** Replaced the `exit`-based single-shot pattern with a `found` guard flag inside `flush()` (`if (!found && def == 1 && path != "") { print path; found=1 }`), so repeated calls (from a section boundary AND the `END` block) are idempotent — the function prints at most once regardless of how many times it's invoked.
- **Files modified:** theme-engine/.config/theme-engine/lib/reload.sh
- **Verification:** Re-ran the full functional test matrix (installs.ini primary path, profiles.ini-only fallback, no-`~/.zen` skip path, and a path-traversal-attempt fixture with `Default=../../../etc`) against synthetic fixtures under `/tmp` — all four scenarios now produce correct symlink/skip/reject behavior with exit code 0, before the fix committed. Also caught and fixed a related minor issue in the `installs.ini` primary-path awk one-liner (`$1=""; sub(/^=/,"")` left a leading space in the output — replaced with a direct `sub(/^Default=/, "")` on `$0`, verified clean).
- **Committed in:** 3012a5d (Task 2 commit — fix applied before commit, not as a separate follow-up commit, since it was caught during pre-commit functional testing)

---

**Total deviations:** 1 auto-fixed (1 bug, caught via proactive functional testing of new-territory bash/awk logic that has no existing repo analog per 06-PATTERNS.md's "No Analog Found" table)
**Impact on plan:** The fix was essential — without it, the profiles.ini-only fallback (the path any machine without a modern `installs.ini` would hit) would silently fail to self-heal the Zen theming symlink. No scope creep; the fix stayed entirely within `theme_engine_reload_zen`'s existing design.

## Issues Encountered
None beyond the awk bug documented above (caught and fixed before task completion, not left as an open issue).

## User Setup Required
None - no external service configuration required. Live-session manual verification (volume/mute/caps-lock OSD pill appearance, and a real Zen-browser theme-switch-then-restart cycle) remains a UAT item per the plan's own `<verification>` section — this machine has no live Wayland session and no previously-launched Zen profile to exercise that path against directly.

## Next Phase Readiness
- SwayOSD and Zen are now both wired into the single `reload.sh` fan-out owner, matching the plan's design goal (this plan is the sole owner of the reload.sh fan-out extension for the phase).
- Container gate confirmed green: `theme-parity` 1542/1542 headless, including both new targets (`swayosd.css`, `zen-userchrome.css`) across all 22 palettes.
- Live-session human verification (OSD pill visual/interaction correctness, Zen restart-to-re-theme cycle) is the remaining open item before OSD-01/THM-05 can be marked fully validated — recommended as a phase-level UAT step, not a blocker for subsequent plans in this phase.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*
