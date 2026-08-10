---
phase: 11-quickshell-viability-gate
audited: 2026-07-26T15:45:00Z
verdict: SECURED
threats_total: 25
threats_closed: 25
threats_open: 0
asvs_level: 1
block_on: high
source_threat_models:
  - 11-01-PLAN.md
  - 11-02-PLAN.md
  - 11-03-PLAN.md
  - 11-04-PLAN.md
  - 11-05-PLAN.md
auditor: "Claude (gsd-security-auditor)"
method: "Mitigations verified against live implementation, not plan prose. Includes three live re-executions of keybind-doctor and quickshell-doctor against the real Hyprland session, and direct filesystem checks of all four permissions.conf binary paths."
---

# Phase 11: Security Audit

**Verdict:** SECURED
**Threats Closed:** 25/25
**ASVS Level:** 1 (`block_on: high`, per `.planning/config.json`)
**Audited:** 2026-07-26T15:45:00Z

Run as state (B) — no prior SECURITY.md; threat models drawn from all five phase plans.

## Threat Verification

| Threat ID | Category | Severity | Disposition | Evidence |
|-----------|----------|----------|-------------|----------|
| T-11-01 | Tampering | high | mitigate | `install.sh:137` — `quickshell` in `PACMAN_PKGS` only; zero occurrences in `AUR_PKGS` (lines 218-272) |
| T-11-SC | Tampering (supply chain) | high | mitigate | Single official-repo line, no hand-enumerated deps added |
| T-11-02 | Tampering/EoP | medium | mitigate | `Probe.qml:61-64` — `JsonAdapter { property string label: "unset" }`, typed scalar only; `grep -rn "Process" quickshell/` returns zero hits — no exec-capable component exists |
| T-11-03 | EoP | medium | mitigate | `quickshell-launch.sh:27,37` — `command -v quickshell` guard then `exec quickshell -p "$CONFIG_DIR"`; `$CONFIG_DIR` is a fixed literal, no user-writable state in the exec line |
| T-11-04 | Spoofing | low | accept | Collision caught by keybind-doctor's live cross-check (T-11-08), re-confirmed live 13/13; single-user desktop |
| T-11-05 | Info Disclosure | low | accept | `quickshell-launch.sh:17-25` — 1 MiB truncation present; log is dated startup/exit lines + stderr only |
| T-11-06 | Tampering | medium | mitigate | `grep -nE '\beval\b\|\bsource\b'` over both doctors → zero command-interpretation hits on any parsed value |
| T-11-07 | Repudiation | high | mitigate | Live-reproduced: poisoned fixture (`SUPER SHIFT+G` collision) → exit 1 naming "chord collision"; real config immediately after → 13 passed, exit 0 |
| T-11-08 | DoS | medium | mitigate | `keybind-doctor:344-351` — duplicate appid+name check present; live: 0 found |
| T-11-09 | Tampering | high | mitigate | `hyprctl binds -j` / `globalshortcuts -j` appear only inside comments — never in an executable line; plain-text shape guard is the live path |
| T-11-10 | Tampering | high | mitigate | `quickshell-doctor:81-83` `_qsd_valid_token()` = `^[A-Za-z0-9_-]+$`, applied before every `hyprctl dispatch global`; values passed as argv elements, never through a shell string |
| T-11-11 | DoS | medium | mitigate | Trap `_qsd_cleanup` installed at 236-238, flags declared 93-110 before any mutation; WR-01 fix confirmed — empty-`mapfile` guards before mutation (~317) and before delta arithmetic (~330) |
| T-11-12 | Repudiation | high | mitigate | Check uses `hyprctl monitors -j` `reserved` array diff, not a `layers -j` grep for a nonexistent field |
| T-11-13 | Tampering | medium | mitigate | `STATE_DIR`/`BASELINE_FILE` resolve under `$HOME/.local/state/quickshell`; `git status --porcelain` empty immediately after a live full run |
| T-11-14 | Spoofing | low | mitigate | Namespace-discipline check live-confirmed PASS: off-level 0, wrong-pid 0 |
| T-11-15 | DoS | high | mitigate | `HEADLESS_CREATED_NAME` armed before `hyprctl output create headless` (~103, ~416), cleared after manual remove (~468); trap-only restore, live headless add/remove returns to baseline count |
| T-11-16 | Tampering | medium | mitigate | JsonAdapter typed-scalar-only, zero Process components. Absent-file case human-tested PASS (graceful default). Empty-JSON-object sub-case disclosed untested in `11-QUICKSHELL-EVIDENCE.md` — a coverage gap, not a missing mitigation: no exec path reads the file regardless of content |
| T-11-17 | DoS | medium | mitigate | `grep -n "quickshell" theme-engine/.../lib/reload.sh` → zero matches; D-13 negative branch, threatened component does not exist |
| T-11-18 | Repudiation | high | mitigate | Virtual-output caveat attached to every QS-03 claim; gate table row reads "OPEN — genuine per-screen-mounting defect", not PASS |
| T-11-19 | Info Disclosure | low | accept | `lib/reload.sh` untouched; no new boundary introduced by plan 04 |
| T-11-20 | EoP | high | mitigate | `permissions.conf` — 4 `permission =` lines, all exact absolute paths, zero `*?[\|` glob chars; all 4 paths verified to exist as declared |
| T-11-21 | DoS | high | mitigate | All 4 pre-existing screencopy consumers enumerated and allowed (incl. `hyprpicker`, added mid-plan per its Rule-2 deviation log); `ecosystem { enforce_permissions = false }` — ships inert |
| T-11-22 | Info Disclosure | medium | accept | `ScreencopyProbe.qml` renders only to a local overlay `PanelWindow`; zero file I/O, zero network, zero logging of captured content |
| T-11-23 | Repudiation | high | mitigate | `11-QUICKSHELL-EVIDENCE.md:1061` — RESEARCH.md's `[ASSUMED — LOW confidence]` tag resolved to a verified finding with quoted mechanics from the running binary |
| T-11-24 | DoS | medium | mitigate | `permissions.conf:26-28,45-54` — reload-vs-restart distinction documented, sourced from `strings` on the live binary, not assumed |

## Unregistered Flags

None found.

`11-02-SUMMARY.md` and `11-04-SUMMARY.md` carry explicit `## Threat Flags: None` sections mapping all new surface to existing threat IDs (T-11-06/07/08/09 and T-11-15/16/17/18) — independently confirmed accurate.

`11-01-SUMMARY.md`, `11-03-SUMMARY.md` and `11-05-SUMMARY.md` have no `## Threat Flags` heading at all. This is a **documentation-consistency gap worth fixing in future phases**, not a security finding: an independent line-by-line review of every file shipped in those plans' scope (`shell.qml`, `shortcuts.json`, `stow.sh`'s quickshell package addition, `ScreencopyProbe.qml`, `permissions.conf`) found no new attack surface outside the registered 25-threat set.

## Relationship to the Code Review

Five findings from `11-REVIEW.md` were fixed and committed before this audit (CR-01 hardcoded home path; CR-02/CR-03 unarmed compositor-state mutation sites; WR-01 volume-probe regex validation; WR-02 MPRIS check narrowing). This audit re-verified the two security-relevant ones in place rather than trusting the fix report: the CR-02/CR-03 arm/disarm flags and their `_qsd_cleanup` branches (T-11-11, T-11-15), and WR-01's pre-mutation guard (T-11-11).

---

_Audited: 2026-07-26T15:45:00Z_
_Auditor: Claude (gsd-security-auditor)_
_Verdict: SECURED — 0 threats open_
