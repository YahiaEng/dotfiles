---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 04
subsystem: ui
tags: [fzf, pacman, paru, aur, gtk3, gsettings, icon-theme, bsdtar, bash]

requires:
  - phase: 13-01
    provides: Shared motion token source and the retrofit gate discipline this plan's checkpoint protocol follows
provides:
  - Ctrl-A browse mode inside the existing icon-theme picker (no new surface, no new keybind)
  - Fetch-and-extract real-icon previews for not-yet-installed repo packages, cached and trap-cleaned
  - Repo and AUR install path feeding the existing state-file + theme-apply pipeline
  - Package-name vs theme-directory-name identity resolved by post-install enumeration diff
  - Fix for a latent engine defect that aborted theme-apply before the icon-theme gsettings write
affects: [icon-theme, theme-engine, gtk-reload, future picker work]

tech-stack:
  added: []
  patterns:
    - "Catalogue enumeration as a third mktemp'd sibling script under one shared EXIT trap"
    - "Never trust a value this script cannot itself re-derive: re-validate an fzf selection against a freshly re-derived catalogue before interpolation"
    - "Package -> theme-directory resolution by before/after enumeration diff, never assumed identity"
    - "Explicit HUP/INT/TERM traps alongside EXIT, so a real pty hangup fires the cleanup path"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/icon-theme-picker.sh
    - theme-engine/.config/theme-engine/lib/gtk.sh

key-decisions:
  - "D-26: Ctrl-A reuses wallpaper-picker.sh's reload()+change-header() idiom character-for-character — one-way, no new keybind, Esc still cancels"
  - "D-28: previews fetch and extract the real package into the picker's own cache rather than shipping committed preview blobs or a curation table"
  - "D-27: AUR installs go through the already-resolved paru/yay helper in the real floating terminal with prompts visible — never auto-confirmed"
  - "Removed the picker's hard-exit when only Adwaita is installed — it made Ctrl-A unreachable on exactly the machine state where browsing matters most"
  - "gtk-4.0-colors.css uses libadwaita's named-color vocabulary (accent_color), not matugen's (primary) — the two conventions are not interchangeable"

patterns-established:
  - "Gate forensics: recover a human-verify gate's claimed outcome from system state (state file, pacman -Qe diff, whole-file pacman.log grep, journalctl sudo window, paru clone mtimes) rather than accepting a verbal account"
  - "Unguarded grep-pipeline assignments are a set -e landmine in any library sourced by a `set -euo pipefail` entrypoint"

requirements-completed: [MAINT-03]

coverage:
  - id: D1
    description: "Ctrl-A switches the picker from the installed list to the browsable repo+AUR catalogue, with already-installed packages marked"
    requirement: MAINT-03
    verification:
      - kind: manual_procedural
        ref: "Task 3 gate steps 1-2, corroborated by picker cache artifacts at 16:52:50-16:53:27"
        status: pass
    human_judgment: true
    rationale: "Interactive fzf mode switch and header change can only be observed by a human driving the real terminal UI"
  - id: D2
    description: "A not-yet-installed repo package is fetched, extracted into the trap-cleaned cache and rendered as real icons; second visit is a cache hit"
    requirement: MAINT-03
    verification:
      - kind: manual_procedural
        ref: "Task 1 verification: elementary-icon-theme 59K montage in 1.4s, 0.02s on re-visit; Task 3 gate step 3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview extraction is confined to the cache dir and never executes anything from the archive"
    requirement: MAINT-03
    verification:
      - kind: manual_procedural
        ref: "post-fetch check: nothing under /usr/share/icons/elementary-icon-theme or ~/.local/share/icons/elementary*; find $CACHE_DIR -maxdepth 1 shows only the picker's own tree"
        status: pass
    human_judgment: false
  - id: D4
    description: "A repo package installs with the package manager's prompts visible and no auto-confirm flag"
    requirement: MAINT-03
    verification:
      - kind: manual_procedural
        ref: "journalctl gate window: sudo COMMAND=/usr/bin/pacman -S --needed elementary-icon-theme (no --noconfirm); [ALPM] installed elementary-icon-theme (8.2.0-2)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The installed theme applies live to Thunar and GTK apps without restarting them"
    requirement: MAINT-03
    verification:
      - kind: manual_procedural
        ref: "Task 3 gate step 5, re-run after 2ea4510; operator confirmed Thunar icons change live with no restart"
        status: pass
    human_judgment: true
    rationale: "Live in-place icon repaint in a running GTK3 app is a visual observation no automated check can stand in for"
  - id: D6
    description: "An AUR package installs through the resolved helper with its PKGBUILD/build prompts streamed for review"
    requirement: MAINT-03
    verification:
      - kind: manual_procedural
        ref: "Task 3 gate step 6 — build attempted (two paru clones, source tarball, pkg/ staging dir), did not complete; no package installed"
        status: fail
    human_judgment: true
    rationale: "ACCEPTED RISK — see 'Accepted risk' below. The AUR install path remains proven only against a mocked harness."

