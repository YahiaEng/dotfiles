---
phase: 14-dashboard-drawer
plan: 05
subsystem: ui
tags: [quickshell, qml, mpris, media-tab, material-design-3, caelestia]

# Dependency graph
requires:
  - phase: 14-03
    provides: "Dashboard.qml pager, drawer-root design constants, MediaBackend.qml/MediaTab.qml stubs with widgetState register"
  - phase: 14-02
    provides: "Material Symbols Rounded FILL-axis verdict, motion tokens (Colours/Motion singletons)"
provides:
  - "MediaBackend.qml — the one shared streaming reader of media-status.sh watch, consumed by MediaTab.qml now and 14-08's compact widget later"
  - "Fixed-argv mutator dispatch through media-players.sh (play/pause, next, previous, seek, volume, player selection) — the drawer's only sanctioned MPRIS write path"
  - "MediaTab.qml — MD3 full player redrawn to the Caelestia (github.com/caelestia-dots/shell) visual convention: art-left/details-right split, circular-masked cover art, dropdown player switcher, optimistic-UI play/pause"
  - "The standing phase-wide directive: every remaining Phase 14 tab plan must follow the corresponding Caelestia shell surface, adapted to this repo's tokens/backends"
affects: [14-06, 14-07, 14-08, 14-09, 15]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Optimistic-UI latch + reconciliation + timeout fallback for controls backed by a slow/polled backend (media-status.sh watch polls at 1 Hz; a truth-driven-only glyph traits the click by up to ~1s)"
    - "QtQuick.Effects MultiEffect maskEnabled/maskSource for real circular image crops — `clip: true` on a radius Rectangle only clips to the bounding box"
    - "The mask shape used by MultiEffect must carry `layer.enabled: true` or it produces an empty mask (no paint node), silently blanking the masked content"
    - "Reactive declarative position bindings must never call mapToItem() inside them — mapToItem() is not itself reactive; compute position from summed reactive ancestor x/y properties, or call it imperatively at a discrete open-time event"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml

key-decisions:
  - "Render-gate round 1-2: initial vertical single-column MD3 player rejected outright — 'Copy caelestia's look instead, it looks more aesthetically pleasing.' Recorded as a standing phase-wide directive for all remaining Phase 14 tab plans (14-06/14-07/14-08/14-09)."
  - "Round 3: circular art with a dotted ring accepted in principle; art clipping and pill placement rejected."
  - "Round 4: real circular crop requires MultiEffect mask + layer.enabled on the mask shape (clip:true on a Rectangle radius only clips the bounding box); corner-alpha-only test assertions cannot catch an empty mask — the harness must also assert the center pixel matches source color."
  - "Round 5: mapToItem() inside a declarative binding is not reactive — replaced with explicit reactive ancestor x/y sums for dropdown positioning; play/pause glyph morph switched from a per-frame FILL-axis Behavior to an instant, GPU-cached crossfade."
  - "Round 6: measured (not guessed) root cause of play/pause perceived lag — media-status.sh watch polls at 1 Hz and the observed status change landed 976ms after the playerctl command; a truth-driven-only glyph always trailed the click by up to ~1s. Fixed with a bounded optimistic-UI latch inside MediaTab.qml (_pendingPlaying / effectivePlaying / requestPlayPause()), silently reconciled on backend confirmation, falling back to backend truth after 2500ms for a command that never confirms. MediaBackend.qml itself is untouched — D-22's truth-driven rule is preserved at the backend layer; the optimism lives entirely in the view."
  - "All six render-gate rounds now formally APPROVED by the human (final approval 2026-07-29: 'approved' — instant response confirmed)."

patterns-established:
  - "Optimistic-UI latch pattern (round 6) is the house convention for any future control backed by a slow/polled backend stream."
  - "MultiEffect mask + layer.enabled(mask) is the house pattern for non-rectangular image crops going forward."
  - "mapToItem() is banned from declarative position bindings repo-wide; compute reactively or imperatively at the triggering event."

requirements-completed: [DASH-04]

