# Phase 2: Static ↔ Dynamic Parity & Switch Reliability - Research

**Researched:** 2026-07-08
**Domain:** Bash-based verification/regression tooling for a matugen-driven theme pipeline (render-diffing + a live stress-test harness) on Arch + Hyprland
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-26:** Parity proof is a new dedicated rerunnable script (working name `theme-parity`) in `theme-engine/.config/theme-engine/`, alongside `theme-doctor` — not an extension of it, not a one-off diff.
- **D-27:** Snapshots are **render-only to temp dirs**: reuse the engine's render step (`lib/generate.sh`) to render themes into temp dirs and diff those. No desktop disruption, no reloads fired, safe to run anytime. It tests exactly what PIPE-04 covers — the output contract, not the reload.
- **D-28:** Depth: structure + variable names + **semantic value checks**. Both modes must produce the exact same file set; each file must contain the same set of variable/color names; AND every color slot must hold a well-formed value (valid hex/rgba, no empty slots, no literal `{{...}}` template leftovers).
- **D-29:** Coverage: **all 6 presets vs materialyou** — all 7 rendered outputs must share identical structure/variable names and pass semantic checks. Catches a broken individual palette JSON, not just a broken mode.
- **D-30:** The canonical output contract (expected state-dir files + per-file required variable/key names) lives in a **manifest file in `theme-engine/`** (e.g. `contract.json` or sourced shell list — exact format Claude's discretion). `theme-parity` validates against it; `theme-doctor`'s existing file-list check should read the same list. Adding a future app target = one manifest update.
- **D-31:** Sequence: **alternate static ↔ dynamic** (e.g. catppuccin → materialyou → nord → materialyou → …), rotating through all 6 presets across the 10 switches, so both mode-transition directions are exercised repeatedly — that's where mode-only divergence hides.
- **D-32:** Pacing: **short fixed gap (3–5s)** between switches — enough for restart-based stragglers (Thunar daemon, walker relaunch) to settle per D-21's 1–2s window. Matches real usage; not a race-hunting rapid-fire test.
- **D-33:** Wallpaper stays **the same throughout** — materialyou iterations reuse the current wallpaper. The test isolates theme-switch reliability (PIPE-06's scope), not wallpaper-picker behavior.
- **D-34:** The script **launches and verifies its own preconditions**: opens a Thunar window, ensures walker's service + elephant are running/healthy before the first switch, and asserts both are still alive at the end. No manual setup step.
- **D-35:** Verdict model: **automated per-switch checks + human visual sign-off on the final switch.** Per-switch: theme-doctor passes, state-dir content matches the applied theme, required processes alive. After switch #10 the user visually confirms every app is correctly themed — that human check is the success-criterion bar.
- **D-36:** Per-switch content check is a **sentinel color match**: take a known color from the applied palette (e.g. accent/primary from the palette JSON or matugen output) and grep that it landed in the rendered state-dir files. Proves THIS theme rendered, not a stale previous one — directly targets drift/stale-cache failure modes.
- **D-37:** **D-15 caveat is a documented pass:** an already-open Thunar window keeping the old palette until closed is NOT a failure. The final visual check verifies a *newly opened* Thunar window has the new palette. State the caveat explicitly in VERIFICATION.md.
- **D-38:** Walker "open" semantics: per-switch the assertion is **service health** (walker gapplication service + elephant running, version-matched); **visible summon happens at human checkpoints** — the user opens Walker at the final switch (optionally mid-run) to confirm themed rendering and working results.
- **D-39:** On mid-run failure: **abort immediately with diagnostics** — dump which check failed, at which switch, theme-doctor output, and relevant file contents to a log. First failure is the most diagnosable; PIPE-06 demands 100% anyway.
- **D-40:** Divergences/bugs found by parity or stress runs are **fixed in this phase**, and fixes may freely modify Phase 1 engine code.
- **D-41:** **Clean full gate after the last fix:** final evidence must be `theme-parity` all-green AND a fresh, uninterrupted 10-switch stress run with zero failures. No stitched/resumed runs as passing evidence.
- **D-42:** Both `theme-parity` and the stress-test script are **keeper scripts stowed in `theme-engine/.config/theme-engine/`** alongside `theme-doctor` — rerunnable regression tools, reproducible on fresh installs, reused by Phase 3's fresh-VM verification (extends the D-25 precedent).
- **D-43:** Stress test is **parameterized with defaults matching PIPE-06** (10 switches, 3–5s gap, alternating sequence). A bare run reproduces the requirement gate exactly; flags allow cranking it (e.g. 50 switches) for future debugging.
- **D-44:** All three tools stay **independent commands** — `theme-doctor` remains the fast read-only invariant check; `theme-parity` renders to temp; the stress test mutates the live desktop. No umbrella flag; Phase 3 calls each explicitly.
- **D-45:** Runs produce **timestamped machine-readable logs** (pass/fail per check) under `~/.local/state/theme/` (or a `logs/` subdir there); the phase's VERIFICATION.md references/quotes the passing runs. Phase 3's VM verification parses the same log format.

### Claude's Discretion

- Exact names of the new scripts (`theme-parity` and the stress script's name) and the contract manifest's format/filename.
- Internal structure of both scripts, flag names, log format details.
- How the stress script opens/monitors the Thunar window and summons/kills walker mechanics.
- Which palette key serves as the sentinel color per theme, and which state-dir files it's grepped in.
- Whether mid-run optional human checkpoints (beyond the final one) are offered.

### Deferred Ideas (OUT OF SCOPE)

- **Rapid-fire race-hunting stress run** — a no-gap back-to-back switch test was considered and not chosen as the gate; could return as a diagnostic tool if races ever surface (noted, unowned).
- **Wallpaper-rotation during dynamic stress** — coupling wallpaper changes into the stress run was rejected for scope; wallpaper→palette behavior is covered by D-20's picker wiring.
- None other — discussion stayed within phase scope.

Also, per the phase boundary in CONTEXT.md: out of scope for this phase is repo cleanup / install.sh hardening / fresh-VM verification (Phase 3), all v2 expansion (OSD, walker menus, media widget, light themes), and live GTK3 re-theming of already-open windows (D-15 caveat stands).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PIPE-04 | Static presets and matugen dynamic themes produce an identical output contract (same canonical paths, same variable names) through one pipeline | Pattern 1 (manifest-driven per-file extraction strategy) gives the concrete, empirically-verified per-file syntax table needed to build `theme-parity`'s structure+name diffing across all 7 targets (D-27/D-28/D-29). Pattern 3 + Pitfall 4 document the exact `matugen -p` prefix path-join behavior that must be replicated for render-only snapshots to find any files at all. Pitfall 3 explains why structural (file-path) parity alone is insufficient and semantic value checks (D-28) must also run. The verified fact that all 6 palette JSONs share an identical key set, and that a live static + dynamic render both produce byte-identical file-path structure, directly de-risks this requirement's feasibility. |
| PIPE-06 | Repeated theme switching is reliable (stress test: 10 consecutive switches with Thunar/Walker open, 100% correct result) | Pattern 2 (format-normalized sentinel/semantic color validation) and Pitfall 1 are the critical finding for D-36's per-switch sentinel check — a naive literal grep silently fails to verify `hyprland.conf`'s distinct `rgba(RRGGBBAA)` format. The Architecture Diagram's stress-test flow encodes D-31/D-32/D-33/D-34/D-35/D-38/D-39's exact sequencing, precondition, and abort-on-failure requirements. The "Don't Hand-Roll" table points the stress test at Phase 1's already-hardened bounded-poll and D-Bus/elephant health-gate code (`lib/reload.sh`, `lib/gtk.sh`) instead of reimplementing process-liveness checks from scratch, directly reducing the risk of reintroducing already-fixed races. |

</phase_requirements>

## Summary

This phase does not add a new technology to the stack — it adds **verification tooling** (two new rerunnable bash scripts) that prove properties of the Phase-1 engine that already exists on disk. Everything needed to build both tools (`matugen`, `jq`, `python3` with `tomllib`, GNU `diffutils`, `hyprctl`, `busctl`) is already installed and already used by the engine. No new packages need to be installed for this phase.

The single hardest technical fact this research surfaced, empirically verified against the live system, is that **the "same color" is rendered in at least three different textual formats across the ten contract files** — `#RRGGBB` hex (gtk/waybar/kitty), `rgba(R, G, B, A)` CSS-standard comma format (a handful of hardcoded GTK shadow constants), and Hyprland's own `rgba(RRGGBBAA)` no-comma stripped-hex-plus-alpha format (hyprland.conf only, via the `$primary = rgba({{colors.primary.default.hex_stripped}}ff)` template pattern). A sentinel-color check (D-36) that does a naive literal string grep will silently pass for 9 files and silently fail to detect drift in `hyprland.conf` unless it normalizes format first. This is the single most important pitfall for the planner to build a task around.

The second key fact is that the "canonical output contract" (D-30) cannot be a flat list of variable names shared across all ten files — each file family uses a structurally different naming convention (`@define-color name value;` for the six GTK-CSS-family outputs, `$name = value` for `hyprland.conf`, bare `key value` pairs for `kitty.conf`, nested TOML tables for `yazi.toml`, nested JSON keys for `vscodium.json`, and **no named variables at all** for `walker-style.css`, which interpolates raw hex directly into CSS properties). The manifest therefore needs a per-file "extraction strategy" field, not just an expected-name list.

**Primary recommendation:** Build `theme-parity` as a manifest-driven script that (1) renders all 7 targets (6 static presets + materialyou) to temp dirs via `lib/generate.sh`, exactly as `theme-apply` does, (2) diffs the resulting file-path sets across all 7 renders for structural parity, (3) per-file, extracts variable/key names using a format-specific strategy declared in the manifest and diffs those sets across all 7 renders, and (4) per-file, validates every extracted value against a format-aware "well-formed color" regex, with an explicit allowlist for the one known-intentional blank (`$image =` in `hyprland.conf`). Build the stress-test script as a thin driver over the real `theme-apply` entrypoint with a format-normalizing sentinel-color check reused from the same manifest/extraction code as `theme-parity`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Render-only theme generation (temp-dir snapshot) | Theme engine (shell script layer) | — | Reuses `lib/generate.sh` directly; no new render logic, just a new caller with a temp target (D-27) |
| Output-contract parity diffing (structure + names + semantic values) | New CLI tool (`theme-parity`) | Theme engine (`theme-doctor` consumes same manifest) | Pure local file/text comparison — no daemon, no service, single-user CLI tool tier |
| Canonical contract definition | Static manifest file in `theme-engine/` | Consumed by `theme-parity` + `theme-doctor` | Single source of truth so adding a future app target is one edit (D-30) |
| Repeated real-switch stress driving | New CLI tool (stress script) | Theme engine (`theme-apply`, `theme-doctor`) | Drives the real entrypoint, asserts on real state-dir + process health — this is an orchestration/test-harness tier sitting above the engine, not inside it |
| Process/window health assertions (Thunar, walker, elephant) | Stress script (bash, via `hyprctl`/`pgrep`/`busctl`) | — | Same OS-process-introspection tier already used inside `lib/gtk.sh`/`lib/reload.sh`; no new tier introduced |
| Evidence logging | Stress script + `theme-parity` | `~/.local/state/theme/logs/` (state/storage tier) | Plain files under the existing state dir — no database, no new storage tier |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 5.x (system) | Both new scripts | Matches every existing engine script (`theme-apply`, `theme-doctor`, `lib/*.sh`) — same language, same conventions, no new runtime |
| matugen-bin | 4.1.0 `[VERIFIED: pacman -Q]` | Render engine both static and dynamic pass through | Already the phase-1 engine's sole render tool; `theme-parity` reuses `lib/generate.sh`'s call into it verbatim (D-27) |
| jq | 1.8.2 `[VERIFIED: jq --version]` | JSON key/value extraction for `vscodium.json` parity checks, and already used by `lib/reload.sh`/`lib/gtk.sh` for `hyprctl clients -j` parsing | Already a hard dependency of the existing engine; no new tool introduced |
| GNU diffutils | 3.12 `[VERIFIED: diff --version]` | File-tree structural diffing (`diff -rq`), sorted-key-set diffing | Standard coreutils-adjacent tool, already installed, zero-dependency |
| python3 | 3.14.6 `[VERIFIED: python3 --version]`, stdlib `tomllib` confirmed importable `[VERIFIED: python3 -c "import tomllib"]` | Parsing `yazi.toml`'s nested TOML structure for key-set extraction (no simple grep pattern covers nested tables) | Already a hard dependency of `lib/gtk.sh`'s GTK4 accent-hue mapper; `tomllib` is stdlib since 3.11, no pip install needed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| hyprctl | ships with hyprland 0.55.4 `[VERIFIED: pacman -Q hyprland]` | `hyprctl clients -j \| jq` to detect an open Thunar window | Stress script precondition/postcondition checks (D-34) — reuse the exact pattern already in `lib/gtk.sh:53-58` |
| busctl | systemd 261 `[VERIFIED: busctl --version]` | Confirm walker's D-Bus well-known name (`dev.benz.walker`) is registered, not just that a process exists | Stress script's walker service-health assertion (D-38) — reuse the exact bus-name check already in `lib/reload.sh:97-103,157-166` |
| sha256sum / md5sum | GNU coreutils (system) `[VERIFIED: command -v]` | Optional quick "did this file's content change" fingerprint, e.g. to detect a stale-cache no-op switch | Only if the planner wants a cheap whole-file identity check in addition to the per-key semantic check; not strictly required since D-36's sentinel-grep already covers "did this file actually update" |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled bash + jq + python3 tomllib manifest system | A general "config diffing" tool/library (e.g. `dyff`, `jd`) | Would add an external dependency for a problem this repo already solves with tools it has; the format heterogeneity (CSS/@define-color, shell-var, TOML, JSON, raw CSS literals) means no single generic diff tool covers all 10 files anyway — hand-rolled per-format extraction is actually less code than gluing 3 different diff tools together |
| Bash stress-test driver | A dedicated test framework (bats, shunit2) | Overkill for a single linear 10-step sequence with process-health assertions against a real desktop session; this repo has zero test-framework precedent (Phase 1 never introduced one) and Phase 2's own decisions (D-42/D-43/D-44) explicitly want a standalone, parameterized bash script, not a test-runner-wrapped suite |

**Installation:**
No new packages required — `matugen-bin`, `jq`, `python3`, `diffutils`, `hyprland` (hyprctl), `systemd` (busctl) are already installed and verified present on the target machine.

**Version verification:** All versions above were verified directly on the live target machine via `pacman -Q`/`--version` during this research session (not via registry lookup, since none of these are language-ecosystem packages requiring npm/pip/cargo verification) — see command outputs cited inline.

## Package Legitimacy Audit

**Not applicable.** This phase installs zero new external packages (no `npm install`, `pip install`, or `pacman -S` of anything not already present). Both new scripts are pure bash using tools already verified installed in Phase 1 (`jq`, `matugen-bin`) or already present on this base Arch system (`python3`, `diffutils`, `hyprctl`, `busctl`, coreutils). The Package Legitimacy Gate is skipped per its own trigger condition ("every phase that installs external packages") — none does here.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌───────────────────────────────────────────┐
                    │   theme-engine/palettes/*.json (6)         │
                    │   + live wallpaper (~/Pictures/.../current.jpg) │
                    └───────────────┬─────────────────────────────┘
                                    │ (7 render targets: 6 presets + materialyou)
                                    ▼
        ┌───────────────────────────────────────────────────────────────┐
        │  theme-parity  (NEW, render-only, never touches live desktop) │
        │                                                                │
        │  for each of 7 targets:                                       │
        │    lib/generate.sh → matugen json|image -p $(mktemp -d)       │
        │         │                                                     │
        │         ▼                                                     │
        │    rendered tree at $TMP$HOME/.local/state/theme/*            │
        │         │                                                     │
        │    ┌────┴─────────────────┬──────────────────────┐            │
        │    ▼                      ▼                      ▼            │
        │  structure diff      per-file key/name        per-file        │
        │  (file-path set      extraction, per          semantic value  │
        │  across all 7)       manifest-declared         check (regex   │
        │                      format), diffed           per declared   │
        │                      across all 7               format,       │
        │                                                 "$image"      │
        │                                                 blank-exempt) │
        └───────────────────────────┬─────────────────────────────────┘
                                    │ pass/fail per check
                                    ▼
                    logs → ~/.local/state/theme/logs/theme-parity-<ts>.log


        ┌───────────────────────────────────────────────────────────────┐
        │  stress-test script (NEW, mutates the LIVE desktop)            │
        │                                                                │
        │  precondition: open a real Thunar window; confirm walker      │
        │  service + elephant healthy (D-34)                            │
        │                                                                │
        │  loop 10x, alternating static↔dynamic, rotating 6 presets,     │
        │  3-5s gap (D-31/D-32/D-33):                                    │
        │     theme-apply <name>   ── the REAL entrypoint, same as the  │
        │       │                     picker/login caller uses          │
        │       ▼                                                       │
        │     per-switch checks:                                        │
        │       - theme-doctor passes                                   │
        │       - state-dir content == applied theme                    │
        │         (sentinel color, FORMAT-NORMALIZED across              │
        │         hex / rgba(comma) / rgba(hyprland-nocomma))            │
        │       - walker+elephant process/bus-name health                │
        │     any failure → abort immediately, dump diagnostics (D-39)  │
        │                                                                │
        │  after switch #10: human visual sign-off (D-35/D-37/D-38)      │
        └───────────────────────────┬─────────────────────────────────┘
                                    │ pass/fail per check
                                    ▼
                    logs → ~/.local/state/theme/logs/stress-<ts>.log
```

A reader can trace the primary use case: palette JSON / wallpaper in → render (temp, safe) → structural + name + value comparison (theme-parity) OR real apply + per-switch assertion (stress test) → timestamped machine-readable log → phase VERIFICATION.md quotes the passing run.

### Recommended Project Structure
```
theme-engine/.config/theme-engine/
├── theme-apply              # existing, unmodified by this phase
├── theme-doctor             # existing, refactored to read contract manifest (D-30)
├── theme-parity             # NEW — render-only structure/name/value parity checker
├── theme-stress-test        # NEW — parameterized real-switch reliability harness (naming: Claude's discretion, D-42)
├── contract.json            # NEW — canonical output contract manifest (format: Claude's discretion, D-30)
├── lib/
│   ├── generate.sh          # existing, reused as-is by theme-parity (D-27)
│   ├── commit.sh            # existing, untouched unless a stress-run bug requires a fix (D-40)
│   ├── reload.sh            # existing, untouched unless a stress-run bug requires a fix (D-40)
│   ├── gtk.sh                # existing, untouched unless a stress-run bug requires a fix (D-40)
│   └── contract.sh          # OPTIONAL — shared bash helpers for reading contract.json + per-format
│                             #   extraction/validation, sourced by both theme-parity and theme-doctor
└── palettes/*.json          # existing, unmodified
```

### Pattern 1: Manifest-driven per-file extraction strategy
**What:** `contract.json` (or equivalent) declares, per output file, both the expected filename AND which extraction strategy applies to it — because the 10 files fall into 4 genuinely different syntaxes.
**When to use:** Any time a new "Don't Hand-Roll" temptation appears to write one universal regex — resist it; the files are not homogeneous.
**Verified format inventory (empirically confirmed against live rendered output this session):**

| File | Format family | Variable syntax | Extraction approach |
|------|---------------|-----------------|----------------------|
| `waybar.css`, `swaync.css`, `wlogout.css`, `gtk-3.0-colors.css`, `gtk-4.0-colors.css` | GTK-CSS named color | `@define-color <name> <value>;` | `grep -oP '@define-color \K\S+'` |
| `hyprland.conf` | Shell-style variable | `$<name> = <value>` | `grep -oP '^\$\K[A-Za-z_]+(?= =)'` |
| `kitty.conf` | Bare key-value | `<name>  <value>` (space-separated, no `=`) | `grep -oP '^[A-Za-z0-9_]+(?=\s)'` |
| `yazi.toml` | Nested TOML tables | `key = { fg = "...", bg = "..." }` | `python3 -c "import tomllib, sys; ..."` walking the parsed dict — a line-regex will not correctly enumerate nested TOML keys |
| `vscodium.json` | Nested JSON | standard JSON | `jq -r '.. \| objects \| keys[]'` or a targeted `jq '.["workbench.colorCustomizations"] \| keys[]'` |
| `walker-style.css` | Raw CSS, **no named variables** | hex/rgba interpolated directly into property values (confirmed: `background-color: {{colors.background.default.hex}};` with no `@define-color`) | Cannot extract "variable names" — instead extract the **set of CSS selector blocks + property names** (e.g. `.box-wrapper { background-color: ...; border: ...; }`) and diff that structural set; separately validate every color-looking value is well-formed |

### Pattern 2: Format-normalized sentinel/semantic color validation
**What:** Before comparing "the same color" across two files, normalize to a canonical form (bare lowercase 6-hex-digit string) rather than doing a literal substring grep.
**When to use:** Every place D-28 (semantic value check) or D-36 (sentinel color match) reads a color out of a rendered file.
**Verified formats present in this codebase (empirically confirmed this session, same theme/rosepine, same underlying `primary` value `#ebbcba`):**
```
gtk-4.0-colors.css:  @define-color primary #ebbcba;
waybar.css:          @define-color primary #ebbcba;
kitty.conf:          color4  #ebbcba
hyprland.conf:       $primary = rgba(ebbcbaff)          ← NO leading #, NO commas, trailing alpha byte
gtk-colors.css shade constants: rgba(0, 0, 0, 0.36)      ← comma CSS format, NOT theme-driven (hardcoded, never varies)
```
**Normalization recipe (bash, no new dependency):**
```bash
# Strip to bare 6 lowercase hex digits regardless of source format.
normalize_color() {
    local raw="$1"
    raw="${raw,,}"                                  # lowercase
    raw="${raw#\#}"                                  # strip leading #
    if [[ "$raw" =~ ^rgba\(([0-9a-f]{6})[0-9a-f]{2}\)$ ]]; then
        echo "${BASH_REMATCH[1]}"                    # hyprland-style rgba(RRGGBBAA)
    elif [[ "$raw" =~ ^([0-9a-f]{6})$ ]]; then
        echo "${BASH_REMATCH[1]}"                    # bare or #-stripped hex
    else
        return 1                                     # comma rgba() or unrecognized — not a sentinel candidate
    fi
}
```
**Source:** derived and verified directly against this repo's live `~/.local/state/theme/*` output and the matugen templates in `matugen/.config/matugen/templates/` — not from external docs (Hyprland's `rgba(RRGGBBAA)` no-comma syntax is a Hyprland-specific config-value convention, confirmed by reading `hyprland-colors.conf`'s `hex_stripped` template filter and the live rendered `hyprland.conf`).

### Pattern 3: Reuse `lib/generate.sh` for render-only snapshots (D-27)
**What:** `theme-parity` must call `theme_engine_generate "$name" "$tmp"` — the exact function `theme-apply` calls — never reimplement the `matugen json`/`matugen image` invocation.
**Verified render-path fact (empirically reproduced this session):** matugen's `-p/--prefix` flag prepends the prefix to the **absolute resolved** `output_path` (after `~` expansion), so a render to `$TMP_DIR` actually lands at `$TMP_DIR$HOME/.local/state/theme/*`, not `$TMP_DIR/*`. `commit.sh` already encodes this as `rendered_dir="$tmp$STATE_DIR"` — `theme-parity` must use the identical path-join logic or its file-discovery will silently find nothing.
```bash
# Source: theme-engine/.config/theme-engine/lib/commit.sh:16-19 (existing, verified pattern)
local rendered_dir="$tmp$STATE_DIR"   # STATE_DIR="$HOME/.local/state/theme"
```

### Anti-Patterns to Avoid
- **Literal-string sentinel grep without format normalization:** Will produce false negatives on `hyprland.conf` for every theme, because its `rgba(RRGGBBAA)` format never contains the literal `#RRGGBB` or bare `RRGGBB` substring search terms would use. Always normalize both sides before comparing (Pattern 2).
- **Treating `walker-style.css`'s lack of `@define-color` names as a parity bug:** It is not a divergence from the other 9 files — it is documented, intentional (see `matugen/config.toml:60-61` comment "hardcoded CSS, no @define-color"). The manifest must model this as a distinct format, not flag it as "9 files have names, 1 doesn't → fail."
- **Flagging `$image =` (blank) in `hyprland.conf` as a broken/empty color slot:** This is a documented, intentional blank across BOTH static and dynamic modes (matugen 4.1.0 has no `colors.image` context in either render mode — confirmed in `hyprland-colors.conf` lines 25-31 and STATE.md's Phase-1 decision log). The semantic-value checker needs an explicit per-file, per-key exemption list, or it will report a permanent false-positive failure on every single run — silently defeating the whole point of D-41's "clean full gate" requirement.
- **Using `(( counter++ ))` in any new bounded-poll loop:** Documented, previously-reproduced footgun in this exact codebase (`lib/reload.sh` comment block, `01-03` fix commit). Under `set -e`, `(( counter++ ))` evaluates to the PRE-increment value; at `counter=0` this is arithmetic-false → exit status 1 → script aborts silently mid-run. Always use `counter=$((counter + 1))`.
- **Giving `theme-parity` (a report-only tool) `set -euo pipefail` the same way `theme-apply` (a mutating tool) has it:** `theme-doctor` deliberately uses `set -uo pipefail` (no `-e`) so that one failed check doesn't abort the rest of the report. `theme-parity` should follow `theme-doctor`'s precedent, not `theme-apply`'s, since it needs to run ALL checks across all 7 targets and report every failure, not stop at the first one.
- **Having the stress-test script silently swallow a failed `theme-apply` and continue to switch #10 anyway:** D-39 explicitly requires abort-on-first-failure with full diagnostics — this is the opposite of `theme-parity`'s "run everything, report all" model. The two new tools intentionally have opposite failure-handling philosophies; do not copy one script's error-handling style into the other.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Directory-tree structural diff (file set across 7 renders) | A custom recursive file-walker + set-comparison | `diff -rq <(cd dirA && find . \| sort) <(cd dirB && find . \| sort)` or plain `comm -3` on sorted `find` output | GNU diffutils already installed, zero new dependency, battle-tested |
| TOML key enumeration for `yazi.toml` | A hand-rolled TOML line-parser (regex on `key = value` lines) | `python3`'s stdlib `tomllib.load()` + a recursive key-walk | `yazi.toml` has genuinely nested tables (`[mgr]`, inline tables `{ fg = ..., bg = ... }`); a line-regex will miscount or miss nested keys. `tomllib` is stdlib (3.11+), already verified present (3.14.6), no pip install |
| JSON key enumeration for `vscodium.json` | A hand-rolled JSON scanner | `jq -r '.. \| objects \| keys[]'` (already a hard engine dependency, used in `lib/reload.sh`) | Already proven correct and already in the dependency graph |
| Bounded process-wait polling (Thunar quit, walker relaunch, elephant health) | A new sleep/poll implementation for the stress test | Copy the exact bounded-poll pattern already in `lib/reload.sh`/`lib/gtk.sh` (`while pgrep ... && (( waited < 20 )); do sleep 0.1; waited=$((waited+1)); done`) | This exact pattern was hardened over 3 rounds of Phase-1 fixes (D-Bus name-release race, elephant health gate, forced-kill fallback); reimplementing it risks reintroducing already-fixed races |
| Timestamped machine-readable pass/fail logs | A logging library or structured-log framework | Plain `printf` lines (TSV or one-JSON-object-per-line) written to `~/.local/state/theme/logs/<tool>-<timestamp>.log` | D-45 only requires "timestamped machine-readable, pass/fail per check" — a logging framework is unjustified overhead for a single-user bash tool; `walker-relaunch.log` already establishes the state-dir-hosts-logs precedent |

**Key insight:** Every "don't hand-roll" item in this phase already has a proven, in-repo precedent from Phase 1. The discipline here is reuse, not invention — the phase's whole premise (D-27, D-30, D-40) is that this tooling proves and hardens Phase 1's engine, not builds a parallel one.

## Common Pitfalls

### Pitfall 1: Format-blind sentinel matching gives false confidence
**What goes wrong:** A parity/stress check greps for a known hex string (e.g. `#ebbcba`) across all rendered files and reports 100% match, while `hyprland.conf` — rendered as `rgba(ebbcbaff)` — never actually gets checked (the grep simply never matches it, and if the check logic treats "no match found" as "not applicable" rather than "fail," the whole hyprland.conf color surface goes unverified).
**Why it happens:** `hyprland.conf`'s template uses matugen's `hex_stripped` filter wrapped in Hyprland's own no-comma `rgba(RRGGBBAA)` literal syntax — a convention unique to this one file among the ten.
**How to avoid:** Always run values through the `normalize_color()` recipe in Pattern 2 before any string comparison; never grep raw literals across heterogeneous files.
**Warning signs:** A "sentinel match" check that reports PASS for 9/10 files but silently never runs its assertion logic against `hyprland.conf` at all (as opposed to explicitly failing) is a sign the format mismatch was never handled.

### Pitfall 2: The `$image` blank field is not a defect — but a naive "no empty slots" check will flag it every time
**What goes wrong:** D-28's semantic check ("every color slot must hold a well-formed value... no empty slots") is written as a blanket rule and immediately fails on `hyprland.conf`'s `$image =` line, on every single render, in every mode, forever — because matugen 4.1.0 has no `colors.image` context to populate in either render mode (a Phase-1 finding, corrected from the original 01-RESEARCH.md assumption).
**Why it happens:** The blanket rule doesn't distinguish "matugen failed to fill this in" from "this was deliberately never templated at all" (the template literally has no `{{...}}` placeholder for `$image` — it's `$image =` with nothing after the `=`, by design, not a rendering failure).
**How to avoid:** The contract manifest needs an explicit per-file, per-key exemption for known-intentional blanks (currently exactly one: `hyprland.conf`'s `image`). Any other blank/malformed value IS a real defect and should fail.
**Warning signs:** `theme-parity` or the stress test's per-switch check reports the exact same single failure on every run regardless of which theme is applied — that's the signature of an un-exempted intentional blank, not a real regression.

### Pitfall 3: Treating "structure differs" and "semantic value differs" as the same failure class
**What goes wrong:** If a palette JSON is missing a key (say, `tertiary_container` was accidentally deleted from one palette file), the render for that theme will either fail outright (matugen errors) or silently produce a `{{...}}` literal leftover in whichever templates reference it, depending on matugen's error-handling for that specific field. A checker that only diffs file *paths* across all 7 targets (structural check) will report 100% pass — the file exists, it's just got broken content inside.
**Why it happens:** D-29 explicitly separates "structure" from "semantic value checks" for exactly this reason — a broken individual palette JSON is a content problem, not a structure problem.
**How to avoid:** Never skip the per-key extraction + semantic-value layers even when the structural (file-path) layer passes 7/7. All three D-28 layers (structure, key-name sets, value well-formedness) are independent checks; all three must run for every one of the 7 targets.
**Warning signs:** A palette-content bug (e.g. one preset's palette JSON has a typo'd key) surviving a `theme-parity` run that only reports "PASS: file structure identical across 7 renders."

### Pitfall 4: Forgetting matugen's `-p` prefix path-join behavior breaks file discovery silently
**What goes wrong:** Code that assumes rendered output lands at `$TMP_DIR/hyprland.conf` etc. (i.e. treats `$TMP_DIR` as if it were the new `STATE_DIR` directly) will find zero files and either crash or — worse — silently report "0 files found, 0 files found, therefore structurally identical" as a false PASS.
**Why it happens:** matugen resolves `~` in `output_path` to the real `$HOME` first, then prepends `-p`'s value as a filesystem prefix on top of that already-absolute path — so the true output path is `$TMP_DIR$HOME/.local/state/theme/...`, confirmed empirically this session and already documented/handled correctly in `commit.sh:16-19`.
**How to avoid:** Reuse `commit.sh`'s exact `rendered_dir="$tmp$STATE_DIR"` join logic (or import the same constant) rather than re-deriving it.
**Warning signs:** `find "$TMP_DIR" -type f` returns nothing even though `matugen` exited 0 — the files exist, just nested one level deeper than expected.

### Pitfall 5: `set -e` interacting badly with report-only comparison logic
**What goes wrong:** If `theme-parity` (which must run every check across 7 targets and report ALL failures per D-28/D-29) is written with `set -euo pipefail` like the mutating `theme-apply`, the very first failed `diff`/`grep`/`[[ ]]` test exits the whole script — reporting only "1 failure" and hiding everything else that might also be broken.
**Why it happens:** Copy-pasting the shebang/strict-mode header from `theme-apply` without considering that a report tool's failure semantics are fundamentally different from a mutating tool's.
**How to avoid:** Follow `theme-doctor`'s existing precedent exactly: `set -uo pipefail` (no `-e`), explicit `check()` helper accumulating PASS/FAIL counters, non-zero final exit only at the very end based on the accumulated FAIL count.
**Warning signs:** A `theme-parity` run that always reports exactly 1 failure regardless of how many things are actually broken.

## Code Examples

### Render-only snapshot into a temp dir (reusing the exact Phase-1 render path)
```bash
# Source: theme-engine/.config/theme-engine/lib/generate.sh (existing, D-27 mandates reuse)
source "$LIB_DIR/generate.sh"

for target in materialyou catppuccin dracula gruvbox nord rosepine tokyonight; do
    tmp="$(mktemp -d)"
    if theme_engine_generate "$target" "$tmp"; then
        rendered_dir="$tmp$HOME/.local/state/theme"   # matugen -p prefix-join behavior (Pitfall 4)
        # ...structure/name/value checks against $rendered_dir...
    fi
    rm -rf "$tmp"
done
```

### Format-specific key extraction (GTK-CSS family — 5 of the 10 files)
```bash
# @define-color <name> <value>; → just the name
grep -oP '@define-color \K\S+' "$rendered_dir/waybar.css" | sort
```

### Format-specific key extraction (hyprland.conf shell-var family)
```bash
grep -oP '^\$\K[A-Za-z_]+(?= =)' "$rendered_dir/hyprland.conf" | sort
```

### Format-specific key extraction (nested TOML — yazi.toml)
```python
# Source: python3 stdlib tomllib, verified importable on 3.14.6 this session
import tomllib, sys
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)

def walk(d, keys):
    if isinstance(d, dict):
        for k, v in d.items():
            keys.add(k)
            walk(v, keys)

keys = set()
walk(data, keys)
print("\n".join(sorted(keys)))
```

### Format-specific key extraction (nested JSON — vscodium.json)
```bash
jq -r '.. | objects | keys[]' "$rendered_dir/vscodium.json" | sort -u
```

### Sentinel color extraction + normalized comparison (D-36)
```bash
# Pull the freshly-rendered primary color regardless of source format,
# normalize to bare lowercase hex, then confirm it lands in every other
# contract file (also normalized) instead of doing a literal grep.
sentinel_hex=$(grep -oP '@define-color primary \K#[0-9a-fA-F]{6}' \
    "$STATE_DIR/gtk-4.0-colors.css" | tr -d '#' | tr 'A-F' 'a-f')

for f in waybar.css kitty.conf hyprland.conf wlogout.css swaync.css; do
    if ! grep -qi "$sentinel_hex" <(sed -E 's/rgba\(([0-9a-fA-F]{6})[0-9a-fA-F]{2}\)/\1/g; s/#//g' "$STATE_DIR/$f"); then
        echo "FAIL: $sentinel_hex not found (normalized) in $f"
    fi
done
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `theme-doctor`'s hardcoded `for f in hyprland.conf waybar.css ...` file list (Phase 1) | Both `theme-doctor` and `theme-parity` read the same `contract.json` manifest | This phase (D-30) | Adding a future app target becomes a one-line manifest edit instead of a two-place (or more) code edit — directly prevents the "fixes stop looping" failure mode this whole milestone exists to fix |
| Manual eyeballing of theme switches for correctness | Automated per-switch sentinel-color + process-health checks, with a human check reserved only for the final visual sign-off (D-35) | This phase | Converts "did it work?" from a fully subjective judgment call into a mostly-mechanical, rerunnable proof, with human judgment scoped down to exactly the one thing automation structurally cannot verify (does it *look* right) |

**Deprecated/outdated:** None — this phase does not deprecate any Phase-1 mechanism; it adds proof tooling around what already exists.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact final names `theme-parity` and a stress-test script name, plus `contract.json`'s exact filename/format, are unconstrained by CONTEXT.md — this research uses working names/suggested JSON shape as illustration, not a locked decision | Recommended Project Structure, Pattern 1 | None if the planner treats these as suggestions (per D-30/D-42's explicit "Claude's discretion") rather than fixed requirements |

**All other claims in this research were verified directly against the live system and live codebase this session** (via `pacman -Q`/`--version`, direct file reads of every template/palette/script involved, and a live matugen render reproducing both static and dynamic output structure) — no user confirmation needed beyond the naming/format discretion already explicitly delegated in CONTEXT.md.

## Open Questions

1. **Does `walker-style.css`'s structural-diff check need to compare CSS selector blocks, or is a coarser check (e.g. "same line count ± tolerance, zero `{{` leftovers, N well-formed color values") sufficient for D-28/D-29's intent?**
   - What we know: `walker-style.css` has no named variables to diff by name (Pattern 1); the file is static CSS structure with 2 interpolated hex values per the current template content read this session.
   - What's unclear: Whether the phase's "structure + variable names" bar (D-28) requires enumerating CSS selectors/properties as a stand-in for "variable names," or whether a looser content-shape check is an acceptable equivalent for this one exceptional file.
   - Recommendation: Treat it as a distinct manifest entry with `format: "css-literal"` and check (a) identical line count/selector set across all 7 renders, and (b) every interpolated value is a well-formed hex — this satisfies D-28's spirit (would catch a broken template or a missing color) without inventing a "variable name" concept that doesn't exist in this file.

2. **Should the stress test's sentinel-color check reuse `theme-parity`'s exact extraction/normalization code, or is a lighter-weight standalone check acceptable given the stress test only needs ONE sentinel per switch, not full per-file semantic validation?**
   - What we know: D-36 only requires a single sentinel-color grep per switch (much lighter than `theme-parity`'s full per-file semantic sweep); D-44 requires the three tools stay fully independent commands with no shared umbrella flag.
   - What's unclear: Whether "independent commands" (D-44) also implies "no shared library code," or whether a small shared `lib/contract.sh` (format extraction + normalization helpers) sourced by both `theme-parity` and the stress test violates that independence.
   - Recommendation: A shared `lib/contract.sh` of pure helper functions (no shared state, no umbrella entrypoint) does not violate D-44's "independent commands, no umbrella flag" intent — it only means both tools call `theme-apply`/`lib/generate.sh` and this new helper library the same way `theme-apply` already composes `lib/generate.sh`+`lib/commit.sh`+`lib/reload.sh`+`lib/gtk.sh` today. Recommend sharing the normalization function at minimum, to avoid the two tools silently drifting on what "matches" means for a color across formats (the exact Pitfall 1 risk, duplicated in two places instead of one).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| matugen-bin | Render-only snapshots (theme-parity), real switches (stress test) | ✓ | 4.1.0 `[VERIFIED]` | — |
| jq | JSON key extraction (vscodium.json), existing engine dependency | ✓ | 1.8.2 `[VERIFIED]` | — |
| python3 (stdlib tomllib) | TOML key extraction (yazi.toml) | ✓ | 3.14.6, tomllib importable `[VERIFIED]` | If ever absent: no clean fallback for nested-TOML key enumeration — flag as a blocking dependency, do not attempt a regex substitute for nested tables |
| GNU diffutils (`diff`) | Structural file-tree diffing | ✓ | 3.12 `[VERIFIED]` | `comm -3` on sorted `find` output as a coreutils-only fallback |
| hyprctl | Thunar-window-open detection (stress test precondition/check) | ✓ | ships with hyprland 0.55.4 `[VERIFIED]` | — |
| busctl | Walker D-Bus bus-name registration check (stress test) | ✓ | systemd 261 `[VERIFIED]` | Already gracefully degraded in `lib/reload.sh` via `command -v busctl` guard — same pattern applies here |
| thunar, walker, elephant, adw-gtk-theme, uwsm, notify-send | Stress-test targets and reload fan-out | ✓ | 4.20.8-3 / 2.16.2-1 / 2.21.0-1 / 6.5-1 / 0.26.6 / (coreutils-adjacent) `[VERIFIED]` | — |
| GNU Stow | Stowing the two new scripts + manifest into `theme-engine/` package | ✓ | 2.4.1 `[VERIFIED]` | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — everything required is present and verified on the target machine.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Single-user local desktop tooling, no auth surface |
| V3 Session Management | No | No session/auth tokens involved |
| V4 Access Control | No | No multi-user access boundary in scope |
| V5 Input Validation | Yes | New scripts accept a palette/theme-name argument the same way `theme-apply` does — must validate against the actual palette filenames on disk before ever interpolating into a path, exactly as `theme-apply` already does (`[[ ! -f "$PALETTES_DIR/$NAME.json" ]]` guard) |
| V6 Cryptography | No | No crypto/secrets touched by this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path/argument injection via an unvalidated theme-name argument to a new script (e.g. `theme-parity ../../etc/passwd`) | Tampering | Reuse `theme-apply`'s existing validate-against-actual-filenames pattern (`theme-engine/.config/theme-engine/theme-apply:45-58`) verbatim in both new scripts — reject unknown names before any path is built |
| Notification content injection (raw matugen/tool stderr piped straight into `notify-send`) | Tampering / Information Disclosure | Reuse `theme-apply`'s existing truncate-and-strip-control-chars pattern (`head -c 200 "$ERROR_LOG" \| tr -d '\000-\011\013\014\016-\037'`) for any new user-facing notification the stress test or theme-parity emits |
| World-readable log/state artifacts under a new `logs/` subdir leaking desktop color/theme info (low-sensitivity, but consistent with existing hardening) | Information Disclosure | The state dir is already `chmod 700` by `commit.sh`; ensure the new `logs/` subdir is created under that same 700-permission parent and inherits restrictive perms, do not `chmod` it independently to something looser |
| A stress-test bug that force-kills windows/processes beyond the intended Thunar/walker targets (e.g. an overly broad `killall`) | Denial of Service (of the user's own session) | Reuse the exact, narrowly-scoped `pgrep -x`/`killall -q` patterns already hardened in `lib/reload.sh`/`lib/gtk.sh` (bounded poll, then targeted forced-kill only of the named binary) rather than writing new process-management logic |

## Project Constraints (from CLAUDE.md)

Extracted from `/home/aorus/dotfiles/.claude/CLAUDE.md` — actionable directives this phase's plan must respect:

- **Tech stack is fixed** — Arch Linux, Hyprland, uwsm, stow, matugen. This phase extends the existing theme-engine tooling; it must not introduce a different templating engine, shell, or theming framework.
- **Theme switching must keep supporting both static preset and matugen dynamic modes through one pipeline** — directly the subject of PIPE-04/this phase; any fix must preserve, not fork, the shared pipeline.
- **Reproducibility: everything must be installable via `install.sh` + stow, no manual host-only state** — the two new scripts and the contract manifest must be added to the `theme-engine` stow package (not left as ad-hoc files outside stow), consistent with D-42.
- **Do not use `xsettingsd`** — not relevant to this phase's scope (no GTK settings-daemon work here), but noted as a permanent constraint on the theming pipeline.
- **GTK3 apps have no live CSS reload; a process restart is required after any CSS/theme-package change** — the stress test's per-switch assertions must account for this (already reflected in D-37's documented D-15 caveat) rather than treating "Thunar didn't instantly recolor while its window stayed open" as a bug.
- **Any walker-restart logic must verify `elephant` is also healthy, not just relaunch `walker`** — directly matches D-38's walker service-health assertion; the stress test must check both processes, reusing `lib/reload.sh`'s existing elephant-socket/version health gate rather than only checking `pgrep walker`.
- **GSD Workflow Enforcement:** file-changing work in the implementation phase must go through a GSD command (`/gsd-execute-phase` etc.), not direct ad-hoc edits — procedural constraint for the executing agent, not a technical one, but worth the planner noting in task framing.

None of these constraints conflict with any Standard Stack or Architecture Pattern recommended above — this research recommends only tools/patterns already inside the fixed stack and already used by the existing theme-engine.

## Sources

### Primary (HIGH confidence — direct verification on this machine, this session)
- Live reads of every file in `theme-engine/.config/theme-engine/` (theme-apply, theme-doctor, lib/generate.sh, lib/commit.sh, lib/reload.sh, lib/gtk.sh, all 6 palette JSONs)
- Live reads of `matugen/.config/matugen/config.toml` and every file in `matugen/.config/matugen/templates/`
- Live reads of `hypr/.config/hypr/scripts/{theme-switch,wallpaper-picker,theme-init}.sh`
- Live `pacman -Q`/`--version` checks: matugen-bin 4.1.0, jq 1.8.2, python3 3.14.6 (+tomllib), diffutils 3.12, hyprland 0.55.4, systemd/busctl 261, thunar 4.20.8-3, walker 2.16.2-1, elephant 2.21.0-1, adw-gtk-theme 6.5-1, uwsm 0.26.6, GNU Stow 2.4.1
- Live reproduction of a render-only `matugen json`/`matugen image` invocation to a scratch temp dir, confirming both (a) the `-p` prefix path-join behavior and (b) that static and dynamic modes produce byte-identical file-path structure
- Live diffing of all 6 palette JSONs' `colors` keys (identical key sets, confirmed via md5sum of sorted key lists)
- Live inspection of the current rendered state dir (`~/.local/state/theme/*`) confirming the three distinct color-format families across files for the same underlying color value
- `.planning/phases/01-root-cause-fix-consolidated-theme-engine/01-VERIFICATION.md` and `.planning/STATE.md` — Phase 1's verified findings this phase builds on (matugen 4.1.0's `colors.image` limitation, the `(( counter++ ))` set -e footgun, D-15's Thunar staleness caveat)

### Secondary (MEDIUM confidence)
None used — no external documentation lookups were needed; every fact required for this phase was directly verifiable against the live codebase and machine.

### Tertiary (LOW confidence)
None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every tool/version verified live on the target machine, zero new packages
- Architecture: HIGH — render path, path-join behavior, and both static/dynamic structural parity directly reproduced and verified this session
- Pitfalls: HIGH — all five pitfalls are drawn from direct empirical inspection of the live rendered files and existing engine code comments (not inferred/guessed), including the three-format color-representation finding which was independently reproduced via live grep against the current state dir

**Research date:** 2026-07-08
**Valid until:** No expiry pressure — this research is grounded in the local, version-pinned, non-networked codebase and machine state rather than external fast-moving documentation; re-verify only if `matugen-bin`, `walker`, or `elephant` are upgraded before this phase is planned/executed.
