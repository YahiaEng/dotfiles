import json, html
r = json.load(open('results.json'))
pals = r['palettes']

def lum(hexs):
    h = hexs.lstrip('#'); 
    def ch(v):
        v = v/255
        return v/12.92 if v <= 0.03928 else ((v+0.055)/1.055)**2.4
    rr,gg,bb = (int(h[i:i+2],16) for i in (0,2,4))
    return 0.2126*ch(rr)+0.7152*ch(gg)+0.0722*ch(bb)

# One Lua snippet, marked up by slot, so every card shows the same code.
def sample(m):
    A = m.get('attrs') if isinstance(m.get('attrs'), dict) else {}
    def S(slot, txt):
        at = A.get(slot) if isinstance(A.get(slot), dict) else {}
        st = f'color:{m[slot]}'
        if at.get('bold'):   st += ';font-weight:600'
        if at.get('italic'): st += ';font-style:italic'
        return f'<span style="{st}">{html.escape(txt)}</span>'
    op = lambda t: S('operator', t)
    return (
f'''{S('comment','-- derive a syntax ramp from the theme palette')}
{S('keyword','local')} {S('variable','Ramp')} {op('=')} {S('fn','require')}{op('(')}{S('string',"'ramp'")}{op(')')}
{S('keyword','local')} {S('constant','MIN_CONTRAST')} {op('=')} {S('number','4.5')}

{S('keyword','function')} {S('fn','Ramp.build')}{op('(')}{S('variable','roles')}{op(')')}
  {S('keyword','local')} {S('variable','bg')} {op('=')} {S('variable','roles')}{op('.')}{S('type','surface')}
  {S('keyword','if')} {S('keyword','not')} {S('variable','bg')} {S('keyword','then')}
    {S('fn','error')}{op('(')}{S('err',"'palette has no surface'")}{op(')')}
  {S('keyword','end')}
  {S('keyword','return')} {op('{')} {S('type','keyword')} {op('=')} {S('fn','spin')}{op('(')}{S('variable','roles')}{op('.')}{S('type','primary')}{op(',')} {S('number','0')}{op(')')} {op('}')}
{S('keyword','end')}''')

cards = []
for p in sorted(pals, key=lambda x: (not x['ok'], x['name'])):
    m = p['ramp']; bg = p['bg']
    kind = 'light' if lum(bg) > 0.5 else 'dark'
    ok = p['ok']
    A = m.get('attrs') if isinstance(m.get('attrs'), dict) else {}
    def mark(slot):
        at = A.get(slot) if isinstance(A.get(slot), dict) else {}
        return ''.join(c for c, k in (('B','bold'), ('I','italic')) if at.get(k))
    swatches = ''.join(
        f'<i title="{s}: {m[s]} {mark(s)}" style="background:{m[s]}">'
        f'<b>{mark(s)}</b></i>'
        for s in ['keyword','fn','string','number','type','constant','variable','operator','comment','err'])
    cards.append(f'''
<article class="card{'' if ok else ' card--fail'}">
  <header class="card__head">
    <h3>{html.escape(p['name'])}</h3>
    <span class="chip chip--{kind}">{kind}</span>
    <span class="verdict verdict--{'ok' if ok else 'no'}">{'legible' if ok else 'too close'}</span>
  </header>
  <div class="swatches">{swatches}</div>
  <div class="code" style="background:{bg}"><pre>{sample(m)}</pre></div>
  <dl class="metrics">
    <div><dt>separation</dt><dd class="{'' if ok else 'bad'}">{p['min_distance']:.0f}</dd></div>
    <div><dt>closest pair</dt><dd>{html.escape(p['closest_pair'])}</dd></div>
    <div><dt>contrast floor</dt><dd>{'met' if p['ok_contrast'] else 'missed'}</dd></div>
  </dl>
</article>''')

