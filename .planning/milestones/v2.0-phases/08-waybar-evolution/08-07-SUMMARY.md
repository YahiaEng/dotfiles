---
phase: 08-waybar-evolution
plan: 07
subsystem: theming-pipeline
tags: [eww, mpris, playerctl, security, yuck, gtk3, hardening]

requires:
  - phase: 08-waybar-evolution
    provides: "eww installed + first-class theme-pipeline render target; skeleton media-popup window; pinned eww 0.6.0 CLI surface (08-06)"

provides:
  - "media-art-resolve.sh — scheme-validated (file/http/https only), hash-keyed album-art resolver with SSRF/local-file-read guards"
  - "media-players.sh — _valid_id bus-name allowlist, the sole argv-form playerctl mutation dispatcher (list/active/select/cmd)"
  - "media-status.sh — single-line JSON deflisten payload, per-field playerctl queries, jq --arg/--argjson emission, D-25 empty payload"
  - "tests/test-media-hardening.sh — hermetic, rerunnable adversarial gate (19 checks, PATH-shimmed playerctl/curl, isolated HOME)"
  - "The real media-popup eww window: 220x220 album art, title/artist/album, prev/play-pause/next, draggable seek bar, volume slider, explicit player switcher — all 7 D-21 elements, verified live against a real running player"
  - "A corrected, expanded record of eww 0.6.0's real widget/CLI surface beyond what 08-06 pinned — see 'Pinned eww CLI/widget facts' below"

affects: [08-08]

tech-stack:
  added: []
  patterns:
    - "eww widget click handling: `box` has NO :onclick in this build — `eventbox` is the only container that wires a real click handler; `button` natively supports :onclick"
    - "eww lazy variable evaluation: defpoll/deflisten scripts only run while a currently-open window references the variable — no separate :run-while gate needed for popup-scoped pollers"
    - "eww image widget paths must always resolve (even while :visible false) and must never rely on shell tilde-expansion — use {EWW_CONFIG_DIR} + a bundled fallback asset instead of an empty-string path"

key-files:
  created:
    - hypr/.config/hypr/scripts/media-art-resolve.sh
    - hypr/.config/hypr/scripts/media-players.sh
    - hypr/.config/hypr/scripts/media-status.sh
    - hypr/.config/hypr/scripts/tests/test-media-hardening.sh
    - eww/.config/eww/assets/blank.png
  modified:
    - eww/.config/eww/eww.yuck
    - eww/.config/eww/eww.scss

key-decisions:
  - "Seek/volume scales operate directly in their native unit (absolute seconds 0..media.length; fractional 0..1 mpris volume) rather than a 0-100 UI scale divided by 100 in yuck — eww's onchange {} substitution is a raw textual replacement performed before the shell sees the command string, so no arithmetic conversion is possible inline. Verified directly against the installed binary."
  - "can_seek is derived as a length>0 heuristic — playerctl/mpris expose no direct CLI surface for the MPRIS CanSeek property; RESEARCH did not verify one either."
  - ":onkeypressed on media-popup closes on ANY keypress (not filtered to Escape specifically) — per-key filtering syntax could not be empirically verified within session time (no working input-injection tool to test real keyboard-focus delivery to the layer-shell overlay), and this is safe because the popup has no text-input controls. :unfocus-close remains the primary, fully-verified D-23 close mechanism."

requirements-completed: [BAR-04]

