---
phase: 01-root-cause-fix-consolidated-theme-engine
plan: 03
subsystem: theming-pipeline
tags: [walker, elephant, thunar, gtk3, gtk4, gsettings, theme-doctor, yazi, bounded-poll]

requires:
  - phase: 01-root-cause-fix-consolidated-theme-engine
    provides: "theme-engine/ stow package (theme-apply, theme-doctor, lib/{generate,commit,reload,gtk}.sh), state-dir contract at ~/.local/state/theme/, single reload owner"
provides:
  - "Hardened Walker restart in lib/reload.sh: kill + bounded pgrep poll + elephant socket/health/version gate before relaunch (no hot-reload key exists in walker 2.16.2, restart-only per corrected D-16)"
  - "Hardened Thunar daemon restart in lib/gtk.sh: bounded pgrep poll, deferred-and-deduped watcher that fires once the last open window closes, no windowed-instance kill"
  - "GTK4/libadwaita dark-mode + hue-mapped accent-color gsettings wiring (documented ceiling: full palette theming is structurally unsupported upstream)"
  - "theme-doctor extended with walker/elephant version-match + elephant listproviders vs walker config.toml provider-parity checks (21/22 invariants pass; the 1 known gap is the deferred elephant provider install, Phase 3 INST-01)"
  - "Retired hypr/.config/hypr/scripts/{walker-restart.sh, walker-theme-gen.sh, gtk-reload.sh} — logic folded into the engine"
  - "yazi OpenRule schema migrated from the retired name key to url/mime (installed yazi 26.5.6 breaking change, unrelated to theming but blocking)"
  - "Human-verified end-to-end: all ten fan-out targets (Hyprland, waybar, kitty, swaync, wlogout, GTK3/Thunar, GTK4, walker, yazi, vscodium) re-theme live on one switch in both static and dynamic modes, no relogin"
affects:
  - phase-02 (parity/repeated-switch stress test now runs against the fully hardened restart paths from this plan)
  - phase-03 (the one deferred theme-doctor gap — elephant listproviders missing files/menus/providerlist/runner/websearch — is explicitly carried to INST-01 verification)

tech-stack:
  added: []
  patterns:
    - "elephant health gate before declaring a restart complete: socket presence + `elephant version` response + walker/elephant version compatibility, so a stale/mismatched elephant is never mistaken for a themed walker"
    - "deferred-and-deduped restart watcher: when a GTK3 daemon can't be restarted immediately because windows are open, a single bounded-poll background watcher (capped iterations, not a fixed sleep) fires the restart once the last window closes, instead of silently dropping the re-theme"
    - "bounded pgrep poll replaces every fixed sleep used as a process-exit wait (walker restart, thunar daemon restart)"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/lib/reload.sh
    - theme-engine/.config/theme-engine/lib/gtk.sh
    - theme-engine/.config/theme-engine/theme-doctor
    - matugen/.config/matugen/templates/walker-style.css
    - matugen/.config/matugen/templates/yazi-theme.toml
    - yazi/.config/yazi/yazi.toml
  removed:
    - hypr/.config/hypr/scripts/walker-restart.sh
    - hypr/.config/hypr/scripts/walker-theme-gen.sh
    - hypr/.config/hypr/scripts/gtk-reload.sh

