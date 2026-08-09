---
phase: 17-ambient-extras
plan: 03
subsystem: infra
tags: [mpvpaper, wallpaper-picker, fzf, hyprlock, hypridle, theme-engine, quickshell-doctor, hyprland, bash]

# Dependency graph
requires: ["17-01", "17-02"]
provides:
  - "wallpaper-picker.sh: merged still+live enumeration list, live marker (▶), frame-aware preview pane, widened writer-side guard, hover debounce (0.25s settle), single Esc-restore intent"
  - "theme_engine_wallpaper_sync_owner in lib/wallpaper.sh — D-21's single owner-declaration path (login/theme-switch/manual-pick, one function, no second call site)"
  - "wallpaper-visibility.sh: snapshot/restore verbs (D-20)"
  - "hypridle.conf 300s listener extended with idle hide/show (D-30, no new listener); gaming-mode-toggle.sh wired for D-28 including the stranded-idle mirror; motion-scale off/on suppression via sync_owner (D-31, no new call site)"
  - "quickshell-doctor mpvpaper-layer-coexistence check + 2 fixtures (standing constraint #4)"
  - "Post-checkpoint fix: hover settle block also writes current.jpg/last-wallpaper (mirrors confirm); Esc restores both; autoset skips redundant re-extraction"
affects: [17-06]

# Actuals (#2632)
actuals:
  tokens: 16266
  tasks: 5
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Hover-as-provisional-confirm: a debounce-settled live hover now writes the SAME two state artifacts (current.jpg symlink, last-wallpaper/<theme>) that an explicit confirm writes, and Esc reverts both to values snapshotted at picker startup — closes the gap where a real, persistent desktop side effect (mpvpaper playing) was invisible to every OTHER state consumer (hyprlock, the next unrelated theme-apply run)"
    - "declare -f <fn> emitted into a generated heredoc script's prologue — one canonical function definition (wp_strip_markers) reused verbatim in three separately-executed scripts instead of copy-pasted"
    - "Cache-warm re-extraction guard ([[ ! -s \"$frame\" ]] before calling the ffmpeg wrapper) — now applied consistently at every frame consumer (preview pane, frame_repair, autoset, the hover settle block)"

key-files:
  created:
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-mpvpaper-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-mpvpaper-layers.json
  modified:
    - hypr/.config/hypr/scripts/wallpaper-picker.sh
    - hypr/.config/hypr/scripts/wallpaper-visibility.sh
    - hypr/.config/hypr/scripts/gaming-mode-toggle.sh
    - hypr/.config/hypr/scripts/quickshell-doctor
    - hypr/.config/hypr/hypridle.conf
    - theme-engine/.config/theme-engine/lib/wallpaper.sh
    - theme-engine/.config/theme-engine/theme-apply

key-decisions:
  - "D-17 marker glyph shipped: LIVE_MARKER=' ▶' (space + U+25B6), distinct from the pre-existing ACTIVE_MARKER=' ●'. A live+active entry renders '... ▶ ●' — LIVE_MARKER stripped second, matching wp_strip_markers' peel order. Human-judged legible at the render gate (no objection raised)."
  - "D-19 debounce interval shipped: 0.25s settle, 0.35s exit-drain (slightly longer than the debounce, so a settle block that hasn't re-checked its token yet always loses the race to the picker's own final intent). Both are stated baselines for a future retune, not re-derived from a measurement — CONTEXT.md left them as Claude's discretion."
  - "17-02 handoff (a) closed: wallpaper-picker.sh:346's writer-side guard widened by delegating to theme_engine_wallpaper_is_live_ref (the SAME shape function 17-02's reader uses) — never a second regex, never a prefix test. A live pick now round-trips through last-wallpaper/<theme> for the first time."
  - "17-02 handoff (b) closed: the active-entry regression (current.jpg resolving under wallpaper-frames/ instead of under WALLPAPER_DIR_REAL, silently zeroing the active marker for every entry) fixed by adding an explicit second branch in ENUM_SCRIPT that re-derives the active entry from last-wallpaper's OWN recorded value when current.jpg resolves under FRAME_DIR_REAL, rather than reverse-matching current.jpg's target against the wallpaper tree."
  - "D-28 flagged assumption resolved: gaming-mode-toggle.sh confirmed LIVE, not silently dead. Lines 113-116/164-188 already use hyprctl eval + hl.config({...}), migrated by 13.1-10. Only the file's OWN header comment still claimed the pre-13.1 hyprctl keyword form — corrected in this plan's Task 2, live-verified both ON and OFF cycles including the stranded-idle case (gaming ON while idle-hidden, gaming OFF must still return the wallpaper)."
  - "hypridle command chaining confirmed live on the installed binary (standing constraint #2): a scratch hypridle instance with a 2s listener proved both on-timeout and on-resume execute a && chain of two commands in full and in order — chosen over the documented wrapper-script fallback, which was not needed."
  - "Root-cause finding from the render-gate's OWN checkpoint round 2 (see below): hovering a live entry starts a real, persistent mpvpaper process but — as originally built in Tasks 1-4 — never updated current.jpg or last-wallpaper/<theme>, only an explicit confirm did. Fixed by making the hover settle block ALSO write both (mirroring confirm) and Esc restore both (extending D-20). This is a genuine behavioral-contract change from what Tasks 1-4 shipped, made necessary by live verification, not assumed at planning time."

