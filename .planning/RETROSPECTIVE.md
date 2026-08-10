# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Theme Pipeline Repair

**Shipped:** 2026-07-09
**Phases:** 3 | **Plans:** 9 | **Tasks:** 25

### What Was Built
- Consolidated `theme-engine` stow package: one `theme-apply` entrypoint rendering static presets and matugen Material You through the same templates into `~/.local/state/theme/`, with a single reload owner fanning out to all ten desktop surfaces live (no relogin).
- The stuck-white root cause fixed: `adw-gtk-theme` installed and the nonexistent `adw-gtk3` install.sh entry replaced, backed by a 23-finding full-repo AUDIT.md.
- Proof tooling as rerunnable regression gates: `contract.json` + `theme-parity` (structural/name-set/semantic parity across all 7 render targets), `theme-stress-test` (10-switch static↔dynamic gate), `theme-doctor` (strict, zero carve-outs).
- Fresh-install reproducibility: hardened `install.sh`/`stow.sh` plus a podman container gate (`verify/container-run.sh`) and a documented graphical-VM procedure — both tiers passed with human sign-off.
- Repo cleanup: wofi tree, debug.txt, retired scripts, orphaned templates gone; screenshots un-folded from stow; git stays clean after every switch.

### What Worked
- **Root-cause-first sequencing.** The full-repo audit in Phase 1 found the missing-package root cause immediately and broke a loop of 8+ prior failed spot-fixes.
- **The acceptance gate earned its keep.** Seven container-gate runs peeled off six real fresh-install defects (stdin-eating heredoc, missing --noconfirm, wlogout repo mismatch, dead AUR entry, headless swaync hang, host-absolute symlink) before the first genuine PASS — none would have surfaced on the dev machine.
- **Single-source-of-truth manifests.** `contract.json` consumed by both checkers eliminated checker/renderer drift; parity passed 217/0 with zero fixes needed, proving the Phase 1 consolidation was already correct.
- **Human sign-off checkpoints at phase ends** caught what automation can't (visual correctness on real desktop and in the VM).

### What Was Inefficient
- INST-03 gate execution stalled on an unpushed origin (~80 commits behind) — the harness clones from the remote, so the gate was blocked until the user authorized a push. Sequencing the push authorization earlier would have saved a deferral cycle.
- The elephant provider gap was misdiagnosed in planning as "packages never installed"; the real cause was a Go plugin/host build-invocation mismatch requiring a human-run `paru --rebuild`. Cost a 55min+ continuation plan.
- Two `set -e` shell footguns (`(( counter++ ))` at zero; rsync `--delete` wiping its own logs) each cost a debugging round — both were self-inflicted by the new tooling, caught by the gates.

### Patterns Established
- All theme output renders to `~/.local/state/theme/` — the repo holds templates, never generated artifacts; a git-clean invariant enforces it.
- Reload strategy per app class: signal-based where supported (waybar SIGUSR2, swaync-client -rs), hardened restart with health gates where not (Walker + elephant, Thunar daemon watcher).
- Every reliability claim gets a rerunnable harness (`theme-parity`, `theme-stress-test`, `container-run.sh`) rather than one-off manual verification.
- Headless guard convention: session-dependent code early-returns when WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS are absent, keeping unattended installs alive.

### Key Lessons
1. When repeated fixes fail, audit before patching — the v1.0 root cause was a package name that never existed, invisible to symptom-level fixes.
2. A reproduction gate must run from the same path a real fresh install takes (real remote clone, unattended, timeout-bounded) — every one of the six gate defects was invisible to dev-machine re-stows.
3. Verify assumed APIs empirically before planning around them: walker's `hotreload_theme` did not exist, GTK3 has no live CSS reload — plans built on those would have failed.
4. Tracked symlinks must be relative; host-absolute paths are silent fresh-install breakers.

### Cost Observations
- Model mix: adaptive profile (not instrumented per-model this milestone)
- Timeline: 3 days, 98 commits
- Notable: 9 plans averaged ~25 min each; the two longest overruns were both misdiagnosis-driven (elephant rebuild, container gate debugging), not scope-driven.

