---
phase: 11-quickshell-viability-gate
plan: 02
subsystem: keybind-regression-gate
tags: [hyprland, keybind-doctor, quickshell, global-shortcut, bash, awk, shellcheck]
dependency-graph:
  requires:
    - "quickshell/.config/quickshell/shortcuts.json (plan 01)"
    - "hypr/.config/hypr/config/keybinds.conf's `global, quickshell:probe` bind (plan 01)"
  provides:
    - "A working keybind-doctor: cross-checks Hyprland's plain-text bind registry against declared config"
    - "A working Quickshell-shortcut cross-check: manifest vs. hyprctl globalshortcuts, plus a purely-static chord-collision detector"
    - "Amended ROADMAP.md/REQUIREMENTS.md wording matching the delivered mechanism (D-15)"
  affects:
    - "Plan 03 (quickshell-doctor) — calls keybind-doctor as one of its checks; now green"
    - "Phases 14 and 16 — each add a new global keybind; the detector must work before then"
tech-stack:
  added: []
  patterns:
    - "Plain-text hyprctl output parsing with a named shape-guard check (never re-adopt structured/-j output for this compositor query)"
    - "ASCII Unit Separator (0x1f) as an inter-process field delimiter instead of tab, because bash's `read` collapses adjacent IFS-whitespace characters (tab included), silently swallowing empty fields"
    - "Declared-manifest cross-checked against a live compositor registry, used when the owning application (Quickshell) itself exposes no introspection API"
key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/keybind-doctor
    - hypr/.config/hypr/config/keybinds.conf
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md
decisions:
  - "Dropped hyprctl binds -j / jq entirely from keybind-doctor; Hyprland 0.56.0's structured serializer for that query is field-misaligned (values shifted relative to keys), not merely malformed — a syntax-only repair would have produced confidently wrong data. Plain-text hyprctl binds is field-correct on this build and is what the file parses now."
  - "Rejected a self-healing auto-switch-back probe (try -j, fall back to plain text on parse failure) — a future build where -j parses cleanly but still misaligns fields would sail through such a probe undetected."
  - "Used ASCII Unit Separator (0x1f), not tab, as the field delimiter between the awk parser and the bash consumer — bash's read collapses adjacent tab characters (tab is IFS-whitespace), which silently ate the empty key field on every code:NNN keycode bind and shifted every later field left by one."
  - "hyprctl globalshortcuts is also parsed as plain text (not -j), for the same discipline, even though its -j output was independently verified clean on this build — consistency with the rest of the file outweighed the marginal simplicity of mixing structured and plain-text parsing across two different compositor queries."
  - "The Quickshell shortcut manifest is the declared side; hyprctl globalshortcuts is the live side (D-16/D-17) — Quickshell 0.3.0 has no GlobalShortcut runtime-introspection API, but the compositor exposes a queryable registry of what actually got claimed, which gets D-16's intended benefit under D-17's fallback shape."
  - "The chord-collision check is purely static (file-under-test + manifest only, no live hyprctl query) so a throwaway fixture that was never reloaded into the compositor can still fail on exactly that check."
  - "Fixed a pre-existing missing trailing newline in keybinds.conf (Rule 1 bug fix) — it silently corrupted the append-based poisoned-fixture mechanism the file's own header documents as its self-test method."
metrics:
  duration: "~25 min (11:43-11:49 across 3 task commits)"
  completed: 2026-07-26
status: complete
---

# Phase 11 Plan 02: Repair keybind-doctor and cross-check Quickshell global shortcuts Summary

Repaired `keybind-doctor` from a state where it crashed on Hyprland 0.56.0's field-misaligned JSON bind query and false-negatived all 78 declared binds, to a working plain-text-parsing regression gate (13 passing checks, 0 failures), then extended it to cross-check Hyprland `bind =` lines against Quickshell's `GlobalShortcut` manifest and Hyprland's own live global-shortcut registry — proving the collision detector actually fires on a poisoned fixture before trusting it.

