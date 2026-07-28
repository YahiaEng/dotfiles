-- motion-lint fixture (13.1-06, D-28).
-- Derives from compliant-hypr.lua, corrupting the animation leaf's BEZIER
-- field to reference a curve name the pipeline does not emit — the
-- Lua-side equivalent of poisoned-dangling-hypr.conf's dangling curve
-- reference. Never required by any live Hyprland config — motion-lint
-- self-test fixture only.
local tokens = require("lib.tokens").get()

local registered_curves = {}
for name, spec in pairs(tokens.motion.curves) do
    hl.curve("motion-" .. name, spec)
    registered_curves["motion-" .. name] = true
end

if tokens.motion.speed.standard ~= nil then
    hl.animation({
        leaf = "windowsIn",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-nonexistent", -- CORRUPTED: was "motion-standard"
        style = "popin 60%",
    })
end