duration: ~7h elapsed (3 sessions, operator-gated)
completed: 2026-07-27
status: complete
---

# Phase 13-04: Icon-Theme Picker Browse & Install Summary

**Ctrl-A browse mode over the live repo+AUR catalogue with fetch-and-extract real-icon previews, a repo/AUR install path feeding the existing theme-apply pipeline, and a root-caused fix for the engine defect that was silently aborting every icon-theme apply.**

## Performance

- **Started:** 2026-07-27T16:41:16+03:00
- **Completed:** 2026-07-27T23:51:57+03:00
- **Tasks:** 3
- **Files modified:** 2 (472 insertions, 81 deletions)

## Accomplishments

- The picker now lists icon themes that are **not yet installed**, sourced from `pacman -Ss` plus the AUR helper, deduped repo-wins-over-AUR, with already-installed entries marked.
- Previews for not-yet-installed repo packages are **real icons from the real package** — fetched via `pacman -Sp` + `curl`, extracted with `bsdtar` restricted to `usr/share/icons/*`, rendered through the existing montage pipeline, cached and trap-cleaned.
- Selecting a catalogue entry installs it (repo via `sudo pacman -S --needed`, AUR via the resolved helper) and applies the theme directory it actually shipped.
- **Root-caused and fixed a latent engine defect** that made every icon-theme selection a no-op for GTK apps — the reason Thunar's icons never changed.

## Task Commits

1. **Task 1: Ctrl-A browse mode + fetch-extract previews** — `149934d` (feat)
2. **Task 2: Wire browse selection to install-and-apply** — `9430130` (feat)
3. **Task 3: Live end-to-end gate** — no code commit of its own; produced `5dfd9fd` and `2ea4510` below
   - **Deviation fix:** explicit HUP/INT/TERM traps — `5dfd9fd` (fix)
   - **Deviation fix:** theme-apply abort before the icon-theme write — `2ea4510` (fix)

## Files Created/Modified

- `hypr/.config/hypr/scripts/icon-theme-picker.sh` — Ctrl-A browse mode, dual-convention icon search, fetch-and-extract previews, repo/AUR install path, explicit signal traps
- `theme-engine/.config/theme-engine/lib/gtk.sh` — corrected the icon-theme accent lookup's color name and made both accent grep pipelines `set -e`-safe

## Task 1 — Ctrl-A browse mode and fetch-extract previews

Commits `149934d`, `5dfd9fd`.

- Added `CATALOG_SCRIPT`, a third mktemp'd sibling of `ENUM_SCRIPT`/`PREVIEW_SCRIPT` covered by the same single extended EXIT trap. Runs `pacman -Ss icon-theme` and (when `paru`/`yay` is present) `<helper> -Ss -a icon-theme`, parses both into `source\tpkgname\tdescription[+marker]` lines, dedupes by package name (repo wins), sorts. Verified standalone: 250 real lines, both `repo` and `aur` source fields present, 4 entries correctly marked already-installed.
- Ctrl-A binding copies `wallpaper-picker.sh`'s `reload(...)+change-header(...)` idiom character-for-character in shape (D-26) — one-way, no new keybind, Esc still cancels, installed list is still what the picker opens on.
- Preview script branches on three shapes: legacy installed name (unchanged), catalogue entry already installed (resolves package → directory via `pacman -Ql`), catalogue entry not installed. Repo sources fetch via `pacman -Sp` + `curl -fsSL --max-time 30 --max-filesize 209715200` and extract via `bsdtar --no-same-owner --no-same-permissions` restricted to `usr/share/icons/*` (never `-P`, never an install). AUR sources render `<helper> -Si` metadata plus an explicit "built from source, no fetchable preview" line.
- Fixed Pitfall 6: two-convention icon search (`SIZExSIZE/category/`, then inverted `category/SIZE/`, then unfiltered fallback), applied to every root the preview script searches.

**Verified for real, not just read:**

