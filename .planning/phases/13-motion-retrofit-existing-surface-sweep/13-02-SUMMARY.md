---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 02
subsystem: theming
tags: [sass, gtk3, swaync, motion, theme-engine, contract.json, systemd, dbus, motion.json]

# Dependency graph
requires:
  - phase: 13-motion-retrofit-existing-surface-sweep
    provides: "13-01's full MD3 easing scale, motion.json's indicators category, the D-21 A/B curve-set toggle, and the render-gate 8x lively-multiplier instrument method"
provides:
  - "The fourth token-consumption path: a sass precompile mechanism (theme_engine_render_motion_scss + theme_engine_compile_gtk3_stylesheets) that plan 13-05 extends to waybar's six files"
  - "swaync fully retrofitted onto motion tokens (MOTION-02 for this one surface): zero raw duration/easing literal remains in swaync/style.scss"
  - "A new contract.json format tag (gtk-css-motion) for compiled GTK3 sheets that bake in motion but only ever @import colour"
  - "A durable finding: colour/opacity-only CSS surfaces cannot host a curve-fidelity render-gate check at any exaggeration — reusable directly by 13-05's waybar gate"
  - "A durable finding: systemd (v261) silently ignores a drop-in .d directory that is itself a symlink — reusable by any future stowed systemd unit in this repo"
