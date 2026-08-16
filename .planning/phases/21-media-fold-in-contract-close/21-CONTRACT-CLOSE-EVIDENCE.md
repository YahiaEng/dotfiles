# Phase 21 Plan 09 — Contract Close Evidence

Captured 2026-08-16, HEAD at capture time `ca50e68` (this plan's own two prior commits:
`ec23c4c` test-media-hardening.sh Check 12, `ca50e68` quickshell-doctor bug fixes),
working tree clean before this document's own commit. Every gate below was invoked
verbatim per its own documented usage (21-RESEARCH.md § "Contract Close Mechanics"),
output captured into a variable with its exit code read directly from `$?` — never
through a piped `grep -q` (the documented `pipefail` trap this repo has already been
bitten by).

## Summary table

| Gate | Invocation | Exit | Verdict | Owned by this plan? |
|------|-----------|------|---------|----------------------|
| theme-doctor | `bash theme-engine/.config/theme-engine/theme-doctor` | 1 | 575 passed, 3 failed | No — all 3 pre-existing, unrelated (see below) |
| theme-parity | `bash theme-engine/.config/theme-engine/theme-parity` | 0 | 1545/1560 checks passed, 0 failed, 20 targets green | — |
| theme-stress-test | `bash theme-engine/.config/theme-engine/theme-stress-test` | **NOT RUN** | deferred to operator (standing rule 5) | Verified statically instead — see below |
| retirement-check --all | `bash hypr/.config/hypr/scripts/retirement-check --all` | 1 | `ags`: failed_classes=0; `waybar`: failed_classes=2 (only failure) | `ags` yes (owned, green); `waybar` no (pre-existing) |
| retirement-check ags (after) | `DOTFILES_DIR=/home/aorus/dotfiles bash hypr/.config/hypr/scripts/retirement-check ags` | 0 | failed_classes=0 | Yes — owned, green |
| retirement-check --self-test | `bash hypr/.config/hypr/scripts/retirement-check --self-test` | 0 | 5/5 fixtures replayed correctly | — |
| quickshell-doctor --self-test | `bash hypr/.config/hypr/scripts/quickshell-doctor --self-test` | 0 | 59/59 fixtures replayed correctly (includes the 4 MPRIS reader-count fixtures) | Yes |
| quickshell-doctor (live, pre-fix) | `bash hypr/.config/hypr/scripts/quickshell-doctor --no-summon --no-headless-output --no-panel-checks` | 1 | 17 passed, 3 failed | Yes — 2 of 3 owned and fixed this plan; captured as the "before" evidence |
| quickshell-doctor (live, post-fix, x5) | same invocation | 0 (all 5 runs) | 20 passed, 0 failed, identical every run | Yes — owned, fixed, stability proven |
| keybind-doctor | `bash hypr/.config/hypr/scripts/keybind-doctor` | 0 | 14/14 passed, 85 binds, new Super+M accounted for | — |
| colour-lint | `bash hypr/.config/hypr/scripts/colour-lint` | 0 | 144/144 passed | — |
| motion-lint | `bash hypr/.config/hypr/scripts/motion-lint` | 0 | 291/291 passed | — |
| test-media-hardening.sh | `bash hypr/.config/hypr/scripts/tests/test-media-hardening.sh` | 0 | 24/24 passed (17 retained + 7 new Check 12) | Yes |

**No gate this plan owns was narrowed, skipped, or scope-adjusted to reach green.**
Every invocation above is the gate's own documented default usage, unchanged.

---

## theme-stress-test — deliberately NOT run, and why

The plan's own Task 2 action asks for `theme-stress-test` to be run as evidence that
removing the `ags.scss` contract entry did not break the representative-file check (the
exact class of failure a prior retirement caused). This executor's standing instructions
for this session **explicitly and unconditionally prohibit** running `theme-stress-test`
or any command that live-applies a theme: a prior executor session ran it by accident
during Plan 08 and re-themed the operator's live desktop mid-session (see
`21-08-SUMMARY.md`'s Deviations §2 — "theme-stress-test is NOT report-only — it mutates
the live desktop theme"). That incident is the direct reason the prohibition exists for
this session, and it is not scoped with an exception for "but this plan's own `<verify>`
block asks for it" — the instruction is unconditional. This executor did not run it.

**Static verification used instead**, matching what `21-08-SUMMARY.md` already
independently confirmed:

```
$ grep -n "REPRESENTATIVE_FILES" -A 1 theme-engine/.config/theme-engine/theme-stress-test
315:REPRESENTATIVE_FILES=(hyprland-tokens.lua gtk-4.0-colors.css kitty.conf)
```

