-- poisoned-collision-keybinds.lua — derived from compliant-keybinds.lua
-- (itself a trimmed excerpt of the real, shipped keybinds.lua) with
-- exactly one defect introduced: a second bind, `Super + A`, claiming
-- the SAME chord as the audio-panel global dispatch, whose dispatcher
-- is a plain exec_cmd rather than the matching `hl.dsp.global(...)`
-- registration. Target check: panel-shortcut-single-registration
-- (delegated to keybind-doctor's static chord-collision check).
-- Expected verdict: FAIL (keybind-doctor's own chord-collision logic,
-- lines 586-616, flags a second Hyprland-declared bind claiming a
-- chord the manifest already owns without going through the matching
-- global dispatcher).

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty")) -- Open terminal
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon the dashboard drawer (DASH-01)
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:audio-panel")) -- Summon audio mixer panel (PANEL-02)
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pavucontrol")) -- POISON: collides with the audio-panel chord, no matching global()
hl.bind(mainMod .. " + C", hl.dsp.window.kill_active()) -- Close active window
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("systemctl --user restart quickshell.service")) -- Emergency: restart the shell
