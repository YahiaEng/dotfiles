---
phase: 18-qml-bar-retirement-machinery
plan: 06
artifact: retirement-baseline
surface: waybar
captured: 2026-08-11
captured_at_commit: 77393f8d349bd65081881fa39689b9e21c5a7bb7
command: "retirement-check waybar"
---

# Waybar Pre-Deletion Retirement Baseline

This is the complete, verbatim output of `retirement-check waybar` captured
against commit `77393f8d349bd65081881fa39689b9e21c5a7bb7` — waybar's registry row is still `pending` at
capture time (this plan ships every real surface `pending`; RETIRE-02 flips
waybar to `retired` in 18-20, in the same commit as the deletion). Every
blocking-domain class below therefore reads `[REPORT]`, not `[PASS]`/`[FAIL]`
— this document is the "before" half of RETIRE-01's twice-run gate.

**18-20 re-runs the identical command** (`retirement-check waybar`, no
`--root`) after deleting waybar's own tree, its stow registrations, and
every layer/autostart/keybind/contract/matugen/checker-internals reference —
and requires every one of the fourteen blocking-domain classes below to
reach zero (`[PASS]`, once the registry row reads `retired`).

## Summary (per-class totals at capture time)

| # | Class | Domain | Reference count |
|---|-------|--------|-----------------:|
| 1 | own-tree | blocking | 204 |
| 2 | layer-window-rules | blocking | 2 |
| 3 | autostart | blocking | 2 |
| 4 | keybinds | blocking | 2 |
| 5 | contract-json | blocking | 9 |
| 6 | matugen-templates | blocking | 5 |
| 7 | checker-internals | blocking | 59 |
| 8 | test-fixtures | blocking | 18 |
| 9 | cross-package-refs | blocking | 217 |
| 10 | install-stow-lists | blocking | 22 |
| 11 | systemd-units | blocking | 5 |
| 12 | dbus-activation | blocking | 0 |
| 13 | xdg-autostart | blocking | 0 |
| 14 | host-package | blocking | 1 |
| 15 | planning-archive | report | 4554 |
| 16 | repo-prose | report | 46 |

Note on row 15: this document's own presence under `.planning/` (its front
matter, summary table and verbatim block below all repeat the word
"waybar" hundreds of times as part of quoted file paths) is itself counted
by `planning-archive` from the moment this file is committed — the count
above already reflects that self-inclusion, captured as the converged
fixed point of "run, embed, re-run, confirm unchanged" rather than a
pre-commit snapshot that would immediately go stale. All fourteen
blocking-domain classes carry `pending`-tier `[REPORT]` lines today,
matching the plan's Measured ground truth table (2 layer rules, 2
autostart, 9 contract entries). Report-domain classes never influence
18-20's pass/fail verdict — they are shipped-milestone-archive and
documentation mentions that legitimately never reach zero.

## Verbatim output

