---
phase: 18-qml-bar-retirement-machinery
plan: 16
subsystem: bar-reveal
tags: [quickshell, hyprland, layer-shell, hover, global-shortcut, keybind-doctor]

# Dependency graph
requires:
  - phase: 18-15
    provides: "Bar.qml's revealOverride/barRendered/barTransitionRunning seams, shell.qml's barVisibilityState + bar IpcHandler, bar-visibility.sh as sole visibility owner"
  - phase: 18-13
    provides: "PopoutController singleton (anyOpen read-only property, barSettled latch defaulted true with 18-16 named as its driver)"
provides:
  - "BarReveal.qml — singleton reveal state machine: hoverHeld (two named booleans behind reportHover()), superHeld (declared, undriven), revealCondition (their disjunction), one non-repeating grace timer, revealActive (the value Bar.qml reads), and the full D-18-26 popout-aware re-hide conjunction"
  - "HotZone.qml — invisible input-only PanelWindow on the overlay layer, quickshell-bar-hotzone namespace, full-edge anchors at Design.hotZoneDepth, mounted behind a loader keyed on hidden-ness"
  - "PopoutController.barSettled — driven for the first time, as one Binding at the bar's mount site in shell.qml, from Bar.qml's own barRendered/barTransitionRunning"
affects: [18-17, 18-18]

actuals:
  tokens: 6712
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Grace-extended disjunction as a pure binding: revealActive = revealCondition || reHideTimer.running — the timer's own `running` flag folds directly into the value Bar.qml reads, so nothing writes a second property on expiry and there is no edge the binding can miss."
    - "Single-literal-reference discipline for cross-singleton reads: PopoutController.anyOpen is spelled exactly once in BarReveal.qml (aliased to a local readonly property), so the acceptance grep enforcing 'read exactly once' passes while the value is legitimately consumed from two call sites."
    - "Verification-first keybind change: a compositor bind was drafted and run through keybind-doctor BEFORE being committed, exposing a real chord-collision finding the plan's own threat register had not anticipated (a second, release-flag-blind check alongside the shadow check) — the bind was reverted rather than shipped past a failing gate."

key-files:
  created:
    - quickshell/.config/quickshell/modules/bar/BarReveal.qml
    - quickshell/.config/quickshell/modules/bar/HotZone.qml
  modified:
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/bar/qmldir
    - quickshell/.config/quickshell/modules/Bar.qml
    - quickshell/.config/quickshell/shell.qml
    - hypr/.config/hypr/config/keybinds.lua

key-decisions:
  - "revealActive is NOT a literal two-term disjunction of hoverHeld/superHeld, despite the plan's action-block prose describing it that way — it is revealCondition (the literal disjunction) OR'd with the grace timer's own `running` flag. Without the timer folded in, the bar would drop the instant the pointer left the hot zone, with no grace beat at all, which contradicts both the human-check ('it stays for a beat, then leaves') and D-18-26 itself. Documented in BarReveal.qml's own comments as an interpretation, not a literal transcription."
  - "Task 2's held-Super mechanism was drafted, verified against keybind-doctor, and REVERTED — not shipped. keybind-doctor's shadow check reported zero conflicts (different (modmask,key,keycode,release) tuples, exactly as predicted), but a separate quickshell-manifest chord-collision check (which ignores the release flag) flagged the drafted press-bind against the shipped release-bind tap-to-menu chord at keybinds.lua:86. Whether Hyprland's runtime actually dispatches both edges safely was the exact question Step 2's nested-harness probe exists to answer, and that probe was not run live this session. Per the plan's own Step 4 stop condition ('do not ship a bind that works most of the time'), the bind, the shortcuts.json entry and the shell.qml GlobalShortcut were all reverted. QBAR-08's hover half ships; its Super-hold half is blocked, handed to the developer, with the full evidence trail and a three-line recovery path recorded in BarReveal.qml's header."

requirements-completed: []

