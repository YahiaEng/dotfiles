-- Completion. blink.cmp, pinned to a v1 release tag so the downloaded
-- prebuilt fuzzy-matcher binary matches the source — installing from a
-- moving branch risks a source/binary mismatch. Fetched from the plugin's
-- own current install docs at write time (v2 is unstable / under active
-- development, hence the explicit "1.*" pin rather than main).
return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      -- Prebuilt Rust binary, downloaded automatically for the pinned
      -- release tag — no Rust toolchain needed in install.sh. Falls back
      -- to the pure-Lua matcher (with a warning) on an unsupported
      -- platform rather than failing outright.
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
