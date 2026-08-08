# Phase 17: Ambient Extras - Context

**Gathered:** 2026-08-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Two independent, purely cosmetic additions to an already-working desktop:

1. **AMB-01** — A *live wallpaper* (anything that moves, not only video containers) plays beneath the desktop, played by an external process rather than decoded in QML, and stops consuming resources when nothing can see it.
2. **AMB-02** — Dynamic cursors (the `hypr-dynamic-cursors` Hyprland plugin) install as an **optional guarded** dependency that can never fail an unattended install, plus the repo's pinned cursor theme moves to `rose-pine-hyprcursor` (folded in during discussion — see D-32).

This is the **last phase of v3.0 and the designated first to cut**. Criterion 3 makes cut-cleanliness a deliverable, not an afterthought: nothing started-and-unfinished may leave references behind.

**Not in this phase:** in-QML video decoding (Out of Scope in REQUIREMENTS.md), wallpaper parallax on workspace switch, slideshow/playlist wallpapers, retiring any existing surface.

</domain>

<decisions>
## Implementation Decisions

### Live wallpaper — definition and layout

- **D-01:** "Live wallpaper" is defined by **behaviour, not extension** — anything that moves. Animated GIF and animated WebP are live wallpapers exactly as much as `.mp4`/`.webm`/`.mkv`/`.mov` are. *(User correction during discussion; the initial framing wrongly treated "live" as a video-container property.)*
- **D-02:** Live wallpapers live in a `live/` subfolder inside each theme: `~/Pictures/Wallpapers/<theme>/live/`. Keeps the theme↔wallpaper association the whole pipeline is built on. — **Reversibility:** costly — the path is consumed by the picker's enumeration, `wallpaper.sh`'s auto-set, the last-wallpaper state validator and the frame-extraction path; moving it later touches all four.
- **D-03:** The picker's **image** pool stays at `-maxdepth 2`; `live/` gets its own **separate enumeration pass** merged into the list. Do NOT raise maxdepth globally — that would pull stray stills inside `live/` into the image pool.
- **D-04:** **mpvpaper plays everything in `live/`** — one backend, one lifecycle, one pause mechanism, one layer surface. awww keeps the static-image path. Chosen on proof-burden grounds after the user established the library will be roughly an even mix of video and GIF/WebP: capability-routing between awww and mpvpaper would mean proving criterion 1's hide path, the layer gate and the cut sweep **twice**, and `awww pause` is daemon-wide while mpv's pause is per-player, so the two hide paths would not even be symmetric. — **Reversibility:** costly — the owner's state machine, the gate and the cut sweep all assume a single backend.

### Live wallpaper — palette and lock screen