requirements-completed: []

coverage:
  - id: D1
    description: "Picker lists a theme's live wallpapers alongside its stills in one merged list (D-03 still pool untouched, separate unfiltered live/ pass), each live entry carrying the ▶ marker, previewed as the cached extracted frame at the D-09 offset (D-18) — and the 17-02 active-marker regression is closed with a before/after count proving it (0 active markers before the fix with a live choice recorded, 1 correct one after)"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "Live enumeration against the real catppuccin theme (6 stills + 3 live entries, correct markers); regression fixture (last-wallpaper set to live/tracer-probe.mp4, current.jpg resolving into wallpaper-frames/) reproduced 0-active-markers before the fix, 1-active-marker (the live entry, both markers) after; preview script run twice against tracer-probe.mp4 produced a real 1920x1080 PNG on first run, byte-identical mtime on second (cache warm); D-09 offset sidecar and no-sidecar paths both produced a frame; zero-byte broken.mp4 degraded to a printed notice with current.jpg untouched; grep confirms zero ffmpeg call sites outside the sourced library"
        status: pass
    human_judgment: false
  - id: D2
    description: "theme_engine_wallpaper_sync_owner is the single D-21 owner-declaration path — login, a theme switch, and a manual picker pick all reach wallpaper-visibility.sh through this one function (theme-apply's call site sits strictly between autoset and reload); the picker's writer-side guard is widened (17-02 handoff (a)) so a live pick now records end to end; gaming/idle/reduced-motion suppression all wired and verified live including the stranded-idle case"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "grep confirms owner invocations exist only inside sync_owner, hypridle.conf, gaming-mode-toggle.sh — never in wallpaper-picker.sh/theme-apply/theme-init.sh/motion-switch.sh directly; git diff --quiet confirms motion-switch.sh/theme-init.sh/autostart.lua untouched; live sync_owner calls proven for a no-ref read (clears to the recorded still), an explicit live ref (selects+plays), an empty-string ref (clears, simulating a cross-theme still pick), and motion-scale=off (suppresses regardless of a valid selection) and back; full picker selection-handler run against a real live entry correctly widened the writer guard end to end (last-wallpaper became 'live/tracer-probe.mp4' verbatim) and repointed current.jpg to a real PNG frame; gaming-mode-toggle.sh ON/OFF proven live plus the stranded-idle scenario (idle hide standing, gaming ON, gaming OFF — wallpaper correctly returned, closing the exact bug class lines 200-213 already document for waybar)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hover debounce (D-19): a live entry is dispatched to the owner only after surviving a 0.25s settle, never on every keystroke; rapid navigation through many entries leaves exactly one player naming the last entry; the exit drain (write a sentinel, sleep past the debounce, then issue the final intent) makes an orphaned start-after-exit impossible. Single Esc-restore intent (D-20): snapshot/restore verbs added to wallpaper-visibility.sh, reused (not re-derived) by _validate_selection, failing closed to clear on a deleted/invalid snapshot"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "Live-timed: generated live script returns in ~6ms (well under the 250ms debounce); 10 rapid live-script invocations across two different files left exactly one real (non-zombie) mpvpaper process naming the LAST entry invoked; orphan case (hover, then immediately drain+restore before the 250ms settle) left no player; snapshot/restore proven live for a live-prior-state round trip, a still-prior-state round trip, and a fail-closed case (snapshot names a file deleted before restore runs, ends with no player); grep confirms zero mpvpaper/pkill/kill/eval references in wallpaper-picker.sh outside comments"
        status: pass
    human_judgment: false
  - id: D4
    description: "quickshell-doctor proves the live wallpaper's layer surface sits on the background level (0) under an mpvpaper-owned PID, never colliding with a quickshell- surface at that level nor appearing itself at the shell's overlay level (3); skips cleanly (never fails) on a still-only desktop; the PID set is an explicit assertion parameter (never a live pgrep inside the helper) so the two committed fixtures replay identically on any host"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "Live PASS with a real wallpaper playing (count=1 off-level=0 wrong-pid=0); live SKIP with none selected; --self-test 38/38 replays pass including the 2 new mpvpaper fixtures (compliant PASSES, poisoned-offlevel FAILS) and all 36 pre-existing replays unchanged; a bounded --no-summon --no-headless-output --no-panel-checks run exited 0 (17 passed, 0 failed) with no state mutation attributable to the new check (find -newer + git status --porcelain both clean of it)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The AMB-01 blocking human render-and-look gate (standing constraint #1) — every visual state the wallpaper has, judged by a human across two checkpoint rounds"
    requirement: AMB-01
    verification:
      - kind: manual_procedural
        ref: "17-03-PLAN.md Task 5's 10-step how-to-verify, run twice: round 1 passed steps 1-7 and 10 on first attempt, FAILED steps 8 (lock screen stuck on the last still) and 9 (motion-off swapped to the last used still instead of stopping cleanly on the video's own frame); round 2, after the fix in 87f539e, re-verified steps 8 and 9 only (the other eight were not re-tested per the coordinator's own instruction, since the fix touches only the hover/cancel/autoset paths) — APPROVED"
        status: pass
    human_judgment: true
    rationale: "Standing constraint #1: a human render-and-look gate is load-bearing, not a formality — machines prove tokens/state resolve, only a human judges whether the desktop reads correctly and looks right. This plan's own checkpoint (gate=\"blocking\") explicitly forbids auto-approval."

