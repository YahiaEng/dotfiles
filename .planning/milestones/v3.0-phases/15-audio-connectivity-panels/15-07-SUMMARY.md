---
phase: 15-audio-connectivity-panels
plan: 07
subsystem: ui
tags: [quickshell, qml, dashboard, quick-toggles, audio, wifi, bluetooth, material-you]

requires:
  - phase: 15-audio-connectivity-panels (plan 02)
    provides: "AudioBackend.qml's masterMuted/setMasterMuted seam and the shell-root guarded openPanel(name)/panelLoaderFor(name) summon function this plan's chevron path reaches"
  - phase: 15-audio-connectivity-panels (plan 03)
    provides: "WifiBackend.qml's wifiEnabled/setWifiEnabled seam, BluetoothBackend.qml's adapterEnabled/setAdapterEnabled seam, and the shell-root IpcHandler surface used this session to prove the guarded summon path end to end"
provides:
  - "QuickToggles.qml's six-tile grid (Gaming/DND/Dark/Volume/Wi-Fi/Bluetooth in one row, zero vertical growth), the three new truth-driven tiles' press verbs, and the chevron split affordance's relay origin (panelRequested/openPanel)"
  - "The four-file panelRequested(string name) relay chain (QuickToggles -> DashboardTab -> Dashboard -> shell.qml) landing in 15-02's single guarded openPanel(name), proving the DASH-08 guard is reached from a fourth caller with no second copy anywhere in the chain"
  - "shell.qml's audioTruthNeeded gate widening — AudioBackend's PwObjectTracker now tracks nodes whenever the drawer OR the audio panel is open, not only the audio panel alone, live-measured to be necessary this session"
affects: [15-08-waybar-quickshell-parity, 15-09-quickshell-doctor-phase-close]

actuals:
  tokens: 15200
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Split-affordance idiom's first quick-toggle-grid use: a chevron MouseArea layered above the existing body MouseArea inside the same tile Rectangle, visible/enabled only when a per-entry chipModel field (chipPanel) is non-empty, so three legacy chips keep a single whole-tile hit region unchanged"
    - "Three-file panelRequested(string name) relay with zero guard duplication — each relay file only re-emits an identically-shaped signal; the single guarded summon function stays declared exactly once, in shell.qml, as 15-02 wrote it"
    - "Backend-instance threading down the same mediaBackend/systemResources mount chain (shell.qml -> Dashboard.qml -> DashboardTab.qml -> QuickToggles.qml), with every same-named right-hand side fully qualified (dashboardWindow.*, root.*) to avoid the live-reproduced property-shadowing hazard Dashboard.qml's own header already documents for systemResources"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
    - quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/shell.qml

key-decisions:
  - "audioTruthNeeded gate widening WAS required — measured live, not assumed. With the drawer open and the audio panel closed, AudioBackend's PwObjectTracker (previously gated on audioPanelLoader.active alone) tracked zero nodes, so defaultSink.audio stayed null and the Volume tile's masterMuted read was frozen at its false fallback; wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle from a terminal did not move the tile under the old gate. shell.qml now declares readonly property bool audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active and binds AudioBackend's panelOpen to it. WifiBackend/BluetoothBackend needed no equivalent change — both expose their enable-state as plain, ungated bindings onto their service singletons (WifiBackend.qml line 66: `property bool wifiEnabled: Networking.wifiEnabled`; BluetoothBackend.qml line 46: `readonly property bool adapterEnabled: root.adapter?.enabled ?? false`), confirmed by direct source read before editing anything."
  - "The Do Not Disturb label did NOT need to wrap to two lines at the installed font — it rendered on one line inside the ~104px tile with visible margin to spare (screenshot evidence in Pending human sign-off below). The width/wrapMode/maximumLineCount machinery was still added exactly as the plan specifies (a hard constraint that must hold even if this session's font/DPI combination doesn't currently require it), so a future font or width change can't silently reintroduce clipping without the wrap mechanism already being in place."
  - "Task 1 and Task 2 landed in ONE commit, not two. Their edits interleave inside the same four files at the same insertion points (the chevron's chipPanel/chipChevronTooltip fields sit inside the same chipModel array entries Task 1 extends to six; the panelRequested signal and openPanel() function sit inside the same block as Task 1's press functions). Splitting them would have required reconstructing an artificial intermediate state with no independent verification value — both tasks' full acceptance criteria were run and passed against the final combined state, documented below."

