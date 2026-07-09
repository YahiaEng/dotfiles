---
phase: 02
slug: static-dynamic-parity-switch-reliability
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-08
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CLI arg → filesystem path | Theme-name argument to theme-parity interpolated toward `palettes/$name.json` | Untrusted CLI string → path component |
| tool stderr → notify-send | Raw matugen/tool stderr could reach a user-facing notification | Tool diagnostics, potential control chars |
| harness → live session processes | Stress harness drives theme-apply, which kills/relaunches Thunar/walker | Process lifecycle of user's own session |
| render/log output → state dir | New `logs/` artifacts written under the chmod-700 state dir | Render diagnostics, run logs |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-02-01 | Tampering | theme-parity theme-name arg | high | mitigate | theme-parity:65–78 validates the argument against actual palette filenames (`materialyou` or existing `palettes/$name.json`) before any path interpolation; unknown names rejected with exit 1 — same guard pattern as theme-apply lines 45–58 | closed |
| T-02-02 | Information Disclosure | theme-parity notifications | medium | mitigate | theme-parity contains no `notify-send` call at all; tool stderr/detail stays in `$LOG_DIR/theme-parity-*.log` only | closed |
| T-02-03 | Information Disclosure | ~/.local/state/theme/logs/ | low | mitigate | theme-parity:44–45 `mkdir -p` + `chmod 700` on `logs/` under the existing chmod-700 state dir; no permission loosening anywhere | closed |
| T-02-04 | Tampering | theme-stress-test theme-name arg | high | mitigate | No user-controlled theme-name argument exists: switch sequence built solely from the hardcoded `STATIC_PRESETS` array plus literal `materialyou` (documented at theme-stress-test:85–91); theme-apply performs its own validation on every name as defense-in-depth (D-44) | closed |
| T-02-05 | Denial of Service (own session) | harness process management | high | mitigate | theme-stress-test performs no kills itself — only read-only `pgrep -x walker` / `pgrep -x elephant` health checks (lines 186, 190); all Thunar/walker lifecycle handling is delegated to theme-apply's hardened lib/reload.sh + lib/gtk.sh bounded-poll/targeted-kill paths; no unscoped `killall` in the phase-02 tools | closed |
| T-02-06 | Information Disclosure | stress notifications | medium | mitigate | theme-stress-test:163 builds the abort notification from internal check descriptions and applies `head -c 200 \| tr -d '\000-\011\013\014\016-\037'` truncate-and-strip before `notify-send`; full diagnostics go to the log file only | closed |
| T-02-07 | Information Disclosure | ~/.local/state/theme/logs/ | low | mitigate | theme-stress-test:93–94 `mkdir -p` + `chmod 700` on `logs/` under the chmod-700 state dir | closed |
| T-02-SC | Tampering | package installs | high | accept | Phase installs zero external packages (RESEARCH Package Legitimacy Audit: N/A) — all tools (matugen, jq, python3 tomllib, diffutils) already present and verified in Phase 1 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-02-01 | T-02-SC | Zero external packages installed in this phase; every tool used (matugen, jq, python3 tomllib, diffutils, rsync) was already present and legitimacy-verified in Phase 1 — no new supply-chain surface introduced | Plan 02-01 / 02-02 threat model (plan-time disposition) | 2026-07-08 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-08 | 8 | 8 | 0 | /gsd-secure-phase (L1 grep-depth, short-circuit — plan-time register, ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-08