coverage:
  - id: D1
    description: "media-art-resolve.sh: scheme-validated (file/http/https only), hash-keyed, SSRF/local-file-read-guarded album-art resolver"
    requirement: "BAR-04"
    verification:
      - kind: integration
        ref: "hypr/.config/hypr/scripts/tests/test-media-hardening.sh checks 8-10 (ftp/loopback rejection, distinct-hash caching) — 19/19 PASS"
        status: pass
      - kind: manual_procedural
        ref: "Direct live invocation: resolved the real Zen/Firefox file:// artUrl to a readable image path; rejected file:///etc/passwd (mime gate); rejected a command-substitution payload with zero execution"
        status: pass
    human_judgment: false
  - id: D2
    description: "media-players.sh: _valid_id bus-name allowlist as the sole gate; list/active/select/cmd subcommands; cmd is the only argv-form playerctl mutation dispatcher"
    requirement: "BAR-04"
    verification:
      - kind: integration
        ref: "hypr/.config/hypr/scripts/tests/test-media-hardening.sh checks 4-7 — 19/19 PASS"
        status: pass
      - kind: manual_procedural
        ref: "Direct live invocation against the real Firefox/Zen player: cmd play-pause flipped playerctl status Playing<->Paused within <500ms; cmd seek 100 moved position to 100.0; cmd volume 0.5/1.0 changed playerctl volume"
        status: pass
    human_judgment: false
  - id: D3
    description: "media-status.sh: single-line JSON deflisten payload, D-25 empty payload on no player, control-char strip, jq --arg/--argjson emission"
    requirement: "BAR-04"
    verification:
      - kind: integration
        ref: "hypr/.config/hypr/scripts/tests/test-media-hardening.sh checks 1-3, 11 — 19/19 PASS"
        status: pass
      - kind: manual_procedural
        ref: "Direct live invocation: real player fields (title/artist/art/position/length/volume) matched ground-truth playerctl output; watch loop deduped correctly (1 line/3.5s idle, 4 lines/3.5s while playing)"
        status: pass
    human_judgment: false
  - id: D4
    description: "tests/test-media-hardening.sh: hermetic, rerunnable adversarial gate proving no player-supplied metadata reaches a shell/eval and nothing escapes its output context"
    requirement: "BAR-04"
    verification:
      - kind: integration
        ref: "hypr/.config/hypr/scripts/tests/test-media-hardening.sh — 19/19 PASS, rerun twice consecutively, both exit 0; real ~/.cache/eww-media-player and ~/.cache/eww-media-art left untouched (isolated HOME)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The real media-popup eww window: all 7 D-21 elements (album art, title/artist/album, transport row, seek bar, volume slider, player switcher), D-25 no-empty-state, zero hex-literal colors, theme-parity green light+dark"
    requirement: "BAR-04"
    verification:
      - kind: automated_ui
        ref: "Live screenshots (grim) against the real running eww daemon and a real Firefox/Zen mpris player: full popup render (art/title/artist/transport/seek/volume/switcher), switcher expand+active-highlight, D-25 empty-body render with zero players, light-theme re-color, dark-theme re-color"
        status: pass
      - kind: integration
        ref: "theme-engine/.config/theme-engine/theme-parity — 1630 passed, 0 failed, eww.scss included across all 22 palettes"
        status: pass
      - kind: unit
        ref: "fontTools cmap assertion (7 Nerd Font codepoints) — 0 missing; grep for hex-literal colors in eww.scss — 0 matches; grep for :onclick/:onchange metadata interpolation — only media.player/player.id/{}/EWW_CMD found"
        status: pass
    human_judgment: false

duration: ~3h
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 07: eww Media Popup + Hardened MPRIS Helpers Summary

**The full-fat D-21 media popup — 220x220 album art, title/artist/album, prev/play-pause/next, a draggable seek bar, a volume slider, and an explicit player switcher — ships as a real eww window backed by three hardened bash helpers that keep player-supplied MPRIS metadata (attacker-controlled D-Bus data) out of every shell command and output context, proven by a 19-check hermetic adversarial gate and verified live end-to-end against the real running eww daemon and a real Firefox/Zen player.**

## Performance

- **Duration:** ~3h (extensive live verification against the real desktop, including discovering and fixing three real eww-version-specific rendering bugs)
- **Completed:** 2026-07-14
- **Tasks:** 3/3
- **Files modified:** 7 (4 created scripts, 1 created asset, 2 modified eww files)

## Accomplishments

