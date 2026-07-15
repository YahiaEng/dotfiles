---
phase: 10-ags-media-applet
plan: 03
subsystem: ui
tags: [ags, astal, gtk4, gjs, typescript, jsx, mpris, playerctl, media, reactive]

# Dependency graph
requires:
  - phase: 10-02
    provides: "AGS scaffold (media window, click-away/Esc, toggle-media request), pinned AGS 3.1.0 reactive primitives, -i media request form"
  - phase: 08-07
    provides: "MPRIS backend scripts (media-status.sh/media-players.sh/media-art-resolve.sh) with _valid_id argv-form security contract"
provides:
  - "lib/media.ts — subprocess-fed reactive `media`/`players` accessors + `cmd`/`seek`/`setVolume`/`selectPlayer`/`refreshPlayers` action helpers"
  - "Per-track seekability latch (`seekable`/`seekLength` accessors) that survives Firefox/YouTube's transient mpris:length=0"
  - "Synchronous startup seed via `media-status.sh once` so the seek slider reflects real length/position on first open"
  - "MediaWindow.tsx control tree: metadata row + transport + seek slider + volume slider + player switcher, bound to live MPRIS state"
  - "Human-verified proof that transport/seek/volume/switcher drive real MPRIS playback (MEDIA-01 controls delivered)"
