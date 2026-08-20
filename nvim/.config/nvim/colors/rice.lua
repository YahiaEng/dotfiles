-- The `rice` colorscheme — reads role colours from the theme engine, derives
-- a full syntax ramp from them in Lua, and paints nvim. Named to match this
-- repo's walker `themes/rice` naming convention.
--
-- Order matters here, and each step exists for a measured reason:
--   1. set &background from the surface colour's own luminance
--   2. `highlight clear` — without it, @lsp.* groups from the previous
--      theme survive a live re-theme and the buffer ends up half-painted
--   3. termguicolors + g.colors_name
--   4. read the roles fresh (never cached), build the ramp, and paint

local palette = require("theme.palette")
local ramp = require("theme.ramp")

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

-- ── 4. read the roles fresh and build the ramp once ─────────────────
roles = palette.roles()
local r = ramp.build(roles)
local attrs = r.attrs or {}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
  vim.api.nvim_set_hl(0, group, { link = target })
end

-- A slot's colour plus whatever bold/italic the ramp decided for it,
-- merged with any per-call override.
local function slot(name, extra)
  local opts = { fg = r[name] }
  local a = attrs[name]
  if a then
    if a.bold then
      opts.bold = true
    end
    if a.italic then
      opts.italic = true
    end
  end
  if extra then
    for k, v in pairs(extra) do
      opts[k] = v
    end
  end
  return opts
end

-- ══════════════════════════════════════════════════════════════════
-- Editor chrome — role colours, not the syntax ramp
-- ══════════════════════════════════════════════════════════════════

hi("Normal", { fg = roles.on_surface, bg = roles.surface })
hi("NormalFloat", { fg = roles.on_surface, bg = roles.surface_variant })
hi("FloatBorder", { fg = roles.outline, bg = roles.surface_variant })
hi("FloatTitle", { fg = roles.primary, bg = roles.surface_variant, bold = true })
hi("CursorLine", { bg = roles.surface_variant })
hi("CursorLineNr", { fg = roles.primary, bold = true })
hi("LineNr", { fg = roles.outline })
hi("SignColumn", { bg = roles.surface })
hi("ColorColumn", { bg = roles.surface_variant })
hi("Visual", { bg = roles.primary_container })
hi("Search", { fg = roles.on_primary, bg = roles.primary })
hi("IncSearch", { fg = roles.on_primary, bg = roles.secondary })
hi("CurSearch", { fg = roles.on_primary, bg = roles.secondary })
hi("MatchParen", { fg = roles.primary, bold = true })
hi("Pmenu", { fg = roles.on_surface, bg = roles.surface_variant })
hi("PmenuSel", { fg = roles.on_primary_container, bg = roles.primary_container, bold = true })
hi("PmenuSbar", { bg = roles.surface_variant })
hi("PmenuThumb", { bg = roles.outline })
hi("StatusLine", { fg = roles.on_surface, bg = roles.surface_variant })
hi("StatusLineNC", { fg = roles.outline, bg = roles.surface_variant })
hi("WinSeparator", { fg = roles.outline })
hi("TabLine", { fg = roles.outline, bg = roles.surface_variant })
hi("TabLineSel", { fg = roles.on_surface, bg = roles.surface, bold = true })
hi("TabLineFill", { bg = roles.surface_variant })
hi("Folded", { fg = roles.outline, bg = roles.surface_variant })
hi("FoldColumn", { fg = roles.outline, bg = roles.surface })
hi("Directory", { fg = roles.primary })
hi("Title", { fg = roles.primary, bold = true })
hi("Question", { fg = roles.tertiary })
hi("MoreMsg", { fg = roles.tertiary })
hi("ModeMsg", { fg = roles.on_surface, bold = true })
hi("ErrorMsg", { fg = roles.error, bold = true })
hi("WarningMsg", { fg = roles.error })
hi("NonText", { fg = roles.outline })
hi("Whitespace", { fg = roles.outline })
hi("SpecialKey", { fg = roles.outline })
hi("EndOfBuffer", { fg = roles.surface })
hi("Conceal", { fg = roles.outline })
hi("QuickFixLine", { bg = roles.surface_variant, bold = true })
hi("WinBar", { fg = roles.on_surface, bg = roles.surface })
hi("WinBarNC", { fg = roles.outline, bg = roles.surface })

-- ══════════════════════════════════════════════════════════════════
-- Legacy syntax groups — from the ramp slots
-- ══════════════════════════════════════════════════════════════════

