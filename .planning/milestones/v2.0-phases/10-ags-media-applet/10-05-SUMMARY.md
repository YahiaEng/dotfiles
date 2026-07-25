---
phase: 10-ags-media-applet
plan: 05
subsystem: ui
tags: [ags, astal, gtk4, gjs, sass, matugen, theming, hot-reload, material-you]

# Dependency graph
requires:
  - phase: 10-02
    provides: "AGS scaffold — Astal.Window name='media', instance 'media', toggle-media request; -i media request form; sass-on-PATH launch requirement"
  - phase: 10-04
    provides: "garuda-restyled MediaWindow.tsx + style.scss using ONLY temporary neutral rgba placeholders (zero hex baseline already established)"
provides:
  - "matugen/.config/matugen/templates/ags-colors.scss — SCSS $var palette template mirroring eww-colors.scss"
  - "[templates.ags] matugen config.toml entry rendering ~/.local/state/theme/ags.scss (NO post_hook — see key-decisions)"
  - "style.scss @imports the rendered palette; zero `#` hex literals"
  - "app.tsx reload-css requestHandler + monitorFile watcher — runtime sass recompile + app.apply_css(css, true) hot-reload"
  - "theme-engine/lib/reload.sh: guarded `ags request -i media reload-css` block in theme_engine_reload() (the actual reload trigger, since no post_hook is used)"
  - "Ground-truthed AGS 3.1.2 apply_css/exec/monitorFile API signatures against /usr/share/ags/js/lib/{gtk4/app,process,file}.ts"