`ags.scss` — the file whose contract entry was removed in Plan 08 — is not named in
`REPRESENTATIVE_FILES`, so the stress test's post-switch snapshot step cannot fail on a
missing file it never names. This is the same reasoning `21-08-SUMMARY.md` recorded
before the deletion landed; it is re-confirmed here, unchanged, against the current tree.

**This is an operator action, not a plan gap.** The stress test genuinely needs to be run
at least once against the final state before this phase is considered fully proven —
that run just cannot happen from an unattended agent session per this session's own
standing rules. Recorded as an explicit "User Setup Required" item in the plan's SUMMARY.

---

## theme-doctor — 3 pre-existing failures, none owned by this plan

```
theme-doctor — theme-engine health check
  [PASS] adw-gtk-theme package installed
  ... (572 more PASS/SKIP lines — state-manifest, walker/elephant health, CSS-parse,
       motion-lint's 291 checks folded in, colour-lint's 144 checks folded in as a
       genuine PASS — not a SKIP; colour-lint ran for real, see below)
  [FAIL] hypr-equivalence-check: binds.json: differs from baseline (structural comparison)
  [PASS] hypr-equivalence-check: animations.json: matches baseline (leaves byte-exact positional, curves set-compared)
  [PASS] hypr-equivalence-check: options.jsonl: matches baseline (normalized: type-key name discarded, bool<->int folded)
  ...
  [FAIL] retirement-check: waybar/keybinds: 1 reference(s)
      /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:237
  ...
  [FAIL] retirement-check: waybar/cross-package-refs: 2 reference(s)
      /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:965
      /home/aorus/dotfiles/quickshell/.config/quickshell/shortcuts.json:54
  ...
  [PASS] git status --porcelain is empty (/home/aorus/dotfiles stays clean)

Summary: 575 passed, 3 failed
```

The colour-lint fold-in (`theme-doctor:520-547`) is a **genuine pass**, not a skip: 144
real `[PASS] colour-lint: CHECK A/CHECK B: ...` lines are present in the raw log, scanning
73 real QML surfaces under `/home/aorus/.config/quickshell`, with 3 named/justified
`[EXEMPT]` lines (WeatherPalette.qml, two MD3 elevation-shadow anchors) — no
`[SKIP] colour-lint` line anywhere in the output. Confirmed by direct grep of the
captured log: zero matches for `SKIP.*colour-lint`.

**All 3 failures are pre-existing and out of this plan's scope** — confirmed against
`21-08-SUMMARY.md`'s own "Pre-existing, out-of-scope findings" section, which flagged
these exact three lines before this plan started, and re-confirmed here that this
plan's own commits (`ec23c4c`, `ca50e68`) touch none of the files these three failures
name (`keybinds.lua` line 237 is the pre-existing Super+D bind's own `-- waybar` mention,
unrelated to media; `shell.qml:965`/`shortcuts.json:54` are Phase 18-era comment prose;
`binds.json` baseline is the Super+M-vs-Phase-13.1-baseline acceptance gap from Plan
21-07):

1. **`hypr-equivalence-check: binds.json`** — the Super+M shortcut added in Plan 21-07 is
   not yet marked "accepted" against the Phase-13.1 hyprctl-binds baseline. This plan's
   own edits never touched `keybinds.lua`'s bind declarations.
2. **`retirement-check: waybar/keybinds`** (1 reference) — a pre-existing waybar mention
   in `keybinds.lua`, unrelated to media/AGS; `waybar` retirement predates this phase
   (Phase 18 Plan 20) and its own registry row was never this plan's business.
3. **`retirement-check: waybar/cross-package-refs`** (2 references) — pre-existing waybar
   mentions in `shell.qml`/`shortcuts.json` prose, same as above.

