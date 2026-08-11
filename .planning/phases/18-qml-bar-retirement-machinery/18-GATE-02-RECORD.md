# 18-GATE-02-RECORD.md — GATE-02's blocking final pass

## What This Record Is

This is GATE-02's blocking final pass under D-18-31 — the last decision point before 18-20's
irreversible deletion commit. D-18-31 schedules two things, never one substituting for the other:
checkpoints during the phase (already discharged inside 18-09, 18-11, 18-12 and the other build
plans as their own `<human-check>` blocks) and this one blocking final pass, run once against the
shipped build, immediately before the deletion commit. A checkpoint verdict recorded in an earlier
wave is evidence a criterion was once true on a partial build; it is never a substitute for
observing it here, on the build actually being retired against.

D-18-32 splits the comparison baseline in two rather than asking one look to do both jobs: Block A
below is an aesthetic judgment calibrated against `athena`, the retired bar's own visual reference;
Block B is a named-capability audit against `config-full`, `config-floating` and `config-vertical`,
walked off `18-BEHAVIOUR-BASELINE.md`'s `## GATE-02 Criterion B Index`. The two stay as two blocks
with two separate baseline columns throughout this record — a row never straddles both.

UI-SPEC's own pass bar, stated verbatim in its "GATE-02 Render-Gate Criteria" section, governs
every verdict recorded here: "A criterion is only 'passed' when confirmed live (clicked, scrolled,
toggled, actually theme-switched) — 'looks right in the source' never counts." Reading the plan,
reading the QML source, or recalling a checkpoint from an earlier wave are all forms of writing
down an answer nobody looked for, and none of them may produce a verdict in this record.

## Verdict Vocabulary

Every verdict cell in this record draws from exactly one of these four tokens and holds nothing
else — never a sentence, a qualifier, a tick or a hedge:

- **`PASS`** — the gesture was performed on the running bar and the criterion was met.
- **`FAIL`** — the gesture was performed and the criterion was not met. Blocks the deletion commit
  until fixed and re-checked as a new iteration.
- **`NOT-DEMONSTRABLE`** — the criterion has no observable subject on this hardware. Authorised on
  exactly one row, B.3's brightness half, by D-18-39; its appearance on any other row is itself a
  gate failure.
- **`OVERRIDDEN`** — close-only, written by the developer against a matching line in
  `## Developer Overrides` that names the reason and the filed follow-up. An override is visible in
  the table rather than hidden behind a pass.

Until task 2 of `18-19-PLAN.md` runs, every verdict and observation cell in this record reads the
literal placeholder `AWAITING-OBSERVATION` — the one exception is `B.4-DRAWER`, whose branch is
resolved by machine below, before any human sits down.

## Build Under Test — Iteration 1

Every field below was captured by running a command against the live host on 2026-08-12, not
recalled or inferred.

- **HEAD sha:** `911d8a57c66b6be8c6f1b1d19bddeb4462f06326` (`git rev-parse HEAD`).
- **Working tree:** `git status --porcelain -- quickshell/ hypr/` returned empty — clean.
- **Reserved array (`hyprctl monitors -j | jq '.[0].reserved'`):** `[0, 48, 0, 0]`.
  **Live-value correction, recorded rather than forced to match the stale plan text:** D-18-38 and
  this phase's own `18-19-PLAN.md` name 46px as the expected top-edge reservation
  (`Design.barHeight` (40) + `Design.barEdgeMargin` (6)). The live value on this host is **48px**,
  because Phase 18.1 (QML Bar Athena Restoration, inserted after Phase 18) raised
  `Design.barHeight` from 40 to 42 to match upstream Athena's own bar height — confirmed directly
  against the shipped tokens: `quickshell/.config/quickshell/modules/dashboard/Design.qml` lines
  138-139 read `barHeight: 42` and `barEdgeMargin: 6`, and 42+6 = 48, matching the live
  `hyprctl` readback exactly. `18-18-SUMMARY.md`'s own key-decisions record the same correction
  ("The reserved array is `[[0,48,0,0]]`, not the `[[0,46,0,0]]` recorded throughout phase 18").
  This mismatch against the plan's stale 46px reference is **not treated as a gate failure** — the
  live host wins, and this is that value recorded with its reason, per the operating instruction
  for this pass. The single-bar-owns-the-zone signal this fingerprint field exists to carry (one
  axis reserving, one bar claiming it) holds regardless of which of the two numbers is correct.
