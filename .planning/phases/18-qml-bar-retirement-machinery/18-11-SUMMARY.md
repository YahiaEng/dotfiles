---
phase: 18-qml-bar-retirement-machinery
plan: 11
subsystem: ui
tags: [quickshell, qml, wlr-layer-shell, hyprland, desktop-entries, idle-inhibit, swaync, walker, dmenu]

# Dependency graph
requires:
  - phase: 18-05
    provides: "BarEntryModel singleton (orientationStatePath, entriesFor), BarCapsule shared chrome, LauncherCapsule/ClockActionsCapsule empty slots, frozen modules/bar/qmldir + Bar.qml + shell.qml for wave 3"
provides:
  - "hypr/.config/hypr/scripts/bar-orientation.sh — the sole writer of ~/.local/state/quickshell/bar-orientation, reached from the settings drawer and the Super-key menu"
  - "elephant/.config/elephant/menus/settings.toml — one added 'Bar orientation' entry beside the superseded 'Waybar layout' entry"
  - "LauncherCapsule.qml filled: the 8-icon app-launcher drawer (apps trigger + 7 application cells), public seam (expanded/requestExpand/requestCollapse/expandedCrossExtent)"
  - "ClockActionsCapsule.qml extended: the four D-18-03 permanent extras (power/gaming/notifications/idleInhibitor) plus the five-axis settings drawer, alongside 18-05's unchanged clock"
  - "NotificationSource inline component — the sealed swaync boundary (unreadCount/dndActive/available/openCentre()/toggleDnd()), the entire contract Phase 19 must re-satisfy"
affects: [18-13, 18-14, 18-17, 18-18, 18-19, 18-20, 19-notification-server]

# Actuals (#2632)
actuals:
  tokens: 10151
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Sealed-backend inline component (NotificationSource): every swaync-specific token (subscription argv, JSON field names, open-centre/dnd argv, the closed class vocabulary) lives inside one QtObject-rooted component; every consumer outside it reaches exactly five backend-neutral names"
    - "QtObject subclass with Process/Timer children needs an explicit `property list<QtObject>` holding them — QtObject has no default property, so anonymous children (the idiom every Item-rooted component in this repo uses) fail to load with 'Cannot assign to non-existent default property'. Found live this plan via the running quickshell hot-reload, confirmed via a throwaway qs -p probe before landing the fix."
    - "Desktop-entry identifier resolution: DesktopEntries.byId() wants the BARE identifier (no trailing .desktop suffix) on quickshell 0.3.0-2 — confirmed empirically via a throwaway qs -p probe enumerating DesktopEntries.applications"
    - "Per-instance availability probe: each drawer cell that launches a script owns its own `[\"test\", \"-x\", path]` Process probe (AudioBackend.qml's pavucontrolProbe precedent), fail-open (available defaults true), so a missing target disables the cell rather than a silent dead click"

key-files:
  created:
    - hypr/.config/hypr/scripts/bar-orientation.sh
  modified:
    - elephant/.config/elephant/menus/settings.toml
    - quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml
    - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml

key-decisions:
  - "NotificationSource's three Process children (subscription, open-centre, toggle-dnd) are attached through one explicit `property list<QtObject> _processes: [...]` rather than as anonymous children under a `default property` — the plan's own suggested `default property list<QtObject>` shape does not load on the installed quickshell 0.3.0-2 (confirmed both in-file and via an isolated throwaway probe); the explicit-list form does, with ids still resolving normally."
  - "DesktopEntries.byId() confirmed empirically to want the bare identifier (no .desktop suffix) — appEntries' desktopId field keeps the suffix (it doubles as the uwsm launch argument) and LauncherCell strips it before the byId call."
  - "Notification subscription command is swaync-client -swb (subscribe-waybar), not swaync-client -s/--subscribe — this is the exact command the retired bar's own custom/notification module already runs continuously (return-type json, no interval), verified live this session against the real running instance (both with a real notification and with none), giving {text, alt, tooltip, class} JSON lines. text is the unread count as a string; class is the eight-member vocabulary format-icons already enumerates (four dnd-prefixed, four not)."
  - "Vertical-orientation drawer host (D-18-11's inward-horizontal leftward-growing strip) is NOT implemented in this plan — per the plan's own instruction, the two-file edit either option needs (Bar.qml or a new BarDrawer.qml type) is a frozen-file / new-registered-type change this plan does not take. expandedCrossExtent is published on both capsules as the contract; the vertical fallback (both strips expand along the column instead) is the plan's own named, acknowledged default. Neither Option A nor Option B was taken during this execution — raised to the orchestrator per the plan's `## Scope correction required`, not silently absorbed."

