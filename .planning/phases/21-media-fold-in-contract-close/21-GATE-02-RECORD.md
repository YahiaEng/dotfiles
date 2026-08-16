---
phase: 21-media-fold-in-contract-close
plan: 08
artifact: GATE-02 combined render + parity gate record
gate: "Task 1 — combined gate (parity checklist + rendered look), one sitting, one verdict"
verdict: PASSED WITH FIXES
judged_commit: 5f38a493e5be9bd9c66d632360c3d6a72876df0b
attested_by: operator (live, interactive walk)
date: 2026-08-16
---

# GATE-02 Record — Media Surface Replacement

Plan 08 Task 1's combined gate, walked live by the operator against the running
shell with the retiring AGS card still installed and summonable for side-by-side
comparison.

**Verdict: PASSED WITH FIXES.** Every parity row and every render check passes at
commit `5f38a49`. It was not a clean pass — the walk surfaced **twelve defects**,
all of them in rows the parity checklist already recorded as SATISFIED. Each was
fixed during the gate and re-verified by the operator before moving on.

---

## Honest statement about the judged tree

Plan 08 Task 1 asks this record to name "the commit SHA judged, so a later reader
can confirm nothing changed between the judgment and the deletion."

**That guarantee does not hold for this gate, and saying otherwise would be false.**
The tree moved continuously throughout the walk: twelve defects were found and
fixed as they surfaced, across ten commits from `74c9877` to `5f38a49`. The gate
was not a single judgment of a frozen tree — it was an iterative find-fix-reverify
loop.

What IS true, and what the deletion interlock should rest on:

- Every row and render check listed below was re-verified by the operator **after**
  its corresponding fix landed.
- The final state, `5f38a49`, is the state in which the operator confirmed the last
  outstanding item (player selection).
- No row is recorded as passing on a tree older than its own fix.

Task 3's precondition — `git diff --quiet 5f38a49 -- quickshell/.config/quickshell/`
— must therefore be evaluated **before** Task 3 makes its own comment-only edits to
`MediaTab.qml`, not after. Task 3 legitimately touches that path; the interlock is
about nothing having drifted between this record and the start of the deletion.

---

## Part A — Parity checklist

Walked row by row against the live AGS card (`ags request -i media toggle-media`)
with the replacement open alongside.

| Row | Capability | Result | Note |
|-----|-----------|--------|------|
| C-01 | Open/close the card | PASS | Two independent gestures on the replacement (dashboard tab, bar-hover popout) plus the new `Super+M` |
| C-02 | Click-away dismiss | PASS | Confirmed on both drawer and popout |
| C-03 | Escape dismiss | PASS | |
| C-04 | Now-playing metadata + empty-state fallback | PASS | |
| C-05 | Cover art + placeholder gating | PASS | |
| C-06 | Audio-reactive visualiser underlay | PASS (by supersession) | Judged as the 60-bar radial ring, not as a reproduction of the flat underlay. **Defect found and fixed:** ring stayed live around a paused source |
| C-07 | Transport: previous | PASS | **Defect found and fixed:** button was ungated on player capability |
| C-08 | Transport: play/pause | PASS | **Defect found and fixed:** FILL-axis jump made the glyph swap read as sudden |
| C-09 | Transport: next | PASS | Same gating defect as C-07 |
| C-10 | Seek (drag-to-position) + disabled state | PASS | **Defect found and fixed:** self-referential `value` binding made the bar resist the pointer and snap back |
| C-11 | Per-track seekability latch | PASS | Built in 21-07; the transient zero-length condition did not produce a seek-row flicker during the walk |
| C-12 | Volume slider (active player) | PASS | **Three defects found and fixed** — see below |
| C-13 | Player switcher (multi-source) | PASS | **Defect found and fixed:** selection silently no-opped, leaving the operator stuck on the first playing source |
| C-14 | Live re-color on theme switch | PASS | Both auto and manual-trigger paths |
| C-15 | Frosted/blurred look via layer rules | PASS | |
| C-16 | Nothing-playing / no active player no-op | PASS | |

`## Dead Definitions` rows (D-01 the unused opener, D-02 the unread `can_seek`
field) were excluded by construction and not judged, per the plan.

**Beyond-parity addition judged separately:** per-player volume in the switcher
dropdown. Not a parity obligation. It carried four of the twelve defects and now
works, including dragging a background player's volume without the selection
jumping to it.

---

## Part B — Rendered look

| Check | Result | Note |
|-------|--------|------|
| B-6 — 60 bars, each on its own band | PASS | Bass hit and cymbal visibly distinct |
| B-7 — ring settles to an even ring of slivers on silence | PASS | The silent-state equivalence the live-ring design was accepted on |
| B-8 — 12-lobe scalloped cover art, bars orbiting the lobes | PASS | |
| B-9 — **non-square art (16:9 and 3:4)** | PASS | Explicit re-opened clipping test. Art fills the lobed mask with no letterboxing and no distortion |
| B-10 — popout ring live; `pgrep -fc "cava -p .*/.config/cava/config"` == 1 with both surfaces open | PASS | Confirmed reporting exactly `1`, not `2` |
| B-11 — **dropdown with many players clips and scrolls** | PASS | **Defect found and fixed:** the dropdown had no scroll mechanism at all. Gate step count also corrected 6 → 8, see below |
| B-12 — pinned controls survive the panel at its tallest | PASS | Dropdown expanded plus long metadata |
| B-13 — `Super+M` opens the dashboard on the Media tab | PASS | |
| Carried debt — DND lit bell glyph (21-05, D-21-27-R) | PASS | Never seen live before this gate; cleared here |