decisions:
  - "`set -e` combined with `(( counter++ ))` at counter=0 evaluates to a false/0 return, tripping `set -e` and silently aborting theme-apply mid-reload before the walker relaunch line ran — this was the actual reason no walker process existed after a switch, not a CSS or restart-logic bug. Fixed by rewriting the counter increment to a form that doesn't trip `set -e` at zero (e.g. `counter=$((counter+1))`) everywhere the pattern occurs in reload.sh and gtk.sh."
  - "walker-style.css selectors (#box, #search, row) targeted a widget tree that doesn't exist in walker 2.16.2's actual class-based GTK4 UI — the matugen template was rewritten against the real widget/class hierarchy, which is why colors previously failed to apply even when the relaunch itself worked."
  - "The Thunar deferral notify-and-skip branch (added in Task 2 per D-15) never actually re-fired the restart once a window closed — it just deferred and forgot. Replaced with a deduped, bounded (5s poll, capped) detached watcher that restarts the daemon exactly once when the last Thunar window closes."
  - "RESEARCH Open Question 2 answered empirically: GTK3 apps do NOT re-color live while a window is open — the process must restart for a new gtk.css to take effect. D-15's 'windows stay stale until closed' caveat STANDS, unmodified. This plan mitigates the practical impact (via the deferred watcher) rather than eliminating the underlying GTK3 limitation, which is unfixable from userspace."
  - "Investigated a user report of 'Thunar still stale' in a second verification round and found NO bug: the hypothesis that GTK_THEME env var suppresses the user's ~/.config/gtk-3.0/gtk.css was empirically disproven (identical CSS parse-warning behavior with and without GTK_THEME set), so D-13 (GTK_THEME sourced from uwsm/env) stands unchanged. The report is explained by the documented D-15 deferral window (~5s after last window close) plus visual confusability between dark-on-dark palettes (e.g. rosepine #191724 vs the prior dark palette)."
  - "THEME-03's GTK4 ceiling is accepted as-is, not treated as a gap: full GTK4/libadwaita palette theming is structurally unsupported upstream (no equivalent to GTK3's gtk.css named-color override is honored the same way across all libadwaita widgets); scope is prefer-dark + nearest-enum accent color via gsettings, with a best-effort gtk-4.0/gtk.css named-color layer for the apps that do read it."
  - "theme-doctor's one remaining failing invariant (elephant listproviders missing files/menus/providerlist/runner/websearch) is a known, previously-identified gap (Phase 1 audit / Blockers) explicitly deferred to Phase 3 INST-01's verification loop — the user accepted this at final checkpoint approval rather than treating it as a Plan 01-03 blocker."

requirements-completed: [THEME-01, THEME-02, THEME-03, THEME-04, THEME-05, THEME-06, SCAN-02]

coverage:
  - id: D1
    description: "Walker restarts via kill + bounded pgrep poll + relaunch, gated on elephant socket/health/version compatibility before declaring success"
    requirement: "THEME-01, SCAN-02"
    verification:
      - kind: manual_procedural
        ref: "theme-apply <preset> live run; walker process confirmed relaunched via pgrep, elephant listproviders responded post-restart, walker opened in new palette colors (not white) — verified across the deviation-fix rounds (36b6440) and the final human checkpoint"
        status: pass
    human_judgment: true
    rationale: "Visual confirmation that Walker actually renders the new colors (vs. the process merely being alive) required the human looking at the live launcher UI."
  - id: D2
    description: "Thunar daemon-only restart with bounded poll; visible windows never killed; deferred restart fires reliably once the last window closes"
    requirement: "THEME-02"
    verification:
      - kind: manual_procedural
        ref: "Three restart scenarios verified on committed code: windowless restart, deferral while a window is open, and the watcher firing on last-window-close (a183fc3); close-all-windows protocol re-confirmed at final human checkpoint"
        status: pass
    human_judgment: true
    rationale: "Confirming a newly-opened Thunar window shows the new palette, and that no window was force-closed, requires human visual inspection."
  - id: D3
    description: "GTK4/libadwaita dark-mode + accent color follow the switch via gsettings; ceiling documented"
    requirement: "THEME-03"
    verification:
      - kind: manual_procedural
        ref: "gsettings color-scheme prefer-dark + hue-mapped accent-color enum verified set after switch (6e575dd); GTK4 apps (Walker) confirmed dark + accented at final checkpoint"
        status: pass
    human_judgment: true
    rationale: "Accent color correctness is a visual judgment call against the source palette's hue."
  - id: D4
    description: "theme-doctor extended with walker/elephant version-match + provider-parity checks, reports pass/fail per invariant"
    requirement: "SCAN-02"
    verification:
      - kind: automated
        ref: "theme-engine/.config/theme-engine/theme-doctor run at Task 3 pre-check: 21/22 invariants pass; the 1 failure (elephant listproviders missing files/menus/providerlist/runner/websearch) is the known, previously-flagged gap deferred to Phase 3 INST-01"
        status: pass
    human_judgment: false
  - id: D5
    description: "All ten fan-out targets re-theme live on one switch, in both static and dynamic modes, no relogin"
    requirement: "THEME-04, THEME-05, THEME-06"
    verification:
      - kind: manual_procedural
        ref: "Final human-verify checkpoint APPROVED: Hyprland, waybar, kitty, swaync, wlogout, vscodium, Walker, yazi, Thunar, GTK4 all confirmed re-theming in both static preset and matugen dynamic (Super+W) switches; switch latency ~1s (vscodium lags slightly, accepted); last-applied theme survives restart/login parity (THEME-06); git stays clean after switches (PIPE-03)"
        status: pass
    human_judgment: true
    rationale: "The phase's headline observable — the desktop visually re-theming consistently — can only be confirmed by a human looking at the live desktop across both modes."
  - id: D6
    description: "Legacy hypr scripts (walker-restart.sh, walker-theme-gen.sh, gtk-reload.sh) retired and invoked nowhere"
    requirement: "THEME-01, THEME-02"
    verification:
      - kind: automated
        ref: "grep -rE 'walker-restart\\.sh|walker-theme-gen\\.sh|gtk-reload\\.sh' theme-engine hypr/.config/hypr/scripts hypr/.config/hypr/config returns no active invocations; all three files deleted"
        status: pass
    human_judgment: false

