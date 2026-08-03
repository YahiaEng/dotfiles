-- poisoned-collision-overview-keybinds.lua — derived from
-- compliant-overview-keybinds.lua (itself a trimmed excerpt of the real,
-- shipped keybinds.lua) with exactly one defect introduced: a second bind,
-- `Super + O`, claiming the SAME chord as the overview global dispatch,
-- whose dispatcher is a plain exec_cmd rather than the matching
-- `hl.dsp.global(...)` registration. Target check:
-- overview-shortcut-single-registration (delegated to keybind-doctor's
-- static chord-collision check). Expected verdict: FAIL (keybind-doctor's
-- own chord-collision logic flags a second Hyprland-declared bind claiming
-- a chord the manifest already owns without going through the matching
-- global dispatcher).

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty")) -- Open terminal
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon the dashboard drawer (DASH-01)
hl.bind(mainMod .. " + O", hl.dsp.global("quickshell:overview")) -- Summon the workspace overview (OVER-01)
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("wlogout")) -- POISON: collides with the overview chord, no matching global()
hl.bind(mainMod .. " + C", hl.dsp.window.kill_active()) -- Close active window
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("pkill walker")) -- Emergency: force-close walker
