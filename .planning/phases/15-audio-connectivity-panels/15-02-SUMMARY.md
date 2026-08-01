---
phase: 15-audio-connectivity-panels
plan: 02
subsystem: ui
tags: [quickshell, qml, pipewire, hyprland, layer-shell]

requires:
  - phase: 15-audio-connectivity-panels (15-01)
    provides: 15-API-PROBE.md's measured Quickshell.Services.Pipewire/Networking/Bluetooth API shapes (UntypedObjectModel .values accessor, PwObjectTracker requirement, PwNodeType exact-equality correction, display-name fallback chain, A2 default-sink write-semantics disposition)
provides:
  - "PanelDialog.qml — the shared standalone-panel frame (PANEL-06) that 15-03..15-09 and Phase 16 construct every panel FROM"
  - "AudioBackend.qml — the PipeWire adapter (Pipewire.defaultAudioSink/Source read/write, PwObjectTracker-fed live audio state, D-15-22 availability probe)"
  - "AudioPanel.qml — master volume + mute wired to the live PipeWire default sink"
  - "shell.qml's single guarded openPanel(name)/closeAllPanels() summon path — the one place the DASH-08 fullscreen-refusal guard lives"
  - "Super+A -> quickshell:audio-panel manifest entry + Hyprland bind"
affects: [15-03, 15-04, 15-05, 15-06, 15-07, 15-08, 15-09, 16]

actuals:
  tokens: 9100
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "PanelDialog as the shared standalone-panel frame — every new summonable layer surface this phase and Phase 16 add extends this type rather than declaring its own PanelWindow"
    - "Single guarded summon path (openPanel(name)/closeAllPanels()) — every panel's GlobalShortcut/IPC entry point calls this function; the DASH-08 fullscreen guard exists exactly once"
    - "PwObjectTracker fed by a reactive trackedNodes list gated on panelOpen — the zero-idle mechanism for PipeWire polling, mirroring MediaBackend/WeatherBackend's drawerOpen gate"

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

key-decisions:
  - "Executed Task 1 (the plan's type=\"tracer\" task) only, then stopped at the executor's mandatory tracer-feedback gate — Tasks 2-4 (Advanced-disabled rendering, four-state vocabulary, windowrules.lua slide rule, gate re-runs, and the blocking human render gate) were NOT executed this session."
  - "Live hardware verification (hyprctl dispatch summoning the real layer surface, quickshell.log inspection, wpctl volume-sync proof, screenshots) was NOT performed from this worktree — see 'Verification Not Performed' below for why, and what the human/orchestrator must run after merge."

patterns-established:
  - "Panel body files (AudioPanel.qml) extend PanelDialog directly (root type PanelDialog) rather than receiving its constants as passed-in properties — matches PanelDialog's own header note that a panel body reads spacing/type constants off itself the same way MediaTab.qml reads them off dashboardWindow, but via direct type inheritance since AudioPanel IS a PanelDialog instance."

requirements-completed: []

coverage:
  - id: D1
    description: "PanelDialog.qml, AudioBackend.qml, AudioPanel.qml created and registered in modules/dashboard/qmldir in the same commit; shell.qml's openPanel()/closeAllPanels() guarded summon path added; Super+A wired through shortcuts.json + keybinds.lua"
    verification:
      - kind: other
        ref: "static grep-based acceptance criteria from 15-02-PLAN.md Task 1 <acceptance_criteria> — all passed (see below)"
        status: pass
      - kind: other
        ref: "qmllint (Qt 6, /usr/bin/qmllint) against PanelDialog.qml, AudioBackend.qml, AudioPanel.qml"
        status: pass
      - kind: e2e
        ref: "15-02-PLAN.md Task 1 <verify> automated block (hyprctl dispatch 'hl.dsp.global(\"quickshell:audio-panel\")' against a live-restarted quickshell process, hyprctl layers -j namespace assertion, quickshell.log inspection)"
        status: unknown
    human_judgment: true
    rationale: "The live <verify> block requires restarting the user's real quickshell process and dispatching a real Hyprland global-shortcut event. This worktree's live-session stow path (~/.config/quickshell) resolves to the main dotfiles checkout, not this worktree branch, so restarting it would test stale code while disrupting the user's live desktop for no benefit. Deferred to the orchestrator/human after this branch is merged — see 'Verification Not Performed' below for the exact commands to run."