### Gate step 11 corrected during the gate

The step as written asked for "six or more players". Measured against the
constants in force, the menu is `N*32 + 8` tall and opens upward from a pill top
at ~267, giving `y = 263 - menuHeight`: it fits through N=7 (232px, y=+31) and
only breaks at N=8 (264px, y=-1). **Six would have false-passed** — the operator
would have observed correct behaviour and ticked the row with the defect
untouched. The plan step was corrected to eight.

This is the same failure shape as D-21-27's spec earlier in this phase: a check
that verifies a true statement which is not the design requirement.

---

## The twelve defects

All twelve sat in rows the parity checklist marked SATISFIED. **Not one was
visible by reading the code for "is the mechanism present and wired."** Every one
required the gesture to actually be performed.

| # | Defect | Root cause | Fix |
|---|--------|-----------|-----|
| 1 | Volume sliders inert on background rows | Row `MouseArea` overlapped the slider; `z` on the Slider cannot outrank a sibling of its parent | `74c9877`, `d675498` |
| 2 | Checkmark offset the rows | `visible: false` drops an item out of a `Row` positioner while the width formula still reserved it | `74c9877` |
| 3 | **Every volume write silently discarded** | `uniqueId` is a **uint**; `setVolumeForPlayer`'s `typeof playerId !== "string"` guard rejected its own ids | `eae7e95` |
| 4 | Slider ignored the mouse wheel | `wheelEnabled` lives on the `QQuickControl` base, defaults off | `035b930` |
| 5 | Visualiser live around a **paused** source | Gated on `CavaService.streaming` alone; cava monitors system audio, not the selected player | `035b930` |
| 6 | **Dragging a volume slider did nothing** | `players` projection carried a `volume` snapshot, so every write rebuilt the array and the Repeater destroyed the delegate mid-drag | `4a4aa24` |
| 7 | Source pill clipped by the visualiser | Bars reach 15px past the non-clipping art slot, against an 8px gap | `6f66b0d` |
| 8 | Times past an hour rendered `90:00` | `_formatTime` had no hour branch | `6f66b0d` |
| 9 | Play/pause swap read as sudden | `fillProgress` flipped on press, re-shaping both glyphs mid-crossfade | `6f66b0d` |
| 10 | **Seek bar fought the drag** | Self-referential `value` binding, re-evaluated on every position tick | `1334a38` |
| 11 | **Dropdown could only grow, never scroll** | No Flickable, no clip, no height ceiling anywhere in the chain | `f6b248f` |
| 12 | **Volume write landed on the wrong player**, and **selection was stuck** | Both resolved a player through an id round-trip | `2c44b27`, `5f38a49` |

### The pattern worth carrying forward

Defects 3 and 12 share one root cause and took three attempts to see, because the
id path *reads* correctly and only fails at runtime. The eventual fix was to stop
resolving players by id at all and pass the live object — so a row's display and
its write share one source by construction. `_playerIdentity` still backs
`activePlayerId` (display) and two retained wrappers; **it is the first suspect if
any id-resolved path ever misbehaves again.**

Twice during this gate a fix was applied on a plausible but wrong theory (a `z`
stacking claim, then a Flickable-steal claim) before measurement found the real
cause. Both are recorded in the commits rather than quietly dropped, so a later
reader does not credit them with fixes they did not make.

---

## Deletion Authorisation

**Judged commit: `5f38a493e5be9bd9c66d632360c3d6a72876df0b`**

The operator walked the full parity checklist and the full render checklist
against the live surfaces, reported twelve defects, re-verified each fix, and
authorised the deletion at Plan 08 Task 2 by selecting **proceed**.

This authorises Task 3: deletion of the retiring AGS media surface from repo and
host — its 156-file tree, its theme-contract entry, its matugen template, its
reload step, its two layer rules, its autostart entry, its install and stow list
entries, and three orphaned shell/python scripts — and reduction of the theme
contract from 18 file entries to 17.

### Retained dependencies — verified independently at authorisation time

Task 2's context names three things that must NOT be deleted alongside the
surface. Each was re-verified live against the tree at `5f38a49` rather than
taken from the pre-gate note:

| Must survive | Evidence |
|---|---|
| Album-art resolver (`media-art-resolve.sh`) | `MediaBackend.qml:521` builds its path by string concatenation (`homeDir + "/.config/hypr/scripts/media-art-resolve.sh"`) and invokes it at `:563`. Carries the scheme allowlist and loopback/private-range rejection |
| Sass compiler | `stow.sh:418-467` shells out to it for the GTK3 stylesheet seed, with no relation to the retiring package. **`install.sh`'s comment attributing it to that package is wrong** and Task 3 must correct it, not act on it |
| Audio analyser (cava) | Consumed by `CavaService.qml`, `MediaTab.qml`, `DashboardTab.qml`, `Design.qml` — it now feeds the visualiser this phase built |

### Known-open, explicitly NOT covered by this authorisation

`quickshell-doctor` reports two failures unrelated to the media surface:
`bar-reserved-zone-stability` (reports `hot-reload=drifted`) and
`permissions-allowlist-paths-resolve` (`missing=2 pattern=1`). The pass/fail count
also differed between two consecutive runs, so at least one is live-state flaky.
These are Plan 09's business — the "every gate green with committed evidence"
plan — and must not be waved through on the strength of this gate.
