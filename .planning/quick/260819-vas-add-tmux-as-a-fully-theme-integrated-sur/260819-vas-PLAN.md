---
phase: quick-260819-vas
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: false
requirements: [D-01, D-02, D-03, D-04, D-05]

files_modified:
  - tmux/.config/tmux/tmux.conf
  - matugen/.config/matugen/templates/tmux-colors.conf
  - matugen/.config/matugen/config.toml
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - stow.sh
  - install.sh
  - .gitignore

user_setup:
  - service: tmux-plugin-manager (AUR)
    why: "tpm is the plugin fetcher (D-02). Installing it needs sudo/an interactive password, which this plan cannot supply. Declaring it in install.sh is the deliverable; installing it on THIS host is an operator action."
    dashboard_config:
      - task: "paru -S tmux-plugin-manager   (then re-run ./stow.sh to fetch the four plugins headlessly)"
        location: "operator terminal"

estimate:
  tokens: 85000
  raw_tokens: 55000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "Launching tmux in kitty shows a status bar coloured from the active theme, with powerline arrow separators between segments (D-05)."
    - "Switching themes re-colours an ALREADY-RUNNING tmux server's status bar with no restart and no manual action."
    - "A fresh machine reproduces tmux completely from install.sh + stow.sh, with the four plugins fetched and no manual prefix + I (D-02)."
    - "On a host where tpm is NOT installed, tmux still starts, loads its config without error, and is fully themed."
    - "~/.config/tmux/plugins/ is a real host-side directory; no third-party plugin code ever lands inside the repo tree."
    - "matugen is the sole writer of every tmux colour option — no plugin can override a colour (D-03)."
  artifacts:
    - tmux/.config/tmux/tmux.conf
    - matugen/.config/matugen/templates/tmux-colors.conf
    - "~/.local/state/theme/tmux-colors.conf (rendered output, 20th contract file)"
    - "contract.json entry { name: tmux-colors.conf, format: tmux-set }"
    - "contract.sh tmux-set branch present in BOTH the name extractor and the pair extractor"
    - "reload.sh theme_engine_reload_tmux"
  key_links:
    - "tmux.conf's `source-file -q ~/.local/state/theme/tmux-colors.conf` — the ONLY path by which theme colours reach tmux. If this line is wrong, tmux silently renders its stock green bar and nothing errors."
    - "contract.sh tmux-set name/pair extractor lockstep — a name matched in one half but not the other is a silent false-pass generator (that file's own comments warn about this twice)."
    - "stow.sh's mkdir for ~/.config/tmux/plugins runs BEFORE the PACKAGES loop — after it, the mkdir follows a folded symlink and writes into the repo."
    - "The tpm `run` line sits ABOVE the themed source-file line — MEASURED: the last writer wins, so this ordering is the whole mechanism keeping plugins off colour options."
    - "`set-environment -g TMUX_PLUGIN_MANAGER_PATH` precedes the tpm run line — otherwise tpm falls back to ~/.tmux/plugins/ and the stow pre-create protects nothing."
---

<objective>
Add tmux to this repo as a first-class, fully theme-integrated surface: a stow package with a
powerline status bar, tpm from the AUR with headless plugin install, a matugen template plus a new
`tmux-set` contract format, and a reload hook so running servers re-theme live.

Purpose: tmux is the last terminal surface on this host that ignores the theme pipeline. kitty, fish,
fzf and fastfetch all re-colour on a theme switch; a tmux session sitting inside kitty renders a stock
green bar that contradicts every other surface on screen.

Output: the 20th contract file (`tmux-colors.conf`), a new `tmux-set` format handler, a `tmux` stow
package, and reproducibility wiring in `install.sh` + `stow.sh`.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

Closest precedents — read these, do not invent a new idiom:
@matugen/.config/matugen/templates/fish-colors.fish
@matugen/.config/matugen/templates/fzf-colors.conf
@theme-engine/.config/theme-engine/lib/contract.sh
@theme-engine/.config/theme-engine/lib/reload.sh
@fish/.config/fish/config.fish
@stow.sh
</context>

<measured_facts>
Everything below was measured on this host during planning. It is ground truth — do NOT re-derive it,
and do NOT let a plausible-sounding alternative override it.

M-1. **AUR `tmux-plugin-manager` 3.1.0 installs tpm to `/usr/share/tmux-plugin-manager/`.**
     Its PKGBUILD does `cp -r tpm/* "$pkgdir/usr/share/tmux-plugin-manager"` from
     `github.com/tmux-plugins/tpm` at tag `v3.1.0`. So the entry points are
     `/usr/share/tmux-plugin-manager/tpm` and `/usr/share/tmux-plugin-manager/bin/install_plugins`.
     The package's own `post_install` note tells users to add `run '/usr/share/tmux-plugin-manager/tpm'`.