affects: [10-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "matugen template -> state-dir SCSS var file -> @import in the consumer's own style.scss — same pattern as eww/waybar/swaync, but AGS needed a corrected @import depth (see key-decisions) and a runtime sass recompile for hot-reload (GTK4 CssProvider only understands plain CSS, not SCSS)."
    - "Single reload-fan-out owner (D-04, theme-engine/lib/reload.sh) — no per-template post_hook in matugen config.toml. New app integrations add a guarded block to theme_engine_reload() instead, following the existing eww/walker/swayosd pattern (liveness-checked, `|| true`, headless-guarded)."

key-files:
  created:
    - matugen/.config/matugen/templates/ags-colors.scss
  modified:
    - matugen/.config/matugen/config.toml
    - ags/.config/ags/style.scss
    - ags/.config/ags/app.tsx
    - theme-engine/.config/theme-engine/lib/reload.sh
    - .gitignore

key-decisions:
  - "NO post_hook in matugen config.toml for the ags template — the file's own header comment and theme-engine/lib/reload.sh's header both explicitly document reload.sh as the SOLE reload-fan-out owner (D-04); a post_hook there would violate that already-locked repo architecture. The `ags request -i media reload-css` call lives in theme_engine_reload() instead, guarded on `ags list | grep -qx media` (liveness-checked exactly like the existing eww/pgrep-gated block)."
  - "style.scss's @import path is 4 levels (\"../../../../.local/state/theme/ags.scss\"), NOT eww's 2 — ground-truthed empirically: AGS's Go bundler resolves --directory/CWD through symlink-collapsing real-path resolution before compiling scss (the sass compile error surfaced the REAL repo path even when --directory pointed at the ~/.config/ags stow symlink), unlike eww's daemon which preserves the symlink. Correct against this repo's actual clone depth (~/dotfiles, 1 level below $HOME) — a known AGS-specific fragility if this repo is ever cloned elsewhere (every other app's theme @import in this engine is symlink-depth-stable; this one alone is not)."
  - "reload-css's runtime `sass` subprocess must be fed the REALPATH-resolved style.scss path, not the stowed symlink path — plain `sass` does NOT collapse symlinks the way AGS's own bundler does, so passing the symlink path made the SAME 4-level @import silently fail every time (caught live in Task 3, not Task 2 — see Deviations)."
  - "Elevation box-shadow (`.media-thumb`) intentionally kept as neutral black `rgba(0,0,0,alpha)` (no `#`, no palette var) — Material elevation shadows represent physical light occlusion, not a themed surface color, matching Material Design's own theme-independent shadow convention. Does not violate the zero-hex-literal rule (no `#`)."

patterns-established:
  - "New matugen-consuming apps in this engine register a `[templates.X]` block with NO post_hook, and add their reload trigger as a guarded, liveness-checked block inside theme_engine_reload() in theme-engine/lib/reload.sh."
  - "For AGS specifically: any runtime path fed to `sass` (or any tool that does its own symlink-preserving resolution) must be realpath-resolved first, since AGS's own bundler already does this collapsing and the style.scss @import depth is written against the real path."

requirements-completed: [MEDIA-03]

coverage:
  - id: D1
    description: "matugen ags-colors.scss template + [templates.ags] config.toml entry render ~/.local/state/theme/ags.scss with named Material You $vars on every theme switch"
    requirement: "MEDIA-03"
    verification:
      - kind: manual_procedural
        ref: "structural greps (template file exists, {{colors.primary.default.hex}} present, [templates.ags] block present, output_path targets state dir) all OK; live theme-apply calls (catppuccin/gruvbox/nord/dracula/materialyou) each re-rendered ags.scss with distinct $primary/$surface hex values, confirmed by `cat`"
        status: pass
    human_judgment: false
  - id: D2
    description: "style.scss @imports the rendered palette and contains ZERO `#` hex literals (comment-stripped)"
    requirement: "MEDIA-03"
    verification:
      - kind: unit
        ref: "grep -vE '^[[:space:]]*//' style.scss | grep -Ec '#[0-9a-fA-F]{3,8}' -> 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "app.tsx handles a reload-css request and watches ~/.local/state/theme/ags.scss with monitorFile, re-applying CSS on change via a runtime sass recompile + app.apply_css(css, true)"
    requirement: "MEDIA-03"
    verification:
      - kind: manual_procedural
        ref: "grep WIRED_OK (reload-css + monitorFile present); live `ags request -i media reload-css` returns ok with no GLib-CRITICAL in the log after the realpath fix"
        status: pass
    human_judgment: false
  - id: D4
    description: "A theme switch (static AND matugen/dynamic) recolors the running applet automatically, with no manual restart — proven end-to-end with two visibly different palettes"
    requirement: "MEDIA-03"
    verification:
      - kind: automated_ui
        ref: "Live pipeline run: theme-apply dracula (static, $primary #ff79c6 pink) -> grim /tmp/ags-final-dracula.png (card/cava/switcher pink, confirmed by Read); theme-apply materialyou (dynamic) -> grim /tmp/ags-final-materialyou.png (same elements now #95cdf7 light blue, confirmed by Read) — same running AGS process throughout (PID unchanged), zero manual restarts or reload-css calls between the two (the reload.sh fan-out + monitorFile did it automatically)"
        status: pass
    human_judgment: false

# Metrics
duration: 30 min
completed: 2026-07-15
status: complete
---

# Phase 10 Plan 05: Matugen Theming + CSS Hot-Reload Summary

**AGS media applet wired into the matugen pipeline — a new `ags-colors.scss` template renders `~/.local/state/theme/ags.scss`, `style.scss` imports it with zero hex literals, and a runtime `sass` recompile + `app.apply_css(css, true)` hot-reloads the running applet on both static and matugen theme switches, with zero manual restarts (MEDIA-03).**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-07-15T18:28Z
- **Tasks:** 3 (all autonomous, no human checkpoint)
- **Files:** 1 created, 5 modified (incl. 2 deviation-driven: reload.sh, .gitignore)

## Accomplishments

- **MEDIA-03 delivered and live-verified end-to-end.** With the applet running, a static theme switch (dracula, `#ff79c6`) and a dynamic matugen theme switch (materialyou wallpaper-driven, `#95cdf7`) both recolored the running applet's cava bars, transport buttons, and switcher pill automatically — same AGS process throughout, zero manual restarts — confirmed by two grim screenshots read back and visually compared.
- `matugen/.config/matugen/templates/ags-colors.scss` created (mirrors `eww-colors.scss`'s SCSS `$name:` var syntax), registered as `[templates.ags]` rendering to `~/.local/state/theme/ags.scss`.
- `style.scss` now imports that palette and carries **zero `#` hex literals** (comment-stripped grep count = 0) — every temporary rgba placeholder from 10-04 replaced with `$primary`/`$surface`/`$on_surface`/`$outline`/etc.
- `app.tsx` extended with a `reload-css` requestHandler case and a `monitorFile` watcher on the rendered palette file — both call a shared `reloadCss()` that recompiles `style.scss` via a runtime `sass` subprocess and applies the result with `app.apply_css(css, true)`.
- Ground-truthed the exact AGS 3.1.2 API surface directly against the installed source (`/usr/share/ags/js/lib/gtk4/app.ts`, `process.ts`, `file.ts`) rather than guessing: `apply_css(style: string, reset = false)` accepts a raw CSS string or an existing-file path (never SCSS), `exec()` is synchronous and throws on failure, `monitorFile()` signature confirmed.

## Task Commits

1. **Task 1: matugen ags-colors.scss template + [templates.ags] entry** — `527c7ad` (feat) — includes the reload.sh wiring deviation (no post_hook)
2. **Task 2: palette @import in style.scss (zero hex) + CSS hot-reload wiring in app.tsx** — `e408d5f` (feat)
3. **Task 3 follow-up fix (found during live verification): realpath-resolve style.scss before feeding sass** — `bfb59f9` (fix)
4. **Task 3: live end-to-end verification** — no separate commit (verification task; two theme switches + screenshots + restoration, all confirmed live)

**Plan metadata:** this commit (docs: complete plan)

## Files Created/Modified

- `matugen/.config/matugen/templates/ags-colors.scss` — SCSS palette template (19 `$name:` vars), mirrors `eww-colors.scss`
- `matugen/.config/matugen/config.toml` — `[templates.ags]` block after `[templates.eww]`, output `~/.local/state/theme/ags.scss`, **no post_hook**
- `ags/.config/ags/style.scss` — `@import "../../../../.local/state/theme/ags.scss";` (4 levels — see key-decisions) + every 10-04 rgba placeholder replaced with a palette var; zero hex literals
- `ags/.config/ags/app.tsx` — `reload-css` requestHandler case + `monitorFile` watcher, both calling `reloadCss()` (realpath -> sass recompile -> `app.apply_css(css, true)`)
- `theme-engine/.config/theme-engine/lib/reload.sh` — new guarded block in `theme_engine_reload()`: `ags list | grep -qx media && ags request -i media reload-css`
- `.gitignore` — ignore `ags/.config/ags/@girs/` (generated `ags types` output, produced while ground-truthing the API)

## Decisions Made

See key-decisions frontmatter. The two load-bearing findings for any future AGS work in this repo:

1. **No post_hook for AGS in matugen config.toml.** This repo's matugen config.toml explicitly states reload.sh is the sole reload-fan-out owner (D-04) — the plan text's `post_hook = "ags request reload-css ..."` instruction predates that lock and would have violated it. Followed the file's own documented convention instead.
2. **AGS's @import path depth is asymmetric between compile-time and reload-time UNLESS you realpath-resolve first.** AGS's own Go bundler collapses the `~/.config/ags` stow symlink to the real repo path before compiling scss (confirmed by the compile error itself surfacing the real path even when invoked against the symlink). This makes `style.scss`'s `@import` 4 levels deep (matching the real repo's depth below `$HOME`), which is CORRECT for AGS's own bundle-time compile — but WRONG if `reload-css`'s own `sass` subprocess is fed the symlink path directly (plain `sass` does not collapse symlinks). The fix resolves the symlink via `realpath` before invoking `sass`, so both invocations agree.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 / repo-convention compliance] No post_hook in matugen config.toml — wired into reload.sh instead**
- **Found during:** Task 1 (reading config.toml before editing)
- **Issue:** The plan (and the approved implementation-plan doc) instructs adding `post_hook = "ags request reload-css 2>/dev/null || true"` to the new `[templates.ags]` block. But `config.toml`'s own header comment and `theme-engine/lib/reload.sh`'s header both explicitly document reload.sh as the SOLE reload-fan-out owner (D-04) — "no post_hook lines below" — a decision locked in after this plan's approved-plan doc was written (01-02 Task 1 specifically stripped all matugen post_hooks). Adding one here would silently reintroduce a second reload-fan-out path this repo's own architecture forbids.
- **Fix:** Registered `[templates.ags]` with no post_hook. Added a guarded block to `theme_engine_reload()` in `reload.sh`: `if command -v ags >/dev/null 2>&1 && ags list 2>/dev/null | grep -qx 'media'; then ags request -i media reload-css 2>/dev/null || true; fi` — same liveness-checked, `|| true`-guarded pattern already used for eww's `pgrep -x eww && eww reload`.
- **Files modified:** `matugen/.config/matugen/config.toml`, `theme-engine/.config/theme-engine/lib/reload.sh`
- **Verification:** Live theme-apply calls (5 total across Task 1-3) each triggered the guarded block with no errors; `ags list` correctly gated the call (empty when AGS wasn't running, `media` when it was).
- **Committed in:** `527c7ad` (Task 1 commit)

**2. [Rule 1 - Bug] AGS's @import path needs 4 levels, not eww's 2 (symlink-collapsing bundler)**
- **Found during:** Task 2 (first `ags run` smoke test after wiring `@import "../../.local/state/theme/ags.scss"` per eww's exact depth, as the plan's read_first instructed)
- **Issue:** `ags run --directory ~/.config/ags` (the stowed symlink) failed to compile: `Error: Can't find stylesheet to import`. The sass compiler error itself surfaced the REAL repo path (`.../dotfiles/ags/.config/ags/style.scss`), proving AGS's Go bundler resolves `--directory`/CWD through symlink-collapsing real-path resolution before compiling — unlike eww's daemon, which preserves the symlink (confirmed by eww's own working 2-level import).
- **Fix:** Changed the import to `../../../../.local/state/theme/ags.scss` (4 levels — correct against the real repo path, which sits exactly 1 directory below `$HOME` on this machine).
- **Files modified:** `ags/.config/ags/style.scss`
- **Verification:** `ags run --directory ~/.config/ags` compiled clean; live screenshot confirmed the catppuccin palette rendered through the card.
- **Committed in:** `e408d5f` (Task 2 commit)

**3. [Rule 1 - Bug] reload-css silently failed — sass fed the symlink path, not the resolved real path**
- **Found during:** Task 3 (live end-to-end pipeline verification) — NOT caught by Task 2's own smoke test, because Task 2 only verified the initial bundle-time compile (which uses AGS's own internal, already-symlink-collapsing invocation), not the separate runtime `sass` subprocess `reloadCss()` spawns via `ags/process`'s `exec()`.
- **Issue:** `ags request -i media reload-css` returned `"ok"` every time, but the applet's colors never actually changed after a theme switch. The AGS log showed a `media-CRITICAL` on every call: `reload-css: sass compile of /home/aorus/.config/ags/style.scss failed: ... Can't find stylesheet to import`. `reloadCss()` built `STYLE_ENTRY` from `${GLib.get_home_dir()}/.config/ags/style.scss` (the stowed symlink) — but per Deviation 2, `style.scss`'s `@import` is written at 4-levels depth, correct ONLY against the REAL repo path. Plain `sass`, unlike AGS's own bundler, does NOT collapse the symlink, so the same 4-level import failed every time this code path ran.
- **Fix:** Resolve the symlink to its real path via `realpath` once at module load (`const STYLE_ENTRY = exec(["realpath", STYLE_LINK])`), matching AGS's own bundler resolution exactly.
- **Files modified:** `ags/.config/ags/app.tsx`
- **Verification:** Live-reproduced before the fix (GLib-CRITICAL on every `reload-css` call, colors never changed); after the fix, `dracula` (static) and `materialyou` (dynamic) theme switches both auto-recolored the running applet with zero `media-CRITICAL` log entries — confirmed via two differing grim screenshots.
- **Committed in:** `bfb59f9` (follow-up fix commit)

**4. [Rule 3 - Blocking, hygiene] `ags/.config/ags/@girs/` left untracked after `ags types`**
- **Found during:** Task 2 (ran `ags types` to ground-truth the exact `apply_css`/`exec`/`monitorFile` API signatures against the installed AGS 3.1.2 before writing app.tsx, per this plan's explicit "pin the exact form against the installed binary" instruction)
- **Issue:** `ags types` generates a large `@girs/` directory of GObject-introspection TypeScript defs (~180 files) — a `node_modules`/`@types`-style generated cache, not repo content, that would otherwise sit untracked forever.
- **Fix:** Added `ags/.config/ags/@girs/` to the top-level `.gitignore`.
- **Files modified:** `.gitignore`
- **Verification:** `git status --short` shows no untracked files under `ags/.config/ags/@girs/` after the ignore rule.
- **Committed in:** `e408d5f` (Task 2 commit)

---

**Total deviations:** 4 (1 repo-convention compliance, 2 Rule-1 bugs, 1 Rule-3 hygiene). None architectural/Rule-4 — all either corrected a plan instruction that had been superseded by an already-locked repo convention, or fixed a genuine live-reproduced bug blocking the plan's own success criterion.
**Impact on plan:** All four were necessary for MEDIA-03 to actually work end-to-end (deviations 2 and 3 in particular — without the realpath fix, `reload-css` silently no-op'd forever, which the plan's own acceptance criteria would have caught as a failure). No scope creep — MPRIS backend, transport/seek/volume/switcher, and the garuda visual layout are all untouched.

## Known Cosmetic Note (out of scope)

The `Gtk.Scale` (seek/volume slider) trough "highlight" fill and thumb do not recolor with the theme — they render via GTK4's system `@accent_color`, sourced from `gtk-4.0/colors.css` (a separate, pre-existing matugen template), which — per this repo's own documented GTK4 characteristic (CLAUDE.md Stack Patterns: "GTK4/libadwaita apps... restart required after CSS change") — is only read at process start, not hot-reloadable. `style.scss` never declared a color for these GTK pseudo-elements (10-04 didn't either), so there was nothing to "replace with a palette var" here; this is a system-level GTK4 characteristic affecting every GTK4 app in this engine (Walker included), not something MEDIA-03/this plan's scope touches. A future plan could add explicit `.media-seek highlight`/`.media-volume highlight` palette-var overrides in `style.scss` (following eww.scss's own `trough`/`highlight`/`slider` pattern) to make these hot-reloadable too, independent of the system accent color.

## Issues Encountered

- **Window auto-hide on focus-loss during automated testing.** The applet window (Astal.Window, `keymode: ON_DEMAND`) intermittently closed itself between my own tool calls during live verification (an intrinsic Astal/layer-shell behavior for `ON_DEMAND` windows, matching the approved spec's "close on focus-loss" design intent — not something 10-02's `MediaWindow.tsx` code implements explicitly, and not touched by this plan). Worked around by re-toggling the window open immediately before each screenshot, within a single tight bash call. Not a bug in this plan's work.
- **Wallpaper side effect from static-theme-apply's autoset.** `theme-apply <static-preset>` auto-sets a wallpaper from that preset's folder (D-11/D-12, pre-existing engine behavior, unrelated to this plan). Since Task 3 required applying multiple themes on the live desktop, the user's original wallpaper (`nord/0-black-moon.jpg`, captured before any theme-apply call in this session) was overwritten several times during testing. Restored via a direct symlink + `awww img` call after the verification sequence completed, back to the exact original file — confirmed the desktop's `current-theme` (catppuccin), `mode` (dark), and wallpaper (`nord/0-black-moon.jpg`) all match the pre-session state.

## User Setup Required

None — no external service configuration. `ags/.config/ags/@girs/` is gitignored generated output, regenerable via `ags types` on any machine.

## Next Phase Readiness

- MEDIA-03 delivered and live-verified: matugen theming now flows through to the AGS media applet exactly like every other themed surface in this repo, hot-reloading with zero manual restart on both static and dynamic theme switches.
- Ready for **10-06** (integration: waybar on-click repoint to `ags request -i media toggle-media`, autostart `exec-once`, eww media-popup retirement, final `stow ags` reproducibility pass). 10-06 should reuse the `-i media` request form and the `ags list | grep -qx media` liveness-check pattern established here if it needs to detect a live AGS instance.
- No blockers.

---
*Phase: 10-ags-media-applet*
*Completed: 2026-07-15*

## Self-Check: PASSED
- `matugen/.config/matugen/templates/ags-colors.scss` — FOUND
- `matugen/.config/matugen/config.toml` (modified) — FOUND
- `ags/.config/ags/style.scss` (modified) — FOUND
- `ags/.config/ags/app.tsx` (modified) — FOUND
- `theme-engine/.config/theme-engine/lib/reload.sh` (modified) — FOUND
- `.gitignore` (modified) — FOUND
- Commit `527c7ad` (Task 1) — FOUND
- Commit `e408d5f` (Task 2) — FOUND
- Commit `bfb59f9` (Task 3 follow-up fix) — FOUND