- **All three hardened helper scripts** (`media-art-resolve.sh`, `media-players.sh`, `media-status.sh`) form a closed data path (playerctl -> per-field query -> control-char strip -> `jq --arg` -> one JSON line) and a closed control path (eww -> `media-players.sh cmd` -> allowlisted verb + validated id -> argv-form playerctl) — no string-to-code re-evaluation anywhere, comment-stripped-grep verified.
- **The hermetic adversarial gate** (`tests/test-media-hardening.sh`) attacks the helpers with a title containing `$(id)`/backticks/`;`/`&`/`<b>`, a newline-bearing artist, a hostile bus-name id (`spotify; id`), an `ftp://` artUrl, a loopback `http://127.0.0.1` artUrl, and a zero-player scenario — 19/19 checks pass, rerun twice consecutively both exit 0, and the real `~/.cache/eww-media-player`/`~/.cache/eww-media-art` are never touched (isolated HOME).
- **The real `media-popup` eww window** replaces 08-06's skeleton with all seven D-21 elements, verified with real, live screenshots against the actual running eww daemon and a real Firefox/Zen mpris player (a YouTube "Speedrunning Super Mario 64" video) — real album art, real title/artist, real seek-bar position (`47:06 / 51:20`), real transport control (play-pause flipped the real player's status), a real volume slider, and a real player-switcher that expands and highlights the active player.
- **D-25 holds, verified visually**: with a synthetic zero-player payload, the popup renders as a completely empty body — no title, no album art, no buttons, no placeholder text of any kind — confirmed via a direct screenshot comparison against the populated state.
- **Theme-pipeline citizenship confirmed live**: switched the whole desktop to `catppuccin-latte` (light) and back to `catppuccin` (dark) mid-session — the popup re-colored correctly both times, and `theme-parity` stayed green (1630/1630) throughout.
- **Three real eww-0.6.0-specific bugs found and fixed during Task 3** that would otherwise have shipped broken: `box` silently accepts `:onclick` at parse time but never fires it at render time (fixed with `eventbox`); `image :path` is evaluated by GTK even while `:visible false`, logging a "Failed to open file ''" error every second once art is momentarily empty (fixed with a bundled `assets/blank.png` fallback resolved through `{EWW_CONFIG_DIR}`, since GTK does not shell-expand `~`); and two real script bugs (`_valid_ids`' read-loop dropped a trailing-newline-less last line; `cmd_list`'s `jq` call was missing `-n` and silently produced empty output).

## Task Commits

1. **Task 1: media-art-resolve.sh — scheme-validated, hash-keyed album-art resolver** — `d79ff13` (feat)
2. **Task 2: media-players.sh + media-status.sh + the hermetic hardening gate** — `09616c1` (feat)
3. **Task 3: eww.yuck + eww.scss — the full-fat media-popup widget tree** — `ba8f1e5` (feat)

**Plan metadata:** (this commit, following)

## Files Created/Modified