## What Was Built

**Task 1 — Plain-text bind parser (D-14).** Replaced the broken `hyprctl binds -j` + `jq` cross-check block (lines 137-194 of the original file) with a plain-text parser over `hyprctl binds`'s blank-line-delimited blocks. The block-type header token (`bind`, `bindl`, `bindle`, `bindr`, `bindm`) varies and is never treated as a fixed prefix — verified directly that a `bindel = ...` declaration surfaces here as `bindle` (letters reordered). A named shape-guard check asserts the expected 8-field layout survives; all four original checks (declared-vs-registered, no shadowing, release-bind inventory, D-03 kill-bind) were re-expressed against the new parser with equivalent semantics. Lines 1-136 (header, `check()`, mainMod resolution, declared-tuple parse, description parity, static `walker -s` grep) are byte-identical to the pre-change file.

A real bug surfaced mid-implementation: bash's `read` collapses adjacent tab characters (tab is IFS-whitespace), which silently dropped the empty `key` field on every `code:NNN` keycode bind (screenshot/record bindings) and shifted every subsequent field left by one — corrupting 4 of 79 declared binds into false "not registered" reports. Fixed by switching the parser/consumer delimiter from tab to ASCII Unit Separator (`0x1f`), which bash does not treat as collapsible whitespace.

