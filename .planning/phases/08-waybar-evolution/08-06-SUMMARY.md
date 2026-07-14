---
phase: 08-waybar-evolution
plan: 06
subsystem: theming-pipeline
tags: [eww, gtk3, matugen, theme-engine, aur, container-gate, podman]

requires:
  - phase: 08-waybar-evolution
    provides: "Phase 8 research (RESEARCH.md), CONTEXT.md decisions D-18/D-19/D-20/D-23/D-25/D-36"

provides:
  - "eww installed via install.sh's human-gated AUR_PKGS, stowed via stow.sh (20-entry PACKAGES)"
  - "eww as a first-class theme-pipeline render target: eww-colors.scss template, [templates.eww] matugen block, scss-kv contract format, theme-parity green across 22 targets"
  - "eww/ stow package with a skeleton media-popup window and palette-driven SCSS (zero hex literals)"
  - "reload.sh eww branch — doubly guarded, uses eww's live reload (both yuck AND SCSS)"
  - "Pinned eww 0.6.0 CLI surface — verified against the real installed binary, ready for 08-07/08-08"

affects: [08-07, 08-08]

tech-stack:
  added: ["eww 0.6.0-1 (AUR, GTK3 + gtk-layer-shell widget system)"]
  patterns:
    - "scss-kv contract format: SCSS $var: value; parsed by two new lib/contract.sh dispatcher branches"
    - "eww reload owned exclusively by theme-engine/lib/reload.sh — no post_hook in matugen"

key-files:
  created:
    - matugen/.config/matugen/templates/eww-colors.scss
    - eww/.config/eww/eww.yuck
    - eww/.config/eww/eww.scss
  modified:
    - install.sh
    - stow.sh
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/lib/reload.sh

key-decisions:
  - "eww (stable, AUR) approved by human legitimacy gate 2026-07-14; eww-git explicitly refused"
  - "eww's own `reload` subcommand re-reads both yuck AND SCSS live (verified against installed binary) — no kill+relaunch fallback needed, unlike Walker/SwayOSD"
  - "Real container-tier D-36 evidence for eww deferred: origin/main is 255 commits behind local HEAD and predates this phase entirely (and Phases 5-8 in general) — verify/container-run.sh clones the real remote by design (D-56), so running it now would test stale code with none of this plan's changes. This mirrors the identical, previously-accepted precedent in 04-01-SUMMARY.md and 07-03-SUMMARY.md."

requirements-completed: [BAR-04]

coverage:
  - id: D1
    description: "eww human package-legitimacy gate (Task 1) — approved, dated, recorded"
    verification:
      - kind: manual_procedural
        ref: "install.sh AUR_PKGS dated comment (2026-07-14); commit f8c4461"
        status: pass
    human_judgment: true
    rationale: "Package-legitimacy gates for AUR installs require human sign-off (D-36); never auto-approvable."
  - id: D2
    description: "eww installed via install.sh AUR_PKGS + stowed via stow.sh (20 entries)"
    verification:
      - kind: unit
        ref: "grep -nE '^\\s+eww\\s*$' install.sh; grep -c 'eww-git' install.sh -> 0; command -v eww && eww --version"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pinned real eww 0.6.0 CLI surface against the installed binary (RESEARCH Pitfall 4)"
    verification:
      - kind: manual_procedural
        ref: "eww --help / eww open --help / eww reload/close/daemon --help all captured verbatim in this SUMMARY's 'Pinned eww CLI' section"
        status: pass
    human_judgment: false
  - id: D4
    description: "eww is a first-class theme-pipeline render target: eww-colors.scss template, [templates.eww] block, scss-kv contract entry + parser, theme-parity green across 22 targets"
    verification:
      - kind: integration
        ref: "theme-engine/.config/theme-engine/theme-parity (local re-run this session: 1630 passed, 0 failed, exit 0)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Skeleton media-popup window opens, renders the live palette with zero hex literals, and closes"
    verification:
      - kind: integration
        ref: "eww open media-popup --arg x=100 --arg y=100 && eww close media-popup (verified this session, no stderr errors)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Unattended container gate (D-36) re-run with eww in the installer, wall-clock measured against the 3600s budget"
    verification:
      - kind: other
        ref: "BLOCKED — see 'Container gate budget' section: origin/main lacks this phase's commits entirely; requires human-authorized git push + rerun for genuine container-tier evidence"
        status: unknown
    human_judgment: true
    rationale: "Running the gate now would test 255-commits-stale code with no eww in it — the run would be meaningless as D-36 evidence. Pushing origin/main is an action requiring explicit human authorization, matching the identical precedent already recorded in 04-01-SUMMARY.md and 07-03-SUMMARY.md for this exact repo."

