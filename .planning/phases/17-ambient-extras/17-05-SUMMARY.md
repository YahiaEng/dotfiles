---
phase: 17-ambient-extras
plan: 05
subsystem: infra
tags: [hyprland-lua, hyprpm, dynamic-cursors, permissions, cursor-theme, hyprcursor, xcursor, rose-pine]

# Dependency graph
requires:
  - phase: 17-ambient-extras (plan 04)
    provides: "rose-pine-hyprcursor installed+declared; guarded install.sh hyprpm block; hyprpm-complete.sh post-login completion helper; permissions.lua plugin-type grant for /usr/bin/hyprpm; live-found Hyprland permission-dialog hang finding"
provides:
  - "hypr/.config/hypr/config/dynamic-cursors.lua — config surface (NOT a load surface) for the dynamic-cursors plugin: hl.plugin.dynamic_cursors guard + hl.config block setting mode=tilt/shake.enabled=false, proven live to apply once hyprpm loads the plugin"
  - "hyprpm-complete.sh: a follow-up hyprctl reload after a successful hyprpm-driven plugin load, so dynamic-cursors.lua's config block gets a config pass where the plugin is already loaded"
  - "D-32 cursor-theme pin delivered as option-c (unify on rose-pine in both formats) across all five verified sites, plus install.sh's rose-pine-cursor package addition and bibata-cursor-theme removal"
  - "A conclusively negative, evidence-backed finding that hl.plugin.load() cannot be safely used from Lua config on this Hyprland build: unmatched permission request -> user-facing dialog every login/lock; matched request -> fatal compositor SIGSEGV via infinite reload()/handlePluginLoads()/postConfigReload() recursion"
affects: [17-06]

# Actuals (#2632)
actuals:
  tokens: 7799
  tasks: 4
  commits: 7

tech-stack:
  added: [rose-pine-cursor (AUR)]
  patterns:
    - "Permission-grant experiments belong in a nested hypr-lua-harness instance first, never a live restart, and even then a nested PASS is not proof — DynamicPermissionManager's confirm/pending/allow states can behave differently once a grant genuinely resolves, as opposed to staying silently pending forever"
    - "A Hyprland Lua config module's failure to perform an action (hl.plugin.load returning without error but doing nothing) can mean 'gated behind a still-pending permission request', not 'inert/unsupported API' — verify against the installed binary's own headers (/usr/include/hyprland/src/...) before concluding an API doesn't work"
    - "coredumpctl + a demangled backtrace is the only reliable oracle for 'did this Lua-triggered compositor action actually crash something', when the crash leaves zero trace in Hyprland's own log or in journalctl"

key-files:
  created:
    - hypr/.config/hypr/config/dynamic-cursors.lua
  modified:
    - hypr/.config/hypr/hyprland.lua
    - hypr/.config/hypr/config/permissions.lua
    - hypr/.config/hypr/scripts/hyprpm-complete.sh
    - hypr/.config/hypr/config/env.lua
    - uwsm/.config/uwsm/env
    - theme-engine/.config/theme-engine/lib/generate.sh
    - thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
    - install.sh

