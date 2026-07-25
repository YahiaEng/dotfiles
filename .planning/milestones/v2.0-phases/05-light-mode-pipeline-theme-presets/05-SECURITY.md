---
phase: 05
slug: light-mode-pipeline-theme-presets
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-12
---

# Phase 05 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CLI arg → filesystem path | theme name argument interpolated into `$PALETTES_DIR/$NAME.json` (theme-apply, theme-parity) | untrusted theme name string |
| render output → notify-send | matugen/render stderr surfaced in desktop notifications | error text (possible control chars / length) |
| state dir → GTK config | symlinked settings.ini consumed by every GTK3/GTK4 app at startup | rendered config content |
| upstream web sources → palette JSONs | transcribed hex values flow into every rendered config | color values |
| walker dmenu → shell | selection string and walker's exit code cross from an external UI process into picker scripts | selection text + exit status |
| state file content → filesystem path | last-wallpaper file content joined into a wallpaper path | bare filename |
| fzf selection → filesystem path | selected list entry joined to the Wallpapers root | list entry text |
| state-dir shell fragment → picker process | fzf-colors.conf is sourced (executes as shell) | engine-rendered shell assignments |
| picker → theme-apply | current-theme state content becomes a process argument | theme name string |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-05-01 | Tampering | theme-apply name allowlist | medium | mitigate | Two-literal (materialyou/materialyou-light) + real-palette-file-existence check before any path interpolation (theme-apply lines 47–58) | closed |
| T-05-02 | Information Disclosure | render errors → notify-send | low | mitigate | `head -c 200` + control-char strip (`tr -d '\000-\011\013\014\016-\037'`) before notify-send (theme-apply line 72) | closed |
| T-05-03 | Tampering | state dir perms / settings.ini symlink target | low | mitigate | `chmod 700 "$STATE_DIR"` (commit.sh:67); folded-stow-symlink guard skips settings.ini wiring when `~/.config/gtk-{3,4}.0` is a symlink (commit.sh:92,99) | closed |
| T-05-04 | Tampering | theme-parity target-arg validation | medium | mitigate | Target arg validated against materialyou/materialyou-light literals + real palette filenames, rejects unknown names (theme-parity lines 70–76) | closed |
| T-05-05 | Tampering | transcribed palette values → rendered configs | low | mitigate | theme-parity Layer 3 semantic gate ("semantic values well-formed", theme-parity:308) + key-set/contract checks; exercised across all 22 targets by automated parity runs (UAT tests 9, 10, 12) | closed |
| T-05-06 | Spoofing | picker display-name → palette-name mapping | low | mitigate | Names built from real `palettes/*.json` basenames; selection maps back via index-matched parallel arrays; theme-apply re-validates final name regardless (theme-switch.sh) | closed |
| T-05-07 | Tampering | last-wallpaper state content path join | medium | mitigate | Bare-filename validation: rejects content containing `/`, requires file to exist inside the theme folder before use (lib/wallpaper.sh:52) | closed |
| T-05-08 | Denial of Service | awww call in headless context | low | mitigate | WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS session guard + `command -v awww` + best-effort `\|\| true` (lib/wallpaper.sh:71–76) | closed |
| T-05-09 | Tampering | fzf selection path join | medium | mitigate | Entries derive exclusively from find enumeration; marker stripped; joined path re-validated as existing regular file under the Wallpapers root before symlink op (wallpaper-picker.sh:311–319) | closed |
| T-05-10 | Elevation of Privilege | sourcing fzf-colors.conf | medium | mitigate | Fragment engine-rendered with quoted assignments into 700-perm state dir (commit.sh chmod); sourced best-effort with `2>/dev/null \|\| true`; no other writer exists (wallpaper-picker.sh:32) | closed |
| T-05-11 | Tampering | current-theme state → theme-apply arg | low | mitigate | theme-apply re-validates every name against real palette files + the two materialyou literals (existing allowlist, unchanged) | closed |
| T-05-05-01 | Tampering | theme-switch.sh / waybar-switch.sh exit-code branch | low | mitigate | Explicit `(( rc == 130 ))` cancel branch; every other nonzero routes to loud failure (notify-send + exit 1); theme-apply re-validates selection (theme-switch.sh, waybar-switch.sh:24–33) | closed |
| T-05-05-02 | Injection | selection string → theme-apply | low | accept | Index-matched parallel array mapping (never a reverse string transform) + theme-apply allowlist re-validation — documented accepted risk AR-05-01 | closed |
| T-05-05-SC | Tampering | package installs | low | accept | No npm/pip/cargo/pacman installs in phase 05 plans; supply-chain gate N/A — documented accepted risk AR-05-02 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-05-01 | T-05-05-02 | Selection string never becomes a path or command directly: it maps to the exact palette basename via an index-matched parallel array, and theme-apply independently re-validates the name against `palettes/*.json` plus the two materialyou literals (defense in depth). Residual risk negligible. | gsd-secure-phase (plan disposition, 05-05-PLAN.md) | 2026-07-12 |
| AR-05-02 | T-05-05-SC | Phase 05 introduces no package installs (npm/pip/cargo/pacman); supply-chain gate not applicable to this scope. | gsd-secure-phase (plan disposition, 05-05-PLAN.md) | 2026-07-12 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-12 | 14 | 14 | 0 | gsd-secure-phase (L1 grep-depth verification; short-circuit — register authored at plan time, threats_open 0) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-12