- **Quickshell pid (`pgrep -x quickshell`):** `1626`.
- **Quickshell start time (`ps -o lstart= -p 1626`):** `Wed Aug 12 01:09:38 2026`.
- **`quickshell-bar` namespace (`hyprctl layers -j`):** present (alongside `awww-daemon`, which is
  an unrelated wallpaper daemon layer and not a second bar).
- **`pgrep -x waybar`:** returned nothing (exit 1) — no waybar process running. It was already
  stopped when this fingerprint was captured; no action was taken to stop it (D-18-32's own
  reasoning — a relaunch would claim a second exclusive zone and corrupt this fingerprint — means
  the correct move on finding it running would be to stop it and record that, but that branch did
  not apply here). It autostarts on next boot via
  `hypr/.config/hypr/config/autostart.lua:62` → `waybar-launch.sh`; it is not disabled, only not
  currently running, and it is not relaunched for this pass.
- **Newest `modules/bar/*.qml` mtime vs. process start:** `find quickshell/.config/quickshell/modules/bar -name '*.qml' -newer /proc/1626` returned nothing — no bar QML file is newer than the
  running process. **No restart was needed or performed.**
- **QBAR-11 soak window:** a live soak measurement window is running against this same quickshell
  process (`18-BAR-SOAK.md`, WINDOWS row 64), anchored to this same start time. This fingerprint
  capture and the rest of this task are entirely read-only against the running process — no
  restart, reload, or `hyprctl eval`/`hyprctl reload` was issued at any point, so the soak window
  is undisturbed.

## Setup, Before Either Half

The exact ordered steps a human follows once before observing any of the fifteen rows below:

1. Confirm the fingerprint block above matches the machine right now — re-run the reserved-array
   and pid checks (`hyprctl monitors -j | jq '.[0].reserved'`, `pgrep -x quickshell`) and confirm
   they still agree with what is recorded (`[0, 48, 0, 0]`, pid `1626`).
2. Open `18-BEHAVIOUR-BASELINE.md` and this record side by side on a second workspace. These two
   documents are the comparison partner for this whole pass. **Do not relaunch waybar**: at this
   wave it has no visibility owner (18-15 renamed `waybar-visibility.sh` to `bar-visibility.sh` and
   repointed all six intent callers), a relaunch would claim a second exclusive zone and change the
   reserved array this record's fingerprint asserts, and D-18-32 independently rules out the
   side-by-side screenshot shape as inviting a port-not-redesign reading.
3. Put the bar in horizontal orientation and leave it there for Block A and for B.1 through B.3.
4. Have a browser and a terminal open on two different workspaces, at least one tray application
   running, and a media player with a deliberately long track title queued — three of the fifteen
   rows have no observable subject without them.
5. Note the current volume, the current theme and the current workspace, so state can be restored
   at the end of the sitting.
6. Do not restart, stop, or reload `quickshell.service`, and do not run `hyprctl reload` or
   `hyprctl eval` — a QBAR-11 soak window is running against the live process captured in the
   fingerprint above, and any of those actions would void it.

## Block A — Aesthetic judgment against athena (D-18-32, first half)