duration: multi-session (Task 1+2 auto execution, checkpoint pause, 2 investigation/fix rounds, final approval)
completed: 2026-07-07
status: complete
---

# Phase 1 Plan 03: Per-App Live Re-Theme — Walker, Thunar, GTK4 Hardening + End-to-End Verification Summary

**Hardened Walker's restart-only reload with an elephant health gate, made Thunar's daemon restart survive open windows via a deduped bounded-poll watcher, wired GTK4 dark+accent through gsettings, and human-verified all ten desktop surfaces re-theme live in both static and dynamic modes with no relogin.**

## Performance

- **Duration:** Multi-session — Tasks 1–2 auto-executed, Task 3 paused at a blocking human-verify checkpoint, two rounds of deviation investigation/fixes followed the first verification attempt, then final approval
- **Completed:** 2026-07-07
- **Tasks:** 3 (2 auto + 1 checkpoint)
- **Commits:** 5 (2 planned task commits + 3 deviation-fix commits)

## Accomplishments

- Hardened `lib/reload.sh`'s Walker restart: kill `walker --gapplication-service`, wait via a bounded `pgrep` poll (never a fixed sleep), verify the elephant backend's socket, `elephant version` response, and walker/elephant version compatibility before relaunching — a stale/mismatched elephant is no longer mistaken for a themed Walker
- Hardened `lib/gtk.sh`'s Thunar restart: bounded-poll daemon-only restart that never kills visible windows, plus a deduped background watcher that fires the deferred restart exactly once when the last open window closes
- Extended `theme-doctor` with walker/elephant version-match and `elephant listproviders` vs `walker/config.toml` provider-parity checks — 21/22 invariants pass
- Wired GTK4/libadwaita dark mode + hue-mapped accent color via gsettings, with the structural full-palette ceiling documented rather than treated as a gap
- Retired `walker-restart.sh`, `walker-theme-gen.sh`, `gtk-reload.sh` — all logic now lives in the engine, nothing invokes the legacy scripts
- Found and fixed a `set -e` + `(( counter++ ))` arithmetic footgun that silently aborted theme-apply mid-reload at counter=0, before the walker relaunch line ever executed — this, not any CSS or restart-logic issue, was why Walker appeared to never come back after a switch
- Rewrote `walker-style.css`'s matugen template selectors against walker 2.16.2's real class-based widget tree (the old `#box`/`#search`/`row` selectors matched nothing)
- Migrated yazi's `OpenRule` matcher schema from the retired `name` key to `url`/`mime` (installed yazi 26.5.6 breaking change that broke yazi startup entirely, unrelated to theming but blocking end-to-end verification)
- Investigated a second-round "Thunar still stale" report and confirmed it was NOT a bug — empirically disproved the GTK_THEME-suppresses-CSS hypothesis and traced the report to the documented D-15 deferral window plus dark-on-dark palette confusability
- Final human verification: all ten targets (Hyprland, waybar, kitty, swaync, wlogout, vscodium, Walker, yazi, Thunar, GTK4) re-theme live in both static and dynamic modes, ~1s switch latency, no relogin, git stays clean