key-decisions:
  - "D-35's stated objective ('load the plugin declaratively from the repo') is NOT met on this Hyprland build (0.56.2, commit efb50993, 2026-08-05) — not 'unconfirmed', conclusively unachievable. Every reachable state was tested and is either user-hostile (permission dialog at every login and every idle-lock) or fatal (SIGSEGV via infinite Config::Lua::CConfigManager recursion). hl.plugin.load() was removed from dynamic-cursors.lua entirely, on evidence, with the full reasoning left in the file's own header so nobody re-adds it."
  - "D-32 resolved to the checkpoint's option-c (unify on rose-pine in both formats), reversing the operator's own earlier stated preference for consistency over option-a's split — 'having two different mouse themes is jarring and breaks a consistent theming flow.' rose-pine-cursor (AUR) provides the real XCursor-format sibling; its installed directory name (BreezeX-RosePine-Linux) is NOT the package name and had to be read from the PKGBUILD and confirmed on disk before use."
  - "bibata-cursor-theme removed from install.sh — a repo-wide sweep confirmed nothing references Bibata-Modern-Classic any more after the option-c pin landed; leaving it installed would have been an unexamined dead dependency, the exact failure class this decision exists to avoid repeating."
  - "The Dawn (light) variant of rose-pine-cursor is deliberately NOT wired to theme mode — cursor is already a mode-orthogonal axis in this pipeline (generate.sh's pre-existing D-07 note), and mode-aware cursor switching is a new capability outside this plan's scope. Recorded as a deliberate non-decision."
  - "hyprpm-complete.sh gained a follow-up, bounded hyprctl reload after a successful hyprpm-driven plugin load [Rule 2, live-found] — without it, dynamic-cursors.lua's guarded config block would never see the plugin as loaded on a normal login, since Hyprland's own single synchronous config pass at startup runs before hyprpm-complete.sh's async load completes."
  - "Two permission-grant candidates for a config-issued hl.plugin.load() call (a caller-identity grant matching the literal string 'config', and a plugin-path-scoped grant) were both tried and both reverted, permanently, after live+nested evidence showed either resolving to ALLOW crashes the compositor. Neither is safe to re-enable; both are left commented out in permissions.lua with an explicit DO-NOT-ENABLE warning and the full backtrace."
  - "[Self-correction, recorded honestly] I claimed reverting the two permission grants (commit f4d2ff6) fixed the login/idle-lock dialog problem. It did not — it restored the exact starting condition (no matching grant -> ASK -> dialog). The coordinator caught this. The actual fix (commit 537af08) is removing the hl.plugin.load() call itself, the only one of three fully-determined states that produces neither a dialog nor a crash."

requirements-completed: []
# AMB-02 intentionally NOT marked — 17-06 owns requirement marking at phase close (an earlier plan
# in this phase did this prematurely once; reverted in 996440b). D-36/D-37/D-32 (this plan's
# in-scope pieces of AMB-02) are delivered and evidenced below; D-35's declarative-load piece is
# conclusively NOT delivered, on evidence, and that is exactly the kind of fact 17-06's cut sweep
# needs to see plainly rather than have implied as done.

coverage:
  - id: D1
    description: "dynamic-cursors.lua config surface (hl.plugin.dynamic_cursors guard + hl.config block: enabled, mode=tilt with rotate/stretch switchable, shake.enabled=false) wired into hyprland.lua as the 8th required module; proven live to apply once the plugin is loaded via hyprpm"
    requirement: AMB-02
    verification:
      - kind: manual_procedural
        ref: "Live getoption readback after a real user restart: plugin:dynamic-cursors:mode -> str: tilt, set: true; plugin:dynamic-cursors:shake:enabled -> bool: false, set: true; plugin handle changed across the restart (555ff2de34d0 -> new), confirming a genuine post-restart load with config applied at load time"
        status: pass
    human_judgment: true
    rationale: "Plugin mode/shake-off is a visual/behavioral property (D-37: mode is fixed at plugin load, provably not runtime-switchable) — only a human judging the real render after a real restart can confirm the shipped tilt mode actually reads correctly and shake-to-find is genuinely off, not merely that getoption reports the right stored value."
  - id: D2
    description: "D-32 cursor-theme pin delivered as option-c across all five sites (generate.sh x2, env.lua, uwsm/env, thunar xsettings.xml x2) plus HYPRCURSOR_THEME/HYPRCURSOR_SIZE additions; install.sh gained rose-pine-cursor (audited) and dropped bibata-cursor-theme (swept clean first)"
    requirement: AMB-02
    verification:
      - kind: manual_procedural
        ref: "Live render gate: user confirmed 'rosepine across wayland and xwayland' on native and XWayland clients, no stock-pointer fallback on either"
        status: pass
      - kind: other
        ref: "generate.sh render function invoked against a throwaway temp dir: both gtk-3.0-settings.ini and gtk-4.0-settings.ini carry exactly one gtk-cursor-theme-name=BreezeX-RosePine-Linux line"
        status: pass
    human_judgment: true
    rationale: "A silent stock-pointer fallback (the exact adw-gtk3 failure class this decision exists to avoid) is only detectable by a human looking at the actual rendered cursor on both client types — a passing grep or getoption cannot distinguish 'theme name is correct' from 'theme name resolves to something visible'."
  - id: D3
    description: "hl.plugin.load() conclusively determined unsafe to use from Lua config on this Hyprland build and removed; two permission-grant candidates tested, both found fatal (SIGSEGV via infinite CConfigManager recursion) or user-hostile (permission dialog every login/lock), both reverted with DO-NOT-ENABLE documentation"
    requirement: AMB-02
    verification:
      - kind: other
        ref: "coredumpctl info <pid> on two separate SIGSEGV Hyprland crashes, demangled backtrace showing Config::Lua::CConfigManager::reload() -> handlePluginLoads() -> postConfigReload() -> reload() unbounded recursion"
        status: pass
      - kind: manual_procedural
        ref: "User-reported dialog text verbatim: 'An application config is trying to load a plugin /var/cache/hyprpm/aorus/dynamic-cursors/dynamic-cursors.so'; confirmed at every login and every hypridle-triggered hyprlock with the grants absent"
        status: pass
    human_judgment: false

