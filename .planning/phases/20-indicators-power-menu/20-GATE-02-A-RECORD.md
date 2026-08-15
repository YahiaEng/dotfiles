# 20-GATE-02-A-RECORD.md — Gate A (OSD), unlocks RETIRE-04

## What This Record Is

Gate A is one of the phase's two independent GATE-02 render gates (D-20-42) — the OSD half.
It judges the replacement OSD (`Toast.qml` instance, `quickshell-osd` namespace) against
swayosd's recorded behaviour (`20-BEHAVIOUR-BASELINE.md`), criterion by criterion, and its
own verdict authorises exactly one thing: `RETIRE-04` (`swayosd` + `swayosd-libinput-backend.service`).
Gate B (the power menu, `20-GATE-02-B-RECORD.md`) is scored and authorised entirely
separately — a stall here must never hold Gate B hostage, per D-20-42.

Format follows `18-GATE-02-RECORD.md`'s precedent: a criteria table with a closed verdict
vocabulary, a judged sha, and a per-gate `## Deletion Authorisation` section.

## Verdict Vocabulary

- **`PASS`** — the gesture was performed on the running shell and the criterion was met.
- **`FAIL`** — the gesture was performed and the criterion was not met. Blocks Gate A's own
  deletion (RETIRE-04) until fixed and re-checked. Does not affect Gate B.
- **`NOT-DEMONSTRABLE`** — the criterion (or one half of it) has no observable subject on this
  hardware, recorded with its reason. Authorised for criterion 3's brightness half by D-18-39's
  precedent (this host has zero backlight-class devices).
- **`AWAITING-OBSERVATION`** — placeholder. Not a verdict. A row carrying this token has not
  yet been judged live and does not authorise anything.

## Automated Pre-Checks (run before presenting this gate, per the executor's `mandatory_verification`)

All read-only, run against the live host on 2026-08-16, HEAD `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205`:

