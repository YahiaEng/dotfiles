---
phase: 06-themed-surfaces-utility-suite
plan: 05
subsystem: infra
tags: [hyprshot, satty, gpu-screen-recorder, ffmpeg, hyprland, keybinds, screenshot, screen-recording]

# Dependency graph
requires:
  - phase: 06-01
    provides: hyprshot/satty/gpu-screen-recorder declared in install.sh PACMAN_PKGS (official extra repo)
  - phase: 06-02
    provides: satty-colors.toml matugen render target + ~/.config/satty/config.toml symlink wiring (initial-tool=arrow, early-exit=all, actions-on-enter=save-to-clipboard,save-to-file)
provides:
  - "Full screenshot suite: capture-region.sh / capture-window.sh / capture-full.sh (hyprshot -z --raw piped into satty for annotate+save+copy)"
  - "record-toggle.sh: walker --dmenu audio picker (silent/desktop/desktop+mic) + slurp region/monitor select + gpu-screen-recorder NVENC/cpu-fallback + SIGINT bounded-poll stop"
  - "gif-export.sh: two-pass ffmpeg palettegen/paletteuse GIF conversion, wired as a Recording Saved notification action"
  - "Omarchy-style Print-key family keybinds (Print/Shift+Print/Ctrl+Print/Alt+Print); old bare screenshot.sh and its Super+X/Z/Shift+Print binds removed, freeing Super+X/Z for Phase 6's utility pickers"
