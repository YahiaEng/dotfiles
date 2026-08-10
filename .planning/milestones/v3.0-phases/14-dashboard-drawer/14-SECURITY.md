---
phase: 14
slug: dashboard-drawer
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
threats_total: 45
threats_closed: 44
threats_open_nonblocking: 1
register_authored_at_plan_time: true
created: 2026-08-01
---

# Phase 14 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register origin: the `<threat_model>` block in all ten of this phase's PLAN files
(`register_authored_at_plan_time: true`), so this audit **verified stated
mitigations** rather than retroactively scanning for new threats.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Open-Meteo HTTP response → the QML engine | Third-party network data parsed and rendered inside a process holding a compositor-exclusive focus grab; a throw inside the drawer is a broken *surface holding desktop input*, not a broken widget | Untrusted JSON |
| `~/.local/state/theme/weather.json` → the request URL | A user-owned dotfile supplies coordinates and unit strings that become part of an outbound request | User-editable config |
| `weather-cache.json` on disk → the render path | Written and re-read across restarts, editable by anything running as the user, parsed on every shell start before any network call | Cached third-party payload |
| The drawer's outbound request → a third-party host | Every fetch discloses a coordinate pair and a timing pattern to an unauthenticated external service | Coarse location, timing |
| MPRIS player control → `media-players.sh` | Player-supplied identifiers reaching a command dispatch | Untrusted player ids |
| Manifest-derived identifiers → `hyprctl dispatch` argv | `shortcuts.json` appid/name pairs reaching a compositor dispatch that is now parsed as Lua source | Config-derived tokens |

---

## Threat Register

45 threats across ten plans. Full per-threat evidence is in the audit trail entry
below; this table records disposition and status.

| Threat ID | Category | Severity | Disposition | Status |
|-----------|----------|----------|-------------|--------|
| T-14-SC | Tampering | high | mitigate | closed |
| T-14-01 | Tampering | high | mitigate | closed |
| T-14-36 | Tampering | high | mitigate | closed |
| T-14-43 | Repudiation | high | mitigate | closed |
| T-14-37 | Denial of Service | high | mitigate | closed |
| T-14-02 | Denial of Service | medium | mitigate | closed |
| T-14-05 | Denial of Service | medium | mitigate | closed |
| T-14-06 | Tampering | medium | accept | closed (accepted) |
| T-14-08 | Denial of Service | medium | mitigate | closed |
| T-14-13 | Tampering | medium | mitigate | closed |
| T-14-15 | Spoofing | medium | mitigate | closed |
| T-14-17 | Denial of Service | medium | mitigate | closed |
| T-14-19 | Denial of Service | medium | mitigate | closed |
| T-14-25 | Denial of Service | medium | mitigate | closed |
| T-14-30 | Tampering | medium | mitigate | closed |
| T-14-31 | Repudiation | medium | mitigate | closed |
| T-14-38 | Denial of Service | medium | mitigate | closed |
| T-14-40 | Repudiation | medium | mitigate | closed (partial — see note) |
| T-14-41 | Tampering | medium | mitigate | closed |
| **T-14-39** | **Spoofing** | **medium** | **mitigate** | **open — below `high` threshold (non-blocking)** |
| T-14-03 (seed) | Tampering | low | mitigate | closed |
| T-14-03 (validate) | Tampering | low | mitigate | closed |
| T-14-04 | Spoofing | low | mitigate | closed |
| T-14-07 | Denial of Service | low | mitigate | closed |
| T-14-09 | Tampering | low | mitigate | closed |
| T-14-10 | Denial of Service | low | mitigate | closed |
| T-14-11 | Tampering | low | mitigate | closed |
| T-14-12 | Spoofing | low | mitigate | closed |
| T-14-14 | Tampering | low | mitigate | closed |
| T-14-16 | Denial of Service | low | mitigate | closed |
| T-14-18 | Tampering | low | mitigate | closed |
| T-14-20 | Denial of Service | low | mitigate | closed |
| T-14-21 | Tampering | low | mitigate | closed |
| T-14-22 | Information Disclosure | low | accept | closed (accepted) |
| T-14-23 | Information Disclosure | low | accept | closed (accepted) |
| T-14-24 | Tampering | low | mitigate | closed |
| T-14-26 | Tampering | low | mitigate | closed |
| T-14-27 | Spoofing | low | mitigate | closed |
| T-14-28 | Spoofing | low | mitigate | closed |
| T-14-29 | Denial of Service | low | mitigate | closed |
| T-14-32 | Spoofing | low | mitigate | closed |
| T-14-33 | Denial of Service | low | mitigate | closed |
| T-14-34 | Tampering | low | mitigate | closed |
| T-14-35 | Information Disclosure | low | mitigate | closed |
| T-14-42 | Information Disclosure | low | accept | closed (accepted) |

*Status: open · closed · open — below high threshold (non-blocking)*
*Only open threats at or above `block_on: high` count toward `threats_open`.*

### Open — non-blocking

**T-14-39 (Spoofing, medium) — the GPU dial's no-hardware claim rests on synthetic evidence, and says otherwise.**

Two of three prongs verified: three synthetic no-GPU shapes were exercised (commit
`14d4044`), and the dial is always present with a designed `gpuState: "empty"`
(`SystemResources.qml:787-803`).

