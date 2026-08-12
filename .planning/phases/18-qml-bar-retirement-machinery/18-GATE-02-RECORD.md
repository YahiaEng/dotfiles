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

- **HEAD sha:** `8c5d2804da17a2966e12c729edbc3236a77c741c` (`git rev-parse HEAD`), re-read 2026-08-12 04:11 for iteration 1. Supersedes the sheet-assembly sha `911d8a57c66b6be8c6f1b1d19bddeb4462f06326`; see the re-bind note below.
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
- **Quickshell pid (`pgrep -x quickshell`):** `528309`.
- **Quickshell start time (`ps -o lstart= -p 528309`):** `Wed Aug 12 02:40:25 2026`.
- **`quickshell-bar` namespace (`hyprctl layers -j`):** present (alongside `awww-daemon`, which is
  an unrelated wallpaper daemon layer and not a second bar).
- **`pgrep -x waybar`:** returned nothing (exit 1) — no waybar process running. It was already
  stopped when this fingerprint was captured; no action was taken to stop it (D-18-32's own
  reasoning — a relaunch would claim a second exclusive zone and corrupt this fingerprint — means
  the correct move on finding it running would be to stop it and record that, but that branch did
  not apply here). It autostarts on next boot via
  `hypr/.config/hypr/config/autostart.lua:62` → `waybar-launch.sh`; it is not disabled, only not
  currently running, and it is not relaunched for this pass.
- **Newest `modules/bar/*.qml` mtime vs. process start:** THREE files are newer than the process
  start — `BarDrawer.qml` (03:59:38), `LauncherCapsule.qml` (04:02:42) and
  `ClockActionsCapsule.qml` (04:05:14). **This is not a stale-build signal and the mtime proxy is
  the wrong test here:** quickshell hot-reloads on file change, so a file newer than the process
  can still be fully loaded by it. The correct check is the log, and it is unambiguous — the last
  successful `Configuration Loaded` is at **04:05:47**, later than the last edit at 04:05:14, so
  the running process carries all three files. **No restart was needed or performed**, which is
  also what kept the QBAR-11 soak window alive.
- **Re-bound for iteration 1 (2026-08-12 04:11).** The fingerprint originally captured for this
  record (HEAD `911d8a5`, pid `1626`, start 01:09:38) is superseded: the host rebooted, the bar's
  hover-to-popout defect was fixed (`b3e5e5a`), and `BarDrawer.qml` landed (`8c5d280`, quick task
  260812-59l) — the last of which exists specifically to remedy row `B.4-DRAWER`. Judging against
  the old fingerprint would have certified a build that no longer exists. The values in this block
  are the live ones, re-read immediately before the sitting.
- **QBAR-11 soak window:** a live soak measurement window is running against this same quickshell
  process (`18-BAR-SOAK.md` Section four-quater, WINDOWS row 66), anchored to this same start time. This fingerprint
  capture and the rest of this task are entirely read-only against the running process — no
  restart, reload, or `hyprctl eval`/`hyprctl reload` was issued at any point, so the soak window
  is undisturbed.

## Setup, Before Either Half

The exact ordered steps a human follows once before observing any of the fifteen rows below:

