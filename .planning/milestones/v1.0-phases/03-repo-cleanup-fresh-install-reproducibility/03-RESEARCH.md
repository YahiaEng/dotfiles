# Phase 3: Repo Cleanup & Fresh-Install Reproducibility - Research

**Researched:** 2026-07-08
**Domain:** Bash install/dotfiles tooling — GNU Stow symlink management, Arch pacman/AUR installers, container + VM reproduction testing
**Confidence:** HIGH (most load-bearing claims verified directly on this repo/machine; VM/container tooling claims are MEDIUM/LOW — see Sources)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Cleanup scope (CLEAN-01, CLEAN-02)**
- **D-46:** Sweep + active hunt. Remove every catalogued dead item — the wofi package dir, `wofi` from install.sh PACMAN_PKGS, the wofi entry in stow.sh PACKAGES, `debug.txt`, the orphaned `wofi-colors.css` matugen template (01-REVIEW IN-02), the phantom `scripts` entry in stow.sh (no such package dir exists), and any Phase-1-retired scripts still on disk — PLUS a dedicated reference-based dead-file audit (grep for unreferenced scripts/configs) across all packages.
- **D-47:** Hunt disposal policy is list-then-confirm: obviously dead files are removed directly; ambiguous unreferenced files are batched into ONE user confirmation checkpoint with evidence before deletion. No silent deletions of uncertain files.
- **D-48:** Screenshots are fixed at the cause: screenshot.sh's save path moves out of the repo (e.g. `~/Pictures/Screenshots`), existing copies under `wallpapers/Pictures/Screenshots/` are deleted, and the path is gitignored as belt-and-suspenders.
- **D-49:** Doc alignment is in scope: README.md and any in-repo references are updated so nothing points at removed files (a clean repo with a README advertising wofi isn't clean).
- **D-50:** CLEAN-02 closes as a rerunnable invariant, not a one-time observation: after a theme switch, assert `git status --porcelain` is empty, and add that assertion as a permanent check (e.g. into theme-doctor).
- **D-51:** Root-level oddities included: `.vscode/` is a hunt candidate under the D-47 policy; stale `.stow-local-ignore` entries (e.g. `debug.txt`) are pruned after deletions so the ignore file only lists things that exist.

**Verification environment (INST-03)**
- **D-52:** Hybrid environment. Fast iteration in an Arch container (podman/docker: install.sh --core-only + stow.sh + render checks + theme-doctor/theme-parity logs); ONE full graphical VM run (QEMU/libvirt with virtio-gpu) is the final INST-03 gate where Hyprland actually starts and the themed desktop is visible.
- **D-53:** INST-03 pass evidence = tool logs + human eyes: theme-doctor and theme-parity green inside the VM (machine-readable logs per D-45) AND the user visually confirms the themed desktop on the VM display — Phase 2's human-final-verdict standard (D-35) carried forward.
- **D-54:** The container run script is a keeper artifact in the repo (rerunnable installer regression check, like theme-doctor); the graphical VM procedure is documented step-by-step in VERIFICATION.md but not automated.
- **D-55:** "Genuinely fresh Arch" baseline = minimal archinstall from the official ISO: base system + networkmanager + a sudo user — no desktop, no AUR helper, nothing else. This deliberately exercises the paru bootstrap path (WR-09).
- **D-56:** Dotfiles enter the fresh environment via real `git clone` from the remote in all verification runs — the true fresh-machine story; catches accidentally-untracked files. Implies fixes are committed/pushed before each verification iteration.

**install.sh structure & unattended policy (INST-01)**
- **D-57:** install.sh is restructured into named sections + flags (core rice / hardware / bootloader / personal) with e.g. `--core-only`; the default full run preserves today's behavior on the real machine, while the VM gate runs core-only.
- **D-58:** Hardware detect-guards on top of flags: NVIDIA package group only installs when an NVIDIA GPU is detected; limine steps only run when limine is present — and the limine config is backed up, never rm'd (WR-08). Flags select intent; guards prevent damage.
- **D-59:** Strictly zero prompts. The verification environment configures passwordless sudo (NOPASSWD); every interactive step is removed from install.sh and stow.sh (including the chsh password prompt — guard it / make it non-interactive). No prompt of any kind until the final human visual check.
- **D-60:** First-boot baseline is seeded at install time (WR-07): stow.sh (or an install.sh post-step) runs `theme-apply catppuccin` once after stowing, so `~/.local/state/theme/` exists before the first login — first impression is a fully themed desktop. Reload steps may no-op harmlessly without a running session.
- **D-61:** Hardcoded personal bits (git identity, Africa/Cairo timezone) move into the personal section that `--core-only` skips — kept as-is for real-machine runs.

**stow.sh hardening (INST-02)**
- **D-62:** stow.sh becomes fully idempotent: safe on a fresh system AND safe to re-run anytime — every state-assuming operation guarded (e.g. the unguarded `mv ~/.config/hypr/hyprland.conf` that currently aborts a fresh run under `set -e`), pre-existing real files backed up rather than clobbered or crashed on, same end state every run.

**Post-install verification (INST-01)**
- **D-63:** Two verification layers at the right times: install.sh ends with an inline critical-package verification pass (`pacman -Q` each package, printed report table — exactly what would have caught the adw-gtk3 ghost), and theme-doctor runs after stow.sh as the full-pipeline gate.
- **D-64:** On a missing package the check hard-fails: print the full verification table, then exit nonzero — an unambiguous failure for the VM gate and any scripted run.
- **D-65:** The hard-fail set is every listed package in the sections that were selected to run (not just a theming-critical subset) — user explicitly chose the strictest reading; a `--core-only` run verifies the core set.
- **D-66:** The deferred elephant provider gap (files/menus/providerlist/runner/websearch absent from `elephant listproviders`) is root-caused and fixed so all installed providers register, and the accepted-gap carve-outs are removed from theme-doctor and theme-stress-test — the checks become strict. The fresh-install run then proves providers work from scratch.
- **D-67:** The Phase-2 verification tooling's advisory false-pass paths are hardened in this phase (02-REVIEW CR-01/WR-01): extraction must fail loudly on zero results, and walker-style.css `{{...}}` template leftovers must be covered — before these tools serve as fresh-install evidence.

### Claude's Discretion
- Container tooling choice (docker vs podman), image details, and the container script's name/location.
- VM tooling specifics (libvirt vs plain QEMU invocation), disk/memory sizing, how the documented procedure is written.
- install.sh flag names and exact section boundaries; verification-table format; how hardware detection is implemented.
- How the dead-file reference hunt is implemented and what counts as "obviously dead" vs "ambiguous".
- Backup naming conventions for stow.sh/limine guards; ordering of cleanup vs hardening plans.
- Where the CLEAN-02 git-clean assertion lives (theme-doctor vs stress-test vs both).

### Deferred Ideas (OUT OF SCOPE)
- Fully-scripted VM provisioning (archinstall config + libvirt/quickemu automation) — considered for the harness and not chosen (D-54); could become a future convenience if the VM gate is rerun often (noted, unowned).
- None other — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| CLEAN-01 | Dead configs removed — wofi package, `debug.txt`, stray screenshots, other unused files | Pitfall 1 + Pattern 2 give the verified, correct fix for the screenshot root cause (stow-fold exclusion, not path relocation); Runtime State Inventory enumerates every tracked artifact to remove; Don't-Hand-Roll/Anti-Patterns section flags that wofi cleanup must touch `install.sh`, `stow.sh`, `matugen/config.toml`'s orphan template, and `README.md` together (IN-02, D-49) |
| CLEAN-02 | `git status` stays clean after a theme switch (no generated files tracked in the repo) | Runtime State Inventory confirms the 22 currently-tracked screenshot PNGs are the only remaining git-hygiene gap (the two matugen-output files are already gitignored); Architecture Patterns diagram shows where a `git status --porcelain` assertion (D-50) fits in the theme-doctor pipeline |
| INST-01 | `install.sh` installs the correct theming-critical packages and verifies critical packages post-install | Code Examples section gives a reusable `verify_packages()` hard-fail pattern (D-63/D-64/D-65); Common Pitfalls 4/5/6 document three still-unfixed, confirmed-live bugs (orphan-cleanup abort, limine no-backup, chsh prompt) that block a zero-prompt unattended run; Elephant provider root cause (Pitfall 3, Pattern 3) gives the concrete D-66 fix split into two independent sub-fixes |
| INST-02 | `stow.sh` completes successfully on a genuinely fresh system (no unguarded operations that assume existing state) | Pitfall 2 is a direct, empirically-confirmed reproduction of the exact bug named in CONTEXT.md's D-62 (the `hyprland` package ships no default config, so the unguarded `mv` always fails on a real fresh system); Pattern 1 gives the exact guard shape |
| INST-03 | Full `install.sh` + `stow.sh` run verified in a disposable Arch VM/container, producing the fully themed desktop | Standard Stack + Package Legitimacy Audit verify every host-side tool needed for the D-52 hybrid gate is a real, correctly-named official-repo package (and correct one wrong name found: `iptables-nft` does not exist, use `iptables`); Environment Availability documents that none of podman/qemu/libvirt are yet installed on this host — a prerequisite step before Plan 03-02 execution; Security Domain flags the NOPASSWD-sudo scoping risk specific to this unattended verification environment |
</phase_requirements>

## Summary

This phase has an unusually large fraction of its findings **already verified as concrete, reproducible bugs on this exact machine**, not hypothetical risks. Three things stand out from direct investigation that materially change how the planner should scope work:

1. **The screenshot/git-status problem (CLEAN-01/CLEAN-02) has one root cause, not two.** `~/Pictures` is not a real directory — GNU Stow's tree-folding collapsed it into a single symlink to `dotfiles/wallpapers/Pictures` because the `wallpapers` package exclusively owns that subtree. `screenshot.sh` writes to `$HOME/Pictures/Screenshots` in good faith, but because of the fold, every screenshot lands literally inside the git working tree — 22 PNGs are currently tracked. Moving the save path only fixes this if the new path is also taken out of stow's fold; a naive rename to another path still under `~/Pictures` or `~/dotfiles` won't fix anything.
2. **`stow.sh`'s unguarded `mv ~/.config/hypr/hyprland.conf ...` will hard-abort on a genuinely fresh system**, confirmed empirically: the `hyprland` pacman package ships **no** `~/.config/hypr/hyprland.conf` at all (`pacman -Ql hyprland` has zero `.config` entries). On this dev machine the line silently "works" today only because a previous run already replaced that path with a stow-owned symlink — which means the current behavior is itself accidental, not idempotent by design.
3. **The `elephant listproviders` "menus" gap is not a missing-package bug — it's an empty-data gap**, confirmed by direct reproduction: creating one file at `~/.config/elephant/menus/test.toml` makes `elephant listproviders` immediately report `menus:test`. With zero menu definition files (expected in v1, since MENU-01/02/03 are deferred to v2), the provider legitimately has nothing to register. The real defect is in `theme-doctor`'s provider-parity comparison, which checks for the literal string `"menus"` — a string that can never appear (elephant always publishes `menus:<filename>`), so that comparison is structurally unable to pass even once real menus exist. Separately, `elephant-files`/`elephant-providerlist`/`elephant-runner`/`elephant-websearch` are listed in `install.sh` but genuinely **not installed** on this dev machine — confirmed via `pacman -Qs elephant` — even though all four resolve fine via `paru -Si` right now, meaning the fix is "actually run/verify the install," not a broken package name.

A second major finding: the CONTEXT.md decisions reference "hardening the Phase-2 verification tooling's false-pass paths (02-REVIEW CR-01/WR-01)" as in-scope work — but **CR-01 and WR-01, along with WR-02 through WR-05, were already fixed in Phase 2** (commits `46f9361`, `0e2abc7`, `a5af471`, `94eb876`, `56b118a`, `31b7cb7`, confirmed in `02-REVIEW-FIX.md`, status `all_fixed`). Reading the current `theme-parity`/`theme-doctor` source confirms the fixes are live. Phase 3 should treat D-67 as a **verification/regression-guard task** (confirm the fixes still hold, add nothing new unless a gap is found), not a re-implementation task — this meaningfully shrinks Plan 03-02's actual code surface.

**Primary recommendation:** Fix the stow-fold root cause (exclude `Screenshots` from the `wallpapers` package's stow tree entirely, not just relocate the save path within it), guard every state-assuming operation in `stow.sh`/`install.sh` with existence/idempotency checks before restructuring into flagged sections, and scope the elephant-provider "root cause" fix as two separate, already-understood problems (install the four missing packages; fix the string-comparison bug in theme-doctor) rather than one open-ended investigation.

## Architectural Responsibility Map

This is a system-configuration project, not a client/server app — tiers below are adapted to that shape (source repo, package layer, symlink layer, runtime, verification harness) rather than the browser/API/DB template.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dead file/config removal (CLEAN-01) | Git repo (source tree) | — | Pure source-tree operation; no runtime component |
| Generated-file git hygiene (CLEAN-02) | Git repo (source tree) | Runtime (theme-engine state dir) | The invariant is about the repo, but the assertion must run after real runtime theme-apply activity to be meaningful |
| Package installation + verification (INST-01) | Package layer (pacman/AUR) | Runtime (systemd services enabled post-install) | Installing packages and confirming they landed is squarely pacman/AUR's job; service enablement is a runtime handoff |
| Symlink idempotency (INST-02) | Stow (symlink layer) | Package layer (pre-existing real files it must not clobber) | Stow's own domain, but must reason about what the package layer may have already placed on disk |
| Fresh-system reproduction proof (INST-03) | Verification harness (container + VM) | All other tiers | The harness orchestrates and observes every other tier; it doesn't own logic, it proves the others work end-to-end |
| Elephant provider registration | Runtime (elephant daemon + its data dir) | Package layer (elephant-* .so files) | Provider *availability* is package-layer; provider *activation* is runtime and, for `menus`, data-driven (file presence in `~/.config/elephant/menus/`) |

## Standard Stack

This phase does not add application dependencies — it hardens existing bash scripts and adds a verification harness. "Stack" here means the verification tooling to introduce, all installed from Arch's official `extra` repository (no AUR, no npm/pip/cargo — the Package Legitimacy Gate's ecosystem-specific seam does not apply; verified instead via direct `pacman -Si`, the same pattern Phase 1 used for `adw-gtk-theme`).

### Core (verification harness — host-side, Claude's Discretion per D-52/D-53)
| Tool | Repo | Purpose | Why Standard |
|------|------|---------|---------------|
| `podman` | extra (verified `pacman -Si podman` this session) | Rootless container runtime for the fast-iteration Arch container gate | Arch-native, no daemon requirement, matches D-52's "podman/docker" hybrid step; `archlinux/archlinux` is the official upstream image, built via podman itself [CITED: hub.docker.com/r/archlinux/archlinux] |
| `qemu-full` (or `qemu-desktop`) | extra (verified) | Full graphical hypervisor for the INST-03 graphical VM gate | Standard KVM-backed hypervisor on Arch; `qemu-desktop` is the lighter meta-package if a minimal footprint is preferred |
| `libvirt` + `virt-install` | extra (verified) | VM lifecycle management (define/start/snapshot) on top of QEMU/KVM | Standard pairing; `virt-install` gives a scriptable one-shot VM creation command instead of hand-rolling `qemu-system-x86_64` invocations |
| `edk2-ovmf` | extra (verified) | UEFI firmware for the guest VM | Needed if the fresh-Arch procedure uses the official ISO's default UEFI boot path |
| `dnsmasq` | extra (verified) | libvirt's default NAT network (`virbr0`) DHCP/DNS | Standard libvirt dependency for outbound network access inside the VM (needed for `pacman -Syu`/AUR clone during the fresh-install run) |
| `iptables` | core (**already installed** on this host) | libvirt NAT network requires nftables-backed iptables rules | Correction: `iptables-nft` is **not** a real Arch package name (verified: `pacman -Si iptables-nft` fails) — the correct package is plain `iptables`, which uses the nft backend by default on current Arch and is already present |

### Supporting
| Tool | Repo | Purpose | When to Use |
|------|------|---------|-------------|
| `dmidecode` | extra (verified) | Hardware/BIOS introspection | Optional, only if hardware-guard detection (D-58) needs more than `lspci` (e.g. distinguishing VM vs bare metal) |
| `systemd-nspawn` | already present (part of `systemd`) | Lightweight container alternative to podman | Available on this host with zero extra install if `podman`/`docker` is rejected during Claude's Discretion — but D-52 already named podman/docker explicitly; nspawn requires root and is less isolated, so podman/docker remains the better default |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| podman (container gate) | docker | Docker requires a root daemon; podman is rootless and Arch-native — prefer podman unless the user has an existing docker workflow. Both are officially packaged. |
| qemu + libvirt (graphical VM) | GNOME Boxes / quickemu | Both are thinner wrappers over the same QEMU/KVM stack; libvirt + virt-install gives the most scriptable path for the D-54 "documented step-by-step procedure," which is why it's preferred here — but this is explicitly Claude's Discretion (D-52) |
| virtio-gpu | QXL/SPICE | virtio-gpu gives smoother/accelerated Wayland rendering on Linux guests and is the modern default; QXL/SPICE is the documented fallback if virtio-gpu has display issues on the specific host GPU driver [CITED: wiki.archlinux.org/title/QEMU/Guest_graphics_acceleration] |

**Installation (host machine, before the VM gate can run — none of these are currently installed, see Environment Availability below):**
```bash
sudo pacman -S --needed podman qemu-full libvirt virt-install edk2-ovmf dnsmasq
sudo systemctl enable --now libvirtd.socket
sudo usermod -aG libvirt "$USER"   # then re-login for group membership to take effect
```

**Version verification:** All six package names above were verified to resolve in the official `extra` repository via `pacman -Si <pkg>` directly on this machine this session (not web-search-only). `iptables-nft` was checked and confirmed **not to exist** under that name — `iptables` is correct and already installed.

## Package Legitimacy Audit

No new npm/PyPI/crates packages are introduced by this phase. The only new installs are Arch official-repo packages for the verification harness (table above), verified directly via `pacman -Si` on this machine rather than the npm/pypi/crates-specific legitimacy seam (which does not cover pacman). This mirrors the precedent set in Phase 1 for `adw-gtk-theme` (Package Legitimacy Audit verdict `OK`, official repo, not AUR).

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| podman, qemu-full, libvirt, virt-install, edk2-ovmf, dnsmasq | pacman `extra` | OK (verified via `pacman -Si` this session) | Approved |
| iptables-nft | — | **does not exist** | Do not reference; use `iptables` (already installed) |

**Packages removed due to SLOP verdict:** none.
**Packages flagged as suspicious (SUS):** none — all are mainstream official-repo Arch packages already widely used for this exact purpose.

## Architecture Patterns

### System Architecture Diagram

```
                     ┌─────────────────────────────────────────┐
                     │  git repo (source of truth, this phase)  │
                     │  install.sh · stow.sh · package dirs     │
                     └───────────────┬───────────────────────────┘
                                     │ git clone (D-56, real remote)
                                     ▼
        ┌─────────────────────────────────────────────────────────┐
        │  Fresh environment (container OR VM, D-52 hybrid)         │
        │                                                             │
        │  1. install.sh --core-only  ─────► pacman/AUR package layer│
        │       │                              (hardware-guarded,    │
        │       │                               D-58; hard-fail      │
        │       ▼                               verify, D-63/D-64)   │
        │  2. post-install verification table ──► pass/fail table    │
        │       │ (exit nonzero on any missing pkg — D-64/D-65)      │
        │       ▼                                                     │
        │  3. stow.sh  ───────────────► symlink layer (idempotent,   │
        │       │                        guarded ops — D-62)         │
        │       ▼                                                     │
        │  4. first-boot seed: theme-apply catppuccin (D-60)         │
        │       │                                                     │
        │       ▼                                                     │
        │  5a. [container] theme-doctor + theme-parity  ─────────────┤──► machine-readable logs
        │      (render/health checks, no Hyprland session)           │    (D-45, D-53 evidence)
        │                                                             │
        │  5b. [VM only] Hyprland actually starts (uwsm) ────────────┤──► human visual confirm
        │      → walker/elephant/waybar/swaync/Thunar live            │    (D-53, non-negotiable)
        └─────────────────────────────────────────────────────────┘
```

### Recommended Project Structure (additions only — no existing structure changes needed)
```
dotfiles/
├── install.sh                      # restructured: sections + flags (D-57), hardware guards (D-58),
│                                    #   zero-prompt (D-59), post-install verify table (D-63)
├── stow.sh                         # hardened: guarded mv, guarded chsh, idempotent re-run (D-62)
├── verify/                         # NEW — Claude's Discretion for exact name/location (D-52)
│   ├── container-run.sh            # keeper artifact: podman run archlinux/archlinux + install.sh
│   │                                #   --core-only + stow.sh + theme-doctor/theme-parity (D-54)
│   └── VM-PROCEDURE.md-section      # documented (not automated) steps, folded into VERIFICATION.md (D-54)
└── theme-engine/.config/theme-engine/
    └── theme-doctor                # add: git status --porcelain assertion (D-50), fix menus-provider
                                     #   string comparison (see Pitfall 3 below)
```

### Pattern 1: Guard-before-mutate for every state-assuming shell operation
**What:** Before any operation that assumes prior state exists (`mv`, `rm`, `chsh`), check for that state's existence/type first, and branch accordingly instead of letting `set -e` abort the whole script.
**When to use:** Every line in `stow.sh`/`install.sh` identified in the Common Pitfalls section below.
**Example (fixing the confirmed hyprland.conf abort):**
```bash
# Source: verified empirically this session — `pacman -Ql hyprland` ships no
# ~/.config/hypr/hyprland.conf, so a fresh system has nothing to move.
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPR_BAK="$HOME/.config/hyprland.conf.bak"
if [[ -e "$HYPR_CONF" && ! -L "$HYPR_CONF" ]]; then
    # Only back up a REAL pre-existing file, never an already-stow-owned symlink
    # (backing up a symlink to our own repo file is pointless churn, observed
    # on this dev machine where hyprland.conf.bak is itself a stray symlink).
    mv "$HYPR_CONF" "$HYPR_BAK"
fi
```

### Pattern 2: Exclude non-stowable data directories from tree-folding, don't just relocate within them
**What:** When a stow package's subtree must contain both stowable dotfiles AND a directory that receives live runtime writes (screenshots, caches, logs), exclude the runtime-write directory from the package via `.stow-local-ignore` (or move it out of the package tree entirely) rather than trusting a plain path relocation.
**When to use:** D-48's screenshot fix.
**Example:**
```bash
# .stow-local-ignore (package-scoped patterns match relative to each package dir)
# Prevents `wallpapers` package from ever tree-folding ~/Pictures/Screenshots
# into a repo-backed symlink — this is the actual fix, not just changing
# SCREENSHOT_DIR in screenshot.sh.
^Pictures/Screenshots$
```
Then in the repo: `git rm -r wallpapers/Pictures/Screenshots/` (delete the 22 tracked PNGs), add `wallpapers/Pictures/Screenshots/` (or the new external path, if moved fully outside `~/Pictures`) to `.gitignore` as belt-and-suspenders per D-48, and re-run `stow --restow wallpapers` to confirm `~/Pictures` becomes a **real** directory containing a `Wallpapers` symlink (tree-fold no longer includes `Screenshots`) — verify with `stow -n wallpapers` (dry run) and `ls -la ~/Pictures`.

### Pattern 3: Compare provider identities correctly when a provider's registered name is dynamic
**What:** `elephant listproviders` publishes `menus` entries as `menus:<filename>` (data-driven, one entry per file in `~/.config/elephant/menus/`), never the bare string `menus`. Any comparison against walker's `config.toml` (which references the bare string `"menus"`) must account for this prefix relationship, not exact-match it.
**When to use:** Fixing `theme-doctor`'s provider-parity check (the current source of the accepted, now-to-be-removed gap per D-66).
**Example:**
```bash
# theme-doctor's existing MISSING loop (current shape, lib inline) — the fix
# is a prefix-aware match for the "menus" configured-provider case only,
# since menus is the one provider elephant registers as "menus:<name>" data-
# driven, confirmed by direct reproduction this session (creating one file
# under ~/.config/elephant/menus/ made "menus:test" appear in listproviders
# immediately, with zero elephant restart required).
for p in $CONFIGURED_PROVIDERS; do
    if [[ "$p" == "menus" ]]; then
        printf '%s\n' "$ACTIVE_PROVIDERS" | grep -q '^menus:' && continue
    elif printf '%s\n' "$ACTIVE_PROVIDERS" | grep -qx "$p"; then
        continue
    fi
    MISSING="$MISSING $p"
done
```
This still correctly reports a gap if literally zero menu files exist and the phase's decision is that a seeded placeholder menu is required — see Open Questions.

### Anti-Patterns to Avoid
- **Deleting/moving files without checking `contract.json`, `.stow-local-ignore`, `.gitignore`, and matugen `config.toml` for stale references simultaneously:** the wofi cleanup touches all four (PACMAN_PKGS in install.sh, PACKAGES in stow.sh, the orphaned `wofi-colors.css` template not in `config.toml`, and README.md) — a partial cleanup leaves silent dangling references, exactly the class of bug IN-02 already flagged once.
- **Treating "install.sh exits 0" as proof of correctness:** AUDIT.md finding #21 (still unfixed) documents that `paru -Sy --needed --noconfirm` exits 0 even when individual AUR packages silently fail — confirmed still true today (`elephant-files`/`elephant-providerlist`/`elephant-runner`/`elephant-websearch` are all listed in `install.sh` but absent from `pacman -Qs elephant` on this machine right now).
- **Re-running `theme-doctor`'s elephant-provider check without first understanding it's testing two independent things** (package presence vs. runtime provider activation) — conflating them will misdiagnose the fix.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting whether an AUR/pacman package actually landed | A custom "did pacman print success" text-scrape of install output | `pacman -Q <pkg>` post-install, exit-code checked (exactly what `theme-doctor` already does for `adw-gtk-theme`) | `pacman -Q` is the canonical, race-free source of truth for "is this package actually registered in the local DB" — matches the existing, already-proven pattern in this repo |
| Unattended fresh Arch base install for VM testing | A hand-rolled `pacstrap`/`arch-chroot` script from scratch | `archinstall` with a JSON config (`user_configuration.json` + `user_credentials.json`) | archinstall is the official Arch installer with a documented unattended/scripted mode; hand-rolling `pacstrap` reimplements partitioning/mirrorlist/bootloader logic archinstall already solves [CITED: archinstall docs] |
| Detecting an NVIDIA GPU to gate package installs | Parsing `nvidia-smi` output (not present pre-driver-install, chicken-and-egg) | `lspci \| grep -i nvidia` (works pre-driver, standard pattern used by e.g. ollama's installer) | `lspci` reads PCI device IDs directly from the kernel/hardware database — works before any GPU driver is installed, which `nvidia-smi` cannot |
| Container-based Arch package-install testing | A custom minimal rootfs built by hand | `archlinux/archlinux` official Docker/OCI image (also has a `repro`/reproducible variant) | Officially maintained, built via the same Podman-based CI Arch uses for its own releases — matches the actual target environment far more closely than a hand-assembled rootfs |

**Key insight:** Every "Don't Hand-Roll" item above has an off-the-shelf primitive maintained by the actual upstream (pacman, archinstall, Arch's own Docker image) — the temptation in an install-script-hardening phase is to write more bespoke bash, but the fixes needed here are almost all *guards around existing calls*, not new logic.

## Runtime State Inventory

This phase is a hybrid rename/cleanup + fresh-install phase, so this inventory is in scope.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | 22 screenshot PNGs currently `git ls-files`-tracked under `wallpapers/Pictures/Screenshots/` (confirmed count via `git ls-files \| wc -l`) — these are real runtime-generated files, not source | **Data migration**: `git rm -r` the tracked screenshots (they are user data, not repo content — do not re-add elsewhere in the repo); **code edit**: fix the stow-fold root cause (Pattern 2) so future screenshots never re-enter git |
| Live service config | None found — no n8n/Datadog/Cloudflare-Tunnel-style external services in this project; the closest analogue is the running `elephant` process (PID confirmed alive since 2026-07-06, well after all elephant-* packages except the four missing ones were installed) whose provider set is entirely file/package-driven, not a remote-configured service | None beyond installing the missing elephant-* packages and (optionally) seeding a menu file — see Open Questions |
| OS-registered state | `~/.config/hyprland.conf.bak` on this dev machine is itself a stow-owned symlink (not a real backup) — a side effect of the current unguarded `mv`, confirmed via `ls -la` (`-> ../../dotfiles/hypr/.config/hypr/hyprland.conf`); no systemd unit files, Task Scheduler equivalents, or pm2-style registrations exist in this project | **Code edit only**: Pattern 1's guard prevents this decoy `.bak` symlink from being (re)created; the existing stray one on this dev machine should be cleaned up manually as part of verifying the fix, not left in place |
| Secrets/env vars | None found — no SOPS, no `.env` outside git, no CI secrets referenced anywhere in `install.sh`/`stow.sh`/`theme-engine/` (grepped for common patterns; git identity and timezone in `install.sh` are plaintext personal config, not secrets, and are explicitly moving to the D-61 personal section) | None |
| Build artifacts / installed packages | `~/.cache/elephant/*.gob` (clipboard/desktopapplications history caches) exist and are unrelated to the provider-registration gap (confirmed: these are query-history caches, not provider config); no stale `egg-info`/compiled-binary equivalents exist in this bash-only project | None — these caches are expected runtime state, not stale artifacts |

**Canonical question answered:** After every file in the repo is updated for this phase, the only runtime system still holding old-string/old-path state is git itself (the 22 tracked screenshot files) and the one decoy `.bak` symlink on this specific dev machine — both are one-time cleanups, not ongoing migrations.

## Common Pitfalls

### Pitfall 1: Fixing the screenshot save path without fixing the stow fold
**What goes wrong:** Changing `SCREENSHOT_DIR` in `screenshot.sh` to a different subdirectory still under `~/Pictures` (or anywhere else stow currently owns) reproduces the exact same bug under a new name — the fix must remove `Screenshots` from what stow tree-folds, not just change where inside the fold it points.
**Why it happens:** GNU Stow's tree-folding is invisible unless you inspect `readlink -f ~/Pictures` — the symptom (screenshots ending up in git) looks like a hardcoded-repo-path bug, but the actual cause is a symlink fold three layers up.
**How to avoid:** Verify the fix with `readlink -f ~/Pictures/Screenshots` post-fix — it must NOT resolve into `dotfiles/`. Confirmed working pattern: exclude `Pictures/Screenshots` from the `wallpapers` stow package via `.stow-local-ignore` (Pattern 2).
**Warning signs:** `git status` still dirty after a screenshot is taken; `ls -la ~/Pictures` shows a single symlink rather than a real directory with per-item symlinks inside.

### Pitfall 2: `stow.sh`'s `mv ~/.config/hypr/hyprland.conf` aborts on a fresh system — confirmed, not hypothetical
**What goes wrong:** On a genuinely fresh Arch install, `~/.config/hypr/hyprland.conf` does not exist (the `hyprland` package ships no default config there — verified via `pacman -Ql hyprland`), so the bare `mv` fails and, under `set -euo pipefail`, aborts `stow.sh` before a single package is stowed.
**Why it happens:** The line was written assuming a prior install (X11 or a different rice) always leaves a stock config behind — true on this dev machine's history, false for the INST-03 fresh-system target.
**How to avoid:** Guard with `[[ -e ... && ! -L ... ]]` before the `mv` (Pattern 1); only back up real, non-symlink files.
**Warning signs:** `stow.sh` output stops immediately after the banner with no `Stowing: fastfetch` line ever printing.

### Pitfall 3: Treating the elephant "menus" gap as a single bug when it's two independent ones
**What goes wrong:** Spending investigation time trying to figure out why an *installed* `elephant-menus` package "fails" to register, when the actual behavior (confirmed by direct reproduction) is that it correctly reports zero providers because zero menu files exist — a correct, by-design response, not a bug.
**Why it happens:** `theme-doctor`'s current comparison logic treats "provider absent from `elephant listproviders`" as one undifferentiated failure mode, conflating "package not installed" (files/providerlist/runner/websearch — genuinely missing packages) with "package installed, zero data to serve" (menus — a comparison-logic bug, not an install bug).
**How to avoid:** Split D-66 into two explicit sub-fixes: (a) install the four genuinely-missing elephant-* packages and confirm via `pacman -Qs elephant`, (b) fix the `theme-doctor` comparison to use prefix matching for `menus:*` (Pattern 3) rather than exact string equality. Decide explicitly (Open Question below) whether v1 also needs a seeded placeholder menu file, given MENU-01/02/03 are v2-deferred.
**Warning signs:** `elephant listproviders` genuinely returns `menus:<something>` once any menu file exists, but `theme-doctor`'s exact-string check still reports a `[FAIL]`.

### Pitfall 4: `paru -R "$(pacman -Qtdq)"` aborts the installer on the single most common case
**What goes wrong:** On a fresh install (the target of INST-03), there are zero orphaned packages, so `pacman -Qtdq` prints nothing and `paru -R ""` fails — under `set -e`, this kills `install.sh` before any post-install task runs (VSCodium extensions, audio services, git config, dbus-broker, the entire limine bootloader update, timezone).
**Why it happens:** The line assumes orphans always exist; a fresh install is the one scenario where that's guaranteed false.
**How to avoid:** `mapfile -t ORPHANS < <(pacman -Qtdq || true); (( ${#ORPHANS[@]} > 0 )) && paru -R "${ORPHANS[@]}"` — array expansion (not a quoted string) also fixes the separate multi-orphan bug in the same line.
**Warning signs:** `install.sh` output stops right after "Removing unused packages and clearing cache..." with no further post-install banner.

### Pitfall 5: `sudo rm /boot/limine/limine.conf` with no backup, no `-f`
**What goes wrong:** Confirmed still present in `install.sh` unchanged — this line has genuine unbootable-system potential: it deletes the live bootloader config before `limine-install`/`limine-update` have proven they'll succeed, and a bare `rm` (no `-f`) aborts the whole script under `set -e` on any re-run where the file is already gone.
**Why it happens:** Written as a "clean slate" step without considering re-run or failure-between-steps scenarios.
**How to avoid:** `[[ -f /boot/limine/limine.conf ]] && sudo cp /boot/limine/limine.conf /boot/limine/limine.conf.bak; sudo rm -f /boot/limine/limine.conf` (matches D-58's "backed up, never rm'd" requirement).
**Warning signs:** Not observable until a `limine-install`/`limine-update` failure leaves the VM/machine with no boot entry at all — this is the one pitfall in the whole phase where the failure mode is catastrophic rather than merely a stalled script, so it deserves priority even though it's a Phase-1-flagged, not phase-3-required-criteria item.

### Pitfall 6: `chsh -s $(which zsh)` breaks the D-59 zero-prompt requirement
**What goes wrong:** `chsh` run as the invoking (non-root) user prompts for that user's login password via PAM on most Arch configurations — this is a hard blocker for D-59's "strictly zero prompts" requirement inside the unattended VM/container gate.
**Why it happens:** `chsh`'s default PAM stack requires authentication for a user changing their own shell, distinct from `sudo`-gated operations. [ASSUMED — standard, well-documented Unix/PAM behavior, not empirically re-tested this session since doing so would mutate this dev machine's login shell]
**How to avoid:** Use `sudo chsh -s "$(which zsh)" "$USER"` or `sudo usermod -s "$(which zsh)" "$USER"` instead — both are root-privileged operations that don't trigger the user-password PAM prompt, consistent with the NOPASSWD-sudo verification environment (D-59).
**Warning signs:** The VM/container gate hangs indefinitely at the `chsh` line with no visible output (a password prompt on a non-interactive/headless run).

## Code Examples

### Verifying the stow fold on this exact repo (reproducible check for the planner/verifier to reuse)
```bash
# Confirms/denies Pitfall 1 after a fix — must show a REAL directory once fixed,
# not a symlink into dotfiles/.
readlink -f "$HOME/Pictures"                 # today: dotfiles/wallpapers/Pictures (bug)
readlink -f "$HOME/Pictures/Screenshots" 2>&1 # today: resolves into the repo (bug)
stow -n wallpapers 2>&1                        # dry-run, inspect what would (re)fold
```

### Post-install verification table pattern (D-63/D-64/D-65 — hard-fail on every listed package)
```bash
# Source: pattern already proven in theme-doctor's check()/PASS/FAIL accumulator
# (theme-engine/.config/theme-engine/theme-doctor) — reused shape, not reinvented.
verify_packages() {
    local -n pkgs_ref="$1"   # nameref to the exact array that was installed this run
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

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Manual X11-era Arch install walkthroughs (partition by hand, `pacstrap`, manual fstab) | `archinstall` with a JSON config for scripted/unattended installs | archinstall has shipped a documented unattended JSON-config mode for several releases; current stable series is 2.x/3.x per its docs | Directly enables D-55's "minimal archinstall from the official ISO" baseline without hand-rolling partitioning/bootloader logic |
| QXL/SPICE as the default VM display for Linux guests | virtio-gpu (optionally with `rutabaga_gfx`/gfxstream for GL/Vulkan passthrough) as the modern default for Wayland compositor testing | virtio-gpu has been mature since Linux 4.4 / QEMU 2.6; it is now the generally-recommended default for Linux guests over QXL | Matters directly for D-52/D-53's graphical VM gate — Hyprland (a Wayland compositor) needs a GPU device the guest kernel can actually drive; QXL/SPICE remains the documented fallback only if virtio-gpu misbehaves on the specific host |

**Deprecated/outdated:**
- Assuming `adw-gtk3` is a real AUR package name (already fixed in Phase 1; mentioned here only because `install.sh`'s AUR/pacman categorization still has one leftover miscategorization — `swaync` is listed under `AUR_PKGS` but has lived in the official `extra` repo since at least this session's `pacman -Si swaync` check; flagged as IN-11 in `01-REVIEW.md`, unfixed).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `chsh` (non-root) prompts for the invoking user's password via PAM, blocking D-59's zero-prompt requirement | Pitfall 6 | Low — even if untrue on some PAM configs, `sudo chsh`/`usermod -s` is a strictly safer choice anyway and costs nothing to adopt regardless |
| A2 | virtio-gpu is the right default GPU device for the INST-03 graphical VM gate (vs. QXL/SPICE) | Standard Stack, State of the Art | Low-medium — if virtio-gpu has driver issues on the specific host's KVM/QEMU version, the documented fallback (QXL/SPICE) is a straightforward swap; this is explicitly Claude's Discretion per D-52 |
| A3 | `podman` is preferable to `docker` for the container-gate script | Standard Stack | Low — both are officially packaged and D-52 leaves the choice to Claude's Discretion; podman's rootless-by-default model fits an unattended-verification use case slightly better but docker works equally well |
| A4 | archinstall's unattended JSON-config mode is the right way to build the "genuinely fresh Arch" VM baseline (vs. a fully manual ISO walkthrough) | Don't Hand-Roll, State of the Art | Low — D-54 already scopes VM provisioning as "documented, not automated," so this only affects how repeatable the documented procedure is, not correctness of the phase's actual deliverables |

**All other claims in this research were verified directly on this repo/machine this session** (stow fold behavior, the hyprland.conf abort, the elephant menus reproduction, the four missing elephant-* packages, the still-unfixed AUDIT/REVIEW findings, the already-fixed Phase-2 CR-01/WR-01..05, package name resolution via `pacman -Si`) — no user confirmation needed for those.

## Open Questions

1. **Should Phase 3 seed a placeholder menu file so `elephant-menus` always registers, or accept "zero menus until v2" as correct?**
   - What we know: The provider registers correctly and immediately once any file exists in `~/.config/elephant/menus/` (reproduced this session); MENU-01/02/03 (actual menu content) are explicitly deferred to v2 per REQUIREMENTS.md.
   - What's unclear: Whether D-66's "root-caused and fixed so all installed providers register" means literally every installed provider must show *some* active entry (implying a placeholder menu is in scope for Phase 3), or whether it only means the comparison logic must stop reporting a false gap for the legitimately-empty case.
   - Recommendation: Treat this as a planning-time decision, not a research one — the cheapest correct interpretation is Pattern 3's prefix-aware fix (no placeholder menu needed, matches "zero menus in v1 is not a bug"), but confirm with the user during planning if D-66's intent was stricter.

2. **Should `elephant-providerlist`'s "silent AUR failure" symptom (AUDIT finding #20) be re-investigated, or is "was simply never (re)installed" sufficient?**
   - What we know: All four missing elephant-* packages (`files`, `providerlist`, `runner`, `websearch`) resolve cleanly via `paru -Si` right now — there is no current evidence of an actual AUR resolution failure, only that they are absent from `pacman -Qs elephant` on this dev machine.
   - What's unclear: Whether the original "silent install failure" symptom (recorded in Phase 1) was a real paru/AUR transient failure that could recur, or simply that `install.sh` was never re-run on this machine after these lines were added.
   - Recommendation: Phase 3's new hard-fail post-install verification table (D-63/D-64) makes this moot going forward regardless of root cause — any future silent failure becomes a loud, blocking exit. No further investigation needed before planning.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| `podman` | Container fast-iteration gate (D-52) | ✗ | — | Install via `pacman -S podman` (official repo, no fallback needed — trivial install) |
| `docker` | Alternative to podman (Claude's Discretion) | ✗ | — | Use podman instead (preferred default) |
| `qemu-full`/`qemu-desktop` | Graphical VM gate (D-52/D-53) | ✗ | — | Install via `pacman -S qemu-full` — no viable fallback for the graphical-VM human-visual-check requirement (D-53 is non-negotiable per CONTEXT.md) |
| `libvirt` + `virt-install` | VM lifecycle scripting | ✗ | — | Could hand-roll raw `qemu-system-x86_64` invocations instead, but libvirt is strongly preferred for the documented, repeatable procedure D-54 requires |
| `edk2-ovmf` | UEFI boot for the guest VM | ✗ | — | Install via pacman; BIOS/SeaBIOS boot is a fallback if the Arch ISO's install path doesn't require UEFI, but UEFI is the modern default |
| `dnsmasq` | libvirt default NAT network | ✗ | — | Install via pacman; required for the VM to reach the network during a real `pacman -Syu`/AUR clone |
| `iptables` | libvirt NAT network rules | ✓ | (already installed, `core` repo) | — |
| `systemd-nspawn` | Lightweight container alternative | ✓ | (ships with `systemd`, already installed) | Not the chosen default (D-52 named podman/docker) but available with zero install if needed |
| `archinstall` (on the Arch ISO, not this host) | Building the D-55 "genuinely fresh Arch" VM baseline | N/A (runs inside the guest ISO boot, not on this host) | — | — |

**Missing dependencies with no fallback:**
- `qemu-full`/`qemu-desktop` — required for D-53's non-negotiable human-visual-confirmation VM gate; must be installed on this host before Plan 03-02's verification work can begin.

**Missing dependencies with fallback:**
- `podman`/`docker` — trivial `pacman -S` install, no real risk.
- `libvirt`/`virt-install` — could be replaced by raw `qemu-system-x86_64` scripting, at the cost of a less-scriptable/repeatable documented procedure.

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1` per `.planning/config.json`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | No auth surface in this phase — install/stow scripts, no login system |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes | The D-59 "strictly zero prompts" verification environment requires passwordless (`NOPASSWD`) sudo — this must be scoped to the throwaway VM/container only (a dedicated `visudo` drop-in for the verification user), never applied to the real dev machine or committed into any repo file that could accidentally be reused outside the disposable environment |
| V5 Input Validation | Yes | Already-established pattern in this repo (theme-apply/theme-parity/theme-stress-test validate theme-name arguments against actual palette filenames before path interpolation, per T-02-04/Security Domain V5 precedent in Phase 2) — any new argument-accepting script this phase adds (e.g. an `install.sh --core-only` flag parser) must reject unknown flags loudly, not silently ignore them |
| V6 Cryptography | No direct crypto, but supply-chain-adjacent | Package integrity is delegated entirely to pacman/AUR's own GPG signature verification (pacman keyring) — this phase does not introduce any custom download/verification logic, so no hand-rolled crypto risk exists |

### Known Threat Patterns for install/stow bash scripting

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| Blanket `NOPASSWD: ALL` sudoers entry left active beyond the disposable VM/container | Elevation of Privilege | Scope the sudoers drop-in narrowly (or, better, only ever apply it inside a VM/container snapshot that is discarded after the run) — document this explicitly in the VM procedure (D-54) so a future reader doesn't copy the NOPASSWD line onto a persistent machine |
| A partially-completed install/stow run (aborted mid-way by one of the confirmed Pitfalls above) leaves the system in an inconsistent, hard-to-diagnose state | Denial of Service (of the setup process itself) | Every guard fix in this research (Pitfalls 1-6) directly mitigates this — idempotent, existence-checked operations mean a re-run always converges to the same end state rather than compounding partial failures |
| AUR package supply-chain risk (any new elephant-*/AUR package this phase touches) | Tampering | Already the established pattern from Phase 1 (T-01-SC): verify via `paru -Si`/`pacman -Si` before adding/re-confirming any package name; official-repo packages preferred over AUR wherever available (this research found one more instance — `swaync`, IN-11 — that should move from `AUR_PKGS` to `PACMAN_PKGS` while `install.sh` is being restructured anyway) |

## Sources

### Primary (HIGH confidence — direct verification on this repo/machine this session)
- `readlink -f ~/Pictures`, `git ls-files wallpapers/Pictures/Screenshots \| wc -l` — confirmed the stow-fold root cause and 22 tracked screenshots
- `pacman -Ql hyprland`, `ls -la ~/.config/hyprland.conf.bak` — confirmed the fresh-system `mv` abort and the decoy symlink on this dev machine
- `elephant listproviders` before/after creating `~/.config/elephant/menus/test.toml` — confirmed the menus provider is data-driven, not broken (test artifact created and removed within this session)
- `pacman -Qs elephant` vs. `install.sh` AUR_PKGS — confirmed 4 packages genuinely absent; `paru -Si elephant-files elephant-providerlist elephant-runner elephant-websearch` — confirmed all 4 resolve on AUR right now
- `pacman -Si podman qemu-full qemu-desktop libvirt virt-install dnsmasq edk2-ovmf iptables-nft dmidecode` — confirmed exact package names/repos; `iptables-nft` confirmed **not** a real package
- `git log --oneline -- theme-engine/.config/theme-engine/theme-parity theme-doctor lib/contract.sh` + reading `02-REVIEW-FIX.md` — confirmed CR-01/WR-01..05 already fixed in Phase 2
- `pacman -Si swaync` — confirmed IN-11 (swaync mislisted under AUR_PKGS) is still live/unfixed
- Direct read of `install.sh`, `stow.sh`, `.gitignore`, `.stow-local-ignore`, `README.md`, `screenshot.sh`, `theme-doctor`, `theme-parity`, `theme-stress-test`, `lib/commit.sh`, `matugen/config.toml`, `01-REVIEW.md`, `01-AUDIT.md`, `02-REVIEW.md`, `02-REVIEW-FIX.md`

### Secondary (MEDIUM confidence — WebSearch corroborated against official docs)
- [GNU Stow manual — Installing Packages](https://www.gnu.org/software/stow/manual/html_node/Installing-Packages.html) — tree-folding behavior (corroborates the direct empirical finding above)
- [archlinux/archlinux Docker image](https://hub.docker.com/r/archlinux/archlinux) — official reproducible container base image

### Tertiary (LOW confidence — WebSearch only, not independently corroborated)
- QEMU/libvirt virtio-gpu setup specifics (exact flags not retrieved — Hyprland Wiki and ArchWiki pages returned bot-protected/JS-rendered content this session; general guidance corroborated by multiple independent search results but no single authoritative source fetched)
- archinstall unattended JSON config exact schema (general shape confirmed via search snippets, not fetched from the primary docs page)
- `chsh` PAM password-prompt behavior (Assumption A1 — standard, well-known Unix behavior, not re-verified empirically this session to avoid mutating this dev machine's login shell)

## Metadata

**Confidence breakdown:**
- Repo-cleanup findings (CLEAN-01/CLEAN-02, stow fold, tracked screenshots, README drift): HIGH — all verified directly against this repo and this dev machine
- Install/stow hardening findings (INST-01/INST-02, all 6 pitfalls): HIGH — every cited bug was either reproduced empirically or confirmed still-present by reading the current, unmodified source
- Elephant provider root cause (D-66): HIGH — reproduced with a real test file and reverted cleanly
- Phase-2 tooling status (D-67): HIGH — confirmed via git log and 02-REVIEW-FIX.md, not re-derived from scratch
- VM/container verification harness specifics (INST-03 tooling): MEDIUM/LOW — package names and repos are HIGH confidence (directly verified), but exact QEMU/virt-install flag syntax and the archinstall JSON schema are LOW confidence (WebSearch snippets only, no primary source successfully fetched) — flag for the planner to verify flag syntax against `man virt-install`/`man qemu-system-x86_64` during Plan 03-02

**Research date:** 2026-07-08
**Valid until:** 30 days (this is a stable, mature toolchain — Arch pacman/AUR mechanics, GNU Stow, and QEMU/libvirt do not churn quickly; re-verify package names if this research is reused after a significant delay)
