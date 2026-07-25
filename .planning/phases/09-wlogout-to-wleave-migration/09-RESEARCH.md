# Phase 9: wlogout to wleave Migration - Research

**Researched:** 2026-07-25
**Domain:** Wayland layer-shell logout menu (GTK3→GTK4 engine swap), Hyprland layerrules, matugen theming pipeline, GTK4 CSS
**Confidence:** HIGH (namespace, config schema, CLI surface, CSS structure, dismissal behavior, dependency availability all confirmed directly against upstream source at the exact pinned AUR tag) / MEDIUM-LOW on two specific points flagged as landmines below (multi-monitor, exit animation)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Visual design (six frosted capsules)**
- D-01: Layout carries over from Phase 6's approved center bar — one horizontal row of six glyph buttons at true vertical center of the screen — but the surface is upgraded, not ported: GTK4 transparent window + Hyprland `layerrule = blur` (the AGS media popup frost technique; requires the 10-06 finding's explicit `window { background-color: transparent; }`).
- D-02: Each button is its own discrete frosted capsule (not one shared card): rounded squares ~96px with large corner radius (~20–24px, AGS-card radius language), ~24px gaps so each capsule reads as its own island.
- D-03: Per-action color identity (floating-waybar rainbow language), applied as tinted frost + on-color glyph: capsule background is the action's container color at translucent alpha; glyph uses the matching `on_*_container` role. This is the M3 pairing that avoids the 08-16 light-preset illegibility failure (colored glyph on neutral translucent pill ≈ 2–3:1 contrast — never do that).
- D-04: Six distinct hues, one per capsule. Material You yields only ~4 native hues, so derive 2 extra with GTK CSS `mix()` — the Phase 8 vertical-bar technique (08-14 durable finding: `mix()` works in `@define-color`, verified via theme-doctor non-empty-provider).
- D-05: Capsule order left→right is a severity gradient: lock, logout, suspend, hibernate, reboot, shutdown — destructive actions grouped at the far end.
- D-06: Rest state: 1px hairline border in each capsule's own hue at reduced alpha.
- D-07: Backdrop: full-screen dim scrim behind the capsules. Starting strength ~40% black; exact alpha is tuned live at the visual checkpoint on both light and dark presets (Claude's discretion within the gate).
- D-08: Hover/aim feedback (keyboard focus renders identically to hover): tint alpha increases, border brightens/glows in the action hue, capsule scales up slightly (~5–8%), and the action name (name only, no key hint) fades + slides up into place below the capsule.
- D-09: Glyphs: refresh the set (do not blindly carry the Phase 6 six). New glyphs must be cmap-verified against the installed Nerd Font before use — the Phase 6/8 discipline; never trust cheat-sheet codepoints, and never let the edit tool store PUA glyphs (08-16: they silently become empty strings — write real UTF-8 codepoints).
- D-10: Animations: staggered pop/slide-in entrance, left-to-right ~30–40ms offsets, total under ~350ms; exit is a reverse-stagger wave on dismissal. On action selection the command must fire immediately — exit animation must never delay the actual power action.

**wlogout retirement (atomic swap)**
- D-11: Full removal, single cutover: the same plan/commit that lands working wleave deletes the `wlogout/` stow package, removes `wlogout` from install.sh PACMAN_PKGS and stow.sh PACKAGES, deletes the matugen `[templates.wlogout]` entry, and replaces the wlogout layerrules. No transition period, no fallback engine. Grep for `wlogout` must come back empty (excluding .planning/ history) after the swap.
- D-12: Render target renamed honestly: `wlogout.css` → `wleave.css` across matugen config.toml, contract.json, theme-doctor's CSS-sheet list, theme-stress-test REPRESENTATIVE_FILES, and the wleave stylesheet's `@import`. Contract stays at the same file count (one target swapped, not added).
- D-13: Package: AUR `wleave` 0.7.1-1 release (NOT `wleave-git` — repo precedent: eww stable approved, eww-git permanently refused). Added to install.sh AUR_PKGS; human package-legitimacy gate at execution time per Phase 4/8 precedent.

**Render-and-look verification**
- D-14: Primary gate is a blocking human visual checkpoint: the executor opens wleave live, captures grim screenshots as phase-artifact evidence, and the user approves on sight before the plan may complete (Phase 8/10 checkpoint pattern). Automated parse/token gates alone can NOT close this phase — that is exactly how WLOG-01 shipped broken.
- D-15: Visual gate coverage: one dark preset, one light preset, plus a live theme switch to prove hot re-theming of the menu (Phase 10 slider-verification pattern; wleave is spawn-per-open so "re-theme" may mean reopen-after-switch — verify what the reload step needs).
- D-16: Automated regression guard: add `wleave.css` to theme-doctor's GTK4 non-empty-provider check (one-line extension of the 06-19 pattern). GTK4 exposes no parse-error signal via PyGObject on this install, so the non-empty-provider assertion is the load-bearing check.
- D-17: Power-action UAT: live spot-check lock + suspend + logout from wleave. Shutdown/reboot are trusted by command-string parity — the layout must carry the Phase 4-audited action strings byte-identically (`hyprshutdown --post-cmd`, `cliphist wipe` prefixes, bare systemctl for suspend/hibernate).

**Behavior & entry points**
- D-18: Open-only semantics: the entry points launch wleave; there is no toggle. Dismissal is Esc AND click-away on the scrim (AGS popup convention). The old pgrep/pkill toggle logic is dropped.
- D-19: Per-button keyboard shortcuts carry over as-is: l=lock, e=logout, u=suspend, h=hibernate, s=shutdown, r=reboot (wleave layout format supports the same keybind field). They stay undocumented in the UI (labels show name only).
- D-20: No confirmation dialogs on any action, including shutdown/reboot — the menu is the deliberate step; severity ordering + distinct colors are the misclick mitigation.
- D-21: Wrapper script renamed `wlogout.sh` → `wleave.sh` (honest naming, consistent with D-12). All three call sites repointed in the atomic swap: keybinds.conf `Super+Shift+Q` (bind itself unchanged), waybar `modules.jsonc` + `config-floating.jsonc` on-clicks, elephant `menus/main.toml` power entry. keybind-doctor descriptions updated to match.
- D-22: Multi-monitor: scrim dims ALL monitors; capsules render on the focused monitor. (Researcher: verify wleave's native multi-output behavior and what flags/config express this.)
- D-23: Launch-failure guard: wleave.sh checks spawn/exit result and fires a notify-send error on failure (capture-scripts `command -v` guard pattern). No fallback menu implementation.

### Claude's Discretion
- Exact scrim alpha, capsule paddings, border widths, corner radius, easing curves, stagger timings — tuned live at the visual checkpoint within the decided design language.
- Which two derived `mix()` hues and the exact hue→action assignment across the six capsules (validate contrast per-preset).
- New glyph selection (cmap-verified) and glyph point size.
- Cursor shape over capsules, arrow-key navigation details, and any wleave-native niceties that don't contradict decisions above.
- How the entrance/exit animations are implemented (wleave native options vs GTK4 CSS transitions) — whichever wleave 0.7.1 actually supports; if reverse-stagger exit is infeasible without delaying actions, degrade to a fast fade and note the deviation.
- Layerrule specifics (namespace, blur, ignorealpha/ignorezero thresholds) for wleave's layer surface.

### Deferred Ideas (OUT OF SCOPE)
- `swaync-intrusive-overlapping.md` (severity: high) — swaync control-center opacity/blur + double-painted notification boxes. Out of Phase 9 scope (swaync bug from Phase 8's 08-09 plan); left pending for a quick task or gap-closure round. Its fix recipe is already root-caused in the todo file.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WLOG-01 | wlogout fully redesigned to modern-rice standards — re-delivered on wleave (GTK4) engine, no regression to Phase 6 center-bar design | Standard Stack (wleave 0.7.1 confirmed AUR package + build deps present), Architecture Patterns (namespace/config/CSS surface verified against source at the pinned tag), Code Examples (config schema + CSS selector strategy), Common Pitfalls (label vertical alignment, `box` node collision, multi-monitor and exit-animation landmines) |
</phase_requirements>

## Summary

wleave 0.7.1 (AUR, release tag — matches D-13 exactly) is a from-scratch Rust/GTK4/libadwaita rewrite of wlogout, not a thin fork. It is **backwards-compatible at the config-file level**: its "legacy" parser accepts exactly the NDJSON format already used by `wlogout/.config/wlogout/layout` (one `{"label","action","text","keybind"}` object per line), so the six Phase-4-audited action strings carry over with **zero required edits** if the file is simply copied. Every fact below marked `[VERIFIED: github.com/AMNatty/wleave@0.7.1]` was confirmed by reading the actual Rust source at the exact git tag the AUR PKGBUILD builds from (`pkgver=0.7.1`, `source=(...#tag=${pkgver})`) — not the `main` branch, which has already moved on to an unreleased 0.8.0 with additional features (`button-defaults`, JSON `icon` shell-expansion) that do **not** exist in the pinned 0.7.1 build.

The migration is straightforward for CSS/config/keybinds/theming-pipeline touchpoints (11 files, all identified below with exact line numbers) but has **two locked decisions that are not natively achievable** on wleave 0.7.1 and need an explicit fallback decision at plan time: (1) **D-22's "scrim on all monitors, capsules on focused monitor"** — wleave opens exactly one window with no per-output targeting; only a single (compositor-chosen) monitor gets anything at all, dimmed or otherwise. (2) **D-10's reverse-stagger exit animation** — wleave hides its window synchronously (`set_visible(false)`) the instant a button is clicked, *before* the (default 100ms) command-execution delay elapses, leaving no window-visible interval in which a GTK CSS exit animation could render. Both are flagged as landmines with recommended closest-achievable alternatives; CONTEXT.md's own Claude's-Discretion clause already pre-authorizes degrading D-10 to a fast fade, so this is not a blocking surprise — it just needs to be planned for explicitly rather than discovered mid-execution.

A third finding changes how sizing should be approached: unlike wlogout (which needed a hand-rolled geometry script deriving outer-box pixel math), **wleave sizes and centers its own window natively** (full-screen layer-shell anchor + `GtkCenterBox`), so `wleave.sh` needs **no port of `wlogout.sh`'s content-box/margin arithmetic** — this whole class of Phase 6 pain (`CONTENT + 2*PAD + 2*BORDER`, focused-monitor margin centering) simply does not apply to the new engine. The other Phase 6 carry-over (GTK not vertically centering label text) still applies, but through a **different mechanism**: wleave positions the un-iconed label via an `Overlay` at `xalign`/`yalign` read from the button's own `width`/`height` JSON fields (0.0–1.0 range), defaulting to `yalign = 0.9` (near the bottom) when unset — so every button in the new layout.json needs an explicit `"height": 0.5` to visually center the glyph, or it will sit low in the capsule exactly the way Phase 6's glyphs sat low without the margin correction.

**Primary recommendation:** Reuse the existing wlogout layout file's action/keybind/label data verbatim (rewrapped into wleave's modern `{"buttons": [...], ...}` JSON schema, not the legacy NDJSON, so top-level options like `buttons-per-row` and `margin` can be declared in the file itself); add `"height": 0.5` to every button; write `wleave.css` using `window { background-color: transparent; }` + `window > box { background-color: rgba(...); }` for the D-01/D-07 transparent-window-plus-scrim split (verified CSS node-name strategy below); target the `layerrule` namespace `wleave` (not `logout_dialog`); and treat D-22/D-10 as explicit, pre-flagged scope decisions to make at plan time rather than research gaps to close later.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Power-action execution (lock/logout/suspend/hibernate/shutdown/reboot) | Browser/Client (local GTK4 app) | OS/systemd (`systemctl`, `hyprshutdown`) | wleave shells out via `sh -c`; the actual privilege/session transition is systemd-logind/systemctl's responsibility, unchanged from wlogout |
| Layer-shell surface placement, blur, scrim | Compositor (Hyprland) | Client (wleave GTK4 window) | `layerrule` (blur, ignore_alpha, animation) is Hyprland-owned and namespace-keyed; the client only controls its own CSS-level transparency/color, not compositor-side blur strength (already documented as a hard architectural ceiling in ROADMAP.md) |
| Color/theme propagation | Theme pipeline (matugen + theme-engine) | Client (wleave CSS `@define-color` consumption) | Unchanged pattern: matugen renders `wleave.css` into the state dir; wleave's own `style.css` `@import`s it, identical to every other GTK-CSS surface in this repo |
| Entry-point dispatch (keybind, waybar click, elephant menu) | Browser/Client (shell scripts + Hyprland binds) | — | Pure invocation plumbing; no server/API tier involved |
| Regression gates (theme-doctor, keybind-doctor, theme-stress-test) | Local tooling (shell/python3 scripts) | — | Same tier as today; only the file lists inside these scripts move |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| wleave | 0.7.1-1 (AUR) | GTK4/libadwaita layer-shell logout menu, wlogout drop-in replacement | `[VERIFIED: AUR PKGBUILD (aur.archlinux.org/cgit, h=wleave)]` — pkgver=0.7.1, pkgrel=1, built via `git+https://github.com/AMNatty/wleave#tag=0.7.1` (release tag, not `main`/`-git`). GTK4 structurally eliminates the WLOG-01 whole-stylesheet-discard failure class (GTK4's `CssProvider` skips only the offending rule, confirmed by this repo's own live GTK3-vs-GTK4 test per ROADMAP.md). Actively maintained (0.5.0→0.8.0-dev in the upstream repo across 2026), unlike wlogout. |
| gtk4-layer-shell | 1.3.0-1 (already installed) | Wayland layer-shell protocol bindings wleave links against | `[VERIFIED: pacman -Qi gtk4-layer-shell on this machine]` — already present, no new install needed |
| libadwaita | 1:1.9.2-1 (already installed) | GTK4 styling/adaptive-widget layer wleave's `ApplicationWindow` subclasses | `[VERIFIED: pacman -Qi libadwaita]` — matches PKGBUILD's `depends=('librsvg' 'libadwaita' 'gtk4-layer-shell')` |
| librsvg | 2:2.62.3-1 (already installed) | SVG icon colorization (wleave's optional `icon` field) | `[VERIFIED: pacman -Qi librsvg]` — not used by this repo's design (glyph-as-text, no icon images), but satisfies the PKGBUILD dependency regardless |

### Build tooling (AUR build-from-source, verified present)
| Tool | Purpose | Status |
|------|---------|--------|
| cargo | Rust toolchain, compiles wleave | `[VERIFIED: command -v cargo → /usr/bin/cargo]` |
| git | AUR source fetch (`source=("wleave::git+...#tag=...")`) | `[VERIFIED: command -v git]` |
| scdoc | Man-page generation (`wleave.1.scd`/`wleave.5.scd` → gzip) | `[VERIFIED: command -v scdoc]` |
| paru | AUR helper already in use elsewhere in this repo's install flow | `[VERIFIED: command -v paru]` |

No missing build dependency — the AUR build has zero blockers on this machine.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| wleave (this phase's locked choice, D-13) | `wleave-git` | Explicitly refused by repo precedent (eww-git refusal, same reasoning: lower adoption, non-reproducible builds pinned to a moving HEAD) |
| wleave | Other GTK4 logout menus (e.g. `nwg-bar`, `swayosd`-adjacent tools) | Out of scope — CONTEXT.md already locked wleave specifically; not re-litigated here |

**Installation:**
```bash
paru -S wleave   # AUR, release tag 0.7.1-1, NOT wleave-git
```

**Version verification:** `[VERIFIED]` AUR package page + PKGBUILD confirm `pkgver=0.7.1 pkgrel=1`, matching CONTEXT.md D-13's pin exactly. Upstream `main` branch has since advanced to an unreleased `0.8.0` (Cargo.toml on `main`) with a `button-defaults` merge feature not present at 0.7.1 — do not follow `main`-branch documentation/examples uncritically; this research cross-checked every claim against the `0.7.1` git tag specifically.

## Package Legitimacy Audit

> This phase's only new external package (`wleave`) is an **AUR** package, not npm/PyPI/crates — the automated `gsd-tools query package-legitimacy check` seam only supports `--ecosystem npm|pypi|crates` and returned `Error: Usage: gsd-tools package-legitimacy check --ecosystem <npm|pypi|crates> ...` when attempted `[VERIFIED: seam invocation this session]`. Verification instead followed this repo's own established AUR precedent (Phase 4/6/8: human package-legitimacy checkpoint at execution time, backed by manual PKGBUILD/source inspection here).

| Package | Registry | Build source | Maintainer | Postinstall scripts | Verdict | Disposition |
|---------|----------|---------------|-----------|----------------------|---------|-------------|
| wleave | AUR (`aur.archlinux.org/packages/wleave`) | `git+https://github.com/AMNatty/wleave#tag=0.7.1` — pinned release tag, not a rolling branch | Chinmay Dalal (AUR-listed maintainer; upstream author is AMNatty) | None — `package()` only installs the compiled binary, license, completions, icons, and gzip'd man pages via `install -Dm` calls; no `pre_install`/`post_install`/`pre_upgrade` hooks in the PKGBUILD | OK (manual review) | Approved — human legitimacy gate still required at execution per D-13/repo precedent, but no red flags found |
| wleave-git | AUR | N/A | N/A | N/A | N/A | Explicitly excluded per D-13 (repo's own eww-git precedent) — do not install |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none — `wleave`'s PKGBUILD is a clean build-from-pinned-tag, standard Rust/cargo build, no arbitrary network calls or out-of-tree filesystem writes in any build phase.

*The AUR ecosystem is outside this seam's automated coverage; the human package-legitimacy checkpoint (D-13) remains the load-bearing control, same as every prior AUR install in this project.*

## Architecture Patterns

### System Architecture Diagram

```
 Entry points                    Dispatch                  wleave process              Compositor / OS
 ────────────                    ────────                  ──────────────              ───────────────
 Super+Shift+Q (keybinds.conf) ┐
 waybar custom/power on-click  ├──► wleave.sh (D-21,      ┌─► wleave binary launches
   (modules.jsonc,             │    D-23 spawn-guard)     │   one GTK4/libadwaita
    config-floating.jsonc)     │         │                │   ApplicationWindow
 elephant menus/main.toml      ┘         │                │        │
   "Power" entry                         ▼                │        ▼
                                   bare `wleave` exec ─────┘   loads ~/.config/wleave/
                                   (no protocol/geometry        {layout.json, style.css}
                                    flags needed — D-01..D-08        │
                                    live in the config files)        ▼
                                                              window.init_layer_shell()
                                                              namespace="wleave", Layer::Overlay,
                                                              anchored all 4 edges,
                                                              exclusive_zone=-1,
                                                              KeyboardMode::Exclusive
                                                                      │
                                                     ┌────────────────┼─────────────────┐
                                                     ▼                ▼                 ▼
                                            Hyprland layerrule   GestureClick       EventControllerKey
                                            (blur, ignore_alpha, (click-away,       (Esc → close;
                                             animation) matched  ALWAYS active,     per-button keybind
                                             on namespace         D-18)             → same action path)
                                             "wleave"
                                                     │
                                                     ▼
                                     six Button widgets, name=label (#lock,#logout,...),
                                     positioned by custom MenuLayout (grid), each showing
                                     a Nerd Font glyph via Overlay-positioned Label
                                     (xalign/yalign from JSON "width"/"height", D-09)
                                                     │ click / keybind
                                                     ▼
                                     on_option(): window.set_visible(false) IMMEDIATELY,
                                     then (after delay_command_ms, default 100ms)
                                     runs `sh -c "<action string>"`, then window.close()
                                                     │
                                                     ▼
                                          systemctl / hyprshutdown / cliphist / uwsm
                                          (unchanged action strings, D-17)


 Theme pipeline (unchanged shape, renamed target):
 matugen [templates.wleave] ──► ~/.local/state/theme/wleave.css ──► @import'd by
 (was [templates.wlogout])       (was wlogout.css)                  ~/.config/wleave/style.css
                                                                     (read at wleave PROCESS START —
                                                                      spawn-per-open means "reopen after
                                                                      switch" = reload, D-15; nothing in
                                                                      reload.sh needs a wleave-specific
                                                                      action, confirmed by grep)
```

### Recommended Project Structure
```
wleave/.config/wleave/
├── layout.json     # renamed from wlogout/layout — modern wrapped schema (not legacy NDJSON)
└── style.css       # renamed from wlogout/style.css — @import's ~/.local/state/theme/wleave.css
```
(Package name `wleave/`, replacing `wlogout/` 1:1 in stow.sh PACKAGES — same alphabetical slot.)

### Pattern 1: Config schema — reuse existing action data, upgrade to wrapped JSON
**What:** wleave 0.7.1 accepts two config shapes, both confirmed at the pinned tag `[VERIFIED: github.com/AMNatty/wleave@0.7.1 src/config.rs]`:
1. **"New" wrapped format** — a single top-level JSON object: `{"buttons": [...], "buttons-per-row": "6", "margin": "5%", ...}`. Parsed first; if this fails, falls back to:
2. **"Legacy" format** — a bare sequence of JSON objects (NDJSON or even comma-less concatenation), each deserialized as one button. This is **exactly** the shape of the existing `wlogout/.config/wlogout/layout` file.

**When to use:** Use the wrapped format for this phase — it is the only way to declare `buttons-per-row`, `margin`, `close-on-lost-focus`, `protocol`, etc. *in the config file* rather than as CLI flags on every invocation. The legacy format is mentioned only because it explains why the current file would technically still load as-is (useful fallback knowledge, not the recommended path).

**Example (verified schema, byte-identical action strings from the current layout, `"height": 0.5` added per the label-centering finding below):**
```json
// Source: github.com/AMNatty/wleave@0.7.1 man/wleave.json.5.scd + src/button.rs WButton struct
{
  "buttons-per-row": "6",
  "close-on-lost-focus": false,
  "show-keybinds": false,
  "buttons": [
    { "label": "lock",      "action": "uwsm app -- hyprlock",                                          "text": "<glyph>", "keybind": "l", "height": 0.5 },
    { "label": "logout",    "action": "cliphist wipe; uwsm stop",                                       "text": "<glyph>", "keybind": "e", "height": 0.5 },
    { "label": "suspend",   "action": "systemctl suspend",                                               "text": "<glyph>", "keybind": "u", "height": 0.5 },
    { "label": "hibernate", "action": "systemctl hibernate",                                             "text": "<glyph>", "keybind": "h", "height": 0.5 },
    { "label": "shutdown",  "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'",     "text": "<glyph>", "keybind": "s", "height": 0.5 },
    { "label": "reboot",    "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'",       "text": "<glyph>", "keybind": "r", "height": 0.5 }
  ]
}
```
`<glyph>` placeholders are D-09's cmap-verified new Nerd Font glyphs (out of scope for research — verify per-glyph with the same `fc-query`/cmap-inspection method used in Phase 6/8, never a cheat-sheet codepoint).

### Pattern 2: CSS surface — transparent window + scrim on the next node down (D-01/D-07)
**What:** `[VERIFIED: github.com/AMNatty/wleave@0.7.1 src/app/mod.rs]` — wleave's widget tree under the top-level window is: `WleaveWindow` (GTK4 `ApplicationWindow`/`AdwApplicationWindow` subclass) → `GtkCenterBox` (content) → `GtkBox` (the buttons container, laid out by wleave's custom `MenuLayout` manager) → one `GtkButton` per action (name=`label`, i.e. CSS `#lock`, `#logout`, etc. — same IDs wlogout already used) → `GtkOverlay` → glyph `GtkLabel.action-name`.

Both `GtkCenterBox` and the buttons container are plain `GtkBox` widgets, and **GTK4's `GtkCenterBox` and `GtkBox` share the identical CSS node name `box`** `[CITED: docs.gtk.org GtkCenterBox / GTK4 CSS node reference]` — a bare `box { ... }` selector would match **both** and is not safe to use for the scrim. Since the `CenterBox` is `window`'s *direct* child while the buttons container is nested one level deeper (inside the `CenterBox`), the CSS child-combinator scopes correctly:

```css
/* Source: github.com/AMNatty/wleave@0.7.1 src/app/mod.rs (widget tree) +
   docs.gtk.org GtkCenterBox (CSS node name "box") */
window {
    background-color: transparent;   /* D-01: the AGS/10-06 technique */
}
window > box {
    background-color: rgba(0, 0, 0, 0.4);   /* D-07 scrim; direct-child selector
                                                 scopes to ONLY the outer CenterBox,
                                                 not the nested buttons box */
}
```
**Must be confirmed live at the D-14 render gate** — this selector strategy is derived from source-code widget-tree analysis, not from an actual on-screen render, and this phase's entire premise is that CSS-logic-without-a-render-check is exactly how WLOG-01 shipped broken.

**When to use:** Any time D-01's "transparent window + separately-colored scrim" pattern is applied to a wleave-family app (also matches how AGS's 10-06 media popup solved the identical problem for its own window).

### Pattern 3: Per-action hue identity via existing `#id` selectors (D-03/D-04) — no new mechanism needed
**What:** wleave sets each button's GTK widget name to the layout's `"label"` field (`.name(&bttn.label)`), which GTK CSS addresses as `#lock`, `#logout`, `#suspend`, `#hibernate`, `#shutdown`, `#reboot` — **identical to wlogout's existing style.css structure**. The `mix()` derived-hue technique from Phase 8 (08-14) is directly reusable:
```css
/* Source: waybar/.config/waybar/theme.css (Phase 8-14 precedent), reused verbatim */
@define-color vhue-purple mix(@primary, @error, 0.4);
@define-color vhue-teal mix(@secondary, @tertiary, 0.5);
```
**When to use:** For the two capsules beyond the four native M3 hues (primary/secondary/tertiary/error).

### Anti-Patterns to Avoid
- **Porting `wlogout.sh`'s geometry math verbatim:** wleave anchors to all four screen edges and centers its own content via `GtkCenterBox` + percentage/px margins read from the config file — there is no content-box-plus-padding-plus-border pixel arithmetic to derive, and no focused-monitor logical-size query needed in the wrapper script. Writing that logic again would be dead code solving a problem wleave already solves internally.
- **Assuming `button-defaults` (a per-button-field shared-defaults block) is available:** it exists on the upstream `main` branch (heading to 0.8.0) but is **absent** from the pinned 0.7.1 tag's `config.rs`/`button.rs` `[VERIFIED]`. Every button must repeat its own `"height": 0.5` etc. individually in the 0.7.1 config; there is no defaults-merge shortcut.
- **Trusting `--close-on-lost-focus` to provide D-18's click-away dismissal:** it does not need to — click-away-to-close is **already unconditional** in 0.7.1 (a `GestureClick` on the primary button, bubble phase, added to the window regardless of config) `[VERIFIED]`. `close-on-lost-focus` is a *separate, additional* behavior (dismiss when the window loses input focus, e.g. alt-tab) — leave it `false` per D-18/D-20's intent (no extra ways to accidentally dismiss beyond Esc + click-away).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Layer-shell window centering/geometry | A ported `wlogout.sh`-style pixel-math geometry derivation | wleave's own `margin`/`buttons-per-row`/`button-aspect-ratio` config fields | The GTK4 rewrite already solves this (`GtkCenterBox` + anchor-all-edges); re-deriving it is solving an already-solved problem and risks reintroducing Phase 6's exact clipping bug in a new codebase |
| Click-away-to-dismiss | A custom `GestureClick`/focus-loss shell wrapper | wleave's built-in, unconditional click-away behavior | Already ships natively at 0.7.1; no CLI flag or config needed |
| Six distinct per-action hues from a ~4-hue Material You scheme | Hardcoded literal hex fallback colors for the 2 "missing" hues | GTK CSS `mix()` in `@define-color` (Phase 8-14 precedent, reused verbatim) | Already proven to survive theme-doctor's non-empty-provider gate in this exact repo; a literal-hex fallback would violate the zero-literal-hex convention and desync from live theme switches |

**Key insight:** Every mechanism this phase needs (self-sizing window, click-away dismissal, per-button CSS IDs, `mix()`-derived hues) already exists either natively in wleave 0.7.1 or as a proven pattern elsewhere in this exact repo. The only genuinely new engineering is the CSS node-collision-aware scrim selector (Pattern 2) and the two flagged landmines below — everything else is direct reuse.

## Common Pitfalls

### Pitfall 1: Label sits low in the capsule (Phase 6's "no vertical centering" finding, new mechanism)
**What goes wrong:** Without an icon set, wleave positions the text label via `Overlay` at `xalign = width.unwrap_or(0.5)`, `yalign = height.unwrap_or(0.9)` `[VERIFIED: src/app/mod.rs]` — the **default is 0.9, i.e. near the bottom of the button**, not centered.
**Why it happens:** wleave's icon+label layout assumes a "new" icon-based system (where the label sits below a picture, vertically stacked, and 0.9 makes sense as "just under the icon") — but this repo's design uses text-only Nerd Font glyphs (no `icon` field), which routes through the icon-less `Overlay`-anchored branch instead, inheriting the icon-oriented default.
**How to avoid:** Set `"height": 0.5` explicitly on every button in layout.json (confirmed valid range 0.0–1.0 per the man page). Leave `"width"` unset (default 0.5 already centers horizontally).
**Warning signs:** Glyph visually touching/crowding the bottom border of the capsule at the D-14 render check — same visual symptom as Phase 6's original bug, different root cause and different fix mechanism (JSON field, not CSS margin).

### Pitfall 2: `box { }` CSS selector matches more than intended
**What goes wrong:** Styling the outer content wrapper (for the D-07 scrim) with a bare `box { background-color: ... }` selector also styles the inner buttons-row `GtkBox`, since both share the CSS node name `box` in GTK4.
**Why it happens:** `GtkCenterBox` does not get its own distinct CSS node name in GTK4 — it renders identically to a plain `GtkBox` for selector-matching purposes `[CITED: docs.gtk.org]`.
**How to avoid:** Use the direct-child combinator `window > box` (Pattern 2) to scope the rule to only the outer `CenterBox`, since the buttons container is nested one level deeper (not a direct child of `window`).
**Warning signs:** The whole capsule row unexpectedly tinted/scrimmed the same color as the backdrop, or capsules losing their intended per-hue background at the render check.

### Pitfall 3 (LANDMINE — flagged per objective instructions): D-22's multi-monitor behavior is not achievable natively
**What goes wrong:** D-22 requires "scrim dims ALL monitors, capsules render on the focused monitor." wleave creates exactly **one** `ApplicationWindow` per `activate` (`app.connect_activate` fires once; `create_app` is called once) and never calls a per-output targeting API (no `gtk_layer_set_monitor` equivalent anywhere in `src/app/mod.rs`/`window.rs`) `[VERIFIED: full source read, both 0.7.1 tag and main branch]`. With no monitor specified, the Wayland layer-shell protocol lets the **compositor** choose a single output (in practice, Hyprland's currently-focused output) — wleave will appear, scrim and capsules together, on **one monitor only**. Other monitors are left completely untouched (no dimming at all), not "dimmed but capsule-free" as D-22 describes.
**Why it happens:** wleave is architecturally single-window/single-output by design (unlike e.g. waybar, which is explicitly multi-instance-per-output). There is no CLI flag or config key to change this — the CLI/config surface was fully enumerated from source (`cli_opt.rs`, man pages) and contains no monitor-selection option.
**Closest achievable alternative:** Accept single-output behavior — wleave opens on the compositor-chosen (typically focused) monitor only; other monitors show neither scrim nor capsules. A workaround of launching one `wleave` instance per connected output would put a **full interactive capsule row on every monitor** (not a scrim-only backdrop on the non-focused ones), which is a worse UX mismatch against D-22's intent than simply not dimming the other monitors — not recommended.
**Recommendation for planning:** Treat D-22 as **infeasible as locked** and route it through the same discretion the CONTEXT.md already grants D-10 ("if infeasible, degrade and note the deviation") — plan to ship single-monitor-only behavior and record the deviation explicitly rather than attempting a multi-instance workaround.

### Pitfall 4 (LANDMINE): D-10's reverse-stagger exit animation collides with wleave's synchronous hide-then-delay sequencing
**What goes wrong:** On any button click, wleave's `on_option()` calls `window.set_visible(false)` **immediately** (before any delay), then — only after the window is already invisible — waits `delay_command_ms` (default 100ms, config-overridable) before running the shell command and calling `window.close()` `[VERIFIED: src/app/mod.rs on_option()]`. There is no "closing" state during which the window is both visible and animatable; the moment a button is clicked, the surface disappears with no transition, and the 100ms delay that follows happens with nothing on screen.
**Why it happens:** The delay exists to let the compositor tear down the layer-shell surface cleanly before the command runs (e.g. so a `systemctl poweroff` doesn't race a still-mapped surface) — it is not designed as an animation window, and GTK doesn't animate `visible`/window-hide transitions via CSS in the first place.
**Closest achievable alternative:** A **compositor-level** exit affordance via Hyprland's `layerrule = animation <style>, match:namespace wleave` (the phase description already confirms `animation` is a valid Hyprland 0.55.4 layerrule keyword) can still produce a slide/fade on the Wayland surface's unmap, independent of wleave's own internal timing — this is a plausible way to get *some* visual exit affordance without touching wleave's command-firing sequence, but whether Hyprland's layer-animation actually triggers on a client-initiated `wl_surface` unmap (versus only on compositor-initiated close) needs live confirmation, not just doc-reading.
**Per-capsule reverse-stagger** (each button animating out individually before the whole window disappears) is very unlikely to be achievable at all, since the whole window vanishes in one synchronous call with no per-widget teardown phase.
**Recommendation for planning:** This is exactly the scenario CONTEXT.md's Claude's Discretion clause already anticipates ("if reverse-stagger exit is infeasible without delaying actions, degrade to a fast fade and note the deviation") — plan for a fast whole-window fade (via Hyprland layerrule animation, confirmed live at D-14) as the default target, not the six-capsule reverse-stagger wave, and treat any successful reverse-stagger as a stretch outcome discovered at the render gate rather than a planned deliverable.

### Pitfall 5: `matugen`'s new template needs container-role keys this repo has never actually exercised
**What goes wrong:** D-03 requires `on_*_container` roles for **all six** actions, but grep across every existing matugen template in this repo shows **zero** current usage of `tertiary_container`, `on_tertiary_container`, `error_container`, or `on_error_container` — only `primary_container`/`secondary_container` (and their `on_*` pairs) are proven to resolve, in the current `wlogout-colors.css` template `[VERIFIED: grep across matugen/.config/matugen/templates/*.css]`.
**Why it happens:** Material Design 3's full role set does define container variants for all four core roles (primary/secondary/tertiary/error), and matugen (built on Google's `material-color-utilities`) is documented to expose the complete M3 role set — but this specific repo's templates have simply never consumed the tertiary/error container keys before now, so their resolution has never been empirically exercised end-to-end in this pipeline.
**How to avoid:** `[ASSUMED, LOW-MEDIUM confidence]` — before committing to the new template, do a cheap dry-run: add the four new `@define-color` lines to a scratch copy of the template, run `theme-engine`'s existing `generate.sh`, and grep the rendered output file for any literal unresolved `{{...}}` or an empty hex value (mirrors this repo's own established verification idiom, e.g. theme-doctor's non-empty-provider check). Treat this as a required Wave-0-style verification step, not an assumption to carry into execution unchecked.
**Warning signs:** A rendered `wleave.css` containing a literal `{{colors.tertiary_container...}}` string, or a `#` followed by nothing / an obviously-wrong hex value for the two "missing" roles.

### Pitfall 6: Copying `main`-branch wleave documentation/examples instead of the pinned 0.7.1 tag
**What goes wrong:** The upstream `README.md` (served from `main`) and any general web search results describe the **current** wleave, which is already at an unreleased `0.8.0` with a `button-defaults` field and per-button `icon` shell-variable expansion that do not exist at 0.7.1.
**Why it happens:** GitHub's default branch view and most search-indexed content reflects `main`, not historical tags.
**How to avoid:** Every claim in this research was cross-checked against `raw.githubusercontent.com/AMNatty/wleave/0.7.1/...` specifically, not `main`. Any future re-verification (e.g. if the AUR package version bumps) must re-pull source at whatever tag is actually pinned, not assume `main`'s docs apply.

## Code Examples

### Full wleave.sh replacement shape (D-21, D-18, D-23 — no geometry math needed)
```bash
#!/usr/bin/env bash
# Source: derived from wleave 0.7.1 architecture findings above — the
# window is self-sizing/self-centering (GtkCenterBox + anchor-all-edges),
# so unlike wlogout.sh there is no CONTENT/PAD/BORDER/BAR_W/MON_W math to
# derive here. Open-only semantics (D-18): no pgrep/pkill toggle.
set -euo pipefail

if ! command -v wleave >/dev/null 2>&1; then
    notify-send "Power menu" "wleave is not installed" -u critical
    exit 1
fi

if ! wleave & then
    notify-send "Power menu" "wleave failed to launch" -u critical
    exit 1
fi
```
(Exact spawn/exit-check idiom should follow this repo's existing `command -v` guard pattern from the capture scripts, per D-23.)

### theme-doctor extension (D-16) — exact one-line move, not an addition
```bash
# Source: theme-engine/.config/theme-engine/theme-doctor (current, lines ~204-217)
# BEFORE:
GTK3_CSS_SHEETS=(
    "$HOME/.config/wlogout/style.css"     # <-- remove this line
    "$HOME/.config/gtk-3.0/gtk.css"
    "$HOME/.config/swaync/style.css"
)
GTK4_CSS_SHEETS=(
    "$HOME/.config/gtk-4.0/gtk.css"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/walker/themes/rice/style.css"
)
# AFTER:
GTK3_CSS_SHEETS=(
    "$HOME/.config/gtk-3.0/gtk.css"
    "$HOME/.config/swaync/style.css"
)
GTK4_CSS_SHEETS=(
    "$HOME/.config/gtk-4.0/gtk.css"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/walker/themes/rice/style.css"
    "$HOME/.config/wleave/style.css"      # <-- add this line
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| wlogout (GTK3, C, largely unmaintained) | wleave (Rust, GTK4/libadwaita, active 0.5.0→0.8.0-dev through 2026) | wleave 0.5.0 (GTK4 rewrite, "Feb 5" per release notes) through 0.7.1 (current AUR pin) | Structurally eliminates the GTK3 whole-stylesheet-discard failure class; adds native click-away dismissal, service mode, conditional multi-command actions (unused here), JSON schema |
| wlogout hand-rolled window geometry (`wlogout.sh`'s content-box math) | wleave native `GtkCenterBox` + anchor-all-edges + percentage margins | wleave 0.5.0 (layer-shell became default) | The entire `CONTENT/PAD/BORDER` derivation class of bug (Phase 6's hardest-won finding) does not exist in the new engine — nothing to port |

**Deprecated/outdated:** wlogout itself — this phase's entire purpose is retiring it; do not reference wlogout docs/behavior as authoritative for anything except "what action strings must carry over byte-identically" (D-17).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | matugen's rendered output exposes `tertiary_container`/`on_tertiary_container`/`error_container`/`on_error_container` color roles (standard M3 role set), even though no existing template in this repo currently consumes them | Pitfall 5, Pattern 3 | If any of these keys don't resolve as expected, the new `wleave-colors.css` template render would either error (matugen typically fails hard on unknown keys) or silently emit an unresolved/empty value, breaking D-03/D-04's per-capsule color pairing for tertiary/error-derived hues — caught by the recommended dry-run verification before committing the template |
| A2 | Hyprland's `layerrule = animation` fires on wleave's client-initiated window-hide (not only on a compositor-initiated close) | Pitfall 4 | If it does not fire on client-hide, D-10's exit affordance may render as an abrupt cut with no animation at all (the honest fallback if even the fast-fade degradation isn't achievable) — must be confirmed live at the D-14 render gate, not assumed |

**If this table is empty:** N/A — see above; both entries are genuinely open and should be confirmed empirically at plan/execution time, not treated as settled research findings.

## Open Questions

1. **Does the two-derived-hue `mix()` technique need adjustment for a translucent (not opaque) fill?**
   - What we know: Phase 8-14's `mix(@primary, @error, 0.4)` precedent produces an opaque derived color; D-03 requires the *capsule background* to be that color at translucent alpha (tinted frost), not opaque.
   - What's unclear: Whether `mix()`'s output composed with a separate `alpha()`/rgba wrapper behaves identically to the four native (non-mixed) hues when both are put through the same alpha treatment — no reason to expect a problem, but not yet rendered.
   - Recommendation: Verify visually at D-14 alongside the label-centering and scrim-selector checks — this is exactly the kind of thing the render gate exists to catch, not something to resolve by more source-reading.

2. **Exact glyph set for D-09**
   - What we know: Six new (not Phase-6-carried) Nerd Font glyphs are needed, cmap-verified against the installed font, real UTF-8 codepoints (never PUA-via-edit-tool).
   - What's unclear: Which specific six codepoints — explicitly Claude's Discretion per CONTEXT.md, not a research question.
   - Recommendation: Apply the same `fc-query`/cmap-inspection method already used in Phase 6/8 at plan/execution time.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| wleave | Core engine (WLOG-01) | ✗ (not yet installed, expected per CONTEXT.md) | — (target: 0.7.1-1) | None needed — AUR build confirmed unblocked (all deps + build tools present) |
| gtk4-layer-shell | wleave runtime dependency | ✓ | 1.3.0-1 | — |
| libadwaita | wleave runtime dependency | ✓ | 1:1.9.2-1 | — |
| librsvg | wleave runtime dependency (unused icon path) | ✓ | 2:2.62.3-1 | — |
| cargo, git, scdoc | AUR build (makedepends) | ✓ | present | — |
| paru | AUR helper | ✓ | present | — |

**Missing dependencies with no fallback:** none — `wleave` itself is the only missing piece, and its own build chain is fully satisfied.
**Missing dependencies with fallback:** none applicable.

## Security Domain

> `security_enforcement` is enabled (`security_asvs_level: 1`) per `.planning/config.json`; this phase's surface is a local, non-network-facing desktop UI tool with no untrusted-input-handling change, so most ASVS categories are not applicable — documented explicitly rather than silently omitted.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | wleave has no auth surface; lock/suspend/shutdown delegate to systemd-logind/hyprlock, unchanged from wlogout |
| V3 Session Management | No | No session state introduced |
| V4 Access Control | No | Single-user desktop config, no privilege boundary crossed by this migration |
| V5 Input Validation | Marginal | The only "input" is a repo-owned, static JSON layout file and a static CSS file — not user-supplied at runtime. The six action strings are fixed, developer-authored shell commands (`sh -c`), identical trust level to wlogout's existing equivalent; no new untrusted input path is introduced |
| V6 Cryptography | No | Not applicable |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Local config-file tampering (another local process/user rewrites `~/.config/wleave/layout.json` to redirect an action string) | Tampering | Standard filesystem permissions on `$HOME` (unchanged threat model from wlogout — this repo is explicitly a single-user personal desktop, out of scope to harden further per PROJECT.md's stated boundaries) |
| Command injection via action string | Tampering/Elevation | Not applicable here — action strings are static, developer-authored, version-controlled, never built from runtime/user input |

## Sources

### Primary (HIGH confidence)
- `github.com/AMNatty/wleave` @ tag `0.7.1` — full source read: `src/main.rs`, `src/config.rs`, `src/app/mod.rs`, `src/app/window.rs`, `src/button.rs`, `src/cli_opt.rs`, `src/layout.rs`, `src/units.rs`, `src/exec.rs`, `Cargo.toml`, `style.css`, `layout.json`, `man/wleave.1.scd`, `man/wleave.json.5.scd` — namespace string, config schema, CLI flags, dismissal behavior, widget tree, action-execution sequencing
- `aur.archlinux.org` PKGBUILD for `wleave` (via cgit) — pkgver/pkgrel/build source/dependencies/absence of install scripts
- This machine, direct verification: `pacman -Qi gtk4-layer-shell/libadwaita/librsvg`, `command -v cargo/git/scdoc/paru`, `pacman -Qi wleave` (confirms not yet installed)
- This repo, direct file reads: `wlogout/.config/wlogout/{layout,style.css}`, `hypr/.config/hypr/scripts/wlogout.sh`, `hypr/.config/hypr/config/windowrules.conf` (lines 184-230), `keybinds.conf` (line 26), `matugen/.config/matugen/config.toml` + `templates/wlogout-colors.css`, `theme-engine/.config/theme-engine/{theme-doctor,contract.json,theme-stress-test,lib/reload.sh}`, `waybar/.config/waybar/{modules.jsonc,config-floating.jsonc,theme.css}`, `elephant/.config/elephant/menus/main.toml`, `install.sh` (lines 195-283), `stow.sh` (lines 1-40), `autostart.conf` (line 74) — full touchpoint inventory + `mix()` precedent
- Full-repo grep for `wlogout` (excluding `.planning/`) — exhaustive touchpoint list (see Runtime State Inventory below)

### Secondary (MEDIUM confidence)
- `docs.gtk.org` GtkCenterBox class reference (via WebSearch) — CSS node name "box" shared with GtkBox
- WebSearch on GTK4 CSS `@keyframes`/transition support — confirms GTK CSS supports `@keyframes`/`animation-*` properties (used for the entrance-stagger recommendation)

### Tertiary (LOW confidence)
- General claim that matugen exposes the full Material Design 3 role set including `tertiary_container`/`error_container` — not empirically proven in this repo (see Assumption A1); flagged for a cheap dry-run verification rather than trusted outright

## Runtime State Inventory

> Included because this is a rename/atomic-swap migration phase (D-11, D-12, D-21).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stow package | `wlogout/.config/wlogout/{layout,style.css}` | Delete package; create `wleave/.config/wleave/{layout.json,style.css}` |
| install.sh | `wlogout` currently lives in **AUR_PKGS** (line 233, inside the block starting `AUR_PKGS=(` at line 212 — **correction to CONTEXT.md's canonical_refs, which states "PACMAN_PKGS (line ~233)"; verified directly against the file, it is AUR_PKGS**, under the comment `# Logout menu (AUR-only; not in official repos)`) | Replace the `wlogout` line with `wleave` in AUR_PKGS (same section, same "AUR-only" comment still applies — wleave is also AUR-only) |
| stow.sh | `wlogout` in `PACKAGES` array (line 38, alphabetically between `waybar` and `yazi`) | Rename in place to `wleave` (alphabetical position unchanged: w-l-e-a-v-e still sorts between `waybar`/`walker` and `yazi`) |
| matugen config.toml | `[templates.wlogout]` block, lines 46-48 (`input_path`/`output_path` both reference `wlogout`) | Rename block to `[templates.wleave]`, paths to `wleave-colors.css` input / `wleave.css` output |
| matugen template | `matugen/.config/matugen/templates/wlogout-colors.css` (12 `@define-color` lines; missing `tertiary_container`/`error_container` roles per Pitfall 5) | Rename file to `wleave-colors.css`; add the two missing container-role pairs (verify via dry-run per Pitfall 5) |
| theme-engine contract.json | `{ "name": "wlogout.css", "format": "gtk-css" }` (line 7) | Rename to `wleave.css` (D-12: contract stays same file count) |
| theme-engine theme-doctor | `GTK3_CSS_SHEETS` array entry `$HOME/.config/wlogout/style.css` (line 205) | Remove from `GTK3_CSS_SHEETS`; add `$HOME/.config/wleave/style.css` to `GTK4_CSS_SHEETS` (D-16) |
| theme-engine theme-stress-test | `REPRESENTATIVE_FILES` array includes `wlogout.css` (line 291) | Rename to `wleave.css` in place |
| Hyprland windowrules.conf | `layerrule = blur on, match:namespace logout_dialog` (line 191); `layerrule = ignore_alpha 0.3, match:namespace logout_dialog` (line 230, plus its explanatory comment block lines 224-229) | Replace both `logout_dialog` matches with `wleave` (D-22/blur/D-01 discretion applies to exact threshold — re-tune since D-01 changes to a transparent-window+separate-scrim technique, not the old direct-alpha-on-window approach) |
| Hyprland keybinds.conf | Line 26: `bind = $mainMod SHIFT, Q, exec, ~/.config/hypr/scripts/wlogout.sh # Open power menu` | Repoint script path to `wleave.sh`; the trailing description ("Open power menu") does not literally say "wlogout" and needs no wording change for keybind-doctor (which only checks a description is present, not its content) |
| waybar modules.jsonc | Line 256: `"on-click": "~/.config/hypr/scripts/wlogout.sh"` (`custom/power` module) | Repoint to `wleave.sh` |
| waybar config-floating.jsonc | Line 82: `"on-click": "bash ~/.config/hypr/scripts/wlogout.sh"` (`custom/power` module) | Repoint to `wleave.sh` |
| elephant menus/main.toml | Line 35: `actions = { "open" = "~/.config/hypr/scripts/wlogout.sh" }` (Power entry) | Repoint to `wleave.sh`; recall the 07-05 stow-parity lesson if `wleave/` is a *new* stow package (it is — run/verify stow after adding, not just after editing an existing symlinked file) |
| autostart.conf comment | Line 74: comment referencing "wlogout logout/shutdown/reboot actions" (cliphist session-end wipe explanation) | Update comment wording to say "wleave" — comment-only, no behavior change |
| theme-engine lib/reload.sh | **None found** — grepped directly, zero `wlogout`/`wleave` references exist in this file today | No change required (D-15 confirmed: wleave is spawn-per-open, "reopen after switch" already picks up the freshly-rendered `wleave.css` via its own `@import`, with no runtime reload call needed — matches wlogout's own current behavior, which also required zero reload.sh wiring) |
| Misc repo mentions (non-functional, doc/comment only) | `.claude/CLAUDE.md` (2 mentions, prose), `VERIFICATION.md` line 214 (prose), `.claude/settings.local.json` line 15 (a historical commit-message string in an allowlist, not live config) | No functional change required; optional prose cleanup only, not gating |

**Grep command used for this inventory:** `grep -rIn "wlogout" --exclude-dir=.planning --exclude-dir=.git .` — 20 matching files, all enumerated above (D-11's "grep must come back empty after the swap" criterion is directly testable against this same command).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — package existence, version, dependencies, and build-tool availability all directly verified (PKGBUILD + `pacman -Qi` + `command -v`)
- Architecture (namespace/config/CSS/dismissal): HIGH — read directly from source at the exact pinned tag, not inferred from docs or `main`-branch drift
- Multi-monitor / exit-animation landmines: MEDIUM (the "what wleave does" half is HIGH/source-verified; the "what Hyprland will do about it" half is LOW/needs live confirmation)
- Pitfalls 1-2 (label alignment, CSS selector collision): HIGH — directly derived from source code logic, though visual confirmation is still required at D-14 per this phase's own core lesson
- Pitfall 5 (matugen container-role keys): LOW-MEDIUM — plausible per M3 spec / matugen's documented behavior, but not empirically proven in this repo; flagged with an explicit recommended verification step

**Research date:** 2026-07-25
**Valid until:** ~30 days (wleave is actively developed; re-verify against whatever tag the AUR package pins if this phase is replanned significantly later — do not trust `main`-branch docs, as demonstrated by the 0.7.1-vs-0.8.0-dev drift found this session)
