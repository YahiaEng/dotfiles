-- Sane defaults. One short reason per cluster, not a restatement of what
-- the option already says it does.

local opt = vim.opt

-- Line numbers: absolute on the current line, relative everywhere else —
-- makes `5j`/`3k` style jumps a glance away.
opt.number = true
opt.relativenumber = true

-- Indentation: spaces, width 2, and match whatever the file already uses
-- when smartindent can tell.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Search: case-insensitive unless the query itself has a capital letter.
opt.ignorecase = true
opt.smartcase = true

-- Splits open where you'd expect them, not top/left.
opt.splitright = true
opt.splitbelow = true

-- Persistent undo across sessions.
opt.undofile = true

-- Keep the sign column reserved so diagnostics don't shove text sideways.
opt.signcolumn = "yes"

-- Keep a few lines of context above/below the cursor.
opt.scrolloff = 8

-- How long nvim waits before firing CursorHold / writeswap — lower means
-- diagnostics and gitsigns feel more responsive.
opt.updatetime = 250

-- Wayland selection: yank goes to the system clipboard by default.
opt.clipboard = "unnamedplus"

-- Mouse support everywhere.
opt.mouse = "a"

opt.termguicolors = true

-- Highlight the line the cursor is on.
opt.cursorline = true

-- Don't wrap long lines.
opt.wrap = false

-- Time to wait for a mapped key sequence to complete — short enough that
-- leader-key combos feel immediate.
opt.timeoutlen = 400
