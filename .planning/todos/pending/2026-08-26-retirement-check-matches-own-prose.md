---
created: 2026-08-26
source: quick task 260826-th1
severity: low
blocking: false
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
