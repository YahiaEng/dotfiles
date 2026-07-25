---
phase: 06-themed-surfaces-utility-suite
audited: 2026-07-13
asvs_level: 1
block_on: high
threats_total: 53
threats_closed: 53
threats_open: 0
threats_open_nonblocking: 0
status: SECURED
---

# Phase 06 — Themed Surfaces & Utility Suite — Security Audit

Verification of every threat declared in the `<threat_model>` blocks of `06-01-PLAN.md` … `06-19-PLAN.md`.
Register authored at plan time; this audit is verification only, not discovery.

**Register size correction:** the audit brief stated 40 threats. The authoritative count across the 19
`<threat_model>` blocks is **53** (the brief undercounted plans 06-17 … 06-19). All 53 are verified below.

## Result

All 53 threats CLOSED. 0 blocking-open, 0 non-blocking-open.
All 4 HIGH-severity threats (T-06-SC, T-06-06, T-06-16, T-06-W16) verified with direct code evidence;
two of them (T-06-W04's sibling-process bound and T-06-W16's guard) additionally verified **behaviorally**
by executing the shipped logic against a decoy/poisoned input rather than trusting the SUMMARY.

## HIGH-severity threats (block_on: high)

| ID | Category | Disposition | Status | Evidence |
|----|----------|-------------|--------|----------|
| T-06-SC | Tampering | mitigate | CLOSED | `install.sh:234-236` — the three AUR packages (`tela-icon-theme`, `colloid-icon-theme-git`, `papirus-folders`) are wired into `AUR_PKGS` and nothing else was added. Human legitimacy checkpoint executed and recorded: `06-01-SUMMARY.md` D2, `human_judgment: true`, `manual_procedural` verification `status: pass`. Backstop: `verify_packages()` (`install.sh:406-428`) hard-fails `exit 1` on any missing package; `VERIFY_PKGS` includes `AUR_PKGS` (`install.sh:446`). |
| T-06-06 | Spoofing / Denial | mitigate | CLOSED | FIX-02 hardening preserved verbatim in `hypr/.config/hypr/hyprlock.conf`: `immediate_render = true` (:20), `ignore_empty_input = true` (:21), `check_text = <i>Checking...</i>` (:184), `fail_text` (:186). The PAM/input-field auth block is untouched; Phase 06 added only label widgets. |
| T-06-16 | Information Disclosure | mitigate | CLOSED | All three legs shipped in-phase, none deferred: (a) cap — `autostart.conf:47-48`, both `cliphist store` watchers carry `-max-items 100`; (b) session-end wipe — `wlogout/.config/wlogout/layout:2,5,6`, `cliphist wipe;` prefixes the logout/shutdown/reboot actions; (c) manual wipe — `hypr/.config/hypr/scripts/clipboard-wipe.sh` exists and is bound at `keybinds.conf:48` (`$mainMod SHIFT, C`). |
| T-06-W16 | Repudiation (false assurance) | mitigate | CLOSED | Guard asserts a NON-EMPTY provider, not merely absence of exceptions: `theme-doctor:260-264` — `css = provider.to_string()` … `elif not css: print(f"FAIL\t{frag}\tprovider is EMPTY — stylesheet discarded")`. Covers 6 GTK3 + 3 GTK4 deployed sheets (`theme-doctor:194-206`). **Independently re-proven during this audit** (not taken from the SUMMARY): the shipped probe logic, run against a clean copy of `style-full.css` and a copy poisoned with the exact CR-01 `button::after { content: "x"; }` construct, returned `PASS 15347 bytes` / `FAIL — Invalid name of pseudo-class`. The guard has teeth. |

## Mitigate — verified (31 further)

