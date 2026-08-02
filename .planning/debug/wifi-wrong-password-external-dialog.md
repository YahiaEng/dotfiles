---
status: diagnosed
trigger: "A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel."
created: 2026-08-02T00:00:00Z
updated: 2026-08-02T00:00:00Z
---

## Current Focus

bug_class: Bohrbug (deterministic — reproduces on every wrong-PSK submit while nm-applet is registered)

reasoning_checkpoint:
  hypothesis: "The external window is nm-applet's GTK secret-request dialog. NetworkManager does NOT fail an activation on a PSK mismatch — it re-enters need-auth and issues GetSecrets to the registered secret agent. nm-applet is the only registered agent, so it prompts. The panel cannot intercept because Quickshell.Networking exposes no secret-agent API."
  confirming_evidence:
    - "journal: `nm-applet[1018]: No keyring secrets found for go-jo/802-11-wireless-security; asking user.` at 18:32:30, 3s after the handshake failure"
    - "journal: `agent-manager: agent[6997708a5b36121d,:1.36/org.freedesktop.nm-applet/1000]: agent registered` — the only agent registration this boot"
    - "journal: `Activation: (wifi) psk mismatch reported by supplicant, asking for new key` then `config -> need-auth (reason 'supplicant-disconnect')` — NM re-asks, it does not fail"
    - "grep over quickshell-network.qmltypes for agent|secret returns only the NoSecrets enum value and connectWithPsk/requestConnectWithPsk — no SecretAgent type exists"
  falsification_test: "If nm-applet were not the owner, no `asking user` line would appear in its journal unit at the moment of the dialog, and NM would report a different agent identifier. Both were checked; neither holds."
  fix_rationale: "N/A — diagnose-only mode."
  blind_spots: "Not empirically measured: what NM emits when NO agent is registered at all. The fix plan must measure this before assuming removing nm-applet yields 'Wrong password' copy."
  candidate_causes:
    - "environment: nm-applet auto-registered as the NM secret agent via /etc/xdg/autostart (package side effect, never repo-configured)"
    - "code: Quickshell.Networking exposes no secret-agent registration surface, so the panel structurally cannot own secret provision"
    - "code: failReasonText maps 'Wrong password' to WifiAuthTimeout, but a real PSK mismatch resolves as NoSecrets -> 'Password required'"
  and_gate: "YES — requires BOTH the registered external agent AND the panel's inability to own secret provision. Removing nm-applet alone stops the window but does not by itself produce 'Wrong password' copy."

next_action: Return diagnosis. Do not fix.

## Symptoms

expected: A wrong password renders row-scoped "Wrong password" copy inside the wifi panel. Everything stays contained within the panel — no external window.
actual: "A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel."
errors: None reported by the user. System journal carries the full causal chain.
reproduction: Test 4 in .planning/phases/15-audio-connectivity-panels/15-UAT.md — open the wifi panel, expand a secured network, enter a deliberately wrong password, submit.
started: Discovered during UAT of phase 15 (audio-connectivity-panels)

## Eliminated

- hypothesis: "The panel fails to supply the passphrase, so NetworkManager has to ask an agent for it."
  evidence: "NM journal at 18:32:27 — `audit: op=\"connection-add-activate\" uuid=eb33a6a5 name=\"go-jo\" pid=2982672 uid=1000 result=\"success\"` where PID 2982672 IS the running quickshell process (`quickshell -p /home/aorus/.config/quickshell`), immediately followed by `connection 'go-jo' has security, and secrets exist.  No new secrets needed.` and `Config: added 'psk' value '<hidden>'`. The panel's connectWithPsk() path works correctly and supplies the PSK up front."
  timestamp: 2026-08-02

- hypothesis: "This is a z-order / layer / styling problem in QML that can be fixed by restyling or re-parenting."
  evidence: "The window belongs to a different process (nm-applet PID 1018), not to quickshell. No QML change can restyle another process's GTK dialog. The behind-ness is a downstream consequence of PanelDialog.qml:129 `WlrLayershell.layer: WlrLayer.Overlay` — a wlr-layer-shell overlay surface is unconditionally above every XDG toplevel in Hyprland."
  timestamp: 2026-08-02

- hypothesis: "A polkit authentication agent is prompting."
  evidence: "polkit-gnome-authentication-agent-1 (PID 1000) is running, but no polkit activity appears anywhere in the journal during the 18:32:27-18:32:39 window. The prompt is logged explicitly by nm-applet, and NM's own agent-manager names nm-applet as the registered agent."
  timestamp: 2026-08-02

## Evidence

- timestamp: 2026-08-02
  checked: "Registered NetworkManager secret agents (journalctl -b -u NetworkManager | grep agent)"
  found: "`agent-manager: agent[6997708a5b36121d,:1.36/org.freedesktop.nm-applet/1000]: agent registered` — exactly one agent registration line this boot, and it is nm-applet."
  implication: "nm-applet holds sole ownership of every NM secret request on this host."

- timestamp: 2026-08-02
  checked: "Process and provenance of nm-applet"
  found: "PID 1018, PPID 809 (systemd --user), unit `app-nm\\x2dapplet@autostart.service`, generated from /etc/xdg/autostart/nm-applet.desktop owned by pacman package network-manager-applet 1.36.0-2. install.sh:116 lists `network-manager-applet` in PACMAN_PKGS. No repo file starts nm-applet — grep across hypr/ finds only windowrules.lua:40 (a float rule for its window class) and a quickshell-doctor comment."
  implication: "The agent is an unmanaged side effect of a package this repo deliberately installs (added in 15-08). Nothing in the repo asked for it to run."

