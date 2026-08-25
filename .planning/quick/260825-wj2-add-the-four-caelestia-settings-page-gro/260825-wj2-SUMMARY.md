---
quick_id: 260825-wj2
date: 2026-08-26
status: complete
description: Add the four Caelestia settings-page groups (Apps, Connected devices + per-app mute, Updates + About, Services + Language & region) and the StackPage sub-page mechanism they're built on
requirements: [CSP-00, CSP-01, CSP-02, CSP-03, CSP-04]
commits:
  - d3e1e290 feat(quick-260825-wj2): add the StackPage sub-page mechanism
  - 509c27b7 feat(quick-260825-wj2): add the Apps settings page group (index 10)
  - 56d5f1a8 feat(quick-260825-wj2): add Updates + About settings pages (11, 12)
  - 64e9a5d4 feat(quick-260825-wj2): split Connected devices out of Network (index 5)
  - 30b4fd73 feat(quick-260825-wj2): port StepperRow — a sixth row primitive (D-9)
  - 9a5b1bee feat(quick-260825-wj2): add Services + Language & region (12, 13)
key-files:
  created:
    - quickshell/.config/quickshell/modules/settings/common/StackPage.qml
    - quickshell/.config/quickshell/modules/settings/common/StepperRow.qml
    - quickshell/.config/quickshell/modules/settings/pages/AppsPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/AllAppsPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/AppInfoPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/UpdatesPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/AboutPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/BluetoothPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/BtDeviceInfoPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/ServicesPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/LanguageRegionPage.qml
  modified:
    - quickshell/.config/quickshell/modules/settings/common/PageBase.qml
    - quickshell/.config/quickshell/modules/settings/common/qmldir
    - quickshell/.config/quickshell/modules/settings/SettingsState.qml
    - quickshell/.config/quickshell/modules/settings/Settings.qml
    - quickshell/.config/quickshell/modules/settings/Pages.qml
    - quickshell/.config/quickshell/modules/settings/PageRegistry.qml
    - quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml
    - quickshell/.config/quickshell/modules/settings/RowIndex.qml
    - quickshell/.config/quickshell/modules/settings/pages/qmldir
    - quickshell/.config/quickshell/modules/settings/pages/NetworkPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/AudioPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/NotificationsPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/SessionPage.qml
    - quickshell/.config/quickshell/modules/Prefs.qml
    - quickshell/.config/quickshell/modules/launcher/Launcher.qml
    - quickshell/.config/quickshell/modules/launcher/MenuTree.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/SystemResources.qml
    - quickshell/.config/quickshell/modules/bar/SystemCapsule.qml
    - quickshell/.config/quickshell/shell.qml
    - hypr/.config/hypr/scripts/settings-index-check
actuals:
  tokens: 47992
  tasks: 6
  commits: 6
status: complete
---

# 260825-wj2 — Add the four Caelestia settings-page groups

## What shipped

