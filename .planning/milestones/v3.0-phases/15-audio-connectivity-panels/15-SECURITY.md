---
phase: 15
slug: audio-connectivity-panels
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-08
---

# Phase 15 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register authored at plan time (`register_authored_at_plan_time: true`) — all 14 PLAN
files carried a parseable `<threat_model>` block. This document consolidates those 14
registers into one phase-level register, verified against the implementation by
`gsd-security-auditor` on 2026-08-08.

**Register-ID note:** `T-15-08` was minted three separate times across plans with three
different meanings. They are disambiguated here as `T-15-08a` / `T-15-08b` / `T-15-08c`
and tracked as three distinct threats. Future phases should not reuse the bare ID.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Human keyboard → the panel's masked field | A wifi passphrase — the only secret this phase handles — crosses into the shell process and becomes a live value in a QML control | **Secret** (plaintext passphrase) |
| Panel → `WifiBackend` → NetworkManager (system D-Bus) | The secret crosses a process boundary; where it may travel on the way is the phase's gating concern | **Secret** (passphrase, via native `connectWithPsk`) |
| Human keyboard → command array (hidden-network probe) | The typed SSID reaches a process argv — the only such path in this phase | Untrusted user input |
| NetworkManager → the rendered list | SSIDs and security types arrive from the air, from hardware this machine does not control, and become rendered strings and row identities | Untrusted remote strings |
| BlueZ → the rendered device list | `deviceName`, `address` and `icon` arrive over a radio from hardware nobody here controls | Untrusted remote strings |
| Panel → NetworkManager / BlueZ as unprivileged session-user D-Bus client | Radio power, connect, disconnect, pair, forget — state changes on system daemons, made from a desktop shell | Control-plane writes (polkit-mediated) |
| Panel → PipeWire / wireplumber (user session socket) | Per-stream and per-device volume/route writes, concurrent with pavucontrol, waybar, SwayOSD and cava | Control-plane writes (many-client) |
| Panel → NetworkManager's saved-profile store | `forget` destroys persisted state on the user's behalf, irreversibly from the panel's point of view | Destructive persisted state |
| Panel → `~/.cache/quickshell.log` | Anything this process writes is readable by every process running as this user for as long as the file lives | Diagnostic text (must never carry the secret) |
| XDG autostart → systemd user session | A stowed file changes which units the session generates | Session unit generation |
| Repo → fresh machine (`stow.sh`) | `stow.sh` materialises the autostart override; a fold bug would redirect unrelated future writes into the repo | Filesystem topology |
| `~/.local/state/theme/palette.json`, `motion.json` → panel surfaces | Engine-owned render targets consumed by the rim and motion system | Theme/motion values |
| `install.sh` `PACMAN_PKGS` → system | `network-manager-applet` added from the official `extra` repo | Package install |
| Third-party reference repos → scratch dir (15-01 only) | `end-4/dots-hyprland` and `caelestia-dots/shell` cloned shallow into `mktemp -d`, read only, never executed or vendored, deleted at task close | Read-only source |

---

## Threat Register

