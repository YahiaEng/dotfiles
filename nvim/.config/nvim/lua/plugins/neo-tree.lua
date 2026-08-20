-- File tree. Kept narrow enough to sit comfortably beside a zellij pane.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
    },
    -- lazy.nvim's automatic `opts` -> setup() wiring would try
    -- require("neo-tree.nvim") (the repo name); the module is actually
    -- named "neo-tree", so call setup explicitly instead.
    config = function()
      require("neo-tree").setup({
        window = { width = 32 },
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
        },
        -- Git status column is on by default; nothing to add here beyond
        -- confirming it stays enabled.
        enable_git_status = true,
      })
    end,
  },
}
