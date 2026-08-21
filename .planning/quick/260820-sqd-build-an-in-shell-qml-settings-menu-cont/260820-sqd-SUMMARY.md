---
phase: quick-260820-sqd
plan: 01
subsystem: ui
tags: [quickshell, qml, hyprland, hyprlang-lua, hypridle, floating-window, hyprland-focus-grab]

# Dependency graph
requires:
  - phase: quick-260820-r44
    provides: the shell's existing modules/dashboard PanelDialog/panel family, Colours.qml/Motion.qml/Design.qml token singletons, NotifServer, AudioBackend/WifiBackend/BluetoothBackend
provides:
  - "An in-shell QML settings window (Super+comma / walker top row), reaching all four locked option groups: Appearance, Audio & connectivity, Display & input, Shell behaviour"
  - "A proven FloatingWindow (toplevel, not layer-surface) architecture pattern with HyprlandFocusGrab-based Esc/click-outside/focus-retention, reusable for any future non-layer-surface Quickshell surface"
  - "hypr-overrides.sh + lib/overrides.lua: a state-dir Lua-overrides persistence pattern for Hyprland monitor/input config that survives hyprctl reload, reusable for any future compositor-setting the shell needs to expose"
  - "idle-overrides.sh: editable hypridle listener timeouts via a source= state-dir include, with validate/backup/rollback discipline for a security-relevant config surface"
affects: [any future Quickshell summonable-surface work, any future Hyprland Lua config override work]

# Actuals (#2632)
actuals:
  tokens: 61000
  tasks: 4
  commits: 7

tech-stack:
  added: []
  patterns:
    - "FloatingWindow (Quickshell toplevel) + HyprlandFocusGrab for Esc-survives-focus-steal, click-outside-dismiss, and Menu-popup-safe input capture — measured to work despite hyprctl activewindow never reflecting it"
    - "validate -> apply live (hyprctl eval) -> verify (hyprctl -j, never the ok reply) -> persist (atomic tmp+mv, only after live verification) for any Hyprland-Lua-config-writing script"
    - "state-dir Lua overrides table (pcall-required, shape-normalised, or-fallback at every consumption site) mirroring lib/tokens.lua's own pattern, for persistence that must survive hyprctl reload"
    - "JSON-intermediate + jq-rendered Lua table literal for a script that reads-modifies-writes a compositor-consumed Lua state file without parsing Lua from bash"

