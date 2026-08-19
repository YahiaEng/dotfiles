---
phase: quick-260819-vas
plan: 01
subsystem: theme-engine
tags: [tmux, matugen, theme-engine, contract, powerline, stow, tpm]
status: complete
dependency-graph:
  requires: []
  provides:
    - "tmux stow package (tmux/.config/tmux/tmux.conf) with a themed, powerline status bar"
    - "matugen tmux-colors.conf template — the 20th contract file"
    - "tmux-set contract format in both of contract.sh's extractors"
    - "theme_engine_reload_tmux live-reload hook (re-themes running tmux servers)"
    - "install.sh/stow.sh reproducibility wiring (tmux, tmux-plugin-manager, headless plugin fetch)"
  affects:
    - "theme-engine/.config/theme-engine/contract.json"
    - "theme-engine/.config/theme-engine/lib/contract.sh"
    - "theme-engine/.config/theme-engine/lib/reload.sh"
    - "matugen/.config/matugen/config.toml"
tech-stack:
  added:
    - "tmux (PACMAN_PKGS)"
    - "tmux-plugin-manager (AUR_PKGS, tpm 3.1.0 from tmux-plugins/tpm tag v3.1.0)"
    - "tmux-sensible, tmux-resurrect, tmux-continuum, tmux-yank (behaviour-only plugins, fetched headlessly by stow.sh via tpm)"
  patterns:
    - "Last-writer-wins ordering as the sole colour-authority mechanism: a tmux.conf run line is ordered against later set lines, so placing the themed source-file LAST makes matugen the unconditional last writer with zero per-plugin colour auditing (M-3)."
    - "New contract format (tmux-set) added in lockstep to both contract.sh extractors, mirroring fish-set but with a hyphen-widened name class, since every tmux option name is hyphenated and fish-set's underscore-only class would have silently dropped every one of them."
    - "Headless plugin fetch placed in stow.sh (not install.sh), because install.sh never runs stow.sh and tpm requires the already-stowed tmux.conf to find its @plugin list and TMUX_PLUGIN_MANAGER_PATH (M-7)."
key-files:
  created:
    - "tmux/.config/tmux/tmux.conf"
    - "matugen/.config/matugen/templates/tmux-colors.conf"
    - ".planning/quick/260819-vas-add-tmux-as-a-fully-theme-integrated-sur/260819-vas-SUMMARY.md"
  modified:
    - "stow.sh"
    - "install.sh"
    - ".gitignore"
    - "matugen/.config/matugen/config.toml"
    - "theme-engine/.config/theme-engine/contract.json"
    - "theme-engine/.config/theme-engine/lib/contract.sh"
    - "theme-engine/.config/theme-engine/lib/reload.sh"
decisions:
  - "M-7 placement correction (already reviewed/accepted in the plan): the headless tpm plugin install lives in stow.sh, after the PACKAGES loop — not in install.sh — because install.sh never runs stow.sh, so at install.sh time ~/.config/tmux/tmux.conf does not exist yet and tpm's own _get_user_tmux_conf/_tpm_path need that stowed file to find the plugin list."
  - "M-3/M-4 ordering finding (measured, not reasoned): a tmux.conf `run` line executes in config order, so a later `set` always wins over anything the plugin wrote — this is the entire mechanism keeping matugen the sole colour writer (D-03), no per-plugin colour audit needed. tmux-continuum writes its own status-right save-interpolation on every load by default; that write is silently discarded by this ordering, so the matugen template re-adds the identical interpolation as an explicitly matugen-owned literal to preserve continuum's auto-save trigger while keeping exactly one writer on status-right."
  - "No self-referential 'tmux-plugins/tpm' @plugin declaration in tmux.conf: tpm itself arrives via the AUR tmux-plugin-manager package (M-1, installed to /usr/share/tmux-plugin-manager/), not via its own git-clone bootstrap, so only the four behaviour plugins (D-03) are declared."
metrics:
  duration: "~50 min"
  completed: "2026-08-19"
actuals:
  tokens: 6200
  tasks: 3
  commits: 3
---

# Quick Task 260819-vas: tmux as a fully theme-integrated surface Summary

