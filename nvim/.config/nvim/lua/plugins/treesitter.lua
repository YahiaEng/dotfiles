-- Treesitter, on the `main` branch (nvim 0.12+ only — this is a hard,
-- incompatible rewrite of the plugin; setup, parser install and enabling
-- highlighting all differ from the `master` branch most circulating
-- examples still use). Confirmed against the plugin's own current README
-- at write time.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- The plugin's own docs are explicit that it does not support
    -- lazy-loading — it must load at startup and update its parsers via
    -- the build step below, so this is the one plugin in this repo that
    -- is not event/ft/cmd-triggered.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      local languages = {
        "lua", "bash", "fish", "python", "json", "toml", "yaml",
        "markdown", "markdown_inline", "c", "kdl", "qmljs", "vim", "vimdoc",
        "diff", "git_config", "gitcommit", "regex",
      }
      require("nvim-treesitter").install(languages)

      -- jsonc has no grammar of its own in this branch's supported-language
      -- list — the json parser already handles it, so just point the
      -- filetype at it rather than installing a language that doesn't exist.
      vim.treesitter.language.register("json", "jsonc")

      -- Highlighting: the `main` branch enables it per-buffer rather than
      -- through a `highlight.enable` option — a plain FileType autocmd
      -- with a pcall guard, since not every filetype has a parser
      -- installed.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      -- Indentation: marked experimental by the plugin itself. Wired the
      -- same way, guarded the same way.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(function()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)
        end,
      })

      -- Incremental selection: NOT carried over. The `main` branch's own
      -- "Supported features" list covers highlighting, folds, indentation,
      -- injections and locals only — incremental selection is not among
      -- them (unlike the old `master` branch). Left out on purpose rather
      -- than wired to a module that no longer exists.
    end,
  },
}