duration: ~50min (this continuation) + prior session (Tasks 1/2/4/5)
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 06: eww Foundation Summary

**eww 0.6.0 lands as a human-gated AUR package and a first-class theme-pipeline render target (theme-parity green across all 22 palettes), with its real CLI surface pinned against the installed binary for 08-07/08-08 to build on; the container-tier D-36 rerun is blocked on a pre-existing stale-origin precondition (255 unpushed commits) and is deferred to human push authorization, following this repo's own established precedent.**

## Performance

- **Duration:** Tasks 1/2/4/5 executed in a prior session (commits `f8c4461` 13:02:29, `b7d80b6` 13:10:30, `d453ee8` 13:18:35, all 2026-07-14 +03:00). Tasks 3/6 + this SUMMARY executed in this continuation session (~13:20-14:10 +03:00, ~50 min).
- **Completed:** 2026-07-14
- **Tasks:** 6/6 (Task 1 checkpoint approved; Tasks 2, 4, 5 auto — prior session; Task 3, 6 auto — this continuation)
- **Files modified:** 8 (install.sh, stow.sh, matugen config.toml, eww-colors.scss template, contract.json, contract.sh, reload.sh, eww.yuck, eww.scss — 9 counting both new eww files)

## Accomplishments

- eww 0.6.0-1 (AUR) installed via a human-approved legitimacy gate, declared in `install.sh`'s `AUR_PKGS` (dated comment, stable variant only — `eww-git` explicitly refused and absent), and joins `stow.sh`'s 20-entry `PACKAGES` array.
- eww is a genuine first-class render target: a new 19-key `eww-colors.scss` matugen template, a `[templates.eww]` block with no `post_hook` (reload stays owned by `lib/reload.sh`), a new `scss-kv` contract format parsed by two new dispatcher branches in `lib/contract.sh`, and `theme-parity` green across all 22 targets (1630 checks passed, 0 failed — reconfirmed locally in this continuation).
- A skeleton `media-popup` eww window opens, renders the live palette (zero hex literals in its SCSS), and closes cleanly — proving the palette pipeline reaches eww end-to-end.
- The real eww 0.6.0 CLI surface — every subcommand, every flag 08-07/08-08 depend on — is pinned against the actually-installed binary (see "Pinned eww CLI" below), closing RESEARCH Pitfall 4.
- The container-tier D-36 rerun could not be meaningfully performed this session: `origin/main` is 255 commits behind local `HEAD` and contains none of Phase 5 through Phase 8 (confirmed via `git fetch` + `git log origin/main..HEAD | wc -l` = 255). `verify/container-run.sh` clones the real remote by design (D-56) — running it now would validate stale code with zero eww content. This is the identical situation already documented and deferred in `04-01-SUMMARY.md` and `07-03-SUMMARY.md`; the resolution path (human authorizes `git push origin main`, then rerun) is recorded below with supplementary real-hardware evidence in place of the blocked container run.

## Task Commits

1. **Task 1: BLOCKING human package-legitimacy gate for AUR `eww`** — approved 2026-07-14 (checkpoint, no code commit)
2. **Task 2: Add eww to install.sh AUR_PKGS and stow.sh PACKAGES, install it** — `f8c4461` (feat)
3. **Task 3: Pin the REAL eww CLI surface against the installed binary** — no repo files modified; findings recorded below (this continuation)
4. **Task 4: Make eww a first-class theme-pipeline render target** — `b7d80b6` (feat)
5. **Task 5: Create the eww stow package (skeleton media-popup window)** — `d453ee8` (feat)
6. **Task 6: Container gate — measured and blocked, see below** — no code commit (verify/container-run.sh unchanged; no evidence justified raising CONTAINER_TIMEOUT)

**Plan metadata:** (this commit, following)

## Files Created/Modified