duration: ~50min execution + 2 render-gate checkpoint round-trips (human verification wait excluded)
completed: 2026-08-09
status: complete
---

# Phase 17 Plan 03: Live Wallpaper Picker, Sync Owner, Debounce/Restore, Coexistence Gate Summary

**The live wallpaper became usable end to end — merged still+live picker list with a cached frame-aware preview, one `theme_engine_wallpaper_sync_owner` function serving login/theme-switch/manual-pick, a debounced hover that can't orphan a player, a single Esc-restore intent, three suppression states, and a `quickshell-doctor` layer-coexistence gate — but shipped with a real bug the render gate caught on its first pass: hovering a live entry started real, persistent playback without ever updating `current.jpg`/`last-wallpaper`, so the lock screen and any unrelated `theme-apply` re-render (motion-scale, in particular) silently reverted to a stale still. Root-caused to one mechanism behind both failing steps and fixed in `87f539e`; re-verified and approved.**

## Performance

- **Duration:** ~50 min for Tasks 1-4 (commit timestamps a1ce086 07:21:49 → 26ea162 07:39:07), plus the round-2 investigation/fix (87f539e 08:08:49), plus two full human checkpoint round-trips (verification wait time not included in the above)
- **Started:** 2026-08-09 (orchestrator phase-start marker for this plan)
- **Completed:** 2026-08-09
- **Tasks:** 5 (4 `type="auto"` + 1 `type="checkpoint:human-verify" gate="blocking"`, run twice)
- **Files modified:** 9 (2 created, 7 modified)

## Accomplishments