### High severity (the only tier that gates at `block_on: high`)

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-15-01 | Information Disclosure | Wifi passphrase: masked field → `WifiBackend.connect` → NetworkManager | high | mitigate | `WifiBackend.qml:35` imports no `Quickshell.Io`, so `Process` is not in scope — zero subprocesses structurally, not by discipline. Single native call site `WifiBackend.qml:367`. Residency: `WifiBackend.qml:351` is `property bool`; `WifiPanel.qml:1023-1025` clears the field before passing through; `WifiPanel.qml:463-474` is param-only. Zero `console.`/`print(`/`Qt.log`/`qDebug`/`qWarning`/`StdioCollector`/`stdout`/`stderr` in both files. Failure copy from fixed 5-string table `WifiBackend.qml:426-442`. | closed |
| T-15-12-02 | Elevation of Privilege | Bluetooth panel reaching a CLI to clear the rfkill block itself | high | mitigate | `BluetoothBackend.qml:16` imports only `Quickshell.Bluetooth` — zero `Process`; all `rfkill`/`bluetoothctl` hits (`:9`, `:51`, `:94`, `:244`) are comments. `BluetoothPanel.qml`'s sole `Process` is `:58-60 ["which","blueman-manager"]`. `rfkill` appears only at `:316` (comment) and `:401` (`ToolTip.text` literal) — never in a command array. | closed |
| T-15-13-01 | Information Disclosure | Entered passphrase during the failure-disambiguation change | high | mitigate | Only a boolean retained: `WifiBackend.qml:351` `property bool`, set at `:358` via `!!(psk && psk.length > 0)`, consumed at `:426`. Single native call site, zero `Process`, zero logging. | closed |
| T-15-13-03 | Tampering | Stowed autostart override folding `~/.config/autostart` into the repo | high | mitigate | `stow.sh:89 mkdir -p "$HOME/.config/autostart"` (rationale `:81-88`) runs **before** the stow loop at `:205-219`. Live-confirmed: `~/.config/autostart` is a real directory; `nm-applet.desktop` is a symlink into the repo. The "directory real, entry symlink" shape, not the failure shape. | closed |
| T-15-14-01 | Information Disclosure | Passphrase reaching a process command line | high | mitigate | All three `WifiPanel.qml` command arrays enumerated: `:64 ["which","nm-connection-editor"]`, `:236`/`:284 ["nmcli","device","wifi","rescan","ssid",root.hiddenSsid]`, `:506 ["nmcli","connection","modify",root.hiddenPendingSsid,"802-11-wireless.hidden","yes"]`. No secret-bearing flag in any; connect stays on the native D-Bus path. Neither `nmcli` process collects stdout/stderr. | closed |
| T-15-14-02 | Tampering | Hostile SSID reaching the directed-probe argv | high | mitigate | `WifiPanel.qml:236`/`:284`: SSID confined to a single trailing array element, never joined into a string, handed to `execve` argv via Quickshell `Process`. No `sh -c`/`bash -c` anywhere in the file. Same fixed shape at `:506`. | closed |

### Medium severity

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-15-02 | Tampering | Advanced-button and waybar `on-click` command arrays | medium | mitigate | Literal one-element arrays at `AudioPanel.qml:85`, `BluetoothPanel.qml:47`, `WifiPanel.qml:47`; single bind `PanelDialog.qml:376`, single launch `:390 startDetached()`. Waybar: 9 present `qs ipc call panel toggle <name>` literals (`modules.jsonc:152,173`; `config-athena.jsonc:322,359,374`; `config-floating.jsonc:59,78`; `config-vertical.jsonc:120,140`) + 1 removed key = the declared ten. Zero `{` format fields across those lines. | closed |
| T-15-03 | Spoofing | A second `org.freedesktop.Notifications` owner while a panel is summoned | medium | mitigate | `quickshell-doctor:657 _qsd_check_panel_notifications_single_owner()`, invoked in summoned context at `:686`; three self-test fixtures at `:1113-1124` (compliant / two-owner / zero-owner) prove it can fail both ways. | closed |
| T-15-08a | Tampering / Denial of Service | Row identity + destructive verb — acting on the wrong network | medium | mitigate | Object identity throughout: `WifiPanel.qml:726 confirmForgetNetwork === networkRow.network`, `:1071 forget(networkRow.network)` — never name-keyed. Zero `.sort(`/`localeCompare`/comparator in either file; first-seen registry `WifiBackend.qml:191+`. Confirm names the network on screen at `:1056`, commit only inside `forgetConfirmYes`. | closed |
| T-15-08b | Spoofing / Tampering | Device-supplied strings rendered by `BluetoothPanel.qml` | medium | mitigate | Four plain-text pins: `:512` (name), `:536` (standalone `ToolTip` contentItem — the unelided-name landing site), `:734` (address), `:776` (forget-confirm label). Zero `StyledText`/`RichText`/`MarkdownText`. Elide + `maximumLineCount: 1` at `:506-507`. `deviceGlyph` uses icon as lookup key only (`:156-158`). Rows keyed by `device.address` (`:442-448`). | closed |
| T-15-11-01 | Denial of Service | `Motion.qml` ambient period arithmetic (zero divisor) | medium | mitigate | Three independent guards: `Motion.qml:106 property real motion_multiplier: 1.0`; `Motion.qml:226-228` `Math.min(mult,1.0)` plus explicit `if (!(divisor > 0)) divisor = 1.0`; `theme-engine/.config/theme-engine/lib/motion.sh:129-131` `$mult > 0` gate invoked at `:214` before any write. | closed |
| T-15-11-04 | Information Disclosure | `WifiBackend.qml` gaining new state around the connect path | medium | mitigate | Zero `Process`, zero `console.`, exactly one `connectWithPsk`. All new state (`rescanInFlight`, `_rescanResultsSeen`, `connectingSuppliedPsk`) is boolean. | closed |
| T-15-12-01 | Spoofing | Tooltip copy naming a command for the user to run | medium | mitigate | `BluetoothPanel.qml:401` is a pure literal with zero interpolation, byte-identical (including double spaces) to `15-UI-SPEC.md:179`. The panel never executes it. | closed |
| T-15-13-02 | Denial of Service | Removing the only registered NM secret agent | medium | accept | See Accepted Risks Log — R-15-08. | closed |
| T-15-13-04 | Spoofing | External process presenting a credential prompt mistaken for the panel's | medium | mitigate | `quickshell/.config/autostart/nm-applet.desktop` carries `Hidden=true`. Live-confirmed: `nm-applet` not running, and `/run/user/1000/systemd/generator.late/` contains no `app-nm\x2dapplet@autostart.service`. | closed |
| T-15-14-03 | Spoofing | Mistyped SSID indistinguishable from an out-of-range network | medium | accept | See Accepted Risks Log — R-15-09. | closed |
| T-15-14-04 | Tampering | Durability follow-up mutating a persisted connection profile | medium | mitigate | `WifiPanel.qml:505-509` gated on `hiddenPendingSsid` name match, so an ordinary row's connect cannot trigger it. Single property on a single profile; fixed argv, no shell, no secret. Non-zero exit surfaces as form-scoped copy at `:384-385`. | closed |
| T-15-14-06 | Elevation of Privilege | Widening the P1 CLI exception beyond its two invocations | medium | mitigate | `WifiPanel.qml` contains exactly three `Process` objects (`:62`, `:340`, `:377`); `WifiBackend.qml` contains zero CLI references and no `Quickshell.Io` import. Fence holds on both housing and surface. | closed |

