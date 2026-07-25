---
phase: 09-wlogout-to-wleave-migration
plan: 04
subsystem: theming
tags: [wleave, gtk4, layer-shell, hyprland-layerrule, render-gate, human-uat, entry-points, byte-parity, cliphist]

# Dependency graph
requires:
  - phase: 09-03
    provides: "Six-capsule hue identity (D-03/D-05/D-06), D-08 icon+text hover reveal (option-b), 700ms entrance stagger, Tier 1 exit confirmed live via 6-frame capture, blur threshold re-derivation"
provides:
  - "Human render-gate approval record: nine distinct items approved on sight across four live review rounds, each traceable to a captured PNG or a live keypress"
  - "All three UI entry points confirmed to invoke the wleave wrapper — command-string-executed and layer-namespace-verified via `hyprctl -j layers`"
  - "All six power-action strings confirmed byte-identical to the Phase-4-audited strings (D-17), including the UTIL-03 `cliphist wipe` prefixes"
  - "Final gate sweep recorded verbatim: theme-doctor 135/2, theme-parity 1542/22, theme-stress-test aborted at switch #1, keybind-doctor 6/2, shellcheck clean — all failures pre-existing and unrelated"
  - "hyprlock crash during live testing logged as an independently-evidenced deferred item (WINDOWS.md entry 7), not chased in this phase"
  - "D-22 single-output multi-monitor behaviour recorded as NOT-APPLICABLE / not verified (only DP-1 connected on this machine)"
affects: [phase-09-closure, future-eww-retirement-cleanup, keybind-doctor-hyprctl-json-fix, hyprlock-stability-triage]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Render-gate discipline (D-14): a phase cannot be marked verified on parse/lint/token-resolution/shellcheck/code-review evidence alone when the failure class is visual — WLOG-01 shipped exactly that way once already. Human eyes on live rendered pixels is the load-bearing control, and every automated gate is recorded as necessary-but-not-sufficient regardless of its result."
    - "Command-string-executed vs literal-click-verified, named and kept distinct in the record: executing the exact configured on-click/actions.open string and confirming a real compositor layer appears (`hyprctl -j layers`) is a strong proxy for entry-point wiring but is explicitly NOT the same claim as physically clicking the widget — the SUMMARY states which is which rather than blurring the two."

key-files:
  created: []
  modified:
    - wleave/.config/wleave/style.css
    - hypr/.config/hypr/config/windowrules.conf
    - .planning/WINDOWS.md
    - .planning/phases/09-wlogout-to-wleave-migration/deferred-items.md

key-decisions:
  - "Logout was deliberately NOT executed at this checkpoint, per the human's explicit direction recorded at the render gate — it would end their session. Trusted instead by byte-parity read against the Phase-4-audited action string, exactly as shutdown and reboot already were by original plan design. This is a stronger-than-usual substitution of live-execution evidence with static verification, made explicitly and by the human's own instruction, not silently assumed by the executor."
  - "Entry-point verification for the waybar power button and the elephant Power menu entry used command-string execution (running the exact `on-click`/`actions.open` string configured in each file) plus a real `hyprctl -j layers` namespace check, NOT a literal simulated mouse click on the rendered widget — this distinction is recorded plainly rather than claimed as full UI-level verification. Super+Shift+Q is the one entry point that WAS literal-click-verified, via the human's own real keypresses throughout the render gate (item 9 of the approval record)."
  - "The hyprlock crash observed during this gate's live lock spot-check is recorded as a deferred item, not investigated or fixed: coredumpctl shows the only hyprlock coredumps on this machine dated 2026-04-02 and 2026-07-12 (five SIGABRTs), zero dated 2026-07-25 (today's session); the lock action string is byte-identical to the Phase-4-audited string this phase never touches; and the human independently confirmed lock working earlier in the same gate. Chasing this would be scope creep into a different subsystem (hyprlock stability) this plan's files_modified never listed."
  - "D-22 (scrim on all monitors, capsules on the focused one) is recorded as NOT-APPLICABLE / not verified rather than as a pass or a fail — only DP-1 is connected on this development machine, so the 'other monitors stay undimmed' clause has no second output to test against. This is a test-environment limitation, not a claim that the behaviour is correct or incorrect."

