-- hypr/.config/hypr/config/animations.lua — animation curve + leaf
-- registration (Phase 13.1, plan 13.1-06). Replaces
-- hypr/.config/hypr/config/animations.conf and closes the hyprlang
-- load-order hazard hyprland.conf's own comment (lines 11-16) warned
-- about: under hyprlang, animations.conf's `enabled = $motion_enabled`
-- line and its `animation =` lines' curve references only resolved
-- because ~/.local/state/theme/hyprland-motion.conf was `source =`d
-- immediately before this file — an undefined `$motion_enabled` there is
-- a hard parse error that stops the compositor from starting. Under Lua
-- that whole class of failure is gone: this module calls
-- require("lib.tokens").get() itself rather than depending on any sibling
-- module having run first (see hyprland.lua.disabled's own header note),
-- so nothing here is ever sensitive to require() order.

local tokens = require("lib.tokens").get()

-- D-08/D-22: animations.conf's own `enabled = $motion_enabled` line
-- deliberately owned this flag so that whichever animations {} block
-- loaded last would not clobber it; under Lua there is only ONE
-- animations registration point, so that ownership split no longer
-- applies, but the flag itself is still handled with the same care that
-- fixed a real shipped bug: derive it with an EXPLICIT nil test, never a
-- boolean-or. `tokens.motion.enabled or true` would evaluate to `true`
-- even when the token resolves false (motion-scale "off"), silently
-- re-enabling animation for a user who deliberately turned it off — this
-- repo already shipped exactly that bug once, a `jq // empty` idiom that
-- treated a JSON `false` as absent (STATE.md's 12-04 finding). Only
-- substitute the default when the token is genuinely absent (nil).
local motion_enabled = tokens.motion.enabled
if motion_enabled == nil then
    motion_enabled = true
end
hl.config({ animations = { enabled = motion_enabled } })

-- Curve registration — one hl.curve() per entry in tokens.motion.curves,
-- named "motion-<key>" to reproduce the `bezier = motion-<key>` names
-- ~/.local/state/theme/hyprland-motion.conf's engine-emitted fragment
-- produced under hyprlang (13-01/MOTION-01: every hand-authored bezier
-- curve declaration was removed there in favour of this engine-emitted
-- set; 13-07 pinned the D-21 A/B curve-comparison toggle to its
-- MD3-default mapping as it stood at removal, and the five hand-authored
-- character curves were deleted from motion.json alongside that — none of
-- that history changes here, this module just resolves from
-- ~/.local/state/theme/hyprland-tokens.lua instead of the hyprlang
-- fragment). Registering every entry in the token table — not only the
-- ones an animation leaf below references — reproduces the fragment's own
-- shape, including its declared-but-never-referenced curves.
-- registered_curves tracks which "motion-<key>" names were actually
-- registered, so a leaf below can skip cleanly (D-13) if the token table
-- doesn't carry the curve it needs. Registered before any leaf references
-- them.
-- D-XX (13.1-08, operator decision): Lua 5.5 randomizes its string-hash
-- seed PER PROCESS. Iterating tokens.motion.curves with a bare pairs()
-- therefore registers curves in a DIFFERENT order on every fresh
-- compositor start — proven live by running 5 separate `lua` processes
-- over the real ~/.local/state/theme/hyprland-tokens.lua motion.curves
-- table and observing 5 different orderings (a same-process,
-- same-hash-seed repeated-reload test cannot detect this, and wrongly
-- looked deterministic). Sorting the key set before iterating makes
-- REGISTRATION deterministic across every fresh process. This does NOT
-- make hypr-equivalence-check's animations.json curve array byte-order
-- match the committed baseline (the baseline's own order came from the
-- old theme-engine-emitted hyprlang fragment and is neither alphabetical
-- nor declaration order) — the gate's curve-array comparison was made
-- order-insensitive instead (see hypr-equivalence-check's
-- _compare_animations_curves_as_set). Both fixes are required together.
local names = {}
for name in pairs(tokens.motion.curves) do
    names[#names + 1] = name
end
table.sort(names)

local registered_curves = {}
for _, name in ipairs(names) do
    local spec = tokens.motion.curves[name]
    local curve_name = "motion-" .. name
    hl.curve(curve_name, spec)
    registered_curves[curve_name] = true
end

-- The 15 animation leaves — one animation-leaf registration per
-- `animation =` line in animations.conf, preserving leaf name, curve name
-- and style argument
-- exactly. Each leaf is wrapped in an explicit nil/registration guard: when
-- its speed token is nil, or its curve was not registered above because
-- the token table had no such curve, the registration is SKIPPED entirely
-- rather than substituting a hardcoded number — Hyprland then falls back
-- to its own built-in default, the compositor still starts, and no second
-- copy of a value motion.json owns is created. A duration/bezier literal
-- here would itself be exactly the raw-value violation motion-lint's
-- CHECK B exists to catch.

-- ── Window animations ────────────────────────────
if tokens.motion.speed.emphasized_in ~= nil and registered_curves["motion-emphasized-decelerate"] then
    hl.animation({
        leaf = "windowsIn",
        enabled = true,
        speed = tokens.motion.speed.emphasized_in,
        bezier = "motion-emphasized-decelerate",
        style = "popin 60%",
    })
end
if tokens.motion.speed.emphasized_out ~= nil and registered_curves["motion-emphasized-accelerate"] then
    hl.animation({
        leaf = "windowsOut",
        enabled = true,
        speed = tokens.motion.speed.emphasized_out,
        bezier = "motion-emphasized-accelerate",
        style = "popin 60%",
    })
end
if tokens.motion.speed.standard ~= nil and registered_curves["motion-standard"] then
    hl.animation({
        leaf = "windowsMove",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-standard",
        style = "slide",
    })
end

-- ── Fade ─────────────────────────────────────────
if tokens.motion.speed.emphasized_in ~= nil and registered_curves["motion-standard-decelerate"] then
    hl.animation({
        leaf = "fadeIn",
        enabled = true,
        speed = tokens.motion.speed.emphasized_in,
        bezier = "motion-standard-decelerate",
    })
end
if tokens.motion.speed.emphasized_out ~= nil and registered_curves["motion-standard-accelerate"] then
    hl.animation({
        leaf = "fadeOut",
        enabled = true,
        speed = tokens.motion.speed.emphasized_out,
        bezier = "motion-standard-accelerate",
    })
end
if tokens.motion.speed.standard ~= nil and registered_curves["motion-standard"] then
    hl.animation({
        leaf = "fadeSwitch",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-standard",
    })
end
if tokens.motion.speed.standard ~= nil and registered_curves["motion-standard"] then
    hl.animation({
        leaf = "fadeShadow",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-standard",
    })
end
if tokens.motion.speed.standard ~= nil and registered_curves["motion-standard"] then
    hl.animation({
        leaf = "fadeDim",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-standard",
    })
end

-- ── Border ───────────────────────────────────────
if tokens.motion.speed.ambient ~= nil and registered_curves["motion-linear"] then
    hl.animation({
        leaf = "border",
        enabled = true,
        speed = tokens.motion.speed.ambient,
        bezier = "motion-linear",
    })
end
if tokens.motion.speed.indicator_border_rotate ~= nil and registered_curves["motion-linear"] then
    hl.animation({
        leaf = "borderangle",
        enabled = true,
        speed = tokens.motion.speed.indicator_border_rotate,
        bezier = "motion-linear",
        style = "loop",
    })
end

-- ── Workspace transitions ────────────────────────
if tokens.motion.speed.emphasized_in ~= nil and registered_curves["motion-emphasized-decelerate"] then
    hl.animation({
        leaf = "workspaces",
        enabled = true,
        speed = tokens.motion.speed.emphasized_in,
        bezier = "motion-emphasized-decelerate",
        style = "slide",
    })
end
if tokens.motion.speed.emphasized_in ~= nil and registered_curves["motion-emphasized-decelerate"] then
    hl.animation({
        leaf = "specialWorkspace",
        enabled = true,
        speed = tokens.motion.speed.emphasized_in,
        bezier = "motion-emphasized-decelerate",
        style = "slidevert",
    })
end

-- ── Layers (menus, notifications) — D-07 split: layersIn/layersOut ──
-- carry their own emphasized-in/emphasized-out speed+curve (300ms
-- decelerate in, 150ms accelerate out); the parent `layers` entry stays
-- declared per the animation tree's inheritance semantics even though
-- every real case is now covered by the two children (13-RESEARCH.md
-- Open Question 2).
if tokens.motion.speed.standard ~= nil and registered_curves["motion-standard"] then
    hl.animation({
        leaf = "layers",
        enabled = true,
        speed = tokens.motion.speed.standard,
        bezier = "motion-standard",
        style = "popin 80%",
    })
end
if tokens.motion.speed.emphasized_in ~= nil and registered_curves["motion-emphasized-decelerate"] then
    hl.animation({
        leaf = "layersIn",
        enabled = true,
        speed = tokens.motion.speed.emphasized_in,
        bezier = "motion-emphasized-decelerate",
        style = "popin 80%",
    })
end
if tokens.motion.speed.emphasized_out ~= nil and registered_curves["motion-emphasized-accelerate"] then
    hl.animation({
        leaf = "layersOut",
        enabled = true,
        speed = tokens.motion.speed.emphasized_out,
        bezier = "motion-emphasized-accelerate",
        style = "popin 80%",
    })
end
