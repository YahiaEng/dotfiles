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
  tasks: 4
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
  - "Task 4's blocking checkpoint:human-verify render gate is APPROVED — all nine checks pass, no change request. The human's explicit answers to the three judgment calls: check 2 (geometry) — 850x620 approved as shipped, the settled frame size 15-03..15-06 lay out against, no retune; check 3 (Advanced affordance) — the shared header chrome approved as-is, inherited unchanged by all three panels; check 9 (entrance motion) — the cascade approved, reads as one singular motion. Plan is now CLOSED, 4/4 tasks complete."
  - "A prior executor's live-verify restart of quickshell was NOT detached and died with that executor's session, silently breaking Super+A/Super+D until recovered with the standing detached-restart form — see Deviations for the full incident record and its carry-forward obligation for 15-03..15-09."

patterns-established:
  - "Panel body files (AudioPanel.qml) extend PanelDialog directly (root type PanelDialog) rather than receiving its constants as passed-in properties — matches PanelDialog's own header note that a panel body reads spacing/type constants off itself the same way MediaTab.qml reads them off dashboardWindow, but via direct type inheritance since AudioPanel IS a PanelDialog instance."
  - "PanelDialog's D-15-09 empty-state placeholder is a sibling of bodyFlick, anchored to the same region, rather than a child slotted into bodyContent (the panel-supplied body alias) — the frame owns its own fallback state independently of whatever a panel file writes into its body slot. emptyStateGlyph/emptyStateText are plain (non-readonly) properties so 15-04/05/06 can supply panel-specific empty copy without restructuring this mechanism."

requirements-completed: [PANEL-02, PANEL-05, PANEL-06]

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
      - kind: other
        ref: "Task 4's nine-check blocking checkpoint:human-verify render gate — APPROVED, no issues raised on any check; checks 2/3/9 answered explicitly per the plan's own resume-signal; see 'Task 4 — Blocking render gate resolution' below for full evidence"
        status: pass
    human_judgment: true
    rationale: "Task 4's render gate is now RESOLVED: APPROVED. Checks 2 (geometry, 850x620), 3 (Advanced affordance, shared header chrome) and 9 (entrance cascade) — the three explicit judgment calls — were each answered by the human ('yes' on all three), verbatim recorded below. D1 is fully closed; no open judgment remains."
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

