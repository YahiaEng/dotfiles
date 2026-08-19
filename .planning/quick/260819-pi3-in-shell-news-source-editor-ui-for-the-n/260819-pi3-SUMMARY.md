---
quick_id: 260819-pi3
date: 2026-08-19
mode: quick
status: complete
one_liner: In-shell manage-sources editor for the News tab — a gear chip opens a raised overlay listing every source (including disabled ones) with enable/disable toggle, inline rename, and a URL-keyed two-step delete confirm, plus a probe-gated add flow that fetches and validates a pasted feed URL before anything is written to news-sources.json and prefills an editable name from the feed's own title
actuals:
  tokens: 16712
  tasks: 4
  commits: 4
---

# Quick Task 260819-pi3 — Summary

## What shipped

All four tasks landed, in the load-bearing order the plan specified:

1. **`NewsBackend.qml` — mutation API and identity reconciliation.**
   `allSources` (readonly computed, includes disabled sources — `sources`
   projects them away and cannot drive an editor); `addSource()`,
   `removeSource()`, `renameSource()`, `setSourceEnabled()`, all through
   `_writeSources()` — the ONE surgical read-modify-write path, mirroring
   `setViewMode()`'s own refuse-on-malformed guard exactly (two writers now,
   both guarded, no shared mode flag, `setViewMode()` itself untouched).
   `validateName()` covers empty/long/duplicate-name (case-insensitive).
   Delete and disable both reset `selectedSource` when it matches the
   affected source, so the filter can never strand on a source the dropdown
   no longer lists. Rename moves the filter AND the already-fetched
   headlines with it (`_renameItemsOfSource()`). D-6's deferred-refresh flag
   (`_refreshWhenSourcesSettle`) is consumed by a handler on the readonly
   `sources` change signal, `Qt.callLater()`-ing the actual refresh — the
   same "child's binding lags the parent's own signal" deferral
   `onCentreOpenChanged` already uses, applied in the opposite direction.

2. **`NewsBackend.qml` — shared transport and the live probe.** Extracted
   `_fetchXml(url, onDone)`: the ONE place an `XMLHttpRequest` is
   constructed in the file now (measured: count stayed at 1). `_fetchSource()`
   rewired to call it, byte-equivalent in every counter/log-line effect.
   `probeSource()` is a second CALLER, never a second fetcher: it carries
   its own `probeState`/`probeReason`/`probeDetail`/`probeUrl`/`probeTitle`/
   `probeItemCount` register and — mechanically verified by an `awk`-scoped
   grep over just its own function body — never references
   `requestsInFlight`, `sourcesOk`, `sourcesFailed`, `_runBuffer` or
   `lastError`. It carries the D-32 centre-open gate. `_feedTitleOf()` reads
   the RSS `channel/title` or Atom `title` for the add-flow's name prefill.
   `abort()` resets an in-flight probe for free via the shared `_activeXhrs`
   registration.

3. **`NewsPane.qml` — the editor overlay.** A gear chip (icon-only,
   `settings` glyph) beside the existing filter and view-toggle chips. The
   overlay itself is an anchored, RAISED SIBLING of the headline list —
   never a layout child of `selectorHost` — on a higher `z` than the filter
   dropdown (structurally verified: the `selectorHost.bottom` anchor count
   went 3→4 and the `z` count went 1→2, while `chipRow` stayed a single
   `Row`), so opening it moves nothing. One row per source via `allSources`:
   a toggle glyph (`check_circle`/`radio_button_unchecked`, no confirm —
   reversible), an inline-rename name field, and a row-scoped two-step
   delete confirm keyed by URL (D-1/D-2), copying `WifiPanel.qml`'s Forget
   shape and its `TextField`-in-a-layer-surface precedent (explicit
   width/height, styled `background` only, two-stage Escape,
   `forceActiveFocus()` on show). D-4's pixel-side name cap
   (`Math.min(implicitWidth, _labelCapWidth)` + `ElideRight`) landed on the
   two previously-unbounded name labels: the filter chip's own label and
   the card meta capsule.