hi("Comment", slot("comment"))
hi("Constant", slot("constant"))
hi("String", slot("string"))
hi("Character", slot("string"))
hi("Number", slot("number"))
hi("Boolean", slot("constant"))
hi("Float", slot("number"))
hi("Identifier", slot("variable"))
hi("Function", slot("fn"))
hi("Statement", slot("keyword"))
hi("Conditional", slot("keyword"))
hi("Repeat", slot("keyword"))
hi("Label", slot("keyword"))
hi("Operator", slot("operator"))
hi("Keyword", slot("keyword"))
hi("Exception", slot("keyword"))
hi("PreProc", slot("type"))
hi("Include", slot("keyword"))
hi("Define", slot("type"))
hi("Macro", slot("type"))
hi("PreCondit", slot("type"))
hi("Type", slot("type"))
hi("StorageClass", slot("type"))
hi("Structure", slot("type"))
hi("Typedef", slot("type"))
hi("Special", slot("constant"))
hi("SpecialChar", slot("constant"))
hi("Tag", slot("keyword"))
hi("Delimiter", slot("operator"))
hi("SpecialComment", slot("comment"))
hi("Debug", slot("err"))
hi("Underlined", slot("variable", { underline = true }))
hi("Ignore", { fg = roles.surface })
hi("Error", slot("err", { bold = true }))
hi("Todo", slot("err", { bg = roles.surface_variant, bold = true }))

-- ══════════════════════════════════════════════════════════════════
-- Treesitter capture groups — linked where the mapping is exact,
-- set explicitly where it is not
-- ══════════════════════════════════════════════════════════════════

link("@variable", "Identifier")
hi("@variable.builtin", slot("keyword"))
link("@variable.parameter", "Identifier")
link("@variable.member", "Identifier")

link("@constant", "Constant")
hi("@constant.builtin", slot("constant", { bold = true }))
link("@constant.macro", "Macro")

hi("@module", slot("type"))
link("@module.builtin", "@module")
link("@label", "Label")

link("@string", "String")
hi("@string.documentation", slot("comment"))
hi("@string.regexp", slot("constant"))
hi("@string.escape", slot("constant", { bold = true }))
link("@string.special", "@string.escape")

link("@character", "Character")
link("@character.special", "@string.escape")
link("@boolean", "Boolean")
link("@number", "Number")
link("@number.float", "Float")

link("@type", "Type")
link("@type.builtin", "Type")
link("@type.definition", "Typedef")

hi("@attribute", slot("constant"))
link("@attribute.builtin", "@attribute")
link("@property", "Identifier")

link("@function", "Function")
link("@function.builtin", "Function")
link("@function.call", "Function")
link("@function.macro", "Macro")
link("@function.method", "Function")
link("@function.method.call", "Function")
hi("@constructor", slot("type", { bold = true }))

link("@operator", "Operator")

link("@keyword", "Keyword")
link("@keyword.function", "Keyword")
link("@keyword.operator", "Keyword")
link("@keyword.return", "Keyword")
link("@keyword.import", "Include")
link("@keyword.conditional", "Conditional")
link("@keyword.repeat", "Repeat")
link("@keyword.exception", "Exception")
link("@keyword.directive", "PreProc")

link("@punctuation.delimiter", "Delimiter")
link("@punctuation.bracket", "Delimiter")
hi("@punctuation.special", slot("operator", { bold = true }))

link("@comment", "Comment")
link("@comment.documentation", "Comment")
hi("@comment.error", { fg = roles.error, italic = true })
hi("@comment.warning", slot("number", { italic = true }))
hi("@comment.todo", slot("err", { bg = roles.surface_variant, bold = true, italic = true }))
hi("@comment.note", slot("fn", { italic = true }))

hi("@markup.strong", { fg = roles.on_surface, bold = true })
hi("@markup.italic", { fg = roles.on_surface, italic = true })
hi("@markup.strikethrough", { fg = roles.outline, strikethrough = true })
hi("@markup.underline", { fg = roles.on_surface, underline = true })
hi("@markup.heading", slot("keyword", { bold = true }))
hi("@markup.quote", slot("comment"))
hi("@markup.math", slot("number"))
hi("@markup.link", slot("fn", { underline = true }))
link("@markup.link.url", "@markup.link")
hi("@markup.raw", slot("string"))
hi("@markup.list", slot("operator"))

hi("@tag", slot("keyword"))
link("@tag.attribute", "@attribute")
link("@tag.delimiter", "Delimiter")

