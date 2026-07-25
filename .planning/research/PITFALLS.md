# Pitfalls Research

**Domain:** Adding a Quickshell/QML shell layer + a spring-based cross-toolkit motion system to an existing, mature Arch + Hyprland rice (Hyprland 0.56.0) that keeps waybar, swaync, SwayOSD, wleave, walker/elephant and the AGS media applet running throughout.
**Researched:** 2026-07-26
**Milestone:** v3.0 Quickshell Foundation & Motion Language (supersedes the v1.0/v2.0-era `PITFALLS.md` this file replaces — those GTK/stow/theming findings are resolved and validated; see git history for the prior content)
**Confidence:** MEDIUM overall — Hyprland-version and package facts below are HIGH (verified directly on this machine); Quickshell/QML behavioral claims are LOW (single-source web search, cross-checked against 2-3 independent hits where noted) per this project's own "verify against the installed binary" rule (see PROJECT.md Key Decisions, hyprlock schema / walker exit-130 / wleave config precedents).

**Ground truth verified directly on this machine (2026-07-26), not a web claim:**
- `hyprctl version` → Hyprland 0.56.0, commit 36b2e0c, clean build.
- `pacman -Si quickshell` → **quickshell 0.3.0-2 is now in the official Arch `extra` repo** (not AUR-only as older web guidance assumes), depending on `qt6-base`, `qt6-declarative`, `qt6-svg`, `qt6-wayland`, `libpipewire`, `polkit`, `jemalloc`. `qt6-base`/`qt6-declarative` 6.11.1 are **already installed** on this machine (pulled in by `aylurs-gtk-shell` 3.1.2, i.e. AGS v3, which itself depends on Qt infrastructure).
- `hyprland-plugins`/`hyprexpo` are **not installed** — `pacman -Ss hyprexpo` returns nothing; hyprexpo is not a pacman package at all, it is installed via `hyprpm add https://github.com/hyprwm/hyprland-plugins` and compiled locally against the running Hyprland's headers.
- `hypr/.config/hypr/config/animations.conf` already defines 11 named bezier curves including Material Design 3 curves (`md3_standard`, `md3_decel`, `md3_accel`) and an `overshot`/`crazyshot`/`bounce` family — this is the exact file the Phase 12 token pipeline must own/regenerate, and it already proves this repo has hand-tuned bezier approximations of "springy" motion before any QML existed.
- The stale `eww-media-popup` layerrule lines called out in PROJECT.md tech-debt are **no longer present** in `windowrules.conf` (only script-level cache-path references to the string `eww` remain, e.g. `~/.cache/eww-media-player`) — apparently cleaned up since that debt was logged; worth re-confirming this in Phase 11 rather than assuming PROJECT.md's tech-debt line is current.

## Critical Pitfalls

### Pitfall 1: Quickshell built and populated before its input/focus model is proven on this exact build — the eww failure repeating in QML clothing

**What goes wrong:**
A dashboard drawer, panel, or overlay gets built in QML with real content (calendar, media controls, toggles) before anyone has clicked a button on a bare Quickshell `PanelWindow` on Hyprland 0.56.0. Quickshell *has* a full input/focus model (`WlrLayershell.keyboardFocus`, `HyprlandFocusGrab`, per-item `mask`/`Region` click-through) — architecturally sounder than eww 0.6.0 ever was — but that model has more moving parts than eww's, which is exactly what makes it possible to build something that *looks* interactive and silently isn't: a `mask` region that doesn't cover the actual clickable item, a `keyboardFocus` left at the default `None` on a surface with text input, or a focus-grab that isn't released so clicks outside the panel do nothing.

**Why it happens:**
Quickshell's input surface is genuinely richer than eww's (anchors, exclusive zones, `KeyboardFocus.{None,OnDemand,Exclusive}`, mask regions), so there is more configuration surface where "compiles and renders" and "the pointer can actually reach the button" diverge. The eww disaster happened because nobody asked the click question before building; Quickshell's greater API surface means there are now *several* independent click questions (keyboard focus, mouse focus, mask region, layer, monitor targeting) rather than one.

**How to avoid:**
Phase 11's viability gate must be a single, throwaway `PanelWindow` with: one anchored edge, a non-zero `exclusiveZone`, `keyboardFocus: KeyboardFocus.OnDemand`, one text field, one button wired to a visible side effect (e.g. write a file, flip a color), and a `HyprlandFocusGrab` that closes it on outside-click. A human clicks the button, types in the field, and clicks outside to dismiss — all three must work on Hyprland 0.56.0 before Phase 11 is marked passed. This mirrors the Phase 10 rule exactly ("a human-clicked test button at plan 2 with authority to STOP the phase") but must additionally cover keyboard input and outside-click dismissal, since those are the two axes eww never even got far enough to test.

**Warning signs:** Any Phase 12+ plan that adds QML widget *content* before Phase 11's gate has a dated pass/fail record with a human signature; a mask region defined once at panel creation time that isn't revisited when the QML layout changes.

**Phase to address:** Phase 11 (viability gate) — this is the phase's entire purpose. Re-verify narrowly whenever a later phase (14-17) adds a genuinely new interaction pattern (e.g. drag-to-reorder in the dashboard, a text-entry search in the workspace overview) rather than assuming Phase 11's one passing click generalizes to every future widget.