requirements-completed: [QBAR-01, QBAR-02]

coverage:
  - id: D1
    description: "bar-orientation.sh is the sole writer of ~/.local/state/quickshell/bar-orientation: closed two-member vocabulary validated before any write, atomic temp-file-plus-rename, walker picker with the repo's exit-130-cancel convention, a non-interactive single-argument path, no process signalling, no retired-surface name"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "automated <verify> script from 18-11-PLAN.md Task 1, run directly this session — all checks PASS (path-once, no-theme-dir-write, atomic-write, closed-vocab==2, cancel-convention, no-signalling, no-waybar-mention); live exercised: vertical/horizontal both write correctly, invalid slug and two-arg form both rejected with file untouched, host left at horizontal"
        status: pass
    human_judgment: false
  - id: D2
    description: "Super-key menu's Settings submenu gains exactly one 'Bar orientation' entry beside the superseded 'Waybar layout' entry, which is left in place for 18-20's deletion commit"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "grep counts on elephant/.config/elephant/menus/settings.toml: bar-orientation.sh count==1, 'Bar orientation' count==1"
        status: pass
    human_judgment: false
  - id: D3
    description: "8-icon app-launcher drawer: an apps trigger cell plus seven application cells (Zen, Spotify, Discord, Steam, Lutris, Obsidian, VSCodium) carried forward verbatim, each resolving a real desktop-entry icon with a single Material Symbol fallback, launched via a detached fixed argv"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "automated <verify> script from 18-11-PLAN.md Task 2, run directly this session — all structural checks PASS (7x .desktop\" literals, 7 named app identifiers each exactly once, startDetached count 1, no running:true, command:[ count 1, no forbidden interpolation, DesktopEntries.byId/heuristicLookup count 2, Image.Error count 1, requestExpand/requestCollapse count 2, no hover/timer leak, no Row/Column, no untokened colour, no frozen file touched); live-verified via the running quickshell process's hot-reload log — no load errors across two edit cycles"
        status: pass
    human_judgment: true
    rationale: "Visual confirmation that all seven icons render as real themed icons (not tofu/generic squares) and that each click actually launches its application requires a human render-gate pass per D-18-31/GATE-02 (human_verify_mode: end-of-phase) — deferred to 18-19, logged as WINDOWS.md ledger entry 33 (unrun-verify)."
  - id: D4
    description: "The four D-18-03 permanent extras (power, gaming, notifications, idle inhibitor) all occupy permanent slots beside 18-05's unchanged clock, visible simultaneously, none behind an expander"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "automated <verify> script from 18-11-PLAN.md Task 3, run directly this session — all structural checks PASS (clock intact, >=4 ActionCell instantiations, NotificationSource seam sealed with 0 swaync mentions outside it, exactly 1 running:true process, gaming read-only/compare-only, IdleInhibitor native/window-bound/starts-false, badge caps at 9+, 0.38 disabled treatment with no enabled:false, no Timer anywhere, no untokened colour, no frozen file touched); live-verified via the running quickshell process's hot-reload log across three edit cycles, the last two clean with no errors"
        status: pass
    human_judgment: true
    rationale: "GATE-02 criterion A.5 (all four extras visibly present and dense) and the bell's live unread-count match against the real swaync state require a human render-gate pass per D-18-31 (human_verify_mode: end-of-phase) — deferred to 18-19, logged as WINDOWS.md ledger entry 33 (unrun-verify)."
  - id: D5
    description: "The notification bell is sealed behind one NotificationSource inline component whose public surface is five backend-neutral names (unreadCount, dndActive, available, openCentre(), toggleDnd()); no swaync-specific token exists anywhere outside it in this file"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "awk boundary-scoped grep: 0 'swaync' hits outside the component body, >0 inside it; notificationSource.(unreadCount|dndActive|available|openCentre()|toggleDnd()) line count (9) equals notificationSource.[a-z] line count (9), proving no consumer reaches an undeclared name"
        status: pass
    human_judgment: false
  - id: D6
    description: "The five-axis settings drawer (theme, orientation, font, icons, wallpaper) reuses the launcher drawer's shape; each axis invokes the one existing switcher script for that axis via a detached launch, gated by its own script-presence probe"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "grep counts: each of the five script literals appears in settingsAxes; theme-switch.sh's own count is inflated to 2 by an inherent substring collision with icon-theme-switch.sh (documented as a stale acceptance-criteria-text issue below, mirroring 18-05-SUMMARY's precedent) rather than a real duplication"
        status: pass
    human_judgment: false
  - id: D7
    description: "D-18-31/GATE-02 human render-gate pass: both drawers open and act on the live bar, both orientation reach paths flip the bar live, all four extras visible at once, no Material Symbols ligature renders as literal text, the idle inhibitor genuinely suppresses idle, the bell's count matches the retired bar's, and a live theme switch re-colours everything with no magenta flash"
    verification: []
    human_judgment: true
    rationale: "Visual/perceptual judgment required per D-18-31/GATE-02; human_verify_mode is 'end-of-phase' (workflow.human_verify_mode in .planning/config.json), so this plan defers the check rather than blocking — logged as WINDOWS.md ledger entry 33 (unrun-verify), identical in kind to 18-05's own entry 25 for the same phase-wide gate."

