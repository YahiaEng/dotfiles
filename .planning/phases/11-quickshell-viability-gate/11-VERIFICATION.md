---
phase: 11-quickshell-viability-gate
verified: 2026-07-26T11:49:32Z
status: gaps_found
score: 6/9 must-haves verified
behavior_unverified: 2
overrides_applied: 0
gaps:
  - truth: "Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug (QS-03 / ROADMAP criterion 2)"
    status: failed
    reason: "shell.qml mounts the probe via a single `LazyLoader { Probe {} }` instance per GlobalShortcut, not one instance per Quickshell.screens entry. A headless output added after shell startup gets zero surface — confirmed live in this verification run: `quickshell-doctor` reported exactly 1 quickshell-probe surface under DP-1 and 0 under a freshly created HEADLESS-21 output. Hotplug add/remove mechanics, the reserved-space diff, and the suspend/resume cycle all independently PASS; only the actual per-screen-render property that QS-03's wording requires fails. A Variants-based fix was attempted in 11-04 and reverted after it introduced two independent live-daemon reliability regressions (documented in 11-QUICKSHELL-EVIDENCE.md, 'Fix attempted and reverted'). REQUIREMENTS.md itself already carries QS-03 as unchecked/Pending, so this gap is honestly self-disclosed by the phase, not concealed — but it is not deferred to any later phase in the traceability table, so it currently has no owner."
    artifacts:
      - path: "quickshell/.config/quickshell/shell.qml"
        issue: "Single LazyLoader per shortcut (lines 26-33, 39-46), no per-Quickshell.screens fan-out"
    missing:
      - "A per-screen surface fan-out mechanism (Variants over Quickshell.screens or an equivalent that does not regress reliability) for at least the permanent shell root, followed by a re-verified quickshell-doctor pass (currently exits 1: 13 passed, 1 failed, on the per-screen-surface-creation check)"
  - truth: "quickshell-doctor performs no persistent mutation beyond the single documented, trap-protected volume-probe exception (explicit 11-03-PLAN.md must-have prohibition)"
    status: failed
    reason: "11-REVIEW.md (code review, dated after all 5 plans executed) found two additional mutation sites with no arming flag and no corresponding `_qsd_cleanup` branch — CR-02 and CR-03. Both confirmed still present in the live script at verification time via direct file read. An interrupt landing mid-check leaves a probe/manifest surface mounted on the user's screen with no restore path, contradicting the script's own stated 'report-only, always restores what it changes' contract that a sibling code path (PROBE_SUMMONED_FOR_HEADLESS_TEST, a few lines above CR-02) correctly implements."
    artifacts:
      - path: "hypr/.config/hypr/scripts/quickshell-doctor"
        issue: "Lines ~198-217 (reserved-space 'stays unclaimed' summon/dismiss loop, CR-03) and ~445-451 (headless-output remove step's transient probe summon, CR-02) mutate compositor state without arming a cleanup flag — verified present at these exact lines during this verification pass"
    missing:
      - "Arm/disarm flags for both mutation sites, mirroring the PROBE_SUMMONED_FOR_HEADLESS_TEST pattern already used correctly a few lines away, plus matching `_qsd_cleanup` branches — 11-REVIEW.md CR-02/CR-03 already spell out the exact fix"
  - truth: "No manual host-only state is baked into any repo-authored Quickshell config file (project Core Value: 'the whole setup reproduces from scratch with one script')"
    status: failed
    reason: "11-REVIEW.md CR-01 found Probe.qml's FileView path hardcoded to the reviewing developer's home directory. Confirmed still present at verification time via direct file read (line 56). On any other user account this silently falls back to the JsonAdapter default forever rather than failing loudly — a quiet host-only-state violation in a file this phase itself stows into the live config, in a package whose entire purpose this phase (per QS-04's must-haves) is to prove state propagation actually works."
    artifacts:
      - path: "quickshell/.config/quickshell/modules/Probe.qml"
        issue: "Line 56: `path: \"/home/aorus/.local/state/quickshell/probe.json\"` — a literal absolute path, unlike quickshell-doctor's own correct `$HOME`-based STATE_DIR convention used elsewhere in this same phase"
    missing:
      - "Replace the literal path with Quickshell.env(\"HOME\") (or the equivalent Directories/StandardPaths helper for this Quickshell version), exactly as 11-REVIEW.md CR-01 already specifies"