affects: [10-04, 10-05, 10-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Long-lived subprocess([bash, media-status.sh, watch]) feeds reactive `media` state one JSON line at a time; exec([bash, media-players.sh, list]) drives `players`"
    - "Per-track state latch: hold seekability + last-known-good length keyed on player+title+artist identity; reset only on real track change or stop — the general fix pattern for any unreliable per-track MPRIS metadata field"
    - "Synchronous one-shot `once` seed at module load before starting the watch subprocess, to avoid a first-render EMPTY-seed window"
    - "Astal `<slider>` (Astal.Slider) with onChangeValue (user-drag-only Gtk.Range signal) for seek/volume — never onValueChanged, which would fire on programmatic value updates"

key-files:
  created:
    - ags/.config/ags/lib/media.ts
  modified:
    - ags/.config/ags/widget/MediaWindow.tsx

key-decisions:
  - "Firefox/YouTube mpris:length is unreliable (intermittently absent mid-track; a seek re-emits metadata WITHOUT length until the next play-state change) — mitigated with a per-track seekability latch, NOT by gating on the live length"
  - "seek/volume sliders use onChangeValue (user-drag-only) instead of the doc's onValueChanged, to avoid a seek-on-every-1s-tick feedback loop against the reactive value binding"
  - "Startup seed via media-status.sh once so the first seek-slider interaction reflects the real position/length instead of an EMPTY-seed length-0 baseline"
  - "Raw NUL bytes in a track-key separator (edit-tool artifact) flagged the source binary — same artifact class as the recurring PUA-glyph-empties-to-empty-string issue (08-16/08-11); use plain visible separators and verify committed blobs have zero NUL bytes"

patterns-established:
  - "Per-track metadata latch for unreliable MPRIS fields"
  - "Verify committed source blobs for stray NUL bytes when edit tooling may inject control characters (git flags such files binary)"

requirements-completed: [MEDIA-01]

coverage:
  - id: D1
    description: "lib/media.ts exposes reactive media/players + cmd/seek/setVolume/selectPlayer/refreshPlayers; all backend calls argv-form; backend scripts byte-unchanged"
    requirement: "MEDIA-01"
    verification:
      - kind: integration
        ref: "git diff --exit-code on media-status.sh/media-players.sh/media-art-resolve.sh — clean (backend byte-unchanged); grep confirms exported accessors/helpers"
        status: pass
    human_judgment: false
  - id: D2
    description: "Per-track seek latch holds seekability across a transient mpris:length=0 after a seek, resets on real track change/stop, and keeps genuinely non-seekable tracks disabled"
    requirement: "MEDIA-01"
    verification:
      - kind: unit
        ref: "/tmp/latch-test.mjs — 8/8 deterministic checks pass (transient-0-after-seek holds, persistent-0 holds, real track change resets, genuine length=0 stays disabled, stop resets)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Transport (prev/play-pause/next), seek slider (repeated drags AND correct first-drag baseline), volume slider, and player switcher all drive real MPRIS playback"
    requirement: "MEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 human gate — user live-tested all controls against Firefox/YouTube MPRIS players; APPROVED"
        status: pass
    human_judgment: true
    rationale: "No agent-side pointer injection exists on this machine; only a human can drag sliders / click transport against a live player. Confirmed by the user."

# Metrics
duration: multi-session (3 human-gate rounds)
completed: 2026-07-15
status: complete
---

# Phase 10 Plan 03: Live MPRIS Controls Summary

**AGS media card bound to live MPRIS state — working transport / seek / volume / player-switcher over the unchanged bash backend, with a per-track seekability latch that survives Firefox/YouTube's unreliable `mpris:length` and a startup seed for a correct first-drag baseline.**

## Performance

- **Duration:** multi-session (3 human-gate rounds: initial gate, seek-bug fix, first-drag-baseline fix)
- **Completed:** 2026-07-15
- **Tasks:** 3 (2 auto + 1 human-verify gate)
- **Files:** 1 created, 1 modified

## Accomplishments

- **MEDIA-01 interactive controls delivered and human-approved.** Transport (prev/play-pause/next), volume, the player switcher, and the seek slider (repeated drags AND correct first-drag baseline) all drive real MPRIS playback against live Firefox/YouTube players.
- `lib/media.ts` exposes reactive `media`/`players` accessors fed by a long-lived `media-status.sh watch` subprocess, plus argv-form `cmd`/`seek`/`setVolume`/`selectPlayer`/`refreshPlayers` helpers.
- `MediaWindow.tsx` rebuilt: the 10-02 test button is replaced with a full control tree (metadata row + transport + seek + volume + switcher), while the outer `Astal.Window`, click-away `Gtk.GestureClick`, and Esc `Gtk.EventControllerKey` are preserved unchanged.
- The three MPRIS backend scripts were reused **byte-unchanged** (git diff clean).

## Task Commits

1. **Task 1: reactive MPRIS state + action helpers** — `8ce59e8` (feat)
2. **Task 2: bind control tree to live state** — `0242f10` (feat)
3. **Fix: per-track seek latch (transient length=0)** — `9984f87` (fix)
4. **Fix: startup seed for first-open seek baseline** — `8a06eee` (fix)
5. **Fix: remove stray NUL bytes from track-key separator** — `a189f5d` (fix)
6. **Task 3: human-verify interaction gate** — no commit (verification gate; APPROVED by the user)

## Files Created/Modified

- `ags/.config/ags/lib/media.ts` — reactive media/players state, per-track seek latch (`seekable`/`seekLength`), startup `once` seed, argv-form action helpers
- `ags/.config/ags/widget/MediaWindow.tsx` — control tree (metadata/transport/seek/volume/switcher) bound to live state; outer window/click-away/Esc unchanged

## Durable Findings

### Firefox/YouTube `mpris:length` is unreliable (load-bearing for anything reading MPRIS length)

Confirmed at the data layer: `playerctl metadata mpris:length` for Firefox is **intermittently absent even mid-track** (observed 20/20 empty samples while `status=Playing`), and a `Set-position`/seek is a known trigger for Firefox to re-emit its metadata bundle **without** length until the next play-state transition. The backend faithfully maps missing length to `length:0`/`can_seek:false` (backend is not the culprit).

**Mitigation — per-track seekability latch** in `lib/media.ts` (`seekable`/`seekLength` accessors): once a track (keyed on player+title+artist) is seen with `length>0`, stay seekable and hold the last-known-good length; a transient/persistent `length:0` on the same track is ignored; reset only on a real track-identity change or a true stop. This is the general pattern for any unreliable per-track MPRIS field.

**Startup seed:** the `watch` subprocess doesn't emit until its first poll, so a synchronous one-shot `exec([bash, media-status.sh, once])` primes `media`/`seekLength` at module load — the seek slider reflects real length/position on first open instead of a length-0 baseline.

## Decisions Made

See key-decisions frontmatter. The three durable choices: the MPRIS-length latch, the `onChangeValue` (not `onValueChanged`) slider signal, and verifying source blobs for stray NUL bytes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug prevention] seek/volume sliders use `onChangeValue`, not the doc's `onValueChanged`**
- **Found during:** Task 2
- **Issue:** The approved plan snippet wired `onValueChanged` → `seek(value)`. With the slider's `value` also bound to the reactive `media.position` accessor (which updates ~1 Hz from the watcher), `onValueChanged` would fire on every programmatic position update and issue a spurious seek every tick — a feedback loop.
- **Fix:** Used Astal's `<slider>` (Astal.Slider) with `onChangeValue`, which is Gtk.Range's user-drag/click/scroll-only signal and never fires for programmatic value updates. Same pattern applied to the volume slider.
- **Files modified:** `ags/.config/ags/widget/MediaWindow.tsx`
- **Verification:** Human gate — repeated seek/volume drags work with no runaway seeking.
- **Committed in:** `0242f10`