---

## Milestone: v2.0 — Desktop Expansion

**Shipped:** 2026-07-25
**Phases:** 7 (4-10) | **Plans:** 64 | **Commits:** 444

### What Was Built
- Reliability base de-risked: wlogout shutdown hang, hyprlock first-keystroke drop and kitty startup all root-caused and fixed (641ms → 33.9ms shell init via fish), plus the v1.0 rsync tech-debt carry-over.
- Light mode through the whole pipeline: 22 theme targets (15 dark, 5 light, 2 Material You), mode auto-detected from palette lightness, theme-scoped wallpaper sets behind a redesigned kitty-graphics picker.
- Every remaining surface re-themed (wlogout, hyprlock, SwayOSD, Zen) plus the full utility suite: screenshot capture/annotate/record, emoji, color, clipboard, icon-theme and font pickers.
- $SUPER-tap walker/elephant menu tree: Utilities, AI dashboard, Game center, power, settings, searchable keybind cheat-sheet.
- Waybar rebuilt: four layouts composed from one shared `modules.jsonc`, OLED-safe single-owner visibility, mpris media center, notification-center access — every layout redesigned per-flow and user-approved on sight.
- Power menu migrated wlogout (GTK3) → wleave 0.7.1 (GTK4), eliminating the whole-stylesheet-discard failure class.
- eww media popup replaced by an AGS v3 media card: working pointer input, cava audio-reactive underlay, matugen-themed with runtime hot reload.

### What Worked
- **Fail-fast viability gates.** Phase 10 put a human-clicked test button at plan 2 with authority to STOP the phase. It passed on the first click and de-risked the remaining four plans — exactly the check whose absence had cost Phase 8 two entire plans.
- **Verifying against the installed binary, not the docs.** Paid off three separate times: hyprlock 0.9.5's option schema via `strings` (the original FIX-02 attempt had shipped dead config), walker 2.16.2's exit-130 cancel convention, and wleave's config surface probed via man pages/`--help`/binary strings before planning.
- **Evidence-first performance work.** Profiling proved nvm sourcing (53.5%) and a remote omp fetch were the real cost; prior guesses had blamed fastfetch and zinit.
- **Descope with a written artifact as a legitimate outcome.** BAR-02 closed with a reproducible gate table and a real luminance measurement rather than being quietly dropped or faked.
- **Mechanical equivalence gates behind refactors.** `waybar-equivalence-check` made the four-layout deduplication provably behavior-preserving.

### What Was Inefficient
- **eww was the single biggest waste of the milestone.** Plans 08-07 and 08-08 built a complete media popup — album art, seek, volume, player switcher, plus a 19-check adversarial security gate — on a toolkit that turned out to be incapable of delivering pointer input on this eww 0.6.0 / Hyprland 0.55.4 build. All of it was discarded in Phase 10. A 10-minute click test before 08-07 would have saved both plans.
- **Phase 8's design blew up at UAT.** Sixteen plans in, the user's verdict was "complete failure... needs a complete redesign" — after every automated gate had passed green. Six additional plans (08-11..08-16) were spent redesigning all four layouts. The gates proved colour tokens resolved; nothing proved the bar looked right.
- **Bookkeeping lagged the code badly.** At milestone close, four artifacts were still flagged open that had been fixed for days or weeks, `08-VERIFICATION.md` still said `human_needed` after the UAT had closed it, `07-VERIFICATION.md` had never been committed at all, and `REQUIREMENTS.md` still stopped at Phase 8 while Phases 9 and 10 had shipped. None were real quality gaps; all of them cost reconciliation time at the worst moment.
- **Out-of-order phase execution confused the state machine.** Phase 10 ran on 07-15, Phase 9 on 07-25; closing Phase 9 advanced `current_phase` to 10, which was already complete. The next planning attempt hit the closed-phase gate instead of the milestone close it actually needed.
- **Push authorization deferred for the entire milestone.** 393 commits accumulated unpushed from Phase 7 onward, keeping the container-tier reproducibility rerun (D-34/D-36) blocked the whole time. This is the same lesson v1.0 recorded and did not act on.