- timestamp: 2026-08-02
  checked: "The exact wrong-password sequence, journalctl -b --since 18:31:50 --until 18:32:45"
  found: |
    18:32:27  audit: op="connection-add-activate" name="go-jo" pid=2982672 uid=1000 result="success"   [quickshell]
    18:32:27  Activation: (wifi) connection 'go-jo' has security, and secrets exist.  No new secrets needed.
    18:32:27  Config: added 'psk' value '<hidden>'
    18:32:28  supplicant interface state: associated -> 4way_handshake
    18:32:30  kernel: wlan0: deauthenticated (Reason: 15=4WAY_HANDSHAKE_TIMEOUT)
    18:32:30  wpa_supplicant: WPA: 4-Way Handshake failed - pre-shared key may be incorrect
    18:32:30  NM: Activation: (wifi) psk mismatch reported by supplicant, asking for new key
    18:32:30  NM: state change: config -> need-auth (reason 'supplicant-disconnect')
    18:32:30  nm-applet[1018]: No keyring secrets found for go-jo/802-11-wireless-security; asking user.
    18:32:30+ nm-applet[1018]: gtk_widget_get_scale_factor assertions (x7, dialog construction)
    18:32:39  NM: no secrets: User canceled the secrets request.
    18:32:39  NM: state change: need-auth -> failed (reason 'no-secrets')
    18:32:39  NM: Activation: failed for connection 'go-jo'
  implication: "Definitive window ownership: nm-applet (PID 1018). The 9-second gap between `asking user` and `User canceled` is the dialog being on screen. NetworkManager never failed the activation on the PSK mismatch — it parked in need-auth and delegated to the agent."

- timestamp: 2026-08-02
  checked: "Quickshell.Networking API surface for secret-agent registration (/usr/lib/qt6/qml/Quickshell/Networking/quickshell-network.qmltypes)"
  found: "grep -inE 'agent|secret|psk|passphrase' returns 4 hits total: the `NoSecrets` enum value, `requestConnectWithPsk`, `connectWithPsk`, and Wpa2Psk/WpaPsk security types. No SecretAgent type, no AgentManager binding, no GetSecrets handler exists in the module."
  implication: "The panel cannot register itself as the NetworkManager secret agent through the module it uses. This is a hard structural constraint of quickshell 0.3.0-2, not an oversight in the panel code."

- timestamp: 2026-08-02
  checked: "Layer assignment of the panel (PanelDialog.qml:128-131)"
  found: "`exclusionMode: ExclusionMode.Normal`, `WlrLayershell.layer: WlrLayer.Overlay`, `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand`. hyprctl layers confirms level 3 (overlay) is where quickshell surfaces mount."
  implication: "Any XDG toplevel — including nm-applet's dialog and the windowrules.lua:40 float rule that targets it — is unconditionally below the open panel. 'Rendered behind' is a guaranteed consequence of the panel's layer, not an independent bug."

- timestamp: 2026-08-02
  checked: "Failure-copy path: WifiBackend.qml:310-325 failReasonText(), WifiPanel.qml:236-250 onConnectFailed"
  found: "'Wrong password' is mapped to ConnectionFailReason.WifiAuthTimeout only. The failure NM actually emitted was reason 'no-secrets' -> ConnectionFailReason.NoSecrets -> 'Password required'. WifiPanel.qml:249 additionally RE-EXPANDS the password row on NoSecrets. The row watchdog is 15000ms and the failure arrived at ~12s, so the panel's handler did run — with the wrong copy."
  implication: "Second, independent finding: even with the external agent gone, a real PSK mismatch does not obviously route to WifiAuthTimeout. The 'Wrong password' string may be unreachable on this NM/quickshell combination. The fix must verify which enum a wrong PSK actually produces, not assume."

## Resolution

root_cause: |
  AND-gate, two simultaneously-required contributing causes:

  (1) [environment] nm-applet is registered as the sole NetworkManager secret agent
      (`agent[:1.36/org.freedesktop.nm-applet/1000]: agent registered`). It is autostarted
      by /etc/xdg/autostart/nm-applet.desktop shipped with network-manager-applet, which
      install.sh:116 installs. On a PSK mismatch NetworkManager does not fail the
      activation — it logs `psk mismatch reported by supplicant, asking for new key`,
      re-enters need-auth, and issues GetSecrets to that agent. nm-applet answers with its
      own GTK3 dialog (`No keyring secrets found for go-jo/802-11-wireless-security;
      asking user.`). That dialog is the external window; it is an ordinary XDG toplevel and
      therefore renders below the panel's WlrLayer.Overlay surface (PanelDialog.qml:129).

  (2) [code] The panel structurally cannot intercept that request: Quickshell.Networking
      (quickshell 0.3.0-2) exposes no secret-agent API whatsoever — only
      connectWithPsk/requestConnectWithPsk on a network object. Supplying the PSK up front
      (which the panel does correctly, proven by pid=2982672 in NM's audit log) is not
      sufficient, because NM re-asks after the handshake fails rather than reporting failure.

  Consequence: the panel's connectFailed never fires with WifiAuthTimeout. It only fires
  once the user dismisses nm-applet's dialog, with reason 'no-secrets' -> NoSecrets ->
  "Password required" — the wrong copy — and WifiPanel.qml:249 then re-expands the row.

fix: [not applied — diagnose-only mode]
verification: [n/a]
files_changed: []
