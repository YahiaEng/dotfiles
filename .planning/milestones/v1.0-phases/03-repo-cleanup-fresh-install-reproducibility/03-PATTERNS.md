# Phase 3: Repo Cleanup & Fresh-Install Reproducibility - Pattern Map

**Mapped:** 2026-07-08
**Files analyzed:** 11 (modified) + 2 new
**Analogs found:** 11 / 11 (all modifications are in-place hardening of existing files; new files follow sibling conventions)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `install.sh` (restructure into sections/flags, guards, verify table) | config/installer script | batch (sequential shell steps) | itself (existing structure, hardened in place) | exact — self-analog, extend existing sectioning already implied by comment banners |
| `stow.sh` (idempotency guards, chsh fix) | config/installer script | batch | itself; guard shape borrowed from `theme-doctor`'s check pattern | exact |
| `theme-engine/.config/theme-engine/theme-doctor` (add git-status assertion, fix menus prefix match) | test/verification script | request-response (report-only, exit code) | itself — extend existing `check()` accumulator pattern | exact |
| `theme-engine/.config/theme-engine/theme-stress-test` (remove elephant-menus carve-out) | test/verification script | batch | `theme-doctor` (sibling verification tool, same repo, same `PASS`/`FAIL` idiom) | role-match |
| `hypr/.config/hypr/scripts/screenshot.sh` (relocate save path out of stow fold) | utility script | file-I/O | itself | exact |
| `.stow-local-ignore` (add `Pictures/Screenshots` exclusion under `wallpapers`, prune `debug.txt`) | config | — | itself — existing `^rice$` entry is the exact precedent for excluding a runtime-write subtree from stow's fold | exact |
| `.gitignore` (add relocated screenshot path or confirm exclusion) | config | — | itself — existing walker/yazi generated-file entries are the precedent for "runtime output, never tracked" | exact |
| `README.md` (remove wofi references, update tree diagram) | doc | — | itself | exact |
| `matugen/.config/matugen/templates/wofi-colors.css` (delete — orphaned, no `[templates.wofi]` registration in config.toml) | dead template | — | n/a (deletion target) | n/a |
| `wofi/` package dir (delete), `wofi` entries in `install.sh` PACMAN_PKGS and `stow.sh` PACKAGES (remove) | config | — | n/a (deletion target) | n/a |
| `verify/container-run.sh` (NEW — container fast-iteration gate) | script / verification harness | batch | `theme-doctor` for PASS/FAIL reporting shape; `install.sh`/`stow.sh` for the sequential-step banner style | role-match (new file, composite analog) |
| `VERIFICATION.md` (NEW or appended section — documented, non-automated VM procedure) | doc | — | `README.md` (existing doc conventions: heading style, tree/step format) | role-match |

## Pattern Assignments

### `install.sh` (installer script, batch)

**Analog:** itself (current source, `/home/aorus/dotfiles/install.sh`)

**Current structure** (lines 1-20, banner + mirror sync):
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   Installing Hyprland Rice Dependencies  ║"
echo "╚══════════════════════════════════════════╝"
...
sudo pacman -Sy reflector --needed
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 30 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syu
```
Section-banner convention (`echo "╔...╗"` triads) already exists per logical block (AUR helper, pacman packages, AUR packages, post-install tasks, limine, timezone) — D-57's "named sections + flags" should formalize these into real bash functions gated by flags, not just decorative echo blocks. Reuse the exact echo-banner style for new/renamed sections (`section_core_rice()`, `section_hardware()`, `section_bootloader()`, `section_personal()`).

**Confirmed-broken lines requiring guards (Pitfall 4, 5, 6 from RESEARCH.md, D-58/D-59/D-62-adjacent):**
```bash
# Line 196 — orphan removal aborts on fresh install (pacman -Qtdq empty):
paru -R "$(pacman -Qtdq)"

