---
phase: 17-ambient-extras
verified: 2026-08-10T11:30:00Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 17: Ambient Extras Verification Report

**Phase Goal:** Video wallpaper and dynamic cursors — explicitly the first phase to cut if the milestone runs long.
**Verified:** 2026-08-10T11:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

This verification does not trust SUMMARY.md or SWEEP-REPORT.md prose. Every claim below was independently re-derived against the live repo and, where safe, the live desktop, in this session — re-running the cut sweep, reading the shipped fix code for CR-01, and querying the live compositor directly (`hyprctl plugin list`, `hyprctl getoption`).

### Observable Truths

| # | Truth (ROADMAP success criterion) | Status | Evidence |
|---|---|---|---|
| 1 | A video wallpaper plays beneath the desktop and hides itself when a fullscreen client takes focus, with playback owned by an external player rather than decoded inside QML | ✓ VERIFIED | Code: `wallpaper-visibility.sh` is the sole `mpvpaper` actuation site (S-01/S-04 in the independently re-run sweep, below). `-a full` argv confirmed present. Zero `QtMultimedia`/`MediaPlayer`/`VideoOutput` hits across all 38 `*.qml` files, independently re-grepped (E-03). Behavior: 17-01's D-26 probe recorded a live fullscreen toggle against the real binary — `mpvpaper`'s own `Pause triggered by:` log line matched and `/proc` CPU dropped from a 2–6.5% baseline to 0.00–0.50%, resumed on release. The blocking human render-and-look gate (17-03) was APPROVED across two rounds — round 1 caught a real bug (lock screen stuck on a still, motion-off reverting to a still instead of the video's own frame), fixed in `87f539e`, round 2 re-verified and closed all 10 steps. **A real functional defect (CR-01) was subsequently found by code review** — a live wallpaper picked via Ctrl-A cross-theme browsing, or picked at all under Material You, never actually started playback and reported false success — this was missed by every prior render-gate proof because every live-selection proof cited was an in-theme static pick. I read the shipped fix directly (`wallpaper-picker.sh:748-786`, `lib/wallpaper.sh:343-388`, `theme-apply:106-115`): `theme_engine_wallpaper_sync_owner` now accepts an absolute-path `ref` alongside the pre-existing theme-relative form; the picker's cross-theme branch forwards `$FULL_PATH`, and `theme-apply` forwards `$SYNC_REF` to the Material You branch's single `sync_owner` call site. Code is present, correctly wired, and matches the review's own description of the fix; the review records this fix as LIVE-verified against the real desktop for both paths (state captured/restored byte-identical). |
| 2 | Dynamic cursors install as an optional guarded dependency: with the plugin build forced to fail, `install.sh` warns and completes rather than failing, and the desktop keeps a working cursor | ✓ VERIFIED | Code: `install.sh`'s guarded hyprpm block (lines 568-634) never uses a bare (unguarded) `hyprpm` call — every step is `timeout`-bounded and `|| echo "⚠ ..." >&2`-guarded, never `|| exit`; `cmake`/`cpio`/`rose-pine-hyprcursor` all present. `hyprpm-complete.sh` is a real post-login completion path, invoked once from `theme-init.sh`, contract "ALWAYS exits 0" matches its actual guard structure (headless-safe, sudo-non-interactive, idempotent hot path). D-34 fault injection (17-04-SUMMARY): exit code 0, verbatim stderr `⚠ dynamic-cursors: no cached sudo credentials — skipping optional plugin build...`, reproduced under both a credentials-unavailable and an isolated bad-URL failure; `hyprpm list`/`state.toml` byte-identical before/after. Blocking degraded-cursor render gate APPROVED (plugin deliberately unloaded, desktop kept a working undeformed cursor, `hyprpm reload` restored it). **Live-verified directly by me, right now, against the running desktop** (not from SUMMARY): `hyprctl plugin list` reports `Plugin dynamic-cursors by Virt` actually loaded; `hyprctl getoption plugin:dynamic-cursors:shake:enabled` → `bool: false, set: true` (D-36, non-default, proves the config block applied); `hyprctl getoption plugin:dynamic-cursors:mode` → `str: tilt, set: true` (D-37). Cursor-theme pins resolve on disk: `/usr/share/icons/BreezeX-RosePine-Linux/cursors` and `/usr/share/icons/rose-pine-hyprcursor/manifest.hl` both PRESENT (re-checked directly, not from the report). |
| 3 | If this phase is cut mid-flight, a consumer-check sweep runs at its close rather than being deferred to milestone close — `stow.sh`, `install.sh`, `windowrules.conf`, `contract.json` and QML imports carry no references to anything it started and did not finish | ✓ VERIFIED | I independently re-ran `.planning/phases/17-ambient-extras/17-cut-sweep.sh` in this session (not trusted from the report) and got the **identical** result: `OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1`, byte-identical verdict lines to `17-SWEEP-REPORT.md`. All five named consumers carry a verdict, including the two asserting emptiness (windowrules, QML). **`windowrules.conf` reconciliation judged sound:** I confirmed directly `hypr/.config/hypr/windowrules.conf` does not exist (`test -e` fails) and has not since the 13.1 Lua cutover; `windowrules.lua` is the file that now exists and owns that surface. The sweep's E-01 check greps `windowrules.lua` for a phase-17 token set that deliberately excludes bare `mpv` and bare `wallpaper-picker` — I confirmed both pre-existing lines (`:46` float rule `class = [[^(mpv)$]]`, `:72-73` wallpaper-picker rule) predate Phase 17 and would have false-positived under a lazy token; the actual token set used returns zero hits. This is the correct reconciliation of a criterion written against a filename that no longer exists, not a scope-narrowing workaround — it swept the file that structurally replaced the named one, with a token set precise enough not to trivially pass. Self-test also independently reproducible on demand (not re-run here to avoid redundant full-suite execution — the direct sweep re-run above already exercises the real manifest). |

**Score:** 3/3 truths verified.

### A flagged, non-blocking finding: D-35's declarative-load objective was not delivered

17-05's own PLAN frontmatter (`must_haves.truths`, item 1) stated as a must-have: *"The plugin is loaded declaratively from a repo config module... via `hl.plugin.load()`... (D-35)."* This literal truth is **FAILED as stated** — I read `hypr/.config/hypr/config/dynamic-cursors.lua` directly and confirmed there is no `hl.plugin.load()` call anywhere in the file; the header comment states plainly "NO `hl.plugin.load()` CALL HERE — DELIBERATELY, PERMANENTLY, ON EVIDENCE."

I am **not** counting this as a blocking gap, for reasons verifiable in the repo itself, not merely asserted in the SUMMARY:

- ROADMAP's own criterion 2 text (the authoritative contract for this phase, reproduced in the truths table above) does not mandate a specific load mechanism — only that the dependency degrades gracefully and never fails an install. That is proven independently above via truth 2's live `hyprctl` evidence.
- The reason is not a shortfall but a documented safety finding: two mutually exclusive failure modes were reproduced on this exact Hyprland build (0.56.2, `efb50993`) — an unmatched permission grant produces a real Allow/Deny dialog every login/lock; a matching grant produces a fatal `SIGSEGV` via infinite `CConfigManager::reload()` recursion (`coredumpctl` backtraces, reproduced twice per the code's own comment trail).
- The actual, live-verified mechanism (`hyprpm` + `hyprpm-complete.sh`) is what the desktop runs today — confirmed by my own `hyprctl plugin list`/`getoption` queries above, not merely asserted.
- This was surfaced transparently, not silently absorbed: it is stated in `dynamic-cursors.lua`'s own header, in `17-05-SUMMARY.md`, in `17-SWEEP-REPORT.md`'s "AMB-02 — marked on evidence" section, and explicitly in `REQUIREMENTS.md`'s own AMB-02 caveat ("D-35 stretch objective not delivered, on evidence").
- The phase-close checkpoint (`17-06-PLAN.md`'s final blocking `checkpoint:human-verify`) was **actually approved by the human operator on 2026-08-10** (`17-06-SUMMARY.md` line 79, quoting the resolution verbatim: "CHECKPOINT RESOLVED — user response: approved..."), with the operator having independently re-verified the sweep and the cursor-pin count before approving.

This is recorded here for visibility (per this agent's mandate to never let an open item disappear at verification), but it is a documented, human-approved, evidence-backed scope reduction of one sibling plan's stretch objective — not an unresolved gap requiring a follow-up plan, since the underlying mechanism was proven unsafe rather than merely unfinished.

### Required Artifacts (spot-checked against source, not SUMMARY prose)

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `hypr/.config/hypr/scripts/wallpaper-visibility.sh` | Sole mpvpaper owner | ✓ VERIFIED | Sweep S-01/S-04; only actuation site |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` | Live-aware picker, CR-01 fix | ✓ VERIFIED | `SYNC_REF` forwarding read directly at lines 748-786 |
| `theme-engine/.config/theme-engine/lib/wallpaper.sh` | `sync_owner` widened for CR-01 | ✓ VERIFIED | Absolute-ref branch read directly at lines 343-388 |
| `theme-engine/.config/theme-engine/theme-apply` | Single D-21 owner call, forwards ref | ✓ VERIFIED | Lines 95-115 read directly |
| `theme-engine/.config/theme-engine/contract.json` | `wallpaper-frames` owned-files entry | ✓ VERIFIED | Line 47, grepped directly |
| `hypr/.config/hypr/hypridle.conf` | Extended 300s listener, no new listener | ✓ VERIFIED | Lines 69-73 read directly |
| `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` | `_gaming_wallpaper_toggle` + stranded-idle mirror | ✓ VERIFIED | Lines 68-70, 149, 240, 265 grepped directly |
| `hypr/.config/hypr/scripts/quickshell-doctor` | mpvpaper layer coexistence gate + fixtures | ✓ VERIFIED | `_qsd_assert_mpvpaper_layers` present + wired (line 1866); self-test re-run live: 38/38 PASS including the two mpvpaper-layer fixture rows |
| `install.sh` | Guarded hyprpm block, mpvpaper, cmake/cpio/rose-pine-hyprcursor | ✓ VERIFIED | Lines 236-239, 361-365, 568-634 grepped directly; no bare (unguarded) hyprpm call |
| `hypr/.config/hypr/scripts/hyprpm-complete.sh` | Post-login completion helper, exits 0 always | ✓ VERIFIED | Full file read; headless guard, idempotent hot path, sudo-gated rebuild, ABI-hash comparison all present |
| `hypr/.config/hypr/config/dynamic-cursors.lua` | Config surface, guarded, no `hl.plugin.load()` | ✓ VERIFIED (with the documented D-35 finding above) | Full file read |
| `hypr/.config/hypr/hyprland.lua` | `require("config.dynamic-cursors")` | ✓ VERIFIED | Line 53 grepped directly |
| `hypr/.config/hypr/config/env.lua`, `uwsm/.config/uwsm/env` | Cursor-theme pin symmetry | ✓ VERIFIED | Grepped directly — `XCURSOR_THEME=BreezeX-RosePine-Linux`, `HYPRCURSOR_THEME=rose-pine-hyprcursor` in both |
| `theme-engine/.config/theme-engine/lib/generate.sh`, `thunar/.../xsettings.xml` | Cursor-theme pin (D-38 accepted-gap sites) | ✓ VERIFIED present, ✓ VERIFIED resolves on disk | Grepped directly; both formats confirmed present on disk |
| `.planning/phases/17-ambient-extras/17-cut-sweep.sh` + manifest + `17-SWEEP-REPORT.md` | Criterion-3 sweep artifact | ✓ VERIFIED | Re-executed in this session, output byte-identical to the committed report |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `wallpaper-picker.sh` (cross-theme / Material You pick) | `wallpaper-visibility.sh` (owner) | `theme_engine_wallpaper_sync_owner` widened ref | ✓ WIRED | CR-01 fix confirmed present at source; review states LIVE-verified for both paths |
| `install.sh` guarded block | `/var/cache/hyprpm/$USER/` | `hyprpm add/enable/update`, all guarded, never aborts install | ✓ WIRED | No unguarded hyprpm call found |
| `theme-init.sh` | `hyprpm-complete.sh` | one backgrounded, output-suppressed invocation | ✓ WIRED | Confirmed in sweep S-18, corroborated by direct read of `hyprpm-complete.sh`'s own header describing the exact call shape |
| `hyprland.lua` | `dynamic-cursors.lua` | `require("config.dynamic-cursors")` | ✓ WIRED | Line 53; corroborated live — plugin config values (`shake:enabled=false`, `mode=tilt`) are actually applied on the running compositor |
| Criterion 3's `windowrules.conf` | `windowrules.lua` (post 13.1 cutover) | sweep's E-01 token-set reconciliation | ✓ WIRED, reconciliation sound | Verified the named file does not exist; the token set excludes two real pre-existing lines that would otherwise false-positive |

### Behavioral / Live Spot-Checks (run in this session, not sourced from SUMMARY)

| Behavior | Command | Result | Status |
|---|---|---|---|
| Cut sweep reproducibility | `bash .planning/phases/17-ambient-extras/17-cut-sweep.sh` | `OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1`, byte-identical to committed report | ✓ PASS |
| quickshell-doctor self-test (includes 2 mpvpaper-layer fixture rows) | `quickshell-doctor --self-test` | `38 passed, 0 failed` | ✓ PASS |
| dynamic-cursors plugin actually loaded on the live compositor | `hyprctl plugin list` | `Plugin dynamic-cursors by Virt` | ✓ PASS |
| D-36 shake-to-find disabled, proven non-default | `hyprctl getoption plugin:dynamic-cursors:shake:enabled` | `bool: false, set: true` | ✓ PASS |
| D-37 mode applied | `hyprctl getoption plugin:dynamic-cursors:mode` | `str: tilt, set: true` | ✓ PASS |
| Cursor-theme pins resolve on disk (D-38 latent-failure check) | `test -d .../BreezeX-RosePine-Linux/cursors`, `test -f .../rose-pine-hyprcursor/manifest.hl` | both PRESENT | ✓ PASS |
| No Phase-17-touched file carries an unresolved debt marker | `grep -nE "TBD\|FIXME\|XXX"` across 11 key files | zero true hits (all matches were `mktemp ...XXXXXX` templates) | ✓ PASS |

Live mpvpaper process was NOT running at verification time (`pgrep mpvpaper` empty, `wallpaper-visibility.sh status` → `stopped`) — this is consistent with no live wallpaper currently being the selected desktop state and is not itself a failure signal; the actuation code path was verified structurally and via the phase's own already-approved fullscreen probe/render-gate evidence rather than by starting playback during this verification session (starting/stopping the live desktop's actual wallpaper was avoided as an unnecessary and disruptive live mutation).

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| AMB-01 | 17-01, 17-02, 17-03 | Video wallpaper plays and hides on fullscreen | ✓ SATISFIED | Truth 1 above; REQUIREMENTS.md marked `[x]` Complete, matching evidence |
| AMB-02 | 17-04, 17-05 | Dynamic cursors optional guarded dependency | ✓ SATISFIED (D-35 stretch caveat recorded) | Truth 2 above; REQUIREMENTS.md marked `[x]` Complete with the D-35 caveat explicitly stated in the same edit |

No orphaned requirements: `grep "Phase 17"` against REQUIREMENTS.md's per-phase count line confirms exactly 2 requirements (AMB-01, AMB-02) map to this phase, matching what all six plans' `requirements:` frontmatter fields declare.

### Anti-Patterns Found

None at blocker or warning severity. `grep -nE "TBD|FIXME|XXX"` across the 11 core Phase-17 files returned only `mktemp` template strings (`.XXXXXX` suffixes), not debt markers. The phase's own code review (`17-REVIEW.md`) found 1 critical + 5 warnings + 2 info issues during a deliberate deep pass; all 8 are recorded `status: fixed` with commit hashes, and I independently confirmed the CR-01 fix (the critical one, and the one most load-bearing for criterion 1/AMB-01) is present in the shipped source rather than trusting the review's own claim.

### Human Verification Required

None outstanding. This phase's blocking human checkpoints (17-01's D-26 probe review, 17-03's render-and-look gate, 17-04's degraded-cursor gate, 17-05's mode/shake gate, and 17-06's final phase-close checkpoint) were already executed during phase execution — not deferred to this verification. The 17-06 phase-close checkpoint's actual resolution ("approved", with the operator's own independent re-verification of the sweep and the cursor-pin count) is recorded verbatim in `17-06-SUMMARY.md` line 79 and was checked directly rather than assumed from a status field.

One item remains explicitly open by design, not by omission: **D-38's cursor-theme-pin gap** (5 sites / 8 declaration lines / 4 files, restated at its corrected size) is accepted, still open, and excluded from drift verdicts — this is a standing, human-approved decision, not a verification finding, and is preserved here so it is not lost at this step.

### Gaps Summary

No gaps found. All three ROADMAP success criteria are independently verified against live source and (for criterion 2) the live running compositor, not merely against SUMMARY/SWEEP-REPORT prose. The one PLAN-level sub-truth that failed as literally stated (17-05's declarative `hl.plugin.load()` objective) does not block the phase goal because the ROADMAP criterion it over-specifies does not mandate that mechanism, the substituted mechanism is independently proven live, and the deviation was surfaced transparently at every level including a human-approved phase-close checkpoint — it is recorded above for visibility, not silently dropped.

---

_Verified: 2026-08-10T11:30:00Z_
_Verifier: Claude (gsd-verifier)_
