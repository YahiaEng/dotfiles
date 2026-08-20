-- Measures whether re-applying a colorscheme repaints every highlight group,
-- or leaves treesitter / LSP semantic-token groups holding the old colours.
--
-- Run: nvim -l probe.lua
-- Writes results.json next to this file.

local here = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
vim.opt.runtimepath:prepend(here)

-- Groups we care about, in three families.
local GROUPS = {
  plain      = { 'Normal', 'Comment', 'String' },
  treesitter = { '@keyword', '@function', '@type' },
  lsp        = { '@lsp.type.function', '@lsp.type.variable', '@lsp.mod.readonly' },
}

-- Read a group's concrete colours (link = false resolves links to real attrs).
local function snap(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if not ok or not hl then return nil end
  local function hex(n) return n and string.format('#%06x', n) or nil end
  return { fg = hex(hl.fg), bg = hex(hl.bg) }
end

local function snap_all()
  local out = {}
  for family, names in pairs(GROUPS) do
    out[family] = {}
    for _, n in ipairs(names) do out[family][n] = snap(n) end
  end
  return out
end

-- Open the sample and get treesitter going.
vim.cmd('edit ' .. here .. '/sample.c')
local buf = vim.api.nvim_get_current_buf()
pcall(vim.treesitter.start, buf, 'c')

-- Attach clangd so real semantic tokens arrive.
local lsp_started = false
if vim.fn.executable('clangd') == 1 then
  local ok = pcall(vim.lsp.start, { name = 'clangd', cmd = { 'clangd' }, root_dir = here })
  lsp_started = ok and true or false
end

-- Wait for the LSP to attach and deliver semantic tokens.
local attached = vim.wait(15000, function()
  return #vim.lsp.get_clients({ bufnr = buf }) > 0
end, 100)

local tokens_seen = false
if attached then
  tokens_seen = vim.wait(15000, function()
    for row = 0, vim.api.nvim_buf_line_count(buf) - 1 do
      local t = vim.lsp.semantic_tokens.get_at_pos(buf, row, 4)
      if t and #t > 0 then return true end
    end
    return false
  end, 200) or false
end

-- Run one A -> B transition and report what moved.
local function transition(to_scheme)
  vim.cmd('colorscheme spikea')
  local before = snap_all()
  vim.cmd('colorscheme ' .. to_scheme)
  local after = snap_all()

  local moved, stale = {}, {}
  for family, names in pairs(GROUPS) do
    for _, n in ipairs(names) do
      local b, a = before[family][n], after[family][n]
      local same = vim.deep_equal(b, a)
      local rec = { group = n, family = family, before = b, after = a }
      if same then table.insert(stale, rec) else table.insert(moved, rec) end
    end
  end
  return { to = to_scheme, before = before, after = after, moved = moved, stale = stale }
end

local naive = transition('spikebnaive')
local cleared = transition('spikebclear')

-- PROBE CALIBRATION: Normal must change in both runs. If it does not, the
-- probe cannot see changes at all and every "stale" result below is worthless.
local function normal_moved(run)
  for _, m in ipairs(run.moved) do if m.group == 'Normal' then return true end end
  return false
end
local calibration = {
  normal_moved_naive   = normal_moved(naive),
  normal_moved_cleared = normal_moved(cleared),
  probe_trustworthy    = normal_moved(naive) and normal_moved(cleared),
}

local results = {
  nvim_version   = vim.version().major .. '.' .. vim.version().minor .. '.' .. vim.version().patch,
  lsp_started    = lsp_started,
  lsp_attached   = attached,
  tokens_seen    = tokens_seen,
  calibration    = calibration,
  naive          = naive,
  cleared        = cleared,
}

local f = assert(io.open(here .. '/results.json', 'w'))
f:write(vim.json.encode(results))
f:close()

print('wrote results.json')