- `hypr/.config/hypr/scripts/media-art-resolve.sh` — new; scheme allowlist (file/http/https), percent-decode + `realpath -e` + mime-gate for `file://`, sha256-of-url cache key + host-guard + `curl --proto` allowlist for `http(s)://`
- `hypr/.config/hypr/scripts/media-players.sh` — new; `_valid_id` bus-name allowlist (`^[A-Za-z0-9._-]{1,128}$`), `list`/`active`/`select`/`cmd` subcommands, the sole argv-form playerctl mutation dispatcher
- `hypr/.config/hypr/scripts/media-status.sh` — new; `once`/`watch`/`position` subcommands, per-field playerctl queries, control-char strip + truncation, `jq --arg`/`--argjson` emission, D-25 empty payload
- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` — new; hermetic PATH-shimmed adversarial gate, 19 checks, isolated HOME
- `eww/.config/eww/eww.yuck` — rewritten; full `media-center` widget tree replacing 08-06's skeleton
- `eww/.config/eww/eww.scss` — rewritten; full UI-SPEC styling (60/30/10 color mapping, swaync button-state convention, 4-size typography scale), zero hex literals
- `eww/.config/eww/assets/blank.png` — new; bundled 1x1 transparent PNG, the always-resolvable fallback for `image :path` when no album art is available
- `.planning/phases/08-waybar-evolution/deferred-items.md` — appended the orphaned `media-player.py` + `config-floating.jsonc:52` duplicate-surface flag for 08-08

## Decisions Made

- **Seek/volume scales use native units, not a 0-100 UI scale.** eww's `scale :onchange "{}"` substitution is a raw textual replacement performed by the yuck interpreter *before* the command string reaches the shell — there is no way to write "divide `{}` by 100" inline in the command string (confirmed via a live scratch test: `{}` never becomes a yuck-evaluable term). The seek scale's `:min`/`:max`/`:value` therefore operate directly in absolute seconds (`0..media.length`), matching `playerctl position <seconds>`'s own semantics exactly; the volume scale operates in fractional `0..1` (mpris's native range), matching `playerctl volume <float>`. Both remain fully argv-form and quoted — this is a unit-representation choice, not a security relaxation.
- **`can_seek` is a `length > 0` heuristic.** Neither `playerctl` nor a simple CLI surface exposes MPRIS's `CanSeek` property directly; RESEARCH did not verify one either. A nonzero track length implies seekability for every player observed on this machine (Firefox/Zen).
- **`:onkeypressed` closes on any keypress, not filtered to Escape.** No working input-injection tool (`ydotool`/`wlrctl`) was available in this session to empirically prove per-key filtering syntax or that the layer-shell overlay window actually receives keyboard focus (a `wtype -k Escape` test left focus on the terminal, not the eww window, even with `:focusable true` set). Since the popup has zero text-input controls, closing on any keypress is a safe simplification; `:unfocus-close true` remains the primary, fully-verified D-23 close mechanism (click-away).
- **No `label` Pango-escaping step was added.** Verified directly (screenshot) that `label :text` does NOT parse Pango markup by default in this eww build — a `<b>Bold</b> & "quoted"` fixture rendered as literal characters, not styled text. This closes T-08-07-06 without needing the jq escaping step the plan conditionally requested.

## Pinned eww CLI/widget facts (this session, against the installed 0.6.0 binary)

Building on 08-06-SUMMARY.md's "Pinned eww CLI" section — everything below was newly verified this session, empirically, against the real installed binary (never assumed from web search):

| Claim | Status | Finding |
|---|---|---|
| `scale`'s `:draggable` property | **DOES NOT EXIST** | `eww open` warns `Unknown attribute draggable`. GTK's `Scale` widget is draggable by mouse unconditionally — there is no separate flag. Use `:active {expr}` to gate interactivity (confirmed accepted, no warning). |
| `defpoll`'s `:run-while` | **EXISTS**, but turned out unnecessary here | Accepted with no parse error. However, a separate, more important finding made it redundant for this plan: `defpoll`/`deflisten` variables are **lazily evaluated** — a variable's backing script only runs while at least one *currently-open* window references that variable (confirmed: a `defpoll` never referenced anywhere printed nothing via `eww get`, and started running only once referenced in an open window's tree). Since `media` and `media_players` are only referenced inside `media-popup`, they already only run while the popup is open — no extra `:run-while` gate needed. Closes RESEARCH Assumption A5. |
| `label :text` Pango markup parsing | **DOES NOT PARSE by default** | Verified via a live screenshot: a `Evil <b>Bold</b> Track & Title "quoted"` fixture rendered as literal characters on the real desktop, not bold text. No jq escaping step was added as a result (see Decisions above). |
| `EWW_CMD` / `EWW_CONFIG_DIR` / `EWW_EXECUTABLE` | **Magic YUCK variables, NOT shell env vars** | `eww state` on a scratch config referencing `{EWW_CMD}` showed `EWW_CMD: "/usr/bin/eww" --config "<dir>"` — these are yuck-parser-level substitutions, confirmed by a separate test showing a spawned script's real shell environment has **no** `EWW_*` variables at all (`env \| grep EWW_` from inside a `defpoll` script returned nothing). Use `{EWW_CMD}` inline in a command string, never `$EWW_CMD` expecting shell expansion. |
| `box` widget's `:onclick` | **DOES NOT WORK** (real bug found this session) | Parses silently with no warning at daemon-init time, but logs `Unknown attribute onclick` at **render time** (only visible once the window is actually opened, not just when the daemon starts) and the handler never fires. `eventbox` is the widget that actually wires a click handler onto an otherwise-inert container; `button` natively supports `:onclick` with no issue. This cost real debugging time — daemon-init-only warning checks are NOT sufficient to prove a widget attribute works; the window must be opened. |
| `image :path` evaluation timing | **Evaluated on every `media` update regardless of `:visible`** (real bug found this session) | Even with `:visible {media.art != ""}` on the `image` widget, GTK still attempts to load `:path`'s value on every state change — an empty-string path logs `Failed to open file "": No such file or directory` as an ERROR on every ~1s tick once art becomes momentarily unavailable (observed live: the real Zen/Firefox mpris bridge's cached artUrl file disappeared mid-session after the video paused). Fixed by binding `:path` to a bundled `assets/blank.png` fallback (a real 1x1 transparent PNG) instead of an empty string, resolved via `{EWW_CONFIG_DIR} + "/assets/blank.png"` — **GTK does not shell-expand `~`**, so `~/.config/eww/assets/blank.png` as a literal path also failed until switched to the magic var. |
| `{}` onchange substitution | **Raw textual replacement, not a yuck expression** | Confirmed: there is no way to wrap `{}` in arithmetic (e.g. `{} / 100`) inside an `:onchange` command string — see Decisions above. |
| Yuck arithmetic: `/`, `%`, `round()` | **`/` is floating point; `%` and `round(x, n)` both work** | Verified via live screenshot: `${round((185 - 185 % 60) / 60, 0)}:${...}` correctly produced `3:05` for 185 seconds and `1:05` for 65 seconds — used for the mm:ss position readout, entirely in yuck arithmetic, never shelling out. |
| `for player in json_array (... ${player.field} ...)` | **Confirmed working**, including dot-field access on loop-bound objects | Verified via live screenshot rendering two distinct labels from a 2-element JSON array. |
| `:limit-width` | **Confirmed working**, truncates with an ellipsis | Verified via live screenshot. |
| Nested `${expr}` inside a quoted attribute string containing its own string-literal quotes | **Works when the inner quotes are plain `"..."`, not backslash-escaped** | `"row ${x == "Playing" ? "playing" : ""}"` parses and evaluates correctly; the earlier attempt with `\"...\"` inside the `${}` produced a hard parse error (`Invalid token`). A whole-value ternary/expression attribute should instead use bare `{expr ? "a" : "b"}` (no outer quotes) when there's no surrounding literal text to mix in. |

