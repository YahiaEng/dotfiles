-- The production scenario: same colorscheme NAME, new palette file underneath.
-- Does re-applying it pick up the new palette, or no-op because the name matches?
--
-- Run: nvim -l probe-live.lua

local here = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
vim.opt.runtimepath:prepend(here)

local GROUPS = { 'Normal', 'Comment', 'String', '@keyword', '@function', '@lsp.type.function' }

local function write_palette(tbl)
  local f = assert(io.open(here .. '/palette.lua', 'w'))
  f:write(('return { fg = %q, bg = %q, dim = %q, accent = %q }')
    :format(tbl.fg, tbl.bg, tbl.dim, tbl.accent))
  f:close()
end

local function snap()
  local out = {}
  for _, n in ipairs(GROUPS) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = n, link = false })
    local function hex(v) return v and string.format('#%06x', v) or nil end
    out[n] = ok and hl and { fg = hex(hl.fg), bg = hex(hl.bg) } or nil
  end
  return out
end

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

-- Palette v1, first apply.
write_palette({ fg = '#aaaaaa', bg = '#111111', dim = '#555555', accent = '#ff0000' })
vim.cmd('colorscheme spikelive')
local v1 = snap()

-- Palette v2 on disk, then re-apply THE SAME scheme name.
write_palette({ fg = '#dddddd', bg = '#222222', dim = '#999999', accent = '#00ccff' })
local ok_reapply, reapply_err = pcall(vim.cmd, 'colorscheme spikelive')
local v2 = snap()

-- Same again via the alternative route, in case :colorscheme short-circuits.
write_palette({ fg = '#eeeeee', bg = '#333333', dim = '#bbbbbb', accent = '#ffcc00' })
local ok_source = pcall(vim.cmd, 'runtime colors/spikelive.lua')
local v3 = snap()

local function diff(a, b)
  local moved, stale = {}, {}
  for _, n in ipairs(GROUPS) do
    local rec = { group = n, before = a[n], after = b[n] }
    if vim.deep_equal(a[n], b[n]) then table.insert(stale, rec) else table.insert(moved, rec) end
  end
  return { moved = moved, stale = stale }
end

local results = {
  reapply_ok        = ok_reapply,
  reapply_err       = reapply_err and tostring(reapply_err) or nil,
  runtime_source_ok = ok_source,
  v1 = v1, v2 = v2, v3 = v3,
  colorscheme_reapply = diff(v1, v2),
  runtime_source      = diff(v2, v3),
}

local f = assert(io.open(here .. '/results-live.json', 'w'))
f:write(vim.json.encode(results))
f:close()
print('wrote results-live.json')