- `wallpaper-picker.sh` gained a separate, unfiltered `live/` enumeration pass (D-03, never merged into the still pool), a distinct `▶` live marker alongside the existing `●` active marker with one order-independent `wp_strip_markers` helper (replacing every open-coded strip in the file, `declare -f`-emitted into both generated script prologues), and a frame-aware preview pane that extracts-once/caches through 17-02's library functions.
- Closed both 17-02 handoffs: the picker's writer-side guard widened (delegating to `theme_engine_wallpaper_is_live_ref`, never a prefix test or a fresh regex) so a live pick now records end to end for the first time; the active-marker regression from `current.jpg` resolving under `wallpaper-frames/` (silently zeroing the marker for every entry) closed with a second explicit branch that re-derives the active entry from `last-wallpaper`'s own recorded value.
- `theme_engine_wallpaper_sync_owner` built as D-21's single owner-declaration path — login (`theme-init.sh` → `theme-apply`), a theme switch, and a manual picker pick all reach `wallpaper-visibility.sh` through this one function, placed strictly between `autoset` and `reload` in `theme-apply`.
- Three suppression states wired and live-verified: D-30 idle (chained onto the existing 300s dim listener — command chaining confirmed on the installed `hypridle` binary via a scratch instance, no new listener), D-28 gaming (mirrors the existing waybar toggle exactly, including the stranded-idle fix), D-31 reduced motion (`sync_owner` reads `motion-scale` directly, no new call site — `motion-switch.sh` stays untouched).
- `wallpaper-visibility.sh` gained `snapshot`/`restore` verbs (D-20) reusing `_validate_selection`, failing closed to `clear`; the generated live-preview script's hover dispatch now debounces (0.25s settle) with a serialised kill via the owner's existing `flock`, and an exit drain on the picker's own Cleanup path closes the orphan window D-19 named.
- `quickshell-doctor` gained `_qsd_check_mpvpaper_layer_coexistence`, proving the live wallpaper's layer surface sits on the background level under an mpvpaper-owned PID and never collides with a `quickshell-` surface — report-only, skips cleanly on a still-only desktop, proven via 2 committed fixtures replayed by `--self-test` (38/38 green).
- **The render gate found a real bug on its first pass** (see Deviations below) — root-caused to one mechanism, fixed once, re-verified and approved on the second pass.

## Task Commits

Each task was committed atomically:

