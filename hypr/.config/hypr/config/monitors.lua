-- hypr/.config/hypr/config/monitors.lua — Lua port of config/monitors.conf
-- (Phase 13.1, plan 13.1-03 Task 2). Value and order parity with the
-- hyprlang original — nothing added/removed/retuned (CONTEXT.md
-- prohibition). The monitor-declaration field spelling
-- (output/mode/position/scale) and hl.config's xwayland.force_zero_scaling
-- are both permitted sources: output/mode/position/scale come from
-- HL.MonitorSpec (hl.meta.lua) and from the vendor example's own monitor-
-- declaration call (`{ output=..., mode=..., position=..., scale=... }`);
-- xwayland.force_zero_scaling comes from HL.ConfigOpt.Xwayland
-- (hl.meta.lua ~L1637-1641).
--
-- Quick task 260820-sqd, Task 3: `local ov = require("lib.overrides").get()`
-- called independently here (not reading a value some previously-loaded
-- module set — lib.overrides.get()'s own header explains why that
-- independence matters). Each field keeps its CURRENT literal as the `or`
-- fallback — D-13's "a missing/corrupt overrides file degrades to today's
-- defaults, never blocks compositor startup" guarantee. Merged at the
-- TABLE level, exactly one `hl.monitor()` call per output (RESEARCH.md A2:
-- whether a second call for the same output replaces or appends is
-- unmeasured, so never emit two).
local ov = require("lib.overrides").get()

-- Primary monitor — 2160x1440 @ 165Hz
-- Adjust the name (DP-1, HDMI-A-1, etc.) to match your output.
-- Run `hyprctl monitors` to find the correct name.
hl.monitor({
    output = "DP-1",
    mode = (ov.monitors["DP-1"] or {}).mode or "2560x1440@165",
    position = (ov.monitors["DP-1"] or {}).position or "0x0",
    scale = (ov.monitors["DP-1"] or {}).scale or 1,
})

-- Unknown-1 fallback: this repo's live session has, at times, reported the
-- physical output as "Unknown-1" rather than "DP-1" (see PROJECT.md /
-- 91482df) — this second declaration is a deliberate duplicate covering
-- both names, byte-identical in every other field to the DP-1 entry
-- above. Carried over unchanged; not migration noise. Reads its OWN
-- "Unknown-1" override key, never the "DP-1" one — the two outputs are
-- never assumed to be the same physical monitor by this override layer.
hl.monitor({
    output = "Unknown-1",
    mode = (ov.monitors["Unknown-1"] or {}).mode or "2560x1440@165",
    position = (ov.monitors["Unknown-1"] or {}).position or "0x0",
    scale = (ov.monitors["Unknown-1"] or {}).scale or 1,
})

-- Fallback for any additional monitors — uncomment and fill in a monitor
-- declaration with output = "", mode = "preferred", position = "auto",
-- scale = "auto" if one is ever needed.

-- ── Xwayland ─────────────────────────────────────────
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
