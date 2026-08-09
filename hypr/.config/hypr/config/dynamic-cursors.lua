-- hypr/.config/hypr/config/dynamic-cursors.lua — config surface for the
-- dynamic-cursors hyprpm plugin (Phase 17 plan 05, D-36/D-37, AMB-02's
-- runtime half). D-35's original objective — load the plugin
-- declaratively from THIS repo, via hl.plugin.load(), so a future cut
-- sweep can see the load itself and not just its config — is NOT met on
-- this installed Hyprland build. See the block below for why: it is not
-- unimplemented, it was implemented, tested live, and found to be either
-- ineffective (silent no-op) or actively dangerous (crashes the
-- compositor), depending on the permission state. What this module DOES
-- deliver: once the plugin is loaded by hyprpm (17-04's already-proven
-- path), this file's `hl.config` block declaratively sets its
-- shake-to-find-off (D-36) and mode (D-37) options from the repo — that
-- part is real, live-verified, and unaffected by any of this.
--
-- Every failure path here degrades to "no dynamic cursors, plain pointer
-- still works" — never to a config load that aborts and never boots the
-- session. AMB-02's whole premise is that this dependency is optional; a
-- cosmetic plugin that can prevent a session from starting has inverted
-- its own cost/benefit (T-17-14).

-- NO hl.plugin.load() CALL HERE — DELIBERATELY, PERMANENTLY, ON EVIDENCE.
-- This module used to resolve os.getenv("USER")/LOGNAME into
-- /var/cache/hyprpm/<user>/dynamic-cursors/dynamic-cursors.so (validated
-- against a restrictive username pattern, T-17-13) and call
-- pcall(hl.plugin.load, plugin_path), guarded by an hl.get_loaded_plugins()
-- idempotency check. Both pieces were removed together — the guard existed
-- solely to protect the load call, and has nothing left to gate once the
-- call is gone.
--
-- DO NOT RE-ADD THIS CALL. Three states are fully determined on this
-- installed Hyprland build (0.56.2, commit efb50993, 2026-08-05), tested
-- live and in the nested hypr-lua-harness (17-05-SUMMARY.md has the full
-- evidence trail):
--
--   1. No permission grant matches the request (the state before this
--      fix, and the state a naive re-add returns to): the request
--      resolves to eDynamicPermissionAllowMode ASK — the default when no
--      rule matches — which means a real Allow/Deny confirmation dialog.
--      Live-confirmed: a dialog appeared at every login and again at
--      every hypridle-triggered hyprlock (600s idle), because the
--      request never got answered and stays pending, re-surfacing at the
--      next opportunity the compositor has to show it. Unacceptable
--      steady state.
--
--   2. A permission grant DOES match (either a `^config$` caller-identity
--      grant or a plugin-path-scoped grant were both tried in
--      permissions.lua, now both commented out with a DO-NOT-ENABLE
--      warning): the request resolves to ALLOW, and Hyprland's own
--      handlePluginLoads() acting on that ALLOW recurses into itself
--      without terminating:
--        Config::Lua::CConfigManager::reload()
--          -> Config::Lua::CConfigManager::handlePluginLoads()
--            -> Config::Lua::CConfigManager::postConfigReload()
--              -> Config::Lua::CConfigManager::reload()   [repeats]
--      until the C stack overflows — SIGSEGV, reproduced twice via
--      coredumpctl with matching backtraces. This is a genuine Hyprland-
--      level defect on this build, not a mistake in this repo's Lua, and
--      it crashes the ENTIRE compositor session, not just this module.
--
--   3. No request is issued at all (this file, as shipped): no dialog,
--      no crash. This is the only viable state, and it is not a
--      workaround — it is the permanent shape of this module going
--      forward.
--
-- The plugin still gets loaded on every real login — by hyprpm, via
-- hypr/.config/hypr/scripts/hyprpm-complete.sh (17-04), which calls
-- `hyprpm reload` as the already-legitimate, already-granted
-- /usr/bin/hyprpm caller (permissions.lua line 163, unaffected by any of
-- this). That path is what the `hl.plugin.dynamic_cursors` guard below is
-- actually waiting on, and it is proven, by the live getoption evidence
-- in 17-05-SUMMARY.md, to correctly apply this module's config block once
-- hyprpm's load lands.

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