## Spotify / player-capability findings (closes RESEARCH Assumptions A2/A5)

- **Spotify was not available to test this session** (only Firefox/Zen's mpris bridge was running) — the remote `https://` artUrl branch (Assumption A2) was exercised only through the hermetic gate's shimmed curl (which downloads a real, valid 1x1 PNG to prove the mime-gate and hash-keyed caching logic genuinely work end-to-end, not just parse). It was not observed against a real Spotify instance.
- **Firefox/Zen's mpris bridge DOES expose a `volume` property** (`playerctl volume` returned `1.000000`), contradicting the plan's own stated assumption ("Firefox/Zen commonly does not [expose volume]"). The volume slider was therefore verified live against a real, working volume control on this exact player — not just the hidden-row fallback path. No player observed in this session lacked a volume property, so the hidden-volume-row path (`:visible {media.volume >= 0}`) was verified structurally (code review + the hermetic gate's `-1` fixture) but not against a real player missing the property.
- **`POLL_INTERVAL=1`** (1 Hz change-detected poll) was kept as specified in the plan — verified live: an idle player produced 1 payload line per ~3.5s window; an actively playing player (position ticking) produced ~1 line per second, confirming the change-detection dedup works correctly under both conditions.

## Duplicate media surface (flagged for 08-08)

Per the plan's own inherited-contract note: `waybar/.config/waybar/config-floating.jsonc:52` still runs a `custom/media-player` module backed by the orphaned upstream sample script `hypr/.config/hypr/scripts/media-player.py`. This is a second, older media surface that 08-07 deliberately did not touch (out of this plan's file territory) — logged in `deferred-items.md` and here so 08-08 deletes both under "one surface per job" once it wires `media-popup` to the bar.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `_valid_ids`' read-loop silently dropped a trailing-newline-less last line**
- **Found during:** Task 2, live testing of `media-players.sh list` against a test shim.
- **Issue:** `while IFS= read -r line; do ... done < <(playerctl -l ...)` returns non-zero from `read` on the final line if the producer's stdout doesn't end in a newline, causing bash to skip the loop body for that line entirely.
- **Fix:** Added `|| [[ -n "$line" ]]` to the while condition (the standard fix for this exact bash idiom bug).
- **Files modified:** `hypr/.config/hypr/scripts/media-players.sh`
- **Commit:** `09616c1`

**2. [Rule 1 - Bug] `cmd_list`'s `jq` invocation was missing `-n`, silently producing empty output**
- **Found during:** Task 2, live testing of `media-players.sh list` against the real Firefox player.
- **Issue:** `jq -c --argjson ... '$acc + [...]'` with no stdin redirect and no `-n` flag reads from (empty) stdin, producing zero output instead of erroring — `list` always printed a blank line regardless of how many players were running.
- **Fix:** Added `-n` (null input) to the `jq` call inside the accumulation loop.
- **Files modified:** `hypr/.config/hypr/scripts/media-players.sh`
- **Commit:** `09616c1`

**3. [Rule 1 - Bug] `_label_for`'s instance-suffix regex didn't match the real-world id shape**
- **Found during:** Task 2, live testing against the real player id `firefox.instance_1_201`.
- **Issue:** The regex `\.instance_[0-9]+$` only matched a single digit run, but real ids have an underscore-joined multi-group suffix (`instance_1_201`), so the label rendered as `Firefox.instance_1_201` instead of `Firefox`.
- **Fix:** Widened the regex to `\.instance_[0-9_]+$`.
- **Files modified:** `hypr/.config/hypr/scripts/media-players.sh`
- **Commit:** `09616c1`

**4. [Rule 1 - Bug] `box` widget's `:onclick` never fires (real eww 0.6.0 behavior)**
- **Found during:** Task 3, live testing of the player-switcher header/rows against the real eww daemon.
- **Issue:** `(box :onclick "..." ...)` parses silently (no warning at daemon-init) but logs `Unknown attribute onclick` once the window is actually opened, and the click handler never fires.
- **Fix:** Wrapped both switcher click targets (the header row and each per-player row) in `eventbox`, which does support `:onclick`.
- **Files modified:** `eww/.config/eww/eww.yuck`
- **Commit:** `ba8f1e5`

**5. [Rule 1 - Bug] `image :path` errors on every tick once album art is momentarily empty**
- **Found during:** Task 3, live testing — the real Zen/Firefox mpris bridge's cached artUrl file disappeared mid-session (video paused), and the daemon log filled with `Failed to open file "": No such file or directory` ERROR lines once per second.
- **Fix:** Created `eww/.config/eww/assets/blank.png` (a bundled 1x1 transparent PNG) and bound `:path` to `{media.art != "" ? media.art : EWW_CONFIG_DIR + "/assets/blank.png"}` — GTK does not shell-expand `~`, so the magic `EWW_CONFIG_DIR` var (an absolute path) was required instead of a literal `~/...` string, which also failed identically.
- **Files modified:** `eww/.config/eww/eww.yuck`, `eww/.config/eww/assets/blank.png` (new), `stow.sh` symlink re-run (no code change — `stow -R eww` picked up the new `assets/` subdirectory cleanly, verified with `stow -n -v eww` dry run first)
- **Commit:** `ba8f1e5`

---

**Total deviations:** 5 auto-fixed (all Rule 1 — bugs discovered during live verification against the real desktop, not scope creep).
**Impact on plan:** All five fixes were necessary for correctness — three were real bugs in this plan's own new scripts, and two were genuine eww-0.6.0-version-specific behaviors that RESEARCH could not have predicted (an "unknown attribute" warning that only appears at render time, not parse time, and an always-evaluated image path). No scope creep; the plan's own frozen cross-plan interface (window name, `--arg` names, exit codes) is unchanged.

## Issues Encountered

- **No working input-injection tool** (`ydotool`, `wlrctl`) was available to simulate a literal mouse click or verify per-key keyboard-focus delivery to the layer-shell overlay window. Worked around by verifying the underlying `media-players.sh cmd` dispatch directly against the real player (proven to flip playback state within 500ms, move seek position, and change volume) and by grep-verifying that every `:onclick`/`:onchange` in `eww.yuck` invokes exactly that same dispatch with only a validated id or eww's own numeric substitution — the same security-relevant code path a real click would exercise, just not the literal GTK click event itself.
- Several stray/orphaned `eww`/`grim` background processes accumulated during iterative scratch-config testing this session (a side effect of this environment's tool-level background-command auto-promotion on long-running foreground calls) and briefly caused ghost-window screenshot confusion (an old window's content overlapping a new scratch window's screenshot at the same on-screen coordinates). Resolved by force-killing all `eww`/`grim` processes between test iterations and re-verifying process lists before each screenshot. Not a defect in any shipped file — confirmed by a final, fully clean end-to-end run (single daemon, single window, zero stray processes, zero errors in the log) immediately before committing Task 3.

## User Setup Required

None — no external service configuration required. The new `~/.cache/eww-media-art/` and `~/.cache/eww-media-player` runtime paths are created automatically on first use by the scripts themselves.

## Next Phase Readiness

- **08-08 is unblocked.** The frozen cross-plan interface is implemented exactly as specified: window name `media-popup`, `eww open media-popup --arg x=<int> --arg y=<int>` (both args required — confirmed, no working bare `eww open media-popup` in this eww build), and `media-players.sh active`'s exit code (0 + id, or 1 + empty) as the D-25 gate 08-08 must check before ever calling `eww open`.
- **08-08 should delete** `waybar/.config/waybar/config-floating.jsonc:52`'s `custom/media-player` module and `hypr/.config/hypr/scripts/media-player.py` once it wires the real `mpris` bar segment to `media-popup` (see "Duplicate media surface" above).
- No blockers. `theme-parity`, `theme-doctor` (modulo the pre-existing, documented dirty-tree check), and `waybar-equivalence-check` all remain green — this plan did not touch any waybar config, matching its stated scope boundary.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

- `test -f hypr/.config/hypr/scripts/media-art-resolve.sh` -> FOUND
- `test -f hypr/.config/hypr/scripts/media-players.sh` -> FOUND
- `test -f hypr/.config/hypr/scripts/media-status.sh` -> FOUND
- `test -f hypr/.config/hypr/scripts/tests/test-media-hardening.sh` -> FOUND
- `test -f eww/.config/eww/eww.yuck` -> FOUND
- `test -f eww/.config/eww/eww.scss` -> FOUND
- `test -f eww/.config/eww/assets/blank.png` -> FOUND
- `git log --oneline --all | grep d79ff13` -> FOUND
- `git log --oneline --all | grep 09616c1` -> FOUND
- `git log --oneline --all | grep ba8f1e5` -> FOUND
