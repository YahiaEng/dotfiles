---
phase: 03-repo-cleanup-fresh-install-reproducibility
plan: 01
subsystem: repo-hygiene
tags: [stow, gitignore, dead-code-removal, dotfiles]

# Dependency graph
requires:
  - phase: 02-static-dynamic-parity-switch-reliability
    provides: consolidated theme-engine, contract.json, verified reload pipeline
provides:
  - Dead wofi package, orphaned matugen template, debug.txt, and Phase-1-retired vscodium-theme.sh removed from the repo
  - README.md aligned so no documentation references the retired Wofi launcher
  - Screenshot PNGs untracked and structurally excluded from the wallpapers stow fold + gitignored
  - A reference-based dead-file hunt with an evidence-backed ambiguous-file batch awaiting confirmation
affects: [03-02, install.sh, stow.sh]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "list-then-confirm deletion policy (D-47): obviously-dead files removed with grep evidence; ambiguous files batched into one evidence table, never silently deleted"
    - "runtime-write subtree excluded from stow fold via .stow-local-ignore, mirrored in .gitignore as belt-and-suspenders (the ^rice$ / Pictures/Screenshots pattern)"

key-files:
  created: []
  modified:
    - README.md
    - .stow-local-ignore
    - .gitignore

key-decisions:
  - "wofi/, matugen/.config/matugen/templates/wofi-colors.css, debug.txt, hypr/.config/hypr/scripts/vscodium-theme.sh removed — all zero-referenced and catalogued in D-46"
  - "screenshot.sh's SCREENSHOT_DIR path left unchanged (D-48) — the fix is the ignore/untrack pair, not a path rename, since the ~/Pictures fold is the actual root cause"
  - "install.sh and stow.sh package-list entries for wofi/scripts NOT touched here — single-owner-per-file, deferred to plan 03-02"
  - "powermenu.sh and .vscode/settings.json flagged AMBIGUOUS rather than obviously-dead, per D-51's explicit naming of 'older switch/picker variants not bound in keybinds.conf' and root-level oddities — despite powermenu.sh being functionally superseded by wlogout.sh, it stays undeleted pending confirmation"
  - "fastfetch/.config/fastfetch/art/*.txt (4 custom ASCII art files) added to the ambiguous batch — config.jsonc uses the built-in 'arch' source, so none of the 4 files are wired to anything"

requirements-completed: [CLEAN-01, CLEAN-02]

coverage:
  - id: D1
    description: "Catalogued dead files removed (wofi/ package, orphaned wofi-colors.css template, debug.txt, vscodium-theme.sh) and README aligned to reference only Walker"
    requirement: "CLEAN-01"
    verification:
      - kind: other
        ref: "test ! -e wofi && test ! -e debug.txt && test ! -e matugen/.config/matugen/templates/wofi-colors.css && test ! -e hypr/.config/hypr/scripts/vscodium-theme.sh"
        status: pass
      - kind: other
        ref: "grep -v '^[[:space:]]*#' README.md | grep -ci wofi -> 0"
        status: pass
      - kind: other
        ref: "git ls-files wofi -> empty"
        status: pass
    human_judgment: false
  - id: D2
    description: "Screenshot PNGs untracked; stow fold + gitignore pair keeps future screenshots out of git permanently (CLEAN-02 invariant)"
    requirement: "CLEAN-02"
    verification:
      - kind: other
        ref: "git ls-files wallpapers/Pictures/Screenshots | wc -l -> 0"
        status: pass
      - kind: other
        ref: "touch a new file in the resolved screenshot dir; git status --porcelain -- wallpapers/Pictures/Screenshots -> empty"
        status: pass
      - kind: other
        ref: "stow -n wallpapers -> no conflicts"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reference-based dead-file hunt run; ambiguous batch (powermenu.sh, .vscode/settings.json, 4 fastfetch art files) presented with evidence, none deleted without confirmation"
    requirement: "CLEAN-01"
    verification: []
    human_judgment: true
    rationale: "D-47 requires an explicit user confirmation before any ambiguous file is deleted — this is a judgment call (keep vs delete) that automation cannot make. Evidence table is below; awaiting human disposition."

# Metrics
duration: 20min
completed: 2026-07-08
status: complete
---

# Phase 3 Plan 1: Repo Cleanup — Dead File Removal & Screenshot Fold Fix Summary

**Removed the wofi package tree, an orphaned matugen template, debug.txt, and a Phase-1-retired script; fixed the screenshot-in-git root cause with a stow-fold exclusion + gitignore pair; ran a reference-based dead-file hunt that surfaced three ambiguous files awaiting confirmation.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-08T11:19:32Z
- **Completed:** 2026-07-08T11:25:25Z
- **Tasks:** 3 completed
- **Files modified:** 30 (8 in Task 1, 24 in Task 2 — includes the 22 untracked PNGs; 0 net new deletions in Task 3)