This document does not fix these three — fixing them would mean expanding this plan's
scope into Phase 18/21-07 debt it does not own, which the deviation rules' scope
boundary explicitly forbids ("only auto-fix issues DIRECTLY caused by the current task's
changes"). They are recorded here, plainly, as **not this plan's business**, exactly the
distinction the plan's own Task 2 action text requires for the two quickshell-doctor
failures below — extended here to the same honest-disclosure standard for theme-doctor's
own three.

---

## theme-parity — fully green, all 22 targets

```
theme-parity — output-contract parity check (20260816T162449Z)

-- Rendering 22 target(s) --
  [PASS] catppuccin: render produced files (found 19)
  [PASS] catppuccin-latte: render produced files (found 19)
  [PASS] dracula: render produced files (found 19)
  [PASS] ethereal: render produced files (found 19)
  [PASS] everfrost: render produced files (found 19)
  [PASS] gruvbox: render produced files (found 19)
  [PASS] gruvbox-light: render produced files (found 19)
  [PASS] hackerman: render produced files (found 19)
  [PASS] kanagawa: render produced files (found 19)
  [PASS] kanagawa-lotus: render produced files (found 19)
  [PASS] matte-black: render produced files (found 19)
  [PASS] miasma: render produced files (found 19)
  [PASS] nord: render produced files (found 19)
  [PASS] osaka-jade: render produced files (found 19)
  [PASS] ristretto: render produced files (found 19)
  [PASS] rosepine-dawn: render produced files (found 19)
  [PASS] rosepine: render produced files (found 19)
  [PASS] tokyonight-day: render produced files (found 19)
  [PASS] tokyonight: render produced files (found 19)
  [PASS] vantablack: render produced files (found 19)
  [PASS] materialyou: render produced files (found 19)
  [PASS] materialyou-light: render produced files (found 19)

-- Mode fixtures --
  ... (22 targets, each PASS)

  ... (per-target internal well-formedness checks omitted here for length — every
       target passed every check; the raw log carries 1560 lines and was fully
       inspected this session, not sampled: `grep -c FAIL` on the full captured log
       returns 0)

-- Motion byte-identity (D-31) --
  [PASS] motion byte-identity: motion.json identical across 22 render dir(s) (diverged: none)
  [PASS] motion byte-identity: gtk-4.0-motion.css identical across 22 render dir(s) (diverged: none)
  [PASS] motion byte-identity: _motion.scss identical across 22 render dir(s) (diverged: none)

Summary: 1545 passed, 0 failed
```

Confirmed by direct grep of the full captured log: zero `[FAIL]` lines anywhere in
1560 lines of output. `theme-parity` renders and cross-compares all 22 targets
(6 static presets + catppuccin family + materialyou/materialyou-light + the rest of
this repo's preset roster) with zero divergence.

---

## retirement-check — ags (this plan's business): PASS, and the before/after pair

**Before** (captured by Plan 08, committed at `21-PRE-DELETION-SWEEP.txt`, HEAD
`ed1a8a5`, status still `pending` at capture time since the registry flip happens after
the sweep): all sixteen reference classes printed an explicit hit-count or zero-count
line as `[REPORT]` (not yet `[PASS]`/`[FAIL]` since status was `pending`), with
non-zero counts across `own-tree` (36), `layer-window-rules` (2), `autostart` (1),
`keybinds` (1), `contract-json` (1), `matugen-templates` (8), `checker-internals` (5),
`cross-package-refs` (20), `install-stow-lists` (8), `systemd-units` (2, including one
live transient systemd scope) — `Summary: surface=ags status=pending failed_classes=0`
(no blocking-domain class scan itself failed; the surface simply hadn't been flipped
yet).

**After** (committed by Plan 08 at `21-POST-DELETION-SWEEP.txt`, HEAD `3c2c8af`,
status `retired`):

```
retirement-check — surface=ags status=retired root=/home/aorus/dotfiles

[SKIP] ags/own-tree: own-tree path(s) not present under /home/aorus/dotfiles: ags/
[PASS] ags/layer-window-rules: no references
[PASS] ags/autostart: no references
[PASS] ags/keybinds: no references
[PASS] ags/contract-json: no references
[PASS] ags/matugen-templates: no references
[PASS] ags/checker-internals: no references
[PASS] ags/test-fixtures: no references
[PASS] ags/cross-package-refs: no references
[PASS] ags/install-stow-lists: no references
[PASS] ags/systemd-units: no references
[PASS] ags/dbus-activation: no references
[PASS] ags/xdg-autostart: no references
[PASS] ags/host-package: no references
[REPORT] ags/planning-archive: 1196 reference(s)
[REPORT] ags/repo-prose: 107 reference(s)

Summary: surface=ags status=retired failed_classes=0
```

**Re-run fresh this session** (`DOTFILES_DIR=/home/aorus/dotfiles bash
hypr/.config/hypr/scripts/retirement-check ags`, exit 0), against the tree at this
plan's own commits, produces the identical verdict — `failed_classes=0` — with
`planning-archive` now at 1213 references (up from 1196, reflecting this plan's own
new prose additions to `.planning/`, expected) and every blocking-domain class still
`[PASS]`:

```
retirement-check — surface=ags status=retired root=/home/aorus/dotfiles

[SKIP] ags/own-tree: own-tree path(s) not present under /home/aorus/dotfiles: ags/
[PASS] ags/layer-window-rules: no references
[PASS] ags/autostart: no references
[PASS] ags/keybinds: no references
[PASS] ags/contract-json: no references
[PASS] ags/matugen-templates: no references
[PASS] ags/checker-internals: no references
[PASS] ags/test-fixtures: no references
[PASS] ags/cross-package-refs: no references
[PASS] ags/install-stow-lists: no references
[PASS] ags/systemd-units: no references
[PASS] ags/dbus-activation: no references
[PASS] ags/xdg-autostart: no references
[PASS] ags/host-package: no references
[REPORT] ags/planning-archive: 1213 reference(s)
[REPORT] ags/repo-prose: 107 reference(s)

Summary: surface=ags status=retired failed_classes=0
```

**The `own-tree` line is `[SKIP]`, not `[PASS]`** — this is correct and expected, not a
gap: the class asserts "the retired tree is absent," and it is genuinely absent
(`ags/.config/ags/` does not exist), so the class has nothing to scan and reports SKIP
rather than a vacuous PASS. This is the class working as designed, not a silently-passed
check.

**Known short-name precision limit, accounted for rather than absorbed** (documented
directly in `21-PRE-DELETION-SWEEP.txt`, re-verified here): `ags` is a short common-word
surface token that can, in principle, word-boundary-match unrelated prose in an unrelated
sentence. Word boundaries already exclude `tags`/`flags`/`images`. Every hit in the
before-sweep's blocking-domain classes was cross-checked against actual file content
before Plan 08 acted on it (`21-08-SUMMARY.md`), and zero were false positives. The
`planning-archive`/`repo-prose` classes remain `[REPORT]`-only by design (never
blocking) precisely because planning prose is expected to keep mentioning a retired
surface's own name in past-tense history — that is not drift, it is the historical
record this repo deliberately keeps.

---

## retirement-check --all — ags green, waybar the only failure (pre-existing, not owned)

```
$ bash hypr/.config/hypr/scripts/retirement-check --all
[exit 1]
```

Full per-surface breakdown (`failed_classes` per surface):

| Surface | failed_classes | Detail |
|---------|-----------------|--------|
| **waybar** | **2** | `waybar/keybinds` (1 ref: `keybinds.lua:237`), `waybar/cross-package-refs` (2 refs: `shell.qml:965`, `shortcuts.json:54`) — pre-existing, Phase 18 Plan 20 debt, not this plan's business |
| swaync | 0 | clean |
| swayosd | 0 | clean |
| wleave | 0 | clean |
| **ags** | **0** | clean — this plan's own business, green |
| wlogout | 0 | clean |
| eww | 0 | clean |
| retirement-fixture | 0 | clean (self-test's own compliant fixture) |

`ags` is the only surface this plan owns, and it is the only surface with zero
`[FAIL]` lines guaranteed by this plan's own work (Plan 08 landed the deletion; this
plan re-confirms it holds under re-run). `waybar` is the sole reason `--all` exits
non-zero, and it predates this phase entirely.

---

## retirement-check --self-test — 5/5

```
retirement-check --self-test — replaying the five committed fixtures

  [PASS] self-test: compliant-clean-surface -> exit 0 (compliant) as expected
  [PASS] self-test: poisoned-stray-layer-rule -> a non-zero exit (poisoned) as expected
  [PASS] self-test: poisoned-stray-contract-entry -> a non-zero exit (poisoned) as expected
  [PASS] self-test: poisoned-stray-cross-script-ref -> a non-zero exit (poisoned) as expected
  [PASS] self-test: poisoned-planning-only -> exit 0 (compliant) as expected

Self-test summary: 5 passed, 0 failed
```

---

## quickshell-doctor — the two failures this plan owned, investigated, root-caused, fixed

Per `21-GATE-02-RECORD.md`, two quickshell-doctor failures were carried into this plan
as explicitly open business, plus a documented run-to-run instability. All three are
now closed, with the actual root cause found by reading the check's own source and
measuring — not assumed.

### --self-test: 59/59, including all 4 reader-count fixtures

```
quickshell-doctor --self-test — replaying the committed quickshell-fixtures
  ...
  [PASS] self-test: compliant-no-mpris-reader.qml alone -> MPRIS-reader-count check FAILS (hits=0 basenames=none, a zero count means the real reader was deleted or moved)
  [PASS] self-test: MediaBackend.qml alone -> MPRIS-reader-count check PASSES (hits=1 basenames=MediaBackend.qml)
  [PASS] self-test: poisoned-second-mpris-reader.qml added alongside MediaBackend.qml -> MPRIS-reader-count check FAILS (hits=2 basenames=poisoned-second-mpris-reader.qml,MediaBackend.qml, the exact case QMEDIA-03 exists to prevent)
  [PASS] self-test: poisoned-prose-only-mpris-mention.qml added alongside MediaBackend.qml -> MPRIS-reader-count check PASSES with count still 1 (hits=1 basenames=MediaBackend.qml, a prose mention must not increment the count)

Self-test summary: 59 passed, 0 failed
```

Re-run after both fixes below (`_qsd_reservation_equal`, comment-aware permissions
extraction) — still 59/59, zero regressions.

### Live run — BEFORE this plan's fixes (captured, HEAD `3c2c8af`, before `ca50e68`)

```
quickshell-doctor — Quickshell coexistence gate (QS-05/QS-06)
  [PASS] quickshell binary present on PATH
  [PASS] quickshell shell process alive (matches the launcher's exec'd invocation)
  [PASS] launcher log's last startup line has no crash/abort marker after it
  [PASS] namespace discipline: off-level: 0, wrong-pid: 0
  [PASS] keybind-doctor clean (MAINT-01 bind-collision proof, exit 0)
  [PASS] single org.freedesktop.Notifications owner, and it is quickshell
  [PASS] service-participant model: collisions: 0
  [PASS] single handler per hardware key: bad: 0
  [PASS] exactly one Quickshell MPRIS reader, and it is MediaBackend.qml (hits=1 basenames=MediaBackend.qml)
  [PASS] one-step-per-press volume probe: measured delta=3277, drift: 0
  [PASS] overview-namespace-conformance: count=0 off-level=0 wrong-pid=0
  [PASS] overview-shortcut-single-registration: manifest=1 globalshortcuts=1, keybind-doctor exit=0
  [FAIL] bar-reserved-zone-stability (QBAR-12): delta=50 axis=2 expected=50, attributed and stable, hot-reload=drifted, restore-verified=1, manifest-entries=9 validated=9
  [PASS] bar-surface-registry (GATE-03): source: rows=10 missing=0 unexpected-reservation=0 unregistered=0, live: permanent=1 off-level=0 wrong-pid=0 unmatched=0
  [PASS] bar-colour-role-routing: scanned=16 bad=0 offenders=none
  [PASS] bar-colour-alpha-resolution: offenders=none
  [PASS] permissions-enforce-readback: bool: true
  [FAIL] permissions-allowlist-paths-resolve (D-16-23 check 5): grants=9 missing=2 non-executable=0 pattern=1
  [FAIL] overview-content-check (D-16-23 check 6): windows=<unparsed> withContent=<unparsed> (raw='Not ready to accept queries yet.')
  [PASS] single-capture-path: files-instantiating-ScreencopyView=1 (WindowThumbnail.qml)

Summary: 17 passed, 3 failed
```

Note the MPRIS-reader-count line is already `[PASS]` here — the reader-count repair
(Plan 21-04) was already in place and green before this plan started; this plan's own
obligation for that item was only to re-confirm it stayed green through the deletion
(it did, in every run captured this session).

The third failure in this before-snapshot, `overview-content-check`
(`'Not ready to accept queries yet.'`), is a live-state warm-up timing artifact
distinct from the two named-open items — it did not recur in any of the 5 post-fix runs
below and is not one of the two items 21-GATE-02-RECORD.md named as this plan's business.
It is noted here for completeness (the run-to-run instability the standing rules asked
this plan to investigate) but not separately root-caused, since it never reproduced
again across 8 total live invocations this session (3 pre-fix, 5 post-fix).

### Root cause 1 — `bar-reserved-zone-stability`: comparison scope too broad

`quickshell-doctor`'s hot-reload half (and, once inspected further, its toggle-restore
half too) compared the **entire** `hyprctl monitors -j` JSON blob for byte-for-byte
string equality across a bounded polling window (up to 10 seconds for the hot-reload
half). That blob carries volatile fields with nothing to do with QBAR-12's own claim
("the bar's own reservation exists, is attributable, is stable") — `focused`,
`activeWorkspace`, and similar live desktop state. Any of those changing during the
window — ordinary desktop activity, not a reservation change — flips the naive
string-equality verdict to "drifted" with zero real reservation instability involved.

The check's own toggle-half (`_qsd_reservation_diff`, keyed by monitor name, comparing
only the `reserved` array) already does this correctly for its own axis/delta
measurement — the hot-reload half and the restore-verification half had each
independently reimplemented the comparison using the broad, wrong scope instead of
reusing it.

