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
| 1 | The OSD frame reads as visually part of the same family as the popup card/centre/toast (rounded corners, `GradientBorder`-free but same `notifSurface` fill register, theme-reactive) — never SwayOSD's flat unthemed pill. | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |
| 2 | A live theme switch re-colours the slider fill/handle within one crossfade, zero literal-hex flash. | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |
| 3 | Volume/brightness/mic key presses each show the correct single-row OSD; pressing two within `osdRecencyWindowMs` shows both as a two-row column; a control that never moved never appears. | PASS (volume, mic) / **NOT-DEMONSTRABLE** (brightness) | **Volume and mic halves PASS**, confirmed live by the operator (single-row show, two-within-window column, absent-if-unmoved). **Brightness half is NOT-DEMONSTRABLE, per D-18-39's precedent** — this host has zero backlight-class devices (`/sys/class/backlight/` empty, `brightnessctl -l` lists only LED-class devices), so the brightness row's code path is present-but-inert and cannot be exercised here. The operator has EXPLICITLY APPROVED proceeding with RETIRE-04 despite this — it does NOT block Gate A's authorisation — but it is recorded as an **accepted, named risk with its verification debt intact**, not a pass. These dotfiles also target a laptop, where this path is a real deliverable that remains unproven. `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md` and WINDOWS.md row 78 stay OPEN — this gate's approval does not close them. |
| 4 | Hover pauses the auto-hide timer; leaving resumes it (not a reset). | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |
| 5 | Drag and scroll both adjust a slider in place, writing through the live backend — confirmed by a value shown elsewhere (bar capsule, centre) agreeing immediately. | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |
| 6 | Caps Lock shows the icon+label row **only** on the ON transition, never on OFF. | **PASS — confirmed live** | The operator pressed the physical Caps Lock key and the indicator appeared, exercised specifically and separately from the rest of the sitting. **This closes WINDOWS row 77**, which had never been confirmed before: the 250ms sysfs poll in `CapsLockBackend.qml` (built after GATE-01 measured the specified event-driven watch dead on this host) DOES fire correctly on a real physical key press. This is also the resolution of `20-RESEARCH.md` Open Question 1 (whether the poll-based fallback would actually work in practice) — it does. |
| 7 | The two GATE-01 open questions are answered with evidence, not assumed: does the pill render over hyprlock (D-20-19); does Caps Lock indicate at the SDDM prompt before this gate authorises RETIRE-04's `swayosd-libinput-backend.service` removal (D-20-17/18). | **PASS** | **Resolved directly from `20-GATE-01-MEASUREMENTS.md`, per this plan's own instruction that criterion 7 reads plan 20-01's recorded measurements rather than re-taking them.** (a) § "SDDM greeter Caps Lock" — no on-screen indicator appeared at the greeter (the keyboard's own hardware LED lighting is a separate, unrelated fact); verdict token `RETIRE-04 proceeds`, not `RETIRE-04: BLOCKED` — so this criterion does not trigger the plan's own "D-20-18 BLOCKED branch fails criterion 7" clause. (b) § "SwayOSD over hyprlock" — the pill did NOT appear over the hyprlock lock surface; per D-20-19's negative branch this is recorded as `amended — locked-key-functionality already satisfied, no lock-surface render required`, not chased as a gap. Both sub-answers are evidenced, neither defaults, and neither blocks RETIRE-04. |

## Deletion Authorisation

**`RETIRE-04 AUTHORISED`**

All seven criteria carry a verdict. Criteria 1, 2, 4, 5 PASS. Criterion 3 PASSES for its volume
and mic halves; its brightness half is NOT-DEMONSTRABLE (zero backlight-class devices on this
host, D-18-39 precedent) and is explicitly accepted by the operator as an open, named risk rather
than treated as blocking — see the note on that row. Criterion 6 PASSES, confirmed live with a
real physical Caps Lock key press. Criterion 7 PASSES (resolved from `20-GATE-01-MEASUREMENTS.md`,
per the plan's own instruction). The operator reported **"Both gates approved"** on 2026-08-16.

**Judged sha:** `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205`.

**Interlock re-verified at authorisation time:**
`git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/`
holds (exit 0, no output) — the shell tree has not moved since the judged sha. Re-run at HEAD
`4aa2f20542edade99c7267a7724fc42d6f213f15` (this record's own commit ancestor) and confirmed
clean.

**Accepted residual risk carried forward, not cleared by this authorisation:** criterion 3's
brightness half stays NOT-DEMONSTRABLE. `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md`
and WINDOWS.md row 78 remain OPEN — this authorisation does not close them, and the brightness
path ships unproven pending real laptop hardware.

Plan 20-09 reads this section as its own precondition. It MUST re-assert the interlock command
above at the moment of deletion before removing `swayosd` — a shell tree that has moved since the
judged sha invalidates this authorisation.
