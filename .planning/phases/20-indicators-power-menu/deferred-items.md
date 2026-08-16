# Deferred Items

Out-of-scope discoveries surfaced while executing a plan, logged rather than fixed per the
executor's scope-boundary rule ("only auto-fix issues directly caused by the current task's
changes").

## From 20-09 (RETIRE-04, swayosd removal)

Both discovered during Task 3's mandatory live `quickshell-doctor` run. Neither references
`swayosd`, neither file is in 20-09's `files_modified`, and both reproduce identically on an
unrelated live run — confirmed pre-existing, not caused by this plan's edits.

1. **`[FAIL] zero Quickshell MPRIS writers (found in 1 file(s) under
   /home/aorus/.config/quickshell)`** — `modules/dashboard/MediaBackend.qml` imports
   `Quickshell.Services.Mpris`. This is QS-06's standing "no Quickshell MPRIS writer" constraint
   (Phase 11), tripped by the dashboard's own media backend — unrelated to OSD/swayosd. Owner:
   whichever phase/plan next touches the media backend (Phase 21, QMEDIA, per STATE.md's roadmap
   note that Phase 21 opens with a cava go/no-go spike before any media work).

2. **`[FAIL] permissions-allowlist-paths-resolve (D-16-23 check 5, T-16-15/T-16-16 mitigation):
   ... grants=9 missing=2 non-executable=0 pattern=1`** — `hypr/.config/hypr/config/permissions.lua`
   (screencopy allow-list, Phase 11/13.1 lineage) carries 2 missing binary paths and 1
   glob/alternation-pattern grant. No `swayosd` reference anywhere in this file. Owner: whichever
   plan next touches the overview/screencopy permission grants.

Both were transiently joined by two more failures on the FIRST live run this session
(`panel-osd-state-driven-trigger` hw-key=2, `one-step-per-press volume probe` delta=2x baseline)
that did NOT reproduce on a second clean run once host volume state settled — confirmed a
timing artifact from a differential-check restore racing the next check's own baseline read, not
a persistent defect. See `20-09-SUMMARY.md` for the full investigation.
