-- What does the distance number actually mean? Bracket it with pairs whose
-- answer we already know, so the pass threshold is not just a guess.
local here = vim.fn.fnamemodify(debug.getinfo(1,'S').source:sub(2), ':p:h')
package.path = here .. '/?.lua;' .. package.path

local function distance(a, b)
  local function rgb(h) h=h:gsub('#','')
    return tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16) end
  local r1,g1,b1 = rgb(a); local r2,g2,b2 = rgb(b)
  local rm=(r1+r2)/2; local dr,dg,db=r1-r2,g1-g2,b1-b2
  return math.sqrt((2+rm/256)*dr*dr + 4*dg*dg + (2+(255-rm)/256)*db*db)
end

local pairs_known = {
  { 'red vs green (obviously different)',        '#ff0000', '#00ff00' },
  { 'gruvbox red vs green (real scheme)',        '#cc241d', '#98971a' },
  { 'gruvbox yellow vs orange (adjacent, still usable)', '#d79921', '#d65d0e' },
  { 'gruvbox blue vs aqua (closest real pair)',  '#458588', '#689d6a' },
  { 'two near-identical greys (unusable)',       '#8a8a8a', '#8a8a8d' },
  { 'identical',                                  '#123456', '#123456' },
}
for _, p in ipairs(pairs_known) do
  print(string.format('%-52s %s vs %s -> %6.1f', p[1], p[2], p[3], distance(p[2], p[3])))
end