The settings window went from 10 pages to 16, closing the measured gap
against Caelestia's `modules/nexus/`: a `StackPage` sub-page mechanism
(ported from Caelestia's own `common/StackPage.qml`), six new pages
(Apps → All apps → App info, Connected devices → Device info, Updates,
About, Services, Language & region), one page split out of `NetworkPage.qml`
(Bluetooth), a sixth row primitive (`StepperRow`, hand-rolled per D-9), and
eleven new Prefs keys — four poll intervals that stopped being hardcoded
literals, plus favourite/hidden apps and default terminal/audio commands.

Final 16-page order, verified against `PageRegistry.qml`:

```
0 Appearance    4 Network            8 Window manager   12 Services
1 Wallpaper     5 Connected devices  9 Notifications     13 Language & region
2 Bar           6 Display            10 Session          14 Updates
3 Audio         7 Input              11 Apps             15 About
```

## Task-by-task

**Task 1 (d3e1e290) — the mechanism.** `StackPage.qml` (a `StackView` +
`openSubPage()`/push-pop transitions on `Motion.qml` tokens), `PageBase`
gained `isSubPage` + a back-arrow header, `SettingsState` gained
`subPageIdxStack`/`selectedApp`/`selectedBtDevice`/`pendingSubPageIdx` +
`openSubPage()`/`closeSubPage()`, `Settings.qml`'s Escape now pops a
sub-page first, `Pages.qml` extracted `_recollectRows()` and resolves a
pending sub-page deep-link at incubation time. `settings-index-check`
CHECK A/B became pair-keyed on `(pageIdx, subPageIdx)` and gained CHECK F
(sub-page file existence). **Falsified inline:** an unindexed `InfoRow` on
`AppearancePage.qml` → gate FAILed naming the page (126 passed, 1 failed) →
reverted → PASSed (127 passed, 0 failed).

**Task 2 (509c27b7) — Apps (index 10), the first real StackPage path.**
Root → All apps → App info, four new Prefs keys
(`launcher.favouriteApps`/`hiddenApps`, `apps.terminal`/`apps.audio`),
`Launcher.qml:filteredApps`/`_compareApps` is the single filter+sort point
for hidden/favourite, and the three measured terminal/audio launch sites
(`SystemCapsule.qml`, `SessionPage.qml`, `MenuTree.qml`) repointed to the
new keys.

**Task 3 (56d5f1a8) — Updates + About (11, 12).** Reused
`UpdatesMode.qml`'s `checkupdates`/`paru -Qua` command set and
`SystemInfoMode.qml`'s fastfetch JSON parse verbatim. Both flat comps, no
sub-pages, no renumbering.

**Task 4 (64e9a5d4) — Connected devices (insert at 5), per-app mute.**
Bluetooth's page-level state, `DeviceRow`, and the whole `SettingsSection`
moved out of `NetworkPage.qml` verbatim into `BluetoothPage.qml`, plus one
addition — a settings-gear affordance per row opening
`BtDeviceInfoPage.qml` (D-8; the existing inline discovery/pairing surface
is not duplicated). `shell.qml` gained `bluetoothPageIdx` (slug lookup) +
`settingsShowingBluetooth`; `BluetoothBackend.panelOpen` now gates on that
instead of `settingsShowingNetwork`. `RowIndex.qml` renumbered
highest-first (12→13 down to 5→6), Bluetooth's five entries moved out of
`pageIdx: 4` into a new `pageIdx: 5` block. `AudioPage.qml`'s per-app mixer
gained a mute `ToggleRow` beside the existing volume `SliderRow`, wrapped
in an explicit-width `Column` (the `SettingsSection.qml`-documented
circular-binding trap).

**Task 5 (30b4fd73) — StepperRow, hand-rolled.** No QQC2 `SpinBox` — this
tree's own measured total-render failure from wrapping a QQC2 interactive
primitive (`SliderRow.qml`'s header). `Pages.activateContentRow` gained a
`stepUp` branch, checked first. **Falsified inline:** an unindexed
`StepperRow` on `NotificationsPage.qml` → gate FAILed naming the page (156
passed, 1 failed) → reverted → PASSed (157 passed, 0 failed).

**Task 6 (9a5b1bee) — Services + Language & region (12, 13).** Four
`StepperRow`s (unit conversion happens at the row, never at the consumer);
`WeatherBackend`'s `cacheTtlMs`/`refreshIntervalMs` both read the same
Prefs key (driving only one would ship a knob that visibly does nothing
under the 15-min cache TTL); `unitsTemp`/`Wind`/`Precip` converted from
`property alias` to a real fallback chain (Prefs → `weather.json` →
`"metric"`, since an alias cannot carry one). "Weather location" moved
verbatim from `NotificationsPage.qml` to `LanguageRegionPage.qml`, still
read-only.

## Verification (all four gates, run once each at the end of the task
that touched them, per this plan's own "never re-run a passing gate"
instruction)

| Gate | Baseline | Final |
|------|----------|-------|
| `settings-index-check` | 126 passed / 0 failed, 10 pages | **167 passed / 0 failed, 16 pages**, CHECK E matching all 16 slugs, CHECK F resolving 3 sub-pages |
| `colour-lint` | 365 / 0 | **398 / 0** |
| `motion-lint` | 370 / 0 | **403 / 0** |
| `bash -n` on the gate script | 0 | **0** |
| `qmllint` on every touched/created `.qml` file | — | **0 on 25 of 30 files** — see below |

**qmllint exemptions (5 files, all pre-existing, none a regression):**
`RowIndex.qml`, `PageRegistry.qml`, `PageCompRegistry.qml` and `shell.qml`
were the plan's own documented baseline exemptions (255 unmodified before
this task touched them). **`Launcher.qml` was NOT on that list but is also
255 at baseline** — measured directly via `git stash` against the
pre-Task-2 tree before editing it, confirming the 255 is pre-existing and
not something this task introduced. Every other touched/created file
(25 of 30) is qmllint-clean.

Both mandatory gate falsifications (Task 1's CHECK A/B/F, Task 5's
StepperRow-in-the-alternation) ran inline and are recorded above with
their raw pass/fail counts.

## Deviations from Plan

### Auto-fixed / adapted during execution

**1. [Rule 1 — process ordering] StepperRow's gate-regex edit landed one
commit early**
- **Found during:** Task 5's own verify pass.
- **Issue:** The plan calls for `settings-index-check` to be edited
  TWICE — Task 1 (pair-keyed CHECK A/B + CHECK F) and Task 5 (adding
  `StepperRow` to the row-primitive alternation and the header comment's
  row-type list). While writing Task 1's CHECK A regex
  (`ROW_PRIMITIVE_RE=...`), `StepperRow` was included in the alternation
  and header comment ahead of schedule — both edits touch the identical
  line and the duplication was not noticed until Task 5's own review pass.