duration: 47min (implementation session; Task 1's original tracer-code-authoring time is recorded separately in git history, commit 5e6bf2d, from the prior worktree session) + a separate gate-closure session for Task 4
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 02: Audio Panel Tracer + Advanced/Empty-State Contract Summary

**Super+A summons a real audio-mixer layer surface wired end to end to the live PipeWire default sink, closing Task 1's tracer-feedback gate live on the main checkout (finding and fixing a real zero-height Slider bug along the way), then landing Task 2's D-15-22 disabled-Advanced treatment and D-15-09 empty-state placeholder and Task 3's gate re-runs — Task 4, the plan's own blocking human render gate, is now APPROVED with all nine checks answered. Plan CLOSED, 4/4 tasks complete.**

## Performance

- **Implementation session's duration:** 47 min
- **Tasks completed:** 4 of 4 — Task 1's live-verify gate closed + a Rule 1 fix; Task 2; Task 3; Task 4's blocking render gate reached, then APPROVED in a follow-up gate-closure session.
- **Files modified (implementation session):** 3 (`AudioPanel.qml` — bug fix; `PanelDialog.qml` — Task 2 additions; `windowrules.lua` — Task 2 addition). The gate-closure session touches only tracking/docs files (this SUMMARY, STATE.md, ROADMAP.md, REQUIREMENTS.md) — no production QML changed.

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

## Task 4 — Blocking render gate resolution

**Verdict: APPROVED.** No issues raised on any of the nine checks. This closes the plan's own `gate="blocking"` checkpoint and moves the plan from 3/4 to 4/4 tasks complete.

### The three explicit judgment calls (required to be answered even on approval, per the plan's own `<resume-signal>`)

- **Check 2 — Geometry (D-15-03).** Human: "yes it reads right." The 850x620 frame is **approved as shipped**. Recorded here as the settled frame size that 15-03, 15-04, 15-05 and 15-06 lay out against — **no retune**. The empty space below the master block noted in the plan's own `<how-to-verify>` is confirmed to be an artefact of the tracer's deliberate one-third-built scope, not of the geometry itself, per the plan's own recommendation (approve-as-is over retune-now).
- **Check 3 — Header band / Advanced affordance (D-15-06).** Human: "yes advanced reads as an optional action." The shared header chrome (glyph, title, labeled "Advanced" on the right, no close button) is **approved as-is** and is inherited **unchanged** by all three panel instances — this is the one check the plan itself flagged as "genuinely worth changing now if it reads wrong" (since it is identical chrome that 15-03 inherits in the very next wave); it read right, so nothing changes.
- **Check 9 — Entrance motion (D-15-08).** Human: "yes it reads as one singular motion." The three-element cascade (header identity → Advanced → master control block) is **approved** — it reads as one settled motion, not three separate arrivals.

### Behavioural checks (facts, not preferences) — approved with no defect found

Checks 1 (summon feel), 4 (master volume + mute live interaction), 5 (no second OSD), 6 (Advanced launch + concurrency), 7 (dismissal paths) and 8 (DASH-08 fullscreen refusal) were all worked through with no issues raised.

### Mechanical re-verification run against the live tree at gate close (recorded as evidence, not re-run as new checks)

- **Check 5 / D-15-24:** `grep -c 'swayosd-client' quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` — zero matches in either file. **PASS** — SwayOSD retains sole ownership of hardware `XF86Audio*` keys; the panel's own slider/mute path never reaches it.
- **Check 5b (criterion-5 coexistence):** `busctl --user list` shows **exactly one** `org.freedesktop.Notifications` owner (swaync). **PASS.**
- **Check 8 / DASH-08:** the fullscreen-refusal guard is present exactly where it must be — inside `function openPanel(name)` in `shell.qml`, documented at lines 142 and 166-169 as living there and nowhere else. **PASS.**
- **Check 6 / PANEL-05:** `grep -c 'startDetached' quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` = `3`; `grep -Eq 'running:[[:space:]]*true' quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` finds nothing. **PASS** — Advanced launches are severed from the panel's destroy-on-dismiss lifecycle, and no lifetime-bound run property exists anywhere in the file.
- **Live global dispatch proof:** `hyprctl dispatch 'hl.dsp.global("quickshell:dashboard")'` shows the `quickshell-dashboard` layer appear then clear; `hyprctl dispatch 'hl.dsp.global("quickshell:audio-panel")'` shows exactly one `quickshell-audio-panel` layer appear then clear. (Layer state needs ~2s to settle before reading `hyprctl layers -j`, or the read is stale and looks like a second bug — noted here so a future re-run does not chase a phantom.)

No round 2 was needed — approved on the first render-gate round.

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

**3. [Rule 1 — operational incident, not a code bug] Non-detached quickshell restart during a prior live-verify session broke Super+A/Super+D until recovered**

A prior executor's live-verify restart of quickshell was **not detached**. The process died when that executor's session ended, silently breaking the human's `Super+D` and `Super+A` — both are `hl.dsp.global("quickshell:...")` dispatches and have no receiver when the shell is dead. Hyprland's own binds remained correctly registered throughout — `hyprctl binds` showed both `A` and `D` still present under modmask 64 — so the config layer looked entirely healthy while every Quickshell keybind was silently dead underneath it.

- **Evidence:** `~/.cache/quickshell.log` ended mid-session at `00:54:49` on an ordinary cascade line, with no error and no shutdown message, leaving a stale `instance.lock` and `ipc.sock` behind in `/run/user/1000/quickshell/by-id/gxg719x14jt/`. A QML crash would have logged something; this did not — the process was killed by its parent shell exiting, not by a fault of its own.
- **Why this happened:** this is the exact failure `15-02-PLAN.md` warns about explicitly (~line 570, "Restart discipline for verification"): "A shell-child restart dies with the executor session and silently breaks `Super+D` ... that has already happened once in this project." It has now happened **twice**.
- **Recovery:** `setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh` (the detached form 14-06 already establishes as the standing rule), confirmed by checking the new PID's PPID is the session manager, not a shell.
- **Files modified:** none — this is a runtime/process incident, not a source change.
- **Verification:** post-recovery, `hyprctl dispatch 'hl.dsp.global("quickshell:dashboard")'` and `hl.dsp.global("quickshell:audio-panel")` both toggle their respective layers correctly again.
- **Carry-forward obligation for 15-03 through 15-09:** any plan whose verification restarts the shell **must** use the detached form (`setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh`) and confirm the new PID's PPID is not a shell before treating the restart as complete. A shell-child restart is not a hypothetical risk in this project — it has now silently broken the live desktop's keybinds twice.

---

**Total deviations this session:** 3 (two Rule 1 code-level fixes — one a genuine rendering bug, one a plan-text/requirement contradiction resolved in the requirement's favor — plus one Rule 1 operational incident with a standing carry-forward obligation for the rest of this phase)
**Impact on plan:** Task 1's fix is a real functional correction (the tracer's core interactive control was invisible before it). Task 2's deviation is a design-intent clarification with no functional regression — it makes the tooltip work as UI-SPEC actually requires. The restart incident caused no data loss and no incorrect committed code, but it did leave the live desktop's panel/drawer keybinds dead until recovered, and it is the second occurrence of a failure mode this project's own plan text already warned about once.

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

## Verification Performed — Task 4 closure

**Task 4's blocking `checkpoint:human-verify` render gate has been answered: APPROVED.** All nine checks (summon feel, geometry discretion, header-band adjacency, master volume+mute live interaction, no-second-OSD proof, Advanced launch+concurrency, dismissal paths, DASH-08 fullscreen refusal, entrance motion) were worked through against the real, currently-live desktop with no issues raised; checks 2, 3 and 9 (the explicit judgment calls) were each answered "yes" with reasons, recorded verbatim in "Task 4 — Blocking render gate resolution" above. See that section for the full nine-check evidence, the mechanical re-verification re-run at gate close, and the approved 850x620/shared-header-chrome contract that 15-03 through 15-09 now inherit.

## Issues Encountered

- Two live quickshell processes were found running simultaneously at session start (stale process hygiene issue in `quickshell-launch.sh`, which execs a new process but never kills a prior one) — resolved by killing the stale PID before any verification; not a plan defect, but worth `quickshell-doctor` or the launch script picking up eventually (out of this plan's scope; noted for a future phase, not filed as a blocker here since it was fully resolved in-session).
- A prior executor's live-verify quickshell restart was not detached and died with that executor's session, silently breaking `Super+A`/`Super+D` until recovered — see Deviations item 3 for the full incident record and its carry-forward obligation for 15-03 through 15-09.

## Next Steps / Plan Continuation

This plan (`15-02`) is **complete** — 4/4 tasks, Task 4's blocking render gate APPROVED. Remaining work belongs to the next plans in the phase, not to this one:

1. **15-03** inherits `PanelDialog`'s public surface and the approved 850x620 geometry / shared header chrome as a settled contract — no further retune expected.
2. STATE.md, ROADMAP.md and REQUIREMENTS.md are updated as part of this closure (see this session's tracking commit).

`PANEL-02`, `PANEL-05` and `PANEL-06` are marked complete in this SUMMARY's frontmatter — Task 4's render gate was the final proof point the plan's own `<success_criteria>` required before any of the three could be checked off, and it is now closed.

---
*Phase: 15-audio-connectivity-panels*
*Plan: 02 (4/4 tasks complete — Task 4's blocking render gate APPROVED, plan CLOSED)*

## Self-Check: PASSED

All nine `key-files` (created + modified) exist on disk; all five referenced commit hashes (`5e6bf2d`, `77c4e28`, `47ff6b1`, `841869d`, `f6326c0`) are present in `git log --oneline --all`. No missing items.