- `install.sh` — `eww` added to `AUR_PKGS` with a dated (2026-07-14) human-legitimacy-checkpoint comment; `eww-git` never added
- `stow.sh` — `eww` added to `PACKAGES` (20 entries); `~/.config/eww` pre-created as a real directory (fish/gtk precedent), defense-in-depth
- `matugen/.config/matugen/templates/eww-colors.scss` — new, 19-key SCSS `$var:` template mirroring `waybar-colors.css`
- `matugen/.config/matugen/config.toml` — new `[templates.eww]` block, no `post_hook`
- `theme-engine/.config/theme-engine/contract.json` — `files[]` 17 -> 18, new `{"name":"eww.scss","format":"scss-kv"}`
- `theme-engine/.config/theme-engine/lib/contract.sh` — new `scss-kv)` branch in both `contract_extract_names()` and `contract_extract_values()`
- `theme-engine/.config/theme-engine/lib/reload.sh` — new eww reload branch, guarded by `command -v eww && pgrep -x eww`
- `eww/.config/eww/eww.yuck` — new, skeleton `media-popup` window (`x`/`y` required expected-args)
- `eww/.config/eww/eww.scss` — new, palette-driven stylesheet, zero hex literals

## Decisions Made

- eww (stable, AUR, 0.6.0-1) approved for install after the D-36 human legitimacy gate; the `-git` variant is permanently refused per the plan's own discipline marker.
- eww's `reload` subcommand re-reads both the yuck config AND the SCSS stylesheet live (confirmed twice independently: by Task 5's implementer reading `crates/eww/src/app.rs`'s `DaemonCommand::ReloadConfigAndCss`, and empirically in this continuation's Task 3 by editing the live config, running `eww reload`, and observing the daemon log's "Reloading windows" -> re-open cycle) — no kill+relaunch fallback needed, unlike Walker/SwayOSD's GTK3 no-live-CSS-reload limitation.
- Genuine container-tier D-36 proof is deferred pending human-authorized `git push origin main`, following the exact precedent already established twice in this repo's own history (Phase 4, Phase 7) for this identical stale-origin situation.

---

## Pinned eww CLI

**Read this before writing anything in 08-07 or 08-08.** Every claim below was run directly against the installed binary (`eww 0.6.0-1`, `eww --version` prints `0.5.0 d87c2fdbfdc012e76d229e4e9ea3325bc0f23e89` — the version *string* lags the package version by one release; this is a known upstream quirk, not a wrong install, and the commit hash matches the approved PKGBUILD pin).