hi("@diff.plus", slot("string"))
hi("@diff.minus", slot("err"))
hi("@diff.delta", slot("type"))

-- ══════════════════════════════════════════════════════════════════
-- LSP semantic tokens — BASE groups only. The client-suffixed variants
-- (@lsp.type.function.<client>) default-link to these; `highlight clear`
-- above is what restores those links after a previous scheme overwrote
-- them.
--
-- Set directly (not via `link`) rather than pointing at the legacy group:
-- `nvim_get_hl` returns an unresolved `{link=...}` table by default, and a
-- semantic token consumer reading a group's colour should not have to know
-- to ask for the resolved one.
-- ══════════════════════════════════════════════════════════════════

hi("@lsp.type.class", slot("type"))
hi("@lsp.type.comment", slot("comment"))
hi("@lsp.type.decorator", slot("constant"))
hi("@lsp.type.enum", slot("type"))
hi("@lsp.type.enumMember", slot("constant"))
hi("@lsp.type.event", slot("type"))
hi("@lsp.type.function", slot("fn"))
hi("@lsp.type.interface", slot("type"))
hi("@lsp.type.keyword", slot("keyword"))
hi("@lsp.type.macro", slot("type"))
hi("@lsp.type.method", slot("fn"))
hi("@lsp.type.modifier", slot("keyword"))
hi("@lsp.type.namespace", slot("type"))
hi("@lsp.type.number", slot("number"))
hi("@lsp.type.operator", slot("operator"))
hi("@lsp.type.parameter", slot("variable"))
hi("@lsp.type.property", slot("variable"))
hi("@lsp.type.regexp", slot("constant"))
hi("@lsp.type.string", slot("string"))
hi("@lsp.type.struct", slot("type"))
hi("@lsp.type.type", slot("type"))
hi("@lsp.type.typeParameter", slot("type"))
hi("@lsp.type.variable", slot("variable"))

-- Modifiers worth distinguishing on their own.
hi("@lsp.mod.deprecated", { strikethrough = true })
hi("@lsp.mod.readonly", { italic = true })
hi("@lsp.mod.defaultLibrary", { italic = true })
hi("@lsp.typemod.variable.readonly", slot("variable", { italic = true }))
hi("@lsp.typemod.variable.defaultLibrary", slot("variable", { italic = true }))

-- ══════════════════════════════════════════════════════════════════
-- Diagnostics, diff, spell — reuse the same ramp slots rather than
-- inventing new colours, so a diagnostic and a syntax token that share a
-- hue always mean the same thing on screen.
-- ══════════════════════════════════════════════════════════════════

hi("DiagnosticError", { fg = r.err })
hi("DiagnosticWarn", { fg = r.number })
hi("DiagnosticInfo", { fg = r.fn })
hi("DiagnosticHint", { fg = roles.outline })

hi("DiagnosticVirtualTextError", { fg = r.err, bg = roles.surface_variant })
hi("DiagnosticVirtualTextWarn", { fg = r.number, bg = roles.surface_variant })
hi("DiagnosticVirtualTextInfo", { fg = r.fn, bg = roles.surface_variant })
hi("DiagnosticVirtualTextHint", { fg = roles.outline, bg = roles.surface_variant })

hi("DiagnosticUnderlineError", { sp = r.err, undercurl = true })
hi("DiagnosticUnderlineWarn", { sp = r.number, undercurl = true })
hi("DiagnosticUnderlineInfo", { sp = r.fn, undercurl = true })
hi("DiagnosticUnderlineHint", { sp = roles.outline, undercurl = true })

hi("DiagnosticSignError", { fg = r.err })
hi("DiagnosticSignWarn", { fg = r.number })
hi("DiagnosticSignInfo", { fg = r.fn })
hi("DiagnosticSignHint", { fg = roles.outline })

hi("DiffAdd", { fg = r.string, bg = roles.surface_variant })
hi("DiffChange", { fg = r.type, bg = roles.surface_variant })
hi("DiffDelete", { fg = r.err, bg = roles.surface_variant })
hi("DiffText", { fg = r.type, bg = roles.surface_variant, bold = true })
hi("Added", { fg = r.string })
hi("Changed", { fg = r.type })
hi("Removed", { fg = r.err })

hi("SpellBad", { sp = r.err, undercurl = true })
hi("SpellCap", { sp = r.type, undercurl = true })
hi("SpellLocal", { sp = r.string, undercurl = true })
hi("SpellRare", { sp = r.constant, undercurl = true })
