# Deferred Items — Phase 22 (fresh-install-proof)

Out-of-scope discoveries found during plan execution, logged per the
executor's scope-boundary rule (only auto-fix issues directly caused by the
current task's own changes; pre-existing debt in unrelated files is logged,
not fixed).

## Plan 22-02: `stow-link-check` real-host findings (2026-08-16)

Running the newly-built `stow-link-check` (and, folded, `theme-doctor`)
against the actual dev host's real `$HOME` — not a fixture, not the
container/VM proof this checker exists for — surfaces **1095 real dangling
symlinks**, none of which are caused by this plan's own changes and none of
which are reachable by the container/VM tier (a fresh clone/VM has none of
this accumulated state):

- **Retired-package leftovers on this specific host** — `~/.config/swayosd`
  and `~/.config/wleave` are stale dangling symlinks into stow packages that
  were deleted from the repo in Phase 20 (RETIRE-04/05) but never
  unstowed/cleaned up on this particular long-lived machine.
  `~/.config/hyprland.conf.bak` similarly points at a path from before the
  Phase 13.1 Lua migration.
- **Steam's own runtime artifacts** under `~/.local/share/Steam/` (several
  hundred `SingletonLock`/`SingletonCookie`/`SingletonSocket`-style
  transient-by-design dangling symlinks, plus `steamrt32`/`steamrt64`
  runtime library shims) — not stow-managed at all, Steam's own behavior.
- **Zen browser's own lock file** (`~/.config/zen/<profile>/lock` — a
  standard Firefox-family profile lock symlink pointing at a
  host:pid string, dangling by design once the browser exits).

None of these are exempted by `stow-link-check`'s own (deliberately empty)
`EXEMPTIONS` list, because none are within the scope that list exists for
(a link this repo's own stow packages create that is legitimately dangling
by design). They are genuine host hygiene debt, unrelated to RETIRE-09's
actual question (does a *fresh* clone reproduce cleanly) and unrelated to
this plan's file scope (`hypr/.config/hypr/scripts/stow-link-check`, its
fixtures, `theme-engine/.config/theme-engine/theme-doctor`'s new fold).

**Not fixed here.** A future host-hygiene pass could `stow -D swayosd
wleave` remnants and prune the stale `.bak` file; Steam's and Zen's own
artifacts are not this repo's concern at all. Recorded so a bare
`theme-doctor` run on this specific dev host is not mistaken for a
regression introduced by this plan.