behavior_unverified_items:
  - truth: "When two clients bind the same XF86Audio* key, which handler wins is deterministic and stable across sessions rather than racing (11-03 backstop truth)"
    test: "Deliberately register a second handler for an already-bound XF86Audio* key across two session restarts and observe which one consistently fires"
    expected: "The same handler wins every time, not a coin-flip"
    why_human: "Marked verification:backstop in 11-03-PLAN.md — no automated check exercises this; QS-06's own gate only proves single-ownership on this host's current config, not resolution order under a deliberately-created conflict"
  - truth: "With zero connected outputs, the shell process survives and re-creates its surfaces when an output returns (11-04 backstop truth)"
    test: "Remove every monitor (impossible to test safely on a single-monitor host without killing the session) and confirm the quickshell process stays alive and remounts surfaces when an output returns"
    expected: "quickshell process survives with 0 outputs and re-creates its surface(s) when an output reappears"
    why_human: "Deliberately never exercised — this host has exactly one physical monitor, and removing it would kill the graphical session running the verification itself. Disclosed as untested in 11-QUICKSHELL-EVIDENCE.md 'Findings and Caveats'"
---

# Phase 11: Quickshell Viability Gate Verification Report

**Phase Goal:** Quickshell is proven to work on this exact machine — pointer, keyboard, focus, dismiss, multi-monitor, hot reload, and peaceful coexistence with everything already running — or the milestone stops here.
**Verified:** 2026-07-26T11:49:32Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

This phase set out to answer one question decisively (QS-02, with STOP authority) and to
mechanically instrument five more (QS-01, QS-03 through QS-06, MAINT-01). The decisive
question passed cleanly and the evidence for it is real: a human-attested, dated,
first-attempt PASS on pointer click, keyboard input (including non-ASCII), and
click-outside dismiss. That part of the phase goal — "pointer, keyboard, focus, dismiss" —
holds.

The "multi-monitor" clause of the phase goal does **not** fully hold. It was tested, not
assumed, and the test found a real defect: the shell's single-instance `LazyLoader` mounts
the probe on whichever screen existed at startup and does not fan out to a monitor added
later. This was independently re-confirmed live during this verification (a freshly created
headless output got zero probe surfaces). The phase's own evidence artifact and SUMMARY
disclose this honestly and REQUIREMENTS.md already carries QS-03 as unchecked — this is not
a case of a gap being laundered into a PASS. But the phase's internally-recorded verdict
(`Verdict: PASS`) reaches that conclusion by treating QS-03 as a project-level
"record-and-continue" item rather than a phase-goal blocker, which is a legitimate call for
the project to make explicitly, but not one this verifier can apply on the project's behalf
without a recorded override.

Separately, code review (`11-REVIEW.md`, produced after all five plans executed) found three
CRITICAL issues that remain unresolved in the codebase as of this verification pass: a
hardcoded-home-directory path in a stowed QML file (a direct hit against the project's
reproducibility Core Value), and two unarmed-mutation gaps in `quickshell-doctor` itself
that violate that same script's own explicit "no persistent mutation beyond one documented
exception" must-have. None of these are hypothetical — all three were independently
re-confirmed by direct file inspection during this verification.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | QS-01: `install.sh`/`stow.sh`/`quickshell/` package all land in one commit | ✓ VERIFIED | `git show --stat 1aea012` lists `install.sh`, `stow.sh`, the whole `quickshell/` package, launcher, autostart, and keybind together |
| 2 | QS-02: human can click a button, type into a field, and dismiss by clicking outside on a Quickshell layer-shell surface | ✓ VERIFIED (human-attested) | Orchestrator-confirmed: clicked button, typed `héllo — ✓`, dismissed by clicking outside — all three worked first attempt under `WlrKeyboardFocus.OnDemand`; dated log in `11-QUICKSHELL-EVIDENCE.md` "2026-07-26 — 11-01 Task 3" |
| 3 | QS-03: surfaces render correctly across all connected monitors and survive hotplug | ✗ FAILED | Live re-run this verification: `quickshell-doctor` → `[FAIL] per-screen surface creation (QS-03): ... under DP-1 (found: 1) and ... under HEADLESS-21 (found: 0)`. Hotplug add/remove mechanics, reserved-space diff, and suspend/resume (human-attested, same PID) independently PASS |
| 4 | QS-04: editing config hot-reloads the running shell without manual restart | ✓ VERIFIED (human-attested), scope-narrowed | QML source hot-reload verified mechanically; `FileView`/`JsonAdapter` hand-edit propagation human-observed live (label updated to `hello`, zero `reload.sh` involvement). Narrowing: a brand-new `GlobalShortcut` needs a process restart to register — this doesn't reverse the PASS, it scopes what it covers |
| 5 | QS-05: shell autostarts and coexists with waybar/swaync/SwayOSD/wleave/AGS/walker — no namespace collision, no exclusive-zone shift, no duplicate global keybind | ✓ VERIFIED | Live re-run this verification: `quickshell-doctor` namespace discipline PASS (off-level 0, wrong-pid 0), reserved-space diff PASS (`[0,46,0,0]` unchanged), `keybind-doctor` invoked internally PASS (13/0); a second GlobalShortcut (`screencopy-probe`) proved the manifest mechanism scales at the cost of one entry + one keybind line |
| 6 | QS-06: no double-handled event source (MPRIS/PipeWire/hardware keys/Notifications) | ✓ VERIFIED | Live re-run this verification: single `org.freedesktop.Notifications` owner (swaync); all 10 XF86Audio*/XF86MonBrightness* keys exactly 1 handler each; 0 Quickshell files reference MPRIS; volume one-step-per-press matched baseline exactly (3277==3277) on this run |
| 7 | MAINT-01: `keybind-doctor` correctly parses `hyprctl binds` plain-text output and cross-checks Quickshell chords | ✓ VERIFIED | Live re-run this verification: 13 passed, 0 failed, exit 0 against real config; evidence artifact documents a separately-run poisoned-fixture proof (12 passed, 1 named FAIL, exit 1) |
| 8 | quickshell-doctor performs no persistent mutation beyond the single documented, trap-protected volume-probe exception (11-03-PLAN.md must-have) | ✗ FAILED | 11-REVIEW.md CR-02/CR-03, independently re-confirmed by direct file read at verification time: two additional summon/dismiss sites (`quickshell-doctor:198-217`, `:445-451`) mutate compositor state with no arming flag and no `_qsd_cleanup` branch |
| 9 | No manual host-only state is baked into any repo-authored Quickshell file | ✗ FAILED | 11-REVIEW.md CR-01, independently re-confirmed by direct file read at verification time: `Probe.qml:56` hardcodes `/home/aorus/.local/state/quickshell/probe.json` |