The third prong — *write down, in the same paragraph as the result, exactly what the
synthetic cases prove and which remain unexercised* — is absent. The record makes the
precise over-claim the threat was written to prevent: `14-10-SUMMARY.md:291-292` states
"The GPU dial degrades to a designed 'No GPU' state on machines without an NVIDIA
adapter, so nothing host-specific is required for reproduction" — an unqualified
hardware-coverage claim derived from synthetic seams only.

Genuinely non-NVIDIA hardware, a driver installed-but-broken, and a query that hangs
rather than fails all remain unexercised **and unstated**. Non-blocking (medium < high),
but it is a documentation-accuracy defect on a fresh-install reproducibility claim.

### Note on T-14-40 (closed, partial)

The revert was built before the gate (`ConditionGlyph.qml:93` `layeringEnabled`) and the
human's verbatim verdict is recorded (`14-10-SUMMARY.md:179` — "Better. Keep it."), with
the executor recording no verdict of its own. The register additionally asked for
separate hero-vs-small-cell answers; only a combined verdict was captured.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-14-01 | T-14-06 | DASH-08's fullscreen guard fails **open** on a stale/empty `lastIpcObject` read — the drawer opens over a fullscreen client rather than refusing. Failing closed would make a stale read *block* the drawer entirely, judged the worse failure. Mitigated as far as sensible by `refreshToplevels()` on the compositor fullscreen event (`shell.qml:158-165`); residual accepted. | Plan time (14-01) | 2026-07-29 |
| AR-14-02 | T-14-22 | Performance dials read local kernel counters (`/proc`, hwmon, UPower). No privilege boundary is crossed and nothing leaves the machine. | Plan time (14-06) | 2026-07-29 |
| AR-14-03 | T-14-23 | Weather fetches disclose a coarse city-level coordinate pair and a timing pattern to Open-Meteo. Inherent to any weather integration; D-30 deliberately seeds city-level (not precise) coordinates, and D-32's TTL bounds the timing signal. | Plan time (14-07) | 2026-07-29 |
| AR-14-04 | T-14-42 | GPU model name is read from `nvidia-smi` and rendered locally only; never transmitted, never written to a committed file. | Plan time (14-10) | 2026-07-30 |

---

## Unregistered Surface (flagged by this audit)

Both `## Threat Flags` sections (`14-09-SUMMARY.md:548`, `14-10-SUMMARY.md:284`) declare
"None new" — and both were written **before** the DASH-10 / UAT-era commits landed. Three
pieces of new surface therefore carry no threat mapping. None is a found vulnerability;
each is an unmodelled area recorded so it is not mistaken for cleared ground.

1. **`QSG_RENDER_LOOP=threaded`** (`quickshell-launch.sh`, `2642e68`) — no register entry.
   Touches the T-14-05 / T-14-17 DoS class: the drawer holds a compositor-exclusive focus
   grab, so a wedged render thread is wedged *desktop* input. The script's own comment
   concedes one session is not a soak on an NVIDIA + Wayland host. Currently covered only
   by a human UAT observation (`14-UAT.md` item 7) — an observation, not a control.
2. **`GradientBorder.qml` / DASH-10** (`b610aff`, `b80096d`, requirement in `5afd63e`) — a
   newly registered type carrying an infinite `NumberAnimation`. Structurally inside
   T-14-33's class (mounted on the destroy-on-dismiss surface, gated on
   `Motion.motionEnabled && root.active`) and satisfies T-14-12 (registered in `qmldir` in
   the same commit that created it) — but a whole minted requirement passed through with
   no threat-model pass.
3. **`indicators` bucket in the QML-facing `motion.json`** (`lib/motion.sh`, `40add03`) — a
   fifth payload key on a pipeline T-14-09 scopes to four rendered targets. It rides the
   same validate-before-write path (`motion.sh:148-166`), so the control holds, but the
   register names no entry for it.

---

## Supplemental Observations

- **`quickshell-doctor` Lua dispatch rewrite** — T-11-10's input-validation control **holds
  across all 8 call sites**. `_qsd_dispatch_global` embeds its argument in a Lua
  double-quoted string; five sites pass the hardcoded literal `"quickshell:probe"`, two pass
  `${m_appid}:${m_name}` gated by `_qsd_valid_token` (`^[A-Za-z0-9_-]+$`) on **both** segments
  with `continue` on failure, and the cleanup-trap site passes a variable whose only
  non-empty assignment happens after that allowlist. Zero raw `hyprctl dispatch global`
  sites remain.
- **Process hygiene (informational, outside T-14-16's declared scope):** one orphaned
  `swaync-client --subscribe` (re-parented to systemd) survived a quickshell instance that
  was hard-killed. The current instance holds zero such children with the drawer dismissed,
  which is what T-14-16 asserts, so the mitigation is not falsified — but a SIGKILL'd parent
  does leave that child behind, which the register does not cover.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open (blocking) | Open (non-blocking) | Run By |
|------------|---------------|--------|-----------------|---------------------|--------|
| 2026-08-01 | 45 | 44 | 0 | 1 (T-14-39) | gsd-security-auditor (ASVS L1, block_on: high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed — the single open threat (T-14-39, medium) is below the
      `high` block threshold and is recorded above rather than silently closed