## Task Commits

1. **Task 1: Hardened Walker restart + elephant health gate, theme-doctor extended** — `c72d61b` (feat)
2. **Task 2: Hardened Thunar daemon restart + GTK4 dark/accent** — `6e575dd` (fix — includes the window-open deferral and GTK4 accent addition)
3. **Deviation fix: yazi OpenRule schema migration (url/mime)** — `22d93e4` (fix)
4. **Deviation fix: walker relaunch set -e footgun + walker-style.css selector rewrite** — `36b6440` (fix)
5. **Deviation fix: deferred Thunar restart watcher fires on last-window-close** — `a183fc3` (fix)

_Note: Task 3 (the human-verify checkpoint) produced no code commit of its own — it is the verification gate that triggered the three deviation-fix commits above and ends with this SUMMARY/metadata commit._

## Files Created/Modified

**Modified:**
- `theme-engine/.config/theme-engine/lib/reload.sh` — inlined hardened walker restart (bounded pgrep poll + elephant health gate); fixed the `set -e`/counter footgun; folded in the walker relaunch reliability fix
- `theme-engine/.config/theme-engine/lib/gtk.sh` — bounded-poll Thunar daemon restart, window-open deferral, deduped watcher that fires on last-window-close, GTK4 dark+accent gsettings wiring
- `theme-engine/.config/theme-engine/theme-doctor` — extended with walker/elephant version-match + `elephant listproviders` provider-parity checks
- `matugen/.config/matugen/templates/walker-style.css` — selectors rewritten against walker 2.16.2's actual class-based widget tree
- `matugen/.config/matugen/templates/yazi-theme.toml`, `yazi/.config/yazi/yazi.toml` — OpenRule matcher migrated from `name` to `url`/`mime`

**Removed:**
- `hypr/.config/hypr/scripts/walker-restart.sh`
- `hypr/.config/hypr/scripts/walker-theme-gen.sh`
- `hypr/.config/hypr/scripts/gtk-reload.sh`

## Decisions Made

See frontmatter `decisions` — highlights: the `set -e` + `(( counter++ ))` arithmetic footgun was the true root cause of the "Walker never comes back" failure (not CSS); walker-style.css's selectors were rewritten against the real widget tree; the Thunar deferral now actually re-fires via a deduped watcher instead of silently dropping the re-theme; RESEARCH Open Question 2 is answered — GTK3 windows do not re-color live, D-15 stands; THEME-03's GTK4 ceiling is accepted as the realistic scope, not a gap; the one remaining theme-doctor failure (elephant provider gap) is explicitly deferred to Phase 3 INST-01 with user sign-off.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] yazi OpenRule matcher schema broke yazi startup entirely**
- **Found during:** Task 3 pre-checkpoint verification (first human-verify round found 3 of 10 targets failing)
- **Issue:** Installed yazi 26.5.6 renamed the `OpenRule` matcher key from `name` to `url`/`mime`. Both the stowed `yazi.toml` and the matugen `yazi-theme.toml` template used the stale key, breaking yazi startup outright — not a theming-specific bug, but it blocked verifying yazi's re-theme at all.
- **Fix:** Migrated both files to the `url`/`mime` schema.
- **Files modified:** `matugen/.config/matugen/templates/yazi-theme.toml`, `yazi/.config/yazi/yazi.toml`
- **Verification:** yazi launches cleanly and re-themes on switch.
- **Commit:** `22d93e4`

