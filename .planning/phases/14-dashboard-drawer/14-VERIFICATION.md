---
phase: 14-dashboard-drawer
verified: 2026-08-01T17:10:00Z
status: human_needed
score: 6/10 must-haves verified
behavior_unverified: 4
overrides_applied: 0
gaps: []
behavior_unverified_items:
  - truth: "Swipe progress driving the tab indicator neither overshoots past the final tab's indicator position nor leaves a sub-pixel gap at rest at any of the four indices (14-03 must_haves, verification: backstop)"
    test: "Drag to each of the four tab indices and release exactly at rest (no residual velocity); zoom into the header indicator at each of the four positions"
    expected: "The indicator's leading/trailing edge lands flush with the active tab label at all four indices — no visible overshoot past index 3's position and no sub-pixel gap at any index"
    why_human: "Sub-pixel alignment and overshoot are a rendered-pixel judgement; no committed gate or SUMMARY records this specific check having been made (the render gate's Task-2/Task-5 checks confirmed general threshold-commit/spring-back behavior, not this pixel-level claim)"
  - truth: "Long real-world track title/artist elides single-line without breaking the fixed frame on the Media tab (14-05 must_haves, verification: backstop)"
    test: "Play a track with a long title and/or artist string (e.g. a classical piece with a long composer credit, or a podcast episode title) and observe the Media tab"
    expected: "Title and artist each elide with an ellipsis on one line; the tab's fixed-height frame does not grow, shrink, or reflow"
    why_human: "No SUMMARY records this specific test being run against a real long title — 14-09's Task 4 check 7 exercised play/pause/seek/switch-player but did not call out a long-title elide case"
  - truth: "The Performance tab's network rate row holds its width at worst-case values with no reflow (14-06 must_haves, verification: backstop)"
    test: "Generate sustained heavy network traffic (large download/upload) so the up/down rate readout reaches its longest realistic string (e.g. \"999.9 MB/s\") and watch the row"
    expected: "The row's fixed-width formatting absorbs the longest value with no layout shift, wrap, or reflow"
    why_human: "14-10's Task 4 confirmed the row was re-centred and widened, and states the 'anti-reflow guarantee' held under that change, but no session recorded feeding it an actual worst-case value string to watch for reflow — the claim rests on the fixed-width formatter's design, not an observed worst-case render"
  - truth: "The Dashboard tab's compact media widget title elides correctly at compact width (14-08 must_haves, verification: backstop)"
    test: "Play a track with a long title while the Dashboard tab's compact media widget is visible"
    expected: "Title elides with an ellipsis inside the widget's fixed-width slot; nothing shifts or wraps"
    why_human: "No SUMMARY records this specific test with a real long-title track against the compact (not full-player) widget specifically"
---

# Phase 14: Dashboard Drawer Verification Report