### Patterns Established
- Every themed surface consumes the palette by `@import` from `~/.local/state/theme/` — zero hex literals in repo stylesheets; adding a surface is a template plus a contract entry.
- A blocking human render-and-look gate on anything with a visual surface, with authority to reject on sight.
- A fail-fast toolkit-viability gate before building a feature on an unproven toolkit.
- New stow packages register in `stow.sh` in the same commit that creates them (the `ags/` gap proved the cost of not doing this — it worked only on this host).
- Shared definitions plus a mechanical equivalence gate whenever N copy-pasted configs are deduplicated.
- Descope only with a written, reproducible evidence artifact.

### Key Lessons
1. **Green mechanical gates do not imply a working surface.** Phase 6 and Phase 8 both shipped visibly broken UIs through fully passing CSS-parse, shellcheck, theme-doctor and token-resolution gates. Machines prove tokens resolve; only a human judges whether it reads correctly.
2. **Prove the toolkit can do the core interaction before building the feature on it.** eww cost two full plans because "can it receive a click?" was never asked first.
3. **Verify options and APIs against the installed binary.** Docs, tutorials and memory were wrong about hyprlock's schema, walker's cancel semantics and Walker's own architecture; the binary was right every time.
4. **Reconcile tracking artifacts at phase close, not milestone close.** Every stale artifact found at this close was cheap to fix and expensive to find.
5. **Sequence push authorization early.** v1.0 recorded this exact lesson and v2.0 repeated it at 5× the scale.

### Cost Observations
- Model mix: adaptive profile (not instrumented per-model this milestone)
- Timeline: 16 days, 444 commits, 488 files (+57,232 / −3,151)
- Notable: 64 plans, but ~8 of them (08-07, 08-08, 08-11..08-16) were rework driven by two avoidable misses — an unverified toolkit and an unverified design. Roughly 12% of the milestone's plans were spent recovering from checks that would have taken minutes.

---

## Milestone: v3.0 — Quickshell Foundation & Motion Language

**Shipped:** 2026-08-10
**Phases:** 8 (11-17, incl. inserted 13.1) | **Plans:** 68 | **Commits:** 530

### What Was Built
- Quickshell adopted as the shell toolkit behind a human-clicked viability gate that passed on the first attempt, with standing authority to stop the milestone.
- One motion source (`theme-engine/motion.json`) rendering to three binary-verified targets — QML `easing.bezierCurve`, GTK4 `cubic-bezier()`, Hyprland `bezier =` — with a runtime normal/reduced/off axis and a deny-by-default `motion-lint` folded into `theme-doctor`.
- The motion language retrofitted across every pre-existing surface: Hyprland, waybar, swaync, walker, SwayOSD, wleave, the AGS media card.
- A Super+D four-tab dashboard drawer that shares state rather than forking it — one MPRIS reader with waybar and AGS, byte-identical quick-toggle scripts to swaync's grid, zero idle timers or subprocesses while dismissed.
- Three in-shell panels (audio mixer, wifi picker, bluetooth manager) on one shared `PanelDialog` frame, verified against real hardware — a real AP, a real hidden network, a real Bluetooth peer.
- A Super+O workspace overview: eleven pixel-stable tiles rendering every window as a live `ScreencopyView` at real geometry, with click-to-focus, two-level keyboard navigation and drag-between-workspaces — on `hyprland-toplevel-export-v1`, no plugin.
- The compositor moved off hyprlang onto Lua ahead of Hyprland 0.57's removal (Phase 13.1, inserted against a real upstream deadline), proven by a committed pre-migration `hyprctl` baseline rather than a hand-diff.
- Ambient extras shipped in full despite being scoped as the first thing to cut: video wallpaper with measured fullscreen-pause, and dynamic cursors as a fault-injection-proven guarded optional dependency.

