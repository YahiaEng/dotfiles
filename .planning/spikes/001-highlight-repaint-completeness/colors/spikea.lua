-- Scheme A: defines plain, treesitter and @lsp.* groups with a distinctive palette.
vim.cmd('highlight clear')
vim.g.colors_name = 'spikea'
local set = vim.api.nvim_set_hl
set(0, 'Normal',               { fg = '#aaaaaa', bg = '#111111' })
set(0, 'Comment',              { fg = '#555555' })
set(0, 'String',               { fg = '#cc4444' })
set(0, '@keyword',             { fg = '#ff0000' })
set(0, '@function',            { fg = '#ff8800' })
set(0, '@type',                { fg = '#ffcc00' })
set(0, '@lsp.type.function',   { fg = '#00ff00' })
set(0, '@lsp.type.variable',   { fg = '#00cccc' })
set(0, '@lsp.mod.readonly',    { fg = '#0000ff' })