duration: ~5h30m (multiple checkpoint round-trips, extensive live/nested investigation, one self-corrected mistake)
completed: 2026-08-09
status: complete
---

# Phase 17 Plan 05: Dynamic-Cursors Config Surface + D-32 Cursor-Theme Pin Summary

**Shipped the plugin's config surface (mode + shake-to-find-off, live-verified) and delivered D-32's cursor-theme unification across all five sites — but conclusively found and removed the plugin's own declarative-load call after it was shown to either prompt a permission dialog on every login/lock or crash the compositor via infinite recursion, depending on permission state.**

## Performance

- **Duration:** ~5h30m (08:31–13:59 EEST), across three blocking checkpoints and one tracer feedback gate, including a session where I had to correct my own wrong claim mid-plan
- **Started:** 2026-08-09T05:31:11Z
- **Completed:** 2026-08-09T10:58:50Z
- **Tasks:** 4 (Task 1 tracer, Task 2 checkpoint:decision + its auto application, Task 3 checkpoint:human-verify)
- **Files modified:** 9 (1 created, 8 modified)

## Accomplishments

- `hypr/.config/hypr/config/dynamic-cursors.lua` created and wired as `hyprland.lua`'s 8th required module — a config surface (not a load surface, see Deviations) that sets `mode=tilt` (D-37, all three values trivially switchable, chosen by the operator at a real render gate after a real restart) and `shake.enabled=false` (D-36), gated by upstream's mandatory `hl.plugin.dynamic_cursors` guard. Live-verified via `getoption` readback across a genuine post-restart plugin load (handle changed `555ff2de34d0` → new handle, `set: true` for both `mode` and `shake:enabled`).
- D-32's cursor-theme pin delivered per the operator's checkpoint decision — **option-c**, unify on rose-pine in both formats — across all five verified sites, including the two (`uwsm/env`, Thunar `xsettings.xml`) no source artifact ever named. `rose-pine-cursor` (AUR) added to `install.sh` after a full live package-legitimacy audit (upstream repo, sha256 re-derivation, PKGBUILD read line-by-line); `bibata-cursor-theme` removed after a repo-wide sweep confirmed it had become a dead dependency. Live-verified by the operator: "rosepine across wayland and xwayland" — no stock-pointer fallback on either client type.
- **The plan's single most consequential finding: `hl.plugin.load()` cannot be safely used from Lua config on this installed Hyprland build (0.56.2, commit `efb50993`, 2026-08-05).** Every reachable permission state was tested, live and in the nested `hypr-lua-harness`, and is either user-hostile (a real Allow/Deny dialog at every login and every idle-lock, confirmed by the user's own verbatim report) or fatal (two reproduced Hyprland SIGSEGV crashes, `coredumpctl` backtraces demangling to unmistakable infinite recursion in `Config::Lua::CConfigManager::reload() -> handlePluginLoads() -> postConfigReload() -> reload()`). The call was removed from `dynamic-cursors.lua` entirely, on this evidence, with the full reasoning left in the file's own header.
- `hyprpm-complete.sh` [Rule 2, live-found] gained a follow-up, bounded `hyprctl reload` after a successful hyprpm-driven plugin load — without it, `dynamic-cursors.lua`'s config block would never see the plugin as loaded on a normal login, since Hyprland's own single synchronous config pass at startup runs before `hyprpm-complete.sh`'s async load completes.

