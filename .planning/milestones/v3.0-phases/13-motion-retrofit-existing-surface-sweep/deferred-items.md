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
- **Owner:** plan 13-07, per operator decision (reassigned from unassigned
  during the between-plans 13-02/13-03 fix pass) — 13-07 already touches
  `motion.json`'s `curve_sets` removal and is a natural place to notice the
  toggle one more time before it's deleted.
  **Accepted tradeoff (operator-approved):** the D-21 A/B toggle remains
  non-persistent for the duration of the D-19 soak window. This is
  acceptable only because the soak is pinned at `md3` (identical to the
  read-default) — any `--curves legacy` comparison attempted before 13-07
  will silently revert after one render.

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
- **Resolved:** fixed in commit `aa4c425` (between-plans fix, 13-02/13-03
  gap) by renaming the loop variable to `ind_name`/`ind_ms` (not merely
  adding `local`, per the suggested-fix note above), plus the same rename
  applied to the two immediate sibling loops in the same Hyprland-writer
  block (`sem_token`/`sem_ms`, `curve_slot`/`curve_easing`), which shared
  the identical unlocalized generic-name shape. Verified falsifiably: the
  clobber was reproduced (empty `$name`) before the fix and confirmed
  resolved after, with the full rendered motion output tree byte-identical
  before/after. The WARN-pass loop (`token`/`clamped_flag`, reading
  `$resolved`) and the GTK4 `:root` writer loop (`token`/`ms`, also reading
  `$resolved`) in the same function have the same unlocalized generic-name
  shape but were left untouched — they are not immediate neighbours of the
  fixed loop (different source TSV, separate block) and no live collision
  was demonstrated for them; noted here for whoever next touches this
  function.

## Between-plans (13-04/13-05 gap): EXIT-trap signal gap — repo-wide sweep

- **Found during:** 13-04 Task 3 checkpoint forensics (root cause in
  `icon-theme-picker.sh`, fixed there in commit `5dfd9fd`, write-up in
  `7b386d0`); this entry records the follow-up sweep of the four sibling
  scripts identified as sharing the same trap shape.
- **Root cause (repo-wide):** bash only overrides a signal's default
  disposition for a signal it has an explicit `trap` on. A `trap '...' EXIT`
  does NOT install a `HUP` handler — a real pty hangup (closing the window
  a script is running in) terminates the process via the kernel's default
  action and bypasses bash's EXIT-trap machinery entirely, so cleanup
  registered only on `EXIT` silently never runs. Synthetic signal tests
  (`kill -HUP`, `timeout -s TERM`) do NOT reproduce this — only a real pty
  hangup does, which is why it survived until a real window-close was
  tested.
- **Fixed:** `font-switcher.sh` — same interactive fzf-in-floating-kitty
  class as `icon-theme-picker.sh` (launched via `font-switch.sh`'s
  `uwsm app -- kitty --class font-switcher ... -- font-switcher.sh`), so a
  real pty hangup on window close is directly reachable. Reproduced live
  with the real launcher and a real `hyprctl dispatch closewindow`: the
  unfixed script left `ENUM_SCRIPT`/`PREVIEW_SCRIPT`/`CACHE_DIR`
  (`/tmp/font-enum-*.sh`, `/tmp/font-preview-*.sh`,
  `/tmp/font-preview-cache-*/`) orphaned on disk every time. Applied the
  same `for _sig in HUP INT TERM; do trap "exit 1" "$_sig"; done` idiom and
  comment block `icon-theme-picker.sh` uses, re-verified against the real
  edited file with the same real launch/close cycle: artifacts confirmed
  gone.
- **Deliberately skipped, with reasoning (not silently):**
  - `color-picker.sh` — bound directly via Hyprland's `exec` dispatcher
    (`keybinds.conf`) and via elephant's menu `open` action
    (`elephant/.config/elephant/menus/utilities.toml`), never inside a
    terminal emulator. Confirmed live: launching it the real way and
    inspecting the running `hyprpicker` process shows `TT ?` (no
    controlling terminal at all) and no corresponding Hyprland client
    window — there is no pty to hang up, so the SIGHUP-on-window-close
    mechanism this bug class depends on cannot occur here. The EXIT trap
    here only removes `$ERR_FILE`, a single scratch file, on the only
    exit paths that actually exist for this process (normal completion or
    a directly-sent signal to the exec'd process itself, both of which
    DO already fire bash's EXIT trap since there's no separate pty layer
    involved).
  - `gif-export.sh` — invoked exclusively as
    `~/.config/hypr/scripts/gif-export.sh "$filename" &` inside an
    already-backgrounded, disowned subshell from `record-toggle.sh`'s
    notification-action click handler (swaync). No terminal wrapper
    anywhere in the repo launches it (grepped for any `kitty --class`
    invocation of it — none found). No controlling pty exists for this
    process, so the gap is unreachable.
  - `media-art-resolve.sh` — invoked as a plain subprocess call from
    `media-status.sh`'s `once`/`watch`/`position` modes, itself a
    background polling loop consumed by AGS's `deflisten` (no terminal,
    no window, no user-facing pty at all). No invocation site anywhere in
    the repo wraps it in a terminal emulator. Unreachable for the same
    reason as `gif-export.sh`.
  - All three skip decisions rest on the same falsifiable fact: the
    process has no controlling terminal (`ps -o tty` shows `?`), and
    SIGHUP-from-window-close is specifically a pty-hangup signal — there
    is no pty in these processes' ancestry for a window close to hang up.
    Trap-cost-is-free bias was considered and rejected here because these
    scripts have nothing analogous to "close" — adding the trap would be
    genuinely dead code, not defense in depth, since the signal path it
    guards against cannot exist in their invocation shape today.
- **Verification method:** real launcher + real `hyprctl dispatch
  closewindow` for the fixed script (font-switcher.sh), confirmed leaked
  before and clean after, both against the actual committed files, not a
  synthetic `kill`/`timeout` stand-in. Gates re-checked unchanged after the
  fix: `theme-doctor` 185/1, `theme-parity` 2163/0, `motion-lint` 41/0 (all
  at the same baseline recorded before this fix).
- **Owner:** resolved — no further action needed unless one of the three
  skipped scripts is later re-wired to run inside a terminal emulator, at
  which point this same trap idiom should be added at that time.
