-- Fuzzy finder. Pinned to the latest release tag, matching telescope's own
-- install recommendation. No fzf-native extension — it needs a compile
-- step (`make`), and this repo's hardest constraint is reproducing the
-- whole editor from one script with no extra build tooling.
return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
      { "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
    },
  },
}