### Low severity

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-15-04 | Denial of Service | Bluetooth inquiry contending with an active A2DP stream | low | mitigate | `BluetoothPanel.qml:907` is the sole `startDiscovery()` call site repo-wide; `BluetoothBackend.qml:426-427` lifecycle stop on panel dismiss; `BluetoothPanel.qml:989` explicit stop affordance. | closed |
| T-15-05 | Elevation of Privilege / Tampering | Panel writes to NetworkManager / BlueZ as unprivileged session-user D-Bus client | low | accept | See Accepted Risks Log — R-15-01. | closed |
| T-15-06 | Tampering (multi-writer) | `AudioBackend` per-stream / per-device writes racing another PipeWire client | low | accept | See Accepted Risks Log — R-15-02. | closed |
| T-15-07 | Tampering | Fault-injection seams `WifiBackend.wifiHardwareEnabled`, `BluetoothBackend.adapter` | low | mitigate | `WifiBackend.qml:67` bound to `Networking.wifiHardwareEnabled`; `BluetoothBackend.qml:34` bound to `Bluetooth.defaultAdapter`. No literal override committed in either file. | closed |
| T-15-08c | Tampering | The `QSD_FIXTURE_*` substitution seams | low | mitigate | `quickshell-doctor:258-306` — every seam reads live when its variable is unset; a variable naming a nonexistent path is `FATAL … exit 1` (`:130`, `:134`, `:259`, `:268`, `:277`, `:291`, `:302`), never a silent fall back to live. | closed |
| T-15-09 | Denial of Service | `rfkill` fault injection + volume write in `panel-swayosd-key-ownership` | low | mitigate | `RFKILL_ORIG_*` declared pre-trap; restoration only inside `_qsd_cleanup()`, never inline; `trap … EXIT` plus `INT→exit 130` and `TERM→exit 143`; `CLEANED_UP` double-restore guard. | closed |
| T-15-SC | Tampering | `install.sh` `PACMAN_PKGS` — `network-manager-applet` install | low | mitigate | `install.sh:125`, in `PACMAN_PKGS` not `AUR_PKGS`. Live `pacman -Si`: repo `extra`, version 1.36.0-2, GNOME project upstream. Zero AUR and zero third-party packages introduced by this phase. | closed |
| T-15-10-01 | Denial of Service | `GradientBorder` `Shape` + `CurveRenderer` on three additional layer surfaces | low | accept | See Accepted Risks Log — R-15-03. | closed |
| T-15-10-02 | Tampering | `~/.local/state/theme/palette.json` as the rim's colour source | low | accept | See Accepted Risks Log — R-15-04. | closed |
| T-15-10-03 | Spoofing | Layer-shell overlay rim visually framing content | low | accept | See Accepted Risks Log — R-15-05. | closed |
| T-15-11-02 | Denial of Service | `rescan()` driving `scannerEnabled` off/on from a user press | low | mitigate | `WifiBackend.qml:156-161` ceiling watchdog bounds the in-flight window; `:90-95` lifecycle `Binding` forces the flag false on dismiss; `:182-189` dismiss clears state and stops both timers. | closed |
| T-15-11-03 | Tampering | `motion.json` engine-owned render target gaining a new key | low | accept | See Accepted Risks Log — R-15-06. | closed |
| T-15-12-03 | Denial of Service | Repeated presses re-spamming the refusing binding into the shell log | low | mitigate | `BluetoothBackend.qml:98-99` early return stops the write before it reaches the `:100` binding. | closed |
| T-15-12-04 | Tampering | An adapter reporting a state the panel does not model | low | accept | See Accepted Risks Log — R-15-07. | closed |
| T-15-13-05 | Tampering | Suppression accidentally disabling unrelated autostart entries | low | mitigate | The stow package holds exactly one file. Live-confirmed: siblings `app-blueman@autostart.service` and `app-print\x2dapplet@autostart.service` are still generated after the re-run. | closed |
| T-15-14-05 | Denial of Service | An unanswered probe leaving the form pending forever | low | mitigate | Four independent exits: `WifiPanel.qml:197-214` probe watchdog, `:190-193` `rowWatchdogTimer`, `:1403-1419` Cancel, `:244-251` panel dismiss. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-15-01 | T-15-05 | Panel writes to NetworkManager and BlueZ run as an unprivileged session-user D-Bus client — the identical trust posture nm-applet, nm-connection-editor and blueman already hold on the same bus, as the same user, mediated by the same polkit rules. This phase adds a client to a many-client service, not a new privilege: no D-Bus name is claimed and no exclusivity asserted (`client-consumer`, cardinality N, encoded by 15-09). If polkit ever refuses a write, the correct outcome is the action failing visibly, which the row-scoped failed state and D-15-26's grammar already require. `forget` — the most consequential — is gated behind Prohibition P4's inline confirm. | YahiaEng | 2026-08-08 |
| R-15-02 | T-15-06 | PipeWire is designed for concurrent multi-client read/write; pavucontrol, waybar and SwayOSD are already simultaneous writers on this host. D-22's truth-driven rendering is what makes it safe: every displayed value is a read of actual backend state, and `pending` is cleared by observed truth rather than by a write returning (`AudioBackend.qml:169-184`; no optimistic local copy at `:71`), so a competing write shows up correctly rather than being masked. The only available "mitigation" would be an exclusive claim on a many-client service — precisely the mistake the phase's `<assumption_delta_decision>` exists to prevent. | YahiaEng | 2026-08-08 |
| R-15-03 | T-15-10-01 | `HyprlandFocusGrab` is exclusive per-compositor on this build (11-QUICKSHELL-EVIDENCE Finding 2), so at most one panel surface exists at a time and each is destroyed on dismiss. At most two rims (drawer + one panel) can ever coexist. Frame cost is bounded by construction, not by tuning. | YahiaEng | 2026-08-08 |
| R-15-04 | T-15-10-02 | `~/.local/state/theme/palette.json` is already the trust model for every themed surface in the repo; this plan adds a consumer, not a new trust relationship. The file is engine-owned and covered by `theme-doctor`'s state-manifest gate. | YahiaEng | 2026-08-08 |
| R-15-05 | T-15-10-03 | The rim is decoration on a surface the user summoned. It carries no input handlers and no text, and no credential or confirmation UI is introduced by the plan that adds it. | YahiaEng | 2026-08-08 |
| R-15-06 | T-15-11-03 | `motion.json` gaining a key sits under the same trust model as every other key in that file — covered by `theme-doctor`'s D-29 state-manifest gate and `contract.json`'s `engine_owned_files`. A field is added, not a new trust relationship. | YahiaEng | 2026-08-08 |
| R-15-07 | T-15-12-04 | The adapter enum has exactly five values and the three branch predicates partition on presence, blocked and enabled. Any unmodelled transient (`Enabling`/`Disabling`) resolves to the populated branch, which is the pre-existing behaviour and is not made worse by this plan. | YahiaEng | 2026-08-08 |
| R-15-08 | T-15-13-02 | Removing the only registered NM secret agent is the user's recorded decision (D-15-4-DISPLACE). Consequence: a non-quickshell NM client needing a secret fails rather than prompts. Bounded because this repo's own wifi path supplies secrets up front, ethernet is primary, and `nm-connection-editor` remains installed (`install.sh:125`) and reachable from the panel's Advanced button (`WifiPanel.qml:47`/`:64`) as the escape hatch. Recorded in the UI-SPEC contract at `15-UI-SPEC.md:167-170`, not only in a commit message. | YahiaEng | 2026-08-08 |
| R-15-09 | T-15-14-03 | A mistyped SSID being indistinguishable from an out-of-range network is inherent to non-broadcast networks and not resolvable from the panel's position. Mitigated as far as it can be: the SSID field is deliberately unmasked (`WifiPanel.qml:1345 echoMode: TextInput.Normal`) so a typo is visible, the field stays open and populated after a not-found, and the copy at `:211` does not assert a cause it cannot know. Recorded in `15-UI-SPEC.md:128,130`. | YahiaEng | 2026-08-08 |

