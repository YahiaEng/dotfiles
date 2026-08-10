# Phase 17 (Ambient Extras) — Criterion-3 Cut Sweep Report

**Run at:** 2026-08-10 (Phase 17's close, plan 17-06)
**Sweep exit code:** 0
**Verdict counts:** `OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1`

This is a real result, not a formality: it means the five sibling plans'
own declared scope boundaries held all the way to phase close, and that
this sweep's own drift-detection path is proven (not merely assumed) to
fire — see `17-cut-sweep.sh --self-test`, which replays a synthesised
`[DRIFT]` case before this run is trusted. Per the plan's own reasoning,
a clean sweep is exactly as reportable a finding as a dirty one — see
"What a clean sweep means" below.

---

## Full sweep output, verbatim (every `[OK]` line included)

```
[OK] S-01 wallpaper-visibility.sh -> install.sh [finished, wired] — transcribed verbatim; mpvpaper is the sole entry in that indentation column
[OK] S-02 wallpaper-visibility.sh (owner) x stow.sh live/ pre-create loop -> stow.sh [finished, wired] — transcribed verbatim from the shipped stow.sh:223 mkdir -p line; tracer row, proven in Task 1
[OK] S-03 wallpaper-visibility.sh (owner) x .gitignore media exclusion -> .gitignore [finished, wired] — transcribed verbatim from .gitignore:41
[OK] S-04 wallpaper-fullscreen-watch.sh (D-27, conditional branch) <-> hypr/.config/hypr/scripts/wallpaper-visibility.sh [symmetric: artifact=no ref=no] — 17-01's own recorded D-26 verdict: PASS on -a full, D-27 watcher NOT built. Live-verified: the watcher file does not exist AND no fullscreen source name appears in the real allowlist case statement (only idle|gaming|motion) - symmetric absence, matching the SUMMARY exactly
[OK] S-05 theme_engine_wallpaper_extract_frame -> theme-engine/.config/theme-engine/contract.json [finished, wired] — confirmed the 12th engine_owned_files entry per 17-02-SUMMARY.md
[OK] S-06 theme_engine_wallpaper_frame_repair -> theme-engine/.config/theme-engine/theme-apply [finished, wired] — call site precedes theme_engine_generate per 17-02's own D-08 ordering
[OK] S-07 theme_engine_wallpaper_is_live_ref -> theme-engine/.config/theme-engine/theme-doctor [finished, wired] — the D-11 conditional gate's own shape check
[OK] S-08 theme_engine_wallpaper_sync_owner -> theme-engine/.config/theme-engine/theme-apply [finished, wired] — D-21's single owner-declaration call site, between autoset and reload
[OK] S-09 theme_engine_wallpaper_sync_owner (hypridle consumer) -> hypr/.config/hypr/hypridle.conf [finished, wired] — the pre-existing 300s dim listener extended, no new listener block (D-30) - verbatim from hypridle.conf:72-73
[OK] S-10 _gaming_wallpaper_toggle -> hypr/.config/hypr/scripts/gaming-mode-toggle.sh [finished, wired] — gaming_mode_off's mirrored idle-show call, closing the stranded-idle case
[OK] S-11 _qsd_assert_mpvpaper_layers -> hypr/.config/hypr/scripts/quickshell-doctor [finished, wired] — the tail call site that actually invokes the coexistence gate
[OK] S-12 compliant-mpvpaper-layers.json fixture -> hypr/.config/hypr/scripts/quickshell-doctor [finished, wired] — named by the --self-test replay
[OK] S-13 poisoned-offlevel-mpvpaper-layers.json fixture -> hypr/.config/hypr/scripts/quickshell-doctor [finished, wired] — named by the --self-test replay
[OK] S-14 wp_strip_markers -> hypr/.config/hypr/scripts/wallpaper-picker.sh [finished, wired] — the owner's snapshot (line ~109) and restore (line ~602) call sites, both present
[OK] S-15 install.sh guarded hyprpm block -> install.sh [finished, wired] — hyprpm's own stated build toolchain
[OK] S-16 install.sh guarded hyprpm block -> install.sh [finished, wired] — hyprpm's own stated build toolchain
[OK] S-17 install.sh guarded hyprpm block -> install.sh [finished, wired] — D-32 package half
[OK] S-18 hyprpm-complete.sh -> hypr/.config/hypr/scripts/theme-init.sh [finished, wired] — one backgrounded, output-suppressed invocation before the exec into theme-apply
[INFO] S-19 hyprpm dynamic-cursors cache artifact (D-38, host-only, root-owned) [present, owner=root, mtime=2026-08-09 00:33:21.808894623 +0300] — D-38: warn-only, never acted on. Operator remediation (never executed by this script): hyprpm remove dynamic-cursors
[OK] S-20 dynamic-cursors.lua config surface -> hypr/.config/hypr/hyprland.lua [finished, wired] — the 8th required module
[OK] S-21 HYPRCURSOR_THEME cursor pin (option-c, format-symmetry invariant) <-> hypr/.config/hypr/config/env.lua [symmetric: artifact=yes ref=yes] — option-independent invariant only: 17-05's checkpoint resolved option-c, so both files pin theme names by construction - this row asserts uwsm/env and env.lua carry the token symmetrically, never a fixed value
[OK] S-22 autostart.lua phase-17 token sweep — asserted empty, confirmed zero hits in hypr/.config/hypr/config/autostart.lua — D-15/D-35 no-new-entries prohibition, independently re-asserted from outside the four plans that each promised to honour it
[OK] S-23 stow.sh phase-17 token sweep (invariant token set, excludes S-02's own live/ literal) — asserted empty, confirmed zero hits in stow.sh — 17-04/17-05 both claim they left stow.sh byte-unchanged; the invariant token set (deliberately narrower than S-02's own $theme_name/live literal) returns zero, confirming it from outside
[OK] E-01 windowrules.lua phase-17 token sweep + windowrules.conf reconciliation — asserted empty, confirmed zero hits in hypr/.config/hypr/config/windowrules.lua — criterion 3 names windowrules.conf, which does not exist (13.1 Lua cutover); windowrules.lua swept in its place. Token set deliberately excludes bare mpv and bare wallpaper-picker - the two pre-existing lines (:46 float rule class ^(mpv)$, :72-73 wallpaper-picker rule) that would false-positive under a lazy token
[OK] E-02 every *.qml in the repo - phase-17 token sweep — asserted empty, confirmed zero hits in glob:*.qml — 38 *.qml files found live via find . -name '*.qml' -not -path './.git/*' at authoring time, matching plan-time count
[OK] E-03 QML in-QML video-decoding tripwire (criterion 1 boundary + Out of Scope entry) — asserted empty, confirmed zero hits in glob:*.qml — verified zero at plan time; this pass enforces it mechanically as both a criterion-3 drift check and a criterion-1/Out-of-Scope boundary check

[INFO] summary OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1
```

`--self-test` result at the time this report was authored: **26 passed, 0
failed, exit 0** — including a real `[DRIFT]` replay (synthesised
consumer file, located to a real line number) and a replay proving a
poisoned manifest row (unknown `ARTIFACT` prefix) halts the *whole*
sweep, not just one interpreter call (see "A bug this sweep found in
itself" below).

**What a clean sweep means.** Every row above resolved `[OK]` (or, for
S-19, `[INFO]` — a report-only line, never a verdict). Zero `[FAIL]`,
zero `[DRIFT]`. That is not "nothing to report" — it means all five
sibling plans' own "Explicitly NOT produced by this plan" boundaries
held under an independent, mechanical check that is *proven* able to
fail (the `--self-test` drift replay), run against the actual shipped
text rather than the plan's predictions of it. Per 13-03's own
precedent for reporting fault-injection results with equal prominence
regardless of outcome: a clean result here is exactly as significant a
finding as a dirty one would have been, and is reported with the same
weight.

---

## A bug this sweep found in itself (Rule 1, disclosed)

While proving the sweep's own "unknown manifest prefix is loud" gate
(Task 1's acceptance criterion) against a real poisoned manifest row —
not just a direct function call — a genuine bug surfaced: `_artifact_present`/
`_ref_present` call `exit 2` on an unknown prefix, but because they run
inside a `$(...)` command substitution, that `exit` only terminated the
*subshell*, not the main script. A poisoned row limped on as a plain
`[FAIL]` line instead of halting the sweep — exactly the "silent
fallthrough on a typo" failure the plan's own acceptance criteria named
as unacceptable. Fixed with `_die_on_bad_rc`, which re-propagates the
subshell's real exit code into the parent shell immediately after every
interpreter call; re-verified with the poisoned-manifest reproduction
(exit 2, sweep halted cleanly) and a new `--self-test` replay. Committed
inside Task 2 (`659b35a`), since it was found live while proving that
same task's own acceptance criteria.

---

## Coverage reconciliation — every item, one bucket, arithmetic stated

Every bullet in all five sibling plans' own **"Artifacts this phase
produces"** sections is classified into exactly one of three buckets:
**covered** (a named manifest row, or — for the five D-38-excluded
cursor-theme pin sites — the accepted-gap section below, which names
and anti-ghost-checks them even though they carry no drift verdict by
design), **runtime-only** (a `~/.cache`/`~/.local/state`/`/var/cache`
path, or git-ignored scratch data — nothing in the repo can reference
it, so a consumer check has nothing to find), or **internal** (a
private function/variable whose only consumer is the file that defines
it, already covered by that file's own row).

| Plan | Items | Covered | Runtime-only | Internal |
|------|------:|--------:|-------------:|---------:|
| 17-01 | 12 | 8 | 2 | 2 |
| 17-02 | 11 | 6 | 1 | 4 |
| 17-03 | 19 | 13 | 2 | 4 |
| 17-04 | 9 | 6 | 3 | 0 |
| 17-05 | 10 | 7 | 1 | 2 |
| **Total** | **61** | **40** | **9** | **12** |

`40 + 9 + 12 = 61`. No item from any sibling's "Artifacts this phase
produces" section was left unplaced.

<details>
<summary>Full item-by-item placement</summary>

**17-01** (`wallpaper-visibility.sh`, mpvpaper, `live/`):
1. `wallpaper-visibility.sh` (file) → **covered** (S-01/S-02/S-03/S-04)
2. `wallpaper-fullscreen-watch.sh` (conditional file) → **covered** (S-04, branch)
3. Private functions inside `wallpaper-visibility.sh` (`_acquire_lock`, `_write_intent`/`_read_intent`, `_write_selection`/`_read_selection`, `_validate_selection`, `_write_actuated`, `_compute`, `_actuate`, `main`) → **internal**
4. CLI surface: `idle`/`gaming`/`motion` suppression verbs → **covered** (S-09, S-10)
5. CLI surface: `select`/`clear`/`reassert`/`status` verbs → **internal** (consumed only by `wallpaper-picker.sh`, itself covered via S-14)
6. CLI surface: `fullscreen` 4th source name (D-27 branch) → **covered** (S-04)
7. Runtime state under `~/.cache/wallpaper-visibility.d/` (dir + 4 named files) → **runtime-only**
8. `~/Pictures/Wallpapers/<theme>/live/` → **covered** (S-02)
9. `install.sh` `AUR_PKGS` `mpvpaper` entry → **covered** (S-01)
10. `stow.sh` `live/` pre-create loop → **covered** (S-02)
11. `.gitignore` media-exclusion rule → **covered** (S-03)
12. Scratch probe assets (`tracer-probe.mp4`/`.gif`/`.webp`) → **runtime-only**

**17-02** (frame extraction, `contract.json`, repair gate):
1. `theme_engine_wallpaper_is_live_ref` → **covered** (S-07)
2. `theme_engine_wallpaper_frame_path` → **internal**
3. `theme_engine_wallpaper_frame_offset` → **internal**
4. `theme_engine_wallpaper_extract_frame` → **covered** (S-05)
5. `theme_engine_wallpaper_frame_repair` → **covered** (S-06)
6. Module-level vars `FRAME_DIR`/`FRAME_OFFSET_DEFAULT` → **internal**
7. `contract.json` `wallpaper-frames` entry → **covered** (S-05)
8. `theme-apply` `frame_repair` call site → **covered** (S-06)
9. `theme-doctor` source line + D-11 gate → **covered** (S-07)
10. Runtime state (`wallpaper-frames/`, `.png`, `.offset`) → **runtime-only**
11. Existing symbols modified (`autoset`, `WALLPAPER_DIR`, `LAST_WALLPAPER_DIR`, `engine_owned_files`) → **internal**

**17-03** (picker, sync-owner, debounce/restore, coexistence gate):
1. `theme_engine_wallpaper_sync_owner` → **covered** (S-08, S-09)
2. `wp_strip_markers` → **covered** (S-14)
3. `_gaming_wallpaper_toggle` → **covered** (S-10)
4. `_qsd_mpvpaper_layer_rows` → **internal**
5. `_qsd_assert_mpvpaper_layers` → **covered** (S-11)
6. `_qsd_check_mpvpaper_layer_coexistence` → **covered** (S-11)
7. `wallpaper-visibility.sh snapshot` verb → **covered** (S-14)
8. `wallpaper-visibility.sh restore` verb → **covered** (S-14)
9. `LIVE_MARKER` var → **internal**
10. `FRAME_DIR_REAL`/`CURRENT_THEME`/`LAST_WALLPAPER_DIR` interpolated vars → **internal**
11. Runtime state `~/.cache/wallpaper-picker-hover` → **runtime-only**
12. Runtime state `~/.cache/wallpaper-visibility.d/.snapshot` → **runtime-only**
13. `compliant-mpvpaper-layers.json` fixture → **covered** (S-12)
14. `poisoned-offlevel-mpvpaper-layers.json` fixture → **covered** (S-13)
15. `theme-apply` `sync_owner` call site → **covered** (S-08)
16. `hypridle.conf` extension → **covered** (S-09)
17. `gaming-mode-toggle.sh` entries (calls + header fix) → **covered** (S-10)
18. `quickshell-doctor` tail call + self-test replays → **covered** (S-11, S-12, S-13)
19. Existing symbols modified (`ACTIVE_MARKER`, `ENUM_SCRIPT`, `PREVIEW_SCRIPT`, `LIVE_SCRIPT`, `PREVIOUS_WALLPAPER`, `THEME_HAS_IMAGES`, `BARE_FILENAME`, `_gaming_waybar_toggle`, `gaming_mode_on`, `gaming_mode_off`, `_qsd_layers_json`, `check`) → **internal**

**17-04** (guarded hyprpm install, D-34 fault injection):
1. `hyprpm-complete.sh` (file) → **covered** (S-18)
2. `install.sh` `cmake` in `PACMAN_PKGS` → **covered** (S-15)
3. `install.sh` `cpio` in `PACMAN_PKGS` → **covered** (S-16)
4. `install.sh` `rose-pine-hyprcursor` in `AUR_PKGS` → **covered** (S-17)
5. `install.sh` guarded dynamic-cursors block + `HYPRPM_PLUGIN_URL` → **covered** (S-15/S-16/S-17)
6. `theme-init.sh` `hyprpm-complete.sh` invocation → **covered** (S-18)
7. `/var/cache/hyprpm/<user>/state.toml` (read, pre-existing) → **runtime-only**
8. `dynamic-cursors.so` (read, pre-existing) → **runtime-only**
9. `dynamic-cursors/state.toml` (read, pre-existing) → **runtime-only**

**17-05** (dynamic-cursors config surface, D-32 pin):
1. `dynamic-cursors.lua` (file) → **covered** (S-20)
2. `hyprland.lua` `require` line → **covered** (S-20)
3. `env.lua` cursor-theme pin + `HYPRCURSOR_THEME`/`SIZE` → **covered** (S-21 + accepted-gap section)
4. `uwsm/env` cursor-theme pin + vars → **covered** (S-21 + accepted-gap section)
5. `generate.sh` `gtk-cursor-theme-name` x2 → **covered** (accepted-gap section, D-38 exclusion)
6. `xsettings.xml` `CursorThemeName` x2 → **covered** (accepted-gap section, D-38 exclusion)
7. `install.sh` `rose-pine-cursor` in `AUR_PKGS` → **covered** (accepted-gap section, D-38 exclusion — per `install.sh`'s own comment tying this entry to the pin)
8. New Hyprland config option names (`plugin:dynamic-cursors:*`) → **internal**
9. `HYPRCURSOR_THEME`/`SIZE` env var *names* (as declarations, distinct from the site pins above) → **internal**
10. Runtime paths read (`dynamic-cursors.so`, `manifest.hl`, `Bibata .../cursors/`) → **runtime-only**

</details>

---

## The five named consumers, each with a verdict

**`stow.sh`** — `[OK]` S-02 (17-01's `live/` loop, tracer-proven), `[OK]`
S-23 (invariant token set: zero phase-17 tokens beyond S-02's own
literal). 17-04 and 17-05 both claimed they left this file byte-unchanged;
confirmed from outside.

**`install.sh`** — `[OK]` S-01 (`mpvpaper`), `[OK]` S-15/S-16/S-17
(`cmake`/`cpio`/`rose-pine-hyprcursor`, the guarded hyprpm block). The
`rose-pine-cursor` entry (17-05) is accounted for in the accepted-gap
section below, per D-38's own exclusion (the entry is explicitly tied
to the cursor-theme pin in the file's own comment).

**`windowrules`** — `[OK]` E-01. **Reconciliation, stated plainly:**
criterion 3 names `windowrules.conf`; `test -e
hypr/.config/hypr/windowrules.conf` fails — that file does not exist
and has not since the 13.1 Lua cutover replaced it with
`hypr/.config/hypr/config/windowrules.lua`. The `.lua` file was swept
in its place, with zero hits for the full phase-17 token set. The
token set deliberately **excludes** bare `mpv` and bare
`wallpaper-picker` — line 46's pre-existing float rule (`class =
[[^(mpv)$]]`) and lines 72-73's pre-existing `wallpaper-picker` named
rule both predate Phase 17 by many milestones, and a lazy token would
have false-positived on either. E-01 returns zero on the shipped repo
with the precise token set actually used.

**`contract.json`** — `[OK]` S-05 (`wallpaper-frames`, the 12th
`engine_owned_files` entry).

**QML imports** — `[OK]` E-02 (zero phase-17 tokens across all 38
`*.qml` files in the repo, enumerated live rather than hardcoded), `[OK]`
E-03 (zero hits for the Qt-multimedia/`MediaPlayer`/`VideoOutput`
video-decoding tripwire — verified zero at plan time, so this is a
real assertion, not a tautology). E-03 does double duty: it is both a
criterion-3 drift check on this phase's own scope and a mechanical
enforcement of criterion 1's "playback owned by an external player
rather than decoded inside QML" clause and REQUIREMENTS.md's Out of
Scope entry "In-QML video decoding for animated wallpaper."

---

## D-38's hyprpm artifact — warned, never acted on

`S-19` reports `/var/cache/hyprpm/aorus/dynamic-cursors` as `[INFO]`
(not `[WARN]`, because 17-04 — its owning plan — has a SUMMARY, i.e.
finished): present, owner `root`, mtime `2026-08-09 00:33:21`. The
operator's own remediation is printed as text —

```
hyprpm remove dynamic-cursors
```

— and is never executed by this sweep. The comment-stripped
`17-cut-sweep.sh` contains zero occurrences of `rm`, `sudo`, `mv`,
`truncate`, `pkill` or `hyprpm ` as an executed command (verified by
grep at Task 1 and re-verified after every later addition); this row's
whole action is read-only inspection (`test -d`, `stat`) of a root-owned
path outside the repo. This is exactly D-38's "warns or prompts rather
than acts" clause, and the one thing it may never do — a silent
privileged removal — is structurally impossible here, not merely
avoided by convention.

---

## The accepted gap — five sites, real line numbers, at its true size

D-38 originally named **one** file (`generate.sh`). RESEARCH.md added a
third site at `env.lua`. **17-05 then found the pin has five sites, not
three.** This report restates the count at its true, currently-measured
size, using the shipped line numbers as of this sweep (17-05's own
render lines shifted from `166,171` to `175,180` during that plan's own
execution — transcribed from the real file, not predicted):

| # | File | Line(s) | Current value |
|---|------|---------|----------------|
| 1 | `theme-engine/.config/theme-engine/lib/generate.sh` | 175 | `gtk-cursor-theme-name=BreezeX-RosePine-Linux` (dark GTK3 branch) |
| 2 | `theme-engine/.config/theme-engine/lib/generate.sh` | 180 | `gtk-cursor-theme-name=BreezeX-RosePine-Linux` (dark GTK4 branch) |
| 3 | `hypr/.config/hypr/config/env.lua` | 22, 24 | `XCURSOR_THEME=BreezeX-RosePine-Linux`, `HYPRCURSOR_THEME=rose-pine-hyprcursor` |
| 4 | `uwsm/.config/uwsm/env` | 16, 18 | `XCURSOR_THEME=BreezeX-RosePine-Linux`, `HYPRCURSOR_THEME=rose-pine-hyprcursor` |
| 5 | `thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` | 6, 10 | `CursorThemeName=BreezeX-RosePine-Linux` (x2 properties) |

**Arithmetic, stated honestly rather than rounded to match a prior
claim:** grouped by *site* (one row per file-location cluster, matching
the checkpoint's own "five sites" framing), this is **5 sites**. Counted
by individual *declaration line*, it is **8** — generate.sh's two
`printf` statements, env.lua's two `hl.env()` calls, uwsm/env's two
`export` lines, and xsettings.xml's two properties. 17-05's own SUMMARY
stated "seven declarations across five files" in its closing handoff;
live re-measurement at this sweep finds **4 files, 8 declaration
lines** — the file count in that closing note appears to be off by one
against the actual shipped tree (there are 4 distinct files, not 5;
`generate.sh`, `env.lua`, `uwsm/env`, `xsettings.xml`). This discrepancy
is recorded here rather than silently propagated, per this plan's own
instruction to state the gap "at its true size" — the 5-sites/8-lines
figures above are the ones a future reader should trust, because they
are re-derived live at this sweep's authoring time directly from the
shipped files (`grep -rn`, verbatim output captured), not carried
forward from an earlier plan's closing arithmetic.

**Anti-ghost format-resolution check, per site, `[INFO]`:**

```
[INFO] XCursor pin resolves: test -d /usr/share/icons/BreezeX-RosePine-Linux/cursors -> PRESENT
[INFO] hyprcursor pin resolves: test -f /usr/share/icons/rose-pine-hyprcursor/manifest.hl -> PRESENT
```

Both formats resolve to real, installed theme directories today — this
is the **latent-failure check**, not a pass/fail gate; the point is
that a mid-flight cut removing the `rose-pine-hyprcursor` /
`rose-pine-cursor` package declarations from `install.sh` **without**
also reverting these 8 lines would silently break this exact check on
the next fresh install, and every subsequent theme render would name a
cursor theme that is not installed — the desktop would silently fall
back to a stock pointer on every surface, the same failure class as the
`adw-gtk3-dark` pin already documented in `CLAUDE.md`.

**These 8 lines are excluded from drift verdicts per D-38** — this
report states them, it does not sweep them for `[DRIFT]`. The exclusion
is D-38's own locked decision; this task does not override, close, or
silently narrow it.

---

## Success criteria — reconciled against quoted evidence, not plan completion

**Criterion 1** ("A video wallpaper plays beneath the desktop and hides
itself when a fullscreen client takes focus, with playback owned by an
external player rather than decoded inside QML"):
- `17-01-SUMMARY.md`, D4: D-26 probe **PASS** — `mpvpaper`'s own log line
  `Pause triggered by:` matched, `/proc`-delta CPU dropped to
  `0.00-0.50%` from a `~2-6.5%` baseline during a real fullscreen toggle,
  resumed on release.
- `17-03-SUMMARY.md`, D5: the blocking human render-and-look gate,
  **APPROVED** across two rounds — round 1 found real bugs (lock-screen
  stuck on a still, motion-off reverted to a still instead of the
  video's own frame), root-caused and fixed in `87f539e`; round 2
  re-verified those two steps and closed all 10.
- E-03 (this sweep): zero hits for `QtMultimedia`/`MediaPlayer`/`VideoOutput`
  across all 38 `*.qml` files — mechanically confirms "not decoded
  inside QML."
- **PROVEN.**

**Criterion 2** ("Dynamic cursors install as an optional guarded
dependency: with the plugin build forced to fail, `install.sh` warns
and completes rather than failing, and the desktop keeps a working
cursor"):
- `17-04-SUMMARY.md`, D4: D-34 fault injection, exit code **0**, stderr
  verbatim: `⚠ dynamic-cursors: no cached sudo credentials — skipping
  optional plugin build (hypr/.config/hypr/scripts/hyprpm-complete.sh
  completes it after login)` — reproduced under both a
  credentials-unavailable condition and an isolated bad-URL `hyprpm
  add` failure. `hyprpm list`/`state.toml` byte-identical before and
  after every test — no pollution.
- `17-04-SUMMARY.md`, D5: the blocking degraded-cursor render gate,
  **APPROVED** — with `dynamic-cursors` deliberately unloaded
  (`hyprctl plugin unload ...`), the desktop kept a working, undeformed
  cursor; `hyprpm reload` restored the plugin.
- **PROVEN.**

**Criterion 3** ("If this phase is cut mid-flight, a consumer-check
sweep runs at its close... carries no references to anything it
started and did not finish"):
- This plan's own sweep run, above: `OK=25 FAIL=0 DRIFT=0 WARN=0
  INFO=1`, exit 0, with a proven-can-fail `[DRIFT]` path
  (`--self-test`).
- **PROVEN — and it is this report itself that is the proof.**

No criterion above is marked satisfied on the strength of a plan being
committed; each cites the specific SUMMARY, the specific evidence
(exit codes, log lines, `/proc` deltas, or this sweep's own verdict
counts), and the specific human checkpoint outcome where one was
load-bearing.

---

## AMB-01 and AMB-02 — marked on evidence

**AMB-01** ("A video wallpaper plays beneath the desktop and hides
itself when a fullscreen client is focused") is criterion 1 plus the
picker/suppression/wiring work that makes it usable. Evidence: criterion
1's proof above, plus 17-03's three suppression states (idle/gaming/
reduced-motion) wired through the single D-21 `sync_owner` path and
live-verified including the stranded-idle case, plus the picker's
merged still+live enumeration and frame-aware preview. **Marked `[x]`
Complete in `REQUIREMENTS.md`.**

**AMB-02** ("Dynamic cursors are installed as an optional guarded
dependency — a missing, unbuilt or ABI-broken plugin degrades
gracefully and never fails an unattended install") is criterion 2's two
clauses, both proven above, plus D-36/D-37's mode/shake config —
live-verified via `getoption` readback across a real post-restart
plugin load (`17-05-SUMMARY.md`, D1). **Marked `[x]` Complete in
`REQUIREMENTS.md`, with an explicit, prominent caveat carried in the
same edit:** D-35's stretch objective — loading the plugin
declaratively from Lua config (`hl.plugin.load()`) rather than via
`hyprpm` — was tested exhaustively across every reachable permission
state and found **conclusively unsafe** on this Hyprland build
(`0.56.2`, commit `efb50993`): an unmatched grant produces a real
Allow/Deny dialog at every login and every idle-lock; a matching grant
produces a fatal `SIGSEGV` via infinite `Config::Lua::CConfigManager::
reload() -> handlePluginLoads() -> postConfigReload() -> reload()`
recursion, reproduced twice with `coredumpctl` backtraces. The call was
removed from `dynamic-cursors.lua` entirely, on this evidence. **This
is a mechanism finding, not a criterion-2 shortfall** — AMB-02's own
wording does not mandate a specific load path, and the actual, proven
mechanism (`hyprpm` + `hyprpm-complete.sh`'s post-login orchestration,
delivered by 17-04) is what the live desktop actually runs on, verified
working (`hyprctl plugin list` reports the plugin loaded; `getoption`
confirms `mode`/`shake` applied). D-35 not shipping declaratively is
recorded here plainly rather than implied as done, per 17-05's own
explicit instruction to this plan.

---

## The three flagged assumptions — reconciled, none dropped, none invented

Per this plan's own no-silent-drop equality (2 probe-surfaced items to
2 surfaced assumptions in 17-01/17-04, plus 17-03's D-28 dependency —
three total, no fourth authored here):

1. **AMB-01's spec-less edge-coverage row** (owner 17-01, `category:
   unclassified`, `status: unresolved`) — **still open.** Restated
   verbatim from `17-01-SUMMARY.md`/`17-02-SUMMARY.md`: Phase 17 has no
   SPEC.md, so the deterministic edge-coverage probe returned
   `unclassified`/`unresolved`, and per protocol this was never
   auto-resolved with a backstop. The edge cases 17-01/17-02/17-03
   verified (fullscreen toggle, animated GIF/WebP, loop-past-end,
   path-traversal rejection, dead-entry fallback, hover/cancel/restore)
   were chosen by each plan's own planner from CONTEXT.md/RESEARCH.md,
   not derived from a verified edge inventory. This remains explicitly
   open — carried forward, not resolved by this plan's execution.

2. **AMB-02's spec-less edge-coverage row** (owner 17-04, same protocol,
   same disposition) — **still open.** Same reasoning: no SPEC.md, no
   derived edge inventory, `category: unclassified`, `status:
   unresolved`, never auto-resolved. 17-04's own edge coverage (D-34's
   two fault-injection triggers, the degraded-cursor gate) was likewise
   planner-chosen, not inventory-derived.

3. **D-28's `gaming-mode-toggle.sh` dependency** (owner 17-03, `category:
   dependency`, recorded at plan time as `partially-resolved`) —
   **resolved.** Evidence, quoted from `17-03-SUMMARY.md`: "gaming-mode-
   toggle.sh confirmed LIVE, not silently dead. Lines 113-116/164-188
   already use `hyprctl eval` + `hl.config({...})`, migrated by 13.1-10.
   Only the file's OWN header comment still claimed the pre-13.1
   `hyprctl keyword` form — corrected in this plan's Task 2, live-
   verified both ON and OFF cycles including the stranded-idle case
   (gaming ON while idle-hidden, gaming OFF must still return the
   wallpaper)." This is a derived, evidence-backed resolution, not the
   passage of time.

No fourth assumption row is authored by this plan.

---

## Acceptance criteria that could not be executed as live end-to-end proofs

Named explicitly, per this plan's own instruction, rather than omitted:

- **Task 3's `<human-check>`** ("read `17-SWEEP-REPORT.md` end to end
  and confirm it is a document you would trust six months from now") is
  the plan's own checkpoint task, immediately following this report —
  not something this executing task can self-certify. Left for the
  phase-close checkpoint.
- This sweep re-derives the accepted-gap arithmetic live (5
  sites/8 declaration lines) rather than trusting 17-05's own closing
  count ("seven declarations across five files") — the discrepancy is
  stated above rather than silently reconciled in either direction,
  since re-deriving it live is exactly what this plan is for.

No other acceptance criterion in this plan's three tasks was skipped;
every automated `<verify>` command was run against the live repo and
its output is captured in this report and in the two task commits'
messages.
