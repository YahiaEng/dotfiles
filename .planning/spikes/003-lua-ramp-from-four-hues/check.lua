-- Runs the ramp over every palette in the repo and measures two things:
--   contrast   -- is each colour readable against that palette's background?
--   separation -- are the ten slots actually told apart from each other?
--
-- Run: nvim -l check.lua

local here = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
package.path = here .. '/?.lua;' .. package.path
local R = require('ramp')

local PALETTE_DIR = vim.fn.fnamemodify(here, ':h:h:h')
  .. '/theme-engine/.config/theme-engine/palettes'

-- Perceptual-ish distance between two colours (redmean). Good enough to catch
-- "these two slots look the same", which is all we need here.
local function distance(a, b)
  local function rgb(h)
    h = h:gsub('#', '')
    return tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16)
  end
  local r1,g1,b1 = rgb(a); local r2,g2,b2 = rgb(b)
  local rm = (r1 + r2) / 2
  local dr, dg, db = r1-r2, g1-g2, b1-b2
  return math.sqrt((2 + rm/256)*dr*dr + 4*dg*dg + (2 + (255-rm)/256)*db*db)
end

local results, summary = {}, { pass = 0, fail = 0 }

for _, file in ipairs(vim.fn.glob(PALETTE_DIR .. '/*.json', false, true)) do
  local name = vim.fn.fnamemodify(file, ':t:r')
  local raw = table.concat(vim.fn.readfile(file), '\n')
  local c = vim.json.decode(raw).colors
  local g = function(k) return c[k]['default']['color'] end

  local roles = {
    surface = g('surface'), on_surface = g('on_surface'),
    on_surface_variant = g('on_surface_variant'), outline = g('outline'),
    primary = g('primary'), secondary = g('secondary'),
    tertiary = g('tertiary'), error = g('error'),
  }

  local ramp = R.build(roles)
  local bg = roles.surface

  -- contrast of every slot against the background
  local contrasts, worst, worst_slot = {}, 99, nil
  for _, slot in ipairs(R.SLOTS) do
    local ct = R.contrast(ramp[slot], bg)
    contrasts[slot] = ct
    local floor = (slot == 'comment' or slot == 'operator') and 3.0 or 4.5
    if ct / floor < worst then worst = ct / floor; worst_slot = slot end
  end

  -- Closest pair among the slots. Two slots that differ in bold/italic are
  -- distinguishable even when their colours are close, so those pairs are not
  -- counted as collisions.
  local attrs = ramp.attrs or {}
  local function attr_key(slot)
    local a = attrs[slot] or {}
    return (a.bold and 'b' or '') .. (a.italic and 'i' or '')
  end
  local min_d, pair = 999, nil
  for i = 1, #R.SLOTS do
    for j = i + 1, #R.SLOTS do
      local a, b = R.SLOTS[i], R.SLOTS[j]
      if attr_key(a) == attr_key(b) then
        local d = distance(ramp[a], ramp[b])
        if d < min_d then min_d = d; pair = a .. '/' .. b end
      end
    end
  end
  if not pair then min_d, pair = 999, 'none (attributes separate all)' end

  local ok_contrast = worst >= 1.0
  local ok_separation = min_d >= 70      -- calibrated: gruvbox's tightest real pair scores 87
  local ok = ok_contrast and ok_separation
  if ok then summary.pass = summary.pass + 1 else summary.fail = summary.fail + 1 end

  results[#results + 1] = {
    name = name, bg = bg, ramp = ramp, contrasts = contrasts,
    worst_slot = worst_slot, worst_ratio = worst,
    min_distance = min_d, closest_pair = pair,
    ok_contrast = ok_contrast, ok_separation = ok_separation, ok = ok,
  }
end

table.sort(results, function(a, b) return a.name < b.name end)
local f = assert(io.open(here .. '/results.json', 'w'))
f:write(vim.json.encode({ summary = summary, palettes = results }))
f:close()
print(string.format('%d palettes checked: %d pass, %d fail', #results, summary.pass, summary.fail))
