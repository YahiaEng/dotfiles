---
quick_id: 260826-npc
slug: fix-retirement-check-cross-package-refs-
date: 2026-08-26
status: complete
commits:
  - 882fea85  fix(retirement-check): stop cross-package-refs matching its own prose
  - 13a0cb89  test(retirement-check): cover the comment filter the self-test cannot see
files_modified:
  - hypr/.config/hypr/scripts/retirement-check
  - hypr/.config/hypr/scripts/tests/retirement-fixtures/poisoned-stray-cross-script-ref/kitty/kitty.conf
  - hypr/.config/hypr/scripts/tests/test-retirement-comment-filter.sh (new)
  - .planning/todos/completed/2026-08-26-retirement-check-matches-own-prose.md (moved)
  - .planning/STATE.md
---

# 260826-npc — retirement-check stops matching its own prose

`theme-doctor` returns a clean run again: **1168 passed / 2 failed → 1218 / 0.**

## The todo undercounted, and the extra case decided the design

The todo named one failing class. A measured `--all` showed **two**:

| class | hit | what actually matched |
|---|---|---|
| `waybar/cross-package-refs` | `bar/TrayCapsule.qml:2` | `// ...lost when waybar was retired` |
| `waybar/cross-package-refs` | `bar/qmldir:51` | `# ...once waybar (the prior SNI host)...` |
| `walker/cross-package-refs` | `settings/common/WallpaperTile.qml:50` | `// ...the focus walker, and` |

The third is the one that settles it. The token matched is the **English word**
in the phrase *"the focus walker"*. The todo's Option 2 (reword the comments)
and Option 3 (path exemption) both assume the reference can be reworded or
enumerated away; neither survives an ordinary English word appearing in prose.
Option 1 — teach the gate to stop reading prose — was the only one left standing,
which is what the todo already suspected and what measurement confirmed.

Across all 11 registry surfaces the class had exactly these 3 hits and nothing
else, so it had **zero true positives to lose**.

## What shipped

`comment_line_filter()` + an opt-in `skip_comment_lines` on `grep_hits()`, with
exactly one caller: `scan_cross_package_refs()`.

Mirrors `motion-lint:148-203` / `colour-lint:179-197` rather than inventing a
mechanism — but **deliberately narrower**. Those strip comments *inline*, because
they hunt for values (durations, hexes) that legitimately sit mid-line. This class
hunts for a **name**, and a name that appears in real code always has code on its
line with it. So only a line whose *entire* content is a comment is skipped; a
trailing comment after code is still scanned.

That distinction is the whole safety argument: **the filter can never suppress a
line that carries code.** That is what makes it acceptable under a blocking-tier
gate.

Two boundaries chosen for the same reason. `#` and `--` require a following
space/tab/EOL, so `#waybar { }` — a real CSS id selector, a real surviving
reference — and `--waybar-compat` still scan. `;`, `%` and `!` are not recognised
at all: nothing in this tree uses them, and each one added is another way for a
real reference to be waved through.

Scoped to one class on purpose. A commented-out `exec-once = waybar` in
`autostart.lua` is a leftover that the `autostart` class is *supposed* to fail on,
not prose about one. The other fifteen classes are untouched.

## The trap, caught by running the gate at the midpoint

`poisoned-stray-cross-script-ref`'s **only** cross-package poison was itself a
comment line (`kitty/kitty.conf:1`). Shipping the filter alone turned that fixture
green — measured, not predicted: the self-test dropped to **4 passed / 1 failed**
at exactly that point, and the blocking gate lost its own proof it can still fail.

The token now sits on a real `kitty.conf` `map` line, in the **same commit** as the
filter, and the fixture's header says why it must stay out of the comment.

## A coverage hole was found and closed

With `comment_line_filter()` stubbed to `return False`, **all five fixtures still
returned their expected verdicts** — 5 passed / 0 failed. The fixture self-test
proves the *classes* fire; nothing proved the predicate's own boundaries.

`tests/test-retirement-comment-filter.sh` now covers them: 21 cases, exec'ing the
shipped definitions straight out of the gate rather than a retyped copy. The
negatives are the point — the CSS id selector and the trailing-comment-after-code
cases are the ones whose regression would make the gate go green over a dirty tree.

It spells **no registry surface name anywhere, comments included**: `tests/` is
scanned by the `test-fixtures` class *without* the comment filter (that class is
meant to match comments), so a real surface name in prose there would red-light
that class for that surface. Placeholder `retired-thing` is in no registry.

## Evidence — every gate run unpiped

| gate | before | after |
|---|---|---|
| `retirement-check --all` | exit 1, 2 failing classes | **exit 0**, 144 PASS, 0 FAIL |
| `retirement-check --self-test` | 5 passed / 0 failed | 5 passed / 0 failed |
| `test-retirement-comment-filter.sh` | (did not exist) | 21 passed / 0 failed |
| `theme-doctor` | 1168 passed / 2 failed | **1218 passed / 0 failed**, exit 0 |

**Falsified in three directions, not asserted:**

1. Stub the predicate to `return False` → the exact three original hits return,
   `--all` exits 1. Restore → exit 0.
2. Drop the space-requirement on `#` (over-eager) → exactly the two CSS-selector
   cases fail, unit test exits 1. Restore → 21/0.
3. Ship the filter without re-poisoning the fixture → self-test 4/1. Re-poison →
   5/0.

## Also corrected

STATE.md claimed `yazi.desktop`'s `Terminal=true` was an open item. It was already
closed when that line was written: 260826-6o1 shipped `yazi-terminal.desktop` and
`nvim-terminal.desktop` (`Terminal=false`, routed through
`/usr/local/bin/open-in-terminal`), both verified installed on the host, and
`AppsPage.qml:407` drops raw `Terminal=true` entries outright rather than offering
one behind a "(needs a terminal)" label. The stale claim survived by being carried
forward verbatim from 260826-437's `stopped_at`, which 6o1 superseded.

## Not done, and why

`quickshell-doctor --self-test` was **not** run. It is a live probe that restarts
the shell; it stays operator-only. `retirement-check --self-test` is a pure file
scan and was run in full at every step.

Three interactive checks remain operator-only — no pointer-injection tool exists
on this host: the settings category drill-in, the Browse dialog's own controls,
and scroll-stutter on live wallpaper tiles.
