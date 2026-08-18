---
quick_id: 260818-ne8
date: 2026-08-18
status: complete
commits:
  - 047aca4
  - bdd9646
  - 16a08a9
---

# Quick Task 260818-ne8 — Summary

Two of the four items under "Known carried debt" in
`.planning/milestones/v4.0-MILESTONE.md` are closed: the SC-3 surviving-prose
item and the Hyprland `options.jsonl` equivalence-exemption item.

## What shipped

### 1. `.claude/CLAUDE.md` — four materially-wrong entries corrected (047aca4)

The file presented four surfaces deleted in v4.0 as the current or planned
stack. That is not a cosmetic prose hit — it is a live instruction file, and an
agent reading it would have been told to use a notification daemon and an OSD
daemon that are uninstalled from repo *and* host.

| Was | Now |
|---|---|
| L7 listed `swaync` and `wleave` among themed components | Names the Quickshell shell as the owner of bar, notifications, OSD, power menu and media |
| L36 `swaync 0.12.6 ... already chosen` | RETIRE-03 (19-08) retired it; the Quickshell root *is* the session notification server; the `swaync-client -rs` post_hook is gone |
| L42 `swayosd 0.3.1 ... for the planned OSD indicators` | RETIRE-04 (20-09) retired it and its libinput service; points at `modules/osd/Osd.qml`, and carries the brightness-unverifiable caveat |
| L73 recommended `swayosd` over `wob` | Now a "never on this stack" row explaining *why* an external OSD daemon was deleted |

The twelve already-correct mentions are untouched, including the research
sources list — rewriting that would falsify the record of what was searched.

### 2. Four `docs/superpowers/` design docs bannered (bdd9646)

165 of SC-3's 183 hits lived in four historical design docs. Each now opens with
a banner naming the retired surface(s), the retiring requirement and plan, and
where the replacement lives. **Bodies untouched: 49 insertions, 0 deletions.**

Every requirement/plan attribution was verified against
`retirement-check --list` and the v4.0 roadmap before being cited — RETIRE-02
waybar (18-20), RETIRE-03 swaync (19-08), RETIRE-04 swayosd (20-09), RETIRE-05
wleave (20-10), RETIRE-06 ags (21-08), RETIRE-07 eww/wlogout (20-10).

### 3. `ACCEPTED_OPTION_CHANGES` for `options.jsonl` (16a08a9)

`VERIFICATION.md`'s exemption row named its own two resolutions. The second was
taken: `options.jsonl`'s comparator now has the accepted-changes table it
lacked, at `hypr-equivalence-check:366`, consulted by both previously
no-escape-hatch arms at `:405-427`.

Stricter than the `binds.json` mechanism it mirrors, where that was cheap:

- keyed by `(option-key, kind)` — forgiving an *addition* never silently
  forgives a later *removal* of the same key
- enumerated, never pattern-matched
- a malformed entry exits 2 rather than degrading to the old fail-open, which
  would have looked identical to a correctly-empty table
- an entry that never fires is reported as stale, so the table cannot rot

## Evidence

**The mechanism was exercised, not trusted green** — v4.0's own closing lesson
is that a gate which has only ever been green has not been shown to reject
anything. Six synthetic-fixture cases, all as expected:

| Case | Expected | Got |
|---|---|---|
| Unlisted key added in live | FAIL | exit 1, `+ misc:brand_new: present in live only` |
| Unlisted key removed from live | FAIL | exit 1, `- misc:goes_away: present in baseline only` |
| Listed added key | accepted note | exit 0, `— option added since baseline, accepted: ...` |
| Listed removed key | accepted note | exit 0, `— option removed since baseline, accepted: ...` |
| Entry filed under the wrong kind | must NOT forgive | exit 1 |
| Malformed entry (`'add'` not `'added'`) | fail closed | exit 2 |

Gate state after all three commits:

- `hypr-equivalence-check` → `PASS: 3  FAIL: 0` (unchanged — an empty table
  must be a no-op, and is)
- `retirement-check --self-test` → `5 passed, 0 failed`
- `retirement-check --all` → `failed_classes=0` on all eight surfaces

## Findings worth carrying

**The drift the exemption anticipated had not fired.** The v4.0 close note
framed the 0.56.1-baseline-vs-0.56.2-host gap as "the drift is real". Measured
directly: it is real in version terms only. The bump added, renamed and removed
**zero** of the 46 tracked keys, and the `int` → `bool` type-key notes come from
the hyprlang → Lua migration, not the version bump. Which is why the table ships
empty — this is a preventive mechanism, and adding it changing any verdict would
have meant it was wrong.

**The re-capture route was a trap, not just the slower option.**
`.hypr-baseline/MANIFEST.md`'s 14-10 amendment records that a re-snapshot
overwrites all ~80 records with fresh live values, including the two `bindm`
mouse-field records 13.1-04 Task 3 explicitly forbade loosening. Re-capturing to
clear a version-drift exemption would have quietly destroyed a deliberate,
documented red. The exemption row offered both routes as equals; they are not.

**SC-3's raw hit count went UP, by design — 183 → 192.** The banners name the
retired surfaces, so `repo-prose` counts them. Stated plainly because the
opposite framing would be misleading: this task did not drive the number down
and was not trying to. The count was never the risk. Two things actually
changed: no file anywhere in the repo now presents a retired surface as current
(the real defect, in `.claude/CLAUDE.md`), and no reader can mistake a
historical design doc for current guidance. `wleave` did reach 0.

**The VM-tier exemption list is now empty.** It had one row; it is resolved.
Any future `theme-doctor` VM run has no exemption available, which is stricter
than the tier Phase 22 shipped. D-22-02's author-before-the-run rule is
unchanged for any new row.

## Deliberately not done

- **Re-capturing `.hypr-baseline/`** — destructive, see above
- **The other two v4.0 carried items** — the container allowlist's rejection
  path (proven only by dry-run) and the absent milestone audit
- **11 `wleave` lineage comments** in `windowrules.lua`/`autostart.lua` — they
  pass every blocking class by design (`scan_layer_window_rules` requires
  `DISPATCH_LAYER_RE` on the same line, so a comment can never `[FAIL]`), and
  they are deliberate provenance
- **1 line in `.claude/settings.local.json`** — a frozen historical permission
  string quoting an old commit message; not in `repo-prose` scope, not in any
  blocking class
- **Rewriting the four design-doc bodies** — operator decision; they are the
  record of what was actually designed at the time
