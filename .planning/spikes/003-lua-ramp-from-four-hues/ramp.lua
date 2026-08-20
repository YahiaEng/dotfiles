-- Derives a full syntax palette from the handful of Material You roles.
--
-- The roles give about four real hues plus greys; syntax highlighting wants ten
-- colours that are told apart at a glance. Two things make that work:
--
--   1. spin hues off the base roles to invent the missing ones
--   2. push each result light or dark until it is readable on that background
--
-- Step 2 is why this adapts to light and dark palettes on its own, which a
-- fixed role-to-slot mapping cannot.
--
-- Monochrome palettes (vantablack, matte-black) get separated by lightness
-- instead of hue, because spinning the hue of a grey does nothing at all.

local M = {}

-- ── colour conversion ──────────────────────────────────────────────

local function hex2rgb(hex)
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1,2),16)/255, tonumber(hex:sub(3,4),16)/255, tonumber(hex:sub(5,6),16)/255
end

local function rgb2hex(r, g, b)
  local function c(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
  return string.format('#%02x%02x%02x', c(r), c(g), c(b))
end

local function rgb2hsl(r, g, b)
  local mx, mn = math.max(r,g,b), math.min(r,g,b)
  local h, s, l = 0, 0, (mx+mn)/2
  if mx ~= mn then
    local d = mx - mn
    s = l > 0.5 and d/(2-mx-mn) or d/(mx+mn)
    if mx == r then h = (g-b)/d + (g < b and 6 or 0)
    elseif mx == g then h = (b-r)/d + 2
    else h = (r-g)/d + 4 end
    h = h/6
  end
  return h, s, l
end

local function hsl2rgb(h, s, l)
  if s == 0 then return l, l, l end
  local function hue(p,q,t)
    if t < 0 then t = t+1 end
    if t > 1 then t = t-1 end
    if t < 1/6 then return p+(q-p)*6*t end
    if t < 1/2 then return q end
    if t < 2/3 then return p+(q-p)*(2/3-t)*6 end
    return p
  end
  local q = l < 0.5 and l*(1+s) or l+s-l*s
  local p = 2*l-q
  return hue(p,q,h+1/3), hue(p,q,h), hue(p,q,h-1/3)
end

M.hex2hsl = function(hex) return rgb2hsl(hex2rgb(hex)) end
M.hsl2hex = function(h,s,l) return rgb2hex(hsl2rgb(h,s,l)) end

-- ── contrast (WCAG 2.1) ────────────────────────────────────────────

local function luminance(hex)
  local r,g,b = hex2rgb(hex)
  local function ch(v) return v <= 0.03928 and v/12.92 or ((v+0.055)/1.055)^2.4 end
  return 0.2126*ch(r) + 0.7152*ch(g) + 0.0722*ch(b)
end
M.luminance = luminance

function M.contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end

-- Perceptual-ish distance (redmean). Calibrated against a real scheme:
-- gruvbox's closest pair (blue vs aqua) scores ~87, two unusable greys ~5.
function M.distance(a, b)
  local function rgb(h) h=h:gsub('#','')
    return tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16) end
  local r1,g1,b1 = rgb(a); local r2,g2,b2 = rgb(b)
  local rm = (r1+r2)/2; local dr,dg,db = r1-r2, g1-g2, b1-b2
  return math.sqrt((2+rm/256)*dr*dr + 4*dg*dg + (2+(255-rm)/256)*db*db)
end

-- ── building blocks ────────────────────────────────────────────────

-- Spin a hue, and give the result a floor of saturation so the spin actually
-- lands somewhere. Without the floor this is a no-op on greys.
function M.spin(hex, degrees, sat_floor)
  local h, s, l = M.hex2hsl(hex)
  h = (h + degrees/360) % 1
  s = math.max(s, sat_floor or 0)
  return M.hsl2hex(h, s, l)
end

-- Walk lightness away from the background until the colour is readable.
-- Handles light and dark backgrounds with the same code path.
function M.ensure_contrast(hex, bg, target)
  target = target or 4.5
  local h, s, l = M.hex2hsl(hex)
  local step = luminance(bg) < 0.5 and 0.02 or -0.02
  local out = hex
  for _ = 1, 60 do
    if M.contrast(out, bg) >= target then return out end
    l = math.max(0, math.min(1, l + step))
    out = M.hsl2hex(h, s, l)
    if l <= 0 or l >= 1 then break end
  end
  return out
end

-- Set a colour to a specific contrast ratio, rather than just "at least".
-- Used to fan monochrome palettes out across distinct lightness steps.
function M.at_contrast(hex, bg, target)
  local h, s, _ = M.hex2hsl(hex)
  local dark_bg = luminance(bg) < 0.5
  local best, best_err = hex, math.huge
  for i = 0, 100 do
    local l = i / 100
    local cand = M.hsl2hex(h, s, l)
    local err = math.abs(M.contrast(cand, bg) - target)
    -- only consider colours on the readable side of the background
    local on_side = dark_bg and l >= 0.2 or l <= 0.85
    if err < best_err and on_side then best, best_err = cand, err end
  end
  return best
end

-- ── the ramp ───────────────────────────────────────────────────────

M.SLOTS = { 'keyword', 'fn', 'string', 'number', 'comment',
            'type', 'constant', 'variable', 'operator', 'err' }

