-- Group definitions changing is not the same as the buffer rendering differently.
-- This checks what actually applies to a character: is the semantic-token extmark
-- bound to the group by NAME (so redefining the group repaints it), or does it
-- carry a resolved colour that would go stale?
--
-- Run: nvim -l probe-render.lua

local here = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
vim.opt.runtimepath:prepend(here)

vim.cmd('edit ' .. here .. '/sample.c')
local buf = vim.api.nvim_get_current_buf()
pcall(vim.treesitter.start, buf, 'c')
if vim.fn.executable('clangd') == 1 then
  pcall(vim.lsp.start, { name = 'clangd', cmd = { 'clangd' }, root_dir = here })
end
vim.wait(15000, function() return #vim.lsp.get_clients({ bufnr = buf }) > 0 end, 100)
vim.wait(10000, function()
  for row = 0, vim.api.nvim_buf_line_count(buf) - 1 do
    local t = vim.lsp.semantic_tokens.get_at_pos(buf, row, 4)
    if t and #t > 0 then return true end
  end
  return false
end, 200)

vim.cmd('colorscheme spikea')

-- Find a position carrying a semantic token, and record what applies there.
local found = nil
for row = 0, vim.api.nvim_buf_line_count(buf) - 1 do
  for col = 0, 40 do
    local toks = vim.lsp.semantic_tokens.get_at_pos(buf, row, col)
    if toks and #toks > 0 then
      local info = vim.inspect_pos(buf, row, col)
      found = { row = row, col = col, line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1], info = info }
      break
    end
  end
  if found then break end
end

-- Every extmark overlapping the buffer, with the hl_group it names.
local marks = {}
for _, ns in pairs(vim.api.nvim_get_namespaces()) do
  local ok, ms = pcall(vim.api.nvim_buf_get_extmarks, buf, ns, 0, -1, { details = true })
  if ok then
    for _, m in ipairs(ms) do
      if m[4] and m[4].hl_group then
        marks[#marks + 1] = { ns = ns, row = m[2], col = m[3], hl_group = tostring(m[4].hl_group) }
      end
    end
  end
end

local out = { found = found, extmark_sample = { unpack(marks, 1, math.min(#marks, 25)) }, extmark_count = #marks }
local f = assert(io.open(here .. '/results-render.json', 'w'))
f:write(vim.json.encode(out))
f:close()
print('wrote results-render.json')