## Task Commits

Each task was committed atomically (this plan needed more commits than tasks — see Deviations for why):

1. **Task 1 (tracer): guarded dynamic-cursors Lua module + `hyprland.lua` wiring + `hyprpm-complete.sh` reload fix** — `e65c953` (feat)
2. **Task 1a (superseded): experimental `/usr/bin/Hyprland` plugin grant** — `b6a72d0` (feat) — reverted in `8b1e814`
3. **Task 2 (checkpoint:decision, resolved option-c) + application: D-32 cursor-theme pin across all five sites + `install.sh`** — `6cdb5cf` (feat)
4. **Task 3, round 1 fix (wrong): revert the `/usr/bin/Hyprland` grant** — `8b1e814` (fix) — corrected the wrong grant target, did not fix the dialog
5. **Task 3, round 2 fix (superseded): plugin-type grant for the `config` caller identity** — `019317a` (feat) — reverted in `f4d2ff6`
6. **Task 3, round 3 fix: revert both grant candidates on crash evidence** — `f4d2ff6` (fix) — safety-critical, but see Deviations: this commit's own claim that it fixed the dialog was wrong
7. **Task 3, round 4 fix (final, correct): remove `hl.plugin.load()` from `dynamic-cursors.lua`** — `537af08` (fix)

No separate plan-metadata commit was needed beyond this SUMMARY's own final commit (see Final Commit below).

## Files Created/Modified

- `hypr/.config/hypr/config/dynamic-cursors.lua` (new) — config surface only; no `hl.plugin.load()` call (see Deviations)
- `hypr/.config/hypr/hyprland.lua` — one `require("config.dynamic-cursors")` line, header amended off its stale "final at seven" claim
- `hypr/.config/hypr/config/permissions.lua` — three plugin-permission grant *attempts* for a config-issued load, all three now commented out with DO-NOT-ENABLE warnings and the full evidence trail; the pre-existing `/usr/bin/hyprpm` grant (17-04) is untouched and still the only active plugin-type grant
- `hypr/.config/hypr/scripts/hyprpm-complete.sh` — follow-up `hyprctl reload` after a successful plugin load (Rule 2 fix)
- `hypr/.config/hypr/config/env.lua` — `XCURSOR_THEME` moved to `BreezeX-RosePine-Linux`; new `HYPRCURSOR_THEME`/`HYPRCURSOR_SIZE` declarations
- `uwsm/.config/uwsm/env` — same two changes, mirroring `env.lua`
- `theme-engine/.config/theme-engine/lib/generate.sh` — both `gtk-cursor-theme-name=` render lines moved to `BreezeX-RosePine-Linux`
- `thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` — both `CursorThemeName` properties moved to `BreezeX-RosePine-Linux`
- `install.sh` — `rose-pine-cursor` added to `AUR_PKGS` (audited inline), `bibata-cursor-theme` removed (swept clean first)

## Decisions Made