key-files:
  created:
    - quickshell/.config/quickshell/modules/settings/ (whole new module: Settings.qml, SettingsState.qml, PageRegistry.qml, PageCompRegistry.qml, NavRail.qml, Pages.qml, common/{PageBase,SettingsSection,SelectRow,NavRow,ToggleRow,SliderRow,InfoRow}.qml, pages/{AppearancePage,ConnectivityPage,ShellBehaviourPage,DisplayInputPage}.qml)
    - hypr/.config/hypr/scripts/hypr-overrides.sh
    - hypr/.config/hypr/lib/overrides.lua
    - hypr/.config/hypr/scripts/idle-overrides.sh
  modified:
    - quickshell/.config/quickshell/shell.qml (settingsLoader, openSettings()/openSettingsPage(), settingsShortcut, settings IpcHandler)
    - quickshell/.config/quickshell/shortcuts.json, hypr/.config/hypr/config/keybinds.lua, hypr/.config/hypr/scripts/hypr-equivalence-check (Super+comma bind + ACCEPTED_ADDITIONS + VOLATILE_KEYS)
    - hypr/.config/hypr/config/windowrules.lua (float-settings window_rule, class org.quickshell measured live)
    - hypr/.config/hypr/config/monitors.lua, hypr/.config/hypr/hyprland.lua (overrides-consuming or-fallback reads)
    - hypr/.config/hypr/hypridle.conf (5 listeners moved to state-dir, 1 source= line)
    - stow.sh (overrides.lua + idle-overrides.conf seed/symlink blocks)
    - elephant/.config/elephant/menus/settings.toml (Settings top row)
    - .planning/PROJECT.md (dated reversal of the "Full GUI settings app" Out of Scope entry)
    - .planning/WINDOWS.md (row 92, the operator's outstanding live pass)

key-decisions:
  - "FloatingWindow (PD-01) confirmed viable via Task 1's tracer probe — class org.quickshell, takes keyboard focus, both IPC verbs drive it — the plan's single load-bearing unverified assumption is now measured, not assumed."
  - "HyprlandFocusGrab, reverted once on an untested fear during the tracer checkpoint round, was re-tried properly (measured, not theorized) after operator pushback and found to reliably solve Esc-survives-focus-steal (12/12) and click-outside-dismiss (operator-confirmed) despite never moving hyprctl activewindow — it captures wl_keyboard routing at a protocol layer beneath window activation."
  - "stayfocused (and every plausible synonym) does not exist in this Hyprland build's Lua window_rule vocabulary — measured via a direct rejection from hl.window_rule's own validator, not inferred from missing docs."
  - "Connectivity page subtext is fixed descriptive text, not a live backend read — reading audioBackendInstance/wifiBackendInstance/bluetoothBackendInstance here would require widening their panelOpen-gated polling the same way 15-07 widened it for the dashboard's Volume tile, out of proportion to a subtitle line."
  - "idle-overrides.sh's ordering validation (dim < lock < display-off < suspend) intentionally diverges from the plan's own prose (\"dim < screen-off < lock < suspend\") — the plan's wording transposes screen-off and lock relative to the actual, correct, already-shipped timeouts; enforcing the literal wording would reject the repo's own defaults."

requirements-completed: [D-01, D-02, D-03, D-04, D-05, D-06]

coverage:
  - id: D1
    description: "Super+comma opens a centred floating Settings window; pressing it again closes it; walker's new top row opens the same window"
    requirement: "D-02, D-06"
    verification:
      - kind: e2e
        ref: "Task 1 live probe (hyprctl clients -j class=org.quickshell, floating=true, size=960x640), run twice"
        status: pass
      - kind: manual_procedural
        ref: "Fourth tracer checkpoint — operator confirmed Super+comma toggle, item 5"
        status: pass
    human_judgment: false
  - id: D2
    description: "Nav rail lists four groups; selecting one swaps the content page; keyboard Up/Down also navigates"
    requirement: "D-01, D-02"
    verification:
      - kind: automated_ui
        ref: "wtype-driven Down x3/Up x3 cycle against a currentPageIdx diagnostic, logged exact 6-transition sequence, run twice, clamping confirmed at both ends"
        status: pass
      - kind: manual_procedural
        ref: "Fourth tracer checkpoint — operator confirmed nav-rail click and arrow-key navigation, items 2-3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Appearance page: Theme applies live and re-colours the desktop and the window itself; Wallpaper/Icon theme/Font launch existing pickers; Bar orientation flips the bar"
    requirement: "D-01, D-04"
    verification:
      - kind: manual_procedural
        ref: "Task 4 human-check item 4 (Appearance) — operator PASS, full 10-item checklist green, WINDOWS.md row 92 closed"
        status: pass
    human_judgment: true
    rationale: "Visual re-colour correctness and picker-window appearance require the operator's own eyes; this host also forbids screenshotting a FloatingWindow (unproven grim -g safety at plan time — later proven safe mid-saga and used for pixel-sample verification of the fix waves below), so no automated visual proof was possible for the ORIGINAL plan pass."
  - id: D4
    description: "Audio, Wi-Fi and Bluetooth rows summon the three existing panels through the guarded openPanel() path; none of the three panels is rebuilt"
    requirement: "D-01, D-04"
    verification:
      - kind: unit
        ref: "grep: zero direct *PanelLoader.active writes in modules/settings/"
        status: pass
      - kind: manual_procedural
        ref: "Task 4 human-check item 5 — operator PASS, full 10-item checklist green, WINDOWS.md row 92 closed"
        status: pass
    human_judgment: true
    rationale: "Confirming the correct panel opens (not just that a signal fired) needs the operator's own eyes."
  - id: D5
    description: "Display + input change applies live via hyprctl eval, verified against hyprctl -j (never the ok reply), and survives hyprctl reload"
    requirement: "D-01, D-03"
    verification:
      - kind: integration
        ref: "Task 3 verify check J — value-preserving round trip on the REAL compositor (write current DP-1 scale, hyprctl reload, confirm it held)"
        status: pass
      - kind: manual_procedural
        ref: "Task 4 human-check item 6 (switch theme, confirm display/input change survives) — operator PASS, full 10-item checklist green, WINDOWS.md row 92 closed"
        status: pass
    human_judgment: true
    rationale: "The round trip proves the mechanism on a value-preserving no-op; the operator's item 6 proves it on a GENUINE change plus a real theme switch, which is the actual failure class Task 3 was built to prevent."
  - id: D6
    description: "A malformed or absent overrides.lua boots the compositor on repo defaults; a monitor name/mode is validated against a closed allowlist before ever reaching hyprctl eval or the persisted Lua"
    requirement: "D-03"
    verification:
      - kind: integration
        ref: "hypr-lua-harness fault-injection battery (valid/malformed/absent overrides.lua), one session, all three PASS"
        status: pass
      - kind: unit
        ref: "hypr-overrides.sh negative-input battery: unknown output, mode not in availableModes, out-of-bounds scale, shell-metacharacter-shaped mode string — all rejected"
        status: pass
    human_judgment: false
  - id: D7
    description: "Motion preset and DND change from the window and persist; idle & lock timeouts are editable, apply to the running daemon, and survive a reboot"
    requirement: "D-01, D-03"
    verification:
      - kind: integration
        ref: "idle-overrides.sh mechanism gate (PD-03 probes B/C re-measured against installed hypridle v0.1.8) + live round trip (dim=300 unchanged, hypridle restarted into the correct uwsm scope, 5 rules confirmed) + negative battery (sub-floor, non-integer rejected without touching the daemon)"
        status: pass
      - kind: manual_procedural
        ref: "Task 4 human-check items 7-9 (motion/DND visible change, idle timeout re-check live including item 8's lock-lengthening, reboot survival) — operator PASS on all three after the post-plan live-pass saga (see below); WINDOWS.md row 92 closed"
        status: pass
    human_judgment: true
    rationale: "Reboot survival and the append-not-replace lengthened-lock-timeout check (item 8) are the whole point of this task's security posture and could not be proven without the operator living through a real idle cycle and a real reboot — both now confirmed."
  - id: D8
    description: "Every write lands under ~/.local/state; the git tree stays clean afterwards"
    requirement: "D-03"
    verification:
      - kind: unit
        ref: "git status --porcelain after every live-exercise round across all four tasks — clean except the pre-existing, out-of-scope .gsd/ dispatch-isolation directory"
        status: pass
    human_judgment: false
  - id: D9
    description: "PROJECT.md's Out of Scope entry reads as a dated, deliberate 2026-08-20 reversal"
    requirement: "D-05"
    verification:
      - kind: unit
        ref: "PROJECT.md diff — strikethrough + REVERSED 2026-08-20 note, matching the QML-rewrite reversal's own form"
        status: pass
    human_judgment: false

duration: ~7h (single continuous session, four tracer-checkpoint rounds)
completed: 2026-08-20
status: complete
---

# Quick Task 260820-sqd: In-Shell QML Settings Window Summary

**A FloatingWindow-based settings window (Super+comma) reaching all four locked option groups — Appearance, Audio & connectivity, Display & input, Shell behaviour — built on a HyprlandFocusGrab pattern proven live after three failed tracer-checkpoint rounds, a state-dir Lua-overrides mechanism for Hyprland config that survives `hyprctl reload`, and an editable hypridle listener config with validate/backup/rollback discipline.**

## Performance

- **Duration:** ~7 hours, one continuous session
- **Tasks:** 4 (plus 3 tracer-checkpoint amendment cycles inside Task 1)
- **Commits:** 7 (`a384b363`, `5614e287`, `ff2dc558`, `cce14214`, `013b03d2`, `acc4e5b1`, `914266c1`)
- **Files changed:** 35, +2841/-149

## Accomplishments

- A new `modules/settings/` QML module: a `FloatingWindow` toplevel (not a layer surface — PD-01's own locked, probe-gated decision) with a left nav rail (click AND arrow-key driven) beside a lazily-incubated page host, built on Caelestia's two-registry decomposition.
- All four D-01 option groups are real, working pages: Appearance (theme/wallpaper/icon/font/bar-orientation), Audio & connectivity (summons the three existing panels), Shell behaviour (motion/DND/idle & lock), Display & input (monitor mode/scale, keyboard/mouse, all live via `hyprctl eval` and persisted through a state-dir Lua overrides table that survives `hyprctl reload`).
- `hypr-overrides.sh` and `idle-overrides.sh`: two new validate → apply → verify → persist scripts, the second with an additional backup/rollback layer since idle/lock is a security control (T-SQD-08).
- `Super+comma` (measured free under both SUPER and SUPER+SHIFT), a new walker top row, and the closing of a stale "no custom settings UI" Out of Scope line in PROJECT.md.

## Task Commits

1. **Task 1: End-to-end tracer** — `a384b363` (feat) + 3 tracer-checkpoint amendments:
   - `5614e287` (fix) — SettingsSection width-collapse
   - `ff2dc558` (fix) — Esc focus-timing race
   - `cce14214` (fix) — focus retention (HyprlandFocusGrab, re-tried and proven), arrow-key nav, click-outside-dismiss
2. **Task 2: Three more pages, nothing rebuilt** — `013b03d2` (feat)
3. **Task 3: Display + input, live + persisted** — `acc4e5b1` (feat)
4. **Task 4: Editable idle & lock, mechanism re-measured first** — `914266c1` (feat)

## Files Created/Modified

See `key-files` frontmatter above for the full list. The single highest-risk new file is `hypr-overrides.sh` (validates monitor/input writes against a closed allowlist before they ever reach `hyprctl eval` or a Lua file the compositor `require`s at boot); the second is `idle-overrides.sh` (same discipline plus backup/rollback, since it governs whether the machine locks at all).

## Decisions Made

See `key-decisions` in the frontmatter. The single most consequential one: **`HyprlandFocusGrab` works for a `FloatingWindow` toplevel**, despite never moving `hyprctl activewindow` — this was found only because the operator explicitly rejected a premature revert (made on an untested fear during the tracer-checkpoint round) and required a real measurement instead. That measurement — an active grab keeps `Keys.onEscapePressed` reachable 12/12 times even after an explicit `hl.dsp.focus` steal to another window, confirmed with the window still open right up to the keypress (ruling out a premature `onCleared` close) — is now a reusable, proven pattern for any future non-layer-surface Quickshell summonable surface.

## Deviations from Plan

### Auto-fixed Issues (Rule 1 — bugs found and fixed before or immediately after first live exercise)

**1. [Rule 1] NavRail crashed the whole shell load — missing `QtQuick.Controls` import**
- **Found during:** Task 1, first live restart attempt
- **Issue:** `ToolTip` attached properties on a `MouseArea` require `import QtQuick.Controls`; without it, Quickshell failed to load the ENTIRE config (not just the settings surface) — the exact "one bad file kills every surface" class this repo's own memory warns about.
- **Fix:** added the import.
- **Committed in:** `a384b363`

**2. [Rule 1] `placeholderComp` rejected the `sState` initial property**
- **Issue:** `Pages.qml`'s `incubateObject(..., { sState: ... })` failed for any page still on `placeholderComp` (a bare `Item` with no `sState` property), breaking `openPage()` for three of the four groups.
- **Fix:** added `property var sState` to the placeholder.
- **Committed in:** `a384b363`

**3. [Rule 1] `SettingsSection` width collapsed to 81px — a genuine circular binding**
- **Found during:** First tracer checkpoint (operator-reported "visuals garbled")
- **Issue:** no explicit width on the outer `Column`; its own width derived from its children's max width, one of which (`contentColumn`) bound its width back to the parent's — measured live at 81px via a temporary diagnostic, just enough to fit the section header.
- **Fix:** `width: parent ? parent.width : implicitWidth`, breaking the cycle with the page's own concrete `bodyFlick.width`.
- **Committed in:** `5614e287`

**4. [Rule 1] Esc failed within ~150ms of window open — a one-shot `forceActiveFocus()` race**
- **Found during:** Second tracer checkpoint
- **Fix:** `Window.onActiveChanged` reactive re-focus instead of a single `Component.onCompleted` call.
- **Committed in:** `ff2dc558`

**5. [Rule 1] `hypr-overrides.sh` mode fallback drifted the persisted mode by a whole Hz on every scale-only edit**
- **Issue:** `refreshRate | floor` on `164.99899` produced `164`, not the true `165`, on every write that recomputed the full monitor spec (required since `hl.monitor()` takes no partial patch).
- **Fix:** `round` instead of `floor`.
- **Committed in:** `acc4e5b1`

**6. [Rule 1] Two independent `false`-is-falsy footguns silently dropped `natural_scroll = false`**
- **Issue:** Lua's `x and y or z` ternary AND jq's `//` alternative operator both treat `false` as "absent", so an explicit `natural_scroll = false` override reverted to `true` at read time (Lua) and vanished entirely at persist time (jq template).
- **Fix:** a real `if/then` conditional in Lua; `(.foo | type) != "null"` in jq.
- **Committed in:** `acc4e5b1`

**7. [Rule 2 — missing critical, security] `DisplayInputPage.qml` built shell commands via `bash -c` string concatenation with device-supplied monitor names**
- **Issue:** `hyprctl monitors -j`'s `.name` field is DEVICE-supplied (T-SQD-04), not this repo's own text — a crafted/malicious monitor name could have broken out of the `bash -c` string before `hypr-overrides.sh`'s own validation ever ran.
- **Fix:** rewrote both apply paths to pass every value as a discrete `Process.command` argv array element — no shell at all, matching this codebase's existing fixed-argv discipline (`PanelDialog.advancedCommand`).
- **Committed in:** `acc4e5b1`

**8. [Rule 1] `hypr-equivalence-check`'s VOLATILE_KEYS note was a Python `SyntaxError`**
- **Issue:** an f-string conversion specifier (`!r`) applied across an inline ternary (`{x!r if y else z}`) is invalid syntax.
- **Fix:** wrapped the ternary in parens first.
- **Committed in:** `acc4e5b1`

**9. [Rule 1] `lib/overrides.lua`'s header comment duplicated the plan's own gate-grepped literal string**
- **Issue:** the plan's Task 3 verify check D greps `pcall(require, "state.overrides")` with `-c 1` and no comment-stripping; the header comment restated the same literal, making the count 2.
- **Fix:** reworded the comment.
- **Committed in:** `acc4e5b1`

### Architectural response to operator direction (not a Rule 1-4 auto-fix — a directed course correction)

**10. HyprlandFocusGrab re-tried after an unfounded revert**
- **Found during:** Third tracer checkpoint
- **Issue:** the second tracer-checkpoint round had reverted `HyprlandFocusGrab` on a THEORIZED risk (that the Theme dropdown's `Menu` popup would trigger a false `onCleared`) without ever measuring it. The operator explicitly identified this as a discipline failure ("measure and do NOT theorize") and directed a proper re-test.
- **Resolution:** measured directly — a full `popup()`/`close()` cycle under an active grab produces zero false `onCleared` events, and the grab (once combined with the reactive `Window.onActiveChanged` re-focus) makes Esc survive a genuine `hl.dsp.focus`-driven steal, 12/12 clean trials.
- **Committed in:** `cce14214`

### Scope narrowing (documented, not silently absorbed)

**11. Connectivity page subtext is static, not a live backend read**
- Reading `audioBackendInstance`/`wifiBackendInstance`/`bluetoothBackendInstance` for a live one-line summary would require widening their `panelOpen`-gated polling the same way 15-07 widened it for the dashboard's Volume tile — judged out of proportion to a subtitle line. Recorded rather than done silently. Files: `ConnectivityPage.qml`.

**12. `idle-overrides.sh`'s ordering validation corrects a transposition in the plan's own prose**
- The plan states "dim < screen-off < lock < suspend"; the actual, correct, already-shipped timeouts are dim(300) < lock(600) < display-off(900) < suspend(1800) — screen-off and lock are transposed in the prose relative to reality. Validated against the real order; enforcing the literal wording would have rejected the repo's own defaults.

**13. Idle & lock "Advanced" NavRow inlines the `$EDITOR` launch rather than adding a new shim script**
- The plan's own Task 4 file list names no new script for this; `uwsm app -- kitty ... -- $EDITOR <path>` is a fixed argv `Process.command` array built directly in `ShellBehaviourPage.qml`, staying within the declared file list.

---

**Total deviations:** 9 auto-fixed bugs (Rule 1 ×8, Rule 2 ×1 — a real shell-injection vector, caught before ever running), 1 operator-directed course correction, 3 scope clarifications.
**Impact on plan:** No scope creep beyond what D-01/D-06 already required. The shell-injection fix (deviation 7) is the one genuinely security-relevant auto-fix; it was caught by code review before any live testing, never shipped or exercised in a vulnerable state.

## Issues Encountered

Four tracer-checkpoint rounds were required before Task 1 closed (see `.planning/quick/.../260820-sqd-CONTEXT.md`-adjacent conversation history for the full back-and-forth) — three genuine bug rounds (width collapse, Esc timing, focus retention/arrow-nav/click-outside) plus the operator's explicit correction on measurement discipline after round 2's unfounded `HyprlandFocusGrab` revert. Every fix that shipped was backed by a live, repeated (2×) measurement before being trusted; the ones that could not be measured on this host (real mouse clicks — no `ydotool`/`wlrctl`/Hyprland pointer-click dispatcher exists here) are recorded as such rather than claimed.

**Tooling gap, recorded for future work on this repo:** no tool on this host can synthesize a real mouse click. `wtype` is keyboard-only; `hl.dsp.cursor.move` (the only pointer primitive in this Lua bridge) does not drive Hyprland's focus system at all (measured 3×, including a warp squarely inside another window's bounds — zero effect on `hyprctl activewindow`). Click-driven UI paths (nav-rail clicks, dropdown pills, click-outside-dismiss) were verified end-to-end only via the operator's own live pass at each tracer checkpoint, never by this executor directly.

## Known Stubs

None. Every row routes through a real script/panel/singleton; no hardcoded empty state reaches the UI.

## User Setup Required

None — no external service configuration required. `stow.sh` seeds all new state-dir files (`overrides.lua`, `idle-overrides.conf`) automatically, only when absent.

## Outstanding — Task 4's human-check: CLOSED

**`.planning/WINDOWS.md` row 92 is closed.** The full ten-item human-check is green, reached after a nine-fix-wave post-plan live-pass saga (below) — every item the operator's own live pass could not be proxied for at plan time (visual re-colour correctness, correct-panel-opens, display/input-survives-theme-switch, motion/DND, idle timeout re-check including item 8's lock-lengthening, and item 9's reboot persistence) is now operator-confirmed PASS.

## Post-Plan Live-Pass Saga

The operator's real-hardware walkthrough surfaced defects this task's own testing (no synthetic mouse click, per the tooling-gap note above) could not reach. Nine fix waves followed, full detail in each commit message (`e1b041e0` through `c05d5aca`, plus the diagnostic-only `3844d35c`):

1. Dropdown theming (item 10), two dead launch rows (nwg-displays, editor), WR-03 refresh-rate rounding.
2. Left/Right arrows corrected from a wrong page-switch model to the operator's actual two-pane-focus spec; page-switch-lag re-check (left as measured-optimal); tab-reset-on-open.
3–5. Dropdown hover flicker chased across three rounds before the real cause surfaced: page ROWS (NavRow/ToggleRow/SliderRow/SelectRow), not the popup, and — once on the right element — a `surfaceVariant`-on-`surfaceVariant` pane made the fill invisible by construction.
6. Idle-row edits appeared to silently fail; root cause was a real, correct ordering-validation rejection with zero UI feedback, not a code bug — fixed with visible error surfacing.
7. Natural-scroll flash and idle-row "stays greyed out" both survived first fixes; root causes were an initial-load color animation racing a `Behavior`, and a missing watchdog on a Process that could hang without ever firing `onExited`.
8. Full INSTRUMENTATION-ONLY round (`3844d35c`) at the operator's explicit order, after two more fix attempts still didn't match their real interaction — `SQDDIAG`-prefixed logging on both remaining paths, then the operator's own reproduction resolved both from their trace.
9. Fixes landed straight from that trace (natural-scroll flash's exact animation-capture mechanism) plus an idle-row busy-spinner UX addition; instrumentation stripped once verified.

**Headline lessons:**
- **(a) Confirm which element a visual report names, with a screenshot, before fixing.** "Menu items" meant the page rows; three fix waves correctly diagnosed and fixed the dropdown POPUP instead, because that assumption was never checked against a picture.
- **(b) Verify visuals by pixel sampling, not role names.** Four separate controls (`NavRow`'s hover fill, `SelectRow`'s dropdown pill, `ToggleRow`'s switch OFF-state, `SliderRow`'s track) were painting `Colours.surfaceVariant` on a `Colours.surfaceVariant` pane — invisible by construction, and invisible to every non-visual check that ran clean.
- **(c) A test that injects below the UI layer, or exercises only the convenient value, verifies plumbing, not product.** Calling a row's own signal directly with hand-picked values proved the write path worked; it did not prove the operator's actual click-then-pick sequence did, and one round's "fix" was verified against a value that happened not to trigger the real bug.
- **(d) The two endgame diagnoses came from instrumenting and letting the OPERATOR reproduce, not from synthetic trials.** After every direct reproduction attempt on this host converged on "works for me," the SQDDIAG round replaced guessing with the operator's own trace as ground truth.
- **(e) Two named follow-ups, deliberately deferred rather than fixed in-band:** `colour-lint` has a measured blind spot for a default-styled QQC2 popup carrying zero in-repo color literals while still showing foreign (system-palette) colors — the gate cannot currently catch this class; and the deployment-order trap this saga hit repeatedly — a settings PAGE can keep serving a stale compiled `Component` across a plain hot-reload (`PageCompRegistry`'s per-page indirection), so verifying or re-checking a page-level fix needs a full `systemctl --user restart quickshell.service`, not just a re-navigate.

## Next Phase Readiness

The settings window is feature-complete against D-01, code-gate-verified across every fix wave (final gate state: colour-lint 182/0, motion-lint 333/0, keybind-doctor 14/0, quickshell-doctor --self-test 59/0, hypr-equivalence-check 3/0), and the operator's full ten-item live pass is green. No blockers remain for closing this quick task.

Named follow-ups this task deliberately did not build (F-01 through F-06 in the plan's own `<decision_ids>` section) remain deferred, not dropped — settings fuzzy search, per-device keyboard/mouse config, `StackPage` drill-down, deep-linking the nine existing walker rows, and the fastfetch logo picker.

## Self-Check: PASSED

All 7 claimed commit hashes found in `git log --oneline --all`. All 6 spot-checked claimed files (`Settings.qml`, `DisplayInputPage.qml`, `hypr-overrides.sh`, `lib/overrides.lua`, `idle-overrides.sh`, this SUMMARY itself) confirmed present on disk.

---
*Quick task: 260820-sqd*
*Completed: 2026-08-20*
