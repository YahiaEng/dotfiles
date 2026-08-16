# Phase 22: Fresh-Install Proof - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning

<domain>
## Phase Boundary

RETIRE-09, single requirement, no debt. Prove that a clean clone of the
post-migration repo still reproduces the whole themed desktop after five stow
packages were deleted (waybar, swaync, swayosd, wleave, ags — plus the
already-retired wlogout and eww leftovers).

This is the milestone's **exit criterion**, not bookkeeping. It structurally
could not run earlier: before the deletions landed it could only ever have
proven the pre-migration state still reproduces, which was already known.

**In scope:** running both INST-03 proof tiers to green against the current
`origin/main`; the harness/checker changes those runs require; fixing whatever
fresh-install defects the runs surface; correcting the reproduction procedure
and README prose that the migration made stale.

**Out of scope:** any new desktop capability, any QML surface work, any debt
item (all eight LEDGER requirements were interleaved into Phases 18-21 by
design — this phase carries none).

</domain>

<decisions>
## Implementation Decisions

### Proof tiers

- **D-22-01:** **Both INST-03 tiers run.** The container gate blocks, and the
  graphical VM tier from `VERIFICATION.md` follows. Rationale: the container
  renders nothing — every surface this milestone built (QML bar, notification
  popups + centre, OSD indicators, power menu, dashboard Media tab) is invisible
  to it, and `VERIFICATION.md`'s own stated pass condition is that "a tool-only
  pass without a human visual confirmation does not satisfy INST-03." PROJECT.md's
  standing decision that a human render gate is load-bearing applies here too.
  SC-1 names only the container tier; this deliberately exceeds it.

- **D-22-02:** **VM tier pass bar = VERIFICATION.md's literal condition minus a
  pre-authored exemption list.** The bar stays `theme-doctor` exit 0 AND
  `theme-parity` 0 failures AND human visual confirmation. Any check that may
  legitimately differ on a genuinely fresh machine must be written down *before*
  the VM run, with its reason. Named candidate: Hyprland version drift between
  the fresh VM's current Hyprland and the `13.1` baseline that
  `hypr-equivalence-check` diffs against (baseline dir:
  `.planning/milestones/v3.0-phases/13.1-hyprland-lua-config-migration/.hypr-baseline`).
  Authoring the list in advance is what prevents a red line being rationalised
  away after it appears. Anything outside the written set is a real defect.
  Same discipline as `retirement-check`'s registry, `motion-lint`'s exemption
  list and `hypr-equivalence-check`'s accepted-additions table.

- **D-22-03:** **`VERIFICATION.md` §6 and §8 are rewritten to the current surface
  inventory, naming surfaces by requirement ID rather than package name.** The
  file is half-migrated today: it already says "the Quickshell bar (including its
  in-process power menu)" but both §6 (line 183) and §8 (line 214) still name a
  package deleted in Phase 19. The human's checklist must name what the desktop
  actually is now — bar, notification popups + centre, dashboard drawer, OSD
  indicators, power menu, workspace overview, Media tab with the cava ring,
  walker, Thunar. Naming by requirement ID (QBAR/QNOTIF/QOSD/QPOWER/QMEDIA) is
  load-bearing, not stylistic: Phase 21 was bitten twice by retirement prose that
  named retired packages literally — once tripping `theme-doctor`, once tripping
  `retirement-check`'s checker-internals class — and this file already sits in
  `retirement-check`'s report tier.

- **D-22-04:** **Defects are fixed in-phase, pushed, and the failing tier re-run
  to green.** A recorded-but-unfixed defect would mean v4.0 ships a repo that does
  not reproduce. **Mechanical constraint the planner must carry: every fix has to
  be pushed to `origin/main` before the container gate can see it** —
  `container-run.sh` does `git clone --depth 1` from the real remote (D-56), so a
  locally-committed fix is invisible to the tier meant to prove it. Consequence
  accepted knowingly: the phase's size is not fully knowable up front. Precedent:
  v1.0's gate runs caught 6 real fresh-install defects this way.

### Absence proof (SC-2 and SC-3)

- **D-22-05:** **`retirement-check --all` runs as a blocking step INSIDE the
  container.** Its class 14 (`host-package`) executes `pacman -Q <surface>`
  against the machine it runs on — so running it in the container asserts against
  *the reproduced system*, which is precisely what SC-2 asks for and what the dev
  host cannot tell you. Its other 13 classes run against the freshly-cloned tree.
  Zero new checker code for this half.