**Fix** (`hypr/.config/hypr/scripts/quickshell-doctor`, commit `ca50e68`): a new shared
helper `_qsd_reservation_equal(a, b)` narrows every "did the reservation actually
change" comparison in this check to the same name-keyed `reserved`-only diff — used now
by the hot-reload half, both restore-verification call sites, and (unchanged) the
existing compositor-reload half.

### Root cause 2 — `permissions-allowlist-paths-resolve`: comment-blind extraction

The check's binary-path extraction (`grep -oP 'binary\s*=\s*"\K[^"]+'`) was not
line-aware — it matched `binary = "..."` inside a Lua `--` comment exactly as readily
as inside a live `hl.permission()` call. The real `permissions.lua` carries three
deliberately-inert, explicitly "STOP — DO NOT ENABLE EITHER GRANT BELOW" candidate
grants (D-35, a documented decision record of a reproduced compositor SIGSEGV) — one
real-but-commented Hyprland self-load path plus two regex-pattern candidates, neither
of which exists as a real file and one of which (`^/var/cache/hyprpm/[^/]+/...`)
contains a `[` metacharacter. That is the exact and only source of the reported
`grants=9 missing=2 pattern=1`: 6 live grants (all resolve, all executable, no
metacharacter) plus those 3 commented candidates.

