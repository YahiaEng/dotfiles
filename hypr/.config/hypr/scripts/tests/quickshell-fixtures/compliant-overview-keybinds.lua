-- compliant-overview-keybinds.lua — captured 2026-08-03 as a trimmed
-- excerpt of the real, shipped hypr/.config/hypr/config/keybinds.lua: the
-- `local mainMod = "SUPER"` declaration keybind-doctor's own MAINMOD_VALUE
-- resolution requires, plus the real Super+O overview global-dispatch bind
-- and a handful of unrelated real binds for shape realism. Target check:
-- overview-shortcut-single-registration (delegated to keybind-doctor's
-- static chord-collision check). Expected verdict: PASS (keybind-doctor
-- exits 0 — no bind collides with the overview chord).

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty")) -- Open terminal
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon the dashboard drawer (DASH-01)
hl.bind(mainMod .. " + O", hl.dsp.global("quickshell:overview")) -- Summon the workspace overview (OVER-01)
hl.bind(mainMod .. " + C", hl.dsp.window.kill_active()) -- Close active window
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("pkill walker")) -- Emergency: force-close walker
