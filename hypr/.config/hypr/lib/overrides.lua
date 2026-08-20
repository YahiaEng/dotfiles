-- hypr/.config/hypr/lib/overrides.lua — defensive overrides-table accessor
-- (quick task 260820-sqd, Task 3), on lib/tokens.lua's exact shape (D-13's
-- pattern extended from colour tokens to Display+input persistence).
--
-- The pcall-wrapped require of the state module below catches BOTH
-- failure classes the generated table can hit:
--   1. a missing file — require()'s hard "module not found" error, the
--      class that would otherwise stop the compositor from starting at
--      all (the state.overrides path resolves through the
--      ~/.config/hypr/state/overrides.lua symlink stow.sh guarantees
--      exists — see stow.sh's seed block — but pcall is the second,
--      independent line of defence, not a substitute for that
--      guarantee);
--   2. a present-but-malformed file — a syntax error surfacing at load
--      time.
-- Both normalise down to the SAME empty-table fallback, so a caller never
-- has to special-case either one.
--
-- get()
-- Returns the normalised overrides table: { monitors = {...}, input =
-- { touchpad = {...} } }. Every one of those sub-tables is guaranteed
-- present (never nil) so a caller can safely index two levels deep
-- (ov.input.touchpad.natural_scroll) even when the whole underlying file
-- is absent or empty — a missing individual KEY inside a present
-- sub-table still degrades gracefully to Lua's native `nil`, defaultable
-- via `or` at the point of use (that is where D-13's "missing token
-- degrades to a default" guarantee actually lives, not here — this
-- function's job is narrower: guarantee the SHAPE, not any individual
-- value).

local M = {}

function M.get()
    local ok, overrides = pcall(require, "state.overrides")
    if not ok or type(overrides) ~= "table" then
        overrides = {}
    end

    overrides.monitors = (type(overrides.monitors) == "table") and overrides.monitors or {}
    overrides.input = (type(overrides.input) == "table") and overrides.input or {}
    overrides.input.touchpad = (type(overrides.input.touchpad) == "table") and overrides.input.touchpad or {}

    return overrides
end

return M
