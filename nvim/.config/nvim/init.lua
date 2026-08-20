-- Entry point. Leader keys first — before anything else loads, so a
-- lazy-loaded plugin's own keymaps bind against the right leader — then
-- the config modules, then the plugin manager, then the colorscheme.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

vim.cmd.colorscheme("rice")