See `key-decisions` in frontmatter for the full list with rationale. Summary:
- D-35's declarative-load objective is conclusively unmet on this Hyprland build — not a gap, a determined fact with evidence.
- D-32 resolved option-c at the operator's explicit direction (consistency over option-a's format split).
- `bibata-cursor-theme` removed as dead weight after a real sweep, not left unexamined.
- The Dawn (light) cursor variant is deliberately unwired from theme mode — a stated non-decision, not an oversight.
- `hyprpm-complete.sh`'s follow-up reload is required for D-36/D-37 to actually apply on a real login — found live, not anticipated by any planning document.
- Both permission-grant candidates for a config-issued plugin load are permanently reverted, on crash evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `hyprpm-complete.sh` needed a follow-up `hyprctl reload`**
- **Found during:** Task 1, live-testing on the nested harness and reasoning through the real login sequence
- **Issue:** Without it, `dynamic-cursors.lua`'s guarded config block would never see the plugin as loaded on a normal login — Hyprland's own single synchronous config pass at startup runs before `hyprpm-complete.sh`'s async load (from autostart) completes, so D-36/D-37 would silently never take effect.
- **Fix:** Added a bounded, `|| true`-guarded `hyprctl reload` immediately after a successful hyprpm-driven load, gated so it never fires on the already-loaded hot path.
- **Files modified:** `hypr/.config/hypr/scripts/hyprpm-complete.sh`
- **Verification:** Live `getoption` readback after a real restart confirmed the config block applied correctly.
- **Committed in:** `e65c953`

**2. [Rule 4-class architectural finding, not auto-fixable, resolved by removal] `hl.plugin.load()` is unsafe on this Hyprland build**
- **Found during:** Task 1's own tracer verification (nested harness), then escalated across Task 3's render gate when the user reported a real permission dialog at every login and idle-lock
- **Issue:** The plan's D-35 objective required a working `hl.plugin.load()` call from Lua config. Every call shape (bare string, table form, path+bool, plugin name) was tried, and the call was found to do nothing detectable — later corrected: it was not inert, it was gated behind a permission request stuck in `PENDING` (Hyprland's `DynamicPermissionManager`, confirmed against the installed dev headers). Two grant candidates were tried to resolve that: a caller-identity grant (`^config$`) and a plugin-path-scoped grant. Testing the second in the nested harness produced two reproduced SIGSEGV crashes — the backtrace demangles to unbounded recursion between `CConfigManager::reload()`, `handlePluginLoads()`, and `postConfigReload()`.
- **Fix:** Removed the `hl.plugin.load()` call and its now-purposeless `hl.get_loaded_plugins()` idempotency guard from `dynamic-cursors.lua` entirely. Replaced with a comment recording the full reasoning and the exact recursion chain, specifically to stop a future re-add. The `hl.plugin.dynamic_cursors` guard and `hl.config` block (the parts that actually deliver D-36/D-37) are untouched.
- **Files modified:** `hypr/.config/hypr/config/dynamic-cursors.lua`, `hypr/.config/hypr/config/permissions.lua`
- **Verification:** Nested harness re-run after the fix: `configerrors` clean, no crash, `hl.config` block mechanics unaffected (unchanged code, already separately proven live). Live session confirmed untouched and healthy throughout every test (`hyprctl monitors`/`plugin list`/`instances` checked before and after every nested-harness invocation).
- **Committed in:** `f4d2ff6` (grant revert), `537af08` (load-call removal, the actual fix)

**Self-correction, recorded honestly rather than omitted:** after commit `f4d2ff6` (reverting both grants), I told the coordinator this resolved the login/idle-lock dialog problem. **It did not.** Reverting the grants restored the exact starting condition — no matching grant means the permission request resolves to `ASK`, which *is* the dialog. I had re-derived the problem and labelled it fixed. The coordinator caught this by re-reading the committed tree. The actual fix required removing the `hl.plugin.load()` call itself (`537af08`), the only one of three fully-determined states (no grant → dialog; matching grant → crash; no request → neither) that is safe.