-- How saturated is this palette overall? Monochrome themes need a different
-- strategy, because rotating the hue of a grey changes nothing.
local function palette_saturation(roles)
  local mx = 0
  for _, k in ipairs({ 'primary', 'secondary', 'tertiary', 'error' }) do
    local _, s = M.hex2hsl(roles[k])
    if s > mx then mx = s end
  end
  return mx
end

function M.build(roles)
  local bg = roles.surface
  local sat = palette_saturation(roles)
  local monochrome = sat < 0.20

  local out = {}

  if monochrome then
    -- No usable hue, and inventing one would throw away the reason someone
    -- picked a monochrome theme. So use three well-separated brightness tiers
    -- and let bold/italic do the rest.
    --
    -- Every slot gets a unique (tier, attribute) pair, and slots that share an
    -- attribute sit at least a tier apart -- near the top of the range there is
    -- no brightness headroom left, so two bold slots one step apart would blur.
    local T = { dim = 3.5, mid = 8.0, bright = 19.0 }
    local plan = {
      comment  = { T.dim,    { italic = true } },
      operator = { T.dim,    {} },

      variable = { T.mid,    {} },
      string   = { T.mid,    { italic = true } },
      number   = { T.mid,    { bold = true } },
      constant = { T.mid,    { bold = true, italic = true } },

      err      = { T.bright, {} },
      type     = { T.bright, { italic = true } },
      keyword  = { T.bright, { bold = true } },
      fn       = { T.bright, { bold = true, italic = true } },
    }
    out.attrs = {}
    for slot, spec in pairs(plan) do
      local src = (slot == 'err') and roles.error or roles.on_surface
      out[slot] = M.at_contrast(src, bg, spec[1])
      out.attrs[slot] = spec[2]
    end
    return out   -- no repair pass: attributes already do the separating
  else
    -- Enough hue to work with. Spin the base roles to invent what is missing.
    local floor = math.max(0.35, sat * 0.7)
    local fix = function(c, t) return M.ensure_contrast(c, bg, t) end

    out.variable = fix(roles.on_surface, 4.5)
    out.keyword  = fix(M.spin(roles.primary,    0,  floor), 4.5)
    out.fn       = fix(M.spin(roles.secondary,  0,  floor), 4.5)
    out.string   = fix(M.spin(roles.tertiary,   0,  floor), 4.5)
    out.err      = fix(M.spin(roles.error,      0,  floor), 4.5)
    out.type     = fix(M.spin(roles.tertiary,  60,  floor), 4.5)
    out.constant = fix(M.spin(roles.primary,  -55,  floor), 4.5)
    out.number   = fix(M.spin(roles.error,     40,  floor), 4.5)
    out.comment  = fix(roles.outline, 3.0)
    out.operator = M.at_contrast(roles.on_surface_variant, bg, 5.5)
    out.attrs = { comment = { italic = true } }   -- the usual convention
  end

  return M.repair(out, bg, monochrome)
end

-- Nudge the closest pair apart until every slot is distinguishable, or until we
-- run out of room. Each move tries several candidates and keeps whichever lifts
-- the worst pair the most, rather than always spinning by a fixed amount.
--
-- Returns the ramp either way -- the checker reports what was actually achieved
-- rather than this pretending it succeeded.
function M.repair(ramp, bg, monochrome, target)
  target = target or 70
  local pinned = { variable = true, err = true }   -- these carry meaning, leave them

  local function worst_pair(r)
    local d, a, b = math.huge, nil, nil
    for i = 1, #M.SLOTS do
      for j = i+1, #M.SLOTS do
        local dd = M.distance(r[M.SLOTS[i]], r[M.SLOTS[j]])
        if dd < d then d, a, b = dd, M.SLOTS[i], M.SLOTS[j] end
      end
    end
    return d, a, b
  end

  for _ = 1, 200 do
    local d, a, b = worst_pair(ramp)
    if d >= target then break end

    local best_slot, best_val, best_score = nil, nil, d
    for _, slot in ipairs({ a, b }) do
      if not pinned[slot] then
        local floor = (slot == 'comment') and 3.0 or 4.5
        local candidates = {}
        if monochrome then
          local h, s, l = M.hex2hsl(ramp[slot])
          for _, dl in ipairs({ 0.08, -0.08, 0.16, -0.16, 0.24, -0.24 }) do
            local nl = l + dl
            if nl > 0.08 and nl < 0.96 then
              candidates[#candidates+1] = M.ensure_contrast(M.hsl2hex(h, s, nl), bg, 3.0)
            end
          end
        else
          for _, deg in ipairs({ 20, -20, 45, -45, 75, -75, 110, -110, 150, 180 }) do
            candidates[#candidates+1] =
              M.ensure_contrast(M.spin(ramp[slot], deg, 0.40), bg, floor)
          end
        end
        local keep = ramp[slot]
        for _, cand in ipairs(candidates) do
          ramp[slot] = cand
          local nd = worst_pair(ramp)
          if nd > best_score then best_score, best_slot, best_val = nd, slot, cand end
        end
        ramp[slot] = keep
      end
    end

    if not best_slot then break end   -- nothing improved things; stop honestly
    ramp[best_slot] = best_val
  end
  return ramp
end

return M