| Check | Result |
|---|---|
| `timeout 6 quickshell -p shell.qml` load, grepped for error/binding-loop | Clean. The one matched line (`QDBusError` from `qt.qpa.services`, the host-portal app-ID warning) is one of the three pre-existing ignorable warnings named in `mandatory_verification` — not a new defect. |
| `qmllint modules/session/PowerMenu.qml` | Exit 0 (Gate B's own surface — PowerMenu is lazy-loaded and does not appear in the shell load-check above, so it is linted separately per `mandatory_verification`'s own instruction; recorded here for completeness since Gate A's automated pass also covers it) |
| `colour-lint` | Exit 0. |
| `motion-lint` | Exit 0. |
| `quickshell-doctor --self-test` | 55/55 passed, 0 failed, exit 0. |
| `grep -n swayosd-client hypr/.config/hypr/config/keybinds.lua` | Two hits, both comments recording that no invocation remains (lines 301, 305) — zero live `swayosd-client` calls. |

These confirm the build is structurally sound going into the live sitting. **None of them
constitute a live-gesture pass for any criterion below** — they are pre-flight only, per the
executor's instruction not to self-certify a criterion the user has not confirmed.

## Build Under Test

- **HEAD sha:** `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205` — the sha this record's criteria are
  judged against. Re-read live via `git rev-parse HEAD` at the moment this file was authored.
- **Working tree:** clean at time of authoring.
- **Interlock plan 20-09 must re-assert before deleting anything:**
  `git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/`
  must still hold (exit 0, no output) at the moment of deletion. A shell tree that moved since
  this sha invalidates this record's judgment.

## Setup, Before Sitting

1. Apply layer rules with `hyprctl eval` or a full Hyprland restart — **never `hyprctl reload`**,
   which silently drops layer-rule edits (a known trap in this repo's own history) and would
   make a correct surface fail criterion 1 for the wrong reason.
2. Have `20-BEHAVIOUR-BASELINE.md`'s swayosd section open alongside this record — that is the
   comparison baseline every criterion below is judged against.
3. For criterion 2, use the real theme-switch path (both a static preset switch and a matugen
   wallpaper switch) — never edit a colour file directly to simulate it.
4. For criterion 6, use a REAL physical Caps Lock key press — not `wtype`. `wtype` does not
   exercise the kernel's LED-classdev path this indicator reads (`20-GATE-01-MEASUREMENTS.md`'s
   own sysfs-watch measurement already found the difference between a synthetic and a real
   press load-bearing).
5. Note the current volume, theme and workspace so state can be restored after the sitting.

## Gate A Criteria

| # | Criterion (verbatim from `20-UI-SPEC.md` § "Gate A — OSD") | Verdict | Observation |
|---|---|---|---|
| 1 | The OSD frame reads as visually part of the same family as the popup card/centre/toast (rounded corners, `GradientBorder`-free but same `notifSurface` fill register, theme-reactive) — never SwayOSD's flat unthemed pill. | AWAITING-OBSERVATION | Not yet judged live. |
| 2 | A live theme switch re-colours the slider fill/handle within one crossfade, zero literal-hex flash. | AWAITING-OBSERVATION | Not yet judged live. |
| 3 | Volume/brightness/mic key presses each show the correct single-row OSD; pressing two within `osdRecencyWindowMs` shows both as a two-row column; a control that never moved never appears. | AWAITING-OBSERVATION | **Brightness half pre-empted, per this plan's own must_haves and D-18-39's precedent:** `/sys/class/backlight/` is empty on this host (zero backlight-class devices, confirmed live in `20-RESEARCH.md`), so the brightness row's code path is present-but-inert and cannot be demonstrated live here — record that half `NOT-DEMONSTRABLE` when the sitting happens, not `FAIL`, and not silently omitted. **Volume and mic halves still require a real live gesture** (single-row show, two-within-window column, absent-if-unmoved) — not yet performed. |
| 4 | Hover pauses the auto-hide timer; leaving resumes it (not a reset). | AWAITING-OBSERVATION | Not yet judged live. |
| 5 | Drag and scroll both adjust a slider in place, writing through the live backend — confirmed by a value shown elsewhere (bar capsule, centre) agreeing immediately. | AWAITING-OBSERVATION | Not yet judged live. |
| 6 | Caps Lock shows the icon+label row **only** on the ON transition, never on OFF. | AWAITING-OBSERVATION | Not yet judged live. **Carries WINDOWS row 77's open verification debt** — the 250ms poll mechanism (`CapsLockBackend.qml`, built after GATE-01 measured the specified event-driven watch dead on this host) has never been confirmed to fire on a real physical key press. This criterion IS that confirmation. |
| 7 | The two GATE-01 open questions are answered with evidence, not assumed: does the pill render over hyprlock (D-20-19); does Caps Lock indicate at the SDDM prompt before this gate authorises RETIRE-04's `swayosd-libinput-backend.service` removal (D-20-17/18). | **PASS** | **Resolved directly from `20-GATE-01-MEASUREMENTS.md`, per this plan's own instruction that criterion 7 reads plan 20-01's recorded measurements rather than re-taking them.** (a) § "SDDM greeter Caps Lock" — no on-screen indicator appeared at the greeter (the keyboard's own hardware LED lighting is a separate, unrelated fact); verdict token `RETIRE-04 proceeds`, not `RETIRE-04: BLOCKED` — so this criterion does not trigger the plan's own "D-20-18 BLOCKED branch fails criterion 7" clause. (b) § "SwayOSD over hyprlock" — the pill did NOT appear over the hyprlock lock surface; per D-20-19's negative branch this is recorded as `amended — locked-key-functionality already satisfied, no lock-surface render required`, not chased as a gap. Both sub-answers are evidenced, neither defaults, and neither blocks RETIRE-04. |

## Deletion Authorisation

**`RETIRE-04 BLOCKED` — pending live render-gate sitting.**

Six of seven criteria (1-6) remain `AWAITING-OBSERVATION`; only criterion 7 is resolved (from
GATE-01's own prior measurement, not a fresh live gesture). Per this record's own pass bar,
every criterion must carry `PASS` or `NOT-DEMONSTRABLE`-with-reason before this section can
read `RETIRE-04 AUTHORISED`. This is a normal, expected mid-gate state — not the D-20-18
scope-escalation branch, which applies only if criterion 7 itself had failed.

**Once the operator completes the live sitting** (criteria 1-6, plus re-confirming criterion 3's
volume/mic halves and the brightness half's `NOT-DEMONSTRABLE` reason), this section is rewritten
with:
1. The authorisation token `RETIRE-04 AUTHORISED` (or a documented `FAIL` list keeping it
   `RETIRE-04 BLOCKED`).
2. Re-verification that `git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/`
   still holds — a shell tree that moved since the judged sha invalidates the judgment.

Plan 20-09 reads this section as its own precondition and refuses to delete `swayosd` on
anything but a full `RETIRE-04 AUTHORISED` pass.
