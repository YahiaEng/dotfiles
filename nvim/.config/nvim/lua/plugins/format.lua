-- Format-on-save. conform no-ops on a missing formatter binary rather than
-- erroring, so the languages below are the sensible choice per filetype
-- regardless of what happens to be installed on this host today — nothing
-- here needs adding to install.sh for the config itself to be correct.
--
-- Installed on this host at write time: fish_indent, jq. stylua, shfmt,
-- yamlfmt, prettier and ruff are not — those buffers simply won't format
-- until the operator installs the relevant tool, exactly conform's
-- documented no-op behaviour for a missing formatter.
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        fish = { "fish_indent" },
        json = { "jq" },
        yaml = { "yamlfmt" },
        markdown = { "prettier" },
        python = { "ruff_format" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },
}