### What Worked
- **The viability gate paid off a second time.** v2.0's lesson was written after eww; v3.0 applied it before writing any Quickshell feature, and QS-02 passed on the first click. The pattern has now de-risked two consecutive toolkit adoptions.
- **Structured `coverage:` blocks in SUMMARY frontmatter.** Phase 16's UAT auto-passed 16 of 30 deliverables from passing verification refs and put exactly the 14 genuine judgment calls in front of the operator, each with a stated reason. This is the first milestone where "what does a human still need to look at?" was a machine-answerable question instead of a re-derivation from prose.
- **Measuring before acting, twice in one phase.** Phase 15's G-15-7 looked exactly like the wifi secret-agent problem and the obvious move was to copy the wifi remedy — measuring first showed pairing then fails outright, so the copy would have turned a cosmetic complaint into a functional regression. The same instinct on G-15-6 would have rebuilt a working mechanism on a costlier route.
- **Closing dead ends with evidence instead of ambiguity.** QS-03 was re-attempted under a bounded budget across two structurally distinct arrangements plus an escape-hatch spike before being dropped one-way; D-35 was tested to the point of reproducing a compositor SIGSEGV before the call was removed. Neither lingered as an open question.
- **Falsifiable gates over hand-verification for the Lua migration.** `hypr-equivalence-check` diffing a live session against a committed baseline made an 80-bind config port provable, and caught two Lua-only hazards — randomized string-hash seeds breaking `pairs()` curve registration per boot, and `hl.dsp.dpms` silently ignoring bare-string arguments — that no amount of reading would have surfaced.