---

### Pitfall 2: Quickshell and the live GTK shell fight over layer-shell exclusive zones and layout shifts

**What goes wrong:**
`zwlr_layer_shell_v1` does not enforce namespace uniqueness or exclusive-zone coordination between clients — a positive exclusive zone from one client pushes tiled windows away from that edge; a second, uncoordinated client claiming the same or an adjacent edge either overlaps the first or triggers a visible reflow/"push" every time either client's zone changes (e.g. waybar hiding via the existing OLED-safe `waybar-visibility.sh`, or a new Quickshell dashboard drawer sliding in with its own exclusive zone). Because v3.0 explicitly keeps waybar live throughout, any new top/bottom-anchored Quickshell surface is a second exclusive-zone claimant on an edge waybar already owns.

**Why it happens:** Quickshell surfaces are additive by design this milestone (PROJECT.md: "v3.0 adds QML surfaces only and retires nothing"), so the natural implementation path is to give each new panel its own anchor without checking what already reserves that edge.

**How to avoid:** Before any Phase 14-16 panel claims `exclusiveZone` on top or bottom, run `hyprctl layers -j` with waybar visible and note its current reserved zone; new Quickshell drawers/panels should default to `exclusiveZone: 0` (overlay-only, occupying no reserved space, matching how the existing wleave/AGS/swaync overlays already behave) unless a specific feature genuinely needs to permanently shrink the usable screen area. Add a one-line assertion to `theme-doctor` or a new `layer-doctor` check: `hyprctl layers -j | jq` reports no two clients both holding non-zero `exclusiveZone` on the same edge.

**Warning signs:** Windows visibly resizing/jumping when a Quickshell surface opens or closes; `hyprctl layers -j` showing more than one non-zero-exclusive-zone client per edge.

**Phase to address:** Phase 14 (dashboard drawer, the first real QML surface) establishes the "overlay by default" convention; Phase 15/16 inherit and must not violate it.

---

### Pitfall 3: Two D-Bus service owners fight over MPRIS, notifications, or hardware media keys

**What goes wrong:** This project already routes MPRIS through a bash backend feeding the AGS media card (Phase 10) and waybar's mpris module. If a Quickshell dashboard drawer (Phase 14) or audio panel (Phase 15) independently queries MPRIS/PipeWire/BlueZ/NetworkManager over D-Bus without deferring to the existing `playerctld`-style "most recently active player" convention, two widgets can disagree about which player is "current," or a new Quickshell notification surface can attempt to claim `org.freedesktop.Notifications` — a single well-known bus name — while swaync already owns it, causing one of the two to silently fail to register (D-Bus behavior on a duplicate `.service` file offering the same name is undefined/first-registrant-wins).

**Why it happens:** Every one of MPRIS, notifications, network and Bluetooth state is broadcast over shared system/session D-Bus signals; nothing stops a second subscriber from listening, and nothing stops a second *implementer* of the same interface from trying to register — the failure is invisible until two clients are running side by side and disagree.