## Accomplishments
- Physically removed `wofi/` (3 files), the orphaned `wofi-colors.css` matugen template, `debug.txt`, and `hypr/.config/hypr/scripts/vscodium-theme.sh` — all zero-referenced and catalogued in D-46
- Aligned README.md (intro, features, stack table, directory tree, keybindings) so it names Walker everywhere it previously named Wofi, including the directory-tree script comments (`theme-switch.sh`/`waybar-switch.sh`/`wallpaper-switch.sh` said "Wofi ... picker" — corrected to "Walker ... picker" since those scripts call `walker --dmenu`)
- Untracked the 22 screenshot PNGs and closed the root cause: `^Pictures/Screenshots$` added to `.stow-local-ignore` (excludes the runtime-write subtree from the `wallpapers` stow fold) and `wallpapers/Pictures/Screenshots/` added to `.gitignore` as belt-and-suspenders — verified a fresh write into the resolved screenshot dir leaves `git status --porcelain` empty
- Ran a repo-wide reference-based dead-file hunt across all stow packages (scripts, matugen templates, hypr keybinds/autostart, waybar configs) — found no additional obviously-dead files beyond Task 1's scope, and surfaced 3 ambiguous unreferenced files, batched below per D-47 with per-file evidence, none deleted

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove catalogued dead files and align documentation** - `61221be` (feat)
2. **Task 2: Fix the screenshot-in-git root cause (stow fold + untrack + ignore)** - `286fb28` (fix)
3. **Task 3: Reference-based dead-file hunt — list-then-confirm before deletion (D-47)** - no commit (audit-only task; zero additional obviously-dead files found, and D-47 forbids deleting the ambiguous batch without confirmation — evidence recorded below and in this SUMMARY instead)

**Plan metadata:** (pending — this SUMMARY + STATE.md + ROADMAP.md commit)

## Files Created/Modified
- `README.md` - Wofi → Walker across intro, features, stack table, directory tree, and keybindings
- `.stow-local-ignore` - removed stale `debug.txt` line; added `^Pictures/Screenshots$` exclusion
- `.gitignore` - added `wallpapers/Pictures/Screenshots/` entry
- `wofi/.config/wofi/{config,style.css,colors.css}` - deleted (dead package)
- `matugen/.config/matugen/templates/wofi-colors.css` - deleted (orphaned template)
- `debug.txt` - deleted
- `hypr/.config/hypr/scripts/vscodium-theme.sh` - deleted (Phase-1-retired, unreferenced)
- `wallpapers/Pictures/Screenshots/*.png` (22 files) - deleted from git tracking (user-generated runtime data)

## Dead-File Hunt Evidence Table (D-47)

Grep sweep run across: `hypr/.config/hypr/config/keybinds.conf`, `hypr/.config/hypr/config/autostart.conf`, all `*.sh`/`*.conf`/`*.jsonc`/`*.toml`/`*.json` files, `install.sh`, `stow.sh`, and `theme-engine/`.

