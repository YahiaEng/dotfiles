---
phase: 21-media-fold-in-contract-close
plan: 04
subsystem: quickshell-doctor (Hyprland scripts / gate tooling)
tags: [quickshell-doctor, mpris, qmedia-03, gate-repair, self-test]
dependency-graph:
  requires: []
  provides:
    - "quickshell-doctor's standing exactly-one-MPRIS-reader check (QMEDIA-03)"
    - "_qsd_assert_mpris_reader() and its QSD_FIXTURE_QUICKSHELL_CONFIG_DIR seam"
  affects:
    - "hypr/.config/hypr/scripts/quickshell-doctor"
tech-stack:
  added: []
  patterns:
    - "Directory-seam assert function (_qsd_assert_mpris_reader), same T-15-08 discipline as _qsd_shell_qml_root/_qsd_panel_qml_dir — called from both the live check and --self-test"
key-files:
  created:
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/MediaBackend.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-no-mpris-reader.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-second-mpris-reader.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-prose-only-mpris-mention.qml
  modified:
    - hypr/.config/hypr/scripts/quickshell-doctor
decisions:
  - "Repaired check 9 in place (promote), never added a second/parallel check — matches the plan's assumption_delta_decision and its own D-21-16 resolution"
  - "Assertion strengthened beyond a bare count per RESEARCH assumption A4: also asserts the single match's basename equals MediaBackend.qml (T-21-08 spoofing mitigation)"
metrics:
  duration: ~20min
  completed: 2026-08-16
status: complete
actuals:
  tokens: 15000
  tasks: 2
  commits: 2
---

# Phase 21 Plan 04: Repair the Standing MPRIS-Reader Check (QMEDIA-03) Summary

Repaired `quickshell-doctor`'s two-phase-old, silently-failing MPRIS check — promoted its
Phase-11 "zero MPRIS writer" assertion to "exactly one MPRIS reader, and it must be
MediaBackend.qml" — then proved the repaired check fails on both sides of its boundary
(zero and two readers) and ignores prose-only mentions, via four new committed self-test
fixtures.

## What Was Built

**Task 1 — promoted the assertion.** `quickshell-doctor` check 9 previously asserted
`MPRIS_HITS -eq 0`, a Phase-11 invariant written before this repo had any media widget.
Phase 18's D-18-05 legitimately repointed `MediaBackend.qml` onto the native
`Quickshell.Services.Mpris` singleton, which made that assertion silently FAIL on an
entirely healthy tree ever since (confirmed live before this plan: 18 passed / 2 failed,
one of them `[FAIL] zero Quickshell MPRIS writers (found in 1 file(s)...)`). The check is
repaired in place, not duplicated:

- Extracted the scan-and-assert logic into `_qsd_assert_mpris_reader(dir, expected)`,
  which asserts **both** halves — `MPRIS_HITS -eq 1` **and** the single match's basename
  equals the expected reader (`MediaBackend.qml`) — closing the spoofing gap RESEARCH
  assumption A4 named (a bare count of one is satisfied by a defect that removes the real
  reader and adds a different one elsewhere).
- Added a new directory seam, `_qsd_quickshell_config_dir()` /
  `QSD_FIXTURE_QUICKSHELL_CONFIG_DIR`, following the same T-15-08 discipline every other
  seam in this file already uses (hard FATAL on a variable naming a nonexistent path,
  inert on the live path unless explicitly set) — this is what makes the check fixture-
  replayable in Task 2 without touching the real `~/.config/quickshell` tree.
- Rewrote the check's header comment and its human-readable label: the matched thing was
  always a *reader*, never a *writer* — the Phase-11 comment had conflated the two from
  the start.
- Kept the regex's existing API-surface discipline unchanged (import line or `Mpris*{`
  instantiation, never a bare substring) and did not touch any other check in the file.

Live gate after the repair: **19 passed / 1 failed** — the MPRIS check is now
`[PASS] exactly one Quickshell MPRIS reader, and it is MediaBackend.qml (hits=1
basenames=MediaBackend.qml, ...)`. The one remaining failure is the pre-existing,
unrelated `permissions-allowlist-paths-resolve` gap (out of scope for this plan, per its
own acceptance criteria). Total failure count dropped by exactly 1, as required.

**Task 2 — self-test fixtures at all three counts plus the prose case.** Four fixtures
committed under `tests/quickshell-fixtures/`, each replayed in its own isolated tmpdir
(mirroring `panel-namespace-conformance`'s existing source-half isolation idiom) via
`_qsd_assert_mpris_reader()` directly, bypassing the reporting-only `check()` wrapper the
same way every other fixture-replay block in this file does:

| Fixture | Scanned alongside | Expected verdict |
|---|---|---|
| `compliant-no-mpris-reader.qml` | (alone) | FAIL — zero readers (real reader deleted/moved) |
| `MediaBackend.qml` | (alone) | PASS — exactly one reader |
| `poisoned-second-mpris-reader.qml` | `MediaBackend.qml` | FAIL — two readers, the case QMEDIA-03 exists to prevent |
| `poisoned-prose-only-mpris-mention.qml` | `MediaBackend.qml` | PASS, count still 1 — a prose mention must not increment the count |

`--self-test` now reports **59 passed / 0 failed** (55 pre-existing + 4 new), exit 0. The
prose fixture's only mention of the service name is inside its own header comment (word
"Mpris" appears, but never followed by an import line or a `{` instantiation) — verified
directly against the live regex before wiring it in, to make sure the fixture actually
tests what it claims to test rather than accidentally matching.

## Deviations from Plan

None — plan executed exactly as written. The plan's `files_modified` frontmatter named
only `quickshell-doctor`; the four fixture files under `tests/quickshell-fixtures/` are a
direct, expected consequence of Task 2's own instructions ("Add self-test fixtures... four
fixtures, each a temporary directory... committed fixture files"), following the file's
own pre-existing convention of one fixture per file (not inline heredocs) — not treated as
an out-of-scope addition.

## Verification

- `bash -n hypr/.config/hypr/scripts/quickshell-doctor` — exits 0 (both commits).
- `grep -c "MPRIS_HITS.*-eq 0" quickshell-doctor` — 0 (obsolete assertion gone).
- `grep -cE "MPRIS_HITS.*-eq 1" quickshell-doctor` — 1 (promoted assertion present).
- Live gate (`--no-summon --no-headless-output --no-panel-checks`): 19 passed / 1 failed,
  MPRIS check green, the one remaining failure is the pre-existing unrelated
  `permissions-allowlist-paths-resolve` gap.
- `--self-test`: 59 passed / 0 failed, including all four new MPRIS fixtures (2 FAIL-
  expected, 2 PASS-expected, all correctly predicted).
- No `producer | grep -q` construct introduced anywhere touched by this plan.

## Self-Check: PASSED

- FOUND: `hypr/.config/hypr/scripts/quickshell-doctor`
- FOUND: `hypr/.config/hypr/scripts/tests/quickshell-fixtures/MediaBackend.qml`
- FOUND: `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-no-mpris-reader.qml`
- FOUND: `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-second-mpris-reader.qml`
- FOUND: `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-prose-only-mpris-mention.qml`
- FOUND commit `9e074af` (Task 1)
- FOUND commit `3568d11` (Task 2)