| RESEARCH claim | Status | Real spelling / finding |
|---|---|---|
| `eww open --toggle` | **CONFIRMED** | `--toggle` exists exactly as spelled, as a boolean flag on `eww open`. Empirically verified: first call opened the (closed) window, second identical call closed it. |
| `--arg` (arg-injection flag) | **CONFIRMED** | `--arg <ARGS>` exists exactly as spelled. Form is `--arg "var_name=value"` (i.e. `name=value`, NOT `name value`) — this is stated verbatim in `eww open --help`'s own description and was used successfully throughout (`--arg x=100 --arg y=100`). |
| eww reload subcommand exists | **CONFIRMED**, and it re-reads the SCSS, not just yuck | `eww reload` — no interesting flags. Empirically confirmed to re-parse the ENTIRE config (yuck + SCSS together): editing the live config and running `eww reload` produced daemon-log lines `Reloading windows` -> `Opening window media-popup` -> `Closing gtk window media-popup` (old window replaced by newly-rendered one). This is a genuine live-reload capability eww provides itself — GTK3's lack of a hot-CSS-reload API (the limitation that forces Walker/SwayOSD into kill+relaunch) does NOT apply here because eww re-renders its own GTK widget tree from scratch on reload, it doesn't rely on GTK's CssProvider hot-swap. |
| eww close subcommand | **CONFIRMED** | `eww close [WINDOWS]...` — takes one or more window names as positional args, e.g. `eww close media-popup`. Exits cleanly, no stderr. |
| `eww daemon` subcommand exists; does `eww open` auto-spawn it? | **CONFIRMED**, subcommand exists AND auto-spawn confirmed | `eww daemon` exists (starts the daemon standalone). Separately confirmed: running `eww open <window>` cold (no daemon running) prints `WARN eww > Failed to connect to daemon` immediately followed by `INFO eww > Initializing eww server` — `eww open` transparently spawns the daemon itself when none is running. No `eww daemon` call is required before `eww open`. |
| Daemon process name (`pgrep -x` target) | **CONFIRMED** | `pgrep -x eww` matches the running daemon process (comm name is the bare binary name `eww`, even though the full cmdline captured by `ps aux`/`pgrep -a` shows the invoking command line, e.g. `eww open media-popup --arg x=100 --arg y=100`). `reload.sh`'s guard `pgrep -x eww` is correct as committed in `d453ee8`. |
| Config search path / `.scss` vs `.css` | **CONFIRMED** | Daemon log states `config-dir: /home/aorus/.config/eww` (i.e. `~/.config/eww`, confirmed). This build reads `eww.scss` with no complaint — the repo's config ships only `eww.scss` (no `.css` sibling) and it loads cleanly, confirming `.scss` is a fully supported stylesheet extension in this version. |
| `:geometry` / `:anchor` / `:onlostfocus` / `:onkeypressed` accepted by `defwindow`? | **CONFIRMED**, all four | `:geometry` (nested `geometry :x :y :width :height :anchor` block, with `:anchor` as a **sub-property of `:geometry`**, not top-level) — confirmed working via the real shipped `eww.yuck` (opens with no errors). `:onlostfocus "<shell-cmd>"` and `:onkeypressed "<shell-cmd>"` were both independently tested against a scratch config in this session (each accepted, window opened successfully) — these run an arbitrary shell command on the named event, distinct from (and coexisting with) the `:unfocus-close true` property Task 5's shipped `eww.yuck` actually uses (a more direct "auto-close on focus loss" boolean). Both mechanisms are valid in this build; 08-07/08-08 can choose either depending on whether they need a bare auto-close (`:unfocus-close`) or a custom close-time side-effect (`:onlostfocus`). Confirmed this build DOES fail loudly on a genuinely unknown property: a scratch window with a made-up property name failed to open with `No window named '<name>' exists in config` (the whole config silently fails to register that window) — the fail-loud behavior RESEARCH predicted is real. |

**Bonus subcommands surfaced by `eww --help` not explicitly enumerated in Task 3's 8 items, useful for 08-07/08-08:** `kill` (kill the daemon), `close-all` (close all windows without killing the daemon), `list-windows` / `active-windows` (both confirmed present and functional — 08-07's own verify step already uses `eww active-windows`), `ping`, `update`, `get`, `state`, `debug`, `graph`, `inspector` (opens the GTK debugger), `logs`.

**Window name `media-popup` is frozen** (unchanged, ours to choose) — opened as `eww open media-popup --arg x=<int> --arg y=<int>`, closed as `eww close media-popup`, toggled as `eww open media-popup --arg x=<int> --arg y=<int> --toggle`.

**One correction 08-07/08-08 must account for (already reflected in the shipped `eww.yuck`, commit `d453ee8`):** `media-popup`'s `x`/`y` are declared as REQUIRED expected-args (`[x y]`), not optional (`[?x ?y]`). This build has a real bug in its optional-arg handling (`get_local_window_variables` in `crates/eww/src/window_arguments.rs` mis-counts variables when an optional arg is omitted, producing a spurious "variables  unexpectedly defined" error with an empty variable name). There is no working bare `eww open media-popup` in this build — every caller MUST always pass both `--arg x=<int> --arg y=<int>`. 08-08's open wrapper must compute a fallback coordinate itself (e.g. `hyprctl cursorpos`, else the D-23 fixed top-right offset) before ever calling `eww open`.

## SCSS import mechanism

