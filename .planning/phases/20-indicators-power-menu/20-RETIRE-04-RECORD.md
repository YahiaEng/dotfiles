# 20-RETIRE-04-RECORD.md — swayosd removal record

Plan 20-09's own artifact. Records the pre-flight halt-or-proceed check (this section) and,
after Task 2's deletion, the post-deletion zero-hit measurement (appended by Task 3).

## Pre-flight

### 1. Gate A verdict

Read directly from `.planning/phases/20-indicators-power-menu/20-GATE-02-A-RECORD.md` §
"Gate A Criteria" and § "Deletion Authorisation":

| # | Criterion | Verdict |
|---|---|---|
| 1 | OSD frame family match | PASS |
| 2 | Live theme switch re-colours OSD | PASS |
| 3 | Volume/brightness/mic single-row + two-row column | PASS (volume, mic) / **NOT-DEMONSTRABLE** (brightness — zero backlight-class devices on this host, D-18-39 precedent; explicitly operator-accepted as an open named risk, does not block) |
| 4 | Hover pauses auto-hide, resumes (not resets) | PASS |
| 5 | Drag/scroll adjust slider in place, backend-confirmed | PASS |
| 6 | Caps Lock ON-only transition | **PASS — confirmed live** (closes WINDOWS row 77) |
| 7 | GATE-01 open questions answered with evidence | PASS |

**`## Deletion Authorisation` section reads: `RETIRE-04 AUTHORISED`.** No FAIL on any criterion.
Criterion 3's brightness half is NOT-DEMONSTRABLE, an accepted named risk carried forward, not a
FAIL — it does not block per the gate record's own text. **This does not halt.**

### 2. Interlock

Judged sha (from the Gate A record): `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205`.

```
$ git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/
$ echo $?
0
```

Exit code **0** — no output, the shell tree has not moved since the judged sha. Current HEAD at
the time of this pre-flight is `3775138899aace60805f1dc52c7bb1e88acb4252` (three commits ahead of
the judged sha, all `docs(20-08):` commits touching only `.planning/`, confirmed via
`git log --oneline 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205..HEAD -- quickshell/.config/quickshell/`
returning empty). **Interlock holds. This does not halt.**

### 3. SDDM verdict

Read directly from `.planning/phases/20-indicators-power-menu/20-GATE-01-MEASUREMENTS.md` §
"SDDM greeter Caps Lock (D-20-17)":

> **Verdict token:** `RETIRE-04 proceeds`

No on-screen indicator appeared at the SDDM greeter; the backend's pre-session reach is confirmed
dead by measurement. Not `BLOCKED`, not `UNTAKEN`. Normalized for this plan's own halt-or-proceed
grammar: **RETIRE-04: proceeds**. **This does not halt.**

### 4. Removal impact preview

The plan's suggested invocations do not run on this host's pacman (v7.1.0, libalpm 16.0.1):

```
$ pacman -Rns --print swayosd
error: invalid option: '--nosave' and '--print' may not be used together
$ pacman -Rnsp swayosd
error: invalid option: '--nosave' and '--print' may not be used together
```

This is a genuine pacman-version behaviour difference from what the plan assumed (Rule 3 blocking
issue, auto-fixed by substituting the equivalent flag combination pacman v7.1.0 accepts):
`--nosave`/`-n` cannot be combined with `--print` on this build. Substituted with `-Rsp` (drops
`-n`/`--nosave`, which only controls whether package-owned config files are preserved on removal —
irrelevant to a dry-run *package* impact preview; `-s` still recurses onto now-orphaned
dependencies):

```
$ pacman -Rsp swayosd
swayosd-0.3.1-1
```

