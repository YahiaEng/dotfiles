---
quick_id: 260826-npc
slug: fix-retirement-check-cross-package-refs-
date: 2026-08-26
status: in-progress
---

# Quick task 260826-npc — retirement-check stops matching its own prose

## Objective

`theme-doctor` has not returned a clean run since 2026-08-23 because
`retirement-check`'s `cross-package-refs` class matches **comments**. Teach the
class to ignore whole-line comments, and re-poison the self-test fixture that
was relying on a comment to prove the class can fail.

## Measured baseline (before any edit)

`retirement-check --all`, run unpiped, exits **1** with **two** failing classes
— the pending todo named only the first:

```
[FAIL] waybar/cross-package-refs: 2 reference(s)
    quickshell/.config/quickshell/modules/bar/TrayCapsule.qml:2
    quickshell/.config/quickshell/modules/bar/qmldir:51
[FAIL] walker/cross-package-refs: 1 reference(s)
    quickshell/.config/quickshell/modules/settings/common/WallpaperTile.qml:50
```

All three are whole-line comments, and none of them is a reference to the
retired surface at all:

- `TrayCapsule.qml:2` — `// Reinstates StatusNotifierItem hosting, lost when waybar was retired`
- `qmldir:51` — `# to register once waybar (the prior SNI host) was retired, so their`
- `WallpaperTile.qml:50` — `// `rowFocused` is written externally by the focus walker, and`

The third is the sharpest case: the token matched is the English word
**"walker"** in the phrase *"the focus walker"*. No rewording rule survives
that — the gate has to stop reading prose.

Across all 11 registry surfaces, `cross-package-refs` currently reports these 3
hits and nothing else, so the class has **zero true positives** to lose.

`retirement-check --self-test` baseline: **5 passed, 0 failed**, exit 0.

## Approach — Option 1 from the todo, scoped to one class

The todo listed three options; Option 1 (teach the gate to skip comments)
closes the failure class, the other two close only the instance.

Mirrors the existing precedent in this tree rather than inventing one:
`motion-lint:148-203` and `colour-lint:179-197` already carry newline-preserving
comment strippers, written newline-preserving precisely so `file:line` citations
stay accurate. Same property is required here.

**Deliberately narrower than those two:** they strip comments *inline*, because
they hunt for values that can sit mid-line. This class hunts for a name, and a
name that appears in real code always has code on its line. So this strips
**whole-line comments only** — a line whose entire content is a comment. A
trailing comment after code is left alone. That cannot delete code, which is
what makes it safe to put behind a blocking-tier gate.

**Scoped to `cross-package-refs` alone.** Opt-in parameter, one caller. The
other fifteen classes are unchanged: a commented-out `exec-once = waybar` in
`autostart.lua` is still a leftover that class should fail on.

## The trap this plan exists to avoid

`tests/retirement-fixtures/poisoned-stray-cross-script-ref/kitty/kitty.conf`
carries its poison **on a comment line**:

```
# fixture: poisoned — an unrelated script namechecks retirement-fixture here
```

That is the fixture's only cross-package reference. Ship the stripper alone and
the fixture goes green, the self-test's `poisoned-stray-cross-script-ref:1`
expectation fails, and the blocking gate loses its own proof-of-failure. The
fixture must be re-poisoned with a **non-comment** reference in the same commit.

## Tasks

1. **`_is_comment_line()` + opt-in `skip_comment_lines` on `grep_hits()`**, wired
   only from `scan_cross_package_refs()`. Handles `//`, `/* … */` spans, `#`,
   `--` (incl. `--[[`) and `<!--`. Whole-line only.
2. **Re-poison the fixture** — move the token out of the comment and into a real
   `kitty.conf` config line, and say in the fixture why it must not go back.
3. **Re-falsify**: self-test must stay 5/0; break the new predicate and confirm
   the fixture fails; restore.
4. **Bookkeeping** — retire the pending todo; correct STATE.md's stale claim that
   `yazi.desktop`'s `Terminal=true` is still open (260826-6o1 closed it).

## Out of scope

Three interactive checks carried in STATE.md remain operator-only — no
pointer-injection tool exists on this host: the settings category drill-in, the
Browse dialog's own controls, and scroll-stutter on live wallpaper tiles.

`quickshell-doctor --self-test` is not run here: it is a live probe that
restarts the shell. `retirement-check --self-test` is a pure file scan and is
run in full.
