-- hypr/.config/hypr/hyprland.lua — top-level Lua config entry point.
-- This IS the live, load-bearing compositor entry point: Hyprland selects
-- its config format at startup purely by whether hyprland.lua exists in
-- the config root, and this repo's cutover (Phase 13.1, plan 13.1-08)
-- already happened — the legacy hyprland.conf and its seven
-- hyprlang config/*.conf siblings were deleted outright by the
-- retirement plan (13.1-10). If this file is wrong, the machine does not
-- boot. There is no `.disabled`-suffixed copy anywhere in this repo any
-- more, and no hyprlang fallback path exists to catch a mistake here.
--
-- WR-03 (13.1-REVIEW.md gap-closure, 2026-07-28): this header previously
-- described this file as the pre-cutover `hyprland.lua.disabled` staging
-- copy — that state is now history, not a currently-enforced invariant.
-- For that pre-cutover history (why the `.disabled` staging convention
-- existed, and the rename-at-cutover process), see `13.1-08-SUMMARY.md`
-- and `13.1-EQUIVALENCE-REPORT.md`; for safely test-driving a FUTURE
-- change to this file without touching the live compositor, see
-- `hypr/.config/hypr/scripts/hypr-lua-harness` (repaired post-cutover to
-- accept an explicit `--entry <path>` argument, defaulting to this very
-- file).
--
-- This entry point is at its FINAL require shape (reached at plan
-- 13.1-03 Task 2, unchanged since): all seven config modules are
-- required below, in the same relative order the retired hyprland.conf's
-- own `source =` lines used to list them. Every one of the seven is now
-- fully ported, live content — none are placeholder modules any more.
--
-- Ordering below is PRESENTATIONAL ONLY, not load-bearing the way
-- hyprland.conf lines 11-16 warn hyprlang's own source order is (that
-- warning existed because animations.conf reads a hyprlang variable
-- `env.conf`'s sibling motion fragment defines, and hyprlang variables
-- are resolved at the point of use during a strictly sequential parse).
-- Under Lua, no module reads a value a previously-loaded module happened
-- to set — every module that needs the generated token table calls
-- `require("lib.tokens").get()` itself (see `local tokens = ...` below,
-- and `config/env.lua`'s own independent call is not needed since it has
-- no token dependency). That property, not the require order, is what
-- makes D-13 hold under Lua.

local tokens = require("lib.tokens").get()

require("config.env")
require("config.monitors")
require("config.autostart")
require("config.animations")
require("config.keybinds")
require("config.windowrules")
require("config.permissions")

-- general block — hyprland.conf lines 27-35, reproduced exactly. Every
-- colour comes from the generated token table with an `or` fallback to the
-- literal value the hyprlang emitter produces today for the currently
-- applied theme (dracula, read from ~/.local/state/theme/hyprland.conf at
-- authoring time) — this `or` is where D-13's "a missing token degrades to
-- a default, never blocking compositor startup" guarantee actually lives;
-- stow.sh's seed-by-invoking-the-real-renderer guarantee is the belt, this
-- is the braces.
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 3,
        col = {
            active_border = {
                colors = {
                    tokens.colors.primary or "rgba(ff79c6ff)",
                    tokens.colors.secondary or "rgba(bd93f9ff)",
                    tokens.colors.tertiary or "rgba(8be9fdff)",
                },
                angle = 45,
            },
            inactive_border = tokens.colors.outline or "rgba(6272a4ff)",
        },
        layout = "dwindle",
        allow_tearing = false,
    },

    -- input block — hyprland.conf lines 38-45, reproduced exactly. No
    -- token dependency (no colour/motion value in this block).
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },

    -- decoration block — hyprland.conf lines 48-74, reproduced exactly.
    -- decoration:shadow:color's accepted Lua form was the one open
    -- question this block carried (13.1-04 Task 1): the quoted-string
    -- form (`"rgba(00000055)"`, byte-identical to the hyprlang literal)
    -- was tried first and reads back correctly — see
    -- 13.1-LUA-FINDINGS.md's "Option readback divergences" section.
    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        fullscreen_opacity = 1.0,

        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            xray = true,
            noise = 0.02,
            contrast = 0.9,
            brightness = 0.8,
            vibrancy = 0.2,
            vibrancy_darkness = 0.5,
        },

        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = "rgba(00000055)",
            offset = { 0, 4 },
        },
    },

    -- dwindle block — hyprland.conf lines 77-82. `pseudotile` is
    -- commented out in the hyprlang source (line 78) and stays unset
    -- here — a commented line is not a value to port (CONTEXT.md
    -- prohibition against enabling a behaviour hyprlang never enabled).
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
    },

    -- misc block — hyprland.conf lines 85-96. `vfr` is commented out
    -- (line 95) and stays unset for the same reason as dwindle.pseudotile
    -- above.
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        enable_swallow = true,
        swallow_regex = "^(kitty)$",
    },

    -- cursor block — hyprland.conf lines 99-101.
    cursor = {
        no_hardware_cursors = true,
    },
})