| ID | Sev | Component | Evidence |
|----|-----|-----------|----------|
| T-06-01 | medium | package-name typo backstop | `install.sh:235` name-corrected to `colloid-icon-theme-git`; `verify_packages` `exit 1` on missing (`install.sh:406-428`) |
| T-06-03 | low | satty symlink write | `lib/commit.sh:114-118` folded-stow guard + idempotent `ln -sf`; `chmod 700 "$STATE_DIR"` (:90) |
| T-06-08 | medium | audio-consent before record | `record-toggle.sh:173` `pick_audio` runs **before** `select_capture_target` (:176); silent omits `-a` entirely (:185-187, `[[ -n "$AUDIO_DEVICES" ]] && audio_args=(-a …)`) |
| T-06-09 | low | subprocess stderr → notify-send | `sanitize() { head -c 200 \| tr -d '\000-\011\013\014\016-\037'; }` defined and applied at every crossing: `record-toggle.sh:45,213`, `color-picker.sh:12,30`, `gif-export.sh:21,27,36`. `capture-*.sh` notify only fixed strings. |
| T-06-10 | medium | Zen profile-path traversal | `lib/reload.sh:156-158` — `realpath -m` then `[[ "$profile_dir" != "$zen_real"/* \|\| ! -d "$profile_dir" ]]` → skip. Real-subdirectory-of-`~/.zen` check, not a blind readlink. |
| T-06-11 | medium | reload fan-out hang (headless) | `lib/reload.sh:33-36` early-return when `WAYLAND_DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` are both empty; second layer `pgrep -x swaync` + `timeout 5` (:47-48) |
| T-06-12 | medium | icon-picker path traversal | `icon-theme-picker.sh:61` real enumeration via `index.theme` scan; `:193-206` exact-match re-validation of the fzf return against the enumerated set, `exit 1` otherwise — before any gsettings/path use |
| T-06-13 | medium | icon theme reverted by theme switch | `lib/generate.sh:118-119` reads `~/.local/state/theme/icon-theme` into the rendered settings.ini; `lib/commit.sh:81` `--exclude=icon-theme` protects it from rsync `--delete` |
| T-06-14 | medium | font-picker config injection | `font-switcher.sh:59` enumerates via `fc-list : family`; `:186-198` exact-match re-validation, `exit 1` otherwise — no free text reaches settings.ini/settings.json |
| T-06-15 | low | in-place sed of stowed CSS | `lib/font.sh:40-47` renders `kitty-font.conf` / `waybar-font.css` into the state dir, consumed by an additive `include`/`@import`; no `sed -i` against tracked stylesheets |
| T-06-17 | low | wtype typing raw walker stdout | `emoji-picker.sh:222` `printf '%s\n' "$EMOJIS" \| grep -qxF "$SELECTED"` → `exit 1` if unmatched; only a recognized list entry reaches `wtype` (:229) |
| T-06-18 | low | hyprpicker stderr → notify-send | `color-picker.sh:12-14,30,34` |
| T-06-10-02 | low | fzf selection → state write | Same re-validation as T-06-12/T-06-14; wrappers do not bypass it |
| T-06-11-01 | low | slurp geometry → `-region` | `record-toggle.sh:181` `capture_args=(-w region -region "${target#region:}")` — array element, no shell re-evaluation |
| T-06-11-02 | low | capture tool missing (silent abort) | `command -v` guard → `notify-send` + `exit 1` in `capture-region.sh:44-46`, `capture-full.sh:19-21`, `capture-window.sh:16-18` |
| T-06-12-01 | low | install.sh helper indirection | `install.sh:300,304` use `"$AUR_HELPER"` (set only to `paru`/`yay` by `command -v` detection at :262-277), not a hardcoded literal |
| T-06-13-02 | low | swayosd restart hang | `lib/reload.sh:78` `pgrep -x swayosd-server` gate; bounded exit poll `(( osd_waited < 20 ))` (:85); detached `setsid uwsm app -- swayosd-server & disown` (:90-91) |
| T-06-14-02 | low | capture pipeline DoS | `command -v hyprshot satty` guards retained; `--raw` present on all three (`capture-region.sh:56`, `capture-full.sh:31`, `capture-window.sh:28`) |
| T-06-15-SC | low | pacman installs | `install.sh:155-162` — `vlc`, `vlc-plugins-all`, `xdg-user-dirs` are in `PACMAN_PKGS` (block ends before `AUR_PKGS` at :188), i.e. official repos with signature verification. No AUR. |
| T-06-W01 | medium | wlogout `action` → `system()` | **Byte-level git evidence.** `git show 6f7d4af -- wlogout/.config/wlogout/layout` changes only the `text` field; all six `action` strings and six `keybind` values are byte-identical across the diff. Current actions (`layout:1-6`) are the audited set. |
| T-06-W02 | low | wlogout style.css discarded | Real GTK3 parse: `theme-doctor` reports `[PASS] CSS-parse: wlogout/style.css (4535 bytes)` — non-empty provider, zero fatal errors. Re-run during this audit. |
| T-06-W04 | medium | `pkill -f` kill-the-wrong-process | `record-toggle.sh:50,60` bound the pattern to argv[0] with a trailing space: `pkill -SIGINT -f "^gpu-screen-recorder "` / `pkill -9 -f "^gpu-screen-recorder "`. **Behaviorally verified during this audit** with live decoy processes: the old unbounded `^gpu-screen-recorder` matched BOTH the recorder and a `gpu-screen-recorder-ui` sibling; the shipped bounded pattern matched only the real recorder. |
| T-06-W05 | low | hyprpicker stdout → notify-send | `color-picker.sh:30` `ERR=$(printf '%s\n%s' "$(cat "$ERR_FILE")" "$OUT" \| sanitize)` — `sanitize` applied to the **combined** stream before `notify-send` (:34) |
| T-06-W06 | low | garbage → `wl-copy` | `color-picker.sh:42-43` `tail -n1` + `[[ "$HEX" =~ ^#?[0-9a-fA-F]{6}$ ]] \|\| exit 1`, guarding `wl-copy` (:45) |
| T-06-W07 | low | clipboard-wipe silent no-op | `clipboard-wipe.sh:18` `|| true` neutralises `cliphist list`'s exit-1-on-empty under `set -e`; destructive-confirm ordering preserved — `printf 'No\nYes\n'` (:26), and only `"Yes"` proceeds (:36) |
| T-06-W09 | medium | rsync `--delete` data destruction | `lib/commit.sh:82` `--exclude=walker-relaunch.log` added; `--delete` **retained** (:79) with only named-file excludes (:79-82), so genuinely stale rendered files are still pruned — the fix did not degenerate into disabling `--delete` |
| T-06-W10 | low | reload fan-out aborted by Zen | `lib/reload.sh:119` uses `install_sections=$(grep -c '^\[' … ) \|\| true`; grep for the `\|\| echo 0` idiom over `reload.sh` returns **none** |
| T-06-W12 | low | `$STATE_DIR` permissions | `lib/commit.sh:90` `chmod 700 "$STATE_DIR"` re-asserted **after** the rsync (:79) — still present after the exclusion edit |
| T-06-W13 | low | shell/Python injection | `theme-doctor:215` `python3 - "$major" "$@" <<'PYEOF'` with `sys.argv` consumption (:219-220). Heredoc is quoted; paths are argv, never interpolated into the Python source string. |
| T-06-W14 | medium | poisoned test stylesheet surviving | Task 3 was proof-only (`trap … EXIT`, no commit). Verified post-hoc: `git status --porcelain -- wlogout/ waybar/` is empty, and `ls -a ~/.config/waybar/` shows only the three real `style-*.css` + three `config-*.jsonc` — no dot-prefixed or temp artifact survived. |
| T-06-W15 | low | theme-doctor requires a display | No `Gtk.init()` anywhere in `theme-doctor` (only a comment at :192 forbidding it). Verified by execution: `env -u WAYLAND_DISPLAY -u DISPLAY theme-doctor` emits all 9 CSS-parse checks green/SKIP. |