- **D-05:** Palette coupling is **Material-You-only**. Static presets keep their fixed palettes and ignore the live wallpaper for palette purposes (mirrors `wallpaper.sh`'s existing early-return for the two materialyou names, inverted).
- **D-06:** **`current.jpg` points at the extracted frame in EVERY mode**, not only Material You. Discovered during discussion: `hypr/.config/hypr/hyprlock.conf:50` reads `~/Pictures/Wallpapers/current.jpg` as the **lock-screen background**, so the frame is not merely a palette input — it is what you see on every unlock. Only the *palette* coupling is Material-You-only.
- **D-07:** The frame is written to `~/.local/state/theme/` as an **engine-owned file registered in `contract.json`**, with `current.jpg` repointed at it via `ln -sfr` (the existing `wallpaper.sh` idiom). `engine_owned_files` is the correct bucket per `lib/contract.sh:43-52` — it is written by something other than a matugen render pass and must survive `commit.sh`'s `rsync --delete`. Everything downstream (matugen, hyprlock, palette.json) keeps reading `current.jpg` unchanged.
- **D-08:** Extraction happens **at selection time, with a repair-on-missing guard** — `theme-apply` re-extracts only when the frame is absent or zero-byte. One `stat()` on the hot path; self-heals a wiped or freshly-installed state dir. *(Recommendation corrected mid-discussion: cached-only was initially recommended and is wrong — the state dir is disposable, so a wipe would surface as a wrong palette and a dangling lock screen with no gate catching it.)*
- **D-09:** Frame selection is a **fixed seek offset with fallback to frame 0**, plus a **recorded per-video offset override**. Rejected: sample-N-frames-and-pick-most-colourful — it selects for outlier frames (and via D-06 would be choosing the lock screen by a colour-variance metric), competes with matugen's own chroma scoring, is non-deterministic across ffmpeg/imagemagick versions against the reproducibility constraint, and needs its own test fixtures inside the cut-candidate phase. The per-video override exists specifically to solve the scene-change case that motivated the rejected option.
- **D-10:** Frame format is **PNG at source resolution**. Lossless because it feeds matugen's colour quantisation (JPEG artifacts shift extracted source colours on gradients) and hyprlock renders it full-screen. Both consumers sniff content, so the `.jpg` symlink name is harmless.
- **D-11:** `theme-doctor` gates the frame **conditionally** — required and non-empty only when the recorded choice names a `live/` entry; its absence is not a finding when the choice is a still.
- **D-12:** Static-preset auto-set **remembers per theme via the existing `last-wallpaper` state** — if the last pick for a theme was its live wallpaper, switching back lands it. **Security caution:** `wallpaper.sh`'s validator currently rejects any recorded value containing `/` as a deliberate T-05-07 mitigation. A `live/<name>` value needs that check **widened precisely, not removed**.
- **D-13:** If the selected live wallpaper is deleted or moved, fall back to **the theme's first still by sorted name and clear the recorded choice** — mirrors `wallpaper.sh`'s existing D-12 never-a-dead-end semantics.

### Live wallpaper — ownership, lifecycle and picker

- **D-14:** A **single wallpaper-visibility owner script** arbitrates the background layer. Every caller — picker, theme-apply, the power states, gaming mode — sends it an *intent*; nothing else starts or stops a player. Mirrors `waybar-visibility.sh`'s single-owner pattern proven in Phase 8 (D-03). — **Reversibility:** costly — every caller is written against the intent interface.
- **D-15:** mpvpaper is launched **`uwsm app --` from the owner**, only when a live wallpaper is actually selected. Matches how `autostart.lua` launches every other session process. No systemd unit (nothing new for the cut sweep); no `autostart.lua` entry (that file carries a documented no-new-entries prohibition).
- **D-16:** **Silent, and no MPRIS identity at all** — `--no-audio` plus suppression of mpv's media-player registration. Directly serves roadmap **standing constraint #4**: MPRIS is already double-consumed (waybar `mpris` + AGS `lib/media.ts`), and a third uncoordinated *writer* is not safe. A wallpaper loop must never appear as "now playing" or capture media keys.
- **D-17:** The picker shows **one merged list with live entries visibly marked** — a second enumeration pass merged in, image pool untouched.
- **D-18:** The picker's kitty-graphics **preview pane extracts the frame on first preview and caches it**, honouring the per-video offset from D-09. Warms the cache so selection is instant and shows the same frame that becomes the lock screen.
- **D-19:** The **awww live desktop preview starts the video on hover, debounced** with a ~250ms settle guard, serialising the kill of any prior instance. *(Grounded correction: `wallpaper-picker.sh:~272` binds the live preview to fzf's `focus:execute-silent(...)` with **no debounce**, and the live script backgrounds `awww img … &` fire-and-forget. That is harmless today because `awww img` is only IPC to a running daemon — no spawn, no surface creation. Hover-starting mpvpaper turns each focus event into spawn + Wayland layer surface + decoder init, unserialised. The objection is **lifecycle churn and orphan risk, not CPU** — the CPU claim made during discussion was unmeasured and should not be carried forward as fact.)*
- **D-20:** **Esc restores the exact prior state** — still or live — via a single "restore this" intent to the owner. Keeps the picker's existing non-destructive-cancel behaviour (`PREVIOUS_WALLPAPER`) and keeps the picker out of the player lifecycle.
- **D-21:** On login, the player is started **through `theme-apply`'s wallpaper step → owner**. `theme-init.sh` stays the thin caller D-01 documents it as. One path serves login, theme switch and manual pick — no login-only branch that only breaks at login.
- **D-22:** Play on **all outputs via `'*'`**. mpvpaper fans out internally, so this phase inherits none of the QS-03 per-screen limitation Phase 12 accepted as permanent. Host has one monitor (DP-1), so multi-output is untested but free.
- **D-23:** **mpvpaper is a hard dependency in `AUR_PKGS`**, inside `verify_packages`' hard-fail list. Verified: `pacman -Si mpvpaper` fails — it is AUR-only and pulls in mpv. AMB-02 is the requirement that mandates optional-guarded; AMB-01 does not, so only one guarded mechanism needs proving this phase.
- **D-24:** Decode path is **`hwdec=auto-safe` with software fallback**. No vendor-specific flag in a stowed dotfile — the host has nvidia-utils 610.57.04 and libva-nvidia-driver 0.0.17, but hardcoding that is exactly the host-only state the reproducibility constraint forbids.

### Live wallpaper — hide and power policy

- **D-25:** "Hide" means **pause the player, keep the process** — decoding stops (the actual point) while the process, its layer surface and its position in the loop survive. Instant resume, no spawn, no surface churn.
- **D-26:** **Use mpvpaper's native `-p/--auto-pause` and `-a/--auto-mode`, but verify them against the installed binary FIRST**, with the independent watcher scoped as a fallback only if verification fails. Research finding: mpvpaper already implements this — `-p` pauses when hidden, `-a` extends the trigger to "any window is `<FULL>` or `<MAX>`", which covers both criterion 1 and the maximize/occlusion case. **But** the mechanism is Wayland surface frame callbacks and upstream is explicit that it is *"at best a hack that works on some compositors… may not work as intended or at all"*; base auto-pause misses a normal window fully covering the wallpaper; and it is documented failing in the wild (GhostNaN/mpvpaper#12, Sway, unresolved). Hyprland 0.56.2 behaviour is **unverified** — standing constraint #2 applies. — **Reversibility:** reversible — the fallback watcher is already scoped.
- **D-27:** If a watcher is needed, it is an **independent wallpaper-fullscreen watcher**, reusing `waybar-fullscreen-watch.sh`'s proven shape (empirically confirmed `fullscreen>>1/0` framing, argv-list subprocess calls, headless early-exit) **as a template, not as a host**. *(User correction, and correct: MIG-06 commits v4.0 to retiring `waybar/` including its stow registration, install dependency, contract entries, layerrules and reload branches. Putting a wallpaper concern inside a waybar-named script would force the retirement to surgically extract a surviving feature from a dying package — precisely the "additive scaffolding drift" this phase's roadmap entry says it **Owns**. Two idle socket2 listeners cost ~10MB each and no measurable CPU; Hyprland serves multiple socket2 clients already.)*
- **D-28:** The wallpaper is additionally suppressed on: **gaming mode ON**, **idle**, and **reduced motion**, alongside the visibility-driven pausing.
- **D-29:** **Split by mechanism — mpvpaper owns `pause`, the owner owns lifecycle.** The owner never touches the pause property; it stops and starts the process for its own states. Two independent writers to one `pause` property is the exact two-sources-of-truth bug class Phase 8 already fixed once and D-03's single-owner rule exists to prevent (enable gaming mode, close the fullscreen window, and visibility logic would helpfully un-pause). **Consequence: no mpv IPC socket is needed at all** — no `--input-ipc-server`, no socket path to manage or clean up. **Trade recorded:** the owner's states restart the loop from the beginning; only fullscreen preserves position.
- **D-30:** Idle suppression hooks the **existing 300s dim listener**'s `on-timeout`/`on-resume` in `hypridle.conf`. Both directions come free, no new listener. Rejected the 120s idle listener: because the owner *stops* the process rather than pausing it, a 2-minute threshold would mean a full teardown and respawn on every brief pause in typing. Note `general { lock_cmd }` has **no unlock counterpart**, so a `listener` is the structurally correct hook for a resumable state.
- **D-31:** Reduced motion suppresses the live wallpaper **only at `motion-scale = "off"`**. The axis is three-valued (`off`/`normal`/`lively`), not boolean; `animations.lua` already resolves its token false at `off`, so a looping video would be the one thing still moving. Reads the same `~/.local/state/theme/motion-scale` file the rest of the pipeline uses.

### Dynamic cursors

- **D-32:** The repo's **pinned cursor theme moves to `rose-pine-hyprcursor`**, folded into this phase alongside AMB-02 (same surface, same install path, `generate.sh` touched once instead of twice). Requires changing `theme-engine/lib/generate.sh:166,171` which currently hardcodes `gtk-cursor-theme-name=Bibata-Modern-Classic` into both GTK settings files on every render, plus the `XCURSOR_THEME` export. **Scope note:** this is user-added scope, not in AMB-02's text.
- **D-33:** Install path is a **guarded attempt in `install.sh` plus a post-login completion helper**. `install.sh` runs the hyprpm step inside a warn-and-continue guard (satisfying criterion 2 literally, and provable by forcing the build to fail); the helper actually completes the build once a session exists. This is the only shape that both matches the criterion's wording and delivers a working plugin on a fresh machine. — **Reversibility:** reversible.
- **D-34:** Criterion 2's forced failure is injected by **pointing hyprpm at a bad plugin URL** — the real install path against a repository that cannot resolve or build, exercising the guard end to end. Matches the fault-injection style already used in 13-03 for the fisher/nvm/uv guards.
- **D-35:** The plugin is loaded via **`hl.plugin.load()` from a guarded repo config module, with the path resolved at runtime** rather than hardcoded. Grounded: hyprpm's artifact lives at `/var/cache/hyprpm/aorus/dynamic-cursors/dynamic-cursors.so` — root-owned and **username-scoped**, so a literal path would not reproduce on another machine or user. Avoids `autostart.lua` entirely (no-new-entries prohibition) and keeps loading declarative and inside the repo where the cut sweep can see it. Config must be wrapped in `if hl.plugin.dynamic_cursors then … end` per upstream, to avoid config errors when the plugin is not loaded.
- **D-36:** **Shake-to-find ships disabled by default.** Upstream ships it on, but at its default `threshold = 6.0` it fired on the user's ordinary pointer movement during live testing — a cursor that balloons unbidden is worse than no feature.
- **D-37:** The **mode (`tilt`/`rotate`/`stretch`) is an implementation-time decision settled at the phase's blocking human render gate**, not now. It cannot be compared live: `mode` is read once at plugin load and is not runtime-switchable (proven — see Live Verification below). The plan should ship the config block with all three trivially switchable so the operator judges them after one restart. Standing constraint #1 requires a blocking human render gate for every visual surface anyway.
- **D-38:** The criterion-3 cut sweep for the cursor half covers **repo references** (`stow.sh`, `install.sh`, config modules) **and the hyprpm artifact under `/var/cache/hyprpm`** (host-only state the reproducibility constraint disallows in spirit; removal needs sudo, so the sweep warns or prompts rather than acts). **Known gap, deliberately accepted:** `generate.sh`'s cursor-theme pin is NOT in sweep scope, so a mid-flight cut could leave it writing `rose-pine-hyprcursor` while `install.sh` no longer installs it — every theme render would then silently fall back to a stock cursor. Recorded so the planner sees it rather than rediscovers it.

### Claude's Discretion

- The owner script's name and placement (`waybar-visibility.sh` naming convention suggests `wallpaper-visibility.sh` under `hypr/.config/hypr/scripts/`).
- The IPC/socket client implementation shape — settled by convention, not preference: `socat` is **not installed**, `python3` and `jq` are, and `waybar-fullscreen-watch.sh` explicitly establishes the *"inline python3 idiom… stdlib networking only, zero new external binary dependency (the package gate stays honest)"*.
- Exact seek-offset default in D-09 and the debounce interval in D-19 (~250ms is a starting point, not a locked value).
- Which `live/` marker glyph the picker uses in D-17.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition and constraints
- `.planning/ROADMAP.md` §"Phase 17: Ambient Extras" — goal, the three success criteria, the "Owns: additive scaffolding drift" line
- `.planning/ROADMAP.md` §"Standing constraints" — **#1** human render-and-look gate, **#2** verify options against the installed binary, **#3** same-commit stow registration, **#4** additive-only coexistence incl. layer namespaces and the MPRIS third-writer rule
- `.planning/REQUIREMENTS.md` — AMB-01, AMB-02; Out of Scope entry "In-QML video decoding for animated wallpaper"; MIG-01/MIG-06 (waybar retires in v4.0 — the basis for D-27)
- `.planning/PROJECT.md` — core value, reproducibility constraint ("no manual host-only state")

### Wallpaper pipeline (AMB-01)
- `theme-engine/.config/theme-engine/lib/wallpaper.sh` — the auto-set function; D-11/D-12 semantics, the `-maxdepth 1` image allow-list, the T-05-07 last-wallpaper validator that D-12 must widen
- `theme-engine/.config/theme-engine/lib/contract.sh` §43-52 — `engine_owned_files` semantics; why D-07 uses that bucket
- `theme-engine/.config/theme-engine/contract.json` — the manifest D-07 adds to
- `theme-engine/.config/theme-engine/lib/commit.sh` — the `rsync --delete` that `engine_owned_files` protects against
- `hypr/.config/hypr/scripts/wallpaper-picker.sh` — enumeration (`maxdepth 1`/`2` image allow-lists), the kitty-graphics preview script, the `focus:execute-silent` live-preview binding (D-19), the `PREVIOUS_WALLPAPER` cancel path (D-20)
- `hypr/.config/hypr/hyprlock.conf` §50 — `path = ~/Pictures/Wallpapers/current.jpg`, the basis for D-06
- `hypr/.config/hypr/scripts/theme-init.sh` — the thin login caller referenced by D-21

### Single-owner and watcher patterns
- `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` — the socket2 listener shape D-27 uses **as a template, not a host**; empirically confirmed `fullscreen>>1/0` framing
- `hypr/.config/hypr/scripts/waybar-visibility.sh` — the single-owner intent pattern D-14 mirrors
- `hypr/.config/hypr/hypridle.conf` — the listener pattern and the 120/300/600/900/1800s thresholds behind D-30
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` — the gaming-mode state file and its runtime-only doctrine (D-28)
- `hypr/.config/hypr/config/autostart.lua` — the documented no-new-entries prohibition (D-15, D-35)

### Motion / reduced motion
- `theme-engine/.config/theme-engine/lib/motion.sh` — the `motion-scale` axis behind D-31
- `hypr/.config/hypr/config/animations.lua` — token resolving false at `motion-scale = "off"`

### Dynamic cursors (AMB-02)
- `https://github.com/VirtCode/hypr-dynamic-cursors` — install via hyprpm, the full config option set, the mandatory `if hl.plugin.dynamic_cursors then … end` guard
- `/usr/share/hypr/stubs/hl.meta.lua` §824 (`hl.config`), §949-951 (`HL.PluginNamespace`), §1314 (`HL.ConfigOpt` — note it has **no** `plugin` field)
- `theme-engine/.config/theme-engine/lib/generate.sh` §166,171 — the hardcoded `gtk-cursor-theme-name=Bibata-Modern-Classic` that D-32 changes
- `hypr/.config/hypr/hyprland.lua` §148-150 — `cursor { no_hardware_cursors = true }`, already set
- `.planning/research/PITFALLS.md` — the hyprpm ABI-coupling analysis, confirmed live this session
- `install.sh` §~600-660 — `verify_packages`' hard-fail design and the `|| echo "  ⚠ …"` warn-and-continue precedent D-33 follows

### Install / deploy
- `install.sh` — `PACMAN_PKGS`, `AUR_PKGS`, `AUR_HELPER` (paru), `verify_packages`
- `stow.sh` — `PACKAGES` array, the pre-create-before-stow idiom, the `current.jpg` seed at §452-456

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`waybar-visibility.sh` single-owner pattern** — the intent-based arbitration model D-14 copies wholesale.
- **`waybar-fullscreen-watch.sh`** — a working socket2 listener with confirmed event framing, headless early-exit, and argv-list subprocess discipline. Template for D-27's fallback watcher.
- **`wallpaper.sh`'s validated-candidate + best-effort idiom** — `|| true` on every step, fall back to the first sorted image when a recorded choice fails validation. D-08 and D-13 both extend it.
- **`wallpaper-picker.sh`'s kitty-graphics preview** with chafa fallbacks — D-18 hangs the video frame off this unchanged.
- **`contract.sh` + `contract.json`** — a single manifest already consumed by both `theme-doctor` and `theme-parity`, so D-07/D-11 get gating for free.
- **`quickshell-doctor`'s `hyprctl layers -j` coexistence check** — built in Phase 11 for exactly the standing-constraint-#4 question; extended rather than duplicated for mpvpaper's background-layer namespace.
- **`hypridle.conf` listeners** — already fan `on-timeout`/`on-resume` into an owner script; D-30 adds one line.
- **`install.sh`'s `|| echo "  ⚠ …"` warn-and-continue precedent** (swayosd/ollama enables, `kernel-module-verify`) — the shape D-33's guard follows.
- **13-03's fault-injection style** — the fisher/nvm/uv guards were *proven* by injecting failures, which is what D-34 does for criterion 2.

### Established Patterns
- **Image-extension allow-lists everywhere.** `wallpaper.sh:41` and `wallpaper-picker.sh:24/98/103` enumerate `jpg|jpeg|png|webp|gif` explicitly. Consequence: video files are *already* invisible to every existing enumerator with zero filter changes — but `.gif`/`.webp` are already claimed by the still path, which is why D-01/D-04 had to define live-vs-static by folder rather than extension.
- **Inline python3 for socket work**, stdlib only, "so the package gate stays honest".
- **Runtime-only compositor changes** — `gaming-mode-toggle.sh` never writes a config file; the theme engine owns on-disk config.
- **Engine-owned state files** are registered in `contract.json` so `commit.sh` and `theme-doctor` cannot drift.

### Integration Points
- `theme-apply` → wallpaper step → **new wallpaper-visibility owner** (login, theme switch, auto-set).
- `wallpaper-picker.sh` → owner (hover preview, commit, Esc restore).
- `hypridle.conf` 300s listener → owner (idle).
- `gaming-mode-toggle.sh` → owner (gaming mode).
- `motion-switch.sh` / `motion-scale` state → owner (reduced motion at `off`).
- `quickshell-doctor` → `hyprctl layers -j` assertion covering mpvpaper's namespace.
- `contract.json` → new engine-owned frame entry; `theme-doctor` conditional gate.
- `install.sh` → `AUR_PKGS` += mpvpaper (hard); guarded hyprpm block (soft); `rose-pine-hyprcursor`.
- `generate.sh` → cursor-theme pin change (D-32).
- A new guarded Lua config module under `hypr/.config/hypr/config/` → `hl.plugin.load()` + the `dynamic_cursors` block.

</code_context>

<specifics>
## Specific Ideas

**Live verification performed during this discussion** — all HIGH confidence, ground truth on this machine, and several of these overturn assumptions in the planning docs:

1. **Hyprland is 0.56.2**, not the 0.56.0 assumed throughout `ROADMAP.md` and `PITFALLS.md` (built from commit `efb5099`, tag v0.56.2, 2026-08-05). This matters specifically for AMB-02 — hyprpm pins plugin commits per Hyprland commit.
2. **`hyprpm` is genuinely hostile to unattended install**, confirmed by running it: it needs sudo for its state store (`[ERR] ensureStateStoreExists: Failed to run a superuser cmd`), then refuses all plugin operations until `hyprpm update` builds headers against the exact running commit (`✖ Headers outdated, please run hyprpm update`), which itself needs a full toolchain. **`cmake` was missing** on this machine (gcc/meson/ninja/git present) — a concrete `install.sh` provisioning gap.
3. **`hyprctl keyword` is dead under the Lua parser** — `"keyword can't work with non-legacy parsers. Use eval."` Runtime config must go through `hyprctl eval`.
4. **Plugin config syntax has an underscore/hyphen split**: the setter is `hl.config { plugin = { dynamic_cursors = { … } } }` (**underscore**), while the runtime option namespace is `plugin:dynamic-cursors:*` (**hyphen**). Four plausible-looking alternative forms were tested and silently did nothing — `hyprctl eval` always replies `ok`, so `hyprctl getoption`'s `set:` flag is the only reliable oracle.
5. **`mode` is fixed at plugin load time.** Setting it via `eval` updates the config value (`getoption` confirms `str: stretch`) while the plugin keeps rendering `tilt`. Toggling `enabled` off/on did not re-init it. This is the basis for D-37.
6. **A hyprcursor theme is NOT required** — the plugin deforms plain XCursor bitmaps fine. This was initially inferred to be the blocker and stated as proven; the user disproved it by observing tilt working on Bibata all along. `rose-pine-hyprcursor` was installed during that false lead; the user then chose to keep it (D-32). **Do not carry the "hyprcursor theme is a prerequisite" claim forward.**
7. **Shake-to-find works and is over-sensitive** at upstream's default `threshold = 6.0` — it fired on ordinary movement. Basis for D-36.
8. **ffmpeg 9.0 has `webp_anim` demuxer + decoder** and GIF demux/decode, so animated WebP should play through mpv. Verified at the ffmpeg level only — mpv/mpvpaper are not installed, so the end-to-end claim is one step removed and remains a research item.
9. **mpvpaper is AUR-only** (`pacman -Si mpvpaper` fails); **socat is not installed**; `paru` is the AUR helper; `jq`/`python3` present.

**Method note for downstream agents:** several recommendations in this discussion were wrong until checked against the installed binary or the actual repo file — the caching guard, the "performance" objection to hover-start, the `.mp4`-only assumption, the waybar-coupled watcher, and the hyprcursor prerequisite. Standing constraint #2 is not ceremony here; treat every option in this document as needing binary-level confirmation before it is built on.

</specifics>

<deferred>
## Deferred Ideas

- **`gaming-mode-toggle.sh` may be silently dead since the 13.1 Lua cutover.** It is documented as driving the compositor exclusively through `hyprctl keyword`, which now errors with *"keyword can't work with non-legacy parsers. Use eval."* — the same failure shape as the `dpms` calls in `hypridle.conf` that were silently dead from the cutover onward. **Not folded into this phase** — it is an existing-surface regression, not ambient-extras scope. File as its own `/gsd-debug`. *(If confirmed, D-28's gaming-mode suppression must not be built on top of a broken toggle.)*
- **Wallpaper parallax on workspace switch** — named in `research/FEATURES.md` as a cheap add-on once live wallpaper exists. New capability; belongs in v4.0.
- **mpvpaper slideshow mode (`-n/--slideshow`)** — a real mpvpaper capability (play the next video in a playlist every N seconds) that nothing in AMB-01 asks for. v4.0 candidate.
- **Removing `rose-pine-hyprcursor` if D-32 is reverted** — `paru -Rns rose-pine-hyprcursor`. Installed this session during the hyprcursor false lead, then deliberately kept.
- **Per-video audio opt-in** — considered and rejected under D-16; an audible wallpaper would need the MPRIS and volume story solved properly rather than suppressed.

</deferred>

---

*Phase: 17-ambient-extras*
*Context gathered: 2026-08-09*