1. **Task 1: Picker enumeration, live marker, frame-aware preview, 17-02 handoffs** - `a1ce086` (feat)
2. **Task 2: One sync-owner path (login/switch/pick), plus 3 suppression states** - `e0e6952` (feat)
3. **Task 3: Hover debounce with serialised kill, single Esc-restore intent** - `eba2051` (feat)
4. **Task 4: `quickshell-doctor` mpvpaper layer-coexistence gate** - `26ea162` (feat)
5. **Task 5: Checkpoint — the AMB-01 render-and-look gate** - no file diff by design (evidence-only); round 1 found real bugs, fixed in a post-checkpoint commit below, round 2 approved
6. **Post-checkpoint fix (Rule 1 — bug found live during Task 5's own verification)** - `87f539e` (fix)

## Files Created/Modified

- `hypr/.config/hypr/scripts/wallpaper-picker.sh` — live enumeration, marker vocabulary, frame-aware preview, widened writer guard, hover debounce, Esc-restore (extended twice: Tasks 1-3, then the round-2 fix)
- `hypr/.config/hypr/scripts/wallpaper-visibility.sh` — `snapshot`/`restore` verbs
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` — `_gaming_wallpaper_toggle`, the stranded-idle mirror call, corrected header comment
- `hypr/.config/hypr/scripts/quickshell-doctor` — `_qsd_mpvpaper_layer_rows`/`_qsd_assert_mpvpaper_layers`/`_qsd_check_mpvpaper_layer_coexistence`, tail call site, 2 `--self-test` replays
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-mpvpaper-layers.json` (new) — real live capture, mpvpaper on the background level
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-mpvpaper-layers.json` (new) — hand-edited, mpvpaper moved to the overlay level
- `hypr/.config/hypr/hypridle.conf` — the existing 300s listener extended with `idle hide`/`idle show`, no new listener block
- `theme-engine/.config/theme-engine/lib/wallpaper.sh` — `theme_engine_wallpaper_sync_owner` (new), `autoset`'s live branch hardened with a cache-warm re-extraction guard
- `theme-engine/.config/theme-engine/theme-apply` — one `theme_engine_wallpaper_sync_owner "$NAME" || true` call site between `autoset` and `reload`

## Decisions Made

See `key-decisions` in frontmatter for the full list with rationale. Summary:
- D-17 glyph: `▶` (live), distinct from `●` (active); human-judged legible at the render gate.
- D-19 debounce: 0.25s settle / 0.35s drain, stated baselines for a future retune.
- Both 17-02 handoffs closed by delegation to the SAME shape function the engine's reader already uses — never a second regex.
- D-28 confirmed live (gaming-mode-toggle.sh is not dead); the stale header comment corrected.
- hypridle command chaining confirmed live (no wrapper-script fallback needed).
- **Round-2 architectural finding:** a debounce-settled hover is now treated as a provisional, revertible confirm for state-persistence purposes (writes `current.jpg`/`last-wallpaper`, reverted by Esc) — see next section for the full account, since this was not assumed at planning time and was discovered only through live render-gate verification.

## The Interface Handoff to 17-02, Closed — Before/After Counts

Requested explicitly by this plan's own `<output>` spec:

- **Active-marker regression (17-02 handoff (b)):** before this plan's fix, with a live choice recorded (`last-wallpaper/<theme>` = `live/tracer-probe.mp4`) and `current.jpg` resolving into `wallpaper-frames/`, the enumeration output carried **0** entries with the active marker (verified by running the pre-fix `ENUM_SCRIPT` logic against this exact state). After the fix: **1** entry carries the active marker, and it is the correct live entry (`catppuccin/live/tracer-probe.mp4 ▶ ●`).
- **Writer-side guard (17-02 handoff (a)):** confirmed widened by delegation — `grep -cF -- '"$BARE_FILENAME" != */*'` returns 1 (the pre-existing branch byte-identical), and the added branch calls `theme_engine_wallpaper_is_live_ref "$BARE_FILENAME"` directly, never a new regex or a prefix test (`grep -c 'live/\*'`-style pattern: zero occurrences). Live-verified: selecting `catppuccin/live/tracer-probe.mp4` in the active theme records `last-wallpaper/catppuccin` as exactly `live/tracer-probe.mp4`.

## The AMB-01 Render Gate — Full Result (Both Rounds)

**Round 1** (10-step `how-to-verify`, run against Tasks 1-4's shipped state): steps **1-7 and 10 passed** on first attempt. Steps **8 and 9 failed**, verbatim from the coordinator's relay of the user's own words:

- **Step 8:** *"lockscreen is stuck on the last still wallpaper and doesn't pickup the live wallpaper"*
- **Step 9:** *"selecting off for animations does not pause the wallpaper. It instead changes it to the last used still wallpaper"*

**Root cause, confirmed by direct live reproduction (not assumed):** hovering a live entry starts a real, persistent `mpvpaper` process on the actual desktop — visually indistinguishable from a confirmed pick — but, as Tasks 1-4 originally shipped it, never touched `current.jpg` or `last-wallpaper/<theme>`; only an explicit confirm (pressing Enter) did. `hyprlock.conf:50` reads `current.jpg` directly (step 8's failure). `theme_engine_wallpaper_autoset` re-derives `current.jpg` from `last-wallpaper/<theme>` on **every** `theme-apply` call, including `motion-switch.sh`'s own unrelated full re-render (step 9's failure) — the instant that ran, it silently repainted the desktop with whatever was last actually confirmed (or the theme default), the moment `sync_owner`'s correct `motion hide` stopped the player and let the awww-daemon layer underneath become visible again.

**The second-order question, answered explicitly (as the coordinator required):** this fixes *"shows the wrong image"* — the desktop must always show the actually-playing video's own frame — **not** *"should show a still instead of pausing."* The stop behavior itself (`motion`/`gaming`/`idle` correctly terminate the `mpvpaper` process, no position preservation, per D-29's own design) was already correct and independently verified working before this bug was found; it was not touched by the fix.

**Fix (`87f539e`):** the hover debounce's settle block — only after surviving the 0.25s debounce, never on every keystroke — now also repoints `current.jpg` to the entry's own frame and records `last-wallpaper/<theme>`, mirroring exactly what confirm already does. Esc now restores both back to their exact pre-session values (captured at picker startup, before any hover can fire), extending D-20's "restore the exact prior state" guarantee to cover this file, not just `current.jpg`'s repaint and the owner's process state. `theme_engine_wallpaper_autoset` was also hardened to skip re-extraction when the frame is already cached (see the dedicated section below — a related but secondary finding).

**Round 2** (steps 8 and 9 only, per the coordinator's own scoping — the other eight untouched by the fix's code paths did not need re-testing): **APPROVED.** AMB-01's render gate is closed; all 10 steps signed off across the two rounds.

## The New Hover Side-Effect Contract (Behavioral Change From What Tasks 1-4 Shipped)

Stated explicitly as a contract, per the coordinator's instruction, because it is a real, user-visible behavior a future editor or the 17-06 sweep needs to know about:

**A live entry hovered in the picker, once its selection survives the 0.25s debounce (i.e., mpvpaper actually starts playing it), now writes BOTH of the following, exactly as an explicit confirm would:**
1. `~/Pictures/Wallpapers/current.jpg` — relinked to that entry's extracted frame.
2. `~/.local/state/theme/last-wallpaper/<current-theme>` — set to that entry's relative path (in-theme hovers only; an out-of-theme Ctrl-A hover is not recorded, matching confirm's own scoping rule).

**Esc (cancel) reverts both** to the exact values captured at picker startup, before any hover could fire — `PREVIOUS_WALLPAPER` (already existed) and the newly-added `PREVIOUS_LAST_WALLPAPER`/`PREVIOUS_THEME_FOR_SNAPSHOT`. Confirmed live for both directions: a still-prior-state session that hovers a live entry then cancels correctly reverts to the still (both `current.jpg` and `last-wallpaper`); a live-prior-state session that hovers a *different* live entry then cancels correctly restores the *original* entry (both files), not the hovered one and not a blank state.

**The residual, stated explicitly for 17-06's sweep:** this restore-on-Esc guarantee depends on the picker process reaching its own Esc-handling code. **If the picker terminates any other way — killed, crashed, or the terminal closed without Esc or Enter — the hovered wallpaper's write to `current.jpg`/`last-wallpaper` stays recorded**, exactly as if it had been confirmed. This is a pre-existing risk class this plan did not introduce (the owner's own process state has always had the same property — a killed picker leaves whatever was last selected via the owner playing), but it now also applies to these two additional files. No code changes further from this plan; flagged here so 17-06's UAT/audit sweep knows this path exists and is not undocumented.

## The `autoset` Re-Extraction Skip — Explicitly Not the Root Cause

Stated plainly, per the coordinator's instruction: `theme_engine_wallpaper_autoset`'s live branch was hardened in the SAME commit (`87f539e`) to skip re-extraction when the frame is already cached (`[[ ! -s "$frame" ]]` guard, matching the convention `theme_engine_wallpaper_frame_repair` and the picker's own preview pane already used). **This was found during the investigation as a real, independently-justifiable gap — autoset was the only frame consumer in the whole file that re-extracted unconditionally on every call, wasting a full `ffmpeg` invocation on every unrelated `theme-apply` re-render — but it was NOT the render gate's root cause.** Direct reproduction confirmed the unconditional-re-extraction version still correctly resolved to the frame when `last-wallpaper` held the correct recorded value; the actual failure only appeared when `last-wallpaper` itself held a stale value, which is the hover-never-persisted bug documented above. Both fixes shipped together because they touch the same function and the same investigation, not because the second was required to close the gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, found live during Task 5's own render-gate verification] Hover started real playback without updating `current.jpg`/`last-wallpaper`**
- **Found during:** Task 5 (the blocking human render-and-look gate), round 1 — steps 8 and 9 both failed
- **Issue:** See "The AMB-01 Render Gate — Full Result" section above for the full root-cause account.
- **Fix:** See "The New Hover Side-Effect Contract" section above.
- **Files modified:** `hypr/.config/hypr/scripts/wallpaper-picker.sh`, `theme-engine/.config/theme-engine/lib/wallpaper.sh`
- **Verification:** Live-reproduced before AND after the fix (hover-only-no-confirm scenario, lock-screen path resolution, `motion-switch.sh off`/`normal` cycle, both Esc-restore directions, still-hover non-regression, rapid-nav debounce non-regression, orphan-drain non-regression) — see commit `87f539e`'s own message for the full list. Confirmed by the render gate's own round-2 human approval.
- **Committed in:** `87f539e`

---

**Total deviations:** 1 auto-fixed (Rule 1 — a real bug found live by the render gate's own verification, not assumed or skipped)
**Impact on plan:** The fix was necessary for AMB-01's own core correctness invariant (what's actually playing must be what every consumer of the wallpaper state sees) and was found only because the render gate insisted on watching every state the wallpaper has, per standing constraint #1 — exactly the purpose that gate exists to serve. No scope creep: both changed files were already this plan's own declared scope; the fix stayed inside the hover/cancel/autoset code paths this plan's own Tasks 1-3 had already touched.

## Issues Encountered

- **Two heredoc-slicing mistakes in this session's own live-verification test harnesses** (not shipped code): extracting a runnable prefix of `wallpaper-picker.sh` for a scripted reproduction twice cut off mid-heredoc (the file grew across Tasks 1-3, moving the `LIVE_SCRIPT` heredoc's true closing line), producing a false "nothing happened" result that briefly looked like a code bug before the line-count mismatch was caught and corrected. Recorded honestly since it consumed real investigation time before the actual bug was found; no shipped file was affected.
- **A render-gate round-1 finding required a full live root-cause investigation** rather than a quick patch — see the dedicated section above. Investigated methodically (multiple full reproduction sequences against the real desktop, a targeted forced-failure test of the D-13 dead-entry branch to rule it out, then the correct hover-without-confirm reproduction) before writing any fix, per the coordinator's own explicit instruction not to guess.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- AMB-01's render gate is closed (all 10 steps signed off across 2 rounds). Per this plan's own explicit instruction, AMB-01 is **NOT** marked complete in `REQUIREMENTS.md` — 17-06 owns that at phase close (see commit `996440b`, which reverted an earlier premature completion mark for exactly this reason).
- The hover side-effect contract (see dedicated section above) is new, real, user-visible behavior 17-06's UAT/audit sweep should be aware of, including its stated residual (a killed/crashed picker leaves a hover-recorded choice standing, same as it always has for the owner's own process state).
- No blockers. The real desktop is left in a working, consistent state: `current-theme=catppuccin`, `last-wallpaper/catppuccin=live/tracer-probe.mp4`, `current.jpg` resolving to that video's own extracted frame under `wallpaper-frames/catppuccin/`, exactly one real `mpvpaper` process at layer level 0, `motion-scale=normal`, `gaming-mode=off`.
- Carried forward, not this plan's scope: the AMB-01 spec-less flagged assumption (owned by 17-01, restated unchanged by 17-01/17-02's own summaries); this plan's own D-28 flagged assumption is now **resolved** (gaming-mode-toggle.sh confirmed live, not dead — see key-decisions); 17-06's criterion-3 cut sweep and phase close.

---
*Phase: 17-ambient-extras*
*Completed: 2026-08-09*

## Self-Check: PASSED

All 9 modified/created source files confirmed present on disk (`hypr/.config/hypr/scripts/wallpaper-picker.sh`, `hypr/.config/hypr/scripts/wallpaper-visibility.sh`, `hypr/.config/hypr/scripts/gaming-mode-toggle.sh`, `hypr/.config/hypr/scripts/quickshell-doctor`, `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-mpvpaper-layers.json`, `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-mpvpaper-layers.json`, `hypr/.config/hypr/hypridle.conf`, `theme-engine/.config/theme-engine/lib/wallpaper.sh`, `theme-engine/.config/theme-engine/theme-apply`) plus this SUMMARY.md. All 5 task/fix commits (`a1ce086`, `e0e6952`, `eba2051`, `26ea162`, `87f539e`) confirmed present in `git log --oneline --all`.