- **Effect:** Harmless in practice — zero `StepperRow` declarations
  existed in the tree from Task 1 through Task 4, so the premature
  inclusion changed no gate output for three tasks. Task 5's own
  falsification (add an unindexed `StepperRow`, confirm FAIL naming the
  page, revert, confirm PASS) still ran fresh against the CURRENT tree in
  Task 5 and is a genuine, valid proof that the gate catches an unindexed
  `StepperRow` — it just proves a regex that had technically existed since
  Task 1's commit rather than being introduced in Task 5's own diff.
- **Files affected:** `hypr/.config/hypr/scripts/settings-index-check`
  (no further edit needed in Task 5 — already correct).
- **Verification:** Task 5's own falsification run (156 passed/1 failed →
  157 passed/0 failed) proves the gate's CURRENT behavior is correct,
  independent of which commit introduced the regex.

**2. [Rule 1 — bug] AllAppsPage favourite indicator folded into subtext**
- **Found during:** Task 2.
- **Issue:** The plan's action text asks for "a filled `favorite` glyph on
  a favourited row, coloured from `Colours.primary`." This tree's `NavRow`
  primitive (`common/NavRow.qml`) has no icon/decoration slot at all —
  label + subtext + a fixed chevron only — and `NavRow.qml` is
  deliberately NOT in Task 2's `<files>` list (editing a primitive this
  many OTHER pages already depend on is a structural change out of that
  task's scope, Rule 4 territory).
- **Fix:** Favourite status is folded into the row's own subtext text
  instead — a `"★ "` prefix ahead of the app name — rather than a separate
  coloured glyph. Documented in `AllAppsPage.qml`'s own header comment as
  a stated divergence.
- **Files affected:** `quickshell/.config/quickshell/modules/settings/pages/AllAppsPage.qml`.
- **Verification:** `settings-index-check` CHECK A/B still pass for the
  (10,1) pair (2 rows, both entries found verbatim) — the row primitive
  count is unaffected by what's inside the subtext string.

**3. [Rule 1 — bug, self-referential gate comment] Fixed a comment that
would have failed its own verify command**
- **Found during:** Task 4, writing `NetworkPage.qml`'s header comment.
- **Issue:** A first draft of the header comment literally read
  `` `grep -c bluetoothBackend` over this file is 0 `` — which itself
  contains the string `bluetoothBackend`, so the task's own verify command
  (`test "$(grep -c bluetoothBackend .../NetworkPage.qml)" -eq 0`) would
  have failed against its own prose — the exact "a grep gate matches its
  own comment" failure class this repo's memory already warns about.
- **Fix:** Reworded the sentence to describe the invariant without
  containing the literal identifier.
- **Files affected:** `quickshell/.config/quickshell/modules/settings/pages/NetworkPage.qml`.
- **Verification:** `grep -c bluetoothBackend NetworkPage.qml` → `0`.

---

**Total deviations:** 3 (1 process-ordering note, 2 auto-fixed).
**Impact on plan:** None affect correctness or the plan's own success
criteria — all three are documented for honesty rather than silently
absorbed. No architectural changes, no scope creep.

## Known Stubs

None. The three "honest non-delivery" `InfoRow`s (`Media playback`,
`File manager` on Apps; `UI language` on Language & region) are
DELIBERATE per the plan's own D-6 — they name capability gaps that don't
exist in this shell (no media-player launcher, no translation layer) and
are not placeholders for future work; the plan explicitly states this is
"the same principle the operator applied to the weather units: a picker
that cannot take effect is worse than no picker."

## Operator checklist (from the plan's own `<verification>` — none of this
was, or could safely be, run by the executor)

A hot reload will NOT show any of this — `Pages.qml` incubates page
components and serves stale QML, and only a shell restart renders a
settings-layout change. **Restart is operator-only** (never from an agent
shell, and never via `quickshell-doctor`, which restarts the shell
internally).

1. Sub-page navigation — Apps → All apps → App info, back via arrow/Escape/
   rail click.
2. Sub-page keyboard focus — Right-arrow into a sub-page rings THAT page's
   row, not the root's. (Static gates cannot see this.)
3. Search into a sub-page — "Favourite" lands on All apps, not App info.
4. Connected devices lists real Bluetooth devices; a device's gear icon
   opens its info sub-page.
5. Apps changes reach the launcher — Hidden removes, Favourite pins.
6. Default apps take effect — Updates page's "Update system" and the bar's
   update action open the configured terminal; the menu's Audio entry
   opens the configured mixer.
7. Audio → Per-app mixer shows a mute toggle under each volume slider.
   7b. The steppers work by mouse AND by keyboard (Enter/Space on a
   keyboard-focused stepper).
8. Services/units are live without a restart (Prefs writes are
   in-process).
9. Notifications → Content sources no longer carries Weather location;
   Language & region does.
10. Sixteen pages in the rail, in the order above.

## Self-Check: PASSED

All 11 newly-created files confirmed present on disk; all 6 commit hashes
confirmed in `git log`.