**Fix** (same commit): extraction is now line-aware, skipping any line whose trimmed
text starts with `--`, matching the exact discipline
`_qsd_windowrules_candidates` already applies earlier in this same file for the
identical reason (Lua comment exclusion).

### Live run — AFTER fixes, x5 consecutive invocations

```
Run 1: rc=0 passed=20 failures=0
Run 2: rc=0 passed=20 failures=0
Run 3: rc=0 passed=20 failures=0
Run 4: rc=0 passed=20 failures=0
Run 5: rc=0 passed=20 failures=0
```

Full output of run 1 (representative — all 5 are byte-identical modulo timestamps):

```
quickshell-doctor — Quickshell coexistence gate (QS-05/QS-06)
  [PASS] quickshell binary present on PATH
  [PASS] quickshell shell process alive (matches the launcher's exec'd invocation)
  [PASS] launcher log's last startup line has no crash/abort marker after it
  [PASS] namespace discipline: off-level: 0, wrong-pid: 0
  [SKIP] no summoned surface adds a reservation (D-21): summon-and-diff disabled by --no-summon
  [PASS] keybind-doctor clean (MAINT-01 bind-collision proof, exit 0)
  [PASS] single org.freedesktop.Notifications owner, and it is quickshell
  [PASS] service-participant model: collisions: 0
  [PASS] single handler per hardware key: bad: 0
  [PASS] exactly one Quickshell MPRIS reader, and it is MediaBackend.qml (hits=1 basenames=MediaBackend.qml)
  [SKIP] panel-namespace-conformance / panel-shortcut-single-registration / panel-notifications-single-owner / panel-osd-state-driven-trigger: disabled by --no-panel-checks
  [PASS] one-step-per-press volume probe: measured delta=3277, drift: 0
  [SKIP] one-step-per-press brightness probe (no backlight-class device)
  [SKIP] headless output add/remove, per-screen surface creation, reserved-space unchanged across hotplug (QS-03): disabled by --no-headless-output
  [PASS] overview-namespace-conformance: count=0 off-level=0 wrong-pid=0
  [SKIP] mpvpaper-layer-coexistence: no live wallpaper is currently selected
  [PASS] overview-shortcut-single-registration: manifest=1 globalshortcuts=1, keybind-doctor exit=0
  [PASS] bar-reserved-zone-stability (QBAR-12): delta=50 axis=2 expected=50, attributed and stable, hot-reload=identical, restore-verified=1, manifest-entries=9 validated=9
  [PASS] bar-surface-registry (GATE-03): source: rows=10 missing=0 unexpected-reservation=0 unregistered=0, live: permanent=1 off-level=0 wrong-pid=0 unmatched=0
  [PASS] bar-colour-role-routing: scanned=16 bad=0 offenders=none
  [PASS] bar-colour-alpha-resolution: offenders=none
  [PASS] permissions-enforce-readback: bool: true set: true
  [PASS] permissions-allowlist-paths-resolve (D-16-23 check 5): grants=6 missing=0 non-executable=0 pattern=0
  [PASS] overview-content-check (D-16-23 check 6): windows=4 withContent=4 (raw='active=true tiles=11 windows=4 withContent=4')
  [PASS] single-capture-path: files-instantiating-ScreencopyView=1 (WindowThumbnail.qml)

Summary: 20 passed, 0 failed
```

