---
created: 2026-08-26
source: quick task 260826-th1
severity: low
blocking: false
status: resolved
resolved: 2026-08-26
resolved_by: quick task 260826-npc
---

# retirement-check flags its own explanatory prose (waybar)

`theme-doctor` reports **2 failures**, one of which is:

```
[FAIL] retirement-check: waybar/cross-package-refs: 2 reference(s)
    quickshell/.config/quickshell/modules/bar/TrayCapsule.qml:2
    quickshell/.config/quickshell/modules/bar/qmldir:51
```

Both "references" are **prose comments**, not code. They explain *why* the
tray capsule was reinstated after waybar was retired:

- `TrayCapsule.qml:2` — "Reinstates StatusNotifierItem hosting, lost when
  waybar was retired (Phase 18 Plan 20, RETIRE-02)…"
- `qmldir:51` — "…apps that minimise to tray had nowhere to register once
  waybar (the prior SNI host) was retired…"

`git blame` puts both in quick task **260823-65s** (2026-08-23), so this
predates 260826-th1 and is unrelated to the Thunar work that surfaced it.

## Why it matters

The gate is matching its own explanatory text — the same failure class
already recorded for other grep-based gates in this repo (a banned-identifier
gate greps its own comment). While it stays red, `theme-doctor` never returns
a clean run, which trains the eye to ignore its output — the real cost.

## Options (not yet decided)

1. Teach `retirement-check` to skip comment lines for the
   `cross-package-refs` class (strip `//` and `#` lines before matching).
   Matches how other gates in this tree were fixed.
2. Reword the two comments to avoid the literal token — cheapest, but loses
   accurate history and the next person writing the same comment re-breaks it.
3. Add a scoped exemption for these two paths — narrowest, but exemptions
   accumulate.

Option 1 is the one that closes the class rather than the instance.

## Care needed

`retirement-check` is a blocking-tier gate. Any edit to it must be validated
with `quickshell-doctor --self-test` **by the operator** (it is a live probe
that restarts the shell), and watch for the `pipefail` + `grep -q` trap that
has flipped gate verdicts in this repo before.

---

## Resolved — 2026-08-26, quick task 260826-npc (`882fea85`, `13a0cb89`)

**Option 1, as this file recommended.** `cross-package-refs` now skips lines
whose entire content is a comment; the other fifteen classes are untouched.

**This file undercounted the problem.** A measured `retirement-check --all`
showed **two** failing classes, not one — `walker/cross-package-refs` at
`settings/common/WallpaperTile.qml:50`, where the matched token is the English
word in the phrase *"the focus walker"*. That case is what made Option 1 the
only defensible choice: options 2 and 3 both assume the reference can be
reworded or exempted, and no wording rule survives an ordinary English word.

**Narrower than the precedent this file pointed at.** `motion-lint` and
`colour-lint` strip comments *inline*, because they hunt values that sit
mid-line. This class hunts a name, and a name in real code always has code on
its line — so only whole-line comments are skipped and a trailing comment after
code is still scanned. The filter cannot suppress a line carrying code.

**The care note was right, and there was a second trap it did not name.** The
`poisoned-stray-cross-script-ref` fixture's only cross-package poison was itself
a comment line, so the filter turned the fixture green and the self-test dropped
to 4/1 — the blocking gate losing its own proof it can fail. Caught by running
the self-test at the midpoint. The poison now sits on a real `kitty.conf` config
line, in the same commit as the filter.

**A coverage hole was found and closed.** With the predicate stubbed to
`return False`, all five fixtures still returned their expected verdicts — the
self-test could not see the predicate at all. `tests/test-retirement-comment-filter.sh`
now covers its boundaries (21 cases, falsifiable).

`quickshell-doctor --self-test` was **not** run — it is a live probe that
restarts the shell, and remains operator-only. The gates that were run, unpiped:
`retirement-check --all` exit 1 → exit 0; `--self-test` 5/0 throughout;
`theme-doctor` 1168/2 → 1218/0.
