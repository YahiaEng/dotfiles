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
-- This entry point required exactly seven config modules from plan
-- 13.1-03 Task 2 through Phase 16's close, in the same relative order the
-- retired hyprland.conf's own `source =` lines used to list them. Phase
-- 17 plan 05 (D-35) added an eighth: config.dynamic-cursors, the guarded,
-- optional load and config surface for the dynamic-cursors hyprpm
-- plugin. It lives under config/ rather than being appended to
-- autostart.lua, which carries a documented no-new-entries prohibition
-- (D-15/D-35 — "no entry added, removed or reordered"). Every one of the
-- eight is fully ported, live content — none are placeholder modules.
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
-- Quick task 260820-sqd, Task 3: called independently here, beside
-- `tokens` above — the same "no module depends on another being loaded
-- first" independence lib.overrides.get()'s own header requires.
local overrides = require("lib.overrides").get()
-- `natural_scroll` is a boolean, which breaks the repo's usual
-- `overrides.x or <literal>` idiom when the override is explicitly
-- `false` (Lua's `and/or` ternary pattern silently reverts to the
-- fallback whenever the "true" branch value is itself falsy) — computed
-- as a real conditional here instead, once, rather than inline.
local naturalScrollOverride = true
if overrides.input.touchpad.natural_scroll ~= nil then
    naturalScrollOverride = overrides.input.touchpad.natural_scroll
end

-- quick-260821-6z1 Task 4 (D-03/R-2) — the `look` subcommand's boolean
-- knobs, same `~= nil` discipline as naturalScrollOverride above and for
-- the identical reason: `false or <default>` would silently re-enable
-- something the operator deliberately turned off. Numeric knobs
-- (gaps_in/gaps_out/border_size/gaps_workspaces/rounding/
-- inactive_opacity/blur.size/blur.passes) do NOT need this treatment —
-- Lua only treats `nil`/`false` as falsy, so `overrides.general.gaps_in
-- or 5` is already correct even when the override is the number 0.
local blurEnabledOverride = true
if overrides.decoration.blur.enabled ~= nil then
    blurEnabledOverride = overrides.decoration.blur.enabled
end
local shadowEnabledOverride = true
if overrides.decoration.shadow.enabled ~= nil then
    shadowEnabledOverride = overrides.decoration.shadow.enabled
end
-- Both binds default to Hyprland's own compositor default (`false`,
-- measured live via `hyprctl getoption binds:<key> -j` before either was
-- ever touched, RESEARCH.md §2.2/§2.4) — there was no prior `binds`
-- block in this file at all before this task.
local workspaceBackAndForthOverride = false
if overrides.binds.workspace_back_and_forth ~= nil then
    workspaceBackAndForthOverride = overrides.binds.workspace_back_and_forth
end
local allowWorkspaceCyclesOverride = false
if overrides.binds.allow_workspace_cycles ~= nil then
    allowWorkspaceCyclesOverride = overrides.binds.allow_workspace_cycles
end

