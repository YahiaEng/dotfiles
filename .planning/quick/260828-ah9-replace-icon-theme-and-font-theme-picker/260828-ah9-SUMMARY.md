---
quick_id: 260828-ah9
slug: replace-icon-theme-and-font-theme-picker
date: 2026-08-28
status: complete
actuals:
  tokens: 43616
  tasks: 5
  commits: 29
  operator_rounds: 5
outcome: operator-approved 2026-08-28 — "Approved. Close this phase and save out work."
gates_added:
  - hypr/.config/hypr/scripts/button-lint
  - hypr/.config/hypr/scripts/transparent-lint
commits:
  - 340b59bc  # Task 1: AppearanceBackend singleton — one backend, four readers
  - 4a5caf2e  # Task 2: Atelier window — FloatingWindow, tab bar, Icons/Fonts tabs
  - 24fb7aa6  # Task 3: Catalogue tab — browse and install icon themes (D-04)
  - 2c24d219  # Task 4: Specimen — icon/font launcher word routes (D-01)
  - 5487ea79  # Task 5 Commit A: keybind package B + equivalence-gate entries
  - a0774ca6  # Task 5 Commit B: script strip, menu/drawer repointing, ROADMAP strike
---

# Replace icon-theme and font theme pickers with QML surfaces

Two new surfaces over one backend replace the fzf-in-kitty icon-theme and font
pickers: **Specimen** (launcher `icon`/`font` word routes) and **Atelier** (one
`FloatingWindow` with Icons/Fonts/Catalogue tabs, reached via `Super+I` /
`Super+Shift+F`). Both scripts kept their `--list`/`--set` machine-facing tail
and lost their interactive half. The Catalogue tab consumes the standing
v5.0 ICON-BROWSE candidate — struck in ROADMAP.md.

## What ships

| Piece | Files |
|---|---|
| Backend singleton | `modules/appearance/AppearanceBackend.qml` |
| Atelier window | `modules/appearance/{Atelier,AtTabBar,AtIconsTab,AtFontsTab,AtCatalogueTab}.qml` |
| Specimen (launcher routes) | `modules/launcher/{IconMode,FontMode}.qml` + `LauncherState`/`Launcher` |
| Menu leaves | `modules/launcher/{MenuTree,MenuMode}.qml` (Style ▸ Icon theme / Font) |
| Bar drawer | `modules/bar/ClockActionsCapsule.qml` (Font/Icon Theme cells) |
| Settings page | `modules/settings/pages/AppearancePage.qml` (repointed to the backend) |
| Keybind | `Super+I` (Icons), `Super+Shift+F` (Fonts); `Super+Shift+I` code editor, `Super+Shift+M` maximize |
| Scripts | `icon-theme-picker.sh` / `font-switcher.sh` stripped to `--list`/`--set`(`/--preview`) |
| Retired | `icon-theme-switch.sh`, `font-switch.sh` (shims), their windowrules.lua blocks |

## Measurements — all three held, no contradiction

- **M1 (48px is too coarse):** confirmed live. `Papirus`/`Papirus-Dark`/`Papirus-Light`
  are visually and structurally the same at 48px; the 22px preview grid is what
  actually distinguishes them (`AppearanceBackend`'s `--preview` verb, biased to
  the requested size).
- **M2 (13×2, not 13×3):** confirmed live — `font-switcher.sh --list` still
  enumerates exactly 39 raw names (13 families × 3 suffixes), and
  `AppearanceBackend.fontFamilies` collapses them to 13×{mono, propo} with no
  third "Nerd Font alone" row.
- **M3 (no icon exists in all 8 themes):** confirmed and EXTENDED live — the
  new `--preview` verb surfaces it directly: `Adwaita` resolves 9/12 probes
  (misses `applications-system`, `utilities-terminal`, `preferences-system`);
  every other installed theme resolves 12/12 once `_find_icon_at_size` follows
  symlinks (see Deviations — this was a real instrument gap the M1/M3
  measurements didn't need to account for, since the retired script's preview
  had the identical blind spot and nobody had compared theme-by-theme
  coverage numbers before).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `_find_icon_at_size` killed `--preview` after ~4 rows under `set -e`**
- **Found during:** Task 1, first live test of the new `--preview` verb
- **Issue:** the helper ended with `[[ -n "$f" ]] && printf '%s\n' "$f"` and no
  explicit `return 0`. Under `set -euo pipefail`, a bare `_f=$(...)`
  assignment (unlike a `local` assignment) propagates the callee's exit
  status — a probe that legitimately found nothing (exit 1) killed the whole
  `--preview` loop.
- **Fix:** added an explicit `return 0` at the end of the function.
- **Files:** `hypr/.config/hypr/scripts/icon-theme-picker.sh`
- **Commit:** 340b59bc

**2. [Rule 1 - Bug] `find` without `-L` under-reported delta-theme coverage**
- **Found during:** Task 1, same test — `Papirus-Dark` measured 4/12 real
  paths instead of the ≥8 the plan's own `<done>` criterion requires
- **Issue:** `Papirus-Dark` only OWNS `actions` (every size) plus
  `devices`/`places` (16px only) as real directories; `apps`/`mimetypes` and
  every non-overridden size are real per-category SYMLINKS into `Papirus`.
  Plain `find` does not descend into a symlinked directory, so the probe
  reported Papirus-Dark as covering 4/12 — an instrument fault, not what an
  icon-theme loader (or `ls -R`) actually resolves.
- **Fix:** `_find_icon_at_size` now uses `find -L`. Papirus-Dark resolves
  12/12 at the requested 22px size.
- **Files:** `hypr/.config/hypr/scripts/icon-theme-picker.sh`
- **Commit:** 340b59bc

**3. [Rule 1 - Bug] `Row.implicitHeight` is read-only — crashed the whole launcher**
- **Found during:** Task 4, surfaced by a coincidental host event (see Issues
  Encountered below), not by any gate
- **Issue:** `IconMode.qml`'s horizontal strip assigned `implicitHeight: 148`
  directly on a `Row` (a Positioner). Positioners compute `implicitHeight`
  from their children and refuse a direct assignment. Quickshell's config
  loader treats this as a fatal type-load error: `Type IconMode unavailable`
  cascaded up through `Launcher.qml` to `Type Launcher unavailable` —
  the ENTIRE launcher (all modes, not just Icons) would have failed to load
  on the next reload.
- **Fix:** removed the assignment; the Row's implicit height already comes
  from its tallest child (the 140px tiles).
- **Files:** `quickshell/.config/quickshell/modules/launcher/IconMode.qml`
- **Commit:** 2c24d219