**2. [Rule 1 - Bug] Walker relaunch didn't stick; rice theme CSS didn't resolve**
- **Found during:** Task 3 pre-checkpoint verification (first human-verify round)
- **Issue:** Two independent root causes compounded into "no walker process after a switch, and when relaunched manually, no colors applied": (a) `set -e` combined with `(( counter++ ))` returns exit 1 when the counter is 0, which silently aborted `theme-apply` mid-reload BEFORE the walker relaunch line ever ran; (b) `walker-style.css`'s selectors (`#box`, `#search`, `row`) matched no real widget in walker 2.16.2's actual class-based GTK4 UI, so even a successful relaunch showed no themed colors. A D-Bus bus-name-release race was also hardened while fixing this.
- **Fix:** Rewrote the counter-increment pattern everywhere it appeared in `reload.sh` to not trip `set -e` at zero; rewrote `walker-style.css` selectors against the real widget tree.
- **Files modified:** `theme-engine/.config/theme-engine/lib/reload.sh`, `matugen/.config/matugen/templates/walker-style.css`
- **Verification:** Walker relaunches reliably and opens in the switched palette's colors on every switch.
- **Commit:** `36b6440`

**3. [Rule 1 - Bug] Deferred Thunar restart never re-fired when the last window closed**
- **Found during:** Task 3 pre-checkpoint verification (first human-verify round)
- **Issue:** The Task 2 notify-and-skip deferral branch (added per D-15 when a window is open at switch time) deferred the restart but never actually re-fired it — Thunar silently stayed on the stale palette indefinitely once a window had been open at switch time.
- **Fix:** Replaced the notify-and-skip branch with a deduped, bounded (5s poll, capped iteration count) detached watcher that restarts the daemon exactly once when the last Thunar window closes. The same `set -e`/counter footgun from deviation #2 was also present here and fixed.
- **Files modified:** `theme-engine/.config/theme-engine/lib/gtk.sh`
- **Verification:** Windowless restart, deferral-with-window-open, and watcher-fires-on-close all verified working on committed code; re-confirmed via the close-all-windows protocol at final human checkpoint.
- **Commit:** `a183fc3`

---

**Total deviations:** 3 auto-fixed (all Rule 1 bug fixes), found during the first human-verify attempt and resolved before final approval.
**Impact on plan:** All three were necessary for the plan's own acceptance criteria (Walker re-themes; Thunar re-themes without killing windows) to actually hold; none changed the plan's architecture or scope.

## Investigation Round 2 — No Bug Found

Between the deviation fixes above and final approval, the user reported "Thunar still stale" a second time. This investigation found **no bug** and produced **no commit**:

