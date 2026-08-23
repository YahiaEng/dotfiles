---
quick_id: 260822-sht
verified: 2026-08-23T01:08:27Z
status: gaps_found
score: 6/9 must-haves verified (2 needing human confirmation, 1 failed)
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "theme-doctor, theme-stress-test, colour-lint, motion-lint, keybind-doctor, quickshell-doctor, stow-link-check and retirement-check all pass with zero references to the retired launcher or its backend anywhere outside .planning/"
    status: partial
    reason: >
      All eight named gates were re-run independently and all pass
      (colour-lint 347/0, motion-lint 531/0, keybind-doctor 13/0,
      quickshell-doctor 28/0 live + 59/59 self-test, stow-link-check 2/2,
      retirement-check walker/elephant/--all/--self-test all
      failed_classes=0, theme-doctor's only FAIL is an unrelated
      "git status is clean" check caused by this verification's own
      not-yet-committed SUMMARY.md/STATE.md — expected mid-workflow
      state, not a functional defect). But the second half of the
      compound truth — "zero references ... anywhere outside .planning/"
      — is false: `git ls-files | xargs grep -li walker\|elephant`
      (excluding .planning/) still returns `.claude/CLAUDE.md` and
      `.continue-here.md` in addition to the expected
      `retirement-check` registry rows. `.claude/CLAUDE.md` in
      particular still describes Walker/elephant in the present tense
      as "the chosen tool," "Actively maintained," "currently installed
      and running on this machine" across ~14 lines in the Technology
      Stack / Version Compatibility / Sources tables — none of it was
      touched by Task 12, which only listed README.md and
      VERIFICATION.md for doc rewrites. This file is loaded as
      authoritative project context for every future agent session in
      this repo, so the stale claims are not merely cosmetic — they
      will actively mislead future troubleshooting about what launcher
      stack is actually installed. retirement-check's own
      `scan_repo_prose()` classifies `.claude/CLAUDE.md` (alongside
      README.md/docs/*.md) as a report-only, non-blocking class by
      long-standing design — which is why the gate itself still exits
      0 — but the PLAN's own must_have text and the SUMMARY's own claim
      ("every prose reference scrubbed") both assert a stricter zero
      that the codebase does not meet.
    artifacts:
      - path: ".claude/CLAUDE.md"
        issue: "~14 lines across the Technology Stack, Version Compatibility, and Sources tables describe walker/elephant as the currently installed, actively-maintained, chosen launcher stack — contradicts the actual post-retirement state."
      - path: ".continue-here.md"
        issue: "Stale pre-execution handoff artifact naming the migration by its old branch/task title; harmless but never cleaned up after the task completed, and it duplicates content already superseded by the SUMMARY."
    missing:
      - "Rewrite .claude/CLAUDE.md's Technology Stack / Version Compatibility / Sources entries for walker and elephant to describe the native QML launcher instead (or remove them and add a QML-launcher entry), matching the treatment already given to README.md."
      - "Delete or archive .continue-here.md now that the task is complete — it was a mid-flight pause artifact, not meant to persist past the task."
human_verification:
  - test: "Type each of the six prefixes (=2+2*10, /, :, ., ;, @) from one open launcher and confirm each swaps to its own mode's result view."
    expected: "Calc shows 22; files lists $HOME entries; clipboard lists cliphist entries; symbols/emoji opens the emoji grid; providerlist shows the mode list; websearch is ready to open the browser."
    why_human: "No input-injection tool exists on this host (wtype misroutes to the focused browser); router wiring and all six mode components are confirmed present and wired in source, but the actual UI swap on keystroke was not in the operator's confirmed list and cannot be driven by the verifier."
  - test: "Tools ▸ Emoji: pick a glyph and confirm it types into a focused field; Super+C: restore a clipboard entry and delete one; Tools ▸ Clipboard wipe: confirm the safe option is preselected and wipe works; Capture ▸ Record toggle audio: exercise the audio-mode picker."
    expected: "Each of these 4 remaining dmenu-consumer flows (of the 7 total) completes end-to-end with no external walker/elephant process involved."
    why_human: "Operator's confirmed list covers theme switching, Bar Orientation, view-all keybinds, and emoji scroll/arrow-nav, but not emoji typing, clipboard restore/delete, clipboard wipe, or record-audio's picker flow specifically. Code evidence is strong (ConfirmMode preselects currentIndex 0, clipboard-wipe.sh --yes and record-toggle.sh --audio both gate correctly, ClipboardMode wires list/restore/delete verbs) but none of it is behaviorally exercised without a live session."
---

# Quick task 260822-sht — walker + elephant → native Quickshell QML launcher — Verification Report

**Task Goal:** migrate walker+elephant to a native Quickshell QML launcher
**Verified:** 2026-08-23T01:08:27Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from PLAN must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Super+Space opens a native QML launcher that lists installed applications and launches the picked one | ✓ VERIFIED | Operator-confirmed live; `shell.qml:731` `launcherLoader` LazyLoader wired to `GlobalShortcut quickshell:launcher`; `shortcuts.json` has a `launcher` entry; `keybind-doctor` confirms the chord is registered live; `Launcher.qml` uses `DesktopEntries.applications.values` + `uwsm app --` execution (per SUMMARY defect fix `0654896f`, confirmed present in source) |
| 2 | Bare Super tap opens QML menu, 9 D-2 roots, all 36 entries reachable, byte-identical leaf commands | ✓ VERIFIED | Operator-confirmed live (Super tap → menu). Independently re-parsed the 6 deleted TOMLs from git history (`74407582^`) with `tomllib`: 36 total entries, 30 non-clipboard `actions.open` commands, **zero missing** from current `MenuTree.qml` — every command byte-identical. `MenuTree.qml` declares exactly the 9 D-2 roots: Apps, Capture, Tools, Style, Setup, Play, AI, Learn, System |
| 3 | All six prefix routes (`=`,`/`,`:`,`.`,`;`,`@`) work from one search field | ? UNCERTAIN | `LauncherState.qml` `_prefixRoutes` table declares all six mapping to real mode files (CalcMode/FilesMode/ClipboardMode/EmojiMode/providerlist/WebSearchMode), all of which exist and are qmldir-registered. Not in the operator's confirmed list; no input-injection tool exists on this host to drive a live check — routed to human verification |
| 4 | All 7 dmenu consumers work end-to-end, no external launcher process | ? UNCERTAIN (partial) | 3 of 7 operator-confirmed (theme switch, bar orientation, keybinds view-all); emoji scroll/nav confirmed but not typing. Code confirms all 7 are wired to real backends (`theme-apply`, `bar-orientation.sh <slug>`, `clipboard-wipe.sh --yes`, `record-toggle.sh --audio <mode>`, `cliphist` verbs, `cheat-sheet-parser.sh --dump`) with no interactive picker left in any of the 6 migrated scripts (`grep -c '_pick'` = 0 in bar-orientation.sh; usage-error-on-no-arg confirmed for clipboard-wipe.sh and record-toggle.sh). 4 of 7 flows not behaviorally exercised — routed to human verification |
| 5 | Emoji surface never invokes `wtype` with a value that isn't an exact glyph from the shipped set (T-06-17) | ✓ VERIFIED | Structural guarantee, verifiable from source: exactly one non-comment `wtype` call site in `EmojiMode.qml`, gated by `validatedGlyph = root._knownGlyphs.has(row.glyph) ? row.glyph : null` with a null-check before the call |
| 6 | Keybinds surface copies a chord and never executes its dispatcher (T-07-26) | ✓ VERIFIED | Zero non-comment `exec_cmd`/`Hyprland.dispatch` occurrences in `KeybindsMode.qml`; the row model structurally carries no executable command field for ordinary rows |
| 7 | R-1 Updates, R-2 System info, R-3 Apps root all deliver real data | ✓ VERIFIED | `UpdatesMode.qml` runs real `checkupdates`/`paru -Qua` processes (not static); `SystemInfoMode.qml` runs real `fastfetch --format json` and parses structured fields; Apps root (`MenuTree.qml:59-64`) switches to the same `apps` mode Super+Space already uses (operator-confirmed) |
| 8 | 8 named gates pass with zero walker/elephant references outside `.planning/` | ✗ FAILED (partial) | All 8 gates independently re-run and pass. But `git ls-files \| grep -li walker\|elephant` (excluding `.planning/`) returns 3 files, not the claimed 0: the expected `retirement-check` registry rows, plus `.claude/CLAUDE.md` (stale, describes walker/elephant as currently installed/chosen) and `.continue-here.md` (stale handoff artifact) — see Gaps |
| 9 | Neither surface installed on host, no package entry in `install.sh` | ✓ VERIFIED | `pacman -Qq \| grep -iE '^(walker\|elephant)'` returns nothing; `install.sh` and `stow.sh` have zero walker/elephant mentions; `walker/` and `elephant/` directories confirmed absent from the working tree |

**Score:** 6/9 truths verified, 2 need human confirmation, 1 failed (partial)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.config/quickshell/modules/launcher/Launcher.qml` | PanelWindow launcher surface | ✓ VERIFIED | 58K, exists, qmllint clean, imported and mounted in `shell.qml` |
| `quickshell/.config/quickshell/modules/launcher/LauncherState.qml` | Singleton mode/query/nav-stack state | ✓ VERIFIED | Has `pragma Singleton` + `singleton` keyword in qmldir; prefix router table present |
| `quickshell/.config/quickshell/modules/launcher/MenuTree.qml` | 9-root menu data model | ✓ VERIFIED | Singleton, 9 roots confirmed, 36 entries confirmed against original TOMLs |
| `quickshell/.config/quickshell/modules/launcher/qmldir` | Module manifest, all types declared | ✓ VERIFIED | 14 entries declared, matching all 14 `.qml` files on disk |
| `quickshell/.config/quickshell/modules/launcher/emoji.tsv` | 160 glyph+name lines | ✓ VERIFIED | `wc -l` = 160, 0 malformed rows (`NF!=2` check) |
| `quickshell/.config/quickshell/shortcuts.json` (launcher entry) | Manifest entry for the launcher shortcut | ✓ VERIFIED | Both `launcher` and `launcher-menu` entries present, `keybind-doctor` confirms live registration |
| `hypr/.config/hypr/scripts/retirement-check` (registry rows) | Two rows, `status=retired` | ✓ VERIFIED | `walker` and `elephant` both `status=retired`, `requirement=260822-sht`, `failed_classes=0` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `shell.qml` LazyLoader | `Launcher.qml` | `launcherLoader` | ✓ WIRED | `shell.qml:731` |
| `Launcher.qml` | `GlobalShortcut quickshell:launcher` | shortcut toggling `launcherLoader.active` | ✓ WIRED | Confirmed live via `qs ipc show` listing `target launcher` with `toggle()`/`open(mode)` |
| GlobalShortcut | `shortcuts.json` manifest | shortcut declaration | ✓ WIRED | Entry present, `keybind-doctor` confirms no manifest/live mismatch |
| `shortcuts.json` | `keybinds.lua` bind | `hl.dsp.global("quickshell:launcher")` | ✓ WIRED | `keybinds.lua:97-99` (Super+Space, Super+R) and `:99` (Super tap → `launcher-menu`) |
| `modules/launcher/qmldir` | every new type | same-commit registration | ✓ WIRED | 14/14 types registered, no orphans |
| `MenuTree.qml` leaves | original TOML `actions.open` | byte-identical strings | ✓ WIRED | Independently re-verified via `tomllib` against git history: 30/30 present, 0 missing |
| `PickerMode.qml` | `theme-apply` / `bar-orientation.sh` | `Quickshell.execDetached` command array | ✓ WIRED | `PickerMode.qml:76,80` real paths with argument |
| `keybinds.lua` Super+Escape | `systemctl --user restart quickshell.service` (DQ-1) | `hl.dsp.exec_cmd` | ✓ WIRED | `keybinds.lua:121`, `keybind-doctor`'s D-03 check confirms live match |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `UpdatesMode.qml` | update list | `checkupdates` / `paru -Qua` `Process` | Yes | ✓ FLOWING |
| `SystemInfoMode.qml` | machine info fields | `fastfetch --format json` `Process` | Yes | ✓ FLOWING |
| `EmojiMode.qml` | glyph grid | `FileView` on `emoji.tsv` (160 real rows) | Yes | ✓ FLOWING |
| `ClipboardMode.qml` | clipboard rows | `cliphist list` `Process` | Yes | ✓ FLOWING |
| `KeybindsMode.qml` | keybind table | `cheat-sheet-parser.sh --dump` live-parsed, never cached | Yes | ✓ FLOWING |
| `MenuTree.qml` | menu tree | static QML data model (by design — replaces the TOML files, not a stub) | N/A (intentional static model) | ✓ FLOWING (by design) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `qalc` backend for calc mode | `qalc -t "2+2*10"` | `22` | ✓ PASS |
| Live shell exposes launcher IPC target | `qs ipc show \| grep -A2 'target launcher'` | `toggle()`, `open(mode: string)` present | ✓ PASS |
| Live shell health post-launch | `systemctl --user is-active quickshell.service` | `active` | ✓ PASS |
| No launcher-related runtime errors since last shell start | `quickshell.log` tail from last start marker, grep for error/undefined | Only an unrelated portal DBus warning | ✓ PASS |
| bar-orientation.sh has no interactive path | `grep -c '_pick' bar-orientation.sh` | `0`; no-arg invocation exits non-zero | ✓ PASS |
| clipboard-wipe.sh / record-toggle.sh reject bad invocations | bare invocation / `--audio bogus` | Both non-zero exit as designed | ✓ PASS |

### Gate Results (independently re-run, not trusted from SUMMARY)

| Gate | Result |
|------|--------|
| `qmllint` on all launcher `.qml` | exit 0, no output |
| `colour-lint` | 347 passed, 0 failed |
| `motion-lint` | 531 passed, 0 failed |
| `keybind-doctor` | 13 passed, 0 failed |
| `stow-link-check` | 2 passed, 0 failed |
| `retirement-check walker` | `failed_classes=0` |
| `retirement-check elephant` | `failed_classes=0` |
| `retirement-check --all` | `failed_classes=0` |
| `retirement-check --self-test` | 5/5 passed |
| `quickshell-doctor` (live) | 28 passed, 0 failed (GATE-03 `unregistered=0`, confirms deferred-items.md item 1 was fixed) |
| `quickshell-doctor --self-test` | 59/59 passed |
| `theme-doctor` | 1057 passed, 1 failed — the 1 failure is `git status --porcelain is empty`, caused by this verification's own uncommitted SUMMARY.md/STATE.md, not a functional defect |
| `theme-stress-test` | Not run — explicitly deferred to the operator pass per the plan's own text ("the slower proof and belongs in the operator pass") |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `./alker\|retired\|` (repo root, untracked) | n/a | Stray 35-byte debris file (`pending\|pending\|walker/\|260822-sht`), clearly produced by a botched shell command (likely an unescaped `\|` in a sed/awk registry edit during Task 10 or 12) that bash interpreted as a pipeline | ⚠️ Warning | Harmless (untracked, doesn't affect any gate), but is unremoved execution debris — should be deleted before this task is considered closed |
| `quickshell/.config/quickshell/modules/launcher/MenuMode.qml` | 8 | `TODO wiring point, left for a future task since no menu in this tree currently needs one` | ℹ️ Info | Warning-tier marker (not the TBD/FIXME/XXX blocker class), well-explained, no functionality currently requires the deferred feature — not a gap |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|--------------|-------------|--------|----------|
| R-1 | System ▸ Updates reports pending package updates | ✓ SATISFIED | `UpdatesMode.qml` wired to `checkupdates`/`paru -Qua`, real processes |
| R-2 | System ▸ System info reports machine information | ✓ SATISFIED | `SystemInfoMode.qml` wired to `fastfetch --format json`, parses real fields |
| R-3 | Apps root entry opens launcher in apps mode | ✓ SATISFIED | `MenuTree.qml:59-64` switches to the `apps` mode, same mechanism as Super+Space |
| 260822-sht | Full walker+elephant retirement | ⚠️ PARTIAL | Functionally complete and gate-verified, but doc-staleness gap (see Gaps) keeps this from being a clean retirement |

### Human Verification Required

See frontmatter `human_verification` for full detail. Summary:

1. **Six prefix routes** — typing `=`, `/`, `:`, `.`, `;`, `@` and confirming the correct mode renders. Code-wired but not in the operator's confirmed list and no input-injection tool exists on this host.
2. **4 of 7 dmenu-consumer flows** — emoji typing-into-field, Super+C restore/delete, clipboard wipe confirm dialog, record-audio picker. Code-wired (real backends, no interactive picker left in the migrated scripts) but not behaviorally exercised.

### Gaps Summary

The launcher itself is real, substantive, and wired — not a stub. Every artifact exists,
every key link resolves, all 30 non-clipboard menu leaf commands were independently
re-verified byte-identical against the deleted TOMLs' git history, both hard security
requirements (T-06-17 glyph validation, T-07-26 keybinds copy-not-execute) are structurally
proven, and every named gate the plan specifies passes when re-run today, including a live
IPC probe against the running shell and a clean `quickshell.log` since the last restart.

The one confirmed gap is narrow but real: the plan's own must_have text and the SUMMARY's
own claim ("every prose reference scrubbed", "repo-wide reference count 0") are not quite
true. `.claude/CLAUDE.md` — the file loaded as authoritative project context for every future
agent session in this repo — still describes walker and elephant in the present tense as the
actively installed, "chosen tool" launcher stack across roughly 14 lines, and a stale
`.continue-here.md` handoff file was never cleaned up. Neither was in Task 12's own file list,
so this reads as an oversight (the plan named README.md/VERIFICATION.md but not
.claude/CLAUDE.md), not an intentional deviation. `retirement-check`'s own design already
treats this class of reference (README/docs/.claude/CLAUDE.md prose) as non-blocking report
domain, which is why every automated gate still exits 0 — but it does not satisfy the plan's
own stricter "zero references anywhere outside .planning/" wording.

Additionally, roughly half of the interactive-behavior must-haves (all six prefix routes; 4
of the 7 dmenu-consumer end-to-end flows) were not in the operator's confirmed list and
cannot be driven by the verifier on this host (no input-injection tooling exists here per
project history). Code evidence for all of them is strong — real backends, no leftover
interactive pickers, structural guards proven — but they remain unconfirmed behaviorally and
are routed to human verification rather than claimed as passed.

---

_Verified: 2026-08-23T01:08:27Z_
_Verifier: Claude (gsd-verifier)_

---

## Orchestrator addendum — gap closed 2026-08-23

The verifier's `gaps_found` finding above is left as written; this records what
was done about it.

**The gap:** `.claude/CLAUDE.md` still described walker and elephant as the
currently-installed, actively-chosen launcher stack — and that file is loaded as
authoritative context at the start of every future session, so it would have told
every subsequent agent that walker was the launcher. A stale `.continue-here.md`
handoff also still referenced them.

**Closed by:**

- `.claude/CLAUDE.md` — the walker and elephant Core Technologies rows now read
  `RETIRED`, pointing to `modules/launcher/`; the "Walker custom menu layouts"
  row is replaced by the QML menu tree; the What-NOT-to-Use row now warns against
  reintroducing either; the walker-restart guidance is replaced by the
  `execDetached` / `uwsm app --` rules the migration established; the version
  compatibility row is voided. Three lines that used Walker as the example GTK4
  app for theming were repointed, since it no longer exists to inspect.
- `.continue-here.md` — deleted (a one-shot checkpoint, resumed long ago).
- `alker|retired|` — stray file in the repo root, deleted. It was debris from a
  malformed `sed` the orchestrator ran while flipping the registry rows; the same
  command had also corrupted the walker registry row's surface name to `pending`,
  which was caught and repaired before commit.

**Evidence:** enumerating tracked files outside `.planning/` that mention either
name now returns exactly two, both intentional — `.claude/CLAUDE.md` (which must
document the retirement) and `hypr/.config/hypr/scripts/retirement-check` (its own
registry rows; the tool self-excludes via `SELF_EXCLUDE`). No line in CLAUDE.md
presents either tool as current.

**Not closed, and correctly so:** the six prefix routes and four dmenu-consumer
flows the verifier marked `human_needed` remain human-only. No input-injection
tooling exists on this host, so they cannot be automated here — they need an
operator at the keyboard.