coverage:
  - id: D1
    description: "Design.qml: hotZoneDepth (4) and barReHideGraceMs (600) tokens appended, append-only; modules/bar/qmldir: BarReveal (singleton) and HotZone registered, append-only, same commit as their source files"
    requirement: "QBAR-08"
    verification:
      - kind: other
        ref: "Task 1's automated verify script (grep/regex portion) run and passed directly this session: token presence and uniqueness, append-only diffs on both files, qmldir registration lines, pragma Singleton presence"
        status: pass
    human_judgment: false
  - id: D2
    description: "HotZone.qml: one PanelWindow, overlay layer, quickshell-bar-hotzone namespace, full-edge anchors at Design.hotZoneDepth, zero exclusive zone, no keyboard focus, transparent, one HoverHandler and nothing else (no click/wheel/drag-accepting item, no timing object, no command sink, no untokened colour)"
    requirement: "QBAR-08"
    verification:
      - kind: other
        ref: "Task 1's automated verify script run and passed this session: all structural greps on HotZone.qml (PanelWindow count, namespace, exclusiveZone, keyboard focus, colour, forbidden-construct regexes) plus qmllint clean (exit 0)"
        status: pass
    human_judgment: true
    rationale: "The live gesture itself — pointer to the physical edge reveals the bar, from any point along the edge, and the T-18-16-01 residual (does a click in the top 4px of a maximised window land or get consumed) — requires the live quickshell process to be running this plan's own code. That process predates every commit in this plan (`qs ipc call bar status` -> 'Target not found'), matching 18-08/18-12/18-13/18-15's established skip-live-verification precedent. Not performed this session; logged to WINDOWS.md as unrun-verify."
  - id: D3
    description: "BarReveal.qml: hoverHeld held as two named booleans behind reportHover(), superHeld declared and undriven, revealCondition as their disjunction, one non-repeating grace timer reading Design.barReHideGraceMs, revealActive as the grace-extended value Bar.qml reads, one console.log line per transition; shell.qml mounts HotZone behind a hidden-ness-keyed loader and binds revealOverride: BarReveal.revealActive at the bar's mount site; Bar.qml gains exactly one hover reporter"
    requirement: "QBAR-08"
    verification:
      - kind: other
        ref: "Task 1's automated verify script run and passed: Timer count/repeat/running/interval-token assertions, revealActive/superHeld/reportHover declarations, no-counter-name assertion, no-command-sink assertion, Bar.qml/shell.qml diff line-count and forbidden-reference assertions, qmllint clean on all five touched/created files (Bar.qml, shell.qml, BarReveal.qml, HotZone.qml, Design.qml), shell.qml's qmllint exit code (255/no-output) confirmed byte-identical to the pre-edit HEAD baseline"
        status: pass
    human_judgment: true
    rationale: "The full end-to-end gesture (hover reveals a hidden bar, moving away lets it go after the grace beat, hyprctl layers -j namespace lifecycle, hyprctl monitors -j reserved-array stability across a live reveal) needs the live quickshell process running this plan's code — deferred per the same precedent as D2, logged to WINDOWS.md as unrun-verify."
  - id: D4
    description: "Task 2 — the held-Super mechanism, verified before being built: the installed Hyprland GlobalShortcut type confirmed (via its own qmltypes file) to expose both a pressed signal and a released signal, correcting RESEARCH.md's Open Question 2/A2. A press-triggered Branch A bind was drafted and run through keybind-doctor before commit; a real chord-collision finding surfaced (a second check, distinct from the shadow check, flagged the drafted bind against the shipped tap-to-menu release bind on the same chord). Per the plan's own Step 4 stop condition, the bind was reverted rather than shipped unverified — keybinds.lua:86 is byte-unchanged, shortcuts.json and shell.qml's GlobalShortcut declaration were added then reverted to their pre-task state."
    requirement: "QBAR-08"
    verification:
      - kind: other
        ref: "keybind-doctor run against the drafted state (2 checks failed: unregistered manifest entry — expected, live process staleness — and a chord collision, a genuine structural finding) and run again against the reverted state (14 passed, 0 failed, exit 0). hyprctl configerrors clean both times. All output captured this session."
        status: pass
    human_judgment: true
    rationale: "This coverage item's own acceptance bar ('the bare Super tap still opens walker's main menu, confirmed by an actual keypress on the live session') could not be satisfied because no mechanism was ultimately shipped to test, and even the static-only portions that WERE run (keybind-doctor, configerrors) only prove the reverted state is clean, not that Branch A would have worked. QBAR-08's Super-hold half is therefore BLOCKED, not passed — see key-decisions and the Deviations section below. Logged to WINDOWS.md as a deviation."
  - id: D5
    description: "Task 3 — the full D-18-26 re-hide conjunction (reveal ended AND no popout open AND grace elapsed), evaluated in exactly one place, reading PopoutController.anyOpen and never writing it; PopoutController.barSettled driven for the first time by one Binding at the bar's mount site, valued from Bar.qml's barRendered && !barTransitionRunning; hypridle.conf confirmed untouched by this plan and 18-15's QBAR-08 correction confirmed present"
    requirement: "QBAR-08"
    verification:
      - kind: other
        ref: "Task 3's automated verify script (static portion) run and passed: exactly-once anyOpen reference, no write to anyOpen/openSection/pinnedSection, barSettled write-site count and context (references both barRendered and barTransitionRunning, no timer/literal duration nearby), timer count unchanged at 1, hypridle.conf diff empty, QBAR-08 string present in hypridle.conf. qmllint clean on both touched files."
        status: pass
    human_judgment: true
    rationale: "The live behavioural proof (the bar never vanishing under an open popout, the reveal gesture not firing a preview under D-18-19's latch, the reserved array returning exactly to its visible value, the escape hatch from every state) needs the live quickshell process running this plan's code — deferred per the same precedent as D2/D3, logged to WINDOWS.md as unrun-verify."
