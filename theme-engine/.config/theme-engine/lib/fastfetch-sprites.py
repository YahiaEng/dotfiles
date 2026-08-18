#!/usr/bin/env python3
"""theme-engine/lib/fastfetch-sprites.py — animated logo sprite generator
(quick task 260818-srl, Task 2).

Ports the six effects (pulse, sweep, glitch, scan, assemble, orbit) from the
operator-reviewed prototype at
.../scratchpad/gen_sprites.py VERBATIM in behaviour — same math, same
S=200/N=24/DUR=60/loop=0/disposal=2/optimize=True, same per-effect logic.
Do not re-derive the effects, do not "improve" the timing, do not drop one.

Exactly three production changes from the prototype, no more:

1. Palette source: reads ~/.local/state/theme/palette.json (the matugen
   [templates.qml] render target, D-11/TOKEN-01) instead of the prototype's
   inline `P = dict(...)`. Same six keys the prototype used: primary,
   tertiary, secondary, surface, onSurface, outline.
2. Mask source: rasterises /usr/share/pixmaps/archlinux-logo.svg (owned by
   the `filesystem` package — present on any Arch install, nothing
   committed to this repo) to a 200x200 RGBA PNG via ImageMagick `magick`,
   into a temp dir, then takes its alpha channel as MASK — replacing the
   prototype's pre-made arch.png.
3. Output contract: CLI `fastfetch-sprites.py <name>|--all [--out <dir>]`,
   default out dir ~/.local/state/theme/fastfetch/. Atomic write (temp file
   then os.replace). A palette-hash sidecar (sha256 of the live
   palette.json) sits next to each GIF — if it matches the CURRENT
   palette.json's hash AND the GIF already exists, generation for that name
   is a no-op. This is what makes:
     - lib/fastfetch.sh's per-theme-switch regen of only the active sprite
       correctly skip when the palette hasn't actually changed (e.g. two
       theme-apply runs of the same theme in a row), and
     - the picker's (Task 3) "generate any missing sprites when it opens"
       cache-warm pass instant on a second open (T-srl-03: DoS bound to
       "the one sprite that actually needs it", never all six every time).

T-srl-04: python-pillow and imagemagick are both official `extra`-repo
pacman packages (confirmed via `pacman -Si python-pillow` before this file
was written) — no AUR, no build recipe, no [ASSUMED]/[SUS] package.
"""

import hashlib
import json
import math
import os
import random
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFilter, ImageChops

STATE_DIR = os.path.expanduser("~/.local/state/theme")
PALETTE_PATH = os.path.join(STATE_DIR, "palette.json")
DEFAULT_OUT_DIR = os.path.join(STATE_DIR, "fastfetch")
ARCH_SVG = "/usr/share/pixmaps/archlinux-logo.svg"

S = 200
N = 24
DUR = 60

EFFECT_NAMES = ("pulse", "sweep", "glitch", "scan", "assemble", "orbit")

# ── Palette roles used (production change 1) ─────────────────────────
# The six keys the prototype's `P = dict(...)` hardcoded, now read live —
# palette.json's own camelCase key names, unchanged.
PALETTE_KEYS = ("primary", "tertiary", "secondary", "surface", "onSurface", "outline")


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def load_palette():
    with open(PALETTE_PATH, "r") as f:
        pal = json.load(f)
    missing = [k for k in PALETTE_KEYS if k not in pal]
    if missing:
        raise KeyError(f"palette.json missing required key(s): {missing}")
    return {k: pal[k] for k in PALETTE_KEYS}


def render_mask(tmp_dir):
    """Production change 2: rasterise the SVG ourselves, no committed PNG."""
    png_path = os.path.join(tmp_dir, "arch-mask.png")
    subprocess.run(
        [
            "magick",
            "-background",
            "none",
            "-density",
            "300",
            ARCH_SVG,
            "-resize",
            f"{S}x{S}",
            png_path,
        ],
        check=True,
        capture_output=True,
    )
    logo = Image.open(png_path).convert("RGBA")
    logo = logo.resize((S, S), Image.LANCZOS)
    return logo.split()[3]  # alpha