4. **`NewsPane.qml` — the two-stage add flow.** Paste a URL → live probe
   (`probeSource()`) → a probe-state line (spinner while probing, reusing
   the pane's existing ambient-loop spinner pattern; the mapped reason on
   failure; a headline count on success) → an editable name field seeded
   from the feed's own title → commit via `addSource(probeUrl, name)` — the
   PROBED url, never the live field text, so a URL edited after a
   successful probe cannot be committed under the stale probe's title. Any
   edit to the URL field calls `clearProbe()`. A hand-rolled placeholder
   (`Paste feed URL…`) rather than the control's own placeholder property,
   since that property's availability and colour knob on this Qt build are
   unmeasured and a hand-rolled one is fully `colour-lint`-safe.

## Deviation from the plan (Rule 3 — blocking issue)

**`_reasonText()` was moved from Task 4 into Task 3.** Task 3's own action
text requires the rename flow's Save handler to "render the mapped reason"
on a non-`"ok"` return — but the reason-code-to-sentence map (`_reasonText()`)
was specced as a Task 4 deliverable. Task 3 cannot render a real error
without it (and its own `<done>` criterion is "a placeholder-free overlay:
rows, toggles, rename and delete all working" — a bare reason CODE like
`"duplicate-name"` shown to the operator would not meet that bar). So
`_reasonText()`, covering every code the backend's mutation API AND the
probe can return, was written and committed as part of Task 3, and Task 4
simply reuses it unchanged for the add flow's probe-state and commit-error
lines. Task 4's own verify gate (`grep -c 'function _reasonText'` == 1) is
unaffected by which task defined it — the function exists exactly once at
the end of both tasks, and the per-code coverage gate
(`for c in scheme duplicate-url ... : grep -c "\"$c\""` >= 1 each) passes
because every code is present in the one definition. No other deviations —
every other line of every task's `<action>` was followed as written.

## Gates (actual output, not asserted)

Run after Task 1 alone, after Task 2 alone, after Task 3 alone, and after
Task 4 (full sweep) — re-run each time per this project's own standing
discipline, not just once at the end.

- **`qmllint`** — exit 0 on both changed files, every time it was run
  (after each of the 4 tasks).
- **`colour-lint`** — 150 passed, 0 failed, every run.
- **`motion-lint`** — 297 passed, 0 failed, every run.
- **Structural/grep gates** (declaration order, one-write-path,
  anchor-5 duck-typing, URL-keyed state, one-transport, probe-isolation,
  D-32 gate presence, overlay-sibling geometry, D-4 caps, QQC2 fence,
  `contentItem` never anchored) — every count matched the plan's own
  measured baseline and target exactly; two false-fails were caught and
  fixed before landing (see below), both **caused by my own explanatory
  comments accidentally repeating a gate's exact search token** — not
  gate-script defects.
- **Glyph gate (poison-tested)** — Task 3: `settings`/`close`/
  `check_circle`/`radio_button_unchecked` all shape to exactly 48.0px;
  poison `setting` (singular) shapes to 336.0px, proving the gate can fail.
  Task 4: `add`/`autorenew` both 48.0px; poison `adds` shapes to 96.0px.
  Both runs exit 0.
- **`quickshell-doctor`** — 28 passed, 0 failed (run after Task 3 and
  again after Task 4).
- **`theme-doctor`** — 592 passed, 2 failed, both **pre-existing and
  unrelated to this task's files**: (a) `walker process running` —
  measured directly, `pgrep -fa walker` returns nothing on this host right
  now (only `elephant` is running); walker/elephant are the app launcher,
  entirely outside this task's News-tab scope, and this was not caused by
  any edit here. (b) `git status --porcelain is empty` — fails because the
  working tree carries this task's own untracked
  `.planning/quick/260819-pi3-.../` directory until the docs commit lands;
  same caveat both `260819-m94`'s and `260818-v3m`'s own SUMMARYs recorded
  for the identical reason, resolves once the orchestrator's docs commit
  runs.
- **`theme-parity`** — 1721 passed, 0 failed.
- **`stow-link-check`** — 2 passed, 0 failed (48 symlinks under `.config`,
  1 under `.`, none dangling).
- **Live file check** — `jq -e '.sources | length == 4'` on
  `~/.local/state/theme/news-sources.json` returns true, and
  `jq '[.sources[] | select(.url | startswith("https://") | not)] | length'`
  returns 0 — the live file was never touched by any static-verification
  step, confirmed mechanically, not asserted.

### The two false-fails caught during execution (both self-inflicted, both fixed)