duration: ~30min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 11: The Two Athena Drawers, Four Permanent Extras, and the Orientation Toggle Summary

**A new `bar-orientation.sh` becomes the sole, allowlist-validated, atomic writer of the value 18-05 already reads; `LauncherCapsule.qml` gains the 8-icon app-launcher drawer with real desktop-entry-resolved icons; `ClockActionsCapsule.qml` gains all four D-18-03 permanent extras (power, gaming, a swaync-backed notification bell sealed behind one named component, and a native wayland idle inhibitor) plus a 5-axis settings drawer — live-proven loading cleanly on the running quickshell process throughout.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-08-11T01:44:00Z (approx, session start)
- **Completed:** 2026-08-11T02:11:00Z (approx, last commit)
- **Tasks:** 3 (all completed)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `bar-orientation.sh` created: the sole writer of `~/.local/state/quickshell/bar-orientation`, a two-member closed vocabulary (`horizontal`/`vertical`) validated before any write, atomic temp-file-plus-rename, a walker picker carrying this repo's exit-130-cancel convention on the no-argument path, and an allowlist-validated single-argument non-interactive path for scripted callers. Never signals or restarts any process — the entry model watches the file and re-lays the bar live. Live-exercised in both directions; host left at `horizontal`.
- `elephant/.config/elephant/menus/settings.toml` gained one `Bar orientation` entry, reusing the exact leading glyph bytes (U+F0DB) of the superseded `Waybar layout` entry beside it, which is deliberately left in place for 18-20's own deletion commit.
- `LauncherCapsule.qml` filled: an `apps` trigger cell plus seven application cells (Zen, Spotify, Discord, Steam, Lutris, Obsidian, VSCodium) carried forward verbatim from the retired bar's own launcher group, each resolving a real icon-theme icon through `DesktopEntries` with a single Material Symbol fallback, launching via a detached fixed four-element argv (`uwsm app -- <desktopId>`). Public drawer seam (`expanded`, `requestExpand()`, `requestCollapse()`, `expandedCrossExtent`) published for 18-13; no dwell/hover machinery built here.
- `ClockActionsCapsule.qml` extended (18-05's clock carried unchanged): all four D-18-03 permanent extras — power (`wleave.sh`, gated on presence), gaming (read-only/compare-only consumer of `~/.cache/gaming-mode`), a notification bell wired to `swaync-client -swb` and sealed inside one `NotificationSource` inline component, and the native `Quickshell.Wayland.IdleInhibitor` bound to the bar's own window, starting disabled — plus the five-axis settings drawer (theme/orientation/font/icons/wallpaper), each axis owning its own script-presence probe and detached launcher.
- Empirically resolved, live, this plan: `DesktopEntries.byId()` on the installed quickshell 0.3.0-2 wants the bare application identifier with **no** trailing `.desktop` suffix (confirmed via a throwaway `qs -p` probe enumerating `DesktopEntries.applications` — `byId("zen")` resolved the real entry for all seven identifiers; `byId("zen.desktop")` returned null for all seven). `appEntries[].desktopId` keeps the suffix (it doubles as the launch argument) and is stripped before the lookup.
- Found and fixed live via the running quickshell process's own hot-reload log: `QtObject` carries no default property, so `NotificationSource`'s three `Process` children (subscription, open-centre, toggle-dnd) cannot be declared as anonymous children the way every `Item`-rooted component in this repo does — confirmed the failure and its fix in isolation via a throwaway probe before landing the working `property list<QtObject>` form in the real file.
- Every task's structural `<verify>` script from the plan was run directly against the committed files this session; all pass except one plan-text-level substring-collision issue (documented below, mirroring 18-05's own precedent).