---

**Total deviations:** 2 auto-fixed/resolved (1 missing-critical, 1 architectural finding resolved by removal), plus one self-corrected wrong claim recorded above.
**Impact on plan:** The Rule 2 fix is necessary for D-36/D-37 to function at all. The D-35 finding is the load-bearing result of this plan — it changes what "done" means for AMB-02's runtime half, and 17-06 must read it as such.

## Issues Encountered

- **No log or journal trace of the permission dialog anywhere on this build.** Neither Hyprland's own log file nor the full user `journalctl -b 0` recorded the event — the caller identity (`config`) and plugin path had to come from the user reading the dialog verbatim, not from any automated evidence source. Recorded as a durable finding: this class of event is not diagnosable from logs alone on Hyprland 0.56.2.
- **An `Edit` tool call silently dropped the `^config$` grant** when the path-scoped grant was added alongside it (both were meant to coexist per the coordinator's instruction; the `old_string`/`new_string` replacement didn't preserve the original active line). This was only caught because the resulting (accidentally solo) path-scoped grant crashed the compositor and forced a closer look. It is also, by accident, the evidence that a config permission rule's regex is matched against the plugin path string, not the caller label — since only the path-scoped grant was active when the crash was captured.
- **`hyprctl dispatch exit` crashes nested Hyprland instances on shutdown** (`wl_display_destroy`, different backtrace from the recursion crash, SIGSEGV) — observed twice, confined to the disposable nested harness instance, does not touch the live session. Not investigated further; noted for whoever next touches `hypr-lua-harness`.
- **Repeated nested-harness crashes during this investigation cost real machine resources** (multiple coredumps, `/var/lib/systemd/coredump/`) — not cleaned up by this plan; a future housekeeping pass may want to prune old Hyprland coredumps from this session (`coredumpctl list` shows several from PIDs 66369, 93341, 111639 dated 2026-08-09 13:46–13:54).

## User Setup Required

None — no external service configuration required. One user-performed restart already happened during this plan's render gate (confirming D-36/D-37/D-32 render correctly); the coordinator is arranging one further restart, independent of this plan's completion, purely to confirm the `hl.plugin.load()` removal actually stops the login/idle-lock dialog. That confirmation is **not required to close this plan** — the removal is correct on the evidence already gathered (the three states are exhaustively determined, not merely likely), and the plan's own code changes are complete and committed.

## Self-Check

**Files:**
```bash
FOUND: hypr/.config/hypr/config/dynamic-cursors.lua
FOUND: hypr/.config/hypr/hyprland.lua
FOUND: hypr/.config/hypr/config/permissions.lua
FOUND: hypr/.config/hypr/scripts/hyprpm-complete.sh
FOUND: hypr/.config/hypr/config/env.lua
FOUND: uwsm/.config/uwsm/env
FOUND: theme-engine/.config/theme-engine/lib/generate.sh
FOUND: thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
FOUND: install.sh
```

**Commits:**
```bash
FOUND: e65c953 (feat(17-05): guarded dynamic-cursors Lua load + config surface (D-35/D-36/D-37))
FOUND: b6a72d0 (feat(17-05): experimental /usr/bin/Hyprland plugin-permission grant (untested, pending restart))
FOUND: 6cdb5cf (feat(17-05): D-32 cursor-theme pin — option-c, unified across all five sites)
FOUND: 8b1e814 (fix(17-05): revert experimental /usr/bin/Hyprland plugin grant — likely cause of login/idle-lock permission dialogs)
FOUND: 019317a (feat(17-05): plugin-type grant for the "config" caller identity (D-35, corrected diagnosis))
FOUND: f4d2ff6 (fix(17-05): revert both plugin-permission grant candidates — CRASH, not a dialog problem (D-35 final))
FOUND: 537af08 (fix(17-05): remove hl.plugin.load() from dynamic-cursors.lua — the only viable state (D-35 closed as unmet))
```