patterns-established:
  - "A tile's chevron dispatches the PANEL namespace name, never the TILE name, via a dedicated per-entry chipModel field (panel) rather than a derived string — the volume tile is 15-07's own proof this split vocabulary is load-bearing (D-26 names the tile for the state that lights it; 15-02/15-03 named the panel for its own namespace)."

requirements-completed: [PANEL-01, PANEL-03, PANEL-04]

coverage:
  - id: D1
    description: "The quick-toggle grid renders six tiles in one row with zero vertical growth (chipHeight stays 72, implicitHeight formula byte-unchanged)"
    requirement: PANEL-01
    verification:
      - kind: automated_ui
        ref: "hyprctl -j layers -- quickshell-dashboard height read 826px before ANY edit (baseline) and 826px again after all four files landed (post-edit), both readings taken this session, byte-identical; git diff confirms neither the chipHeight nor implicitHeight line was touched"
        status: pass
    human_judgment: true
    rationale: "The height-preservation claim is fully machine-verified (two live hyprctl readings, plus a git-diff confirmation that the two governing lines are byte-unchanged). Whether the six-tile row READS as an intentional Material You composition (versus three tiles that got squeezed) is a taste call left to the batched render-gate review below, per the plan's own framing of that question as a human-only check."
  - id: D2
    description: "Volume/Wi-Fi/Bluetooth tiles read live truth from their threaded-in backends and follow an externally-made change with no tile interaction (D-22)"
    requirement: "PANEL-01, PANEL-03, PANEL-04"
    verification:
      - kind: automated_ui
        ref: "Volume: wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle (external) flipped the tile from lit to unlit within one screenshot cycle (~1s), and back after the reverse toggle -- required the audioTruthNeeded gate widening, see key-decisions. Wi-Fi: nmcli radio wifi off/on (external) flipped the tile unlit/lit within ~1s each way, no gate change needed. Both proven with before/after screenshots this session."
        status: pass
      - kind: source_review
        ref: "Bluetooth tile's adapterEnabled read is architecturally identical to Wi-Fi's (plain ungated property, same null-coalescing shape) -- confirmed by direct source read of BluetoothBackend.qml line 46. The tile rendered correctly unlit at rest, matching this session's genuine rfkill-soft-blocked bluetooth state (non-negotiable rule 3), but an explicit external toggle-and-observe cycle was NOT run for bluetooth specifically, to avoid touching the session's blocked bluetooth radio."
        status: partial
    human_judgment: false
    rationale: "Volume and Wi-Fi are both live-verified end-to-end this session with before/after screenshots. Bluetooth is source-verified (identical mechanism, no gate difference) plus a correct-at-rest observation, but its own external-toggle live proof was intentionally skipped to honor the non-negotiable instruction to leave the session's Bluetooth soft-block untouched."
  - id: D3
    description: "Each tile body press performs its verb through the backend writer and never assigns the tile's own lit state; a toggle that cannot land reverts to truth via the existing shared watchdog (E6 error contract), no fifth widget state"
    requirement: "PANEL-01, PANEL-03, PANEL-04"
    verification:
      - kind: source_review
        ref: "pressVolume/pressWifi/pressBluetooth all follow pressGaming's exact shape: early-return on pendingChip/null-backend, set pendingChip, restart the ONE shared chipWatchdogTimer, call the backend writer with the negation of the current truth read -- grep-confirmed exactly 4 Timer{} blocks in the file (the same 4 it shipped with), zero second pending property, zero second watchdog constant."
        status: pass
    human_judgment: true
    rationale: "The press-never-assigns-lit-state structural guarantee, the single shared watchdog, and the E6 error-contract wiring are all verified by direct source reading (grep counts + code inspection), matching the identical pattern the three Phase 14 chips already use and this repo's render gate already approved once. A literal click-driven fault-injection proof (pressing the actual Wi-Fi tile body while radio-blocked and watching it settle) was attempted but NOT cleanly reproduced this session -- see Deviations below for the full honest account of why, and what was substituted."
  - id: D4
    description: "Each tile's chevron opens its own panel through the single guarded shell-root summon; the Volume tile dispatches 'audio', not 'volume'; no relay file duplicates the DASH-08 guard; a chevron press with a fullscreen client focused is refused"
    requirement: "PANEL-01, PANEL-03, PANEL-04"
    verification:
      - kind: automated_ui
        ref: "qs ipc call panel open|toggle {audio,wifi,bluetooth} -- all three exercised this session, each opening its own quickshell-<name>-panel layer and tearing down quickshell-dashboard, then closing cleanly (hyprctl -j layers readings before/after for all three). The IPC handler's open()/toggle() call the IDENTICAL root.openPanel(name) function the chevron's onClicked -> QuickToggles.openPanel(name) -> panelRequested(name) -> ... -> shell.qml's onPanelRequested handler also reaches, so this proves the guard, loader resolution and closeAllPanels() dispatch chain the chevron path terminates in. Fullscreen refusal also directly proven: with a real kitty client set to fullscreen (fullscreen=2, confirmed via hyprctl -j activewindow), both the drawer summon AND `qs ipc call panel open audio` were silently refused -- zero quickshell-* layers appeared either time."
        status: pass
      - kind: source_review
        ref: "grep confirms signal panelRequested(string name) exists exactly once in each of QuickToggles.qml/DashboardTab.qml/Dashboard.qml, shell.qml carries exactly one onPanelRequested handler, and fullscreenBlocking/`.active =` appear zero times (comments stripped) in all three relay files."
        status: pass
    human_judgment: true
    rationale: "The guarded-summon function itself (the thing that actually decides whether a panel opens) is fully machine-verified end to end for all three panels, including the fullscreen-refusal branch with a real fullscreened client. What is NOT literally proven is a physical mouse click landing on the chevron's own 32x32 MouseArea specifically -- this host has no synthetic pointer-input tool (ydotool/dotool/wlrctl/xdotool all absent, confirmed again this session; wtype is keyboard-only), the same documented gap 15-05-SUMMARY.md and 15-06-SUMMARY.md both recorded for their own click-driven proofs. QML's own load-time validation is corroborating evidence the wiring is real: the final loaded config produced zero 'Cannot assign to non-existent property' or 'no such signal' errors, which QML raises immediately if a handler doesn't match a declared signal three levels deep -- but this is not the same as a human's or a synthetic tool's actual click. Flagged explicitly in Pending human sign-off below rather than implied as fully proven."
  - id: D5
    description: "Dismissing a chevron-opened panel lands on the desktop, never the drawer; Super+D re-summons on the Dashboard tab (D-15-20, D-14)"
    requirement: "PANEL-01, PANEL-03, PANEL-04"
    verification:
      - kind: automated_ui
        ref: "Opened the wifi panel via the guarded summon function (qs ipc call panel open wifi), confirmed quickshell-dashboard replaced by quickshell-wifi-panel; sent Escape via wtype -k Escape, confirmed zero quickshell-* layers (desktop); dispatched the dashboard global shortcut, confirmed quickshell-dashboard reappeared; screenshotted the tab bar and confirmed the Dashboard tab (not Media/Performance/Weather) was the active/underlined tab."
        status: pass
    human_judgment: false
    rationale: "Fully machine-verified via three sequential hyprctl -j layers readings and one screenshot of the tab bar's active-tab underline, no ambiguity."