**2. [Rule 1 - Bug] Seek slider disabled after one seek (transient `mpris:length=0`)**
- **Found during:** Task 3 human gate (round 1)
- **Issue:** Gating the seek `<With>` on the live `media.length > 0` tore the slider down whenever Firefox emitted a transient `length:0` line (notably right after a seek), showing "Not seekable" until a play-state change.
- **Fix:** Per-track seekability latch (`seekable`/`seekLength`) in `lib/media.ts`; widget gates on `seekable` and binds slider max to `seekLength`.
- **Files modified:** `ags/.config/ags/lib/media.ts`, `ags/.config/ags/widget/MediaWindow.tsx`
- **Verification:** 8/8 deterministic latch checks (`/tmp/latch-test.mjs`) + human gate round 2.
- **Committed in:** `9984f87`

**3. [Rule 1 - Bug] Seek slider length-0 baseline on first open**
- **Found during:** Task 3 human gate (round 2)
- **Issue:** At applet open the `watch` subprocess hadn't emitted yet, so `media` was the EMPTY seed (position 0) and `seekLength` was 0 — the first seek drag started against a length-0/max-1 baseline.
- **Fix:** Synchronous startup seed via `exec([bash, media-status.sh, once])` before starting the watcher.
- **Files modified:** `ags/.config/ags/lib/media.ts`
- **Verification:** grim screenshot on open shows the thumb at the real position (~73% for pos 1421 / len 1940); human gate round 3.
- **Committed in:** `8a06eee`

**4. [Rule 1 - Defect caught during verification] Raw NUL bytes in the track-key separator**
- **Found during:** post-fix commit verification of `lib/media.ts`
- **Issue:** The latch's `trackKeyOf` joined player/title/artist with **2 raw NUL (0x00) bytes** injected by the edit tooling. Runtime-harmless (NUL is a valid JS string-join char — the latch tests passed), but git classified the TypeScript source as a binary blob (NULs at offsets 1764/1775), making it corrupt and unreviewable. This is the **same edit-tool artifact class as the recurring PUA-glyph-empties-to-empty-string issue (08-16/08-11)** — invisible characters silently entering source via the edit path.
- **Fix:** Rewrote `trackKeyOf` to `[m.player, m.title, m.artist].join(" :: ")` with a plain visible separator. Verified the committed blob now has **0 NUL bytes** (`git cat-file -p HEAD:… | tr -cd '\000' | wc -c` → 0).
- **Files modified:** `ags/.config/ags/lib/media.ts`
- **Verification:** Committed-blob NUL count = 0; ags run compiles clean; render unchanged.
- **Committed in:** `a189f5d`

---

**Total deviations:** 4 auto-fixed (1 feedback-loop prevention, 2 MPRIS-quirk bugs surfaced at the human gate, 1 source-corruption defect caught in verification).
**Impact on plan:** All fixes necessary for correct interactive behavior and clean source. No scope creep — backend untouched, controls scope unchanged.

## Security

- All backend calls are **argv-form arrays** (e.g. `["bash", PLAYERS_SH, "cmd", p, action]`), never shell strings.
- Only `_valid_id`-validated player ids (from `media.player`/`players[].id`) and numeric slider values are passed to the backend; **no track metadata (title/artist/album) ever reaches a command argument** (inherits the 08-07 T-08-07 contract; threat T-10-03-01/02/03 mitigations upheld).
- The three MPRIS backend scripts (`media-status.sh`, `media-players.sh`, `media-art-resolve.sh`) are reused **byte-unchanged** (git diff clean).

## Issues Encountered

- The seek control required two human-gate rounds to reach correct behavior (transient-length latch, then startup seed) — both root-caused at the data layer before fixing, not guessed.
- A stray-NUL source-corruption defect was caught during commit verification and cleaned up before finalization.

## User Setup Required

None — no external service configuration.

## Cosmetic Note (carried forward)

Album art showed a broken-image placeholder during verification (the art path resolution is not yet fully wired for this player). The art treatment is **replaced entirely in 10-04's garuda restyle** (blurred-art background + cava underlay), so no action is taken here.

## Next Phase Readiness

- MEDIA-01 interactive controls delivered and human-approved. Ready for **10-04** (garuda visual restyle + cava audio-reactive underlay + Hyprland `ags-media` blur layerrule), which builds on the `media` accessor (art path) and the working control tree from this plan.

---
*Phase: 10-ags-media-applet*
*Completed: 2026-07-15*