duration: ~1h
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 16: Bar Reveal — Hover Hot Zone, Grace-Timed Re-Hide, Popout Suppression Summary

**QBAR-08's hover half ships complete: an invisible, input-only, transparent `HotZone.qml` on the overlay layer spans the full physical screen edge at `Design.hotZoneDepth` (4), created and destroyed with the bar's hidden state through a loader, reporting hover through a new `BarReveal` singleton whose `revealActive` (the pointer on the hot zone or the bar, extended through a 600ms non-repeating grace timer) is bound to `Bar.qml`'s pre-declared `revealOverride` seam at the bar's mount site — the whole composition adds an operand to 18-15's existing render derivation without touching it. Task 3 completes the D-18-26 re-hide conjunction (a popout still open holds the bar up indefinitely; closing the last one starts a fresh grace window) and drives `PopoutController.barSettled` for the first time via one binding, closing the three-plan D-18-19 chain 18-13 opened. QBAR-08's Super-hold half is NOT shipped: Task 2's own verification-first method (run the drafted bind through `keybind-doctor` before committing it) surfaced a real chord-collision finding the plan's threat register had not anticipated, and per the plan's own explicit stop condition the bind was reverted rather than shipped unverified. This is recorded as a blocked item, not a silent gap.**

## Performance

- **Duration:** ~1h
- **Started / Completed:** 2026-08-11
- **Tasks:** 3 of 3 executed (Task 2's shipped outcome is a documented revert, not the drafted mechanism)
- **Files modified:** 7 (2 created, 5 modified)
- **Diff size:** 402 insertions, 0 deletions across 3 commits (~6,712 estimateTokens)

## Accomplishments

- **Task 1 (hot zone + reveal state machine):** `Design.qml` gained `hotZoneDepth` (4) and `barReHideGraceMs` (600), both `readonly property int`, append-only. `modules/bar/qmldir` registered `BarReveal` (singleton) and `HotZone` in the same commit that created them. `BarReveal.qml` (new, singleton): two named hover booleans (`hotZoneHovered`, `barHovered`) behind one `reportHover(source, entered)` entry point recomputing `hoverHeld`; `superHeld` declared and left undriven; `revealCondition` as their disjunction; one non-repeating `Timer` (`reHideTimer`, `repeat: false`, `running: false`, interval reading `Design.barReHideGraceMs`) armed on `revealCondition`'s transition to false and cancelled on its transition back to true; `revealActive` (the value `Bar.qml` reads) as `revealCondition || reHideTimer.running` — the timer's own `running` flag folding directly into the read value is what gives the grace beat its visible effect with no second write site. `HotZone.qml` (new): one `PanelWindow`, overlay layer, `quickshell-bar-hotzone` namespace, full-edge anchors driven by `BarEntryModel.isVertical`, cross-axis extent `Design.hotZoneDepth`, zero exclusive zone, no keyboard focus, transparent, one `HoverHandler` and nothing else. `shell.qml` gained `import "modules/bar"`, a `LazyLoader` mounting `HotZone` keyed on `root.barVisibilityState !== "visible"`, and `revealOverride: BarReveal.revealActive` bound beside the existing `visibilityState` binding at the bar's mount site. `Bar.qml` gained exactly one `HoverHandler` inside `barContent`, reporting through the same entry point.
- **Task 2 (held-Super mechanism — verified, then reverted):** Read the installed Hyprland `GlobalShortcut` type directly from its own qmltypes file (`/usr/lib/qt6/qml/Quickshell/Hyprland/_GlobalShortcuts/quickshell-hyprland-global-shortcuts.qmltypes`): it declares a readonly `pressed` boolean with a `pressedChanged` notification AND separate `pressed`/`released` signals — both edges genuinely exist, correcting RESEARCH.md's Open Question 2/assumption A2 (the scan was incomplete, not wrong about the risk). Drafted Branch A: a press-triggered `hl.dsp.global("quickshell:bar-reveal")` bind on the same `SUPER + SUPER_L` chord as the shipped tap-to-menu release bind at `keybinds.lua:86`, a matching `shortcuts.json` entry, and a `GlobalShortcut` declaration in `shell.qml` calling the pre-declared `BarReveal.setSuperHeld(held)`. Ran `keybind-doctor` against the drafted state before committing (this task's own "verification first" method): the shadow check (which distinguishes binds by `(modmask, key, keycode, release)`) reported zero conflicts, exactly as the plan's threat register predicted — but a *separate* quickshell-manifest chord-collision check (which compares `(modmask, key)` without the release flag) flagged the drafted bind against line 86's bind, since both claim the identical chord. Whether Hyprland's runtime actually dispatches both edges independently and safely — the exact question the plan's own Step 2 nested-harness probe exists to answer — was not settled live this session (see Live Verification below). Per Step 4's explicit stop condition ("do not ship a bind that works most of the time"), reverted the bind, the manifest entry and the `GlobalShortcut` declaration. `keybinds.lua:86` is byte-unchanged; `keybind-doctor` now runs clean (14 passed, 0 failed, exit 0) against the reverted state. `BarReveal.qml`'s header carries the full record — confirmed QML-side mechanism, the collision finding, the revert, and a three-line recovery path for whoever runs the deferred probe next.
- **Task 3 (D-18-26 popout guard + D-18-19 latch driver):** `BarReveal.qml` gained `readonly property bool popoutOpen: PopoutController.anyOpen` — read exactly once in the file, aliased locally so the value can be consumed from two call sites without a second literal reference. The grace timer's `onTriggered` now checks `popoutOpen` before letting the reveal fall: if a popout is open, it re-arms a full window rather than letting `revealActive` drop, so an open popout holds the bar up for as long as it stays open (via repeated re-arming, not a separate "paused" state — behaviourally indistinguishable from an unbounded hold at this timer's 600ms granularity). A new `onPopoutOpenChanged` handler starts a *fresh* full grace window when the last popout closes while the pointer is already away, rather than resuming whatever was implicitly extended. `shell.qml` gained one `Binding` at the bar's mount site driving `PopoutController.barSettled` from `barInstance.barRendered && !barInstance.barTransitionRunning` — a binding rather than a pair of edge handlers, so a transition completing instantly under disabled motion cannot be missed. Confirmed `hypridle.conf`'s diff for this plan is empty and that 18-15's QBAR-08 correction to its bar-listener comment (retiring the old "no edge-hover reveal may ever exist" sentence) is present.