## Accepted Risks Log

Each entry below is a threat whose declared disposition is `accept`. The premise of each acceptance was
verified against the code — an accept whose stated precondition is false is not an accepted risk.

| ID | Sev | Accepted Risk | Premise verified |
|----|-----|---------------|------------------|
| T-06-02 | low | Rendered `satty.toml` is consumed by satty as its config | Rendered from trusted palette JSON via the same render→commit pipeline as Phases 1-5; no user input reaches the template. `lib/commit.sh:108-118`. |
| T-06-04 | low | wlogout power-action commands run session-power operations | `git show 0dd58f8` (the 06-03 edit): the six `action` strings are byte-identical across the diff — the plan touched only `text`. Actions remain the Phase-4 uwsm-audited set. |
| T-06-05 | low | GTK label renders an arbitrary Unicode glyph | Glyphs are hardcoded in `wlogout/layout:1-6` from the Nerd Font cheat-sheet; no external input path. |
| T-06-07 | low | playerctl / battery output rendered on the lock surface | Labels render only trusted local subprocess output; no external input reaches hyprlock. |
| T-06-10-01 | low | `icon-theme-switch.sh` / `font-switch.sh` exec kitty | `uwsm app -- kitty` with a fixed literal script path and window class; no user-controlled interpolation (`icon-theme-switch.sh:7`, `font-switch.sh:7`). |
| T-06-10-03 | low | `contract.json` `presence_only_files` → theme-doctor | `lib/contract.sh:32-33` reads the list with `jq` and drives only `[[ -f … ]]` existence checks under `$STATE_DIR`. |
| T-06-10-SC | low | package installs | Plan 06-10 adds no packages. Verified: `AUR_PKGS` gained exactly the 3 audited entries phase-wide. |
| T-06-11-03 | low | subprocess stderr → notify-send | `color-picker.sh`'s `sanitize` gates stderr; the capture guards emit only a fixed "not installed" string. |
| T-06-11-SC | low | package installs | Plan 06-11 adds no packages. |
| T-06-12-02 | low | hyprlock placeholder colour variable | `hyprlock.conf:177` — `$on_surface_variant_hex` is matugen-rendered from the trusted palette into a pango span; no external input. |
| T-06-12-SC | low | package installs | Plan 06-12 adds no packages — it only fixes the `$AUR_HELPER` indirection. |
| T-06-13-01 | low | **EoP:** `sudo systemctl enable --now swayosd-libinput-backend.service` | `install.sh:342` — fixed literal unit name, no interpolation; the unit is the packaged `extra/swayosd` root service with its own upstream polkit policy + udev rules. `install.sh` already runs privileged pacman steps; failure surfaces to stderr rather than being swallowed. **This is the only privileged operation Phase 06 adds.** |
| T-06-13-03 | low | autostart `exec-once = uwsm app -- swayosd-server` | `autostart.conf:36` — fixed package-provided binary name via the same `uwsm app --` scope isolation as every other autostart daemon; no path or argument is user-controlled. |
| T-06-13-SC | low | package installs | Plan 06-13 adds no packages — swayosd was already legitimacy-gated in 06-01. |
| T-06-14-01 | low | `keybinds.conf` keycode rebind | Static config edit under stow; same scripts, same dispatch path. No new attack surface. |
| T-06-W03 | low | glyph codepoints in `layout` | Inert display data; no execution or disclosure path. |
| T-06-W08 | low | `/tmp` `mktemp` leaks (accept-with-mitigation) | Leaked artifacts are the pickers' own enum/preview scripts and cached preview PNGs — no secrets. Mitigation nonetheless shipped: `trap … EXIT` present in `color-picker.sh`, `gif-export.sh`, `font-switcher.sh:55`, `icon-theme-picker.sh:49`. |
| T-06-W11 | low | Zen profile path from `installs.ini` / `profiles.ini` | `lib/reload.sh:156` resolves with `realpath -m` and places a userChrome symlink only under the user's own `~/.zen`. A hostile `~/.zen/installs.ini` implies the user's own browser config is already compromised — no privilege boundary crossed. Additionally bounded by T-06-10's subdirectory check. |