```
retirement-check — surface=waybar status=pending root=/home/aorus/dotfiles

[REPORT] waybar/own-tree: 204 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:107
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:199
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:202
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:205
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:214
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:215
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:222
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:226
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:233
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:258
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:264
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:266
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:271
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:275
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:277
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:4
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:46
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:51
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:53
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:70
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:74
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:13
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:147
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:16
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:171
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:178
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:190
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:205
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:21
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:228
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:254
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:267
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:27
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:32
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:5
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:55
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:56
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:59
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:62
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:9
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:23
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:6
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:8
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:2
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:27
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:29
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:47
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:5
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:56
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:59
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:61
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:62
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:63
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:66
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:67
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:100
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:103
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:106
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:107
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:113
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:114
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:117
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:118
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:122
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:132
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:16
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:17
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:24
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:25
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:5
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:53
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:54
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:75
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:79
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:101
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:105
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:161
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:177
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:258
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:261
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:262
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:266
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:311
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:32
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:320
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:330
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:35
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:38
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:4
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:40
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:67
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:93
    /home/aorus/dotfiles/waybar/.config/waybar/bar-common.jsonc:12
    /home/aorus/dotfiles/waybar/.config/waybar/bar-common.jsonc:15
    /home/aorus/dotfiles/waybar/.config/waybar/bar-common.jsonc:18
    /home/aorus/dotfiles/waybar/.config/waybar/bar-common.jsonc:28
    /home/aorus/dotfiles/waybar/.config/waybar/bar-common.jsonc:3
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:101
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:113
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:28
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:384
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:4
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:6
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:93
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:98
    /home/aorus/dotfiles/waybar/.config/waybar/config-athena.jsonc:99
    /home/aorus/dotfiles/waybar/.config/waybar/config-floating.jsonc:111
    /home/aorus/dotfiles/waybar/.config/waybar/config-floating.jsonc:113
    /home/aorus/dotfiles/waybar/.config/waybar/config-floating.jsonc:114
    /home/aorus/dotfiles/waybar/.config/waybar/config-floating.jsonc:116
    /home/aorus/dotfiles/waybar/.config/waybar/config-floating.jsonc:117
    /home/aorus/dotfiles/waybar/.config/waybar/config-floating.jsonc:32
    /home/aorus/dotfiles/waybar/.config/waybar/config-full.jsonc:27
    /home/aorus/dotfiles/waybar/.config/waybar/config-vertical.jsonc:166
    /home/aorus/dotfiles/waybar/.config/waybar/config-vertical.jsonc:225
    /home/aorus/dotfiles/waybar/.config/waybar/config-vertical.jsonc:7
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:188
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:192
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:193
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:202
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:236
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:242
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:315
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:316
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:317
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:63
    /home/aorus/dotfiles/waybar/.config/waybar/modules.jsonc:7
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:10
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:15
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:158
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:194
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:2
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:215
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:218
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:298
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:3
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:310
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:32
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:361
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:379
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:4
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:43
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:45
    /home/aorus/dotfiles/waybar/.config/waybar/style-athena.scss:7
    /home/aorus/dotfiles/waybar/.config/waybar/style-floating.scss:19
    /home/aorus/dotfiles/waybar/.config/waybar/style-floating.scss:20
    /home/aorus/dotfiles/waybar/.config/waybar/style-floating.scss:21
    /home/aorus/dotfiles/waybar/.config/waybar/style-floating.scss:24
    /home/aorus/dotfiles/waybar/.config/waybar/style-floating.scss:36
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:10
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:19
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:2
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:24
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:3
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:4
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:41
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:52
    /home/aorus/dotfiles/waybar/.config/waybar/style-full.scss:7
    /home/aorus/dotfiles/waybar/.config/waybar/style-vertical.scss:15
    /home/aorus/dotfiles/waybar/.config/waybar/style-vertical.scss:16
    /home/aorus/dotfiles/waybar/.config/waybar/style-vertical.scss:17
    /home/aorus/dotfiles/waybar/.config/waybar/style-vertical.scss:20
    /home/aorus/dotfiles/waybar/.config/waybar/style-vertical.scss:32
    /home/aorus/dotfiles/waybar/.config/waybar/style-vertical.scss:41
    /home/aorus/dotfiles/waybar/.config/waybar/theme.scss:148
    /home/aorus/dotfiles/waybar/.config/waybar/theme.scss:4
    /home/aorus/dotfiles/waybar/.config/waybar/theme.scss:40
    /home/aorus/dotfiles/waybar/.config/waybar/theme.scss:7
    /home/aorus/dotfiles/waybar/.config/waybar/theme.scss:9
    /home/aorus/dotfiles/waybar/.config/waybar/waybar-modules.scss:187
    /home/aorus/dotfiles/waybar/.config/waybar/waybar-modules.scss:190
    /home/aorus/dotfiles/waybar/.config/waybar/waybar-modules.scss:198
    /home/aorus/dotfiles/waybar/.config/waybar/waybar-modules.scss:220
    /home/aorus/dotfiles/waybar/.config/waybar/waybar-modules.scss:4
[REPORT] waybar/layer-window-rules: 2 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:222
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:401
[REPORT] waybar/autostart: 2 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/autostart.lua:42
    /home/aorus/dotfiles/hypr/.config/hypr/config/autostart.lua:48
[REPORT] waybar/keybinds: 2 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:102
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:107
[REPORT] waybar/contract-json: 9 reference(s)
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:26
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:27
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:28
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:29
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:3
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:30
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:31
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:34
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:43
[REPORT] waybar/matugen-templates: 5 reference(s)
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:33
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:34
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:35
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:36
    /home/aorus/dotfiles/matugen/.config/matugen/templates/swayosd-colors.css:3
[REPORT] waybar/checker-internals: 59 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hypr-equivalence-check:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hypr-equivalence-check:38
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hypr-equivalence-check:6
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:1153
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:121
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:400
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:401
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:403
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:1520
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:190
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:9
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:343
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:345
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:346
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:347
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:348
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:350
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:361
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:364
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:367
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:466
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:467
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:472
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:484
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:486
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:487
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:529
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:543
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:637
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:638
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:640
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:642
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:650
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:653
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:654
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:656
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:660
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:667
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:669
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:678
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:682
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:686
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:690
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:74
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:741
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:771
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:787
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:354
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:356
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:359
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:379
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:380
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-parity:381
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:238
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:244
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:255
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:286
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:300
[REPORT] waybar/test-fixtures: 18 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-mpvpaper-layers.json:38
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-panel-layers.json:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-mpvpaper-layers.json:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-panel-layers.json:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-panel-layers.json:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-unknown-namespace-layers.json:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:143
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:146
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:156
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:159
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:169
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:174
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:181
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:184
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:27
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:6
[REPORT] waybar/cross-package-refs: 217 reference(s)
    /home/aorus/dotfiles/ags/.config/ags/widget/MediaWindow.tsx:16
    /home/aorus/dotfiles/ags/.config/ags/widget/MediaWindow.tsx:44
    /home/aorus/dotfiles/elephant/.config/elephant/menus/settings.toml:30
    /home/aorus/dotfiles/elephant/.config/elephant/menus/settings.toml:31
    /home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf:12
    /home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf:40
    /home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf:43
    /home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf:53
    /home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf:54
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/colour-lint:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/colour-lint:134
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/font-switcher.sh:20
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/font-switcher.sh:252
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/font-switcher.sh:253
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:144
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:148
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:235
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:239
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:255
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:263
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:52
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:53
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:54
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:55
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:56
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/gaming-mode-toggle.sh:61
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hypr-lua-harness:50
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hyprpm-complete.sh:81
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/hyprpm-complete.sh:88
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-launch.sh:4
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-launch.sh:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/record-toggle.sh:20
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/record-toggle.sh:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/record-toggle.sh:32
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:24
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/swaync-launch.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:19
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:323
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:38
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:71
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:79
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:85
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wallpaper-visibility.sh:86
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:107
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:199
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:202
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:205
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:214
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:215
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:222
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:226
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:233
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:258
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:264
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:266
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:271
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:275
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:277
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:4
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:46
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:51
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:53
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:70
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-design-lint:74
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:13
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:147
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:16
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:171
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:178
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:190
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:205
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:21
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:228
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:254
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:267
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:27
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:32
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:5
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:55
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:56
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:59
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:62
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-equivalence-check:9
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:23
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:6
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh:8
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:15
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:2
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:27
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:29
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:47
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:5
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:56
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:59
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:61
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:62
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:63
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:66
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-launch.sh:67
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:100
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:103
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:106
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:107
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:113
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:114
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:117
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:118
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:122
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:132
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:16
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:17
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:24
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:25
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:5
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:53
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:54
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:75
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-switch.sh:79
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:101
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:105
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:14
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:161
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:177
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:22
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:258
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:26
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:261
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:262
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:266
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:28
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:311
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:32
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:320
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:33
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:330
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:35
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:38
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:4
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:40
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:45
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:67
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:7
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/waybar-visibility.sh:93
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:195
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:196
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:22
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:74
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:88
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:96
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml:416
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/Design.qml:128
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/Design.qml:141
    /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:324
    /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:375
    /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:376
    /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:386
    /home/aorus/dotfiles/quickshell/.config/quickshell/shell.qml:387
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/commit.sh:70
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/commit.sh:84
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/commit.sh:86
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/commit.sh:90
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/commit.sh:91
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/commit.sh:93
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/contract.sh:255
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/contract.sh:29
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/font.sh:12
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/font.sh:29
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/font.sh:46
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/font.sh:47
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/font.sh:50
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/font.sh:53
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/generate.sh:26
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/gtk.sh:311
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:583
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:585
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:591
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:592
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:593
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:594
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:595
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/motion.sh:596
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:14
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:15
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:19
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:20
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:21
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:33
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:71
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:73
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:81
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:82
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/wallpaper.sh:441
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:142
[REPORT] waybar/install-stow-lists: 22 reference(s)
    /home/aorus/dotfiles/install.sh:73
    /home/aorus/dotfiles/stow.sh:260
    /home/aorus/dotfiles/stow.sh:274
    /home/aorus/dotfiles/stow.sh:278
    /home/aorus/dotfiles/stow.sh:289
    /home/aorus/dotfiles/stow.sh:37
    /home/aorus/dotfiles/stow.sh:399
    /home/aorus/dotfiles/stow.sh:400
    /home/aorus/dotfiles/stow.sh:405
    /home/aorus/dotfiles/stow.sh:408
    /home/aorus/dotfiles/stow.sh:419
    /home/aorus/dotfiles/stow.sh:420
    /home/aorus/dotfiles/stow.sh:421
    /home/aorus/dotfiles/stow.sh:422
    /home/aorus/dotfiles/stow.sh:423
    /home/aorus/dotfiles/stow.sh:424
    /home/aorus/dotfiles/stow.sh:442
    /home/aorus/dotfiles/stow.sh:443
    /home/aorus/dotfiles/stow.sh:444
    /home/aorus/dotfiles/stow.sh:448
    /home/aorus/dotfiles/stow.sh:453
    /home/aorus/dotfiles/stow.sh:528
[REPORT] waybar/systemd-units: 5 reference(s)
    systemctl --user list-unit-files: app-Hyprland-waybar\x2dfullscreen\x2dwatch.sh-19e9d1cf.scope                transient -
    systemctl --user list-unit-files: app-Hyprland-waybar\x2dlaunch.sh-353e4682.scope                             transient -
    systemctl --user list-unit-files: app-Hyprland-waybar\x2dlaunch.sh-96640265.scope                             transient -
    systemctl --user list-unit-files: app-Hyprland-waybar\x2dlaunch.sh-a0a0532d.scope                             transient -
    systemctl --user list-unit-files: waybar.service                                                              disabled  enabled
[REPORT] waybar/dbus-activation: 0 reference(s)
[REPORT] waybar/xdg-autostart: 0 reference(s)
[REPORT] waybar/host-package: 1 reference(s)
    pacman -Q waybar: waybar 0.15.0-2
[REPORT] waybar/planning-archive: 4554 reference(s)
[REPORT] waybar/repo-prose: 46 reference(s)

Summary: surface=waybar status=pending failed_classes=0
```
