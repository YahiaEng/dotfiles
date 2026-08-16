---
schema_version: 1
open_count: 54
waived_count: 2
fixed_count: 27
total_count: 83
last_updated: 2026-08-16T04:51:35.665Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 09 | unrun-verify | theme-engine/.config/theme-engine/contract.json |  | theme-doctor/theme-stress-test blocked by orphaned eww.scss entry (phase 08-06/10-06 incomplete retirement) — unrelated to wlogout->wleave, see 09-02 deferred-items.md item 3 | fixed |  | 2026-07-25T16:10:45.874Z | 2026-07-27T22:02:08.027Z |
| 2 | 09 | deviation | hypr/.config/hypr/scripts/keybind-doctor |  | keybind-doctor's hyprctl binds -j JSON parsing broken on Hyprland 0.56.0 (pre-existing, all 78 binds affected uniformly) — see 09-02 deferred-items.md item 1 | fixed |  | 2026-07-25T16:10:45.954Z | 2026-07-27T22:02:08.105Z |
| 3 | 09 | unrun-verify | wleave/.config/wleave/style.css |  | D-10 entrance-vs-hover interaction (hovering during the ~350ms entrance stagger window) was not exercised live in this session — tooling available (hyprctl dispatch movecursor / wtype) could not reliably land a synthetic pointer/focus event inside that short window. Structural mitigation (entrance transform on the base rule, hover/focus scale on a separate paired selector, animation-fill-mode:backwards) is in place per plan, but not confirmed by a live capture. | open | RE-DEFERRED (LEDGER-05, 20-02): the underlying race (hover during entrance stagger) is not artefact-specific — the replacement power grid's entrance cascade (D-20-36) is also not serialised against input readiness. Owner: plan 20-08's Gate B. | 2026-07-25T16:49:50.384Z |  |
| 4 | 09 | deviation | .planning/phases/09-wlogout-to-wleave-migration/09-03-SUMMARY.md |  | 09-03 hover evidence (09-03-hover-dark.png) was captured via keyboard focus (wtype Tab), not literal mouse hover — hyprctl dispatch movecursor warps the compositor cursor position without emitting a wl_pointer motion/enter event this GTK4 client processes, confirmed by a live jiggle test that produced no :hover activation despite a correct hyprctl cursorpos. Since :hover and :focus are byte-identical paired CSS selectors in this stylesheet, the focus-driven capture proves the same code path, but the specific input modality (real mouse hover) remains unconfirmed live. | open | RE-DEFERRED (LEDGER-05, 20-02): same disposition family as row 3 — no synthetic real-mouse-hover tool exists on this host, and the gap carries forward unchanged onto the new power-grid surface. Owner: plan 20-08's Gate B (same render-gate record as row 3). | 2026-07-25T16:49:50.463Z |  |
| 5 | 09 | deviation | wleave/.config/wleave/layout.json |  | Icon glyph size is the SVG's natural/shrink-fit size under the icon+label vertical stack (empirically ~27-29px at the tuned margin), not forced to the UI-SPEC's literal 36px Display-role token — that token assumed the retired text-glyph delivery mechanism. Visually consistent and legible per the 09-03 evidence captures; not explicitly re-pinned to a fixed pixel size. | open | RE-DEFERRED (LEDGER-05, 20-02): the replacement power grid pins Design.sessionTileIconSize (32) explicitly per 20-UI-SPEC.md — a strong fixed-by-construction candidate, but plan 20-06 (which builds it) has not run yet. Owner: plan 20-06 — close once its own acceptance criteria confirm the pinned size renders. | 2026-07-25T16:49:50.541Z |  |
| 6 | 09 | deviation | hypr/.config/hypr/scripts/wleave.sh |  | Fault-injection test (09-04): moving ~/.config/wleave/layout.json aside does NOT trigger the wrapper's launch-failure notify-send. wleave has its own packaged config fallback chain and silently loads /etc/wleave/layout.json (a large unstyled 3x2 grid, version-info footer visible) instead. This is not a silently-empty scrim (satisfies the UI-Consideration-1 backstop's core requirement) but it is a third, unenumerated outcome the wrapper script's command -v/kill -0 guards do not cover — wleave.sh has no check that the user's own layout.json exists. Not fixed in 09-04 (file not in this plan's declared files_modified); flagged for future triage. | waived | wleave.sh (the fault-injection subject) is deleted whole in plan 20-10, and D-20-23 deletes the availability-probe concept outright: an in-process QML surface has no external-binary-missing failure mode to guard against, so this bug class cannot recur. | 2026-07-25T17:10:45.472Z | 2026-08-15T16:08:48.300Z |
| 7 | 09 | deviation | hypr/.config/hypr/hyprlock.conf |  | hyprlock crashed (SIGABRT) during 09-04 human render-gate testing of the lock action. Almost certainly independent of this phase: the only hyprlock coredumps on this machine are dated 2026-04-02 and 2026-07-12 (five SIGABRTs), none from the 2026-07-25 session; the lock action string (uwsm app -- hyprlock) is byte-identical to the Phase-4-audited string, unchanged by this phase; and the human independently confirmed lock working earlier in the same gate. Logged for separate triage, not chased in this phase. | open |  | 2026-07-25T18:53:00.893Z |  |
| 8 | 12 | deviation | hypr/.config/hypr/config/animations.conf |  | Plan 12-04's acceptance criterion expected 'animation = ' count of 14; live file has 13 (pre-existing, unchanged by this plan; D-04 fence proven intact via before/after count equality) | fixed |  | 2026-07-26T20:29:08.850Z | 2026-07-27T22:02:08.186Z |
| 9 | 12 | unrun-verify | theme-engine/.config/theme-engine/theme-stress-test |  | 12-06's D-17 live re-colour assertion could not be exercised via the REAL, committed theme-stress-test in the dev session: its per-switch theme-doctor gate (D-66, strict exit 0) always fails on the pre-existing, out-of-scope untracked vscodium desktop file (documented in deferred-items.md / STATE.md, predates Phase 12). D-17's own assertions (live re-colour match + PID-unchanged) WERE fully proven via a scratch-patched, never-committed copy of the identical script that bypassed only that one pre-existing check: a complete 10/10-switch run passed with zero failures (162 passed, 0 failed), the quickshell PID never changed across all 10 rsync-based palette.json replacements, and every switch's rendered Colours.primary matched the freshly-rendered palette.json. UPDATED 2026-07-27 (Phase 12 close): the untracked vscodium file was resolved by `604368e`, and the REAL committed theme-stress-test was then re-run end-to-end. It did NOT pass identically — the 'expected to pass identically' prediction above was WRONG, and the scratch-copy proof was weaker than it appeared precisely because it bypassed this check. Switches 1-4 passed in full (including every D-17 live re-colour assertion and PID-unchanged check, against the real script this time). Switch #5 ('dracula') FAILED the D-66 strict theme-doctor gate. ROOT CAUSE (pre-existing Phase 03 debt, NOT a Phase 12 regression): `lib/wallpaper.sh:65` repoints `wallpapers/Pictures/Wallpapers/current.jpg` via `ln -sfr` on every STATIC theme switch; that symlink is TRACKED in git (committed target `catppuccin/5-alien-planet.jpg`); and theme-doctor asserts `git status --porcelain` is empty (invariant added in 90f73c2, phase 03-03) while theme-stress-test requires a strict theme-doctor pass after EVERY switch (1a4ce30, phase 03-03). So any switch to a static theme whose wallpaper differs from the committed target dirties a tracked file and fails the gate. Confirmed by mechanism: switching back to `catppuccin` restored the symlink and the tree went clean again. CONSEQUENCE: the committed theme-stress-test can never reach 10/10 while its sequence contains a static theme with a non-committed wallpaper — this is structural, not environmental. Material You themes are unaffected (wallpaper.sh explicitly never touches current.jpg for those). FIX OPTIONS (deferred to Phase 13, the designated existing-surface sweep, per user decision at Phase 12 close): (a) untrack current.jpg (`git rm --cached` + gitignore) AND add fresh-install seeding to stow.sh — note current.jpg is NOT currently seeded by stow.sh/install.sh, so a fresh machine depends on the tracked symlink existing; or (b) narrowly exempt that one path from theme-doctor's clean-tree check as runtime state. Phase 12 itself is unaffected: criterion 1's live re-colour is independently confirmed by the 12-06 D-27 human render gate AND by switches 1-4 of this real run. | fixed |  | 2026-07-26T21:50:46.937Z | 2026-07-27T22:34:56.419Z |
| 10 | 13 | deviation | hypr/.config/hypr/config/animations.conf |  | D-06 boundary correction: layer-surface exits (walker/swaync/wleave) are client-owned, not compositor-owned; Check 3's original render-gate method had no valid instrument, closed on mechanical proof instead (13-01-SUMMARY.md) | waived | D-06 boundary correction (layer-surface exit is client-owned, mechanically proven in 13-01) is a confirmed architectural fact, not a pending defect; the same boundary is inherited correctly by this phase's two new windowrules.lua namespaces. | 2026-07-27T03:43:43.806Z | 2026-08-15T16:08:52.144Z |
| 11 | 13.1 | deviation | hypr/.config/hypr/config/windowrules.lua |  | hl.window_rule size field's percentage form (85% 85% / 70% 65%) registers with zero configerrors but has no runtime effect on installed Hyprland 0.56.1 Lua config manager; affects 6/30 rules (5 pickers + yazi-fm); see COVERAGE.md 'Window-rule size field' section and 13.1-07-SUMMARY.md | fixed | Operator directly confirmed on 2026-07-28 ("my window rules are in order") that all 6 affected windows (wallpaper-picker, icon-theme-picker, font-switcher, network-manager, cheat-sheet, yazi-fm) size correctly on the live Lua session in practice, despite the mechanically-proven zero-configerror size percentage-form no-op found in 13.1-07. No code change made — windowrules.lua's size strings are left byte-identical, per operator instruction. See COVERAGE.md 'Window-rule size field' section, operator-confirmation addendum. | 2026-07-28T04:47:47.278Z | 2026-07-28T17:16:00.000Z |
| 12 | 13.1 | deviation | hypr/.config/hypr/scripts/gaming-mode-toggle.sh |  | hyprctl keyword is a silent no-op on the Lua-config compositor (exit 0, no effect) - breaks gaming-mode-toggle's eye-candy on/off calls; see deferred-items.md item 1 | fixed |  | 2026-07-28T10:25:31.641Z | 2026-07-28T12:14:49.536Z |
| 13 | 13.1 | deviation | hypr/.config/hypr/hypridle.conf |  | 13.1-09's consumer-retarget sweep was INCOMPLETE. That plan correctly identified the Lua-cutover dispatch break and fixed theme-engine/.config/theme-engine/theme-stress-test (lines 368/571, hl.dsp.global form), but it did not sweep the rest of the repo for the same pattern — it left 7 further legacy 'hyprctl dispatch <string>' call sites dead, plus ~8 more in quickshell-doctor (logged separately). Missed sites, all silently no-op under the Lua config manager (the compositor wraps the payload into 'return hl.dispatch(<payload>)' and evaluates it as Lua SOURCE, which is a parse error): hypridle.conf after_sleep_cmd/on-timeout(900)/on-resume(900) — the 15-minute display blank AND its resume were both dead; ai-workspace.sh:58 and ai-webapp-launch.sh:28 ('workspace name:ai' — the latter broke the switch-then-launch ordering the whole script depends on, so Zen AI windows were landing on the wrong workspace); config-floating.jsonc:98-99 waybar scroll. All 7 retargeted and verified 2026-07-28 in debug session waybar-workspace-click-dead. LESSON: 13.1-09 fixed the site it tripped over rather than grepping the repo for the pattern class; a 'hyprctl dispatch' grep would have caught all 15 at once. SHARPEST FORM OF THIS, confirmed from git history: commit e82f2bd (13.1-09) MODIFIED ai-webapp-launch.sh in that very commit — a comment-only edit repointing windowrules.conf to windowrules.lua — while the broken 'hyprctl dispatch workspace name:ai' sat two lines below the edited hunk; and THAT SAME COMMIT separately fixed the identical bug class in theme-stress-test as a declared 'Rule 3 blocking-issue fix'. So the pattern was recognised, fixed where it blocked the plan's own verification, and not generalised — not even within a file the plan was actively editing. The generalisable guard is a repo-wide grep for the withdrawn API whenever one instance of it is fixed. NOTE the dpms sites were NOT a mechanical transliteration — see that debug session: hl.dsp.dpms('on') is NOT 'turn on', the bare-string arg is ignored entirely and falls through to the eTogglableAction zero-default TOGGLE; only the table form {action=...} works, and under toggle semantics on-resume would have blanked the display on every wake. | fixed |  | 2026-07-28T13:12:15.497Z | 2026-07-28T13:12:39.733Z |
| 14 | 13.1 | deviation | hypr/.config/hypr/scripts/quickshell-doctor |  | ~8 legacy 'hyprctl dispatch global <name>' call sites still on the withdrawn string form and therefore silently dead under the Lua config manager (same mechanism as WINDOWS #13). Missed by 13.1-09's sweep. DELIBERATELY DEFERRED by operator decision on 2026-07-28 when selecting Branch C in debug session waybar-workspace-click-dead: the operator chose plain C over 'C + quickshell-doctor', so this was left untouched rather than overlooked. Fix is mechanical and already patterned in-repo: 'hyprctl dispatch \\'hl.dsp.global("<name>")\\'' (see theme-stress-test:368/571). CAUTION when picking this up: quickshell-doctor must NOT be run casually to test the change — its headless-output add/remove test previously SEGV-crashed this compositor during a DP-1 hotplug. | fixed |  | 2026-07-28T13:12:31.315Z | 2026-08-10T23:52:50.674Z |
| 15 | 13.1 | deviation | waybar/.config/waybar/config-floating.jsonc |  | ACCEPTED DEBT, NOT A BUG TO FIX HERE: waybar 0.15.0-2's hyprland/workspaces CLICK is permanently dead on the Lua-config compositor and is unreachable from config. The legacy dispatch strings ('dispatch workspace <id>', 'dispatch workspace name:', 'dispatch focusworkspaceoncurrentmonitor', 'dispatch togglespecialworkspace') are compiled into Workspace::handleClicked and the IPC error reply is discarded; 'man 5 waybar-hyprland-workspaces' documents no on-click key for this module, and the payloads are Lua SYNTAX errors so no Lua-side shim/metatable can rescue them. Upstream Waybar PR #5013 fixes it but postdates the 0.15.0 release, so no shipped Arch package carries it (refs: Waybar #5008/#5035, Hyprland discussion #14255). Operator rejected both upgrading to waybar-git (throwaway -git package in install.sh's reproducible path) and rolling back to hyprlang (would undo an equivalence-proven migration). RESOLUTION PATH: dies with waybar at the Quickshell cutover — Quickshell's QML uses the GlobalShortcut Wayland protocol and contains zero IPC dispatch string sites, so the bug class is removed structurally. The SCROLL handlers in this same file WERE fixable (config strings, not compiled in) and were fixed 2026-07-28. The inert 'on-click: activate' key is retained with an explanatory comment. | open |  | 2026-07-28T13:12:31.415Z |  |
| 16 | 13.1 | deviation | hypr/.config/hypr/scripts/ai-webapp-launch.sh |  | WR-04 (13.1-REVIEW.md): the workspace-switch dispatch (`hyprctl dispatch 'hl.dsp.focus({workspace="name:ai"})'`) is guarded by a bash logical-or-true idiom, silently discarding any failure of the one mechanism the script's own header says is the ONLY way to correctly place a Zen AI web-app window on `name:ai` — a failed switch lets the browser launch on whatever workspace is currently active with no error surfaced. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05). | open |  | 2026-07-28T17:16:00.000Z |  |
| 17 | 13.1 | deviation | hypr/.config/hypr/scripts/ai-workspace.sh |  | WR-05 (13.1-REVIEW.md): the idempotency check's PRESENT comma-joined class list is tested with bash substring matching ([[ "$PRESENT" != *"$CLAUDE_CODE_CLASS"* ]]), not delimiter-aware exact matching — a window class that merely CONTAINS ai-claude-code/ai-local-models as a substring produces a false "already present" match and silently skips the launch, violating D-24 idempotency. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05). | open |  | 2026-07-28T17:16:00.000Z |  |
| 18 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml |  | 15-05 Task 3: full password-connect, in-flight Cancel, real failure, and Forget-confirm proofs not run live — host has no synthetic pointer-input tool (15-API-PROBE Open Q2) and no real wifi passphrase was available; only single-press Escape-dismiss with nothing expanded was proven live | open |  | 2026-08-02T01:58:16.101Z |  |
| 19 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml |  | 15-06 Task 3: pairing failure, cancel-not-failure, connect failure/recovery, watchdog-fire, press-guard, adjacency, and all chevron/verb/Forget click proofs not run live — host has zero paired devices, zero discoverable peers within range (8s live scan empty), and no synthetic pointer-input tool; only the empty-state render and discovery's reactive/lifecycle-teardown-firing paths were proven live | open |  | 2026-08-02T02:21:50.326Z |  |
| 20 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | Chevron/tile-body click paths not literally exercised — no synthetic pointer tool on host; guarded summon function proven via IPC equivalent instead | open |  | 2026-08-02T02:40:09.329Z |  |
| 21 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | E6 error-contract fault injection (rfkill-blocked toggle reverting to truth) not cleanly reproduced live — NetworkManager software radio switch succeeded independent of rfkill state; source-verified mechanism only | open |  | 2026-08-02T02:40:14.434Z |  |
| 22 | 15 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | Bluetooth tile external-toggle live-truth proof not run — session's rfkill soft-blocked bluetooth state intentionally left untouched per non-negotiable rule 3 | open |  | 2026-08-02T02:40:14.524Z |  |
| 23 | 15 | deviation | quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml |  | pendingGlyph opacity pulse (WifiPanel.qml ~:574-595) and its BluetoothPanel.qml counterpart still bind one-shot emphasizedIn/OutDuration tokens as an infinite pulse period, inheriting the reduced-makes-it-faster inversion G-15-1 fixed for the sweep lines; deliberately left unchanged per 15-11's scope_fence (a pulse's message survives being fast, unlike a sweep's) | open |  | 2026-08-02T17:07:48.756Z |  |
| 24 | 18 | unrun-verify | quickshell/.config/quickshell/modules/Bar.qml |  | 18-01 Task 2's <human-check> render gate (pill renders, floats clear of edge, live HH:MM, theme crossfade with no magenta flash) was not run by the executor — automated verify passed; visual confirmation deferred to the user per established project preference (skip-live-verification memory). | open |  | 2026-08-10T23:12:33.140Z |  |
| 25 | 18 | unrun-verify | quickshell/.config/quickshell/modules/Bar.qml |  | D-18-31/GATE-02 human render-gate for 18-05 (orientation flip, vertical clock re-stack, theme crossfade in both orientations) not performed by the executor — deferred to the user per established project preference (18-01's identical precedent, WINDOWS entry 24). | open |  | 2026-08-11T00:13:17.928Z |  |
| 26 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-RESTART-PARITY.md |  | QBAR-10 destructive restart/rate-limit live proof (SIGTERM retire, SIGKILL restart, 6x SIGKILL rate-limit trip, recovery) and the Task 3 human visual check were deferred to the operator — full runbook provided; only non-destructive systemctl show/is-enabled/systemd-analyze checks were run by the executor | open |  | 2026-08-11T00:45:20.302Z |  |
| 27 | 18 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml |  | 18-08 Task 3 D-18-31/GATE-02 live render-gate not performed this session: album art, seek slider, player switcher, transport buttons and near-instant external-pause reflection unconfirmed against a real quickshell reload | open |  | 2026-08-11T01:11:51.902Z |  |
| 28 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/SystemCapsule.qml |  | 18-08 Task 1/2 D-18-31/GATE-02 live render-gate not performed this session: system capsule cpu/ram/disk/updates not visually confirmed against top/free/df/checkupdates on a live-reloaded bar | open |  | 2026-08-11T01:11:57.190Z |  |
| 29 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml |  | 18-08 Task 4 D-18-31/GATE-02 live render-gate not performed this session: audio/network/bluetooth glyph reactions to a real mute/radio toggle, vertical re-stack and theme-switch crossfade unconfirmed on a live-reloaded bar | open |  | 2026-08-11T01:11:57.281Z |  |
| 30 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/TrayCapsule.qml |  | 18-10 Task 2 live click-through on a real tray application's real menu row was NOT performed this session — no StatusNotifierWatcher existed on this host's session bus before this plan's Task 1 commit (waybar's athena layout deliberately removed its own tray module), and neither blueman-applet nor nm-applet registered a StatusNotifierItem even after quickshell began self-hosting the watcher. The implemented leaf-activation call (sendTriggered() on the concrete DBusMenuItem) is the highest-ranked candidate by static existence evidence (dbusmenu.hpp:97), not by live observation; RESEARCH.md Open Question 1 remains open pending a user-side click-through on real hardware with a real tray menu. | fixed | resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists | 2026-08-11T01:40:49.092Z | 2026-08-11T14:47:35.113Z |
| 31 | 18 | deviation | quickshell/.config/quickshell/modules/bar/TrayCapsule.qml |  | 18-10 Task 3's acceptance criterion 'exactly one Rectangle {} in the file (the menu popup's own)' is unsatisfiable given Task 2's own explicit action text, which separately requires a 1px Colours.outline separator divider and a Colours.surface hover-tint background on menu rows — both need a Rectangle in plain QtQuick. Implemented per Task 2's semantic spec (menuSurface background + one separator-divider Rectangle declared once inside the row Repeater delegate + one hover-tint Rectangle declared once inside the same delegate = 3 Rectangle declaration sites in source), documented as a stale/self-contradictory acceptance-criteria text issue rather than distorting the UI to force a literal count of 1 — mirrors 18-05-SUMMARY.md's own Deviation precedent for this exact class of plan-text conflict. | fixed | resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists | 2026-08-11T01:41:17.168Z | 2026-08-11T14:47:35.113Z |
| 32 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/TrayCapsule.qml |  | 18-10 GATE-02 B.5's full visual pass (icons actually rendering and looking correct in both orientations, menu opening and looking correct) was not human-eyeballed this session — no tray application successfully registered a StatusNotifierItem on this host (see the paired unrun-verify entry), so there was nothing to look at. Only the mechanical half was proven live this session: hyprctl reserved-zone and quickshell-bar layer-namespace readings across horizontal -> vertical -> horizontal with zero TrayCapsule.qml load errors at each step. Deferred to the user, same shape as 18-05's own D-18-31 deferral. | fixed | resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists | 2026-08-11T01:41:17.263Z | 2026-08-11T14:47:35.113Z |
| 33 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml |  | D-18-31/GATE-02 human render-gate check for 18-11 not performed by executor (human_verify_mode: end-of-phase) — both drawers open/act, both orientation reach paths, all four extras visible, no literal-text glyph, idle inhibitor genuinely suppresses idle, bell count matches, theme-switch crossfade clean. Deferred to 18-19's blocking GATE-02 pass. | open |  | 2026-08-11T02:11:30.945Z |  |
| 34 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml |  | 18-12 Task 1 human-check deferred: live wheel-scroll on audio entry vs wpctl get-volume, both bounds — running quickshell process predates this plan's code | open |  | 2026-08-11T02:24:38.777Z |  |
| 35 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml |  | 18-12 Task 2 human-check deferred: repoint deviceClass to leds, confirm hot-reload renders real percentage, scroll, revert, vertical orientation — running quickshell process predates this plan's code | open |  | 2026-08-11T02:24:38.864Z |  |
| 36 | 18 | lint-warning | quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml | 117 | Pre-existing untokened color: (cellItem.tint) from 18-11, found by 18-12's file-wide colour-token gate but out of scope (not touched by 18-12) | open |  | 2026-08-11T02:24:38.953Z |  |
| 37 | 18 | lint-warning | quickshell/.config/quickshell/modules/bar/TrayCapsule.qml | 241 | Pre-existing untokened color: ("transparent") from 18-10, found by 18-12's file-wide colour-token gate but out of scope (not touched by 18-12) | fixed | resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists | 2026-08-11T02:24:39.043Z | 2026-08-11T14:47:35.113Z |
| 38 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/SectionPopout.qml |  | 18-13 Task 1 human-check not run this session: click-to-open live rendering, hyprctl y=50 confirmation, volume slider moving real system volume, click-outside destruction, 18-12 scroll gesture survival, vertical-orientation placement — deferred (live quickshell process predates this plan's commits). | open |  | 2026-08-11T02:48:07.664Z |  |
| 39 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/PopoutController.qml |  | 18-13 Task 2 human-check not run this session: felt 400ms dwell, bar-sweep-opens-nothing proof, diagonal-move-survives-the-gap, pin/Escape/click-outside cycle, no-keystroke-theft typing proof — deferred (live quickshell process predates this plan's commits). | open |  | 2026-08-11T02:48:07.772Z |  |
| 40 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/AudioPopout.qml |  | 18-13 Task 3 human-check not run this session: foot-pill visual comparison against a dashboard panel's Advanced button, click-through to AudioPanel.qml, live pending/empty state provocation, theme-switch crossfade check — deferred (live quickshell process predates this plan's commits). | open |  | 2026-08-11T02:48:07.870Z |  |
| 41 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/WifiPopout.qml |  | 18-14 Task 1 human-check deferred: live scan/discovery negative-check (iw dev / bluetoothctl show) while wifi/bluetooth popouts are open | open |  | 2026-08-11T03:14:04.331Z |  |
| 42 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/ClockPopout.qml |  | 18-14 Task 2 human-check deferred: cell-for-cell calendar comparison against the dashboard card and the resources popout's unsampled em-dash state on a fresh shell restart | open |  | 2026-08-11T03:14:04.420Z |  |
| 43 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/MediaPopout.qml |  | 18-14 Task 3 human-check deferred: live transport control, multi-player case, and confirming all five foot-link destinations are intact and unthinned | open |  | 2026-08-11T03:14:04.512Z |  |
| 44 | 18 | unrun-verify | hypr/.config/hypr/scripts/bar-visibility.sh |  | 18-15 Task 3's live per-driver zone-policy proof sequence (qs ipc call bar <verb> round trip against idle/gaming/keybind, plus the hyprctl monitors -j reserved-array deltas) was not run — the live quickshell process predates every commit in this plan and has not been restarted/reloaded, matching the phase's established skip-live-verification precedent (18-08/18-12/18-13). | open |  | 2026-08-11T03:35:30.387Z |  |
| 45 | 18 | deviation | quickshell/.config/quickshell/shell.qml |  | 18-15 Task 2's acceptance grep for 'exactly four functions matching show / hideIdle / hideHard / status' counts 5 whole-file matches, not 4 — a pre-existing overviewIpc.status() (16-04) collides with the regex. barIpc itself declares exactly the specified four functions; the mismatch is in the verify script's scope (whole-file vs. handler-scoped), not a defect in the implementation. | open |  | 2026-08-11T03:35:37.331Z |  |
| 46 | 18 | deviation | hypr/.config/hypr/config/keybinds.lua |  | 18-16 Task 2: held-Super reveal bind (Branch A) drafted then reverted — keybind-doctor's chord-collision check flagged it against the shipped SUPER+SUPER_L tap-to-menu bind at line 86; compositor-side probe not live-verified this session | open |  | 2026-08-11T09:26:59.846Z |  |
| 47 | 18 | unrun-verify | quickshell/.config/quickshell/modules/bar/BarReveal.qml |  | 18-16: hot-zone/reveal live gestures (pointer-to-edge reveal, Super-hold reveal, popout-suppression, escape hatch, reserved-array stability, hyprctl layers lifecycle) not exercised — live quickshell process predates this plan's commits ('qs ipc call bar status' -> Target not found), matching 18-08/18-12/18-13/18-15 precedent | open |  | 2026-08-11T09:26:59.939Z |  |
| 48 | 18 | deviation | hypr/.config/hypr/scripts/bar-visibility.sh |  | 18-17 found and fixed live: qs ipc call bar show (no --) silently fails to invoke on quickshell 0.3.0's qs CLI (literal token 'show' collides with the ipc show subcommand); _ipc_call() now uses 'qs ipc call -- bar $verb'. Never live-tested before 18-17 (18-15-SUMMARY recorded the interactive round-trip as not performed). | fixed |  | 2026-08-11T10:09:37.777Z | 2026-08-11T10:10:14.135Z |
| 49 | 18 | deviation | quickshell/.config/quickshell/modules/bar/BarReveal.qml |  | 18-17 found and fixed live: BarReveal.qml (18-16 Task 3) declares pragma Singleton and roots on the Singleton {} type but never imports Quickshell (the module that type comes from), so any real quickshell.service restart/reload since 18-16 landed failed with 'Singleton is not a type', taking down the whole bar. Fixed with a one-line import; verified clean on both a full systemd restart and a source-touch hot reload. | fixed |  | 2026-08-11T10:10:20.236Z | 2026-08-11T10:10:27.569Z |
| 50 | 18 | deviation | hypr/.config/hypr/scripts/quickshell-doctor |  | 18-17 Task 2 acceptance criterion 'grep -cE ^\\s*trap  returns 1' is stale against pre-existing file state: quickshell-doctor already carried 3 trap lines (EXIT/INT/TERM, all invoking the single _qsd_cleanup) before this plan touched the file. Task 2 extended _qsd_cleanup's body only, installed no new trap statement — the real invariant (one cleanup function, one flag per mutation class) holds; the literal grep count does not and never could on this file. | open |  | 2026-08-11T10:10:34.633Z |  |
| 51 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-FRAME-RATE.md |  | LEDGER-03 frame-rate campaign (Task 1 of 18-18) deferred: full methodology and exact resume commands recorded in 18-FRAME-RATE.md, but no condition (C0-C4) was measured this session. Requires stopping quickshell.service to run an unsupervised QSG_RENDER_TIMING instance, and rearranging the live desktop to OVER-04's 8-window/3-workspace load floor (live check: only 4 windows/4 workspaces present). LEDGER-03 stays open; 16-OVER04-MEASUREMENT.md/PROJECT.md/MILESTONES.md not edited. | fixed |  | 2026-08-11T10:28:14.163Z | 2026-08-11T22:03:07.085Z |
| 52 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md |  | QBAR-11 soak (Task 4 of 18-18) deferred: Task 3's aggregated inventory, pre-declared tolerances, and a real start capture (pid 737907, RSS 450424 KiB, wake rate 19.3429/sec and CPU rate 0.002476 cpu-sec/sec over a genuine 300s observation) are complete in 18-BAR-SOAK.md. Task 4's end capture, 200-cycle hide/reveal exercise, and verdict require at least 14400s of continued single-pid uptime with unchanged NRestarts, which cannot elapse within one session. Exact resume commands recorded in 18-BAR-SOAK.md Section five. QBAR-11 stays open; no verdict asserted. | fixed |  | 2026-08-11T10:28:19.689Z | 2026-08-11T22:08:11.418Z |
| 53 | 18.1 | unrun-verify | quickshell/.config/quickshell/modules/Bar.qml |  | 18.1-04 Task 1's live restart check (quickshell.log carries no new TrayCapsule-is-not-a-type or unresolved-type QML error line, and the bar renders every remaining capsule in both orientations with the tray gap gone) was NOT performed this session — deferred to the user per established project preference (skip-live-verification memory; same shape as WINDOWS entries 24/25). The hyprctl monitors -j reserved array was compared before and after the edit without a restart (unchanged: [0,46,0,0]), which does not by itself prove the new qmldir/Bar.qml/BarEntryModel.qml code loads without error. | open |  | 2026-08-11T14:49:54.036Z |  |
| 54 | 18.1 | unrun-verify | quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml |  | 18.1-05 Task 3 leg 2 (drawer opening into a moving bar) not live-observed — no synthetic pointer-input tool exists on this host (PROJECT.md-recorded finding); the dwell timer re-evaluating drawerHoverActive/drawerSettled at fire time (not only arm time) is asserted from source instead, per the plan's own stated fallback for this leg. Deferred to 18.1-07's GATE-02 hover walkthrough. | open |  | 2026-08-11T15:00:44.002Z |  |
| 55 | 18.1 | unrun-verify | quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml |  | 18.1-05 Task 3 leg 3 (drawer open when the bar hides) not live-observed — expanding a drawer via real hover, then triggering a bar hide (idle/fullscreen/gaming/keybind) and watching it collapse, needs pointer input this host has no synthetic tool for. Asserted from source instead: onDrawerSettledChanged stops both timers and calls requestCollapse() immediately (no grace) the moment drawerSettled goes false while expanded, and requestExpand() is reachable only from the dwell timer's fire handler which re-gates on drawerSettled, so the drawer cannot mechanically reappear expanded on the next reveal without a fresh hover+dwell cycle. Deferred to 18.1-07's GATE-02 hover walkthrough. | open |  | 2026-08-11T15:00:51.726Z |  |
| 56 | 18.1 | unrun-verify | quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml |  | 18.1-05 Task 3's zero-idle-at-rest check (both drawer timers not running with the pointer away and both drawers collapsed) was not confirmed via live introspection — no QML Timer.running probe/IPC exists on this host to poll it. Asserted from source instead: both drawerDwellTimer/drawerGraceTimer (in LauncherCapsule.qml and ClockActionsCapsule.qml) are repeat:false and are only ever started via .restart() inside onDrawerHoverActiveChanged (armed on a hover-state transition) or onDrawerSettledChanged (only while already expanded) — neither has running:true set unconditionally nor a Component.onCompleted starter, mirroring the same static method BarReveal.qml's own reHideTimer zero-idle claim already relies on. | open |  | 2026-08-11T15:00:58.131Z |  |
| 57 | 18.1 | deviation | quickshell/.config/quickshell/modules/bar/ |  | D-20's quickshell-doctor colour-role-routing check exempts the seven SectionPopout-family files (SectionPopout.qml, AudioPopout.qml, WifiPopout.qml, BluetoothPopout.qml, ClockPopout.qml, ResourcesPopout.qml, MediaPopout.qml) by basename — 66 live Colours.* references across those seven files at time of writing. D-06/D-20 as written say the whole of modules/bar/, but phase 18.1's own scope_fence places popout content and the SectionPopout framework explicitly OUT of scope: these are separate anchored surfaces with their own surfaceBase, not bar capsules, and their palette references were never part of the fill-versus-tint defect the check exists to catch. This is a deferred decision, not a closed one — a future phase migrating the popout family onto BarRoles should remove this exemption and shrink QSD_BAR_COLOUR_ROLE_EXEMPT accordingly. | open |  | 2026-08-11T15:15:17.265Z |  |
| 58 | 18.1 | deviation | quickshell/.config/quickshell/modules/Colours.qml | 106 | GATE-02 defect 1: BarRoles alpha-blend roles read .r/.g/.b off Colours.qml roles typed property string, not property color, so blended surfaces (capsule/capsuleHover/barSurface/barSurfaceHover/capsuleTrack) resolve to opaque black. Root cause of the operator's GATE-02 FAIL complaint 1. Not fixed in 18.1-07 (recording-only plan). | fixed |  | 2026-08-11T15:40:37.602Z | 2026-08-11T16:45:06.911Z |
| 59 | 18.1 | deviation | quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml |  | GATE-02 defect 2: bar geometry unmistakably larger than Athena — Design.iconSizeMd (24px) vs Athena's glyph-only 16px, capsule inner padding 8px (Design.spacingSm) vs Athena's 6px 6px; filed out of scope during this phase's Athena audit, which was wrong. Pacman/updates glyph also not optically centred. Root cause of the operator's GATE-02 FAIL complaint 2. Not fixed in 18.1-07 (recording-only plan). | fixed |  | 2026-08-11T15:40:50.375Z | 2026-08-11T16:45:24.824Z |
| 60 | 18.1 | deviation | quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml | 308 | GATE-02 defect 3: drawer expansion reads as sudden/clunky vs Athena's smooth expansion. Container motion IS present (motion.json motion_enabled:true, 375ms emphasized-in MD3 bezier, Behavior on width/height at LauncherCapsule.qml:308-323) but revealed cells appear instantly with no fade/stagger, unlike Athena's transition: all on the members themselves. Not definitively isolated as the sole cause — a lead, not proven. Root cause lead for the operator's GATE-02 FAIL complaint 3. Not fixed in 18.1-07 (recording-only plan). | fixed |  | 2026-08-11T15:40:50.480Z | 2026-08-11T16:45:24.921Z |
| 61 | 18.1 | deviation | quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml | 50 | GATE-02 defect 4: app drawer shows jarring generic icons for apps without a good themed icon. appEntries (LauncherCapsule.qml:50-57) IS the correct predetermined 7-app list matching Athena's custom/app-* set; the divergence is in icon resolution — this phase's D-18-01 icon-theme redesign resolves each entry through the desktop-entry/icon-theme database instead of Athena's one-hardcoded-glyph-per-app approach. D-18-01's redesign is the direct cause and needs revisiting. Root cause of the operator's GATE-02 FAIL complaint 4. Not fixed in 18.1-07 (recording-only plan). | fixed |  | 2026-08-11T15:40:50.580Z | 2026-08-11T16:45:25.018Z |
| 62 | 18.1 | unmet-truth | quickshell/.config/quickshell/modules/bar/BarRoles.qml |  | GATE-02 verification-method gap: no alpha-blended BarRoles role was ever probed for a resolved numeric value across this phase's automated checks — plan 18.1-01's verification asserted typeof BarRoles.accent === object (a non-alpha role) and never exercised a blended one. Plan 18.1-06's D-20 quickshell-doctor colour-routing check only asserts no direct Colours.* reference survives under modules/bar/; it does not assert a routed role RESOLVES to a real colour. This is why a 100%-black bar (see WINDOWS id 58) passed every automated check in the phase, including the check built specifically to guard bar colour correctness. The check is not wrong, it is insufficient — needs a resolved-value assertion on every alpha role, not just a routing/reference check. | fixed |  | 2026-08-11T15:40:50.676Z | 2026-08-11T16:45:25.110Z |
| 63 | 18 | deviation | quickshell/.config/quickshell/shell.qml |  | 18-18 Task 5, option-b (operator decision 2026-08-12): 18-05 widened three SystemResources backend gates all-or-nothing, so switching on cpu/memory/storage for the bar also switched on the GPU and network samplers no bar entry consumes — SystemCapsule.qml reads only cpuFraction/memoryFraction/storageFraction. Measured cost: 900 nvidia-smi subprocess spawns per hour (gpuPollInterval 4000ms -> 3600/4), per 18-BAR-LIVENESS-CHARGE.md's live measurement. Wake/CPU-time share is NOT isolable from the soak's aggregate observation (that figure includes every backend combined); isolating it would need a differential gate-disabled-vs-enabled run, which means editing shell.qml. Remedy is one line of work: add a second, drawer-only gate expression in shell.qml so the GPU and network samplers follow the drawer while cpu/memory/storage follow the bar. Not done in phase 18 — shell.qml is 18-05's file, frozen for wave 3, and five shipped-and-verified plans (18-15, 18-16, 18-17 among them) depend on its current shape. Routed here from 18-08, measured by 18-18, decided by the operator as debt rather than an in-phase scope correction. Citation: 18-BAR-SOAK.md § 'GPU-and-network-sampler cost'. | open |  | 2026-08-11T21:48:09.267Z |  |
| 64 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md |  | QBAR-11 soak (18-18 Task 4) — window RE-ANCHORED and now RUNNING as of 2026-08-12 01:00. Supersedes row 52, whose anchor (pid 737907) went void when quickshell restarted during Phase 18.1's bar rebuild. Live anchor is 18-BAR-SOAK.md Section four-bis: pid 262631, unit start 2026-08-12 00:32:15 EEST, NRestarts=0, RSS 477016 KiB, wake rate 6.9533/sec, CPU rate 0.001167 cpu-sec/sec over a real 300s observation, reserved [[0,48,0,0]], quickshell-bar sole namespace. Earliest valid end capture approximately 04:32:15 EEST (unit start + 14400s). STILL TO RUN: the end capture, at least 5 spaced RSS samples through the window, the 200-cycle hide/reveal exercise via bar-visibility.sh's own verbs, and the verdict against the re-anchored threshold table. TWO METHODOLOGY CORRECTIONS carried by the artifact and required of the end capture: (1) intersect the long-lived-child set by COMMAND, not pid — proven live when the swaync-client -swb child re-spawned 262662 -> 424020 mid-session, which a pid intersection would have reported as a dead subscription; (2) the reserved array is [[0,48,0,0]] not [[0,46,0,0]] — Design.barHeight went 40 -> 42 in 18.1 to match upstream Athena, so 18-19's fingerprint and 18-20's parity statement are both stale by 2px and must record the live value with that reason rather than be made to pass. If quickshell restarts before the window elapses, the window voids again and Section four-bis must be re-taken. | fixed |  | 2026-08-11T22:08:11.516Z | 2026-08-11T22:27:29.410Z |
| 65 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md |  | QBAR-11 soak (18-18 Task 4) — LIVE WINDOW, third anchor. Supersedes rows 52 and 64, both voided (52 by Phase 18.1's bar rebuild, 64 by a host reboot at 01:09 on 2026-08-12). Live anchor is 18-BAR-SOAK.md Section four-ter: pid 1626, unit start 2026-08-12 01:09:39 EEST, NRestarts=0, RSS 221928 KiB, wake rate 10.5767/sec (band 8.4614-12.6920), CPU rate 0.001400 cpu-sec/sec (band 0.00105-0.00175), RSS ceiling 254696 KiB, reserved [[0,48,0,0]], waybar count 0, quickshell-bar sole namespace, 34 module timers. Earliest valid end capture approximately 05:09:39 EEST. STILL TO RUN: end capture, at least 5 RSS samples spaced through the window, the 200-cycle hide/reveal exercise via bar-visibility.sh verbs, and the verdict. THREE CONSTRAINTS the end capture must honour: (1) resume with PID=1626, and intersect the long-lived-child set by COMMAND not pid — proven necessary when the swaync-client -swb child re-spawned mid-session and a pid intersection would have reported the subscription dead; (2) waybar must be stopped first — it autostarts from hypr/.config/hypr/config/autostart.lua:62 via waybar-launch.sh, and while it runs the reserved array reads [[0,94,0,0]] instead of [[0,48,0,0]], breaking the start/end comparison; (3) the RSS figures across Sections four/four-bis/four-ter are NOT a series and no growth rate may be derived across them — they are different process lifetimes (221928 KiB at 10 min post-boot vs 477016 KiB after a full rebuild session). The recurring obstacle is holding 4h of uninterrupted uptime, not the measurement itself, which takes 5 minutes and has worked first time on every attempt. | fixed |  | 2026-08-11T22:27:29.504Z | 2026-08-12T00:14:57.114Z |
| 66 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md |  | QBAR-11 soak (18-18 Task 4) — LIVE WINDOW, FOURTH anchor. Supersedes rows 52, 64 and 65, all voided: 52 by Phase 18.1's bar rebuild, 64 by a host reboot at 01:09, 65 by the two quickshell restarts spent fixing the bar's hover-to-popout defect (b3e5e5a). Live anchor is 18-BAR-SOAK.md Section four-quater: pid 528309, unit start 2026-08-12 02:40:26 EEST, NRestarts=0, RSS 428640 KiB, wake rate 6.5733/sec (band 5.2586-7.8880), CPU rate 0.001100 cpu-sec/sec (band 0.000825-0.001375), RSS ceiling 461408 KiB, reserved [[0,48,0,0]], waybar count 0, 34 module timers. Earliest valid end capture approximately 06:40:26 EEST. STILL TO RUN: end capture, at least 5 RSS samples spaced through the window, the 200-cycle hide/reveal exercise via bar-visibility.sh verbs, and the verdict. FOUR CONSTRAINTS: (1) resume with PID=528309 and intersect the long-lived-child set by COMMAND not pid — proven necessary when the swaync-client -swb child re-spawned mid-session, where a pid intersection would have reported the subscription dead; (2) stop waybar first — it autostarts from hypr/.config/hypr/config/autostart.lua:62, and while it runs reserved reads [[0,94,0,0]] instead of [[0,48,0,0]], breaking the start/end comparison; (3) the RSS figures across Sections four/four-bis/four-ter/four-quater are NOT a series and no growth rate may be derived across them — four process lifetimes across two builds; (4) this window measures the POST-FIX build where all six bar sections hover-open; earlier anchors measured a build where wifi and audio could not be hover-opened at all. THE FINDING WORTH CARRYING: the window has voided three times and every capture itself took 5 minutes and worked first time. The difficulty of QBAR-11 is holding four uninterrupted hours on a workstation in active use, not taking the measurement. If this recurs, consider whether the requirement should be re-scoped to a window the host can actually hold. | fixed |  | 2026-08-12T00:14:57.214Z | 2026-08-12T12:11:04.623Z |
| 67 | 18 | deviation | quickshell/.config/quickshell/modules/Bar.qml |  | BAR DOES NOT SURVIVE A MONITOR REMOVAL / NO-OUTPUTS EVENT, and its own status verb reports a false positive. Observed live 2026-08-12: at 14:32:51 the log shows 'quickshell.hyprland.ipc: Got removal for monitor "FALLBACK" which was not previously tracked' immediately followed by 'qt.qpa.wayland: There are no outputs - creating placeholder screen'. After the real output returned, the quickshell-bar layer namespace was ABSENT from hyprctl layers and reserved read [[0,0,0,0]], while the shell's own state machine logged 'bar: visibility=visible zone=reserved' — i.e. the shell believed the bar was up and reserving when no surface existed. quickshell itself never died: same pid 528309, NRestarts=0, ActiveState=active, zero QML errors. TWO SEPARATE DEFECTS HERE. (1) The PanelWindow does not re-create its layer surface after the output it was bound to is destroyed and restored — a display sleep/wake or DPMS cycle silently removes the bar for the rest of the session. (2) The owner's designed recovery verb does not recover it and its status verb LIES: `bar-visibility.sh status` printed 'visible' with no surface present, and `bar-visibility.sh reassert` — documented in 18-BAR-SOAK.md Section five as 'the recovery if the status reads anything else' — completed without error and changed nothing. Only `systemctl --user restart quickshell.service` restored it. IMPACT: this is a permanent-liveness defect against QBAR-11's own subject matter, it is invisible to every automated gate in phase 18 (no QML error, service active, status verb green), and it will recur on any monitor sleep. It also means bar-visibility.sh's status output cannot be trusted as evidence that the bar is rendering — any gate or check that greps it is checking intent, not reality. NOT FIXED: found while restoring the operator's desktop, recorded rather than chased at the time. | open |  | 2026-08-12T12:10:22.886Z |  |
| 68 | 18 | unrun-verify | .planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md |  | QBAR-11 soak still OPEN after four anchors. Supersedes rows 52, 64, 65 and 66. The fourth window (pid 528309, 02:40:26 to 15:05 on 2026-08-12) is the first to ELAPSE — etimes 44941s, 12.5 hours, NRestarts=0, single pid, one long-lived child by command — and it still yields no verdict. Full accounting in 18-BAR-SOAK.md Section six. Process gates all PASS. RSS gates FAIL at face value (428640 to 594696 KiB = +162 MiB against a 32 MiB ceiling; about 13.0 MiB/hour against a 5 MiB/hour cap) but that failure is explicitly NOT reported as a leak, for three disqualifying reasons: (1) the window spanned the whole development session that fixed the hover defect, added BarDrawer.qml and fixed four GATE-02 defects, so the config was hot-reloaded many times and every reload re-instantiates the QML tree — a soak is defined against a bar left alone, and this one measured a bar being rebuilt underneath itself; (2) the measurement subject vanished mid-window when the bar layer surface was lost to a monitor-removal event (row 67) and never returned, so for an unknown span nothing was rendering; (3) the 300s end observation, the five spaced RSS samples and the 200-cycle hot-zone exercise were all skipped in favour of restoring the operator's missing bar. WHAT A VALID WINDOW NEEDS: a fifth anchor taken when no development work is planned against quickshell/, held 4 hours with no hot reload, no monitor sleep and no restart, ending in the full Section-five procedure. THE REAL FINDING, now observed four times and worth acting on rather than repeating: this requirement asks for four uninterrupted hours on a workstation that is simultaneously the development target for the code being measured. Every capture took five minutes and worked first time; every window died to something environmental (a rebuild, a reboot, a fix, a monitor sleep). Consider re-scoping QBAR-11 to a window this host can actually hold, or deliberately setting aside a quiescent session for it, rather than re-anchoring a fifth time and hoping. | open |  | 2026-08-12T12:11:20.063Z |  |
| 69 | 18 | deviation | hypr/.config/hypr/scripts/bar-watchdog.sh |  | quick 260812-n9b added quickshell-bar-watchdog.service, a second permanent long-lived process supervising the bar (WINDOWS row 67 workaround). 18-BAR-SOAK.md Section one still states the bar carries exactly one permanent child process — no longer true, not corrected by this plan per its hard constraints. | open |  | 2026-08-12T14:09:51.533Z |  |
| 70 | 18 | deviation | hypr/.config/hypr/scripts/bar-watchdog.sh |  | quick 260812-n9b's watchdog for WINDOWS row 67 is armed and fixture-proven but end-to-end recovery (real monitor-sleep -> surface-loss -> auto-restore) is UNPROVEN — reproducing the trigger is unsafe on this host (row 14, SEGV during a DP-1 hotplug). WINDOWS row 67 stays open. | open |  | 2026-08-12T14:09:51.627Z |  |
| 71 | 19 | unrun-verify | theme-engine/.config/theme-engine/theme-stress-test |  | theme-stress-test cannot reach a full 10-switch clean run: hypr-equivalence-check (folded into theme-doctor) fails on binds.json/animations.json/options.jsonl divergence from its stale Phase-13.1 baseline (predates the v3.0 archive + phases 14-18), plus a structural incompatibility discovered in this session — its col.active_border/col.inactive_border comparison can only ever match the ONE theme the baseline was captured under, so it cannot pass across a multi-theme stress run even after re-baselining. Pre-existing, tracked since Phase 15 (15-audio-connectivity-panels/deferred-items.md item 1); out of scope for 19-03. D-19-45/D-19-46 verified independently via direct theme-apply runs (git clean throughout, pointer survives materialyou-materialyou rsync cycle). | open |  | 2026-08-13T09:53:24.990Z |  |
| 72 | 19 | unrun-verify | quickshell/.config/quickshell/modules/notifications/NotifServer.qml |  | Task 1 human-check not run interactively: DND-on tile-lit-state after a restart, and fullscreen-focused-client suppression path — hyprctl dashboard summon failed on a pre-existing Lua config quirk; persistence/suppression proven via JSON/log inspection instead | open |  | 2026-08-13T12:17:51.925Z |  |
| 73 | 19 | unrun-verify | quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml |  | Task 2 human-check not run interactively: opening the drawer, clicking the DND tile, confirming all six tiles render untruncated with the full two-line label — grid state ownership proven structurally via grep/quickshell-doctor instead | open |  | 2026-08-13T12:17:52.009Z |  |
| 74 | 19 | unrun-verify | quickshell/.config/quickshell/modules/toast/Toast.qml |  | Task 3 human-check not run interactively: visually confirming the toast slides in top-centre with correct on/off copy, self-dismisses after ~2s, and two rapid toggles produce one toast not two — DND was flipped by directly editing the state file, never exercising the real toggleDnd()/dndToggled/show() path | open | RE-DEFERRED (LEDGER-05, 20-02): Phase 20's OSD reuses this exact Toast frame type. Owner: plan 20-08's Gate A, criteria 3 (auto-hide) and 4 (hover-pause) — exercises the identical show()/timer/self-dismiss mechanism this row flags as unproven. | 2026-08-13T12:17:52.097Z |  |
| 75 | 19 | unrun-verify | quickshell/.config/quickshell/modules/centre/NotifCentre.qml |  | Task 1-3 human-check blocks (slide/fade, Escape close, empty-state tint, grouping/clearing live sends, footer sliders, bell/Super+N summon) deferred to end-of-phase UAT per human_verify_mode=end-of-phase | open |  | 2026-08-13T12:43:20.122Z |  |
| 76 | 20 | deviation | quickshell/.config/quickshell/modules/session/PowerMenu.qml |  | Plan 20-06 Task 1's grid design was rejected live and rebuilt to a radial ring; the ring's own Task-1 human-check (7 items, plus the two live-verified bug fixes) has not yet been re-run live against the ring — deferred to the operator per continuation-agent instructions not to press keys/restart the shell. | fixed |  | 2026-08-15T17:56:24.301Z | 2026-08-15T21:25:58.952Z |
| 77 | 20 | deviation | quickshell/.config/quickshell/modules/osd/CapsLockBackend.qml |  | QOSD-02 Caps Lock detector uses a bounded 250ms poll (shared with Osd.qml's recency Timer) instead of the event-driven sysfs watch the plan specified — GATE-01 measured the watch dead on this host; live ON-transition firing on a real physical key press is unverified | fixed |  | 2026-08-15T18:21:21.959Z | 2026-08-15T21:25:59.053Z |
| 78 | 20 | deviation | hypr/.config/hypr/config/keybinds.lua |  | Brightness keybinds now route through BrightnessBackend via a new shell.qml osd IpcHandler instead of a raw brightnessctl exec, fixing the OSD trigger gap 20-04-SUMMARY.md named — unverified since this host has zero backlight-class devices; re-test on real laptop hardware | open |  | 2026-08-15T18:21:26.383Z |  |
| 79 | 20 | unrun-verify | quickshell/.config/quickshell/modules/session/PowerMenu.qml |  | 20-07 Task 1/2/3 human-checks not run live (no restarts/keypresses this session): detector timing, warning chip placement, cascade stagger, OSD suppression, popup dismissal, scrim colour fix | open |  | 2026-08-15T18:48:59.990Z |  |
| 80 | 20 | deviation | quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml |  | MPRIS import trips quickshell-doctor's zero-MPRIS-writer check — pre-existing, unrelated to swayosd, logged in 20-09 deferred-items.md | open |  | 2026-08-16T01:02:25.646Z |  |
| 81 | 20 | deviation | hypr/.config/hypr/config/permissions.lua |  | permissions-allowlist-paths-resolve gate fails (2 missing binary paths, 1 glob pattern) — pre-existing, unrelated to swayosd, logged in 20-09 deferred-items.md | open |  | 2026-08-16T01:02:29.771Z |  |
| 82 | 20 | deviation | hypr/.config/hypr/scripts/media-players.sh |  | eww-media-* cache paths renamed to media-* to close eww's retirement-check blocking tier; narrows 20-RETIREMENT-BASELINE.md's original report-only disposition | fixed |  | 2026-08-16T01:42:29.301Z | 2026-08-16T01:42:48.234Z |
| 83 | 21 | stub | quickshell/.config/quickshell/modules/dashboard/MediaTab.qml |  | Cava-verification overlay (cavaVerifyOverlay/cavaVerifyPath) is deliberately oversized checkpoint-driven scaffolding, not the final visualiser; 21-06 owns normalizing to real proportions per 21-UI-SPEC.md's Visualiser Geometry table | open |  | 2026-08-16T04:51:35.665Z |  |

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
    "reason": "RE-DEFERRED (LEDGER-05, 20-02): the underlying race (hover during entrance stagger) is not artefact-specific — the replacement power grid's entrance cascade (D-20-36) is also not serialised against input readiness. Owner: plan 20-08's Gate B.",
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
    "reason": "RE-DEFERRED (LEDGER-05, 20-02): same disposition family as row 3 — no synthetic real-mouse-hover tool exists on this host, and the gap carries forward unchanged onto the new power-grid surface. Owner: plan 20-08's Gate B (same render-gate record as row 3).",
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
    "reason": "RE-DEFERRED (LEDGER-05, 20-02): the replacement power grid pins Design.sessionTileIconSize (32) explicitly per 20-UI-SPEC.md — a strong fixed-by-construction candidate, but plan 20-06 (which builds it) has not run yet. Owner: plan 20-06 — close once its own acceptance criteria confirm the pinned size renders.",
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
    "status": "waived",
    "reason": "wleave.sh (the fault-injection subject) is deleted whole in plan 20-10, and D-20-23 deletes the availability-probe concept outright: an in-process QML surface has no external-binary-missing failure mode to guard against, so this bug class cannot recur.",
    "recorded_at": "2026-07-25T17:10:45.472Z",
    "resolved_at": "2026-08-15T16:08:48.300Z"
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
    "status": "waived",
    "reason": "D-06 boundary correction (layer-surface exit is client-owned, mechanically proven in 13-01) is a confirmed architectural fact, not a pending defect; the same boundary is inherited correctly by this phase's two new windowrules.lua namespaces.",
    "recorded_at": "2026-07-27T03:43:43.806Z",
    "resolved_at": "2026-08-15T16:08:52.144Z"
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
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-28T13:12:31.315Z",
    "resolved_at": "2026-08-10T23:52:50.674Z"
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
    "description": "WR-04 (13.1-REVIEW.md): the workspace-switch dispatch (`hyprctl dispatch 'hl.dsp.focus({workspace=\"name:ai\"})'`) is guarded by a bash logical-or-true idiom, silently discarding any failure of the one mechanism the script's own header says is the ONLY way to correctly place a Zen AI web-app window on `name:ai` — a failed switch lets the browser launch on whatever workspace is currently active with no error surfaced. Explicitly deferred, not fixed, per gap-closure task scope (out of scope: WR-04/WR-05).",
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
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "15",
    "file": "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml",
    "line": null,
    "description": "pendingGlyph opacity pulse (WifiPanel.qml ~:574-595) and its BluetoothPanel.qml counterpart still bind one-shot emphasizedIn/OutDuration tokens as an infinite pulse period, inheriting the reduced-makes-it-faster inversion G-15-1 fixed for the sweep lines; deliberately left unchanged per 15-11's scope_fence (a pulse's message survives being fast, unlike a sweep's)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T17:07:48.756Z",
    "resolved_at": null
  },
  {
    "id": 24,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/Bar.qml",
    "line": null,
    "description": "18-01 Task 2's <human-check> render gate (pill renders, floats clear of edge, live HH:MM, theme crossfade with no magenta flash) was not run by the executor — automated verify passed; visual confirmation deferred to the user per established project preference (skip-live-verification memory).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-10T23:12:33.140Z",
    "resolved_at": null
  },
  {
    "id": 25,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/Bar.qml",
    "line": null,
    "description": "D-18-31/GATE-02 human render-gate for 18-05 (orientation flip, vertical clock re-stack, theme crossfade in both orientations) not performed by the executor — deferred to the user per established project preference (18-01's identical precedent, WINDOWS entry 24).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T00:13:17.928Z",
    "resolved_at": null
  },
  {
    "id": 26,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-RESTART-PARITY.md",
    "line": null,
    "description": "QBAR-10 destructive restart/rate-limit live proof (SIGTERM retire, SIGKILL restart, 6x SIGKILL rate-limit trip, recovery) and the Task 3 human visual check were deferred to the operator — full runbook provided; only non-destructive systemctl show/is-enabled/systemd-analyze checks were run by the executor",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T00:45:20.302Z",
    "resolved_at": null
  },
  {
    "id": 27,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml",
    "line": null,
    "description": "18-08 Task 3 D-18-31/GATE-02 live render-gate not performed this session: album art, seek slider, player switcher, transport buttons and near-instant external-pause reflection unconfirmed against a real quickshell reload",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T01:11:51.902Z",
    "resolved_at": null
  },
  {
    "id": 28,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/SystemCapsule.qml",
    "line": null,
    "description": "18-08 Task 1/2 D-18-31/GATE-02 live render-gate not performed this session: system capsule cpu/ram/disk/updates not visually confirmed against top/free/df/checkupdates on a live-reloaded bar",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T01:11:57.190Z",
    "resolved_at": null
  },
  {
    "id": 29,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml",
    "line": null,
    "description": "18-08 Task 4 D-18-31/GATE-02 live render-gate not performed this session: audio/network/bluetooth glyph reactions to a real mute/radio toggle, vertical re-stack and theme-switch crossfade unconfirmed on a live-reloaded bar",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T01:11:57.281Z",
    "resolved_at": null
  },
  {
    "id": 30,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/TrayCapsule.qml",
    "line": null,
    "description": "18-10 Task 2 live click-through on a real tray application's real menu row was NOT performed this session — no StatusNotifierWatcher existed on this host's session bus before this plan's Task 1 commit (waybar's athena layout deliberately removed its own tray module), and neither blueman-applet nor nm-applet registered a StatusNotifierItem even after quickshell began self-hosting the watcher. The implemented leaf-activation call (sendTriggered() on the concrete DBusMenuItem) is the highest-ranked candidate by static existence evidence (dbusmenu.hpp:97), not by live observation; RESEARCH.md Open Question 1 remains open pending a user-side click-through on real hardware with a real tray menu.",
    "status": "fixed",
    "reason": "resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists",
    "recorded_at": "2026-08-11T01:40:49.092Z",
    "resolved_at": "2026-08-11T14:47:35.113Z"
  },
  {
    "id": 31,
    "kind": "deviation",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/TrayCapsule.qml",
    "line": null,
    "description": "18-10 Task 3's acceptance criterion 'exactly one Rectangle {} in the file (the menu popup's own)' is unsatisfiable given Task 2's own explicit action text, which separately requires a 1px Colours.outline separator divider and a Colours.surface hover-tint background on menu rows — both need a Rectangle in plain QtQuick. Implemented per Task 2's semantic spec (menuSurface background + one separator-divider Rectangle declared once inside the row Repeater delegate + one hover-tint Rectangle declared once inside the same delegate = 3 Rectangle declaration sites in source), documented as a stale/self-contradictory acceptance-criteria text issue rather than distorting the UI to force a literal count of 1 — mirrors 18-05-SUMMARY.md's own Deviation precedent for this exact class of plan-text conflict.",
    "status": "fixed",
    "reason": "resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists",
    "recorded_at": "2026-08-11T01:41:17.168Z",
    "resolved_at": "2026-08-11T14:47:35.113Z"
  },
  {
    "id": 32,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/TrayCapsule.qml",
    "line": null,
    "description": "18-10 GATE-02 B.5's full visual pass (icons actually rendering and looking correct in both orientations, menu opening and looking correct) was not human-eyeballed this session — no tray application successfully registered a StatusNotifierItem on this host (see the paired unrun-verify entry), so there was nothing to look at. Only the mechanical half was proven live this session: hyprctl reserved-zone and quickshell-bar layer-namespace readings across horizontal -> vertical -> horizontal with zero TrayCapsule.qml load errors at each step. Deferred to the user, same shape as 18-05's own D-18-31 deferral.",
    "status": "fixed",
    "reason": "resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists",
    "recorded_at": "2026-08-11T01:41:17.263Z",
    "resolved_at": "2026-08-11T14:47:35.113Z"
  },
  {
    "id": 33,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml",
    "line": null,
    "description": "D-18-31/GATE-02 human render-gate check for 18-11 not performed by executor (human_verify_mode: end-of-phase) — both drawers open/act, both orientation reach paths, all four extras visible, no literal-text glyph, idle inhibitor genuinely suppresses idle, bell count matches, theme-switch crossfade clean. Deferred to 18-19's blocking GATE-02 pass.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:11:30.945Z",
    "resolved_at": null
  },
  {
    "id": 34,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml",
    "line": null,
    "description": "18-12 Task 1 human-check deferred: live wheel-scroll on audio entry vs wpctl get-volume, both bounds — running quickshell process predates this plan's code",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:24:38.777Z",
    "resolved_at": null
  },
  {
    "id": 35,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml",
    "line": null,
    "description": "18-12 Task 2 human-check deferred: repoint deviceClass to leds, confirm hot-reload renders real percentage, scroll, revert, vertical orientation — running quickshell process predates this plan's code",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:24:38.864Z",
    "resolved_at": null
  },
  {
    "id": 36,
    "kind": "lint-warning",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml",
    "line": 117,
    "description": "Pre-existing untokened color: (cellItem.tint) from 18-11, found by 18-12's file-wide colour-token gate but out of scope (not touched by 18-12)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:24:38.953Z",
    "resolved_at": null
  },
  {
    "id": 37,
    "kind": "lint-warning",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/TrayCapsule.qml",
    "line": 241,
    "description": "Pre-existing untokened color: (\"transparent\") from 18-10, found by 18-12's file-wide colour-token gate but out of scope (not touched by 18-12)",
    "status": "fixed",
    "reason": "resolved by deletion of TrayCapsule.qml in phase 18.1 (D-15) — the subject file no longer exists",
    "recorded_at": "2026-08-11T02:24:39.043Z",
    "resolved_at": "2026-08-11T14:47:35.113Z"
  },
  {
    "id": 38,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/SectionPopout.qml",
    "line": null,
    "description": "18-13 Task 1 human-check not run this session: click-to-open live rendering, hyprctl y=50 confirmation, volume slider moving real system volume, click-outside destruction, 18-12 scroll gesture survival, vertical-orientation placement — deferred (live quickshell process predates this plan's commits).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:48:07.664Z",
    "resolved_at": null
  },
  {
    "id": 39,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/PopoutController.qml",
    "line": null,
    "description": "18-13 Task 2 human-check not run this session: felt 400ms dwell, bar-sweep-opens-nothing proof, diagonal-move-survives-the-gap, pin/Escape/click-outside cycle, no-keystroke-theft typing proof — deferred (live quickshell process predates this plan's commits).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:48:07.772Z",
    "resolved_at": null
  },
  {
    "id": 40,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/AudioPopout.qml",
    "line": null,
    "description": "18-13 Task 3 human-check not run this session: foot-pill visual comparison against a dashboard panel's Advanced button, click-through to AudioPanel.qml, live pending/empty state provocation, theme-switch crossfade check — deferred (live quickshell process predates this plan's commits).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T02:48:07.870Z",
    "resolved_at": null
  },
  {
    "id": 41,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/WifiPopout.qml",
    "line": null,
    "description": "18-14 Task 1 human-check deferred: live scan/discovery negative-check (iw dev / bluetoothctl show) while wifi/bluetooth popouts are open",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T03:14:04.331Z",
    "resolved_at": null
  },
  {
    "id": 42,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/ClockPopout.qml",
    "line": null,
    "description": "18-14 Task 2 human-check deferred: cell-for-cell calendar comparison against the dashboard card and the resources popout's unsampled em-dash state on a fresh shell restart",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T03:14:04.420Z",
    "resolved_at": null
  },
  {
    "id": 43,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/MediaPopout.qml",
    "line": null,
    "description": "18-14 Task 3 human-check deferred: live transport control, multi-player case, and confirming all five foot-link destinations are intact and unthinned",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T03:14:04.512Z",
    "resolved_at": null
  },
  {
    "id": 44,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "hypr/.config/hypr/scripts/bar-visibility.sh",
    "line": null,
    "description": "18-15 Task 3's live per-driver zone-policy proof sequence (qs ipc call bar <verb> round trip against idle/gaming/keybind, plus the hyprctl monitors -j reserved-array deltas) was not run — the live quickshell process predates every commit in this plan and has not been restarted/reloaded, matching the phase's established skip-live-verification precedent (18-08/18-12/18-13).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T03:35:30.387Z",
    "resolved_at": null
  },
  {
    "id": 45,
    "kind": "deviation",
    "phase": "18",
    "file": "quickshell/.config/quickshell/shell.qml",
    "line": null,
    "description": "18-15 Task 2's acceptance grep for 'exactly four functions matching show / hideIdle / hideHard / status' counts 5 whole-file matches, not 4 — a pre-existing overviewIpc.status() (16-04) collides with the regex. barIpc itself declares exactly the specified four functions; the mismatch is in the verify script's scope (whole-file vs. handler-scoped), not a defect in the implementation.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T03:35:37.331Z",
    "resolved_at": null
  },
  {
    "id": 46,
    "kind": "deviation",
    "phase": "18",
    "file": "hypr/.config/hypr/config/keybinds.lua",
    "line": null,
    "description": "18-16 Task 2: held-Super reveal bind (Branch A) drafted then reverted — keybind-doctor's chord-collision check flagged it against the shipped SUPER+SUPER_L tap-to-menu bind at line 86; compositor-side probe not live-verified this session",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T09:26:59.846Z",
    "resolved_at": null
  },
  {
    "id": 47,
    "kind": "unrun-verify",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/BarReveal.qml",
    "line": null,
    "description": "18-16: hot-zone/reveal live gestures (pointer-to-edge reveal, Super-hold reveal, popout-suppression, escape hatch, reserved-array stability, hyprctl layers lifecycle) not exercised — live quickshell process predates this plan's commits ('qs ipc call bar status' -> Target not found), matching 18-08/18-12/18-13/18-15 precedent",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T09:26:59.939Z",
    "resolved_at": null
  },
  {
    "id": 48,
    "kind": "deviation",
    "phase": "18",
    "file": "hypr/.config/hypr/scripts/bar-visibility.sh",
    "line": null,
    "description": "18-17 found and fixed live: qs ipc call bar show (no --) silently fails to invoke on quickshell 0.3.0's qs CLI (literal token 'show' collides with the ipc show subcommand); _ipc_call() now uses 'qs ipc call -- bar $verb'. Never live-tested before 18-17 (18-15-SUMMARY recorded the interactive round-trip as not performed).",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T10:09:37.777Z",
    "resolved_at": "2026-08-11T10:10:14.135Z"
  },
  {
    "id": 49,
    "kind": "deviation",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/bar/BarReveal.qml",
    "line": null,
    "description": "18-17 found and fixed live: BarReveal.qml (18-16 Task 3) declares pragma Singleton and roots on the Singleton {} type but never imports Quickshell (the module that type comes from), so any real quickshell.service restart/reload since 18-16 landed failed with 'Singleton is not a type', taking down the whole bar. Fixed with a one-line import; verified clean on both a full systemd restart and a source-touch hot reload.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T10:10:20.236Z",
    "resolved_at": "2026-08-11T10:10:27.569Z"
  },
  {
    "id": 50,
    "kind": "deviation",
    "phase": "18",
    "file": "hypr/.config/hypr/scripts/quickshell-doctor",
    "line": null,
    "description": "18-17 Task 2 acceptance criterion 'grep -cE ^\\s*trap  returns 1' is stale against pre-existing file state: quickshell-doctor already carried 3 trap lines (EXIT/INT/TERM, all invoking the single _qsd_cleanup) before this plan touched the file. Task 2 extended _qsd_cleanup's body only, installed no new trap statement — the real invariant (one cleanup function, one flag per mutation class) holds; the literal grep count does not and never could on this file.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T10:10:34.633Z",
    "resolved_at": null
  },
  {
    "id": 51,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-FRAME-RATE.md",
    "line": null,
    "description": "LEDGER-03 frame-rate campaign (Task 1 of 18-18) deferred: full methodology and exact resume commands recorded in 18-FRAME-RATE.md, but no condition (C0-C4) was measured this session. Requires stopping quickshell.service to run an unsupervised QSG_RENDER_TIMING instance, and rearranging the live desktop to OVER-04's 8-window/3-workspace load floor (live check: only 4 windows/4 workspaces present). LEDGER-03 stays open; 16-OVER04-MEASUREMENT.md/PROJECT.md/MILESTONES.md not edited.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T10:28:14.163Z",
    "resolved_at": "2026-08-11T22:03:07.085Z"
  },
  {
    "id": 52,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md",
    "line": null,
    "description": "QBAR-11 soak (Task 4 of 18-18) deferred: Task 3's aggregated inventory, pre-declared tolerances, and a real start capture (pid 737907, RSS 450424 KiB, wake rate 19.3429/sec and CPU rate 0.002476 cpu-sec/sec over a genuine 300s observation) are complete in 18-BAR-SOAK.md. Task 4's end capture, 200-cycle hide/reveal exercise, and verdict require at least 14400s of continued single-pid uptime with unchanged NRestarts, which cannot elapse within one session. Exact resume commands recorded in 18-BAR-SOAK.md Section five. QBAR-11 stays open; no verdict asserted.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T10:28:19.689Z",
    "resolved_at": "2026-08-11T22:08:11.418Z"
  },
  {
    "id": 53,
    "kind": "unrun-verify",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/Bar.qml",
    "line": null,
    "description": "18.1-04 Task 1's live restart check (quickshell.log carries no new TrayCapsule-is-not-a-type or unresolved-type QML error line, and the bar renders every remaining capsule in both orientations with the tray gap gone) was NOT performed this session — deferred to the user per established project preference (skip-live-verification memory; same shape as WINDOWS entries 24/25). The hyprctl monitors -j reserved array was compared before and after the edit without a restart (unchanged: [0,46,0,0]), which does not by itself prove the new qmldir/Bar.qml/BarEntryModel.qml code loads without error.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T14:49:54.036Z",
    "resolved_at": null
  },
  {
    "id": 54,
    "kind": "unrun-verify",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml",
    "line": null,
    "description": "18.1-05 Task 3 leg 2 (drawer opening into a moving bar) not live-observed — no synthetic pointer-input tool exists on this host (PROJECT.md-recorded finding); the dwell timer re-evaluating drawerHoverActive/drawerSettled at fire time (not only arm time) is asserted from source instead, per the plan's own stated fallback for this leg. Deferred to 18.1-07's GATE-02 hover walkthrough.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T15:00:44.002Z",
    "resolved_at": null
  },
  {
    "id": 55,
    "kind": "unrun-verify",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml",
    "line": null,
    "description": "18.1-05 Task 3 leg 3 (drawer open when the bar hides) not live-observed — expanding a drawer via real hover, then triggering a bar hide (idle/fullscreen/gaming/keybind) and watching it collapse, needs pointer input this host has no synthetic tool for. Asserted from source instead: onDrawerSettledChanged stops both timers and calls requestCollapse() immediately (no grace) the moment drawerSettled goes false while expanded, and requestExpand() is reachable only from the dwell timer's fire handler which re-gates on drawerSettled, so the drawer cannot mechanically reappear expanded on the next reveal without a fresh hover+dwell cycle. Deferred to 18.1-07's GATE-02 hover walkthrough.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T15:00:51.726Z",
    "resolved_at": null
  },
  {
    "id": 56,
    "kind": "unrun-verify",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml",
    "line": null,
    "description": "18.1-05 Task 3's zero-idle-at-rest check (both drawer timers not running with the pointer away and both drawers collapsed) was not confirmed via live introspection — no QML Timer.running probe/IPC exists on this host to poll it. Asserted from source instead: both drawerDwellTimer/drawerGraceTimer (in LauncherCapsule.qml and ClockActionsCapsule.qml) are repeat:false and are only ever started via .restart() inside onDrawerHoverActiveChanged (armed on a hover-state transition) or onDrawerSettledChanged (only while already expanded) — neither has running:true set unconditionally nor a Component.onCompleted starter, mirroring the same static method BarReveal.qml's own reHideTimer zero-idle claim already relies on.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T15:00:58.131Z",
    "resolved_at": null
  },
  {
    "id": 57,
    "kind": "deviation",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/",
    "line": null,
    "description": "D-20's quickshell-doctor colour-role-routing check exempts the seven SectionPopout-family files (SectionPopout.qml, AudioPopout.qml, WifiPopout.qml, BluetoothPopout.qml, ClockPopout.qml, ResourcesPopout.qml, MediaPopout.qml) by basename — 66 live Colours.* references across those seven files at time of writing. D-06/D-20 as written say the whole of modules/bar/, but phase 18.1's own scope_fence places popout content and the SectionPopout framework explicitly OUT of scope: these are separate anchored surfaces with their own surfaceBase, not bar capsules, and their palette references were never part of the fill-versus-tint defect the check exists to catch. This is a deferred decision, not a closed one — a future phase migrating the popout family onto BarRoles should remove this exemption and shrink QSD_BAR_COLOUR_ROLE_EXEMPT accordingly.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T15:15:17.265Z",
    "resolved_at": null
  },
  {
    "id": 58,
    "kind": "deviation",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/Colours.qml",
    "line": 106,
    "description": "GATE-02 defect 1: BarRoles alpha-blend roles read .r/.g/.b off Colours.qml roles typed property string, not property color, so blended surfaces (capsule/capsuleHover/barSurface/barSurfaceHover/capsuleTrack) resolve to opaque black. Root cause of the operator's GATE-02 FAIL complaint 1. Not fixed in 18.1-07 (recording-only plan).",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T15:40:37.602Z",
    "resolved_at": "2026-08-11T16:45:06.911Z"
  },
  {
    "id": 59,
    "kind": "deviation",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml",
    "line": null,
    "description": "GATE-02 defect 2: bar geometry unmistakably larger than Athena — Design.iconSizeMd (24px) vs Athena's glyph-only 16px, capsule inner padding 8px (Design.spacingSm) vs Athena's 6px 6px; filed out of scope during this phase's Athena audit, which was wrong. Pacman/updates glyph also not optically centred. Root cause of the operator's GATE-02 FAIL complaint 2. Not fixed in 18.1-07 (recording-only plan).",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T15:40:50.375Z",
    "resolved_at": "2026-08-11T16:45:24.824Z"
  },
  {
    "id": 60,
    "kind": "deviation",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml",
    "line": 308,
    "description": "GATE-02 defect 3: drawer expansion reads as sudden/clunky vs Athena's smooth expansion. Container motion IS present (motion.json motion_enabled:true, 375ms emphasized-in MD3 bezier, Behavior on width/height at LauncherCapsule.qml:308-323) but revealed cells appear instantly with no fade/stagger, unlike Athena's transition: all on the members themselves. Not definitively isolated as the sole cause — a lead, not proven. Root cause lead for the operator's GATE-02 FAIL complaint 3. Not fixed in 18.1-07 (recording-only plan).",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T15:40:50.480Z",
    "resolved_at": "2026-08-11T16:45:24.921Z"
  },
  {
    "id": 61,
    "kind": "deviation",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml",
    "line": 50,
    "description": "GATE-02 defect 4: app drawer shows jarring generic icons for apps without a good themed icon. appEntries (LauncherCapsule.qml:50-57) IS the correct predetermined 7-app list matching Athena's custom/app-* set; the divergence is in icon resolution — this phase's D-18-01 icon-theme redesign resolves each entry through the desktop-entry/icon-theme database instead of Athena's one-hardcoded-glyph-per-app approach. D-18-01's redesign is the direct cause and needs revisiting. Root cause of the operator's GATE-02 FAIL complaint 4. Not fixed in 18.1-07 (recording-only plan).",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T15:40:50.580Z",
    "resolved_at": "2026-08-11T16:45:25.018Z"
  },
  {
    "id": 62,
    "kind": "unmet-truth",
    "phase": "18.1",
    "file": "quickshell/.config/quickshell/modules/bar/BarRoles.qml",
    "line": null,
    "description": "GATE-02 verification-method gap: no alpha-blended BarRoles role was ever probed for a resolved numeric value across this phase's automated checks — plan 18.1-01's verification asserted typeof BarRoles.accent === object (a non-alpha role) and never exercised a blended one. Plan 18.1-06's D-20 quickshell-doctor colour-routing check only asserts no direct Colours.* reference survives under modules/bar/; it does not assert a routed role RESOLVES to a real colour. This is why a 100%-black bar (see WINDOWS id 58) passed every automated check in the phase, including the check built specifically to guard bar colour correctness. The check is not wrong, it is insufficient — needs a resolved-value assertion on every alpha role, not just a routing/reference check.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T15:40:50.676Z",
    "resolved_at": "2026-08-11T16:45:25.110Z"
  },
  {
    "id": 63,
    "kind": "deviation",
    "phase": "18",
    "file": "quickshell/.config/quickshell/shell.qml",
    "line": null,
    "description": "18-18 Task 5, option-b (operator decision 2026-08-12): 18-05 widened three SystemResources backend gates all-or-nothing, so switching on cpu/memory/storage for the bar also switched on the GPU and network samplers no bar entry consumes — SystemCapsule.qml reads only cpuFraction/memoryFraction/storageFraction. Measured cost: 900 nvidia-smi subprocess spawns per hour (gpuPollInterval 4000ms -> 3600/4), per 18-BAR-LIVENESS-CHARGE.md's live measurement. Wake/CPU-time share is NOT isolable from the soak's aggregate observation (that figure includes every backend combined); isolating it would need a differential gate-disabled-vs-enabled run, which means editing shell.qml. Remedy is one line of work: add a second, drawer-only gate expression in shell.qml so the GPU and network samplers follow the drawer while cpu/memory/storage follow the bar. Not done in phase 18 — shell.qml is 18-05's file, frozen for wave 3, and five shipped-and-verified plans (18-15, 18-16, 18-17 among them) depend on its current shape. Routed here from 18-08, measured by 18-18, decided by the operator as debt rather than an in-phase scope correction. Citation: 18-BAR-SOAK.md § 'GPU-and-network-sampler cost'.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T21:48:09.267Z",
    "resolved_at": null
  },
  {
    "id": 64,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md",
    "line": null,
    "description": "QBAR-11 soak (18-18 Task 4) — window RE-ANCHORED and now RUNNING as of 2026-08-12 01:00. Supersedes row 52, whose anchor (pid 737907) went void when quickshell restarted during Phase 18.1's bar rebuild. Live anchor is 18-BAR-SOAK.md Section four-bis: pid 262631, unit start 2026-08-12 00:32:15 EEST, NRestarts=0, RSS 477016 KiB, wake rate 6.9533/sec, CPU rate 0.001167 cpu-sec/sec over a real 300s observation, reserved [[0,48,0,0]], quickshell-bar sole namespace. Earliest valid end capture approximately 04:32:15 EEST (unit start + 14400s). STILL TO RUN: the end capture, at least 5 spaced RSS samples through the window, the 200-cycle hide/reveal exercise via bar-visibility.sh's own verbs, and the verdict against the re-anchored threshold table. TWO METHODOLOGY CORRECTIONS carried by the artifact and required of the end capture: (1) intersect the long-lived-child set by COMMAND, not pid — proven live when the swaync-client -swb child re-spawned 262662 -> 424020 mid-session, which a pid intersection would have reported as a dead subscription; (2) the reserved array is [[0,48,0,0]] not [[0,46,0,0]] — Design.barHeight went 40 -> 42 in 18.1 to match upstream Athena, so 18-19's fingerprint and 18-20's parity statement are both stale by 2px and must record the live value with that reason rather than be made to pass. If quickshell restarts before the window elapses, the window voids again and Section four-bis must be re-taken.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T22:08:11.516Z",
    "resolved_at": "2026-08-11T22:27:29.410Z"
  },
  {
    "id": 65,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md",
    "line": null,
    "description": "QBAR-11 soak (18-18 Task 4) — LIVE WINDOW, third anchor. Supersedes rows 52 and 64, both voided (52 by Phase 18.1's bar rebuild, 64 by a host reboot at 01:09 on 2026-08-12). Live anchor is 18-BAR-SOAK.md Section four-ter: pid 1626, unit start 2026-08-12 01:09:39 EEST, NRestarts=0, RSS 221928 KiB, wake rate 10.5767/sec (band 8.4614-12.6920), CPU rate 0.001400 cpu-sec/sec (band 0.00105-0.00175), RSS ceiling 254696 KiB, reserved [[0,48,0,0]], waybar count 0, quickshell-bar sole namespace, 34 module timers. Earliest valid end capture approximately 05:09:39 EEST. STILL TO RUN: end capture, at least 5 RSS samples spaced through the window, the 200-cycle hide/reveal exercise via bar-visibility.sh verbs, and the verdict. THREE CONSTRAINTS the end capture must honour: (1) resume with PID=1626, and intersect the long-lived-child set by COMMAND not pid — proven necessary when the swaync-client -swb child re-spawned mid-session and a pid intersection would have reported the subscription dead; (2) waybar must be stopped first — it autostarts from hypr/.config/hypr/config/autostart.lua:62 via waybar-launch.sh, and while it runs the reserved array reads [[0,94,0,0]] instead of [[0,48,0,0]], breaking the start/end comparison; (3) the RSS figures across Sections four/four-bis/four-ter are NOT a series and no growth rate may be derived across them — they are different process lifetimes (221928 KiB at 10 min post-boot vs 477016 KiB after a full rebuild session). The recurring obstacle is holding 4h of uninterrupted uptime, not the measurement itself, which takes 5 minutes and has worked first time on every attempt.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-11T22:27:29.504Z",
    "resolved_at": "2026-08-12T00:14:57.114Z"
  },
  {
    "id": 66,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md",
    "line": null,
    "description": "QBAR-11 soak (18-18 Task 4) — LIVE WINDOW, FOURTH anchor. Supersedes rows 52, 64 and 65, all voided: 52 by Phase 18.1's bar rebuild, 64 by a host reboot at 01:09, 65 by the two quickshell restarts spent fixing the bar's hover-to-popout defect (b3e5e5a). Live anchor is 18-BAR-SOAK.md Section four-quater: pid 528309, unit start 2026-08-12 02:40:26 EEST, NRestarts=0, RSS 428640 KiB, wake rate 6.5733/sec (band 5.2586-7.8880), CPU rate 0.001100 cpu-sec/sec (band 0.000825-0.001375), RSS ceiling 461408 KiB, reserved [[0,48,0,0]], waybar count 0, 34 module timers. Earliest valid end capture approximately 06:40:26 EEST. STILL TO RUN: end capture, at least 5 RSS samples spaced through the window, the 200-cycle hide/reveal exercise via bar-visibility.sh verbs, and the verdict. FOUR CONSTRAINTS: (1) resume with PID=528309 and intersect the long-lived-child set by COMMAND not pid — proven necessary when the swaync-client -swb child re-spawned mid-session, where a pid intersection would have reported the subscription dead; (2) stop waybar first — it autostarts from hypr/.config/hypr/config/autostart.lua:62, and while it runs reserved reads [[0,94,0,0]] instead of [[0,48,0,0]], breaking the start/end comparison; (3) the RSS figures across Sections four/four-bis/four-ter/four-quater are NOT a series and no growth rate may be derived across them — four process lifetimes across two builds; (4) this window measures the POST-FIX build where all six bar sections hover-open; earlier anchors measured a build where wifi and audio could not be hover-opened at all. THE FINDING WORTH CARRYING: the window has voided three times and every capture itself took 5 minutes and worked first time. The difficulty of QBAR-11 is holding four uninterrupted hours on a workstation in active use, not taking the measurement. If this recurs, consider whether the requirement should be re-scoped to a window the host can actually hold.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-12T00:14:57.214Z",
    "resolved_at": "2026-08-12T12:11:04.623Z"
  },
  {
    "id": 67,
    "kind": "deviation",
    "phase": "18",
    "file": "quickshell/.config/quickshell/modules/Bar.qml",
    "line": null,
    "description": "BAR DOES NOT SURVIVE A MONITOR REMOVAL / NO-OUTPUTS EVENT, and its own status verb reports a false positive. Observed live 2026-08-12: at 14:32:51 the log shows 'quickshell.hyprland.ipc: Got removal for monitor \"FALLBACK\" which was not previously tracked' immediately followed by 'qt.qpa.wayland: There are no outputs - creating placeholder screen'. After the real output returned, the quickshell-bar layer namespace was ABSENT from hyprctl layers and reserved read [[0,0,0,0]], while the shell's own state machine logged 'bar: visibility=visible zone=reserved' — i.e. the shell believed the bar was up and reserving when no surface existed. quickshell itself never died: same pid 528309, NRestarts=0, ActiveState=active, zero QML errors. TWO SEPARATE DEFECTS HERE. (1) The PanelWindow does not re-create its layer surface after the output it was bound to is destroyed and restored — a display sleep/wake or DPMS cycle silently removes the bar for the rest of the session. (2) The owner's designed recovery verb does not recover it and its status verb LIES: `bar-visibility.sh status` printed 'visible' with no surface present, and `bar-visibility.sh reassert` — documented in 18-BAR-SOAK.md Section five as 'the recovery if the status reads anything else' — completed without error and changed nothing. Only `systemctl --user restart quickshell.service` restored it. IMPACT: this is a permanent-liveness defect against QBAR-11's own subject matter, it is invisible to every automated gate in phase 18 (no QML error, service active, status verb green), and it will recur on any monitor sleep. It also means bar-visibility.sh's status output cannot be trusted as evidence that the bar is rendering — any gate or check that greps it is checking intent, not reality. NOT FIXED: found while restoring the operator's desktop, recorded rather than chased at the time.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-12T12:10:22.886Z",
    "resolved_at": null
  },
  {
    "id": 68,
    "kind": "unrun-verify",
    "phase": "18",
    "file": ".planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md",
    "line": null,
    "description": "QBAR-11 soak still OPEN after four anchors. Supersedes rows 52, 64, 65 and 66. The fourth window (pid 528309, 02:40:26 to 15:05 on 2026-08-12) is the first to ELAPSE — etimes 44941s, 12.5 hours, NRestarts=0, single pid, one long-lived child by command — and it still yields no verdict. Full accounting in 18-BAR-SOAK.md Section six. Process gates all PASS. RSS gates FAIL at face value (428640 to 594696 KiB = +162 MiB against a 32 MiB ceiling; about 13.0 MiB/hour against a 5 MiB/hour cap) but that failure is explicitly NOT reported as a leak, for three disqualifying reasons: (1) the window spanned the whole development session that fixed the hover defect, added BarDrawer.qml and fixed four GATE-02 defects, so the config was hot-reloaded many times and every reload re-instantiates the QML tree — a soak is defined against a bar left alone, and this one measured a bar being rebuilt underneath itself; (2) the measurement subject vanished mid-window when the bar layer surface was lost to a monitor-removal event (row 67) and never returned, so for an unknown span nothing was rendering; (3) the 300s end observation, the five spaced RSS samples and the 200-cycle hot-zone exercise were all skipped in favour of restoring the operator's missing bar. WHAT A VALID WINDOW NEEDS: a fifth anchor taken when no development work is planned against quickshell/, held 4 hours with no hot reload, no monitor sleep and no restart, ending in the full Section-five procedure. THE REAL FINDING, now observed four times and worth acting on rather than repeating: this requirement asks for four uninterrupted hours on a workstation that is simultaneously the development target for the code being measured. Every capture took five minutes and worked first time; every window died to something environmental (a rebuild, a reboot, a fix, a monitor sleep). Consider re-scoping QBAR-11 to a window this host can actually hold, or deliberately setting aside a quiescent session for it, rather than re-anchoring a fifth time and hoping.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-12T12:11:20.063Z",
    "resolved_at": null
  },
  {
    "id": 69,
    "kind": "deviation",
    "phase": "18",
    "file": "hypr/.config/hypr/scripts/bar-watchdog.sh",
    "line": null,
    "description": "quick 260812-n9b added quickshell-bar-watchdog.service, a second permanent long-lived process supervising the bar (WINDOWS row 67 workaround). 18-BAR-SOAK.md Section one still states the bar carries exactly one permanent child process — no longer true, not corrected by this plan per its hard constraints.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-12T14:09:51.533Z",
    "resolved_at": null
  },
  {
    "id": 70,
    "kind": "deviation",
    "phase": "18",
    "file": "hypr/.config/hypr/scripts/bar-watchdog.sh",
    "line": null,
    "description": "quick 260812-n9b's watchdog for WINDOWS row 67 is armed and fixture-proven but end-to-end recovery (real monitor-sleep -> surface-loss -> auto-restore) is UNPROVEN — reproducing the trigger is unsafe on this host (row 14, SEGV during a DP-1 hotplug). WINDOWS row 67 stays open.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-12T14:09:51.627Z",
    "resolved_at": null
  },
  {
    "id": 71,
    "kind": "unrun-verify",
    "phase": "19",
    "file": "theme-engine/.config/theme-engine/theme-stress-test",
    "line": null,
    "description": "theme-stress-test cannot reach a full 10-switch clean run: hypr-equivalence-check (folded into theme-doctor) fails on binds.json/animations.json/options.jsonl divergence from its stale Phase-13.1 baseline (predates the v3.0 archive + phases 14-18), plus a structural incompatibility discovered in this session — its col.active_border/col.inactive_border comparison can only ever match the ONE theme the baseline was captured under, so it cannot pass across a multi-theme stress run even after re-baselining. Pre-existing, tracked since Phase 15 (15-audio-connectivity-panels/deferred-items.md item 1); out of scope for 19-03. D-19-45/D-19-46 verified independently via direct theme-apply runs (git clean throughout, pointer survives materialyou-materialyou rsync cycle).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T09:53:24.990Z",
    "resolved_at": null
  },
  {
    "id": 72,
    "kind": "unrun-verify",
    "phase": "19",
    "file": "quickshell/.config/quickshell/modules/notifications/NotifServer.qml",
    "line": null,
    "description": "Task 1 human-check not run interactively: DND-on tile-lit-state after a restart, and fullscreen-focused-client suppression path — hyprctl dashboard summon failed on a pre-existing Lua config quirk; persistence/suppression proven via JSON/log inspection instead",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T12:17:51.925Z",
    "resolved_at": null
  },
  {
    "id": 73,
    "kind": "unrun-verify",
    "phase": "19",
    "file": "quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml",
    "line": null,
    "description": "Task 2 human-check not run interactively: opening the drawer, clicking the DND tile, confirming all six tiles render untruncated with the full two-line label — grid state ownership proven structurally via grep/quickshell-doctor instead",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T12:17:52.009Z",
    "resolved_at": null
  },
  {
    "id": 74,
    "kind": "unrun-verify",
    "phase": "19",
    "file": "quickshell/.config/quickshell/modules/toast/Toast.qml",
    "line": null,
    "description": "Task 3 human-check not run interactively: visually confirming the toast slides in top-centre with correct on/off copy, self-dismisses after ~2s, and two rapid toggles produce one toast not two — DND was flipped by directly editing the state file, never exercising the real toggleDnd()/dndToggled/show() path",
    "status": "open",
    "reason": "RE-DEFERRED (LEDGER-05, 20-02): Phase 20's OSD reuses this exact Toast frame type. Owner: plan 20-08's Gate A, criteria 3 (auto-hide) and 4 (hover-pause) — exercises the identical show()/timer/self-dismiss mechanism this row flags as unproven.",
    "recorded_at": "2026-08-13T12:17:52.097Z",
    "resolved_at": null
  },
  {
    "id": 75,
    "kind": "unrun-verify",
    "phase": "19",
    "file": "quickshell/.config/quickshell/modules/centre/NotifCentre.qml",
    "line": null,
    "description": "Task 1-3 human-check blocks (slide/fade, Escape close, empty-state tint, grouping/clearing live sends, footer sliders, bell/Super+N summon) deferred to end-of-phase UAT per human_verify_mode=end-of-phase",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T12:43:20.122Z",
    "resolved_at": null
  },
  {
    "id": 76,
    "kind": "deviation",
    "phase": "20",
    "file": "quickshell/.config/quickshell/modules/session/PowerMenu.qml",
    "line": null,
    "description": "Plan 20-06 Task 1's grid design was rejected live and rebuilt to a radial ring; the ring's own Task-1 human-check (7 items, plus the two live-verified bug fixes) has not yet been re-run live against the ring — deferred to the operator per continuation-agent instructions not to press keys/restart the shell.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-15T17:56:24.301Z",
    "resolved_at": "2026-08-15T21:25:58.952Z"
  },
  {
    "id": 77,
    "kind": "deviation",
    "phase": "20",
    "file": "quickshell/.config/quickshell/modules/osd/CapsLockBackend.qml",
    "line": null,
    "description": "QOSD-02 Caps Lock detector uses a bounded 250ms poll (shared with Osd.qml's recency Timer) instead of the event-driven sysfs watch the plan specified — GATE-01 measured the watch dead on this host; live ON-transition firing on a real physical key press is unverified",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-15T18:21:21.959Z",
    "resolved_at": "2026-08-15T21:25:59.053Z"
  },
  {
    "id": 78,
    "kind": "deviation",
    "phase": "20",
    "file": "hypr/.config/hypr/config/keybinds.lua",
    "line": null,
    "description": "Brightness keybinds now route through BrightnessBackend via a new shell.qml osd IpcHandler instead of a raw brightnessctl exec, fixing the OSD trigger gap 20-04-SUMMARY.md named — unverified since this host has zero backlight-class devices; re-test on real laptop hardware",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-15T18:21:26.383Z",
    "resolved_at": null
  },
  {
    "id": 79,
    "kind": "unrun-verify",
    "phase": "20",
    "file": "quickshell/.config/quickshell/modules/session/PowerMenu.qml",
    "line": null,
    "description": "20-07 Task 1/2/3 human-checks not run live (no restarts/keypresses this session): detector timing, warning chip placement, cascade stagger, OSD suppression, popup dismissal, scrim colour fix",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-15T18:48:59.990Z",
    "resolved_at": null
  },
  {
    "id": 80,
    "kind": "deviation",
    "phase": "20",
    "file": "quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml",
    "line": null,
    "description": "MPRIS import trips quickshell-doctor's zero-MPRIS-writer check — pre-existing, unrelated to swayosd, logged in 20-09 deferred-items.md",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-16T01:02:25.646Z",
    "resolved_at": null
  },
  {
    "id": 81,
    "kind": "deviation",
    "phase": "20",
    "file": "hypr/.config/hypr/config/permissions.lua",
    "line": null,
    "description": "permissions-allowlist-paths-resolve gate fails (2 missing binary paths, 1 glob pattern) — pre-existing, unrelated to swayosd, logged in 20-09 deferred-items.md",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-16T01:02:29.771Z",
    "resolved_at": null
  },
  {
    "id": 82,
    "kind": "deviation",
    "phase": "20",
    "file": "hypr/.config/hypr/scripts/media-players.sh",
    "line": null,
    "description": "eww-media-* cache paths renamed to media-* to close eww's retirement-check blocking tier; narrows 20-RETIREMENT-BASELINE.md's original report-only disposition",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-16T01:42:29.301Z",
    "resolved_at": "2026-08-16T01:42:48.234Z"
  },
  {
    "id": 83,
    "kind": "stub",
    "phase": "21",
    "file": "quickshell/.config/quickshell/modules/dashboard/MediaTab.qml",
    "line": null,
    "description": "Cava-verification overlay (cavaVerifyOverlay/cavaVerifyPath) is deliberately oversized checkpoint-driven scaffolding, not the final visualiser; 21-06 owns normalizing to real proportions per 21-UI-SPEC.md's Visualiser Geometry table",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-16T04:51:35.665Z",
    "resolved_at": null
  }
]
````