Added tmux as the repo's 20th theme-integrated surface — a stow package with a powerline
status bar, tpm from the AUR with headless plugin install, a new `tmux-set` matugen contract
format, and a live-reload hook — with Tasks 1-3 executed and verified headlessly; Task 4 (the
plan's blocking human-verify checkpoint) is intentionally NOT attempted and remains open,
awaiting the operator to install tpm and confirm the bar's visual appearance in a real kitty
window.

## Performance

- **Duration:** ~50 min
- **Tasks:** 3/4 (Tasks 1-3 complete; Task 4 blocking checkpoint awaiting operator)
- **Files changed:** 9 (4 created, 5 modified — matches `files_modified` in the plan frontmatter)
- **Commits:** 3

## Accomplishments

- **Task 1 (32112f8):** Created `tmux/.config/tmux/tmux.conf` — behaviour options, tpm plugin
  declarations (guarded `run` line via `if-shell '[ -x /usr/share/tmux-plugin-manager/tpm ]'`),
  `TMUX_PLUGIN_MANAGER_PATH` set before the run line (M-2), and the themed
  `source-file -q ~/.local/state/theme/tmux-colors.conf` as the LAST line. Wired `stow.sh`
  (package added to `PACKAGES`, `~/.config/tmux/plugins` pre-created before the PACKAGES loop,
  headless plugin fetch added after it under an isolated `TMUX_TMPDIR`) and `install.sh`
  (`tmux` in `PACMAN_PKGS`, `tmux-plugin-manager` in `AUR_PKGS`). `.gitignore` covers the
  plugins directory as belt-and-braces.
- **Task 2 (b8c04ec):** Authored `matugen/.config/matugen/templates/tmux-colors.conf`, the 20th
  contract file — a powerline status bar built entirely from role-paired Material You colours
  (primary/on_primary, surface_variant/on_surface_variant, surface/on_surface, outline, error),
  with U+E0B0/U+E0B2 arrow separators and the one documented non-colour literal (the re-added
  continuum save-interpolation, M-4). Added `[templates.tmux]` to `config.toml`, and a new
  `tmux-set` format to both of `contract.sh`'s extractors (kept in lockstep — verified via
  `diff` producing an empty result on the rendered output).
- **Task 3 (e552bcd):** Added `theme_engine_reload_tmux` to `lib/reload.sh`'s fan-out, called
  right after the kitty signal. Silent/best-effort, guarded on tmux being installed, the
  rendered file existing, and each live socket under
  `${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/`. Sources the generated colours file directly (never
  `tmux.conf`) so a theme switch never re-executes the tpm `run` line.

## Deviations from Plan

None beyond what the plan itself already flagged and pre-approved: the M-7 placement
correction (headless plugin fetch in `stow.sh`, not `install.sh`) is exactly as the plan
specified and was not re-derived or altered here.

One self-correction made mid-execution, not a plan deviation: the first draft of
`tmux-colors.conf`'s `status-left`/`status-right` values used `#[fg=...,bg=...]` style
transitions without actually embedding the literal U+E0B0/U+E0B2 glyph characters between
them — i.e., the colour transitions were present but the visible arrow glyph itself was
missing. Caught by Task 2's own automated verify (the `grep -qF` glyph checks), fixed before
committing, and re-verified against a fresh render before the commit landed. No stale/incorrect
version of the template was ever committed.

## Verification Evidence

All verification below was run via the plan's M-9 headless probe idiom
(`tmux -L <throwaway-socket> ... new-session -d`, read back via `show-option`/
`show-environment`, always followed by `kill-server`). No compositor surface was spawned, no
screenshot was taken, and quickshell was never touched or restarted.

- **Task 1 automated verify:** `TASK1-PASS` — server starts clean with the theme file absent,
  `TMUX_PLUGIN_MANAGER_PATH` resolves to the XDG plugins path, tpm run line guarded and ordered
  above the final `source-file -q`, zero hex-colour literals in `tmux.conf`, exactly 4
  `@plugin` declarations, stow.sh pre-create precedes the PACKAGES loop, both scripts pass
  `bash -n`.
