---
phase: quick-260820-0ha
plan: 01
subsystem: theming
tags: [zellij, matugen, kdl, multiplexer, theme-engine, contract]

requires:
  - phase: quick-260819-vas
    provides: "tmux as the first themed terminal multiplexer — the ln -sf symlink idiom (walker/yazi/satty) and the reload.sh hook/no-hook contrast this plan extends"

provides:
  - "matugen renders zellij's ENTIRE config.kdl (keybinds, options, inline themes block) from one template — the only shape measured to live-reload a running session"
  - "output_path corrected to the state dir (D-02), symlinked into ~/.config/zellij/config.kdl by commit.sh, mirroring walker/yazi/satty"
  - "a new `kdl` contract format: one shared python3 emitter (contract_kdl_theme_pairs) driving both contract_extract_names and contract_extract_values, so the two halves cannot drift"
  - "21st contract.json entry (zellij.kdl, format kdl); theme-parity's enforce_emptiness list now treats kdl as a colour format"
  - "zellij declared in install.sh PACMAN_PKGS (official extra repo, no AUR, no plugin manager); ~/.config/zellij pre-created in stow.sh before the PACKAGES loop as a forward fold guard"
  - "reload.sh comment recording that zellij deliberately gets NO reload hook (D-05), measured not assumed"

affects: [terminal multiplexer follow-ups, any future tmux-retirement task, any future matugen contract-format addition]

actuals:
  tokens: 7214
  tasks: 3
  commits: 3

tech-stack:
  added: [zellij 0.44.3 (official extra repo)]
  patterns:
    - "whole-config-render-from-one-template, not a colour fragment, for applications with no include/source mechanism (KDL has none)"
    - "shared single emitter for a new contract format's name/value extractor pair, instead of the tmux-set/fish-set mirrored-regex idiom — structurally prevents extractor drift rather than merely warning about it"

key-files:
  created:
    - matugen/.config/matugen/templates/zellij-config.kdl
  modified:
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/lib/commit.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/theme-parity
    - install.sh
    - stow.sh
    - theme-engine/.config/theme-engine/lib/reload.sh
    - .planning/quick/260820-0ha-add-zellij-as-the-themed-multiplexer-mat/reload-probe.py

key-decisions:
  - "D-01: matugen renders the ENTIRE config.kdl from one template — only an inline theme was measured to live-reload; a separate themes/<name>.kdl does not, and KDL has no include mechanism to source a colour fragment the way fish/fzf/tmux do."
  - "D-02 (corrected from the task brief): output_path is ~/.local/state/theme/zellij.kdl, NOT ~/.config/zellij/config.kdl directly — three code-measured reasons: commit.sh promotes only $tmp$STATE_DIR/ via rsync, theme-doctor resolves every contract file as $STATE_DIR/$f, and theme-parity resolves every contract file as $tmp$STATE_DIR/$fname. A template targeting the app's config path directly would render into the throwaway tmp tree and be silently discarded, and could never carry a contract entry. commit.sh symlinks ~/.config/zellij/config.kdl to the state-dir file with ln -sf, mirroring walker/yazi/satty."
  - "D-04: a new kdl contract format shares ONE emitter (contract_kdl_theme_pairs) between contract_extract_names and contract_extract_values, rather than the tmux-set/fish-set idiom of two hand-mirrored regexes — a deliberate improvement, verified with a lockstep-invariant test on a real rendered file, not merely warned about in a comment."
  - "D-05: NO reload hook in reload.sh. zellij watches its own config file and live-reloads a running session through the symlink-plus-rsync swap commit.sh already performs — measured this session with a PTY probe against the real template and promotion mechanism (non-empty capture on every branch, old fg SGR gone, new one present, no restart)."
  - "D-06: tmux is completely untouched — its PACMAN_PKGS entry, template, contract entry, reload hook and stow pre-create all still work exactly as before."
  - "D-07: the themes block must stay MULTI-LINE, one colour per line — the collapsed single-line form is a KDL parse error, measured this session (1116-byte capture vs ~25680 for a working session)."
  - "D-08: the layout-selection option is deliberately left unset so the default layout's native powerline status bar renders — switching to the compact bar would discard the wedge look the operator chose. Powerline wedges (U+E0B0..E0B3) came free with zero separator configuration."
  - "MEASURED EXCEPTION (recorded in reload-probe.py, applied and re-verified this session): zellij 0.44.3 does NOT re-theme pane-FRAME chrome on a live config reload — the frame title line keeps its session-start colours until that pane is recreated. Everything this integration exists for (the status bar and its powerline segments) DOES re-theme correctly. Ruled out by measurement before relaxing the gate: not a colour collision (palette B doesn't contain palette A's fg), not a capture-window artifact (survives settling plus a resize-forced full repaint), not fixed by toggle-pane-frames x2 or zellij action set-dark-theme (both rc=0, stale line remains). A reload hook cannot fix this and was deliberately NOT added. The probe still fails hard on any stale colour OUTSIDE frame chrome, which is what would signal a genuinely broken reload."
  - "Task 1's render gate's hex-literal check was applied against the TEMPLATE SOURCE, not the rendered output — matugen substitutes real hex into every render, so the literal-check can only ever be meaningful against the template's own non-comment body. The doubled-brace and colour-slot-structure checks stayed against the render, per the task's own <done> text."

