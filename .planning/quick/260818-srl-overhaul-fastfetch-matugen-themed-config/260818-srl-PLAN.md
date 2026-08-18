---
quick_id: 260818-srl
date: 2026-08-18
mode: quick
---

# Quick Task 260818-srl — Fastfetch overhaul: matugen-themed closed box, reworked modules, animated sprite logos, and a picker

## Objective

Bring `fastfetch` — the one stowed surface still outside this repo's core value —
into the theme pipeline, and give the greeting a real identity:

1. **Themed.** A matugen template renders `~/.local/state/theme/fastfetch.jsonc`
   every theme-apply. The hardcoded `dim_white` separator dies with the retired
   `config.jsonc`.
2. **Closed.** The box gets a right border on every row, not just the rules.
3. **Reworked.** Every module in the shipped config must actually emit a row.
4. **Animated.** Six palette-drawn sprite logos, regenerated in the new colours
   on every theme switch.
5. **Selectable.** A picker — keybind *and* command — switches between 6 sprites,
   5 ASCII arts, `random`, and `none`, on a theme-orthogonal state axis.

## Architecture — the seam (do not blur it)

```
matugen  → ~/.local/state/theme/fastfetch.jsonc   (colours, box, modules)
selector → --logo-type / --logo CLI flags          (which logo, this launch)
closer   → box-close.awk                           (right border, geometry only)
fish runs: fastfetch -c <state config> <logo flags> --pipe false | awk -f <closer>
```

matugen never knows which logo was picked. The selector never touches colours.
The closer never touches either — it self-calibrates off the box's own top rule.
No component can break another.

---

## Measured ground truth

Everything below was measured on this host. **Do not re-derive it.** Where a
fact is *not* here, measure it — never assume (standing rule).

### Carried in from the approved design session (already measured, trust as given)

- fastfetch 2.67.1, runs on **every** interactive fish shell
  (`fish/.config/fish/config.fish:15`, a bare `fastfetch`). Runtime 6.6ms
  (5 runs, 5.9–7.1). `fish -i` total 31.1–32.2ms.
- fastfetch is **not** in matugen: `config.toml` has 13 templates, none fastfetch.
- `logo.type: file` does per-glyph-run colour substitution: art containing
  `$1AAAA$2BBBB` with `logo.color = {"1": …, "2": …}` renders each run in its slot.
- **CLI logo flags override the config's logo while the config's colours survive.**
  `--logo-type file --logo <path>` swaps the art; `--logo-type none` removes it.
- A missing logo file **and** a failed `kitty-icat` both fall back to the builtin
  arch logo **silently, exit 0, no warning** — under both `TERM=xterm-kitty` and
  `TERM=xterm-256color`. This is why logo selection happens *before* fastfetch is
  invoked. fastfetch's own fallback is the wrong one.
- kitty 0.48.2; the graphics protocol supports terminal-driven animation since
  0.20.0 (`/usr/share/doc/kitty/html/_sources/graphics-protocol.rst.txt:953-957` —
  frame gaps `z`, animation state `s=3`, loop count `v=1`, explicitly designed so
  "cat like utilities" can exit and leave the animation running). A sprite keeps
  animating after icat exits.
- `kitten` process spawn floor: **14.3ms** (3 runs) — the entire cost of the
  animated path.
- `-c/--config` takes exactly **one** file. fastfetch has **no** include mechanism.
- Sprite generation: **725ms** for all six, **207ms** for one. Pillow 12.3.0 and
  ImageMagick 7.1.2 both present.
- `/usr/share/pixmaps/archlinux-logo.svg` is owned by the `filesystem` package →
  reproducible on a fresh Arch system with nothing committed to this repo.
- python-pillow is installed here but **absent from install.sh** (imagemagick is
  present, line 91). Without it, fresh installs silently get ASCII forever.
- Working prototype at
  `/tmp/claude-1000/-home-aorus-dotfiles/2fb5b504-d50f-4dba-a65e-dcade3fa3ac4/scratchpad/gen_sprites.py`
  — six effects, operator-reviewed in a gallery. **Port it. Do not rewrite the effects.**

### Measured during planning (2026-08-18, this session)

