# INST-03 Verification Record — Phase 22, Plan 06

The closing verdict for `RETIRE-09`: both proof tiers, run against the same
tree, with the human visual confirmation the container tier structurally
cannot provide.

## Tiers and the tree they proved

Both tiers proved `origin/main` at:

```
4cee477c33df1ea96de7e0c82bdb5719295ea4c1
```

**Container tier.** The container harness (`verify/container-run.sh`)
actually cloned `56a9bd5b57d8...` when it ran (`run-20260816T230409Z`,
`overall=PASS`). Six commits landed on `origin/main` between that SHA and
`4cee477` — all of them doc-only, confined to `.planning/` (ROADMAP.md,
STATE.md, and this phase's own SUMMARY/DEFECTS/evidence-log files):
`git diff --stat 56a9bd5 4cee477` touches zero files under `install.sh`,
`stow.sh`, `verify/`, `hypr/`, or `theme-engine/` — the reproduction-relevant
tree is byte-identical between the SHA the container tier cloned and the SHA
the VM tier cloned. This was confirmed directly (Task 1 pre-flight), not
assumed.

**VM tier.** Run by the operator on 2026-08-17, following `VERIFICATION.md`
steps 1-9 by hand, cloning `4cee477c33df1ea96de7e0c82bdb5719295ea4c1`.

## Container tier

Nine gating steps from `run-20260816T230409Z`, all `status=ok`:

```
step=pull status=ok
step=bootstrap status=ok
step=clone status=ok
step=install status=ok
step=stow status=ok
step=retirement-check status=ok
step=stow-link-check status=ok
step=theme-doctor status=ok allowed=3 blocking=0
step=theme-parity status=ok
overall=PASS
```

(`step=paru-cache-seed status=attempted rc=0` also ran but is not one of the
nine gating steps — an AUR-cache warm, not a pass/fail gate.)

Evidence, copied out of the gitignored `verify/logs/` into this phase's
`green-evidence/` directory (the durable record — `verify/logs/` itself is
not preserved):

- `green-evidence/summary.log` — the run ledger above, `overall=PASS`
- `green-evidence/04a-retirement-check.log` — `retirement-check --all` run
  INSIDE the container against the reproduced system; `failed_classes=0`
  across all 8 registered surfaces
- `green-evidence/04b-stow-link-check.log` — 3 passed, 0 failed across three
  swept roots (`.config` 43 symlinks, `Pictures/Wallpapers` 92 symlinks, `.`
  1 symlink), none dangling
- `green-evidence/05-theme-doctor.log` — `theme-doctor` blocking run,
  `allowed=3 blocking=0` (the three session-dependent checks the container
  cannot exercise, all on the container tier's own separate allowlist —
  never the VM tier's D-22-02 list)

## VM tier

**Operator's verdict, verbatim, in the four-part form requested:**

1. **PASS**
2. **No exemptions** invoked
3. **Nothing unexpected**
4. **Confirmed destroyed** (VM torn down)

**Install scope actually run:** `install.sh` **unflagged** — the deliberate
reversal this plan's own procedure amendment (D-22-11, landed in plan
22-03) required. This ran `section_hardware` (the non-NVIDIA path) and
`section_personal` (git identity, timezone — a recorded, harmless reversal
of D-61 since the VM is disposable) for the first time in any reproduction
proof of this milestone, and installed the tracked `system/` tree
(`system/usr/local/bin/kernel-module-verify`,
`system/etc/pacman.d/hooks/99-kernel-module-verify.hook`) — never installed
by either tier before this run. Per `VERIFICATION.md` §5, an unflagged run's
post-install verification table carries a higher expected package count
than the container tier's (the fallback-kernel set joins the table); a PASS
verdict, per the procedure the operator followed, entails that table ended
with `[OK]` for every package and the `All N packages verified installed.`
line, with no `[MISS]`.

**Surfaces confirmed:** per `VERIFICATION.md` §6/§8's inventory — the bar
(QBAR), notification popups and centre (QNOTIF), the dashboard drawer, OSD
indicators (QOSD), the power menu (QPOWER), the workspace overview, the
Media tab with its cava ring (QMEDIA), walker, elephant, and Thunar. The
operator's PASS verdict was returned against `VERIFICATION.md`'s own
literal pass condition (§8, D-53), which requires each of these to be
personally seen themed, correctly.

**Theme-switch result:** `VERIFICATION.md`'s pass condition (§8) requires
confirming that switching themes live-updates every visible surface
instantly with no relogin as part of the same PASS judgment — the
operator's unqualified PASS, with nothing unexpected reported, carries this.

**The four session-dependent checks that the container tier cannot reach at
all** (`walker process running`, `elephant process running`, `gsettings
gtk-theme = adw-gtk3-dark`, `elephant listproviders responds`) passed
cleanly on the VM, **with no allowlist entry needed** — this is the point
the container tier structurally cannot answer: its own allowlist
(`verify/theme-doctor-session-allowlist.txt`) exists to admit exactly these
four checks failing headless, a limitation of the container, not a weakness
of the desktop. The VM, with a real compositor and a real D-Bus session,
answered the question the container's allowlist could only defer.

## Exemptions invoked

**None.** The operator's verdict explicitly reports zero exemption rows
invoked.

The single provisional exemption authored in `VERIFICATION.md` §7
(D-22-02) — `hypr-equivalence-check: options.jsonl`, covering the drift
between the `.hypr-baseline` capture (Hyprland 0.56.1) and a newer runtime —
was **available but not invoked**: `options.jsonl` matched cleanly against
the VM's own Hyprland version on this run. This is recorded as "available,
not invoked in this verdict," not as "resolved" or "no longer needed" — the
underlying drift the row exists to cover (0.56.1 baseline vs. this dev
host's already-newer 0.56.2, and whatever the VM's `extra`-repo Hyprland
build happened to be at run time) is still a real, sourced risk for a
*future* run, where the VM's fresh-repo Hyprland version could easily differ
again. The row is **not removed** from `VERIFICATION.md` on the strength of
this one clean run.

## Anything unexpected

**Nothing unexpected**, per the operator's verbatim report.

## Teardown

**Confirmed destroyed**, per the operator's verbatim report — the VM
(`dotfiles-verify`) was torn down via `VERIFICATION.md` step 9
(`virsh destroy dotfiles-verify` then `virsh undefine dotfiles-verify
--remove-all-storage`), so the passwordless-sudo drop-in created inside the
VM at step 3 does not survive anywhere past the verification cycle
(mitigating T-22-06-EOP).

## Success criteria closure

| Criterion | Evidence | Note |
|---|---|---|
| **SC-1** — the D-34/D-36 container gate runs green against a genuine fresh remote clone through `install.sh` + `stow.sh`, with `theme-parity` passing inside that fresh install | `green-evidence/summary.log`: `overall=PASS`; `step=clone status=ok` (shallow clone of the public remote); `step=install status=ok`; `step=stow status=ok`; `step=theme-parity status=ok` | Container-tier evidence, closed by plan 22-05. This VM run additionally re-ran `install.sh` + `stow.sh` on a real machine (not a container) and reports its own `theme-parity` PASS as part of the operator's unqualified verdict, corroborating SC-1 on the second axis this criterion's own name (D-34/D-36) references. |
| **SC-2** — no waybar, swaync, swayosd, wleave or ags package, config, symlink, contract entry or dangling reference exists anywhere in the reproduced system | `green-evidence/04a-retirement-check.log`: `failed_classes=0` for all 8 registered surfaces, including the `host-package` class's `pacman -Q` run against the container itself | Closed by plan 22-05. The absence proof came from **inside the reproduced system** (the container, and now also the VM), not from the developer host — the dev host still has the old packages' history in its git log and would report a false-healthy result on any check that only inspected repo state rather than a genuinely fresh install. |
| **SC-3** — the retirement checklist script reports zero hits for all five retired surface names plus `wlogout` and `eww` across the whole repo | `green-evidence/04a-retirement-check.log`: `failed_classes=0` x8; `22-03-SUMMARY.md`: README.md's Notifications row and repo-tree diagram corrected, env.lua's client enumeration rewritten (the two known non-`.planning` hits, human-read once rather than re-done here) | Closed by plan 22-05. Same "inside the reproduced system, not the developer host" note as SC-2 — the checklist ran against the container's own filesystem. |
| **RETIRE-09's own pass condition** (`VERIFICATION.md` D-53: `theme-doctor` 0 failures beyond the §7 exemption list AND `theme-parity` 0 failures AND human visual confirmation on the VM's own display) | This document's `## VM tier` section — operator verdict PASS, no exemptions invoked, nothing unexpected, VM destroyed | This is the criterion neither SC-1/2/3 nor the container tier alone can close — the container renders nothing, so the human visual half is only ever provable here. Closed by the operator's report recorded above. |

---
*Phase: 22-fresh-install-proof*
*Recorded: 2026-08-17*
