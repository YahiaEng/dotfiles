-- lazy.nvim bootstrap — clones the plugin manager itself on first run, then
-- hands off to every spec file under lua/plugins/. Snippet matches
-- lazy.nvim's own current installation docs (fetched at write time from
-- github.com/folke/lazy.nvim, doc/lazy.nvim.txt) rather than a
-- remembered version — the exact shape has changed across releases.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Every file under lua/plugins/ returns a spec table and is picked up
  -- automatically — add a plugin by adding a file there, nothing to
  -- register here.
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "rice" } },
  checker = {
    -- Report available updates; never install them without asking.
    enabled = true,
    notify = false,
  },
  change_detection = {
    -- Watch for config file edits, but stay quiet about it — a popup on
    -- every theme switch would be noise, not signal.
    enabled = true,
    notify = false,
  },
})
