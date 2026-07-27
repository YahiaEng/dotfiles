# Phase 13 — Deferred Items (out-of-scope discoveries)

Items found during plan execution that are real but not caused by the executing
plan's own changes, per the executor's scope-boundary discipline (fix the tree
you're touching for your own reasons; log, don't fix, everything else).

## 13-02: `motion-curves` missing from `contract.json`'s `engine_owned_files` (found during Task 2 Step 0)

- **Found during:** 13-02 Task 2, Step 0 (D-18 soak-baseline capture)
- **Introduced by:** Plan 13-01 (D-21's A/B curve-set toggle), not this plan
- **Issue:** `~/.local/state/theme/motion-curves` (written directly by
  `motion-switch.sh --curves <name>`, read by
  `theme_engine_read_motion_curves`) is not listed in `contract.json`'s
  `engine_owned_files` array. `commit.sh`'s `rsync -a --delete` therefore
  treats it as extraneous state-dir content on every single `theme-apply`
  run and deletes it — this is the exact "engine-owned file forgotten in the
  exclude list" bug class `commit.sh`'s own comment block documents eight
  prior instances of (motion-scale, the ninth, was added correctly in 13-01;
  motion-curves, the tenth, was missed).
- **Confirmed empirically (not reasoned):**
  ```
  $ echo "legacy" > ~/.local/state/theme/motion-curves
  $ ~/.config/theme-engine/theme-apply catppuccin   # exit 0, "ok"
  $ ls ~/.local/state/theme/motion-curves
  ls: cannot access '.../motion-curves': No such file or directory
  ```
  The file is written, then silently deleted by the very next commit —
  including the commit *inside the same `theme-apply` invocation* that was
  supposed to apply it.
- **Practical impact:** `motion-curves` always reads back as its default
  (`md3`) after any `theme-apply`/`motion-switch.sh` call, because
  `theme_engine_read_motion_curves` treats "file absent" as "use default".
  D-21's A/B toggle (`motion-switch.sh --curves legacy`) therefore appears to
  work for exactly one render (the render inside the same invocation that
  wrote the file) and then silently reverts to `md3` on every subsequent
  render — a real defect in the soak's own measuring instrument.
  **Currently benign for the running D-19 soak**: the soak's pinned curve-set
  is `md3`, which is also the read-default, so this bug happens to be
  unobservable at the soak's current settings. It becomes observable the
  moment anyone runs `motion-switch.sh --curves legacy` for an A/B
  comparison and expects it to persist across a second render.
- **Not fixed here:** out of scope for 13-02 per the executor's scope
  boundary (Rule 1-3 auto-fixes are limited to issues directly caused by the
  current task's own changes; this predates 13-02 and was introduced by
  13-01). `contract.json` is in 13-02's `files_modified` list, but only for
  the two new format-validated `files` entries (`_motion.scss`,
  `swaync-style.css`) Task 3 adds — not for `engine_owned_files` maintenance
  unrelated to this plan's own surface.
- **Suggested fix (for whoever picks this up):** add `"motion-curves"` to
  `contract.json`'s `engine_owned_files` array, one line, same shape as the
  `motion-scale` entry immediately above it. Falsifiable the same way it was
  found: write the file, run `theme-apply`, confirm it survives.
- **Owner:** unassigned — surfaced here rather than in a specific plan's
  `files_modified` list since no remaining Phase 13 plan currently touches
  `contract.json`'s `engine_owned_files` for an unrelated reason. Candidate
  for a quick task, or for plan 13-07 (which already touches `motion.json`'s
  `curve_sets` removal and is a natural place to notice the toggle one more
  time before it's deleted).

## 13-02: unlocalized `read -r name` loop in `lib/motion.sh` silently clobbers `theme_engine_generate`'s `name` parameter (found while proving the D-31 poisoned-fixture test)

- **Found during:** 13-02 Task 3, proving theme-parity's D-31 byte-identity
  walk can fail (a poisoned-fixture test keyed off `$name` inside
  `theme_engine_generate` silently read as empty instead of the target name)
- **Introduced by:** Plan 13-01 (D-21's `$motion_speed_indicator_<name>`
  Hyprland-variable emitter in `theme_engine_render_motion_files`), not this
  plan
- **Issue:** `lib/motion.sh`'s indicator-duration loop —
  `while IFS=$'\t' read -r name ms; do ... done <<< "$speed_indicators"` —
  declares its loop variable `name` with **no `local`**. `theme_engine_generate`
  (in `lib/generate.sh`) has its own `local name="$1"` and calls
  `theme_engine_render_motion_files "$tmp"` directly (not in a subshell) partway
  through its body. Because bash's `local` variables are dynamically scoped, an
  unlocalized `read -r name` inside a function called from within
  `theme_engine_generate`'s own scope does not create a new variable — it
  silently overwrites `theme_engine_generate`'s own `local name`, which is
  never reset afterward.
- **Confirmed empirically (not reasoned):** added a temporary,
  never-committed debug line at the end of `theme_engine_generate`
  (`if [[ "$name" == "dracula" ]]; then ...`) and traced execution with
  `set -x`. The trace showed `+ [[ '' == dracula ]]` — `$name` had already been
  silently reset to empty by the time execution reached the end of the
  function, even though `theme_engine_generate` was invoked with
  `name="dracula"` as its first argument and never reassigns it itself.
  Root-caused to the exact `read -r name` loop cited above by grepping every
  sourced file for an unlocalized `name` variable.
- **Practical impact:** currently **inert** — no production code path in
  either the pre-13-02 or the 13-02 codebase reads `$name` again inside
  `theme_engine_generate` after `theme_engine_render_motion_files` is called
  (the only use after that point was this plan's own temporary,
  never-committed poisoned-fixture debug line, which was rewritten to key off
  an environment variable instead specifically to route around this bug — see
  13-02-SUMMARY.md). It is a live landmine for the next person who adds code
  after the motion-render call site that reads `$name` (or, more generally,
  who calls any function sharing a common local-variable name without adding
  `local` to it) — a "false-pass generator" in the same family WR-05's
  identical-shaped `hypr-vars` fix already named once in this codebase (see
  the sibling finding above and 13-02-SUMMARY.md's Deviations section).
- **Not fixed here:** out of scope for 13-02 per the executor's scope
  boundary — introduced by 13-01, and no shipped 13-02 code path is affected
  by it (the affected debug scaffolding was never committed). `lib/motion.sh`
  is in 13-02's `files_modified` list, but only for the new
  `theme_engine_render_motion_scss`/`theme_engine_compile_gtk3_stylesheets`
  writers Task 2 adds — this pre-existing loop is unrelated code this plan
  did not otherwise need to touch.
- **Suggested fix (for whoever picks this up):** add `local` to the loop
  declaration — `while IFS=$'\t' read -r name ms; do` becomes
  `while IFS=$'\t' read -r name ms; do` preceded by `local name ms` (or
  simply `local -r name`/rename the loop variable to something
  indicator-specific, e.g. `ind_name`, to avoid the collision class
  entirely rather than relying on every future caller never sharing the
  identifier). Falsifiable the same way it was found: call
  `theme_engine_generate` directly, print `$name` after
  `theme_engine_render_motion_files` returns, confirm it is unchanged.
- **Owner:** unassigned — candidate for whichever plan next touches
  `lib/motion.sh`'s indicator emitters (13-05 already touches
  `GTK3_SCSS_TARGETS` in the same file) or a quick task.