npass = sum(1 for p in pals if p['ok']); nfail = len(pals)-npass
open('preview.html','w').write(f'''<title>Twenty Palettes, One Ramp</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap">
<style>
:root {{
  --ink:#14161a; --ground:#fbfbfc; --panel:#ffffff; --muted:#6a7080;
  --rule:#e3e5ea; --accent:#147d7d; --pass:#2e7d4f; --fail:#b3261e;
  --sans:"IBM Plex Sans",ui-sans-serif,system-ui,sans-serif;
  --mono:"IBM Plex Mono",ui-monospace,"SF Mono",Menlo,monospace;
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --ink:#e7e9ee; --ground:#0f1114; --panel:#171a1f; --muted:#9aa1ad;
    --rule:#272b32; --accent:#4fb3b3; --pass:#5cc98a; --fail:#ef6b60;
  }}
}}
:root[data-theme="dark"] {{
  --ink:#e7e9ee; --ground:#0f1114; --panel:#171a1f; --muted:#9aa1ad;
  --rule:#272b32; --accent:#4fb3b3; --pass:#5cc98a; --fail:#ef6b60;
}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--ground);color:var(--ink);font-family:var(--sans);
  line-height:1.55;-webkit-font-smoothing:antialiased}}
.wrap{{max-width:1180px;margin:0 auto;padding:clamp(28px,5vw,64px) clamp(18px,4vw,32px) 96px;
  display:flex;flex-direction:column;gap:40px}}
.lede{{display:flex;flex-direction:column;gap:14px;max-width:66ch}}
.eyebrow{{font-family:var(--mono);font-size:12px;letter-spacing:.14em;text-transform:uppercase;
  color:var(--accent);font-weight:600}}
h1{{font-size:clamp(30px,4.4vw,46px);line-height:1.1;margin:0;font-weight:700;
  letter-spacing:-.02em;text-wrap:balance}}
.sub{{color:var(--muted);font-size:17px;margin:0}}
.tally{{display:flex;gap:26px;flex-wrap:wrap;padding:18px 22px;background:var(--panel);
  border:1px solid var(--rule);border-radius:10px;font-family:var(--mono);font-size:13px}}
.tally b{{font-size:22px;display:block;font-weight:600;font-variant-numeric:tabular-nums}}
.tally span{{color:var(--muted);font-size:11px;letter-spacing:.1em;text-transform:uppercase}}
.scale{{background:var(--panel);border:1px solid var(--rule);border-radius:10px;padding:22px}}
.scale h2{{font-size:14px;margin:0 0 4px;letter-spacing:.02em}}
.scale p{{margin:0 0 16px;color:var(--muted);font-size:13.5px;max-width:70ch}}
.scale ol{{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:7px;
  font-family:var(--mono);font-size:12.5px}}
.scale li{{display:grid;grid-template-columns:58px 1fr;gap:14px;align-items:center}}
.scale .n{{text-align:right;font-weight:600;font-variant-numeric:tabular-nums}}
.bar{{height:9px;border-radius:5px;background:var(--accent);opacity:.85}}
.scale .note{{color:var(--muted)}}
.grid{{display:grid;gap:22px;grid-template-columns:repeat(auto-fill,minmax(340px,1fr))}}
.card{{background:var(--panel);border:1px solid var(--rule);border-radius:10px;overflow:hidden;
  display:flex;flex-direction:column}}
.card--fail{{border-color:color-mix(in srgb,var(--fail) 45%,var(--rule))}}
.card--fail .card__head{{box-shadow:inset 3px 0 0 var(--fail)}}
.card__head{{display:flex;align-items:center;gap:9px;padding:13px 16px;border-bottom:1px solid var(--rule);flex-wrap:wrap}}
.card__head h3{{margin:0;font-size:14.5px;font-weight:600;font-family:var(--mono);flex:1}}
.chip{{font-family:var(--mono);font-size:10px;letter-spacing:.1em;text-transform:uppercase;
  padding:2px 7px;border-radius:4px;border:1px solid var(--rule);color:var(--muted)}}
.verdict{{font-family:var(--mono);font-size:10.5px;letter-spacing:.06em;font-weight:600}}
.verdict--ok{{color:var(--pass)}} .verdict--no{{color:var(--fail)}}
.swatches{{display:flex;height:14px}}
.swatches i{{flex:1;display:flex;align-items:center;justify-content:center}}
.swatches b{{font-family:var(--mono);font-size:7.5px;font-weight:700;color:#0006;
  mix-blend-mode:luminosity;letter-spacing:.04em}}
.code{{padding:15px 17px;overflow-x:auto}}
.code pre{{margin:0;font-family:var(--mono);font-size:12px;line-height:1.62;white-space:pre}}
.metrics{{display:flex;gap:20px;margin:0;padding:12px 16px;border-top:1px solid var(--rule);
  font-family:var(--mono);flex-wrap:wrap}}
.metrics div{{display:flex;flex-direction:column;gap:1px}}
.metrics dt{{font-size:9.5px;letter-spacing:.1em;text-transform:uppercase;color:var(--muted)}}
.metrics dd{{margin:0;font-size:13px;font-weight:600;font-variant-numeric:tabular-nums}}
.metrics dd.bad{{color:var(--fail)}}
footer{{border-top:1px solid var(--rule);padding-top:22px;color:var(--muted);font-size:13.5px;max-width:72ch}}
footer strong{{color:var(--ink);font-weight:600}}
</style>
<div class="wrap">
  <div class="lede">
    <p class="eyebrow">spike 003 &middot; themed nvim</p>
    <h1>Twenty palettes, one derived ramp</h1>
    <p class="sub">The theme palettes carry about four real hues plus greys. Syntax highlighting
    wants ten colours you can tell apart. This is what happens when Lua spins the missing hues
    off the ones that exist, then pushes each result until it is readable on its own background.</p>
  </div>

  <div class="tally">
    <div><b>{len(pals)}</b><span>palettes</span></div>
    <div><b style="color:var(--pass)">{npass}</b><span>legible</span></div>
    <div><b style="color:var(--fail)">{nfail}</b><span>too close</span></div>
    <div><b>10</b><span>syntax slots</span></div>
  </div>

  <section class="scale">
    <h2>What the separation number means</h2>
    <p>Distance between the two closest colours in a ramp. The bar is calibrated against gruvbox,
    a hand-tuned scheme, so the pass mark is borrowed from something known to work rather than picked.</p>
    <ol>
      <li><span class="n">650</span><span class="bar" style="width:100%"></span></li>
      <li><span class="n"></span><span class="note">pure red vs pure green</span></li>
      <li><span class="n">245</span><span class="bar" style="width:38%"></span></li>
      <li><span class="n"></span><span class="note">gruvbox red vs green</span></li>
      <li><span class="n">87</span><span class="bar" style="width:13.4%"></span></li>
      <li><span class="n"></span><span class="note">gruvbox blue vs aqua &mdash; its tightest real pair, and the pass mark</span></li>
      <li><span class="n">5</span><span class="bar" style="width:1%"></span></li>
      <li><span class="n"></span><span class="note">two near-identical greys &mdash; unusable</span></li>
    </ol>
  </section>

  <div class="grid">{''.join(cards)}</div>

  <footer>Each sample is painted on its own palette&rsquo;s background, so these colours ignore
  your light/dark setting &mdash; that is the point. Swatch strips are marked <strong>B</strong>
  for bold and <strong>I</strong> for italic.
  <strong>vantablack</strong> stays deliberately monochrome: it has no hue to spin, so three
  brightness tiers carry the broad strokes and bold/italic separate the slots that share one.
  <strong>nord</strong> is the one palette still under the mark &mdash; it is low-contrast and
  tightly hued by design, and forcing saturation into it would cost the same character that
  keeping vantablack grey preserves.</footer>
</div>''')
print("preview.html written")
