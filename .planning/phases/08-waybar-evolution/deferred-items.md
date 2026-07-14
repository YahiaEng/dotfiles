# Deferred Items — Phase 08 (waybar-evolution)

Out-of-scope discoveries logged during plan execution, per the executor's
SCOPE BOUNDARY rule (only auto-fix issues directly caused by the current
task's changes; pre-existing unrelated issues are logged here, not fixed).

## 08-06: theme-doctor's "git status --porcelain is empty" check fails due to pre-existing dirty files

**Found during:** 08-06, Task 5 verification (`theme-doctor` run).

**Not caused by 08-06.** These three paths were already dirty/untracked at
the start of this execution session, before any 08-06 task touched the
repo:

- `wallpapers/Pictures/Wallpapers/current.jpg` (modified, tracked)
- `.planning/phases/07-super-key-menu/07-VERIFICATION.md` (untracked)
- `csv` (untracked, repo root)

None of these are `files_modified` in 08-06's plan, and none were touched
by any 08-06 task. `theme-doctor`'s git-clean check
(`theme-engine/.config/theme-engine/theme-doctor` line ~301) requires the
**entire** `dotfiles` repo tree to have zero `git status --porcelain`
output — a single unrelated dirty file anywhere in the repo fails this one
check regardless of what the theme pipeline itself is doing correctly.

**Not fixed** — out of scope for 08-06. All 40 other theme-doctor checks
pass, including the new `eww.scss` contract-file-existence check this plan
adds. Whoever picks up phase 07's verification doc or the stray `csv`
file/wallpaper change should re-run `theme-doctor` afterward to confirm
this single check clears once the tree is genuinely clean.

## 08-03: `stow.sh` aborts early on a pre-existing vscodium conflict, before reaching the new waybar-visibility.css seed line

**Found during:** 08-03, Task 1 verification (`./stow.sh` run).

**Not caused by 08-03.** `~/.config/VSCodium/User/settings.json` is a real
file on this host (not a stow symlink), so `stow --restow vscodium`
reports "cannot stow ... since neither a link nor a directory and --adopt
not specified" and exits non-zero. Under `stow.sh`'s `set -euo pipefail`,
this aborts the whole script mid-loop — the exact same pre-existing issue
08-01-SUMMARY already documented ("stow.sh aborted early on a pre-existing,
unrelated vscodium conflict (not caused by this plan)").

**Consequence for this plan:** the new seed line added to `stow.sh`
(`~/.local/state/theme/waybar-visibility.css`, seed-only-when-absent) is
never reached by a live `./stow.sh` run on this host, since `vscodium` is
stowed before `waybar`'s cache-init section runs. Verified correct
behavior instead by running the exact seed snippet in isolation against
the real `$HOME` (mkdir -p + create-if-absent), confirming: (1) the file
is created when absent, (2) a second run with a non-empty dim rule already
present leaves the content untouched (seed-only-when-absent, not clobber).
See `08-03-SUMMARY.md` for the verification transcript.

**Not fixed** — fixing the vscodium settings.json ownership conflict is
out of scope for 08-03 (waybar-only plan) and not in its `files_modified`
list. Whoever resolves the 08-06-logged vscodium/dirty-tree item should
also confirm a full `./stow.sh` run reaches and passes the waybar cache-init
section end-to-end.

## 08-07: orphaned `media-player.py` + `config-floating.jsonc:52` duplicate media surface

**Found during:** 08-07, `<inherited_contracts>` review (explicitly flagged as
"informational, not this plan's work" by the plan itself).

**Not caused by 08-07.** `waybar/.config/waybar/config-floating.jsonc:52`
still runs a `custom/media-player` module backed by the orphaned upstream
sample script `hypr/.config/hypr/scripts/media-player.py`. This is a
second, older media surface living in 08-01/08-05/08-08's file territory —
08-07 built the real, hardened media center (`media-*.sh` + the
`media-popup` eww window) as an independent implementation, per D-24's
"not a port" instruction, and deliberately did not touch waybar configs or
`media-player.py`.

**Not fixed** — out of scope for 08-07 (no waybar config in this plan's
`files_modified`). Whoever executes 08-08 (wiring the `mpris` bar segment
to `media-popup`) should delete `config-floating.jsonc:52`'s
`custom/media-player` module and `media-player.py` under "one surface per
job," so the phase ends with exactly one media surface, not two.

**08-08 resolution (superseded, documented for the record):** the actual
`08-08-PLAN.md` (written after this note, with fuller context) explicitly
overrides this suggestion: its `<critical_finding>` and acceptance criteria
require touching **only** `custom/media`'s `on-click` key in floating —
`exec` (`media-player.py`), `format`, `format-icons`, `escape`,
`max-length`, `interval`, `return-type`, and the scroll bindings must stay
byte-identical. Rationale (not stated explicitly in 08-08-PLAN.md but
consistent with D-22): floating has no `mpris` module at all, so deleting
`custom/media`/`media-player.py` outright would leave floating with **no**
media segment whatsoever, breaking BAR-04's "accessible from every layout"
requirement for that one layout. 08-08 therefore re-points `on-click` on
the existing `custom/media` module (which turned out to be a single
shared `modules.jsonc` definition, referenced — not privately copied — by
floating; see `08-08-SUMMARY.md`'s Step A finding) rather than deleting it.
`media-player.py` remains in place, now polled for its glyph/text output
only — the popup opener button became the click target, matching every
other layout's `mpris` segment.
