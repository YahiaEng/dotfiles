-- motion-lint fixture (13.1-06, D-28).
-- Mirrors compliant-hypr.conf's shape for the Lua config surface: every
-- value is reached through the token accessor, never a hand-rolled
-- duration or bezier control point. Never required by any live Hyprland
-- config — motion-lint self-test fixture only.
local tokens = require("lib.tokens").get()

local registered_curves = {}
for name, spec in pairs(tokens.motion.curves) do
    hl.curve("motion-" .. name, spec)
    registered_curves["motion-" .. name] = true
end

if tokens.motion.speed.standard ~= nil and registered_curves["motion-standard"] then
    hl.animation({
        leaf = "windowsIn",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-standard",
        style = "popin 60%",
    })
end
