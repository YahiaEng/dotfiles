# Phase 17: Ambient Extras - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-09
**Phase:** 17-ambient-extras
**Areas discussed:** Video ↔ palette coupling, Player ownership & switching, Hide-on-fullscreen & power, Cursor install path

---

## Video ↔ palette coupling

| Question | Options | Selected |
|---|---|---|
| Should a video wallpaper drive the Material You palette? | Yes, extract a still frame / No, decorative only / **Only in Material You mode** | Only in Material You mode |
| Where should the extracted frame live? | **State dir + repoint current.jpg** / Sidecar beside the video / Cache path outside the contract | State dir + repoint current.jpg |
| When should the frame be extracted? | **At selection + repair-on-missing** / Once at selection, cached only / Every theme-apply run | At selection + repair-on-missing |
| Which frame becomes the palette source? | **Fixed offset + per-video override** / Fixed offset only / First frame always / Sample several, pick most colourful | Fixed offset + per-video override |
| Where do video wallpapers live on disk? | Flat in per-theme folders / Separate tree / **Subfolder inside each theme** | `live/` subfolder (user-named) |
| Should static-preset auto-set land a live wallpaper? | **Remember per theme via last-wallpaper** / Stills only / Always prefer the video | Remember per theme |
| What should current.jpg point at in a static preset? | **The extracted frame, every mode** / Leave it on the last still / Frame for lock screen only | Extracted frame, every mode |
| If the video file is deleted or moved? | **Fall back to theme's first still, clear the choice** / Fall back to stow seed / Leave dangling and log | Fall back to first still |
| How should theme-doctor treat the frame? | **Conditional gate** / Always present, seeded / Never gated | Conditional gate |
| Frame resolution and format? | **Source resolution PNG** / Source resolution JPEG / Downscaled PNG | Source resolution PNG |

**Notes:**
- The user **challenged the caching recommendation** ("Why did you not recommend option 3?"). The challenge was correct: repair-on-missing costs one `stat()`, self-heals a disposable state dir, and matches `wallpaper.sh`'s existing best-effort self-healing shape. Recommendation was corrected rather than defended.
- The user **asked why sample-and-pick-most-colourful wasn't recommended** ("It sounds like it will produce the best colour palette"). Answered with: it selects for outlier frames; `hyprlock.conf:50` makes this frame the **lock-screen background**, so the metric would be choosing the lock screen; it competes with matugen's own chroma scoring; it is non-deterministic across ffmpeg/imagemagick versions; and it needs test fixtures inside a cut-candidate phase. The per-video override was added specifically because the user's underlying concern (scene-change video) was legitimate.
- The user named the folder `live/` (not `video/`) and explicitly accepted the picker-depth change.

---

## Player ownership & switching

| Question | Options | Selected |
|---|---|---|
| Who arbitrates awww vs mpvpaper on the background layer? | **Single visibility owner script** / Picker stops/starts inline / Run both, layer above | Single owner script |
| How is mpvpaper launched? | **uwsm app from the owner** / systemd --user service / exec-once in autostart.lua | uwsm app from owner |
| Audio and MPRIS? | **Silent + no MPRIS identity** / Silent, leave MPRIS alone / Opt-in audio per video | Silent + no MPRIS |
| How do live entries appear in the picker? | **One merged list, marked** / Separate picker / Toggle key | Merged list |
| What does the preview pane show for a video? | **Extract frame on first preview, cache** / Static placeholder / No preview | Extract + cache |
| What does the awww live desktop preview do? | **Start the video, debounced** / Paint the extracted frame / Start undebounced / Leave desktop untouched | Start debounced |
| Which outputs? | **All via '\*'** / Named primary only / Shared decoder | All via `'*'` |
| What does Esc restore? | **Owner restores exact prior state** / Videos restored as frame / No restore | Exact prior state |
| How is the new layer namespace gated? | **Extend quickshell-doctor** / Dedicated check in owner / No new gate | Extend quickshell-doctor |
| Where does login start the player? | **theme-apply's wallpaper step** / Dedicated autostart entry / No restore on login | theme-apply wallpaper step |
| Is mpvpaper hard or optional? | **Hard dependency in AUR_PKGS** / Optional-guarded / Not installed by install.sh | Hard dependency |
| Decode path on NVIDIA? | **hwdec=auto-safe** / Force NVIDIA hwdec / Software only | hwdec=auto-safe |

**Notes:**
- The user **challenged the "bad for performance" framing** of hover-start ("Is option 2 really bad for performance?"). The challenge was correct on two counts: the CPU claim was **unmeasured** (mpvpaper is not installed), and the actual objection was mis-stated — it is process/layer-surface lifecycle churn and orphan risk, arising from `wallpaper-picker.sh`'s undebounced `focus:execute-silent` binding and fire-and-forget `&`. A ~250ms debounce collapses the churn, which made the user's preferred option viable and it was adopted.

---

## Hide-on-fullscreen & power