**Phase Goal:** "The first real QML surface — a four-tab swipeable dashboard drawer that reads the state the desktop already owns instead of forking it."
**Verified:** 2026-08-01T17:10:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ROADMAP criterion 1 — keybind opens/dismisses drawer, rest of desktop stays interactive, zero exclusive zone on any waybar-reserved edge | ✓ VERIFIED | `hypr/.config/hypr/config/keybinds.lua:181` binds Super+D to `quickshell:dashboard`; `shell.qml`'s `dashboardShortcut` toggles `dashboardLoader.active`; `Dashboard.qml` sets `WlrLayershell.layer: WlrLayer.Overlay` + `WlrKeyboardFocus.OnDemand` + a `HyprlandFocusGrab` (`onCleared: dismissRequested()`, `Keys.onEscapePressed`). 14-09-SUMMARY.md Task 3 §D re-observed this live across all four populated tabs: `hyprctl layers -j` shows `quickshell-dashboard` at level 3 with exclusive zone 0 on every tab, waybar's `[[0,46,0,0]]` reserved array byte-identical before/during/after, and zero `quickshell-dashboard*` entries after dismiss on every path |
| 2 | ROADMAP criterion 2 — four tabs reachable by drag-threshold-commit-with-spring-back and by direct header tap | ✓ VERIFIED | `Dashboard.qml`'s `TabBar`+`SwipeView`+custom `ListView` contentItem (stock drag physics, `highlightMoveDuration: Motion.standardDuration`); 14-03-SUMMARY.md records a live human check of drag-and-hold/threshold-commit/spring-back; 14-09's render gate re-judged this with all tabs populated (check 5) and it was in the explicit PASS list, not a change request |
| 3 | ROADMAP criterion 3 — Dashboard (calendar/date-time/compact media/resources), Media (full player+cover art), Performance (CPU/mem/net/storage/battery), Weather (conditions+forecast, degrades gracefully) | ✓ VERIFIED | Each tab file confirmed substantively populated: `DashboardTab.qml` (clock hero, six-row calendar grid, compact media widget reading shared `mediaBackend`, three mini-dials, toggle footer); `MediaTab.qml`+`MediaBackend.qml` (cover art, transport, seek, volume, player chips, "Nothing playing" empty state); `PerformanceTab.qml`+`SystemResources.qml` (CPU/Memory/Storage/Battery/GPU dials + network rate row, UPower-backed battery, `/proc` readers); `WeatherTab.qml`+`WeatherBackend.qml` (current hero, 8-hour strip, 5-day row, stale badge, never-cached placeholder, try/catch shape-checked parsing). 14-09's render gate checks 6-9 all in the explicit PASS list |
| 4 | ROADMAP criterion 4 — media widget reads existing MPRIS state via the one shared backend; AGS card, waybar and drawer show the same track/player simultaneously; no second media backend | ✓ VERIFIED | `MediaBackend.qml` runs exactly one `Process` (`media-status.sh watch`), shared via the `mediaBackend` property across `MediaTab.qml` and `DashboardTab.qml`'s compact widget — grep confirms zero `Quickshell.Services.Mpris` imports anywhere in the tree and zero second `media-status.sh`/`media-players.sh` invocations. 14-09-SUMMARY.md Task 3 recorded the mechanical delta proof (process count baseline 1 → open baseline+1 → dismissed back to 1, unchanged across 5 cycles) and Task 4's render gate check 10 ("three readers, one track") is in the explicit PASS list |
| 5 | ROADMAP criterion 5 — dashboard toggle flip mirrors swaync's grid and vice versa with one backing state; no panel opens over a fullscreen client | ✓ VERIFIED | `QuickToggles.qml` execs the identical three scripts/state-reads swaync's `config.json` toggle grid uses (`gaming-mode-toggle.sh`+`~/.cache/gaming-mode`, `swaync-client -dn/-df`+`swaync-client -D`, `theme-switch.sh`+`~/.local/state/theme/mode`) — byte-identical tokens confirmed on both sides. `shell.qml`'s `fullscreenBlocking` guard refuses Super+D over a true-fullscreen client. 14-09 Task 3 confirmed the mirror's source-identity table and D-26's flip direction against the real config string; Task 4 re-exercised fullscreen refusal live (kitty, both `fullscreen`-and-`maximized` states refused) and toggle-mirror check 11 is in the explicit PASS list |
| 6 | DASH-09 (minted 2026-07-30) — Performance tab shows a fifth GPU dial at the same panel width as the four-dial layout it replaces, with a designed no-GPU absent-hardware placeholder | ✓ VERIFIED | `PerformanceTab.qml` renders 5 dials (GPU, CPU, Memory, Storage, Battery) at `dialDiameter: 176`; `SystemResources.qml` adds a `gpuPollInterval: 4000`ms one-shot-probe-plus-sampler gated on `drawerOpen`, with `gpuState: "empty"` as the always-present no-GPU placeholder. 14-10-SUMMARY.md records live verification: 1040px frame width unchanged, human render gate ("just right," not crammed) approved, three synthetic no-GPU cases exercised (binary absent/no-devices/non-zero exit), all landing in the same empty state at unchanged geometry |
| 7 | Swipe indicator never overshoots past the final tab's position and never leaves a sub-pixel gap at rest, at any of the four indices (14-03 must_haves, `verification: backstop`) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Code present and wired (`swipeProgress` clamped, single-source-of-truth indicator); no SUMMARY records this specific pixel-level check having been made — see Human Verification |
| 8 | Long real-world track title/artist elides single-line on the Media tab without breaking the fixed frame (14-05 must_haves, `verification: backstop`) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `MediaTab.qml` uses single-line elide by design; no SUMMARY records a long-title track actually being played and observed — see Human Verification |
| 9 | Performance tab's network rate row holds width at worst-case values with no reflow (14-06 must_haves, `verification: backstop`) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Fixed-width formatting and a preserved "anti-reflow guarantee" are recorded in 14-10-SUMMARY.md, but no session fed it an actual worst-case rate string and watched for reflow — see Human Verification |
| 10 | Dashboard tab's compact media widget title elides correctly at compact width (14-08 must_haves, `verification: backstop`) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Code present (fixed-slot elide); no SUMMARY records a long-title observation against the compact widget specifically — see Human Verification |

