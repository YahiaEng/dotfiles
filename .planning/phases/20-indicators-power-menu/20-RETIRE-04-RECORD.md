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