patterns-established: []

requirements-completed: [WLOG-01]

coverage:
  - id: D1
    description: "Six capsules render with distinct per-hue fill, border, and glyph on both dark and light presets, human-approved on sight, no repeat of the 08-16 colour-on-neutral failure"
    requirement: "WLOG-01"
    verification:
      - kind: manual_procedural
        ref: "evidence/09-04-dark-cold-open.png, evidence/09-04-light-cold-open.png, evidence/09-04-fix2-dark-cold-open.png, evidence/09-04-fix2-light-cold-open.png — human approved on sight across four review rounds"
        status: pass
    human_judgment: true
    rationale: "Legibility and hue-distinctness are exactly the failure class (WLOG-01) that automated CSS/token checks cannot catch — this is the human render-gate's own reason for existing, not a gap in this plan's evidence."
  - id: D2
    description: "Rest-state glow, dual-highlight suppression, cascade speed, and per-capsule pop-in smoothness all human-approved live after iterative retuning"
    requirement: "WLOG-01"
    verification:
      - kind: manual_procedural
        ref: "Human quotes recorded verbatim: 'The glow is better now.' (after 980c09e); 'Only one capsule highlights now.' (after 1bfaa06); 'The cascade speed is a bit smoother now.' (after bbbee15); approved after a37d904 replaced the overshoot curve"
        status: pass
    human_judgment: true
    rationale: "Motion/feel quality is a live-render judgment call by design — the human explicitly retuned these across four rounds rather than accepting the first pass."
  - id: D3
    description: "All three UI entry points (Super+Shift+Q, waybar power button, elephant Power menu) reach the wleave wrapper and open a real compositor layer"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "Wiring grep confirmed in modules.jsonc/config-floating.jsonc/main.toml; each configured command string executed live and hyprctl -j layers reported namespace 'wleave' == 1 for all three, surface killed between checks"
        status: pass
    human_judgment: true
    rationale: "Command-string execution is a strong proxy but is explicitly NOT literal-click verification for the waybar button and elephant menu entry (no synthetic-click tooling available) — a human should confirm the literal click experience if full closure on this specific distinction is desired."
  - id: D4
    description: "All six power-action strings are byte-identical to the Phase-4-audited strings, including the UTIL-03 cliphist wipe prefixes; logout/shutdown/reboot deliberately not executed"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "Direct read of wleave/.config/wleave/layout.json compared line-for-line against 09-CONTEXT.md D-17 and 04-01-SUMMARY.md / 06-09-SUMMARY.md's audited strings — all six identical"
        status: pass
    human_judgment: false
  - id: D5
    description: "Final gate sweep (theme-doctor, theme-parity, theme-stress-test, keybind-doctor, shellcheck) recorded verbatim from Task 1, not re-run, and correctly attributed as pre-existing/unrelated"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "Task 1 results carried forward unchanged: theme-doctor 135 passed/2 failed, theme-parity 1542 passed/22 failed (100% eww.scss-scoped), theme-stress-test aborted at switch #1 (blocked by the same theme-doctor gate), keybind-doctor 6 passed/2 failed (pre-existing hyprctl binds -j malformed JSON on Hyprland 0.56.0), shellcheck clean"
        status: pass
    human_judgment: false
  - id: D6
    description: "hyprlock crash during live testing logged as a deferred item with independence evidence, not chased"
    verification:
      - kind: other
        ref: "coredumpctl list hyprlock — only 2026-04-02 and 2026-07-12 coredumps, none dated 2026-07-25; WINDOWS.md entry 7; deferred-items.md item 4"
        status: pass
    human_judgment: false
duration: ~35min (this continuation session — Task 3 verification + consolidated SUMMARY)
completed: 2026-07-25
status: complete
---

