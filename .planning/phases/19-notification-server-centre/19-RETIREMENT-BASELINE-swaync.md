---
phase: 19-notification-server-centre
plan: 08
artifact: retirement-baseline
surface: swaync
captured: 2026-08-13
captured_at_commit: 45e2d7f1f1ff510bd2a191abb074a17f39518879
command: "retirement-check swaync"
---

# Swaync Pre-Deletion Retirement Baseline

This is the complete, verbatim output of `retirement-check swaync` captured against
commit `45e2d7f1f1ff510bd2a191abb074a17f39518879` — swaync's registry row is still
`pending` at capture time (per D-18-34/D-18-37, every real surface ships `pending`
until its own deletion plan flips the row in the same commit as the removal). Every
blocking-domain class below therefore reads `[REPORT]`, not `[PASS]`/`[FAIL]` — this
document is the "before" half of RETIRE-01's twice-run gate, mirroring
`18-RETIREMENT-BASELINE-waybar.md`'s own shape and the same discipline: a baseline
that already reads zero would mean the checklist is not looking where the surface
actually is, and that is a finding to stop on, not a pass.

Task 5 of this plan re-runs the identical command (`retirement-check swaync`, no
`--root`) after deleting swaync's own tree, its stow registrations, and every
layer/autostart/keybind/contract/matugen/checker-internals reference — and records
that "after" run at `19-RETIREMENT-AFTER-swaync.md`, requiring every blocking-domain
class to reach zero (or the architecturally-correct `[SKIP]` an own-tree class reaches
once its own tree is genuinely gone, per Phase 18's own precedent).

## Summary (per-class totals at capture time)

| # | Class | Domain | Reference count |
|---|-------|--------|-----------------:|
| 1 | own-tree | blocking | 20 |
| 2 | layer-window-rules | blocking | 4 |
| 3 | autostart | blocking | 1 |
| 4 | keybinds | blocking | 0 |
| 5 | contract-json | blocking | 2 |
| 6 | matugen-templates | blocking | 5 |
| 7 | checker-internals | blocking | 7 |
| 8 | test-fixtures | blocking | 15 |
| 9 | cross-package-refs | blocking | 37 |
| 10 | install-stow-lists | blocking | 18 |
| 11 | systemd-units | blocking | 4 |
| 12 | dbus-activation | blocking | 2 |
| 13 | xdg-autostart | blocking | 0 |
| 14 | host-package | blocking | 1 |
| 15 | planning-archive | report | 1599 |
| 16 | repo-prose | report | 13 |

`retirement-check swaync` exits 0 (`failed_classes=0`) — expected, since a `pending`
surface's blocking-domain classes are `[REPORT]`, never `[FAIL]`; the checklist's
pass/fail verdict only activates once a surface's registry row reads `retired`.

Notable rows for this plan's own closing work:

- **Class 4 (`keybinds`) is 0**, not because swaync has no keybind — `Super+N` is
  bound to it via `hl.dsp.exec_cmd("swaync-client -t -sw")` in `keybinds.lua` — but
  because `19-06` already repointed that bind onto the shell's own `GlobalShortcut`
  before this baseline was taken. That repoint is prior-plan work, correctly absent
  here.
- **Class 6 (`matugen-templates`) is 5**, not the `swaync-colors.css` template's own 1
  reference: the four `config.toml` hits are the `[templates.swaync]` block itself,
  and the fifth (`swayosd-colors.css:3`) is a token-boundary false-positive — a
  comment inside the *swayosd* template mentioning "swaync" in prose, matched because
  `retirement-check`'s own word-boundary grep has no way to distinguish a substring
  mention from a real reference. Recorded here, not silently dropped: Task 5's deletion
  touches only the four `config.toml` lines and the `swaync-colors.css` file itself;
  this fifth prose mention in an unrelated file is out of this plan's declared scope.
- **Class 11 (`systemd-units`) includes `quickshell.service`**, twice — this is the
  service's own header comment, which narrates swaync's autostart history as prose
  (`"the wallpaper daemon, the (now retired) bar, ... quickshell (until this plan),
  swaync, ..."`) — not a functional reference. Left for Task 5's own scope, since
  `quickshell.service` is not in this plan's declared `files_modified`.
- **Class 12 (`dbus-activation`) is 2** — `org.erikreider.swaync.service` and
  `org.erikreider.swaync.cc.service`, both packaged under
  `/usr/share/dbus-1/services/`. The first of these is the mechanism this plan's own
  live single-owner proof (Task 1) has to work around: it declares
  `Name=org.freedesktop.Notifications` with `SystemdService=swaync.service`, meaning
  the notification bus name itself is D-Bus-activatable back onto swaync for as long
  as the package remains installed — confirmed directly on this host
  (`cat /usr/share/dbus-1/services/org.erikreider.swaync.service`). Both files are
  removed by Task 5's `pacman -R swaync`, not by any repo edit.

## Verbatim output

```
retirement-check — surface=swaync status=pending root=/home/aorus/dotfiles

[REPORT] swaync/own-tree: 20 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:18
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:2
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:21
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:27
    /home/aorus/dotfiles/swaync/.config/swaync/config.json:2
    /home/aorus/dotfiles/swaync/.config/swaync/config.json:67
    /home/aorus/dotfiles/swaync/.config/swaync/config.json:68
    /home/aorus/dotfiles/swaync/.config/swaync/style.scss:2
    /home/aorus/dotfiles/swaync/.config/swaync/style.scss:6
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:1
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:12
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:14
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:15
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:19
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:3
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:31
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:5
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf:9
[REPORT] swaync/layer-window-rules: 4 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:224
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:225
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:402
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:403
[REPORT] swaync/autostart: 1 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/autostart.lua:140
[REPORT] swaync/keybinds: 0 reference(s)
[REPORT] swaync/contract-json: 2 reference(s)
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:24
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:4
[REPORT] swaync/matugen-templates: 5 reference(s)
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:38
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:39
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:40
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:41
    /home/aorus/dotfiles/matugen/.config/matugen/templates/swayosd-colors.css:3
[REPORT] swaync/checker-internals: 7 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:1153
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:391
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:404
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:351
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:356
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:345
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:370
[REPORT] swaync/test-fixtures: 15 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:102
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:103
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:104
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:114
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:115
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:116
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:126
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:34
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:36
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:38
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:42
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:44
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/notif-fault-inject:7
[REPORT] swaync/cross-package-refs: 37 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hypr-lua-harness:50
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:18
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:2
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:21
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:27
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:436
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:77
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:78
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:79
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:80
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:85
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:89
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:90
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:92
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:94
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:148
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:31
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:416
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/ToggleState.qml:109
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/ToggleState.qml:222
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/ToggleState.qml:48
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/ToggleState.qml:80
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/notifications/NotifCard.qml:29
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/notifications/NotifData.qml:70
    /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:874
    /home/aorus/dotfiles/quickshell/.config/systemd/user/quickshell.service:11
    /home/aorus/dotfiles/quickshell/.config/systemd/user/quickshell.service:5
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/gtk.sh:311
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:590
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:32
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:38
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:7
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:82
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:87
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:88
[REPORT] swaync/install-stow-lists: 18 reference(s)
    /home/aorus/dotfiles/install.sh:169
    /home/aorus/dotfiles/stow.sh:102
    /home/aorus/dotfiles/stow.sh:105
    /home/aorus/dotfiles/stow.sh:107
    /home/aorus/dotfiles/stow.sh:112
    /home/aorus/dotfiles/stow.sh:113
    /home/aorus/dotfiles/stow.sh:223
    /home/aorus/dotfiles/stow.sh:29
    /home/aorus/dotfiles/stow.sh:427
    /home/aorus/dotfiles/stow.sh:428
    /home/aorus/dotfiles/stow.sh:432
    /home/aorus/dotfiles/stow.sh:434
    /home/aorus/dotfiles/stow.sh:446
    /home/aorus/dotfiles/stow.sh:464
    /home/aorus/dotfiles/stow.sh:468
    /home/aorus/dotfiles/stow.sh:473
    /home/aorus/dotfiles/stow.sh:90
    /home/aorus/dotfiles/stow.sh:94
[REPORT] swaync/systemd-units: 4 reference(s)
    /home/aorus/dotfiles/quickshell/.config/systemd/user/quickshell.service:11
    /home/aorus/dotfiles/quickshell/.config/systemd/user/quickshell.service:5
    /home/aorus/dotfiles/swaync/.config/systemd/user/swaync.service.d/override.conf
    systemctl --user list-unit-files: swaync.service                                                              disabled  enabled
[REPORT] swaync/dbus-activation: 2 reference(s)
    /usr/share/dbus-1/services/org.erikreider.swaync.cc.service
    /usr/share/dbus-1/services/org.erikreider.swaync.service
[REPORT] swaync/xdg-autostart: 0 reference(s)
[REPORT] swaync/host-package: 1 reference(s)
    pacman -Q swaync: swaync 0.12.6-1
[REPORT] swaync/planning-archive: 1599 reference(s)
[REPORT] swaync/repo-prose: 13 reference(s)

Summary: surface=swaync status=pending failed_classes=0
```

## Feeds

Task 5 of this plan (RETIRE-03) re-runs `retirement-check swaync` after the deletion
and the registry-row flip, recording the result at `19-RETIREMENT-AFTER-swaync.md`,
which must read every blocking-domain class at `[PASS]` (zero references) or the
architecturally-correct `[SKIP]` an own-tree class reaches once the tree is genuinely
gone — matching `18-RETIREMENT-AFTER-waybar.md`'s own precedent.
