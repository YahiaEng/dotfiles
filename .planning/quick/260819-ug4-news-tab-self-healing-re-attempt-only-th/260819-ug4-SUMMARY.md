---
phase: quick-260819-ug4
plan: 01
subsystem: news-tab
tags: [news, quickshell, self-healing, cache]
status: complete
dependency-graph:
  requires: []
  provides:
    - "NewsBackend.qml self-healing retry (cache-derived, partial-run-safe)"
  affects:
    - "quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml"
tech-stack:
  added: []
  patterns:
    - "Retry set derived from cache contents, not in-memory failure state — restart-durable"
    - "Positive per-run record (_okNames) as the publish gate and carry-forward key, replacing a negative-only (_failedNames) key"
key-files:
  created:
    - "hypr/.config/hypr/scripts/tests/news-selfheal-gate"
  modified:
    - "quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml"
decisions:
  - "The retry set is derived from cache contents (_sourcesNeedingRetry(), configured sources with zero cached items), not from _failedNames, because the latter is in-memory-only and does not survive a shell restart, and cannot distinguish 'failed' from 'succeeded with zero items' — both read identically as a dead feed to the operator."
  - "_finishRun()'s publish gate and carry-forward now key on _okNames (positive per-run record) instead of the sourcesOk counter/_failedNames, because refresh() seeds sourcesOk with the deliberately-skipped healthy-source count for a partial run, which would let a counter-only gate wrongly publish a wholly-failed partial run."
  - "fetchedAtMs (the whole-cache TTL clock) advances only when _runSourceCount === root.sources.length — i.e. only on a whole run — so a partial run cannot push the TTL out or lie in the age readout."
metrics:
  duration: "~35 min"
  completed: "2026-08-19"
actuals:
  tokens: 48000
  tasks: 2
  commits: 2
---

# Phase quick-260819-ug4 Plan 01: News tab self-healing (retry-from-cache) Summary

Made the News tab re-attempt, on a centre-open inside a fresh whole-cache TTL, only the
configured sources with zero cached headlines — instead of skipping the entire refresh
whenever the whole cache reads as fresh, which previously let one failed source sit dead
until the TTL rolled over.

## What Was Built

**Task 1 — `NewsBackend.qml` reworked (commit `fb997af`).**

- New run state: `_okNames` (positive twin of `_failedNames` — sources that succeeded
  this run) and `_runSourceCount` (how many sources this run actually attempted).
- New helpers, declared above the two `FileView` blocks per this file's own
  declaration-order rule: `_sourcesNeedingRetry()` (configured sources with zero items
  in `root.items`, matched via `indexOf` on an array — not an object-as-map, to avoid the
  `constructor`/`__proto__` collision hazard) and `_carryForward()` (items to preserve:
  configured AND not in `_okNames`).
- `_fetchSource()`'s success branch now also pushes onto `_okNames`.
- `_finishRun()`: publish gate is now `_okNames.length > 0`; carry-forward calls
  `_carryForward()`; `fetchedAtMs` advances only when `_runSourceCount === sources.length`
  (a partial run logs that it deliberately left the timestamp alone); `_okNames` resets
  alongside `_runBuffer`.
- `refresh(force)`: centre-open guard and in-flight guard unchanged and first; the
  zero-valid-sources guard moved above the staleness gate; a `targets` list defaults to
  `root.sources` and narrows to `_sourcesNeedingRetry()` only when not forced and the
  cache is fresh (returning early, with a log line, when nothing needs retrying);
  `sourcesOk` is seeded to `sources.length - targets.length` so the "N of M sources
  unreachable" footer keeps counting M over every configured source.
- `abort()` now also resets `_okNames`/`_runSourceCount` so a centre-close mid-run can't
  leave a stale positive record.
- Header gained a new "Self-healing retry, derived from cache not memory" section
  recording the design decision and its trade-off (a persistently-empty legitimate
  source is re-attempted every centre-open — bounded by `maxSources`, logged, visible).
  The `_failedNames` property comment was corrected in place (no longer claims to be the
  carry-forward key).