Post-fix, `grants=6` (down from the pre-fix `grants=9`) — exactly the 3 commented
candidate grants no longer counted, matching the root-cause analysis precisely.

**Bar left in the correct, original state**: `bash
hypr/.config/hypr/scripts/bar-visibility.sh status` after all of the above toggling
reports `visible`, confirming no residual state was left behind by the repeated
toggle-and-restore cycles this check performs internally.

---

## keybind-doctor — 14/14

```
keybind-doctor — Hyprland keybind regression gate
  [PASS] mainMod resolved from keybinds.lua (got: SUPER)
  [PASS] declared-bind parse shape guard: 85 hl.bind(...) line(s) parsed (parse errors: 0)
  [PASS] description parity (D-30): all 85 declared binds carry a trailing '--' description (missing: 0)
  [PASS] static grep: no 'walker -s <set>' invocation in keybinds.lua
  [PASS] hyprctl binds returned data
  [PASS] plain-text bind block shape guard: 85 block(s) parsed, shape errors: 0
  [PASS] declared-vs-registered: all 85 declared binds appear in hyprctl binds (missing: 0)
  [PASS] no shadowing: found: 0
  [PASS] release-bind inventory recorded (1 release-triggered bind(s) registered)
  [PASS] D-03 kill-bind present
  [PASS] quickshell manifest schema: shortcuts.json well-formed
  [PASS] no duplicate appid+name in quickshell manifest (found: 0)
  [PASS] quickshell shortcut registered: unregistered: 0, registry shape errors: 0
  [PASS] quickshell chord collision: found: 0

Summary: 14 passed, 0 failed
```

