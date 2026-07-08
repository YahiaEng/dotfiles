# Phase 3: Repo Cleanup & Fresh-Install Reproducibility - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-08
**Phase:** 3-Repo Cleanup & Fresh-Install Reproducibility
**Areas discussed:** Cleanup scope, Verification env, Unattended policy, Post-install checks

---

## Cleanup scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full sweep (Recommended) | Named three + all catalogued dead items (wofi refs, wofi-colors.css, phantom scripts entry, retired Phase-1 scripts) | |
| Minimal (named three only) | Only wofi package, debug.txt, screenshots | |
| Sweep + active hunt | Full sweep plus a reference-based dead-file audit across all packages | ✓ |

**User's choice:** Sweep + active hunt

| Option | Description | Selected |
|--------|-------------|----------|
| Relocate save path (Recommended) | screenshot.sh saves outside the repo; delete repo copies; gitignore path | ✓ |
| Delete + gitignore | Delete existing, gitignore the in-repo path | |
| Keep on disk, gitignore only | Leave files, ignore in git | |

**User's choice:** Relocate save path

| Option | Description | Selected |
|--------|-------------|----------|
| List, then confirm (Recommended) | Obvious dead removed directly; ambiguous batched into one confirmation checkpoint | ✓ |
| Delete everything unreferenced | Trust the reference analysis fully | |
| Ambiguous → wontfix note | Only remove certain cases; document the rest | |

**User's choice:** List, then confirm

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, align docs (Recommended) | Update README.md and in-repo references to removed files | ✓ |
| Code only | Leave prose docs alone | |

**User's choice:** Yes, align docs

| Option | Description | Selected |
|--------|-------------|----------|
| Verify + scripted check (Recommended) | Assert git clean after switch and add as permanent check | ✓ |
| One-time verification | Document in VERIFICATION.md only | |
| You decide | Claude picks during planning | |

**User's choice:** Verify + scripted check

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, include both (Recommended) | .vscode/ as hunt candidate; prune stale .stow-local-ignore entries | ✓ |
| Only stale ignore entries | Leave .vscode/ alone | |
| Leave both | Skip both | |

**User's choice:** Yes, include both

---

## Verification env

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid (Recommended) | Container iteration + one graphical VM final gate | ✓ |
| Full VM only | Everything in a graphical VM | |
| Container only | Accept container evidence as the reproduction proof | |

**User's choice:** Hybrid

| Option | Description | Selected |
|--------|-------------|----------|
| Tool logs + human eyes (Recommended) | theme-doctor/theme-parity green in VM + user visually confirms VM desktop | ✓ |
| Automated only | Headless assertions + grim screenshot | |
| Human eyes only | Visual check with no machine evidence | |

**User's choice:** Tool logs + human eyes

| Option | Description | Selected |
|--------|-------------|----------|
| Container script keeper, VM documented (Recommended) | Container run script in repo; VM procedure documented, not automated | ✓ |
| Both fully scripted | Also automate VM provisioning | |
| Nothing kept | One-off procedures | |

**User's choice:** Container script keeper, VM documented

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal archinstall (Recommended) | Base + networkmanager + sudo user from official ISO | ✓ |
| Arch cloud image | Official prebuilt qcow2 | |
| You decide | Claude picks a genuinely fresh baseline | |

**User's choice:** Minimal archinstall

| Option | Description | Selected |
|--------|-------------|----------|
| git clone from remote (Recommended) | Clone from GitHub inside the fresh environment | ✓ |
| Copy from host | Mount/scp the working tree | |
| Clone for gate, copy for iteration | Copy in container, clone in VM | |

**User's choice:** git clone from remote

---

## Unattended policy

| Option | Description | Selected |
|--------|-------------|----------|
| Sections + flags (Recommended) | Named groups with flags like --core-only | ✓ |
| Guards, keep monolithic | Detection guards in one linear script | |
| Split into separate scripts | install-core.sh + install-host.sh | |

