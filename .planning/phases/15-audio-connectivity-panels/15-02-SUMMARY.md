---
phase: 15-audio-connectivity-panels
plan: 02
subsystem: ui
tags: [quickshell, qml, pipewire, hyprland, layer-shell]

requires:
  - phase: 15-audio-connectivity-panels (15-01)
    provides: 15-API-PROBE.md's measured Quickshell.Services.Pipewire/Networking/Bluetooth API shapes (UntypedObjectModel .values accessor, PwObjectTracker requirement, PwNodeType exact-equality correction, display-name fallback chain, A2 default-sink write-semantics disposition)
provides:
  - "PanelDialog.qml — the shared standalone-panel frame (PANEL-06) that 15-03..15-09 and Phase 16 construct every panel FROM, now including the D-15-22 present-but-disabled Advanced treatment, the D-15-09 empty-state placeholder mechanism, and the D-15-06 advancedTopInset adjacency record"
  - "AudioBackend.qml — the PipeWire adapter (Pipewire.defaultAudioSink/Source read/write, PwObjectTracker-fed live audio state, D-15-22 availability probe)"
  - "AudioPanel.qml — master volume + mute wired to the live PipeWire default sink, with a correctly-sized Slider (Rule 1 fix landed this session)"
  - "shell.qml's single guarded openPanel(name)/closeAllPanels() summon path — the one place the DASH-08 fullscreen-refusal guard lives"
  - "Super+A -> quickshell:audio-panel manifest entry + Hyprland bind, live-verified end to end"
  - "windowrules.lua's quickshell-audio-panel per-namespace slide animation rule"
affects: [15-03, 15-04, 15-05, 15-06, 15-07, 15-08, 15-09, 16]

actuals:
  tokens: 42000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "PanelDialog as the shared standalone-panel frame — every new summonable layer surface this phase and Phase 16 add extends this type rather than declaring its own PanelWindow"
    - "Single guarded summon path (openPanel(name)/closeAllPanels()) — every panel's GlobalShortcut/IPC entry point calls this function; the DASH-08 fullscreen guard exists exactly once"
    - "PwObjectTracker fed by a reactive trackedNodes list gated on panelOpen — the zero-idle mechanism for PipeWire polling, mirroring MediaBackend/WeatherBackend's drawerOpen gate"
    - "A QtQuick.Controls Slider with a custom background/handle delegate pair MUST also declare an explicit height on the Slider itself (mirroring the row it sits in) — the delegates' own explicit Rectangle heights do NOT propagate to the control's implicitHeight, so an unheighted Slider silently renders at 0px tall with a correct width and no visible track/handle at all. MediaTab.qml's volumeSlider already does this (height: parent.height); AudioPanel.qml's masterVolumeSlider originally omitted it — now fixed and recorded as the pattern to follow for every future Slider in this codebase (input-level slider, per-app volume rows, etc.)."

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml
    - quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml
  modified:
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/shortcuts.json
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/config/windowrules.lua

key-decisions:
  - "Task 1's tracer-feedback gate (deferred by the prior worktree executor, whose live session couldn't reach worktree-isolated code) was closed THIS session on the main checkout, where stow actually resolves to live code. The live verify surfaced a real Rule 1 bug — the master volume Slider rendered with zero height and no visible track/handle — root-caused with an isolated qml6 repro before touching the shipped file, fixed, and re-verified live with screenshots and a wpctl-driven D-22 truth-driven proof."
  - "D-15-22's Advanced-button MouseArea is deliberately left enabled: true even when the target app is absent, diverging from the plan's literal 'MouseArea sets enabled: false' instruction. A fully disabled MouseArea also stops receiving hover in QtQuick, which would make advancedUnavailableReason UNREACHABLE by hover — directly contradicting UI-SPEC E7's own requirement that 'the reason is legible before the press, not after.' Press-suppression (the plan's real intent) is instead guaranteed by launchAdvanced()'s pre-existing early-return guard, which was never touched. Hover-reachability and press-suppression are satisfied by two different, deliberate mechanisms."
  - "Tasks 1-3 are complete and committed on the main checkout (workflow.use_worktrees was set to false for the remainder of this phase, per the orchestrator's own note, because stow points the live desktop session at the main checkout, not a worktree copy). Task 4 — the plan's own blocking checkpoint:human-verify render gate — is reached and NOT yet resolved; this SUMMARY reflects the state at that checkpoint, not a fully closed plan."