---

# Phase 15 Plan 07: Six-Tile Quick-Toggle Grid + Chevron Split Affordance Summary

**The dashboard's quick-toggle grid grows from three chips to six tiles in one row at exactly its previous height, with Volume/Wi-Fi/Bluetooth becoming the phase's first genuinely stateful tiles -- live backend truth, a body-press verb, and a chevron that opens the matching panel through the single DASH-08-guarded summon function 15-02 wrote, with zero second copy of that guard anywhere in the four-file relay chain.**

## Performance

- **Duration:** ~50 min (code + live verification combined, no separate phases)
- **Tasks:** 2 of 2 `type="auto"` tasks completed and committed together (see Deviations for why); Task 3 (`checkpoint:human-verify`, blocking) recorded below under "Pending human sign-off" per the orchestrator's batched-review instruction rather than stopped on
- **Files modified:** 4 (`QuickToggles.qml`, `DashboardTab.qml`, `Dashboard.qml`, `shell.qml`)

## Accomplishments

- `QuickToggles.qml`'s `chipModel` extended to six entries in the outline's fixed order (`gaming`, `dnd`, `dark`, `volume`, `wifi`, `bluetooth`), each new entry carrying a `panel`/`chevronTooltip` pair the three legacy entries leave empty.
- Three backend seams (`audioBackend`/`wifiBackend`/`bluetoothBackend`) threaded down the exact `mediaBackend`/`systemResources` mount chain (`shell.qml` -> `Dashboard.qml` -> `DashboardTab.qml` -> `QuickToggles.qml`), every same-named right-hand side fully qualified (`dashboardWindow.*` / `root.*`) to avoid the live-reproduced property-shadowing hazard `Dashboard.qml`'s own header documents.
- Three truth mirrors (`volumeUnmuted`/`wifiRadioOn`/`bluetoothAdapterOn`) with the deliberately asymmetric null-backend fallbacks the plan specifies (audio missing -> lit; connectivity missing -> unlit), three press functions shaped exactly like `pressGaming()`, and both `chipLitFor`/`pressChipByName` extended with no second dispatch mechanism.
- The single shared `chipWatchdogTimer`/`pendingChip` model now covers all six tiles (still exactly 4 `Timer{}` blocks in the file) -- E6's `error` contract (a refused toggle reverts to truth) needed zero new code.
- The label `Text` gained an explicit width (`chipItem.width - chipLabelInset*2`), `Text.WordWrap`, `maximumLineCount: 2`, no elide mode -- required by the hard constraint even though this session's font/DPI combination rendered "Do Not Disturb" on one line at ~104px (see Pending human sign-off).
- The chevron split affordance: a `Text` glyph + `MouseArea` (32x32, `chevronHitSize`) layered above the existing body `MouseArea`, visible/enabled only when `chipPanel !== ""`, deliberately NOT disabled while a chip is pending (opposite of the body `MouseArea`, commented as an intentional asymmetry).
- `panelRequested(string name)` relayed unchanged through three files, landing in `shell.qml`'s existing `Dashboard {}` handler that calls 15-02's `openPanel(name)` -- zero second copy of the `fullscreenBlocking` guard or a direct `.active =` write anywhere in the relay chain (grep-confirmed).
- `shell.qml`'s `audioTruthNeeded` gate widening, measured necessary live this session (see key-decisions) -- `AudioBackend.panelOpen` now reads `dashboardLoader.active || audioPanelLoader.active` instead of the audio panel loader alone; the wifi and bluetooth backends' gates are untouched, confirmed unnecessary by direct source read before editing.