**Task 2 — Quickshell shortcut cross-check (D-16/D-17).** Extended the CLI to `keybind-doctor [keybinds.conf] [shortcuts.json]` (second arg defaults to `$HOME/.config/quickshell/shortcuts.json`, first arg's meaning unchanged). Quickshell 0.3.0 has no `GlobalShortcut` runtime-introspection API, so the manifest is the declared side and `hyprctl globalshortcuts` (also parsed plain-text, same discipline as Task 1) is the live side. Four new checks, each independently failable:
1. Manifest schema — valid JSON array, non-empty `appid`/`name`/`chord.mods`/`chord.key`.
2. No duplicate `appid`+`name` — RESEARCH.md Pitfall 4: a duplicate pair can crash Quickshell at startup with no log line naming the cause.
3. Registered — every manifest entry appears in the live `hyprctl globalshortcuts` registry.
4. Chord collision — purely static (file-under-test + manifest only): fails if any Hyprland-declared bind claims a manifest-owned chord without going through the matching `global` dispatcher.

A missing manifest produces `[SKIP]`, not a failure, so the gate still works on a machine that never stowed `quickshell/`.

**Task 3 — Proven-to-fail proof + wording amendment (D-15/D-18).** Built a throwaway poisoned fixture (a copy of `keybinds.conf` plus one line claiming the `quickshell:probe` chord via `exec` instead of `global`), ran it (exit 1, `chord collision` named as the failure), then ran the real config immediately after (exit 0, 13/13 green). Amended `ROADMAP.md` criterion 4 and `REQUIREMENTS.md`'s `MAINT-01` line, per D-15: both had asserted structured `hyprctl binds -j` parsing and an exclusive-zone claim readable from `hyprctl layers -j` — neither is true on this build (`layers -j` carries no exclusive-zone field at all; the real reservation lives in `hyprctl monitors -j`'s `reserved` array, currently `[0,46,0,0]`, all waybar's). Both amendments name the mechanism this build actually delivers and point at the evidence artifact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Tab-delimiter field collapse in the plain-text bind parser**
- **Found during:** Task 1, first live run (4 of 79 binds false-reported as "not registered")
- **Issue:** Used tab (`\t`) as the field delimiter between the awk parser and the bash consumer. Bash's `read` treats tab as IFS-whitespace and collapses adjacent occurrences, silently discarding the empty `key` field on every `code:NNN` keycode bind and shifting all subsequent fields (keycode, release, dispatcher, arg) left by one.
- **Fix:** Switched the delimiter to ASCII Unit Separator (`$'\x1f'`), which bash's `read` does not collapse. Verified all 79 declared binds now correctly resolve (`missing: 0`).
- **Files modified:** `hypr/.config/hypr/scripts/keybind-doctor`
- **Commit:** `98a07da`

**2. [Rule 1 - Bug] Missing trailing newline in `keybinds.conf` silently corrupted the poisoned-fixture mechanism**
- **Found during:** Task 3, first poisoned-fixture attempt (fixture did not fail — investigated why)
- **Issue:** `hypr/.config/hypr/config/keybinds.conf` had no trailing newline. Appending a fixture line via `printf ... >> file` (exactly as the plan's own verify script and the file's header-documented self-test procedure both do) concatenated the new line onto the file's last existing line instead of starting a new one, producing a non-bind line the parser correctly ignored — making the collision check falsely appear to pass.
- **Fix:** Added the missing trailing newline (whitespace-only change, no bind semantics affected). Re-ran the exact literal verify script from the plan afterward; it now correctly reports the fixture failing.
- **Files modified:** `hypr/.config/hypr/config/keybinds.conf`
- **Commit:** `01bb3f1`

### Design choice worth flagging (not a deviation, but not literally specified)

**`hyprctl globalshortcuts` parsed as plain text, not `-j`.** Independently verified that `hyprctl globalshortcuts -j` produces clean, non-misaligned JSON on this build (`[{"name": "quickshell:probe", "description": ""}]`) — unlike the bind query. The plan's action text asked to "parse what it actually emits" without mandating a format; I chose plain text anyway, for consistency with the rest of the file's now-uniform "never trust a compositor JSON serializer" discipline, and because the registry currently holds only one entry, which isn't enough live data to independently confirm the JSON path stays clean under load. Documented in the evidence artifact's D-14 record-why section.

## Known Stubs

None — no stub patterns (hardcoded empty values, placeholder text, unwired data) introduced by this plan.

## Threat Flags

None — all new surface (manifest parsing, live-registry parsing, CLI second argument) was already covered by the plan's own threat model (T-11-06/07/08/09) and mitigated per the acceptance criteria (no `eval`/`source`/backtick expansion over any parsed value; verified via grep).

## Verification

- `keybind-doctor` exits 0 on the real config: **13 passed, 0 failed**.
- `grep -vE '^\s*#' keybind-doctor | grep -c 'binds -j'` → 0; same for `LIVE_JSON`.
- `shellcheck keybind-doctor` → exit 0, no warnings.
- Poisoned fixture (D-18): exit 1, `chord collision` named as the failure; real config immediately after: exit 0, 13/13. Fixture directory deleted; `git status --porcelain` clean of any `keybinds`-named file outside `hypr/.config/hypr/config/`.
- Duplicate-`appid`+`name` manifest fixture: exit non-zero, only the duplicate check fails.
- Unregistered-shortcut manifest fixture (using an unclaimed chord to isolate the check): exit non-zero, only the `registered` check fails, naming `quickshell:nonexistent`.
- Manifest moved aside: `[SKIP]` printed, overall exit 0.
- `grep -c 'binds -j' .planning/ROADMAP.md .planning/REQUIREMENTS.md` → 0 in both.
- `git diff --stat .planning/ROADMAP.md` → 1 file changed, 1 insertion(+), 1 deletion(-) (scoped).

## Self-Check: PASSED

- FOUND: `hypr/.config/hypr/scripts/keybind-doctor` (modified, shellcheck clean, exits 0 live)
- FOUND: `hypr/.config/hypr/config/keybinds.conf` (trailing-newline fix present)
- FOUND: `.planning/ROADMAP.md` amendment present, scoped diff confirmed
- FOUND: `.planning/REQUIREMENTS.md` amendment present
- FOUND: `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` MAINT-01 section present
- FOUND commit `98a07da` (Task 1) in `git log`
- FOUND commit `c9d9450` (Task 2) in `git log`
- FOUND commit `01bb3f1` (Task 3) in `git log`