1. **`onSourcesChanged` count** (Task 1 gate expects exactly 1). My own
   explanatory comment on `_refreshWhenSourcesSettle` originally read
   "consumed by `onSourcesChanged` below" — literally repeating the gate's
   search token in prose, pushing the count to 2. Reworded to "consumed by
   the sources-changed handler below" (no literal token), count returned
   to 1.
2. **`_fetchXml(` count** (Task 2 gate expects exactly 3: declaration +
   the two call sites). A `console.log()` string in the transport's own
   synchronous-refusal branch read `"NewsBackend: _fetchXml() refused
   synchronously..."`, adding a 4th match. Reworded to "shared transport
   refused synchronously...", count returned to 3.
3. **`addSource(` count** (Task 4 gate expects exactly 1: the one commit
   call site). My own header comment for the add-flow section read
   "...but is fully editable — `addSource()` re-validates it regardless",
   adding a 2nd match. Reworded to "the backend's own commit mutator
   re-validates it regardless", count returned to 1.

None of these were gate-script defects — each was this executor's own
prose accidentally spelling out a banned/counted identifier, exactly the
class of trap this project's own standing rules warn about ("grep gate
matches its own comment"). Caught by re-running the gate immediately after
each edit, not by inspection.

## What was CUT (per the plan, stated plainly)

- **Drag-to-reorder.** Headlines sort by date and selection is round-robin
  by source (`_finishRun()`), so list order affects nothing but tie-breaks.
  Most QML-expensive item on the list, least load-bearing — cut as planned,
  not discovered as a gap.
- **Per-source tunables** (`max_items_per_source`, `ttl_minutes`, etc.)
  stay hand-edited. No UI was added for them.
- **The stow.sh seed block and the live host `news-sources.json`** were not
  touched by any code path this task introduced — the plan's own
  constraint, honoured. (The file's four existing sources were read
  during static verification via `jq`, never written.)

## Unverified — stated plainly, not implied as passing

**Every item in the plan's "Human verification (operator, after commit)"
section is unverified by this executor**, by design and per this session's
own standing constraint (no live shell restarts, no `grim` screenshots —
this host SIGSEGVs into Hyprland safe mode on a single capture, a
previously-recorded incident). That list (11 items) covers: the overlay
actually rendering over the headlines with nothing shifting underneath it,
the toggle/rename/delete verbs working end-to-end against the live
`quickshell` process, a real probe against `theverge.com`'s RSS feed and
against a non-feed URL (`example.com/`) and a non-`https` URL, the
eight-source-cap rejection, the two-stage-Escape behaviour, and survival
across a `systemctl --user restart quickshell`. All of these require
clicking through the live UI or restarting the shell, which this executor
did not do. What WAS verified is everything static: `qmllint`, every
structural/counting gate, the poison-tested glyph gate, the full
lint/doctor/parity/link-check sweep, and that the live JSON file's shape
and content are unchanged by any static-verification step.

## Files

- `quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml` —
  mutation API (`allSources`, `addSource`, `removeSource`, `renameSource`,
  `setSourceEnabled`, `validateName`), shared transport (`_fetchXml`),
  live probe (`probeSource`, `clearProbe`, `_feedTitleOf`), identity
  reconciliation, D-6 deferred refresh
- `quickshell/.config/quickshell/modules/centre/NewsPane.qml` — gear chip,
  manage-sources overlay (toggle/rename/delete rows), the two-stage add
  flow, `_reasonText()`, D-4 name-label caps

## Commits

- `b95c449` — Task 1: `feat(news): source mutation API and identity reconciliation in NewsBackend`
- `46e1e50` — Task 2: `feat(news): share one transport between the fetch run and a live feed probe`
- `8279891` — Task 3: `feat(news): in-shell source editor overlay with toggle, rename and delete`
- `813561c` — Task 4: `feat(news): probe-gated add flow with an editable feed-title name`

## Known Stubs

None. Every code path introduced is real: the mutation API writes through
the same guarded read-modify-write idiom `setViewMode()` already proves
live in production, the probe shares the exact transport the working
refresh path uses (not a parallel/mocked implementation), and the add
flow's commit step re-validates server-side regardless of what the UI
already checked. Nothing renders a placeholder value or a "coming soon"
string.

## Self-Check: PASSED

Both changed files confirmed present on disk. All 4 task commit hashes
(`b95c449`, `46e1e50`, `8279891`, `813561c`) confirmed present in
`git log --oneline --all`.
