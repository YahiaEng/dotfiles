# Phase 22: Fresh-Install Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-16
**Phase:** 22-fresh-install-proof
**Areas discussed:** Proof tiers, Absence proof (SC-2/SC-3), Gate blocking set, Install scope, Sequencing

---

## Area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Proof tiers | Container gate only, or container + graphical VM tier | ✓ |
| Absence proof (SC-2) | How "no retired package/config/symlink/dangling ref in the reproduced system" is proven | ✓ |
| Gate blocking set | What hard-gates the container run's exit code | ✓ |
| Install scope | Keep `--core-only` or widen | ✓ |

**User's choice:** all four.

---

## Todo cross-reference

| Option | Description | Selected |
|--------|-------------|----------|
| Don't fold | `brightness-osd-unverifiable-on-desktop` matched on generic keywords; hardware-availability gap, and ROADMAP states Phase 22 carries no debt | ✓ |
| Fold it in | Treat the brightness OSD verification gap as in-scope | |

**User's choice:** Don't fold. Recorded as reviewed-not-folded in CONTEXT.md.

---

## Proof tiers

### Q1 — Which tiers must run for the phase to close?

| Option | Description | Selected |
|--------|-------------|----------|
| Both tiers | Container blocks + graphical VM tier; the container renders nothing this milestone built | ✓ |
| Container only | Take SC-1 literally; cheapest, nothing proves Hyprland starts | |
| Container + bounded boot-and-look | Shortened VM run skipping the full 9-step procedure | |

**User's choice:** Both tiers.
**Notes:** Grounded on VERIFICATION.md's own stated pass condition ("a tool-only pass
without a human visual confirmation does not satisfy INST-03") and PROJECT.md's
standing human-render-gate decision. Cost of the VM tier accepted explicitly.

### Q2 — The VM tier's pass bar, now that theme-doctor is 578 checks

| Option | Description | Selected |
|--------|-------------|----------|
| Literal bar + pre-authored exemptions | theme-doctor exit 0, minus a list written before the run with reasons | ✓ |
| Strict literal bar | No exemptions; risks an unbounded checker-repair project on version drift | |
| Boot + human render only | Cheapest VM tier; forfeits the session-dependent checks | |

**User's choice:** Literal bar + pre-authored exemptions.
**Notes:** Correction made during the discussion — an initial concern that
`hypr-equivalence-check` was hardware-shaped was checked and found wrong: it
compares binds/animations/options only. The real named risk is Hyprland version
drift against the 13.1 baseline.

### Q3 — What the human judges on the VM

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite §6/§8 to the current inventory, by requirement ID | Names surfaces by QBAR/QNOTIF/QOSD/QPOWER/QMEDIA rather than package name | ✓ |
| Minimal staleness fix | Strip stale mentions, leave §8 generic | |
| Derive from each phase's GATE-02 record | Reuse operator-approved gesture lists | |

**User's choice:** Rewrite by requirement ID.
**Notes:** Driven by measurement — VERIFICATION.md §6 (line 183) and §8 (line 214)
still name a package deleted in Phase 19, and the file already sits in
`retirement-check`'s report tier. Phase 21's twice-repeated lesson applies.

### Q4 — Defect policy

| Option | Description | Selected |
|--------|-------------|----------|
| Fix in-phase, push, re-run the failing tier | Milestone exit criterion; phase size not fully knowable up front | ✓ |
| Fix in-phase, re-run container only | Cheaper; a fix can regress what the VM would catch | |
| Record and triage | Bounds the phase; risks closing on "mostly reproduces" | |

**User's choice:** Fix in-phase, push, re-run.
**Notes:** The push constraint was surfaced from the harness source —
`container-run.sh` clones `origin/main`, so an unpushed fix is invisible to it.

---

## Absence proof (SC-2 / SC-3)

### Q1 — How SC-2 is proven

| Option | Description | Selected |
|--------|-------------|----------|
| retirement-check inside the container + new dangling-symlink assertion | host-package class runs `pacman -Q` against the reproduced system; symlink half has no mechanism today | ✓ |
| retirement-check inside the container only | Zero new code; leaves dangling symlinks unproven | |
| Host-side retirement-check only | Cheapest; proves the repo is clean, not the reproduced system | |

**User's choice:** Both.
**Notes:** Two measurements drove the options — `retirement-check` class 14 was
confirmed to shell out to `pacman -Q`, and a repo-wide grep confirmed no
dangling-symlink check exists anywhere.

### Q2 — What closes SC-3's "zero hits"

| Option | Description | Selected |
|--------|-------------|----------|
| Blocking tier zero + one-time review of live-code and README hits | Literal all-hits-zero is unreachable by design (D-18-37) | ✓ |
| Blocking tier zero, full stop | Already true today; leaves README advertising a deleted package | |
| Promote the stale ones to blocking | Strongest guarantee; re-arms the Phase 20 exemption interlock | |