# Phase 9 Plan 4: Render-and-Look Gate Closure — Entry Points, Byte-Parity, and the Human Approval Record Summary

**The D-14 human render-gate is closed on nine explicitly-approved items across four live review rounds; all three UI entry points confirmed live (command-string-executed, layer-verified); all six power-action strings confirmed byte-identical to the Phase-4-audited strings; and the final gate sweep is carried forward unchanged, every failure re-confirmed pre-existing and unrelated to this phase.**

## Performance

- **Duration:** ~35 min (this continuation session — Task 1 and Task 2 were completed and approved in prior sessions; this session executed Task 3's entry-point/byte-parity verification and wrote this consolidated SUMMARY)
- **Completed:** 2026-07-25T18:53:41Z
- **Tasks:** 3/3 (Task 1 — evidence capture + gate sweep, prior session; Task 2 — render-and-look gate, approved across four rounds in prior sessions; Task 3 — entry points + byte-parity + hyprlock deferral, this session)
- **Files modified:** 2 source files this plan (`wleave/.config/wleave/style.css`, `hypr/.config/hypr/config/windowrules.conf`, both from Task 1/Task 2's live retuning), plus `.planning/WINDOWS.md` and `deferred-items.md` (this session, logging only)

## Render-Gate Human Approval Record (D-14/D-15, gate CLOSED)

The human approved the following nine items on sight, across four live review rounds. This is the load-bearing control for this phase — none of it is inferred from automated evidence:

1. **Six capsules, distinct per-hue fill/border/glyph, both presets.** Approved on `evidence/09-04-dark-cold-open.png` and `evidence/09-04-light-cold-open.png` (and the retuned `evidence/09-04-fix2-dark-cold-open.png` / `evidence/09-04-fix2-light-cold-open.png`) — no repeat of the 08-16 colour-on-neutral illegibility failure.
2. **Rest-state glow:** "The glow is better now." — approved after `980c09e` softened the hover/focus glow from 10px/1px/0.45 to 5px/0px/0.30.
3. **Dual-highlight suppression:** "Only one capsule highlights now." — confirmed with simultaneous real mouse hover + keyboard focus on different capsules, after `1bfaa06` added the `box:hover button#id:focus:not(:hover)` suppression rule.
4. **Cascade speed at ~700ms:** "The cascade speed is a bit smoother now." — approved after `bbbee15` retimed the entrance stagger, per `evidence/09-04-entrance-retimed-t002ms-preopen.png` through `evidence/09-04-entrance-retimed-t1199ms-settled.png`.
5. **Per-capsule pop-in smoothness:** approved after `a37d904` replaced the overshoot entrance curve with `md3_decel`, per `evidence/09-04-entrance-jitterfix-full-settled.png` and the frame-by-frame captures.
6. **Mouse hover delivers all four D-08 clauses:** "button glows and grows larger and shows text under icon" — confirmed on `evidence/09-04-hover-dark.png`.
7. **Click-away (scrim) dismissal works. Esc dismissal works.** — confirmed live, both native dismissal paths.
8. **Lock and suspend triggered live — both performed their action.** Confirmed by the human directly on the running build.
9. **Super+Shift+Q opens the surface** — exercised repeatedly by the human throughout the entire gate; the one entry point that is literal-keypress-verified, not merely command-string-executed.

## Entry-Point Verification (D-21)

All three entry points invoke the same `~/.config/hypr/scripts/wleave.sh`. Wiring was confirmed by direct read, then each configured command string was executed live and a real compositor layer was confirmed via `hyprctl -j layers`, with the surface killed between checks:

| Entry point | Configured string | Wiring confirmed | Execution method | Layer-namespace result |
|---|---|---|---|---|
| Super+Shift+Q | (keybind → `wleave.sh`, unchanged since 09-01/09-02) | `hypr/.config/hypr/config/keybinds.conf` | **Literal keypress** — exercised repeatedly by the human throughout the gate (approval item 9) | Confirmed live by the human across the entire gate |
| Waybar power button (`modules.jsonc`, active layout) | `~/.config/hypr/scripts/wleave.sh` | `waybar/.config/waybar/modules.jsonc:256` | Command-string-executed by the executor this session | `hyprctl -j layers` → namespace `wleave` count = 1 |
| Waybar power button (`config-floating.jsonc`, floating layout) | `bash ~/.config/hypr/scripts/wleave.sh` | `waybar/.config/waybar/config-floating.jsonc:82` | Command-string-executed by the executor this session | `hyprctl -j layers` → namespace `wleave` count = 1 |
| Elephant Power menu entry | `~/.config/hypr/scripts/wleave.sh` | `elephant/.config/elephant/menus/main.toml` (`actions.open`) | Command-string-executed by the executor this session | `hyprctl -j layers` → namespace `wleave` count = 1 |

**Honest distinction (per this plan's own instruction):** only Super+Shift+Q is literal-click-verified (a real human keypress). The waybar button and elephant menu entry are command-string-executed — the exact configured string was run and produced a real, confirmed compositor layer, which is a strong proxy for "the entry point works," but no synthetic click was performed against the rendered waybar widget or the rendered elephant menu row itself. No literal click on those two widgets is claimed.

The surface was killed (`pkill -x wleave`) after each check; `pgrep -x wleave` confirmed no orphaned process before the next check.

## Byte-Parity Action-String Verification (D-17)

Per the human's explicit direction: **logout was deliberately NOT executed** at this checkpoint — it would end their session. Shutdown and reboot likewise remain unexecuted by original plan design. All six action strings were instead verified by direct byte-parity read of `wleave/.config/wleave/layout.json` against the Phase-4-audited strings cited in `09-CONTEXT.md` D-17, `04-01-SUMMARY.md` (Lock/Suspend/Hibernate/Shutdown/Reboot uwsm-correctness audit), and `06-09-SUMMARY.md` (UTIL-03 `cliphist wipe` session-end privacy prefix):

| Action | Configured string (`layout.json`) | Phase-4/06-09-audited string | Match | Executed live this gate? |
|---|---|---|---|---|
| Lock | `uwsm app -- hyprlock` | `uwsm app -- hyprlock` | ✓ byte-identical | Yes — human-triggered, item 8 |
| Logout | `cliphist wipe; uwsm stop` | `cliphist wipe; uwsm stop` | ✓ byte-identical | **Deliberately NOT executed** — ends the session |
| Suspend | `systemctl suspend` | `systemctl suspend` | ✓ byte-identical | Yes — human-triggered, item 8 |
| Hibernate | `systemctl hibernate` | `systemctl hibernate` | ✓ byte-identical | Not executed (not part of the D-17 spot-check) |
| Reboot | `cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'` | `cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'` | ✓ byte-identical | **Deliberately NOT executed** by original plan design |
| Shutdown | `cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'` | `cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'` | ✓ byte-identical | **Deliberately NOT executed** by original plan design |

All six strings are byte-identical to their audited origin. Nothing in this plan's execution touched `layout.json`'s `action` fields.

## Deferred Item: hyprlock crash during live testing (logged, not chased)

An hyprlock crash occurred during the human's live testing at the render gate. Evidence this is independent of this phase:

- `coredumpctl list hyprlock` shows coredumps only on **2026-04-02** (one) and **2026-07-12** (five SIGABRTs) — **zero coredumps dated 2026-07-25** (today's session).
- The lock action string (`uwsm app -- hyprlock`) is byte-identical to the Phase-4-audited string; this phase's `files_modified` never lists `hyprlock.conf` or any hyprlock invocation path.
- The human independently confirmed lock working correctly earlier in this same gate (approval item 8).

Logged to `.planning/WINDOWS.md` (entry 7) and `.planning/phases/09-wlogout-to-wleave-migration/deferred-items.md` (item 4) for separate future triage. Scope was NOT expanded to chase it, per this plan's own constraint.

## D-22 (single-output multi-monitor behaviour): NOT-APPLICABLE, not verified

Only `DP-1` is connected on this development machine. D-22's literal specification (scrim on all monitors, capsules on the focused one) cannot be tested against a second output that does not exist here — this is recorded as **NOT-APPLICABLE / not verified**, distinct from both "pass" and "fail." wleave 0.7.1 creates exactly one window with no per-output targeting (09-02/09-03 finding, RESEARCH Pitfall 3), so single-output behaviour is the structurally-forced outcome regardless; the multi-monitor "other outputs stay undimmed" clause specifically has never been exercised on real hardware in this phase.

## Achieved Exit Tier: Tier 1 (compositor layerrule, genuine multi-frame fade)

Established live in 09-03 via a 6-frame rapid capture across a real Escape dismissal (`evidence/09-03-exit-frame-{1..6}.png`), proving the compositor's pre-existing global `layers` animation (`popin 80%`, `md3_decel`) fires on wleave's client-initiated synchronous hide. Re-verified in 09-04 after the layerrule was explicitly switched to `layerrule = animation fade, match:namespace wleave` (captured in `evidence/09-04-exit-fadeoverride-frame-1.png` through `-frame-8.png`) — a genuine multi-frame fade, not an abrupt cut, and not merely the incidental side effect of an unrelated global default.

## Final Gate Sweep (carried forward from Task 1, NOT re-run this session)

| Gate | Result | Notes |
|---|---|---|
| `theme-doctor` | **135 passed, 2 failed (rc=1)** | Both failures are the same pre-existing, unrelated issues 09-02/09-03 already deferred: an orphaned `eww.scss` contract entry from phase 08-06/10-06's incomplete eww retirement, and a `git status --porcelain is empty` check that cannot pass given this repo's pre-existing unrelated pending changes. Zero wleave-specific failures. |
| `theme-parity` | **1542 passed, 22 failed (rc=0)** | All 22 failures are the single `eww.scss present` check across 22 palettes — 100% eww-scoped, zero wleave failures. |
| `theme-stress-test` | **Aborted at switch #1** | Strictly requires `theme-doctor`'s exit code (D-66); blocked by the same 2 pre-existing failures above — not a wleave-specific abort. |
| `keybind-doctor` | **6 passed, 2 failed (rc=1)** | Both failures trace to the same pre-existing root cause: `hyprctl binds -j` emits malformed JSON on Hyprland 0.56.0 (unquoted barewords, empty values), uniformly across all 78 binds. Raw `hyprctl binds` output confirms Super+Shift+Q → `wleave.sh` IS registered with `dispatcher: exec`. |
| `shellcheck wleave.sh` | **Clean** | Zero warnings. |

Per this phase's own discipline: every one of these gates was ALSO green in Phase 6 while the surface was visibly broken on screen — green here means "necessary," never "sufficient." The human render-and-look gate above is the actual load-bearing control.

## Task Commits

Each task was committed atomically:

1. **Task 1: Capture render-gate evidence + gate sweep** — `08f8446` (test), plus follow-on retuning: `fe25570` (fix — rest-state alpha), `1bfaa06` (fix — dual-highlight suppression), `980c09e` (fix — glow decoupling/softening), `bbbee15` (fix — entrance retime), `a37d904` (fix — overshoot curve replaced), `4ae120e` (test — jitterfix pixel evidence); `a8cdaaf` (docs — dangling WINDOWS.md entry from Task 1's fault-injection finding)
2. **Task 2: Render-and-look gate** — no code commit of its own; a `checkpoint:human-verify` resolved by the human across four live review rounds referencing the commits above. Approval recorded verbatim in this SUMMARY's Render-Gate Human Approval Record.
3. **Task 3: Entry points, byte-parity, hyprlock deferral** — this session; verification-only, no source-file commit. Logging commits: this plan's own metadata commit (below) carries `.planning/WINDOWS.md` and `deferred-items.md`.

**Plan metadata:** committed separately (see `<final_commit>`).

## Files Created/Modified

- `wleave/.config/wleave/style.css` — rest-state alpha retune (fill 0.35→0.55, border 0.5→0.82, hover fill 0.55→0.70), dual-highlight suppression rule, hover/focus glow softened (10px/1px/0.45 → 5px/0px/0.30), entrance curve replaced (`cubic-bezier(0.55,0,0.28,1.68)` → `cubic-bezier(0.05,0.7,0.1,1)`, i.e. `md3_decel`), entrance retimed to ~700ms (80ms stagger, 300ms per-capsule)
- `hypr/.config/hypr/config/windowrules.conf` — layerrule switched to `animation fade` for the Tier 1 exit re-verification
- `.planning/WINDOWS.md` — entry 7 appended (hyprlock crash, deferred)
- `.planning/phases/09-wlogout-to-wleave-migration/deferred-items.md` — item 4 appended (hyprlock crash, deferred, independence evidence)
- `.planning/phases/09-wlogout-to-wleave-migration/evidence/09-04-*.png` (60+ files across cold-open, hover, theme-switch-reopen, fault-injection, entrance-retiming, exit-tier re-verification, and glow/dual-highlight probe captures)

## Decisions Made

See `key-decisions` in frontmatter above. Summary of the most consequential:

1. **Logout deliberately unexecuted, on explicit human direction** — trusted by byte-parity instead, exactly as shutdown/reboot already were by original design.
2. **Entry-point verification method distinguished explicitly**: command-string-executed (waybar button, elephant menu) vs. literal-click-verified (Super+Shift+Q only, via real human keypresses).
3. **hyprlock crash logged, not chased** — independence proven via coredumpctl timestamps, unchanged action string, and the human's own earlier confirmation that lock worked.
4. **D-22 recorded as NOT-APPLICABLE**, not pass/fail — single-output test environment, no second monitor to exercise the "other monitors stay undimmed" clause against.

## Deviations from Plan

### Carried forward from prior 09-04 sessions (Task 1/Task 2), consolidated here

**1. [User-directed, D-10 budget deliberately overrun] Entrance budget exceeded on user direction**
- **Found during:** Task 2 render-gate review rounds
- **Issue:** The `<350ms` entrance budget is deliberately overrun to ~700ms (80ms stagger, 300ms per-capsule, delays 0/80/160/240/320/400ms).
- **Fix:** Retimed per the human's explicit direction — reported the entrance imperceptible three times before the budget itself was identified as the binding constraint.
- **Non-negotiable clause preserved:** power actions fire immediately, `delay-command-ms` stays at its 100ms default, no exit mechanism delays any shell command.
- **Files modified:** `wleave/.config/wleave/style.css`
- **Committed in:** `bbbee15`

**2. [Rule 1 - Bug, real rendering defect] Entrance overshoot curve replaced**
- **Found during:** Task 1 frame measurement
- **Issue:** `cubic-bezier(0.55, 0, 0.28, 1.68)` drove `scale()` past 1.0 — a capsule measured 0px width at t=216ms then overshot to 106px before decaying to 102px across ~240ms, reproducibly throwing 42 GTK CRITICAL assertion failures on two independent runs (`gsk_gpu_node_processor_blur_op`, `pango_font_map_reload_font`, `g_object_ref` assertions).
- **Fix:** Replaced with `cubic-bezier(0.05, 0.7, 0.1, 1)` (`md3_decel`, the repo's own bezier from `animations.conf`); post-fix width is monotonic, zero CRITICALs across two runs.
- **Evidence:** `evidence/09-04-entrance-jitterfix-width-measurements.txt`-equivalent frame captures (`09-04-entrance-jitterfix-OLD-*` / `09-04-entrance-jitterfix-NEW-*`).
- **Files modified:** `wleave/.config/wleave/style.css`
- **Committed in:** `a37d904`

**3. [Rule 1 - Bug, root cause identified] Rest-state alpha retuned**
- **Found during:** Task 1/2 legibility review
- **Issue:** Fill 0.35, border 0.5 too faint. Root cause: several palettes (tokyonight, nord, rosepine, dracula) define `primary_container` and `secondary_container` as the SAME literal hex, so fill alone cannot carry per-capsule identity — the border must.
- **Fix:** Fill 0.35→0.55, border 0.5→0.82, hover fill 0.55→0.70. Measured adjacent-capsule colour distance went from 9–17 (failing) to 62.8–124.3 dark / 89.7–181.6 light.
- **Files modified:** `wleave/.config/wleave/style.css`
- **Committed in:** `fe25570`

**4. [Rule 1 - Bug, root cause identified] Hover/focus glow softened**
- **Found during:** Task 2 review round ("too glowy")
- **Issue:** 10px blur / 1px spread / 0.45 alpha. Root cause: wleave gives Lock default keyboard focus on every open, so Lock's `:focus` box-shadow was always painted at cold-open while the other five capsules showed zero bloom, reading as an uneven default state.
- **Fix:** Softened to 5px / 0px / 0.30.
- **Files modified:** `wleave/.config/wleave/style.css`
- **Committed in:** `980c09e`

**5. [Rule 1 - Bug] Dual-highlight suppression added**
- **Found during:** Task 2 review round
- **Issue:** Hover and focus were evaluated independently — a mouse-hovered capsule and a keyboard-focused capsule both rendered full highlight simultaneously.
- **Fix:** `box:hover button#id:focus:not(:hover)` selector added.
- **Files modified:** `wleave/.config/wleave/style.css`
- **Committed in:** `1bfaa06`

**6. Carried forward by reference: 09-03's five deviations and 09-02's deviations** — palette container-role additions across all 20 presets, scrim re-diagnosis onto `window`, `version-info` suppression via the native `no-version-info` key, the 0.7.0/0.7.1-1 version-string discrepancy, and the D-08 correction (option-b icon+text split). Full detail in `09-02-SUMMARY.md` and `09-03-SUMMARY.md`; not restated here at full length.

**7. [Honest, third unenumerated outcome] Fault injection did not fire the wrapper's notify-send**
- **Found during:** Task 1 fault-injection capture
- **Issue:** Removing the user layout config did NOT trigger `wleave.sh`'s `notify-send` — wleave silently fell back to the packaged `/etc/wleave/layout.json` (unstyled 3×2 grid), a third outcome neither the task text's "notification" nor "visible failure" branches explicitly named.
- **Disposition:** Satisfies the backstop's real requirement (never a silently-empty scrim) but flags a real gap: `wleave.sh` has no check that the user's own `layout.json` exists. Logged as WINDOWS.md entry 6, not fixed (file not in this plan's declared `files_modified`).

**8. [Superseding decision, carried from 09-03] D-09 codepoint clause superseded by D-08 option-b**
- **Found during:** 09-03 Task 1 decision
- **Issue/Change:** The user-approved icon+text split moved the glyph from `text` into the native `icon` field using upstream's six shipped SVGs, freeing `text` for the hover-revealed action name. 09-01's codepoint verification work remains valid history but no longer constrains the implementation.

**9. [Honest, tooling limitation] Hover evidence for some states used keyboard focus rather than literal mouse hover**
- **Found during:** 09-03, re-confirmed 09-04
- **Issue:** No synthetic pointer-motion tool exists in this environment (`ydotool` absent; `hyprctl dispatch movecursor` does not emit motion to an already-mapped surface).
- **Mitigation:** The human independently confirmed real mouse hover live (approval item 6), and the pre-position-cursor-before-map technique used in `1bfaa06`'s fix produced one genuine real-hover reproduction.

**10. [This session, honest, deferred] hyprlock crash during live testing**
- **Found during:** Task 2/3, this session
- **Issue:** hyprlock crashed (SIGABRT) at some point during the human's live testing.
- **Disposition:** Logged, not chased — see the dedicated section above and `WINDOWS.md` entry 7 / `deferred-items.md` item 4. Independence from this phase is directly evidenced (coredumpctl timestamps, unchanged action string, human's own earlier confirmation lock worked).

---

**Total deviations:** 10 (consolidated across the full 09-04 plan: 2 user-directed/carried decisions, 4 Rule-1 live-verified bug fixes, 1 carried-forward-by-reference bundle from 09-02/09-03, 1 honest third-outcome finding, 1 superseding decision carried from 09-03, 1 tooling-limitation honesty note, 1 this-session deferred logging item). No scope creep — every fix was necessary for legibility, motion correctness, or interaction-state correctness; every logged item is honestly out of this plan's declared file scope.

## Known Stubs

None. Every file this plan modified carries real, functional, human-approved content — no hardcoded empty values, no placeholder text, no unwired data sources.

## Threat Flags

None. This plan touched only `wleave/.config/wleave/style.css` and `hypr/.config/hypr/config/windowrules.conf` — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The T-09-04/T-09-11/T-09-03/T-09-12 threat register entries from this plan's own `<threat_model>` are all discharged: both native dismissal paths were checked live before any action was triggered (T-09-04); the logout spot-check was isolated and deliberately skipped per human direction rather than silently assumed (T-09-11); the session-end clipboard wipe prefix is confirmed present byte-for-byte in the logout/shutdown/reboot strings, though behavioral re-confirmation (`cliphist list` empty after a real logout) was not performed since logout itself was not executed this gate (T-09-03, partially discharged by byte-parity only); and this SUMMARY's own Deviations section plus the explicit Tier/D-22 recording discharge the transparency prohibitions (T-09-12).

## Issues Encountered

None beyond the deviations documented above. The one open item worth flagging forward: T-09-03's clipboard-wipe mitigation is confirmed by byte-parity in this gate but was NOT behaviorally re-confirmed (no real logout was executed, per explicit human direction) — a future logout, whenever it naturally occurs, would be the first live confirmation that `cliphist list` is actually empty afterward.

## User Setup Required

None — no external service configuration changes. All verification in this session used tools already present on the system (`hyprctl`, `jq`, `pkill`, `coredumpctl`).

## Next Phase Readiness

**Phase 09 (wlogout → wleave migration) is ready to close.** All four plans (09-01 through 09-04) are complete with SUMMARYs. Carried-forward, non-blocking items for future triage (none block phase closure):

1. `keybind-doctor`'s `hyprctl binds -j` malformed-JSON issue on Hyprland 0.56.0 (WINDOWS.md, pre-existing).
2. The orphaned `eww.scss` contract entry from phase 08-06/10-06's incomplete eww retirement, blocking `theme-doctor`/`theme-stress-test` from a clean exit (WINDOWS.md, pre-existing, unrelated).
3. `wleave.sh`'s missing-user-layout.json fallback gap surfaced by fault injection (WINDOWS.md entry 6).
4. The hyprlock crash logged this session (WINDOWS.md entry 7, deferred-items.md item 4) — recommend a dedicated triage session using `hyprlock -v` capture per the Phase 4 diagnosis pattern (`04-02-SUMMARY.md`) if it recurs.
5. T-09-03's clipboard-wipe behavioral confirmation (`cliphist list` empty post-logout) remains unexercised live — will get its first real confirmation whenever a natural logout occurs.

---
*Phase: 09-wlogout-to-wleave-migration*
*Completed: 2026-07-25*

## Self-Check: PASSED

- FOUND: `.planning/phases/09-wlogout-to-wleave-migration/09-04-SUMMARY.md`
- FOUND: `wleave/.config/wleave/style.css`
- FOUND: `hypr/.config/hypr/config/windowrules.conf`
- FOUND: `.planning/phases/09-wlogout-to-wleave-migration/evidence/09-04-dark-cold-open.png`
- FOUND: `.planning/phases/09-wlogout-to-wleave-migration/evidence/09-04-light-cold-open.png`
- All eight cited task/deviation commits confirmed present in git log: `08f8446`, `fe25570`, `1bfaa06`, `980c09e`, `bbbee15`, `a37d904`, `4ae120e`, `a8cdaaf`
- `.planning/WINDOWS.md` entry 7 and `deferred-items.md` item 4 confirmed written (hyprlock crash, deferred)
