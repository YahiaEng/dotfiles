-- Reads the role colours the theme engine writes.
--
-- No caching: every call re-reads the file fresh from disk. `:colorscheme
-- rice` re-executes colors/rice.lua, but `require()` caches modules, so a
-- module-level palette table would freeze the colours at first load and a
-- live theme switch would silently do nothing. Keep this a function.

local STATE_FILE = vim.fn.expand("~/.local/state/theme/nvim.lua")

-- Catppuccin defaults, used until the theme engine has run once, or if its
-- output is ever missing/malformed.
local FALLBACK = {
  surface = "#1e1e2e",
  on_surface = "#cdd6f4",
  surface_variant = "#313244",
  on_surface_variant = "#a6adc8",
  outline = "#585b70",
  primary = "#cba6f7",
  on_primary = "#11111b",
  primary_container = "#4a4568",
  on_primary_container = "#e5dcff",
  secondary = "#89b4fa",
  tertiary = "#a6e3a1",
  error = "#f38ba8",
}

local M = {}

function M.roles()
  local ok, data = pcall(dofile, STATE_FILE)
  if ok and type(data) == "table" and data.surface and data.primary then
    return data
  end
  return FALLBACK
end

return M