- **Hypothesis tested:** `GTK_THEME` env var suppresses `~/.config/gtk-3.0/gtk.css` (the user's stowed override), so Thunar renders stock Adwaita instead of the intended palette.
- **Result:** Empirically **disproven** — junk-CSS stderr probes produced identical parse warnings with and without `GTK_THEME` set, showing the user's CSS loads at USER priority regardless of `GTK_THEME`. D-13 (GTK_THEME sourced solely from `uwsm/env`) stands unchanged.
- **Corroborating evidence:** A lime-green override test screenshot-confirmed the palette pipeline does apply to Thunar chrome; all three restart scenarios (windowless, deferral-with-window-open, watcher-fires-on-close) were re-verified working on the already-committed code.
- **Actual explanation:** D-15's documented deferral window — while ANY Thunar window is open, all windows (including newly opened ones) come from the same stale process; re-theme happens ~5s after the LAST window closes, not instantly. Compounded by dark-on-dark palette pairs (e.g. rosepine `#191724` vs. the prior dark palette) being visually hard to distinguish at a glance, which made an already-successful re-theme look like a failure.

## RESEARCH Open Question 2 — Answered

**Question:** Does an already-open Thunar window re-color live when a switch happens, without restarting the process?

**Answer: No.** GTK3 has no live CSS reload API — a new `gtk.css`/`colors.css` is inert until the process restarts. This was empirically confirmed during Task 2 execution and re-confirmed during the Investigation Round 2 work above. **D-15's "windows stay stale until closed" caveat STANDS, unmodified** — it is not relaxed by this plan. The plan mitigates the practical impact (the deferred, deduped watcher in `lib/gtk.sh` ensures the restart reliably fires once the last window closes, rather than being silently dropped) but does not and cannot eliminate the underlying GTK3 limitation from userspace.

## THEME-03 — GTK4 Ceiling Documented

Full GTK4/libadwaita palette theming (matching GTK3's complete named-color override) is **structurally unsupported upstream** — libadwaita's styling model does not honor an app-wide named-color CSS override the same way GTK3 does across all widgets. This plan scopes GTK4/libadwaita theming to:
- `color-scheme` set to `prefer-dark` via gsettings (live-updating via the portal)
- Accent color set via gsettings, hue-mapped to the nearest libadwaita accent enum (GNOME47+ accent-color key)
- A best-effort `gtk-4.0/gtk.css` named-color override layer (wired in Plan 01-02) for the subset of GTK4 apps/widgets that do read it

This is documented as **the realistic ceiling for this milestone, not an outstanding gap** — no further GTK4 palette work is planned or expected to close it further without upstream libadwaita changes.

## theme-doctor Status

21/22 invariants pass. The one failure — `elephant listproviders` missing `files`/`menus`/`providerlist`/`runner`/`websearch` providers — is the **previously-identified, known gap** (flagged in Phase 1's audit and carried in STATE.md's Blockers/Concerns since Plan 01-01) explicitly **deferred to Phase 3's INST-01 verification loop**. The user explicitly accepted this at final checkpoint approval rather than treating it as a blocker for this plan.

## Human Verification — Final Checkpoint (APPROVED)

All ten fan-out targets confirmed re-theming live on one switch, in both static and dynamic modes, with no relogin:
- **Static + dynamic parity:** Hyprland, waybar, kitty, swaync, wlogout, vscodium, Walker, yazi, Thunar, GTK4 all re-theme correctly in both a static preset switch and a matugen dynamic (Material You, Super+Shift+B wallpaper pick / Super+W) switch
- **Switch latency:** ~1s across the signal-driven surface (D-21); vscodium lags slightly behind the rest — noted as acceptable, not a regression
- **Wallpaper-driven Material You:** applies immediately on wallpaper change
- **Login parity (THEME-06):** the last-applied theme survives a restart/re-login, matching picker behavior
- **Git cleanliness (PIPE-03):** `git status` stays clean of generated color files after switches
- **Thunar close-all-windows protocol:** re-verified working end-to-end at this final checkpoint

## Issues Encountered

None beyond the deviations and investigation documented above — no unresolved issues remain from this plan.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 1's goal — every visible desktop app re-themes live from a single shared engine, root cause eliminated, full repo audited — is now complete and human-verified. Ready for Phase 2 (Static ↔ Dynamic Parity & Switch Reliability):
- The hardened restart paths (Walker, Thunar) in this plan are exactly what Phase 2's repeated-switch stress test (10 consecutive switches with Thunar/Walker open) will exercise — both are now bounded-poll and health-gated rather than fire-and-hope.
- The one open item (elephant provider gap) is explicitly scoped to Phase 3 INST-01, not this phase or Phase 2.

No blockers for Phase 2.

## Known Stubs

None — every deliverable in this plan is wired to real, live-verified behavior (no placeholder/mock reload paths).

## Threat Flags

None beyond what the plan's own threat model already covered (T-03-01 bounded-poll DoS cap, T-03-02 elephant health gate) — both mitigated and verified live this session. No new network endpoints, auth paths, or trust-boundary-crossing surface was introduced by this plan's fixes.

---
*Phase: 01-root-cause-fix-consolidated-theme-engine*
*Completed: 2026-07-07*

## Self-Check: PASSED

- theme-engine/.config/theme-engine/lib/reload.sh — FOUND
- theme-engine/.config/theme-engine/lib/gtk.sh — FOUND
- theme-engine/.config/theme-engine/theme-doctor — FOUND
- matugen/.config/matugen/templates/walker-style.css — FOUND
- yazi/.config/yazi/yazi.toml — FOUND
- hypr/.config/hypr/scripts/walker-restart.sh — CONFIRMED REMOVED (retired per plan)
- hypr/.config/hypr/scripts/walker-theme-gen.sh — CONFIRMED REMOVED (retired per plan)
- hypr/.config/hypr/scripts/gtk-reload.sh — CONFIRMED REMOVED (retired per plan)
- Commit c72d61b — FOUND
- Commit 6e575dd — FOUND
- Commit 22d93e4 — FOUND
- Commit 36b6440 — FOUND
- Commit a183fc3 — FOUND