**Output names only `swayosd-0.3.1-1` — nothing else.** No orphaned dependency is named, meaning
none of swayosd's dependencies (`glibc gtk4 gtk4-layer-shell libinput gdk-pixbuf2 pango libevdev
libpulse systemd-libs glib2 cairo dbus libgcc` per `pacman -Qi swayosd`) would become orphaned by
this removal — they are all still required by other installed packages. The removal is scoped to
`swayosd` alone. **This does not halt.**

### 5. Reverse-dependency check

```
$ pactree -r swayosd
swayosd
```

Only `swayosd` itself is printed — nothing on this host depends on it. **This does not halt.**

### 6. Baseline recall

Pre-deletion `retirement-check swayosd` output, committed in `20-RETIREMENT-BASELINE.md`
(captured 2026-08-15, exit 0, `status=pending failed_classes=0`). All hits are `[REPORT]` tier
(nothing `[FAIL]`-tier exists pre-retirement by the checker's own design — the `[FAIL]` tier only
fires once a surface's registry status flips to `retired`):

| Reference class | Hit count |
|---|---|
| own-tree | 4 |
| layer-window-rules | 0 |
| autostart | 1 |
| keybinds | 11 |
| contract-json | 1 |
| matugen-templates | 5 |
| checker-internals | 36 |
| test-fixtures | 3 |
| cross-package-refs | 13 |
| install-stow-lists | 10 |
| systemd-units | 2 |
| dbus-activation | 0 |
| xdg-autostart | 0 |
| host-package | 1 |
| planning-archive | 1057 |
| repo-prose | 3 |

Task 3's post-deletion run is measured against this table: every git-tracked-config class above
(own-tree, autostart, keybinds, contract-json, matugen-templates, checker-internals,
test-fixtures, cross-package-refs, install-stow-lists, systemd-units, host-package) must drop to
0 once `swayosd`'s registry status flips to `retired` and Task 2's deletion lands; `planning-archive`
and `repo-prose` are expected to stay non-zero (D-18-37 report tier, historical record).

**Note (host-package drift since baseline capture):** the pre-deletion baseline recorded
`pacman -Q swayosd: swayosd 0.3.1-1` on 2026-08-15; `pacman -Qi swayosd` re-run just now for this
pre-flight confirms the same version (`0.3.1-1`, Install Date 2026-07-13) — unchanged, no drift.

## Verdict

**All six pre-flight items clear. No halt condition is met.** Gate A is AUTHORISED with no FAIL,
the interlock holds at an unmoved shell tree, the SDDM measurement reads `RETIRE-04 proceeds`, the
removal preview (via the pacman-version-adjusted equivalent flag) names only `swayosd` itself with
no orphaned dependencies, and nothing reverse-depends on it. **RETIRE-04 is cleared to proceed to
the plan's own `checkpoint:decision` task**, which gates the actual irreversible package removal
separately from this read-only pre-flight.

This task made no repository or host change — `git diff --quiet HEAD -- swayosd/ matugen/
theme-engine/ hypr/ install.sh stow.sh` confirmed clean both before and after this section was
written (only `.planning/` changed).

## Post-deletion

### State-change note: manual removal outside this session

Between the pre-flight above and this task, the operator ran the package/unit removal manually
(outside this agent session), and a mid-task message reported that state. This record does not
take that message on trust: every fact below (`pacman -Q swayosd`, `systemctl is-enabled
swayosd-libinput-backend.service`, `systemctl list-unit-files`) was independently re-verified via
read-only commands run directly in this session before Task 2's own `<action>` proceeded. The
config-side edits below are this task's own work, committed together with the confirmed-absent
package/unit in a single commit, config-then-package, per the plan's own precedent.

**Two host-state defects were found and fixed as part of finishing this deletion, not by the
manual removal:**

1. A `swayosd-server` process (pid, confirmed via `pgrep -a swayosd`) was still running — an
   already-running instance outlives its own deleted package file until killed. Killed via
   `pkill -x swayosd-server`; the resulting stale transient systemd `--user` scope
   (`app-Hyprland-swayosd\x2dserver-*.scope`) cleared on its own once the process exited (confirmed
   absent via `systemctl --user list-units --all` and `systemctl --user reset-failed`).
2. A stale rendered `~/.local/state/theme/swayosd.css` (a matugen output from a prior theme
   render) remained on disk after `contract.json`'s entry for it was removed — `theme-doctor`'s
   D-29 state-manifest gate correctly flagged it as `unaccounted`. Deleted; `theme-doctor` returned
   to 519/519 immediately after.

### Before/after zero-hit pair (RETIRE-01's own requirement)

Pre-deletion baseline (`20-RETIREMENT-BASELINE.md`, captured 2026-08-15, `status=pending`):

| Reference class | Before (baseline) | After (this task) |
|---|---|---|
| own-tree | 4 | 0 (own-tree path no longer exists — `[SKIP]`, not counted as a hit) |
| layer-window-rules | 0 | 0 |
| autostart | 1 | 0 |
| keybinds | 11 | 0 |
| contract-json | 1 | 0 |
| matugen-templates | 5 | 0 |
| checker-internals | 36 | 0 |
| test-fixtures | 3 | 0 |
| cross-package-refs | 13 | 0 |
| install-stow-lists | 10 | 0 |
| systemd-units | 2 | 0 |
| dbus-activation | 0 | 0 |
| xdg-autostart | 0 | 0 |
| host-package | 1 | 0 |
| planning-archive (report-tier) | 1057 | 1188 (grew — this plan's own `.planning/` writes; D-18-37 report-tier, expected, not a failure) |
| repo-prose (report-tier) | 3 | 3 (report-tier, expected, not a failure) |

Every git-tracked-config (blocking-domain) class dropped to exactly 0. Raw post-deletion
`retirement-check swayosd` output (verbatim, exit 0):

```
retirement-check — surface=swayosd status=retired root=/home/aorus/dotfiles