- Papirus (installed, `SIZExSIZE/category/`) → 40K non-empty montage.
- `elementary-icon-theme` (real, not-yet-installed repo package, inverted `category/SIZE/` convention per 13-RESEARCH.md's own test case) → fetched, extracted, rendered a 59K non-empty montage on first visit (1.4s, network-bound); second visit rendered from cache in 0.02s (~70x faster, no second network call).
- Extraction confinement: after the fetch, nothing under `/usr/share/icons/elementary-icon-theme` or `~/.local/share/icons/elementary*`; `find $CACHE_DIR -maxdepth 1` showed only the picker's own cache tree.
- AUR-only entry (`paper-icon-theme-git`) previewed as metadata text plus the explicit no-preview line.
- Network-unreachable simulated via a PATH-shadowed `curl` stub returning exit 6 → visible `✗ fetch failed … network unreachable or download error` line, no partial archive/extract dir left behind, no crash.

## Task 2 — Wire browse selection to the install-and-apply pipeline

Commit `9430130`.

- Post-selection handling branches on whether `$SELECTED` is a tab-separated catalogue line or a legacy plain name; the legacy branch is byte-for-byte the pre-existing validation logic.
- Catalogue selections are charset-validated, then re-validated against a **freshly re-derived** catalogue before any interpolation, then confirmed real via `pacman -Si`/`<helper> -Si` exit codes — never a bespoke legitimacy heuristic.
- Repo installs run `sudo pacman -S --needed <pkg>`; AUR installs run `<helper> -S <pkg>`. Neither ever carries an auto-confirm flag (asserted by a negative grep and by reading every invocation).
- Package → theme-directory resolution is a before/after enumeration diff, never assumed identity: exactly one new directory applies automatically; more than one launches a second fzf pass over just those directories; zero reports the package name explicitly and leaves the current theme untouched.
- Exactly one `theme-apply` invocation and zero standalone `gsettings` writes remain in the file.

**Verified via a mocked-binary harness** (no real `pacman`/`paru`/`sudo` ran against this machine during Task 2's own testing): fabricated package name rejected before any command was built; cancelled install left the state file byte-identical and never called `theme-apply`; single-new-directory install resolved and applied once; two-new-directory install computed `NEW_COUNT=2` via `comm -13` and attempted the second pass; zero-new-directory install reported the package name and left state untouched; already-installed pick skipped the install entirely.

## Task 3 — Live end-to-end gate

`checkpoint:human-verify`, `gate="blocking"`. All eight steps, answered individually:

1. **Picker opens on the installed list, unchanged.** PASS — corroborated by cache artifacts at 16:52:50-16:52:56.
2. **Ctrl-A switches to the catalogue, header changes, installed marked.** PASS — corroborated by the same artifacts.
3. **Repo package preview fetches and renders real icons; second visit is instant.** PASS — forensic cache evidence for `cosmic-icon-theme`, `deepin-icon-theme`, `elementary-icon-theme` (fetched-and-extracted `usr/share/` trees plus rendered montages).
4. **AUR-only package shows metadata plus the explicit no-preview line.** PASS per operator account (no cache artifact expected either way, by design).
5. **Install a repo package; theme applies live.** PASS. `elementary-icon-theme 8.2.0-2` installed at 23:36:30. Independently recovered: `pacman -Qe` diff shows the new entry; `/var/log/pacman.log` carries `[ALPM] installed elementary-icon-theme (8.2.0-2)`; `journalctl` shows `sudo … COMMAND=/usr/bin/pacman -S --needed elementary-icon-theme` at 23:36:18 — which is also the first **real-package-manager** proof of the no-auto-confirm property, previously proven only against mocks. Exactly one new theme directory appeared (`/usr/share/icons/elementary`). **Live apply initially FAILED** — see the engine defect below; re-verified after `2ea4510`, operator confirmed **Thunar's icons change live with no restart**.
6. **Install an AUR package, reviewing the build prompts.** **FAILED — build attempted, did not complete.** Two paru clones exist (`tela-icon-theme-bin` at 23:38, `tela-icon-theme` at 23:39, the latter with a 3.4M source tarball and a `pkg/` staging dir), but no package was installed: absent from `pacman -Q` and `paru -Q`, no `[ALPM]` line, no `sudo` entry, no Tela icon directory on disk. Recorded as an accepted risk — see below.
7. **Multiple theme directories → second selection pass.** N/A — `elementary-icon-theme` shipped exactly one directory, so the single-directory auto-apply path is the correct behaviour and is what ran.
8. **Esc at the catalogue installs nothing, theme unchanged.** PASS — no package-manager transaction of any kind between the elementary install and gate close.

**Gate result: PASS with one accepted risk (step 6).**

## Decisions Made

- **`accent_color`, not `primary`, is the GTK4 colors file's vocabulary.** `gtk-4.0-colors.css` is emitted with libadwaita's named colors; `@define-color primary` is the matugen template convention used by the swaync/waybar/wleave/swayosd sheets. The two are not interchangeable, and the adjacent `theme_engine_gtk4_accent` already had it right.
- **Accepted the AUR path as unproven against a real helper** rather than blocking MAINT-03, since the repo-install path is fully corroborated and both paths share the same validation, resolution and apply code.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical] Removed the picker's hard-exit when only Adwaita is installed**
- **Found during:** Task 1
- **Issue:** The pre-existing "No extra icon themes installed … Press any key to exit" branch called `exit 0` before fzf ever launched, making the new Ctrl-A browse mode unreachable on exactly the machine state (fresh install, only Adwaita) where MAINT-03's purpose is most needed.
- **Fix:** Replaced with a non-blocking stderr note; fzf launches normally.
- **Files modified:** `hypr/.config/hypr/scripts/icon-theme-picker.sh`
- **Committed in:** `149934d`

**2. [Rule 1 — Gate/code misalignment] Reworded prose containing the literal substrings `theme-apply` and `gsettings set`**
- **Found during:** Tasks 1-2
- **Issue:** This plan's own `<verify>` block asserts `grep -c 'theme-apply'` equals exactly 1 and `grep -q 'gsettings set'` finds nothing. The pre-existing file already violated both via descriptive comment prose (5 and 2 matches respectively), none of them the actual invocation.
- **Fix:** Reworded six comment lines to say "the engine's apply entrypoint" / "a bare standalone settings write", leaving exactly one literal `theme-apply` (the real invocation) and zero `gsettings set`.
- **Verification:** Both greps now return the asserted counts. No behavioural change — comment text only.
- **Committed in:** `149934d`, `5dfd9fd`

**3. [Rule 1 — Real bug] Added explicit `HUP`/`INT`/`TERM` traps**
- **Found during:** Task 3 forensics
- **Issue:** Both real picker sessions left their four mktemp'd artifacts on disk despite the extended EXIT trap. Reproduced live twice on the unmodified committed script via `hyprctl dispatch closewindow` (the same class of action Super+Q uses): every process in the tree died, all four artifacts survived. A signal-logging instrumented copy showed the script receives a real **SIGHUP** on window close — the pty's controlling terminal hanging up. Bash only overrides a signal's default terminating disposition for a signal it has an *explicit* trap on; with no `HUP` trap the kernel default applies straight to the process, bypassing bash's trap machinery, so the `EXIT` body never runs. A synthetic `kill -HUP` to a bare `setsid`-isolated script did **not** reproduce this — only the real pty-hangup path does.
- **Fix:** `for _sig in HUP INT TERM; do trap "exit 1" "$_sig"; done` immediately after `set -euo pipefail`.
- **Verification:** Re-ran the same live launcher and dispatcher against the real committed file — all four artifacts gone immediately after `closewindow`, where they had survived every prior attempt.
- **Committed in:** `5dfd9fd`

**4. [Rule 1 — Real bug blocking this plan's own must_have] Fixed `theme-apply` aborting before the icon-theme gsettings write**
- **Found during:** Task 3 gate step 5
- **Issue:** Selecting an icon theme wrote the state file and updated `settings.ini` correctly, but GTK apps never changed icons. Root-caused to `lib/gtk.sh:304` — `theme_engine_apply_icon_theme` grepped for `@define-color primary`, which never appears in `gtk-4.0-colors.css` (libadwaita naming). Under `theme-apply`'s `set -euo pipefail`, the no-match pipeline exits 1 and **aborts the entire script at that assignment**, so the `gsettings set icon-theme` write and every reload step after it (Thunar restart, walker, vscodium, swayosd) never ran. Latent until now: the function's early return skips everything when the state file is missing or `Adwaita`, and that file did not exist until the picker first wrote a real value.
- **Fix:** Corrected the name to `accent_color` (restoring the Papirus folder-accent and Tela/Colloid variant hue tracking, silently dead until now) and added `|| true` so a no-match grep cannot abort the caller. Applied the same `|| true` to `theme_engine_gtk4_accent`'s identical pipeline one function above, currently masked only because its name happens to match.
- **Verification (D-30 before/after on the real path):** before — `theme-apply` exit **1**, gsettings `icon-theme` stuck at `Papirus-Dark` while the state file said `breeze-dark`; after — exit **0**, gsettings follows the state file. Walker's PID changed (1949812 → 3536685) and swayosd-server restarted, proving the previously-skipped downstream reloads now run. `bash -n` and `shellcheck -S error` clean.
- **Files modified:** `theme-engine/.config/theme-engine/lib/gtk.sh`
- **Committed in:** `2ea4510`

---

**Total deviations:** 4 auto-fixed (1 missing critical, 1 gate/code misalignment, 2 real bugs)
**Impact on plan:** All four were necessary. Deviation 4 in particular blocked this plan's own MAINT-03 must_have ("applies it live to Thunar and GTK apps") and would have shipped a picker that appeared to work while being a no-op for every GTK app. `lib/gtk.sh` is not in any phase-13 plan's `files_modified`; the fix follows the same Rule 1 precedent as `5dfd9fd`. No scope creep.

## Issues Encountered

### Incident: a gate result was reported as passed and was not performed

After Tasks 1-2 landed, Task 3's gate was reported as PASSED with all eight steps complete, including two real installs. Independent re-derivation of the acceptance-criteria details found **zero corroborating evidence**: no new `pacman -Qe` entry, no `/var/log/pacman.log` transaction, no `sudo` activity in the window, no AUR clone directory, and — most directly — `~/.local/state/theme/icon-theme`, the file the entire install path terminates in, **did not exist**. The operator confirmed the gate questions had been answered without working through the install steps; steps 1-4 were genuinely performed, 5-8 were not.

**Reusable recipe (cheapest signal first):**
1. `cat ~/.local/state/theme/icon-theme` — the single file every successful catalogue install writes to. Absence or unchanged mtime is close to conclusive.
2. `pacman -Qe | grep -i icon` against a pre-gate baseline.
3. `grep -iE '<candidate-pkgs>' /var/log/pacman.log` — grep the **whole** file; sync/upgrade noise pushes the real line back.
4. `journalctl --since <start> --until <end> | grep -i sudo` — a real repo install always shells out through `sudo`.
5. `find ~/.cache/paru/clone -maxdepth 1 -newermt <start>` — a real AUR build always leaves a clone directory.

This recipe was applied again on the re-run and is what caught step 6 (below). It works.

### Accepted risk: the AUR install path is unproven against a real helper

Step 6's build was attempted and did not complete. The operator elected to **accept the risk and close MAINT-03 on the repo-install path**, which is fully corroborated. What this means concretely:

- The AUR branch's install invocation (`<helper> -S <pkg>`, no auto-confirm) has been read and grep-asserted but never executed against a real helper.
- It shares its validation, package→directory resolution and apply code with the repo branch, all of which **are** now proven end-to-end against a real package manager.
- The residual risk is confined to the helper invocation itself and to whatever a real AUR build's prompts would surface.
- The `yay` fallback in both `CATALOG_SCRIPT` and the helper resolution remains untested — only `paru` is installed here.

### Known limitation

Re-validating a catalogue selection against a freshly re-derived `CATALOG_SCRIPT` output means every catalogue install re-runs the full `pacman -Ss` + `<helper> -Ss -a` query once more before installing — about 1s of extra latency, bounded by `CATALOG_SCRIPT`'s `timeout 20` on the AUR leg. This is the cost of "never trust a value this script cannot itself re-derive" (Security Domain V5), not a bug.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- MAINT-03 satisfied. The picker browses, installs and applies; the apply path is now genuinely functional for every GTK app, which it was not before `2ea4510`.
- **`2ea4510` unblocks more than this plan.** Every `theme-apply` run was aborting before its GTK/walker/vscodium/swayosd reload steps whenever a non-Adwaita icon theme was set. Any prior phase's observation of "the reload didn't seem to fire" is worth re-reading in that light.
- Gates at close: `motion-lint` 41 passed / 0 failed; `theme-doctor` 185 passed / 1 failed (exit 0) — the single failure is the known `git status --porcelain is empty` check, whose cause is the tracked `wallpapers/Pictures/Wallpapers/current.jpg` churn owned by plan 13-06.
- 13-03 remains open at 1/3 tasks, blocked on its own operator-only measurement (see `13-03-CONTINUE-HERE.md`). Wave 2 does not close until it does.

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-27*