affects: [13-05, 13-06, 13-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "sass --no-charset --no-source-map --load-path=<tmp state dir> as the GTK3-stylesheet compile invocation shape, run inside theme_engine_generate as a fourth sibling writer"
    - "GTK-CSS @name colour references escaped via #{\"...\"} sass interpolation, verified byte-identical to the pre-conversion literal"
    - "A new contract.json format tag (gtk-css-motion) whose name/value surrogate is the set of cubic-bezier(...) values inside transition:/animation: declarations plus a synthetic @import marker — the pattern to reuse for any future colour-free, motion-only compiled sheet"
    - "systemd user-service drop-ins in this repo MUST have their parent .d directory pre-created as a real directory in stow.sh before stow runs, or systemd silently ignores the whole drop-in"

key-files:
  created:
    - hypr/.config/hypr/scripts/swaync-launch.sh
    - swaync/.config/systemd/user/swaync.service.d/override.conf
    - .planning/phases/13-motion-retrofit-existing-surface-sweep/deferred-items.md
  modified:
    - theme-engine/.config/theme-engine/lib/motion.sh
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-parity
    - theme-engine/.config/theme-engine/theme-doctor
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/config/autostart.conf
    - stow.sh
    - swaync/.config/swaync/style.scss (renamed from style.css)

key-decisions:
  - "Task 1 (D-01 one-way door re-confirmed): proceed-sass — the sass precompile mechanism is confirmed as swaync's and, subsequently, waybar's (13-05) GTK3 launch path"
  - "contract.json format tag: swaync-style.css registered as a NEW gtk-css-motion tag, not the plan's originally-specified gtk-css, after proving both gtk-css and the alternative css-literal empty/fail against the real theme-parity checker"
  - "D-Bus race fix: a stowed systemd drop-in (ExecStart override) rather than masking swaync.service — keeps D-Bus activation alive as a themed recovery path instead of eliminating one racer"
  - "D-17 render gate APPROVED on revised evidence — 2 of 5 checks visually confirmed (liveness, compositor-delivered entrance/exit); duration mechanically proven with visual confirmation explicitly WAIVED by the operator; curve-shape fidelity closed on mechanical token-identity proof after exhaustively proving no visual instrument exists on this surface at any exaggeration"

patterns-established:
  - "A surface whose transitions animate only colour/opacity properties cannot host a curve-fidelity render-gate check at any exaggeration, because there is no spatial reference against which acceleration/deceleration is visible — duration remains judgeable, curve shape does not. Proven by exhaustive enumeration, not assumed; see the Render Gate section below for the full method and evidence table. Directly reusable by 13-05's waybar gate if waybar's transitions turn out to be colour-only too."
  - "Any future stowed systemd user-service drop-in in this repo must pre-create its own .d directory as a real directory in stow.sh (mkdir -p before the stow loop) — stow's normal whole-directory symlink fold makes systemd 261 silently ignore the entire drop-in (DropInPaths= stays empty), proven by direct A/B comparison against an identical real directory."

requirements-completed: []
# MOTION-02 and MOTION-03 are BOTH multi-surface/multi-plan requirements
# (MOTION-02: "waybar, swaync, walker, SwayOSD, wleave and the AGS media
# card all animate from the shared motion tokens"; MOTION-03: "every
# retrofitted surface passes a blocking render gate"). This plan satisfies
# ONLY the swaync portion of each. Marking either complete here would
# misrepresent waybar's still-pending 13-05 conversion and its own render
# gate — same discipline 13-01's SUMMARY applied for the identical reason.
# Left open in REQUIREMENTS.md; 13-05 is where either could be closed.

coverage:
  - id: D1
    description: "swaync's stylesheet consumes motion tokens through a sass-compiled state-dir sheet; zero raw duration/easing literal remains in the repo-authored source"
    requirement: "MOTION-02"
    verification:
      - kind: other
        ref: "motion-lint (swaync/style.scss scanned, CHECK A/B both pass, exemption removed); theme-parity Layer 1-4 (structure/name-set/value/byte-identity, all pass for _motion.scss and swaync-style.css); theme-doctor GTK3 CssProvider load + whole-stylesheet-discard control reproduction"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-17 render gate: swaync fidelity — liveness (colour re-apply), duration-axis reach, compositor-delivered entrance/exit, and curve-shape fidelity"
    requirement: "MOTION-03"
    verification: []
    human_judgment: true
    rationale: "Fidelity is a perceptual judgment only the operator can make. Approved 2026-07-27 on REVISED evidence: only 2 of 5 checks (liveness, compositor-delivered entrance/exit) received live visual confirmation. The duration-axis check was mechanically proven (compiled sheet reads exactly 100ms at reduced, 200ms at normal) with visual confirmation explicitly WAIVED by the operator. The two curve-shape-fidelity checks were closed on mechanical token-identity proof (compiled sheet's cubic-bezier control points byte-identical to Hyprland's and the QML-consumed motion.json's emitted values for the same token) after an exhaustive enumeration proved no visual instrument exists anywhere on this surface for judging curve shape, at any exaggeration — see the Render Gate section for the full method, evidence table, and the durable finding this produced."

duration: multi-session (exact wall-clock start not captured; spans the D-19 soak window from 2026-07-27T03:40:53Z through this plan's close)
completed: 2026-07-27
status: complete
---

# Phase 13 Plan 02: Sass-Precompile Mechanism + Swaync Motion Retrofit Summary

**Swaync's six transitions now resolve `standard` (200ms MD3-standard curve) from `motion.json` through a sass-compiled `~/.local/state/theme/swaync-style.css`, delivered by a fourth theme-engine render/compile pipeline stage — plus a real D-Bus-activation race regression this plan introduced and fixed, and a systemd/stow interaction that will bite the next stowed systemd drop-in in this repo unless it reads this SUMMARY first.**

## Performance

- **Duration:** multi-session (see frontmatter note)
- **Completed:** 2026-07-27T12:51:42Z
- **Tasks:** 4/4 complete (1 decision, 2 auto, 1 checkpoint:human-verify)
- **Files modified:** 12 (2 new: `swaync-launch.sh`, `swaync.service.d/override.conf`; 10 modified; `swaync/style.css` renamed to `.scss`)

## Accomplishments

- **The sass precompile mechanism exists and is proven**, end-to-end, against the real binaries: `theme_engine_render_motion_scss` (a new `_motion.scss` sass partial writer) and `theme_engine_compile_gtk3_stylesheets` (`sass --no-charset --no-source-map --load-path=...`, a `GTK3_SCSS_TARGETS` array plan 13-05 appends six waybar rows to without restructuring) — both wired into `theme_engine_generate` as a fourth sibling writer, propagated `|| return 1`, proven to leave the live state dir byte-unchanged on a deliberately broken `.scss`.
- **swaync converted**: `style.css` → `style.scss` (git history preserved via `git mv`), every `@name` colour reference interpolation-escaped, all six `transition: all 0.2s ease` rules tokenized onto `#{m.$motion-duration-standard} #{m.$motion-easing-standard}`, colour kept a live `@import` (D-03) — a theme switch still re-colours swaync with zero recompile.
- **The whole-stylesheet-discard failure class (WLOG-01) was reproduced, not assumed**: a charset-at-rule-prepended control copy of the compiled sheet loads through a real GTK3 `CssProvider` as 0 bytes with a fatal parse error; the real (no-charset) compiled sheet loads as 22,279 bytes with zero fatal errors.
- **contract.json/theme-parity/theme-doctor/motion-lint/stow.sh all learned the two new render targets** — full format-validated entries (not presence-only, per D-35), the D-31 byte-identity walk extended and proven able to fail, the swaync exemption removed from motion-lint, and a loud (no `|| true`) `stow.sh` seed that invokes the real renderer+compiler.
- **A real regression this plan introduced was found and fixed**: swaync's D-Bus service-activation path was racing Hyprland's `exec-once` launch and — after this plan made colour+motion require an explicit `-s <compiled-path>` flag — could win and load the system-stock, unstyled `/etc/xdg/swaync/style.css` instead. Fixed with a stowed systemd drop-in, not a mask, so D-Bus activation stays a working, themed recovery path.
- **A systemd/stow interaction was discovered, isolated, and worked around**: systemd 261 silently ignores an entire drop-in `.d` directory when it is a symlink (stow's normal whole-directory fold). Fixed by pre-creating the real directory in `stow.sh` before stow runs, so only the file inside gets symlinked.
- **D-17 render gate APPROVED on revised evidence** — only 2 of 5 checks received live visual confirmation; the other 3 closed on mechanical proof after an exhaustive enumeration showed swaync's stylesheet has no visual instrument for curve-shape fidelity at all (colour/opacity-only transitions, no geometric property ever animates). This is recorded as its own durable, reusable finding below.
- **D-18 soak integrity preserved throughout**: `hyprland-motion.conf`'s sha256 was pinned before any edit and re-verified byte-identical after every single render-affecting operation in this plan (including the render-gate's own scratch `lively`-multiplier instrument, restored to `1.25` before close).

## Task Commits

1. **Task 1: Costly door — the sass precompile mechanism (D-01)** — decision only, no commit (operator selected `proceed-sass`)
2. **Task 2: Emit the partial, compile inside generate, convert swaync** — `4b11232` (feat)
3. **Task 3: Point swaync at the compiled sheet, and close the guards around it** — `3f4e567` (feat) — includes the D-Bus race fix and the two `contract.sh` deviations described below
4. **Task 4: D-17 render gate** — no code artifact (checkpoint-only task); outcome recorded in this SUMMARY

**Plan metadata:** committed alongside this SUMMARY (see final commit hash in orchestrator output)

## Files Created/Modified

- `theme-engine/.config/theme-engine/lib/motion.sh` — `theme_engine_render_motion_scss` (new writer), `theme_engine_compile_gtk3_stylesheets` + `GTK3_SCSS_TARGETS` (new compile function + registry)
- `theme-engine/.config/theme-engine/lib/generate.sh` — wires the compile step as a fourth sibling writer, `|| return 1` propagated
- `theme-engine/.config/theme-engine/lib/contract.sh` — new `gtk-css-motion` format (name+value extractors); `scss-vars` name+value extractors widened to accept hyphens (both deviations from the plan text — see below)
- `theme-engine/.config/theme-engine/contract.json` — two new `files` entries: `_motion.scss` (`scss-vars`), `swaync-style.css` (`gtk-css-motion`)
- `theme-engine/.config/theme-engine/theme-parity` — D-31 byte-identity walk extended to the two new render targets
- `theme-engine/.config/theme-engine/theme-doctor` — `GTK3_CSS_SHEETS` repoints swaync's entry at the compiled state-dir output
- `hypr/.config/hypr/scripts/motion-lint` — `swaync/style.css` exemption removed
- `hypr/.config/hypr/scripts/swaync-launch.sh` (new) — launches swaync pointed at the compiled sheet, degrading to unstyled (never no-daemon) if absent
- `hypr/.config/hypr/config/autostart.conf` — repointed at the new launcher
- `stow.sh` — seeds the two new render targets by invoking the real renderer/compiler (loud on failure, no `|| true`); pre-creates `~/.config/systemd/user/swaync.service.d` as a real directory before stow runs
- `swaync/.config/systemd/user/swaync.service.d/override.conf` (new) — the D-Bus-activation-path fix
- `swaync/.config/swaync/style.scss` (renamed from `style.css`) — fully tokenized, colour stays a live `@import`

## Decisions Made

- **Task 1 (D-01 re-confirmation):** `proceed-sass` — operator confirmed the sass precompile mechanism before it became swaync's launch path. Recorded verbatim before Task 2 created any file, per the gate's acceptance criteria.
- **contract.json format tag for `swaync-style.css`:** `gtk-css-motion` (new), not the plan's originally-specified `gtk-css`. See "Deviation 1" below for the full proof.
- **`scss-vars` extractor fix:** widened to accept hyphens. See "Deviation 2" below.
- **D-Bus race fix shape:** a stowed systemd drop-in overriding `ExecStart`, not masking `swaync.service`. Operator's explicit reasoning: masking makes Hyprland's `exec-once` the *only* possible launch path — if it ever fails, there is no notification daemon and no recovery route. The drop-in makes both racers correct instead of eliminating one.
- **Render gate closure:** APPROVED on revised evidence — see the dedicated section below.

## Deviations from Plan

Four deviations, each substantial enough to warrant its own write-up rather than a list entry. All were investigated empirically against the real binaries/checkers before being decided, per this repo's "verify against the binary" discipline, and none were decided by the executor alone — each was reported to the coordinator/operator with evidence before being resolved.

### Deviation 1 — `swaync-style.css`'s contract.json format tag: `gtk-css-motion`, not `gtk-css`

**Plan said:** register `swaync-style.css` under contract.json's existing `gtk-css` format, "reusing the existing format strings rather than inventing new ones."

**What I found:** `gtk-css`'s extractor (`grep -oP '@define-color \K\S+'`) returns **zero** matches on the real compiled sheet — correct, since D-03 keeps colour a live `@import`, never a declaration. Registering it that way would make `theme-parity`'s Layer 2 empty-reference-set guard fail on **every** render dir, because the guard explicitly refuses a vacuous empty-vs-empty comparison. I tried the one other plausible candidate too (`css-literal`, whose name-extractor found 94 real selector+property pairs) and ran the **real** `theme-parity` against it: Layer 3 failed outright (`[FAIL] catppuccin: swaync-style.css value extraction succeeded`), because `css-literal`'s value-extractor looks for hex/rgba colour tokens, of which this file — by design — has none.

**How I proved it:** ran the actual `theme-parity` script (not a manual re-derivation) against each candidate registration in turn, captured the exact failure lines, and only then concluded neither existing tag survives contact with the real checker.

**What I chose:** a new `gtk-css-motion` format tag in `contract.sh`, whose name/value surrogate is the set of `cubic-bezier(...)` values found inside `transition:`/`animation:` declarations (same selector-tracking shape as `css-literal`'s structural stand-in, filtered to declarations that carry a `cubic-bezier(...)`) plus a synthetic `@import` name/value pair confirming the colour import line is present. Non-vacuous (7 real name/value pairs today: 6 transitions + 1 import), theme-independent (satisfies D-35's byte-identity premise, proven — see Layer 4 output below), additive-only (touches no existing format's behaviour). This is the same pattern this pipeline has used three times before when an existing tag didn't fit new content (`css-vars` for `:root` custom properties, `hypr-motion` for the bezier+`$var` union, `scss-vars` for `ags.scss`'s `$name:` declarations).

**Verified:** `theme-parity` Layer 1-4 all pass for `swaync-style.css` under `gtk-css-motion` across all 22 render dirs; the D-31 byte-identity check was proven able to fail via a real poisoned-fixture run (see the theme-parity commit's dynamic-scoping note below for why the poison hook is keyed off an env var rather than `$name`) before being trusted to pass.

**Committed in:** `3f4e567`

### Deviation 2 — `scss-vars` extractor hyphen fix (a pre-existing false-pass, found by this plan's own file)

**What I found:** `_motion.scss`, registered under the plan's own specified `scss-vars` tag, ALSO returned zero names from the real `theme-parity` run. Root cause: `scss-vars`'s existing regex (`[A-Za-z_][A-Za-z0-9_]*`, in both `contract_extract_names` and `contract_extract_values`) has no hyphen in its character class. `ags.scss` — the format's only prior consumer — exclusively uses underscored names (`$primary_container`), so this never surfaced. `_motion.scss`'s tokens are legitimately hyphenated (`$motion-duration-standard`, matching this repo's semantic token naming convention throughout), so **every single variable in the file was invisible to the extractor** — a silent, total false-pass-in-reverse (would have shown as a real FAIL on every render, not a silent pass, but for the wrong reason: "file has no variables" rather than "hyphenated variables aren't recognized").

**Why this is the same bug class WR-05 already named once:** this file's own comment on the `hypr-vars` extractor reads: *"allow digits after the first character ($color4, $surface2) — a digit-bearing variable silently vanishing from BOTH name and value extraction is a false-pass generator."* The exact same shape, one character class over.

**What I chose:** widened `scss-vars`'s character class in both `contract_extract_names` and `contract_extract_values` to `[A-Za-z_][A-Za-z0-9_-]*`.

**Verified, both directions:** `_motion.scss`'s hyphenated names now extract correctly (confirmed with the real regex against the real rendered file); `ags.scss`'s underscore-only names are unaffected (confirmed byte-identical extraction before/after — the widened class is a strict superset for every existing consumer).

**Committed in:** `3f4e567`

### Deviation 3 — D-Bus service-activation race: a real regression this plan introduced, found and fixed within it

**What I found while verifying Task 3's own acceptance criteria** (`pgrep -af swaync` after a restart should show the resolved compiled-sheet path): swaync ships as a D-Bus-**activatable** systemd user service (`org.freedesktop.Notifications`, `/usr/lib/systemd/user/swaync.service`). Repeatably, with full process-death confirmation between attempts (ruling out a simple timing coincidence):

```
$ pkill -x swaync; <wait for full exit, confirmed via pgrep loop>
$ ./swaync-launch.sh &        # exec swaync -s ~/.local/state/theme/swaync-style.css
$ cat /proc/$(pgrep -x swaync)/cmdline
/usr/bin/swaync                # NO -s flag — this is NOT my process
$ systemctl --user status swaync.service
Active: active (running) ... Loading CSS: "/etc/xdg/swaync/style.css"   ← system stock, unstyled
```

Something triggers D-Bus activation of `org.freedesktop.Notifications` in the brief window between my process starting and it registering the bus name; systemd's own unit wins the race and spawns a bare, argument-less `swaync`, which falls back to the system stock stylesheet — my explicitly-launched process loses ("An instance of SwayNotificationCenter is already running!") and exits.

**Why this is a regression THIS PLAN introduced, not a pre-existing bug:** the race has always existed structurally, but was invisible before this plan — the old `exec-once = uwsm app -- swaync` (no `-s` flag) and the D-Bus-activated fallback both resolved to the **same** file, since swaync's own convention auto-discovers `~/.config/swaync/style.css`, which existed at that path before this plan's conversion. Making colour+motion require an **explicit** `-s <compiled-path>` is what turns a previously-benign race into an observable failure: the two racers now resolve to **different** files.

**Fix chosen (operator decision, not mine):** a stowed systemd drop-in (`swaync.service.d/override.conf`) overriding `ExecStart` to add the `-s` flag, rather than masking `swaync.service` outright. Rationale: masking makes Hyprland's `exec-once` the *only* possible way swaync can ever start — if it fails, there is no notification daemon and no recovery path. The drop-in makes **both** racers correct instead of eliminating one, so D-Bus activation survives as a working, themed safety net.

**Verified to the same standard as the regression itself** — deliberately letting the racer that beat me originally win, not just checking config:
```
$ systemctl --user show swaync.service -p DropInPaths -p ExecStart
DropInPaths=/home/aorus/.config/systemd/user/swaync.service.d/override.conf
ExecStart={ ... argv[]=/usr/bin/swaync -s /home/aorus/.local/state/theme/swaync-style.css ... }
$ pkill -x swaync; systemctl --user start swaync.service   # deliberately trigger the D-Bus/systemd path
$ cat /proc/$(pgrep -x swaync)/cmdline
/usr/bin/swaync -s /home/aorus/.local/state/theme/swaync-style.css   ← now correct
```
Also confirmed: the Hyprland `exec-once` path (`swaync-launch.sh`) still works standalone with no conflict (exactly one process, correctly styled); `stow -n`/`--restow` stays clean and doesn't disturb pre-existing real content under `~/.config/systemd/user/` (`default.target.wants`, `pipewire.service.wants`, etc.); `swaync.service` is confirmed unmasked (`systemctl --user is-enabled` → `disabled`, not masked — no `/dev/null` symlink).

**Committed in:** `3f4e567`

### Deviation 4 (durable finding, not a code fix in itself) — systemd 261 silently ignores a symlinked drop-in directory

**What happened:** my first attempt at Deviation 3's fix — stowing `swaync.service.d/override.conf` through the swaync package's *normal* directory-folding behaviour — did not work. `systemctl --user show swaync.service -p DropInPaths` came back **empty**, and `ExecStart` stayed unchanged, even after `daemon-reload`, even with the file content and `%h`/`ExecStart=` reset syntax verified correct.

**Root-caused by direct A/B, not assumed:**
```
# A: stow's normal fold — swaync.service.d is a SYMLINK to the repo directory
$ ls -la ~/.config/systemd/user/swaync.service.d
lrwxrwxrwx ... swaync.service.d -> ../../../dotfiles/swaync/.config/systemd/user/swaync.service.d
$ systemctl --user daemon-reload && systemctl --user show swaync.service -p DropInPaths
DropInPaths=                                              ← EMPTY, silently ignored

# B: identical content, but swaync.service.d is a REAL directory
$ rm -rf ~/.config/systemd/user/swaync.service.d
$ mkdir -p ~/.config/systemd/user/swaync.service.d
$ cp <same override.conf> ~/.config/systemd/user/swaync.service.d/override.conf
$ systemctl --user daemon-reload && systemctl --user show swaync.service -p DropInPaths
DropInPaths=/home/aorus/.config/systemd/user/swaync.service.d/override.conf   ← picked up
```
Nothing else differed between A and B — same file, same content, same path, same `daemon-reload`. The only variable was whether the `.d` directory itself was a symlink.

**Fix:** `stow.sh` now pre-creates `~/.config/systemd/user/swaync.service.d` as a real directory (same `mkdir -p`-before-stow idiom already used for `fish`'s plugin dirs, `gtk-3.0`/`gtk-4.0`, and `quickshell`). With the real directory already present, stow descends into it instead of folding it, and symlinks only `override.conf` — which systemd trusts. Verified `stow -n` plans exactly that (`LINK: .config/systemd/user/swaync.service.d/override.conf`, no directory-level fold), and re-ran the full A/B proof after the `mkdir -p` landed: `DropInPaths` populated, `ExecStart` correct, the racer that beat me originally now loads the right sheet.

**Why this is recorded as its own durable finding, not folded into Deviation 3:** this is a **generalizable repo-level gotcha**, independent of swaync specifically — the generalizable rule is: **any future stowed systemd user-service drop-in in this repo must have its parent `.d` directory pre-created as a real directory in `stow.sh`, or systemd (at least v261) silently ignores the entire drop-in with no error, no warning, and a config that looks correct on inspection.** This is a false-pass generator in the same family as Deviation 2's `scss-vars` hyphen bug: it fails silently and looks like it worked (the file exists, the content is right, `daemon-reload` succeeds with no error) until you specifically check `DropInPaths=` or watch the actual process argv. A future contributor adding a systemd drop-in to this repo without reading this SUMMARY will hit exactly this wall and may not think to check `DropInPaths=` at all.

**Committed in:** `3f4e567`

---

**Total deviations:** 4 substantial (2 contract.json/contract.sh format fixes, 1 regression-found-and-fixed, 1 durable stow/systemd finding). All were investigated empirically before being decided, and all four were reported to the coordinator/operator with reproducible evidence before resolution — none were decided by the executor alone.
**Impact on plan:** No scope creep — all four are either corrections required to make this plan's own stated deliverable actually work (Deviations 1, 3, 4) or a pre-existing bug this plan's own new file exposed (Deviation 2). `theme-engine/.config/theme-engine/lib/contract.sh` and `swaync/.config/systemd/user/swaync.service.d/override.conf` were not in the plan's original `files_modified` list; both are recorded here explicitly for that reason.

## Render Gate (Task 4, D-17) — Full Method and Findings

**Gate tally, stated plainly per the operator's instruction — only 2 of 5 checks received live visual confirmation:**

| # | Check | Result | Evidence |
|---|---|---|---|
| 3 | Colour re-apply (liveness) | **Visually confirmed by operator** ✓ | `theme-apply dracula`→`catppuccin`; swaync visibly re-coloured both times, stayed styled (no silent whole-sheet discard) |
| 5 | Compositor-delivered entrance/exit | **Visually confirmed by operator** ✓ | Notification popup appear/dismiss animation confirmed still present and unaffected by this plan (13-01's `layersIn`/`layersOut`, not this stylesheet) |
| 4 | Duration axis reaches the compiled sheet | **Mechanically proven; visual confirmation WAIVED by operator** | Compiled sheet reads `transition: all 100ms ...` at `motion-switch.sh reduced`, `all 200ms ...` at `normal` — an exact, falsifiable diff of the rendered file. The operator accepted this without watching the live trigger. |
| 1-2 | Curve-shape fidelity vs. the QML token-inspector replay | **No visual instrument exists on this surface, at any exaggeration — closed on mechanical token-identity proof** | See below |

### The 8x `lively` instrument did not rescue checks 1-2 (unlike 13-01)

Following 13-01's exact precedent (scratch-edit `motion.json`'s `lively` preset multiplier from `1.25` to `8`, apply through the real `motion-switch.sh lively` pipeline, verify every consumer shows the identical exaggerated value before trusting a human judgment), I staged checks 1-2 at 8x and verified the exaggeration reached all three consumers identically: Hyprland's `$motion_speed_standard = 16.00` (1600ms), the QML-consumed `motion.json`'s `semantic.standard.duration_ms: 1600`, and the compiled `swaync-style.css`'s `transition: all 1600ms cubic-bezier(0.2, 0, 0, 1)`.

The operator's verdict at 8x: **"CAN'T JUDGE."** The instrument that rescued 13-01's checks did not rescue this one.

### Hypothesis tested, not assumed: colour/opacity transitions have no visible curve shape

**Hypothesis (operator's, tested rather than accepted on say-so):** easing shape is perceptible in position/scale/geometry changes (a thing travelling through space — accelerate-vs-decelerate is directly visible) and largely imperceptible in colour/opacity fades, because there is no spatial reference to judge acceleration against. 13-01's checks compared window/layer *movement*; swaync's transitions are hover/toggle state changes.

**Method:** enumerated every one of the six `transition:`-carrying selectors in `swaync/style.scss` and the exact pseudo-class rule that fires each one, listing every property that actually changes:

| Selector | Firing rule | Properties changed |
|---|---|---|
| `.widget-title > button` | `:hover` | `background`, `color` |
| `.widget-volume/.widget-slider scale trough slider` | *(none authored — dead code, see below)* | — |
| `.widget-buttons-grid flowboxchild > button` | `:hover`, `.toggle:checked`, `.active` | `background`, `color` |
| `.notification` | `:hover` | `border-color` |
| `.close-button` | `:hover` | `background`, `color` |
| `.notification-action` | `:hover` | `background`, `color` |

**Result: every one is colour-only.** Zero geometric properties (`transform`, `margin`, `padding`, `border-width`, size, position) are ever paired with a `transition:` declaration anywhere in this file. There is no slider thumb, expanding body, or travelling toggle knob to stage the comparison on — the hypothesis held completely, by exhaustive enumeration, not by giving up after one failed attempt.

**Durable, generalizable finding (write it once, reuse everywhere):** *a surface whose transitions animate only colour and opacity cannot host a curve-fidelity check at any exaggeration, because there is no spatial reference against which acceleration is visible; duration remains judgeable, curve shape does not.* **13-05 owns this phase's third and last render gate (waybar).** If waybar's stylesheets also transition only colour/opacity, its executor will hit exactly this wall and should inherit this conclusion — including the enumeration method above — rather than rediscovering it through a failed 8x attempt of their own.

**Closure evidence accepted for checks 1-2 in place of a visual instrument:** the compiled sheet's `standard` token is byte-identical, control-point-for-control-point, across all three consumption paths — `transition: all 1600ms cubic-bezier(0.2, 0, 0, 1)` in the compiled sheet at the 8x scratch scale, matching Hyprland's `$motion_speed_standard = 16.00` and the QML-consumed `motion.json`'s `{duration_ms: 1600, easing: "standard", bezier: [0.2, 0, 0, 1, 1, 1]}` for the identical named token. This is mechanical, not perceptual — it proves the *number* is correct everywhere, not that a human can *see* the curve, which the enumeration above proves is impossible on this surface regardless.

### Dead-CSS find (small, but real, found by the same enumeration)

`.widget-volume/.widget-slider scale trough slider` carries a `transition: all #{m.$motion-duration-standard} #{m.$motion-easing-standard};` declaration, but **no authored pseudo-class rule in this file ever fires it** — there is no `:hover`, `:active`, or `:checked` variant defined for this selector anywhere in `swaync/style.scss`. This transition is dead code: syntactically valid, tokenized correctly, and functionally inert. Not fixed in this plan (out of scope — this predates the conversion; the original `style.css` had the identical `transition: all 0.2s ease;` on this same selector with the same absence of a firing rule, so this is not a regression this plan introduced, merely something the enumeration above happened to surface). Left as a candidate for whoever next touches this file.

### Why this closure is honest, not a rubber stamp

Per the operator's explicit instruction, this is recorded plainly rather than blurred: **this gate is materially weaker than 13-01's Hyprland gate.** 13-01 achieved direct visual confirmation on 4 of 5 checks (with one closed on revised mechanical evidence for a genuinely different reason — no compositor-owned-exit surface existed to test against). This plan's gate achieved direct visual confirmation on only 2 of 5, with one mechanically proven and visually waived, and two closed on mechanical token-identity after proving — not assuming — that no stronger evidence is obtainable on this surface. A future reader deciding whether to trust swaync's motion fidelity should know the evidence is mostly mechanical, and exactly why: the surface's own content (colour/opacity-only transitions) makes stronger evidence structurally unobtainable, not merely inconvenient to gather.

## Out-of-Scope Findings (deferred, not fixed in this plan)

Two pre-existing latent bugs were found during this plan's own testing but are **not fixed here** — both were introduced by plan 13-01, neither is exercised by any shipped 13-02 code path, and fixing them would exceed this plan's `files_modified` scope for an unrelated reason. Full reproduction evidence for both lives in `.planning/phases/13-motion-retrofit-existing-surface-sweep/deferred-items.md`:

1. **`motion-curves` missing from `contract.json`'s `engine_owned_files`** — `commit.sh`'s `rsync --delete` silently deletes the D-21 A/B curve-set toggle's state file on every `theme-apply` run. Currently benign (the soak's pinned curve-set, `md3`, happens to also be the read-default), but the toggle silently reverts to `md3` on any subsequent render after being set to `legacy` — a real defect in the soak's own measuring instrument, dormant only because of what value happens to be pinned right now.
2. **An unlocalized `read -r name` loop in `lib/motion.sh` silently clobbers `theme_engine_generate`'s `name` parameter** via bash's dynamic scoping — found while building this plan's own poisoned-fixture test for the D-31 byte-identity assertion (a first attempt keyed off `$name` silently read as empty; traced to `lib/motion.sh`'s indicator-duration emitter loop, which declares its loop variable `name` with no `local`). Currently inert (no shipped code reads `$name` after the motion-render call site), but a live landmine for the next person who adds code there.

## D-36 Latency Measurement (Task 3, item H)

Per D-36 ("measure the added cost, treat slowness as a finding, not a design input"), timed `theme_engine_generate` in isolation (5 runs each, same palette, same environment) before and after this plan's sass-compile addition, using the actual 13-01-tip and current library files rather than a `git stash` (avoids any worktree/stash side effects):

| | Before (13-01 tip, no compile step) | After (this plan, with compile step) |
|---|---|---|
| Run 1-5 | 113ms (constant across 5 runs) | 131, 157, 142, 130, 132ms |
| **Average** | **113ms** | **138ms** |

**The sass compile step adds ~25ms (~22%) per `theme_engine_generate` call.** For context, a full end-to-end `motion-switch.sh normal` (including the entire reload fan-out — `hyprctl reload`, `swaync-client -rs`, GTK reload, walker restart, etc.) currently takes ~1.7s wall-clock, dwarfing this addition; the isolated measurement above is the one that actually isolates what this plan's change cost, rather than reload-chain noise. **No recompile-only fast path was added** (D-36 explicitly rejects this — a second render path that can drift from the first is exactly the class the consolidated theme engine was built to end). This is reported as a finding, not acted on.

## Issues Encountered

Covered in full above as Deviations 1-4 and the Render Gate section — no additional issues beyond those.

## User Setup Required

None — no external service configuration required. The systemd drop-in is applied automatically by `stow.sh` on any fresh install or re-run.

## Gate Status at Close

- `theme-parity`: **2163 passed, 0 failed** (baseline 1985/0 — above baseline; the increase is the new `_motion.scss`/`swaync-style.css` coverage across all layers and render dirs)
- `motion-lint`: **41 passed, 0 checks failed** (baseline 39/0 — above baseline; swaync's `.scss` is now scanned and non-exempt, contributing 2 new PASS lines in place of one EXEMPT line)
- `theme-doctor`: **185 passed** (baseline 182/0 — above baseline on pass count), but **1 FAIL remains**: `git status --porcelain is empty`. This is **not a 13-02 regression** — `wallpapers/Pictures/Wallpapers/current.jpg` was modified by this plan's own render-gate Check 3 (`theme-apply dracula`/`catppuccin` cycling), and per WINDOWS #9 this runtime-state churn belongs to plan 13-06 (which untracks and gitignores it). Left exactly as-is, neither staged nor reverted, per explicit instruction — 13-06 is where this resolves structurally.

## Next Phase Readiness

- **The sass precompile mechanism is ready for plan 13-05** to extend to waybar's six files: `GTK3_SCSS_TARGETS` accepts new rows with zero restructuring, and the `gtk-css-motion` contract format (Deviation 1) is directly reusable for waybar's compiled sheets if they turn out to be colour-free the same way swaync's is.
- **13-05's own render gate should read this SUMMARY's curve-shape-fidelity finding first.** If waybar's stylesheets also transition only colour/opacity (worth checking directly rather than assuming), its executor should reuse the enumeration method above rather than rediscovering the same wall through a failed 8x attempt.
- **Any future stowed systemd drop-in in this repo needs the pre-create-real-directory treatment** documented in Deviation 4 — this is now a standing `stow.sh` pattern (see the `fish`/`gtk-3.0`/`gtk-4.0`/`quickshell`/`swaync.service.d` precedent block).
- **MOTION-02 and MOTION-03 remain intentionally open** in REQUIREMENTS.md — both are multi-surface/multi-plan requirements, and this plan satisfies only swaync's portion of each. 13-05's waybar conversion and its own render gate are what closes them.
- **Two out-of-scope findings are filed** in `deferred-items.md` for whoever next touches `lib/motion.sh` or `contract.json`'s `engine_owned_files` (13-05 already touches the former for `GTK3_SCSS_TARGETS`, and is a natural place to also apply the `local name` fix while in that file).
- **The D-19 soak clock continues uninterrupted** — `hyprland-motion.conf` was re-verified byte-identical to the pre-plan baseline immediately before this SUMMARY was written, after every render-affecting operation in this plan including the render gate's own scratch instrument (fully reverted).

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-27*