- **D-22-06:** **A dangling-symlink assertion is new work, built as a permanent
  checker.** Measured: nothing in this repo checks for dangling symlinks anywhere
  — grepped `theme-doctor`, `theme-parity`, `stow.sh` and the whole scripts tree;
  the only "dangling" hits are `motion-lint`'s token-reference language and prose.
  SC-2's symlink clause has no mechanism today. Build it the way every other gate
  here is built: standalone script + committed compliant/poisoned fixtures +
  `--self-test`, folded into `theme-doctor` with a guarded skip — the shape
  `motion-lint`, `colour-lint` and `retirement-check` all took. The container step
  is then just one caller, and it guards every future retirement rather than only
  this one. Explicitly rejected: a bare `find -xtype l` written into the harness,
  because "a gate that cannot be pointed at a fixture cannot be proven to fail"
  (D-28). — **Reversibility:** costly — folding into `theme-doctor` adds a check
  every future run must satisfy; removing it later means unpicking the fold, its
  fixtures and its self-test entries.

- **D-22-07:** **SC-3 closes on `failed_classes=0` across all 8 surfaces, PLUS a
  one-time human read of the surviving non-`.planning` hits.** The literal
  "zero hits across the whole repo" reading is unreachable by design — D-18-37
  states plainly that folding `.planning/` into the blocking tier makes a green
  run structurally impossible (1214 eww hits alone). Measured state at discussion
  time: all 8 surfaces already report `failed_classes=0`, so the mechanical half
  of SC-3 is satisfied before the phase starts. The review pass is what earns it.
  **It already has a hit:** `README.md:24` still lists "Notifications | SwayNC" in
  its feature table and lines 70/80 still draw `swaync/.config/swaync/` in the
  repo-tree diagram — factually wrong about the current desktop, not historical
  prose. `env.lua:15-16` lists two retired packages among "native Wayland
  clients". By contrast `autostart.lua:186`, `windowrules.lua` and
  `quickshell-doctor:723` read correctly as rewritten retirement-lineage comments
  and must be left alone per D-21-19. Deliberately NOT chosen: promoting these to
  the blocking tier, which would re-arm the exemption interlock that stalled
  Phase 20's final plan.

### Gate blocking set

- **D-22-08:** **`theme-doctor` stops being informational in the container.** It
  blocks on everything except a committed allowlist of session-dependent failures.
  Rationale from measurement: at the last green run (`run-20260709T060703Z`)
  `theme-doctor` was 20 passed / 3 failed, and all three failures were genuinely
  session-dependent (`gsettings gtk-theme`, `walker process running`,
  `elephant process running`). Today `theme-doctor` is **578 checks**, the
  overwhelming majority file/lint checks that pass fine headless — so
  informational-only now discards roughly 575 checks of coverage inside the one
  environment that matters. Chosen over giving `theme-doctor` a `--headless` mode
  because that modifies the project's most load-bearing script during its closing
  regression phase.

- **D-22-09:** **The allowlist is derived by measurement, then justified at source
  level.** Run the container gate once informationally, read the *actual* failure
  list against today's 578 checks, then admit an entry only if it carries a
  structural reason read out of `theme-doctor`'s own source (no session bus / no
  compositor / no display / no user session). A failure with no such reason is a
  defect, not an exemption. This blocks the obvious failure mode — fitting the
  list to whatever happened to go red.

- **D-22-10:** **The allowlist is committed next to `container-run.sh`** and read
  by the harness, so a re-run months later enforces the same bar without anyone
  remembering the reasoning. Matches how `contract.json`, the `retirement-check`
  registry and `motion-lint`'s exemption list all work here: the rule is data the
  tool consumes, not prose someone has to honour. — **Reversibility:** reversible
  — one file plus its read site in the harness.

### Install scope

- **D-22-11:** **Container tier stays `install.sh --core-only`; the VM tier runs
  unflagged `install.sh`.** Measured: `--core-only` skips exactly two sections —
  `section_hardware` (NVIDIA via `lspci`, limine bootloader) and
  `section_personal` (git identity, timezone). Every package install, including
  `quickshell` and `cava`, lives in `section_core_rice` and always runs, and
  `verify_packages` hard-fails on that set. So the container's scope is already
  correct and needs no change.
  **The gap is `system/`:** a tracked tree
  (`system/usr/local/bin/kernel-module-verify`,
  `system/etc/pacman.d/hooks/99-kernel-module-verify.hook`) deliberately not
  stowed — `install.sh:698` installs it with `sudo install` inside
  `section_hardware`, and `install.sh:816` skips its verification under
  `--core-only` too. **Neither tier has ever installed it.** A VM is a real
  machine with a real bootloader, so an unflagged run there proves
  `section_hardware`'s non-NVIDIA path and installs `system/` for the first time
  in any reproduction proof.
  **This reverses D-61 for the VM tier** (`section_personal` writes git identity
  and timezone, skipped since v1.0 as "not meaningful, potentially wrong" in a
  disposable environment) — harmless on a machine deleted at VERIFICATION.md
  step 9, but it is a reversal and must be recorded as one, not slipped in.
  — **Reversibility:** reversible — a flag choice in a documented procedure.

