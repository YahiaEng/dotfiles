-- hypr/.config/hypr/config/dynamic-cursors.lua — guarded, optional load and
-- config surface for the dynamic-cursors hyprpm plugin (Phase 17 plan 05,
-- D-35/D-36/D-37, AMB-02's runtime half). 17-04 made the plugin
-- *installable* without ever failing an unattended install; this module
-- makes it *configured*, declaratively, from inside the repo, where a
-- future cut sweep can see it — rather than relying on hyprpm's own
-- state.toml `enabled = true` to load it invisibly at every login.
--
-- Every failure path here degrades to "no dynamic cursors, plain pointer
-- still works" — never to a config load that aborts and never boots the
-- session. AMB-02's whole premise is that this dependency is optional; a
-- cosmetic plugin that can prevent a session from starting has inverted
-- its own cost/benefit (T-17-14).

local username = os.getenv("USER") or os.getenv("LOGNAME")

-- T-17-13: the artifact path is a fixed prefix + the resolved username +
-- a fixed suffix — no component is caller-supplied and this module takes
-- no arguments, but the username itself still comes from the environment,
-- so it is validated against a restrictive pattern (alphanumerics, dot,
-- underscore, hyphen only) before interpolation. A traversal segment or
-- an absolute-path escape cannot redirect the load; a name that fails
-- this check skips the load entirely rather than falling back to
-- anything else.
if username and username:match("^[%w._%-]+$") then
    local plugin_path = "/var/cache/hyprpm/" .. username .. "/dynamic-cursors/dynamic-cursors.so"

    -- Idempotency guard, not decoration: re-issuing hl.plugin.load()
    -- against an already-loaded plugin is proven live (17-RESEARCH.md
    -- Deep-Dive #5, reconfirmed by 17-04's Task 3 fault injection) to
    -- time out the Hyprland IPC rather than fail cleanly. On this
    -- machine the common case is that hyprpm already loaded the plugin
    -- via autostart, so this branch is the one that normally runs.
    local already_loaded = false
    for _, p in ipairs(hl.get_loaded_plugins()) do
        if p.name == "dynamic-cursors" then
            already_loaded = true
            break
        end
    end

    if not already_loaded then
        -- pcall: a missing artifact, an unreadable file, an ABI mismatch
        -- against the running Hyprland build, or a wrong call signature
        -- all degrade to "plugin didn't load" instead of aborting the
        -- rest of config evaluation (D-35).
        pcall(hl.plugin.load, plugin_path)
    end
end

-- Upstream's mandatory guard (D-35) — without it, referencing the
-- plugin's config namespace raises a config error whenever the plugin is
-- not loaded, which is exactly the availability failure this module
-- exists to prevent. Note the underscore/hyphen split: this guard and
-- the hl.config key below both use underscores
-- (hl.plugin.dynamic_cursors / plugin.dynamic_cursors); the runtime
-- option namespace hyprctl getoption reads uses hyphens
-- (plugin:dynamic-cursors:*). They are not interchangeable — four
-- plausible-looking alternative setter forms were tested live during
-- planning and silently did nothing at all (17-CONTEXT.md Specific
-- Ideas #4).
if hl.plugin.dynamic_cursors then
    hl.config({
        plugin = {
            dynamic_cursors = {
                enabled = true,

                -- D-37: mode is read once at plugin load and is provably
                -- not runtime-switchable (verified live: setting it via
                -- `hyprctl eval` updates the stored getoption value while
                -- the plugin keeps rendering the old one, and toggling
                -- `enabled` off/on does not re-initialise it). So the
                -- three values genuinely cannot be A/B'd live — the only
                -- honest way to choose is to ship them all trivially
                -- switchable here and let a human judge one real render
                -- per restart. Uncomment exactly one, restart, look.
                mode = "tilt",
                -- mode = "rotate",
                -- mode = "stretch",

                shake = {
                    -- D-36: upstream ships shake-to-find ON. At its
                    -- default threshold it fired on ordinary pointer
                    -- movement during live testing (17-CONTEXT.md
                    -- Specific Ideas #7) — a cursor that balloons unbidden
                    -- is worse than no feature. Disabled here.
                    enabled = false,
                },
            },
        },
    })
end