## Task Commits

Each task was committed atomically:

1. **Task 1: The orientation toggle — one script, both reach paths, and the value 18-05 already reads** — `604bd45` (feat)
2. **Task 2: The 8-icon app-launcher drawer** — `8ef9b6c` (feat)
3. **Task 3: The four permanent extras and the settings drawer — with swaync sealed behind one named boundary** — `8bad199` (feat)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `hypr/.config/hypr/scripts/bar-orientation.sh` — new, the sole writer of the bar's orientation value
- `elephant/.config/elephant/menus/settings.toml` — one added entry (orientation, Super-key menu half)
- `quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml` — filled: 8-icon launcher drawer
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` — extended: four extras + settings drawer

## Decisions Made

- **NotificationSource's Process children attach via an explicit `property list<QtObject>`, not a `default property`** — the plan's own suggested `default property list<QtObject>` shape (needed because `QtObject` has no built-in default property, unlike every `Item`-rooted inline component elsewhere in this repo) fails to load on the installed quickshell 0.3.0-2 with "Cannot assign to non-existent default property," reproduced both in the real file and in an isolated throwaway probe. The explicit `property list<QtObject> _processes: [ Process {...}, Process {...}, Process {...} ]` form loads cleanly and every `id` inside the list still resolves normally elsewhere in the component (also proven via the same throwaway probe before landing the fix). See Deviations for the full trail.
- **`DesktopEntries.byId()` wants the bare identifier, confirmed empirically** — resolved via a throwaway `qs -p` probe against the installed quickshell 0.3.0-2 rather than assumed, per the plan's own explicit instruction. `appEntries[].desktopId` keeps the `.desktop` suffix (it doubles as the `uwsm app --` launch argument) and `LauncherCell` strips it before the `byId` call.
- **Notification subscription is `swaync-client -swb`**, not the `-s`/`--subscribe` form `QuickToggles.qml`'s own DND reader uses — `-swb` ("subscribe-waybar") is the exact command the retired bar's own `custom/notification` module already runs continuously, verified live this session directly against the running swaync instance (`{"text": "0", "alt": "none", "tooltip": "", "class": "none"}` at rest; `{"text": "1", "alt": "notification", "tooltip": "1 Notification", "class": "notification"}` with one live test notification, cleared afterward). `text` is the unread count as a string; `class` is the eight-member vocabulary `modules.jsonc`'s own `format-icons` object already enumerates.
- **Vertical-orientation drawer host: neither Option A nor Option B taken this execution** — per the plan's own instruction, this is a frozen-file (`Bar.qml`) or new-registered-type (`BarDrawer.qml`) change that Task 2/Task 3 explicitly do not take. `expandedCrossExtent` is published on both capsules as the contract either option would consume; in vertical orientation both strips currently expand along the bar's own column instead of leftward, the plan's own named, acknowledged fallback rather than a silent capability reduction. Raised to the orchestrator per `## Scope correction required` in `18-11-PLAN.md`; **not resolved by this execution**.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `NotificationSource`'s Process children would not load under the plan's own suggested `default property` shape**

