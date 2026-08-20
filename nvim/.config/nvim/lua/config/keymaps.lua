-- Non-plugin keymaps only. A plugin's own keymaps belong in its spec under
-- `lua/plugins/`, as a lazy `keys` trigger — never here. Keeping the two
-- separate is what makes a plugin's lazy-loading strategy visible from its
-- own file instead of scattered across this one.

local map = vim.keymap.set

-- Window navigation — move between splits with Ctrl+hjkl.
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Buffer navigation.
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Clear search highlight.
map("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Move selected lines up/down, keeping the selection.
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep the cursor centred on half-page jumps and search hops.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down, centred" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up, centred" })
map("n", "n", "nzzzv", { desc = "Next search result, centred" })
map("n", "N", "Nzzzv", { desc = "Previous search result, centred" })

-- Write / quit.
map("n", "<leader>w", ":write<CR>", { desc = "Write buffer" })
map("n", "<leader>q", ":quit<CR>", { desc = "Quit window" })