**User's choice:** Blocking tier zero + review pass.
**Notes:** The review pass already has a confirmed hit — `README.md:24` lists
SwayNC as this desktop's notification daemon, and lines 70/80 draw its stow tree.
`env.lua:15-16` lists two retired packages as live Wayland clients. Distinguished
from `autostart.lua`/`windowrules.lua`/`quickshell-doctor`, whose mentions are
correctly-written retirement-lineage comments protected by D-21-19.

### Q3 — Shape of the dangling-symlink assertion

| Option | Description | Selected |
|--------|-------------|----------|
| Permanent checker, self-tested, folded into theme-doctor | Matches motion-lint/colour-lint/retirement-check; guards future retirements | ✓ |
| A step inside container-run.sh only | ~5 lines; can never be proven to fail | |
| Fold into stow.sh as a post-stow assertion | Right place/time; turns the installer into a checker | |

**User's choice:** Permanent checker, folded.

---

## Gate blocking set

### Q1 — What blocks the container gate

| Option | Description | Selected |
|--------|-------------|----------|
| theme-doctor blocks, minus a pre-authored session-failure allowlist | Recovers ~575 checks of coverage without surgery on a 578-check script | ✓ |
| Add the headless-safe linters as separate blocking steps | Precise; misses everything theme-doctor checks beyond those three folds | |
| Give theme-doctor a --headless mode | Cleanest long-term; modifies the most load-bearing script mid-regression-phase | |

**User's choice:** Allowlist approach.
**Notes:** Grounded on the Jul 9 log — theme-doctor was 20 passed / 3 failed in
the container, all three genuinely session-dependent. At 578 checks today the
informational treatment discards far more than it did in v1.0.

### Q2 — How the allowlist is derived

| Option | Description | Selected |
|--------|-------------|----------|
| Measure first, then justify each entry at source level | Blocks fitting the list to whatever went red | ✓ |
| Derive by source-reading only | Independent of results; a static read can miss a real headless failure | |
| Start from the Jul 9 list of three | Cheapest; predates the entire migration | |

**User's choice:** Measure first, justify at source level.

### Q3 — Where the allowlist lives

| Option | Description | Selected |
|--------|-------------|----------|
| Committed next to container-run.sh | The rule is data the tool consumes | ✓ |
| In the phase evidence document | Harness unchanged; re-runs have no enforced bar | |

**User's choice:** Committed next to the harness.

---

## Install scope

### Q1 — section_hardware and the system/ tree

| Option | Description | Selected |
|--------|-------------|----------|
| Full install.sh on the VM tier; container stays --core-only | Proves section_hardware's non-NVIDIA path and installs system/ for the first time | ✓ |
| Keep --core-only on both, record the gap | Zero new risk; a tracked tree stays unproven | |
| Invoke section_hardware without section_personal | Most precise; adds a flag to install.sh during the phase meant to prove it | |

**User's choice:** Full `install.sh` on the VM tier.
**Notes:** Two corrections were made during this area after measurement. First, an
initial claim that the non-core sections skip services and systemd units was
wrong — every package install is in `section_core_rice`, and the two quickshell
units deliberately carry no `[Install]` section so enabling never writes outside
the repo. Second, `stow.sh`'s PACKAGES array was checked and is clean (17 entries,
`cava` and `quickshell` present, all five retired packages absent) — no repeat of
the `ags/` registration gap. The genuine finding was `system/`, installed only by
`section_hardware` and therefore never exercised by either tier.

---

## Sequencing

### Q1 — Phase order

| Option | Description | Selected |
|--------|-------------|----------|
| Baseline run first, unmodified | One run does triple duty; no harness edit against a guessed baseline | ✓ |
| Modify the harness first | One long run; failure becomes unattributable between two changed variables | |
| Baseline both tiers first | Most information; spends the expensive VM build on a run expected to change | |

**User's choice:** Baseline run first.
**Notes:** Last `overall=PASS` was `run-20260709T060703Z` (2026-07-09); three later
runs record no verdict, the last stopping after `step=clone status=ok`. Whether
the harness itself still completes is an open question, not an assumption.

---

## Claude's Discretion

- File format of the committed session-failure allowlist.
- Naming of the new dangling-symlink checker.
- Whether the symlink sweep covers `$HOME/.config` only or every path
  `stow.sh`'s PACKAGES loop can write to (guidance given: err toward covering all).

## Deferred Ideas

- A real `--headless` mode for `theme-doctor` — cleaner long-term, declined here
  to avoid modifying the most load-bearing script during the closing regression
  phase. Candidate for v5.0.
- Promoting stale-prose hits from `retirement-check`'s report tier to blocking —
  declined to avoid re-arming the Phase 20 exemption interlock. Needs a design
  that separates "historical lineage comment" from "current factual claim".
- A `section_hardware`-without-`section_personal` entry point in `install.sh` —
  the most precise answer to the install-scope question, declined because this
  phase proves `install.sh` rather than restructuring it.
