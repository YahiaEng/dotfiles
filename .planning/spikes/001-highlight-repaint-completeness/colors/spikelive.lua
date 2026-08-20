-- Reads the palette written by the theme pipeline, then paints from it.
vim.cmd('highlight clear')
vim.g.colors_name = 'spikelive'

local here = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
local chunk = loadfile(here .. '/palette.lua')
local p = chunk and chunk() or { fg = '#ffffff', accent = '#ff00ff', dim = '#888888' }

local set = vim.api.nvim_set_hl
set(0, 'Normal',             { fg = p.fg, bg = p.bg })
set(0, 'Comment',            { fg = p.dim })
set(0, 'String',             { fg = p.accent })
set(0, '@keyword',           { fg = p.accent })
set(0, '@function',          { fg = p.fg })
set(0, '@lsp.type.function', { fg = p.accent })
