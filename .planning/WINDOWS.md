---
schema_version: 1
open_count: 15
waived_count: 0
fixed_count: 7
total_count: 22
last_updated: 2026-08-02T02:40:14.524Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 09 | unrun-verify | theme-engine/.config/theme-engine/contract.json |  | theme-doctor/theme-stress-test blocked by orphaned eww.scss entry (phase 08-06/10-06 incomplete retirement) — unrelated to wlogout->wleave, see 09-02 deferred-items.md item 3 | fixed |  | 2026-07-25T16:10:45.874Z | 2026-07-27T22:02:08.027Z |
| 2 | 09 | deviation | hypr/.config/hypr/scripts/keybind-doctor |  | keybind-doctor's hyprctl binds -j JSON parsing broken on Hyprland 0.56.0 (pre-existing, all 78 binds affected uniformly) — see 09-02 deferred-items.md item 1 | fixed |  | 2026-07-25T16:10:45.954Z | 2026-07-27T22:02:08.105Z |
| 3 | 09 | unrun-verify | wleave/.config/wleave/style.css |  | D-10 entrance-vs-hover interaction (hovering during the ~350ms entrance stagger window) was not exercised live in this session — tooling available (hyprctl dispatch movecursor / wtype) could not reliably land a synthetic pointer/focus event inside that short window. Structural mitigation (entrance transform on the base rule, hover/focus scale on a separate paired selector, animation-fill-mode:backwards) is in place per plan, but not confirmed by a live capture. | open |  | 2026-07-25T16:49:50.384Z |  |
| 4 | 09 | deviation | .planning/phases/09-wlogout-to-wleave-migration/09-03-SUMMARY.md |  | 09-03 hover evidence (09-03-hover-dark.png) was captured via keyboard focus (wtype Tab), not literal mouse hover — hyprctl dispatch movecursor warps the compositor cursor position without emitting a wl_pointer motion/enter event this GTK4 client processes, confirmed by a live jiggle test that produced no :hover activation despite a correct hyprctl cursorpos. Since :hover and :focus are byte-identical paired CSS selectors in this stylesheet, the focus-driven capture proves the same code path, but the specific input modality (real mouse hover) remains unconfirmed live. | open |  | 2026-07-25T16:49:50.463Z |  |
| 5 | 09 | deviation | wleave/.config/wleave/layout.json |  | Icon glyph size is the SVG's natural/shrink-fit size under the icon+label vertical stack (empirically ~27-29px at the tuned margin), not forced to the UI-SPEC's literal 36px Display-role token — that token assumed the retired text-glyph delivery mechanism. Visually consistent and legible per the 09-03 evidence captures; not explicitly re-pinned to a fixed pixel size. | open |  | 2026-07-25T16:49:50.541Z |  |
| 6 | 09 | deviation | hypr/.config/hypr/scripts/wleave.sh |  | Fault-injection test (09-04): moving ~/.config/wleave/layout.json aside does NOT trigger the wrapper's launch-failure notify-send. wleave has its own packaged config fallback chain and silently loads /etc/wleave/layout.json (a large unstyled 3x2 grid, version-info footer visible) instead. This is not a silently-empty scrim (satisfies the UI-Consideration-1 backstop's core requirement) but it is a third, unenumerated outcome the wrapper script's command -v/kill -0 guards do not cover — wleave.sh has no check that the user's own layout.json exists. Not fixed in 09-04 (file not in this plan's declared files_modified); flagged for future triage. | open |  | 2026-07-25T17:10:45.472Z |  |
| 7 | 09 | deviation | hypr/.config/hypr/hyprlock.conf |  | hyprlock crashed (SIGABRT) during 09-04 human render-gate testing of the lock action. Almost certainly independent of this phase: the only hyprlock coredumps on this machine are dated 2026-04-02 and 2026-07-12 (five SIGABRTs), none from the 2026-07-25 session; the lock action string (uwsm app -- hyprlock) is byte-identical to the Phase-4-audited string, unchanged by this phase; and the human independently confirmed lock working earlier in the same gate. Logged for separate triage, not chased in this phase. | open |  | 2026-07-25T18:53:00.893Z |  |
| 8 | 12 | deviation | hypr/.config/hypr/config/animations.conf |  | Plan 12-04's acceptance criterion expected 'animation = ' count of 14; live file has 13 (pre-existing, unchanged by this plan; D-04 fence proven intact via before/after count equality) | fixed |  | 2026-07-26T20:29:08.850Z | 2026-07-27T22:02:08.186Z |
| 9 | 12 | unrun-verify | theme-engine/.config/theme-engine/theme-stress-test |  | 12-06's D-17 live re-colour assertion could not be exercised via the REAL, committed theme-stress-test in the dev session: its per-switch theme-doctor gate (D-66, strict exit 0) always fails on the pre-existing, out-of-scope untracked vscodium desktop file (documented in deferred-items.md / STATE.md, predates Phase 12). D-17's own assertions (live re-colour match + PID-unchanged) WERE fully proven via a scratch-patched, never-committed copy of the identical script that bypassed only that one pre-existing check: a complete 10/10-switch run passed with zero failures (162 passed, 0 failed), the quickshell PID never changed across all 10 rsync-based palette.json replacements, and every switch's rendered Colours.primary matched the freshly-rendered palette.json. UPDATED 2026-07-27 (Phase 12 close): the untracked vscodium file was resolved by `604368e`, and the REAL committed theme-stress-test was then re-run end-to-end. It did NOT pass identically — the 'expected to pass identically' prediction above was WRONG, and the scratch-copy proof was weaker than it appeared precisely because it bypassed this check. Switches 1-4 passed in full (including every D-17 live re-colour assertion and PID-unchanged check, against the real script this time). Switch #5 ('dracula') FAILED the D-66 strict theme-doctor gate. ROOT CAUSE (pre-existing Phase 03 debt, NOT a Phase 12 regression): `lib/wallpaper.sh:65` repoints `wallpapers/Pictures/Wallpapers/current.jpg` via `ln -sfr` on every STATIC theme switch; that symlink is TRACKED in git (committed target `catppuccin/5-alien-planet.jpg`); and theme-doctor asserts `git status --porcelain` is empty (invariant added in 90f73c2, phase 03-03) while theme-stress-test requires a strict theme-doctor pass after EVERY switch (1a4ce30, phase 03-03). So any switch to a static theme whose wallpaper differs from the committed target dirties a tracked file and fails the gate. Confirmed by mechanism: switching back to `catppuccin` restored the symlink and the tree went clean again. CONSEQUENCE: the committed theme-stress-test can never reach 10/10 while its sequence contains a static theme with a non-committed wallpaper — this is structural, not environmental. Material You themes are unaffected (wallpaper.sh explicitly never touches current.jpg for those). FIX OPTIONS (deferred to Phase 13, the designated existing-surface sweep, per user decision at Phase 12 close): (a) untrack current.jpg (`git rm --cached` + gitignore) AND add fresh-install seeding to stow.sh — note current.jpg is NOT currently seeded by stow.sh/install.sh, so a fresh machine depends on the tracked symlink existing; or (b) narrowly exempt that one path from theme-doctor's clean-tree check as runtime state. Phase 12 itself is unaffected: criterion 1's live re-colour is independently confirmed by the 12-06 D-27 human render gate AND by switches 1-4 of this real run. | fixed |  | 2026-07-26T21:50:46.937Z | 2026-07-27T22:34:56.419Z |
| 10 | 13 | deviation | hypr/.config/hypr/config/animations.conf |  | D-06 boundary correction: layer-surface exits (walker/swaync/wleave) are client-owned, not compositor-owned; Check 3's original render-gate method had no valid instrument, closed on mechanical proof instead (13-01-SUMMARY.md) | open |  | 2026-07-27T03:43:43.806Z |  |
| 11 | 13.1 | deviation | hypr/.config/hypr/config/windowrules.lua |  | hl.window_rule size field's percentage form (85% 85% / 70% 65%) registers with zero configerrors but has no runtime effect on installed Hyprland 0.56.1 Lua config manager; affects 6/30 rules (5 pickers + yazi-fm); see COVERAGE.md 'Window-rule size field' section and 13.1-07-SUMMARY.md | fixed | Operator directly confirmed on 2026-07-28 ("my window rules are in order") that all 6 affected windows (wallpaper-picker, icon-theme-picker, font-switcher, network-manager, cheat-sheet, yazi-fm) size correctly on the live Lua session in practice, despite the mechanically-proven zero-configerror size percentage-form no-op found in 13.1-07. No code change made — windowrules.lua's size strings are left byte-identical, per operator instruction. See COVERAGE.md 'Window-rule size field' section, operator-confirmation addendum. | 2026-07-28T04:47:47.278Z | 2026-07-28T17:16:00.000Z |
| 12 | 13.1 | deviation | hypr/.config/hypr/scripts/gaming-mode-toggle.sh |  | hyprctl keyword is a silent no-op on the Lua-config compositor (exit 0, no effect) - breaks gaming-mode-toggle's eye-candy on/off calls; see deferred-items.md item 1 | fixed |  | 2026-07-28T10:25:31.641Z | 2026-07-28T12:14:49.536Z |
| 13 | 13.1 | deviation | hypr/.config/hypr/hypridle.conf |  | 13.1-09's consumer-retarget sweep was INCOMPLETE. That plan correctly identified the Lua-cutover dispatch break and fixed theme-engine/.config/theme-engine/theme-stress-test (lines 368/571, hl.dsp.global form), but it did not sweep the rest of the repo for the same pattern — it left 7 further legacy 'hyprctl dispatch <string>' call sites dead, plus ~8 more in quickshell-doctor (logged separately). Missed sites, all silently no-op under the Lua config manager (the compositor wraps the payload into 'return hl.dispatch(<payload>)' and evaluates it as Lua SOURCE, which is a parse error): hypridle.conf after_sleep_cmd/on-timeout(900)/on-resume(900) — the 15-minute display blank AND its resume were both dead; ai-workspace.sh:58 and ai-webapp-launch.sh:28 ('workspace name:ai' — the latter broke the switch-then-launch ordering the whole script depends on, so Zen AI windows were landing on the wrong workspace); config-floating.jsonc:98-99 waybar scroll. All 7 retargeted and verified 2026-07-28 in debug session waybar-workspace-click-dead. LESSON: 13.1-09 fixed the site it tripped over rather than grepping the repo for the pattern class; a 'hyprctl dispatch' grep would have caught all 15 at once. SHARPEST FORM OF THIS, confirmed from git history: commit e82f2bd (13.1-09) MODIFIED ai-webapp-launch.sh in that very commit — a comment-only edit repointing windowrules.conf to windowrules.lua — while the broken 'hyprctl dispatch workspace name:ai' sat two lines below the edited hunk; and THAT SAME COMMIT separately fixed the identical bug class in theme-stress-test as a declared 'Rule 3 blocking-issue fix'. So the pattern was recognised, fixed where it blocked the plan's own verification, and not generalised — not even within a file the plan was actively editing. The generalisable guard is a repo-wide grep for the withdrawn API whenever one instance of it is fixed. NOTE the dpms sites were NOT a mechanical transliteration — see that debug session: hl.dsp.dpms('on') is NOT 'turn on', the bare-string arg is ignored entirely and falls through to the eTogglableAction zero-default TOGGLE; only the table form {action=...} works, and under toggle semantics on-resume would have blanked the display on every wake. | fixed |  | 2026-07-28T13:12:15.497Z | 2026-07-28T13:12:39.733Z |
| 14 | 13.1 | deviation | hypr/.config/hypr/scripts/quickshell-doctor |  | ~8 legacy 'hyprctl dispatch global <name>' call sites still on the withdrawn string form and therefore silently dead under the Lua config manager (same mechanism as WINDOWS #13). Missed by 13.1-09's sweep. DELIBERATELY DEFERRED by operator decision on 2026-07-28 when selecting Branch C in debug session waybar-workspace-click-dead: the operator chose plain C over 'C + quickshell-doctor', so this was left untouched rather than overlooked. Fix is mechanical and already patterned in-repo: 'hyprctl dispatch \\'hl.dsp.global("<name>")\\'' (see theme-stress-test:368/571). CAUTION when picking this up: quickshell-doctor must NOT be run casually to test the change — its headless-output add/remove test previously SEGV-crashed this compositor during a DP-1 hotplug. | open |  | 2026-07-28T13:12:31.315Z |  |
| 15 | 13.1 | deviation | waybar/.config/waybar/config-floating.jsonc |  | ACCEPTED DEBT, NOT A BUG TO FIX HERE: waybar 0.15.0-2's hyprland/workspaces CLICK is permanently dead on the Lua-config compositor and is unreachable from config. The legacy dispatch strings ('dispatch workspace <id>', 'dispatch workspace name:', 'dispatch focusworkspaceoncurrentmonitor', 'dispatch togglespecialworkspace') are compiled into Workspace::handleClicked and the IPC error reply is discarded; 'man 5 waybar-hyprland-workspaces' documents no on-click key for this module, and the payloads are Lua SYNTAX errors so no Lua-side shim/metatable can rescue them. Upstream Waybar PR #5013 fixes it but postdates the 0.15.0 release, so no shipped Arch package carries it (refs: Waybar #5008/#5035, Hyprland discussion #14255). Operator rejected both upgrading to waybar-git (throwaway -git package in install.sh's reproducible path) and rolling back to hyprlang (would undo an equivalence-proven migration). RESOLUTION PATH: dies with waybar at the Quickshell cutover — Quickshell's QML uses the GlobalShortcut Wayland protocol and contains zero IPC dispatch string sites, so the bug class is removed structurally. The SCROLL handlers in this same file WERE fixable (config strings, not compiled in) and were fixed 2026-07-28. The inert 'on-click: activate' key is retained with an explanatory comment. | open |  | 2026-07-28T13:12:31.415Z |  |
| 16 | 13.1 | deviation | hypr/.config/hypr/scripts/ai-webapp-launch.sh |  | WR-04 (13.1-REVIEW.md): the workspace-switch dispatch (`hyprctl dispatch 'hl.dsp.focus({workspace="name:ai"})'`) is `\|\| true`-guarded, silently discarding any failure of the one mechanism the script's own header says is the ONLY way to correctly place a Zen AI web-app window on `name:ai` — a failed switch lets the browser launch on whatever workspace is currently active with no error surfaced. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05). | open |  | 2026-07-28T17:16:00.000Z |  |
| 17 | 13.1 | deviation | hypr/.config/hypr/scripts/ai-workspace.sh |  | WR-05 (13.1-REVIEW.md): the idempotency check's PRESENT comma-joined class list is tested with bash substring matching ([[ "$PRESENT" != *"$CLAUDE_CODE_CLASS"* ]]), not delimiter-aware exact matching — a window class that merely CONTAINS ai-claude-code/ai-local-models as a substring produces a false "already present" match and silently skips the launch, violating D-24 idempotency. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05). | open |  | 2026-07-28T17:16:00.000Z |  |
| 18 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml |  | 15-05 Task 3: full password-connect, in-flight Cancel, real failure, and Forget-confirm proofs not run live — host has no synthetic pointer-input tool (15-API-PROBE Open Q2) and no real wifi passphrase was available; only single-press Escape-dismiss with nothing expanded was proven live | open |  | 2026-08-02T01:58:16.101Z |  |
| 19 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml |  | 15-06 Task 3: pairing failure, cancel-not-failure, connect failure/recovery, watchdog-fire, press-guard, adjacency, and all chevron/verb/Forget click proofs not run live — host has zero paired devices, zero discoverable peers within range (8s live scan empty), and no synthetic pointer-input tool; only the empty-state render and discovery's reactive/lifecycle-teardown-firing paths were proven live | open |  | 2026-08-02T02:21:50.326Z |  |
| 20 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | Chevron/tile-body click paths not literally exercised — no synthetic pointer tool on host; guarded summon function proven via IPC equivalent instead | open |  | 2026-08-02T02:40:09.329Z |  |
| 21 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | E6 error-contract fault injection (rfkill-blocked toggle reverting to truth) not cleanly reproduced live — NetworkManager software radio switch succeeded independent of rfkill state; source-verified mechanism only | open |  | 2026-08-02T02:40:14.434Z |  |
| 22 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | Bluetooth tile external-toggle live-truth proof not run — session's rfkill soft-blocked bluetooth state intentionally left untouched per non-negotiable rule 3 | open |  | 2026-08-02T02:40:14.524Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "09",
    "file": "theme-engine/.config/theme-engine/contract.json",
    "line": null,
    "description": "theme-doctor/theme-stress-test blocked by orphaned eww.scss entry (phase 08-06/10-06 incomplete retirement) — unrelated to wlogout->wleave, see 09-02 deferred-items.md item 3",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-25T16:10:45.874Z",
    "resolved_at": "2026-07-27T22:02:08.027Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "09",
    "file": "hypr/.config/hypr/scripts/keybind-doctor",
    "line": null,
    "description": "keybind-doctor's hyprctl binds -j JSON parsing broken on Hyprland 0.56.0 (pre-existing, all 78 binds affected uniformly) — see 09-02 deferred-items.md item 1",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-25T16:10:45.954Z",
    "resolved_at": "2026-07-27T22:02:08.105Z"
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "09",
    "file": "wleave/.config/wleave/style.css",
    "line": null,
    "description": "D-10 entrance-vs-hover interaction (hovering during the ~350ms entrance stagger window) was not exercised live in this session — tooling available (hyprctl dispatch movecursor / wtype) could not reliably land a synthetic pointer/focus event inside that short window. Structural mitigation (entrance transform on the base rule, hover/focus scale on a separate paired selector, animation-fill-mode:backwards) is in place per plan, but not confirmed by a live capture.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:49:50.384Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "09",
    "file": ".planning/phases/09-wlogout-to-wleave-migration/09-03-SUMMARY.md",
    "line": null,
    "description": "09-03 hover evidence (09-03-hover-dark.png) was captured via keyboard focus (wtype Tab), not literal mouse hover — hyprctl dispatch movecursor warps the compositor cursor position without emitting a wl_pointer motion/enter event this GTK4 client processes, confirmed by a live jiggle test that produced no :hover activation despite a correct hyprctl cursorpos. Since :hover and :focus are byte-identical paired CSS selectors in this stylesheet, the focus-driven capture proves the same code path, but the specific input modality (real mouse hover) remains unconfirmed live.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:49:50.463Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "09",
    "file": "wleave/.config/wleave/layout.json",
    "line": null,
    "description": "Icon glyph size is the SVG's natural/shrink-fit size under the icon+label vertical stack (empirically ~27-29px at the tuned margin), not forced to the UI-SPEC's literal 36px Display-role token — that token assumed the retired text-glyph delivery mechanism. Visually consistent and legible per the 09-03 evidence captures; not explicitly re-pinned to a fixed pixel size.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:49:50.541Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "09",
    "file": "hypr/.config/hypr/scripts/wleave.sh",
    "line": null,
    "description": "Fault-injection test (09-04): moving ~/.config/wleave/layout.json aside does NOT trigger the wrapper's launch-failure notify-send. wleave has its own packaged config fallback chain and silently loads /etc/wleave/layout.json (a large unstyled 3x2 grid, version-info footer visible) instead. This is not a silently-empty scrim (satisfies the UI-Consideration-1 backstop's core requirement) but it is a third, unenumerated outcome the wrapper script's command -v/kill -0 guards do not cover — wleave.sh has no check that the user's own layout.json exists. Not fixed in 09-04 (file not in this plan's declared files_modified); flagged for future triage.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T17:10:45.472Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "09",
    "file": "hypr/.config/hypr/hyprlock.conf",
    "line": null,
    "description": "hyprlock crashed (SIGABRT) during 09-04 human render-gate testing of the lock action. Almost certainly independent of this phase: the only hyprlock coredumps on this machine are dated 2026-04-02 and 2026-07-12 (five SIGABRTs), none from the 2026-07-25 session; the lock action string (uwsm app -- hyprlock) is byte-identical to the Phase-4-audited string, unchanged by this phase; and the human independently confirmed lock working earlier in the same gate. Logged for separate triage, not chased in this phase.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T18:53:00.893Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "12",
    "file": "hypr/.config/hypr/config/animations.conf",
    "line": null,
    "description": "Plan 12-04's acceptance criterion expected 'animation = ' count of 14; live file has 13 (pre-existing, unchanged by this plan; D-04 fence proven intact via before/after count equality)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-26T20:29:08.850Z",
    "resolved_at": "2026-07-27T22:02:08.186Z"
  },
  {
    "id": 9,
    "kind": "unrun-verify",
    "phase": "12",
    "file": "theme-engine/.config/theme-engine/theme-stress-test",
    "line": null,
    "description": "12-06's D-17 live re-colour assertion could not be exercised via the REAL, committed theme-stress-test in the dev session: its per-switch theme-doctor gate (D-66, strict exit 0) always fails on the pre-existing, out-of-scope untracked vscodium desktop file (documented in deferred-items.md / STATE.md, predates Phase 12). D-17's own assertions (live re-colour match + PID-unchanged) WERE fully proven via a scratch-patched, never-committed copy of the identical script that bypassed only that one pre-existing check: a complete 10/10-switch run passed with zero failures (162 passed, 0 failed), the quickshell PID never changed across all 10 rsync-based palette.json replacements, and every switch's rendered Colours.primary matched the freshly-rendered palette.json. UPDATED 2026-07-27 (Phase 12 close): the untracked vscodium file was resolved by `604368e`, and the REAL committed theme-stress-test was then re-run end-to-end. It did NOT pass identically — the 'expected to pass identically' prediction above was WRONG, and the scratch-copy proof was weaker than it appeared precisely because it bypassed this check. Switches 1-4 passed in full (including every D-17 live re-colour assertion and PID-unchanged check, against the real script this time). Switch #5 ('dracula') FAILED the D-66 strict theme-doctor gate. ROOT CAUSE (pre-existing Phase 03 debt, NOT a Phase 12 regression): `lib/wallpaper.sh:65` repoints `wallpapers/Pictures/Wallpapers/current.jpg` via `ln -sfr` on every STATIC theme switch; that symlink is TRACKED in git (committed target `catppuccin/5-alien-planet.jpg`); and theme-doctor asserts `git status --porcelain` is empty (invariant added in 90f73c2, phase 03-03) while theme-stress-test requires a strict theme-doctor pass after EVERY switch (1a4ce30, phase 03-03). So any switch to a static theme whose wallpaper differs from the committed target dirties a tracked file and fails the gate. Confirmed by mechanism: switching back to `catppuccin` restored the symlink and the tree went clean again. CONSEQUENCE: the committed theme-stress-test can never reach 10/10 while its sequence contains a static theme with a non-committed wallpaper — this is structural, not environmental. Material You themes are unaffected (wallpaper.sh explicitly never touches current.jpg for those). FIX OPTIONS (deferred to Phase 13, the designated existing-surface sweep, per user decision at Phase 12 close): (a) untrack current.jpg (`git rm --cached` + gitignore) AND add fresh-install seeding to stow.sh — note current.jpg is NOT currently seeded by stow.sh/install.sh, so a fresh machine depends on the tracked symlink existing; or (b) narrowly exempt that one path from theme-doctor's clean-tree check as runtime state. Phase 12 itself is unaffected: criterion 1's live re-colour is independently confirmed by the 12-06 D-27 human render gate AND by switches 1-4 of this real run.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-26T21:50:46.937Z",
    "resolved_at": "2026-07-27T22:34:56.419Z"
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "13",
    "file": "hypr/.config/hypr/config/animations.conf",
    "line": null,
    "description": "D-06 boundary correction: layer-surface exits (walker/swaync/wleave) are client-owned, not compositor-owned; Check 3's original render-gate method had no valid instrument, closed on mechanical proof instead (13-01-SUMMARY.md)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T03:43:43.806Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "13.1",
    "file": "hypr/.config/hypr/config/windowrules.lua",
    "line": null,
    "description": "hl.window_rule size field's percentage form (85% 85% / 70% 65%) registers with zero configerrors but has no runtime effect on installed Hyprland 0.56.1 Lua config manager; affects 6/30 rules (5 pickers + yazi-fm); see COVERAGE.md 'Window-rule size field' section and 13.1-07-SUMMARY.md",
    "status": "fixed",
    "reason": "Operator directly confirmed on 2026-07-28 (\"my window rules are in order\") that all 6 affected windows (wallpaper-picker, icon-theme-picker, font-switcher, network-manager, cheat-sheet, yazi-fm) size correctly on the live Lua session in practice, despite the mechanically-proven zero-configerror size percentage-form no-op found in 13.1-07. No code change made — windowrules.lua's size strings are left byte-identical, per operator instruction. See COVERAGE.md 'Window-rule size field' section, operator-confirmation addendum.",
    "recorded_at": "2026-07-28T04:47:47.278Z",
    "resolved_at": "2026-07-28T17:16:00.000Z"
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "13.1",
    "file": "hypr/.config/hypr/scripts/gaming-mode-toggle.sh",
    "line": null,
    "description": "hyprctl keyword is a silent no-op on the Lua-config compositor (exit 0, no effect) - breaks gaming-mode-toggle's eye-candy on/off calls; see deferred-items.md item 1",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-28T10:25:31.641Z",
    "resolved_at": "2026-07-28T12:14:49.536Z"
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "13.1",
    "file": "hypr/.config/hypr/hypridle.conf",
    "line": null,
    "description": "13.1-09's consumer-retarget sweep was INCOMPLETE. That plan correctly identified the Lua-cutover dispatch break and fixed theme-engine/.config/theme-engine/theme-stress-test (lines 368/571, hl.dsp.global form), but it did not sweep the rest of the repo for the same pattern — it left 7 further legacy 'hyprctl dispatch <string>' call sites dead, plus ~8 more in quickshell-doctor (logged separately). Missed sites, all silently no-op under the Lua config manager (the compositor wraps the payload into 'return hl.dispatch(<payload>)' and evaluates it as Lua SOURCE, which is a parse error): hypridle.conf after_sleep_cmd/on-timeout(900)/on-resume(900) — the 15-minute display blank AND its resume were both dead; ai-workspace.sh:58 and ai-webapp-launch.sh:28 ('workspace name:ai' — the latter broke the switch-then-launch ordering the whole script depends on, so Zen AI windows were landing on the wrong workspace); config-floating.jsonc:98-99 waybar scroll. All 7 retargeted and verified 2026-07-28 in debug session waybar-workspace-click-dead. LESSON: 13.1-09 fixed the site it tripped over rather than grepping the repo for the pattern class; a 'hyprctl dispatch' grep would have caught all 15 at once. SHARPEST FORM OF THIS, confirmed from git history: commit e82f2bd (13.1-09) MODIFIED ai-webapp-launch.sh in that very commit — a comment-only edit repointing windowrules.conf to windowrules.lua — while the broken 'hyprctl dispatch workspace name:ai' sat two lines below the edited hunk; and THAT SAME COMMIT separately fixed the identical bug class in theme-stress-test as a declared 'Rule 3 blocking-issue fix'. So the pattern was recognised, fixed where it blocked the plan's own verification, and not generalised — not even within a file the plan was actively editing. The generalisable guard is a repo-wide grep for the withdrawn API whenever one instance of it is fixed. NOTE the dpms sites were NOT a mechanical transliteration — see that debug session: hl.dsp.dpms('on') is NOT 'turn on', the bare-string arg is ignored entirely and falls through to the eTogglableAction zero-default TOGGLE; only the table form {action=...} works, and under toggle semantics on-resume would have blanked the display on every wake.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-28T13:12:15.497Z",
    "resolved_at": "2026-07-28T13:12:39.733Z"
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "13.1",
    "file": "hypr/.config/hypr/scripts/quickshell-doctor",
    "line": null,
    "description": "~8 legacy 'hyprctl dispatch global <name>' call sites still on the withdrawn string form and therefore silently dead under the Lua config manager (same mechanism as WINDOWS #13). Missed by 13.1-09's sweep. DELIBERATELY DEFERRED by operator decision on 2026-07-28 when selecting Branch C in debug session waybar-workspace-click-dead: the operator chose plain C over 'C + quickshell-doctor', so this was left untouched rather than overlooked. Fix is mechanical and already patterned in-repo: 'hyprctl dispatch \\'hl.dsp.global(\"<name>\")\\'' (see theme-stress-test:368/571). CAUTION when picking this up: quickshell-doctor must NOT be run casually to test the change — its headless-output add/remove test previously SEGV-crashed this compositor during a DP-1 hotplug.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T13:12:31.315Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "13.1",
    "file": "waybar/.config/waybar/config-floating.jsonc",
    "line": null,
    "description": "ACCEPTED DEBT, NOT A BUG TO FIX HERE: waybar 0.15.0-2's hyprland/workspaces CLICK is permanently dead on the Lua-config compositor and is unreachable from config. The legacy dispatch strings ('dispatch workspace <id>', 'dispatch workspace name:', 'dispatch focusworkspaceoncurrentmonitor', 'dispatch togglespecialworkspace') are compiled into Workspace::handleClicked and the IPC error reply is discarded; 'man 5 waybar-hyprland-workspaces' documents no on-click key for this module, and the payloads are Lua SYNTAX errors so no Lua-side shim/metatable can rescue them. Upstream Waybar PR #5013 fixes it but postdates the 0.15.0 release, so no shipped Arch package carries it (refs: Waybar #5008/#5035, Hyprland discussion #14255). Operator rejected both upgrading to waybar-git (throwaway -git package in install.sh's reproducible path) and rolling back to hyprlang (would undo an equivalence-proven migration). RESOLUTION PATH: dies with waybar at the Quickshell cutover — Quickshell's QML uses the GlobalShortcut Wayland protocol and contains zero IPC dispatch string sites, so the bug class is removed structurally. The SCROLL handlers in this same file WERE fixable (config strings, not compiled in) and were fixed 2026-07-28. The inert 'on-click: activate' key is retained with an explanatory comment.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T13:12:31.415Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "13.1",
    "file": "hypr/.config/hypr/scripts/ai-webapp-launch.sh",
    "line": null,
    "description": "WR-04 (13.1-REVIEW.md): the workspace-switch dispatch (`hyprctl dispatch 'hl.dsp.focus({workspace=\"name:ai\"})'`) is `|| true`-guarded, silently discarding any failure of the one mechanism the script's own header says is the ONLY way to correctly place a Zen AI web-app window on `name:ai` — a failed switch lets the browser launch on whatever workspace is currently active with no error surfaced. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T17:16:00.000Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "13.1",
    "file": "hypr/.config/hypr/scripts/ai-workspace.sh",
    "line": null,
    "description": "WR-05 (13.1-REVIEW.md): the idempotency check's PRESENT comma-joined class list is tested with bash substring matching ([[ \"$PRESENT\" != *\"$CLAUDE_CODE_CLASS\"* ]]), not delimiter-aware exact matching — a window class that merely CONTAINS ai-claude-code/ai-local-models as a substring produces a false \"already present\" match and silently skips the launch, violating D-24 idempotency. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T17:16:00.000Z",
    "resolved_at": null
  },
  {
    "id": 18,
    "kind": "unrun-verify",
    "phase": "15",
    "file": "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml",
    "line": null,
    "description": "15-05 Task 3: full password-connect, in-flight Cancel, real failure, and Forget-confirm proofs not run live — host has no synthetic pointer-input tool (15-API-PROBE Open Q2) and no real wifi passphrase was available; only single-press Escape-dismiss with nothing expanded was proven live",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T01:58:16.101Z",
    "resolved_at": null
  },
  {
    "id": 19,
    "kind": "unrun-verify",
    "phase": "15",
    "file": "quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml",
    "line": null,
    "description": "15-06 Task 3: pairing failure, cancel-not-failure, connect failure/recovery, watchdog-fire, press-guard, adjacency, and all chevron/verb/Forget click proofs not run live — host has zero paired devices, zero discoverable peers within range (8s live scan empty), and no synthetic pointer-input tool; only the empty-state render and discovery's reactive/lifecycle-teardown-firing paths were proven live",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T02:21:50.326Z",
    "resolved_at": null
  },
  {
    "id": 20,
    "kind": "unrun-verify",
    "phase": "15",
    "file": "quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml",
    "line": null,
    "description": "Chevron/tile-body click paths not literally exercised — no synthetic pointer tool on host; guarded summon function proven via IPC equivalent instead",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T02:40:09.329Z",
    "resolved_at": null
  },
  {
    "id": 21,
    "kind": "unrun-verify",
    "phase": "15",
    "file": "quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml",
    "line": null,
    "description": "E6 error-contract fault injection (rfkill-blocked toggle reverting to truth) not cleanly reproduced live — NetworkManager software radio switch succeeded independent of rfkill state; source-verified mechanism only",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T02:40:14.434Z",
    "resolved_at": null
  },
  {
    "id": 22,
    "kind": "unrun-verify",
    "phase": "15",
    "file": "quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml",
    "line": null,
    "description": "Bluetooth tile external-toggle live-truth proof not run — session's rfkill soft-blocked bluetooth state intentionally left untouched per non-negotiable rule 3",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T02:40:14.524Z",
    "resolved_at": null
  }
]
````
