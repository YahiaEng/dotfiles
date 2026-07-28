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

-- Primary monitor — 2160x1440 @ 165Hz
-- Adjust the name (DP-1, HDMI-A-1, etc.) to match your output.
-- Run `hyprctl monitors` to find the correct name.
hl.monitor({
    output = "DP-1",
    mode = "2560x1440@165",
    position = "0x0",
    scale = 1,
})

-- Unknown-1 fallback: this repo's live session has, at times, reported the
-- physical output as "Unknown-1" rather than "DP-1" (see PROJECT.md /
-- 91482df) — this second declaration is a deliberate duplicate covering
-- both names, byte-identical in every other field to the DP-1 entry
-- above. Carried over unchanged; not migration noise.
hl.monitor({
    output = "Unknown-1",
    mode = "2560x1440@165",
    position = "0x0",
    scale = 1,
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