patterns-established:
  - "Whole-application-config-from-one-template for apps with no fragment/include mechanism (D-01) — the pattern any future zellij-shaped multiplexer integration should reuse."
  - "Single shared extractor function for name+value contract-format pairs, replacing the older mirrored-regex idiom for any NEW contract format going forward."

requirements-completed: [D-01, D-02, D-03, D-04, D-05, D-06, D-07, D-08]

coverage:
  - id: D1
    description: "matugen renders zellij's whole config.kdl (11 colour slots inside a multi-line themes block, no hardcoded literal, no doubled-brace leftover) and zellij setup --check exits 0 against it"
    requirement: "D-01"
    verification:
      - kind: other
        ref: "Task 1 automated verify: matugen json render + python3 structure/literal scan + zellij setup --check, re-run 2026-08-20"
        status: pass
    human_judgment: false
  - id: D2
    description: "A running zellij session re-themes when the symlink target is replaced via rsync (commit.sh's real promotion mechanism), with no reload hook and no restart"
    requirement: "D-05"
    verification:
      - kind: other
        ref: ".planning/quick/260820-0ha-add-zellij-as-the-themed-multiplexer-mat/reload-probe.py (PTY probe, amended to exempt the measured pane-frame-chrome limitation), re-run 2026-08-20, exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "The kdl contract format's two extractors agree on their key sets on a real rendered file, all 11 colours are well-formed, a themes-less file fails loudly, and theme-parity treats kdl as a colour format across every palette"
    requirement: "D-04"
    verification:
      - kind: other
        ref: "Task 2 automated verify (lockstep invariant + loud-failure test) + full theme-parity run: 1897/1897 passed"
        status: pass
    human_judgment: false
  - id: D4
    description: "zellij is declared in install.sh PACMAN_PKGS beneath tmux (untouched); ~/.config/zellij is pre-created in stow.sh before the PACKAGES loop and is not itself a stow package; reload.sh gained only a comment, no hook function"
    requirement: "D-03, D-06"
    verification:
      - kind: other
        ref: "Task 3 automated verify (static python3 assertion script) + bash -n on every touched shell file"
        status: pass
    human_judgment: false
  - id: D5
    description: "theme-doctor, theme-parity and colour-lint all pass with zellij.kdl as a live-rendered, live-wired contract file on the actual desktop state dir (not just a throwaway probe render)"
    verification:
      - kind: other
        ref: "theme-doctor 596/596 pass (after re-running theme-apply catppuccin to populate the live state dir), theme-parity 1897/1897 pass, colour-lint 150/150 pass — all re-run after Task 3's commit"
        status: pass
    human_judgment: false
  - id: D6
    description: "Operator confirms the look (powerline wedges render solid, colours read well) and the live re-theme in a REAL kitty window — something automation cannot judge"
    verification: []
    human_judgment: true
    rationale: "Task 4 is a blocking human-verify checkpoint by design (gate=\"blocking\"). Terminal glyph rendering and colour-role legibility require a human's eyes in a real compositor surface; this host's standing rule (screenshots crash Hyprland on this NVIDIA + dynamic-cursors setup) means the executor cannot substitute a screenshot for this judgment either. Left OPEN for the operator per the plan's explicit instruction not to attempt it."