- **Task 2 automated verify:** `TASK2-PASS` — `contract.json` holds 20 entries with
  `tmux-colors.conf` -> `tmux-set`; the `tmux-set` format appears exactly twice in
  `contract.sh` (lockstep proof-of-presence); rendering `catppuccin.json` through the real
  `matugen` binary produced a `tmux-colors.conf` with no unresolved `{{` placeholders, every
  non-comment line matching `set -g NAME "value"`, and both powerline glyphs present on the
  correct sides; the name/pair extractors agreed byte-for-byte (`diff` empty); a live tmux
  server accepted the rendered file and reported back its own `status-style`/`status-left`
  values; **`theme-parity` passed 1809/1809 checks across all 22 shipped palettes** with
  `tmux-colors.conf` included.
- **Task 3 automated verify:** `TASK3-PASS` — `theme_engine_reload_tmux` is a silent, exit-0
  no-op with no server running; ran a real `theme-apply gruvbox` and confirmed a throwaway
  server deliberately pinned to `fg=red,bg=red` adopted the gruvbox-rendered `status-style`
  (`bg=#282828,fg=#ebdbb2`) after the hook ran; `theme-doctor` reported the new
  `tmux-colors.conf` state file present; `theme-parity` passed again post-hook-addition;
  `git status --porcelain tmux/` was clean apart from the tracked `tmux.conf`.
- **`theme-doctor` git-clean check note (expected, not a defect):** immediately after Task 3,
  `theme-doctor`'s overall summary showed `594 passed, 1 failed` — the sole failure was
  `git status --porcelain is empty`, which is a whole-repo check, not scoped to tmux. It fails
  right now solely because this task's own `.planning/quick/260819-vas.../` directory
  (PLAN.md + this SUMMARY.md) is intentionally left uncommitted per this task's explicit
  instruction ("the orchestrator handles the docs commit"). All three code-task commits
  (32112f8, b8c04ec, e552bcd) left the repo tree otherwise clean; this check will read clean
  once the orchestrator's docs commit lands.
- A real `theme-apply` was run against the current theme (permitted and expected per this
  plan's own `<verification>` sequencing note and the host prohibitions list — it fans out to
  hyprctl/kitty/GTK/walker/Zen, never quickshell). No live tmux server existed on this host
  before or after this task; every probe used a throwaway `-L` socket, and every probe's
  `kill-server` was confirmed run (`pgrep -a tmux` returned nothing at the end).

## Known Stubs

None. Every option in `tmux-colors.conf` is matugen-driven; no hardcoded/placeholder value
ships anywhere in the delivered files.

## Task 4: Checkpoint — NOT attempted, awaiting operator

Per this task's explicit instructions, **Task 4 (`checkpoint:human-verify`, gate="blocking")
was not attempted and is not marked done.** It requires:

1. The operator to run `paru -S tmux-plugin-manager` (sudo/password — cannot be supplied here)
   and then `./stow.sh` to fetch the four plugins.
2. A real kitty window + live visual read of the bar (arrow glyphs, colour legibility,
   segment placement) — outside this task's headless-only scope.
3. A live theme switch with an open tmux session, to visually confirm live re-colouring.
4. `tmux show-option -gqv status-style` / `status-right` sanity checks against the rendered
   file.

See the plan's Task 4 `<how-to-verify>` block for the full operator script. The tmux package
is NOT stowed on this host yet (Task 1 only authored the package tree and verified it via a
`-f <path>` throwaway config, per M-9 — it never ran `stow.sh` against the live
`~/.config/tmux/` target), so `~/.config/tmux/tmux.conf` does not yet exist as a live symlink
and no plugins have been fetched onto this host.

## Self-Check: PASSED

- `tmux/.config/tmux/tmux.conf` — FOUND
- `matugen/.config/matugen/templates/tmux-colors.conf` — FOUND
- `stow.sh` contains `tmux` package entry — FOUND (`grep -qE '^\s+tmux$' stow.sh`)
- `install.sh` contains `tmux` and `tmux-plugin-manager` — FOUND
- `theme-engine/.config/theme-engine/contract.json` has 20 entries incl. `tmux-colors.conf` —
  FOUND
- `theme-engine/.config/theme-engine/lib/contract.sh` has `tmux-set` in both extractors —
  FOUND (count = 2)
- `theme-engine/.config/theme-engine/lib/reload.sh` defines and calls
  `theme_engine_reload_tmux` — FOUND (count >= 2)
- Commit 32112f8 — FOUND (`git log --oneline --all | grep 32112f8`)
- Commit b8c04ec — FOUND
- Commit e552bcd — FOUND
