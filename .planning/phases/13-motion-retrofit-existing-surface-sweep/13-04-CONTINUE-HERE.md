# 13-04 — PAUSED at 2/3 tasks (resume here)

**Status:** PAUSED, not complete. No `13-04-SUMMARY.md` exists and none should
be written until Task 3 actually finishes. `STATE.md`, `ROADMAP.md`, and
`REQUIREMENTS.md` have NOT been updated to reflect plan completion — this plan
is still open. `MAINT-03` is NOT complete.

**Why paused:** Task 3 is a blocking, non-auto-approvable human-verify gate
(`gate="blocking"`) whose full scope requires a real repo install AND a real
AUR build performed with an operator watching the package manager's/AUR
helper's own prompts in the real floating-kitty terminal. Steps 5-8 of that
gate (the actual installs) are still outstanding — see the incident note
below for exactly what happened and why this is recorded as partial, not
complete.

---

## Task 1 — DONE, committed

Commits `149934d` (Ctrl-A browse mode and fetch-extract previews) and
`5dfd9fd` (signal-trap fix, added after Task 3 forensics — see below).

- Added `CATALOG_SCRIPT`, a third mktemp'd sibling of `ENUM_SCRIPT`/
  `PREVIEW_SCRIPT`, covered by the same single extended EXIT trap. It runs
  `pacman -Ss icon-theme` and (when `paru`/`yay` is present) `<helper> -Ss -a
  icon-theme`, parses both into `source\tpkgname\tdescription[+marker]`
  lines, dedupes by package name (repo wins over AUR), and sorts. Verified
  standalone: 250 real lines, both `repo` and `aur` source fields present,
  4 entries correctly marked already-installed.
- Added the Ctrl-A binding, copying `wallpaper-picker.sh`'s
  `reload(...)+change-header(...)` idiom character-for-character in shape
  (D-26) — one-way, no new keybind, Esc still cancels, installed list is
  still what the picker opens on.
- Extended the preview script to branch on three shapes: legacy installed
  name (unchanged), catalogue entry already installed (resolves package →
  directory via `pacman -Ql`, renders normally), catalogue entry not
  installed. For `repo` sources, fetches via `pacman -Sp` + `curl -fsSL
  --max-time 30 --max-filesize 209715200`, extracts via `bsdtar
  --no-same-owner --no-same-permissions` restricted to the archive's
  `usr/share/icons/*` paths (never `-P`, never an install), and renders the
  real icons. For `aur` sources (no prebuilt package), renders `<helper>
  -Si` metadata with an explicit "built from source, no fetchable preview"
  line.
- Fixed Pitfall 6: two-convention icon search (`SIZExSIZE/category/` then
  inverted `category/SIZE/` then unfiltered fallback), applied to both the
  curated-name lookup and the bulk fallback, and to every root the preview
  script ever searches (installed, already-installed-via-catalogue, and
  freshly extracted).
- Removed the old hard-exit when only Adwaita is installed (Rule 2
  deviation) — it made Ctrl-A unreachable on exactly the machine state
  (fresh install) where browsing/installing a new theme is most wanted.
- Reworded banner/comment prose that literally contained the substrings
  `theme-apply` and `gsettings set` outside their one legitimate use each,
  to align the baseline file with 13-04's own literal-substring verify
  checks (Rule 1 deviation — see Deviations section below).
- **Added after Task 3 forensics:** explicit `trap "exit 1" HUP/INT/TERM`
  so a real window close reliably fires the existing EXIT trap (see
  "Orphaned-artifact investigation" below for the full finding).

