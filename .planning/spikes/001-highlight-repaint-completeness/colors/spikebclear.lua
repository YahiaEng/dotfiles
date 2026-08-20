-- Scheme B, clearing: same definitions, but `highlight clear` runs first.
vim.cmd('highlight clear')
vim.g.colors_name = 'spikebclear'
local set = vim.api.nvim_set_hl
set(0, 'Normal',    { fg = '#dddddd', bg = '#222222' })
set(0, 'Comment',   { fg = '#888888' })
set(0, 'String',    { fg = '#44cc44' })
set(0, '@keyword',  { fg = '#ffaa00' })
set(0, '@function', { fg = '#aa66ff' })
set(0, '@type',     { fg = '#66ddff' })