| ID | Criterion (verbatim) | Baseline | Gesture | Verdict | Observation |
|---|---|---|---|---|---|
| A.1 | Every capsule is a fully rounded, discrete pill with a visible gap to its neighbors — never one continuous bar (matches D-18-09, contradicts athena's own `"spacing": 0`, which this redesign deliberately supersedes). | athena | Look at the horizontal bar, count the capsules, and confirm each has a visibly rounded left and right end with a visible background gap to its neighbour. The failure this catches is a run of capsules reading as one continuous bar, which is what athena's own `"spacing": 0` produced and what D-18-09 deliberately supersedes. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| A.2 | The bar floats clear of the screen edge with a visible margin on every visible side — never edge-flush. | athena | With a maximised window behind it, confirm a strip of desktop is visible above the bar and beyond both of its ends. The floating posture is D-18-08's; the two outer offsets are UI-SPEC's only two grid exemptions and exist to land the bar where the retired one sat. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| A.3 | Workspace indicators show live per-app window icons in the `{icon} {windows}` shape — never dots, pills, or bare numbers. | athena | Open a terminal on one workspace and a browser on another, then confirm each occupied slot renders that application's glyph and each empty slot renders a numeral only (D-18-02, D-18-12). Name the specific failure mode: a Material Symbols ligature that does not exist renders as its own name in plain text, so a slot showing a word instead of a glyph is a fail, not a styling nit. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| A.4 | Switching the live theme re-colors every bar element (capsule fills, active-state tints, the `GradientBorder` rim) within one crossfade, with zero literal-hex flash anywhere. | athena | Switch the live theme and watch the bar through the transition, confirming capsule fills, the active-workspace tint and the `GradientBorder` rim all re-colour within one crossfade. Name the specific artefact: `Colours.qml`'s nineteen fallback defaults are magenta, so a magenta flash means a palette read failed rather than that an animation was slow. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| A.5 | The bar reads as *denser* than end-4/Caelestia, not simplified toward them: both drawers (launcher + settings), the always-visible tray, and all four extras (power, gaming toggle, bell, updates+idle) are visibly present, not folded away or deferred — this is the explicit check against the standing instruction not to simplify toward the reference shells. | athena | Without clicking anything, confirm all of these are simultaneously visible: the launcher drawer trigger, the settings drawer trigger, the tray icon row, and the four extras — power, gaming-mode toggle, notification bell, and the updates count with the idle inhibitor (D-18-01, D-18-03, D-18-04). At zero pending updates the updates item rendering nothing is the specified empty state, not a miss. This row is the explicit check against simplifying toward end-4/Caelestia. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |

## Block B — Capability audit against config-full / config-floating / config-vertical (D-18-32, second half)

This block is walked off `18-BEHAVIOUR-BASELINE.md`'s `## GATE-02 Criterion B Index` rather than
from memory. Its two named corrections apply here: B.1's "bluetooth" clause is sourced from
athena, not from the three-layout capability audit, and floating's `hyprland/workspaces`
scroll-up/down is a live capability B.3 as written does not cover and no plan currently owns.

| ID | Criterion (verbatim) | Baseline | Gesture | Verdict | Observation |
|---|---|---|---|---|---|
| B.1 | Every readout the three retired layouts collectively exposed (clock, battery when present, network, bluetooth, audio, cpu/ram/disk) is present and live on the new bar. | `config-full`, `config-floating`, `config-vertical` (bluetooth sourced from athena, per the Criterion B Index correction) | Walk the criterion IDs the index maps to B.1 and, for each, find its readout on the bar and confirm the value is live rather than static: put the CPU under load and watch the number move, toggle wifi off and on and watch the glyph change, play audio and watch the volume value follow. The battery entry rendering nothing on this batteryless desktop is D-18-06 satisfied and is recorded as such, not as a missing readout. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| B.2 | Clicking a workspace switches to it (the capability dead under waybar 0.15.0's compiled-in dispatch — QBAR-03's whole reason for existing). | `config-full`, `config-floating`, `config-vertical` (via the shared `hyprland/workspaces` dead dispatch) | Click a non-active occupied workspace slot, then click an **empty** slot, confirming both switch (check `hyprctl activeworkspace -j`). The empty slot is the specific trap 18-09 names: an empty workspace has no Hyprland object at all, and the object-only dispatch path can silently do nothing without anyone noticing if the gate only exercises occupied tiles. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| B.3 | Scrolling on the audio section adjusts volume; scrolling on the brightness-bearing section adjusts brightness (parity with `config-floating`'s scroll bindings). | `config-floating` (audio scroll-step; brightness, D-18-39) | Two halves recorded in one cell. **Audio (live gesture):** scroll up and down over the audio entry and confirm `wpctl get-volume @DEFAULT_AUDIO_SINK@` moves with it — three wheel-up notches should raise the value by 15 percentage points, bound holding at both ends. **Brightness (transcribed, not judged — D-18-39):** copied verbatim from `18-SCROLL-GATE-RECORD.md` § "Section 1": verdict **"not demonstrable on this hardware — structurally present"**. Evidence: `/sys/class/backlight/` is empty (desktop board, no panel); `brightnessctl -m -l -c backlight` prints nothing and exits non-zero; `light`, which `config-floating.jsonc`'s own `"on-scroll-up": "light -A 5"` / `"on-scroll-down": "light -U 5"` shelled out to, is not installed — the capability being compared against was already dead in the baseline, per `18-BEHAVIOUR-BASELINE.md`'s own `## Dead Definitions` (`floating` / `backlight` row). This half is a transcription; forming a fresh judgment about it here is exactly what 18-12 wrote the sentence down in advance to prevent. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| B.4 | The horizontal↔vertical toggle (settings drawer + Super-menu, D-18-30) reaches the vertical orientation and every readout present in horizontal is still present, in the 44px stacked-text form, with no truncation. | `config-vertical` | Flip to vertical from the settings drawer, then flip back and flip again from the Super-key menu's settings entry, confirming both reach paths work (D-18-30). In vertical, walk every readout counted in B.1 and confirm each is present in the 44px column in its stacked or abbreviated form with nothing clipped — the clock as two stacked lines, other readouts as glyph plus short value (D-18-14). The acceptance bar is no truncation, not an identical stacking shape everywhere. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| B.5 | Tray icons render and their menus open on click, in both orientations. | `config-full`, `config-vertical`, `config-floating` | In horizontal, confirm the tray capsule holds one cell per running tray application and that clicking one opens its menu anchored below; flip to vertical and repeat, confirming the menu anchors leftward (D-18-04). If the tray is empty, start a tray application first — the empty-tray collapse is a different, already-owned state and is not what this row tests. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| B.6 | Nothing deliberately cut during athena's own 08-16 evolution (e.g. the old tray-folded settings sub-menu) is expected back — only a genuine `full`/`floating`/`vertical`-exclusive capability counts as a regression if missing. | `config-full`, `config-floating`, `config-vertical` (exclusion list: `18-BEHAVIOUR-BASELINE.md` § `## Dead Definitions`) | Walk `18-BEHAVIOUR-BASELINE.md`'s `## Dead Definitions` table first and confirm nothing listed there (athena's `tray`, floating's `backlight`) is being counted as missing, then walk the remaining criterion IDs the index maps to B.6 and confirm each is either present on the bar or accounted for in that exclusion list. Only a genuine `full`/`floating`/`vertical`-exclusive capability counts as a regression. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |

## Named Sub-Judgments

Three findings earlier plans routed here, each arriving pre-recorded with its evidence and its
remedy so the human decides rather than investigates under blocking-gate pressure.

| ID | Criterion (verbatim) | Baseline | Gesture | Verdict | Observation |
|---|---|---|---|---|---|
| B.4-DRAWER | D-18-11: vertical-orientation drawers expand inward, horizontally — "a floating strip growing leftward over the desktop." | live repo state vs. `D-18-11` | **Branch resolved by machine, before any human sits down.** Command run: `test -f quickshell/.config/quickshell/modules/bar/BarDrawer.qml` (18-11's recommended Option B) — file **does not exist**. Second command: `grep -n "Math.max" quickshell/.config/quickshell/modules/Bar.qml` and a search for any maximum-against-a-published-`expandedCrossExtent` expression in `Bar.qml` (18-11's Option A) — **no such expression exists**; `Bar.qml`'s vertical `implicitWidth` is pinned to `Design.barColumnWidth` alone (line 94: `implicitWidth: barWindow.vertical ? Design.barColumnWidth : 0`). Neither of 18-11's two scope-correction options was taken. Per 18-11's own closing instruction ("If neither is taken before 18-19 ... 18-19's blocking pass must record that explicitly rather than waving it through. Do not let that become the silent default."), this row is pre-filled as a failure rather than left pending. | FAIL | D-18-11 is not met: with neither Option A (widen `Bar.qml`'s vertical window) nor Option B (a new `modules/bar/BarDrawer.qml`) taken, the vertical drawers (`LauncherCapsule`, `ClockActionsCapsule`) can only expand within `Bar.qml`'s fixed `Design.barColumnWidth` (44px) vertical window — i.e. along the column, not leftward over the desktop as D-18-11 requires. Both capsules already publish `expandedCrossExtent` (confirmed live: `grep -l expandedCrossExtent` matches `ClockActionsCapsule.qml` and `LauncherCapsule.qml`), so the contract a fix would consume already exists; only the host that can render it is missing. **Remedy, named by 18-11:** Option B (recommended) — register `modules/bar/BarDrawer.qml` as a `LazyLoader`-gated anchored strip surface, one new `qmldir` line, no change to `Bar.qml`, no change to the reservation. This is a live-verified structural fact, not a rendered observation — no live look at the vertical drawer's actual on-screen behaviour was performed as part of resolving this branch, and the human pass should still glance at it in vertical orientation to confirm this matches what is visually shown, per the plan's own instruction to "look anyway and write down what you saw." |
| B.6-WS | Scroll-to-switch-workspaces: not implemented on the new bar (a deliberate cut, routed here by 18-09/18-12). | `config-floating` (`hyprland/workspaces` scroll-up/down → `hl.dsp.focus`) | Hover the workspace capsule and scroll **without** holding Super, confirming nothing happens; then hold Super and scroll anywhere, confirming the workspace changes. **Evidence, transcribed from `18-SCROLL-GATE-RECORD.md` § "Section 2":** `keybinds.lua` already binds Super plus mouse wheel globally to the identical dispatch expressions — verbatim: `hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))` and `hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))` — so the only thing lost by retiring `config-floating` is scroll-over-the-bar **without** holding Super. Live-checked: `WorkspaceCapsule.qml` currently contains no `WheelHandler` (`grep -c WheelHandler` returns 0), confirming the cut is real and not implemented. **Judgment for the human:** is losing scroll-over-the-bar-without-Super a loss? **Remedy if it is** (pre-specified by 18-12, mechanical, not a fresh design): a `WheelHandler` on `WorkspaceCapsule.qml`'s root entry item, same shape as the two `WheelHandler`s already built in `MediaConnectivityCapsule.qml` (`target: null`, `angleDelta.y` accumulated into signed 120-unit notches), dispatching the same `hl.dsp.focus({workspace: "e+1"})` / `"e-1"` expression forms via the capsule's existing click-dispatch call surface. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |
| B.6-WSCOUNT | The persistent workspace slot count: three of the four retired layouts persist five slots, `config-floating.jsonc` alone persists six — a named delta routed here by 18-09. | `config-floating` (six persistent slots) vs. the other three retired layouts (five) | Count the always-present workspace slots on the bar with no windows open beyond them. **Evidence, live-checked and corrected against the routing plans:** `18-09-PLAN.md` and `18-SCROLL-GATE-RECORD.md` both state `persistentSlotCount` ships at **5**. The **live value on this host is 6** (`grep -n persistentSlotCount quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml` → `readonly property int persistentSlotCount: 6`) — `git log` shows Phase 18.1 (the Athena restoration, inserted after 18-09 shipped) moved this value across several commits after 18-09/18-12 were written (`444d6dd` "grow the workspace capsule dynamically above a persistent floor of five", `d0c4404` "show all nine workspaces plus the reserved AI slot", `6a33caa` "cap the workspace floor at seven", `c5b6ada` "make the reserved AI workspace persistent again"), landing at 6 — matching `config-floating.jsonc`'s own six, not the 5-vs-6 delta the routing plans describe. **This is a live-value correction, recorded rather than silently inherited**: the 5-vs-6 delta the routing plans named may already be closed by the current build. **Judgment for the human:** confirm the live count matches 6 by looking at the bar, and judge whether that count (now matching `config-floating`) is acceptable, or whether some other count-related defect remains. **Remedy if a gap remains:** one integer in `WorkspaceCapsule.qml`'s `persistentSlotCount` constant. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |

## Lifted UI-SPEC Rows Judged Here

`18-UI-SPEC.md`'s `## UI Considerations` E7 long-text row, the one row of the fifty-six with no
owning plan across 18-01 and 18-05 through 18-16 — 18-17's structural checks and 18-18's soak
render nothing, so this blocking pass is its last chance.

| ID | Criterion (verbatim) | Baseline | Gesture | Verdict | Observation |
|---|---|---|---|---|---|
| UI-E7-LT | UI-SPEC § "UI Considerations", E7 long-text: "No unbounded bar text except the media title, capped and elided." UI-SPEC § "Section Capsule Internals": the media track title is capped at `mediaTitleMaxChars` (30) with `Text.ElideRight`, the one named exception to the "no truncation for bounded values" rule; "No *other* bar element may cite this exception — network deliberately renders `{icon}` only (SSID in the popout)." | none (a structural check against the bar's own text-rendering contract, not a layout comparison) | With a deliberately long-titled track playing, confirm the media title elides at `Design.mediaTitleMaxChars` and that the bar's capsule extent does not grow as the title changes. Then scan the whole bar in both orientations for any second free-form string — an SSID rendered inline, a window title, a tray tooltip drawn into the bar. There must be none: the network entry renders its glyph only, with the SSID in its popout. | AWAITING-OBSERVATION | AWAITING-OBSERVATION |

## Iteration 1 — Verdicts

_Pending — task 2 of `18-19-PLAN.md` has not yet run this pass. This section is written by task 2
after the fifteen gestures above are performed live: who ran the pass, the date and time, the
elapsed sitting, anything observed that did not fit a table cell, and — if any row fails — the
list of failing row IDs with the file that owns each remedy._

## Developer Overrides

A `FAIL` becomes non-blocking only through this section, and only the developer writes an entry
here — never the executor, and never inferred from an unanswered question. Each override is one
line naming the row ID, the reason it is accepted, and where the follow-up is filed. An
overridden row's verdict cell is then changed to `OVERRIDDEN` so the acceptance stays visible in
the table rather than disappearing behind a pass.

_(no entries yet)_

## Deletion Authorisation

RETIRE-02 BLOCKED — gate not yet run

18-20 reads this section as its own precondition before it deletes `config-athena.jsonc`,
`config-full.jsonc`, `config-floating.jsonc`, `config-vertical.jsonc`, `modules.jsonc`,
`bar-common.jsonc` and `waybar-equivalence-check`. It additionally re-asserts that nothing under
`quickshell/.config/quickshell/` changed since the authorising sha, so a fix landing after the
gate invalidates the authorisation by construction rather than by anyone remembering to re-run it.
This line is rewritten only by task 3 of `18-19-PLAN.md`, after all fifteen rows above carry a
verdict from the closed vocabulary.
