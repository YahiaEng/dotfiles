# Phase 3: Repo Cleanup & Fresh-Install Reproducibility - Context

**Gathered:** 2026-07-08
**Status:** Ready for planning

<domain>
## Phase Boundary

The repo becomes clean of dead configs and generated artifacts (CLEAN-01/02), and the entire themed desktop is proven to reproduce unattended on a genuinely fresh Arch system via `install.sh` + `stow.sh` (INST-01/02/03). This phase owns: physical removal of dead files (wofi et al.) plus a reference-based dead-file hunt, relocating the screenshot save path out of the repo, hardening `install.sh` into a sectioned/flagged zero-prompt installer with hardware guards and hard-fail package verification, making `stow.sh` fully idempotent, seeding the first-boot theme baseline, root-causing the deferred elephant provider gap, hardening the Phase-2 verification tooling's false-pass paths, and running the hybrid container + graphical-VM reproduction gate.

Out of this phase: all v2 expansion (OSD, walker menus, media widget, more themes), light theme support, hyprlock/hypridle, automating VM provisioning (documented procedure only).

</domain>

<decisions>
## Implementation Decisions

### Cleanup scope (CLEAN-01, CLEAN-02)
- **D-46:** **Sweep + active hunt.** Remove every catalogued dead item — the wofi package dir, `wofi` from install.sh PACMAN_PKGS, the wofi entry in stow.sh PACKAGES, `debug.txt`, the orphaned `wofi-colors.css` matugen template (01-REVIEW IN-02), the phantom `scripts` entry in stow.sh (no such package dir exists), and any Phase-1-retired scripts still on disk — PLUS a dedicated reference-based dead-file audit (grep for unreferenced scripts/configs) across all packages.
- **D-47:** Hunt disposal policy is **list-then-confirm**: obviously dead files are removed directly; ambiguous unreferenced files are batched into ONE user confirmation checkpoint with evidence before deletion. No silent deletions of uncertain files.
- **D-48:** Screenshots are fixed at the cause: **screenshot.sh's save path moves out of the repo** (e.g. `~/Pictures/Screenshots`), existing copies under `wallpapers/Pictures/Screenshots/` are deleted, and the path is gitignored as belt-and-suspenders.
- **D-49:** **Doc alignment is in scope**: README.md and any in-repo references are updated so nothing points at removed files (a clean repo with a README advertising wofi isn't clean).
- **D-50:** CLEAN-02 closes as a **rerunnable invariant**, not a one-time observation: after a theme switch, assert `git status --porcelain` is empty, and add that assertion as a permanent check (e.g. into theme-doctor).
- **D-51:** Root-level oddities included: `.vscode/` is a hunt candidate under the D-47 policy; stale `.stow-local-ignore` entries (e.g. `debug.txt`) are pruned after deletions so the ignore file only lists things that exist.

### Verification environment (INST-03)
- **D-52:** **Hybrid environment.** Fast iteration in an Arch container (podman/docker: install.sh --core-only + stow.sh + render checks + theme-doctor/theme-parity logs); ONE full graphical VM run (QEMU/libvirt with virtio-gpu) is the final INST-03 gate where Hyprland actually starts and the themed desktop is visible.
- **D-53:** INST-03 pass evidence = **tool logs + human eyes**: theme-doctor and theme-parity green inside the VM (machine-readable logs per D-45) AND the user visually confirms the themed desktop on the VM display — Phase 2's human-final-verdict standard (D-35) carried forward.
- **D-54:** The **container run script is a keeper artifact** in the repo (rerunnable installer regression check, like theme-doctor); the graphical VM procedure is **documented step-by-step in VERIFICATION.md but not automated**.
- **D-55:** "Genuinely fresh Arch" baseline = **minimal archinstall from the official ISO**: base system + networkmanager + a sudo user — no desktop, no AUR helper, nothing else. This deliberately exercises the paru bootstrap path (WR-09).
- **D-56:** Dotfiles enter the fresh environment via **real `git clone` from the remote** in all verification runs — the true fresh-machine story; catches accidentally-untracked files. Implies fixes are committed/pushed before each verification iteration.

### install.sh structure & unattended policy (INST-01)
- **D-57:** install.sh is restructured into **named sections + flags** (core rice / hardware / bootloader / personal) with e.g. `--core-only`; the default full run preserves today's behavior on the real machine, while the VM gate runs core-only.
- **D-58:** **Hardware detect-guards on top of flags**: NVIDIA package group only installs when an NVIDIA GPU is detected; limine steps only run when limine is present — and the limine config is **backed up, never rm'd** (WR-08). Flags select intent; guards prevent damage.
- **D-59:** **Strictly zero prompts.** The verification environment configures passwordless sudo (NOPASSWD); every interactive step is removed from install.sh and stow.sh (including the chsh password prompt — guard it / make it non-interactive). No prompt of any kind until the final human visual check.
- **D-60:** First-boot baseline is **seeded at install time** (WR-07): stow.sh (or an install.sh post-step) runs `theme-apply catppuccin` once after stowing, so `~/.local/state/theme/` exists before the first login — first impression is a fully themed desktop. Reload steps may no-op harmlessly without a running session.
- **D-61:** Hardcoded personal bits (git identity, Africa/Cairo timezone) move into the **personal section that `--core-only` skips** — kept as-is for real-machine runs.

### stow.sh hardening (INST-02)
- **D-62:** stow.sh becomes **fully idempotent**: safe on a fresh system AND safe to re-run anytime — every state-assuming operation guarded (e.g. the unguarded `mv ~/.config/hypr/hyprland.conf` that currently aborts a fresh run under `set -e`), pre-existing real files backed up rather than clobbered or crashed on, same end state every run.

### Post-install verification (INST-01)
- **D-63:** Two verification layers at the right times: **install.sh ends with an inline critical-package verification pass** (`pacman -Q` each package, printed report table — exactly what would have caught the adw-gtk3 ghost), and **theme-doctor runs after stow.sh** as the full-pipeline gate.
- **D-64:** On a missing package the check **hard-fails**: print the full verification table, then exit nonzero — an unambiguous failure for the VM gate and any scripted run.
- **D-65:** The hard-fail set is **every listed package** in the sections that were selected to run (not just a theming-critical subset) — user explicitly chose the strictest reading; a `--core-only` run verifies the core set.
- **D-66:** The deferred elephant provider gap (files/menus/providerlist/runner/websearch absent from `elephant listproviders`) is **root-caused and fixed** so all installed providers register, and the accepted-gap carve-outs are **removed** from theme-doctor and theme-stress-test — the checks become strict. The fresh-install run then proves providers work from scratch.
- **D-67:** The Phase-2 verification tooling's advisory false-pass paths are **hardened in this phase** (02-REVIEW CR-01/WR-01): extraction must fail loudly on zero results, and walker-style.css `{{...}}` template leftovers must be covered — before these tools serve as fresh-install evidence.

### Claude's Discretion
- Container tooling choice (docker vs podman), image details, and the container script's name/location.
- VM tooling specifics (libvirt vs plain QEMU invocation), disk/memory sizing, how the documented procedure is written.
- install.sh flag names and exact section boundaries; verification-table format; how hardware detection is implemented.
- How the dead-file reference hunt is implemented and what counts as "obviously dead" vs "ambiguous".
- Backup naming conventions for stow.sh/limine guards; ordering of cleanup vs hardening plans.
- Where the CLEAN-02 git-clean assertion lives (theme-doctor vs stress-test vs both).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — CLEAN-01, CLEAN-02, INST-01, INST-02, INST-03 (the five requirements this phase covers)
- `.planning/ROADMAP.md` — Phase 3 goal, 5 success criteria, 2-plan breakdown (03-01 cleanup, 03-02 install hardening + VM verification)

### The findings this phase fixes (scoped here by prior phases)
- `.planning/phases/01-root-cause-fix-consolidated-theme-engine/01-REVIEW.md` — CR-01 (rsync missing from package lists, hard-required by commit.sh), CR-02 (orphan-cleanup `paru -R "$(pacman -Qtdq)"` aborts installer), WR-07 (unseeded first-boot state dir), WR-08 (limine config deleted with no backup), WR-09 (paru /tmp clone not idempotent), IN-02 (orphaned wofi-colors.css), IN-11 (swaync mislisted as AUR — it's in extra)
- `.planning/phases/01-root-cause-fix-consolidated-theme-engine/01-AUDIT.md` — full-repo audit findings and dispositions
- `.planning/phases/02-static-dynamic-parity-switch-reliability/02-REVIEW.md` — CR-01/WR-01 (parity/doctor silent false-pass paths, D-67), IN-04 (stress-test accepted-gap coupling to remove per D-66)

### Prior phase decisions (locked — do not re-litigate)
- `.planning/phases/01-root-cause-fix-consolidated-theme-engine/01-CONTEXT.md` — D-01..D-25; especially D-10 (catppuccin fallback, no pre-generation required), D-11 (wofi never in engine; removal is Phase 3), D-25 (theme-doctor as rerunnable regression check)
- `.planning/phases/02-static-dynamic-parity-switch-reliability/02-CONTEXT.md` — D-26..D-45; especially D-42/D-44 (keeper tools, independent commands Phase 3 calls explicitly), D-45 (machine-readable logs the VM verification parses)

### The code being cleaned/hardened
- `install.sh` — package lists + post-install tasks; the restructure target (D-57..D-61, D-63..D-65)
- `stow.sh` — PACKAGES list (phantom `scripts` entry, wofi), unguarded mv, chsh; the idempotence target (D-62)
- `.stow-local-ignore`, `.gitignore` — prune stale entries (D-51); generated-file ignores already in place
- `wofi/.config/wofi/` — the dead package to remove
- `matugen/.config/matugen/templates/` — contains the orphaned wofi-colors.css (IN-02)
- `hypr/.config/hypr/scripts/screenshot.sh` — save-path relocation target (D-48)
- `theme-engine/.config/theme-engine/theme-doctor`, `theme-parity`, `theme-stress-test` — verification tools reused as VM evidence; hardening surface (D-50, D-66, D-67)
- `theme-engine/.config/theme-engine/lib/commit.sh` — the rsync hard-dependency behind CR-01

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `theme-doctor` / `theme-parity` / `theme-stress-test`: the Phase-2 keeper tools are the in-VM evidence suite (D-42/D-44/D-45 anticipated exactly this reuse); their logs land under `~/.local/state/theme/logs/`
- `contract.json`: single source of truth for the render-target file list — any check additions should read it, not hardcode
- Existing notify-send feedback and check/report script style — new container script follows the theme-doctor pattern

### Established Patterns
- `set -euo pipefail` everywhere + the `(( counter++ ))` at-zero abort gotcha — use `counter=$((counter+1))` in new/modified scripts
- Stow package-per-app layout; `.stow-local-ignore` guards non-stowed paths (the `^rice$` entry shows the pattern)
- `--needed --noconfirm` package installs already in place — the prompt problems are sudo, chsh, and failure-mode aborts, not pacman flags

### Integration Points
- `.gitignore` already covers the two generated files (walker rice style.css, yazi theme.toml) — CLEAN-02 is mostly verification + the permanent assertion (D-50)
- git status is currently clean after switches on the dev machine — the invariant check formalizes it
- stow.sh's "Skipping: scripts (directory not found)" warning is the visible symptom of the phantom entry
- The repo remote (GitHub) is the delivery mechanism for verification runs (D-56) — verify a remote is configured and pushable before the first container iteration

</code_context>

<specifics>
## Specific Ideas

- The user went STRICTER than the recommendation twice on install verification: strictly-zero-prompts (D-59) and hard-fail on EVERY listed package (D-65). Bias the installer work toward strictness and unambiguous machine-readable failure — no warn-and-continue paths.
- On deletions the user wants control: list-then-confirm (D-47) — automation everywhere else, but no silent removal of files whose purpose is uncertain.
- The stuck-white history remains the emotional core: human eyes on the final VM desktop (D-53) is non-negotiable evidence, same as Phases 1–2.

</specifics>

<deferred>
## Deferred Ideas

- **Fully-scripted VM provisioning** (archinstall config + libvirt/quickemu automation) — considered for the harness and not chosen (D-54); could become a future convenience if the VM gate is rerun often (noted, unowned).
- None other — discussion stayed within phase scope.

</deferred>

---

*Phase: 3-Repo Cleanup & Fresh-Install Reproducibility*
*Context gathered: 2026-07-08*
