---
quick_id: 260826-qr1
date: 2026-08-26
status: complete
commits:
  - 0766996e fix(gates): point the overview chord at Tab, and assert the check that ran
  - 94fb8103 fix(install): qt6-imageformats ships libqwebp — read the contents, not the blurb
---

# Quick Task 260826-qr1 — SUMMARY

Both items STATE.md carried as OPEN are closed. Neither was reachable by a gate;
one of them **was a gate**, quietly reporting a pass it had not earned.

## Item 1 — the mislabelled 58/1, and the blind spot underneath it

### The reported problem was real and is fixed

`quickshell-doctor --self-test` printed a failure as
`compliant-overview-keybinds.lua -> keybind-doctor's static chord-collision check
clean`, but that check **passed** with `found: 0`. keybind-doctor runs thirteen
checks; the self-test asserted on its **whole exit code**, so the actual failure —
`declared-vs-registered`, which compares the fixture's binds against live
`hyprctl binds` — surfaced under a chord-collision label. A reader chasing that
line would have gone looking for a bind collision that did not exist.

`_qsd_kbd_collision_rc()` now extracts the one verdict line a fixture can
legitimately answer. It returns 0 (pass), 1 (fail), or **2 (the check never ran)**.
The two poisoned assertions require exactly 1, so a keybind-doctor that dies early
can no longer satisfy an expectation of "non-zero". No pipeline in the extractor:
`grep -q` exits 141 under `pipefail` when it matches early and stops reading, which
would flip a verdict according to how long the output happened to be.

All four keybind assertions were re-pointed, not just the failing pair. The
audio-panel two passed only because their fixture's binds happen to match the live
session; they carried the identical latent defect.

### The larger finding — the gate was blind, not merely mislabelled

STATE.md framed this as fixture drift. It was not confined to the fixture.

The **shipped manifest** `quickshell/.config/quickshell/shortcuts.json` still
declared the overview chord as `SUPER+O`, while `keybinds.lua:265` binds
`SUPER+Tab`. keybind-doctor's collision check (`keybind-doctor:605-626`) walks the
**manifest's** chords and looks for declared binds claiming the same
`(modmask, key, release)` tuple. Nothing declares `Super+O` any more — live
`hyprctl binds` has **zero** `key: O` entries — so `COLLISION_COUNT` was 0
**vacuously**. Since the bind moved, a second bind claiming `Super+Tab` would not
have been caught. The check had stopped covering the overview chord entirely and
went on reporting a pass.

That is the failure mode worth remembering: a gate whose reference data drifts does
not go red. It goes green, and stays green, over nothing.

`GlobalShortcut` (`shell.qml:1932-1937`) registers by `appid`/`name` and never
reads `chord`, so the manifest's chord field is purely keybind-doctor's cross-check
contract. Re-pointing it is inert at runtime and is exactly what restores coverage.

### The poisoned fixture had to move in the same commit

The poison in `poisoned-collision-overview-keybinds.lua` **depends on the manifest
chord** — the collision check only flags binds claiming a chord the manifest owns.
Had only the manifest moved to `Tab`, the collider would have kept claiming
`Super+O`, which the manifest no longer owns, and the poisoned fixture would have
gone quietly green: a poison that no longer bites, in a gate that would then look
healthier than before. Both files moved together, and the poison was re-proven
biting before the commit landed.

### A full enumeration, because one drift implies others might exist

All 13 manifest entries were cross-checked against every `hl.dsp.global(...)` bind
in `keybinds.lua`. **Exactly one** real drift (overview). Two other rows flagged by
a first, buggy parser were false and worth recording so they are not re-chased:
`launcher` legitimately carries a second chord (`Super+R`, `keybinds.lua:98`), and
`launcher-menu` declares its release edge through a `{ release = true }` options
table (`keybinds.lua:99`) rather than a distinct function name. The first parser
read neither, and reported 13 of 13 as drifted — a reminder that an instrument
returning "everything is broken" is usually itself broken.

## Item 2 — the webp candidate is confirmed, and the description was the trap

`qt6-imageformats` was left out of `install.sh` on purpose, because its package
description advertises only `TIFF, MNG, TGA, WBMP` and nobody had checked whether
it actually ships a webp plugin. Adding it on that basis was correctly refused.

The description is incomplete. The real 6.11.2-1 package contains **seven** plugins:

```
usr/lib/qt6/plugins/imageformats/libqicns.so
usr/lib/qt6/plugins/imageformats/libqjp2.so
usr/lib/qt6/plugins/imageformats/libqmng.so
usr/lib/qt6/plugins/imageformats/libqtga.so
usr/lib/qt6/plugins/imageformats/libqtiff.so
usr/lib/qt6/plugins/imageformats/libqwbmp.so
usr/lib/qt6/plugins/imageformats/libqwebp.so   <-- present
```

`Depends On: ... libwebp ...` corroborates independently.

Measuring this needed a detour worth recording: `pacman -Fl` returns nothing
without a sudo `pacman -Fy` to populate the files db, and no such db exists on this
host. The package was fetched from the configured mirror and listed directly — no
sudo, no install, and it reads the actual contents rather than any metadata field.

`qt6-imageformats` is now in `PACMAN_PKGS`, which puts it in `VERIFY_PKGS`
automatically, so a fresh `install.sh` run proves it landed.

## Verification

| Check | Result |
|---|---|
| live `keybind-doctor` before edits (baseline) | 13 passed / 0 failed, exit 0 |
| live `keybind-doctor` after edits | 13 passed / 0 failed, exit 0 — **byte-identical to baseline** |
| `compliant-overview-keybinds.lua` collision, re-pointed manifest | `found: 0` |
| `poisoned-collision-overview-keybinds.lua` collision, re-pointed manifest | `found: 1`, naming line 28 — **poison still bites** |
| `_qsd_kbd_collision_rc` across 4 fixtures | 0, 1, 0, 1 — correct |
| `_qsd_kbd_collision_rc` on a missing fixture | 2 — fails both assertion shapes, cannot pass as "non-zero" |
| `bash -n` quickshell-doctor / keybind-doctor / install.sh | OK |
| colour-lint | 425 passed / 0 failed |
| motion-lint | 612 passed / 0 failed |
| settings-index-check | 178 passed / 0 failed |
| qml-import-check | 0 unresolved across 143 files |
| stow-link-check | 2 passed / 0 failed |
| retirement-check --all | `failed_classes=0` |
| theme-doctor | 1218 passed / 0 failed, exit 0 |

The poisoned fixture is the positive control for the manifest fix: it proves the
re-pointed `found: 0` is a real zero and not another vacuous one.

## Not done, and why

- **`quickshell-doctor --self-test` itself was not run.** It is a LIVE probe that
  restarts quickshell from inside, so it stays operator-only. Its keybind seam —
  the entire subject of item 1 — was exercised directly instead, at all four call
  sites plus the missing-fixture case. The expected reading is **59 passed / 0
  failed**; the previously failing assertion now tests the check it names.
- **`qt6-imageformats` was not installed on this host.** That needs sudo. One
  command closes it: `sudo pacman -S --needed qt6-imageformats`. Until then the
  single `.webp` in the library (`catppuccin/live/tracer-probe.webp`) still shows
  its poster frame. Nothing else in the repo depends on it.