### Sequencing

- **D-22-12:** **Baseline run first, on the unmodified harness, against today's
  `origin/main`.** One run does triple duty: it says whether the five deletions
  broke reproduction at all; it produces the real failure list D-22-09 requires;
  and it re-establishes whether the harness still works after sitting idle since
  July. Order: baseline → harness/checker changes → container re-run to green →
  VM tier. Explicitly rejected: modifying the harness first, which changes two
  variables at once and makes a failure unattributable between "the migration
  broke reproduction" and "the new harness code is wrong."
  **Harness state to expect:** last `overall=PASS` was `run-20260709T060703Z`
  (2026-07-09). Three later runs exist (`run-20260711T175822Z`,
  `run-20260714T102234Z`, and two more on 2026-07-14) and none records a verdict —
  the last one's `summary.log` stops after `step=clone status=ok`. Treat "does the
  harness itself still complete" as an open question, not an assumption.

### Claude's Discretion

- The exact file format of the committed session-failure allowlist (D-22-10) and
  the naming of the new dangling-symlink checker (D-22-06) are unconstrained —
  match the conventions of the neighbouring checkers.
- Whether the dangling-symlink sweep covers `$HOME/.config` only or also the
  other stow targets (`~/Pictures`, `~/.local`, `~/.config/systemd/user`) is a
  planning call; err toward covering every path `stow.sh`'s `PACKAGES` loop can
  write to.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The two proof tiers
- `verify/container-run.sh` — the D-34/D-36 container harness. Authored v1.0
  Phase 3, **untouched since**. Pulls a fresh `archlinux/archlinux` image,
  `git clone --depth 1` from `https://github.com/yahiaeng/dotfiles` (D-56),
  `install.sh --core-only` → `stow.sh` → `theme-parity`. `theme-doctor` runs
  informational only. Contains two post-mortems worth reading before editing it:
  the `run-20260708T220706Z` stdin-eating false pass, and the
  "never trust the container exit code alone" verdict logic.
- `VERIFICATION.md` (repo root) — the human-run graphical VM procedure (D-54),
  9 steps. §5 is the `--core-only` invocation D-22-11 changes; §6 and §8 are the
  stale sections D-22-03 rewrites; §7 states the pass condition D-22-02 amends;
  §9 is the teardown. The NOPASSWD scoping warning at the top is load-bearing.
- `verify/logs/run-20260709T060703Z/` — the last `overall=PASS` evidence, incl.
  `05-theme-doctor.log` (20 passed / 3 failed, the three session-dependent ones)
  and `summary.log`.

### Retirement machinery
- `hypr/.config/hypr/scripts/retirement-check` — two-tier checklist (RETIRE-01).
  `--all` / `--self-test` / `--list` / `--root <dir>`. Registry and the 16 classes
  are in the header; class 14 `host-package` (`pacman -Q`) is the one that makes
  D-22-05 work. D-18-37 explains why the report tier exists and why folding
  `.planning/` into blocking would make green unreachable.
- `hypr/.config/hypr/scripts/tests/retirement-fixtures/` — the 5 committed
  fixture trees; the model for D-22-06's new checker fixtures.

### Gates the container will block on
- `theme-engine/.config/theme-engine/theme-doctor` — 578 checks. Folds
  `motion-lint` (line ~461), `hypr-equivalence-check` (~485, live-session
  guarded), `colour-lint` (~520, no session guard needed). Read the fold comments
  before deriving the D-22-09 allowlist.
- `hypr/.config/hypr/scripts/hypr-equivalence-check` — compares binds /
  animations / options only (no monitor or hardware data). Baseline resolves to
  `.planning/phases/13.1-.../.hypr-baseline` if present, else
  `.planning/milestones/v3.0-phases/13.1-hyprland-lua-config-migration/.hypr-baseline`.
- `hypr/.config/hypr/scripts/motion-lint`, `hypr/.config/hypr/scripts/colour-lint`
  — the exemption-list and `--self-test` precedents D-22-06 and D-22-10 follow.

### Reproduction scripts under proof
- `install.sh` — `section_core_rice` (:421, always runs, all packages),
  `section_hardware` (:636, skipped under `--core-only`, installs `system/` at
  :698), `section_personal` (:737, D-61), dispatch at :783-800, `VERIFY_PKGS`
  hard-fail at :792.
- `stow.sh` — `PACKAGES` array at :19 (17 entries, `cava` and `quickshell`
  present, all five retired packages absent). The systemd-user-tree exception
  comment at :200-225 documents the three trees that escape
  `~/.config/<pkg>/`.
- `system/` — the never-yet-installed tree (`kernel-module-verify` +
  `99-kernel-module-verify.hook`).