duration: ~45min (this session's resumed portion — Task 1 verify through Task 3 commit)
completed: 2026-08-20
status: halted
---

# Quick Task 260820-0ha: Zellij as the Themed Multiplexer Summary

**matugen renders zellij's ENTIRE config.kdl (options, keybinds, and an inline multi-line themes block) from one template — the only shape measured to live-reload a running session, wired into `~/.config/zellij/config.kdl` by symlink with no reload hook.**

## Performance

- **Duration:** ~45 min (this resumed session: Task 1's verify gates through Task 3's commit)
- **Completed:** 2026-08-20
- **Tasks:** 3 of 4 (Task 4 is a blocking human-verify checkpoint, intentionally left open)
- **Files modified:** 9 across 3 commits (10 including the plan doc's own prior commit)

## Accomplishments

- A single matugen template (`zellij-config.kdl`) renders zellij's entire config — options, keybinds, and an inline `themes { rice { ... } }` block with all 11 colour slots — because KDL has no include mechanism and only an inline theme was measured to live-reload.
- Corrected the task brief's stated `output_path` (`~/.config/zellij/config.kdl`) to the state dir (`~/.local/state/theme/zellij.kdl`, D-02) with three code-measured reasons documented directly in the template header, so a future reader does not "fix" it back. `commit.sh` symlinks the app's config path to it with `ln -sf`, mirroring the walker/yazi/satty idiom.
- A new `kdl` contract format was added with ONE shared extractor function (`contract_kdl_theme_pairs`) driving both the name and value extractors — a deliberate improvement over the tmux-set/fish-set mirrored-regex idiom, verified with a real lockstep-invariant test rather than assumed.
- `contract.json` now carries 21 file entries (zellij.kdl, format kdl); `theme-parity`'s emptiness-enforcement list treats `kdl` as a colour format.
- `zellij` is declared in `install.sh`'s `PACMAN_PKGS` (official `extra` repo, no AUR, no plugin manager needed); `~/.config/zellij` is pre-created in `stow.sh` before the `PACKAGES` loop as a forward fold guard, even though no zellij stow package ships today.
- `reload.sh` gained a comment-only note beside the tmux hook recording, by measurement, why zellij needs none — it watches its own config and live-reloads itself.
- Re-ran `theme-apply catppuccin` (the currently active theme, unchanged) so the LIVE desktop state dir actually carries `zellij.kdl` and the `commit.sh` symlink wiring — `theme-doctor`'s state-manifest gate requires the live render to exist, not just a throwaway probe render, and this is what makes Task 4's checkpoint attemptable by the operator.
- tmux is completely untouched (D-06) — its package entry, template, contract entry, reload hook and stow pre-create all still work exactly as before.

## Task Commits

1. **Task 1: End-to-end themed zellij — one path, template to running session** — `60962c0` (feat)
2. **Task 2: The kdl contract format — one emitter, two extractors, 21st entry** — `b0e2579` (feat)
3. **Task 3: Reproducibility — package declaration, fold guard, and the no-hook note** — `4adb17a` (feat)

**Plan metadata:** `43f2614` (docs: plan zellij as the themed multiplexer — predates this execution session)

_Note: Task 1 was implemented in a prior session and sat uncommitted in the working tree when this session resumed; this session verified it against the (orchestrator-amended) reload-probe.py gate and committed it as the first commit above, then continued through Tasks 2 and 3._

## Files Created/Modified

- `matugen/.config/matugen/templates/zellij-config.kdl` — new; the whole zellij config, rendered from one template (D-01)
- `matugen/.config/matugen/config.toml` — `[templates.zellij]` block registered directly after `[templates.tmux]`
- `theme-engine/.config/theme-engine/lib/commit.sh` — `ln -sf` symlink wiring for `~/.config/zellij/config.kdl`, with the folded-stow-symlink guard
- `theme-engine/.config/theme-engine/contract.json` — 21st entry, `zellij.kdl` tagged `kdl`
- `theme-engine/.config/theme-engine/lib/contract.sh` — new `contract_kdl_theme_pairs` shared emitter + `kdl` branches in both extractors
- `theme-engine/.config/theme-engine/theme-parity` — `kdl` added to the `enforce_emptiness` case list
- `install.sh` — `zellij` added to `PACMAN_PKGS`, beneath the untouched `tmux` entry
- `stow.sh` — `mkdir -p ~/.config/zellij` pre-create, before the `PACKAGES` loop
- `theme-engine/.config/theme-engine/lib/reload.sh` — comment-only note beside `theme_engine_reload_tmux`; no new hook function or call
- `.planning/quick/260820-0ha-add-zellij-as-the-themed-multiplexer-mat/reload-probe.py` — amended (by the orchestrator, prior to this session) to exempt the measured zellij 0.44.3 pane-frame-chrome staleness while still failing hard on any stale colour outside frame chrome

## Decisions Made

See `key-decisions` in frontmatter (D-01 through D-08, plus the measured pane-frame exception and the render-gate hex-literal fix). All decisions were made during planning or by the orchestrator investigating the prior halt; this execution session applied them without re-litigating.

## Known Limitation (measured, not a defect)

**zellij 0.44.3 does not re-theme pane-FRAME chrome on a live config reload.** The frame title line (the box-drawing border around a pane) keeps its session-start colours until that specific pane is recreated. This does NOT affect the status bar or its powerline segments — the actual surface this integration exists for — which re-theme correctly and immediately, proven by a non-empty PTY capture on every probe run. This was measured and ruled out as a collision, capture-window artifact, or fixable-by-reload-command issue (see the `MEASURED EXCEPTION` decision above and the corresponding comment block in `reload-probe.py`). A reload hook cannot fix it and was deliberately not added — D-05 stands. The operator should expect this during Task 4's live verification and not read it as a broken integration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 1's render gate hex-literal check applied against the TEMPLATE SOURCE, not the rendered output**
- **Found during:** Resuming Task 1's verify (this session)
- **Issue:** The plan's automated gate ran its "no hardcoded colour literal" regex against the RENDERED file, which matugen always fills with real hex values — the assertion could never pass as literally written.
- **Fix:** Ran the hex-literal check against the template SOURCE file's non-comment body (where a literal would indicate an actual authoring mistake), and kept the doubled-brace + colour-slot-structure checks against the rendered output, exactly as the task's own `<done>` text intended.
- **Files modified:** none (verification-only correction, no template/code change needed — the template already had zero literals)
- **Verification:** Gate passed: "PASS render: 11 colour slots, no leftovers, no literals"
- **Committed in:** n/a (verification methodology, not a code change)

**2. [Rule 3 - Blocking] Live state dir lacked zellij.kdl, failing theme-doctor's state-manifest gate**
- **Found during:** Task 3's verify (theme-doctor)
- **Issue:** `theme-doctor` checks `[[ -f "$STATE_DIR/$f" ]]` for every contract file against the REAL desktop state dir. All prior renders in this task were into throwaway `mktemp -d` prefixes for isolated gate testing, so the live `~/.local/state/theme/zellij.kdl` never existed, and `theme-doctor` failed with `[FAIL] /home/aorus/.local/state/theme/zellij.kdl exists`.
- **Fix:** Ran `./theme-engine/.config/theme-engine/theme-apply catppuccin` — the currently active theme and mode, unchanged — which re-rendered every contract file (including the new zellij.kdl) into the live state dir and ran commit.sh's promotion + symlink wiring for real.
- **Files modified:** none tracked in git (writes only to `~/.local/state/theme/` and `~/.config/zellij/config.kdl`, both outside the repo)
- **Verification:** `theme-doctor` re-run: 596/596 pass, including `[PASS] /home/aorus/.local/state/theme/zellij.kdl exists`. `readlink -f ~/.config/zellij/config.kdl` resolves to the state-dir file; `zellij setup --check` exits 0 against it.
- **Committed in:** n/a (live desktop state, not tracked in git)

---

**Total deviations:** 2 auto-fixed (1 verification-methodology correction pre-authorized by the blocker resolution, 1 blocking live-state gap)
**Impact on plan:** Both were necessary corrections/completions for the plan's own gates to mean what they say. No scope creep — no template, contract, or reload logic changed beyond what Tasks 1–3 already specified.

## Issues Encountered

None beyond the two items above. The prior session's halt (reload-probe.py's stale-colour assertion) was already resolved by the orchestrator before this session began and was not re-litigated, per the blocker-resolution instructions.

## User Setup Required

None — no external service configuration required. zellij 0.44.3 was already installed on this host; `install.sh` now declares it for fresh-machine reproducibility.

## Next Phase Readiness

**Blocked on Task 4 — operator confirmation, not yet attempted (per explicit instruction: this is a `gate="blocking"` human-verify checkpoint).**

What's ready for the operator to verify in a real kitty window:
- `zellij` status bar colours from the active theme (currently catppuccin/dark, live in the state dir)
- Powerline wedge glyphs render solid (not tofu/boxes) — font coverage judgment call
- Splitting panes/tabs (Ctrl+p n, Ctrl+t n) to see real content in the bar
- Opening a SECOND kitty window and switching themes (Super+Shift+T or `theme-apply <name>`) while the first zellij session stays open, to confirm the live re-theme
- One light palette (catppuccin-latte) for a contrast sanity check on the role pairing
- `tmux` sanity check (D-06) — its own themed status bar should be unaffected

Judgement calls flagged in the plan for the operator's opinion: zellij's default keybinds (unmodified), the `orange` slot's role assignment (no kitty analogue), and whether `session_serialization`/`serialize_pane_viewport` (on by default) should stay on.

No other blockers. All three implementation tasks are committed, and every automated gate (theme-doctor, theme-parity, colour-lint, the live-reload PTY probe) is green against the live desktop state.

---
*Phase: quick-260820-0ha*
*Completed: 2026-08-20*