## Unregistered Flags

No `## Threat Flags` section exists in any of the 19 SUMMARY files, so no executor-declared new attack
surface was carried forward. Two observations, both informational — neither is a finding:

1. **Post-phase fix commits touched wlogout with no threat mapping.** Commits `8db47a2`, `952dc4e`,
   `5f61504`, `fa78129` landed after `06-19-SUMMARY.md` and modified `wlogout/style.css` and
   `hypr/.config/hypr/scripts/wlogout.sh`. They are covered in effect by the T-06-W02/T-06-W16 guard,
   which was re-run during this audit and still reports `[PASS] CSS-parse: wlogout/style.css (4535 bytes)` —
   this is exactly the regression class the guard was built to catch, and it is catching it.
   `git diff 8db47a2~1 HEAD -- wlogout/.config/wlogout/layout` is empty: no `action` string was touched.
2. **`hypr/.config/hypr/scripts/wlogout.sh` uses `pkill -x wlogout`** (`:18`) — the exact-match form,
   already bounded, i.e. it does not reproduce the T-06-W04 unbounded-`pkill -f` defect class.

## Residual Observations (non-threats, tracked only)

- `font-switcher.sh:219` creates `FONT_FRAGMENT_FILE` via `mktemp` and removes it at `:228`, but that path
  is not covered by the file's `EXIT` trap (`:55`, which covers `ENUM_SCRIPT`/`PREVIEW_SCRIPT`/`CACHE_DIR`).
  An abort between :219 and :228 leaks one `/tmp/font-vscodium-fragment-*.json`. This is inside the
  already-accepted T-06-W08 envelope (no secrets, unpredictable name, user-only perms) and does not
  change its disposition.
- `swayosd/style.css` is `[SKIP]` in the CSS-parse guard — not deployed under `~/.config` on this machine
  (`run stow.sh`). The guard correctly reports SKIP rather than a false PASS.
