# Phase 20 GATE-01: Pre-Deletion Retirement Baseline

The "before" half of RETIRE-01's before/after zero-hit pair for all four of this phase's
retirement targets (`swayosd`, `wleave`, `wlogout`, `eww`). Plans 20-09 and 20-10 re-run the
identical `retirement-check <surface>` command post-deletion and diff against this document.

CONTEXT.md's own `canonical_refs` list (§ "The surfaces being replaced" / "Integration points
that must be repointed or removed") is authoritative but **not exhaustive** — this sweep's job
is to find what it missed, per this plan's own must-have. The reference-site table below is
restricted to sites CONTEXT.md's `canonical_refs` does not already name; sites CONTEXT.md
already covers are not repeated here.

---

## Pre-deletion retirement-check output

Raw, verbatim, committed output of `hypr/.config/hypr/scripts/retirement-check <surface>` run
this session (2026-08-15) against the unmodified tree — before any deletion in this phase.

### `retirement-check swayosd` (exit 0)

```
retirement-check — surface=swayosd status=pending root=/home/aorus/dotfiles

[REPORT] swayosd/own-tree: 4 reference(s)
    /home/aorus/dotfiles/swayosd/.config/swayosd/style.css:1
    /home/aorus/dotfiles/swayosd/.config/swayosd/style.css:3
    /home/aorus/dotfiles/swayosd/.config/swayosd/style.css:4
    /home/aorus/dotfiles/swayosd/.config/swayosd/style.css:6
[REPORT] swayosd/layer-window-rules: 0 reference(s)
[REPORT] swayosd/autostart: 1 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/autostart.lua:192
[REPORT] swayosd/keybinds: 11 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:293
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:294
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:295
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:297
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:298
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:299
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:300
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:303
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:304
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:307
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:308
[REPORT] swayosd/contract-json: 1 reference(s)
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:14
[REPORT] swayosd/matugen-templates: 5 reference(s)
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:78
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:79
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:80
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:81
    /home/aorus/dotfiles/matugen/.config/matugen/templates/swayosd-colors.css:2
[REPORT] swayosd/checker-internals: 36 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:1154
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:398
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:411
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:10
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:1000
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:1005
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:1008
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:1010
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:1012
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2212
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2217
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2222
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2227
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2763
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2764
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2768
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2769
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2773
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2788
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2832
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2833
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2842
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:635
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:642
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:646
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:647
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:648
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:649
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:659
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:80
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:947
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:951
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:955
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:999
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:359
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:248
[REPORT] swayosd/test-fixtures: 3 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-hyprctl-binds.txt:3
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-duplicate-xf86-binds.txt:4
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-missing-xf86-binds.txt:4
[REPORT] swayosd/cross-package-refs: 13 reference(s)
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml:16
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/dashboard/Design.qml:350
    /home/aorus/dotfiles/quickshell/.config/systemd/user/quickshell.service:7
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/gtk.sh:311
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:104
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:107
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:111
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:115
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:116
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:117
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:123
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:128
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/reload.sh:137
[REPORT] swayosd/install-stow-lists: 10 reference(s)
    /home/aorus/dotfiles/install.sh:190
    /home/aorus/dotfiles/install.sh:553
    /home/aorus/dotfiles/install.sh:556
    /home/aorus/dotfiles/install.sh:561
    /home/aorus/dotfiles/install.sh:562
    /home/aorus/dotfiles/install.sh:572
    /home/aorus/dotfiles/install.sh:582
    /home/aorus/dotfiles/install.sh:722
    /home/aorus/dotfiles/install.sh:829
    /home/aorus/dotfiles/stow.sh:29
[REPORT] swayosd/systemd-units: 2 reference(s)
    /home/aorus/dotfiles/quickshell/.config/systemd/user/quickshell.service:7
    systemctl --user list-unit-files: app-Hyprland-swayosd\x2dserver-8c85c667.scope                               transient -
[REPORT] swayosd/dbus-activation: 0 reference(s)
[REPORT] swayosd/xdg-autostart: 0 reference(s)
[REPORT] swayosd/host-package: 1 reference(s)
    pacman -Q swayosd: swayosd 0.3.1-1
[REPORT] swayosd/planning-archive: 1057 reference(s)
[REPORT] swayosd/repo-prose: 3 reference(s)

Summary: surface=swayosd status=pending failed_classes=0
```