**Score:** 6/9 truths verified (2 present-but-behavior-unverified, tracked separately below; not counted toward the score)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.config/quickshell/shell.qml` | Headless ShellRoot, LazyLoader summon mechanism, two GlobalShortcuts | ✓ VERIFIED, wired | Confirmed live: zero level-3 layer entries at idle, exactly one per-shortcut on summon |
| `quickshell/.config/quickshell/modules/Probe.qml` | QS-02 instrumentation panel | ⚠️ VERIFIED but flawed | Functionally correct (human-confirmed) but ships a hardcoded home-directory path (CR-01, gap #3 above) |
| `quickshell/.config/quickshell/modules/ScreencopyProbe.qml` | Criterion-5 live capture tiles | ✓ VERIFIED, wired | Substantive `ScreencopyView`/`ToplevelManager` implementation, not a stub; human-attested to render real window content with 4 concurrent windows |
| `quickshell/.config/quickshell/shortcuts.json` | Declared appid/name/chord manifest | ✓ VERIFIED | 2 entries (`probe`, `screencopy-probe`), cross-checked live against `hyprctl globalshortcuts` |
| `hypr/.config/hypr/scripts/keybind-doctor` | Repaired plain-text parser + Quickshell cross-check | ✓ VERIFIED, wired | Live run: 13 passed, 0 failed, exit 0 |
| `hypr/.config/hypr/scripts/quickshell-doctor` | Seventh rerunnable coexistence gate | ⚠️ VERIFIED but flawed | Runs correctly and reports honestly (13 passed, 1 failed, exit 1 — the disclosed QS-03 gap), but has its own unaddressed interrupt-safety defects (CR-02/CR-03, gap #2 above) |
| `hypr/.config/hypr/config/permissions.conf` | Sourced, inert screencopy permission config | ✓ VERIFIED, wired | Exists, sourced from `hyprland.conf`, ships `enforce_permissions = false`, documents the mechanism verified against the installed binary via `strings` |
| `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` | Single verdict, filled gate table, reproduce section | ✓ VERIFIED | All 7 requirement rows present, verdict line present, reproduce commands are real and were independently re-run during this verification |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `autostart.conf` | `quickshell-launch.sh` → `shell.qml` | `exec-once` | ✓ WIRED | Live process confirmed (`pgrep -f 'quickshell -p'`), came up on its own across a real reboot per orchestrator context |
| `stow.sh` PACKAGES `quickshell` | `~/.config/quickshell` symlink tree | stow | ✓ WIRED | `grep -n quickshell stow.sh` shows PACKAGES entry + pre-created real directory (D-19) |
| `keybinds.conf` `global` dispatcher | `shortcuts.json` manifest → `hyprctl globalshortcuts` | GlobalShortcut | ✓ WIRED | Both `quickshell:probe` and `quickshell:screencopy-probe` present live in `hyprctl globalshortcuts` |
| `Probe.qml` FileView path | `~/.local/state/quickshell/probe.json` → JsonAdapter → label | FileView/watchChanges | ⚠️ WIRED but hardcoded | Functionally wired and human-confirmed live-updating, but the path is a literal `/home/aorus/...` string rather than `$HOME`-derived (gap #3) |
| `install.sh` PACMAN_PKGS `quickshell` | pacman dependency closure | pacman | ✓ WIRED | `pacman -Qi quickshell` confirms 0.3.0-2 from `extra`, full Qt6/cpptrace closure resolved, nothing hand-enumerated |
| `quickshell-doctor` | `keybind-doctor` (exit code) | internal invocation | ✓ WIRED | Confirmed via live run: `[PASS] keybind-doctor clean (MAINT-01 bind-collision proof, exit 0)` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `keybind-doctor` exits clean against real config | `bash hypr/.config/hypr/scripts/keybind-doctor` | 13 passed, 0 failed, exit 0 | ✓ PASS |
| `quickshell-doctor` full live run (includes summon/dismiss and headless-output hotplug) | `bash hypr/.config/hypr/scripts/quickshell-doctor` | 13 passed, 1 failed, exit 1 — sole failure is the disclosed QS-03 per-screen-mounting gap; volume-probe matched baseline exactly this run (no false-positive drift) | ⚠️ PARTIAL — matches the phase's own disclosed defect, no new regression found |
| `git show --stat 1aea012` — same-commit registration | `git show --stat 1aea012` | `install.sh`, `stow.sh`, whole `quickshell/` package, launcher, autostart, keybind all present | ✓ PASS |
| `hyprctl globalshortcuts` lists both manifest entries | `hyprctl globalshortcuts` | `quickshell:probe`, `quickshell:screencopy-probe` both present | ✓ PASS |
| Idle layer-shell footprint | `hyprctl layers -j \| jq '."DP-1".levels["3"]'` | `[]` | ✓ PASS |
| No hex/authored-colour literal in repo QML | `grep -nE '#[0-9A-Fa-f]{3,8}\b' quickshell/.config/quickshell/**/*.qml` | no matches | ✓ PASS |
| Working tree clean (no stray state committed) | `git status --porcelain` | empty | ✓ PASS |
| Debt-marker scan (TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER) across all phase-modified files | `grep -nE ...` over the 13 files this phase touched | no matches | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| QS-01 | 11-01 | install.sh/stow.sh/quickshell package, same commit | ✓ SATISFIED | Commit `1aea012` verified |
| QS-02 | 11-01, 11-05 | Human click/type/click-outside-dismiss gate, STOP authority | ✓ SATISFIED | Human-attested PASS, first attempt |
| QS-03 | 11-04 | Renders correctly on every monitor, survives hotplug | ✗ BLOCKED | Per-screen mounting fails; hotplug mechanics/suspend-resume pass. REQUIREMENTS.md itself already marks this Pending/unchecked — consistent with this finding |
| QS-04 | 11-04, 11-05 | Hot-reload without manual restart | ✓ SATISFIED (scope-narrowed) | QML + FileView hot-reload confirmed; new-GlobalShortcut registration needs restart, disclosed |
| QS-05 | 11-03, 11-05 | Autostart + coexistence, no collision/shift/duplicate keybind | ✓ SATISFIED | quickshell-doctor + keybind-doctor both green on QS-05's own checks |
| QS-06 | 11-03 | Single-owner event sources | ✓ SATISFIED | All checks PASS live |
| MAINT-01 | 11-02 | keybind-doctor plain-text parsing repair | ✓ SATISFIED | 13/0 live, poisoned-fixture proof documented |

No orphaned requirements: all 7 IDs declared in the phase's `requirements` field (across 11-01 through 11-05 PLAN frontmatter) match REQUIREMENTS.md's Phase 11 traceability rows exactly (QS-01..06, MAINT-01).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/Probe.qml` | 56 | Hardcoded `/home/aorus/...` path (CR-01) | 🛑 Blocker | Violates project Core Value (no manual host-only state); silently degrades to default on any other account rather than failing loudly |
| `hypr/.config/hypr/scripts/quickshell-doctor` | ~445-451 | Unarmed probe summon/dismiss in headless-remove step (CR-02) | 🛑 Blocker | Interrupt mid-check strands a mounted probe surface, violating the script's own "always restores" contract |
| `hypr/.config/hypr/scripts/quickshell-doctor` | ~198-217 | Unarmed summon/dismiss loop over every manifest surface (CR-03) | 🛑 Blocker | Same class as CR-02, and grows automatically as more surfaces are added to the manifest in later phases |
| `hypr/.config/hypr/scripts/quickshell-doctor` | 294-317 | Volume-probe arithmetic on unvalidated regex-extracted values (WR-01) | ⚠️ Warning | Could abort the whole script (truncated report) or silently compute a bad delta on a future pactl/locale change |
| `hypr/.config/hypr/scripts/quickshell-doctor` | 275-283 | MPRIS-writer check is a bare case-insensitive substring match on prose (WR-02) | ⚠️ Warning | A future doc comment mentioning "MPRIS" would flip this check to FAIL on nothing real |
| `hypr/.config/hypr/config/keybinds.conf` | 209 | Misplaced `windowrule` line (IN-01) | ℹ️ Info | Cosmetic organization issue, not a viability-gate concern |
| `install.sh` | 369 | Inconsistent `$AUR_HELPER` quoting (IN-02) | ℹ️ Info | Harmless today, latent trap if the variable is ever loosened |