| Question | Options | Selected |
|---|---|---|
| What counts as a live wallpaper? | *(Reformulated twice after user correction)* | Behaviour, not extension — GIF/WebP included |
| One backend or capability routing inside `live/`? | **mpvpaper plays everything** / awww for GIF+WebP, mpvpaper for video / awww first with fallback | mpvpaper for everything |
| Expected library mix? | Mostly video / Mostly GIF-WebP / **Genuinely mixed** / Don't know | Genuinely mixed |
| What does "hide" mean? | **Pause the player, keep the process** / Stop entirely and respawn / Hide surface only | Pause, keep process |
| How does fullscreen state reach the owner? | Extend waybar-fullscreen-watch.sh *(withdrawn)* → **Independent watcher** / Shared package-neutral watcher / Quickshell subscribes | Independent watcher |
| Which other states pause it? | Gaming mode / Lock+idle / Reduced motion / Any maximized-or-occluding window | **All four** |
| Given mpvpaper's native flags, how is visibility handled? | **Native -p/-a, verified first, watcher as fallback** / Native, no fallback / Own watcher from the start / Adopt mpvpaper-stop | Native, verified first |
| How to avoid two writers to `pause`? | **Split by mechanism** / Owner owns pause, drop -p/-a / Last writer wins | Split by mechanism |
| Which idle point stops it? | **Existing 300s dim listener** / 600s lock / 120s idle / New listener | 300s dim listener |
| At which motion-scale values? | **Only at 'off'** / 'off' + framerate cap at 'normal' / Not tied to motion-scale | Only at 'off' |

**Notes:**
- The user **corrected the definition of "live wallpaper"**: "Live wallpapers were never about the extension. By definition, it's anything that is not just a static wallpaper which includes .gif and .webp." The prior framing had wrongly treated `.mp4` as definitional. Two questions were reformulated as a result.
- The user **asked whether mpv-for-everything is heavier than two backends**. Answered honestly: capability routing genuinely is cheaper at runtime (awww is already running; mpv adds a process and GPU context), but the delta is one background process and **unmeasured**; the two-backend cost lands in proof burden — criterion 1's hide path, the layer gate and the cut sweep each proven twice, plus `awww pause` being daemon-wide vs mpv's per-player pause. The deciding fact (library mix) was handed back to the user rather than assumed.
- The user **rejected extending `waybar-fullscreen-watch.sh`**: "Waybar gets removed in the next milestone. Do not make that deprecation process more annoying by adding more waybar dependency." Correct and backed by MIG-06 and this phase's own "Owns: additive scaffolding drift" line. Recommendation withdrawn.
- The user then **demanded research before options**: "You keep recommending wrong or inefficient solutions. Do your research into each option for every discussion question before presenting them to me." Method changed for the remainder. Immediate payoff: mpvpaper's native `-p/--auto-pause`, `-s/--auto-stop` and `-a/--auto-mode` were found, largely obviating the watcher design that had been under construction.

---

## Cursor install path

| Question | Options | Selected |
|---|---|---|
| How should the plugin be installed? | **Guarded attempt in install.sh + post-login completion** / Post-login only / Ship a hyprcursor theme instead / Drop AMB-02 | Guarded + post-login |
| How is the forced failure injected? | **Bad plugin URL** / Failing hyprpm shim on PATH / Uninstall the toolchain | Bad plugin URL |
| Which behaviours? | *(Asked, then superseded by live testing)* | Mode deferred to render gate |
| Should the rose-pine pin be part of Phase 17? | **Fold into Phase 17** / Separate /gsd-quick / Leave it | Fold into Phase 17 |
| How is the mode settled? | **Implementation task with human render gate** / Go with tilt / Write config and restart now | Render gate |
| How should shake-to-find ship? | Enabled with raised threshold / **Disabled by default** / Enabled at upstream defaults | Disabled by default |
| How is the plugin loaded each session? | **hl.plugin.load() from repo config, path resolved at runtime** / hyprpm reload via autostart / Copy the .so | hl.plugin.load() |
| What does the cut sweep cover? | Repo references / hyprpm artifact / generate.sh pin / Live cursor check | **Repo references + hyprpm artifact** |

**Notes:**
- The user asked to **test the three modes live** rather than choose from descriptions. This drove a long empirical sequence that produced most of the phase's hard findings — and exposed several wrong assumptions.
- **Errors made and corrected during this area:** (1) `hyprctl keyword` was suggested for mode switching; it is dead under the Lua parser. (2) Four candidate Lua setter forms were invented and all silently failed before upstream's actual syntax was read. (3) The missing hyprcursor theme was inferred to be the blocker and stated as "now proven" — the user disproved it ("that tilt was working with the old XCursor bitmap"). A package (`rose-pine-hyprcursor`) had already been installed on that false inference; the user chose to keep it, which became D-32.
- The real cause of "all three modes look the same" was that **`mode` is read once at plugin load** and is not runtime-switchable — `getoption` reported `stretch` while the plugin kept rendering `tilt`.
- The user chose **not** to include `generate.sh`'s cursor pin in the cut sweep; the resulting gap is recorded explicitly in D-38 rather than silently accepted.

---

## Claude's Discretion

- Owner script name/placement (convention suggests `wallpaper-visibility.sh`).
- IPC/socket client shape — settled by repo convention (inline python3 stdlib; `socat` is not installed).
- Exact seek-offset default and the ~250ms debounce interval.
- The `live/` marker glyph in the picker list.

## Deferred Ideas

- **`gaming-mode-toggle.sh` may be silently dead since the 13.1 Lua cutover** — documented as driving the compositor exclusively via `hyprctl keyword`, which now errors. Same failure shape as the `dpms` calls in `hypridle.conf`. File as its own `/gsd-debug`; not folded into this phase.
- Wallpaper parallax on workspace switch — v4.0.
- mpvpaper slideshow mode (`-n/--slideshow`) — v4.0.
- Removing `rose-pine-hyprcursor` if D-32 is ever reverted.
- Per-video audio opt-in — considered and rejected under D-16.
