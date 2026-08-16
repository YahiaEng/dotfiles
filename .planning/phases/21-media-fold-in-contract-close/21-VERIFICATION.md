---
phase: 21-media-fold-in-contract-close
verified: 2026-08-16T17:28:46Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
resolved_after_verification: 2026-08-16T17:52:00Z
gaps:
  - truth: "theme-doctor is green"
    status: resolved
    resolution: >
      Closed by the orchestrator in the same execute-phase run, in two commits.
      (1) The phase-owned gap named below — the unregistered Super+M bind — was
      fixed by adding its ACCEPTED_ADDITIONS entry to hypr-equivalence-check,
      mirroring the QBAR-09 SUPER_L entry's shape. hypr-equivalence-check went
      PASS 3 / FAIL 0 (was 2/1).
      (2) The two "waybar" failures this report DEFERRED to Phase 22 turned out
      not to be Phase 18 debt at all. `git blame` puts all three lines
      (keybinds.lua:237, shell.qml:965, shortcuts.json:54) on 5cb32ed
      `feat(21-08)` — THIS phase's own retirement commit. They are prose
      comments Plan 07/08 wrote to explain what the Super+M bind restores, and
      they named the retired bar package literally. Reworded to name that
      retirement by requirement ID (RETIRE-02); retirement-check waybar went
      failed_classes=0 (was 2). The deferral below is therefore WITHDRAWN as
      misclassified, not carried to Phase 22.
      theme-doctor now reports "577 passed, 1 failed", the single remaining
      failure being its own `git status --porcelain is empty` check, which is
      satisfied once this report and STATE.md are committed by phase close.
      Re-verified after the fixes: retirement-check --self-test 5/5,
      keybind-doctor 14/14 (the appid:name identifier triple still byte-matches
      across all three files), colour-lint 144/144, motion-lint 291/291,
      theme-parity 1545/1545.
    original_status: failed
    reason: >
      theme-doctor exits 1 (confirmed by direct re-run this session:
      "Summary: 574 passed, 4 failed"). Of the persistent (non-transient)
      failures, one is directly caused by this phase's own work and was never
      closed out: `hypr-equivalence-check: binds.json` fails because Plan
      21-07's new `Super+M` keybind (`quickshell:media`, modmask=64 key='M')
      was added to `keybinds.lua` but never registered in
      `hypr-equivalence-check`'s own "accepted new binds since baseline"
      table — the exact bookkeeping step Phase 18's QBAR-09 `SUPER_L`
      hold-to-reveal bind used as its own precedent
      (`hypr-equivalence-check:536-537`, comment: "Phase 18 QBAR-09
      hold-to-reveal bar (keybinds.lua:134)"). 21-CONTRACT-CLOSE-EVIDENCE.md
      (committed by Plan 21-09) itself documents this exact failure and
      explicitly declines to fix it, misclassifying it alongside two
      unrelated pre-existing waybar failures as "none owned by this plan" —
      but the binds.json failure's root cause (the Super+M bind) is Plan
      21-07's own change, squarely inside this phase's scope, not inherited
      debt. Roadmap Success Criterion 4 states "theme-doctor and
      theme-parity are green" with no carve-out for self-caused failures.
    artifacts:
      - path: "hypr/.config/hypr/scripts/hypr-equivalence-check"
        issue: "The accepted-additions table (~line 536) has no entry for modmask=64 key='M', so the live SUPER+M bind added in Plan 21-07 reads as an unaccepted deviation from the Phase-13.1 baseline every time theme-doctor's hypr-equivalence-check fold runs."
    missing:
      - "Add an accepted-bind entry for (mainMod, 'M') to hypr-equivalence-check's acceptance table, citing Plan 21-07 / QMEDIA-01's Super+M-to-Media-tab shortcut, mirroring the existing SUPER_L/QBAR-09 entry's shape."
      - "Re-run theme-doctor and confirm the binds.json line reports PASS."
deferred: []
withdrawn_deferrals:
  - truth: "theme-doctor is green (retirement-check: waybar/keybinds and waybar/cross-package-refs failures)"
    was_addressed_in: "Phase 22"
    withdrawn_because: >
      The deferral rested on the claim that these references were "pre-existing
      Phase 18 (waybar retirement) debt, confirmed untouched by any Phase 21
      commit". That claim is false. `git blame -L` on each of the three sites
      (keybinds.lua:237, shell.qml:965, shortcuts.json:54) returns 5cb32ed
      `feat(21-08): RETIRE-06 — remove the standalone media applet, config and
      package` — a Phase 21 commit, dated 2026-08-16. 21-CONTRACT-CLOSE-EVIDENCE.md
      and 21-09-SUMMARY.md made the same misclassification, and this report
      inherited it. All three were prose, all three were reworded in-phase, and
      retirement-check waybar now reports failed_classes=0. Nothing is owed to
      Phase 22 on this item.
---

# Phase 21: Media Fold-In & Contract Close Verification Report

**Phase Goal:** One now-playing surface remains in the whole desktop, and the theme contract reaches its post-migration shape with every gate green.
**Verified:** 2026-08-16T17:28:46Z
**Status:** passed (initial verdict `gaps_found`; sole gap closed in-run — see Gap Closure)
**Re-verification:** Yes — gap closed and re-checked by the orchestrator on 2026-08-16T17:52Z

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dashboard Media tab does everything the standalone AGS card did (transport, seek, cover art, per-player volume, player switching) | ✓ VERIFIED | `21-BEHAVIOUR-BASELINE.md` parity checklist: 16/16 capabilities SATISFIED or SATISFIED-BY-SUPERSESSION. `21-GATE-02-RECORD.md`: human operator walked every row live against the running AGS card, found 12 defects (all in "SATISFIED"-marked rows), fixed and re-verified every one before authorising deletion (judged commit `5f38a49`). Per-player volume and transitive dedup confirmed built in `MediaBackend.qml` (`_playerGroups`, `setVolumeForPlayer`) and live-tested per Part A of the gate record. |
| 2 | Audio-reactive visualiser renders as a ring around shaped cover art while audio plays, restoring the cava element Phase 14 cut | ✓ VERIFIED | `CavaService.qml` (ref-counted `Process`+`SplitParser`, `claim()`/`release()`, linger timer) wired into both `MediaTab.qml` and `MediaPopout.qml`. `21-GATE-02-RECORD.md` Part B: B-6 through B-13 all PASS, including exactly-one-cava-process-for-two-open-surfaces (`pgrep -fc` == 1) and non-square art clipping. Code review found one regression (ring dancing on a paused player in the bar popout) — confirmed fixed in commit `15fb29d` (`root.mediaBackend.playing` gate now present in `MediaPopout.qml`, verified by direct read this session). |
| 3 | Exactly one MPRIS reader runs anywhere in the desktop, and `ags/` is gone from repo and host with its contract entry, `[templates.ags]`, its `reload.sh` step and its layer rules, checklist-verified zero-hits before and after | ✓ VERIFIED | `quickshell-doctor` live run this session: `[PASS] exactly one Quickshell MPRIS reader, and it is MediaBackend.qml (hits=1)`. `MediaPopout.qml`'s one "Mpris" hit is a comment, not an import (confirmed by direct grep). `retirement-check --surface ags` this session: `failed_classes=0`, all 13 reference classes PASS, zero hits. `ags` package not installed (`pacman -Q ags`/`aylurs-gtk-shell` both fail). No `ags/` directory in repo. `contract.json` has no `ags.scss`/`ags` entry (17 `files` entries, none named ags). `matugen/.config/matugen/config.toml` has no `[templates.ags]` block. `theme-engine/.config/theme-engine/lib/reload.sh` has no ags step. `windowrules.lua` has no ags layer rule. `21-PRE-DELETION-SWEEP.txt`/`21-POST-DELETION-SWEEP.txt` pair committed and cross-referenced. |
| 4 | `theme-doctor` and `theme-parity` are green with `contract.json` at its post-migration size (18 → 17) and no orphaned entries | ✓ VERIFIED (after in-run gap closure) | `theme-parity` green (1545/1545, orchestrator-confirmed this run). `contract.json` confirmed at exactly 17 `files` entries via direct read, no orphaned ags entry, `scss-vars` format family still represented (`_motion.scss`). `theme-doctor` was NOT green at initial verification — exit 1, "Summary: 574 passed, 4 failed". **All content failures were then closed in-run** (commits for the Super+M acceptance entry and the three reworded prose sites); theme-doctor now reports "577 passed, 1 failed", the lone remaining failure being its own tree-clean check, satisfied at phase-close commit. Breakdown of the original 4: `hypr-equivalence-check: binds.json` (this phase's own unregistered Super+M bind) and the two `retirement-check: waybar/*` hits (also this phase's own prose, per `git blame` on 5cb32ed) are all fixed; the 4th, `git status --porcelain` dirty, was the in-progress STATE.md. |
| 5 | Phase 16's `16-VERIFICATION.md` exists, its two malformed `coverage:` blocks are corrected, and quick task `260728-51j` is resolved | ✓ VERIFIED | `.planning/milestones/v3.0-phases/16-workspace-overview/16-VERIFICATION.md` exists (139 lines, `status: passed`, `## Reconstruction Provenance` section present, honestly records OVER-04 as UNMEASURED). `16-05-SUMMARY.md`: `status: not_run` replaced with `status: unknown` (confirmed, zero `not_run` matches remain). `16-06-SUMMARY.md`: D2/D3/D4 each carry a distinct `rationale:` field (confirmed by direct grep, 4 matches). `STATE.md:669`: `260728-51j` row present, marked "Resolved — already done, closed on evidence 2026-08-16" with concrete on-disk evidence cited. |

**Score:** 5/5 truths verified (4/5 at initial verification)

### Deferred Items

None. The one deferral this report originally recorded was **withdrawn as misclassified** — see Gap Closure below. Nothing from Phase 21 is owed to Phase 22.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.config/quickshell/modules/CavaService.qml` | Ref-counted cava streaming singleton | ✓ VERIFIED | `claim()`/`release()`, linger timer, `_bars` cleared on stop (post-review fix), `Number.isFinite` guard on parsed values (post-review fix) |
| `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` | Full-parity Media tab with 60-bar radial visualiser | ✓ VERIFIED | Transport, seek, per-player volume, switcher, seek-latch, visualiser ring — all present and gate-verified live |
| `quickshell/.config/quickshell/modules/bar/MediaPopout.qml` | Bar popout mirroring the tab's ring | ✓ VERIFIED | `playing`-gated ring confirmed fixed post-review (`15fb29d`) |
| `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` | Single MPRIS reader, dedup, seek latch, per-player volume | ✓ VERIFIED | Sole `Mpris` import in the QML tree; single-linkage dedup fix confirmed (`15fb29d`) |
| `theme-engine/.config/theme-engine/contract.json` | 17 `files` entries, no `ags` entry | ✓ VERIFIED | Direct read: exactly 17 entries, none named `ags`/`ags.scss` |
| `ags/` (repo tree) | Absent | ✓ VERIFIED | `find . -maxdepth 1 -iname "ags*"` returns nothing |
| `hypr/.config/hypr/scripts/hypr-equivalence-check` | Accepted-bind table current with all this-phase additions | ✗ STALE | Missing an entry for the Super+M bind added in Plan 21-07 — causes a live theme-doctor failure |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `MediaTab.qml` | `CavaService.qml` | `claim()`/`release()` reference counting | ✓ WIRED | Confirmed live: `pgrep -fc "cava -p .*/.config/cava/config"` == 1 with both dashboard and popout open (GATE-02 B-10) |
| `MediaBackend.qml` | MPRIS (`Quickshell.Services.Mpris`) | Native `Mpris` singleton import | ✓ WIRED | Sole reader in the QML tree, confirmed by `quickshell-doctor`'s promoted check |
| `MediaTab.qml` | `media-art-resolve.sh` | String-concatenated path + `Process` invocation | ✓ WIRED | `MediaBackend.qml:521,563` — confirmed retained (not deleted alongside `ags`), new bare-path handoff test added (Plan 21-09, 24/24 pass) |
| `theme-engine/reload.sh` | (ags reload step) | N/A | ✓ REMOVED | No `ags` step remains; confirmed by direct grep |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| QMEDIA-01 | 21-02, 21-05, 21-07, 21-08 | Media tab full parity | ✓ SATISFIED | GATE-02 record, 16/16 parity rows PASS |
| QMEDIA-02 | 21-01, 21-06, 21-08 | Audio-reactive visualiser ring | ✓ SATISFIED | GATE-02 Part B render checks, CavaService wiring confirmed |
| QMEDIA-03 | 21-04, 21-08, 21-09 | Exactly one MPRIS reader | ✓ SATISFIED | quickshell-doctor live confirms hits=1; self-test 59/59 including reader-count fixtures |
| RETIRE-06 | 21-02, 21-08, 21-09 | `ags` removed the same way | ✓ SATISFIED | retirement-check `--surface ags` failed_classes=0; package/dir/contract/template/reload/layer-rules all confirmed absent |
| RETIRE-08 | 21-08, 21-09 | contract.json 18→17, theme-doctor + theme-parity green, no orphaned entries | ✓ SATISFIED (after in-run gap closure) | contract.json (17 entries) and theme-parity (1545/1545) green; theme-doctor's content failures all closed in-run, now 577 passed / 1 failed (tree-clean check only). REQUIREMENTS.md recorded RETIRE-08 as `[ ]`/"Pending" at initial verification, correctly; it is marked complete at phase close. |
| LEDGER-06 | 21-03 | Phase 16 paperwork | ✓ SATISFIED | 16-VERIFICATION.md exists, coverage blocks fixed, quick task closed |

No orphaned requirements — all 6 IDs from ROADMAP.md's Phase 21 entry are claimed by at least one plan's frontmatter, and every plan's `requirements:` field maps back to one of the six.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No TBD/FIXME/XXX/TODO/HACK found in any file touched by Phase 21's commit range | — | Clean |

`placeholder` matches in `MediaTab.qml`/`MediaPopout.qml` are legitimate cover-art-fallback UI terminology (`artPlaceholder`, `artPlaceholderGlyph`, `artPlaceholderBadge`), not stub markers — each backs a real fallback rendering path, not an unimplemented feature.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Exactly one MPRIS reader | `quickshell-doctor --no-summon --no-headless-output --no-panel-checks` | `[PASS] exactly one Quickshell MPRIS reader ... hits=1` | ✓ PASS |
| ags fully retired | `retirement-check --surface ags` (as run inside `--all`) | `failed_classes=0`, zero hits all classes | ✓ PASS |
| quickshell-doctor self-test | `quickshell-doctor --self-test` | `59 passed, 0 failed` | ✓ PASS |
| Album-art bare-path handoff | `test-media-hardening.sh` | `24 passed, 0 failed` | ✓ PASS |
| theme-doctor | `theme-doctor` | initial `574 passed, 4 failed`; after in-run gap closure `577 passed, 1 failed` (tree-clean check only) | ✓ PASS (after closure) |
| contract.json size | direct JSON read | `files` array length == 17 | ✓ PASS |

### Human Verification Required

None. Success Criteria 1 and 2 (the criteria most dependent on rendered/interactive behavior) already carry a recorded, defect-by-defect human go/no-go verdict (`21-GATE-02-RECORD.md`, operator-attested, PASSED WITH FIXES) that this verification treats as satisfying evidence rather than re-requesting a duplicate live walk. `theme-stress-test`'s live run remains an outstanding **operator action** (per 21-09-SUMMARY.md's "User Setup Required" — a live-theme-mutating command this session's own standing rules prohibit running), but it is not gating this verdict: `contract.json`'s static shape and `theme-parity`'s 1545/1545 pass already establish the criterion's factual content, and the stress test is a belt-and-braces confirmation, not new evidence this report depends on.

### Gaps Summary

Four of five roadmap Success Criteria are fully met, with strong evidence (a defect-by-defect human-attested combined gate for the two hardest-to-verify criteria, a clean retirement sweep for `ags`, and a faithful reconstruction of Phase 16's missing paperwork). The blocking gap is narrow and mechanical: Success Criterion 4 requires `theme-doctor` to be green, and it is not — `theme-doctor` exits 1 with 3 persistent failures. Two of the three are legitimately pre-existing Phase 18 waybar debt that Phase 22's fresh-install proof already commits to closing (deferred, not a gap here). The third — `hypr-equivalence-check: binds.json` — is not inherited debt: it is caused directly by this phase's own Plan 21-07 change (the `Super+M` → Media-tab shortcut, itself a named requirement item under QMEDIA-01), which added a live keybind without registering it in `hypr-equivalence-check`'s acceptance table, the exact bookkeeping step Phase 18's `QBAR-09` bind used as precedent in the same file. `21-CONTRACT-CLOSE-EVIDENCE.md` (Plan 21-09) documents this failure accurately but incorrectly folds it into the same "not owned by this plan" bucket as the two genuine waybar items, which is why it went unfixed. The fix is a one-line addition to `hypr-equivalence-check`'s accepted-bind table, mirroring existing code in the same file — low effort, high confidence.

This finding aligns with `.planning/REQUIREMENTS.md`'s own current state: RETIRE-08 is still recorded `[ ]`/"Pending" in that document, not prematurely checked off — the requirements ledger and this verification agree.

## Gap Closure (post-verification, same execute-phase run)

The initial verdict was `gaps_found`, 4/5. Both items below were closed by the
orchestrator before phase close; each was re-checked with the gate that had failed.

| # | Item | Original classification | What was actually true | Fix | Gate after |
|---|------|------------------------|------------------------|-----|-----------|
| 1 | `hypr-equivalence-check: binds.json` FAIL | Phase-owned gap (correct) | Plan 21-07 added `Super + M` to `quickshell:media` at `keybinds.lua:243` but never registered it in `ACCEPTED_ADDITIONS`. The table's own header explains this failure mode: the baseline is a frozen pre-migration snapshot, so any undeclared new bind fails permanently. | Added the `("", 64, "M", False)` entry, mirroring the QBAR-09 `SUPER_L` entry two lines up. | `hypr-equivalence-check` PASS 3 / FAIL 0 (was 2/1) |
| 2 | `retirement-check: waybar/keybinds` (1) + `waybar/cross-package-refs` (2) | Deferred to Phase 22 as "pre-existing Phase 18 debt, untouched by any Phase 21 commit" — **incorrect** | `git blame -L` on all three sites returns `5cb32ed feat(21-08)`, this phase's own retirement commit. They are prose comments Plan 07/08 wrote to explain what the Super+M bind restores, naming the retired bar package literally. `21-CONTRACT-CLOSE-EVIDENCE.md` and `21-09-SUMMARY.md` made the same misclassification; this report inherited it. | Reworded all three to name that retirement by requirement ID (RETIRE-02). | `retirement-check waybar` failed_classes=0 (was 2) |

One nested defect worth recording: the first draft of the fix-1 comment wrote the
retired media surface's package name in prose, which immediately tripped
`retirement-check`'s `ags/checker-internals` class (`hypr-equivalence-check:541`)
— the gate catching the gate's own fix. Reworded to a requirement ID before commit.
This is the same failure mode as item 2, one commit apart, and is why both fixes
name retired surfaces by ID rather than by package name.

**theme-doctor after closure:** `577 passed, 1 failed` (was `574 passed, 4 failed`).
The single remaining failure is theme-doctor's own `git status --porcelain is empty`
check, tripped by this report and `STATE.md` being uncommitted at the time of the run;
it is satisfied by the phase-close commit.

**Re-checked after the fixes:** retirement-check `--self-test` 5/5 · keybind-doctor
14/14 (the `appid:name` identifier triple still byte-matches across `keybinds.lua`,
`shortcuts.json` and `shell.qml`) · colour-lint 144/144 · motion-lint 291/291 ·
theme-parity 1545/1545 · `shortcuts.json` parses as JSON · `keybinds.lua` passes
`luac -p`. `shell.qml`'s `qmllint` exit 255 is pre-existing at HEAD and unchanged.

---

_Verified: 2026-08-16T17:28:46Z_
_Gap closure verified: 2026-08-16T17:52Z (orchestrator, same run)_
_Verifier: Claude (gsd-verifier)_