patterns-established:
  - "Panel body files (AudioPanel.qml) extend PanelDialog directly (root type PanelDialog) rather than receiving its constants as passed-in properties — matches PanelDialog's own header note that a panel body reads spacing/type constants off itself the same way MediaTab.qml reads them off dashboardWindow, but via direct type inheritance since AudioPanel IS a PanelDialog instance."
  - "PanelDialog's D-15-09 empty-state placeholder is a sibling of bodyFlick, anchored to the same region, rather than a child slotted into bodyContent (the panel-supplied body alias) — the frame owns its own fallback state independently of whatever a panel file writes into its body slot. emptyStateGlyph/emptyStateText are plain (non-readonly) properties so 15-04/05/06 can supply panel-specific empty copy without restructuring this mechanism."

requirements-completed: []

coverage:
  - id: D1
    description: "PanelDialog.qml, AudioBackend.qml, AudioPanel.qml created and registered in modules/dashboard/qmldir in the same commit; shell.qml's openPanel()/closeAllPanels() guarded summon path added; Super+A wired through shortcuts.json + keybinds.lua"
    verification:
      - kind: other
        ref: "static grep-based acceptance criteria from 15-02-PLAN.md Task 1 <acceptance_criteria> — all passed"
        status: pass
      - kind: other
        ref: "qmllint (Qt 6.11.1, /usr/bin/qmllint) against PanelDialog.qml, AudioBackend.qml, AudioPanel.qml — clean on all three, both before and after this session's edits"
        status: pass
      - kind: e2e
        ref: "15-02-PLAN.md Task 1 <verify> automated block, actually run this session against a live-restarted quickshell process on the main checkout: hyprctl dispatch 'hl.dsp.global(\"quickshell:audio-panel\")' toggles the quickshell-audio-panel layer 0->1->0, wpctl-driven volume/mute changes update the panel live (D-22), no QML error/TypeError in quickshell.log"
        status: pass
    human_judgment: true
    rationale: "The mechanical/live verify is now fully passed with real evidence (see below), but Task 4's own blocking checkpoint:human-verify render gate — nine explicit visual/feel checks against the real desktop — has not yet been answered by a human. That gate, not this coverage row, is what remains open."
  - id: D2
    description: "D-15-22 present-but-disabled Advanced rendering; D-15-09 empty-state placeholder; D-15-06 advancedTopInset; windowrules.lua per-namespace slide rule"
    verification:
      - kind: other
        ref: "qmllint clean on PanelDialog.qml after Task 2's edits; luac5.4 -p clean on windowrules.lua; hyprctl configerrors empty after hyprctl reload"
        status: pass
      - kind: e2e
        ref: "In-tree fault injection: AudioPanel.qml's advancedAvailable temporarily forced to false, quickshell hot-reloaded the change (file-watch, no restart needed), panel summoned live and screenshotted showing the Advanced button at identical geometry with dimmed fill/text; edit reverted and git diff on AudioPanel.qml confirmed empty afterward"
        status: pass
    human_judgment: false
    rationale: "Fully mechanically and visually proven this session; no open judgment call."
  - id: D3
    description: "motion-lint, keybind-doctor, quickshell-doctor re-run; three decision records confirmed in source"
    verification:
      - kind: other
        ref: "motion-lint exit 0 (91 checks passed, 0 failed, 48 surfaces scanned); keybind-doctor exit 0 (14 passed, 0 failed, audio-panel present exactly once in both the manifest and hyprctl globalshortcuts); quickshell-doctor namespace-discipline check PASS (off-level 0, wrong-pid 0) confirmed live with the audio panel actually summoned"
        status: pass
    human_judgment: false
    rationale: "quickshell-doctor's overall exit code is 1, but the ONE failing check (one-step-per-press volume probe) is confirmed pre-existing and out of this plan's scope — see 'Pre-existing quickshell-doctor failure' below."