## Task Commits

1. **Tasks 1+2 combined: six-tile truth/verbs/labels + chevron relay** - `49d870f` (feat)

Both `type="auto"` tasks landed in this one commit rather than two -- see Deviations below for the full account. Task 3 (render-gate checkpoint) produced no file changes; its findings are recorded in `coverage` above and "Pending human sign-off" below.

**Plan metadata:** commit pending (this SUMMARY + STATE.md/ROADMAP.md/REQUIREMENTS.md update)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` - Six-tile `chipModel`, three backend seams, three truth mirrors, three press functions, chevron split affordance, `panelRequested`/`openPanel` relay origin, label wrap machinery
- `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml` - Three backend properties relayed down, `panelRequested` signal relayed up, `QuickToggles` mount site wiring
- `quickshell/.config/quickshell/modules/Dashboard.qml` - Three backend properties relayed down, `panelRequested` signal relayed up, `dashboardTabLoader` mount site wiring
- `quickshell/.config/quickshell/shell.qml` - `audioTruthNeeded` gate, three backend bindings on the `Dashboard {}` instance, `onPanelRequested` handler calling the existing guarded `openPanel(name)`

## Decisions Made

See `key-decisions` in frontmatter for full text. Summary:

- **`audioTruthNeeded` gate widening was REQUIRED**, measured live, not assumed (branch B of the plan's flagged assumption). WifiBackend/BluetoothBackend needed no equivalent change.
- **The Do Not Disturb label did not actually need to wrap** at this session's font/DPI, but the wrap machinery is in place regardless per the plan's hard constraint.
- **Tasks 1+2 landed in one commit**, not two, due to interleaved edit locations across the same four files -- documented rather than forced apart artificially.

### Decision records landed verbatim in source (quoted here per the plan's `<output>` requirement)

**D-15-20**, above `openPanel(name)` in `QuickToggles.qml`:
> Dismissing a panel opened from a tile returns to the desktop, never to the drawer. This is not a preference the tile path could have chosen differently: `hyprland_focus_grab_v1` is exclusive per-compositor on this build (11-QUICKSHELL-EVIDENCE Finding 2, verified in both orders), so the panel's own grab implicitly clears the drawer's, firing its `onCleared` and destroying the drawer's surface rather than hiding it.

**D-15-21**, above `chipModel` in `QuickToggles.qml`:
> The grid goes from three tiles to six in ONE row ... Zero vertical growth is the whole point ... the shipped drawer is 760px wide ... so the tile row is 760 - 48 (`content` margins) - 48 (`DashboardTab` padding) = 664px, and six tiles at five 8px gaps is about 104px each ... HARD CONSTRAINT: the Do Not Disturb label wraps to two lines inside the 72px height and must NEVER be shortened to an acronym.

**E6 `error` contract**, beside `chipWatchdogTimer`:
> A toggle that does not take ... must revert the tile to its true state rather than sticking lit. This needs no new code and deliberately introduces no fifth widget state.

### Corrected tile arithmetic (source lines confirmed this session)

760px `drawerMinWidth` (`Dashboard.qml` line 101) - 48px `content` margins - 48px `DashboardTab` padding = 664px tile row; six tiles at five 8px gaps = (664 - 40) / 6 ≈ **104px per tile**. Confirmed at the render gate: the Do Not Disturb label rendered legibly at this width without needing to wrap (see Pending human sign-off, item 1).

## Live Measurements Recorded

- **Drawer height, before any edit:** `quickshell-dashboard` layer 760x**826**px (`hyprctl -j layers`).
- **Drawer height, after all four files landed:** `quickshell-dashboard` layer 760x**826**px. **Byte-identical** -- D-15-21's zero-vertical-growth claim holds.
- **Volume live truth:** `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` (external) flipped the tile lit<->unlit within ~1s each direction, drawer open, audio panel closed. Restored to original unmuted state (`Volume: 0.58`, not muted) afterward.
- **Wi-Fi live truth:** `nmcli radio wifi off` / `nmcli radio wifi on` (external) flipped the tile unlit<->lit within ~1s each direction. Restored to `enabled` (radio on, disconnected, ethernet primary) afterward.
- **Chevron-path proof, all three panels, via the identical guarded function the chevron reaches:**
  - `qs ipc call panel open audio` -> `quickshell-audio-panel` appeared, `quickshell-dashboard` gone; `qs ipc call panel toggle audio` -> closed.
  - `qs ipc call panel open wifi` -> `quickshell-wifi-panel` appeared, `quickshell-dashboard` gone; closed via `wtype -k Escape` (D-15-20 proof, see below).
  - `qs ipc call panel open bluetooth` -> `quickshell-bluetooth-panel` appeared; `qs ipc call panel toggle bluetooth` -> closed.
- **D-15-20 dismissal:** after opening the wifi panel, `wtype -k Escape` produced zero `quickshell-*` layers (desktop). Dispatching the dashboard global shortcut afterward re-summoned `quickshell-dashboard`, screenshot-confirmed the Dashboard tab (not Media/Performance/Weather) was active.
- **DASH-08 fullscreen refusal, both paths:** focused a real `kitty` client, fullscreened it (`hyprctl -j activewindow` confirmed `fullscreen: 2`). With it fullscreen: (1) the dashboard global shortcut produced zero `quickshell-*` layers; (2) `qs ipc call panel open audio` (the identical function the chevron path reaches) also produced zero `quickshell-*` layers. Restored the client to `fullscreen: 0` afterward.
- **`quickshell-doctor`:** 12 passed / 1 failed. The one failure (`one-step-per-press volume probe`, measuring hardware-key volume-step drift) is a **pre-existing, environment-dependent failure unrelated to this plan** -- confirmed by `git stash`-ing all four of this plan's files, re-running the doctor against the pre-edit state, and observing the identical failure with the identical numbers, then restoring the plan's changes via `git stash pop`. Out of this plan's declared scope (four QML files touching none of the volume-step/swayosd machinery); not auto-fixed per the deviation rules' scope boundary.
- **`keybind-doctor`:** 14 passed / 0 failed.
- **`motion-lint`:** 99 passed / 0 failed, all four modified files individually confirmed PASS on both CHECK A and CHECK B.
- **`git diff --stat`:** exactly 4 files, matching the plan's fence.
- **Hex literals:** `grep -cE '#[0-9a-fA-F]{3,8}'` (comments stripped) is `0` across all four files.
- **`~/.cache/quickshell.log`:** zero `QML .*Error`/`TypeError`/`is not a function`/`Unable to assign` lines across the entire session, including the summon/chevron-equivalent/panel/dismiss cycles above.

## Deviations from Plan

### Auto-fixed Issues

None requiring a Rule 1/2/3 fix during code-writing -- the plan's own flagged assumptions (audioTruthNeeded, wifi/bluetooth gate shape) were investigated exactly as instructed and resolved by measurement, not by an unplanned bug fix.

### Scope note: Tasks 1 and 2 committed together, not separately

**Recorded plainly rather than silently merged.** The plan's own task boundaries put Task 1's truth/verb/label work and Task 2's chevron/relay work in the *same* insertion points inside the *same* four files -- e.g. Task 2's `chipPanel`/`chevronTooltip` fields sit inside the very `chipModel` array entries Task 1 extends to six, and Task 2's `panelRequested` signal/`openPanel` function sit directly beside Task 1's `pressChipByName`. Constructing an artificial intermediate commit (Task 1 only) would have meant either shipping a broken partial diff or hand-reconstructing a state neither task's own acceptance criteria describes. Both tasks' full verification blocks were run independently against the final combined state and both passed in full (see `coverage` above and the Live Measurements section) -- this is a commit-granularity deviation, not a verification-coverage gap.

### Scope note: two live-verification gaps, both consistent with 15-05/15-06's documented precedent

1. **No synthetic pointer-input tool exists on this host** (`ydotool`/`dotool`/`wlrctl`/`xdotool` all absent, `wtype` is keyboard-only -- reconfirmed this session, identical to 15-05-SUMMARY.md and 15-06-SUMMARY.md's own finding). This means the chevron's own 32x32 `MouseArea` and each tile's body `MouseArea` could not be literally clicked and observed. Substituted: the guarded summon function the chevron ultimately reaches (`shell.qml`'s `openPanel(name)`) was exercised end-to-end for all three panels via `qs ipc call panel open|toggle <name>` -- the IPC handler calls the *identical* function, so the guard/loader/dismiss machinery is fully proven; only the physical click landing on the chevron's specific hit region is unproven. Recorded as `human_judgment: true` in `coverage` D4 rather than implied as fully click-verified.
2. **The E6 error-contract fault injection did not cleanly reproduce a "refused write."** Blocking wifi via `rfkill block wifi` and then attempting `nmcli radio wifi on` (simulating what `setWifiEnabled(true)` would do) surprisingly succeeded at the NetworkManager software-radio-switch level (`nmcli radio wifi` read back `enabled`) even while the hardware remained soft-blocked -- NetworkManager's own software toggle is apparently independent of rfkill state on this build, so this did not produce a clean "the write is refused" scenario to observe a stuck-then-reverting tile against. Combined with gap 1 above (no way to literally press the tile), this criterion is **source-verified only**: the mechanism (`pressWifi()` never assigns `wifiRadioOn`, the one shared `chipWatchdogTimer` clears `pendingChip` after `chipTimeoutMs` regardless of outcome) is structurally sound and matches the three Phase 14 chips' already-approved pattern exactly, but was not observed live end-to-end this session. rfkill and nmcli wifi radio state were both restored to session-start (`Soft blocked: no`, `enabled`) immediately after the attempt.
3. **Bluetooth's own external-toggle live proof was intentionally not run**, to honor the non-negotiable instruction to leave the session's rfkill-soft-blocked bluetooth state untouched. The Bluetooth tile's mechanism is architecturally identical to Wi-Fi's (confirmed by direct source read, no gate difference), and it correctly rendered unlit at rest against the genuine soft-blocked state -- but no external `bluetoothctl power on/off` cycle was performed to watch it flip.

---

**Total deviations:** 0 auto-fixed bugs. 1 commit-granularity deviation (two tasks in one commit, both fully verified). 3 live-verification gaps, all honestly recorded rather than implied as covered, two of them a repeat of the exact tooling gap 15-05/15-06 already documented for this host.
**Impact on plan:** No code defect found or introduced. The DASH-08 guard-uniqueness, zero-vertical-growth, and drawer/panel replace-not-stack invariants are all fully machine-verified. The literal mouse-click and hardware-fault-injection proofs are the batched items for human review before 15-09, same posture as 15-05/15-06's own gaps.

## Issues Encountered

**`quickshell-doctor`'s volume-step probe fails, confirmed pre-existing and unrelated to this plan** (see Live Measurements above for the git-stash isolation proof). No action taken -- out of this plan's declared file scope, logged here rather than silently absorbed or auto-fixed.

**No synthetic pointer-input tool on this host** -- the same platform gap 15-05-SUMMARY.md and 15-06-SUMMARY.md both already documented, now confirmed a third time for this plan's own click-driven affordances (chevron, tile body press).

## User Setup Required

None. rfkill (bluetooth soft-blocked) and nmcli wifi-radio state were both restored to session-start values before this SUMMARY was written -- confirmed via `rfkill list` (`Soft blocked: yes` for `hci0`, `Soft blocked: no` for `phy0`) and `nmcli -t -f DEVICE,TYPE,STATE device status` (`wlan0:wifi:disconnected`, `eno1:ethernet:connected`) immediately before this write. Quickshell was never restarted -- same PID (`2982672`) throughout, confirmed via `qs list` at both the start and the end of this session.

## Next Phase Readiness

**Code is complete and the machine-verifiable half of every acceptance criterion passed.** The DASH-08 guard-uniqueness proof, the zero-vertical-growth proof, the D-15-20 dismiss/re-summon proof, the live-truth-follows-external-change proof (Volume/Wi-Fi), and the `motion-lint`/`keybind-doctor`/hex-literal/log-error mechanical checks are all directly measured this session, not assumed. What remains for the batched human review before 15-09: (1) an actual mouse click on the chevron and each tile body (no synthetic pointer tool on this host, a now three-times-documented gap), (2) a genuine "toggle refused" fault-injection observed live rather than reasoned from source, and (3) the taste calls the render gate itself flags below (composition, chevron discoverability, lit-state-at-rest legibility).

15-08 (waybar click parity) and 15-09 (quickshell-doctor phase-close gate) should read this SUMMARY's `audioTruthNeeded` finding before touching anything audio-adjacent -- the gate now widens on `dashboardLoader.active`, not only `audioPanelLoader.active`, which 15-09's own doctor checks may need to account for if they probe `AudioBackend.panelOpen` directly.

## Pending human sign-off

Per the orchestrator's instruction, Task 3's render gate was not stopped on. These are my own honest, evidence-backed judgements for the batched review before 15-09, following the required pros-and-cons-plus-recommendation format at each judgement call.

1. **THE HEADLINE QUESTION — is "Do Not Disturb" legible at six across?** **I can answer this one directly, live-verified with a zoomed screenshot this session.** At the shipped ~104px tile width, "Do Not Disturb" rendered on **one line**, comfortably inside the tile with visible left/right margin, no clipping at the rounded edge, no collision with the icon above it. This is a stronger outcome than the plan's own arithmetic anticipated (it expected a two-line wrap might be necessary) -- this session's installed font apparently sets "Do Not Disturb" narrower than the plan's conservative estimate. **My recommendation: approve.** The wrap machinery (explicit width, `WordWrap`, `maximumLineCount: 2`, no elide) is still correctly in place per the hard constraint, so a future font/DPI change that DOES require wrapping is already handled without further code changes -- it just isn't visually exercised on this specific host/font combination today.

2. **The six-across composition as a whole.** **Live-verified via screenshot**, not merely reasoned about. Six tiles read as one deliberate row -- consistent tile width, consistent rounding, consistent icon size (24px, matching `iconSizeMd`), no visual "got squeezed" artifact. Two tiles (Gaming, Bluetooth) sit unlit/gray at rest, four (DND-unlit-too actually, so: Dark/Volume/Wi-Fi lit, Gaming/DND/Bluetooth unlit) sit in a legible three-and-three split in this session's actual state (not the four-lit example the plan's own hypothetical described, since DND was off and Bluetooth was rfkill-blocked at measurement time). **My recommendation: approve** -- the reference lens (end-4/Caelestia's compact-tile scaling, never adding rows) reads as intended; nothing in the screenshot suggests the icon is "lost" at this tile size.

3. **The chevron affordance.** **Partially live-verified.** The chevron glyph (`chevron_right`) is visibly present in the top-right corner of exactly the three new tiles (Volume/Wi-Fi/Bluetooth) and visibly absent from the three legacy tiles (Gaming/DND/Dark) in the same screenshot -- confirmed by direct pixel inspection of the zoomed crop. **What I could NOT verify**: an actual mouse hover producing its distinct tooltip, or an actual mouse click landing on the 32x32 hit region and opening the panel (no synthetic pointer tool on this host -- see Deviations). What I substituted: exercising the identical downstream function (`shell.qml`'s `openPanel(name)`) via IPC, which proves the guard/loader/relay machinery works correctly, but says nothing about whether a human's actual finger/cursor finds the 32x32 region comfortable to hit. **My recommendation: approve the mechanism as built (source-verified: correct glyph, correct visibility gating, correct stacking order above the body MouseArea) but ask a human to specifically try clicking it** -- this is exactly the kind of subjective hit-target-feel question this gate exists to catch, and I have no way to answer it myself on this host.

4. **Lit state at rest.** **Live-verified via screenshot.** In this session's actual state (DND off, Dark on from a prior test, Volume unmuted, Wi-Fi radio on, Bluetooth rfkill-blocked), three tiles sat lit (Dark/Volume/Wi-Fi) and three sat unlit (Gaming/DND/Bluetooth) -- a different split than the plan's own "four lit" hypothetical (which assumed Bluetooth would also be on), but the same underlying point holds: the row reads clearly with three tiles lit simultaneously, the accent tone doesn't flatten the lit/unlit distinction at this ratio. **My recommendation: approve** -- but note that at THIS host's typical daily state (bluetooth usually blocked, as per non-negotiable rule 3), the "four tiles lit" scenario the plan describes may be rarer here than on a bluetooth-enabled daily driver; worth a human's opinion on whether the four-lit case (when bluetooth+wifi+volume+dark are all on) still reads clearly, since I could not produce that exact combination without violating the instruction to leave bluetooth blocked.

5. **Zero vertical growth.** **Fully machine-verified**, not a judgement call. 826px before, 826px after (two live `hyprctl -j layers` readings, quoted above). Nothing below the toggle block was pushed or cropped -- confirmed by eye in both full-drawer screenshots taken this session (the calendar, media widget, and resource strip all sit in their expected positions in both). **Recommend treating this as settled**, per the plan's own framing.

6. **A toggle that cannot land.** **Not cleanly fault-injected this session** -- see Deviations item 2 above for the honest account (rfkill+nmcli didn't reproduce a refused write; no pointer tool to press the actual tile). Source-verified only: the mechanism is structurally identical to the three already-approved Phase 14 chips. **My recommendation: treat this as the single highest-priority item for a human (or a future session with a synthetic pointer tool available) to actually exercise** -- it's the plan's own named E6 contract and the one live-behavior claim I could not honestly confirm end-to-end.

**Bottom line:** every machine-checkable claim in this plan (guard uniqueness, zero vertical growth, drawer/panel replace-not-stack, live-truth-follows-external-change for Volume and Wi-Fi, DASH-08 fullscreen refusal on both the drawer and the panel-open path, `motion-lint`/`keybind-doctor`/hex/log-error hygiene) is directly measured and passes. What's left for a human: an actual click on the chevron and tile bodies (no pointer tool on this host, a now-recurring gap across 15-05/15-06/15-07), and a live look at the E6 error-revert behavior. Recorded in `.planning/WINDOWS.md` per the ledger protocol.

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml`
- FOUND: `quickshell/.config/quickshell/modules/Dashboard.qml`
- FOUND: `quickshell/.config/quickshell/shell.qml`
- FOUND: commit `49d870f` (Tasks 1+2)
</content>
