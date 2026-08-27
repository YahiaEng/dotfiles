# 260827-np1 — measured ground truth (2026-08-27)

Every number below came from a command on this host, not from inference.

## 1. The tooling does not exist yet

| Capability | Package | State | Repo | Size |
|---|---|---|---|---|
| Virus scan | `clamav` | **NOT INSTALLED** | extra 1.5.3-1 | 30.65 MiB |
| CVE audit | `arch-audit` | **NOT INSTALLED** | extra 0.2.0-5 | 1.9 MiB |
| Rootkit scan | `rkhunter` | **NOT INSTALLED** | extra 1.4.6-4 | 230 KiB |
| Hardening audit | `lynis` | **NOT INSTALLED** | extra 3.1.7-1 | 262 KiB |
| Disk health | `smartmontools` | installed 7.5-1 | — | — |
| Sensors | `lm_sensors` | installed 1:3.6.2-1 | — | — |
| Packet filter | `nftables` | installed 1:1.1.6-3 | — | — |

All four missing packages are in **official `extra`** — pacman, no AUR. `install.sh`
additions only. Nothing here needs an AUR helper.

**Design consequence:** "tool absent" is a FIRST-CLASS STATE, not an error path. On a
fresh install (the project's reproducibility constraint) every scanner tile starts
absent. A design that only draws clean/threat is wrong on day one.

## 2. SMART needs root; sensors do not

    $ smartctl -H /dev/nvme0   ->  Permission denied
    $ smartctl -H /dev/sda     ->  Permission denied
    $ smartctl --scan          ->  works (3 devices)
    $ sensors                  ->  works, full output

Devices: `sda` 1.8T SATA HDD (ST2000DM008), `nvme0n1` 3.6T + `nvme1n1` 1.8T
(WD_BLACK SN850X). Live temps read unprivileged: k10temp Tctl +53.9C,
nvme Composite +50.9C (crit +93.8C), r8169 +50.5C.

Two privilege paths exist, both already precedented here:
- `polkit-gnome-authentication-agent-1` is ALREADY autostarted
  (`hypr/.config/hypr/config/autostart.lua:191`) -> `pkexec` pops a real GUI prompt.
- `smartd.service` ships with smartmontools and is **disabled**; enabling it via
  `install.sh` puts SMART in the journal with ZERO runtime privilege in the shell.

## 3. No host firewall is active

    systemctl is-enabled nftables  -> disabled
    systemctl is-enabled iptables  -> disabled
    firewalld / ufw                -> not-found (not installed)
    nft list ruleset               -> only Docker's own `table ip nat` chains

The only ruleset present was created by Docker. **The host is unfirewalled today.**
This is a genuine finding the pane reports on first open, not a hypothetical.

## 4. Palette has `error` but no severity ramp

`modules/Colours.qml` exposes **19 roles**, every one `property string`:
primary, primaryContainer, secondary, secondaryContainer, tertiary, surface,
surfaceVariant, background, outline, error + the nine `on*` counterparts.

There is **no `warning`, no `success`, no severity ramp**. A CVE list needs
critical/high/medium/low; an AV verdict needs clean/threat. Those four-to-five steps
must be DERIVED (`Qt.tint`/`Qt.alpha` over error/tertiary/primary), never invented as
literals -- `colour-lint` rejects hardcoded colours in QML.

**Repeat trap (b52 finding #1):** the roles are `property string`, so `.r/.g/.b` are
`undefined` and `Qt.rgba(role.r, ...)` renders **pure black** at the right alpha.

## 5. A real scan outlives the page that started it  <- the sharp one

`UpdatesPage.qml`'s own header states the rule:

> "a page is destroyed when the user navigates away (`Pages.qml:_swapTo` destroys
> before incubating the next), so a page-scoped Process's lifetime is naturally
> capped."

Every existing probe is SHORT -- `checkupdates`, `paru -Qua`, both sub-second. A
`clamscan` over a home directory runs for MINUTES. A page-scoped `Process` is killed
the instant the user navigates away, mid-scan.

This is the same class as the standing launcher rule: work that must outlive its
surface belongs on a **singleton** (or `Quickshell.execDetached`), never on a
component-scoped `Process`.

**Design consequence:** the Security Center is the first surface here that needs
progress, cancel, and survive-navigation. That is an architecture requirement the
layout has to express -- a scan must be visible as RUNNING from somewhere other than
the page that launched it.

## 6. Geometry to author against

- Settings pages cap content at **800px** (`PageBase.qml:46`, `Math.min(800, ...)`).
- Dashboard drawer floor is **760px** (`Design.qml:891 dashboardMinWidth`).
- Spacing 4/8/16/24/32; settings fonts title 24 / row 18 / sub 14; icon 28.

## 7. The structural analog already exists

`modules/settings/pages/UpdatesPage.qml` is the closest working precedent:
page-scoped `Process` children, a `_loading` gate that waits for BOTH probes,
per-record parsing with a never-drop-a-line fallback, and defensive exit handling
("ANY non-zero exit degrades to nothing-pending, never a distinct error state").
Reusable shell: `PageBase`, `SettingsSection`, `InfoRow`, `NavRow`, `ToggleRow`,
`SelectRow`, `StackPage`.