**How to avoid:**
- MPRIS: Quickshell widgets must read from the same active-player convention the bash backend/waybar module already use (i.e. treat `playerctld`'s proxy object, not a raw first-found player, as the source of truth) rather than independently enumerating `org.mpris.MediaPlayer2.*` names.
- Notifications: Quickshell must **never** implement the `org.freedesktop.Notifications` interface itself this milestone — swaync stays the sole notification daemon per the "no retirements in v3.0" rule. Any Quickshell notification-adjacent UI (e.g. surfacing counts in the dashboard) must be a *client* of swaync's state, not a competing server.
- Hardware media/volume/brightness keys: SwayOSD's libinput backend already claims these keys system-wide; a new Quickshell surface must not also bind `XF86Audio*`/`XF86MonBrightness*` in Hyprland config, which would double-fire the action (e.g. volume moving twice per keypress) or race on which client updates first.
- Add a concrete pre-flight check to Phase 15: `busctl --user list | grep -c freedesktop.Notifications` must be 1, and `qdbus`/`gdbus introspect` confirms swaync (not a new process) owns it, before any connectivity/audio panel plan is marked done.

**Warning signs:** Volume/brightness changing by more than one step per keypress; two different "now playing" surfaces showing different tracks simultaneously; a new notification popup appearing alongside swaync's for the same event.

**Phase to address:** Phase 14 (dashboard drawer, first MPRIS-touching QML surface) establishes the shared-state convention; Phase 15 (audio + connectivity panels) is the highest-risk phase for this pitfall since it adds PipeWire/NetworkManager/BlueZ D-Bus consumers displacing pavucontrol/nm-connection-editor/blueman.

---

### Pitfall 4: hyprexpo / hyprpm plugin breaks silently on the next Hyprland upgrade, or never installs unattended

**What goes wrong:** Hyprland plugins compile against Hyprland's internal C++ headers, which have no ABI stability guarantee across versions. The official `hyprwm/hyprland-plugins` repo works around this with an explicit `commit_pins` table in `hyprpm.toml` mapping exact Hyprland commit hashes to compatible plugin commits; `hyprpm` auto-selects the pinned revision for the *currently running* Hyprland build. Two concrete failure modes follow directly from this: (1) upgrading Hyprland (including via a routine `pacman -Syu`) ahead of a new pin being published breaks hyprexpo until `hyprpm update` catches up — which can be any amount of time, and is not this project's schedule to control; (2) `hyprpm` requires a running Hyprland session and a full local compiler toolchain (it builds the plugin as a local artifact, it is not distributed as a Hyprland-version-matched pacman binary the way `quickshell` now is) — this is fundamentally harder to make work unattended in `install.sh`'s container/fresh-install gate than any package currently in `PACMAN_PKGS`/`AUR_PKGS`.

**Why it happens:** Hyprland plugins are, by upstream design, tied to internal headers rather than a stable ABI — this is a known, documented tradeoff of the plugin system, not a bug, and it is structurally different from every other dependency this repo currently manages via pacman.

**How to avoid:**
- Treat the workspace-overview feature's dependency on hyprexpo (or the `hyprland-toplevel-export-v1` protocol directly, which is the lower-risk path — see Pitfall 5) as **optional and gracefully degradable**, exactly as PROJECT.md already flags it "research-gated." Concretely: `install.sh` must never hard-fail if `hyprpm add`/`hyprpm enable hyprexpo` fails; the feature detects plugin absence at runtime and either falls back to a QML-native window-thumbnail overview built on `hyprland-toplevel-export-v1` alone, or is skipped with a clear log line.
- Pin the plugin commit that was tested against 0.56.0 in a repo-tracked note (mirroring the `hyprlock`-schema-via-`strings` precedent: verify the installed binary/version, don't trust docs) and re-verify that pin any time `hyprland` is bumped in `install.sh`'s `PACMAN_PKGS`.
- Do not let the container reproducibility gate (D-34/D-36, unblocked as of v2.0 push) silently start requiring a compiler toolchain and a live Hyprland session just to satisfy an optional Phase 16 feature — keep hyprexpo's install step conditionally skippable in the same script.

**Warning signs:** `hyprctl plugin list` empty or missing hyprexpo after a routine system upgrade; `install.sh` failing (rather than warning) on a fresh container/VM because `hyprpm add` needs a running compositor that a headless install context doesn't have.

**Phase to address:** Phase 16 (workspace overview) is where this is decided — PROJECT.md already marks it "research-gated on the hyprexpo / `hyprland-toplevel-export-v1` plugin question." The recommendation from this research: **prefer `hyprland-toplevel-export-v1` (a Wayland protocol Quickshell has first-class support for, gated by Hyprland's own `PERMISSION_TYPE_SCREENCOPY` permission system and a `noscreenshare` window-rule opt-out) over hyprexpo (a compiled plugin with ABI-pinning risk) if the feature can be built without it**, since it avoids the entire compiled-plugin reproducibility problem. If hyprexpo's specific rendering (live GPU-accelerated overview compositing) turns out to be required, it must ship as the explicitly-optional path this project's own "ambient extras... first thing cut if the milestone runs long" precedent already establishes for lower-priority features.

---

### Pitfall 5: Hyprland's screencopy permission system silently blocks the workspace overview instead of erroring

**What goes wrong:** Hyprland gates both generic screencopy and the `hyprland-toplevel-export-v1` protocol behind its own permission system (`PERMISSION_TYPE_SCREENCOPY`), and individual windows can opt out entirely via a `noscreenshare` window rule. A Quickshell workspace-overview surface that requests toplevel thumbnails without the right permission grant, or that captures a window the user (or a prior config) marked `noscreenshare`, can end up rendering blank/black thumbnails rather than throwing a visible error — the same "config that silently does nothing" shape as the hyprlock 0.9.5 unknown-option failure this project already has a standing rule against.

**Why it happens:** Permission systems designed to prevent malicious screen-scraping are, by design, silent-by-default (deny without a loud error) rather than fail-loud, since a loud denial can itself leak information about what's running.

**How to avoid:** Before building the overview UI, verify with `hyprctl` (or the Hyprland permissions wiki page, cross-checked against `strings $(which Hyprland)` per this project's established binary-verification rule) exactly what permission grant Quickshell needs and confirm it's set in `ecosystem.conf`/permission config *and* that no existing window rule in this repo's `windowrules.conf` sets `noscreenshare` on a surface that should appear in the overview (e.g. accidentally on a regular app window from an old experiment).
- Build a one-line acceptance check into Phase 16: capture at least 3 concrete windows across 2 workspaces and assert (by eye, per the human render-and-look gate) that all 3 show real live content, not blank tiles.

**Warning signs:** Overview shows correct window *count* and *layout* but blank/placeholder thumbnails for some or all windows — this is the "mechanical gate green, visual gate red" shape from the Phase 6/8 UAT rejections, applied to a permission problem instead of a CSS problem.

**Phase to address:** Phase 16 (workspace overview).

---

### Pitfall 6: Spring-to-bezier fitting silently loses fidelity that nobody notices until side-by-side comparison

**What goes wrong:** A single `cubic-bezier(x1,y1,x2,y2)` is mathematically pinned to fixed endpoints (0,0)-(1,1) with exactly two free control points. It can fake *one* overshoot by letting a control point's y-value exceed [0,1] (this project's own `overshot`/`crazyshot`/`bounce` curves in `animations.conf` already do exactly this), but it structurally cannot express multiple oscillations, a settle/ring-down, or decoupled mass/stiffness/damping behavior the way a true spring (QML's native `SpringAnimation`, or libadwaita's `AdwSpringAnimation`) can. When the token pipeline (Phase 12) fits a bezier approximation to a spring definition for the GTK4/Hyprland targets, the fitted curve will visibly diverge from the QML original specifically on any spring tuned for a bouncy/high-energy feel — exactly the kind of tuning a "top-tier rice" motion language is likely to want somewhere.

**Why it happens:** "One motion language, many renderers" is architecturally correct for *color* (a discrete palette maps losslessly to any target), but motion is a continuous function, and only one of the three renderers (QML) can execute the actual physics model — the other two are compile targets that approximate it, by construction, not by mistake.

**How to avoid:**
- Set an explicit fidelity ceiling as a design decision, not an oversight: springs with damping ratios producing more than one visible oscillation should be *reserved for QML-native surfaces only* (Quickshell panels), while GTK4/Hyprland targets get a single-overshoot bezier fit or a critically-damped (no-overshoot) curve, decided per-token rather than trying to force-fit every spring everywhere.
- Where a spring must be approximated for GTK4 CSS, check whether the specific widget is libadwaita-authored (wleave, and potentially the AGS media card if migrated) — those can use `AdwSpringAnimation` directly in code for a real physics match instead of a CSS bezier fit, sidestepping the fidelity loss entirely for that subset of surfaces. Plain-CSS-styled GTK elements (most of waybar/swaync's styling) have no such escape hatch and must use the bezier compile target.
- Add a Phase 12 verification step that is a **human side-by-side render-and-look gate** (per the standing rule from Phase 6/8): play the same named motion token on a QML test surface and its GTK4/Hyprland fitted equivalent, side by side, and require a human sign-off that the fitted version doesn't look "wrong" — automated curve-fitting error metrics (least-squares distance between sampled points) can pass while the perceptual result still reads as sluggish or twitchy, exactly the class of failure mechanical gates already missed twice in this project.

**Warning signs:** A token that looks "springy/bouncy" in the QML dashboard drawer but "linear/flat" or "janky" in waybar/swaync/Hyprland window animations after the same nominal spring config is compiled to all three targets.

**Phase to address:** Phase 12 (token pipeline) must decide and document the fidelity ceiling and the fitting algorithm's acceptance criteria; Phase 13 (motion retrofit) is where the fitted curves actually get applied across existing surfaces and where the side-by-side render gate must run, once per retrofitted surface, not once for the whole phase.

---

### Pitfall 7: Hyprland silently ignores/mishandles a malformed fitted bezier curve emitted by the token pipeline

**What goes wrong:** Hyprland's `bezier =` directive previously crashed on non-float values in the 4 curve-generation points; a merged fix (upstream PR #6246) changed this to an error message rather than a compositor crash. What is *not* confirmed by available research is Hyprland 0.56.0's exact behavior on well-formed-but-semantically-odd input the fitting algorithm could plausibly emit — e.g. a fitted curve whose control points happen to coincide, or floats at the edge of the accepted range — and whether such input silently falls back to a default curve (the documented behavior class already established in this project for hyprlock 0.9.5's unknown-option handling) versus loudly erroring.

**Why it happens:** The token pipeline (Phase 12) is a code generator; a generator bug (e.g. a rounding error, a degenerate spring producing near-zero control-point separation) can emit syntactically valid but semantically broken bezier values that Hyprland may accept without complaint, producing animations that are subtly wrong rather than obviously broken — the config-silently-does-nothing failure mode this project already has a standing rule against for hyprlock.

**How to avoid:** Before Phase 12 ships the Hyprland compile target, directly verify current 0.56.0 behavior (not docs, not memory — per this project's own established rule) by feeding `hyprctl keyword animation bezier <name>, <deliberately-degenerate-values>` and confirming with `hyprctl animations` whether it's rejected, clamped, or silently substituted. Add this as a `theme-doctor`-style assertion: after every `theme-apply`/token regeneration, run `hyprctl animations -j` and assert every named bezier curve the pipeline emitted is present and reports the values that were generated (not a fallback default), the same "assert the config actually took" pattern already used for GTK3/GTK4 CSS parse-failure detection.

**Warning signs:** An animation that used to look distinctive (e.g. `md3_decel`) reverting to Hyprland's built-in default curve after a token regeneration, with no error printed anywhere.

**Phase to address:** Phase 12 (token pipeline) for the generator-side safeguard; Phase 13 (motion retrofit) for the regression assertion added to the existing `theme-doctor` gate family.

---

### Pitfall 8: No reduced-motion escape hatch anywhere in the new pipeline

**What goes wrong:** Neither QML/Quickshell, GTK4 CSS, nor Hyprland's `animation =`/`bezier =` config expose a standard OS-level "reduced motion" toggle equivalent to the web's `prefers-reduced-motion` media query. If the token pipeline treats motion as purely aesthetic and never threads a global "reduce/disable" flag through all three targets, the desktop has zero accessibility escape hatch and zero simple way to turn off animations for performance debugging (e.g. isolating whether a sluggish-feeling surface is an animation-tuning problem or something else).

**Why it happens:** None of the three target ecosystems provide this for free — it has to be deliberately designed into the single source-of-truth token schema, and it's easy to defer indefinitely since nothing forces the question the way a missing color token would (a missing color is visually obvious; a missing reduced-motion path is only obvious to someone who wants it).

**How to avoid:** Add a single boolean/enum token (e.g. `motion.enabled` or a duration multiplier) to the Phase 12 token schema from day one, threaded to: QML's `Behavior`/`SpringAnimation` `enabled` property or a duration multiplier, GTK4's `@keyframes`/transition durations (multiply by 0 or a near-0 epsilon), and Hyprland's global `animations { enabled = ... }` bucket (Hyprland already supports a top-level animations-off switch — cheaper to just gate the whole `animations {}` block than to zero every individual `animation =` line). Wire it to `theme-apply` as an optional flag (`theme-apply <name> --reduce-motion`) consistent with this project's existing single-entrypoint pattern, rather than a separate ad hoc mechanism.

**Warning signs:** No way to answer "is this slow because of animation duration or because of something else" without editing multiple config files by hand across three toolkits.

**Phase to address:** Phase 12 (token pipeline) — must be in the schema from the start, since retrofitting a reduce-motion axis after Phase 13's retrofit is complete means re-touching every surface a second time.

---

### Pitfall 9: Motion that reads fine in a one-off demo click but feels sluggish in daily repeated use

**What goes wrong:** A spring/curve tuned while reviewing a single transition in isolation (open the dashboard drawer once, watch it settle) can feel noticeably slow or heavy once it's the transition a user triggers dozens of times a day — durations and overshoot that read as "polished" on the fifth watch read as "in my way" on the five-hundredth. This is a known UX trap in motion design generally, and this project's own history shows the adjacent version of it already happened once: 09-04's fix log (`windowrules.conf`) records a "roll-in animation is still too fast and looks [wrong]" defect found only after real usage, root-caused via `hyprctl animations`, not caught by any one-shot manual look.

**Why it happens:** A single execution of an animation and the two-hundredth execution of the same animation are perceptually different experiences (novelty vs. habituation), and no mechanical gate or single human click can distinguish them — only actual daily use surfaces this class of pitfall, which is why it isn't caught by the render-and-look gate as currently scoped (a single click-and-look, not a usage-over-time check).

**How to avoid:** For any motion token applied to a high-frequency interaction (workspace switch, drawer open/close, notification appear — anything a user triggers many times per session, as opposed to a rare action like the power menu), bias tuning toward shorter durations and toward critically-damped/no-overshoot springs by default, reserving longer/bouncier motion for genuinely rare, "reward" moments. Treat the render-and-look gate as necessary but not sufficient for these specific tokens: add an explicit multi-day dogfooding note to the phase's UAT ("used daily for N days, still feels right") for the highest-frequency surfaces (workspace overview open/close in particular, since Phase 16 is exactly this kind of high-frequency interaction) rather than closing on a single click.

**Warning signs:** A motion that felt right at review time gets reported as "annoying" or "gets in the way" days into real use — this is the leading indicator this pitfall already produced once in this project (09-04).

**Phase to address:** Phase 13 (motion retrofit) sets the default duration/damping conventions for high- vs. low-frequency interactions; Phase 16 (workspace overview) is the single highest-frequency new surface in this milestone and should carry an explicit multi-day-use check before being declared complete, not just a render-and-look pass.

---

### Pitfall 10: Scaffolding drift repeats the eww cleanup cost if Quickshell is ever descoped mid-milestone

**What goes wrong:** The eww retirement (Phase 10) needed a follow-up task because inert references survived in `contract.json`, layerrules, `stow.sh`, `install.sh` and `reload.sh` after the toolkit itself was gone. v3.0 does not retire anything, but it *adds* a brand-new stow package (a `quickshell/` config tree) and Phase 17's "ambient extras" are explicitly the first thing cut if the milestone runs long — meaning this milestone can end with an *added-then-abandoned* half-built Quickshell feature (e.g. a Phase 17 surface started and cut) leaving exactly the same class of scattered dead references, just in the opposite direction (additive dead code instead of retirement dead code).

**Why it happens:** The "consumer-check before retiring a toolkit" rule (PROJECT.md, marked "Revisit — the check missed two inert layerrules") was written for the *retirement* direction; nothing in this project's current process explicitly checks for orphaned scaffolding left behind by a **descoped-before-completion** addition, which is the actual risk shape v3.0 introduces via Phase 17's explicit cut candidate.

**How to avoid:** Apply the stow-registration rule from day one of Phase 11 (register `quickshell/` in `stow.sh` in the same commit that creates it — this is the existing rule, just applied preemptively rather than retroactively), and if Phase 17 (or any phase) is cut mid-flight, run the same grep-every-consumer sweep used for eww's retirement (defwindow/script/autostart/matugen-template/layerrule equivalents: QML imports, `windowrules.conf` layer rules, `install.sh` package entries, `stow.sh` registration) specifically for anything that phase partially added, before closing the milestone.

**Warning signs:** `git grep -i quickshell` or `git grep -i qs\.modules` turning up references in `install.sh`/`stow.sh`/`windowrules.conf` to a feature that was never finished; a `quickshell/` stow package present but not listed in `stow.sh` (the exact AGS-package gap this project already hit once).

**Phase to address:** Phase 11 (register the new stow package immediately, don't wait). Whichever phase is actually cut (most likely 17, per PROJECT.md's explicit framing) must run the consumer-check sweep as part of its close-out, not defer it to milestone-close reconciliation (the same "bookkeeping lagged the code" inefficiency logged in the v2.0 retrospective).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|--------------------|-----------------|------------------|
| Giving a new Quickshell panel a non-zero `exclusiveZone` "to be safe" instead of overlay-only | Guarantees the panel never gets occluded | Permanently shrinks usable screen area and creates a second exclusive-zone claimant alongside waybar, risking layout-shift bugs (Pitfall 2) | Only for a surface truly meant to be always-visible and permanent, decided deliberately — never as a default |
| Fitting every spring token to a bezier for GTK4/Hyprland with a single generic algorithm and no per-token review | Fast, mechanical, "one pipeline" purity | Springy/bouncy tokens degrade silently on non-QML targets (Pitfall 6) with no automated way to detect the perceptual loss | Acceptable only for critically-damped (no-overshoot) tokens where bezier fitting is lossless in practice; bouncy tokens need the human side-by-side gate |
| Wiring hyprexpo as a hard dependency of the workspace overview instead of an optional/degradable path | Simpler code, one rendering path | Reproducibility (fresh install / container gate) breaks whenever the Hyprland-hyprexpo pin lags an upgrade, and unattended install can't compile a plugin the way it can `pacman -S` a package (Pitfall 4) | Never, per this project's existing reproducibility constraint — must always degrade gracefully |
| Skipping the multi-day dogfooding check on high-frequency motion tokens and closing on the single render-and-look click | Faster phase close | Repeats the exact 09-04 "looked fine, felt wrong in daily use" pattern (Pitfall 9) | Acceptable only for genuinely low-frequency interactions (power menu, rare dialogs); never for workspace-switch-class frequency |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|--------------|------------------|--------------------|
| MPRIS (Quickshell dashboard vs. existing bash backend/waybar mpris module) | New QML widget independently enumerates `org.mpris.MediaPlayer2.*` and picks "first found" | Read the same `playerctld`-proxied "most recently active" player state the existing backend already uses |
| Notifications (swaync vs. any Quickshell-native popup) | Quickshell surface implements its own `org.freedesktop.Notifications` server | Quickshell only ever consumes/displays swaync's existing state; swaync remains the sole D-Bus name owner this milestone |
| Hardware media/volume/brightness keys (SwayOSD vs. a new Quickshell control) | A new panel adds its own `XF86Audio*`/`XF86MonBrightness*` Hyprland binds | Leave SwayOSD's libinput-backend service as sole key-handler; Quickshell surfaces call the same `swayosd-client`/PipeWire APIs on click, they don't re-bind the physical keys |
| Layer-shell exclusive zones (Quickshell panels vs. waybar) | New panel claims a permanent exclusive zone without checking what waybar already reserves | `hyprctl layers -j` before adding any new non-zero exclusive zone; default new Quickshell surfaces to overlay (zero exclusive zone) |
| Hyprland plugins (hyprexpo via hyprpm) | Treating a plugin like a normal pacman dependency in `install.sh` | Make the install step optional/non-fatal, pin to a verified-compatible commit, and provide a protocol-only (`hyprland-toplevel-export-v1`) fallback path that needs no compiled plugin |
| Global shortcuts (Quickshell's Hyprland-specific `GlobalShortcut` type vs. existing `bind=` entries) | New QML shortcut registered for a key combo already bound in Hyprland config | Grep existing `hypr/.config/hypr/config/*.conf` binds before assigning any Quickshell `GlobalShortcut` key; note the documented Hyprland bug where the `e` (repeat) bind flag combined with GlobalShortcuts can cause indefinite repeat-trigger even after key release — avoid that flag combination entirely |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Eagerly instantiating every QML component for every dashboard section at startup instead of using `Loader` | Elevated idle memory/CPU from a long-running Quickshell process even when most panels are closed | Use Quickshell's documented `Loader`-based lazy instantiation pattern for anything not always-visible (per-panel content, popovers) | Noticeable once more than 2-3 heavy panels (dashboard, audio mixer, connectivity, overview) are all resident simultaneously |
| A single long-running QML process accumulating state across suspend/resume cycles | Real-world reports (end-4/dots-hyprland) of high CPU/RAM and audio-service interaction specifically around suspend/resume | Test explicitly through at least one suspend/resume cycle during Phase 11's viability gate, not just a fresh-boot click test | First laptop suspend/resume after the shell has been open for a while |
| A chat/AI-style feature accumulating unbounded QML object graphs (reported memory leak in a comparable dotfiles project's AI sidebar) | Steady memory growth, eventually one core pegged at 100% | Not directly in v3.0 scope (no AI sidebar planned), but any Phase 14 dashboard widget that streams/accumulates data (e.g. live system resource graphs) should cap history length rather than growing an array indefinitely | Any widget that appends to a QML ListModel/array per tick without a cap |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Granting the workspace-overview feature broad/always-on screencopy permission rather than the minimum `hyprland-toplevel-export-v1`-scoped grant | Any compromised or buggy QML surface with that permission could capture arbitrary window content, not just what the overview needs | Scope the permission grant narrowly in `ecosystem.conf`/Hyprland permission config to only the overview process, and confirm `noscreenshare` window rules from other features (e.g. a password manager, if ever added) are respected, not silently bypassed |
| A new Quickshell `GlobalShortcut` silently shadowing an existing security-relevant bind (e.g. the lock-screen keybind) | A key that used to lock the session stops doing so because a new Quickshell global shortcut claimed it first | Explicitly grep and diff all existing Hyprland binds against any new Quickshell `GlobalShortcut` registration before shipping, as part of the same regression sweep this project already runs after keybind changes (the ~48-bind sweep precedent from Phase 7) |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-------------------|
| Two "now playing" surfaces (waybar mpris + new Quickshell dashboard media control) disagreeing on current track/player | Confusing, looks broken even though each individual surface is technically correct | Both read from the same active-player proxy state; treat this as one logical data source with two renderers, same pattern as the color/motion token pipeline itself |
| A dashboard drawer or overview that opens/closes with different exclusive-zone/anchor behavior on each monitor in a multi-monitor setup | Panel appears on the wrong monitor, or at inconsistent positions, breaking the "instantly and consistently" core value this whole project is built around | Explicitly test the viability gate and every new panel across the actual multi-monitor configuration this machine runs, not just a single-monitor dev check |
| Motion tuned to feel great once, but tiring on the two-hundredth repetition | Users perceive the desktop as "trying too hard" or "in the way" over time even though nothing is functionally broken | Default high-frequency interactions to short/critically-damped motion; reserve pronounced springiness for rare, deliberate moments (Pitfall 9) |

## "Looks Done But Isn't" Checklist

- [ ] **Quickshell viability gate:** Often missing keyboard-input and outside-click-dismiss testing — verify a human typed into a field and dismissed via outside click, not just clicked one button (Pitfall 1)
- [ ] **Token pipeline motion fitting:** Often missing a side-by-side QML-vs-GTK4/Hyprland perceptual comparison — verify a human watched both renderings of the same token back to back, not just that curve-fitting error metrics passed (Pitfall 6)
- [ ] **Workspace overview:** Often missing a check that captured thumbnails are live content, not blank/placeholder tiles from a silently-denied permission — verify by eye across at least 3 real windows on 2+ workspaces (Pitfall 5)
- [ ] **hyprexpo dependency:** Often missing a documented, tested fallback path when the plugin fails to install/build — verify `install.sh` completes (with a warning, not a failure) when `hyprpm add` is forced to fail (Pitfall 4)
- [ ] **New Quickshell stow package:** Often missing `stow.sh` registration in the same commit it's created — verify with `grep quickshell stow.sh` before the first commit that adds `quickshell/` is closed (Pitfall 10, repeating the AGS gap)
- [ ] **Reduced-motion token:** Often entirely absent by design, not oversight-then-caught — verify the Phase 12 token schema has a `motion.enabled`/reduce-motion axis before any surface is retrofitted (Pitfall 8)
- [ ] **MPRIS/notifications D-Bus ownership:** Often missing an explicit single-owner check — verify `busctl --user list | grep -c freedesktop.Notifications` is exactly 1 after any Quickshell surface is added (Pitfall 3)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|-------------------|
| Quickshell input/focus failure discovered after real content is built (Pitfall 1) | HIGH (mirrors the full eww rebuild cost) | Same recovery this project already executed once: stop the phase immediately per the fail-fast gate's authority, do not attempt to patch around a structural input failure, and treat toolkit swap/redesign as the only real fix — but this should be near-zero-probability if the Phase 11 gate is actually run before Phase 14 |
| hyprexpo breaks after a routine Hyprland upgrade (Pitfall 4) | LOW if built as optional from the start; HIGH if wired as a hard dependency | If optional: `hyprpm update`/reinstall and move on. If hard-dependency (the mistake): the workspace overview is unusable until fixed, potentially blocking an unrelated Hyprland security update the user needs |
| Two D-Bus service owners conflict (Pitfall 3) | LOW | Identify and stop the newer/incorrectly-added service claiming the shared name; this is a config/autostart fix, not a rebuild |
| Spring-to-bezier fidelity loss discovered late, after Phase 13's retrofit is already applied everywhere (Pitfall 6) | MEDIUM | Re-tune the specific offending tokens' damping ratios toward critically-damped defaults for non-QML targets, rather than re-deriving the whole fitting algorithm; scoped to the tokens actually flagged, not a full retrofit redo |
| A cut Phase 17 feature leaves scaffolding drift (Pitfall 10) | LOW if caught at phase close; MEDIUM if caught only at milestone close | Run the same consumer-check grep sweep used for eww's retirement, scoped to whatever the cut phase partially added |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|-----------------|
| 1. Quickshell input/focus structural failure (eww recurrence) | Phase 11 (viability gate) | Human clicks a button, types in a field, and dismisses via outside-click on a bare `PanelWindow` on Hyprland 0.56.0 before any content is built; gate has explicit STOP authority |
| 2. Layer-shell exclusive-zone/layout-shift conflicts with waybar | Phase 14 (dashboard drawer, first real QML surface) | `hyprctl layers -j` shows at most one non-zero-exclusive-zone client per edge; new panels default to overlay (zero exclusive zone) |
| 3. D-Bus/MPRIS/notification/hardware-key double-handling | Phase 14 (MPRIS) and Phase 15 (audio/connectivity, highest risk) | `busctl --user list | grep -c freedesktop.Notifications` == 1; both "now playing" surfaces show the same track/player simultaneously; volume/brightness keys move exactly one step per press |
| 4. hyprexpo/hyprpm plugin ABI + unattended-install risk | Phase 16 (workspace overview) | `install.sh` completes (warns, does not fail) with hyprpm forced to fail; feature has a documented fallback or is skippable |
| 5. Screencopy permission silently blocking captures | Phase 16 (workspace overview) | Human confirms live (non-blank) thumbnails across 3+ windows, 2+ workspaces |
| 6. Spring-to-bezier fidelity loss | Phase 12 (token pipeline, sets fidelity ceiling) / Phase 13 (retrofit, runs the gate) | Human side-by-side render-and-look comparison of the same token on QML vs. GTK4/Hyprland targets, per retrofitted surface |
| 7. Hyprland silently substituting a default curve for a malformed fitted bezier | Phase 12 (generator safeguard) / Phase 13 (regression assertion) | `hyprctl animations -j` after every token regeneration confirms emitted curve values match the generator's output, not a fallback |
| 8. Missing reduced-motion escape hatch | Phase 12 (token pipeline schema) | `theme-apply <name> --reduce-motion` (or equivalent) demonstrably shortens/disables animation across all three targets |
| 9. Motion that's fine once, sluggish in daily repeat use | Phase 13 (sets duration/damping conventions) / Phase 16 (highest-frequency new surface) | Multi-day dogfooding note in UAT for high-frequency surfaces, not just a single render-and-look click |
| 10. Additive scaffolding drift if a phase is cut mid-flight | Phase 11 (stow registration on day one) / whichever phase is actually cut (likely 17) | `grep quickshell stow.sh` passes from the first commit; a consumer-check sweep runs at the cut phase's close, not deferred to milestone close |

## Sources

**Direct system verification on target machine (HIGH confidence — ground truth, not a web claim):** `hyprctl version`; `pacman -Q`/`-Si` for `hyprland`, `quickshell`, `qt6-base`, `qt6-declarative`, `aylurs-gtk-shell`, `waybar`, `swaync`, `swayosd`, `wleave`, `walker`, `elephant`, `hyprland-plugins`; `pacman -Ss hyprexpo`; repo inspection of `hypr/.config/hypr/config/animations.conf` and `windowrules.conf`.

**Web search (LOW confidence, single-source unless noted, per this project's own "verify against installed binary/schema" precedent from PROJECT.md — treat every claim below as needing local re-verification before being relied on in a plan):**
- "Quickshell QML Hyprland layer-shell PanelWindow exclusive zone anchors keyboard focus grabFocus" — Quickshell docs (`quickshell.org/docs`), `hyprwm/Hyprland` issue #4968
- "Quickshell QML hot reload errors silent failure debugging" — Quickshell docs, `caelestia-dots/shell` issue #647, `end-4/dots-hyprland` issue #1757
- "Quickshell multi-monitor Hyprland memory CPU usage" — Quickshell FAQ/docs, `end-4/dots-hyprland` issue #2320
- "Quickshell Qt6 version requirement install Arch Linux" — Arch package page for `quickshell`, `quickshell-git` AUR page, Quickshell install docs
- "Quickshell PanelWindow WlrLayershell click through mouse input mask QML" — Quickshell docs, `hyprwm/Hyprland` issue #4968
- "Quickshell waybar together layer shell namespace exclusive zone conflict" — Quickshell docs, wayland.app wlr-layer-shell protocol page, waybar manpage
- "multiple MPRIS clients playerctld conflict" — `altdesktop/playerctl` issue #161, ArchWiki MPRIS page
- "org.freedesktop.Notifications name taken two notification daemons" — dunst FAQ, ArchWiki Desktop notifications page
- "hyprpm hyprexpo plugin ABI Hyprland version mismatch" — `hyprwm/hyprland-plugins` issues #107/#175, `hyprwm/Hyprland` discussion #12232, `hyprland-plugins/hyprpm.toml`
- "hyprland-toplevel-export-v1 protocol window thumbnails workspace overview" — wayland.app protocol page, `hyprwm/Hyprland` discussion #13332, Quickshell BUILD.md/DeepWiki, Hyprland Permissions wiki page
- "spring animation cubic-bezier approximation overshoot limitations" — joshcollinsworth.com easing-curves blog, joshwcomeau.com spring-physics articles
- "GTK4 CSS transition animation limitations spring physics" — joshwcomeau.com, libadwaita `Adw.SpringAnimation`/`Adw.Animation` docs (gnome.pages.gitlab.gnome.org)
- "Hyprland bezier config invalid curve fallback" — `hyprwm/Hyprland` PR #6246
- "Quickshell reduced motion accessibility" — no Quickshell-specific source found; general MDN/CSS-Tricks `prefers-reduced-motion` background only
- "Quickshell global shortcut Hyprland keybind conflict" — Quickshell `Quickshell.Hyprland/GlobalShortcut` docs, `hyprwm/Hyprland` issue #8904

---
*Pitfalls research for: v3.0 Quickshell Foundation & Motion Language milestone*
*Researched: 2026-07-26*
