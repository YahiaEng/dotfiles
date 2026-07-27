# 13-04 — PAUSED at 2/3 tasks (resume here)

**Status:** PAUSED, not complete. No `13-04-SUMMARY.md` exists and none should
be written until Task 3 finishes. `STATE.md` and `ROADMAP.md` have NOT been
updated to reflect plan completion — this plan is still open.

**Why paused:** Task 3 is a blocking, non-auto-approvable human-verify gate
(`gate="blocking"`) that exercises the phase's first live AUR build and the
first real `sudo pacman -S`/AUR-helper installs performed during this plan's
execution. Per `<system_impact_caution>`, no package may be installed without
an explicit operator checkpoint — that checkpoint is Task 3, and it requires a
human physically present at the real floating-kitty terminal to watch the
package manager's/AUR helper's own prompts stream and decide whether to
proceed. This is not automatable and was not attempted.

---

## Task 1 — DONE, committed

Commit `149934d` — Ctrl-A browse mode and fetch-extract previews.

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
- Mid-fetch kill: backgrounded a script carrying the exact trap line under
  `timeout -s TERM 2`, confirmed via an in-process self-check that all four
  mktemp'd artifacts existed, then confirmed from the parent process after
  SIGTERM that all four (`ENUM_SCRIPT`, `PREVIEW_SCRIPT`, `CATALOG_SCRIPT`,
  `CACHE_DIR`) were gone — the extended EXIT trap covers every artifact on
  an abort path, including the SIGTERM/SIGHUP class the plan names.

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
command was ever run against this machine — per `<system_impact_caution>`,
Task 3 is the only place a real install may happen, and only with the
operator watching):
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
  (which degrades gracefully — `|| true` — in this non-interactive sandbox
  with no controlling terminal; the fzf mechanism itself is the same
  already-shipped pattern used everywhere else in the file).
- A simulated zero-new-directory install reported the package name
  explicitly and left state untouched, exiting 0 without guessing.
- An already-installed catalogue pick (mock `pacman -Q` succeeds) skipped
  the mock install step entirely and resolved its directory via mock
  `pacman -Ql` output.

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

## Task 3 — NOT STARTED (resume point)

`checkpoint:human-verify`, `gate="blocking"`. This task performs the first
live AUR build and the first real repo/AUR installs this plan has produced.
It requires an operator physically watching the real floating-kitty
terminal.

Reproduced verbatim from `13-04-PLAN.md`:

> 1. Launch the picker. Confirm it opens on the installed list, unchanged
>    from before.
> 2. Press **Ctrl-A**. Confirm the list switches to the catalogue, the
>    header changes, and already-installed packages are marked.
> 3. Arrow onto a not-yet-installed **repo** package (e.g. a Tela or Colloid
>    variant). Confirm the fetching line appears immediately, then real
>    icons render in the preview pane. Arrow away and back — confirm the
>    second render is instant (cache hit).
> 4. Arrow onto an **AUR-only** package. Confirm the pane shows package
>    metadata plus the explicit "built from source, no preview" line, not an
>    empty pane.
> 5. **Install a repo package.** Confirm the package manager prompts, the
>    install completes, and the theme applies live — check Thunar's icons
>    change without restarting it, and check a GTK app's icons change.
> 6. **Install an AUR package.** Review the helper's PKGBUILD diff / build
>    prompts as they stream. **Read them.** Confirm they are what you expect
>    for the package you chose, then proceed or abort. Either outcome is a
>    valid gate result — report which.
> 7. If either installed package shipped multiple theme directories, confirm
>    the second selection pass appeared rather than one being chosen for
>    you.
> 8. Press Esc at the catalogue without selecting. Confirm nothing was
>    installed and the active theme is unchanged.

**Acceptance criteria for Task 3** (from the plan): all eight steps answered
individually; step 6 records whether the AUR build was proceeded with or
aborted and what the reviewed prompts showed (a blank "approved" is not
acceptable); step 5 records the specific applications whose icons were
observed to change; the package names installed during the gate are
recorded; `~/.config/theme-engine/theme-doctor` exits 0 at the end.

**Suggested real packages to exercise** (both confirmed resolvable this
session, neither installed on this machine): a `repo` candidate such as
`elementary-icon-theme` (already proven fetchable/previewable in Task 1's
testing — this run would be the first time it is actually *installed*), and
an `aur` candidate such as `tela-icon-theme-git` or `paper-icon-theme-git`
(both confirmed resolvable via `paru -Si` this session).

---

## Resume instructions for a fresh session

1. Re-read `13-04-PLAN.md` Task 3 in full before acting.
2. Confirm `git log --oneline -3` shows `9430130` and `149934d` present, and
   `git status --short` shows nothing dirty except
   `wallpapers/Pictures/Wallpapers/current.jpg`.
3. Run Task 3's eight steps live with the operator watching the real
   floating-kitty terminal (this cannot be automated — installing software
   requires an explicit human-supervised checkpoint per
   `<system_impact_caution>`).
4. Record all eight answers, the AUR review outcome, the applications whose
   icons changed, and the package names installed.
5. Confirm `~/.config/theme-engine/theme-doctor` exits 0.
6. Only then write `13-04-SUMMARY.md` (folding this file's Task 1/2 content
   plus Task 3's results and deviations), update `STATE.md`/`ROADMAP.md`,
   mark `MAINT-03` complete in `REQUIREMENTS.md`, and make the final
   metadata commit.
7. Delete this file (or fold its content into the SUMMARY) once the plan is
   actually complete — it exists only to make the resume point unambiguous.