- **Found during:** Task 3, watching `~/.cache/quickshell.log` after saving `ClockActionsCapsule.qml` (per this repo's established live-reload-as-correctness-oracle practice, 18-05's own precedent)
- **Issue:** The plan's action text implies `NotificationSource`'s three `Process` children (subscription, open-centre, toggle-dnd) are declared as ordinary anonymous children inside `component NotificationSource: QtObject { ... }`, the same shape every `Item`-rooted inline component in this repo already uses (`ToggleChip`, `PresetSegment`, `LauncherCell`). `QtObject` — unlike `Item` — declares no default property at all, so an anonymous child inside a `QtObject`-rooted component fails to load: `Cannot assign to non-existent default property`, reproduced live at two different line offsets as the file grew, and reproduced a third time in complete isolation via a throwaway `qs -p` probe (`component Foo: QtObject { ... Process {...} }` alone, no other content) to rule out any interaction with the surrounding file.
- **Fix:** Declared one explicit `property list<QtObject> _processes: [ Process {...}, Process {...}, Process {...} ]` inside the component instead of anonymous children. Proven working first via the same throwaway probe (a `QtObject` with a named `list<QtObject>` property holding two `Process` elements, one referenced by `id` from a function on the root object and successfully started) before landing the fix in the real file.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml`
- **Verification:** Re-saved the file after the fix; `~/.cache/quickshell.log` showed "Reloading configuration... Configuration Loaded" with no errors. Re-verified twice more (an appended blank line, then its removal) to confirm the clean state was not a one-off — both reloads were clean.
- **Committed in:** `8bad199`

---

**Total deviations:** 1 auto-fixed (Rule 1 — a bug found via live quickshell reload, the same correctness-oracle method 18-01/18-05 established for this phase).
**Impact on plan:** Necessary for `ClockActionsCapsule.qml` to load at all; no scope creep.

### Stale/self-contradictory acceptance-criteria text (not code deviations — documented per 18-05-SUMMARY's own precedent for this exact category)

**1. `git diff <file> | grep -c '^-'` returns `0` is unsatisfiable by construction for a pure-addition diff.** Task 1's acceptance criteria assert this for `elephant/.config/elephant/menus/settings.toml` to prove the superseded `Waybar layout` entry was not touched. `git diff` always emits a `--- a/<path>` header line, which itself starts with `-` — so the literal count can never be `0` for ANY diff, additions-only or not. The actual settings.toml diff is additions-only (9 lines added, 0 removed, confirmed by inspecting the diff directly): the superseded entry is byte-for-byte untouched. Implemented per the criterion's evident semantic intent; the literal grep is stale text, mirroring 18-05-SUMMARY's Deviation #2/Decision precedent for this exact class of issue.

**2. `grep -c "theme-switch.sh"` inherently returns `2`, not `1`, because `icon-theme-switch.sh` contains `theme-switch.sh` as a literal substring.** Task 3's acceptance criteria loop over the five settings-axis script names asserting each appears exactly once. `theme-switch.sh` and `icon-theme-switch.sh` are both real, pre-existing repo scripts referenced by their real filenames (verified on disk this session) — the substring collision is inherent to the two filenames themselves and exists regardless of how `ClockActionsCapsule.qml` is written. `settingsAxes` declares each of the five scripts exactly once, in its own array element; the count-of-2 is the checker text, not a real duplication.

## Issues Encountered

- The desktop-entry database (`DesktopEntries.applications`) populates asynchronously — a fresh `qs -p` probe read zero entries for roughly a second after process start before `applicationsChanged` fired with the full 51-entry set. `LauncherCell`'s `resolvedEntry` binding reads `DesktopEntries.applications.values.length` (the value itself unused) specifically so this binding re-evaluates once that scan completes, rather than freezing at whatever was indexed when the binding was first created. Not expected to be user-visible on the real bar (the shell process has been running since well before this plan's edits landed), but recorded since it is exactly the kind of startup-order hazard a soak or a cold-boot render gate should watch for.

## User Setup Required

None — no external service configuration required.

## Known Stubs

None. Every element this plan ships is functionally wired: all seven launcher applications resolve real icons or fall back visibly, all five settings axes gate on their own script-presence probe, the bell reads a live swaync subscription, the idle inhibitor is the real wayland protocol client, and the orientation script is fully exercised (both directions, both invalid-input paths).

The one acknowledged, named limitation is **not** a stub in the fabricated-data sense: in vertical orientation, both drawers (launcher and settings) currently expand along the bar's own column rather than D-18-11's specified inward-horizontal leftward direction, because the host that direction needs is a frozen-file (`Bar.qml`) or new-registered-type change this plan explicitly does not take (see `## Scope correction required` in `18-11-PLAN.md`, and the "Vertical-orientation drawer host" decision above). `expandedCrossExtent` is published on both capsules as the contract whichever future option consumes. Flagged here, in `key-decisions`, and in the plan's own required SUMMARY content — not absorbed into a silently reduced vertical bar.

