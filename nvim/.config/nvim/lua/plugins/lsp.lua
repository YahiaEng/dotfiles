-- Language servers. nvim-lspconfig now ships only server DEFINITIONS —
-- the actual wiring goes through core's vim.lsp.config()/vim.lsp.enable(),
-- not the old require('lspconfig').X.setup{} framework (that framework is
-- deprecated and being removed). Confirmed against the plugin's own
-- current README at write time.
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
      -- blink.cmp advertises extra completion capabilities to every
      -- server — apply it to every config via the '*' wildcard.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Starting set for this machine. Add a server by naming it here —
      -- nvim-lspconfig already ships its command/root-marker defaults, so
      -- most servers need nothing beyond an empty table.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })
      vim.lsp.config("clangd", {})

      vim.lsp.enable({ "lua_ls", "clangd" })

      -- Diagnostics: signs, virtual text, float — configured once, for
      -- every server.
      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●" },
        float = { border = "rounded", source = true },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
      })

      -- Core already covers most of this. `grn` rename, `gra` code action,
      -- `grr` references, `gri` implementation, `grt` type definition and
      -- `gO` symbols are mapped unconditionally, `]d`/`[d` jump diagnostics,
      -- and nvim binds `K` to hover itself on attach — then removes it again
      -- on detach, which a hand-rolled version would not.
      --
      -- So this only adds what core leaves out: `gd`, which has no default
      -- map because it rides the tagfunc, plus two leader aliases for
      -- muscle memory from other editors.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
        end,
      })
    end,
  },
}