coverage:
  - id: D1
    description: "MediaBackend.qml — single shared Process streaming media-status.sh watch's JSON-per-line payload, gated on drawerOpen, with a default-safe payload shape, defensive per-line parsing (try/catch, reject empty/non-object lines, keep last-good value), and derived display fields (displayTitle/Artist/Album, artPath, playing, positionSeconds, lengthSeconds, volumeLevel, hasVolume, canSeek) consumed by MediaTab.qml"
    requirement: "DASH-04"
    verification:
      - kind: manual_procedural
        ref: "Task 1 acceptance criteria — process-count delta proof (baseline+1 while open, baseline after dismiss, 5 summon-dismiss cycles), motion-lint CHECK A/B PASS on MediaBackend.qml, git diff --numstat clean on media-status.sh/media-players.sh/qmldir/Dashboard.qml/shell.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fixed-argv mutator dispatch (playPause/nextTrack/previousTrack/seekTo/setVolume/selectPlayer) through media-players.sh only — the player id passes _valid_id twice (list emission + mutator re-validation), no shell re-splitting, no computed verb, no raw playerctl invocation anywhere in the drawer"
    requirement: "DASH-04"
    verification:
      - kind: manual_procedural
        ref: "Task 1 acceptance criteria — terminal-exercised out-of-range seek/volume rejection (media-players.sh cmd <id> seek -5 / volume abc both exit 2, no player state change), motion-lint scan for playerctl/Quickshell.Services.Mpris/sh -c literals"
        status: pass
    human_judgment: false
  - id: D3
    description: "MediaTab.qml MD3 full player redrawn to the Caelestia visual convention (art-left/details-right split, heading-role title, secondary-tinted album, circular-masked cover art with dotted ring, dropdown player switcher, tonal transport with pill play/pause, source pill under art) with the D-41 in-place empty register ('Nothing playing', controls present-disabled, no slot movement) and per-field metadata fallbacks"
    requirement: "DASH-04"
    verification:
      - kind: manual_procedural
        ref: "Task 3 blocking human render-gate — six rounds, final verdict 'approved' 2026-07-29 (art crop, dropdown position, play/pause responsiveness, empty register, three-reader simultaneity)"
        status: pass
    human_judgment: true
    rationale: "Visual/aesthetic judgment (Caelestia-look fidelity, perceived responsiveness, layout correctness) requires human sign-off per ROADMAP standing constraint 1 — this is exactly what the six render-gate rounds performed and closed."

# Metrics
duration: multi-session (6 render-gate rounds)
completed: 2026-07-29
status: complete
---

# Phase 14 Plan 05: Media Tab + Shared MediaBackend Summary

**Filled MediaBackend.qml (one shared streaming reader + fixed-argv mutator dispatch) and redrew MediaTab.qml into a Caelestia-look MD3 full player, closing six render-gate rounds — the last fixing a measured 976ms MPRIS poll-latency perceived-lag with a bounded optimistic-UI latch.**

## Performance

- **Duration:** multi-session, six render-gate rounds across one day
- **Started:** 2026-07-29 (commit `8fe91cc`, 18:50 local)
- **Completed:** 2026-07-29 (commit `25eddb3`, 21:05 local; human final approval same day)
- **Tasks:** 3 (Task 1 backend, Task 2 tab, Task 3 blocking render gate — re-entered five additional times on feedback)
- **Files modified:** 2 (`MediaBackend.qml`, `MediaTab.qml`)

## Accomplishments