### `retirement-check wleave` (exit 0)

```
retirement-check — surface=wleave status=pending root=/home/aorus/dotfiles

[REPORT] wleave/own-tree: 26 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:13
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:17
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:23
    /home/aorus/dotfiles/wleave/.config/wleave/layout.json:15
    /home/aorus/dotfiles/wleave/.config/wleave/layout.json:22
    /home/aorus/dotfiles/wleave/.config/wleave/layout.json:29
    /home/aorus/dotfiles/wleave/.config/wleave/layout.json:36
    /home/aorus/dotfiles/wleave/.config/wleave/layout.json:43
    /home/aorus/dotfiles/wleave/.config/wleave/layout.json:50
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:1
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:109
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:126
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:130
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:131
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:163
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:182
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:26
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:263
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:363
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:39
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:431
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:56
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:64
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:95
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:98
[REPORT] wleave/layer-window-rules: 3 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:231
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:292
    /home/aorus/dotfiles/hypr/.config/hypr/config/windowrules.lua:440
[REPORT] wleave/autostart: 0 reference(s)
[REPORT] wleave/keybinds: 1 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:68
[REPORT] wleave/contract-json: 1 reference(s)
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/contract.json:4
[REPORT] wleave/matugen-templates: 4 reference(s)
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:48
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:49
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:50
    /home/aorus/dotfiles/matugen/.config/matugen/config.toml:51
[REPORT] wleave/checker-internals: 16 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:1156
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:381
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:382
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:383
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:441
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:450
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:451
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:688
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:691
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/motion-lint:692
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:11
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:361
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:248
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:296
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:300
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-stress-test:314
[REPORT] wleave/test-fixtures: 3 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-gtk4.css:2
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-gtk4.css:2
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-gtk4.css:2
[REPORT] wleave/cross-package-refs: 9 reference(s)
    /home/aorus/dotfiles/elephant/.config/elephant/menus/main.toml:35
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:12
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:13
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:17
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/wleave.sh:23
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/Dashboard.qml:437
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:567
    /home/aorus/dotfiles/quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml:148
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/lib/gtk.sh:311
[REPORT] wleave/install-stow-lists: 2 reference(s)
    /home/aorus/dotfiles/install.sh:317
    /home/aorus/dotfiles/stow.sh:36
[REPORT] wleave/systemd-units: 0 reference(s)
[REPORT] wleave/dbus-activation: 0 reference(s)
[REPORT] wleave/xdg-autostart: 0 reference(s)
[REPORT] wleave/host-package: 1 reference(s)
    pacman -Q wleave: wleave 0.7.1-2
[REPORT] wleave/planning-archive: 1482 reference(s)
[REPORT] wleave/repo-prose: 2 reference(s)

Summary: surface=wleave status=pending failed_classes=0
```

### `retirement-check wlogout` (exit 0)

```
retirement-check — surface=wlogout status=pending root=/home/aorus/dotfiles

[SKIP] wlogout/own-tree: no own-tree path declared in the registry for this surface
[REPORT] wlogout/layer-window-rules: 0 reference(s)
[REPORT] wlogout/autostart: 0 reference(s)
[REPORT] wlogout/keybinds: 0 reference(s)
[REPORT] wlogout/contract-json: 0 reference(s)
[REPORT] wlogout/matugen-templates: 0 reference(s)
[REPORT] wlogout/checker-internals: 0 reference(s)
[REPORT] wlogout/test-fixtures: 1 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-overview-keybinds.lua:18
[REPORT] wlogout/cross-package-refs: 1 reference(s)
    /home/aorus/dotfiles/wleave/.config/wleave/style.css:229
[REPORT] wlogout/install-stow-lists: 0 reference(s)
[REPORT] wlogout/systemd-units: 0 reference(s)
[REPORT] wlogout/dbus-activation: 0 reference(s)
[REPORT] wlogout/xdg-autostart: 0 reference(s)
[REPORT] wlogout/host-package: 1 reference(s)
    pacman -Q wlogout: wlogout 1.2.2-0
[REPORT] wlogout/planning-archive: 952 reference(s)
[REPORT] wlogout/repo-prose: 0 reference(s)

Summary: surface=wlogout status=pending failed_classes=0
```