**User's choice:** Sections + flags

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, detect + guard (Recommended) | NVIDIA/limine detection on top of flags; limine config backed up (WR-08) | ✓ |
| Flags only | Steps run unconditionally when selected | |

**User's choice:** Yes, detect + guard

| Option | Description | Selected |
|--------|-------------|----------|
| One sudo up front, guard chsh (Recommended) | Single sudo auth accepted; chsh non-blocking | |
| Strictly zero prompts | NOPASSWD sudo in verification env; every interactive step removed | ✓ |
| Prompts acceptable | Only decisions must be eliminated | |

**User's choice:** Strictly zero prompts (stricter than recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Fully idempotent (Recommended) | Fresh-safe AND re-run-safe; guards + backups everywhere | ✓ |
| Fresh-run guards only | Guard only fresh-run breakers | |
| You decide | Claude picks the bar | |

**User's choice:** Fully idempotent

| Option | Description | Selected |
|--------|-------------|----------|
| Seed at install time (Recommended) | theme-apply catppuccin post-stow (WR-07 fix) | ✓ |
| Ship pre-rendered defaults | Commit a default state dir | |
| Accept transient first-boot errors | Keep relying on login-time theme-init | |

**User's choice:** Seed at install time

| Option | Description | Selected |
|--------|-------------|----------|
| Personal section, skippable (Recommended) | git identity/timezone in the section --core-only skips | ✓ |
| Guard with idempotence too | Personal section + check-before-act | |
| Remove from installer | Configure manually post-install | |

**User's choice:** Personal section, skippable

---

## Post-install checks

| Option | Description | Selected |
|--------|-------------|----------|
| Inline check + theme-doctor (Recommended) | install.sh package verification pass + theme-doctor after stow | ✓ |
| theme-doctor only | Rely on the post-stow gate alone | |
| Inline only | No theme-doctor in the install flow | |

**User's choice:** Inline check + theme-doctor

| Option | Description | Selected |
|--------|-------------|----------|
| Hard-fail with report (Recommended) | Print verification table, exit nonzero | ✓ |
| Report and continue | Warnings only | |
| Fail only in verification mode | Dual behavior via flag | |

**User's choice:** Hard-fail with report

| Option | Description | Selected |
|--------|-------------|----------|
| Theming + session core (Recommended) | Hard-fail on the theming/session set; personal apps warn only | |
| Every listed package | Hard-fail if anything from any selected section is missing | ✓ |
| You decide | Claude derives the critical list | |

**User's choice:** Every listed package (stricter than recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Root-cause and fix (Recommended) | Fix provider registration, remove accepted-gap carve-outs from checks | ✓ |
| Verify fresh, then decide | Test whether the gap reproduces on fresh install first | |
| Keep the accepted gap | Leave the carve-out documented | |

**User's choice:** Root-cause and fix

| Option | Description | Selected |
|--------|-------------|----------|
| Harden in Phase 3 (Recommended) | Fix parity/doctor false-pass paths (02-REVIEW CR-01/WR-01) before they serve as VM evidence | ✓ |
| Keep advisory, defer | Leave as documented advisories | |
| You decide | Claude weighs against phase size | |

**User's choice:** Harden in Phase 3

---

## Claude's Discretion

- Container tooling (docker vs podman), image, script name/location
- VM tooling specifics and documentation format
- install.sh flag names, section boundaries, verification-table format, hardware-detection implementation
- Dead-file hunt implementation; the "obviously dead" vs "ambiguous" line
- Backup naming for stow.sh/limine guards; plan ordering
- Where the CLEAN-02 git-clean assertion lives (theme-doctor vs stress-test vs both)

## Deferred Ideas

- Fully-scripted VM provisioning (archinstall config + libvirt/quickemu automation) — considered, not chosen; future convenience if the VM gate is rerun often (unowned)