- `MediaBackend.qml` is now the drawer's single shared reader of the existing `media-status.sh watch` stream — one `Process` gated on `drawerOpen`, a default-safe payload shape, defensive try/catch parsing that keeps the last-good value on any malformed/truncated line, and the full derived-field surface (`displayTitle`/`displayArtist`/`displayAlbum`, `artPath`, `playing`, `positionSeconds`/`lengthSeconds`, `volumeLevel`/`hasVolume`, `canSeek`) both this tab and 14-08's future compact widget read.
- Every mutating action (play/pause, next, previous, seek, volume, player selection) is a fixed argv array dispatched through `media-players.sh` — the repo's only sanctioned MPRIS mutator — with the player id validated by `_valid_id` twice (once at list-emission time, once again by the mutator itself) and never re-split by a shell.
- `MediaTab.qml` shipped as an MD3 full player, then was rebuilt across five further render-gate rounds into the Caelestia (`github.com/caelestia-dots/shell`) visual convention: art-left/details-right split, heading-role title, secondary-tinted album, a circular-masked cover art with a dotted ring and an integrated source pill, a dropdown player switcher (not the originally planned chip row's final look — see Deviations), tonal transport buttons with a pill-shaped play/pause.
- Root-caused and fixed the play/pause "jittery/laggy" render-gate rejection by *measuring* (not guessing) the actual MPRIS round trip: `media-status.sh watch` polls at 1 Hz, and the observed status change landed 976ms after the `playerctl` command — a truth-driven-only glyph structurally always trailed the user's click by up to a second. Fixed with a bounded optimistic-UI latch confined entirely to `MediaTab.qml` (`_pendingPlaying`, `effectivePlaying`, `requestPlayPause()`), silently reconciled the instant the backend confirms, with a 2500ms fallback to backend truth for a command that never confirms. `MediaBackend.qml` was not touched for this fix — D-22's truth-driven rule stays intact at the backend layer; the optimism lives only in the view.
- Found and fixed two durable QML technical gaps along the way, both recorded as house patterns: (a) `clip: true` on a radius `Rectangle` clips only to the bounding box, not the circle — a real circular crop needs `QtQuick.Effects.MultiEffect` with `maskEnabled`/`maskSource`, and the invisible mask shape must carry `layer.enabled: true` or it silently produces an empty mask (no paint node, no art rendered at all); (b) `mapToItem()` used inside a declarative position binding is not itself reactive and silently never re-evaluates — the dropdown open-position bug was fixed by replacing it with explicit reactive ancestor x/y sums.
- All six render-gate rounds are now formally APPROVED by the human, with the final approval (2026-07-29, "approved") confirming instant play/pause response, correct circular art crop, correct dropdown open direction, and the in-place empty register.

## Task Commits

Each task was committed atomically, with five additional render-gate feedback commits after Task 2's initial landing:

1. **Task 1: MediaBackend — one streaming reader, fixed-argv mutator dispatch** - `8fe91cc` (feat)
2. **Task 2: MediaTab — the MD3 full player, per-field fallbacks, empty register** - `61ab008` (feat)
3. **Render-gate round 1-2 feedback: redesign MediaTab to Caelestia look** - `f092c2a` (feat)
4. **Render-gate round 1-2: record rejection + standing Caelestia-look directive** - `8809a61` (docs)
5. **Render-gate round 3: circular art with dotted ring + integrated source indicator** - `88ce608` (feat)
6. **Render-gate round 4: circular-mask art crop + source pill under art** - `b6fb50a` (feat)
7. **Render-gate round 5: dropdown open-position + play/pause morph** - `7b33aa5` (fix)
8. **Render-gate round 6: play/pause perceived-lag root cause — optimistic UI** - `25eddb3` (fix)

**Task 3 (checkpoint:human-verify, gate="blocking"):** re-entered six times across rounds 1 through 6; final verdict APPROVED 2026-07-29.

**Plan metadata:** committed alongside this SUMMARY (see final commit hash in the completion report).

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` - the shared streaming reader of `media-status.sh watch`, the derived display-field surface, the player list, and the six-verb fixed-argv mutator dispatch through `media-players.sh`
- `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` - the MD3 full player in the Caelestia visual convention: circular-masked cover art with dotted ring and source pill, title/artist/album type stack, seek band, tonal transport with optimistic-UI play/pause, volume band, dropdown player switcher, and the D-41 in-place empty register

## Decisions Made

- **Render-gate round 1-2 (REJECTED then redirected):** the initial vertical single-column MD3 player was rejected by the human — "I am not a fan of the media tab design. Copy caelestia's look instead, it looks more aesthetically pleasing. Do this for the rest of the tabs if applicable." This became a **standing phase-wide directive**: every remaining Phase 14 tab/content plan (14-06 Performance, 14-07 Weather, 14-08 Dashboard composition, 14-09 polish) must follow the corresponding Caelestia shell (github.com/caelestia-dots/shell) surface where an equivalent exists, adapted to this repo's Colours/Motion tokens and backends — studied from the real QML source (shallow clone), never from a screenshot.
- **Round 3 (partial accept):** circular art with a dotted ring accepted as the right direction; art clipping ("clipping and out of bounds") and pill placement ("under the album/circular dotted frame") both rejected and re-specified.
- **Round 4 (two durable technical findings, one partial accept):** (a) `clip: true` on a radius `Rectangle` only clips to the bounding box — real circular crop needs `MultiEffect` `maskEnabled`/`maskSource`, and the mask shape needs `layer.enabled: true` or the mask is empty (no paint node, art invisible); (b) corner-pixel-alpha assertions alone cannot catch that empty-mask failure mode because the background is already circular — the verification harness must also assert the center pixel matches the source color. Art clipping and pill placement approved this round; dropdown position (opened at the album art's upper-left corner) and play/pause animation ("jittery and laggy") rejected.
- **Round 5 (two fixes, one still open):** (a) dropdown fix — `mapToItem()` inside a declarative binding is not reactive; replaced with explicit reactive ancestor-chain x/y sums. (b) play/pause — the FILL variable-axis `Behavior` forced a per-frame glyph re-shape; changed to an instant, GPU-cached crossfade. Dropdown approved (opens above when space is tight — the computed-direction logic works); play/pause still judged laggy.
- **Round 6 (measured root cause, final approval):** instrumented and measured the actual MPRIS round trip rather than continuing to guess at animation timing — `media-status.sh watch` polls at 1 Hz, and the status change landed 976ms after the `playerctl` command. The glyph was bound to backend truth only, so it always trailed the click by up to ~1s regardless of animation tuning. Fixed with a bounded optimistic-UI latch entirely inside `MediaTab.qml` (`_pendingPlaying` latch, `effectivePlaying`, `requestPlayPause()`), silent reconciliation on backend confirmation, 2500ms fallback to backend truth for a failed/unconfirmed command. `MediaBackend.qml` untouched — D-22's truth-driven rule preserved at the backend layer. Verified with a mock-latency harness (5/5 assertions). **Human verdict: APPROVED — instant response confirmed.**
- The optimistic-UI latch + reconciliation + timeout-fallback pattern is now the house convention for any future control backed by a slow/polled backend.
- The `MultiEffect` mask + `layer.enabled` on the mask shape is now the house pattern for non-rectangular image crops.
- `mapToItem()` is now banned from declarative position bindings repo-wide — compute from reactive ancestor geometry, or call it imperatively at a discrete triggering event (e.g., dropdown open).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Circular art crop rendered as a bounding-box crop, not a true circle**
- **Found during:** Render-gate round 4
- **Issue:** `clip: true` on a radius `Rectangle` clips content to the item's rectangular bounding box, not to the rounded shape — art appeared clipped/out-of-bounds at the corners, exactly as the human called out at round 3.
- **Fix:** Replaced with `QtQuick.Effects.MultiEffect` `maskEnabled: true` / `maskSource` pointed at an invisible circular mask shape carrying `layer.enabled: true` (without which the mask silently produces no paint node and the art vanishes entirely).
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml`
- **Verification:** center-pixel-alpha assertion added alongside the pre-existing corner-pixel assertion (corner-only checks cannot distinguish "correctly masked" from "empty mask over an already-circular background").
- **Committed in:** `b6fb50a`

**2. [Rule 1 - Bug] Dropdown player switcher opened at the wrong position (album art's upper-left corner)**
- **Found during:** Render-gate round 4
- **Issue:** Dropdown open-position was computed via `mapToItem()` inside a declarative QML binding; `mapToItem()` does not participate in QML's reactivity system, so the binding silently never re-evaluated after the anchor geometry settled.
- **Fix:** Replaced with an explicit reactive expression summing the ancestor chain's `x`/`y` properties directly, and added a computed open-direction (opens above when there isn't room below).
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml`
- **Verification:** human-observed at round 5 — dropdown opens correctly including the tight-space-above case.
- **Committed in:** `7b33aa5`

**3. [Rule 1 - Bug] Play/pause glyph morph read as jittery/laggy across two feedback rounds**
- **Found during:** Render-gate round 4 (reported), round 5 (partially fixed, still judged laggy), round 6 (root-caused and fixed)
- **Issue:** Round 5's fix (removing the per-frame FILL-axis `Behavior` in favor of an instant GPU-cached crossfade) addressed the animation mechanics but not the underlying cause: the glyph was bound purely to backend truth, and `media-status.sh watch` only re-emits at 1 Hz, with the actual player status change measured at 976ms after the dispatched command. No animation tuning could close that gap because the true state genuinely hadn't arrived yet.
- **Fix:** Added a bounded optimistic-UI latch in `MediaTab.qml` (`_pendingPlaying`, `effectivePlaying`, `requestPlayPause()`) that shows the expected new state immediately on press, reconciles silently the moment the backend confirms, and falls back to backend truth after 2500ms if no confirmation arrives (covers a refused or failed command). `MediaBackend.qml` is untouched — the truth-driven contract (D-22) still governs the backend; the tab layer alone now tolerates the backend's measured latency.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml`
- **Verification:** mock-latency test harness, 5/5 assertions; human final approval 2026-07-29 ("approved" — instant response confirmed).
- **Committed in:** `25eddb3`

**4. [Rule 4-adjacent, human-directed] Player-switcher UI redesigned from planned chips to a dropdown**
- **Found during:** Render-gate round 3 feedback
- **Issue:** The plan's locked artifact (`playerChipRow`/`PlayerChip`) specified a chip row; the human's Caelestia-look directive plus round-3/4 feedback on pill/source placement drove the switcher toward a dropdown-style control that better matched the Caelestia visual reference and the source-pill placement the human asked for.
- **Resolution:** This is a human-directed visual change made under the standing Caelestia-look directive (round 1-2), not an unrequested architectural change — the backend contract (`selectPlayer()`, the player list, the active-id predicate) is unchanged; only the switcher's rendered shape moved from chips to a dropdown. Recorded here rather than silently reconciled against the plan's original artifact name, since the plan's `key_links`/`artifacts` block names `playerChipRow` explicitly.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml`
- **Committed in:** `88ce608`, `b6fb50a`, `7b33aa5` (progressive refinement across rounds 3-5)

---

**Total deviations:** 3 auto-fixed (Rule 1 bugs) + 1 human-directed visual redesign under the standing Caelestia directive.
**Impact on plan:** All three Rule 1 fixes were necessary for correctness (a broken circular crop, a dead reactive binding, and a structurally-impossible-to-fix-via-animation-alone latency perception). The chip-to-dropdown change was explicitly requested by the human at the render gate under the same directive that redirected the whole tab's visual language — no scope creep, no unrequested architecture change.

## Issues Encountered

The render gate took six rounds to close, longer than this plan's single blocking checkpoint anticipated. Each round surfaced a concrete, specific issue (never a vague "doesn't feel right") and each was root-caused rather than patched by animation-tuning guesswork — most notably round 6, where the fix required *measuring* the actual MPRIS command-to-status-change latency (976ms) rather than continuing to adjust motion timing, which could never have closed a gap caused by data arrival, not rendering. All six rounds are now resolved and approved.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `MediaBackend.qml`'s derived-field surface (`displayTitle`/`displayArtist`/`displayAlbum`, `artPath`, `playing`, `positionSeconds`/`lengthSeconds`, `volumeLevel`/`hasVolume`, `canSeek`, the player list) is ready for 14-08's compact Dashboard-tab media widget to read as its second consumer — no second stream needed.
- The three durable QML findings (MultiEffect mask + `layer.enabled`, `mapToItem()` non-reactivity, optimistic-UI latch pattern) are now recorded house patterns any of 14-06/14-07/14-08/14-09 can reuse without rediscovering them.
- The standing Caelestia-look directive is now binding on every remaining Phase 14 tab/content plan — 14-06 (Performance), 14-07 (Weather already shipped, complete), 14-08 (Dashboard composition), and 14-09 (polish) must each study the corresponding real Caelestia QML source before drawing their surface.
- All verification gates green at close: `motion-lint` reports CHECK A/CHECK B PASS on both files touched, `~/.cache/quickshell.log` clean, and the frozen files (`qmldir`, `Dashboard.qml`, `shell.qml`, `DashboardTab.qml`, `media-status.sh`, `media-players.sh`) remain byte-unchanged per `git diff --numstat`.
- DASH-04 is now complete: the Media tab shows a full player with cover art, reading the existing MPRIS backend (`media-status.sh`/`media-players.sh`) rather than a second media source.
- The three-reader simultaneity observation (AGS card, waybar's mpris module, and this tab naming the same track at the same moment) was recorded live as input for 14-09's formal roadmap-criterion-4 proof — not a substitute for it.

---
*Phase: 14-dashboard-drawer*
*Completed: 2026-07-29*