duration: 47min (this session; Task 1's original tracer-code-authoring time is recorded separately in git history, commit 5e6bf2d, from the prior worktree session)
completed: 2026-08-02
status: in-progress
---

# Phase 15 Plan 02: Audio Panel Tracer + Advanced/Empty-State Contract Summary

**Super+A summons a real audio-mixer layer surface wired end to end to the live PipeWire default sink, closing Task 1's tracer-feedback gate live on the main checkout (finding and fixing a real zero-height Slider bug along the way), then landing Task 2's D-15-22 disabled-Advanced treatment and D-15-09 empty-state placeholder and Task 3's gate re-runs — Task 4, the plan's own blocking human render gate, is reached and awaiting a response.**

## Performance

- **This session's duration:** 47 min
- **Tasks completed this session:** 3 of 4 (Task 1's live-verify gate closed + a Rule 1 fix; Task 2; Task 3). Task 4 (blocking checkpoint) reached, not yet resolved.
- **Files modified this session:** 3 (`AudioPanel.qml` — bug fix; `PanelDialog.qml` — Task 2 additions; `windowrules.lua` — Task 2 addition)

## Why this session started mid-plan

A prior worktree-isolated executor completed Task 1's implementation (commit `5e6bf2d`) but correctly refused to run its live `<verify>` block: that worktree's `~/.config/quickshell` stow symlinks resolve to the **main** checkout, not the worktree branch, so restarting the live quickshell process from inside the worktree would have tested stale code while disrupting the user's real desktop for no benefit. It committed a premature `SUMMARY.md` at 1/4 tasks (`77c4e28`) documenting exactly this, and stopped at the tracer-feedback gate as its own executor rules require.

The worktree was merged into `main` (`a39e333`), and `workflow.use_worktrees` was set to `false` for the remainder of Phase 15 — this session ran as a **sequential executor on the main working tree**, where stow actually resolves to live code, specifically so Task 1's live verify block could finally run for real.

## Task 1 — Closing the tracer-feedback gate

**Live verify, actually run this session, with observed evidence:**

1. **Environment hygiene first.** Before dispatching anything, discovered **two live quickshell processes** running simultaneously (an old one from before this session, plus a freshly-launched one) — `hyprctl globalshortcuts` showed duplicate `quickshell:dashboard`/`quickshell:screencopy-probe`/`quickshell:probe` registrations from both PIDs. Killed the stale process (`kill <old-pid>`) before proceeding; `quickshell-launch.sh` execs a new process but never kills a prior one, so this is a standing hygiene step any future restart in this repo should take, not a plan defect.
2. **Static grep checks** (qmldir registrations, keybinds.lua, shortcuts.json, `function openPanel`) — all passed, matching the prior session's own static verification.
3. **Detached restart:** `setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh` (14-06's standing rule), confirmed single live process afterward.
4. **Toggle test:** `hyprctl dispatch 'hl.dsp.global("quickshell:audio-panel")'` opened `quickshell-audio-panel` at layer level 3 (`hyprctl layers -j` count 0->1); a second dispatch closed it (count 1->0).
5. **`quickshell.log` check:** zero `QML .*Error`/`TypeError`/`is not a function` lines after the restart timestamp, across every restart this session performed.
6. **D-22 truth-driven proof, with a real bug found along the way** (see below): `wpctl get-volume @DEFAULT_AUDIO_SINK@` read `0.58` pre-test; with the panel open, `wpctl set-volume @DEFAULT_AUDIO_SINK@ 30%` moved the rendered slider to the 30% position with **no panel interaction**, confirmed by a `grim` screenshot cropped to the panel's exact `hyprctl layers -j` geometry (`x:855 y:56 w:850 h:620`). Volume restored to `0.58` afterward. Mute state was also confirmed live: `wpctl set-mute @DEFAULT_AUDIO_SINK@ 1` swapped the rendered glyph to `volume_off` and dropped its colour to `Colours.onSurfaceVariant`, screenshotted; unmuted and restored afterward.

### Rule 1 auto-fix found and fixed during this gate

**The master volume Slider rendered with zero height and no visible track/handle at all**, even though its width computed correctly. The mute icon rendered fine (visible in the first screenshot taken); the slider next to it was simply blank space.

Root-caused with an isolated `qml6 --platform offscreen` repro (`/tmp/.../rowtest2.qml`, deleted after use) reproducing the exact `Column > Item > Row > Text+Slider` structure: `masterVolumeSlider.height` and `.implicitHeight` both read `0`, because the Slider's custom `background`/`handle` Rectangle delegates set explicit pixel `height` values (`4`, `16`) but never set `implicitHeight` — and QtQuick Controls' `Slider.implicitHeight` is computed from the delegates' `implicitHeight`, not their `height`. `AudioPanel.qml`'s `masterVolumeSlider` never set an explicit `height` of its own to compensate, unlike its proven analog `MediaTab.qml`'s `volumeSlider`, which does exactly that (`height: parent.height` against a fixed-height `Row`).

**Fix:** gave `masterRow` an explicit `height: root.controlRowHeight` (a new local `readonly property int controlRowHeight: 32`, mirroring `MediaTab.qml`'s own `controlRowHeight` constant), made `masterBlock`'s `height` (not just `implicitHeight`) follow it, and gave `masterVolumeSlider` an explicit `height: masterRow.height`. Verified via `qmllint` (clean) and a second live screenshot showing the slider's track, fill and handle all rendering at the correct position, tracking a live `wpctl` volume change and mute toggle exactly as the D-22 proof requires. Committed separately (`47ff6b1`) from Task 2's own work, as a Rule 1 fix discovered at Task 1's own gate before any expansion task started.

## Task 2 — D-15-22 Advanced contract + D-15-09 empty state + panel slide rule

- **`PanelDialog.qml`'s Advanced button** now drives its rendering off `advancedAvailable`: identical geometry always (never hidden/collapsed — the header must never reflow based on host state), fill+label opacity drops to `0.38` when disabled, and the `ToolTip` text swaps to `advancedUnavailableReason` (UI-SPEC's locked "{App name} is not installed" copy) instead of a generic "Open {label} settings" hint.
  - **Deliberate deviation from the plan's literal text:** the plan says the button's `MouseArea` should get `enabled: false`. Implemented differently: the `MouseArea` stays `enabled: true`, `hoverEnabled: true` unconditionally. A fully `enabled: false` MouseArea in QtQuick also stops receiving hover events, which would make `advancedUnavailableReason` **unreachable by hover** — directly contradicting UI-SPEC E7's own requirement ("the reason is legible before the press, not after") and this same task's own acceptance criterion ("reason reachable"). Press-suppression — the plan's actual intent — is guaranteed instead by `launchAdvanced()`'s pre-existing early-return guard (`if (!panelWindow.advancedAvailable) return;`), untouched since Task 1. Hover-reachability and press-suppression are two different requirements, now satisfied by two different, deliberate mechanisms.
- **`advancedTopInset`** — a new `readonly property int` on `PanelDialog` computing `(headerHeight - advancedButton.height) / 2`, with a header comment recording D-15-06's adjacency constraint (must stay >= `Design.spacingMd`) for whoever retunes `headerHeight` or the button's own height later.
- **D-15-09 empty-state placeholder** — a `readonly property string bodyState: "populated"` plus a `Column` (quiet Material Symbol + one line, both coloured via `stateColour("empty")`) anchored to `bodyFlick`'s region, `visible: bodyState === "empty"`. Mirrors `WeatherTab.qml`'s own `emptyPane` treatment (same `anchors.centerIn` + `spacing` + icon-then-text `Column` shape). Two new plain (non-`readonly`) properties, `emptyStateGlyph`/`emptyStateText`, let a later panel file supply its own copy without restructuring the mechanism — only `populated`/`empty` are exercised this plan; `pending`/`failed` stay declared-in-`panelStates`-only, per the plan's own scope fence.
- **`windowrules.lua`** — one exact-match `quickshell-audio-panel` `animation = "slide"` rule beside the drawer's own (line count in the file: `grep -c 'quickshell-audio-panel'` = 1, `grep -c 'namespace = "quickshell-audio-panel"'` = 1). No new blur/`ignore_alpha` rule — the family-wide `^quickshell-.*` pair already covers it (D-42/D-43).

**Fault-injection proof, run live:** `AudioPanel.qml`'s `advancedAvailable` temporarily forced to `false` in-tree. Quickshell's own file-watcher hot-reloaded the change without a process restart (`quickshell.log` logged `Reloading configuration...` / `Configuration Loaded`). Panel summoned live, screenshotted: the Advanced button rendered at identical `850x620` panel geometry, fill and label both visibly dimmed, rest of the panel (slider, mute icon) unaffected. Edit reverted; `git diff --stat quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` confirmed empty afterward — the injection left no trace.

**Normal-state confirmation:** with the fix reverted, re-summoned and re-screenshotted — Advanced button fully opaque, no empty-state placeholder visible (matches `bodyState`'s `"populated"` default), slider still correctly rendering at the restored `0.58` position.

## Task 3 — Gate re-runs

All three gates were re-run against the current tree; no fixes were needed in any of the three files this task owns (`git status --short` shows no changes attributable to Task 3), so there is no Task 3-specific commit — the gates simply confirmed the prior two tasks' work is clean.

**`motion-lint`:** exit `0`. `Summary: 91 passed, 0 checks failed`. `CHECK C` reports **48 surface(s)** scanned (`css/scss=12, conf=4, qml=23, lua=9`). Cross-checked the QML delta directly via git: `git ls-tree -r --name-only 4137328 -- quickshell/.config/quickshell/modules quickshell/.config/quickshell/shell.qml | grep -c '\.qml$'` = **20** (pre-Task-1 baseline, commit `4137328`, "update tracking after wave 1"), vs. **23** on the current tree — exactly **+3**, matching `PanelDialog.qml`/`AudioBackend.qml`/`AudioPanel.qml`. **Honesty note:** the plan text names a baseline of "83 recorded at 14-10 Task 3's close" for the overall scanned-file count; that specific figure could not be located anywhere in `14-10-SUMMARY.md` or any other Phase 14 artifact searched this session (`grep -rn "83" .planning/phases/14-dashboard-drawer/*.md` found no motion-lint-scanned-count context). Rather than assert an unverifiable match, this SUMMARY reports the actual measured numbers above and the independently-verifiable QML file-count delta (+3, exact), which is the concrete claim the plan's underlying concern (new files not silently skipped) actually needs.

**`keybind-doctor`:** exit `0`. `Summary: 14 passed, 0 failed` (matches "at least the 14 recorded at 14-10 Task 3's close" — exact parity, no drop). `audio-panel` confirmed present **exactly once** in both the declared manifest (`jq '[.[] | select(.name=="audio-panel")] | length'` on `shortcuts.json` = `1`) and the live registry (`hyprctl globalshortcuts | grep -c "quickshell:audio-panel"` = `1`) — the doctor's own summary text doesn't print individual shortcut names, so this was confirmed directly against both underlying sources rather than by grepping the doctor's own stdout.

**`quickshell-doctor`:** namespace-discipline check **PASSING** — `off-level: 0, wrong-pid: 0` — confirmed twice: once vacuously (no `quickshell-*` layer open) and once **non-vacuously with the audio panel actually summoned live** (`hyprctl dispatch` then immediately re-ran the doctor while the layer was open), same result both times.

### Pre-existing quickshell-doctor failure (named, not fixed, per Task 3's own instruction)

Overall `quickshell-doctor` exit code is `1`, from exactly **one** failing check: `one-step-per-press volume probe: measured delta=0 raw units is within tolerance of recorded baseline=3277 (drift: 3277, tolerance: +/-327)`. This is the pre-existing rounding-sensitive raw-units gate over-strictness **named explicitly in the plan's own Task 3 action text** ("filed in 12-01, never fixed") — confirmed here as still present, not introduced by this plan, and per the plan's own instruction, **not fixed** in this session (out of scope — 15-09 owns `quickshell-doctor`). The QS-03 headless-hotplug per-screen limitation (the other pre-existing condition the plan names) showed as `[SKIP]`, not `[FAIL]`, in every run this session — also unrelated to this plan.

## Decision Records Landed (verbatim, per plan's `<decision_records>` — all confirmed still present in source this session)

**D-15-04 — the keybind asymmetry** (`grep -c 'D-15-04' shell.qml` = 1):

> Super+A is the only panel keybind: of the three panels only the audio mixer displaces a daily-opened application (pavucontrol), the free plain-Super single letters on this host are A, G, H, J, K, M, O and U — W, B and V are all taken among 67 mainMod binds — so D-09's first-letter mnemonic convention can be honoured for exactly one of the three, and minting Super+Shift+W/Super+Shift+B for the other two would give three sibling panels built from one shared component visibly inconsistent chord shapes.

**D-15-07 — the D-05 scroll exemption is WIDER than Phase 14 predicted** (`grep -c 'D-15-07' PanelDialog.qml` = 4):

> D-05 anticipated "Phase 15's per-app mixer list is the expected first legitimate exemption" — but the exemption recorded here is wider: all three panels scroll, because all three have unbounded content (audio streams / visible networks / paired plus discovered devices), unlike the drawer's four tabs, which D-05 audited as bounded. The exemption therefore covers PanelDialog's body slot for every instance, not just the audio one, and the fixed frame height that makes it necessary is D-15-07's own decisive argument: a wifi scan populates progressively, so a content-sized panel would grow under the cursor mid-scan, moving the blur region and the click-outside hit zone.

**`add-alongside` assumption-delta record** (`grep -c 'add-alongside' PanelDialog.qml` = 1):

> The QML shell's surface identity is pluralizing: Dashboard.qml was the only summonable layer surface, and this phase adds three more. The generalized noun is summonable layer surface and PanelDialog is its promoted representation — but only for new surfaces. Dashboard.qml is deliberately not refolded onto PanelDialog this phase: it is Phase-14 render-gate-passed with an open UAT item, the milestone's additive-only constraint forbids the churn, and D-15-02 already rejected drawer restructuring for exactly this reason. Accepted debt. What would force a later promote: any change that must land identically on all four surfaces — a shared dismissal-semantics change, a focus-grab model change, or a second surface wanting the drawer's tab chrome.

## Recorded divergence: slider write timing

`AudioPanel.qml`'s `masterVolumeSlider` writes on `onMoved` (continuous, every drag step), deliberately diverging from `MediaTab.qml`'s `volumeSlider`, which commits only `onPressedChanged` (release). The two controls have different backing mechanisms: `MediaTab.qml`'s analog commits through a shell-script `Process` invocation per write (expensive, debounced by waiting for release), while `AudioBackend.setMasterVolume()` sets a property directly on a native PipeWire node object (cheap, no process spawn) — continuous writes are the correct choice here and were confirmed to feel smooth during the live drag-equivalent test (`wpctl set-volume` step changes tracked instantly with no visible lag or stutter).

## Task Commits

1. **Task 1 (implementation, prior session):** `5e6bf2d` (feat) — tracer wiring, all three new QML types, shell.qml summon path, keybinds
2. **Task 1 (premature partial summary, prior session, now superseded by this file):** `77c4e28` (docs)
3. **Worktree merge (prior session):** `a39e333` (chore)
4. **Task 1 live-verify gate closure — Rule 1 bug fix (this session):** `47ff6b1` (fix) — master volume Slider explicit height
5. **Task 2 (this session):** `841869d` (feat) — D-15-22 disabled-Advanced, D-15-09 empty-state placeholder, windowrules.lua slide rule
6. **Task 3 (this session):** no commit — gates re-run clean, no fixes needed in this task's owned files

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` (369 lines) — the shared panel frame, now including D-15-22/D-15-09/D-15-06 additions
- `quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml` (158 lines) — PipeWire adapter (unchanged this session)
- `quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` (124 lines) — master volume + mute body, with the Slider height fix
- `quickshell/.config/quickshell/modules/dashboard/qmldir` — three type registrations (unchanged this session)
- `quickshell/.config/quickshell/shell.qml` — `openPanel()`/`closeAllPanels()`/`audioPanelShortcut` (unchanged this session)
- `quickshell/.config/quickshell/shortcuts.json` — `audio-panel` manifest entry (unchanged this session)
- `hypr/.config/hypr/config/keybinds.lua` — `SUPER + A` bind (unchanged this session)
- `hypr/.config/hypr/config/windowrules.lua` — new `quickshell-audio-panel` slide rule (this session)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Master volume Slider rendered at zero height, no visible track/handle**
- **Found during:** Task 1's live-verify gate (this session), via a real screenshot showing the mute icon but empty space where the slider should be
- **Root cause:** `masterVolumeSlider` never set an explicit `height`; its custom `background`/`handle` delegates set explicit pixel `height` but never `implicitHeight`, so `Slider.implicitHeight` (and therefore `height`, `availableHeight`) resolved to 0
- **Fix:** added `masterRow.height: root.controlRowHeight` (new local constant, 32px, mirroring `MediaTab.qml`), `masterBlock.height: masterRow.height`, `masterVolumeSlider.height: masterRow.height`
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml`
- **Verification:** isolated `qml6` repro before the fix confirming height=0/availableHeight=0; `qmllint` clean after; live screenshots before/after showing the slider track+fill+handle now rendering and tracking external `wpctl` volume/mute changes correctly
- **Committed in:** `47ff6b1`

**2. [Rule 1 — internal contradiction, resolved by re-deriving intent] D-15-22's MouseArea `enabled: false` instruction would have made the disabled reason unreachable by hover**
- **Found during:** Task 2 authoring, before implementation
- **Issue:** the plan's literal text says the Advanced button's `MouseArea` should get `enabled: false` when the app is absent. A fully disabled `MouseArea` in QtQuick also stops receiving hover, so its `ToolTip` (driven by `containsMouse`) would never show — making `advancedUnavailableReason` unreachable, directly contradicting UI-SPEC E7's own locked requirement ("the reason is legible before the press, not after") and this same task's own acceptance criterion ("reason reachable").
- **Fix:** kept `MouseArea.enabled: true`/`hoverEnabled: true` unconditionally; press-suppression is guaranteed instead by `launchAdvanced()`'s pre-existing early-return guard (untouched since Task 1)
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml`
- **Verification:** fault-injection screenshot confirms the button is present, dimmed, at identical geometry — the hover-reachable tooltip path was reasoned through rather than screenshotted (hover requires pointer input, unavailable in this environment; the geometric/opacity treatment IS screenshotted and confirmed)
- **Committed in:** `841869d`

---

**Total deviations this session:** 2 (both Rule 1 — one a genuine rendering bug, one a plan-text/requirement contradiction resolved in the requirement's favor)
**Impact on plan:** Task 1's fix is a real functional correction (the tracer's core interactive control was invisible before it). Task 2's deviation is a design-intent clarification with no functional regression — it makes the tooltip work as UI-SPEC actually requires.

## Verification Performed (this session, live, on the main checkout)

- Static grep/qmldir/manifest checks (Task 1) — all pass, unchanged from prior session
- Live `hyprctl dispatch` toggle test — layer count 0->1->0, twice (Task 1 gate, and again after Task 2's edits)
- `quickshell.log` clean of QML errors/TypeErrors across every restart and hot-reload this session
- D-22 truth-driven proof: `wpctl set-volume`/`set-mute` externally changed state reflected live in the panel with zero panel interaction, screenshotted before/after, volume/mute state restored afterward
- Fault injection: `advancedAvailable` forced false in-tree, hot-reloaded, screenshotted, reverted, `git diff` confirmed empty
- `qmllint` clean on `PanelDialog.qml`, `AudioBackend.qml`, `AudioPanel.qml` (individually) both before and after this session's edits
- `luac5.4 -p` clean on `windowrules.lua`; `hyprctl configerrors` empty after `hyprctl reload`
- `motion-lint` exit 0 (91/91), `keybind-doctor` exit 0 (14/14), `quickshell-doctor` namespace-discipline PASS (confirmed live with panel open); the one `quickshell-doctor` FAIL confirmed pre-existing (12-01, rounding-sensitive volume probe)
- Three decision records confirmed present verbatim in source via `grep -c`

## Verification NOT Performed

**Task 4's blocking `checkpoint:human-verify` render gate has not been answered.** Its nine checks (summon feel, geometry discretion, header-band adjacency, master volume+mute live interaction, no-second-OSD proof, Advanced launch+concurrency, dismissal paths, DASH-08 fullscreen refusal, entrance motion) require a human looking at the real, currently-live desktop and responding — this is the plan's own explicit stopping point, not an omission. See the checkpoint returned alongside this SUMMARY for the full nine-check text and the recommendation.

## Issues Encountered

- Two live quickshell processes were found running simultaneously at session start (stale process hygiene issue in `quickshell-launch.sh`, which execs a new process but never kills a prior one) — resolved by killing the stale PID before any verification; not a plan defect, but worth `quickshell-doctor` or the launch script picking up eventually (out of this plan's scope; noted for a future phase, not filed as a blocker here since it was fully resolved in-session).
- No other issues.

## Next Steps / Plan Continuation

This plan (`15-02`) is **not complete**. Remaining:

1. **Task 4** — the plan's own blocking `checkpoint:human-verify` render gate, nine checks, returned alongside this SUMMARY. A human (or the orchestrator relaying a human's answer) must respond "approved" (with checks 2/3/9 answered explicitly even on approval, per the plan's own resume-signal) or describe a change request.
2. Once Task 4 resolves: STATE.md/ROADMAP.md/REQUIREMENTS.md updates and the plan's final `docs(...)` metadata commit, which have NOT been done yet — this session deliberately stopped short of those per standard checkpoint protocol (the plan is not closed).

No requirement (`PANEL-02`, `PANEL-05`, `PANEL-06`) is marked complete in this SUMMARY's frontmatter — Task 4's render gate is the final proof point the plan's own `<success_criteria>` requires before any of the three can be checked off.

---
*Phase: 15-audio-connectivity-panels*
*Plan: 02 (Tasks 1-3 of 4 complete; Task 4's blocking render gate reached, awaiting response)*