- `quickshell/.config/systemd/user/quickshell.service` and
  `quickshell-bar-watchdog.service` — both deliberately carry **no `[Install]`
  section** so enabling can never write a wants-symlink outside the repo; their
  headers state this explicitly. `autostart.lua:104` starts them. Do not "fix"
  this into an enable step — it is the reproducibility guarantee, not an omission.

### Phase framing
- `.planning/ROADMAP.md` § Phase 22 — goal, the three success criteria, and the
  "the dev host will lie to you" note.
- `.planning/REQUIREMENTS.md:73` — RETIRE-09's text; :224 for its placement
  rationale.
- `.planning/PROJECT.md` § Key Decisions — the two-tier INST-03 gate decision,
  the human-render-gate decision, and "new stow packages must register in
  `stow.sh` in the same commit" (the `ags/` precedent).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `retirement-check --all`: already green (`failed_classes=0` across all 8
  registered surfaces, measured 2026-08-16). Needs no code change to serve
  D-22-05 — only a new call site inside the container script.
- `retirement-check`'s fixture + `--self-test` pattern, and `motion-lint` /
  `colour-lint`'s exemption-list pattern: the two templates D-22-06's new checker
  should be built from rather than inventing a shape.
- `container-run.sh`'s `log_step` helper and `summary.log` `step=<name>
  status=<ok|fail>` convention: new blocking steps slot in without changing the
  verdict logic.
- The `theme-doctor` fold pattern (`[PASS]`/`[FAIL]` line re-emission with a
  guarded skip when the checker is absent): D-22-06's fold follows it verbatim.

### Established Patterns
- **Every gate here is rerunnable, fixture-backed and self-testable.** A check
  that cannot be pointed at a fixture and proven to fail is not accepted (D-28).
- **Rules live as data the tool consumes**, not prose a human honours —
  `contract.json`, the retirement registry, `motion-lint`'s exemptions, the
  `hypr-equivalence-check` accepted-additions table. D-22-10 extends this.
- **Comments naming a retired surface are rewritten, never scrubbed** (D-21-19),
  and prose in this repo should name surfaces by requirement ID to avoid tripping
  the checkers (Phase 21's twice-repeated lesson).
- **Config-then-package, one commit** (WINDOWS #1) — applied five times this
  milestone.

### Integration Points
- `container-run.sh`'s in-container heredoc: where the `retirement-check` step,
  the dangling-symlink step and the `theme-doctor` allowlist evaluation are wired.
  Note the heredoc is single-quoted so nothing expands on the host, and the
  script runs from a file over the `/logs` mount (never stdin) — preserve both.
- `theme-doctor`: where D-22-06's checker folds in, alongside the existing three.
- `VERIFICATION.md` §5/§6/§7/§8: where D-22-02, D-22-03 and D-22-11 land.
- `origin/main`: the container's actual input. Clean tree and `HEAD == origin/main`
  (`aab9b2e`) at discussion time.

</code_context>

<specifics>
## Specific Ideas

- The phase opens on a **measurement, not a change** — run the harness as it
  stands and read what it says before touching a line of it.
- The allowlist must be defensible check-by-check from `theme-doctor`'s source,
  not from what happened to go red.
- `README.md` advertising a deleted package as this desktop's notification daemon
  is a known, already-identified defect to fix during the SC-3 review pass — not
  a discovery the phase needs to make.

</specifics>

<deferred>
## Deferred Ideas

- **Giving `theme-doctor` a real `--headless` mode.** Considered and set aside for
  D-22-08's allowlist approach, because it would modify the project's most
  load-bearing script during its closing regression phase. Genuinely the cleaner
  long-term shape if a second headless caller ever appears — candidate for v5.0.
- **Promoting stale-prose hits from `retirement-check`'s report tier to blocking.**
  Rejected here (D-22-07) because it re-arms the exemption interlock that stalled
  Phase 20's final plan. Revisit only with a design that distinguishes
  "historical lineage comment" from "current factual claim".
- **A `section_hardware`-without-`section_personal` entry point in `install.sh`.**
  The most precise answer to D-22-11, declined because this phase's job is to
  prove `install.sh`, not restructure it.

### Reviewed Todos (not folded)
- **`2026-08-15-brightness-osd-unverifiable-on-desktop.md`** — "Brightness OSD
  path cannot be verified on this host — laptop-only, unproven" (area: shell,
  match score 0.6). Not folded: it matched on generic keywords
  (cannot/host/only/config), it is a hardware-availability gap (no backlight
  device on this host, already authorised as NOT-DEMONSTRABLE by D-18-39 on
  GATE-02's B.3 row), and ROADMAP.md states explicitly that Phase 22 carries no
  debt at all. Remains a pending todo for a future milestone.

</deferred>

---

*Phase: 22-Fresh-Install Proof*
*Context gathered: 2026-08-16*
