-- poisoned-collision-overview-keybinds.lua — derived from
-- compliant-overview-keybinds.lua (itself a trimmed excerpt of the real,
-- shipped keybinds.lua) with exactly one defect introduced: a second bind
-- claiming the SAME chord as the overview global dispatch, whose
-- dispatcher is a plain exec_cmd rather than the matching
-- `hl.dsp.global(...)` registration. Target check:
-- overview-shortcut-single-registration (delegated to keybind-doctor's
-- static chord-collision check). Expected verdict: FAIL (keybind-doctor's
-- own chord-collision logic flags a second Hyprland-declared bind claiming
-- a chord the manifest already owns without going through the matching
-- global dispatcher).
--
-- CHORD RE-POINTED Super+O -> Super+Tab on 2026-08-26 (quick task
-- 260826-qr1), in the same commit that re-pointed shortcuts.json's overview
-- entry. THIS FIXTURE'S POISON DEPENDS ON THAT MANIFEST CHORD: the
-- collision check walks the manifest's chords and flags declared binds that
-- claim one without the matching `hl.dsp.global(...)`. Had only the
-- manifest moved, the poison below would have kept claiming Super+O, which
-- the manifest no longer owns, and this fixture would have gone quietly
-- green — a poisoned fixture that no longer bites. Both lines move together
-- or neither does.

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty")) -- Open terminal
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon the dashboard drawer (DASH-01)
hl.bind(mainMod .. " + Tab", hl.dsp.global("quickshell:overview")) -- Summon the workspace overview (OVER-01)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("some-other-binary")) -- POISON: collides with the overview chord, no matching global()
hl.bind(mainMod .. " + C", hl.dsp.window.kill_active()) -- Close active window
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("systemctl --user restart quickshell.service")) -- Emergency: restart the shell