affects: [06-06, 06-07, 06-08, 06-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "hyprshot -z -r | satty --filename - --output-filename PATH --disable-notifications — satty owns save+copy via its own actions-on-enter config; caller only notifies (matching pre-existing wording) when the output file actually landed, since Escape exits satty without saving"
    - "walker --dmenu exit-130-cancel pattern (theme-switch.sh precedent) reused for the record-audio picker"
    - "SIGINT + bounded 5s poll + SIGKILL stop idiom (reload.sh/gtk.sh precedent) applied to gpu-screen-recorder"
    - "Backgrounded notify-send -A action capture ( action=$(notify-send ... -A ...) ) & disown ) so a blocking notification-action prompt never hangs the toggle script"
    - "XDG_RUNTIME_DIR ephemeral state file (record-toggle-filename) to hand the just-saved video path from start to stop, mirroring gtk.sh's existing runtime_dir convention"

key-files:
  created:
    - hypr/.config/hypr/scripts/capture-region.sh
    - hypr/.config/hypr/scripts/capture-window.sh
    - hypr/.config/hypr/scripts/capture-full.sh
    - hypr/.config/hypr/scripts/record-toggle.sh
    - hypr/.config/hypr/scripts/gif-export.sh
  modified:
    - hypr/.config/hypr/config/keybinds.conf
  deleted:
    - hypr/.config/hypr/scripts/screenshot.sh

key-decisions:
  - "hyprshot/satty CLI flags verified against the live upstream sources (Gustash/Hyprshot raw script, gabm/Satty cli/src/command_line.rs) fetched over the network during execution, since neither binary is installed on this dev machine yet (install deferred to install.sh's next run, per 06-01) — same verification approach 06-02 used for satty's config schema"
  - "capture-full.sh uses `hyprshot -m output -m active` (grab_active_output, no slurp) for a true one-keypress instant full-screen capture, matching the old bare screenshot.sh's instant 'full' mode; capture-window.sh uses plain `-m window` (click-to-select among visible windows), the standard upstream hyprshot window UX"
  - "satty invoked with --disable-notifications; each capture script fires its own notify-send (only if the output file exists, since Escape exits satty without saving) using the exact pre-existing screenshot.sh wording/icon per 06-UI-SPEC's Copywriting Contract — satty still performs the actual save+copy via its own actions-on-enter config (D-02)"
  - "record-toggle.sh's gpu-screen-recorder invocation, slurp region/monitor picker (with hyprpicker freeze + <20px^2 click-snap-to-rect), and SIGINT-then-bounded-poll stop are adapted near-verbatim from the live Omarchy reference (basecamp/omarchy bin/omarchy-capture-screenrecording), fetched this session per RESEARCH.md Pattern 5's explicit citation"
  - "Recording state (in-progress output path) lives in $XDG_RUNTIME_DIR/record-toggle-filename, not a git-tracked or theme-engine state-dir file — ephemeral, cleared on reboot, matches this repo's existing runtime_dir convention (gtk.sh)"

patterns-established:
  - "Utility CLI scripts under hypr/scripts/ verify third-party CLI flags against live upstream source when the binary isn't yet installed locally, rather than trusting RESEARCH.md's WebSearch-sourced paraphrase — same discipline 06-02 established for satty's config schema"

requirements-completed: [SHOT-01, SHOT-02, SHOT-03]

coverage:
  - id: D1
    description: "capture-region.sh / capture-window.sh / capture-full.sh freeze-capture region/window/active-output via hyprshot -z --raw piped into satty, which owns save+copy+notify"
    requirement: "SHOT-01"
    verification:
      - kind: unit
        ref: "bash -n all three scripts; grep hyprshot/satty presence; keybinds.conf grep for Print/Shift+Print/Ctrl+Print binds — all pass (see plan verify commands)"
        status: pass
      - kind: manual_procedural
        ref: "Live-session: Print/Shift+Print/Ctrl+Print each open satty with the captured image, Enter saves+copies+closes"
        status: unknown
    human_judgment: true
    rationale: "hyprshot and satty are not installed on this dev machine yet (install deferred to install.sh's next run) — the actual capture/annotate/save/copy flow cannot be exercised end-to-end until install.sh runs on a real session; flags were verified against live upstream source, not run locally."
  - id: D2
    description: "satty owns save+copy+notify (D-02); default pre-selected tool is arrow (rendered in 06-02's satty.toml); notification wording/icon matches the pre-existing screenshot.sh convention"
    requirement: "SHOT-02"
    verification:
      - kind: unit
        ref: "grep -q 'disable-notifications' capture-region.sh; grep -q 'camera-photo' capture-region.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "record-toggle.sh: Alt+Print opens a walker --dmenu audio picker (silent/desktop/desktop+mic) before region/monitor select, then records via gpu-screen-recorder with NVENC auto-detect + cpu fallback; second press stops via SIGINT with a bounded 5s poll then SIGKILL"
    requirement: "SHOT-03"
    verification:
      - kind: unit
        ref: "bash -n record-toggle.sh; grep for gpu-screen-recorder/walker --dmenu/SIGINT — all pass (plan verify command)"
        status: pass
      - kind: manual_procedural
        ref: "Live-session: Alt+Print picks an audio mode, records a region, Alt+Print again stops and shows Recording Saved with Open/Export GIF actions"
        status: unknown
    human_judgment: true
    rationale: "gpu-screen-recorder is not installed on this dev machine yet — the actual recording pipeline (NVENC encode, SIGINT finalize, notification action wiring) cannot be exercised end-to-end until install.sh runs on a real graphical session."
  - id: D4
    description: "gif-export.sh performs a two-pass ffmpeg palettegen/paletteuse conversion, invoked as the Recording Saved notification's Export GIF action"
    requirement: "SHOT-03"
    verification:
      - kind: unit
        ref: "bash -n gif-export.sh; grep -q 'palettegen' gif-export.sh"
        status: pass
    human_judgment: false
  - id: D5
    description: "No audio is ever captured without explicit selection (T-06-08): the silent branch omits the -a flag entirely"
    requirement: "SHOT-03"
    verification:
      - kind: unit
        ref: "record-toggle.sh: AUDIO_DEVICES=\"\" for the silent case, and `[[ -n \"$AUDIO_DEVICES\" ]] && audio_args=(-a ...)` — empty string never adds -a"
        status: pass
    human_judgment: false
  - id: D6
    description: "Raw subprocess stderr never reaches notify-send unsanitized (T-06-09)"
    requirement: "SHOT-03"
    verification:
      - kind: unit
        ref: "grep -n 'head -c 200' record-toggle.sh gif-export.sh — both scripts' sanitize() functions present and used before every error notify-send call"
        status: pass
    human_judgment: false
  - id: D7
    description: "Old bare screenshot.sh deleted; no dangling reference anywhere in the repo"
    requirement: "SHOT-01"
    verification:
      - kind: unit
        ref: "[ ! -f screenshot.sh ] && ! grep -rq 'screenshot.sh' hypr/.config/hypr/ (repo-wide grep also clean)"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 05: Screenshot & Screen-Recording Suite Summary

**Omarchy-style Print-key capture suite — hyprshot -z --raw piped into satty for freeze/annotate/save/copy (region/window/full), plus Alt+Print gpu-screen-recorder toggle with an explicit walker audio picker and ffmpeg palettegen/paletteuse GIF export as a notification action**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-12T16:45:00Z
- **Completed:** 2026-07-12T17:15:00Z
- **Tasks:** 3
- **Files modified:** 7 (5 created, 1 edited, 1 deleted)

## Accomplishments
- Three freeze-capture scripts (`capture-region.sh`, `capture-window.sh`, `capture-full.sh`) pipe `hyprshot -z --raw` straight into `satty`, which owns save+copy via its already-configured `actions-on-enter` (06-02); each script only fires a notification — reusing the pre-existing screenshot.sh's exact wording/icon — if a file actually landed, since Escape/close exits satty without saving
- `record-toggle.sh` implements the full SHOT-03 recording toggle: a `walker --dmenu` audio picker (silent/desktop/desktop+mic, D-06) using theme-switch.sh's exit-130-cancel convention, a slurp region/monitor picker with hyprpicker freeze and click-snap-to-rect (adapted from the live Omarchy reference), `gpu-screen-recorder` with NVENC auto-detect + cpu fallback, and a SIGINT-then-bounded-5s-poll-then-SIGKILL stop
- `gif-export.sh` performs a two-pass ffmpeg `palettegen`/`paletteuse` GIF conversion, wired as the "Export GIF" action on the Recording Saved notification
- `keybinds.conf`'s Screenshots section now binds Print=region, Shift+Print=window, Ctrl+Print=full, Alt+Print=record toggle; the old Super+X/Z/Shift+Print bare-screenshot binds are gone, freeing Super+X/Z for this phase's utility pickers (D-32)
- `hypr/.config/hypr/scripts/screenshot.sh` deleted; confirmed zero remaining references anywhere in the repo

## Task Commits

Each task was committed atomically:

1. **Task 1: Capture scripts (hyprshot -z into satty) + Print-family keybinds** - `e81aaaa` (feat)
2. **Task 2: record-toggle.sh + gif-export.sh + Alt+Print bind** - `31d2352` (feat)
3. **Task 3: Delete the old screenshot.sh and confirm no dangling references** - `6999ae4` (chore)

**Plan metadata:** (pending — this commit)

## Files Created/Modified
- `hypr/.config/hypr/scripts/capture-region.sh` - `hyprshot -m region -z -r | satty ...` region freeze-capture
- `hypr/.config/hypr/scripts/capture-window.sh` - `hyprshot -m window -z -r | satty ...` window freeze-capture (click-to-select)
- `hypr/.config/hypr/scripts/capture-full.sh` - `hyprshot -m output -m active -z -r | satty ...` instant active-monitor capture
- `hypr/.config/hypr/scripts/record-toggle.sh` - audio picker + slurp region/monitor select + gpu-screen-recorder + SIGINT stop + Recording Saved notification actions
- `hypr/.config/hypr/scripts/gif-export.sh` - two-pass ffmpeg palettegen/paletteuse GIF conversion + GIF Exported notification
- `hypr/.config/hypr/config/keybinds.conf` - Screenshots section replaced with the Print-key family; Alt+Print record-toggle bind added
- `hypr/.config/hypr/scripts/screenshot.sh` - deleted (fully replaced)

## Decisions Made
- hyprshot/satty CLI flags verified against live upstream source (fetched over the network this session) rather than a local `--help` run, since neither binary is installed on this dev machine yet — matches 06-02's precedent for satty's config schema
- `capture-full.sh` uses `hyprshot -m output -m active` for a true instant (no-click) full-screen capture; `capture-window.sh` uses plain `-m window` for the standard click-to-select-a-window upstream UX
- satty runs with `--disable-notifications`; each capture script fires its own notify-send matching the pre-existing screenshot.sh wording/icon exactly, per 06-UI-SPEC's Copywriting Contract, only when the output file exists (never on cancel)
- `record-toggle.sh`'s recorder invocation, slurp picker, and stop sequence are adapted near-verbatim from the live Omarchy reference script (fetched this session) per RESEARCH.md Pattern 5's explicit citation
- In-progress recording path tracked in `$XDG_RUNTIME_DIR/record-toggle-filename` (ephemeral, not git-tracked), matching this repo's existing `runtime_dir` convention (gtk.sh)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed lingering "screenshot.sh" references from new script header comments before Task 3's deletion**
- **Found during:** Task 3 (deleting screenshot.sh and verifying no dangling references)
- **Issue:** Task 1's `capture-region.sh` and `capture-full.sh` header comments explicitly named "screenshot.sh" while explaining behavior parity with the old script. Task 3's verification (`! grep -rq 'screenshot.sh' hypr/.config/hypr/`) would have failed once the file was deleted, since the comments themselves matched the grep.
- **Fix:** Reworded both comments to describe "the old bare grim/slurp screenshot" without naming the literal filename.
- **Files modified:** `hypr/.config/hypr/scripts/capture-region.sh`, `hypr/.config/hypr/scripts/capture-full.sh`
- **Verification:** `bash -n` clean on both files; `grep -rq 'screenshot.sh' hypr/.config/hypr/` returns clean after the fix and after `git rm screenshot.sh`
- **Committed in:** `6999ae4` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Purely a self-referential verification-timing fix within this plan's own files — no scope creep, no behavior change to any capture script.

## Issues Encountered
- Neither `hyprshot`, `satty`, nor `gpu-screen-recorder` is installed on this dev machine (confirmed via `command -v`/`pacman -Q`) — all three are declared in `install.sh` (06-01) but installation is deferred to a real `install.sh` run. CLI flags for all three were verified against the live upstream source repositories (Gustash/Hyprshot's raw script, gabm/Satty's `cli/src/command_line.rs`, basecamp/omarchy's `bin/omarchy-capture-screenrecording`) fetched over the network this session — a stronger ground-truth source than RESEARCH.md's WebSearch-paraphrased flag descriptions, and consistent with 06-02's precedent for resolving the same kind of not-yet-installed-binary uncertainty. End-to-end manual verification (D1/D3 coverage entries) is deferred to a live graphical session after `install.sh` runs.

## User Setup Required

None — no external service configuration required. Once `install.sh` runs (06-01's package additions), the Print-key family and Alt+Print recording toggle work immediately with no further setup.

## Next Phase Readiness
- The full screenshot/recording keybind family (Print/Shift+Print/Ctrl+Print/Alt+Print) is in place; Super+X and Super+Z are confirmed free for 06-UI-SPEC D-32's utility pickers (emoji/icon-theme on Z, color/font on X)
- `06-06` (SwayOSD + Zen) and later plans in this phase can proceed independently — no shared files with this plan beyond the already-registered contract.json/satty.toml from 06-02
- Recommend a quick live-session smoke test (Print/Shift+Print/Ctrl+Print/Alt+Print) once `install.sh` has installed hyprshot/satty/gpu-screen-recorder on a real graphical session, to close out the two `human_judgment: true` coverage entries (D1, D3) above

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/scripts/capture-region.sh
- FOUND: hypr/.config/hypr/scripts/capture-window.sh
- FOUND: hypr/.config/hypr/scripts/capture-full.sh
- FOUND: hypr/.config/hypr/scripts/record-toggle.sh
- FOUND: hypr/.config/hypr/scripts/gif-export.sh
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-05-SUMMARY.md
- CONFIRMED DELETED: hypr/.config/hypr/scripts/screenshot.sh
- FOUND commit: e81aaaa (Task 1)
- FOUND commit: 31d2352 (Task 2)
- FOUND commit: 6999ae4 (Task 3)
- FOUND commit: cc3307d (SUMMARY.md)