### `retirement-check eww` (exit 0)

```
retirement-check — surface=eww status=pending root=/home/aorus/dotfiles

[SKIP] eww/own-tree: no own-tree path declared in the registry for this surface
[REPORT] eww/layer-window-rules: 0 reference(s)
[REPORT] eww/autostart: 0 reference(s)
[REPORT] eww/keybinds: 0 reference(s)
[REPORT] eww/contract-json: 0 reference(s)
[REPORT] eww/matugen-templates: 0 reference(s)
[REPORT] eww/checker-internals: 2 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor:2607
    /home/aorus/dotfiles/theme-engine/.config/theme-engine/theme-doctor:555
[REPORT] eww/test-fixtures: 2 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-media-hardening.sh:11
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/tests/test-media-hardening.sh:12
[REPORT] eww/cross-package-refs: 3 reference(s)
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/media-art-resolve.sh:20
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/media-players.sh:20
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/media-players.sh:24
[REPORT] eww/install-stow-lists: 0 reference(s)
[REPORT] eww/systemd-units: 0 reference(s)
[REPORT] eww/dbus-activation: 0 reference(s)
[REPORT] eww/xdg-autostart: 0 reference(s)
[REPORT] eww/host-package: 1 reference(s)
    pacman -Q eww: eww 0.6.0-1
[REPORT] eww/planning-archive: 1085 reference(s)
[REPORT] eww/repo-prose: 27 reference(s)

Summary: surface=eww status=pending failed_classes=0
```

**All four surfaces currently report `status=pending` (not yet retired) and `failed_classes=0`
(nothing yet blocking a retirement, because nothing has been deleted).** This is the expected
pre-deletion shape: `retirement-check`'s `[FAIL]` tier only fires against a `retired`-status
surface still leaving live blocking references — plans 20-09/20-10 flip status to `retired`
after deletion, at which point this same command re-run is the "after" half of the pair.

---

## Reference sites not in 20-CONTEXT.md's canonical_refs

CONTEXT.md's `canonical_refs` already names: both surfaces' own-tree files, the three
`windowrules.lua` layer rules, `keybinds.lua:68` and `:293-314`, the walker menu entry,
`ClockActionsCapsule.qml:567-580`, `autostart.lua:185-200`, `contract.json:4/14`,
`matugen/config.toml:49-51/79-81` + template files, `lib/reload.sh:107-128`,
`theme-doctor:359,361`, `theme-stress-test:296-314`'s `REPRESENTATIVE_FILES` array,
`lib/gtk.sh:311`, `install.sh:190/317/553-562`, `stow.sh:29/36`. Those are not repeated below.

Every row carries a disposition from the set `{delete, edit, re-instrument, report-only}` — a
row with no disposition is an unclosed hole per this plan's own instruction.

