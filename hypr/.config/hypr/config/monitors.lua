local overrides = require("lib.overrides").get().monitors
local weaselway = os.getenv("AQ_DRM_DEVICES") == "/dev/dri/by-path/platform-dxgdrm-card"
local defaultScale = weaselway and 1 or "auto"

local function setMonitor(output, monitor, position)
    hl.monitor({
        output = output,
        mode = monitor.mode or "preferred",
        position = monitor.position or position or "auto",
        scale = monitor.scale or defaultScale,
    })
end

-- Let Hyprland place newly connected outputs and choose their EDID mode.
setMonitor("", {})
for output, monitor in pairs(overrides) do
    if type(monitor) == "table" and not (weaselway and output:match("^Virtual%-[1-4]$")) then
        setMonitor(output, monitor)
    end
end

-- Weaselway advertises the viewer's dimensions as the preferred DRM mode.
-- Keep a windowed viewer usable at small resolutions with a 1x default.
if weaselway then
    local positions = {}
    local runtime = os.getenv("XDG_RUNTIME_DIR")
    local layout = runtime and io.open(runtime .. "/arch-hyprland-displays")
    if layout then
        for line in layout:lines() do
            local output, position = line:match("^(Virtual%-[1-4]) (%d+x%d+)$")
            if output then positions[output] = position end
        end
        layout:close()
    end
    for i = 1, 4 do
        local output = "Virtual-" .. i
        -- Windows positions and viewer pixels describe the same 1x layout.
        local monitor = not positions[output] and type(overrides[output]) == "table" and overrides[output] or {}
        setMonitor(output, monitor, positions[output])
        hl.device({ name = "weaselway-touchscreen-" .. i, output = output })
    end
    hl.config({ cursor = { default_monitor = "Virtual-1", no_hardware_cursors = false } })
end

-- ── Xwayland ─────────────────────────────────────────
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
