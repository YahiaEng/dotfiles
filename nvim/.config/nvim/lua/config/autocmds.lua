-- Small editor behaviours that don't belong to any one plugin.

local augroup = vim.api.nvim_create_augroup("config-autocmds", { clear = true })

-- Briefly flash whatever was just yanked.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Reopen a file at the cursor position it was last closed at.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Strip trailing whitespace on save, without moving the cursor.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Create any missing parent directories before writing a new file.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(event)
    local dir = vim.fn.fnamemodify(event.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})
