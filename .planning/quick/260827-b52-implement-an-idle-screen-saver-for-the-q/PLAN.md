---
quick_id: 260827-b52
slug: implement-an-idle-screen-saver-for-the-q
date: 2026-08-27
status: complete
stage: 2
---

# Quick task 260827-b52 — Aorus idle screen saver

**Ask (operator, verbatim):** "Implement screen saver. Inspired by Omarchy but
replace 'Omarchy' with 'Aorus' instead which will be our dotfiles identity.
Generate a web page artifact with possible designs."

Two deliverables, in order. **Stage 1 ends at a decision** — the same shape as
quick task 260826-rfy (dashboard/perf study), which published a study, took the
operator's pick, then built it in stages 2–3.

---

## Reference — vendored, not paraphrased

`.planning/notes/aorus-screensaver/` holds Omarchy's actual files at master
`f4378f0d` (memory: *vendor the reference source*). What they establish:

| File | Mechanism |
|---|---|
| `bin_omarchy-launch-screensaver` | Spawns **one terminal window per monitor**, class `org.omarchy.screensaver`, running `omarchy-screensaver`. Requires `tte`; picks alacritty/ghostty/foot/kitty by `xdg-terminal-exec --print-id`. |
| `bin_omarchy-screensaver` | `printf '\033]11;rgb:00/00/00\007'` (force true black), `cursor:invisible true`, then loops `tte -i ~/.config/omarchy/branding/screensaver.txt --random-effect --anchor-canvas c --frame-rate 120`. Exits on `read -n1` (any key) **or** loss of window focus. |
| `bin_omarchy-branding-screensaver` | Branding is a plain text file — `image` transcodes any SVG/PNG to braille/block art, `text` opens it in an editor, `reset` restores `logo.txt`. |
| `config_hypr_hypridle.conf` | screensaver at **150s**, lock at **152s** — because launching the terminal *resets the idle timer*, so the lock listener's clock restarts. 150+152 ≈ 5 min. |
| `logo.txt` | 10 rows × ~80 cols of `▄█▀` block art. |

**Measured on this host:** `tte` is **not installed** (`terminaltexteffects` is not
a pacman package name here). `magick` 7.1.2.29 and `chafa` are installed.

## The architectural ruling this task rests on

Omarchy's screensaver is an **external terminal process**. This repo spent the
whole of v4.0 deleting external surfaces — waybar (RETIRE-02), swaync
(RETIRE-03), swayosd (RETIRE-04), walker/elephant (260822-sht), hyprlock
(260827-ar3) — and `.claude/CLAUDE.md` states the rule outright: *"Reintroducing
one would re-split the theming pipeline across a second toolkit for no
functional gain."*

**So: the screensaver is an in-process Quickshell surface, not a terminal.**
The *inspiration* carried over is the idea — a full-bleed idle canvas showing
the project's own wordmark under cycling effects, dismissed by any input. The
*implementation* follows `modules/lock/`, which is the closest existing analog:
a fullscreen surface with N operator-selectable layouts behind one `layoutKey`
switch and a settings picker.

This also removes Omarchy's 150/152s hack — no window is spawned, so nothing
resets the idle timer.

## Wordmark — generated, not hand-drawn

`aorus_block.txt` (10 rows × 78 cols) was produced by running "AORUS" through
Omarchy's **own** block transcoder algorithm (`omarchy-transcode-ascii`'s awk
half, re-run locally): `magick` renders the text at pointsize 400 in
FiraCode Nerd Font Mono Bold → alpha extract → trim → resize `78x20!` →
threshold → PBM → half-block pairs. Same pipeline, same style, same dimensions
as `logo.txt` (10 × ~80).

## Current idle ladder (measured, `~/.local/state/hypr/idle-overrides.conf`)

| Timeout | Action |
|---|---|
| 120s | bar idle-hide |
| 300s | dim to 30% + live-wallpaper suppress |
| 600s | `loginctl lock-session` |
| 1200s | dpms off |
| 1800s | suspend |

The screensaver has to be inserted into this ladder, and where it goes is a
stage-1 decision, not an assumption.

---

## Stage 1 — design study (this stage)

- [x] Vendor Omarchy's screensaver sources; establish the real mechanism
- [x] Generate the AORUS block wordmark through Omarchy's own transcoder
- [x] Measure the palette (19 roles), motion tokens, idle ladder, monitor (2560×1440)
- [ ] Publish a web-page artifact rendering every candidate direction **to
      scale** at one shared scale factor (memory: *show the design, don't
      describe it*; *publish a design study, then let them pick*)
- [ ] Surface the non-visual rulings the operator must make (ladder position,
      true black vs surface, burn-in policy, dismissal)
- [ ] Commit study + vendored reference

**Stage 1 ends here. No QML is written until the operator picks.**

## Stage 2 — build (after the pick)

Shape it mirrors `modules/lock/`:

- `modules/screensaver/Screensaver.qml` — shell-root mount, `IpcHandler`
  target `screensaver` (`show`/`hide`/`isActive`), one surface per screen
- `modules/screensaver/ScreensaverSurface.qml` — `WlrLayershell` overlay,
  `exclusiveZone: -1` (memory: a non-negative zone **overrides**
  `ExclusionMode.Ignore` — the power-menu scrim defect), keyboard grab,
  dismiss on any key/motion
- One `.qml` per picked style, each declared in `modules/screensaver/qmldir`
  **in the same commit that creates it** (qml-import-check enforces this)
- `Prefs.qml` key + a settings picker row, mirroring the lock-layout picker
- hypridle listener + `install.sh`/`stow.sh` touchpoints
- Gates: `colour-lint`, `motion-lint`, `settings-index-check`, `qmllint`

## Constraints carried in from memory

- Colours come from `Colours.qml` only — `colour-lint` rejects literals. The
  one deliberate exception to argue for is a true-black backdrop.
- Durations come from `Motion.qml`; read live tokens
  (`~/.local/state/theme/motion.json` — zen: standard 400ms), never the `|| 200`
  fallbacks.
- Never restart quickshell from the agent shell — hand restarts to the operator.
- No screenshots of a live layer surface until the last edit lands; incubated
  pages serve stale QML.