require("config.env")
require("config.monitors")
require("config.autostart")
require("config.animations")
require("config.keybinds")
require("config.windowrules")
require("config.permissions")
require("config.dynamic-cursors")

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
        -- quick-260821-6z1 Task 4 (D-03/R-2) — each keeps its CURRENT
        -- literal as the `or` fallback (D-13's guarantee): a missing or
        -- partial overrides file degrades to exactly today's behaviour.
        -- `gaps_workspaces` had no prior literal here at all (Hyprland's
        -- own compositor default is 0, measured live).
        gaps_in = overrides.general.gaps_in or 5,
        gaps_out = overrides.general.gaps_out or 10,
        border_size = overrides.general.border_size or 3,
        gaps_workspaces = overrides.general.gaps_workspaces or 0,
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
    -- Quick task 260820-sqd, Task 3: each field keeps its CURRENT literal
    -- as the `or` fallback (D-13's guarantee) — a missing/corrupt
    -- overrides file degrades to exactly today's behaviour. All four
    -- fields here are overrides-writable (D-01's Display+input group);
    -- hypr-equivalence-check's VOLATILE_KEYS is sized to exactly these.
    input = {
        kb_layout = overrides.input.kb_layout or "us",
        follow_mouse = overrides.input.follow_mouse or 1,
        sensitivity = overrides.input.sensitivity or 0,
        touchpad = {
            natural_scroll = naturalScrollOverride,
        },
    },

    -- decoration block — hyprland.conf lines 48-74, reproduced exactly.
    -- decoration:shadow:color's accepted Lua form was the one open
    -- question this block carried (13.1-04 Task 1): the quoted-string
    -- form (`"rgba(00000055)"`, byte-identical to the hyprlang literal)
    -- was tried first and reads back correctly — see
    -- 13.1-LUA-FINDINGS.md's "Option readback divergences" section.
    decoration = {
        -- quick-260821-6z1 Task 4 (D-03/R-2) — same or-fallback discipline
        -- as `general` above for the numeric fields; the two booleans
        -- (blur.enabled, shadow.enabled) go through the `~= nil`-checked
        -- locals above, never `or`, for the same reason
        -- naturalScrollOverride does.
        rounding = overrides.decoration.rounding or 12,
        active_opacity = 1.0,
        inactive_opacity = overrides.decoration.inactive_opacity or 0.92,
        fullscreen_opacity = 1.0,

        blur = {
            enabled = blurEnabledOverride,
            size = overrides.decoration.blur.size or 8,
            passes = overrides.decoration.blur.passes or 3,
            new_optimizations = true,
            xray = true,
            noise = 0.02,
            contrast = 0.9,
            brightness = 0.8,
            vibrancy = 0.2,
            vibrancy_darkness = 0.5,
        },

        shadow = {
            enabled = shadowEnabledOverride,
            range = 20,
            render_power = 3,
            color = "rgba(00000055)",
            offset = { 0, 4 },
        },
    },

    -- binds block (quick-260821-6z1 Task 4, D-03/R-2) — no prior block of
    -- this name existed in this file before this task. Both fields
    -- default to Hyprland's own compositor default (`false`, measured
    -- live) and go through the `~= nil`-checked locals above, never `or`.
    binds = {
        workspace_back_and_forth = workspaceBackAndForthOverride,
        allow_workspace_cycles = allowWorkspaceCyclesOverride,
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

    -- ── render (quick task 260818-nwo) ────────────────────────────────
    -- expand_undersized_textures defaults to TRUE. Its job is to stretch a
    -- surface's existing texture to fill the new geometry when the client
    -- has not yet committed a buffer at that size — which is exactly what
    -- an animated resize does on every frame. The stretched edge pixels are
    -- the visible "smear" on window edges during transitions, worst on the
    -- Quickshell drawer switching tabs and on the notification popouts'
    -- bottom edge as they slide up: both animate their own layer-surface
    -- geometry, so both hit this path continuously.
    --
    -- Identified by elimination on the live session, not by reading the
    -- name. `decoration:motion_blur` was checked first (its name describes
    -- the symptom verbatim) and is off; `decoration:blur:new_optimizations`
    -- and `decoration:blur:xray` were each toggled live and neither changed
    -- the smear. Setting this to false did, confirmed by the operator.
    --
    -- Cost of disabling: during the frames where a client is behind on
    -- resizing, the un-expanded area shows the surface's own background
    -- rather than stretched pixels. For this desktop every animated resize
    -- is a Quickshell layer surface whose background is opaque and painted
    -- by the shell itself, so there is nothing to see there anyway — the
    -- stretch was pure artifact.
    render = {
        expand_undersized_textures = false,
    },
})

-- ── Per-device overrides (quick-260821-6z1 Task 6, D-08/F-03/R-5) ──────
-- `hl.device()` is a distinct API from `hl.config()` (RESEARCH.md §5.3)
-- — looped separately, one call per persisted entry, keyboard layout
-- and/or scroll factor only (the only two per-device fields with a real
-- read-back oracle; per-device sensitivity/natural-scroll are N-03,
-- never persisted here at all).
--
-- T-6z1-04: an unplugged device must not block compositor start.
-- `pcall` is the boot-time tolerance rule; membership-in-the-live-set is
-- a SEPARATE write-time rule already enforced by `hypr-overrides.sh
-- device`'s own membership check — deliberately not collapsed into this
-- one, since a device present at write-time can legitimately be absent
-- at a LATER boot (unplugged, swapped) without that being an error here.
for _devName, _devSpec in pairs(overrides.devices) do
    local _spec = { name = _devName }
    if _devSpec.kb_layout ~= nil then
        _spec.kb_layout = _devSpec.kb_layout
    end
    if _devSpec.scroll_factor ~= nil then
        _spec.scroll_factor = _devSpec.scroll_factor
    end
    pcall(function()
        hl.device(_spec)
    end)
end