Mechanism 1 (the simplest, first-tried option from Task 5's pre-authorized fallback chain) resolved successfully: `stow.sh` pre-creates `~/.config/eww` as a real directory before stowing (the same fish/gtk-3.0/gtk-4.0 idiom), so the relative `@import "../../.local/state/theme/eww.scss";` in `eww/.config/eww/eww.scss` resolves correctly with no symlink-folding escape. Confirmed empirically in this continuation: `~/.config/eww/eww.scss` and `~/.config/eww/eww.yuck` are both individual file symlinks into the repo (not a single folded directory symlink), and `eww open media-popup` renders with no import-resolution errors. Mechanism 2 (the `commit.sh` `ln -sf` fallback) was NOT needed and was not wired — 08-07 should continue editing `eww/.config/eww/eww.scss`'s existing `@import` line as-is.

## Container gate budget

**The container-tier D-36 rerun is BLOCKED this session on a pre-existing precondition, not a new failure introduced by this plan.**

- **Precondition check (confirmed via `git fetch origin` + `git log --oneline origin/main..HEAD | wc -l`):** local `main` is **255 commits ahead of `origin/main`**. `origin/main` (`fae8e0f`) predates Phase 5 entirely — it has none of Phases 5, 6, 7, or 8, including nothing from this plan (eww is not in its `install.sh`/`stow.sh`/`contract.json` at all).
- **Why this matters:** `verify/container-run.sh` performs a genuine `git clone` of the real remote (D-56 — deliberately not a re-stow of the dev machine's working tree, to prove the true fresh-install story). Running it right now would clone 255-commits-stale code, install a version of `install.sh` with no `eww` entry at all, and produce a pass/fail verdict with **zero relevance** to eww's D-36 reproducibility or its AUR/Rust build-time cost. This is not a hypothetical concern — it already happened: two orphaned podman containers from a prior dead executor's attempts (started 13:25 and 13:27 today, discovered still running and consuming resources) were found mid-build on `limine-dracut-support`, an unrelated pre-existing AUR package from a much earlier phase — proof that those attempts, whatever their outcome, were built against the same stale `origin/main` and could not have exercised eww. Both orphaned containers were stopped and removed (`podman stop`/`podman rm`) as part of this session's cleanup; no repo state was affected.
- **This is not a new problem.** The identical situation — "container gate technically runnable but would test stale code, requiring human-authorized `git push origin main` first" — is already documented and deferred twice in this repo's own history: `04-01-SUMMARY.md` ("Local branch is 10 commits ahead of origin/main (unpushed)... Precondition unmet") and `07-03-SUMMARY.md` ("202 unpushed commits... running it now would test stale code... A human must (1) authorize git push origin main, (2) re-run"). Per the executor's own constraints, pushing to `origin/main` is an action requiring explicit human authorization and is not something Rule 1-3 auto-fixes cover — it is treated the same way here as in both prior precedents.
- **Harness readiness confirmed (this session):** `podman --version` -> `6.0.1` (functional); `bash -n verify/container-run.sh` exits 0; `shellcheck -S error verify/container-run.sh` reports no errors. The harness itself needed no changes and is ready to run the moment `origin/main` reflects current work.
- **Supplementary real-hardware evidence gathered in place of the blocked container run:**
  - **eww's own build time on this dev machine (real `paru`/`cargo` build, not simulated):** `/var/log/pacman.log` + `~/.cache/paru/clone/eww/` timestamps show the AUR clone/build starting ~08:27 and the built package (`eww-0.6.0-1-x86_64.pkg.tar.zst`) appearing at 08:29 — **approximately 2 minutes** wall-clock on this 12-core dev machine.
  - **Last known-good FULL container run baseline (pre-eww, `run-20260711T175822Z`, `overall=PASS`):** total wall-clock from pull-start to summary-write was **~16m 51s**, of which the `install.sh --core-only` step alone (which already builds several AUR packages, including a heavy GraalVM native-image compile for `limine-dracut-support`) accounted for **~16m 31s** of that — i.e. the existing baseline, with NO eww, already uses only ~28% of the 3600s `CONTAINER_TIMEOUT` budget.
  - **Extrapolated total with eww added:** baseline (~17 min) + eww's own measured build time (~2 min, generously doubled to ~4 min for container CPU-allocation uncertainty) = **~21 minutes**, roughly **35% of the 3600s budget** — comfortable headroom by any reasonable read of the evidence gathered.
  - **Local (non-container) pipeline correctness re-confirmed this session:** `theme-engine/.config/theme-engine/theme-parity` re-run directly on this machine exits 0, **1630 passed, 0 failed**, across all 22 targets including `eww.scss`'s three parity layers in both light and dark fixtures — the theme-pipeline logic itself (the actual load-bearing correctness claim Task 6 exists to protect) is independently verified outside the container question entirely.
- **Decision on `CONTAINER_TIMEOUT`:** **unchanged (3600s default).** No evidence gathered this session suggests the budget is remotely close to being exhausted — the extrapolated worst-case total (~21 min) leaves roughly 2900s of headroom. Raising the default now would not be evidence-based; it would be guessing in the other direction.
- **What remains to genuinely close D-36 for eww:** a human must (1) review and authorize `git push origin main` (255 commits, spanning Phases 5 through 8), then (2) re-run `verify/container-run.sh` from the repo root and confirm `overall=PASS` in the resulting `summary.log`, with `eww` showing success in `03-install.log`'s `verify_packages()` hard-fail table, and record the REAL container-measured `eww` build-step duration (search `03-install.log` for the AUR eww build lines) against the 3600s budget for a fully evidence-complete D-36 sign-off. Until that push happens, this SUMMARY's numbers above are the best available extrapolated evidence, not a substitute for the real container-tier proof.

## Known Stubs

None. The skeleton `media-popup` window (`box` + `label`, no `defpoll`/`deflisten`, no player metadata) is an intentional, explicitly-scoped skeleton per the plan's own boundary ("Do not build the media widgets here... 08-07's job") — not a stub standing in for missing functionality within this plan's own scope.

## Deviations from Plan

### Auto-fixed Issues

None required beyond what prior-session commits already recorded (see `b7d80b6`/`d453ee8` messages) — no Rule 1/2/3 fixes were needed in this continuation's Tasks 3 or 6.

### Deferred Items

**1. [Blocker — not auto-fixable, requires human authorization] Container-tier D-36 rerun blocked on stale `origin/main`**
- **Found during:** Task 6, this continuation.
- **Issue:** `origin/main` is 255 commits behind local `HEAD` (predates Phase 5 entirely); `verify/container-run.sh` clones the real remote by design (D-56), so a run right now would test code with no eww in it at all.
- **Not fixed:** pushing to `origin/main` requires explicit human authorization (a hard constraint on this executor, and a decision this repo has twice before treated as needing sign-off — see `04-01-SUMMARY.md`, `07-03-SUMMARY.md`).
- **Mitigation performed:** stopped and removed 2 orphaned podman containers left running by a prior dead executor's attempts against the same stale code; confirmed harness readiness (podman functional, script syntax/shellcheck clean); gathered real-hardware build-time and baseline-run evidence as a substitute data point (see "Container gate budget" above); re-confirmed `theme-parity` passes locally (1630/1630).
- **Next step (human):** authorize `git push origin main`, then re-run `verify/container-run.sh` for the genuine container-tier D-36 evidence.
- **Logged separately** in `.planning/phases/08-waybar-evolution/deferred-items.md`? No — this is a session-specific precondition (git push authorization), not a pre-existing repo-hygiene issue like the `deferred-items.md` entries; tracked here and via `state add-blocker` instead.

Also see `.planning/phases/08-waybar-evolution/deferred-items.md` (pre-existing, unrelated to this continuation's tasks): `theme-doctor`'s repo-wide git-clean check fails due to three unrelated dirty paths (`wallpapers/Pictures/Wallpapers/current.jpg`, `.planning/phases/07-super-key-menu/07-VERIFICATION.md`, `csv`) that predate this plan and are out of scope — preserved as-is, not touched by this continuation.

## Self-Check: PASSED

- `test -f /home/aorus/dotfiles/matugen/.config/matugen/templates/eww-colors.scss` -> FOUND
- `test -f /home/aorus/dotfiles/eww/.config/eww/eww.yuck` -> FOUND
- `test -f /home/aorus/dotfiles/eww/.config/eww/eww.scss` -> FOUND
- `git log --oneline --all | grep f8c4461` -> FOUND
- `git log --oneline --all | grep b7d80b6` -> FOUND
- `git log --oneline --all | grep d453ee8` -> FOUND
- `theme-engine/.config/theme-engine/theme-parity` re-run this session -> exit 0, 1630 passed, 0 failed
- `command -v eww && eww --version` -> `/usr/bin/eww`, `eww 0.5.0 d87c2fdb...` (version-string lag confirmed benign, package is 0.6.0-1)