All three Blocker items above were found by `11-REVIEW.md` (code review, dated after execution) and were independently re-confirmed present in the live codebase during this verification pass — they are not resolved by any subsequent commit.

### Human Verification Required

Two backstop-tier must-haves were deliberately never exercised, per the phase's own explicit design (not an oversight):

#### 1. XF86 duplicate-key handler determinism

**Test:** Deliberately register a second handler for an already-bound `XF86Audio*` key across two session restarts and observe which one consistently fires.
**Expected:** The same handler wins every time, not a race.
**Why human:** Marked `verification: backstop` in 11-03-PLAN.md; QS-06's own gate only proves single-ownership on this host's current, non-conflicting config.

#### 2. Zero-output survival

**Test:** Remove every connected monitor and confirm the `quickshell` process stays alive and re-mounts its surface(s) when an output returns.
**Expected:** Process survives with 0 outputs; surfaces reappear when an output does.
**Why human:** This host has exactly one physical monitor; removing it would kill the graphical session performing the test. Deliberately, explicitly left untested (disclosed in `11-QUICKSHELL-EVIDENCE.md`).

### Gaps Summary

Three real, unresolved gaps stand between this phase and a clean pass:

1. **QS-03's per-screen-mounting defect is genuine and currently unowned.** It is honestly disclosed (REQUIREMENTS.md already shows it unchecked, the evidence artifact documents a reverted fix attempt), but the phase's internal `Verdict: PASS` treats it as project-level "record-and-continue" rather than a phase-goal blocker. That is a legitimate project call, but this verifier found no recorded override for it — literal ROADMAP criterion 2 ("renders correctly across all connected monitors") is not met, and no later phase in the traceability table claims ownership of closing it.