**Claims spot-checked against live state at close:**
- `luac -p` exits 0 on `dynamic-cursors.lua`, `hyprland.lua`, `env.lua`, `permissions.lua`.
- `bash -n` exits 0 on `uwsm/.config/uwsm/env`, `generate.sh`, `install.sh`, `hyprpm-complete.sh`.
- `grep -v '^--' dynamic-cursors.lua | grep -c 'hl.plugin.load'` returns 0 — the call is genuinely gone from live code, present only in the explanatory comment block.
- `sed -n '/^AUR_PKGS=(/,/^)/p' install.sh` contains exactly one `rose-pine-cursor` and zero `bibata-cursor-theme`.
- `test -d /usr/share/icons/BreezeX-RosePine-Linux/cursors` and `test -f /usr/share/icons/rose-pine-hyprcursor/manifest.hl` both succeed (verified during Task 2).
- `hyprctl monitors -j | jq -e 'length > 0'` and `hyprctl plugin list` (still reporting the live-loaded plugin) both succeed at the time this SUMMARY was authored — the live session survived every nested-harness test in this plan.
- `git status --short` clean at the point this SUMMARY was authored.

## Self-Check: PASSED

No missing files, no missing commits. One claim (that reverting the permission grants alone fixed the dialog) was made incorrectly mid-plan and is documented, corrected, and superseded above rather than silently smoothed over.

## Next Phase Readiness

- **AMB-02 is intentionally left unmarked in REQUIREMENTS.md** — 17-06 owns requirement marking at phase close. This plan delivers D-36 (shake off), D-37 (mode switchable, tilt shipped) and D-32 (cursor-theme consistency, option-c) with live evidence; it does **not** deliver D-35's declarative-load mechanism, and 17-06 must read that as a determined fact, not an open item.
- **17-06's cut sweep should treat `dynamic-cursors.lua` as config-only**, not load-bearing for the plugin actually being loaded — the real, working load path is unchanged from 17-04: `hyprpm` via `hyprpm-complete.sh`.
- **`permissions.lua` carries three commented-out, explicitly DO-NOT-ENABLE plugin-permission grant attempts** (`/usr/bin/Hyprland`, `^config$`, a path-scoped regex) with the full crash evidence inline. 17-06's sweep (and any future contributor) should leave these commented — they are documentation of a dead end, not dormant capability.
- **A pending, low-priority housekeeping item**: several Hyprland coredumps from this plan's investigation remain in `/var/lib/systemd/coredump/` — not cleaned up, not blocking, worth a `coredumpctl clean` pass at some point.
- **The D-38 breadcrumb for 17-06's cut-sweep scope**: the full cursor-theme site list is `theme-engine/lib/generate.sh:175,180` (render lines, was `166,171`), `hypr/config/env.lua` (`XCURSOR_THEME` + new `HYPRCURSOR_THEME`), `uwsm/env` (same two, mirrored), `thunar/xsettings.xml` (`CursorThemeName` ×2). All five (now seven declarations across five files) are cursor-theme pins in the class D-38 already accepted as out of the criterion-3 cut sweep's scope — this plan added two new declarations (`HYPRCURSOR_THEME`/`HYPRCURSOR_SIZE` in two files) to that same class, not a new exception.
- **The permission-dialog fix (`537af08`) has one user restart still pending**, arranged by the coordinator independently of this plan's completion, to give final human confirmation the dialog is gone. The fix does not depend on that confirmation to be correct — the three reachable states were exhaustively determined by evidence (a real user-reported dialog for the "no grant" state, two reproduced SIGSEGV crashes for the "matching grant" state, and straightforward code inspection for the "no request issued" state) — but 17-06 or a future session should note if that confirmation ever surfaces a fourth state this plan didn't anticipate.

---
*Phase: 17-ambient-extras*
*Completed: 2026-08-09*