duration: 12min
completed: 2026-08-01
status: in-progress
---

# Phase 15 Plan 02: Audio Panel Tracer (Task 1 only) Summary

**Super+A now summons a real audio-mixer layer surface wired end to end to the live PipeWire default sink through a new shared PanelDialog frame and a single guarded openPanel() path — Tasks 2-4 of this plan (Advanced-disabled UI, gate re-runs, blocking human render gate) remain and were deliberately not run this session.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-01T21:15:35Z
- **Completed:** 2026-08-01T21:27:34Z
- **Tasks:** 1 of 4 (Task 1 — the plan's `type="tracer"` task)
- **Files modified:** 7 (3 created, 4 modified)

## Why only Task 1 ran

15-02-PLAN.md's Task 1 is tagged `type="tracer"`. Per this executor's standing
tracer-feedback-gate rule (`gsd-executor.md` `<execution_flow>`): a tracer task
is committed exactly like a normal task, and then — because this session is
interactive (auto mode is not active; `workflow.auto_advance` is `false` in
`.planning/config.json`) — the executor must STOP immediately after committing
the tracer and return a `checkpoint:human-verify` for the tracer's own
`<verify>` block, **before any expansion task**. Tasks 2-4 are expansion work
(D-15-22 disabled-Advanced rendering, the four-state vocabulary, the
`windowrules.lua` slide rule, the gate re-runs, and the plan's own blocking
human render gate) and were not started.

This is a genuine, deliberate stopping point, not an error or an omission.

## Accomplishments (Task 1)

- `PanelDialog.qml` — the shared standalone-panel frame every panel this
  phase and Phase 16 add is constructed FROM (PANEL-06): layer posture
  parameterized from `Dashboard.qml`'s proven `PanelWindow`/`WlrLayershell`/
  `HyprlandFocusGrab` skeleton, a header band (glyph, title, labeled
  Advanced button, no close button), fixed 850x620 geometry (D-15-07 — no
  content-derived sizing), a scrollable `Flickable`+`Column` body slot
  aliased as the type's `default property`, and a D-15-08 entrance cascade
  reusing D-21's existing stagger token.
- `AudioBackend.qml` — the PipeWire adapter: `Pipewire.defaultAudioSink`/
  `defaultAudioSource` reads, `PwObjectTracker`-fed live `audio.volume`/
  `audio.muted` state (mandatory per 15-API-PROBE.md's A6 finding — a node's
  audio interface is inert until tracked), `UntypedObjectModel.values`
  accessor and exact-equality `PwNodeType` filtering (A3's corrective
  finding on composite flag bits), the A1 display-name fallback chain
  (`application.name` -> `application.process.binary` -> `node.name`), and
  a fail-open `pavucontrol` availability probe for D-15-22.
- `AudioPanel.qml` — master volume slider + mute toggle, the ONLY body
  content this plan renders (device pickers and the per-app mixer list are
  deliberately absent — 15-04's job). Advanced launches `pavucontrol` via
  `startDetached()` (T-15-02's fixed-argv discipline).
- `shell.qml` — `audioPanelLoader`/`audioBackendInstance` siblings of the
  dashboard's own loaders/backends, and the single guarded
  `openPanel(name)`/`closeAllPanels()` summon path: **the DASH-08
  fullscreen-refusal guard now lives in exactly one place**, correcting
  15-PATTERNS.md's own wrong inline snippet (which said panels skip the
  guard entirely — REQUIREMENTS DASH-08 and ROADMAP Phase 14 criterion 5
  both say panels are covered too). `audioPanelShortcut.onPressed` calls
  `root.openPanel("audio")` and never touches `audioPanelLoader.active`
  directly.
- `shortcuts.json` / `keybinds.lua` — the fourth `GlobalShortcut` manifest
  entry and the `SUPER + A` bind, `A` verified free among the host's 67
  pre-existing `mainMod` binds.

## Decision Records Landed (verbatim, per plan's `<decision_records>`)

**D-15-04 — the keybind asymmetry** — landed as the comment block above
`audioPanelShortcut` in `shell.qml` (verified: `grep -c 'D-15-04'` = 1):

> Super+A is the only panel keybind: of the three panels only the audio
> mixer displaces a daily-opened application (pavucontrol), the free
> plain-Super single letters on this host are A, G, H, J, K, M, O and U —
> W, B and V are all taken among 67 mainMod binds — so D-09's first-letter
> mnemonic convention can be honoured for exactly one of the three, and
> minting Super+Shift+W/Super+Shift+B for the other two would give three
> sibling panels built from one shared component visibly inconsistent
> chord shapes.

**D-15-07 — the D-05 scroll exemption is WIDER than Phase 14 predicted** —
landed verbatim in `PanelDialog.qml`'s header comment (verified: `grep -c
'D-15-07'` = 4, spanning the header block and inline reiterations):

> D-05 anticipated "Phase 15's per-app mixer list is the expected first
> legitimate exemption" — but the exemption recorded here is wider: all
> three panels scroll, because all three have unbounded content (audio
> streams / visible networks / paired plus discovered devices), unlike the
> drawer's four tabs, which D-05 audited as bounded. The exemption
> therefore covers PanelDialog's body slot for every instance, not just the
> audio one, and the fixed frame height that makes it necessary is
> D-15-07's own decisive argument: a wifi scan populates progressively, so
> a content-sized panel would grow under the cursor mid-scan, moving the
> blur region and the click-outside hit zone.

**`add-alongside` assumption-delta record** — landed verbatim in
`PanelDialog.qml`'s header (verified: `grep -c 'add-alongside'` = 1):

> The QML shell's surface identity is pluralizing: Dashboard.qml was the
> only summonable layer surface, and this phase adds three more. The
> generalized noun is summonable layer surface and PanelDialog is its
> promoted representation — but only for new surfaces. Dashboard.qml is
> deliberately not refolded onto PanelDialog this phase: it is Phase-14
> render-gate-passed with an open UAT item, the milestone's additive-only
> constraint forbids the churn, and D-15-02 already rejected drawer
> restructuring for exactly this reason. Accepted debt. What would force a
> later promote: any change that must land identically on all four
> surfaces — a shared dismissal-semantics change, a focus-grab model
> change, or a second surface wanting the drawer's tab chrome.

## Task Commits

1. **Task 1: End-to-end "summon the audio panel and change the volume" —
   one path only** — `5e6bf2d` (feat)

No plan-metadata commit yet — this SUMMARY's own commit is that record for
Task 1's partial state; the plan's final `docs(...)` completion commit
happens only once all four tasks land.

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` (288
  lines) — the shared panel frame
- `quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml` (158
  lines) — PipeWire adapter
- `quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` (109
  lines) — master volume + mute body
- `quickshell/.config/quickshell/modules/dashboard/qmldir` — three new
  non-singleton type registrations, same commit as their creation
- `quickshell/.config/quickshell/shell.qml` — `audioPanelLoader`,
  `audioBackendInstance`, `openPanel()`, `closeAllPanels()`,
  `audioPanelShortcut`
- `quickshell/.config/quickshell/shortcuts.json` — `audio-panel` manifest
  entry
- `hypr/.config/hypr/config/keybinds.lua` — `SUPER + A` bind

## Decisions Made

- Followed the API-PROBE's measured accessor shape throughout (`.values`
  for JS iteration, `PwObjectTracker` mandatory, exact-equality
  `PwNodeType` matching) rather than 15-RESEARCH.md/15-PATTERNS.md's
  disproven `.count`/`.get(i)`/bitwise-AND snippets, per the upstream
  findings authority note in this session's own prompt.
- `AudioPanel.qml` extends `PanelDialog` directly (root type `PanelDialog`)
  rather than receiving spacing/type constants as passed-in properties —
  a direct-inheritance variant of the same "read constants off the window
  root" pattern `MediaTab.qml` uses via `dashboardWindow`, made possible
  because `AudioPanel` literally IS a `PanelDialog` instance.
- Deferred Task 1's own opacity/tooltip disabled-Advanced treatment,
  `advancedTopInset`, and the four-state `bodyState`/empty-placeholder to
  Task 2, since the plan's own text assigns those explicitly to Task 2's
  action spec ("D. D-15-22 present-but-disabled Advanced" and "B. Exercise
  the four-state vocabulary honestly") — Task 1's own action text for the
  header band does not mention them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Comment text collided with an acceptance-criteria grep
pattern**
- **Found during:** Task 1, pre-commit static verification
- **Issue:** `PanelDialog.qml`'s header comment above `launchAdvanced()`
  originally read `NOT a lifetime-bound \`running: true\`` — the literal
  substring `running: true` in a comment is indistinguishable, to
  `grep -Eq 'running:[[:space:]]*true'`, from an actual lifetime-bound
  Process assignment, which the plan's own acceptance criterion explicitly
  forbids anywhere in the file (`! grep -Eq 'running:[[:space:]]*true'
  PanelDialog.qml`).
- **Fix:** Reworded the comment to `NOT a lifetime-bound \`running\`
  assignment` — same meaning, no longer matches the pattern.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml`
- **Verification:** `grep -E 'running:[[:space:]]*true' PanelDialog.qml`
  now exits 1 (no match).
- **Committed in:** `5e6bf2d` (part of Task 1 commit — caught before commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — comment text accidentally
matched a forbidden-pattern grep)
**Impact on plan:** Cosmetic; no functional change. No scope creep.

## Verification Performed

All of Task 1's **static** acceptance criteria were run and passed from
this worktree:

- `qmldir` contains `PanelDialog 1.0 PanelDialog.qml`,
  `AudioPanel 1.0 AudioPanel.qml`, `AudioBackend 1.0 AudioBackend.qml` —
  each `grep -c` = 1.
- `keybinds.lua` contains `quickshell:audio-panel` — `grep -c` = 1.
- `shortcuts.json` contains `"audio-panel"` — `grep -c` = 1.
- `shell.qml` contains `function openPanel` — `grep -c` = 1.
- Prohibition P1 holds in source: `grep -E 'nmcli|bluetoothctl|wpctl|pactl'`
  over `AudioBackend.qml`/`AudioPanel.qml`/`PanelDialog.qml` returns no
  matches.
- D-15-24 holds by construction: `grep -c 'swayosd-client'` = 0 in both
  `AudioBackend.qml` and `AudioPanel.qml`.
- `grep -c 'startDetached'` in `PanelDialog.qml` = 3 (Advanced launch,
  header comment reference x2), and
  `! grep -Eq 'running:[[:space:]]*true' PanelDialog.qml` holds (exit 1).
- `PanelDialog.qml` declares every contract-surface member by exact name:
  `panelTitle`, `panelGlyph`, `namespaceSuffix`, `advancedLabel`,
  `advancedCommand`, `advancedAvailable`, `advancedUnavailableReason`,
  `panelWidth`, `panelHeight`, `panelStates`, `stateColour`,
  `requestDismiss`, `dismissRequested` — all 13 confirmed present.
- `grep -c 'D-15-04'` in `shell.qml` = 1; `grep -c 'D-15-07'` in
  `PanelDialog.qml` = 4; `grep -c 'add-alongside'` in `PanelDialog.qml` = 1.
- `quickshell/.config/quickshell/modules/Dashboard.qml` is byte-unchanged
  (`git diff --stat` for that path is empty).
- `qmllint` (Qt 6.11.1, `/usr/bin/qmllint`) run against `PanelDialog.qml`,
  `AudioBackend.qml`, and `AudioPanel.qml` individually: exit 0, no
  warnings, on all three. (`shell.qml` itself returns exit 255 with no
  diagnostic output under a standalone `qmllint` invocation — reproduced
  identically against the pre-existing, unmodified `shell.qml` from
  `HEAD~1` via a throwaway copy, confirming this is a pre-existing tool/
  environment limitation with this file's `ShellRoot` root type and
  relative-directory imports, not a defect introduced by this plan's
  edit — the throwaway copy was deleted before committing.)
- `keybinds.lua` syntax-checked clean via `luac5.4 -p` (parse-only, exit
  0). `shortcuts.json` validated as well-formed JSON via `python3 -m
  json.load`.
- `grep -c 'fullscreenBlocking'` in `shell.qml` = 4 (≥ 3 required), with
  one occurrence inside `openPanel()`'s own body (line 169: `if
  (root.fullscreenBlocking) return;`).

## Verification NOT Performed (and why)

The plan's Task 1 `<verify>` automated block and every live-hardware item
in its `<acceptance_criteria>` — restarting quickshell, dispatching
`hl.dsp.global("quickshell:audio-panel")`, asserting on `hyprctl layers -j`,
checking `~/.cache/quickshell.log`, and the `wpctl get-volume`/slider-sync
proof — were **not run** from this session, for a concrete, checked reason:

This execution runs as a parallel worktree-isolated agent
(`/home/aorus/dotfiles/.claude/worktrees/agent-a0723a28d8bbe378e`). The
live user session's `~/.config/quickshell` (the path
`hypr/.config/hypr/scripts/quickshell-launch.sh` always launches from) is
stowed from `/home/aorus/dotfiles` (the **main** checkout), not from this
worktree branch. Restarting the live `quickshell` process from here would
(a) load the main checkout's `shell.qml`, not this worktree's new
`openPanel()`/`audioPanelLoader` — so the test would prove nothing about
this plan's code — and (b) kill and relaunch the user's actual, currently
running desktop shell for no verification benefit. `hyprctl` itself was
confirmed live and reachable from this sandbox (`hyprctl monitors -j`
returned this host's real `DP-1` monitor), so the live compositor IS
reachable — the blocker is specifically that the live *quickshell* process
does not read from this worktree's files.

**What must happen next, once this worktree's branch is merged into the
main checkout:**

```
cd ~/dotfiles
~/.config/hypr/scripts/motion-lint          # not yet re-run (Task 3's job)
~/.config/hypr/scripts/keybind-doctor       # not yet re-run (Task 3's job)
setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh   # detached restart, 14-06's standing rule
hyprctl dispatch 'hl.dsp.global("quickshell:audio-panel")'
hyprctl layers -j | jq '[.[].levels["3"][]? | select(.namespace=="quickshell-audio-panel")] | length'   # expect 1
hyprctl dispatch 'hl.dsp.global("quickshell:audio-panel")'
hyprctl layers -j | jq '[.[].levels["3"][]? | select(.namespace=="quickshell-audio-panel")] | length'   # expect 0
tail -50 ~/.cache/quickshell.log            # expect no QML .*Error / TypeError / "is not a function"
```

Then, with the panel summoned, compare `wpctl get-volume @DEFAULT_AUDIO_SINK@`
against the rendered slider position, run `wpctl set-volume
@DEFAULT_AUDIO_SINK@ 30%` from a terminal, and confirm the summoned panel's
slider moves without any panel interaction (the D-22 truth-driven proof
Task 1's own acceptance criteria requires) — then restore the original
volume.

## Issues Encountered

None beyond the one auto-fixed comment-text collision documented above.

## Next Steps / Plan Continuation

This plan (`15-02`) is **not complete**. Remaining, in order:

1. **Live verification of Task 1's tracer** (the commands above), by the
   orchestrator or a human with access to the merged main checkout —
   this IS the tracer-feedback gate this session's executor rules require
   before any expansion task may start.
2. **Task 2** — D-15-22 present-but-disabled Advanced rendering, the
   four-state vocabulary's empty-state placeholder, the D-15-06 adjacency
   inset, and the `windowrules.lua` per-namespace slide animation rule.
3. **Task 3** — re-run `motion-lint`, `keybind-doctor`, and
   `quickshell-doctor`'s namespace-discipline check; confirm the three
   decision records are present in source (already true, verified above)
   and reproduce them in this SUMMARY (already done above).
4. **Task 4** — the plan's own blocking `checkpoint:human-verify` render
   gate (nine checks, three of them judgment calls that must be answered
   explicitly per the plan's own resume-signal).

No requirement (`PANEL-02`, `PANEL-05`, `PANEL-06`) is marked complete in
this SUMMARY's frontmatter — none of the three is fully proven yet given
Tasks 2-4 remain and the live tracer verification is still pending.

---
*Phase: 15-audio-connectivity-panels*
*Plan: 02 (Task 1 of 4 complete; tracer-feedback gate reached)*
