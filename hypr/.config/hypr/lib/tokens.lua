-- hypr/.config/hypr/lib/tokens.lua — defensive token-table accessor (D-13,
-- Phase 13.1). Every consumer obtains the generated colour/motion table by
-- calling tokens.get() — NEVER by reading a value a previously-loaded
-- module happened to set. That is what makes "no module depends on another
-- being loaded first" structurally true rather than a convention this repo
-- has to remember to follow.
--
-- pcall(require, "state.tokens") catches BOTH failure classes the
-- generated table can hit:
--   1. a missing file — require()'s hard "module not found" error, the
--      class that would otherwise stop the compositor from starting at
--      all (the state.tokens path resolves through the
--      ~/.config/hypr/state/tokens.lua symlink stow.sh guarantees exists —
--      see stow.sh's seed block — but pcall is the second, independent
--      line of defence, not a substitute for that guarantee);
--   2. a present-but-malformed file — a syntax error surfacing at load
--      time.
-- Both normalise down to the SAME empty-table fallback, so a caller never
-- has to special-case either one.

local M = {}

-- get()
-- Returns the normalised token table: { colors = {...}, motion = { speed =
-- {...}, curves = {...} } }. Every one of those sub-tables is guaranteed
-- present (never nil) so a caller can safely index two levels deep
-- (tokens.motion.speed.standard) even when the whole underlying file is
-- absent or empty — a missing individual KEY inside a present sub-table
-- still degrades gracefully to Lua's native `nil`, defaultable via `or` at
-- the point of use (that is where D-13's "missing token degrades to a
-- default" guarantee actually lives, not here — this function's job is
-- narrower: guarantee the SHAPE, not any individual value).
function M.get()
    local ok, tokens = pcall(require, "state.tokens")
    if not ok or type(tokens) ~= "table" then
        tokens = {}
    end

    tokens.colors = (type(tokens.colors) == "table") and tokens.colors or {}
    tokens.motion = (type(tokens.motion) == "table") and tokens.motion or {}
    tokens.motion.speed = (type(tokens.motion.speed) == "table") and tokens.motion.speed or {}
    tokens.motion.curves = (type(tokens.motion.curves) == "table") and tokens.motion.curves or {}

    return tokens
end

return M