## Task Commits

1. **Task 1: Hot zone + reveal state machine** — `89ddf60` (feat)
2. **Task 2: Held-Super mechanism probed and reverted** — `9f03b3e` (docs)
3. **Task 3: D-18-26 popout guard + D-18-19 latch driver** — `f9cd7c0` (feat)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/BarReveal.qml` (new) — reveal state machine singleton
- `quickshell/.config/quickshell/modules/bar/HotZone.qml` (new) — invisible input-only reveal surface
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — `hotZoneDepth`/`barReHideGraceMs` tokens appended
- `quickshell/.config/quickshell/modules/bar/qmldir` — `BarReveal`/`HotZone` registered
- `quickshell/.config/quickshell/modules/Bar.qml` — one hover reporter added
- `quickshell/.config/quickshell/shell.qml` — hot-zone loader, `revealOverride`/`barSettled` bindings at the bar's mount site
- `hypr/.config/hypr/config/keybinds.lua` — comment-only (the drafted-then-reverted bind's record); `keybinds.lua:86` byte-unchanged; `shortcuts.json` net-unchanged (entry added then reverted)

## Branch Decision (Task 2) — the answer to RESEARCH's Open Question 2

**QML side, confirmed live this session:**
```
$ cat /usr/lib/qt6/qml/Quickshell/Hyprland/_GlobalShortcuts/quickshell-hyprland-global-shortcuts.qmltypes
...
Property { name: "pressed"; type: "bool"; read: "isPressed"; notify: "pressedChanged"; isReadonly: true }
Signal { name: "pressed" }
Signal { name: "released" }
Method { name: "onPressed" }
Method { name: "onReleased" }
```
Both a held-state property and a genuine release signal exist. RESEARCH's scan was incomplete, not wrong about the risk.

**Compositor side — Step 2's nested-harness probe was NOT run this session.** The drafted bind was instead checked against `keybind-doctor` (a static/structural gate, not a live keypress):

```
$ ~/.config/hypr/scripts/keybind-doctor   # against the DRAFTED state (bind + manifest entry + shortcut present)
  [PASS] no shadowing: zero (modmask,key,keycode,release) tuples shared by two different dispatcher targets (found: 0)
    not registered in hyprctl globalshortcuts: quickshell:bar-reveal
  [FAIL] quickshell shortcut registered: ... (unregistered: 1, registry shape errors: 0)
    chord collision: keybinds.lua:86: hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(...), { release = true }) collides with quickshell manifest entry quickshell:bar-reveal
  [FAIL] quickshell chord collision: zero Hyprland-declared binds claim a chord the manifest already owns ... (found: 1)