2. **Three CRITICAL code-review findings (CR-01/02/03) remain unfixed in the shipped code.** These were surfaced by `11-REVIEW.md` *after* all five plans were marked complete, meaning the phase's own SUMMARY files could not have accounted for them. All three were independently re-confirmed present at this verification's timestamp: a hardcoded home-directory path in a stowed QML file, and two unarmed-mutation defects in the very script (`quickshell-doctor`) whose job is to prove safe, restore-on-interrupt coexistence.

If the project wishes to accept the QS-03 gap as-is and proceed to Phase 12, the cleanest path is an explicit override entry (see below) rather than silently treating the internal evidence-artifact verdict as authoritative. The two `quickshell-doctor` defects and the hardcoded path are small, mechanical fixes with exact patches already written in `11-REVIEW.md` — they do not require new design work, only a short follow-up plan (or inclusion at the top of Phase 12's task list) before further surfaces are built on `quickshell-doctor`'s coexistence guarantee.

**This looks intentional for QS-03 specifically** (a documented, human-authorized project decision that only QS-02 carries STOP authority). To accept that one deviation, add to VERIFICATION.md frontmatter:

```yaml
overrides:
  - must_have: "Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug (QS-03)"
    reason: "D-10: only QS-02 carries STOP authority this phase; QS-03's per-screen-mounting gap is a disclosed, non-blocking finding, and this host has only one physical monitor to begin with"
    accepted_by: "<name>"
    accepted_at: "<ISO timestamp>"
```

No such override is suggested for the three code-review findings (CR-01/02/03) — those are not disclosed design tradeoffs, they are unaddressed defects against the phase's own stated must-haves, with fixes already specified.

---

_Verified: 2026-07-26T11:49:32Z_
_Verifier: Claude (gsd-verifier)_