- No timer of any kind was introduced; all three https enforcement points, `maxSources`
  (hard 8), and the clamped tunables are untouched.

**Task 2 — structural gate authored (commit `9a89f51`).**

- `hypr/.config/hypr/scripts/tests/news-selfheal-gate`, a `#!/usr/bin/env python3` script
  (matches this directory's existing Python-gate precedent — `keybind-source-equivalence`)
  that strips `//`-prefixed comment lines before matching, avoiding both of this repo's
  recorded gate failure modes (a grep matching its own comment prose; `grep -q` under
  `pipefail` exiting 141 and flipping a verdict).
- Five invariants, each printed as its own PASS/FAIL line: no `Timer {` construct; exactly
  one `_okNames.length > 0`; `if (!root.centreOpen)` within 200 characters of
  `function refresh(`; exactly one `fetchedAtMs = Date.now()` assignment guarded by
  exactly one `_runSourceCount === root.sources.length`; both new helpers declared above
  the first `FileView {`.
- Falsified by hand: replaced the whole-run condition with `if (true)`, confirmed the gate
  reported `FAIL: invariant 4` with the correct reason, then restored the file from a
  scratchpad backup and re-ran — clean PASS on all five, `git diff` showed no residual
  change (the restore matched the already-committed state exactly).

## Verification (Tasks 1-2)

```
$ qmllint modules/dashboard/NewsBackend.qml; echo "qmllint exit=$?"
qmllint exit=0

$ python3 -c "... helper declaration-order check ..."
PASS: both new helpers exist and are declared above the FileViews
exit=0

$ hypr/.config/hypr/scripts/tests/news-selfheal-gate; echo "gate exit=$?"
PASS: invariant 1 — no `Timer {` construct in the comment-stripped body
PASS: invariant 2 — exactly one `_okNames.length > 0` occurrence
PASS: invariant 3 — `if (!root.centreOpen)` appears within 200 characters of `function refresh(`
PASS: invariant 4 — exactly one `fetchedAtMs = Date.now()` assignment, guarded by exactly one whole-run condition
PASS: invariant 5 — both `_sourcesNeedingRetry` and `_carryForward` declared above the first FileView
gate exit=0

$ colour-lint | tail; motion-lint | tail
Summary: 150 passed, 0 checks failed
Summary: 297 passed, 0 checks failed
(no NewsBackend.qml findings in either lint's output)
```

## Deviations from Plan

None — Tasks 1 and 2 executed exactly as written. The falsification exercise required by
Task 2's `<done>` criteria was performed by hand-poisoning the whole-run condition
(invariant 4) rather than a different invariant; the plan named this as one acceptable
example ("for example deleting the whole-run condition").

## Known Stubs

None.

## Threat Flags

None — this plan's threat model (T-ug4-01..04, T-ug4-SC) covers the surface introduced;
no new network endpoint, auth path, or trust boundary was added beyond what the threat
model already registers. The retry set remains a strict subset of `root.sources`, reusing
`_fetchSource()`/the shared transport unchanged, so both downstream https enforcement
points still apply.

## Task 3 — OPERATOR-VERIFIED 2026-08-19

Exercise B and Exercise C both passed live. Evidence from `~/.cache/quickshell.log`:

```
8532: refresh() — cache fresh, 0 minute(s) old, every source has headlines — nothing to re-attempt
8533: refresh() — cache fresh, 0 minute(s) old, every source has headlines — nothing to re-attempt
8536: quickshell-launch.sh: starting 2026-08-19T22:17:23+03:00
8547: refresh() — cache fresh, 3 minute(s) old, but re-attempting 1 source(s) with no cached headlines: Phoronix
8548: carried 30 item(s) forward from 3 source(s) not refreshed this run: Hacker News: Front Page, Ars Technica, It's FOSS
8549: partial run (1 of 4 source(s)) — fetchedAtMs left unchanged
```

`news-cache.json` after the run: `fetched_at` still 22:13:53 — i.e. from BEFORE the
22:17:23 restart, so the partial run did not advance it — with items back to
10/10/10/10 across all four sources, so the healed source's items reached disk anyway.

Which must_haves this closes: retry set survives a restart (a fresh process with zero
in-memory failure state targeted Phoronix from cache contents alone); only the
zero-item source is fetched; the healthy sources are carried, not clobbered; a partial
run does not advance `fetchedAtMs`; a heal survives a restart. Exercise B independently
covers the no-op path — one log line, zero fetches.

Exercise A was NOT run as scripted, and is treated as subsumed: its three assertions
(targeted fetch of only the zero-item source, unchanged `fetched_at`, unchanged sibling
counts) are all demonstrated by Exercise C above. A only differs in how the zero-item
state is created — a source rename picked up via `watchChanges: true` rather than a
doctored cache plus restart — which is a trigger mechanism, not a property of the fix.

STILL NOT EXERCISED, recorded rather than implied: the all-attempted-sources-fail
partial run, whose expected behaviour is that `_okNames` stays empty, the publish gate
falls to the else branch and items/cache are left untouched. Reachable only with a
deliberately unreachable host.

BOUNDARY FOUND DURING VERIFICATION, from the operator's own log rather than reasoning:
a source that FAILS but still holds previously-cached items is NOT re-attempted, because
`_carryForward()` preserves those items and `_sourcesNeedingRetry()` keys on zero cached
items. Observed at lines 8508 -> 8531 -> 8532: Hacker News failed, its 10 items were
carried, and the next open reported "every source has headlines — nothing to
re-attempt". This is coherent with the defect this task targeted — a feed that reads as
DEAD, i.e. blank — but it is narrower than "retry anything that failed", and it means a
stale-but-populated source still waits out the TTL. Not a defect; a named boundary.

**Task 3 is a `checkpoint:human-verify` gated `blocking` and was NOT attempted by the
executor**, per this quick task's host prohibitions (no `qml6`, no compositor probes, no
screenshots, no self-restart of quickshell). It remains open.

**Precondition to check before starting:** quickshell is running
(`pgrep -f 'quickshell -p'` returns a pid) and
`~/.local/state/theme/news-sources.json` has at least two enabled sources, each with
cached headlines in `~/.local/state/theme/news-cache.json`.

**What the operator must do** (full detail in `260819-ug4-PLAN.md`'s Task 3
`<how-to-verify>`):

1. **Baseline** — record `fetched_at` and the per-source item counts from
   `news-cache.json`.
2. **Exercise A (self-heal fires, no restart)** — open/close the centre once to freshen
   the cache, rename one source in `news-sources.json` (e.g. `Phoronix` →
   `Phoronix Test`, live-reloaded, no restart), reopen the centre on the News tab, then
   check `~/.cache/quickshell.log` (`tail -40 ... | grep NewsBackend`) for: a "cache
   fresh, but re-attempting" line naming only the renamed source; a fetch for that one
   source only (no fetch lines for untouched sources); a carry-forward line; and a line
   confirming `fetchedAtMs` was deliberately not advanced. On screen: the renamed
   source's headlines return, other sources are unchanged, footer does not falsely read
   "unreachable". Re-check the baseline command — `fetched_at` must be unchanged. Rename
   the source back.
2. **Exercise B (no-op path)** — with every source healthy and cache fresh, reopen the
   centre and confirm a single "nothing to re-attempt" log line with zero fetch lines.
3. **Exercise C (restart durability)** — close the centre, doctor `news-cache.json` to
   strip one source's items while leaving `fetched_at` fresh, restart quickshell
   themselves (`systemctl --user restart quickshell` — the operator must do this, not an
   agent), reopen the centre, and confirm the self-heal fires for the doctored source even
   with no in-memory failure record.

**Resume signal:** the operator should reply "approved", or paste the `NewsBackend` log
lines showing what went wrong so the next session can diagnose from evidence rather than
a described symptom.

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml` (modified)
- FOUND: `hypr/.config/hypr/scripts/tests/news-selfheal-gate` (created, executable)
- FOUND commit `fb997af` (`feat(news): self-heal only the sources missing cached headlines`)
- FOUND commit `9a89f51` (`test(news): add structural gate for the self-healing retry invariants`)