**Verified for real, not just read** (per the plan's method_note):
- Papirus (installed, `SIZExSIZE/category/` convention) → 40K non-empty
  montage.
- `elementary-icon-theme` (real, not-yet-installed repo package, inverted
  `category/SIZE/` convention per 13-RESEARCH.md's own test case) → fetched,
  extracted, rendered a 59K non-empty montage on first visit (1.4s,
  network-bound); second visit rendered from cache in 0.02s (~70x faster,
  no second network call).
- Extraction confinement: after the fetch, nothing appeared under
  `/usr/share/icons/elementary-icon-theme` or
  `~/.local/share/icons/elementary*`; `find $CACHE_DIR -maxdepth 1` showed
  only the picker's own cache tree.
- AUR-only entry (`paper-icon-theme-git`) previewed as metadata text plus
  the explicit no-preview line.
- Network-unreachable simulated via a PATH-shadowed `curl` stub returning
  exit 6 (`Could not resolve host`) — the preview showed the visible
  `✗ fetch failed for cosmic-icon-theme — network unreachable or download
  error` line, left no partial archive/extract dir behind, and did not
  crash.
- Mid-fetch kill (initial pass, before the trap gap below was found):
  backgrounded a script carrying the exact trap line under `timeout -s TERM
  2`, confirmed all four mktemp'd artifacts existed, then confirmed after
  SIGTERM they were gone. This is a true positive for plain SIGTERM
  delivered directly to a bare process — it did NOT catch the real-world
  gap described below, which only manifests via the actual Hyprland
  window-close path.

## Task 2 — DONE, committed

Commit `9430130` — wire browse selection to the install-and-apply pipeline.

- Post-selection handling branches on whether `$SELECTED` is a tab-separated
  catalogue line or a legacy plain name; the legacy branch is byte-for-byte
  the pre-existing validation logic.
- Catalogue selections are defense-in-depth charset-validated, then
  re-validated against a freshly re-derived catalogue (the exact set
  `CATALOG_SCRIPT` would emit right now) before any interpolation, then
  confirmed real via `pacman -Si`/`<helper> -Si` exit codes — never a
  bespoke legitimacy heuristic.
- Repo installs run `sudo pacman -S --needed <pkg>`; AUR installs run
  `<helper> -S <pkg>`. Neither ever carries an auto-confirm flag (asserted
  by both the automated negative grep and by reading every invocation).
- Package → theme-directory resolution is a before/after enumeration diff,
  never an assumed identity: exactly one new directory applies
  automatically; more than one launches a second fzf pass over just those
  directories using the same preview pipeline; zero reports the package
  name explicitly and leaves the current theme untouched rather than
  guessing.
- Already-installed catalogue picks skip the install step entirely and
  resolve their directory via `pacman -Ql` (package file ownership), never
  reinstalling.
- Exactly one `theme-apply` invocation and zero standalone `gsettings`
  writes remain in the file (verified by grep — required rewording two
  further comment lines, see Deviations).

**Verified via a mocked-binary harness** (no real `pacman`/`paru`/`sudo`
command was ever run against this machine for Task 2's own testing — per
`<system_impact_caution>`, an install may only happen with the operator
watching):
- A fabricated package name never emitted by the mock catalogue was
  rejected with exit 1 and the exact validation-failure message, before any
  mock `pacman -Si`/`sudo pacman -S` call fired.
- A simulated cancelled install (mock `pacman -S` exits 1) left the
  `icon-theme` state file byte-identical (md5-compared before/after) and
  exited 1 without ever calling `theme-apply`.
- A simulated successful single-new-directory install resolved to that
  directory, wrote it to state, and called the mocked `theme-apply` exactly
  once with the active preset.
- A simulated two-new-directory install correctly computed
  `NEW_COUNT=2` via the `comm -13` diff and attempted the second fzf pass
  (which degrades gracefully — `|| true` — in a non-interactive harness with
  no controlling terminal; the fzf mechanism itself is the same
  already-shipped pattern used everywhere else in the file).
- A simulated zero-new-directory install reported the package name
  explicitly and left state untouched, exiting 0 without guessing.
- An already-installed catalogue pick (mock `pacman -Q` succeeds) skipped
  the mock install step entirely and resolved its directory via mock
  `pacman -Ql` output.

**This mocked-binary coverage is exactly why Task 2's install path is still
unproven against a real package manager — see the incident note below.**

## Deviations from Plan (Tasks 1–2)

**1. [Rule 2 — missing critical functionality] Removed the picker's
hard-exit when only Adwaita is installed.** The pre-existing "No extra icon
themes installed … Press any key to exit" branch called `exit 0` before fzf
ever launched, which would make the new Ctrl-A browse mode completely
unreachable on exactly the machine state (fresh install, only Adwaita
present) where MAINT-03's own stated purpose — browsing and installing a new
theme — is most needed. Replaced with a non-blocking stderr note and let fzf
launch normally. Files: `hypr/.config/hypr/scripts/icon-theme-picker.sh`.

**2. [Rule 1 — gate/code misalignment] Reworded prose containing the literal
substrings `theme-apply` and `gsettings set`.** 13-04-PLAN.md's own Task 2
`<verify>` block asserts `grep -c 'theme-apply'` equals exactly 1 and
`grep -q 'gsettings set'` finds nothing, anywhere in the file. The
pre-existing file (before any 13-04 change) already violated both checks via
descriptive comment prose (5 matches for `theme-apply`, 2 for
`gsettings set`, none of them the actual invocation/prohibition being
described). Reworded five comment lines to refer to "the engine's apply
entrypoint" / "the engine" / "a bare standalone settings write" instead,
preserving their meaning while leaving exactly one literal `theme-apply`
(the real invocation on the line that runs it) and zero literal
`gsettings set` occurrences. No behavioural change — comment text only.
(A sixth occurrence of this same class was introduced and caught during the
Task 3 forensics pass — see the trap fix's own commit message — where a new
comment describing the trap literally contained `trap '...' EXIT` and had to
be reworded the same way.)

**3. [Rule 1 — real bug, found during Task 3 checkpoint forensics] Added
explicit `HUP`/`INT`/`TERM` traps.** See "Orphaned-artifact investigation"
below for the full finding and proof. Files:
`hypr/.config/hypr/scripts/icon-theme-picker.sh`. Commit `5dfd9fd`.

## Known limitation (not a deviation, documented for the next reader)

Re-validating a catalogue selection against a freshly re-derived
`CATALOG_SCRIPT` output (rather than a value fzf's own `reload()` produced
internally, which this script cannot observe) means every catalogue install
re-runs the full `pacman -Ss` + `<helper> -Ss -a` query once more before
installing — an extra ~1s of latency in this session's testing, bounded by
`CATALOG_SCRIPT`'s own `timeout 20` on the AUR leg. This is the cost of
"never trust a value this script cannot itself re-derive" (Security Domain
V5) rather than a bug.

The `yay` fallback path in both `CATALOG_SCRIPT` and the main script's AUR
helper resolution is untested on this machine — only `paru` is installed
here. It follows the same `-Ss -a <term>` / `-Si` / `-S` invocation shape as
`paru`, which is the documented common AUR-helper convention, but per this
phase's own "verify against the binary, do not reason about it" discipline
this should be treated as unverified rather than confirmed, should a `yay`
user ever exercise this path.

---

## Incident: a gate result was reported as passed and was not performed

**What happened.** After Tasks 1-2 landed, the coordinator reported Task 3's
gate as PASSED with all eight steps described as complete, including two
real installs (a repo package and an AUR build). Before writing the summary,
this session independently re-derived the two acceptance-criteria details
the plan requires (the actual package names installed; the resulting active
theme/resolved directory) rather than accepting them as given, per this
phase's own "recover it yourself, don't invent it" discipline. That check
found **zero corroborating evidence anywhere on the system**: no new entry
in `pacman -Qe`/`pacman -Qs icon`, no transaction of any kind in
`/var/log/pacman.log` for any icon-theme package, no `sudo` activity at all
in `journalctl` for the relevant window, no AUR clone directory under
`~/.cache/paru/clone/`, and — the most direct signal — `~/.local/state/
theme/icon-theme` (the file the entire install path terminates in) **did not
exist**. The operator subsequently confirmed directly: the gate questions
were answered too quickly, without actually working through the install
steps. Steps 1-4 were genuinely performed; steps 5-8 were not.

**Reusable recipe for checking this specific gate cheaply, next time
(cheapest signal first):**
1. `cat ~/.local/state/theme/icon-theme` — this is the single file every
   successful catalogue install (and nothing else) writes to. Its absence,
   or an unchanged mtime, is close to conclusive on its own.
2. `pacman -Qe | grep -i icon` / `pacman -Qs icon` — compare against the
   pre-gate baseline (this session's baseline: `adwaita-icon-theme`,
   `adwaita-icon-theme-legacy`, `breeze-icons`, `hicolor-icon-theme`,
   `papirus-icon-theme`, plus font/cache packages with "icon" in the name).
   Any new entry not in that list is a real install.
3. `grep -iE '<candidate-pkg-names>' /var/log/pacman.log` — a real install
   always produces an `[ALPM] installed <pkg>` line; grep the WHOLE file,
   not just the tail, since sync/upgrade noise can push the real line back.
4. `journalctl --since <gate-start> --until <gate-end> | grep -i sudo` — a
   real repo install always shells out through `sudo`; its total absence in
   the exact gate window is a strong negative signal.
5. `find ~/.cache/paru/clone -maxdepth 1 -newermt <gate-start>` — a real AUR
   build always leaves a clone directory, even if the package was later
   removed.

**Independent corroboration that steps 1-4 genuinely did happen** (not
taken on faith either — recovered from the same forensic pass): two real
picker invocations left their mktemp'd artifacts on disk at 16:52:50-16:52:56
and 16:53:02-16:53:27. Their cache contents are real, non-empty montage PNGs
for `Adwaita`/`AdwaitaLegacy`/`breeze`/`breeze-dark` (the installed list) and
fetched-and-extracted `usr/share/` trees plus rendered montages for
`cosmic-icon-theme`, `deepin-icon-theme`, and `elementary-icon-theme` (real,
not-yet-installed repo packages, browsed via the catalogue) — exactly the
D-28 fetch-for-preview behaviour Task 1 implements, and exactly consistent
with steps 1-4 (open list, Ctrl-A, browse repo previews, view an AUR-only
entry's metadata) having been exercised for real. No `aur`-sourced package
appears in either cache (AUR previews render as text only, by design, so
this is expected either way — it does not itself prove or disprove step 4,
which the operator's own account already confirms).

## Orphaned-artifact investigation (Rule 1 — real bug, fixed)

**The question:** both real sessions above left their `ENUM_SCRIPT`/
`PREVIEW_SCRIPT`/`CATALOG_SCRIPT`/`CACHE_DIR` artifacts on disk. Task 1's own
verification had already claimed the extended EXIT trap covers a mid-fetch
SIGTERM. Those two facts are in tension, so this needed resolving with a
live repro, not a guess.

**Reproduced live, faithfully, on this machine** (a real Hyprland/Wayland
session was reachable from this tool environment via `hyprctl`, so this did
not need to be simulated):
1. Launched the real, unmodified, already-committed picker via its real
   launcher (`icon-theme-switch.sh`, which runs `uwsm app -- kitty --class
   icon-theme-picker ... -- icon-theme-picker.sh`).
2. Confirmed the real process tree: `kitty → bash(icon-theme-picker.sh,
   session leader, PGID = its own PID) → bash(subshell for `$(...| fzf...)`)
   → fzf`, all sharing one process group.
3. Closed the window with `hyprctl dispatch closewindow <address>` — the
   same class of action Super+Q's `killactive` keybind uses.
4. **Result, reproduced twice on the unmodified script:** every process in
   the tree died, but all four mktemp'd artifacts survived.
5. Built a signal-logging instrumented copy (traps on HUP/INT/QUIT/TERM/
   USR1/USR2/PIPE, each logging to a file before re-exiting) and repeated
   the same live close. **Found: the script receives a real `SIGHUP`** on
   window close, consistent with the pty's controlling terminal hanging up.
6. This is the actual mechanism: bash only overrides a signal's *default*
   (process-terminating) disposition for a signal it has an **explicit**
   trap registered on. The existing `trap '...' EXIT` line does not itself
   install a handler for `HUP` — with no explicit `HUP` trap, the kernel's
   default disposition (terminate immediately) applies straight to the
   process, bypassing bash's own trap-checking machinery, so the `EXIT`
   trap body never gets a chance to run. (A synthetic `kill -HUP -<pgid>`
   sent directly to a bare, `setsid`-isolated test script — no real pty, no
   kitty, no fzf — did NOT reproduce this: that path evidently goes through
   bash's normal signal delivery in a way the real pty-hangup path does
   not. The live repro through the real dispatcher is the one that matters
   and the one this fix is verified against.)
7. **Fix:** added `for _sig in HUP INT TERM; do trap "exit 1" "$_sig"; done`
   right after `set -euo pipefail`, so each of these signals now runs
   through the shell's own `exit` path, which does fire the existing `EXIT`
   trap.
8. **Verified the fix against the real, final, committed file** — not a
   copy — using the same live launcher and the same live dispatcher: all
   four artifacts (`icon-enum-*.sh`, `icon-preview-*.sh`, `icon-catalog-*.sh`,
   `icon-preview-cache-*`) were gone immediately after `closewindow`, where
   they had survived every prior attempt on the unmodified file.

**Verdict:** this was a real gap in Task 1's own coverage — the mid-fetch
kill test proved SIGTERM-to-a-bare-process works, which is true but was not
representative of the actual failure mode (a real terminal hangup signal,
delivered through a real pty, to a script with no explicit trap for it).
Fixed and re-verified against the real system. Commit `5dfd9fd`.

All orphaned `/tmp/icon-{enum,preview,catalog}-*.sh` and
`/tmp/icon-preview-cache-*` artifacts (both from the operator's original
gate attempt and from this investigation's own repro runs) have been
removed. `git status --short` shows only the pre-existing
`wallpapers/Pictures/Wallpapers/current.jpg` churn (owned by plan 13-06).
Gates confirmed at baseline after the fix: `theme-doctor` 185/1,
`theme-parity` 2163/0, `motion-lint` 41/0.

---

## Task 3 — PARTIALLY EXERCISED (resume point)

`checkpoint:human-verify`, `gate="blocking"`. Steps 1-4 passed, live,
corroborated independently (see incident note above). **Steps 5-8 remain
OUTSTANDING** and must be run for real before `MAINT-03` can be marked
complete — the install path (Task 2) is currently proven only against a
mocked `pacman`/`paru`/`sudo` harness, never against the real package
manager.

Reproduced verbatim from `13-04-PLAN.md`:

> 1. Launch the picker. Confirm it opens on the installed list, unchanged
>    from before. **— DONE, passed.**
> 2. Press **Ctrl-A**. Confirm the list switches to the catalogue, the
>    header changes, and already-installed packages are marked.
>    **— DONE, passed.**
> 3. Arrow onto a not-yet-installed **repo** package (e.g. a Tela or Colloid
>    variant). Confirm the fetching line appears immediately, then real
>    icons render in the preview pane. Arrow away and back — confirm the
>    second render is instant (cache hit). **— DONE, passed** (forensic
>    cache evidence: `cosmic-icon-theme`, `deepin-icon-theme`,
>    `elementary-icon-theme` all fetched and rendered).
> 4. Arrow onto an **AUR-only** package. Confirm the pane shows package
>    metadata plus the explicit "built from source, no preview" line, not an
>    empty pane. **— DONE, passed** per operator account (no cache artifact
>    is expected either way for this step, by design).
> 5. **Install a repo package.** Confirm the package manager prompts, the
>    install completes, and the theme applies live — check Thunar's icons
>    change without restarting it, and check a GTK app's icons change.
>    **— OUTSTANDING. Not performed.**
> 6. **Install an AUR package.** Review the helper's PKGBUILD diff / build
>    prompts as they stream. **Read them.** Confirm they are what you expect
>    for the package you chose, then proceed or abort. Either outcome is a
>    valid gate result — report which. **— OUTSTANDING. Not performed.**
> 7. If either installed package shipped multiple theme directories, confirm
>    the second selection pass appeared rather than one being chosen for
>    you. **— OUTSTANDING (depends on step 5/6 actually running).**
> 8. Press Esc at the catalogue without selecting. Confirm nothing was
>    installed and the active theme is unchanged. **— OUTSTANDING. Not
>    performed** (distinct from steps 1-4's exit — no evidence either way
>    that Esc specifically, as opposed to a window close, was exercised).

**Acceptance criteria for Task 3** (from the plan, still to satisfy): all
eight steps answered individually with real evidence; step 6 records
whether the AUR build was proceeded with or aborted and what the reviewed
prompts showed (a blank "approved" is not acceptable); step 5 records the
specific applications whose icons were observed to change; the package
names installed during the gate are recorded; `~/.config/theme-engine/
theme-doctor` exits 0 at the end. **Recover the package names and resolved
theme from the system yourself afterward** using the recipe above — do not
rely solely on the operator's verbal account this time.

**Suggested real packages to exercise** (both confirmed resolvable this
session, neither installed on this machine as of this writing): a `repo`
candidate such as `elementary-icon-theme` (already proven fetchable/
previewable — this run would be the first time it is actually *installed*),
and an `aur` candidate such as `tela-icon-theme-git` or `paper-icon-theme-git`
(both confirmed resolvable via `paru -Si` this session).

---

## Resume instructions for a fresh session

1. Re-read `13-04-PLAN.md` Task 3 in full before acting.
2. Confirm `git log --oneline -5` shows `5dfd9fd`, `9430130`, `149934d`
   present, and `git status --short` shows nothing dirty except
   `wallpapers/Pictures/Wallpapers/current.jpg`.
3. Run Task 3's steps 5-8 live with the operator watching the real
   floating-kitty terminal (this cannot be automated — installing software
   requires an explicit human-supervised checkpoint per
   `<system_impact_caution>`). Steps 1-4 do not need to be repeated; they
   are already corroborated, but there is no harm in re-confirming them in
   the same live session if convenient.
4. Record all eight answers, the AUR review outcome, the applications whose
   icons changed, and the package names installed.
5. **Recover the package names, the resolved theme directory, and the final
   `icon-theme`/`current-theme` state yourself from the system** (the
   recipe under "Incident" above) — do not accept a verbal summary alone
   this time, per this phase's own discipline and the reason this file
   exists in its current form.
6. Confirm `~/.config/theme-engine/theme-doctor` exits 0.
7. Only then write `13-04-SUMMARY.md` (folding this file's Task 1/2/3
   content, the incident, and the trap-fix investigation in full), update
   `STATE.md`/`ROADMAP.md`, mark `MAINT-03` complete in `REQUIREMENTS.md`,
   and make the final metadata commit.
8. Delete this file (or fold its content into the SUMMARY) once the plan is
   actually complete — it exists only to make the resume point unambiguous.