| Path:line | Reference class | Surface | Disposition |
|---|---|---|---|
| `quickshell-doctor:80,635-659,947-955,999-1012,2212-2227,2763-2842` — the `panel-swayosd-key-ownership` check (its `_qsd_swayosd_server_reachable`/`_qsd_osd_activation_count` helpers, the `osd-differential` sub-check polling `hyprctl layers -j` for `namespace == "swayosd"`, the `source-holds-by-construction` sub-check grepping the panel QML dir for `swayosd-client` refs) | checker-internals | swayosd | **re-instrument** — deleting swayosd without re-instrumenting this check turns a green GATE-03 gate red; the check's differential-proof mechanism (drive an action, confirm the OSD's own layer activates) is reusable against the new in-process QML OSD namespace once plan 20-05/20-09 defines it |
| `motion-lint:398,411` — `swayosd/style.css` whole-file EXEMPTIONS entry (`'no motion literals — motion is compositor-delivered through the layer animation (D-02)'`) | checker-internals | swayosd | **delete** — the exempted file no longer exists once the package is removed |
| `motion-lint:1154` — `$HOME/.config/swayosd` deployed-directory scan root | checker-internals | swayosd | **delete** — removing this root from the `ROOTS` array once the directory no longer exists |
| `quickshell-doctor:2763-2842` — the swayosd-client-driven `one-step-per-press` volume/brightness probes | checker-internals | swayosd | **re-instrument** — same disposition as the key-ownership check; the probe's differential proof needs a new activation signal once `swayosd-client` no longer exists |
| `motion-lint:381-383` — historical comment recording wleave's whole-file EXEMPTIONS entry was already removed by plan 12-07 | checker-internals | wleave | **report-only** — already-historical prose, not a live reference needing action |
| `motion-lint:441,450-451` — `wleave/style.css button:hover,button:focus` LINE_EXEMPTIONS entry (narrower than a whole-file exemption, covers exactly the overshoot-timing hover rule) | checker-internals | wleave | **delete** — the exempted file no longer exists once the package is removed |
| `motion-lint:688-692` — `DELAY_PROPERTY_RE` comment block citing wleave's six per-capsule `animation-delay` lines as the found-live example that motivated the carve-out | checker-internals | wleave | **edit** — the regex mechanism itself is generic (any `animation-delay`/`transition-delay` property, not wleave-specific) and stays; only the comment's wleave-specific citation becomes stale and should be updated to whatever surface next exercises it, or generalized |
| `motion-lint:1156` — `$HOME/.config/wleave` deployed-directory scan root | checker-internals | wleave | **delete** — removing this root from the `ROOTS` array once the directory no longer exists |
| `tests/quickshell-fixtures/compliant-hyprctl-binds.txt:3`, `poisoned-duplicate-xf86-binds.txt:4`, `poisoned-missing-xf86-binds.txt:4` — all three carry `swayosd-client` XF86Audio*/XF86MonBrightness* bind strings as fixture data, explicitly targeting the `panel-swayosd-key-ownership` check (each fixture's own header comment states `Target check: panel-swayosd-key-ownership`) | test-fixtures | swayosd | **edit** — these fixtures are dependent on the re-instrumented check above; once that check's target mechanism changes (no more `swayosd-client` exec strings to count), the fixture content must be repointed to whatever binding shape the new OSD's key-ownership proof actually checks |
| `tests/motion-fixtures/compliant-gtk4.css:2`, `poisoned-raw-gtk4.css:2`, `poisoned-dangling-gtk4.css:2` — each file's header comment states it *"Derives from wleave/.config/wleave/style.css's hover/focus transition block ... rewritten to GTK4's longhand transition-* form"* | test-fixtures | wleave | **report-only** — these are derived, standalone test data exercising motion-lint's generic GTK4 CSS token-checking mechanism (CHECK A/CHECK B), not live pointers into `wleave/style.css`; they remain valid motion-lint self-test fixtures after wleave is deleted, no edit required |
| `tests/motion-fixtures/poisoned-fallback-gtk4.css:2` — a fourth fixture in the same directory (CR-01 bypass-lock fixture), not named in this plan's own enumeration but present on disk | test-fixtures | wleave (by lineage, not by content) | **report-only** — same reasoning as the three named above; flagged here because a reference class discovered at deletion time is exactly the failure mode this sweep exists to prevent, so the omission from this plan's own action text is corrected here rather than silently inherited |
| `theme-stress-test:314` — `REPRESENTATIVE_FILES=(hyprland-tokens.lua wleave.css gtk-4.0-colors.css kitty.conf)` | checker-internals | wleave | **delete (not repoint)** — `gtk-4.0-colors.css` is already a second `gtk-css`-format entry in the same array, so removing `wleave.css` still leaves the `gtk-css` format represented; a repoint would be redundant. Recorded explicitly so plan 20-10 does not invent a repoint. |
| `theme-doctor:357-362` — `GTK4_CSS_SHEETS=("$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/swayosd/style.css" "$HOME/.config/walker/themes/rice/style.css" "$HOME/.config/wleave/style.css")` | checker-internals | both | **edit** — remove the swayosd and wleave entries from this 4-element array (leaving `gtk.css` and walker's own sheet); this is the same array CONTEXT.md's `theme-doctor:359,361` citation already names line-by-line, listed here as one edit spanning both surfaces |
| `VERIFICATION.md:214` — *"The Quickshell bar, swaync, walker, wleave, and Thunar all show the same theme"* | repo-prose | wleave | **report-only** — repository-root prose in the fresh-install VM verification checklist, not a functional reference; classified report-tier per this plan's own instruction, owned by whichever plan next touches `VERIFICATION.md` (Phase 22's fresh-install proof is the natural owner) |
| `quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml:16`, `Design.qml:350`, `.config/systemd/user/quickshell.service:7` | cross-package-refs (comment prose) | swayosd | **report-only** — each is an inline code comment mentioning swayosd/swayosd-client in passing (as the sole OSD producer, as a scroll-step precedent, as one of many autostart entries listed for historical context) — none is a functional dependency; comments become stale, not broken, and are left for the plan that next edits each file |
| `quickshell/.config/quickshell/modules/Dashboard.qml:437`, `modules/overview/WorkspaceTile.qml:148` | cross-package-refs (comment prose) | wleave | **report-only** — same reasoning: both are inline comments citing wleave as a design precedent (focus-grab dismiss wiring, blur/frost tuning history), not functional dependencies |
| `swayosd/repo-prose: 3 reference(s)` (aggregate, not individually listed above) | repo-prose | swayosd | **report-only** — batched per the two-tier split (D-18-37); individually enumerable via a fresh `retirement-check swayosd` run if needed, none blocking |
| `eww/checker-internals:2` (`quickshell-doctor:2607`, `theme-doctor:555`), `eww/cross-package-refs:3` (`media-art-resolve.sh:20`, `media-players.sh:20,24`) | checker-internals / cross-package-refs | eww | **report-only for this plan** — eww's own consumer sweep belongs to RETIRE-06/Phase 21's media fold-in (`ags/` retirement), not RETIRE-07's scope in this phase; recorded here for completeness since `retirement-check eww` was run as part of this task's four-surface sweep, but disposition ownership is out of this phase |
| `wlogout/cross-package-refs:1` (`wleave/.config/wleave/style.css:229`) | cross-package-refs | wlogout | **report-only** — a comment inside wleave's own stylesheet mentioning the retired wlogout sheet's pattern by name (contrast/design-precedent citation, not a functional dependency); becomes moot once wleave/style.css is itself deleted in this phase |

**Contract/theme-engine sites already fully enumerated by CONTEXT.md's canonical_refs**
(`contract.json:4/14`, `matugen/config.toml:49-51/79-81` + the two template files,
`lib/reload.sh:107-128`, `theme-doctor:359,361`, `lib/gtk.sh:311`, `install.sh:190/317/553-562`,
`stow.sh:29/36`) all carry an implicit **delete** disposition — CONTEXT.md's own "Integration
points that must be repointed or removed" framing already states this; not re-tabulated here to
avoid duplicating an already-authoritative list.

**install/stow sites** — `install.sh:190` (swayosd package), `install.sh:317` (wleave
package), `install.sh:553-562` (`systemctl enable --now swayosd-libinput-backend.service`
block — disposition contingent on `20-GATE-01-MEASUREMENTS.md` § D-20-17's verdict), `stow.sh:29`
(swayosd), `stow.sh:36` (wleave) — all **delete**, already named in canonical_refs, confirmed
present at the exact cited lines this session.
