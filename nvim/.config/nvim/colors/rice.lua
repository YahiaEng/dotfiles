-- The `rice` colorscheme — reads role colours from the theme engine and
-- paints nvim from them. Named to match this repo's walker `themes/rice`
-- naming convention.
--
-- Order matters here, and each step exists for a measured reason (see
-- .planning/spikes/001-highlight-repaint-completeness):
--   1. set &background from the surface colour's own luminance
--   2. `highlight clear` — without it, @lsp.* groups from the previous
--      theme survive a live re-theme and the buffer ends up half-painted
--   3. termguicolors + g.colors_name
--   4. read the roles fresh (never cached) and paint

local palette = require("theme.palette")

-- ── 1. light/dark detection from surface luminance ─────────────────
-- Assigning &background reloads the active colorscheme, so this must only
-- run when the wanted value actually differs — an unguarded assignment
-- recurses into this file.
local function hex2rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function relative_luminance(hex)
  local r, g, b = hex2rgb(hex)
  local function chan(v)
    return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)
end

local roles = palette.roles()
local wanted_bg = relative_luminance(roles.surface) < 0.5 and "dark" or "light"
if vim.o.background ~= wanted_bg then
  vim.o.background = wanted_bg
end

-- ── 2. clear whatever the previous colorscheme left behind ─────────
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

-- ── 3. announce this scheme ─────────────────────────────────────────
vim.o.termguicolors = true
vim.g.colors_name = "rice"

-- ── 4. read the roles fresh and paint ───────────────────────────────
-- (re-read, in case the palette module fell back to something the
-- luminance check above did not see — cheap, and keeps this file the
-- single place that decides what gets painted)
roles = palette.roles()

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Small tracer set — Task 2 expands this to the full editor + treesitter +
-- LSP semantic-token surface.
hi("Normal", { fg = roles.on_surface, bg = roles.surface })
hi("NormalFloat", { fg = roles.on_surface, bg = roles.surface_variant })
hi("Comment", { fg = roles.outline, italic = true })
hi("String", { fg = roles.tertiary })
hi("Function", { fg = roles.secondary })
hi("Keyword", { fg = roles.primary, bold = true })
hi("Type", { fg = roles.tertiary })
hi("CursorLine", { bg = roles.surface_variant })
hi("Visual", { bg = roles.primary_container })
hi("StatusLine", { fg = roles.on_surface, bg = roles.surface_variant })
hi("LineNr", { fg = roles.outline })

-- The two base groups SPIKE 001 proved go stale without `highlight clear`.
hi("@keyword", { fg = roles.primary, bold = true })
hi("@lsp.type.function", { fg = roles.secondary })