def palette_hash():
    with open(PALETTE_PATH, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def sidecar_path(out_dir, name):
    return os.path.join(out_dir, f"{name}.hash")


def gif_path(out_dir, name):
    return os.path.join(out_dir, f"{name}.gif")


def is_up_to_date(out_dir, name, current_hash):
    gp = gif_path(out_dir, name)
    sp = sidecar_path(out_dir, name)
    if not os.path.isfile(gp) or not os.path.isfile(sp):
        return False
    try:
        with open(sp, "r") as f:
            stored = f.read().strip()
    except OSError:
        return False
    return stored == current_hash


def atomic_write_gif(out_dir, name, frames):
    os.makedirs(out_dir, exist_ok=True)
    gp = gif_path(out_dir, name)
    fd, tmp_path = tempfile.mkstemp(dir=out_dir, prefix=f".{name}-", suffix=".gif.tmp")
    os.close(fd)
    frames[0].save(
        tmp_path,
        format="GIF",
        save_all=True,
        append_images=frames[1:],
        duration=DUR,
        loop=0,
        optimize=True,
        disposal=2,
    )
    os.replace(tmp_path, gp)
    return gp


def atomic_write_sidecar(out_dir, name, current_hash):
    sp = sidecar_path(out_dir, name)
    fd, tmp_path = tempfile.mkstemp(dir=out_dir, prefix=f".{name}-", suffix=".hash.tmp")
    with os.fdopen(fd, "w") as f:
        f.write(current_hash)
    os.replace(tmp_path, sp)


# ═══════════════════════════════════════════════════════════════════════
# The six effects — ported verbatim from the prototype. BG/PRI/TER/SEC/
# OUT/ON and MASK are module-level globals set in main() before any of
# these run, exactly matching the prototype's own top-level-script shape.
# ═══════════════════════════════════════════════════════════════════════

BG = PRI = TER = SEC = OUT = ON = None
MASK = None


def base():
    return Image.new("RGB", (S, S), BG)


def tint(mask, color):
    im = Image.new("RGBA", (S, S), color + (0,))
    im.putalpha(mask)
    return im


# 1 PULSE — breathing logo with a glow that swells
def pulse():
    fr = []
    for i in range(N):
        t = i / N
        k = 0.5 + 0.5 * math.sin(2 * math.pi * t)
        c = base()
        glow = tint(MASK.filter(ImageFilter.GaussianBlur(10)), PRI)
        g = glow.copy()
        a = g.split()[3].point(lambda v: int(v * (0.25 + 0.45 * k)))
        g.putalpha(a)
        c.paste(g, (0, 0), g)
        col = lerp(PRI, ON, k * 0.55)
        sc = 1.0 + 0.05 * k
        sz = int(S * sc)
        off = (S - sz) // 2
        lm = MASK.resize((sz, sz), Image.LANCZOS)
        lay = Image.new("RGBA", (S, S), col + (0,))
        m = Image.new("L", (S, S), 0)
        m.paste(lm, (off, off))
        lay.putalpha(m)
        c.paste(lay, (0, 0), lay)
        fr.append(c)
    return fr


# 2 SWEEP — a bright band travels diagonally across a dim logo
def sweep():
    fr = []
    for i in range(N):
        t = i / N
        c = base()
        dim = tint(MASK, lerp(OUT, BG, 0.35))
        c.paste(dim, (0, 0), dim)
        band = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(band)
        x = -S + t * (3 * S)
        for w, v in ((80, 90), (46, 180), (20, 255)):
            d.polygon([(x - w, S), (x + w, S), (x + w + S, 0), (x - w + S, 0)], fill=v)
        band = band.filter(ImageFilter.GaussianBlur(7))
        band = ImageChops.multiply(band, MASK)
        hi = Image.new("RGBA", (S, S), ON + (0,))
        hi.putalpha(band)
        pr = tint(ImageChops.multiply(band.point(lambda v: min(255, v * 2)), MASK), PRI)
        c.paste(pr, (0, 0), pr)
        c.paste(hi, (0, 0), hi)
        fr.append(c)
    return fr


# 3 GLITCH — RGB-split slice displacement in bursts
def glitch():
    rnd = random.Random(7)
    fr = []
    bursts = {5, 6, 7, 14, 15, 20}
    for i in range(N):
        c = base()
        lay = tint(MASK, PRI)
        if i in bursts:
            for col, dx in ((TER, -7), (SEC, 6)):
                g = tint(MASK, col)
                g.putalpha(g.split()[3].point(lambda v: int(v * 0.55)))
                c.paste(g, (dx, 0), g)
            out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
            y = 0
            while y < S:
                h = rnd.randint(5, 18)
                dx = rnd.randint(-16, 16)
                out.paste(lay.crop((0, y, S, min(S, y + h))), (dx, y))
                y += h
            lay = out
        c.paste(lay, (0, 0), lay)
        fr.append(c)
    return fr


# 4 SCAN — CRT scanline rolls down the logo
def scan():
    fr = []
    raster = Image.new("L", (S, S), 0)
    rd = ImageDraw.Draw(raster)
    for y in range(0, S, 3):
        rd.line([(0, y), (S, y)], fill=38)
    for i in range(N):
        t = i / N
        c = base()
        dim = tint(MASK, lerp(PRI, BG, 0.55))
        c.paste(dim, (0, 0), dim)
        band = Image.new("L", (S, S), 0)
        bd = ImageDraw.Draw(band)
        y = int(t * (S + 60)) - 30
        for h, v in ((34, 70), (18, 160), (7, 255)):
            bd.rectangle([0, y - h, S, y + h], fill=v)
        band = band.filter(ImageFilter.GaussianBlur(5))
        band = ImageChops.multiply(band, MASK)
        hot = Image.new("RGBA", (S, S), ON + (0,))
        hot.putalpha(band)
        c.paste(hot, (0, 0), hot)
        sh = Image.new("RGBA", (S, S), BG + (0,))
        sh.putalpha(ImageChops.multiply(raster, MASK))
        c.paste(sh, (0, 0), sh)
        fr.append(c)
    return fr


# 5 ASSEMBLE — logo builds from flying blocks, holds, scatters
def assemble():
    rnd = random.Random(3)
    C = 10
    cs = S // C
    fr = []
    starts = [[(rnd.randint(-160, 160), rnd.randint(-160, 160)) for _ in range(C)] for _ in range(C)]
    lay = tint(MASK, PRI)

    def ease(t):
        return 1 - (1 - t) ** 3

    for i in range(N):
        t = i / N
        c = base()
        if t < 0.5:
            k = ease(min(1, t / 0.45))
        elif t < 0.72:
            k = 1.0
        else:
            k = 1 - ease(min(1, (t - 0.72) / 0.28))
        for r in range(C):
            for q in range(C):
                sx, sy = starts[r][q]
                dx = int(sx * (1 - k))
                dy = int(sy * (1 - k))
                cell = lay.crop((q * cs, r * cs, (q + 1) * cs, (r + 1) * cs))
                if k < 1:
                    a = cell.split()[3].point(lambda v: int(v * (0.15 + 0.85 * k)))
                    cell.putalpha(a)
                c.paste(cell, (q * cs + dx, r * cs + dy), cell)
        fr.append(c)
    return fr


# 6 ORBIT — abstract, no logo: rings of drifting dots
def orbit():
    fr = []
    rings = [(74, 7, PRI, 1.0), (52, 5, TER, -1.6), (30, 4, SEC, 2.3)]
    for i in range(N):
        t = i / N
        c = base()
        d = ImageDraw.Draw(c)
        d.ellipse([S // 2 - 84, S // 2 - 84, S // 2 + 84, S // 2 + 84], outline=lerp(BG, OUT, 0.45))
        for rad, cnt, col, spd in rings:
            for k in range(cnt):
                a = 2 * math.pi * (k / cnt + t * spd)
                x = S // 2 + rad * math.cos(a)
                y = S // 2 + rad * math.sin(a)
                rr = 4.5 if rad > 60 else 3.5
                d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col)
        d.ellipse([S // 2 - 6, S // 2 - 6, S // 2 + 6, S // 2 + 6], fill=ON)
        fr.append(c)
    return fr


EFFECTS = {
    "pulse": pulse,
    "sweep": sweep,
    "glitch": glitch,
    "scan": scan,
    "assemble": assemble,
    "orbit": orbit,
}


def generate_one(name, out_dir, current_hash, force=False):
    if not force and is_up_to_date(out_dir, name, current_hash):
        print(f"{name}.gif  up to date (palette unchanged) — skipped")
        return

    frames = EFFECTS[name]()
    gp = atomic_write_gif(out_dir, name, frames)
    atomic_write_sidecar(out_dir, name, current_hash)
    size_kb = os.path.getsize(gp) / 1024
    print(f"{name}.gif  {size_kb:.0f} KB  {len(frames)} frames")


def main(argv):
    if len(argv) < 2:
        print(f"usage: {argv[0]} <name>|--all [--out <dir>]", file=sys.stderr)
        print(f"  name in: {', '.join(EFFECT_NAMES)}", file=sys.stderr)
        return 2

    target = argv[1]
    out_dir = DEFAULT_OUT_DIR
    rest = argv[2:]
    i = 0
    while i < len(rest):
        if rest[i] == "--out" and i + 1 < len(rest):
            out_dir = os.path.expanduser(rest[i + 1])
            i += 2
        else:
            print(f"unrecognised argument: {rest[i]}", file=sys.stderr)
            return 2

    if target != "--all" and target not in EFFECT_NAMES:
        print(f"unknown sprite name: {target}", file=sys.stderr)
        print(f"  valid names: {', '.join(EFFECT_NAMES)}", file=sys.stderr)
        return 2

    if not os.path.isfile(PALETTE_PATH):
        print(f"palette not found: {PALETTE_PATH} — run theme-apply first", file=sys.stderr)
        return 1

    global BG, PRI, TER, SEC, OUT, ON, MASK

    pal = load_palette()
    BG = rgb(pal["surface"])
    PRI = rgb(pal["primary"])
    TER = rgb(pal["tertiary"])
    SEC = rgb(pal["secondary"])
    OUT = rgb(pal["outline"])
    ON = rgb(pal["onSurface"])

    current_hash = palette_hash()

    with tempfile.TemporaryDirectory(prefix="fastfetch-sprite-mask-") as tmp_dir:
        MASK = render_mask(tmp_dir)

        names = list(EFFECT_NAMES) if target == "--all" else [target]
        for name in names:
            generate_one(name, out_dir, current_hash)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