*Accepted risks do not resurface in future audit runs.*

---

## Unregistered Flags

Raised by the auditor during verification. None is at or above the `high` block
threshold, so none gates phase advancement. Recorded here so they are not lost.

| # | Flag | Assessment |
|---|------|------------|
| 1 | No SUMMARY contains a `## Threat Flags` section — all 14 checked, zero structured flags emitted during implementation. The register received no implementation-time additions. | Process gap, not a vulnerability. Flags 2–5 are the auditor's, not the executor's. |
| 2 | `WifiPanel.qml` has **zero `textFormat` pins**. SSIDs arrive over the air — the same untrusted-string class `T-15-08b` closed for `BluetoothPanel` — yet `:802-814` (row label), `:822` (`ToolTip.text`, the *unelided* full SSID) and `:1056` (forget-confirm) are plain `Text` with no pin, so Qt's `Text.AutoText` detection applies. No global pin exists in `Design.qml`/`Colours.qml`. | **The one substantive finding.** The 15-06 plain-text discipline was never carried back to the wifi panel. No register row covers it; if minted it would be medium — same class as T-15-08b — and therefore still below `block_on: high`. Recommend minting as a follow-up. |
| 3 | Stale in-code assertion: `WifiPanel.qml:280` says "Assigned in ONE place", but G-15-6's re-probe pulse added a second assignment site at `:236` alongside `:284`. | Comment accuracy only — the security property is identical at both sites. T-15-14-02's "assigned in one place" wording is now imprecise. |
| 4 | T-15-13-01's stated grep ("zero properties whose name carries a passphrase-shaped token") is literally contradicted by `connectingSuppliedPsk` (`WifiBackend.qml:351`). | Substance holds — it is `property bool`, not a string. A literal re-run of the plan's own grep would fail on a correctly-implemented file. The assertion, not the code, is wrong. |
| 5 | Seam count drift: `quickshell-doctor` carries **10** `QSD_FIXTURE_*` seams, not the register's six (extras are phase-11/16 overview checks). | Coverage is broader than claimed, not narrower. All 10 follow the same live-when-unset + FATAL-on-bad-path pattern. |