**Score:** 6/10 truths verified (4 present + wired, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.config/quickshell/modules/Dashboard.qml` | Drawer layer-shell surface, pager, cascade mount, click-outside/Esc dismiss | ✓ VERIFIED | 728 lines; `WlrLayer.Overlay`, `HyprlandFocusGrab`, `TabBar`/`SwipeView`, `cascadeArmed`, `highlightMoveDuration: Motion.standardDuration` all present |
| `quickshell/.config/quickshell/shell.qml` | `dashboardLoader`, `dashboardShortcut` GlobalShortcut, fullscreen refusal guard | ✓ VERIFIED | `dashboardTabIndex`, `dashboardLoader`, `fullscreenBlocking`, `dashboardShortcut` all present and wired |
| `quickshell/.config/quickshell/shortcuts.json` | `quickshell:dashboard` manifest entry on Super+D | ✓ VERIFIED | Present, matches `keybinds.lua`'s dispatch target byte-for-byte |
| `hypr/.config/hypr/config/keybinds.lua` | Super+D bind dispatching `quickshell:dashboard` | ✓ VERIFIED | Line 181 confirmed |
| `hypr/.config/hypr/config/windowrules.lua` | `quickshell-*` family blur/ignore_alpha rules + `quickshell-dashboard` exact-match fallback | ✓ VERIFIED | Both family regex and exact-match rules present |
| `quickshell/.config/quickshell/modules/dashboard/qmldir` | Manifest declaring all 13 dashboard types | ✓ VERIFIED | All types (`DashboardTab`, `MediaTab`, `PerformanceTab`, `WeatherTab`, `MediaBackend`, `WeatherBackend`, `SystemResources`, `QuickToggles`, `Dial`, `Cascade`, `Design`, `WeatherPalette`, `ConditionGlyph`) registered |
| `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` | Swaync-mirrored toggle grid, no second state source | ✓ VERIFIED | Execs identical scripts/watches identical state files as `swaync/config.json` |
| `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` + `MediaTab.qml` | Single shared MPRIS-reading backend, full player UI | ✓ VERIFIED | One `Process` (`media-status.sh watch`), fixed-argv mutator dispatch, no MPRIS import |
| `quickshell/.config/quickshell/modules/dashboard/SystemResources.qml` + `PerformanceTab.qml` + `Dial.qml` | Five-dial resource reader (CPU/Mem/Storage/Battery/GPU) + network row | ✓ VERIFIED | `/proc` readers, UPower battery, `nvidia-smi`-backed GPU dial, all gated on `drawerOpen` |
| `quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml` + `WeatherTab.qml` + `WeatherPalette.qml` + `ConditionGlyph.qml` | Weather data path + degraded-state rendering + layered condition glyphs | ✓ VERIFIED | Open-Meteo single request, TTL cache, shape-checked parsing, never-cached placeholder, two-tone glyph experiment (approved) |
| `swaync/.config/swaync/config.json` | D-26 dark-mode flip direction matching the drawer | ✓ VERIFIED | `update-command` reads `~/.local/state/theme/mode`, `dark) echo true` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `keybinds.lua` | `shortcuts.json` | `quickshell:dashboard` identifier | ✓ WIRED | Byte-identical string on both sides |
| `Dashboard.qml` | `windowrules.lua` | `quickshell-dashboard` namespace | ✓ WIRED | Namespace matched by both family regex and exact-match rule |
| `DashboardTab.qml`/`MediaTab.qml` | `MediaBackend.qml` | `mediaBackend` property | ✓ WIRED | Same shared instance consumed by both, no re-derivation |
| `PerformanceTab.qml`/`DashboardTab.qml` | `SystemResources.qml` | `systemResources` property | ✓ WIRED | Shared reader, no second poll timer |
| `PerformanceTab.qml` | `Dial.qml` | 5 instances at retuned diameter | ✓ WIRED | `dialDiameter: 176`, `Colours.outline` for GPU ring |
| `QuickToggles.qml` | `swaync/config.json` | identical exec targets + watched state paths | ✓ WIRED | Confirmed byte-identical strings |
| `WeatherTab.qml` | `WeatherPalette.qml`/`ConditionGlyph.qml` | layered glyph rendering, single consumer | ✓ WIRED | `WeatherPalette` read from exactly one file outside its own declaration |
| `theme-doctor` | `hypr-equivalence-check` | guarded-skip fold | ✓ WIRED | Present at `theme-doctor:672-700`, degrades to SKIP with no live compositor |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `MediaTab.qml`/compact media widget | `mediaBackend.displayTitle/Artist/playing` | `media-status.sh watch` JSON stream | Yes — live MPRIS payload | ✓ FLOWING |
| `PerformanceTab.qml` dials | `systemResources.*Fraction`, `gpuUtil` | `/proc/stat`,`/proc/meminfo`,`/proc/net/dev`, UPower, `nvidia-smi` | Yes — real kernel/service/subprocess reads | ✓ FLOWING |
| `WeatherTab.qml` | `weatherBackend.current/hourly/daily` | Open-Meteo HTTP request + disk cache | Yes — real network fetch with shape validation | ✓ FLOWING |
| `QuickToggles.qml` chip lit states | `gamingState`,`dndState`,`darkState` | `~/.cache/gaming-mode`, swaync DND, `~/.local/state/theme/mode` | Yes — same files swaync itself reads | ✓ FLOWING |

### Behavioral Spot-Checks

Not independently re-run by this verification pass — the orchestrator already executed the repo's own committed gate scripts (`theme-parity`, `keybind-doctor`, `theme-doctor`, `quickshell-doctor`) and confirmed the drawer summons, mounts, and dismisses live. This verification instead cross-checked the underlying source for each must-have (Steps 4-6 above) and treated the orchestrator's live-session confirmation plus 14-09/14-10's own first-hand `hyprctl`/process-count/fault-injection evidence as the behavioral proof, since re-running would re-touch the live desktop session unnecessarily.

### Probe Execution

No `scripts/*/tests/probe-*.sh` files exist in this repo and none are referenced by this phase's PLAN/SUMMARY files — SKIPPED (not applicable to this phase's verification instrument set; this phase uses `theme-doctor`/`quickshell-doctor`/`keybind-doctor`/`motion-lint` instead, addressed under Anti-Patterns and the orchestrator's pre-supplied gate results).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DASH-01 | 14-01, 14-09 | Keybind opens drawer; click outside/Esc dismisses; no input blocking | ✓ SATISFIED | Truth 1 above |
| DASH-02 | 14-03, 14-09 | Four swipeable tabs, drag-threshold + header tap | ✓ SATISFIED | Truth 2 above |
| DASH-03 | 14-08, 14-09 | Dashboard tab: calendar, date/time, compact media, resources | ✓ SATISFIED | Truth 3 above |
| DASH-04 | 14-05, 14-09 | Media tab reads existing MPRIS backend, no second source | ✓ SATISFIED | Truth 4 above |
| DASH-05 | 14-06, 14-10 | Performance tab: CPU/memory/network/storage/battery | ✓ SATISFIED | Truth 3 above (4-dial base), extended by DASH-09 |
| DASH-06 | 14-02, 14-07, 14-10 | Weather tab: conditions + forecast, degrades gracefully | ✓ SATISFIED | Truth 3 above; `WeatherBackend.qml`'s try/catch shape check + never-cached placeholder |
| DASH-07 | 14-04, 14-09 | Quick-toggles share swaync's backing state, no second source | ✓ SATISFIED | Truth 5 above |
| DASH-08 | 14-01, 14-09 | No panel opens over a true-fullscreen client | ✓ SATISFIED | Truth 5 above; `fullscreenBlocking` guard, live-re-tested |
| DASH-09 | 14-10 | GPU dial, same panel width, absent-hardware placeholder | ✓ SATISFIED | Truth 6 above |

No orphaned requirements found — all nine DASH-01..09 IDs declared across plan frontmatter are accounted for, matching REQUIREMENTS.md's Phase 14 row set exactly (MAINT-04, also touched by 14-10 as an instrument repair, is explicitly excluded from this phase's coverage per this verification's own instructions — its ownership stays with Phase 13.1).

**Documentation-sync note (non-blocking):** `.planning/REQUIREMENTS.md` still shows `DASH-09` with an unchecked `[ ]` box and its traceability row as "Pending — planned in 14-10," even though 14-10 has since built and the human render gate has approved it (per 14-10-SUMMARY.md's Task 4 record). This is a bookkeeping gap in REQUIREMENTS.md, not a code gap — recorded here so the phase-close documentation update catches it.

### Anti-Patterns Found

None. Grep swept every phase-modified QML/Lua/JSON file for `TBD`/`FIXME`/`XXX` (one benign match, `hl.dsp.xxx(...)` in a keybinds.lua doc comment referring to Hyprland's own dispatcher-naming convention, not a debt marker), for "not yet implemented"/"coming soon", and for hex colour literals outside the two documented `WeatherPalette.qml`/exemption files. Zero raw duration literals (`duration: [0-9]`) found in any repo-authored drawer QML. Zero `Quickshell.Services.Mpris` imports anywhere in the tree. Zero `quickshell` references in `theme-engine/lib/reload.sh` (the reload fan-out prohibition holds).

### Human Verification Required

1. **Swipe indicator pixel alignment**
   **Test:** Drag to each of the four tab indices and release exactly at rest; zoom into the header indicator at each position.
   **Expected:** No overshoot past index 3's position; no sub-pixel gap at any of the four indices.
   **Why human:** Pixel-level rendered alignment; no committed gate or SUMMARY records this specific check.

2. **Media tab long-title elide**
   **Test:** Play a track with an unusually long title/artist string and observe the Media tab.
   **Expected:** Single-line elide with ellipsis; the fixed-height frame does not grow, shrink, or reflow.
   **Why human:** No SUMMARY records this specific case being exercised with a real long title.

3. **Performance tab network-row worst-case width**
   **Test:** Generate sustained heavy network traffic so the up/down readout reaches its longest realistic value and watch the row.
   **Expected:** No layout shift, wrap, or reflow — the fixed-width formatting absorbs the worst case.
   **Why human:** The "anti-reflow guarantee" is a design claim recorded in 14-10-SUMMARY.md, not an observed worst-case render.

4. **Compact media widget long-title elide**
   **Test:** Play a track with a long title while the Dashboard tab's compact media widget is visible.
   **Expected:** Title elides inside the widget's fixed-width slot with no shift.
   **Why human:** No SUMMARY records this case tested against the compact widget specifically (as distinct from the full Media tab).

### Gaps Summary

No blocking gaps. All five ROADMAP success criteria and DASH-09 are solidly verified against the live codebase, corroborated by first-hand `hyprctl`/process-count/fault-injection evidence recorded in 14-09-SUMMARY.md and 14-10-SUMMARY.md, and by explicit human render-gate PASS verdicts on the checks that map to them (checks 1, 5, 6, 7, 8, 9, 10, 11 in 14-09's eleven-check gate; all six checks in 14-10's Task 4 gate). The orchestrator's prior-phase-owned tooling defects (`quickshell-doctor`'s vacuous headless-output-remove check, `hypr-equivalence-check`'s motion-scale precondition sensitivity) do not affect these truths, because the underlying claims (zero exclusive zone, no-panel-over-fullscreen) were independently confirmed via direct `hyprctl` reads rather than resting on those doctor scripts alone.

The four items routed to human verification are all explicitly-flagged `verification: backstop` must-haves from PLAN frontmatter (14-03, 14-05, 14-06, 14-08) — fine-grained visual/behavioral polish claims that presence-and-wiring checks cannot resolve and that no SUMMARY records being exercised with the specific real-world input each claim names (a long track title, a worst-case network rate string, an exact-rest indicator position). They do not block the phase goal — the four tabs and their content are unambiguously built, wired, and independently confirmed at the render gate for their primary behaviors — but per the standing rule that a `backstop`-tagged truth cannot be marked VERIFIED on code presence alone, they route to human_needed rather than being silently absorbed into a clean pass.

---

*Verified: 2026-08-01T17:10:00Z*
*Verifier: Claude (gsd-verifier)*