## Threat Flags

None beyond what this plan's own `<threat_model>` already registers (T-18-11-01 through T-18-11-08, all `mitigate` or `accept` at `medium` or lower severity, below `security_block_on: high`). No new network endpoint, auth path, or trust-boundary crossing was introduced beyond those already named in the plan.

## Next Phase Readiness

- `NotificationSource`'s public surface (`unreadCount`, `dndActive`, `available`, `openCentre()`, `toggleDnd()`) is the entire contract Phase 19's notification-server plan must re-satisfy when it replaces this component's body. No consumer outside the component reaches any other name (mechanically verified: the narrow and broad `notificationSource.*` grep counts are equal, both 9).
- The one permanent child process this plan adds (the `swaync-client -swb` subscription inside `NotificationSource`) is a named charge against QBAR-11 — 18-18's soak must read this SUMMARY alongside 18-08's `18-BAR-LIVENESS-CHARGE.md`; it is deliberately NOT written into that other document (18-08 owns it in the same wave; a shared write would be the one file conflict wave 3 has otherwise avoided entirely).
- **Outstanding, raised not resolved:** the vertical-orientation drawer host (D-18-11's leftward-growing strip) — see `## Scope correction required` in `18-11-PLAN.md`. Recommendation in the plan text is Option B (a new `BarDrawer.qml` registered type, `LazyLoader`-gated). Whoever picks this up should read that section in full before choosing.
- **Outstanding, deferred by design:** the D-18-31/GATE-02 human render-gate pass for this plan's two files — `human_verify_mode` is `end-of-phase` in `.planning/config.json`, so this plan defers rather than blocks. Logged as WINDOWS.md ledger entry 33 (`unrun-verify`, phase 18), the same kind and precedent as 18-05's own entry 25. This should be confirmed before 18-19's GATE-02 blocking pass is taken as final.
- Wave 3 finishes with this plan having touched neither the frozen root files (`Bar.qml`, `BarEntryModel.qml`, `qmldir`, `shell.qml`) nor `Design.qml` — confirmed by `git diff --name-only` containing none of them.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `hypr/.config/hypr/scripts/bar-orientation.sh`
- FOUND: `elephant/.config/elephant/menus/settings.toml`
- FOUND: `quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml`
- FOUND commit: `604bd45`
- FOUND commit: `8ef9b6c`
- FOUND commit: `8bad199`