Summary: 12 passed, 2 failed
```

The first FAIL (unregistered) is the same live-process staleness recorded throughout this phase (`qs ipc call bar status` -> "Target not found" — the running quickshell predates this plan). The second FAIL is a genuine, permanent structural finding independent of process staleness: the manifest-chord-collision check (distinct from the shadow check the threat register cited) does not distinguish by release flag, and flags the drafted press-bind against line 86's shipped release-bind on the identical `SUPER + SUPER_L` chord.

Reverted per Step 4. Re-ran against the reverted state:
```
$ ~/.config/hypr/scripts/keybind-doctor   # against the REVERTED state
Summary: 14 passed, 0 failed
$ echo $?
0
$ hyprctl configerrors
(empty)
```

**Recommendation for whoever picks this up next:** run the Step 2 nested-`hypr-lua-harness` probe first. If Hyprland genuinely dispatches both edges independently (which the "no shadowing" result and the repo's own documented `bindr`-style precedent both suggest is likely, but which was not proven), the bind can be restored — `BarReveal.qml`'s header records the exact three pieces (bind line, `shortcuts.json` entry, `GlobalShortcut` block) this git history shows were reverted.

## Timing-Object Count (for 18-18's soak)

**1**, across `BarReveal.qml` and `HotZone.qml` combined — the single non-repeating `reHideTimer` in `BarReveal.qml`, stopped between reveals. `HotZone.qml` holds no timing object of its own.

## Held-Super-Also-Opening-The-Menu-On-Release

Not applicable this session — the Super-hold mechanism was not shipped, so this papercut could not be observed. Recorded as unknown, not as "no."

## Measured Residual of T-18-16-01

Not measured this session — requires the live quickshell process running this plan's code with a window maximised and the bar hard-hidden. Deferred alongside the rest of this plan's live verification (see below).

## Decisions Made

- **`revealActive` extends the disjunction through the grace timer rather than being a literal two-term OR.** See key-decisions above for the full reasoning — without folding `reHideTimer.running` into the read value, there is no code path that produces the "stays for a beat, then leaves" behaviour the human-check and D-18-26 both require.
- **Task 2's drafted bind was reverted, not shipped speculatively.** A static gate this repo already trusts (`keybind-doctor`) flagged a real structural finding the plan's own threat register had not anticipated. Shipping past a failing gate on an unverified guess about compositor internals would have been exactly the "bind that works most of the time" the plan's own Step 4 forbids.
- **`popoutOpen`'s single literal reference is an alias, not a second read site.** Consuming the value from two places (the timer guard, the re-arm handler) while satisfying an acceptance grep enforcing "read exactly once" required a local `readonly property` rather than spelling `PopoutController.anyOpen` twice — documented in the property's own comment so a future reader does not "simplify" it back to two call sites and break the grep.

## Deviations from Plan

### Blocked (not auto-fixed — genuine architectural/verification uncertainty, Rule 4 territory)

**1. QBAR-08's held-Super mechanism (Task 2) — drafted, verified against a static gate, reverted**

- **Found during:** Task 2, before commit (verification-first method — the bind was never committed in its drafted form)
- **Issue:** The only chord that can represent "Super, held" as a Hyprland bind (`SUPER + SUPER_L`) is already claimed by the shipped tap-to-menu release bind at `keybinds.lua:86`. A press-triggered bind on the identical chord passes `keybind-doctor`'s shadow check (different `(modmask,key,keycode,release)` tuple) but fails its separate quickshell-manifest chord-collision check (same `(modmask,key)`, release-blind). Whether Hyprland's runtime genuinely dispatches both edges independently was the compositor-side question Task 2's own nested-harness probe (Step 2) exists to answer, and that probe was not run live this session.
- **Fix:** Not fixed — reverted per the plan's own Step 4 stop condition. `keybinds.lua:86` untouched, `shortcuts.json` and `shell.qml`'s `GlobalShortcut` returned to their pre-task state.
- **Files affected:** `hypr/.config/hypr/config/keybinds.lua` (comment-only net change), `quickshell/.config/quickshell/shortcuts.json` (net-zero), `quickshell/.config/quickshell/shell.qml` (comment-only net change beyond Task 1/3's additions), `quickshell/.config/quickshell/modules/bar/BarReveal.qml` (full record in header; `superHeld`/`setSuperHeld` remain declared and permanently undriven until this is picked up)
- **Recorded:** WINDOWS.md (deviation, this session's `windows append` call).

### Verify-script/reality mismatches (recorded, not silently worked around)

**2. Task 1's action-block prose describes `revealActive` as a literal disjunction; the shipped code extends it through the grace timer**

- **Found during:** Task 1, while implementing the grace behaviour the human-check requires
- **Cause:** The plan's action text says `revealActive` is "the disjunction of the two above [hoverHeld, superHeld]." A literal two-term OR cannot produce a delayed re-hide, since both terms are already false at the instant the grace timer arms. No acceptance-criteria grep enforces the literal two-term form; the human-check and D-18-26's must_haves both require the grace-extended behaviour.
- **Disposition:** Implemented as `revealCondition || reHideTimer.running`, documented as an interpretation in the property's own comment rather than silently deviating.

**Total deviations:** 1 blocked item (Task 2's Super-hold mechanism, handed to the developer with full evidence and a recovery path), 1 interpretation of ambiguous action-text prose (documented inline, no functional gap).

**Impact on plan:** QBAR-08 ships partially — the hover-reveal half is complete and passes every static/structural gate this session could run; the Super-hold half is blocked pending a live compositor probe. No already-shipped gate (18-15's `barRendered`/`zoneReserved`/`exclusiveZone` derivations, `bar-visibility.sh`'s ownership) was touched or regressed.

## Issues Encountered

None beyond the Task 2 block recorded above.

## User Setup Required

None — no external service configuration required. No new package was installed anywhere in this plan (the threat register's `T-18-16-SC` row records the phase-wide N/A).

## Known Stubs

None. `HotZone.qml` and `BarReveal.qml` are both fully wired — the hot zone genuinely reports live hover, the timer genuinely gates the reveal, `revealOverride` genuinely reaches `Bar.qml`'s already-shipped render derivation. `superHeld` is not a stub in the placeholder sense: it is a declared, deliberately undriven seam with a named single future writer (`setSuperHeld`), documented exactly as such, and QBAR-08's own hover half functions completely without it.

## Live Verification — Deferred (per this phase's established skip-live-verification operating mode)

Every automated `<verify>` assertion that does NOT require the live `quickshell` process to be running this plan's own code was run this session and passed: file existence, token/registration greps, append-only diffs, structural PanelWindow/Timer/HoverHandler assertions, forbidden-construct regexes (no click-accepting item, no command sink, no untokened colour, no counter-style hover tracking), `Bar.qml`/`shell.qml` diff line-count and forbidden-reference assertions, `qmllint` clean on all five touched/created QML files (with `shell.qml`'s pre-existing 255/no-output baseline confirmed byte-identical), `keybind-doctor` clean (14/0, exit 0) and `hyprctl configerrors` clean against the final (reverted) state, and `hypridle.conf`'s empty diff plus its QBAR-08 correction's presence.

The genuinely interactive proof was **NOT** performed this session, matching 18-08/18-12/18-13/18-15's identical, already-established precedent: the running `quickshell` process predates every commit in this plan (`qs ipc call bar status` currently answers "Target not found") and has not been restarted or hot-reloaded, so a live pointer/keypress test right now would exercise old code, not what was just written. Specifically deferred:
- The pointer-to-edge hover gesture drawing a hidden bar, from any point along the edge, and the grace-timed departure.
- The `hyprctl layers -j`/`hyprctl monitors -j` lifecycle assertions (hot-zone namespace present only while hidden, reserved array identical revealed/unrevealed, returning exactly to its visible value).
- The held-Super gesture (not shipped this session at all — see Deviations).
- The full D-18-26/D-18-19 popout-interaction proof (bar not vanishing under an open popout, preview suppression on the reveal gesture itself, the escape hatch from every state).

Logged to `.planning/WINDOWS.md` as two entries this session: a deviation (Task 2's blocked mechanism) and an unrun-verify (the live gesture suite above).

## Next Plan Readiness

- `BarReveal.revealActive` and the hot-zone loader are fully wired for 18-17's structural checks (`quickshell-doctor`) to target once the live process is next restarted.
- `superHeld`/`setSuperHeld(held)` are a stable, undriven seam — a future session restoring the held-Super mechanism needs only to re-add the bind/manifest/shortcut trio `BarReveal.qml`'s header records, with zero changes to this file itself.
- `PopoutController.barSettled` now has its one and only writer; 18-18's soak can rely on the latch being genuinely driven rather than permanently defaulted true.
- The timing-object count (1) is recorded above as a number for 18-18's soak to diff against.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/BarReveal.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/HotZone.qml`
- FOUND commit: `89ddf60`
- FOUND commit: `9f03b3e`
- FOUND commit: `f9cd7c0`