# Line 236 — limine.conf deleted with no backup, no -f:
sudo rm /boot/limine/limine.conf
```
Fix shape (from RESEARCH Code Examples, apply directly):
```bash
mapfile -t ORPHANS < <(pacman -Qtdq || true)
(( ${#ORPHANS[@]} > 0 )) && paru -R "${ORPHANS[@]}"

[[ -f /boot/limine/limine.conf ]] && sudo cp /boot/limine/limine.conf /boot/limine/limine.conf.bak
sudo rm -f /boot/limine/limine.conf
```

**Package list edits (D-46, IN-11):**
```bash
# PACMAN_PKGS (line 41-141): remove `wofi` (line 55); move `swaync` from
# AUR_PKGS (line 149) into PACMAN_PKGS — it lives in official `extra` (IN-11).
# AUR_PKGS (line 147-188): remove `swaync` (moved above), keep elephant-* set
# (D-66 root-causes registration separately, not an install.sh package-list change).
```

**Post-install verify table (D-63/D-64/D-65)** — new function to add, following the exact shape already given in RESEARCH.md Code Examples and matching `theme-doctor`'s `check()` accumulator idiom above:
```bash
verify_packages() {
    local -n pkgs_ref="$1"
    local missing=() name
    for name in "${pkgs_ref[@]}"; do
        if pacman -Q "$name" &>/dev/null; then
            printf '  [OK]   %s\n' "$name"
        else
            printf '  [MISS] %s\n' "$name"
            missing+=("$name")
        fi
    done
    if (( ${#missing[@]} > 0 )); then
        echo "install.sh: ${#missing[@]} package(s) failed to install: ${missing[*]}" >&2
        exit 1
    fi
}
```

**Personal section extraction (D-61)** — isolate into a guarded function skipped by `--core-only`:
```bash
# Lines 222-226 (git identity) and 242 (timezone) move into:
section_personal() {
    git config --global user.name yahiaEng
    git config --global user.email eng-yahia-tarek@outlook.com
    sudo timedatectl set-timezone Africa/Cairo
}
```

**chsh zero-prompt fix (Pitfall 6, applies to stow.sh not install.sh — see below).**

---

### `stow.sh` (installer script, batch)

**Analog:** itself (current source, `/home/aorus/dotfiles/stow.sh`)

**Confirmed-broken unguarded mv (Pitfall 2, D-62)** — line 46:
```bash
mv ~/.config/hypr/hyprland.conf ~/.config/hyprland.conf.bak
```
Fix (Pattern 1 from RESEARCH.md, exact excerpt to reuse):
```bash
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPR_BAK="$HOME/.config/hyprland.conf.bak"
if [[ -e "$HYPR_CONF" && ! -L "$HYPR_CONF" ]]; then
    mv "$HYPR_CONF" "$HYPR_BAK"
fi
```

**chsh prompt fix (Pitfall 6, D-59)** — line 70:
```bash
chsh -s $(which zsh)
```
becomes:
```bash
sudo chsh -s "$(which zsh)" "$USER"
```

**PACKAGES array edits (D-46)** — lines 19-39: remove `scripts` (phantom, no such package dir exists on disk — confirmed via `ls` above) and `wofi`.

**Stow loop is already correctly idempotent** (`stow --restow`, lines 48-55) — no change needed there; keep the existing per-package `[[ -d "$pkg" ]]` guard as the template for any new guarded step.

---

### `theme-engine/.config/theme-engine/theme-doctor` (verification script, request-response)

**Analog:** itself

**Existing `check()` accumulator** (lines 20-30) — reuse verbatim for any new assertion:
```bash
check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        echo "  [PASS] $desc"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $desc"
        FAIL=$((FAIL + 1))
    fi
}
```

**CLEAN-02 git-status invariant (D-50)** — new check, follow the existing stow-conflict check's guarded-skip shape (lines 74-79) as the template:
```bash
if command -v git >/dev/null 2>&1 && [[ -d "$DOTFILES_DIR/.git" ]]; then
    GIT_DIRTY="$(cd "$DOTFILES_DIR" && git status --porcelain)"
    [[ -z "$GIT_DIRTY" ]]
    check "git status --porcelain is empty (repo clean)" "$?"
else
    echo "  [SKIP] git status check ($DOTFILES_DIR/.git not found)"
fi
```

**Provider-parity menus fix (D-66, Pattern 3 in RESEARCH.md)** — replace the exact-match loop at lines 136-140:
```bash
# current (bug):
for p in $CONFIGURED_PROVIDERS; do
    if ! printf '%s\n' "$ACTIVE_PROVIDERS" | grep -qx "$p"; then
        MISSING="$MISSING $p"
    fi
done
```
```bash
# fixed (prefix-aware for menus):
for p in $CONFIGURED_PROVIDERS; do
    if [[ "$p" == "menus" ]]; then
        printf '%s\n' "$ACTIVE_PROVIDERS" | grep -q '^menus:' && continue
    elif printf '%s\n' "$ACTIVE_PROVIDERS" | grep -qx "$p"; then
        continue
    fi
    MISSING="$MISSING $p"
done
```
Also remove the "expected/known gap" comment block at lines 122-125 once D-66's package installs land — the check becomes strict per D-66.

---

### `theme-engine/.config/theme-engine/theme-stress-test` (verification script, batch)

**Analog:** `theme-doctor` (sibling tool, same repo, same PASS/FAIL idiom — read theme-stress-test directly during planning to find its own elephant-menus carve-out; not yet read in this pass since RESEARCH.md IN-04 already localizes it as "accepted-gap coupling to remove"). Apply the same prefix-aware menus fix pattern as theme-doctor above wherever theme-stress-test independently exact-matches `menus`.

---

### `hypr/.config/hypr/scripts/screenshot.sh` (utility, file-I/O)

**Analog:** itself

**Current save path** (line 7):
```bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
```
**Root cause (Pitfall 1, Pattern 2 in RESEARCH.md):** `~/Pictures` is stow-folded into `dotfiles/wallpapers/Pictures` because `wallpapers` exclusively owns that subtree — relocating `SCREENSHOT_DIR` to a fresh subdirectory alone does NOT fix this if it's still under `~/Pictures` or `~/dotfiles`. Two-part fix required:
1. Exclude `Pictures/Screenshots` from the `wallpapers` stow package via `.stow-local-ignore` (see below) so `~/Pictures` becomes a real directory again.
2. Only then is a `SCREENSHOT_DIR="$HOME/Pictures/Screenshots"` (now genuinely outside the repo tree) actually a fix — or move it out of `~/Pictures` entirely (e.g. `$HOME/Screenshots`) for extra safety, per D-48's "e.g. `~/Pictures/Screenshots`" phrasing which assumes the fold is also fixed.

**Verification command** (reuse directly, from RESEARCH.md Code Examples):
```bash
readlink -f "$HOME/Pictures"                 # must be a real dir post-fix, not a repo symlink
readlink -f "$HOME/Pictures/Screenshots" 2>&1 # must NOT resolve into dotfiles/
stow -n wallpapers 2>&1                        # dry-run confirms new fold shape
```

---

### `.stow-local-ignore` (config)

**Analog:** itself — the existing `^rice$` entry (lines 12-15) is the exact, already-proven precedent for excluding a runtime-write subtree from a stow package's fold:
```
# D-09/AUDIT #17: the walker rice-theme dir is wired directly by
# theme-engine/lib/commit.sh (a symlink into ~/.local/state/theme/,
# idempotent on every theme-apply) — never let a plain `stow --restow`
# fight over this path.
^rice$
```
New entry to add (Pattern 2 from RESEARCH.md — package-scoped, matches relative to the `wallpapers` package dir):
```
^Pictures/Screenshots$
```
Also remove stale `debug.txt` line (line 10) after the file is deleted (D-51).

---

### `.gitignore` (config)

**Analog:** itself — existing walker/yazi generated-file entries (bottom of file) are the precedent comment style and rationale format for "runtime output that must never be tracked":
```
walker/.config/walker/themes/rice/style.css
yazi/.config/yazi/theme.toml
```
If the fixed screenshot path stays anywhere under the repo's stow-managed tree (belt-and-suspenders per D-48), add a matching entry with the same explanatory-comment convention. If the path moves fully outside `~/Pictures`/`~/dotfiles` (recommended), a `.gitignore` entry becomes moot but D-48 explicitly still asks for one as a second layer of defense — add it regardless.

---

### `README.md` (doc)

**Analog:** itself — existing tree-diagram entries for `wofi/` (lines 73-76) and the wofi mention in the intro (line 3) are the exact deletion targets; the `waybar/`, `kitty/`, `swaync/` entries directly above/below (lines 60-79) are the formatting template to preserve when wofi's block is removed (keep tree alignment, comment column position).

---

## Shared Patterns

### Guard-before-mutate (idempotency)
**Source:** RESEARCH.md Pattern 1, exemplified by the fix needed in `stow.sh` line 46 and `install.sh` lines 196/236
**Apply to:** `install.sh` (orphan removal, limine rm), `stow.sh` (hyprland.conf mv)
```bash
if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
    mv "$TARGET" "$BACKUP"
fi
```

### PASS/FAIL check accumulator
**Source:** `theme-engine/.config/theme-engine/theme-doctor` lines 17-30 (existing, proven)
**Apply to:** any new checks in theme-doctor, theme-stress-test, and the new `verify/container-run.sh` — reuse the same `check()` function shape/output format so all verification tooling reads consistently in CI/VM logs (D-45 machine-readable requirement).

### Stow-fold exclusion for runtime-write subtrees
**Source:** `.stow-local-ignore` line 15 (`^rice$`) — the only existing precedent for this exact problem class
**Apply to:** `Pictures/Screenshots` exclusion under `wallpapers` package (D-48/CLEAN-01)

### `set -euo pipefail` + `counter=$((counter+1))` (never `((counter++))`)
**Source:** established convention noted in RESEARCH.md "Established Patterns" (confirmed present throughout `theme-doctor`, `install.sh`, `stow.sh`)
**Apply to:** all new/modified scripts this phase touches, including `verify/container-run.sh`

### Section-banner echo style
**Source:** `install.sh` lines 9-11, 200-202, 206-208 and `stow.sh` lines 41-43, 72-75
```bash
echo "╔══════════════════════════════════════════╗"
echo "║   <title, centered-ish>                  ║"
echo "╚══════════════════════════════════════════╝"
```
**Apply to:** any new top-level section banners in restructured `install.sh` and the new `verify/container-run.sh`, for visual consistency with the rest of the installer suite.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `verify/container-run.sh` | script | batch | No prior container-orchestration script exists in this repo; compose from `theme-doctor`'s report idiom + `install.sh`/`stow.sh`'s banner/step style (see Pattern Assignments above) — no single closer analog. Exact name/location is Claude's Discretion per D-52. |
| `VERIFICATION.md` VM-procedure section | doc | — | No prior "documented manual procedure" doc exists in this repo (README.md documents the shipped system, not an operator runbook) — follow README.md's heading/tree-diagram conventions but expect original structure for the step-by-step VM procedure. |

## Metadata

**Analog search scope:** repo root (`install.sh`, `stow.sh`, `.gitignore`, `.stow-local-ignore`, `README.md`), `theme-engine/.config/theme-engine/` (theme-doctor, theme-parity, theme-stress-test, lib/contract.sh), `hypr/.config/hypr/scripts/screenshot.sh`, `matugen/.config/matugen/config.toml`, `wofi/` package tree (listing only, confirming deletion scope)
**Files scanned:** 11 read directly this session (plus prior-phase docs already loaded via CONTEXT.md/RESEARCH.md cross-references)
**Pattern extraction date:** 2026-07-08