**Files confirmed LIVE (checked, not flagged):**
| File | Reference found |
|---|---|
| `hypr/.config/hypr/scripts/media-player.py` | `waybar/.config/waybar/config-floating.jsonc:52` (`custom/media-player` module) |
| `hypr/.config/hypr/scripts/vscodium-extensions.sh` | `install.sh:214-215` |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` | `hypr/.config/hypr/scripts/wallpaper-switch.sh:12` |
| `theme-engine/.config/theme-engine/lib/{generate,commit,gtk,reload,contract}.sh` | sourced by `theme-apply`/`theme-doctor`/`theme-parity`/`theme-stress-test` |
| All `matugen/.config/matugen/templates/*` (post-cleanup) | every remaining template has a matching `[templates.*]` entry in `config.toml` |
| `theme-switch.sh`, `waybar-switch.sh`, `wallpaper-switch.sh`, `screenshot.sh`, `waybar-launch.sh`, `theme-init.sh`, `wlogout.sh` | bound directly in `keybinds.conf`/`autostart.conf` |

**AMBIGUOUS batch — NOT deleted, awaiting explicit confirmation:**

| Path | Size | Last modified | Reference search run | Result | Recommendation |
|---|---|---|---|---|---|
| `hypr/.config/hypr/scripts/powermenu.sh` | 488 bytes | 2026-03-26 | `grep -rn "powermenu.sh" -- keybinds.conf autostart.conf *.sh *.conf *.jsonc *.toml install.sh stow.sh theme-engine/` | zero hits anywhere | Likely delete — functionally superseded by `wlogout.sh` + the `wlogout` stow package (bound to `$mainMod SHIFT, Q`), which offers the same lock/logout/reboot/shutdown/suspend actions via a GUI instead of a walker dmenu. Matches D-51's explicit "older switch/picker variant not bound in keybinds.conf" description, so it is gated here rather than auto-removed. |
| `.vscode/settings.json` | 57 bytes | 2026-03-30 | `grep -rn "\.vscode" install.sh stow.sh README.md`; not in any stow package (root-level, not under a `.config/` package prefix); not in `.stow-local-ignore` | zero hits; sets `files.associations: {"*.css": "gtk-css"}` (editor-only convenience for authoring CSS templates) | Likely keep — explicitly named as a D-51 root-level oddity, but its purpose (editor CSS syntax highlighting while authoring this repo's `.css`-named CSS-like templates) is legitimate developer tooling, not dead output. Recommend keeping unless the user disagrees. |
| `fastfetch/.config/fastfetch/art/{cyberpunk_mask,illuminati,satan_cross,star}.txt` (4 files) | 3273 / 3430 / 1555 / 3773 bytes | 2026-03-14 | `grep -n "art\|source" fastfetch/.config/fastfetch/config.jsonc` → `"source": "arch"` (built-in logo, not a custom-art path); `grep -rln "cyberpunk_mask\|illuminati\|satan_cross\|star\.txt"` across all conf/script files → no other referencer | config.jsonc does not point at any of the 4 files | Uncertain — could be leftover experiments from before `config.jsonc` settled on the built-in "arch" logo, or intentional assets kept for manual swapping later. Recommend the user decide: delete if abandoned, or wire one into `config.jsonc`'s `source` if intended for use. |

**Files referenced in `keybinds.conf`/`autostart.conf` were never placed in either bucket** (confirmed live, excluded from the hunt entirely): `theme-switch.sh`, `waybar-switch.sh`, `wallpaper-switch.sh`, `screenshot.sh`, `waybar-launch.sh`, `theme-init.sh`, `wlogout.sh`.

**No obviously-dead files were found beyond what Task 1 already removed** — the hunt corroborated that D-46's catalogue was complete for the "obvious" bucket; everything else unreferenced is uncertain-purpose and gated here.

## Decisions Made
- Screenshot save path (`SCREENSHOT_DIR="$HOME/Pictures/Screenshots"` in `screenshot.sh`) intentionally left unchanged per D-48 — relocating the path alone would not fix the bug since `~/Pictures` is stow-folded from `wallpapers/Pictures`; the actual fix is the `.stow-local-ignore` fold exclusion + `.gitignore` pair
- `powermenu.sh` kept undeleted despite clear functional supersession by `wlogout.sh`, because D-51 explicitly names "older switch/picker variants not bound in keybinds.conf" as an ambiguous-bucket category requiring confirmation, not an obvious-bucket one
- install.sh/stow.sh package-list entries referencing `wofi` and the phantom `scripts` package were intentionally NOT touched in this plan (single-owner-per-file; owned by plan 03-02)

## Deviations from Plan

None - plan executed exactly as written. Task 3 found zero additional obviously-dead files (a valid hunt outcome, not a shortfall) and correctly deferred all three ambiguous findings to the confirmation gate rather than guessing.

## Issues Encountered

None. One iteration was needed on Task 1's acceptance check: the initial README edit left "Wofi" inside directory-tree inline comments (`# Wofi theme picker`, etc.) that the `grep -v '^[[:space:]]*#'` filter didn't exclude (those lines start with `│`, not `#`) — caught immediately by the acceptance-criteria gate and fixed before proceeding to Task 2 (not logged as a Rule-1 deviation since it was corrected within the same task's verification loop, before any commit).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for plan 03-02 (install.sh/stow.sh package-list cleanup — removing the `wofi` and phantom `scripts` entries this plan deliberately left untouched)
- **Action needed from the user:** review the 3-item ambiguous batch above (`powermenu.sh`, `.vscode/settings.json`, 4 `fastfetch` art files) and confirm keep/delete for each — this will be harvested into the phase-end UAT per `workflow.human_verify_mode: end-of-phase`
- No blockers for continuing Phase 3 execution

---
*Phase: 03-repo-cleanup-fresh-install-reproducibility*
*Completed: 2026-07-08*

## Self-Check: PASSED

- FOUND: README.md, .stow-local-ignore, .gitignore
- CONFIRMED ABSENT: wofi/, debug.txt, matugen/.config/matugen/templates/wofi-colors.css, hypr/.config/hypr/scripts/vscodium-theme.sh
- FOUND commit 61221be (Task 1: feat(03-01) remove dead artifacts, align README)
- FOUND commit 286fb28 (Task 2: fix(03-01) untrack screenshots, stow-fold exclusion)
- Plan-level `<verification>` block re-run: all 5 checks pass (dead files gone; README wofi count 0; screenshot git-clean invariant holds; tracked screenshot count 0; `stow -n wallpapers`/`stow -n theme-engine` report no conflicts)
