-- motion-lint fixture (13.1-06, D-28).
-- Derives from compliant-hypr.lua, corrupting the animation leaf's SPEED
-- field back to a raw hand-authored number instead of a
-- tokens.motion.speed.* reference — the Lua-side equivalent of
-- poisoned-raw-hypr.conf's raw speed literal. Never required by any live
-- Hyprland config — motion-lint self-test fixture only.
local tokens = require("lib.tokens").get()

local registered_curves = {}
for name, spec in pairs(tokens.motion.curves) do
    hl.curve("motion-" .. name, spec)
    registered_curves["motion-" .. name] = true
end

if registered_curves["motion-standard"] then
    hl.animation({
        leaf = "windowsIn",
        enabled = true,
        speed = 5, -- CORRUPTED: was tokens.motion.speed.standard
        bezier = "motion-standard",
        style = "popin 60%",
    })
end
