-- Pops up the available next keys when you pause mid-chord. Since leader is
-- Space and the bindings live next to their plugins, this is the only place
-- they all show up in one list.
--
-- v3 rewrote the API: groups are declared with `wk.add{}` now, not the old
-- `register{}` tables. Most examples still floating around are v2 and break.
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- "helix" draws a bordered panel down the right-hand side; the
      -- alternatives are "modern" (floating box) and "classic" (bottom strip).
      preset = "helix",
      delay = 300,
      icons = {
        mappings = false,   -- no nerd-font glyphs on entries, just the keys
        separator = "→",
      },
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
      layout = {
        spacing = 4,
      },
      -- Names for the prefixes, so a half-typed chord reads as a category
      -- instead of a bare letter. Every individual key already carries its
      -- own `desc` where it is defined, so only the prefixes need naming.
      spec = {
        -- Leader groups
        { "<leader>f", group = "find" },
        { "<leader>c", group = "code" },
        { "<leader>h", group = "git hunk" },
        { "<leader>r", group = "refactor" },

        -- Non-leader prefixes worth labelling
        { "g", group = "goto" },
        { "]", group = "next" },
        { "[", group = "previous" },

        -- Buffer-local maps from the LSP and gitsigns only exist once those
        -- attach, so they appear in the popup on a real buffer and are absent
        -- on the greeter. That is the intended behaviour, not a gap.
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer keymaps",
      },
    },
  },
}
