# 20-RETIRE-05-07-RECORD.md — RETIRE-05 (`wleave`) + RETIRE-07 (`wlogout`, `eww`)

Pre-deletion pre-flight and post-deletion after-runs for this plan's two requirements, per
`20-10-PLAN.md` Task 1 / Task 3.

## Pre-flight

Run 2026-08-16, HEAD `2ed3b5f410df2720bdfb0ececea94f3348729433` (plan 20-09's completed state).
No repository or host change was made during this section.

### 1. Gate B verdict

`20-GATE-02-B-RECORD.md` § Deletion Authorisation reads **`RETIRE-05 AUTHORISED`**. All thirteen
criteria carry a verdict: criteria 1-12 all `PASS`; criterion 13 (the Phase 15 "who owns the
prompt" security carry-over) is `OVERRIDDEN` — recorded as the known, accepted residual it was
defined to be, with its three mitigations (transient surface, Escape always closes, focus-grab
dismiss) all confirmed to hold. No `FAIL` on any criterion. **Result: PASS — no halt on this
item.**

### 2. Interlock

Command re-run verbatim, exactly as the Gate B record and this plan's own precondition specify:

```
$ git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/
$ echo "exit: $?"
exit: 1
```

**Result: NON-ZERO — the interlock, taken literally, FAILS.** The quickshell tree has moved
since the judged sha. Per this plan's own instruction ("Non-zero exit means the shell tree moved
after the judgment; halt and report rather than re-authorising") and per the Gate B record's own
closing paragraph ("a shell tree that has moved since the judged sha invalidates this
authorisation"), this is a halt condition on its own literal terms — not something this pre-flight
is authorised to wave through by supplying its own justification.

**Content investigated regardless, for the record, so the operator has full information when
asked to rule on it:**

- `git diff --stat 8b6a111 -- quickshell/.config/quickshell/` shows exactly three files touched,
  all by plan 20-09 (RETIRE-04, commit `2ed3b5f`'s comment-purge sweep, documented in its own
  `20-09-SUMMARY.md` key-decision #2):
  - `modules/dashboard/AudioBackend.qml` (6 lines: comment reword)
  - `modules/dashboard/Design.qml` (14 lines: comment reword)
  - `modules/osd/Osd.qml` (5 lines: comment reword)
- `PowerMenu.qml` and every other file under `modules/session/` do **not** appear in the diff —
  grepped for explicitly, zero hits.
- Every changed line in the diff is a comment line (`//...`) or a blank line inside a comment
  block — verified by filtering the diff's added/removed lines for anything that is not a comment
  or blank; zero non-comment lines found. No QML property, binding, signal handler, or logic
  changed anywhere in the diff.
- The edits are plan 20-09's own documented purge of the literal token "swayosd" from comment
  prose in files `retirement-check`'s `cross-package-refs` class scans, required to flip that
  surface's registry row to `retired` — unrelated in intent and in content to the power-menu
  surface Gate B judged.

**This pre-flight's own conclusion:** the interlock's non-zero exit is real and the plan's own
rule requires halting on it. The investigation above finds nothing that touches the surface Gate B
actually judged (no criterion 1-13 depends on `AudioBackend.qml`, `Design.qml`, or `Osd.qml`), but
this pre-flight does not have standing to self-certify that conclusion and re-authorise — the
plan's own text reserves that judgment. **Recorded as a halt-and-report condition; see the
Checkpoint section below.**

### 3. Removal impact previews

This host's pacman rejects `-n`/`--print` together. The plan's literal command was attempted
first, verbatim, for each target:

```
$ pacman -Rns --print wleave
error: invalid option: '--nosave' and '--print' may not be used together
$ pacman -Rns --print wlogout
error: invalid option: '--nosave' and '--print' may not be used together
$ pacman -Rns --print eww
error: invalid option: '--nosave' and '--print' may not be used together
```

A version difference from what the plan's literal command assumes. `-Rsp` (`--recursive
--print`, omitting `--nosave` which only affects `.pacnew` backup handling, not the impact list)
is the equivalent preview on this pacman version and is what was actually run:

```
$ sudo pacman -Rsp wleave
error: target not found: wleave
```
(Expected — `wleave` is already uninstalled; see Live installed-state confirmation below and the
executor's own `<critical_state_change>` briefing.)

```
$ sudo pacman -Rsp wlogout
wlogout-1.2.2-0
```
Names only `wlogout` itself — no orphaned dependency pulled with it (`gtk3`,
`gobject-introspection`, `gtk-layer-shell` are all still required by other installed packages on
this host).

```
$ sudo pacman -Rsp eww
eww-0.6.0-1
```
Names only `eww` itself — no orphaned dependency pulled with it.

**Result: both live previews name nothing beyond their own target. No halt on this item.**

### 4. Reverse-dependency checks

```
$ pactree -r wleave
error: package 'wleave' not found
```
(Expected — already uninstalled.)

```
$ pactree -r wlogout
wlogout
```
Only the package itself — nothing depends on it.

```
$ pactree -r eww
eww
```
Only the package itself — nothing depends on it.

**Result: nothing depends on any of the three. No halt on this item.**

### 5. Baseline recall

Pre-deletion `retirement-check` hit counts, from `20-RETIREMENT-BASELINE.md` (committed 2026-08-15,
run against the unmodified tree before any Phase 20 deletion):

| Surface | Status at baseline | `failed_classes` at baseline | Host package at baseline |
|---|---|---|---|
| `wleave` | `pending` | 0 | `wleave 0.7.1-2` |
| `wlogout` | `pending` | 0 | `wlogout 1.2.2-0` |
| `eww` | `pending` | 0 | `eww 0.6.0-1` |

These are the numbers Task 3's after-runs are measured against: `failed_classes` (blocking tier)
must reach/stay 0 for all three, and `status` must flip from `pending` to `retired`.

### 6. Live installed-state confirmation

```
$ pacman -Q wleave
error: package 'wleave' was not found
```
**`wleave` is confirmed ALREADY ABSENT from the host**, independently verified by this pre-flight
(not taken on the trust of the `<critical_state_change>` briefing alone, per that briefing's own
instruction to verify rather than act on authority). This matches the operator's report that they
removed it manually, at the same time as `swayosd`, outside any agent session. **No
`pacman -Rns wleave` will be run by this plan — the package-removal half of RETIRE-05 is already
done.** Only the config-side deletion (Task 2's repo changes) remains outstanding for `wleave`.

```
$ pacman -Qi wlogout
... Install Date   : Tue 24 Mar 2026 ... Install Reason : Explicitly installed ...
$ pacman -Qi eww
... Install Date   : Tue 14 Jul 2026 ... Install Reason : Explicitly installed ...
```
Both `wlogout` and `eww` are **confirmed still installed** on this host, explicitly installed
(not as a dependency). RETIRE-07's premise holds unmodified — the full `pacman -Rns wlogout eww`
removal in Task 3 is still live scope.

**`eww` install-script note (T-20-10-02):** `pacman -Qi eww` reports `Install Script: Yes`. Read
directly from `/var/lib/pacman/local/eww-0.6.0-1/install` before any removal:

```
post_install() { echo "... The example config can be found in /etc/xdg/eww ..." }
post_upgrade() { post_install }
```

The script defines **only** `post_install`/`post_upgrade` hooks (a one-time informational message
shown at install/upgrade time). It defines **no** `pre_remove`/`post_remove` hook. **Removing
`eww` runs nothing from this script** — pacman only invokes the hook functions actually present
in the `.INSTALL` file, and removal-time hooks are simply absent here.

## Checkpoint

Item 2 (Interlock) is a literal FAIL by this plan's own rule, even though the investigated content
is benign (three comment-only edits in files unrelated to `PowerMenu.qml`/`modules/session/`).
Per this plan's `<interlock>` instruction and the Gate B record's own closing paragraph, this
pre-flight does not have standing to wave that through on its own reasoning — it halts and reports
to the operator instead of re-authorising. See the executor's return message for the structured
checkpoint request. Items 1, 3, 4, 5, 6 all pass cleanly with no halt condition.
