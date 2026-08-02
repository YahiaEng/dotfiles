---
plan: 15-13
phase: 15-audio-connectivity-panels
gap_closure: true
closes_gap: G-15-4
requirements: [PANEL-03]
status: complete
completed: 2026-08-02
---

# 15-13 — Wrong wifi password opened an external dialog (G-15-4)

## What was built

**Task 1 (`4ad6b39`) — the ownership half.** nm-applet was the sole registered
NetworkManager secret agent for the whole boot. On a wrong passphrase NM does not fail the
activation — it re-enters `need-auth` and issues `GetSecrets` to that agent, which answers
with its own GTK toplevel. A layer-shell overlay sits unconditionally above every XDG
toplevel in Hyprland, so no QML change could ever have won that z-order fight; removing the
agent is the only fix.

A minimal stowed XDG override now sits at `quickshell/.config/autostart/nm-applet.desktop`
(`Hidden=true`), housed in the `quickshell` package because the wifi panel is what took over
the responsibility — and so it needs no new `PACKAGES` entry. `stow.sh` gained the
`~/.config/autostart` fold guard, and its audit note was corrected: the standing claim that
"every OTHER package ships exclusively under `~/.config/<pkg>/`" had quietly become false.
`install.sh` records that the package is deliberately retained for `nm-connection-editor`
while only its agent is suppressed.

**Task 2 (`6ad2631`) — the second, independent defect underneath the dialog.** `NoSecrets`
carries two meanings and NM cannot tell them apart. `WifiBackend` gained
`connectingSuppliedPsk`, a plain boolean recording only *whether* a passphrase was supplied,
cleared on success, cancel and failure. `failReasonText()` takes it as an optional second
parameter with a falsy default, branching `NoSecrets` into the rejected-passphrase copy vs.
the request copy. `WifiPanel`'s re-expand branch now passes `false` explicitly, so a rejected
passphrase no longer re-opens the field as though none had been typed.

**Task 3 — spec.** The `NoSecrets` row is superseded in place with the disambiguator, the
environmental precondition naming the override file, and an explicit record of what was not
measured.

## Deviations

- **Comment wording adjusted twice to satisfy the plans' own negative greps** — both
  `BluetoothPanel` (15-12) and `WifiPanel` gate on the whole file including comments, and
  explanatory prose that *named* a forbidden string tripped them. Shipped copy unaffected.
- **A duplicate quickshell instance was spawned and killed.** The detached restart left two
  processes (the pre-edit one from 20:18 and the new one); the older was killed, leaving
  exactly one. Flagging because a stale second instance is the failure mode recorded in
  STATE.md/14-06.
- **`~/.config/autostart` folded on first restow.** I ran `stow --restow quickshell`
  directly, bypassing the new `mkdir -p` guard, and stow symlinked the whole directory into
  the repo — the exact bug the guard exists to prevent. Unfolded, made real, restowed, and
  re-verified. The guard itself is correct; this proves the hazard is live.

## Verification

**Ran and passed:**
- Generator re-run drops `app-nm\x2dapplet@autostart.service` while both sibling units
  (`blueman`, `print-applet`) are still generated — the suppression is selective, not blunt.
- `~/.config/autostart` is a **real directory** holding a **symlink into the repo** (the two
  are distinguished, since the failure mode is the directory itself being the symlink).
- nm-applet process stopped; ethernet (`Fiber:eno1`) and wifi (`go-jo:wlan0`) both still up.
- `bash -n` on both `stow.sh` and `install.sh`; `quickshell` package symlinks intact.
- Exactly one native `connectWithPsk` call site; no passphrase stored in any property; the
  panel restates none of the five locked strings; the enum stringifier is never rendered.
- Shell restarted detached, config loaded with **no QML errors**, wifi panel summons and
  mounts exactly one `quickshell-wifi-panel` layer. `motion-lint` 107/0.

**NOT run — this is the material gap in this plan.** At the user's explicit instruction to
finish quickly, Task 2's **entire Step One measurement was skipped**. That step was the point
of the task, not preamble:

- **The raw failure enum reaching `connectionFailed` with no agent registered is unmeasured.**
  The recorded blind spot was precisely "what does NM emit with no agent at all", and the
  mapping is now wired to a *reasoned* answer rather than an observed one. The implementation
  is written to be correct for either candidate, but that is an argument, not evidence.
- **The failure latency is unmeasured, and this is the one that can still leave G-15-4 open.**
  If NM's failure now lands at or past the panel's 15000 ms row watchdog, the row clears
  before the copy arrives and the user still sees nothing. The plan called this out as a
  possible third defect owned by this task. It is untested.
- No wrong-PSK connect was driven through the real UI path, so **no external window was
  proven absent**, and the correct-password path was not re-confirmed.
- No connection-list baseline/diff was taken (no stray profile check).

**Task 1's `<human-check>` also remains outstanding** and cannot be discharged unattended: a
logout/login or reboot is the only thing that proves the suppression survives a real session
start rather than only a `daemon-reload`.

G-15-4 is therefore **source-verified and partially runtime-verified** — the agent removal is
proven live, the copy path is not.

## Key files

- `quickshell/.config/autostart/nm-applet.desktop` (new)
- `stow.sh`, `install.sh`
- `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml`
- `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml`
- `.planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md`

## Commits

- `4ad6b39` feat(15-13): suppress the autostarted NetworkManager secret agent under stow
- `6ad2631` feat(15-13): disambiguate the no-secrets failure so the rejected-passphrase copy is reachable
- (this commit) docs(15-13): lock the disambiguator in the spec, record what was not measured
