---
phase: 09-wlogout-to-wleave-migration
verified: 2026-07-25T22:10:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 9: wlogout to wleave Migration Verification Report

**Phase Goal:** Replace wlogout with wleave (GTK4) as the power menu, eliminating the GTK3 whole-stylesheet-discard failure class that produced the WLOG-01 blocker, and moving onto an actively-maintained tool — with no regression to the Phase 6 center-bar design.
**Requirements:** WLOG-01 (re-delivered on a new engine)
**Verified:** 2026-07-25T22:10:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The GTK3 whole-stylesheet-discard failure class is structurally eliminated — the new engine is genuinely GTK4, not GTK3 with a new name | ✓ VERIFIED | `pacman -Qi wleave` → Depends On: `librsvg libadwaita gtk4-layer-shell`; `ldd /usr/bin/wleave` links `libgtk-4.so.1`, `libadwaita-1.so.0`, `libgtk4-layer-shell.so.0` — confirmed independently, not merely asserted. This engine class recovers per-rule on an invalid CSS rule rather than discarding the whole sheet (documented GTK4 behavior; the root driver named explicitly in ROADMAP.md's "Why this phase exists"). |
| 2 | WLOG-01 is genuinely re-delivered: six *styled* capsules (distinct per-hue fill/border/glyph), not six unstyled buttons — the original blocker | ✓ VERIFIED | `wleave/.config/wleave/layout.json` defines exactly six buttons (lock/logout/suspend/hibernate/reboot/shutdown) each with an `icon` + Title Case `text`; `wleave/.config/wleave/style.css` gives each an id-selector rule with a distinct M3-role `background-color`/`color`/`border-color` (four native + two `mix()`-derived hues). Independently viewed `evidence/09-04-fix2-dark-cold-open.png` and `-light-cold-open.png`: six visibly distinct-hued capsules render legibly on both dark and light wallpaper-driven presets — the visual regression WLOG-01 was blocked by. `evidence/09-04-fix2-hover-dark.png` independently confirms the hover-revealed "Log Out" label + border glow + scale-up on a live capture. |
| 3 | The wlogout retirement is complete at the repo/config level — no dangling references in scripts, configs, contract entries, or install/stow package lists | ✓ VERIFIED (one disclosed cosmetic exception) | `wlogout/` directory does not exist in the repo. Repo-wide grep (excluding `.planning/`, `.git/`, `settings.local.json`) returns exactly one hit: a rationale *comment* in `wleave/.config/wleave/style.css:219` ("Do NOT copy the retired wlogout sheet's pattern...") — this is the same IN-01 finding the code review already caught and disclosed; it is prose, not a functional reference, and does not affect any check that greps for the retired namespace (`logout_dialog`: zero repo-wide matches). `contract.json`, `theme-doctor`'s GTK4 sheet list, `windowrules.conf`'s layerrules (`match:namespace wleave`), `keybinds.conf`, both waybar layouts, and the elephant menu all point exclusively at wleave. |
| 4 | Reproducibility is intact: `install.sh` + `stow.sh` alone reproduce the power menu on a fresh Arch system, with no host-only manual state | ✓ VERIFIED | `install.sh:233` lists `wleave` in `AUR_PKGS`; `stow.sh:38` lists `wleave` in `PACKAGES`. Confirmed live: `~/.config/wleave/layout.json` and `~/.config/wleave/style.css` resolve via `readlink -f` back to `/home/aorus/dotfiles/wleave/.config/wleave/{layout.json,style.css}` — genuine stow symlinks, not host-only copies. `wlogout` is absent from both `AUR_PKGS` and `PACKAGES`. |
| 5 | The Phase 6 center-bar design is preserved: six capsules, one horizontal row, screen centre, severity-gradient order lock→logout→suspend→hibernate→reboot→shutdown | ✓ VERIFIED | `layout.json`'s `buttons` array is ordered lock, logout, suspend, hibernate, reboot, shutdown — matches the severity gradient exactly. Independently viewed evidence screenshots confirm one horizontal row of six capsules, screen-centred, over a dimmed desktop scrim — the same layout shape as Phase 6, on the new engine. |
| 6 | Requirement WLOG-01 is the sole requirement claimed by this phase, and every plan's declared requirement is accounted for — no orphaned requirement IDs | ✓ VERIFIED | All four plans (`09-01` through `09-04`) declare `requirements: [WLOG-01]` in frontmatter, consistent with ROADMAP.md's phase annotation "Requirements: WLOG-01 (re-delivered on a new engine)". REQUIREMENTS.md's existing traceability table maps WLOG-01 to Phase 6 (its original delivery); Phase 9 is a documented redelivery-on-a-new-engine, not a new/undeclared requirement, so there is no orphaned ID here. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wleave/.config/wleave/layout.json` | Six power actions, severity-ordered, wrapped JSON schema | ✓ VERIFIED | Six buttons present, correct order, correct action strings, `no-version-info: true`, `buttons-per-row: "6"`, `column-spacing: 24` |
| `wleave/.config/wleave/style.css` | Transparent window + scrim + six-hue capsule geometry + hover/focus + entrance stagger | ✓ VERIFIED | `window { background-color: rgba(0,0,0,0.40) }` scrim; six id-selector rest-state rules; paired `:hover`/`:focus` rules (9/9); `@keyframes capsule-entrance` with six per-id delays; imports `~/.local/state/theme/wleave.css` |
| `hypr/.config/hypr/scripts/wleave.sh` | Open-only launcher, spawn-failure guard, no toggle/geometry logic | ✓ VERIFIED | Binary-absent and spawn-fail both `notify-send -u critical` + `exit 1`; no `pgrep`/`pkill`; `set -euo pipefail`; executable (`-rwxr-xr-x`) |
| `matugen/.config/matugen/templates/wleave-colors.css` | 23-key M3 palette template including four container roles | ✓ VERIFIED | All 23 `{{colors.*.default.hex}}` tokens present, including `tertiary_container`/`on_tertiary_container`/`error_container`/`on_error_container`; rendered `~/.local/state/theme/wleave.css` resolves all 23 with zero unresolved `{{` tokens for the active preset |
| `.planning/phases/.../evidence/*.png` | grim screenshot evidence for render-gate views | ✓ VERIFIED | 80 evidence files present, including all named dark/light cold-open, hover, and exit-tier captures; independently viewed 3 of them (dark cold-open, light cold-open, hover) and confirmed content matches claims |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `hypr/.config/hypr/config/keybinds.conf` | `hypr/.config/hypr/scripts/wleave.sh` | Super+Shift+Q exec bind | ✓ WIRED | `bind = $mainMod SHIFT, Q, exec, ~/.config/hypr/scripts/wleave.sh` present |
| `waybar/.config/waybar/modules.jsonc` | `hypr/.config/hypr/scripts/wleave.sh` | `custom/power` on-click | ✓ WIRED | Line 256: `"on-click": "~/.config/hypr/scripts/wleave.sh"` |
| `waybar/.config/waybar/config-floating.jsonc` | `hypr/.config/hypr/scripts/wleave.sh` | `custom/power` on-click | ✓ WIRED | Line 82: `"on-click": "bash ~/.config/hypr/scripts/wleave.sh"` (invocation-style inconsistency noted as IN-02, cosmetic — does not break wiring) |
| `elephant/.config/elephant/menus/main.toml` | `hypr/.config/hypr/scripts/wleave.sh` | Power entry `actions.open` | ✓ WIRED | Line 35: `actions = { "open" = "~/.config/hypr/scripts/wleave.sh" }` |
| `wleave/.config/wleave/style.css` | `~/.local/state/theme/wleave.css` | relative `@import` | ✓ WIRED | `@import url("../../.local/state/theme/wleave.css");` — target file exists, renders 23/23 tokens |
| `matugen/.config/matugen/config.toml` | `~/.local/state/theme/wleave.css` | `[templates.wleave]` render target | ✓ WIRED | `input_path`/`output_path` correctly configured, confirmed rendered |
| `hypr/.config/hypr/config/windowrules.conf` | wleave namespace | `layerrule ... match:namespace wleave` | ✓ WIRED | `blur on`, `animation fade`, `ignore_alpha 0.25` all scoped to `match:namespace wleave`; zero `logout_dialog` references remain |
| `install.sh` / `stow.sh` | `~/.config/wleave/` | AUR_PKGS + PACKAGES entries | ✓ WIRED | Both list `wleave`; live stow symlinks confirmed via `readlink -f` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|--------------|-------------|--------------|--------|----------|
| WLOG-01 | 09-01, 09-02, 09-03, 09-04 (all four) | wlogout redelivered on a new (GTK4) engine, eliminating the GTK3 whole-stylesheet-discard failure class | ✓ SATISFIED | See Truths 1–5 above; six styled capsules render correctly on both presets, all entry points wired, reproducible via install.sh+stow.sh, GTK3 engine retired from the repo |

No orphaned requirements found — REQUIREMENTS.md and all four PLAN frontmatters agree on WLOG-01 as the sole requirement for this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `hypr/.config/hypr/scripts/wleave.sh` | 1-25 | No liveness guard against duplicate/stacked `wleave` invocations (WR-01, code review) | ⚠️ Warning | Double-invoking an entry point in quick succession could stack surfaces; explicit design tradeoff of D-18 (no pgrep/pkill liveness scan) — does not block the phase goal |
| `hypr/.config/hypr/scripts/wleave.sh` | 20-24 | Fixed 300ms `sleep`+`kill -0` spawn check, no retry/backoff (WR-02, code review) | ⚠️ Warning | Could spuriously report launch failure under load; not observed in this verification's testing |
| `hypr/.config/hypr/scripts/wleave.sh` | 1-25 | No check that the user's own `layout.json` exists before launch (WR-03, code review); confirmed via fault-injection in 09-04, silently falls back to unstyled upstream default | ⚠️ Warning | Honestly disclosed (WINDOWS.md entry 6, deferred-items.md item 4); does not produce a blank/invisible surface (satisfies the D-23/UI-Consideration-1 backstop), but is a real, undisclosed-to-user degraded mode |
| `wleave/.config/wleave/style.css` | 219 | Rationale comment names the retired "wlogout" tool (IN-01, code review) | ℹ️ Info | Cosmetic; contradicts the literal "zero matches" claim in 09-02-SUMMARY.md but does not affect any functional check |
| Multiple entry-point files | — | Inconsistent invocation style (`bash script.sh` vs bare path) across the four wiring points (IN-02, code review) | ℹ️ Info | Low risk today since the file is executable; would only matter if the executable bit were ever lost on a subset of entry points |

No TBD/FIXME/XXX debt markers found in any of the 15 phase-touched source files scanned. No Critical/Blocker findings — matches the code review's own `status: issues_found` (0 critical / 3 warning / 2 info) classification, all advisory and already transparently disclosed in the phase's own SUMMARY/WINDOWS.md records rather than hidden.

### Gate Sweep Cross-Reference (independently re-run)

| Gate | SUMMARY-claimed result | Independently re-run result | Match |
|------|------------------------|------------------------------|-------|
| `theme-doctor` | 135 passed, 2 failed (`eww.scss` orphan, dirty git tree — both pre-existing/unrelated) | 135 passed, 2 failed, identical two failures (`eww.scss exists`, `git status --porcelain is empty`); `wleave.css` PASS, `CSS-parse: wleave/style.css` PASS | ✓ Exact match |

`theme-parity` (1542/22, 100% eww.scss-scoped) was not re-run in full here (long-running, already independently corroborated by the orchestrator per the established context) but the `theme-doctor` re-run above cross-validates the same "wleave-clean, eww-orphan-only" failure pattern claimed across all four SUMMARYs.

## Human Verification Required

None. The D-14 human render-and-look gate is already closed (established context, corroborated independently in this verification by direct visual inspection of `evidence/09-04-fix2-dark-cold-open.png`, `-light-cold-open.png`, and `-hover-dark.png`, all of which show the claimed six distinct-hued capsules, legible on both presets, with a working hover-reveal state). No new behavior-dependent truth was left unexercised in this verification pass.

## Gaps Summary

None. All six derived observable truths are verified against the actual codebase, not just asserted in SUMMARY.md. The three code-review Warnings (WR-01/02/03) and two Info items (IN-01/02) are real, but are advisory robustness/completeness gaps rather than goal-blocking failures — none of them contradicts a must-have truth, leaves an artifact missing/stub, or breaks a key link, and all are already transparently disclosed in this phase's own records (WINDOWS.md, deferred-items.md, 09-REVIEW.md) rather than hidden. The one deliberately out-of-scope item (D-22 multi-monitor) is correctly recorded as NOT-APPLICABLE given only one output is connected on this machine, per the roadmap's own scope note that this phase was never expected to fix wlogout's blur-strength limitation.

---

_Verified: 2026-07-25T22:10:00Z_
_Verifier: Claude (gsd-verifier)_