The Super+M shortcut (Plan 21-07) is accounted for: it is one of the 85 declared binds,
appears in `hyprctl binds`, and is the quickshell manifest entry validated by the last
three checks above.

---

## colour-lint — 144/144, motion-lint — 291/291

```
colour-lint — QML colour deny-by-default gate
  target: real deployed quickshell surface set
  [EXEMPT] WeatherPalette.qml — Phase 14 Plan 09 Task 4 approved exemption
  [EXEMPT] overview/DragGhost.qml shadowColor: — MD3 elevation shadow, not a theme colour
  [EXEMPT] overview/WindowThumbnail.qml shadowColor: — MD3 elevation shadow, not a theme colour
  [PASS] colour-lint: CHECK C: colour-lint scanned 73 surface(s) under /home/aorus/.config/quickshell
  ... (144 CHECK A/CHECK B pairs, all PASS, including MediaBackend.qml, MediaTab.qml,
       CavaService.qml, BarRoles.qml, Overview.qml, WorkspaceTile.qml — every file
       Plan 08's out-of-plan comment-rewrites touched)

Summary: 144 passed, 0 checks failed
```

```
motion-lint — motion-token deny-by-default gate
  target: real deployed surface set (4 root dir(s))
  [NOTE] hyprland-motion.conf absent — optional legacy source skipped (normal, hyprland-tokens.lua is primary)
  [EXEMPT] walker/**/style.css — motion is compositor-delivered
  [PASS] motion-lint: CHECK C: motion-lint scanned 146 surface(s) (css/scss=2, conf=9, qml=101, lua=34)
  ... (291 CHECK A/CHECK B pairs, all PASS, including every file this phase touched)

Summary: 291 passed, 0 checks failed
```

Both are also folded into `theme-doctor`'s own run above as genuine passes (not skips).

---

## test-media-hardening.sh — 24/24, Check 12 (T-21-26) included