1. Confirm the fingerprint block above matches the machine right now — re-run the reserved-array
   and pid checks (`hyprctl monitors -j | jq '.[0].reserved'`, `pgrep -x quickshell`) and confirm
   they still agree with what is recorded (`[0, 48, 0, 0]`, pid `528309`).
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
| B.4-DRAWER | D-18-11: vertical-orientation drawers expand inward, horizontally — "a floating strip growing leftward over the desktop." | live repo state vs. `D-18-11` | **Branch re-resolved by machine for Iteration 2, 2026-08-12 ~17:35.** The `FAIL`/observation this cell previously carried was written by task 1 at HEAD `911d8a5` (before `git merge-base --is-ancestor` confirms `8766918`, task 1's own commit, is an ancestor of `8c5d280`) — genuinely correct at that instant, because `BarDrawer.qml` did not exist yet. It went stale three commits later in the same sitting: `fc01499`/`55208c4`/`10674fd`/`8c5d280` (quick task 260812-59l, "add BarDrawer.qml vertical drawer host (18-11 Option B)") landed **before** Iteration 1's fingerprint was even re-bound to `8c5d280` by follow-up `2327903` — so Iteration 1's own bound build already had the file, and this row's text was never updated to match. Re-run now against current HEAD `13de40f`: `test -f quickshell/.config/quickshell/modules/bar/BarDrawer.qml` → **file exists**. `grep -n BarDrawer quickshell/.config/quickshell/modules/bar/qmldir` → registered (`BarDrawer 1.0 BarDrawer.qml`). `grep -n LazyLoader quickshell/.config/quickshell/modules/bar/BarDrawer.qml` → present (multiple lines; file's own header names it "a LazyLoader-gated anchored strip surface"). `grep -rn "BarDrawer {" quickshell/.config/quickshell/modules/bar/{LauncherCapsule,ClockActionsCapsule}.qml` → both mount `BarDrawer { … }` behind their own `LazyLoader`. **18-11's Option B is taken, as of `8c5d280` and unchanged through `13de40f`.** Per task 1's own action text ("If either is true, write the row with the placeholder verdict and a gesture … in vertical orientation open the launcher drawer and confirm the strip grows leftward over the desktop rather than along the column"), this row reverts to the placeholder and the gesture below, superseding the stale pre-fill. | AWAITING-OBSERVATION | AWAITING-OBSERVATION — **gesture for the human, Iteration 2:** in vertical orientation, open the launcher drawer, then separately the clock/settings drawer (`ClockActionsCapsule.qml`), and confirm each strip grows leftward over the desktop rather than along the 44px column. Named explicitly because `8c5d280`'s own commit message states plainly that this behaviour "is claimed by construction and unproven by observation" — the authoring agent could not move the pointer on this host (Hyprland 0.56.2's Lua dispatch form rejects `movecursor`, `wtype` is keyboard-only) — so this row is that behaviour's first live look, not a re-confirmation of something already seen. If either strip instead grows along the column, that is a `FAIL` against D-18-11 exactly as task 1's original determination described, with the same Option-B remedy (already applied) now itself the thing found not to work and needing further investigation rather than a known one-file fix. |
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

---

## Iteration 1 — operator findings, 2026-08-12 04:15

Build under test: HEAD `8c5d280`, quickshell pid `528309`, reserved `[[0,48,0,0]]`, no waybar.

The operator began the sitting and reported four defects before completing all fifteen rows.
Per this record's own contract the gate **judges and does not fix** — each finding below is
recorded with its owning file and its remedy, the fix lands outside this record, and the next
iteration re-observes **all fifteen rows**, not only these four. The remaining rows are
**not** recorded as passing: they were not reached, which is different from passing, and they
carry no verdict yet.

| # | Operator's words | Owning file | Root cause | Status |
|---|---|---|---|---|
| F1 | "The time pill looks like it is positioned higher up than the rest of the pills" | `BarCapsule.qml` (and/or `ClockActionsCapsule.qml`) | LEAD, NOT PROVEN: `contentGrid` is `anchors.centerIn: parent`, but `Grid` defaults to `AlignTop` for its items and no `verticalItemAlignment` is set anywhere in the file. A child shorter than the tallest in the row would ride high. **To be measured live before any edit** — this file family has disproven four confident code-reading hypotheses (three in 18.1, one on 2026-08-12). | Open |
| F2 | "The popup text explaining what a glyph is, appears on top of the glyph obstructing the view" | six sites: `AudioPopout.qml:104`, `IdleInhibitorCapsule.qml:97`, `MediaConnectivityCapsule.qml:552`, `ClockActionsCapsule.qml:367`, `SectionPopout.qml:408`, `LauncherCapsule.qml:246` | CONFIRMED by source: not one tooltip sets a position. Every site sets only `ToolTip.visible`, `ToolTip.text` and `ToolTip.delay`, so Qt's default placement applies — and on a 42px top-edge bar there is no room above, so it lands on the glyph. This is one systemic defect, not six separate ones. | Open |
| F3 | "I am not sure if the 'light pulp' glyph does anything when clicked" | `IdleInhibitorCapsule.qml` | The click IS wired and functional — `onClicked` toggles `idleInhibited`, which drives a real `IdleInhibitor { enabled: idleInhibited }`. The defect is **feedback, not function**: the only signals are a colour tint and a `FILL` variable-axis change gated on `fillAxisAvailable`. If that axis is unavailable the entire feedback is a small glyph changing colour. Needs a live check of `fillAxisAvailable`. | Open |
| F4 | "The media popup ... buttons need to be centered and positioned correctly" | `MediaPopout.qml:168` | CONFIRMED by source: `transportRow` is the only child of the popout body carrying neither `width: parent.width` nor a centering anchor. `mediaRow` (:66), the progress bar (:145) and `multiPlayerText` (:263) all set `width: parent.width`. So the transport row alone lays out at x=0, left-aligned. | Open |

**Consequence for the gate.** `## Deletion Authorisation` stays `RETIRE-02 BLOCKED`. Four open
defects plus `B.4-DRAWER` unobserved plus eleven rows unreached is not a pass, and 18-20 must
not run.

**Note on F2 and F4 as a pair.** Both are absences rather than errors — a property nobody set,
not a value set wrongly. Neither would ever surface in a static check, and both were invisible
to every automated gate in this phase. That is the third time in this repo a purely visual
defect has survived a green automated pass, which is the precedent D-18-31 cites as the reason
this human gate exists at all.

---

## Build Under Test — Iteration 2

Every field below was captured by running a command against the live host on 2026-08-12
~17:33-17:37, not recalled or inferred, immediately before this iteration's sitting.

- **HEAD sha:** `13de40f81b11745b9cd37c241af28588abdfa63e` (`git rev-parse HEAD`).
- **Working tree:** `git status --porcelain -- quickshell/ hypr/` returned empty — clean.
- **Reserved array (`hyprctl monitors -j | jq '.[0].reserved'`):** `[0, 48, 0, 0]` — unchanged
  from Iteration 1; still the live 48px value (`Design.barHeight` 42 + `Design.barEdgeMargin` 6)
  recorded there with its D-18-38-vs-live-host reasoning, not the phase's stale 46px reference.
- **Quickshell pid (`pgrep -x quickshell`):** `1520318` — a different pid than Iteration 1's
  `528309`, confirming the process restarted (host reboot or an intervening bar-watchdog
  recovery — `quickshell-bar-watchdog.service` landed in this same commit range, see below) at
  some point since Iteration 1's sitting. This is expected and not itself a defect: Iteration 2
  binds to *this* pid, not the old one.
- **Quickshell start time (`ps -o lstart= -p 1520318`):** `Wed Aug 12 16:37:09 2026`.
- **`quickshell-bar` namespace (`hyprctl layers -j`):** present (alongside `awww-daemon`, the
  same unrelated wallpaper-daemon layer noted in Iteration 1).
- **`pgrep -x waybar`:** returned nothing (exit 1) — no waybar process running.
- **All six fingerprint values match the orchestrator's pre-dispatch expectation exactly**
  (HEAD, pid, reserved array, waybar-absent, layer namespace, clean tree) — no halt condition
  was met.

**Iteration 2 supersedes Iteration 1's binding sha `8c5d280` (`8c5d2804da17a2966e12c729edbc3236a77c741c`).**
Eighteen commits landed in between (`git log --oneline 8c5d280..HEAD`), most materially the four
Iteration-1 defect fixes plus one closely-related tooltip fix found while fixing them, in this
order (oldest first):

| Commit | Summary |
|---|---|
| `2327903` | docs(18-19): re-bind the GATE-02 fingerprint to the build actually under test |
| `da9a703` | docs(18-19): record four GATE-02 iteration-1 defects with owning files |
| `6721977` | **feat(quick-260812-69w): F2 escaping bar tooltips + F4 centred transport row** |
| `6285f5d` | **fix(quick-260812-69w): F1 clock pill vertical alignment + F3 idle bulb accent fill** |
| `d1c8702` | docs(quick-260812-69w): fix four GATE-02 iteration-1 bar defects |
| `da032fc` | docs(18-18): soak window elapsed but contaminated; record the bar-loss defect |
| `c78655e` | fix(bar): give hover drawers their own collapse grace, 600ms not 200ms |
| `33c768a` | docs: log the drawer-grace fix in STATE quick tasks |
| `e3f8266` | fix(bar): make the expanded bluetooth glyph's gaps uniform at 16px |
| `c40d1de` | fix(bar): stop tooltips double-counting the bar's own extent on both axes |
| `67333c5` | feat(bar): show an ethernet glyph left of wifi while a wired link is connected |
| `6f8d101` | docs: log the tooltip-placement and ethernet-glyph edits |
| `8853755` | feat(bar): move the ethernet glyph to the right of the wifi glyph |
| `8b9286a` | docs(quick-n9b): plan the event-driven bar watchdog for WINDOWS row 67 |
| `f425ac3` | feat(quick-260812-n9b): bar-watchdog listener, health check, recovery, proven on fixture |
| `b63cddb` | feat(quick-260812-n9b): quickshell-bar-watchdog.service, installed and verified live |
| `59ec9ae` | feat(quick-260812-n9b): wire bar-watchdog into autostart, D-18-28 reversal noted |
| `13de40f` | docs(quick-260812-n9b): bar watchdog — restore the bar after a monitor sleep |

`6721977` and `6285f5d` are the fixes for the four operator-reported defects (F1 clock pill
vertical alignment, F2 tooltips landing on top of the glyph, F3 idle-bulb feedback, F4 media
transport row not centered). `c40d1de` is a related tooltip fix found in the same area
afterward (double-counted bar extent on both axes) — not one of the original four, but touching
the same tooltip-placement surface F2 named, so Iteration 2's B.1/UI-E7-LT/tray-tooltip
observations should watch for any regression there too. The remaining commits (ethernet glyph,
drawer collapse grace, bluetooth glyph gap, bar-watchdog service) are unrelated feature/reliability
work from other quick tasks that also landed in this window; none of them is a remedy this gate
routed, but B.1's live-readout walk and B.5's tray gesture should note if the ethernet glyph or the
watchdog's presence changes anything a criterion checks.

**B.4-DRAWER machine resolution (see the corrected row above, in `## Named Sub-Judgments`).**
`BarDrawer.qml` exists at current HEAD, registered in `qmldir`, `LazyLoader`-gated, and mounted by
both `LauncherCapsule.qml` and `ClockActionsCapsule.qml` — 18-11's Option B is taken. This was
already true at Iteration 1's own bound sha (`8c5d280`); the row's stale `FAIL` text (written by
task 1 against an earlier, pre-`8c5d280` HEAD) has been corrected in place above, reverted to the
placeholder verdict and given the observation gesture, rather than left to silently block a build
that in fact already carries the fix. The visual behaviour itself has never been observed live —
the landing commit says so explicitly — so this is a first-look row for Iteration 2, not a
re-confirmation.

## Iteration 2 — Verdicts

_Pending — no human sitting has been performed against this iteration's fingerprint yet. All
fifteen rows below are reset to the placeholder for this iteration; the master tables above
(`## Block A`, `## Block B`, `## Named Sub-Judgments`, `## Lifted UI-SPEC Rows Judged Here`) are
where verdicts and observations are actually written when the sitting happens — this list is the
Iteration 2 checklist, not a second copy of those tables, so that filling in the master tables is
never ambiguous about which iteration it belongs to. Order fixed per the plan's ordering contract:
Block A first, then Block B, then the three named sub-judgments, then the lifted row._

- [ ] A.1 — AWAITING-OBSERVATION
- [ ] A.2 — AWAITING-OBSERVATION
- [ ] A.3 — AWAITING-OBSERVATION
- [ ] A.4 — AWAITING-OBSERVATION
- [ ] A.5 — AWAITING-OBSERVATION
- [ ] B.1 — AWAITING-OBSERVATION
- [ ] B.2 — AWAITING-OBSERVATION
- [ ] B.3 — AWAITING-OBSERVATION (audio half live; brightness half transcribed per D-18-39 — never judged fresh)
- [ ] B.4 — AWAITING-OBSERVATION
- [ ] B.5 — AWAITING-OBSERVATION
- [ ] B.6 — AWAITING-OBSERVATION
- [ ] B.4-DRAWER — AWAITING-OBSERVATION (branch machine-resolved to Option-B-taken above; gesture still required — first live look at the drawer's actual expansion direction)
- [ ] B.6-WS — AWAITING-OBSERVATION
- [ ] B.6-WSCOUNT — AWAITING-OBSERVATION
- [ ] UI-E7-LT — AWAITING-OBSERVATION

**`## Deletion Authorisation` stays `RETIRE-02 BLOCKED`** until all fifteen rows above carry a
verdict from the closed vocabulary and task 3 runs. Iteration 1's four defects (F1-F4) are fixed
and their commits are named above, but Iteration 1 never reached eleven of the fifteen rows and
recorded no verdict on any of the fifteen — a re-check re-observes all fifteen, not only the four
that were reported, because the workspace capsule, the entry list and the drawer host are shared
surfaces and a fix to one can regress another (must_haves, "A re-check re-observes all fifteen
rows").

---

## Iteration 2 — operator findings, 2026-08-12 17:45

Build under test: HEAD `13de40f`, quickshell pid `1520318`, reserved `[0,48,0,0]`, no waybar.

The operator opened the sitting and reported one defect before any row was verdicted. Per this
record's contract the gate **judges and does not fix**: the finding is recorded here with its
owning files and its remedy, the fix lands outside this record, and Iteration 3 re-observes **all
fifteen rows**. No row below Iteration 2's checklist carries a verdict — the sitting was
suspended, which is different from passing.

| # | Operator's words | Owning files | Root cause | Status |
|---|---|---|---|---|
| F5 | "The popup cards appear too low. They should be aligned with the top of the window" | `SectionPopout.qml:167` (horizontal), `SectionPopout.qml:168` + `BarDrawer.qml:101` (vertical) | **CONFIRMED BY MEASUREMENT, not by source reading.** `hyprctl layers -j` with the wifi popout pinned open returned `ns=quickshell-bar-wifi x=2085 y=100 w=360 h=276` against a bar measured in the same call at `y=6 h=42` (bottom edge 48) and a reserved array of `[0,48,0,0]`. The card's top therefore sits **52px below y=48, where the window area begins**. Cause is a double-count of the bar's own extent: `_horizontalTopMargin` is `Design.barEdgeMargin + Design.barHeight + Design.spacingXs` (52), but the compositor has *already* offset this anchored surface past the bar's 48px exclusive zone, so the bar's extent is added twice — 48 + 52 = the measured 100. | Open |

**This is the same defect `BarTooltip.qml` already measured and fixed, in a file that never got the
correction.** `BarTooltip.qml:78-90` records the identical failure from 2026-08-12 in the F2 fix:
the tooltip started from `barEdgeMargin + barHeight + spacingXs` (52) transcribed from
`SectionPopout`'s shape, "rendered at y=100 (measured via `hyprctl layers`) against a bar whose
bottom edge is 48", and was corrected to `_horizontalTopMargin: Design.spacingXs` — "only the GAP
past the edge the compositor already found, nothing more." The two surfaces are structurally
identical and share their whole layer posture: both `PanelWindow`, both
`anchors { top: true; left: !vertical; right: vertical }`, both `exclusiveZone: 0`, both
`exclusionMode: ExclusionMode.Ignore`, both `WlrLayershell.layer: WlrLayer.Overlay`. The comment at
`SectionPopout.qml:82-84` justifying the difference — "a popout is positioned inside a window that
spans the screen, whereas this is an anchored layer surface" — is factually wrong about
`SectionPopout`, which is itself an anchored layer surface, not a screen-spanning window.

**Scope: one systemic defect across two files, not six.** All six cards inherit the frame —
`AudioPopout.qml`, `MediaPopout.qml`, `WifiPopout.qml`, `BluetoothPopout.qml`, `ClockPopout.qml`
and `ResourcesPopout.qml` all declare `SectionPopout` as their root — so a single expression owns
every card's position. The vertical branch carries the same shape twice
(`SectionPopout.qml:168` and `BarDrawer.qml:101`, both
`barEdgeMargin + barColumnWidth + spacingXs` past a right edge the compositor has already found),
predicting a 54px overshoot in vertical orientation. **That half is a prediction, not a
measurement** — it requires the same `hyprctl layers` read taken in vertical orientation before any
edit, and it must not be fixed on the strength of the horizontal measurement alone.

**Remedy.** One term per expression: drop the bar's extent (`Design.barHeight` /
`Design.barColumnWidth`) and keep only the gap, exactly as `BarTooltip.qml:91-92` now does. Lands
the horizontal card top at 52 — 4px clear of the bar's bottom edge, `Design.spacingXs` on the
repo's 4px grid. Fix lands as a quick task outside this record.

**Consequence for the gate.** `## Deletion Authorisation` stays `RETIRE-02 BLOCKED` and 18-20 must
not run. Iteration 2's verdict checklist is void: a popout reposition moves a surface that
`A.2` (floating clear of every edge), `B.5` (tray menu opening below the cell, and leftward in
vertical) and `B.4-DRAWER` (drawer growth direction) are all judged against, so the fix supersedes
this iteration's fingerprint and Iteration 3 opens against a new one.

**Note on F5 against F2.** F2 and F5 are the same root cause in two files, found thirteen hours
apart by two separate sittings, because the F2 fix corrected the file it was reported against and
did not sweep the sibling that taught it the wrong expression. Neither was visible to any automated
gate in this phase — that is now the fourth purely visual defect to survive a green automated pass,
strengthening rather than weakening the precedent D-18-31 cites for why this human gate exists.
