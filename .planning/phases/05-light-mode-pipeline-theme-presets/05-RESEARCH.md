# Phase 5: Light Mode Pipeline & Theme Presets - Research

**Researched:** 2026-07-11
**Domain:** Bash-orchestrated matugen theming pipeline (GTK3/GTK4 light-mode support, palette JSON authoring, fzf/kitty-graphics wallpaper picker)
**Confidence:** HIGH (pipeline mechanics — read + empirically tested directly against this repo's installed tools) / MEDIUM (canonical upstream light-palette hex values — fetched from official sources, not re-derived from raw repo files in every case)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Preset lineup (THM-02)**
- **D-01:** Ship a palette JSON for every staged wallpaper folder — the Omarchy-style lineup: matte-black, osaka-jade, ristretto, everfrost, kanagawa, hackerman, miasma, ethereal, vantablack — transcribed from Omarchy's published themes, alongside the existing 6 (catppuccin, dracula, gruvbox, nord, rosepine, tokyonight). Presets and wallpaper sets stay 1:1.
- **D-02:** Ship a light variant for every theme family that has a **canonical upstream light variant** (e.g. catppuccin-latte, rose-pine dawn, gruvbox-light, tokyonight-day, kanagawa-lotus). Dark-only families (matte-black, vantablack, …) stay dark-only. The researcher pins down the definitive canonical-light list; do not invent light palettes for families without one.
- **D-03:** Light variants are modeled as **standalone presets** — their own palette JSON (e.g. `catppuccin-latte.json`), applied via `theme-apply catppuccin-latte`. No variant-flag plumbing, no family/sub-palette resolution. Mode detection alone tells the pipeline a preset is light.
- **D-04:** The legacy `themes/` stow package (per-app static theme files under `themes/.config/themes/`) is **deleted this phase**, after the planner verifies nothing references it. "Presets = palette JSONs in theme-engine" is the single source of truth; new presets never add per-app static files.

**Light-mode behavior (THM-01)**
- **D-05:** Material You gets light support via an explicit **`materialyou-light`** entry alongside `materialyou` (matugen `-m light` on the same wallpaper). Explicit user choice only — no auto mode flip from wallpaper lightness.
- **D-06:** Mode is auto-detected from palette lightness (background/surface colors) per the roadmap, **plus** an optional `"mode": "light"|"dark"` override key in the palette JSON that wins when present — deterministic escape hatch for edge palettes.
- **D-07:** Light mode flips **colors + GTK signals only**: rendered palette, GTK3 theme name (adw-gtk3-dark ↔ adw-gtk3), gsettings color-scheme (prefer-dark ↔ prefer-light), and the GTK4 accent mapping. Icon/cursor themes are untouched — icon theming is Phase 6 (UTIL-04).
- **D-08:** The `gtk-3.0/settings.ini` chokepoint is fixed by making settings.ini a **rendered contract target**: matugen template rendered into `~/.local/state/theme/`, with `~/.config/gtk-3.0/settings.ini` symlinked there (seeded by `stow.sh`, same pattern as other themed files). The repo tree stays clean on every switch — no in-place edits of stow-tracked files.

**Wallpaper sets & restriction (THM-03)**
- **D-09:** Strict convention: `Wallpapers/<preset-name>/` matches the palette JSON name exactly. Rename the drifting folders once (`rose-pine` → `rosepine`, `tokyo-night` → `tokyonight`, etc.). No mapping/manifest file.
- **D-10:** Light variants get their **own wallpaper folders** (e.g. `Wallpapers/catppuccin-latte/`) — no family-folder sharing or fallback resolution. User populates them with light wallpapers.
- **D-11:** `theme-apply <static-preset>` **auto-sets the wallpaper** from that theme's set: remember the last-used wallpaper per theme, fall back to the first in the folder. One action lands a fully coherent desktop (Omarchy-style). (Material You keeps its existing direction: wallpaper drives palette.)
- **D-12:** Fall-open semantics: if a preset's wallpaper folder is empty or missing, the picker falls back to **all** wallpapers — never a dead end. Loose files at the Wallpapers/ root and non-preset dirs (`anime/`, …) form a **shared pool**: always offered under Material You, offered for static themes only as the empty-set fallback.

**Wallpaper picker redesign (THM-04)**
- **D-13:** Keep the fzf-in-floating-kitty stack, upgraded: **pixel-perfect previews via the kitty graphics protocol** (kitten icat / `chafa -f kitty`) instead of block art. The live `awww` desktop preview on navigate is a keeper feature — do not lose it.
- **D-14:** Layout: fzf list + **large pixel-perfect preview pane** with filename/resolution metadata and a marker on the currently-active wallpaper. No terminal thumbnail grid (fzf can't; explicitly rejected).
- **D-15:** The picker is **pipeline-themed**: fzf colors sourced from `~/.local/state/theme/` via a new small render target (fzf color fragment + `contract.json` entry) so the picker matches the active theme, including light mode. No hardcoded catppuccin colors remain.
- **D-16:** Restriction UI: with a static theme active the picker opens showing **only that theme's set** (header names the theme), with a keybind (e.g. Ctrl-A) to temporarily browse the full collection. Material You always browses everything.

### Claude's Discretion
- Lightness-detection math (which palette keys, threshold) — planner/executor pick; must classify all shipped palettes correctly given D-06's override escape hatch exists.
- Exact per-theme "last-used wallpaper" state storage (state-dir metadata file naming) — follow existing `current-theme` state conventions.
- fzf color fragment format and which fzf color slots map to which palette roles.
- How the light parity fixture is wired into `theme-parity` (fixture palette choice, assertion set) — success criterion just requires both a light and a dark fixture passing.
- Omarchy palette transcription details (which Omarchy source files to read, key mapping into the ~20-key matugen custom-keyword schema).

### Deferred Ideas (OUT OF SCOPE)
- Icon theme dark/light variant switching on mode change — deliberately excluded from D-07; Phase 6's UTIL-04 icon-theme picker owns icon theming.
- Terminal thumbnail-grid picker layout — rejected for this phase (fzf can't natively); revisit only if a future picker rework moves off fzf.
- Walker-based wallpaper picker — considered and rejected in favor of the upgraded kitty picker; Phase 7's menu work could revisit cohesion later.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THM-01 | Theme pipeline supports light mode — both dark-hardcoded chokepoints fixed (`lib/gtk.sh` gsettings + `gtk-3.0/settings.ini`), mode auto-detected from palette lightness, contract/parity gates extended with a light fixture | Both chokepoints located and read in full (see Architecture Patterns); `matugen -m` behavior empirically tested (see Pitfall 1 — critical); gsettings `color-scheme` enum and `adw-gtk3`/`adw-gtk3-dark` theme names verified installed; contract.json/theme-parity structure fully documented for extension |
| THM-02 | Additional popular static presets shipped, including light themes (e.g. catppuccin-latte), as palette JSONs through the existing pipeline | Omarchy lineup verified against upstream repo listing; canonical light-variant list verified per family (catppuccin, rose-pine, gruvbox, tokyonight, kanagawa have free canonical light; nord and dracula do not — see Assumptions Log); exact 20-key schema confirmed via existing palette JSONs; hardcoded preset arrays outside `theme-apply` located (theme-parity, theme-stress-test — see Pitfall 2) |
| THM-03 | Wallpapers are organized per-theme; with a static theme active the picker restricts choices to that theme's set, with Material You any wallpaper is allowed | Current wallpaper folder inventory taken (naming drift, missing dracula folder — see Runtime State Inventory); no existing last-used-wallpaper state to migrate; `wallpaper-picker.sh`/`theme-apply` integration point read in full |
| THM-04 | Wallpaper picker redesigned to Omarchy-level aesthetics | kitty graphics protocol confirmed available (kitty 0.47.4, kitten icat); official fzf project's own icat integration pattern sourced directly (`fzf-preview.sh`); fzf `--color` COLSPEC full slot list verified against installed fzf 0.74.0 |
</phase_requirements>

## Summary

This phase extends an already well-architected, atomically-committed theming pipeline (`theme-apply` → `generate.sh` → `commit.sh` → `reload.sh`, gated by `contract.json`/`theme-parity`) rather than building anything from scratch. The existing pipeline is disciplined: render-then-atomic-commit, a single reload owner, headless guards, and a security-validated preset-name allowlist. Phase 5's job is to thread a **mode (light/dark) concept** through that pipeline for the first time, expand the preset/wallpaper library ~2.5x, and upgrade the wallpaper picker's rendering technology — all without breaking the atomicity/parity guarantees already in place.

The single most important finding from this research, verified empirically against the installed `matugen 4.1.0` binary: **`matugen json`'s `-m/--mode` flag has zero effect when every color in the input JSON is already a literal hex value** (confirmed via byte-identical `diff` of `-m light` vs `-m dark` output for the existing `catppuccin.json`). This is because matugen's mode flag only affects **M3 tonal-palette derivation from a source color** — the code path used by `matugen image` (Material You). Our static presets never go through that derivation; they supply every key directly. This means **D-06's palette-lightness auto-detection must be implemented as a wholly separate computation** (reading the rendered palette's `background`/`surface` hex and computing perceptual lightness), decoupled from matugen entirely — it is not something matugen infers for us on the static-preset path. `-m` only needs to be passed for the two Material You entries (`materialyou`, `materialyou-light`), confirmed by a second empirical test showing genuinely different rendered output between `-m light` and `-m dark` on the same wallpaper image.

The second major finding: **two additional hardcoded preset-name arrays exist outside `theme-apply`** — `theme-parity`'s default `TARGETS=(materialyou catppuccin dracula gruvbox nord rosepine tokyonight)` and `theme-stress-test`'s `STATIC_PRESETS=(catppuccin dracula gruvbox nord rosepine tokyonight)`. Both must be updated (or converted to dynamic `palettes/*.json` enumeration) alongside the ~14 new presets this phase adds, or the parity gate and stress-test harness will silently exclude every new preset from coverage.

Wallpaper inventory reveals two pre-existing data-quality issues the planner should resolve explicitly rather than paper over: there is **no `dracula/` wallpaper folder** at all (falls open to the shared pool under D-12, but is worth a conscious decision), and the staged `everfrost/` folder does not match Omarchy's actual upstream theme name `everforest` — likely worth reconciling during the D-09 rename pass. Both are logged under Open Questions.

For light-palette authoring, canonical upstream sources were verified directly for five of the requested families — Catppuccin Latte, Rosé Pine Dawn, Gruvbox Light, TokyoNight Day, and Kanagawa Lotus all have official, freely-licensed hex palettes. Nord has no official free light variant (a 2017 GitHub issue discussing one was never shipped), and Dracula's only light variant ("Alucard") is a **Dracula Pro paid-product exclusive** — not present in the free `dracula/dracula-theme` repo. Both should stay dark-only per D-02's own criterion ("canonical upstream light variant" — Alucard fails "freely available," Nord fails "exists at all").

**Primary recommendation:** Implement mode as a first-class computed value (not a matugen artifact) written to a small state-dir file during `generate.sh`, consumed by `gtk.sh` and the new fzf color-fragment renderer; extend the two extra hardcoded preset arrays alongside `theme-apply`'s dynamic `palettes/*.json` enumeration; reuse fzf's own upstream `fzf-preview.sh` icat integration pattern verbatim rather than re-deriving the kitty graphics protocol invocation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Palette rendering (matugen json/image) | Theme Engine (bash orchestration) | — | `generate.sh` is the sole render entrypoint; templates live under `matugen/` |
| Mode detection (light/dark) | Theme Engine (bash orchestration) | — | Must run at render time, before commit, since it drives which GTK settings get written; matugen itself cannot supply it for static presets (verified — see Summary) |
| GTK3/GTK4 signal propagation (gsettings, settings.ini) | Desktop Session (GTK/gsettings/portal) | Theme Engine (renders the input files) | The engine renders files and writes gsettings; the portal + GTK3/4 runtime is what actually applies them to running apps |
| Wallpaper storage & selection | Filesystem (`~/Pictures/Wallpapers/`) | Theme Engine (`theme-apply` wallpaper auto-set) | Wallpapers are plain files on disk; the engine only reads/writes a `current.jpg` symlink and small state files |
| Wallpaper picker UI | Terminal UI (fzf + kitty graphics protocol) | Theme Engine (invoked on selection) | Picker is a thin fzf/bash frontend; theme re-apply on selection delegates back to the single `theme-apply` entrypoint (no duplicated logic) |
| Output-contract validation | Theme Engine (`theme-parity`, `contract.json`) | — | Structural/name-set/semantic-value parity checks are pure render-time validation, no live session needed |

## Standard Stack

### Core
| Tool | Version (installed, verified) | Purpose | Why Standard |
|------|---------|---------|--------------|
| matugen-bin | 4.1.0 | Renders palette JSON / wallpaper image → all themed app config files | Already the engine's sole rendering tool; `-m light\|dark` flag confirmed present via `matugen --help` [VERIFIED: local binary] |
| fzf | 0.74.0 | Wallpaper picker list + fuzzy filter + preview pane host | Already in use; full `--color` COLSPEC slot list confirmed via `fzf --man` [VERIFIED: local binary] |
| kitty / kitten icat | 0.47.4 | Pixel-perfect image rendering in the picker's preview pane via the kitty graphics protocol | Already the picker's host terminal (floating kitty window); `kitten icat` ships with kitty itself, no separate install [VERIFIED: local binary] |
| chafa | 1.18.2 | Fallback/alternate renderer; supports `--format kitty` (native kitty graphics protocol output, not block art) as well as `iterm`/`sixels`/`symbols` | Already in use (current picker uses `chafa --symbols=block`); `-f kitty` upgrades it to the same pixel-perfect protocol without swapping tools [VERIFIED: local binary `chafa --help`] |
| jq | (already installed) | contract.json parsing, palette JSON key inspection | Already the pipeline's JSON tool throughout `lib/contract.sh` |
| python3 | (already installed) | Lightness/color-math computation (mirrors the existing `theme_engine_gtk4_accent` colorsys pattern in `lib/gtk.sh`) | Already used in this exact codebase for HSL-based accent-color mapping — same technique extends naturally to lightness-based mode detection |
| adw-gtk-theme | 6.5-1 (official `extra` repo) | Provides both `adw-gtk3` (light) and `adw-gtk3-dark` GTK3 theme names | **Verified installed and both variants present:** `/usr/share/themes/adw-gtk3/` and `/usr/share/themes/adw-gtk3-dark/` both exist on this machine [VERIFIED: `pacman -Ql adw-gtk-theme`, `ls /usr/share/themes/`] — D-07's light/dark GTK3 theme-name flip has no missing-package risk this time (CLAUDE.md's prior finding about this package being absent is now resolved) |

### Supporting
No new libraries are required — every tool this phase needs is already installed on the target machine and already integrated into the pipeline. This phase is pure extension of existing bash/matugen/fzf/kitty/chafa usage, not a new-dependency phase.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Own lightness-detection math (python3 colorsys HLS) | A dedicated color library (e.g. `culori`-equivalent) | No such tool is already in the stack; python3's stdlib `colorsys` is already proven in this exact codebase (`theme_engine_gtk4_accent`) — adding a new dependency for one threshold calculation is unjustified |
| `kitten icat` for previews | `chafa -f kitty` | Both produce native kitty-graphics-protocol output; `kitten icat` is the canonical tool and has fzf's own upstream integration pattern (`fzf-preview.sh`) to crib from directly — prefer it as primary, `chafa -f kitty` as a documented fallback if `kitten` behaves unexpectedly inside the floating-kitty preview pane |
| Dynamic `palettes/*.json` enumeration everywhere | Manually maintained hardcoded arrays (current state in theme-parity/theme-stress-test) | Hardcoded arrays are the CURRENT state and are a proven pitfall source (new presets silently excluded from parity/stress coverage) — recommend converting both to dynamic enumeration as part of this phase's preset expansion, not just appending to the arrays |

**Installation:**
No install commands needed — all tools already present. Nothing to add to `install.sh` for this phase.

**Version verification:** All versions above were confirmed directly against the installed binaries on the target machine (`matugen --version`, `fzf --version`, `kitty --version`, `chafa --version`, `pacman -Q adw-gtk-theme`), not against training-data assumptions.

## Package Legitimacy Audit

Not applicable — this phase installs **no new packages**. Every tool used (matugen-bin, fzf, kitty, chafa, jq, python3, adw-gtk-theme) is already installed and already part of this repo's `install.sh`/pipeline. No `npm view`/`pip index`/`cargo search` gate is triggered.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────┐
                         │   theme-apply <name>         │
                         │  (single entrypoint, D-01)   │
                         └──────────────┬───────────────┘
                                        │
                    validate name against palettes/*.json
                    OR literal "materialyou"/"materialyou-light"  ◄── extend allowlist (D-05)
                                        │
                                        ▼
                         ┌─────────────────────────────┐
                         │  generate.sh (render step)   │
                         │  matugen json|image -m ...   │◄── mode flag ONLY meaningful
                         └──────────────┬───────────────┘     for materialyou (verified,
                                        │                      see Pitfall 1)
                         ┌──────────────┴───────────────┐
                         │  NEW: mode detection step     │
                         │  read rendered background/    │
                         │  surface hex OR palette JSON  │◄── decoupled from matugen
                         │  "mode" override key (D-06)   │    entirely — separate calc
                         └──────────────┬───────────────┘
                                        │  writes state-dir mode marker
                                        ▼
                         ┌─────────────────────────────┐
                         │  commit.sh (atomic move)      │
                         │  rsync tmp/ → state dir       │
                         └──────────────┬───────────────┘
                                        │
                                        ▼
                         ┌─────────────────────────────┐
                         │  reload.sh (single fan-out    │
                         │  owner) → gtk.sh reload       │
                         └──────────────┬───────────────┘
                                        │
                    ┌───────────────────┼────────────────────┐
                    ▼                   ▼                    ▼
        gsettings color-scheme   GTK3 theme-name        GTK4 accent
        prefer-dark|light (D-07) adw-gtk3|-dark (D-07)  mapping (existing)
                    │
                    ▼
        settings.ini SYMLINK (NEW, D-08) → matugen-rendered
        state-dir target, seeded by stow.sh

  ── Wallpaper picker (separate invocation path) ──────────────────────
  wallpaper-switch.sh (floating kitty) → wallpaper-picker.sh (fzf)
        │
        ├─ restricted to Wallpapers/<active-theme>/ when static (D-16)
        │  fall-open to full pool if folder empty/missing (D-12)
        ├─ preview pane: kitten icat / chafa -f kitty (D-13/D-14)
        ├─ fzf --color sourced from NEW state-dir fzf fragment (D-15)
        └─ on select → ln -sfr current.jpg, theme-apply <active-theme>
                        (auto-sets wallpaper on static theme-apply, D-11)
```

### Recommended Project Structure
```
theme-engine/.config/theme-engine/
├── theme-apply              # extend allowlist: materialyou-light + palettes/*.json glob (unchanged mechanism)
├── contract.json            # grows: settings.ini target (D-08), fzf color fragment (D-15)
├── theme-parity             # extend default TARGETS array (or make it dynamic — Pitfall 2) + light fixture
├── theme-stress-test        # extend STATIC_PRESETS array (Pitfall 2) — same risk, same fix
├── lib/
│   ├── generate.sh          # add matugen -m light|dark branch for materialyou/materialyou-light only
│   ├── mode.sh               # NEW — lightness detection + override-key read, single source of truth for "is this render light or dark"
│   ├── gtk.sh                # becomes mode-aware: reads mode.sh's output instead of hardcoding prefer-dark/adw-gtk3-dark
│   ├── commit.sh             # unchanged mechanism; settings.ini symlink wiring added alongside walker/yazi symlinks
│   └── reload.sh             # unchanged mechanism
└── palettes/
    ├── catppuccin.json  … existing 6
    ├── catppuccin-latte.json          # NEW light presets (standalone, D-03)
    ├── rosepine-dawn.json
    ├── gruvbox-light.json
    ├── tokyonight-day.json
    ├── kanagawa-lotus.json
    ├── matte-black.json  … 9 NEW Omarchy-lineup dark presets (D-01)
    └── ...

matugen/.config/matugen/templates/
├── gtk-colors.css            # unchanged (already mode-agnostic — named colors only)
├── gtk3-settings.ini         # NEW template — renders the settings.ini contract target (D-08)
└── fzf-colors.sh (or .conf)  # NEW template — renders the fzf color fragment (D-15)

gtk/.config/gtk-3.0/
└── settings.ini              # becomes a SYMLINK target (D-08), seeded by stow.sh, no longer stow-tracked content

hypr/.config/hypr/scripts/
├── wallpaper-picker.sh        # rewritten preview pane (kitten icat), restriction logic (D-16), fzf color sourcing (D-15)
└── theme-init.sh              # stays a thin caller; may need last-used-wallpaper read if D-11 wires through here too
```

### Pattern 1: Mode is computed, never inherited from matugen
**What:** For static presets, the render step (`matugen json`) ignores `-m` entirely — colors come through byte-identical regardless of the flag (verified, see Summary/Pitfall 1). Mode must be derived independently: read the palette JSON's optional top-level `"mode"` key first (D-06 override); if absent, compute perceptual lightness of the rendered `background`/`surface` hex.
**When to use:** Every `theme-apply <static-preset>` invocation, before `commit.sh` runs, so `gtk.sh`'s reload step can branch on it.
**Example (extends the exact pattern already used for GTK4 accent mapping in `lib/gtk.sh`):**
```bash
# theme-engine/lib/mode.sh — NEW file, same shape as gtk.sh's accent helper
theme_engine_detect_mode() {
    local palette_json="$1"      # e.g. palettes/catppuccin-latte.json
    local rendered_bg_hex="$2"   # background hex already rendered this run

    # D-06 override key wins when present
    local override
    override=$(jq -r '.mode // empty' "$palette_json" 2>/dev/null)
    if [[ "$override" == "light" || "$override" == "dark" ]]; then
        echo "$override"
        return 0
    fi

    # Fallback: perceptual lightness of background, same colorsys technique
    # already proven in theme_engine_gtk4_accent (lib/gtk.sh)
    python3 - "$rendered_bg_hex" <<'PYEOF'
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
l = colorsys.rgb_to_hls(r, g, b)[1]
print("light" if l > 0.5 else "dark")
PYEOF
}
```
*Threshold (`0.5`) and which key (`background` vs `surface`) is Claude's Discretion per CONTEXT.md — validate against every shipped palette, including the new light presets, before locking it.*

### Pattern 2: materialyou-light is the only case where `-m` actually matters
**What:** `matugen image <wallpaper> -m light` produces genuinely different M3-derived colors than `-m dark` (verified empirically — full 20-color kitty.conf diff, not a no-op). This is because image-based generation derives the tonal palette from a source color, and mode changes that derivation.
**When to use:** Only in the `generate.sh` branch that already special-cases `name == "materialyou"`; add a sibling branch for `materialyou-light` that passes `-m light` (and `materialyou` stays implicitly `-m dark`, matching current default behavior — no behavior change for the existing entry).
**Example:**
```bash
# lib/generate.sh — extend the existing materialyou branch
if [[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]; then
    local mode_flag="dark"
    [[ "$name" == "materialyou-light" ]] && mode_flag="light"
    matugen image "$wallpaper" --source-color-index 0 -m "$mode_flag" \
        -c "$MATUGEN_CFG" -p "$tmp" 2>"$GENERATE_LOG"
fi
```

### Pattern 3: settings.ini as a rendered contract target + seeded symlink
**What:** Same pattern already used for `walker-style.css` and `yazi.toml` in `commit.sh` (`ln -sf "$STATE_DIR/<file>" "$target_path"`), applied to `gtk-3.0/settings.ini`. A new matugen template renders `gtk-application-prefer-dark-theme`/`gtk-theme-name` (mode-driven) plus the static, non-themed lines (`gtk-icon-theme-name`, `gtk-cursor-theme-name`, `gtk-cursor-theme-size`, `gtk-font-name` — copy verbatim from the current file, D-07 says only colors+GTK signals flip, icon/cursor stay untouched).
**When to use:** `stow.sh`'s first-boot seed step (already calls `theme-apply catppuccin` — needs to additionally symlink settings.ini, same as it currently doesn't need to for walker/yazi because `commit.sh` already does that wiring on every apply).
**Example template skeleton:**
```ini
# matugen/.config/matugen/templates/gtk3-settings.ini.template — NEW
[Settings]
gtk-application-prefer-dark-theme={{ "1" if mode == "light" else "1" }}  {{!-- mode drives THIS, not the icon/cursor lines --}}
gtk-theme-name={{ "adw-gtk3" if mode == "light" else "adw-gtk3-dark" }}
gtk-icon-theme-name=Adwaita
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-font-name=FiraCode Nerd Font 11
```
*Note: matugen's own templating language does not have first-class `mode` variable injection the way this pseudocode implies — confirm during planning whether mode should be passed via `--import-json-string` (matugen supports this flag, confirmed in `matugen json --help`) or whether `gtk.sh`'s reload step should instead write settings.ini's two mode-sensitive lines directly via `sed`/`printf` post-render, mirroring how `gtk.sh` already does gsettings via shell rather than matugen templating. This is an open implementation decision for the planner, not fully resolved by this research — flagged in Open Questions.*

### Pattern 4: kitty graphics protocol preview pane (verbatim from fzf's own upstream script)
**What:** fzf's own maintainers ship a reference `bin/fzf-preview.sh` that already solves kitty-icat-in-a-preview-pane correctly, including the scroll-artifact gotcha (a trailing ANSI reset line confuses fzf's own rendering unless handled).
**When to use:** As the preview-script body for the redesigned `wallpaper-picker.sh`, replacing the current `chafa --symbols=block+border+space` invocation.
**Example (sourced directly from `github.com/junegunn/fzf/blob/master/bin/fzf-preview.sh`):**
```bash
# Detection: is this a kitty-graphics-capable terminal?
if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten &>/dev/null; then
    kitten icat --clear --transfer-mode=memory --unicode-placeholder \
        --stdin=no --place="${dim}@0x0" "$file" | sed '$d' | sed $'$s/$/\e[m/'
fi
```
Where `$dim` is computed from `$FZF_PREVIEW_COLUMNS`/`$FZF_PREVIEW_LINES` (already read in the existing picker's preview script). `--clear` prevents stale images lingering when the fzf selection changes (the exact "chafa image doesn't clear on scroll" bug this pattern exists to avoid, per fzf issue discussions).

### Pattern 5: dark preset + light preset key-role mapping (verified against existing rosepine.json)
**What:** Rose Pine's existing dark `palettes/rosepine.json` maps named upstream colors to this repo's 20-key schema as: `primary=rose, on_primary=base, secondary=gold, tertiary=iris, surface/background=base, surface_variant=overlay, on_surface_variant=subtle, outline=highlightHigh, error=love`. The **same role mapping**, applied to Rosé Pine Dawn's official hex values, produces a correct light sibling with zero guesswork about which upstream color plays which schema role.
**When to use:** For every one of the 5 canonical-light presets (D-02) — diff each existing dark JSON's key→upstream-color-name mapping, then re-apply that exact mapping using the light variant's own upstream hex values (never re-derive the mapping from scratch, never invent new role assignments for the light sibling).
**Example — Rosé Pine Dawn, using the verified official palette (rosepinetheme.com/palette) and rosepine.json's exact role mapping:**
```json
{
  "colors": {
    "image": "",
    "primary": { "default": { "color": "#d7827e" } },
    "on_primary": { "default": { "color": "#faf4ed" } },
    "secondary": { "default": { "color": "#ea9d34" } },
    "tertiary": { "default": { "color": "#907aa9" } },
    "surface": { "default": { "color": "#faf4ed" } },
    "background": { "default": { "color": "#faf4ed" } },
    "surface_variant": { "default": { "color": "#f2e9e1" } },
    "on_surface_variant": { "default": { "color": "#797593" } },
    "outline": { "default": { "color": "#797593" } },
    "error": { "default": { "color": "#b4637a" } }
  }
}
```
*(remaining keys — `on_secondary`, `*_container` variants, `on_error` — follow the same "copy the dark JSON's structural shape, substitute the Dawn hex for the equivalent named role" method; `highlightHigh`'s exact Dawn hex was not directly captured by this research's source fetch and should be pulled from `rosepinetheme.com/palette` during execution — see Open Questions.)*

### Anti-Patterns to Avoid
- **Passing `-m` to `matugen json` expecting it to affect a static preset's colors:** it does nothing (verified). Don't build any light/dark logic that depends on this — it will silently no-op.
- **Adding a new hardcoded preset array instead of fixing the two existing ones:** `theme-parity`'s `TARGETS` and `theme-stress-test`'s `STATIC_PRESETS` are already a proven drift source (see Pitfall 2) — growing the preset count without touching these two files will silently under-test every new preset.
- **In-place editing of `gtk-3.0/settings.ini` as a stow-tracked file:** violates the git-clean-after-switch invariant already enforced elsewhere in this pipeline (stress-tested). Must be a symlink to a state-dir render target, exactly like walker/yazi.
- **Inventing a light palette for a family with no canonical upstream source:** D-02 is explicit — Nord and Dracula (free tier) have none; don't hand-transcribe "Nord Light" or "Alucard" from an unofficial community fork without flagging it to the user first (Assumptions Log / Open Questions cover this).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Kitty-graphics-protocol image rendering inside an fzf preview pane, including the scroll/clear-artifact handling | A custom `kitten icat` invocation figured out from scratch by trial and error | The exact invocation from fzf's own upstream `bin/fzf-preview.sh` (Pattern 4 above) | fzf's own maintainers already solved the "stale image on scroll" and "reset-code confuses fzf's line count" issues referenced in multiple fzf/kitty/ghostty GitHub issues — re-deriving this from first principles risks reproducing already-fixed bugs |
| Perceptual-lightness / accent-color math from a hex string | A bespoke luminance formula | `python3`'s stdlib `colorsys.rgb_to_hls` — already proven working in this exact file (`theme_engine_gtk4_accent` in `lib/gtk.sh`) | Zero new dependency, zero new pattern to review — literally copy the technique already shipped and tested in this codebase for the accent-color feature |
| GTK3 theme-name / dark-mode gsettings toggling | A new settings-writing abstraction | Extend the existing `theme_engine_gtk_reload` function in `lib/gtk.sh` — it already owns every gsettings call in this pipeline | Single-owner discipline this codebase already enforces (`reload.sh`'s header comment: "no other file... may invoke... this is the single owner") — a parallel gsettings-writing path would violate that invariant |

**Key insight:** Every "don't hand-roll" item in this phase has an in-repo precedent to copy from — this is a mature, disciplined codebase and the correct move is almost always "extend the existing single-owner function," not "write a new one."

## Runtime State Inventory

> Phase 5 triggers this section because D-09 renames two wallpaper folders (`rose-pine`→`rosepine`, `tokyo-night`→`tokyonight`) and D-04 deletes the legacy `themes/` stow package.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `~/.local/state/theme/current-theme` already stores the **palette name** (`rosepine`, `tokyonight` — no dash), not the wallpaper folder name. Verified: `theme-apply`'s usage/validation enumerates `palettes/*.json`, and those files are already named `rosepine.json`/`tokyonight.json` (no dash). The dash-vs-no-dash drift is **wallpaper-folder-only**. | No data migration needed for `current-theme` — it's already correct. Only the two wallpaper folders themselves need `git mv`. |
| Live service config | None — no external service (n8n, Datadog, etc.) references wallpaper folder names or theme names in this project. | None. |
| OS-registered state | None — no systemd units, Task Scheduler entries, or similar reference wallpaper/theme folder names. | None. |
| Secrets/env vars | None — no SOPS keys or env vars reference `rose-pine`/`tokyo-night`/`themes/` by name. | None. |
| Build artifacts | `current.jpg` symlink currently points to a **loose root-level file** (`shaded-landscape.jpg`), not into any per-theme folder — verified via `ls -la`. The rename is transparent to it. No other build artifact (egg-info, compiled binary) references these names. | None, but note explicitly: if a future default seed ever points `current.jpg` into `rose-pine/` or `tokyo-night/` before the rename lands, that symlink would dangle — sequence the rename before any wallpaper-auto-set logic (D-11) that could point into those folders. |

**themes/ package deletion (D-04) verification:** Grepped every `.sh`/`.toml`/`.conf`/`.json` file in the repo (excluding `themes/` itself) for `themes/.config/themes`, `~/.config/themes`, and `$HOME/.config/themes` — **zero references found** outside `themes/` itself and `stow.sh`'s package list (`themes` in the `PACKAGES` array) and a comment string ("Use Super+Shift+T to switch themes" — unrelated, just prose). Confirmed via `grep -rln "themes"` across `kitty/`, `yazi/`, `vscodium/` config trees — no hits. **Safe to delete** after removing the `themes` entry from `stow.sh`'s `PACKAGES` array. [VERIFIED: direct grep against this repo]

## Common Pitfalls

### Pitfall 1: `matugen -m` is a silent no-op for custom-JSON (static preset) rendering
**What goes wrong:** A planner/executor might assume passing `-m light` to `matugen json <palette>` will "make it light" the same way it does for `matugen image`. It does not — output is byte-identical regardless of `-m` when every color key already has a literal hex value.
**Why it happens:** matugen's `-m` flag controls M3 tonal-palette *derivation* from a single source color; a custom JSON with every key already specified skips derivation entirely, so there's nothing for the mode flag to influence.
**How to avoid:** Treat mode detection for static presets as a fully separate computation (Pattern 1) — never wire `-m` into the static-preset render branch of `generate.sh`. Only the materialyou/materialyou-light branch needs `-m`.
**Warning signs:** If `theme-parity`'s light fixture and dark fixture render byte-identical output for a static preset, this pitfall has been reintroduced.
**Evidence:** Verified empirically this session — `diff` of `matugen json catppuccin.json -m dark` vs `-m light` rendered output showed zero differences across all 10 contract files.

### Pitfall 2: Hardcoded preset-name arrays outside `theme-apply` silently exclude new presets
**What goes wrong:** `theme-parity`'s default `TARGETS=(materialyou catppuccin dracula gruvbox nord rosepine tokyonight)` and `theme-stress-test`'s `STATIC_PRESETS=(catppuccin dracula gruvbox nord rosepine tokyonight)` are both literal bash arrays, not derived from `palettes/*.json` like `theme-apply`'s own usage text is. Adding ~14 new palette JSONs without touching these two files means the parity gate and stress-test harness never actually exercise the new presets — they'll appear to pass cleanly while providing zero coverage.
**Why it happens:** These arrays were written when there were exactly 6 static presets and nobody has needed to touch them since; the drift is invisible because the scripts still run successfully, just against a shrinking fraction of the real preset surface.
**How to avoid:** Update both arrays to include every new preset name (all 9 new dark + 5 new light + existing 6, plus `materialyou-light`), or better, convert both to `for f in "$PALETTES_DIR"/*.json; do ...; done` dynamic enumeration matching `theme-apply`'s own pattern — eliminates the drift risk permanently.
**Warning signs:** `theme-parity` (no argument) or `theme-stress-test` completing "successfully" without ever mentioning a newly-added preset name in its output.

### Pitfall 3: GTK3 has no live CSS/settings.ini reload — the process must restart
**What goes wrong:** Rendering a fresh `settings.ini` into the state dir and re-symlinking it changes nothing for an already-running GTK3 process (Thunar) until it restarts — same limitation already documented in this codebase for `gtk-3.0-colors.css`.
**Why it happens:** GTK3 reads `settings.ini` once at process start; there is no GSettings-equivalent live-watch for this file.
**How to avoid:** The settings.ini symlink refresh must ride along with the *same* Thunar-restart logic `theme_engine_gtk_reload` already implements for CSS changes (the window-open deferred-watcher pattern) — do not build a second, parallel restart mechanism.
**Warning signs:** Switching from dark to light shows correctly-colored CSS in Thunar (if GTK3 CSS somehow lived-reloaded, which it doesn't either) but the window chrome/widget style stays on the old GTK theme name.

### Pitfall 4: Two of the requested "canonical light variants" don't actually have a free canonical source
**What goes wrong:** D-02 lists "rose-pine dawn, gruvbox-light, tokyonight-day, kanagawa-lotus" as examples but doesn't enumerate the full family list exhaustively — a planner might assume every one of the ~15 total families (6 existing + 9 new Omarchy-lineup) needs a light sibling investigated.
**Why it happens:** Not every popular dark theme brand ships an official light counterpart, and one that appears to exist (Dracula's "Alucard") is gated behind a paid product tier, not the free/open repo this project would transcribe from.
**How to avoid:** Only the 5 families verified in this research (catppuccin, rosepine, gruvbox, tokyonight, kanagawa) have a **free, official, canonical** light source. Nord (no free official light variant exists — a 2017 proposal issue was never shipped) and Dracula (Alucard is Dracula Pro-exclusive) should stay dark-only. None of the 9 new Omarchy-lineup themes (matte-black, osaka-jade, ristretto, everfrost, hackerman, miasma, ethereal, vantablack) have a light sibling in Omarchy's own theme directory listing either — confirmed by enumerating Omarchy's `themes/` directory (only `catppuccin-latte` and `flexoki-light` exist as separate light-flavored directories among 18 total, and `flexoki` isn't part of this project's lineup).
**Warning signs:** A `nord-light.json` or `dracula-light.json`/`alucard.json` appearing in `palettes/` without an explicit user decision documented — that would be inventing colors D-02 explicitly forbids ("do not invent light palettes for families without one").

## Code Examples

### fzf color fragment — recommended slot-to-palette-role mapping (D-15, Claude's Discretion)
```bash
# matugen/.config/matugen/templates/fzf-colors.conf — NEW template (format TBD: shell-exportable
# key=value pairs are simplest for wallpaper-picker.sh to `source` directly)
FZF_COLOR_FG="{{colors.on_background.default.hex}}"
FZF_COLOR_BG="-1"
FZF_COLOR_HL="{{colors.tertiary.default.hex}}"
FZF_COLOR_FG_PLUS="{{colors.on_primary_container.default.hex}}"
FZF_COLOR_BG_PLUS="{{colors.surface_variant.default.hex}}"
FZF_COLOR_HL_PLUS="{{colors.tertiary.default.hex}}"
FZF_COLOR_INFO="{{colors.secondary.default.hex}}"
FZF_COLOR_PROMPT="{{colors.primary.default.hex}}"
FZF_COLOR_POINTER="{{colors.tertiary.default.hex}}"
FZF_COLOR_MARKER="{{colors.tertiary.default.hex}}"
FZF_COLOR_SPINNER="{{colors.secondary.default.hex}}"
FZF_COLOR_HEADER="{{colors.on_surface_variant.default.hex}}"
FZF_COLOR_BORDER="{{colors.outline.default.hex}}"
```
Then in `wallpaper-picker.sh`:
```bash
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true
FZF_COLOR_ARGS=(
    --color="fg:${FZF_COLOR_FG:-#cdd6f4},bg:${FZF_COLOR_BG:--1},hl:${FZF_COLOR_HL:-#f5c2e7}"
    --color="fg+:${FZF_COLOR_FG_PLUS:-#cdd6f4},bg+:${FZF_COLOR_BG_PLUS:-#313244},hl+:${FZF_COLOR_HL_PLUS:-#f5c2e7}"
    --color="info:${FZF_COLOR_INFO:-#94e2d5},prompt:${FZF_COLOR_PROMPT:-#cba6f7},pointer:${FZF_COLOR_POINTER:-#f5c2e7}"
    --color="marker:${FZF_COLOR_MARKER:-#f5c2e7},spinner:${FZF_COLOR_SPINNER:-#94e2d5},header:${FZF_COLOR_HEADER:-#a6adc8}"
    --color="border:${FZF_COLOR_BORDER:-#585b70}"
)
```
*Fallback hex literals preserve current catppuccin-mocha behavior if the state-dir fragment is missing (fresh install before first `theme-apply`), matching this codebase's existing graceful-degradation style.*

### Preset-name allowlist extension (theme-apply, D-05)
```bash
# theme-apply — extend the existing validation gate (currently only special-cases "materialyou")
if [[ "$NAME" != "materialyou" && "$NAME" != "materialyou-light" ]]; then
    if [[ ! -f "$PALETTES_DIR/$NAME.json" ]]; then
        # ... existing reject-unknown-name logic, unchanged
    fi
fi
```
This same two-name special case must be replicated in `theme-parity`'s existing single-target validation block (it duplicates this exact check today — CONTEXT.md's canonical_refs already flags this).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Wallpaper picker preview via `chafa --symbols=block+border+space` (character-cell block art) | `chafa -f kitty` or `kitten icat` (native kitty graphics protocol, pixel-perfect) | Kitty's graphics protocol has been stable and widely adopted since well before this repo's kitty 0.47.4; chafa added `-f kitty` output support some time ago — both tools already installed support it today, this is not a version-gated feature | Directly enables D-13/D-14's "pixel-perfect previews" requirement with zero new dependencies |
| Single dark-only GTK theme name hardcoded in two chokepoints | Mode-derived GTK theme name, computed once per `theme-apply` and threaded through both chokepoints | This phase (THM-01) is the first time this pipeline supports a light path at all | Closes the two dark-hardcoded chokepoints named explicitly in the phase's success criteria |

**Deprecated/outdated:**
- Character-block-art (`chafa --symbols=...`) previews for the wallpaper picker: superseded by native graphics-protocol rendering in the same tool (`chafa -f kitty`) — no tool swap needed, just a flag change plus/or a switch to `kitten icat`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Rosé Pine Dawn's `highlightLow`/`highlightMed`/`highlightHigh` exact hex values (needed to complete the `outline` key mapping for `rosepine-dawn.json`) were not captured by this session's source fetch — only base/surface/overlay/muted/subtle/text/love/gold/rose/pine/foam/iris were returned by the WebFetch of rosepinetheme.com/palette. | Code Examples (Pattern 5) | Low — the executor must pull the missing 3 values directly from `rosepinetheme.com/palette` or the `rose-pine-palette` npm/GitHub package before finalizing the JSON; using the wrong value only affects the `outline` key's exact shade, not overall correctness |
| A2 | The Omarchy theme directory listing (18 themes, no light siblings besides catppuccin-latte/flexoki-light) was obtained via `WebFetch` summarization of a GitHub directory tree page, not a direct `git clone`/API listing. | Pitfall 4 / Common Pitfalls | Medium — if Omarchy has since added a light variant for one of the 9 new lineup themes that wasn't visible in the fetched listing, D-02's "no light palette for families without a canonical source" guidance could wrongly exclude a now-available option. Recommend the executor re-check `github.com/basecamp/omarchy/tree/master/themes` directly before finalizing the "dark-only" list. |
| A3 | TokyoNight Day's exact `bg`/`fg`/accent hex values were extracted via WebFetch summarization of the raw `tokyonight_day.lua` source rather than a byte-exact copy — the values quoted (`bg: #e1e2e7`, etc.) should be spot-checked against the raw file before being hand-typed into a palette JSON. | Code Examples / Pattern 5 discussion | Low — summarization of a raw Lua table is generally reliable, but any single wrong hex digit would only affect that one shade, not the overall theme's correctness |
| A4 | The recommended fzf `--color` slot-to-palette-role mapping (Code Examples) is an original recommendation by this research, not sourced from any existing convention in this repo or upstream — CONTEXT.md explicitly marks slot mapping as Claude's Discretion. | Code Examples | Low — purely a starting point; the planner/executor is free to adjust which palette role feeds which fzf slot as long as no hardcoded catppuccin hex remains (D-15's actual requirement) |
| A5 | The exact matugen templating mechanism for injecting a computed `mode` value into a rendered `settings.ini` template (via `--import-json-string` vs. a post-render `sed` patch in `gtk.sh`) was not resolved by this research — both are technically possible given matugen's confirmed CLI flags, but which one fits this codebase's existing single-owner-per-concern discipline best is a planning-time decision. | Architecture Patterns, Pattern 3 | Medium — picking the wrong mechanism could mean writing GTK-signal logic in two places (a "second hardcode site," which D-13/PIPE-05's design explicitly warns against elsewhere in this codebase) instead of one |

**If this table is empty:** N/A — see entries above.

## Open Questions

1. **`everfrost` (staged wallpaper folder) vs `everforest` (Omarchy's actual upstream theme name)**
   - What we know: The local `Wallpapers/everfrost/` folder exists (4 files) and Omarchy's own theme lineup includes a theme named `everforest`, not `everfrost` — no `everfrost` theme appears in Omarchy's published theme list.
   - What's unclear: Whether this is an intentional distinct name chosen by the user when staging wallpapers, or a typo that should be corrected to `everforest` for both the wallpaper folder and the new palette JSON, to keep the "transcribed from Omarchy's published themes" (D-01) promise accurate.
   - Recommendation: Surface this to the user explicitly during planning/discussion before naming the palette JSON — don't silently pick one.

2. **Missing `dracula/` wallpaper folder**
   - What we know: `dracula.json` already exists as a palette (one of the pre-existing 6), but there is no `Wallpapers/dracula/` folder at all — confirmed via `find`.
   - What's unclear: Whether the user wants a `dracula/` folder created and populated (matching D-09's strict 1:1 convention), or is fine with Dracula permanently falling open to the shared pool per D-12's fall-open semantics.
   - Recommendation: Treat as an explicit planning decision, not a silent fall-through — D-09's own wording ("Strict convention: `Wallpapers/<preset-name>/` matches the palette JSON name exactly") suggests every preset should have a folder, which Dracula currently violates.

3. **Where does the mode value get injected into the rendered `settings.ini` — matugen templating or a post-render `gtk.sh` patch?**
   - What we know: matugen supports `--import-json-string` (confirmed via CLI help) which could inject an extra `mode` field into template render data; alternatively, `gtk.sh`'s reload step already directly writes gsettings values via shell (not matugen templating) for the exact same light/dark concept.
   - What's unclear: Which mechanism better fits this codebase's demonstrated preference for single-owner-per-concern (matugen owns color rendering; `gtk.sh` owns GTK signal writing) — settings.ini blends both concerns (colors are NOT in settings.ini, but the dark/light *signal* conceptually belongs with gtk.sh's other signal-writing, not matugen's template rendering).
   - Recommendation: Lean toward keeping mode-writing logic in `gtk.sh`/`commit.sh` (shell-side), with matugen's settings.ini template rendering only the genuinely static lines (icon/cursor/font) — avoids matugen needing any new mode-aware templating feature it wasn't designed for. Confirm during planning.

4. **Last-used-wallpaper-per-theme storage format (D-11)**
   - What we know: No existing per-theme state tracking exists in this codebase. The closest existing convention is `~/.cache/current-waybar-layout` (a single flat file, one value, read with a hardcoded fallback) and `~/.local/state/theme/current-theme` (same shape).
   - What's unclear: Whether "last-used wallpaper per theme" should be one file per theme (e.g. `~/.local/state/theme/last-wallpaper/<preset-name>`) or a single small JSON/flat mapping file.
   - Recommendation: One-flat-file-per-theme under a new subdirectory most closely matches this codebase's existing convention (avoids introducing JSON-parsing into a script that currently only ever `cat`s single-value files) — Claude's Discretion per CONTEXT.md, but this is the natural fit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| matugen-bin | Palette rendering (all presets + materialyou/-light) | ✓ | 4.1.0 | — |
| fzf | Wallpaper picker list UI | ✓ | 0.74.0 | — |
| kitty / kitten icat | Pixel-perfect preview rendering | ✓ | 0.47.4 | chafa -f kitty (same protocol, different tool) |
| chafa | Preview rendering (current + fallback) | ✓ | 1.18.2 (supports `-f kitty`) | — |
| jq | contract.json / palette JSON parsing | ✓ | (installed) | — |
| python3 | Lightness/mode-detection computation | ✓ | (installed) | — |
| adw-gtk-theme (`adw-gtk3` + `adw-gtk3-dark`) | GTK3 light/dark theme names (D-07) | ✓ | 6.5-1 | — |
| ImageMagick `identify` | Wallpaper resolution metadata in preview pane | ✓ | 7.1.2-26 | — |
| podman | `verify/container-run.sh` regression harness (will exercise new settings.ini symlink seeding) | ✓ | 6.0.0 | — |
| rsync | `commit.sh` atomic state-dir sync | ✓ | (installed) | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — every tool this phase needs is already installed and verified working.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Personal single-user desktop, no auth surface touched by this phase |
| V3 Session Management | No | Not applicable |
| V4 Access Control | No | Not applicable |
| V5 Input Validation | Yes | Existing allowlist pattern in `theme-apply`/`theme-parity` (validate preset name against actual `palettes/*.json` filenames before path interpolation) must be extended to cover `materialyou-light` as a second special-cased literal, exactly as `materialyou` is today — this is a straightforward extension of an already-correct pattern, not new design |
| V6 Cryptography | No | Not applicable — no secrets/crypto touched by theming |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via unvalidated preset name → `$PALETTES_DIR/$NAME.json` interpolation | Tampering | Already mitigated in `theme-apply`/`theme-parity` (allowlist check against real filenames before interpolation, per the existing Security Domain V5 comment block in both files) — extend to the new `materialyou-light` literal, don't relax the check |
| Path traversal via unvalidated wallpaper filename → `$WALLPAPER_DIR/$SELECTED` interpolation in the redesigned picker (D-16's theme-restricted browsing adds a new selection path) | Tampering | The current picker already constrains the candidate set via `find "$WALLPAPER_DIR" -maxdepth 1 ... -printf "%f\n"` (filenames only, no path components possible) before ever building `$WALLPAPER_DIR/$SELECTED` — the new theme-restricted variant must preserve this same "enumerate real files, never trust raw user/fzf-selection interpolation into a path with `..`-traversal potential" pattern when it adds a per-theme subfolder scan |
| Notification content injection via raw matugen/render error text reaching `notify-send` | Information Disclosure (minor) | Already mitigated — `theme-apply`'s existing error-summary truncation/sanitization (`head -c 200 ... tr -d '\000-\011...'`) covers this; no new render-error surface is added by this phase that bypasses it |

## Sources

### Primary (HIGH confidence)
- Direct repository read: `theme-engine/.config/theme-engine/{theme-apply,contract.json,theme-parity,theme-stress-test,theme-doctor,palettes/*.json,lib/*.sh}`, `matugen/.config/matugen/{config.toml,templates/*}`, `gtk/.config/gtk-{3,4}.0/*`, `hypr/.config/hypr/scripts/{wallpaper-picker.sh,wallpaper-switch.sh,theme-init.sh}`, `stow.sh`, `install.sh`, `themes/.config/themes/*` — full file reads, not summaries
- Direct empirical test on this machine: `matugen json` with `-m light` vs `-m dark` on `catppuccin.json` → byte-identical output (`diff` returned no output) — proves Pitfall 1
- Direct empirical test on this machine: `matugen image` with `-m light` vs `-m dark` on the current wallpaper → genuinely different output (`diff` showed 20+ changed lines) — confirms Pattern 2 is necessary
- `matugen --help` / `matugen json --help` / `matugen image --help` (local binary v4.1.0) — confirms `-m/--mode` flag exists and its exact accepted values
- `fzf --man` (local binary v0.74.0) — full `--color` COLSPEC slot-name list
- `pacman -Q adw-gtk-theme`, `pacman -Ql adw-gtk-theme`, `ls /usr/share/themes/` — confirms both `adw-gtk3` and `adw-gtk3-dark` theme directories are installed
- `gsettings range org.gnome.desktop.interface color-scheme` — confirms enum values `default`/`prefer-dark`/`prefer-light`
- `grep -rln "themes"` across the whole repo (excluding `themes/` itself) — confirms zero references to the legacy `themes/` package, supporting D-04's safe-deletion premise
- `find wallpapers/Pictures/Wallpapers -iname "*dracula*"` and per-folder file counts — confirms the missing `dracula/` folder and current wallpaper inventory
- `catppuccin.com/palette` (WebFetch, official Catppuccin site) — Latte flavor hex values

### Secondary (MEDIUM confidence)
- `raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/lua/tokyonight_day.lua` (WebFetch, official upstream source file, summarized) — TokyoNight Day hex values
- `raw.githubusercontent.com/ellisonleao/gruvbox.nvim/main/lua/gruvbox.lua` (WebFetch, official upstream source file, summarized) — Gruvbox Light hex values
- `raw.githubusercontent.com/rebelot/kanagawa.nvim/master/lua/kanagawa/colors.lua` (WebFetch, official upstream source file, summarized) — Kanagawa Lotus hex values
- `rosepinetheme.com/palette` (WebSearch summary, official Rosé Pine site — not directly WebFetched due to a fetch failure this session) — Dawn variant partial hex values (see Assumption A1 for the gap)
- `github.com/basecamp/omarchy/tree/master/themes` (WebFetch of GitHub directory listing) — 18-theme Omarchy lineup, used to confirm no additional light variants exist among the 9 new dark presets
- `raw.githubusercontent.com/basecamp/omarchy/master/themes/kanagawa/colors.toml` (WebFetch) — confirms Omarchy's per-theme file structure (colors.toml as a 16-color terminal palette, not the M3-style 20-key schema this project uses — transcription requires the same role-mapping technique as Pattern 5)
- WebSearch: Nord official light-variant status (2017 GitHub issue never shipped) — `github.com/arcticicestudio/nord/issues/46`
- WebSearch: Dracula "Alucard" light variant confirmed to be a Dracula Pro (paid) exclusive, not in the free `dracula/dracula-theme` repo — `draculatheme.com/pro`, `draculatheme.com/blog/dracula-pro-2.0-our-first-light-theme`
- WebSearch: fzf + kitty icat integration pattern discussion (GitHub issues #3228, #3199, #3486 on junegunn/fzf; #2238 on kovidgoyal/kitty) — corroborates Pattern 4's approach and the scroll-artifact gotcha

### Tertiary (LOW confidence)
- None — every finding in this research was either directly verified against this repository/machine, or sourced from an official/upstream project page or source file (no unverified forum/blog-only claims were used for factual color values or tool behavior).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every tool already installed and version-verified directly on the target machine, nothing new to evaluate
- Architecture (pipeline extension patterns): HIGH — based on full reads of every file in the existing pipeline plus two empirical CLI tests, not assumption
- Canonical light-palette hex values: MEDIUM — sourced from official upstream project pages/files via WebFetch summarization rather than raw byte-exact file reads in every case (see Assumptions Log A1/A3); role-mapping *technique* (Pattern 5) is HIGH confidence since it's derived directly from this repo's own existing dark JSON
- Pitfalls: HIGH — Pitfalls 1-3 are either empirically tested or directly read from repo source; Pitfall 4 is corroborated by two independent official sources (Nord's own GitHub issue tracker, Dracula's own product pages)

**Research date:** 2026-07-11
**Valid until:** 30 days for pipeline/tool-version findings (stable, locally-verified); canonical palette hex values are effectively permanent (upstream color palettes rarely change) but should be spot-checked against source if this research is reused after a long gap