**4. [Rule 1 - Bug] `hypr-equivalence-check`'s binds.json PASS branch discarded every accepted-note**
- **Found during:** Task 5, verifying the four new `ACCEPTED_ADDITIONS`/
  `ACCEPTED_REMOVALS` entries actually fired
- **Issue:** the `options.jsonl` branch already prints `$diff_out` (the
  accepted-note lines) on BOTH pass and fail (`[[ -n "$diff_out" ]] && echo
  "$diff_out"`). The `binds.json` branch immediately below it was missing
  that same line — every accepted-addition/removal note was silently
  discarded whenever the gate passed. This defeated the gate's own stated
  guarantee ("a stale entry that does not fire is itself reported, so a
  mis-typed identity cannot pass silently") on exactly the path that
  matters — a green run — and affected every prior accepted rebind in this
  gate's history, not just this task's four.
- **Fix:** added the identical guard to the `binds.json` PASS branch.
- **Files:** `hypr/.config/hypr/scripts/hypr-equivalence-check`
- **Commit:** 5487ea79

---

**Total deviations:** 4 auto-fixed (4× Rule 1 — all bugs, all found and fixed
before their task's commit). No scope creep; no architectural changes.

## Issues Encountered

**A transient, unrelated Wayland/compositor crash coincided with Task 3's
close (08:22:59), triggering `quickshell.service`'s `Restart=on-failure`
policy (systemd, not me — the hard prohibition on restarting quickshell from
this shell was never violated).** The crash itself (`The Wayland connection
experienced a fatal error: Invalid argument`) is unrelated to this task's
QML — it matches the class of NVIDIA+Wayland flakiness already on record for
this host. Its side effect was useful: the resulting fresh config load
surfaced Deviation 3 above (`IconMode.qml`'s `Row.implicitHeight` bug) that a
running engine's incremental hot-reload would not otherwise have
re-evaluated, since `qmllint`/`qmlformat` are blind on this host and the only
real QML-load-error signal is the running shell's own reload log. Confirmed
fixed: the shell reached a clean `Configuration Loaded` state afterward and
stayed there through every subsequent edit (same PID, `179750`, throughout
Tasks 4-5).

**MenuTree.qml's two `command:` fields still contain the literal strings
`icon-theme-switch.sh`/`font-switch.sh`** (kept "for the record", mirroring
this file's own pre-existing `theme-switch.sh` precedent — see Task 5
Commit B's own message for the full reasoning). A naive grep for those
filenames outside `#`/`--`/`//`-comment lines still matches these two lines.
Confirmed NOT a live reference (`row.appearance` is checked and returns
before `row.command` is ever reached in `MenuMode.qml`'s `activate()`), and
confirmed this is the SAME shape the codebase already ships for
`theme-switch.sh` (also deleted, also kept in a `command:` field). Not a
defect — documented in the Task 5 Commit B message.

**The two shim deletions (`icon-theme-switch.sh`, `font-switch.sh`) landed in
Task 5 Commit A instead of Commit B**, because `git rm` had already staged
them during editing, before the two-commit split was executed. Both commits
are still independently correct and gate-passing (the deletions don't affect
`hypr-equivalence-check` at all); this is a packaging deviation, not a
functional one.

## Operator Round 1 — nine defects, all nine closed

Reported after live use. Five commits, `534fcafd`..`6075ef1f`, all pushed.
**The recurring theme: the build had drifted from the study artifact**, which
the operator correctly held as the source of truth.

| # | Defect | Root cause | Fix |
|---|--------|-----------|-----|
| 1 | No uninstall | Never built — `grep -c "uninstall\|-Rs"` = 0 | `pacman -Qoq` ownership resolution + confirm overlay + terminal handoff (`6075ef1f`) |
| 2a | No title bar | `title: "Appearance"` was set but no header row rendered | The study's `.surf-hd`: name + live `N themes · M families` sub (`534fcafd`) |
| 2b+2d | Fonts grouped wrong / duplicates | **One defect, and it was presentation, not measurement** | Group by family in the rail; variants in the detail pane (`6668476d`) |
| 2c | Rails not resizable | No grips existed in any appearance file | Shared `AtRailGrip`, scene-anchored, persisted (`eb83bf3e`) |
| 2e | Icons had no detail pane | Bare `GridView`, no rail, no compare | Rail + detail + compare, previewing at **22px** (`4bbbaf5e`) |
| 3 | No drag-to-move | Never built | `startSystemMove()` from the title bar (`534fcafd`) |
| 4 | Size reset on reopen | Nothing persisted; size recomputed from screen every open | `width`/`height` watched and persisted, clamped (`534fcafd`) |

**THE ONE THAT MATTERED MOST WAS MINE, AND IT WAS A PRESENTATION BUG WEARING A
MEASUREMENT'S CLOTHES.** The M2 collapse in `AppearanceBackend.qml:328-390` was
CORRECT all along — it emits 13 families x 2 behaviours, exactly as measured.
But `AtFontsTab.qml:68` rendered those 26 rows in a FLAT list keyed on
`modelData.family`, so the list read "FiraCode / FiraCode / JetBrainsMono /
JetBrainsMono / …". **A correct measurement, thrown away one layer up.** The
operator read it as "you did not deal with duplicate fonts" and was right about
the symptom while the cause sat in the view, not the model. Defects 2b and 2d
were never two defects.

**THE ICONS TAB QUIETLY DEFEATED ITS OWN FOUNDING MEASUREMENT.** It previewed at
48px — the exact size at which M1 proved Papirus / Papirus-Dark / Papirus-Light
are byte-identical. The tab could not distinguish three of the eight themes it
listed, which is the whole reason the 22px finding existed. Now 22px.

**TWO ITEMS WERE VERIFIED POSSIBLE BEFORE BEING PROMISED**, rather than assumed:
`startSystemMove`/`startSystemResize` are real methods on
`FloatingWindowInterface`, and `width`/`height` are writable (not read-only) on
`ProxyWindowBase` — both read out of
`/usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes`. Also confirmed
no windowrule pins the Atelier's geometry, so QML owns its size.

**UNINSTALL IS NOT ONE-TO-ONE, AND A NAIVE VERSION WOULD HAVE BEEN DESTRUCTIVE.**
`Adwaita` resolves to **two** packages — `adwaita-cursors` AND
`adwaita-icon-theme` — so removing "the Adwaita icon theme" on a single-package
assumption takes the cursor theme with it. Every affected package is now listed
before anything runs. Separately, `~/.local/share/icons/Papirus` and
`Papirus-Dark` are **unowned** user-directory copies that shadow the system
ones; those have no package to remove and are shown as an explicit path
deletion. Active theme/font carries its own warning. Privilege posture matches
`PackagesBackend` exactly — verified 0 hits for `pkexec|sudo|--noconfirm`
outside comments.

**Recovered work, not re-done work.** The executing agent died mid-round with
defect 1 uncommitted (5 modified files + an untracked `AtUninstallConfirm.qml`).
The work was assessed on disk rather than assumed lost or assumed good: it
loaded clean (zero errors after the last `Configuration Loaded`, by line
position), passed all four gates, and matched the brief on every case, so it was
committed as-is.

Gates after the round: `colour-lint` 566/0, `motion-lint` 751/0,
`qml-import-check` 0 unresolved / 190 files, `settings-index-check` 191/0.

### Still owed after round 1

Everything below the line remains unrun — no agent shell on this host can
click, screenshot, or restart. Round 1 adds these:

1. Drag the title bar — does the window move, and do tab clicks still register?
2. Resize, close, reopen — does it come back the size you left it?
3. Fonts tab — 13 family rows, not 26; clicking one shows its variants.
4. Icons tab — do Papirus / Papirus-Dark / Papirus-Light look **different** at 22px? This is the founding measurement; if 22px does not separate them either, the preview needs a different probe set.
5. Compare button on the Icons detail pane.
6. Drag each rail (Icons, Fonts, Catalogue) — width persists across reopen.
7. Uninstall an icon theme; confirm the package list is right before letting it run. **Try `Adwaita` specifically** — it must list two packages.
8. Uninstall an unowned user-dir theme (`~/.local/share/icons/Papirus`) — it should offer a path deletion, not a package removal.

## Operator Round 2 — three defects, all root-caused by measuring first

`123f6544`. **Every one had a cause the round-1 code review did not catch,
because the code read correctly in all three cases.**

**1. Size persistence did not fail on the write path — it succeeded with the
wrong value.** The decisive measurement was `prefs.json`, not the source: it
held `atelierWidth: 760, atelierHeight: 480` — **both minimums to the pixel** —
while `iconsRailWidth: 233` and `catalogueLeftWidth: 432`, written through the
SAME Prefs path, had persisted fine. So Prefs worked and the value was wrong.
`onWidthChanged`/`onHeightChanged` also fire during LazyLoader teardown, where
`width` collapses toward 0; round 1's `Math.max(760, 0)` turned that into 760
and wrote it, so **every close overwrote the operator's real size with the
clamp floor.** The clamp was the bug: clamping converts an invalid sample into
a plausible one, making bad data indistinguishable from a deliberate minimum.
Invalid samples are now rejected (`!visible`, or below `minimumSize`), never
clamped.

**2. Selection highlight was the same role as the surface behind it.** Rows
were `Colours.surfaceVariant`; the Atelier's body panel IS `surfaceVariant`
(`Atelier.qml`'s `surfaceBase` at 0.78 opacity). The detail pane updated
correctly the whole time — which is exactly what "they expand on the right but
do not get highlighted" describes. **Fourth recurrence of this class in this
shell** after the Dial track and 14-10's GPU ring: a widget that draws nothing
is usually the same colour as its backing surface, not broken data. Both
identity comparisons were sound (`string === string` in Icons, `.family ===
.family` in Fonts) — I checked those first and they were a dead end. The study
had already specified the answer and the build diverged from it: `.frow.sel` is
`rgba(255,121,198,.13)` plus `border-left: 2px solid var(--stage-acc)`. Now the
accent at 13% plus a real 2px accent bar, neither able to collide with a
surface role. Applied to the tab bar too, which had the same collision.

**3. The chips did follow the palette — just not the shell's resting
treatment.** `compareChip` already rested quiet (transparent fill, outline
border, `onSurfaceVariant` label) and took the accent only when ACTIVE.
Apply/Install/Uninstall instead wore full-strength `primary`/`error` border AND
label at all times, several to a screen, on a `surfaceVariant` panel. That
inconsistency is what read as "too bright and does not follow theme". Accent is
now reserved for hover and genuine state; accent-for-real-state (the active
theme's name, the search cursor) was deliberately left alone.

**A WRONG HYPOTHESIS, KILLED BY MEASUREMENT BEFORE IT COST ANYTHING.** I
suspected `Atelier.qml:171`'s
`Qt.rgba(win.surfaceBase.r, win.surfaceBase.g, win.surfaceBase.b, …)` was the
recorded pure-black bug (Colours roles are strings, so `.r/.g/.b` are
undefined). It is not: `surfaceBase` is declared `readonly property color`, so
the string is coerced and the components are valid — same as `Workbench.qml`,
which carries a comment recording exactly why. Checking beat asserting, and it
was that check which surfaced the real cause of defect 2.

Gates after the round: `colour-lint` 566/0, `motion-lint` 751/0,
`qml-import-check` 0 unresolved / 190 files, `settings-index-check` 191/0.
Live load verified clean by line position — last `Configuration Loaded` at line
9221 of 9225, zero errors after it.

### Known residue

`prefs.json` still holds the poisoned `760x480` from before the fix. It was
deliberately NOT hand-edited: the live shell keeps Prefs in memory
(`watchChanges: false`) and would overwrite a disk edit. **The window will open
at minimum size once more; the first resize after that persists correctly and
permanently.**

## Operator Round 3 — four items, all pre-root-caused, all implemented

`17a7b7f0`..`7e4ef134`, three commits, all pushed-pending. The operator supplied
the diagnosis for all four items with live measurements this round — the brief
was explicit: do not re-diagnose, implement. All four landed.

| # | Item | Commit |
|---|------|--------|
| 1 | Rail/tab-bar highlight + button language | `17a7b7f0` |
| 2+3 | Difference-aware compare + extended probe set | `4bb56576` |
| 4 | Menu word routes (`icon`/`font`/`pkg` from Super-tap menu) | `7e4ef134` |

**Item 1 — copied `WbSidebar.qml`'s treatment verbatim, twice diverged from
before.** The operator's own measurement stood: `surfaceVariant` ==
`primaryContainer` == `secondaryContainer` == `#44475a` in the live Dracula
palette, and the Atelier's body panel IS `surfaceVariant`. `WbSidebar.qml:87`'s
fix — give the rail its own `Qt.alpha(Colours.surface, 0.55)` backdrop BEFORE
drawing a container-role selection on top of it — is what makes
`Colours.primaryContainer` legible at all; without that backdrop the same
collision the operator flagged twice would recur a third time. Applied to the
Icons rail, Fonts rail, Catalogue's left pane, and `AtTabBar.qml`'s strip (the
operator named this one explicitly too — same panel, same collision). Removed
round 2's 13%-accent-tint-plus-2px-bar entirely; kept only the applied-theme/
font label accent (`railRow.active ? Colours.primary : …`) as the one marker
distinguishing "applied" from "selected for viewing", per the brief. Every
hand-rolled chip — `AtIconsTab`'s `applyChip`/`compareChip`/`uninstallChip`,
`AtFontsTab`'s uninstall chip, `AtCatalogueTab`'s `installButton`,
`AtUninstallConfirm`'s primary/cancel buttons — replaced with `packages/
WbButton`. Tones: Apply = "primary" (Icons tab's single main action);
Catalogue's per-row Install = "ghost" (many per screen, never the pane's one
action); every Uninstall = "danger"; Compare/Cancel/OK = "ghost".

*Known limitation, not a deviation:* `WbButton` has no toggled/active visual
state — it only has `tone` (primary/ghost/danger) and `enabled`. The Icons
tab's Compare button used to visually invert when toggled on; it now only
changes its own LABEL ("Compare with Papirus" → "Hide compare"), no colour
change. This is the direct cost of "one button language, not two" — a second,
richer chip shape was exactly what round 2 was asked to stop doing.

**Items 2+3 — converged into one difference-aware compare, live-measured
before picking probe names.** Rather than trust the operator's category-level
finding blind, every candidate probe name was verified directly on this host
with `md5sum` against the actual `_find_icon_at_size` resolution chain (not
just `ls`, since Papirus-Light's `actions/` and Papirus-Dark's `panel/` are
whole-directory symlinks into Papirus — a naive per-file scan would have
missed that and mis-picked a probe). Two names, exactly matching the operator's
own category-level counts:

- `edit-copy` (`actions/`) hashes `[Papirus=A, Papirus-Dark=B, Papirus-Light=A]`
  — resolves in 6 of the 8 installed themes (every theme but Adwaita), matching
  "present in 6 of 8 themes" precisely.
- `indicator-messages` (`panel/`) hashes `[Papirus=A, Papirus-Dark=A,
  Papirus-Light=B]` — resolves in exactly 3 of 8 (Papirus, Papirus-Dark,
  Papirus-Light only), matching "present in only 3 of 8 themes (panel is a
  Papirus-ism)" precisely. (The first panel candidate tried, `ac-adapter`,
  measured 4/8 — AdwaitaLegacy also carries a legacy PNG of it — so it was
  swapped for `indicator-messages`, which measured exactly 3/8.)

Built as a new `--preview-diff <theme> [sz]` script verb (same
`<probe>\t<path-or-'-'>` shape as `--preview`, reusing `_find_icon_at_size`)
plus `AppearanceBackend.diffPreviewFor()` — its OWN queue/process/cache,
deliberately not folded into the primary 12-probe queue, so the rail's `X/12`
coverage number is never touched by this addition. The Icons tab detail pane
now has three sections instead of two: the primary 12-icon grid (recognisable,
unchanged, hidden only while actively comparing so nothing renders twice), a
Compare section that pairs each of the 12 probes' selected+baseline icons
side by side and SORTS differing ones first (`detail._pairs`), and a
"Distinguishing probes" secondary strip (always visible, pairs with the
baseline once Compare is on) reporting its own honest "N of 2 available for
&lt;theme&gt;" — Adwaita/breeze/elementary show `0/2` or `1/2` and a
placeholder cell, never folded into or inflating the 12-probe number.

**Item 4 — one-line reorder, exactly as directed.** `_routeQuery()` now checks
`_wordRoutes` before the `_stickyModes` bail, using the identical match test
it already had (`lower === word || lower.indexOf(word + " ") === 0`) — so
typing "icon"/"font"/"pkg" from Super-tap menu mode now routes out, while an
ordinary menu-filter keystroke ("c", "col", "settings") still can't collide
with a route word, since it never matches that test. `wallpaper`/`systeminfo`
sticky modes get the identical fix incidentally (same `_stickyModes` table),
though the operator only reported it for menu mode.

**Deviations: none.** All four items matched their stated root cause exactly;
no Rule 1-4 fixes were needed beyond what the brief already specified.

Gates after this round: `qml-import-check` 0 unresolved / 190 files,
`colour-lint` 566/0, `motion-lint` 751/0, `settings-index-check` 191/0 — run
after EACH commit, not just once at the end. `~/.cache/quickshell.log` read
after every edit via byte-offset tail; every hot reload after this round's
edits settled reached a clean `Configuration Loaded` with zero errors
following it (one transient bracket-mismatch mid-edit on `AtCatalogueTab.qml`
self-corrected within the same edit sequence, before that file's commit).

### Operator checklist — round 3 (nothing below could be seen from this shell)

Same standing limitation as rounds 1-2: no input-injection tool, `grim`
crashes this NVIDIA host, and restarting quickshell/`quickshell-doctor` are
both forbidden from this shell. All of the following are new with this round
and remain **unrun**:

1. Icons/Fonts rails and the Catalogue's left pane — does the new
   `Qt.alpha(Colours.surface, 0.55)` backdrop read as a visible, distinct
   panel-within-a-panel, and does a selected row's `primaryContainer` fill
   now actually contrast against it?
2. `AtTabBar.qml` — same question for the tab strip.
3. Every WbButton — Apply (primary), Install/Compare/Cancel/OK (ghost),
   Uninstall (danger) — do the three tones read distinctly against the new
   backdrops, and does "Installed"/disabled read as dimmed rather than dead?
4. Icons tab, Compare toggle on Papirus-Dark vs Papirus (or Papirus-Light vs
   Papirus) — does the side-by-side grid render, do differing probes sort
   first, and does the summary line read correctly ("N of 12 differ" /
   "12 of 12 identical")?
5. The "Distinguishing probes" strip — for Papirus/-Dark/-Light, do
   `edit-copy` and `indicator-messages` visibly show DIFFERENT icons between
   variants? For Adwaita/breeze/elementary, does it show honest placeholders
   and a low/zero "N of 2 available" count without looking broken?
6. Super-tap the launcher into menu mode, type `icon` — does it jump straight
   to the Icon Specimen mode? Same for `font` and `pkg`. Then re-open the menu
   and type an ordinary filter word (e.g. `col` for Colour picker) — does it
   still fuzzy-filter the current menu level rather than routing away?

## Operator Round 4 — repeat complaint closed at the class, two items landed

`8e9d5f58`..`070f5f85`, three commits, all pushed-pending. Item 1 was the
operator's explicit repeat complaint: "You keep repeating this issue."

| # | Item | Commit |
|---|------|--------|
| 1 | Full button sweep — fix WbButton at source, add button-lint gate | `8e9d5f58` |
| 2 | Catalogue rows now selectable, with a real detail pane | `69225f2e` |
| 3 | Instant selection / animated hover; SelectRow palette-scrim leak closed | `070f5f85` |

**Item 1 — WHY THIS KEPT RECURRING, AND WHY IT WON'T AGAIN.** Rounds 1-3
"fixed" the button class by moving hand-rolled chips INTO `WbButton`, but
never fixed `WbButton` itself — `tone: "primary"` painted a SOLID
`Colours.primary` fill at rest, `tone: "danger"` painted a full-strength
`Colours.error` border AND label at rest. The destination was exactly as
loud as what it replaced, which is why the operator kept seeing the same
brightness on new widgets (`Uninstall`, the Fonts tab's "propo" chip) after
each round. Fixed at the SOURCE this time: every tone now keeps its LABEL
at `Colours.onSurface` at rest — the label is what draws the eye — and
confines accent to border/fill, which is a light tint at rest (primary:
`Qt.alpha(Colours.primary, 0.16)`; danger: transparent fill,
`Qt.alpha(Colours.error, 0.5)` border) and only deepens on hover or the
new `active` prop (primary hover: `0.28`; danger hover: `0.18` fill +
full-strength border AND label, the one tone that still amplifies on
hover, matching an irreversible action). `active` is the toggled/on-state
round 3 recorded as missing — it renders like hover-at-rest without
needing the pointer present, wired to the Icons tab's Compare button and
the Fonts tab's Mono/Propo/Apply chips (their "currently applied" state).

Converted the two remaining hand-rolled button-likes — `AtFontsTab.qml`'s
Mono/Propo/Apply "vchip" (the exact "propo" button the operator named) and
`AtCatalogueTab.qml`'s Re-check pill — to `WbButton`. `appearance/` now has
exactly one button implementation; measured with a parser (13 interactive
elements: 7 `WbButton`, 6 correctly-left-alone raw `MouseArea`s — rail
rows, tabs, the uninstall-confirm backdrop), not a grep.

**The recurrence-prevention gate.** New `hypr/.config/hypr/scripts/
button-lint`: deny-by-default, flags a `Rectangle` with its own `radius:`
that has a DIRECT `Text` child AND a DIRECT `MouseArea{onClicked}` child
lacking `hoverEnabled: true`. That last clause is what lets rows/tabs pass
WITHOUT a name-based allowlist — verified against the real files, not
invented: every row/tab/list delegate in this tree sets `hoverEnabled:
true` because its background depends on `containsMouse`; neither retired
chip (`vchip`, Re-check) ever bothered with hover tracking at all. Text
wrapped inside an intermediate `Row`/`Column` (every rail row, the
catalogue result row) is a GRANDCHILD, not a direct child, so those never
even reach the `hoverEnabled` check. `AtTabBar.qml`'s tab pill is the one
shape structurally CLOSE to a button (`Text` and `MouseArea` both direct
children, sized from the label like a chip) and is exactly the case the
`hoverEnabled` clause exists to separate correctly. **Poison-tested**: ran
the gate against the real PRE-FIX tree — it FAILED at both
`AtFontsTab.qml:299` (vchip) and `AtCatalogueTab.qml:288` (Re-check),
while passing `AtTabBar.qml` — then again with 5 committed self-test
fixtures (3 compliant, 2 poisoned, replaying the exact vchip/Re-check
shapes) — before converting either file, so the gate is proven to fail,
not merely asserted to. Live scan post-fix: 9/9 clean. Self-test: 5/5.

`packages/WbDetail.qml` (the one other `WbButton` consumer, outside this
task) was checked structurally, not visually: its six `WbButton` usages
(2 primary, 2 ghost, 1 danger, 1 conditional primary/danger) reference only
`label`/`tone`/`enabled`/`onActivated` — none of the props renamed or
removed — so every call site still binds correctly and nothing broke at
the API level. The new lighter-fill visual on its primary/danger buttons
is unverified (could not screenshot); flagged below.

**Item 2 — the same defect in a new costume.** `AtCatalogueTab.qml:184`'s
row `MouseArea` had NO `onClicked` at all — confirmed by direct read
before touching anything. Added `selectedName`/`_selectedEntry`, an
`onClicked` that selects, and the SAME `primaryContainer`/hover-tint
treatment the Icons/Fonts rails and tab strip already carry. Selecting a
row now populates a real detail card above the install log — name, source
(repo/AUR), version, installed state — not only a visual highlight, per
the brief's own "a selection that does nothing is the same defect in a new
costume." `AppearanceBackend.qml`'s `_parseCatalogueBlock` gained version
capture, verified live against both `pacman -Ss papirus-icon-theme`
("extra/papirus-icon-theme 20260801-1 [installed]") and `paru -Ss -a
icon-theme` ("aur/numix-icon-theme-git 21.10.31.r0.g7a28092dd-1 [+437
~0.26]") — version is the third whitespace token in both sources on this
host. The Install button's own `MouseArea` (inside `WbButton`, layered
above the row's background `MouseArea` by declaration order) was already
isolated from the row click by z-order before this change; verified
unchanged, not re-architected.

**Item 3 — two unrelated causes sharing one symptom.** The rails/tab/
catalogue fix and the SelectRow fix are NOT the same bug wearing two
costumes — they're genuinely different mechanisms that both read as
"laggy"/"flashy":

- *Rails, tab strip, catalogue selection:* each row's single combined
  `color` binding + one `Behavior on color` animated EVERY colour change
  — hover AND selection alike — at `Motion.colourDuration` (300ms, live-
  measured). Split into two layered fills per row: `selectFill` (an
  instant `visible` toggle, no `Behavior` at all — a hard cut) for the
  discrete selection state, `hoverFill` (the original animated `Behavior`,
  untouched) for the continuous hover state. Applied identically across
  `AtFontsTab.qml`, `AtIconsTab.qml`, `AtTabBar.qml`, and the new
  `AtCatalogueTab.qml` row.
- *SelectRow.qml's documented flash:* re-measured rather than trusted.
  Read the installed Basic style directly
  (`/usr/lib/qt6/qml/QtQuick/Controls/Basic/{Menu,MenuItem}.qml`, no
  `QT_QUICK_CONTROLS_STYLE` set on this host, confirmed via `systemctl
  --user show-environment`) side by side with this file: `Menu.background`
  and `MenuItem.background` were **already** overridden with `Colours.*`
  roles before this round — the file's own comment named the RIGHT class
  of bug (Qt's Basic-style defaults reading `control.palette.midlight`/
  `.light`/`.window`) but the fix it describes was already in place; there
  was no live leak on either of those two properties to close. Reading the
  same installed `Menu.qml` surfaced a genuinely still-open leak the
  comment never named: `T.Overlay.modal`/`T.Overlay.modeless` default to
  `Color.transparent(control.palette.shadow, 0.5/0.12)` — the popup's own
  scrim — and neither was ever overridden in this file. Closed with
  `Qt.alpha(Colours.background, …)`, the exact idiom
  `AtUninstallConfirm.qml`'s own modal backdrop already uses. Separately,
  gave `menuItem.down` its own immediate, un-animated `Colours`-based fill
  (`Qt.alpha(Colours.primary, 0.12)`) — previously a press painted NOTHING
  until `highlighted` caught up 300ms later, which reads exactly like "a
  flash before the highlight settles" with zero palette involvement at
  all. The existing `highlighted` border ring and its `Behavior` are
  untouched, as instructed.

**Deviations: none of Rules 1-4** — every fix matched a directly measured
cause. One documented correction to the brief's own premise: item 3's
SelectRow instruction assumed `Menu.background`/`MenuItem.background`
were still leaking; direct measurement showed they were not, so the actual
fix landed one layer over (`Overlay.modal`/`modeless`) plus the
`down`-state timing gap — same class of bug (a QQC2 default reading
`palette.*`, and a discrete-state-change animated too slowly), different
exact property, found by re-measuring rather than trusting the file's own
older comment at face value.

Gates after this round, run after EACH commit: `colour-lint` 566/0,
`motion-lint` 766/0, `qml-import-check` 0 unresolved/190 files,
`settings-index-check` 191/0, `button-lint` 9/9 (new gate, self-test 5/5).
`~/.cache/quickshell.log` read after every edit via ANSI-stripped,
`grep -a`'d tail, positions compared against the last `Configuration
Loaded` line by absolute line number (not `head`/`tail` guesswork); every
edit in this round reached a clean reload with zero errors after it, and
each check's log mtime was confirmed strictly newer than the edited
file's own mtime before trusting it.

### Operator checklist — round 4 (nothing below could be seen from this shell)

Same standing limitation as every prior round: no input-injection tool, no
`grim` (crashes this NVIDIA host), and restarting quickshell/
`quickshell-doctor` are both forbidden from this shell. All of the
following are new with this round and remain **unrun**:

1. Every `WbButton` — Apply/Review (primary), Compare/Cancel/OK/Install/
   Re-check/Mark-explicit (ghost), Uninstall/Queue-removal (danger) — does
   the new light-tint-at-rest, deepen-on-hover treatment actually read as
   calmer than round 3's shape, and does danger still read unambiguously
   once hovered (border+fill+label all amplify to full error)?
2. Icons tab Compare button, and the Fonts tab's currently-applied Mono/
   Propo chip — does `active` visibly read as "toggled on" (the deepened
   hover-at-rest fill) even with the pointer elsewhere?
3. `packages/WbDetail.qml`'s six `WbButton`s (Update/Review/Mark-explicit/
   Queue-removal) — unrelated to this task's own files, but they inherit
   the new tone logic automatically. Do they still read correctly, or did
   the lighter fill make anything here too subtle?
4. Catalogue tab: click a row — does it highlight AND populate the new
   detail card (name/source/version/installed) above the log? Click
   Install on a DIFFERENT row than the one selected — does it still work
   without requiring selection first?
5. Click a rail row (Icons/Fonts), a tab, or a catalogue row — does the
   selection highlight snap in INSTANTLY (no cross-fade), while hovering
   an unselected row still fades in smoothly?
6. Open any settings dropdown menu (e.g. Appearance → theme/icon picker) —
   press-and-hold an item: does anything still flash light grey before the
   highlight ring settles? This is the one item this round could NOT
   verify even indirectly — the fix targets `Overlay.modal`/`modeless` and
   `menuItem.down`, neither of which this shell can render.

## Operator Checklist — everything below needs a human

None of the 17 items in the plan's own `<operator_checklist>` could be run
from this agent shell — no input-injection tool exists here, `grim`
screenshots crash this NVIDIA host, and restarting quickshell/running
`quickshell-doctor` are both forbidden. All 17 remain **unrun**, verbatim
from the plan:

1. `Super+I` opens the Atelier on the Icons tab.
2. `Super+Shift+F` opens the same window on the Fonts tab; re-aims if already open on Icons.
3. `Super+Shift+I` opens the code editor; `Super+Shift+M` maximizes; `Super+F` unchanged.
4. `Super+Shift+Z`/`Super+Shift+X` now do nothing.
5. Papirus/Papirus-Dark/Papirus-Light look visibly different in the Icons tab.
6. Thin-coverage themes (Adwaita, breeze) show visible placeholders + an honest coverage count.
7. Each Fonts-tab row renders in its own font; two rows per family (Mono/Propo), not three.
8. Clicking a theme/font applies it — desktop re-themes, notification fires.
9. Click-outside dismisses the Atelier; mouse-out does not.
10. `Esc` closes the window.
11. Launcher `icon` route: strip appears, word painted in accent, arrow keys walk it, Enter applies.
12. Launcher `font` route: same; `fontconfig` stays an ordinary app search.
13. Catalogue tab: search returns repo+AUR rows; Install closes the Atelier, opens a clickable terminal.
14. After install, reopening the Atelier shows the before/after diff and the new theme in Icons.
15. Resize the Atelier and reopen it — the tab you left on is the tab you return to.
16. Bar clock drawer's Font/Icon Theme cells open the launcher on the new routes.
17. `quickshell-doctor --self-test` (operator-only — it restarts the shell internally).

## What was verified live from this shell (everything a static gate or a log
read CAN prove)

- `bash -n` clean on both stripped scripts; `--list` still enumerates (8 icon
  themes, 39 raw font names); `--preview <theme> 22` emits 12 tab-separated
  rows for every installed theme.
- `hyprctl reload` + `hypr-equivalence-check`: **PASS: 3 FAIL: 0**, all four
  new bind entries firing as accepted notes; `hyprctl -j binds` directly
  confirms modmask 65 I/M present, 65 Z/X absent, 64 I/F/Z/X/M unchanged.
- `keybind-doctor`: **13 passed, 0 failed**. `stow-link-check`: **2 passed, 0
  failed**.
- `qml-import-check`: **0 unresolved / 188 files** (up from 180).
  `colour-lint`: **560/0** (up from 536). `motion-lint`: **745/0** (up from
  721). `settings-index-check`: **191/0** (unchanged, no settings-page
  structure touched beyond the two repointed SelectRows).
- `~/.cache/quickshell.log`: read at every task boundary via byte-offset
  tail; zero errors naming any new file after each task's edits settled;
  quickshell's own `Configuration Loaded` line confirms every hot reload
  succeeded.

## Next Phase Readiness

Nothing blocked. The Atelier's Catalogue tab retires the v5.0 ICON-BROWSE
roadmap candidate (struck this task). All five plan tasks landed with their
own `<verify>` blocks green; the four deviations above were all bugs found
and fixed before their owning task's commit, never deferred.

## Self-Check: PASSED

All 10 claimed files exist on disk; all 6 claimed commit hashes are present in `git log`.

## Operator round 5

Two population-scale items, both directly measured before touching code.

**Commits:**
- `55a8d8d4` — item 1: transparent-interpolation sweep (25 files)
- `edb32364` — item 2: shared row press surface (`RowSurface.qml`) + WbButton press state (11 files)
- `e9f68c80` — item 3: `transparent-lint` gate + fixtures (5 files)

### Item 1 — transparent-interpolation flash, shell-wide

Root cause (operator's own ground truth, confirmed by direct measurement,
not re-derived): `"transparent"` in QML is `#00000000` — black at zero
alpha. Every animated `color`/`border.color` ternary using the literal
`"transparent"` as its off-branch alongside a `Behavior` interpolated
through dark tones on the way to/from the real hue — that dark smear is
the flash.

Enumerated the population myself with a parser-equivalent method (grep +
context read of every `"transparent"`/`Behavior on (color|border.color)`
pair, verified per-site by reading the actual block structure, not
counted mechanically) rather than trusting the operator's own count
verbatim, per the standing "never guess, measure" rule. Result: **27 real
animated-transparent sites, redistributed slightly differently than the
operator's own per-file census but the same total** —
`settings/common/SelectRow.qml` has 2 real sites, not 3 (the third
candidate, `menuItem.down`'s fill, is already immediate/non-animated by
round 4's own design — correctly not a site); `settings/NavRail.qml` has
2, not 1 (both its `isCurrentPage` row fill and its search-result
`border.color` ring are genuinely animated). Every other file in the
operator's list had exactly the 1 site named.

**Beyond the operator's own census:** re-scanning the whole tree for any
animated-transparent site NOT in the 24-file list surfaced a 28th —
`packages/WbButton.qml`'s own `color:` JS function had three
`"transparent"` branches (disabled state, danger-tone rest, ghost-tone
rest) under one `Behavior on color`, live on every WbButton on every
hover/tone/disabled transition shell-wide (Update/Review/Uninstall/
Compare/Re-check/Mark-explicit — every button in the workbench and the
Atelier). Fixed in the same commit as the rest of the sweep, since it's
the identical bug class.

Fix shape throughout: replace the literal `"transparent"` branch with
`Qt.alpha(<the hue this branch fades to/from>, 0)` — same zero alpha,
correct hue, so the transition crosses "real colour fading out" to "real
colour fading in" instead of through black. For `WbButton.qml`'s
disabled-state branch specifically, added a `_restHue` property deriving
the tone's own base hue (primary/error/onSurface) so the disabled fade
also lands on the right colour family rather than an arbitrary one.

Left alone (measured, not assumed): every bare, non-conditional
`color: "transparent"` base fill that sits beside an animated
`border.color` in the same block (the pre-round-5 shape every settings
row used) — that property is never animated, so it never interpolates.
Two mechanical-scan false positives were checked and confirmed harmless:
`bar/ClockActionsCapsule.qml`'s `property color fillColour: "transparent"`
is a property DEFAULT gated by `visible: cellItem.fillActive` (never
visible while at its default, so the transition never renders); and
`launcher/IconMode.qml`'s only real `color:` ternary already used
`Qt.alpha(...)` on both branches — the nearby `"transparent"` grep hit
was an unrelated sibling Rectangle's static border-only fill.

### Item 2 — shared row press surface + WbButton press

Ground truth confirmed by direct read of all 8 named row components: 6
are `Control`-rooted (NavRow, SelectRow, SliderRow, StepperRow, TextRow,
ToggleRow), 2 are `Item`-rooted (InfoRow, WallpaperTile) — not the
6/3 split in the operator's own ground truth (which would total 9, one
too many for 8 rows); the actual split is 6/2. Each declared its own
`rowFocused` border-ring background, no shared base, and none painted
anything on press.

Built `settings/common/RowSurface.qml` — one shared `focused`/`hovered`/
`pressed` background, declared in `qmldir`. `focused`/`hovered` keep the
exact existing animated border-ring behaviour (OR'd together internally,
matching every row's own prior `(rowFocused || hover) ? accent :
transparent` shape byte-for-byte in rendered result). `pressed` is new:
an immediate, un-animated neutral fill (`Qt.alpha(Colours.onSurface,
0.13)`, no `Behavior` at all) — a press must read as instant, not a
300ms fade (the exact bug item 1 just fixed, reapplied here as a design
rule for the new state).

Used as `background:` for the 7 Control/Item primitives that fit the
slot (NavRow, SelectRow, SliderRow, StepperRow, TextRow, ToggleRow,
InfoRow). Press wiring measured per row's actual click target rather
than assumed uniform:
- **NavRow** — its own whole-row `hoverArea` MouseArea already has a
  native `pressed`; wired directly.
- **SelectRow/SliderRow/StepperRow/ToggleRow** — none has a whole-row
  MouseArea (each uses a passive `HoverHandler` for hover specifically
  so it never steals clicks from an inner MouseArea — dropdownPill/
  track/steppers/switchPill). Added a sibling `TapHandler {
  gesturePolicy: TapHandler.PassiveOnly }` per row, same non-exclusive
  reasoning as the existing `HoverHandler`, to observe press without
  grabbing it.
- **InfoRow** — no `pressed:` wire at all. Its own file header states
  "this row does nothing when clicked" (PD-07, pre-existing, not
  something this round introduced) — the premise that InfoRow needs
  press feedback is false for a non-interactive row, so it gets
  `focused:` only, deviation documented per the item's own instruction
  rather than inventing a click target that doesn't belong.
- **TextRow** — no `pressed:` wire. Its click target is the inner
  `TextField`, which already paints its own background/state
  independently; the row-level ring is a pure focus indicator.

**WallpaperTile** — its layered image/badge/active-ring/hover-tint
overlay structure doesn't fit `RowSurface`'s single `background:`-slot
pattern (it's an image tile with multiple stacked Rectangles, not a
Control with one swappable background), so per the constraint ("if a
file needs structural change to accept the shared surface, say so
rather than restructuring it silently") it does NOT use `RowSurface`
directly. It gets the SAME idiom applied by hand instead: a new
un-animated sibling Rectangle over its existing animated hover-tint
Rectangle, driven by its own `hover.pressed` (the tile's existing
whole-tile MouseArea already has a native `pressed`, no new handler
needed).

**WbButton.qml** — added the same `selectFill`/`hoverFill` split round 4
used for the Atelier: the existing animated `color`/`Behavior on color`
stays as the rest/hover fill unchanged, and a new instant, un-animated
overlay Rectangle deepens one step further per tone (primary 0.38/danger
0.28/ghost 0.16 alpha) while `area.pressed` — the button's own existing
MouseArea already has a native `pressed`.

Every press tint stays in the same restrained neutral/tone-matched
language existing hover fills already use — never a new accent colour,
per the operator's three prior rejections of loud accents (rounds 2-4).

### Item 3 — `transparent-lint` gate, poison-tested

Added as a SIBLING to `button-lint` (not an extension of it) — `button-
lint` is deliberately scoped to `modules/appearance/`'s hand-rolled-
button class; this defect was shell-wide and about colour-animation
semantics, which matches `colour-lint`'s own whole-tree
`$HOME/.config/quickshell` scope far more closely. Reused button-lint's
comment-stripping/brace-tracking/block-parsing infrastructure rather
than writing a second parser from scratch, extended with a `Behavior on
<property>` block-open form so a `Behavior on color` block is
distinguishable from `Behavior on border.color` by type — the gate
matches the ANIMATED property exactly, not "any Behavior nearby."

**A real bug was found and fixed during this gate's own hardening,
before it was ever trusted:** the first implementation built each
property's "value text" from a raw `lines[start:end+1]` slice. Running
it against the real tree (not just the self-test fixtures) immediately
surfaced a false positive on `launcher/IconMode.qml`'s icon-tile
Rectangle — its OWN `color:` ternary contains no `"transparent"` at all,
but a completely unrelated NESTED Rectangle's `color: "transparent"`
(a static border-only fill three properties later) sat between two
blank "own" lines in the raw slice and got silently absorbed. Fixed by
tracking each span as the explicit list of un-nested line indices and
joining only those lines' text, never a contiguous range. This is
exactly the class of bug the "run gates once, but run new gates against
the REAL tree before trusting them" discipline exists to catch — a gate
that only ever sees its own fixtures never learns this failure mode.

**Poison-tested against a real site, per the item's own instruction (not
just the fixtures):** reverted `settings/common/RowSurface.qml`'s
`border.color` to its literal-`"transparent"` pre-fix shape — gate went
RED (`RowSurface.qml:56 animated border.color branch...`). Restored —
gate green again. `--self-test` also passes 4/4 against its own
committed fixtures under `tests/transparent-fixtures/` (2 compliant: the
`Qt.alpha` idiom, and a non-animated conditional-transparent that must
NOT be flagged; 2 poisoned: the single-line-ternary shape and the
WbButton-style multi-line-JS-function shape). `button-lint --self-test`
re-run afterward, unmodified — still 5/5.

### Gates after this round

`colour-lint` 569/0 (up from 566 — RowSurface.qml + WbButton.qml's new
press-fill Rectangle add scannable colour-assignment anchors).
`motion-lint` 769/0 (up from 766). `button-lint` 9/9, self-test 5/5
(unchanged, sibling gate not modified). `qml-import-check` 0
unresolved/192 files (up from 190 — RowSurface.qml new, plus
transparent-lint's fixtures excluded from the real-tree scan by design).
`settings-index-check` 191/0 (unchanged focus-row count — confirms no
row's structure/geometry/keyboard-reachability changed, only its
background implementation). New gate `transparent-lint`: 192/0 clean on
the real tree (191 files + the scan-count floor check), self-test 4/4,
poison-tested against a real site as required.
`~/.cache/quickshell.log` read after every edit via ANSI-stripped tail;
zero new errors after any edit in this round, `Configuration Loaded`
confirmed after each hot reload.

### Deviations from plan

**1. [Item 2 premise correction] InfoRow does not get press feedback.**
The item named all 8 rows uniformly; direct read of InfoRow's own header
comment ("this row does nothing when clicked", pre-existing PD-07
design, not introduced this round) shows it has no click target at all.
`RowSurface`'s `pressed` prop is simply never wired for this row —
documented rather than inventing a click gesture that contradicts the
row's own stated design.

**2. [Item 2 structural note] WallpaperTile does not consume
`RowSurface` directly.** Its layered image/badge/ring overlay structure
doesn't fit the single-`background:`-slot pattern the other 7 rows
share. Applied the identical idiom (immediate, un-animated, neutral
tint) by hand as a sibling overlay Rectangle instead of forcing the
shared component in — flagged per the constraint rather than silently
restructuring the tile.

**3. [Item 1 addition, Rule 1 — bug] `WbButton.qml` swept too.** Not in
the operator's named 24-file/27-site list, found by re-scanning the
whole tree. Same bug class (animated `"transparent"` branches), fixed in
the same commit as the rest of item 1.

None of Rules 2-4 applied — no missing critical functionality discovered
beyond the two feedback gaps the operator already named, no architectural
changes needed.

### Operator checklist — round 5 (nothing below could be seen from this shell)

Same standing limitation as every prior round: no input-injection tool,
no `grim` (crashes this NVIDIA host), restarting quickshell/
`quickshell-doctor` both forbidden from this shell. All of the following
are new with this round and remain **unrun**:

1. Open Settings and hover, then click-and-hold, any row across every
   page (NavRow/SelectRow/SliderRow/StepperRow/TextRow/ToggleRow/
   InfoRow) — does the press now read as an immediate response (a visible
   tint appearing the instant the mouse goes down), distinct from the
   animated focus/hover ring?
2. Open the Wallpaper picker and press-and-hold a tile — same question,
   for the tile's own deeper hover-tint press state.
3. Click any `WbButton` (Workbench Update/Review/Uninstall, Atelier
   Compare/Re-check/Mark-explicit) and hold — does it now visibly deepen
   further on press, on top of its existing hover fill?
4. Open any settings dropdown menu (SelectRow's own popup) and open the
   Atelier's rail/tab/catalogue selections — does the previously-reported
   flash (a dark smear before the real colour settles) read as gone now
   that every animated transition fades through the correct hue instead
   of through black?
5. Does `SliderRow`'s row-level press tint interfere with actually
   dragging the slider track, or does the drag gesture still work
   uncontested (the `TapHandler`'s `PassiveOnly` policy is designed not
   to compete, but only a live drag can confirm it doesn't)?
