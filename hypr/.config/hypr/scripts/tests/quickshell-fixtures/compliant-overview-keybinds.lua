-- compliant-overview-keybinds.lua — captured 2026-08-03 as a trimmed
-- excerpt of the real, shipped hypr/.config/hypr/config/keybinds.lua: the
-- `local mainMod = "SUPER"` declaration keybind-doctor's own MAINMOD_VALUE
-- resolution requires, plus the real overview global-dispatch bind and a
-- handful of unrelated real binds for shape realism. Target check:
-- overview-shortcut-single-registration (delegated to keybind-doctor's
-- static chord-collision check). Expected verdict: PASS — no bind collides
-- with the overview chord.
--
-- CHORD RE-POINTED Super+O -> Super+Tab on 2026-08-26 (quick task
-- 260826-qr1). The shipped bind moved to Super+Tab (keybinds.lua:265) and
-- neither this fixture nor shortcuts.json followed. Two consequences, both
-- now closed: keybind-doctor's `declared-vs-registered` check compared this
-- fixture's stale Super+O against live `hyprctl binds` and failed — which
-- the caller printed as a chord-collision verdict, the mislabelled 58/1 —
-- and the collision check itself went blind, since it hunts the chord the
-- MANIFEST names and nothing bound Super+O any more.
--
-- Keep this chord equal to shortcuts.json's overview entry and to
-- keybinds.lua's own bind. If it drifts again, the collision half of this
-- fixture stops proving anything.

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty")) -- Open terminal
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon the dashboard drawer (DASH-01)
hl.bind(mainMod .. " + Tab", hl.dsp.global("quickshell:overview")) -- Summon the workspace overview (OVER-01)
hl.bind(mainMod .. " + C", hl.dsp.window.kill_active()) -- Close active window
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("systemctl --user restart quickshell.service")) -- Emergency: restart the shell