| # | Fact | How measured |
|---|---|---|
| M-1 | **fastfetch accepts `#RRGGBB` hex in every colour slot** — `display.color.{keys,title,output,separator}` *and* `logo.color.{1..9}` — and converts it to `38;2;R;G;B` truecolor. | Live config with `"keys": "#b3c5ff"` and `logo.color."1": "#b3c5ff"` rendered `^[[38;2;179;197;255m`. |
| M-2 | **fastfetch has no value-width padding.** `--key-width`/`--key-padding-left` pad *keys* only. A format placeholder spec like `{user-name:20}` is silently ignored — output identical to `{1}`. `fastfetch --help` lists no value-padding option. | `fastfetch --help` full read + live `{user-name:20}` test. |
| M-3 | **Therefore the right border cannot be produced by fastfetch alone** and must be appended by a post-filter. |  Follows from M-2. |
| M-4 | **`--pipe false` keeps colour when stdout is a pipe.** Piped output is colourless by default (fastfetch auto-disables); `--pipe false` forces SGR back on. | `fastfetch -c … \| cat -v` with and without the flag. |
| M-5 | **`display.constants` + `{$1}` works** in a `custom` module format. | `"display": {"constants":["CONST"]}` + `{"type":"custom","format":"[{$1}]"}` → `[CONST]`. |
| M-6 | **gawk 5.4.1 under `LANG=en_US.UTF-8` counts characters, not bytes.** `│ ab│` with SGR stripped → `length()` = 5. | Live pipe through `awk '{t=$0; gsub(/\033\[[0-9;]*m/,"",t); print length(t)}'`. |
| M-7 | **Zero `│` in all four existing art files** (`grep -c '│' art/*.txt` → 0,0,0,0). The "first `│` on a line is the box's left border" rule is therefore unambiguous. | `grep -c` over `fastfetch/.config/fastfetch/art/*.txt`. |
| M-8 | **`SUPER + SHIFT + T` is free.** Taken today: `T` (theme), `W` (wallpaper), `Z` (emoji), `SHIFT+Z` (icon theme), `X` (colour), `SHIFT+X` (font), `SHIFT+G`, `SHIFT+K`, `SHIFT+B`, `SHIFT+C`, `SHIFT+Q`, `SHIFT+F`, `SHIFT+S`, `SHIFT+<digits>`, `SHIFT+<arrows>`. No `SHIFT + T`. | `grep -n 'hl.bind(mainMod' hypr/.config/hypr/config/keybinds.lua`, full read. |
| M-9 | **Stow shape.** `~/.config/fastfetch`, `~/.config/matugen`, `~/.config/hypr/scripts`, `~/.config/theme-engine` are **whole-directory symlinks** — new files inside them appear with no re-stow. `~/.config/fish/functions` is a **real directory** with per-file symlinks — a new fish function **requires `stow -R fish`**. | `ls -ld` on each. |
| M-10 | **contract.json `json` format is safe for a mixed config.** theme-parity's Layer 3 sets `enforce_emptiness=0` for `json`/`toml` and only validates values that *look* like a colour — non-colour leaves are not violations. But its `{{` leftover scan (`grep -q '{{'`) runs on **every** contract file regardless of format. | `theme-engine/lib/contract.sh:100-175`, `theme-parity:223-275`. |
| M-11 | **theme-doctor's D-29 state-manifest gate fails on any entry under `~/.local/state/theme/` not declared in contract.json** (`files[]`, `state_metadata_files`, `presence_only_files`, or `engine_owned_files`). | `theme-engine/theme-doctor:86-117`. |
| M-12 | **colour-lint is QML-only** (scans `.qml` for `Colours.*` refs and hardcoded hex) — no fastfetch/awk/shell surface enters its scope. | `hypr/.config/hypr/scripts/colour-lint` header. |

### The one design consequence you must absorb

M-2 + M-3 mean the **closed box needs a post-filter**. This is not a scope
reduction and not optional — the operator locked "closed box". The filter is
`box-close.awk`, and it is designed to be immune to the logo:

> For each output line, ignore everything before the **first `│`**. Compute the
> display width of the remainder (SGR-stripped, M-6), pad to the width learned
> from the box's own top rule, and append `│`.

Because the logo — ASCII art *or* a kitty graphics escape sequence with unicode
placeholders — always sits **left** of the border and never contains `│` (M-7),
the filter never has to count it. The target width is read off the `┌…┐` rule
that fastfetch itself printed, so there is no constant shared between the
template and the filter and no way for them to drift.

---

## Tasks

### Task 1 — Themed, closed, reworked box, end-to-end on the ASCII path

This is the tracer: one path wired through every layer — matugen template →
state file → fish greeting → visible themed closed box. It ships production
quality, not a prototype.

**Files:**
- `matugen/.config/matugen/templates/fastfetch.jsonc` (NEW)
- `matugen/.config/matugen/config.toml` (new `[templates.fastfetch]`, the 14th)
- `fastfetch/.config/fastfetch/art/arch.txt` (NEW)
- `fastfetch/.config/fastfetch/box-close.awk` (NEW)
- `fastfetch/.config/fastfetch/config.jsonc` (DELETE — retired into the template)
- `theme-engine/.config/theme-engine/contract.json`
- `fish/.config/fish/config.fish` (line 15)

**Action:**

**1a. The matugen template.** Port `fastfetch/.config/fastfetch/config.jsonc`'s
module structure into `matugen/.config/matugen/templates/fastfetch.jsonc`, then:

- Replace the hardcoded `"separator": "dim_white"` and add a full `display.color`
  block — `keys`, `title`, `output`, `separator` — each a matugen role
  (`{{colors.<role>.default.hex}}`). M-1 proves hex works in all four; **do not**
  hand-build `38;2;R;G;B` strings or reach for Tera filters, hex is accepted
  directly. Choose foreground-intent roles only — `on_*_container`, `primary`,
  `tertiary`, `on_surface`, `outline` — never a bare `*_container` role. That
  category error is exactly what quick task 260818-nwo fixed in
  `kitty-colors.conf`; the header comment there records the contrast
  measurements. Measure the contrast of your chosen key/output roles against
  `surface` and record it in the template header.
- Add a `logo.color` map defining **all nine slots `"1"`–`"9"`**, each a role.
  This is what makes `star.txt`'s 25 `$7` runs and `satan_cross.txt`'s `$2`/`$4`
  runs theme automatically, and it must not depend on which art is selected.
- Put the box rule's horizontal run in `display.constants` and write the three
  rule rows as `┌{$1}┐`, `├{$1}┤`, `└{$1}┘` (M-5). The box width then lives in
  exactly **one** place in the template. Set that width by measuring the widest
  rendered content row on this host and adding margin — do not keep 38 blind.
- Set the rule rows' colour so the drawn border matches the appended one.
  Measure whether a per-module `outputColor` key exists in 2.67.1 before using
  it; if it does not, fall back to `display.color.output` and confirm the rules
  pick it up. Either way, verify by eye in the rendered output, not by assumption.
- **Never emit `{{` in the rendered output.** theme-parity greps every contract
  file for `{{` and fails on a hit (M-10). Keep the JSON pretty-printed
  one-brace-per-line, exactly as the current `config.jsonc` already is, so two
  `{` are never adjacent. Verify with a grep, do not eyeball it.
- **No `post_hook`.** The `config.toml` header records "Reload is owned solely by
  `theme-engine/lib/reload.sh` (PIPE-02, D-04) — no post_hook lines below."
  Follow the `[templates.fish]` precedent exactly, whose comment reads "no
  post_hook needed, since fish reads it at shell start and existing shells are
  not re-themed live." fastfetch is the same case; say so in the comment.

**1b. Module rework.** Keep the current information architecture (identity →
system → session → hardware → colours). Then make it honest: **every module in
the shipped config must actually emit a row.** Run the candidate set with
`--show-errors true` **inside a real kitty window** and drop or fix anything
that emits nothing. `terminalfont` is the known offender — measure whether it is
empty everywhere or only outside kitty, then either fix it or delete it. Do not
ship a configured module that renders nothing. Adding modules is at your
discretion; the same rule applies to anything you add.

**1c. `art/arch.txt`.** Extract fastfetch's own builtin arch ASCII (measure which
flag prints it — `--print-logos` / `--list-logos`, check `fastfetch --help`),
write it to `art/arch.txt`, and insert `$1`/`$2`/`$3` run markers so it themes
through `logo.color`. Assert the result contains no `│` (M-7's invariant must
hold for the new file too).

**1d. `box-close.awk`.** A single gawk program, no state beyond the current line:

- On a line containing the top rule (`┌` … `┐`): record `W` = SGR-stripped
  display width of the substring from `┌` to end of the rule.
- On a line containing `│`: take the substring from the **first** `│`; strip SGR
  into a scratch copy (`gsub(/\033\[[0-9;]*m/,"",t)`, M-6); pad with spaces to
  `W - 1` display columns; append `│`.
- **Colour the appended border by capture, not by constant:** re-emit the SGR
  sequence that immediately precedes the first `│` on that line, then the `│`,
  then a reset. The filter never learns a palette value, so it cannot drift from
  the template.
- Every other line passes through **byte for byte** — this is what keeps the
  kitty graphics APC payload intact on the sprite path.
- If `W - 1` minus the content width is negative (a row wider than the box),
  print the line unmodified rather than producing a ragged border, and make that
  case visible (a counter printed to stderr is fine). A silently ragged box is
  worse than a loud one.

**1e. contract.json.** Add to `files[]`:
`{"name": "fastfetch.jsonc", "format": "json"}` (M-10 — `json` is the correct
tag; the mixed non-colour leaves are safe under it). Add `"fastfetch"` and
`"fastfetch-logo"` to `engine_owned_files` **now**, in this task, even though
neither exists until Tasks 2–3 — that closes the M-11 gate window before it can
open. The "seeded but unregistered" bug class has recurred eight times in this
repo (`.planning/milestones/v3.0-phases/14-dashboard-drawer/14-02-SUMMARY.md`).

**1f. Retire `config.jsonc`.** Delete it. `~/.config/fastfetch` is a whole-dir
symlink (M-9) so no re-stow is needed.

**1g. The fish selector, ASCII half.** Replace the bare `fastfetch` at
`fish/.config/fish/config.fish:15`. This task implements the ASCII rows of the
decision table; Tasks 2 and 3 fill in the rest:

| state value | kitty? | result | lands in |
|---|---|---|---|
| an ascii name | either | that themed ASCII | Task 1 |
| missing/unreadable | either | themed ASCII (`arch`) | Task 1 |
| a sprite name | yes | that sprite, animating | Task 2 |
| a sprite name | **no** | themed ASCII | Task 2 |
| random | either | random sprite / random ASCII | Task 3 |
| none | either | no logo, box only | Task 3 |

Rules that apply from this task onward:

- The state value is **validated against the enumerated art set** before it is
  ever interpolated into `--logo <path>`. Never pass raw state-file content as a
  path (T-srl-01).
- **Nothing may silently reach the stock builtin arch logo.** Every unknown path
  lands on themed ASCII.
- Fresh-install degradation: if `~/.local/state/theme/fastfetch.jsonc` does not
  exist yet (no theme-apply has run), run plain `fastfetch` with no `-c`. Comment
  it in the same voice as the `fish-colors.fish` guard at
  `config.fish:19-35` — a missing render degrades to "the old look", never to a
  broken shell.
- The invocation is `fastfetch -c <state config> <logo flags> --pipe false |
  awk -f ~/.config/fastfetch/box-close.awk`. `--pipe false` is load-bearing
  (M-4) — without it the pipe strips every colour.

**Verify:**

```bash
# renders, is valid JSON, no template leftovers, no adjacent braces
~/.config/theme-engine/theme-apply "$(cat ~/.local/state/theme/current-theme)"
jq -e . ~/.local/state/theme/fastfetch.jsonc >/dev/null
grep -c '{{' ~/.local/state/theme/fastfetch.jsonc   # must be 0

# the box actually closes: every border row ends at the same display column
fastfetch -c ~/.local/state/theme/fastfetch.jsonc \
  --logo-type file --logo ~/.config/fastfetch/art/arch.txt --pipe false \
  | awk -f ~/.config/fastfetch/box-close.awk \
  | awk '/│|┌|├|└/ {t=$0; gsub(/\033\[[0-9;]*m/,"",t); sub(/^[^┌├└│]*/,"",t); print length(t)}' \
  | sort -u | wc -l    # must be 1

# every configured module emits a row (run this inside kitty)
fastfetch -c ~/.local/state/theme/fastfetch.jsonc --show-errors true --logo-type none

# repo gates
~/.config/theme-engine/theme-doctor
~/.config/theme-engine/theme-parity
~/.config/hypr/scripts/stow-link-check
```

Also measure and record: `fish -ic exit` wall time (5 runs) against the
31.1–32.2ms baseline, and the added cost of the awk hop.

**Done:** A new kitty window greets with a matugen-themed, fully closed box
whose right border is flush on every row, using the themed `arch.txt` ASCII;
theme-doctor, theme-parity and stow-link-check all pass; `config.jsonc` is gone
and `fastfetch.jsonc` is a registered contract file.

---

### Task 2 — Palette-drawn animated sprites, regenerated on every theme switch

**Files:**
- `theme-engine/.config/theme-engine/lib/fastfetch-sprites.py` (NEW)
- `theme-engine/.config/theme-engine/lib/fastfetch.sh` (NEW)
- `theme-engine/.config/theme-engine/theme-apply` (hook)
- `install.sh` (python-pillow)
- `fish/.config/fish/config.fish` (sprite rows of the decision table)

**Precondition:** python-pillow and imagemagick are present on this host
(measured). `/usr/share/pixmaps/archlinux-logo.svg` exists and is owned by the
`filesystem` package.

**Action:**

**2a. Port the generator.** Copy the six effect functions from the prototype at
`…/scratchpad/gen_sprites.py` **verbatim in behaviour** — `pulse`, `sweep`,
`glitch`, `scan`, `assemble`, `orbit`, with `S=200`, `N=24`, `DUR=60`,
`loop=0`, `disposal=2`, `optimize=True`. The operator reviewed these six in a
rendered gallery and approved them. **Do not re-derive the effects, do not
"improve" the timing, do not drop one that looks hard to port.**

Three production changes, and only three:

1. **Palette source.** Read `~/.local/state/theme/palette.json` instead of the
   prototype's inline `P = dict(...)`. Keys available there: `primary`,
   `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondary`,
   `onSecondary`, `secondaryContainer`, `onSecondaryContainer`, `tertiary`,
   `onTertiary`, `surface`, `onSurface`, `surfaceVariant`, `onSurfaceVariant`,
   `background`, `onBackground`, `outline`, `error`, `onError`. The six the
   prototype uses are `primary`, `tertiary`, `secondary`, `surface`, `onSurface`,
   `outline`.
2. **Render the mask yourself.** The prototype read a pre-made `arch.png`. The
   production script must rasterise `/usr/share/pixmaps/archlinux-logo.svg` to a
   200×200 RGBA PNG via ImageMagick into a temp dir, then take its alpha channel
   as `MASK`. This is the step that makes the whole feature reproducible with
   nothing committed to the repo.
3. **Output contract.** CLI: `fastfetch-sprites.py <name>|--all [--out <dir>]`,
   defaulting to `~/.local/state/theme/fastfetch/`. Write atomically (temp file
   then `mv`). Alongside the GIFs write a palette-hash sidecar (sha256 of
   `palette.json`) so a regeneration for an unchanged palette is a no-op —
   that is what makes the picker's "generate the rest when it opens" instant on
   second open.

**2b. `lib/fastfetch.sh`.** One function, `theme_engine_fastfetch_regen`:

- Read `~/.local/state/theme/fastfetch-logo`. If it names a **sprite**,
  regenerate **only that one** (207ms). If it names an ASCII art, `none`, or is
  missing, no-op. **Never regenerate all six here** — 725ms on every theme
  switch is the cost the operator explicitly rejected.
- If the sidecar hash matches the current `palette.json`, no-op.
- Best effort throughout: a generator failure leaves the previous GIF in the old
  palette and must **never** fail a theme switch. Log, don't abort.

**2c. Hook it into `theme-apply`.** Call it **after** `theme_engine_commit` (the
palette must already be live in the state dir — the generator reads
`palette.json` from there, not from the tmp render tree) and **before**
`theme_engine_reload`, guarded with `|| true`. Comment the placement and *why*
it cannot move earlier, in the voice of the existing
`theme_engine_wallpaper_autoset` / `sync_owner` placement comments in that file.
This is generation, not reload — do not put it in `reload.sh`, which is the sole
reload fan-out owner (D-04).

**2d. install.sh.** Add `python-pillow` beside `imagemagick` (line ~91). Confirm
with `pacman -Si python-pillow` that it is an official-repo package before
adding it — official repo, pacman, not AUR (T-srl-04). Without this, a fresh
install silently gets ASCII forever with no diagnostic.

**2e. Fish selector, sprite half.** Add the two sprite rows of the decision
table. The kitty check must be a real capability check, not a guess — measure
which of `$KITTY_WINDOW_ID` / `$TERM` is reliable here and use it, mirroring the
`[[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitten` idiom
`icon-theme-picker.sh:273` already uses. A sprite is selected **only if its GIF
exists and is readable**; otherwise themed ASCII. Never the builtin.

**Verify:**

```bash
# six sprites, 24 frames each, in the live palette
python ~/.config/theme-engine/lib/fastfetch-sprites.py --all
ls ~/.local/state/theme/fastfetch/*.gif | wc -l    # 6
python - <<'EOF'
from PIL import Image; import glob
for f in sorted(glob.glob(__import__('os').path.expanduser('~/.local/state/theme/fastfetch/*.gif'))):
    im = Image.open(f); n = 0
    try:
        while True: im.seek(n); n += 1
    except EOFError: pass
    print(f.split('/')[-1], n, im.size)
EOF
# expect 24 frames, (200, 200) for all six

# a theme switch regenerates ONLY the active sprite
stat -c '%n %Y' ~/.local/state/theme/fastfetch/*.gif > /tmp/srl-before
~/.config/theme-engine/theme-apply <other-theme>
stat -c '%n %Y' ~/.local/state/theme/fastfetch/*.gif > /tmp/srl-after
diff /tmp/srl-before /tmp/srl-after   # exactly one line differs

~/.config/theme-engine/theme-doctor    # state-manifest gate with fastfetch/ present
```

Measure and record: single-sprite regen wall time (expect ~207ms), all-six
(~725ms), and the greeting's real cost on the sprite path (expect ≈6.6 + 14.3ms).
Confirm live in kitty that the sprite **keeps animating after the prompt
returns** — that is the protocol-verified behaviour and the whole point.

**Done:** Six sprites render in the live palette; a theme switch re-renders
exactly the active one; a kitty greeting shows it animating; a non-kitty
greeting shows themed ASCII; `install.sh` can reproduce it on a fresh system.

---

### Task 3 — The picker: keybind, command, 13 entries

**Files:**
- `hypr/.config/hypr/scripts/fastfetch-logo-picker.sh` (NEW)
- `hypr/.config/hypr/scripts/fastfetch-logo-switch.sh` (NEW)
- `hypr/.config/hypr/config/keybinds.lua`
- `fish/.config/fish/functions/fastfetch-logo.fish` (NEW)
- `fish/.config/fish/config.fish` (`random` / `none` rows)

**Action:**

**3a. Mirror `icon-theme-picker.sh`.** It is the template, and its discipline is
not decoration — every item below exists because it fixed a real, recorded bug:

- Launcher (`fastfetch-logo-switch.sh`) is the `icon-theme-switch.sh` shape:
  `uwsm app -- kitty --class … --title … -- <picker>`.
- Explicit `for _sig in HUP INT TERM; do trap "exit 1" "$_sig"; done` **before**
  the single EXIT trap. An EXIT-only trap does not fire when Hyprland closes the
  floating window — verified live against a real `hyprctl dispatch closewindow`
  (`icon-theme-picker.sh:24-42`).
- **One** EXIT trap covering **all** mktemp'd artifacts. Never install a second
  on-exit handler; it silently replaces the first.
- mktemp'd preview script, not inline quoting.
- fzf colours sourced from `~/.local/state/theme/fzf-colors.conf` with
  `${VAR:-fallback}` defaults for fresh-install degradation.
- The fzf return is **re-validated against the actually-enumerated set** before
  any use — never free text (T-srl-02).
- Atomic state write: `"$STATE.tmp"` then `mv`.
- Active entry marked `" ●"`, stripped with `${SELECTED% ●}` before use.

**3b. 13 entries:** 6 sprites (`pulse`, `sweep`, `glitch`, `scan`, `assemble`,
`orbit`) + 5 ASCII (`arch`, `star`, `satan_cross`, `cyberpunk_mask`,
`illuminati`) + `random` + `none`. The four pre-existing art files are wired in
**as-is** — do not edit their content. `star.txt` (25 `$7` runs) and
`satan_cross.txt` (28 `$2`/`$4` runs) theme automatically through Task 1's
nine-slot `logo.color` map; the two braille arts have zero runs and render as a
single primary-coloured run. That is expected, not a defect.

**3c. Preview.**

- **Sprites:** reuse the proven idiom verbatim —
  `kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no
  --place="${COLS}x${IMG_LINES}@0x0" "$gif" 2>/dev/null | sed '$d' | sed $'$s/$/\e[m/'`
  with the two-tier chafa fallback (`chafa --format=kitty`, then plain chafa).
  **Do not** pass `--animate=off` the way the icon picker does for static grids.
- **ASCII:** render the actual art text, coloured — not an image. Read the
  `logo.color` slot map out of `~/.local/state/theme/fastfetch.jsonc` with `jq`
  and substitute the `$N` markers, so the preview is byte-identical to what the
  greeting will draw. Do not hardcode a palette.
- **`random` / `none`:** an explanatory card, not a broken image pane.
- **Known unverified, do not chase:** whether `kitten icat` animates *inside* an
  fzf preview pane (fzf redraws the pane on every keypress). The greeting itself
  **will** animate — that is the protocol-verified path. Design the preview so a
  still first frame is an acceptable outcome. Do not block this task on making
  the preview animate.

**3d. On selection:** validate → atomic write to
`~/.local/state/theme/fastfetch-logo` → if a sprite was chosen and its GIF is
missing or stale against the palette hash, generate it via Task 2's script →
`notify-send`. This is a **theme-orthogonal** axis exactly like
`~/.local/state/theme/icon-theme`: the choice survives every palette switch and
the frames regenerate in the new colours. Unlike `icon-theme-picker.sh`, this
picker does **not** need to re-run `theme-apply` — colours did not change, only
which logo the next shell draws. Say so in a comment so a later reader does not
"fix" it by adding one.

**3e. Cache-warm on open:** generate any missing sprites when the picker opens
(725ms worst case, instant on a second open thanks to the palette-hash sidecar).
Show progress; never block the list from appearing.

**3f. Keybind + command.**
- `hypr/.config/hypr/config/keybinds.lua`: bind `mainMod .. " + SHIFT + T"` to
  `~/.config/hypr/scripts/fastfetch-logo-switch.sh` with a trailing
  `-- Fastfetch logo picker` comment, placed beside the other picker binds
  (lines 182-185) in their exact comment style. `SUPER+SHIFT+T` is free (M-8) and
  sits next to `SUPER+T` (theme) the same way `SUPER+SHIFT+Z` (icon theme) sits
  next to `SUPER+Z` (emoji). Re-confirm it is still free before writing.
- Command: `fish/.config/fish/functions/fastfetch-logo.fish`, in the `y.fish`
  shape (a `function … --description` wrapper). It runs the picker directly in
  the current terminal — no floating kitty, since the user is already in one.
- **`stow -R fish` is required** for the new function to link (M-9 — the
  functions dir is a real directory with per-file symlinks, unlike every other
  path this task touches). Do not skip it and do not assume it worked; verify
  the symlink.

**3g. Finish the decision table:** `random` picks uniformly from the sprite set
in kitty and from the ASCII set otherwise; `none` passes `--logo-type none` for
a box-only greeting.

**Verify:**

```bash
~/.config/hypr/scripts/keybind-doctor
~/.config/hypr/scripts/hypr-equivalence-check
~/.config/hypr/scripts/stow-link-check
ls -l ~/.config/fish/functions/fastfetch-logo.fish   # must be a symlink into the repo

# every one of the 13 entries produces a greeting, none reaches the builtin logo
for e in pulse sweep glitch scan assemble orbit arch star satan_cross \
         cyberpunk_mask illuminati random none; do
  printf '%s\n' "$e" > ~/.local/state/theme/fastfetch-logo
  fish -ic exit
done

# cleanup discipline: no mktemp leftovers after a real window close
ls /tmp/fastfetch-* 2>/dev/null   # empty after the picker is closed via hyprctl dispatch closewindow
```

Operator-verifiable: open the picker by keybind **and** by command, arrow
through all 13 entries, confirm previews render, select a sprite, open a new
kitty and see it animating.

**Done:** Both entry points open the picker; all 13 entries are selectable and
previewable; the selection survives a theme switch and regenerates in the new
palette; keybind-doctor, hypr-equivalence-check and stow-link-check pass.

---

## Threat model

| ID | Category | Component | Severity | Disposition | Mitigation |
|---|---|---|---|---|---|
| T-srl-01 | Tampering / Elevation | `config.fish` selector | high | mitigate | `~/.local/state/theme/fastfetch-logo` content becomes a `--logo <path>` argument. Validate against the enumerated art/sprite set before any interpolation; unknown → themed ASCII. Never pass raw state content as a path. |
| T-srl-02 | Tampering | `fastfetch-logo-picker.sh` | high | mitigate | fzf returns free text. Re-validate the selection against the actually-enumerated entry set before the state write, exactly as `icon-theme-picker.sh:573-582` does. |
| T-srl-03 | Denial of Service | `theme-apply` sprite hook | medium | mitigate | Regen is bounded to the single active sprite (207ms), hash-gated to a no-op on an unchanged palette, and `|| true` so it can never fail or stall a theme switch. |
| T-srl-04 | Tampering (supply chain) | `install.sh` | medium | mitigate | `python-pillow` is an official `extra` repo package installed via pacman — not AUR, no build recipe. Confirm with `pacman -Si python-pillow` before adding. No `[ASSUMED]`/`[SUS]` package enters this task. |
| T-srl-05 | Information Disclosure | `box-close.awk` | low | accept | The filter reads only fastfetch's own stdout and appends a border glyph. It has no access to anything the greeting did not already print. |

---

## Success criteria

- [ ] `~/.local/state/theme/fastfetch.jsonc` is rendered by matugen on every
      theme-apply, registered in `contract.json`, and free of `{{` leftovers.
- [ ] `[templates.fastfetch]` is the 14th template and carries **no** `post_hook`.
- [ ] The box closes: every border row ends at the same display column, on both
      the ASCII and the sprite path.
- [ ] Every module in the shipped config emits a row (measured in kitty with
      `--show-errors true`).
- [ ] Six sprites render in the live palette, 24 frames, 200×200; a theme switch
      regenerates exactly the active one.
- [ ] A kitty greeting animates; a non-kitty greeting shows themed ASCII;
      **no path anywhere reaches the stock builtin arch logo.**
- [ ] All 13 picker entries are selectable and previewable, from a keybind
      (`SUPER+SHIFT+T`) and from the `fastfetch-logo` command.
- [ ] `~/.local/state/theme/fastfetch-logo` survives a palette switch.
- [ ] `theme-doctor`, `theme-parity`, `keybind-doctor`, `stow-link-check`,
      `hypr-equivalence-check`, `colour-lint` all pass.
- [ ] `install.sh` lists `python-pillow`.
- [ ] Nothing generated is committed: `~/.local/state/theme/fastfetch/*.gif`,
      `fastfetch.jsonc`, `fastfetch-logo` are all state-dir only.
- [ ] `fish -ic exit` cost measured and recorded against the 31.1–32.2ms baseline.

## Out of scope

The weather-panel city label and the notification-centre news tab — both are
separate quick tasks the operator has already scheduled. **Do not touch
`quickshell/`.**
