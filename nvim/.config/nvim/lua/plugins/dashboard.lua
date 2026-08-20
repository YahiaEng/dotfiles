-- The screen you land on when nvim opens with no file. Banner, the files you
-- were last in, and the handful of keys worth reaching for from a cold start.
--
-- snacks.nvim is a bundle; only the dashboard is switched on here. The file
-- tree stays neo-tree's job, so `explorer` is left off deliberately to avoid
-- two things claiming the same role.
--
-- Loads eagerly on purpose: a greeter that lazy-loads has already missed the
-- moment it exists for. It steps aside on its own when nvim is opened with a
-- file or directory argument.
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = table.concat({
            " █████╗  ██████╗ ██████╗ ██╗   ██╗███████╗",
            "██╔══██╗██╔═══██╗██╔══██╗██║   ██║██╔════╝",
            "███████║██║   ██║██████╔╝██║   ██║███████╗",
            "██╔══██║██║   ██║██╔══██╗██║   ██║╚════██║",
            "██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║",
            "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝",
          }, "\n"),
          keys = {
            { icon = "", key = "f", desc = "Find file",  action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "", key = "g", desc = "Live grep",  action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "", key = "r", desc = "Recent",     action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "", key = "e", desc = "File tree",  action = ":Neotree toggle" },
            { icon = "", key = "c", desc = "Config",     action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
            { icon = "", key = "l", desc = "Plugins",    action = ":Lazy" },
            { icon = "", key = "q", desc = "Quit",       action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { title = "Recent", padding = 1 },
          { section = "recent_files", limit = 5, indent = 2, padding = 1 },
        },
      },
      -- Rest of the bundle stays off; neo-tree, telescope and gitsigns
      -- already cover these.
      explorer = { enabled = false },
      picker = { enabled = false },
      notifier = { enabled = false },
  },
  },
}
