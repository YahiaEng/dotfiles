# Deferred Items — Phase 22 (fresh-install-proof)

Out-of-scope discoveries found during plan execution, logged per the
executor's scope-boundary rule (only auto-fix issues directly caused by the
current task's own changes; pre-existing debt in unrelated files is logged,
not fixed).

## Resolved in Plan 22-08 (2026-08-17)

Plan 22-02's real-host sweep (below, historical) reported **1095 findings**
under the checker as originally scoped. Plan 22-08 found that figure was
overwhelmingly a sweep-SCOPE defect, not real host debt, and closed it in
three steps:

1. **Fixture self-reference (phase-blocking, 5 findings).** The hypr
   package deploys `stow-link-check`'s own committed test fixtures to
   `~/.config/hypr/scripts/tests/stow-link-fixtures/` on every machine — a
   `.config`-recursive sweep reported its own deliberately-poisoned fixture
   links as real findings on every run, which would have failed
   `theme-doctor` on every fresh install forever. Fixed with a scope
   exclusion (not an `EXEMPTIONS` entry — a deployed test fixture is out of
   the sweep's declared territory, not a link legitimately dangling by
   design).
2. **Sweep-root over-breadth (1085 findings).** `SWEEP_ROOTS` declared
   `.local` recursive and `.` (home root) as a blanket depth-1 walk, but
   only `vscodium` writes under `~/.local` (`.local/share/applications/`)
   and only `zshell` writes a top-level `$HOME` dotfile (`~/.zshrc`).
   The prior over-broad roots were catching **Steam's own runtime
   artifacts** under `~/.local/share/Steam/` (transient-by-design
   `SingletonLock`/`SingletonCookie`/`SingletonSocket` symlinks plus
   `steamrt32`/`steamrt64` shims), **podman's overlay storage** under
   `~/.local/share/containers/`, and `~/.steampath` — none stow-managed at
   all. `.config`'s recursive descent was also unconditional, catching
   **Zen browser's own profile lock file** (`~/.config/zen/<profile>/lock`)
   the one time it happened to exist. All four are now permanently out of
   the sweep's declared scope (not merely absent on this run) — the roots
   were narrowed to what `stow.sh`'s `PACKAGES` loop actually writes,
   re-derived directly against every package's shipped tree rather than
   trusted from the prior plan's broader declaration.
3. **Real repository debt (3 findings) — removed from the dev host.**
   `~/.config/swayosd` and `~/.config/wleave` were stale dangling symlinks
   into stow packages deleted from the repo in Phase 20 (RETIRE-04/05) but
   never unstowed on this particular long-lived machine.
   `~/.config/hyprland.conf.bak` similarly pointed at a path from before
   the Phase 13.1 Lua migration. All three were confirmed (`test -L` +
   non-resolving `test -e`) as pure dangling symlinks holding no data, then
   removed with plain `rm` (never `rm -r`). `stow-link-check` against the
   real `$HOME` now exits 0 with zero findings; `theme-doctor`'s stow-link
   fold passes; no live stow package link was disturbed.

**The 1095 figure is now historical** — it described the pre-22-08
checker's over-broad scope, not the repository's actual debt, which turned
out to be exactly the 3 items above. Current state: `stow-link-check`
reports 0 findings on this dev host, and RETIRE-09's symlink-absence clause
(SC-2) is provable clean here for the first time.

## Plan 22-02: `stow-link-check` real-host findings (2026-08-16) — historical

Running the newly-built `stow-link-check` (and, folded, `theme-doctor`)
against the actual dev host's real `$HOME` — not a fixture, not the
container/VM proof this checker exists for — surfaced **1095 real dangling
symlinks** under the checker's original (pre-22-08) scope, none of which
were caused by plan 22-02's own changes and none of which were reachable by
the container/VM tier (a fresh clone/VM has none of this accumulated
state). See "Resolved in Plan 22-08" above for the breakdown and
resolution — this section is kept for the historical record of what the
first real sweep found before the checker's scope was corrected.
