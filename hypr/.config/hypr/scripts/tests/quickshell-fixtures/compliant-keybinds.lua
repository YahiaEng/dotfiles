-- compliant-keybinds.lua — captured 2026-08-02 as a trimmed excerpt of
-- the real, shipped hypr/.config/hypr/config/keybinds.lua: the
-- `local mainMod = "SUPER"` declaration keybind-doctor's own
-- MAINMOD_VALUE resolution requires, plus the real Super+A audio-panel
-- global-dispatch bind (line 188 of the shipped file) and a handful of
-- unrelated real binds for shape realism. Target check:
-- panel-shortcut-single-registration (delegated to keybind-doctor's
-- static chord-collision check). Expected verdict: PASS (keybind-doctor
-- exits 0 — no bind collides with the audio-panel chord).

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty")) -- Open terminal
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon the dashboard drawer (DASH-01)
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:audio-panel")) -- Summon audio mixer panel (PANEL-02)
hl.bind(mainMod .. " + C", hl.dsp.window.kill_active()) -- Close active window
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("systemctl --user restart quickshell.service")) -- Emergency: restart the shell