M-2. **tpm 3.1.0 does NOT default to an XDG plugin path when the env var is preset.**
     `scripts/variables.sh` sets `DEFAULT_TPM_PATH="$HOME/.tmux/plugins/"`. The `tpm` script only
     calls `set_default_tpm_path` when `show-environment -g TMUX_PLUGIN_MANAGER_PATH` fails. Therefore
     tmux.conf MUST `set-environment -g TMUX_PLUGIN_MANAGER_PATH` **before** the tpm run line, or the
     stow pre-create of `~/.config/tmux/plugins` protects a directory tpm never uses.

M-3. **A `run` line in tmux.conf is ordered deterministically against later `set` lines — last writer
     wins.** Measured on tmux 3.7c with a fake plugin that rewrites `status-style`/`status-right`:
       - run line at the BOTTOM (the order tpm's docs recommend) -> `status-style` became
         `fg=red,bg=blue`; the plugin overwrote the themed value.
       - run line ABOVE the themed block -> themed values survived intact.
     This is the measured mechanism behind D-03. Ordering, not per-plugin auditing, is what keeps
     plugins off colour options.

M-4. **tmux-continuum DOES write `status-right` and `status-left` by default.** Its `continuum.tmux`
     `add_resurrect_save_interpolation()` prepends `#(.../continuum_save.sh)` to `status-right`, and
     `update_tmux_option` rewrites both. There is no option to disable it. Under M-3's ordering the
     write is discarded — which also discards continuum's auto-save trigger, so the interpolation must
     be re-added as an explicitly owned literal (see Task 2).

M-5. **`source-file -q` tolerates a missing file and accepts a `~` path.** Measured: a server started
     against a config whose `source-file -q ~/.local/state/theme/NOPE.conf` target did not exist
     returned exit 0 and applied every later line normally. This is the graceful-degradation mechanism.

M-6. **The proposed `tmux-set` extractors are lockstep-clean on a realistic rendered file.** Measured
     against a file containing `status-left`/`status-right` values full of `#[fg=...]` markup and both
     powerline codepoints: name extractor and pair extractor produced identical name sets (`diff` empty).

M-7. **`install.sh` does NOT run `stow.sh`.** Its closing message tells the operator "1. Run
     './stow.sh' to set up symlinks". So at install.sh time `~/.config/tmux/tmux.conf` does not exist —
     and tpm's `_get_user_tmux_conf` needs it to find the `@plugin` list, while `_tpm_path` fatally
     aborts ("Tmux Plugin Manager not configured in tmux.conf") without it. **The headless plugin
     install therefore belongs in `stow.sh`, after the PACKAGES loop — not in install.sh.** D-02's
     intent (no manual `prefix + I`) is fully honoured; only the file placement differs from the
     literal wording, because the wording's placement provably cannot work.

M-8. **`TMUX_TMPDIR` redirects the tmux socket directory.** Measured: with it set, the socket resolved
     to `$TMUX_TMPDIR/tmux-1000/default` and the default socket was untouched. This is how the headless
     plugin install stays isolated from the operator's live tmux server.

M-9. **The headless probe idiom is safe and works.** `tmux -L <sock> -f <conf> new-session -d`, then
     `show-options -g` / `display-message -p`, then `kill-server`. Spawns no window, touches no
     compositor surface. Verified end to end during planning.

M-10. **tmux itself is undeclared.** `grep -n tmux install.sh` returns nothing, and the repo has zero
      tmux references outside `.planning/`. tmux 3.7c is installed on this host but only by hand, so
      `tmux` must be added to `PACMAN_PKGS` or the fresh-install path has no multiplexer at all.
</measured_facts>

<hard_limits>
- NEVER spawn qml6 or any compositor surface. NEVER take screenshots. Do NOT restart quickshell.
- Verify tmux ONLY via the M-9 headless probe idiom, and ALWAYS `kill-server` afterwards.
- Use a throwaway socket name (`-L gsdtmux`). NEVER run `tmux kill-server` against the default socket —
  the operator may have a live session on it.
- Do NOT attempt to install the AUR packages. That needs sudo and is the operator's action.
- Gate hygiene: strip comment lines before any counting grep, and never use `grep -q` inside a
  `pipefail` pipeline (it can exit 141 on a match and flip the verdict by file length). Capture counts
  into a variable and compare numerically.
</hard_limits>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: tmux stow package, themed config, and reproducibility wiring</name>

  <files>
tmux/.config/tmux/tmux.conf
stow.sh
install.sh
.gitignore
  </files>

  <read_first>
stow.sh lines 54-59 (the fisher pre-create — copy this idiom in spirit and in comment style)
stow.sh lines 249-270 (the PACKAGES loop, so the mkdir lands BEFORE it)
fish/.config/fish/config.fish lines 138-150 (the guarded-source graceful-degradation idiom)
install.sh line 59 (PACMAN_PKGS) and line 311 (AUR_PKGS)
  </read_first>

  <behavior>
    - A server started against this tmux.conf with the generated colours file ABSENT exits 0 and
      applies every later config line (M-5 degradation path).
    - A server started against it with the generated colours file PRESENT reports the file's
      `status-style` value from `show-options -g`.
    - With tpm absent from the filesystem, server start still exits 0 (the run line is guarded).
    - `TMUX_PLUGIN_MANAGER_PATH` reads back as the XDG plugins path, not `~/.tmux/plugins/`.
  </behavior>

  <action>
Create the `tmux` stow package and wire it into both reproducibility scripts. This is the tracer: it
proves the whole vertical path — package present, config loads, theme file sourced, plugin manager
located — before any template or contract work exists.

**1. `tmux/.config/tmux/tmux.conf`** — author in this exact order, because the order IS the mechanism
(M-3):

  a. Behaviour/prefix/base options. Keep the prefix at the default `C-b` unless a comment justifies
     otherwise. Set `mouse on`, base-index 1, pane-base-index 1, renumber-windows on. Do NOT set any
     colour option here — colours arrive only through step (d).

  b. `set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.config/tmux/plugins/"` — MUST precede the
     run line in (c), per M-2. Comment it with the M-2 reason (tpm's own default is `~/.tmux/plugins/`
     and it only computes a default when this is unset).

  c. The four `@plugin` declarations (D-03, behaviour only, never colours) followed by the guarded tpm
     run line. tpm's plugin-list parser is a text scan requiring the plugin to be field 4 of a line
     matching `^[ \t]*set(-option)? +-g +@plugin`, so write each as
     `set -g @plugin 'tmux-plugins/tmux-sensible'` and similarly for `tmux-resurrect`,
     `tmux-continuum`, `tmux-yank`. Guard the run line on tpm's presence so a host without the AUR
     package still starts clean:
     `if-shell '[ -x /usr/share/tmux-plugin-manager/tpm ]' "run '/usr/share/tmux-plugin-manager/tpm'" ""`
     Add `set -g @resurrect-capture-pane-contents 'on'` and `set -g @continuum-restore 'on'` as
     behaviour-only plugin config.

  d. **LAST line of the file**, and comment it as load-bearing:
     `source-file -q ~/.local/state/theme/tmux-colors.conf`
     Cite M-3 in the comment: a `run` line executes in config order, so anything tpm's plugins write
     to a colour option is overwritten by this source-file. That ordering is what makes matugen the
     sole colour writer (D-03), and it is the ONLY reason no per-plugin colour audit is needed. Also
     cite M-5: `-q` is what lets a fresh install (before the first theme-apply) load without error,
     the same shape as fish/config.fish's `test -f` guard.
     Record the M-4 trade-off in this comment too: continuum's own `status-right` save-interpolation
     is discarded by this ordering, and Task 2's template re-adds it as an owned literal so auto-save
     still fires.

  Write no hexadecimal colour literal anywhere in this file. Every colour comes from the sourced file.

**2. `stow.sh`** — three edits:
  - Add `tmux` to the `PACKAGES` array (keep it alphabetical: between `thunar` and `uwsm`).
  - Add `mkdir -p "$HOME/.config/tmux/plugins"` **before** the PACKAGES loop, beside the fisher/gtk/
    quickshell pre-creates. Comment it in the same voice as its neighbours and state the specific
    consequence: this package's only shipped file is `.config/tmux/tmux.conf`, so on a fresh machine
    nothing stops stow folding `~/.config/tmux` into a single symlink back into the repo — after which
    tpm's `ensure_tpm_path_exists` creates `plugins/` INSIDE the cloned repo and clones third-party
    plugin code there, breaking the git-clean invariant theme-doctor's state-manifest gate exists to
    protect. Placement before the loop is load-bearing, not incidental.
  - **After** the PACKAGES loop, add the headless plugin install (D-02). Per M-7 this belongs here,
    not in install.sh, because install.sh never runs stow.sh and tpm needs the stowed tmux.conf to
    find both the plugin list and the plugin path. Guard on the binary's presence so a host that has
    not installed the AUR package yet is a clean skip with an informative message, never a failure.
    Isolate it from any live server using M-8: run it under a `TMUX_TMPDIR` pointing at a `mktemp -d`,
    so it can never read a stale live server's environment or disturb the operator's session; clean
    the temp dir up afterwards. Tolerate a non-zero exit (`|| true`) in the same spirit as the stow
    loop's own conflict guard — a plugin fetch failing must not abort the remaining seeds below it.

**3. `install.sh`** — two declarations:
  - `tmux` into `PACMAN_PKGS` (M-10: it is currently undeclared, so the fresh-install path has no
    multiplexer). Put it near the `kitty`/`fish` terminal entries.
  - `tmux-plugin-manager` into `AUR_PKGS` (D-02), with a comment recording the legitimacy evidence
    from this plan's threat model: the PKGBUILD builds from `github.com/tmux-plugins/tpm` at tag
    `v3.1.0`, the canonical upstream. Note in the same comment that plugin FETCHING happens later, in
    stow.sh, and why (M-7).

**4. `.gitignore`** — add `tmux/.config/tmux/plugins/` as belt-and-braces behind the stow pre-create,
following the existing `wallpapers/Pictures/Wallpapers/*/live/` entry's comment style: if the fold
guard ever regresses, cloned plugin code must still never enter git history.
  </action>

  <verify>
    <automated>
cd /home/aorus/dotfiles &&
S=gsdtmux1 &&
# (a) config loads clean with the theme file ABSENT (M-5 degradation path)
tmux -L $S -f tmux/.config/tmux/tmux.conf new-session -d -s t &&
echo "PLUGPATH=$(tmux -L $S show-environment -g TMUX_PLUGIN_MANAGER_PATH)" &&
tmux -L $S show-environment -g TMUX_PLUGIN_MANAGER_PATH | grep -F "/.config/tmux/plugins/" &&
tmux -L $S kill-server &&
# (b) zero hardcoded colour literals in tmux.conf, comment lines stripped first
N=$(grep -v '^[[:space:]]*#' tmux/.config/tmux/tmux.conf | grep -cE '#[0-9a-fA-F]{6}' || true) &&
[ "$N" -eq 0 ] &&
# (c) the theme source-file is the LAST non-comment, non-blank directive
grep -v '^[[:space:]]*#' tmux/.config/tmux/tmux.conf | grep -vE '^[[:space:]]*$' | tail -1 | grep -F 'source-file -q' &&
# (d) tpm run line appears BEFORE that source-file line (M-3 ordering)
[ "$(grep -n 'tmux-plugin-manager/tpm' tmux/.config/tmux/tmux.conf | head -1 | cut -d: -f1)" -lt \
  "$(grep -n 'source-file -q' tmux/.config/tmux/tmux.conf | tail -1 | cut -d: -f1)" ] &&
# (e) set-environment precedes the tpm run line (M-2)
[ "$(grep -n 'TMUX_PLUGIN_MANAGER_PATH' tmux/.config/tmux/tmux.conf | head -1 | cut -d: -f1)" -lt \
  "$(grep -n 'tmux-plugin-manager/tpm' tmux/.config/tmux/tmux.conf | head -1 | cut -d: -f1)" ] &&
# (f) all four plugins declared in tpm's required field-4 shape
[ "$(grep -cE '^[[:space:]]*set(-option)? +-g +@plugin' tmux/.config/tmux/tmux.conf)" -eq 4 ] &&
# (g) stow.sh pre-create precedes the PACKAGES loop
[ "$(grep -n 'config/tmux/plugins' stow.sh | head -1 | cut -d: -f1)" -lt \
  "$(grep -n 'for pkg in "\${PACKAGES\[@\]}"' stow.sh | cut -d: -f1)" ] &&
# (h) declarations landed
grep -qE '^\s+tmux$' stow.sh && grep -qE '^\s+tmux$' install.sh &&
grep -qE '^\s+tmux-plugin-manager$' install.sh &&
bash -n stow.sh && bash -n install.sh &&
echo TASK1-PASS
    </automated>
  </verify>

  <done>
`tmux/.config/tmux/tmux.conf` exists and starts a server cleanly with no theme file present;
`TMUX_PLUGIN_MANAGER_PATH` resolves to the XDG plugins path; the tpm run line is guarded and ordered
above the final `source-file -q`; tmux.conf contains no hex colour; `stow.sh` stows the package,
pre-creates the plugin dir before the loop and installs plugins headlessly afterwards; `install.sh`
declares both `tmux` and `tmux-plugin-manager`; `.gitignore` covers the plugin dir. Both scripts pass
`bash -n`.
  </done>
</task>


<task type="auto" tdd="true">
  <name>Task 2: matugen template, config.toml entry, and the new tmux-set contract format</name>

  <files>
matugen/.config/matugen/templates/tmux-colors.conf
matugen/.config/matugen/config.toml
theme-engine/.config/theme-engine/lib/contract.sh
theme-engine/.config/theme-engine/contract.json
  </files>

  <read_first>
matugen/.config/matugen/templates/fzf-colors.conf (the role-mapping header idiom, and the documented
  single non-colour literal — this plan's continuum interpolation is the same category)
matugen/.config/matugen/templates/fish-colors.fish (quoting-is-load-bearing header)
theme-engine/.config/theme-engine/lib/contract.sh: the `fish-set` branch near line 107 (name
  extractor) AND near line 351 (pair extractor) — read BOTH and the lockstep warning between them
matugen/.config/matugen/config.toml lines 63-78 (the fzf and fish blocks)
  </read_first>

  <behavior>
    - The name extractor and the pair extractor, run over the rendered file, produce byte-identical
      sorted name sets (`diff` empty). This is the lockstep property; M-6 confirms the proposed
      regexes satisfy it on a realistic file.
    - `theme-parity` passes across every shipped palette with the new file in the contract.
    - The rendered `status-left` contains U+E0B0 and `status-right` contains U+E0B2.
    - A tmux server sourcing the rendered file reports the file's own values from `show-options -g`.
  </behavior>

  <action>
**1. `matugen/.config/matugen/templates/tmux-colors.conf`** — the 20th contract file. Format is
`set -g <option> "<value>"`, one per line, values ALWAYS double-quoted.

  Quoting is load-bearing, exactly as single quotes are in `fish-colors.fish`: tmux treats an
  unquoted `#` as a comment, and every powerline segment marker starts with `#[`. Explain that in the
  header. Equally load-bearing in the other direction: never place a double-quote character INSIDE a
  value — the pair extractor's value class terminates at the first one, which would let a name match
  in the name extractor but truncate in the pair extractor. That asymmetry is the exact silent
  false-pass this file's format is designed to avoid.

  Options to emit (all colour-bearing, so all matugen-owned):
  `status-style`, `status-left`, `status-right`, `window-status-style`,
  `window-status-current-style`, `window-status-activity-style`, `pane-border-style`,
  `pane-active-border-style`, `message-style`, `message-command-style`, `mode-style`,
  plus `status-left-length` / `status-right-length` set generously enough that the powerline segments
  are never truncated (the default 10 for status-left will clip them).

  **Role assignment rule — state it in the header and follow it without exception:** a powerline
  segment is a background/foreground PAIR, so pair every background role with its matching `on_*`
  role (`primary`/`on_primary`, `surface_variant`/`on_surface_variant`, `surface`/`on_surface`). A
  bare `*_container` role is a BACKGROUND and must never land in a foreground slot on its own — that
  is the precise category error `fish-colors.fish` and the fastfetch template headers both document,
  and the pairing rule makes it structurally impossible here. Use `outline` for the inactive/receding
  elements (pane border, inactive window text) where low contrast is the intent, and `error` for the
  activity style — never a hardcoded red.

  **Powerline separators (D-05):** U+E0B0 `` (right-facing) closes a left-anchored segment; U+E0B2
  `` (left-facing) opens a right-anchored one. Emit them as literal UTF-8 characters, not escape
  sequences. The transition segment between two backgrounds sets `fg` to the OUTGOING segment's
  background and `bg` to the INCOMING one — that is what makes the arrow read as a solid wedge rather
  than an outline. kitty runs FiraCode Nerd Font, which covers both codepoints (already measured).

  Compose `status-left` as: session-name segment on `primary`, arrow, host segment on
  `surface_variant`, arrow out to `surface`. Compose `status-right` as the mirror: arrow in from
  `surface`, date segment on `surface_variant`, arrow, clock segment on `primary`.

  **The one non-colour literal (M-4), and it must be documented as such** — mirroring how
  `fzf-colors.conf`'s header calls out `FZF_COLOR_BG="-1"` as its only literal. `status-right` must
  BEGIN with a guarded continuum save-interpolation:
  `#($HOME/.config/tmux/plugins/tmux-continuum/scripts/continuum_save.sh 2>/dev/null)`
  Explain why in the header: under Task 1's ordering (M-3) our source-file is the last writer, which
  discards continuum's own injection of this interpolation — and that injection is continuum's only
  auto-save trigger, so dropping it silently disables auto-save. Re-adding it here keeps exactly ONE
  writer on `status-right` while preserving the plugin's behaviour. It emits no visible output, and
  the `2>/dev/null` keeps a pre-install host (script absent) from writing shell noise into the bar.

  Every colour value is a matugen keyword. Do not hardcode a hex anywhere in the template.

**2. `matugen/.config/matugen/config.toml`** — add a `[templates.tmux]` block alongside `[templates.fish]`,
input `~/.config/matugen/templates/tmux-colors.conf`, output `~/.local/state/theme/tmux-colors.conf`.
No `post_hook` — `lib/reload.sh` is the sole fan-out owner (D-04). Comment it in the surrounding
voice: unlike fish (read once at shell start), a running tmux server CAN be re-themed live, and Task 3
adds that hook.

**3. `theme-engine/.config/theme-engine/lib/contract.sh`** — add the `tmux-set` format to BOTH
extractors, and keep the two halves in lockstep the way `fish-set` does. Place each new branch
directly after its `fish-set` sibling.

  Name extractor branch:
    `grep -oP "^set -g \K[A-Za-z0-9_-]+(?= )" "$path" 2>/dev/null | sort -u`
  Pair extractor branch:
    `sed -nE 's/^set -g ([A-Za-z0-9_-]+) "?([^"]*)"?$/\1\t\2/p' "$path" 2>/dev/null`

  Both anchor on the identical `^set -g ` prefix and the identical name class, so neither can be
  looser than the other. Comment the branch with the reason this format had to exist at all rather
  than reusing `fish-set`: `fish-set`'s name class is `[A-Za-z0-9_]+`, and every tmux option is
  hyphenated (`status-style`, `pane-border-style`, `message-style`), so every single name would have
  vanished from extraction — the same class of silent false-pass that WR-05's digit fix and 13-02's
  scss hyphen fix each closed. Note that the value half deliberately keeps the `#[...]` markup intact,
  the same way `fish-set` keeps its `--background=` prefix: theme-parity's Layer 3 matches the colour
  tokens inside it, and stripping the markup would discard the segment structure. Also update the
  format list in `contract_format`'s header comment so it stays accurate.

**4. `theme-engine/.config/theme-engine/contract.json`** — add
`{ "name": "tmux-colors.conf", "format": "tmux-set" }` to `files`, taking it from 19 entries to 20.
No `exempt_keys`.
  </action>

  <verify>
    <automated>
cd /home/aorus/dotfiles &&
# (a) contract.json is valid and now has exactly 20 file entries with the new one present
[ "$(jq '.files | length' theme-engine/.config/theme-engine/contract.json)" -eq 20 ] &&
[ "$(jq -r '.files[] | select(.name=="tmux-colors.conf") | .format' theme-engine/.config/theme-engine/contract.json)" = "tmux-set" ] &&
# (b) the format appears in BOTH extractors — two occurrences, lockstep proof-of-presence
[ "$(grep -c '^\s*tmux-set)' theme-engine/.config/theme-engine/lib/contract.sh)" -eq 2 ] &&
bash -n theme-engine/.config/theme-engine/lib/contract.sh &&
# (c) render the template in isolation and prove the two extractors agree (the lockstep property)
T=$(mktemp -d) &&
matugen json theme-engine/.config/theme-engine/palettes/catppuccin.json \
  -c matugen/.config/matugen/config.toml -p "$T" >/dev/null 2>&1 &&
R="$T/.local/state/theme/tmux-colors.conf" && [ -s "$R" ] &&
source theme-engine/.config/theme-engine/lib/contract.sh &&
diff <(contract_extract_names tmux-colors.conf "$R") \
     <(contract_extract_values tmux-colors.conf "$R" | cut -f1 | sort -u) &&
# (d) powerline codepoints present in the RENDERED output, on the right sides
grep -F 'status-left ' "$R" | grep -qF $'' &&
grep -F 'status-right ' "$R" | grep -qF $'' &&
# (e) no unrendered template placeholder and no bare-container-in-foreground smell: every value quoted
[ "$(grep -c '{{' "$R" || true)" -eq 0 ] &&
[ "$(grep -vE '^[[:space:]]*#' "$R" | grep -vE '^[[:space:]]*$' | grep -cvE '^set -g [A-Za-z0-9_-]+ ".*"$' || true)" -eq 0 ] &&
# (f) a real tmux server accepts the rendered file and reports its values back (M-9 idiom)
S=gsdtmux2 &&
printf 'source-file -q "%s"\n' "$R" > "$T/probe.conf" &&
tmux -L $S -f "$T/probe.conf" new-session -d -s t &&
tmux -L $S show-option -gqv status-style | grep -qF 'bg=#' &&
tmux -L $S show-option -gqv status-left | grep -qF $'' &&
tmux -L $S kill-server &&
rm -rf "$T" &&
# (g) full parity across every shipped palette
theme-engine/.config/theme-engine/theme-parity &&
echo TASK2-PASS
    </automated>
  </verify>

  <done>
`tmux-colors.conf` renders from matugen with no unresolved placeholders, every line in
`set -g name "value"` shape; both powerline codepoints appear on the correct sides; the `tmux-set`
name and pair extractors return identical name sets; contract.json holds 20 entries; a live tmux
server accepts the rendered file; `theme-parity` passes across all palettes.
  </done>
</task>


<task type="auto" tdd="true">
  <name>Task 3: live-reload hook and end-to-end pipeline verification</name>

  <files>
theme-engine/.config/theme-engine/lib/reload.sh
  </files>

  <read_first>
theme-engine/.config/theme-engine/lib/reload.sh lines 1-124 (the fan-out, the headless guard, and how
  the existing hooks absorb an absent target with `2>/dev/null || true`)
  </read_first>

  <behavior>
    - With no tmux server running (the common case), the hook returns 0, prints nothing, and writes
      nothing.
    - With a server running, that server's `status-style` matches the freshly rendered file after the
      hook runs.
    - With tmux not installed at all, the hook returns 0 silently.
  </behavior>

  <action>
Add `theme_engine_reload_tmux` to `lib/reload.sh` and call it from `theme_engine_reload`'s fan-out.

Shape it like the file's existing hooks — best-effort, silent, never fatal. Three guards, in order:
`command -v tmux` (absent on a host that has not installed it yet), the socket directory's existence,
and a per-socket `[[ -S ]]` test. Iterate every socket under `${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/`
rather than only the default one, so a server on a named socket re-themes too; for each, run
`tmux -S "$sock" source-file -q` against the state-dir file, redirecting output and tolerating
non-zero. Guard the whole loop on the rendered file existing, so a run before the first successful
render is a clean no-op.

Source the GENERATED file directly, not `~/.config/tmux/tmux.conf`. Comment the reason: re-sourcing
the whole config would re-execute the tpm `run` line and re-source every plugin on every theme
switch, and sourcing only the colour file makes matugen trivially the last writer without depending
on file ordering at all.

Place the call inside `theme_engine_reload`, after the kitty signal — grouped with the other terminal
surfaces. Note in the comment that this sits after the function's headless early-return, so a
theme-apply with no graphical session skips it; that is consistent with every other hook here, and a
tmux server started later picks the colours up from its own config at start.

Also record what makes tmux different from fish in a comment: `fish-colors.fish` is read once at shell
start and existing shells are deliberately not re-themed, whereas a tmux server holds its options in
memory for the life of the server, so without this hook a long-lived session would keep stale colours
indefinitely — which is precisely why this surface earns a reload hook and fish does not.
  </action>

  <verify>
    <automated>
cd /home/aorus/dotfiles &&
bash -n theme-engine/.config/theme-engine/lib/reload.sh &&
grep -q 'theme_engine_reload_tmux' theme-engine/.config/theme-engine/lib/reload.sh &&
# hook is both defined and called
[ "$(grep -c 'theme_engine_reload_tmux' theme-engine/.config/theme-engine/lib/reload.sh)" -ge 2 ] &&
# (a) no-server case: silent, exit 0, no output
source theme-engine/.config/theme-engine/lib/reload.sh &&
OUT=$(theme_engine_reload_tmux 2>&1); RC=$? &&
[ "$RC" -eq 0 ] && [ -z "$OUT" ] &&
# (b) live-server case: start a throwaway server with deliberately wrong colours,
#     run the hook, prove it adopted the rendered file's value
theme-engine/.config/theme-engine/theme-apply "$(cat "$HOME/.local/state/theme/current-theme")" &&
R="$HOME/.local/state/theme/tmux-colors.conf" && [ -s "$R" ] &&
EXPECT=$(sed -nE 's/^set -g status-style "(.*)"$/\1/p' "$R") && [ -n "$EXPECT" ] &&
printf 'set -g status-style "fg=red,bg=red"\n' > /tmp/gsdtmux-stale.conf &&
tmux -L gsdtmux3 -f /tmp/gsdtmux-stale.conf new-session -d -s t &&
[ "$(tmux -L gsdtmux3 show-option -gqv status-style)" = "fg=red,bg=red" ] &&
tmux -L gsdtmux3 source-file -q "$R" &&
[ "$(tmux -L gsdtmux3 show-option -gqv status-style)" = "$EXPECT" ] &&
tmux -L gsdtmux3 kill-server && rm -f /tmp/gsdtmux-stale.conf &&
# (c) the full pipeline gate: the new file is now a live contract member
theme-engine/.config/theme-engine/theme-doctor &&
theme-engine/.config/theme-engine/theme-parity &&
# (d) git-clean invariant: nothing wrote plugin code into the repo
[ -z "$(git status --porcelain tmux/ | grep -v 'tmux.conf' || true)" ] &&
echo TASK3-PASS
    </automated>
  </verify>

  <done>
`theme_engine_reload_tmux` is defined and wired into the fan-out; it is a silent no-op with no server
running and with tmux absent; a running server adopts the rendered `status-style` after sourcing;
`theme-doctor` and `theme-parity` both pass with `tmux-colors.conf` as the 20th contract file; the
repo tree is clean of any plugin output.
  </done>
</task>


<task type="checkpoint:human-verify" gate="blocking">
  <name>Checkpoint: operator installs tpm and confirms the bar renders correctly</name>
  <what-built>
tmux is now a full member of the theme pipeline: a `tmux` stow package with a powerline status bar, a
matugen template rendering `~/.local/state/theme/tmux-colors.conf` as the 20th contract file, a new
`tmux-set` format in both of contract.sh's extractors, a live-reload hook for running servers, and
`install.sh`/`stow.sh` declarations so a fresh machine reproduces it with the four plugins fetched
automatically.

Everything above was verified headlessly — no window was ever opened. Two things only you can confirm:
how the bar actually LOOKS in a real kitty window, and the tpm install, which needs your password.
  </what-built>

  <how-to-verify>
1. Install tpm and fetch the plugins (this is the operator action the plan could not perform):

     paru -S tmux-plugin-manager
     cd ~/dotfiles && ./stow.sh

   `stow.sh` should report the four plugins downloading. Confirm they landed OUTSIDE the repo:

     ls ~/.config/tmux/plugins/          # expect: tmux-continuum tmux-resurrect tmux-sensible tmux-yank
     cd ~/dotfiles && git status --porcelain    # expect: clean

2. Open a kitty window and run `tmux`. Look at the bar:
   - Do the segment separators render as SOLID arrow wedges, or as blank boxes / outlines?
     (Blank boxes would mean a font fallback problem, not a colour problem.)
   - Do the colours match the rest of the desktop, or does anything read as washed out / unreadable?
   - Is the session name on the left and the date + clock on the right legible against their
     backgrounds?

3. With that tmux session still open, switch themes from your usual picker. The bar should re-colour
   in place, without you restarting tmux.

4. Confirm the plugins behave and stay out of the colours:

     tmux show-option -gqv status-style      # should match ~/.local/state/theme/tmux-colors.conf
     tmux show-option -gqv status-right      # should still be the themed powerline string

Report back anything that looks wrong — especially any segment whose text is hard to read, since the
role pairing can be adjusted per-slot in the template.
  </how-to-verify>

  <resume-signal>Type "approved", or describe what looks wrong (which segment, and whether it is a colour problem or a glyph/box problem).</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| AUR -> local build | `tmux-plugin-manager` is community-submitted; its PKGBUILD runs at build time. |
| GitHub -> `~/.config/tmux/plugins/` | tpm `git clone`s four third-party repos at stow time. |
| plugin code -> tmux config | tpm sources every plugin's `*.tmux` file **as tmux configuration**, and those scripts execute shell. |

## Package Legitimacy Audit

No RESEARCH.md exists for this quick task, so the audit is inlined here. Verified during planning by
reading the PKGBUILD and `.SRCINFO` directly from the AUR, not from a search result:

| Package | Source | Verdict |
|---------|--------|---------|
| `tmux-plugin-manager` 3.1.0 | `git+https://github.com/tmux-plugins/tpm.git#tag=v3.1.0` | **VERIFIED** — canonical upstream, pinned to a signed release tag (not a floating branch), +17 votes. Installs to `/usr/share/tmux-plugin-manager/` only. |
| `tmux-plugins/tmux-sensible`, `-resurrect`, `-continuum`, `-yank` | fetched by tpm from the `tmux-plugins` GitHub org | **VERIFIED as canonical org** — the same org that publishes tpm itself; these are the reference implementations, not lookalikes. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-vas-01 | Tampering | AUR `tmux-plugin-manager` build | medium | mitigate | Tag-pinned to `v3.1.0` at the canonical upstream (audited above). Install requires the operator's sudo — the blocking checkpoint is where a human sees the package before it lands. |
| T-vas-02 | Tampering | tpm `git clone` of four plugins | medium | accept | Unpinned clones from the canonical `tmux-plugins` org, the same trust model this repo already accepts for fisher plugins in `config.fish`. Recorded, not silently assumed. |
| T-vas-03 | Elevation of Privilege | plugin `*.tmux` scripts sourced as tmux config | medium | accept | Inherent to any tmux plugin manager; the plugins run as the user, no privilege boundary is crossed. Scope is bounded by D-03 (behaviour-only plugin set, four known repos). |
| T-vas-04 | Tampering | plugin code written into the repo tree | high | mitigate | `stow.sh` pre-creates `~/.config/tmux/plugins` as a real directory BEFORE the stow loop, defeating the dir-fold; `.gitignore` covers the path as belt-and-braces; Task 3's verify asserts `git status --porcelain tmux/` is clean. |
| T-vas-05 | Tampering | two writers on one colour option | medium | mitigate | M-3 ordering makes matugen's `source-file` the last writer unconditionally; M-4's continuum interpolation is re-added as an explicitly owned literal so exactly one writer remains. Task 1 verify (d) asserts the ordering by line number. |
| T-vas-06 | Information Disclosure | `#()` shell interpolation in `status-right` | low | mitigate | The single interpolation is a fixed absolute path to a known plugin script with `2>/dev/null`; no user input reaches it, and it emits nothing on a host where the plugin is absent. |
</threat_model>

<verification>
Whole-pipeline checks, run after all three tasks:

- `theme-engine/.config/theme-engine/theme-doctor` — passes with 20 contract files.
- `theme-engine/.config/theme-engine/theme-parity` — passes across every shipped palette.
- `bash -n` on `stow.sh`, `install.sh`, `lib/contract.sh`, `lib/reload.sh`.
- `git status --porcelain tmux/` clean apart from the tracked `tmux.conf`.
- The headless probe (M-9) confirms a real tmux server adopts the rendered values.

Note the sequencing consequence: adding `tmux-colors.conf` to `contract.json` makes `theme-doctor`
report a missing state file until a `theme-apply` renders it. Task 3's verify runs `theme-apply`
against the CURRENT theme for exactly this reason. That is safe under this plan's hard limits — the
reload fan-out touches hyprctl, kitty, GTK, walker and Zen, and never quickshell.
</verification>

<success_criteria>
- Every `must_haves.truths` entry holds, with truths 1-3 confirmed at the operator checkpoint and
  truths 4-6 confirmed by the automated verifies.
- All five ratified decisions are implemented: full theme pipeline (D-01), AUR tpm with headless
  install (D-02), the four behaviour-only plugins (D-03), no kitty auto-attach and no shell hook
  (D-04), powerline arrow separators (D-05).
- `contract.json` holds 20 file entries; `tmux-set` exists in both contract.sh extractors and they
  agree on the name set.
- A theme switch re-colours a running tmux server with no restart.
- Nothing in the repo tree changed except the nine files listed in `files_modified`.
</success_criteria>

<output>
Create `.planning/quick/260819-vas-add-tmux-as-a-fully-theme-integrated-sur/260819-vas-SUMMARY.md` when done.

Record in the summary: the M-7 placement correction (headless plugin install lives in `stow.sh`, not
`install.sh`, because install.sh never runs stow.sh) and the M-3/M-4 ordering finding (a tmux `run`
line is last-writer-wins, and tmux-continuum writes `status-right` by default). Both are non-obvious,
were measured rather than reasoned, and would be re-derived expensively by anyone touching this
surface later.
</output>