```
test-media-hardening — adversarial gate for media-art-resolve.sh (BAR-04)

-- media-art-resolve.sh: artUrl scheme/host adversarial gate --
  [PASS] media-art-resolve.sh ftp://: exits non-zero
  [PASS] media-art-resolve.sh ftp://: curl never invoked
  [PASS] media-art-resolve.sh http://127.0.0.1: exits non-zero
  [PASS] media-art-resolve.sh http://127.0.0.1: host guard fires before any network call
  [PASS] media-art-resolve.sh http://[::1]/x.png: exits non-zero (SSRF bypass blocked)
  [PASS] media-art-resolve.sh http://[::1]/x.png: host guard fires before any network call
  [PASS] media-art-resolve.sh http://[fd00::1]/x.png: exits non-zero (SSRF bypass blocked)
  [PASS] media-art-resolve.sh http://[fd00::1]/x.png: host guard fires before any network call
  [PASS] media-art-resolve.sh http://2130706433/x.png: exits non-zero (SSRF bypass blocked)
  [PASS] media-art-resolve.sh http://2130706433/x.png: host guard fires before any network call
  [PASS] media-art-resolve.sh https://0x7f.0.0.1/x.png: exits non-zero (SSRF bypass blocked)
  [PASS] media-art-resolve.sh https://0x7f.0.0.1/x.png: host guard fires before any network call
  [PASS] media-art-resolve.sh http://[::ffff:127.0.0.1]/x.png: exits non-zero (SSRF bypass blocked)
  [PASS] media-art-resolve.sh http://[::ffff:127.0.0.1]/x.png: host guard fires before any network call
  [PASS] media-art-resolve.sh: two distinct https urls -> two distinct cache paths
  [PASS] media-art-resolve.sh: neither cache filename contains a substring of its url
  [PASS] media-art-resolve.sh: both resolved cache files actually exist on disk

-- media-art-resolve.sh: album-art handoff — bare-path contract (T-21-26) --
  [PASS] media-art-resolve.sh remote artUrl: stdout is a bare local path — no scheme separator anywhere
  [PASS] media-art-resolve.sh remote artUrl: stdout is not the input echoed back
  [PASS] media-art-resolve.sh remote artUrl: fetch is recorded in the stubbed network client's invocation log (no real network call)
  [PASS] media-art-resolve.sh local file:// artUrl: stdout is a bare local path — no scheme separator anywhere
  [PASS] media-art-resolve.sh local file:// artUrl: stdout is not the input echoed back with its scheme intact
  [PASS] media-art-resolve.sh local file:// artUrl: stdout resolves to the real underlying file path
  [PASS] media-art-resolve.sh local file:// artUrl: file branch never touches the network client

Summary: 24 passed, 0 failed
```

---

## Theme contract state — a documented fact, not a claim

```
$ node -e "const j=require(process.cwd()+'/theme-engine/.config/theme-engine/contract.json');process.stdout.write(String(j.files.length))"
17
```

Contract carries **17 file entries** — the post-migration size Plan 08 reduced it to
(18 → 17, removing the `ags.scss`/scss-vars entry). The removed entry's own format
family (`scss-vars`) remains represented: `theme-parity:239`'s own comment (re-cited
via `theme-doctor`'s folded run above) points at `_motion.scss` as the surviving
`scss-vars` representative, and `theme-parity`'s live run above shows `_motion.scss`
rendered and byte-identical across all 22 targets — the format family is exercised for
real, not merely present in a table.

---

## Exactly one MPRIS reader — the sweep plus the standing check

**One-time sweep** (Plan 21-04, repaired `quickshell-doctor` check 9 from an obsolete
"zero readers" assertion to "exactly one"): `21-08-SUMMARY.md`'s coverage table and this
plan's own `--self-test` run above both confirm the check's 4 fixtures (zero-reader,
one-reader, two-reader, prose-only-mention) all resolve correctly.

**Standing check, live, this session** (every quickshell-doctor invocation above,
pre-fix and post-fix alike):

```
[PASS] exactly one Quickshell MPRIS reader, and it is MediaBackend.qml (hits=1 basenames=MediaBackend.qml, under /home/aorus/.config/quickshell)
```

The sweep proved the check itself is correct (self-test fixtures); the standing check
proves the live tree currently satisfies it (hits=1, MediaBackend.qml only) — the sweep
is this plan's evidence that the check works, the standing check is the line it holds
afterward, exactly the distinction QMEDIA-03 requires.

---

## Deviation from the plan's own Task 2 `<verify>` block

The plan's Task 2 `<verify>` block includes a `theme-stress-test` invocation. This
executor's standing session rules (issued by the orchestrator that spawned this
session, not by this plan) unconditionally prohibit running `theme-stress-test` or any
command that live-applies a theme, following a prior session's accidental live
re-theming of the operator's desktop by running this exact command. This is a genuine
conflict between the plan text and a higher-priority session-level safety rule; the
safety rule was followed. See the dedicated section above for the static substitute
verification and the operator action this defers.