[SKIP] swayosd/own-tree: own-tree path(s) not present under /home/aorus/dotfiles: swayosd/
[PASS] swayosd/layer-window-rules: no references
[PASS] swayosd/autostart: no references
[PASS] swayosd/keybinds: no references
[PASS] swayosd/contract-json: no references
[PASS] swayosd/matugen-templates: no references
[PASS] swayosd/checker-internals: no references
[PASS] swayosd/test-fixtures: no references
[PASS] swayosd/cross-package-refs: no references
[PASS] swayosd/install-stow-lists: no references
[PASS] swayosd/systemd-units: no references
[PASS] swayosd/dbus-activation: no references
[PASS] swayosd/xdg-autostart: no references
[PASS] swayosd/host-package: no references
[REPORT] swayosd/planning-archive: 1188 reference(s)
[REPORT] swayosd/repo-prose: 3 reference(s)

Summary: surface=swayosd status=retired failed_classes=0
```

Reaching this required going beyond `files_modified`'s declared list: `retirement-check`'s
`checker-internals`/`cross-package-refs`/`keybinds` classes scan comment prose too (word-boundary,
case-insensitive), and once the registry row flipped to `retired` in the same commit, every
surviving comment mentioning "swayosd" anywhere in `theme-stress-test`, `keybinds.lua`,
`AudioBackend.qml`, `Design.qml` (x2), `Osd.qml` and `quickshell.service` became a blocking `[FAIL]`
— not just the files this plan's frontmatter named. Each was reworded to drop the literal token
without changing its meaning (Rule 1/2 deviation, documented in `20-09-SUMMARY.md`). `wleave`
mentions in the same files were left untouched — confirmed still `status=pending` in the
`--all` run below, unmodified by this plan.

### Gate suite (all eight, literal exit codes)

| Gate | Exit code |
|---|---|
| `theme-engine/theme-doctor` | 0 (519 passed, 0 failed) |
| `theme-engine/theme-parity` | 0 (1721 passed, 0 failed) |
| `hypr/scripts/motion-lint` | 0 (283 passed, 0 failed) |
| `hypr/scripts/colour-lint` | 0 (142 passed, 0 failed) |
| `hypr/scripts/quickshell-doctor --self-test` | 0 (55 passed, 0 failed) |
| `hypr/scripts/quickshell-doctor` (live) | 1 first attempt (transient, see below); 0 on two subsequent clean re-runs (26 passed, 2 pre-existing unrelated failures — see Known Non-Blocking Findings) |
| `hypr/scripts/retirement-check --all` | 0 |
| `hypr/scripts/keybind-doctor` | 0 (14 passed, 0 failed) |

`theme-doctor`'s own `retirement-check` fold (`[REPORT] wleave (pending, RETIRE-05):
blocking-domain=67 ...`) confirms `wleave`/`ags`/`wlogout`/`eww` all stayed `pending`, unmodified
by this plan.

### `theme-stress-test` — deliberately not run in this plan

Not executed here, per this plan's own instruction. Its `REPRESENTATIVE_FILES` array still names
`wleave.css`, which plan 20-10 removes; running it here would either pass for the wrong reason
(wleave.css still present) or fail for a reason this plan does not own. **Plan 20-10 is the named
owner** of both running `theme-stress-test` and updating its `REPRESENTATIVE_FILES` array. A
single comment-only edit to `theme-stress-test:248` (dropping the word "swayosd" from a list of
retired daemons, leaving "wleave" untouched) was made in this plan's Task 2 commit — required
because `retirement-check`'s `checker-internals` class scans that file's raw text, not because
`theme-stress-test` itself was run or because its `REPRESENTATIVE_FILES` array was touched.

### Known non-blocking findings (investigated, not this plan's to fix)

**Transient live-run failure, not reproduced on retest.** The FIRST live `quickshell-doctor` run
this session showed two additional failures: `panel-osd-state-driven-trigger` measured
`hw-key=2` (expected 1) and the one-step-per-press volume probe measured `delta=6554` (exactly
2x the recorded baseline `3277`). Investigated directly: a clean, isolated manual
`wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0` measured a delta of exactly 3277 — matching
the baseline precisely, with no doubling. Two subsequent full re-runs of `quickshell-doctor` (host
volume state settled) both passed cleanly with no doubling. Conclusion: a one-off timing artifact
(most likely the differential check's own PipeWire-volume restore step landing close in time to
the next check's baseline read), not a persistent defect in the wpctl/-l 1.0 exec target this
plan repointed the probe onto. Not chased further; flagged here rather than silently dropped.

**Two pre-existing, unrelated failures, confirmed on every live run (before and after this
plan's edits, and unrelated to swayosd by content):**

1. `zero Quickshell MPRIS writers (found in 1 file(s))` — `modules/dashboard/MediaBackend.qml`'s
   own `Quickshell.Services.Mpris` import. No `swayosd` reference; not in this plan's
   `files_modified`. Logged to `deferred-items.md`, owner: Phase 21 media work.
2. `permissions-allowlist-paths-resolve` (`grants=9 missing=2 non-executable=0 pattern=1`) —
   `hypr/.config/hypr/config/permissions.lua`'s screencopy allow-list. No `swayosd` reference; not
   in this plan's `files_modified`. Logged to `deferred-items.md`, owner: whichever plan next
   touches overview/screencopy permission grants.

Both are logged in `.planning/phases/20-indicators-power-menu/deferred-items.md` per the
executor's scope-boundary rule, not fixed here.

### What this deletion did NOT prove

Nothing here establishes that a fresh clone of this repository still reproduces the desktop from
`install.sh` + `stow.sh` alone. `install.sh`'s swayosd package entry and its
`swayosd-libinput-backend.service` enable block were removed by inspection and by the same
gates this record already ran (`theme-doctor`, `retirement-check --all`), not by an actual
fresh-install run. That proof is **RETIRE-09's fresh-install container gate, Phase 22** — named
here explicitly so this record does not imply a broader guarantee than it earned.

### Carried-forward, still-open items (unaffected by this plan)

- **Brightness stays unproven on this host.** Gate A recorded criterion 3's brightness half as
  `NOT-DEMONSTRABLE` (zero backlight-class devices), an accepted named risk, not a pass.
  `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md` and WINDOWS.md
  row 78 remain **OPEN** — this plan did not close them, and does not close them now.
- **Caps Lock was confirmed live** (WINDOWS row 77, closed in plan 20-08) — the 250ms sysfs poll
  in `CapsLockBackend.qml` fires correctly on a real physical key press. This is what made
  dropping swayosd's Caps Lock role (including its libinput backend) safe.
- **`wleave`, `ags`, `wlogout`, `eww` are all untouched**, confirmed `status=pending` in the
  `retirement-check --all` run above — plan 20-10's scope (RETIRE-05/06/07), not this plan's.

### Verdict

RETIRE-04 complete: `swayosd` and `swayosd-libinput-backend.service` are gone from both repo and
host, every reference class (including the checker-internals/test-fixture/cross-package-refs
classes CONTEXT.md's `canonical_refs` did not enumerate) is cleared, the before/after zero-hit
pair is committed, and all eight gates are green with their literal exit codes recorded above.
