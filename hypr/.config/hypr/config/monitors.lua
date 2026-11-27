local overrides = require("lib.overrides").get().monitors
local weaselway = os.getenv("AQ_DRM_DEVICES") == "/dev/dri/by-path/platform-dxgdrm-card"
local defaultScale = weaselway and 1 or "auto"

local function setMonitor(output, monitor)
    hl.monitor({
        output = output,
        mode = monitor.mode or "preferred",
        position = monitor.position or "auto",
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

-- The preferred DRM mode uses viewer pixels. The layout file carries the
-- corresponding logical positions and per-display scales.
if weaselway then
    local displays = {}
    local runtime = os.getenv("XDG_RUNTIME_DIR")
    local layout = runtime and io.open(runtime .. "/arch-hyprland-displays")
    if layout then
        for line in layout:lines() do
            local output, position, scale = line:match("^(Virtual%-[1-4]) (%d+x%d+) ([%d.]+)$")
            if not output then
                output, position = line:match("^(Virtual%-[1-4]) (%d+x%d+)$")
            end
            if output then displays[output] = { position = position, scale = tonumber(scale) } end
        end
        layout:close()
    end
    for i = 1, 4 do
        local output = "Virtual-" .. i
        local saved = overrides[output]
        setMonitor(output, displays[output] or (type(saved) == "table" and saved or {}))
        hl.device({ name = "weaselway-touchscreen-" .. i, output = output })
    end
    hl.config({ cursor = { default_monitor = "Virtual-1", no_hardware_cursors = false } })
end

-- ── Xwayland ─────────────────────────────────────────
hl.config({
    xwayland = {
        -- Let Hyprland scale legacy X11 surfaces in the WSL desktop too.
        force_zero_scaling = not weaselway,
    },
})
