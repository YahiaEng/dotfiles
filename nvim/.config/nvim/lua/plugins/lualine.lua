-- Statusline. `theme = 'auto'` derives lualine's colours from the active
-- colorscheme.
--
-- MEASURED, not guessed: does this follow a live `:colorscheme` re-apply?
-- Read `lualine.lua`'s own `setup_theme()` directly (installed under
-- ~/.local/share/nvim/lazy/lualine.nvim) — it registers its OWN
-- `ColorScheme`/`OptionSet background` autocommand that re-runs
-- `require('lualine').setup()` internally. Confirmed live: driving a
-- theme switch at a running instance and reading `lualine_a_normal`'s
-- background before and after moved on its own, with no extra code here.
-- So: it follows. Nothing to build — just call setup() once.
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = { theme = "auto" },
    },
  },
}