### Evidence caveats

Mechanism verified present in code; the behavioural proof is SUMMARY-sourced and was
not re-executed during this audit.

- **T-15-09** — `quickshell-doctor:1302-1305` states in its own comment that *this*
  script never mutates rfkill; the fault injection is driven live, outside the script.
  The restore trap is fully present and correctly ordered. The before/after
  `rfkill list` identity is 15-09-SUMMARY evidence.
- **T-15-14-02 leading-dash case** — structurally closed (execve argv, no shell).
  Whether `nmcli` itself reparses a leading-dash SSID as a flag is behavioural evidence
  from 15-14 Task 2; not re-executed here because it mutates radio state.

---

## Prior-Session Gap — Resolved

`15-VERIFICATION.md:173-176` flagged: *"No security review… wifi passphrase handling, an
autostart override that removes the system's NetworkManager secret agent, and a new
`nmcli` subprocess — a real omission."*

That gap was **procedural, not substantive**. All three named surfaces are covered by
register rows now verified CLOSED with concrete code evidence:

| Named surface | Covering rows |
|---------------|---------------|
| Wifi passphrase handling | T-15-01, T-15-13-01, T-15-14-01 |
| Autostart override / NM secret agent | T-15-13-03, T-15-13-04, T-15-13-05, R-15-08 |
| New `nmcli` subprocess | T-15-14-01, T-15-14-02, T-15-14-04, T-15-14-06 |

The omission closes with this document.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-08 | 34 | 34 | 0 | gsd-security-auditor (ASVS L1, block_on: high) |

Severity distribution: 6 high / 12 medium / 16 low. Dispositions: 25 mitigate / 9 accept.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-08