### What Was Inefficient
- **Phase 16 shipped two false passes on the same deliverable.** Multi-window thumbnails passed automated checks and screenshot verification twice with only one window visibly painted. The real fix came only after the operator's own eyes caught it and the executor switched from screenshots to per-delegate IPC measurement. Screenshot-based self-verification is not the human gate; it repeatedly reads as one.
- **The bookkeeping lesson from v2.0 repeated, in a new shape.** v2.0's close found stale artifacts; v3.0's close found a whole missing one — Phase 16 has no VERIFICATION.md, which alone orphaned four requirements and forced an override closeout. The pre-close audit also surfaced 53 open items. Recording the lesson twice has not yet changed the behaviour.
- **Waived gates accumulate silently.** Three separate measurement gates were waived rather than performed across the milestone (D-19/D-20 motion soak, WR-04 teardown hazard, and Phase 16's session-restart enforcement proof). Two were later closed; WR-04 is still open and is the milestone's only unfinished requirement. A waiver is cheap in the moment and indistinguishable from a pass in every summary that follows it.
- **A reuse gap crossed a phase seam unnoticed.** `GradientBorder` was built in Phase 14 and never reached the Phase 15 panel family built on a shared frame — exactly the kind of omission a wiring-oriented integration pass reads as clean, because nothing is broken. It surfaced only when the user raised it, and was then diagnosed and deliberately left unfixed.
- **Executor-unprovable checks needed a name earlier.** Several deliverables were structurally unverifiable from inside the session — a session restart would kill the executor, no synthetic pointer tool exists on this host — and each was rediscovered independently rather than being a known category with a standard disposition.

### Patterns Established
- Structured `coverage:` blocks in SUMMARY frontmatter, splitting deliverables into auto-covered (with refs) and human-needed (with a stated reason), consumed directly by UAT generation.
- One source, N render targets, each verified against its own installed binary rather than assumed compatible — extended from colour (`contract.json`) to motion (`motion.json`).
- Falsifiable equivalence gates for config migrations: snapshot the old system's own readback, commit it, diff the new one against it.
- Guarded optional dependencies: anything installed via `hyprpm` or an AUR helper must exit 0 and warn on failure, proven by deliberate fault injection, never fail an unattended install.
- Validation boundaries at every dispatch site that could carry client-controlled text into a compositor evaluator.
- Naming the rung a measurement actually reached, and recording the untested half as UNMEASURED rather than inferring it.

### Key Lessons
1. **Screenshot verification is not the human gate.** Phase 16 passed two automated/screenshot rounds on a visibly broken surface. When the deliverable is "does this read correctly", the only instrument is a person looking at it on their own desktop.
2. **A missing artifact costs more than a stale one.** v2.0 learned to reconcile tracking artifacts at phase close; v3.0 shows the sharper version — one unwritten VERIFICATION.md orphaned four requirements and downgraded the whole milestone from verified to override closeout.
3. **A waiver is a decision, not a result, and needs to stay visibly distinct from one.** Three gates were waived this milestone. Every downstream summary reads a waived gate the same way it reads a passed one unless the waiver is carried forward explicitly.
4. **Reuse omissions cross phase seams invisibly.** Nothing is broken, so wiring-oriented integration checks read clean. Detecting these needs a "who consumes this?" pass on newly built shared components, not a connectivity pass.
5. **Categorize executor-unprovable checks up front.** "The executor is a child process of the thing under test" and "no synthetic input tool exists on this host" are structural facts about this project, not per-plan surprises.

### Cost Observations
- Model mix: adaptive profile (not instrumented per-model this milestone)
- Timeline: 16 days, 530 commits, 68 plans
- Notable: 4.25 plans/day, the project's highest, on its most novel technology — and with no rework block comparable to v2.0's ~12%. The cost moved from rework to verification debt: the milestone closed with 53 open artifacts and one phase unverified, which is a different failure mode than v2.0's, not a smaller one.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 3 | 9 | Established root-cause-first auditing and rerunnable verification gates (parity/stress/container) |
| v2.0 | 7 | 64 | Added the *human* gate class — blocking render-and-look approval and fail-fast toolkit-viability checks — after mechanical gates twice passed green on broken surfaces |
| v3.0 | 8 | 68 | Made the human gate *addressable*: structured `coverage:` blocks decide per-deliverable whether a human is still needed and why, so UAT stops re-asking what automation already answered. First milestone to close as an `override_closeout` |

### Scale

| Milestone | Days | Commits | Plans | Plans/day |
|-----------|------|---------|-------|-----------|
| v1.0 | 3 | 98 | 9 | 3.0 |
| v2.0 | 16 | 444 | 64 | 4.0 |
| v3.0 | 16 | 530 | 68 | 4.25 |

### Top Lessons (Verified Across Milestones)

1. **Audit before patching when fixes loop** (v1.0; reinforced v2.0 — Phase 4's profiling disproved two long-standing guesses about kitty startup).
2. **Acceptance gates must reproduce the real environment, not approximate it** (v1.0; reinforced v2.0 — the eww popup passed every repo-side gate and could not accept a click).
3. **Verify APIs against the installed binary, never against docs or memory** (v1.0 walker `hotreload_theme`; v2.0 hyprlock schema, walker exit-130, wleave config surface — 4 confirmed instances, now a standing rule).
4. **Mechanical gates cannot judge a visual surface** (v2.0, twice — Phases 6 and 8). Any phase with a UI needs a blocking human render gate.
5. ⚠️ **Sequence push authorization early — REPEATED, still unresolved.** v1.0 lost a deferral cycle to an ~80-commit unpushed origin; v2.0 carried 393 unpushed commits from Phase 7 to milestone close, blocking the container-tier gate the entire time. This is the one lesson the project has recorded and then not acted on. Resolved at the v2.0 close; enforce earlier in v3.0.
6. ⚠️ **Close the tracking artifact at phase close — REPEATED, escalating.** v2.0 found four stale artifacts at milestone close. v3.0 found a missing one: Phase 16 never got a VERIFICATION.md, which orphaned four requirements and downgraded the entire milestone to an `override_closeout`. The failure mode got worse, not better, after the lesson was written down.
7. **Screenshot self-verification is not the human render gate** (v3.0, Phase 16 — two false passes on the same deliverable). The gate established in v2.0 only works when a person looks at the running surface; an executor capturing and judging its own screenshot reproduces the exact failure the gate exists to catch.
8. **Distinguish waived gates from passed ones in every artifact downstream** (v3.0 — three waivers, one still open as the milestone's only unfinished requirement). A waiver reads identically to a pass in summary frontmatter unless it is carried forward explicitly.
