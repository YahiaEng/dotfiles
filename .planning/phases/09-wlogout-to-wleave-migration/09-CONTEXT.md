# Phase 9: wlogout to wleave Migration - Context

**Gathered:** 2026-07-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace wlogout with wleave (GTK4, AUR `wleave` 0.7.1) as the power menu, eliminating the GTK3 whole-stylesheet-discard failure class (the WLOG-01 blocker), and re-deliver the power menu as a redesigned, pipeline-themed surface — six frosted capsules over a dimmed desktop — with no loss of the six audited power actions. Migration is a full atomic swap: every wlogout touchpoint (stow package, wrapper script, keybind, waybar on-clicks, elephant menu entry, layerrules, matugen template, contract.json, theme-doctor/parity/stress-test references, install.sh, stow.sh) moves to wleave in one cutover. The phase closes with a blocking human render-and-look gate — the compensating control for Phase 6's lesson that every automated gate can pass while the surface is visibly broken.

Not in scope: any other surface's theming, the swaync control-center fixes (open todo, separate work), a cross-app animation language (POLISH-01, deferred), and compositor-global blur strength (unfixable by any layer-shell client — documented in ROADMAP.md).

</domain>

<decisions>
## Implementation Decisions

### Visual design (six frosted capsules)
- **D-01:** Layout carries over from Phase 6's approved center bar — one horizontal row of six glyph buttons at true vertical center of the screen — but the surface is upgraded, not ported: GTK4 transparent window + Hyprland `layerrule = blur` (the AGS media popup frost technique; requires the 10-06 finding's explicit `window { background-color: transparent; }`).
- **D-02:** Each button is its own discrete frosted capsule (not one shared card): rounded squares ~96px with large corner radius (~20–24px, AGS-card radius language), ~24px gaps so each capsule reads as its own island.
- **D-03:** Per-action color identity (floating-waybar rainbow language), applied as **tinted frost + on-color glyph**: capsule background is the action's container color at translucent alpha; glyph uses the matching `on_*_container` role. This is the M3 pairing that avoids the 08-16 light-preset illegibility failure (colored glyph on neutral translucent pill ≈ 2–3:1 contrast — never do that).
- **D-04:** Six distinct hues, one per capsule. Material You yields only ~4 native hues, so derive 2 extra with GTK CSS `mix()` — the Phase 8 vertical-bar technique (08-14 durable finding: `mix()` works in `@define-color`, verified via theme-doctor non-empty-provider).
- **D-05:** Capsule order left→right is a severity gradient: lock, logout, suspend, hibernate, reboot, shutdown — destructive actions grouped at the far end.
- **D-06:** Rest state: 1px hairline border in each capsule's own hue at reduced alpha.
- **D-07:** Backdrop: full-screen dim scrim behind the capsules. Starting strength ~40% black; exact alpha is tuned live at the visual checkpoint on both light and dark presets (Claude's discretion within the gate).
- **D-08:** Hover/aim feedback (keyboard focus renders identically to hover): tint alpha increases, border brightens/glows in the action hue, capsule scales up slightly (~5–8%), and the action name (name only, no key hint) fades + slides up into place below the capsule.
- **D-09:** Glyphs: refresh the set (do not blindly carry the Phase 6 six). New glyphs must be cmap-verified against the installed Nerd Font before use — the Phase 6/8 discipline; never trust cheat-sheet codepoints, and never let the edit tool store PUA glyphs (08-16: they silently become empty strings — write real UTF-8 codepoints).
- **D-10:** Animations: staggered pop/slide-in entrance, left-to-right ~30–40ms offsets, total under ~350ms; exit is a reverse-stagger wave on dismissal. On action selection the command must fire immediately — exit animation must never delay the actual power action.

### wlogout retirement (atomic swap)
- **D-11:** Full removal, single cutover: the same plan/commit that lands working wleave deletes the `wlogout/` stow package, removes `wlogout` from install.sh PACMAN_PKGS and stow.sh PACKAGES, deletes the matugen `[templates.wlogout]` entry, and replaces the wlogout layerrules. No transition period, no fallback engine. Grep for `wlogout` must come back empty (excluding .planning/ history) after the swap.
- **D-12:** Render target renamed honestly: `wlogout.css` → `wleave.css` across matugen config.toml, contract.json, theme-doctor's CSS-sheet list, theme-stress-test REPRESENTATIVE_FILES, and the wleave stylesheet's `@import`. Contract stays at the same file count (one target swapped, not added).
- **D-13:** Package: AUR `wleave` 0.7.1-1 release (NOT `wleave-git` — repo precedent: eww stable approved, eww-git permanently refused). Added to install.sh AUR_PKGS; human package-legitimacy gate at execution time per Phase 4/8 precedent.

### Render-and-look verification
- **D-14:** Primary gate is a blocking human visual checkpoint: the executor opens wleave live, captures grim screenshots as phase-artifact evidence, and the user approves on sight before the plan may complete (Phase 8/10 checkpoint pattern). Automated parse/token gates alone can NOT close this phase — that is exactly how WLOG-01 shipped broken.
- **D-15:** Visual gate coverage: one dark preset, one light preset, plus a live theme switch to prove hot re-theming of the menu (Phase 10 slider-verification pattern; wleave is spawn-per-open so "re-theme" may mean reopen-after-switch — verify what the reload step needs).
- **D-16:** Automated regression guard: add `wleave.css` to theme-doctor's GTK4 non-empty-provider check (one-line extension of the 06-19 pattern). GTK4 exposes no parse-error signal via PyGObject on this install, so the non-empty-provider assertion is the load-bearing check.
- **D-17:** Power-action UAT: live spot-check lock + suspend + logout from wleave. Shutdown/reboot are trusted by command-string parity — the layout must carry the Phase 4-audited action strings byte-identically (`hyprshutdown --post-cmd`, `cliphist wipe` prefixes, bare systemctl for suspend/hibernate).

### Behavior & entry points
- **D-18:** Open-only semantics: the entry points launch wleave; there is no toggle. Dismissal is Esc AND click-away on the scrim (AGS popup convention). The old pgrep/pkill toggle logic is dropped.
- **D-19:** Per-button keyboard shortcuts carry over as-is: l=lock, e=logout, u=suspend, h=hibernate, s=shutdown, r=reboot (wleave layout format supports the same keybind field). They stay undocumented in the UI (labels show name only).
- **D-20:** No confirmation dialogs on any action, including shutdown/reboot — the menu is the deliberate step; severity ordering + distinct colors are the misclick mitigation.
- **D-21:** Wrapper script renamed `wlogout.sh` → `wleave.sh` (honest naming, consistent with D-12). All three call sites repointed in the atomic swap: keybinds.conf `Super+Shift+Q` (bind itself unchanged), waybar `modules.jsonc` + `config-floating.jsonc` on-clicks, elephant `menus/main.toml` power entry. keybind-doctor descriptions updated to match.
- **D-22:** Multi-monitor: scrim dims ALL monitors; capsules render on the focused monitor. (Researcher: verify wleave's native multi-output behavior and what flags/config express this.)
- **D-23:** Launch-failure guard: wleave.sh checks spawn/exit result and fires a notify-send error on failure (capture-scripts `command -v` guard pattern). No fallback menu implementation.

### Claude's Discretion
- Exact scrim alpha, capsule paddings, border widths, corner radius, easing curves, stagger timings — tuned live at the visual checkpoint within the decided design language.
- Which two derived `mix()` hues and the exact hue→action assignment across the six capsules (validate contrast per-preset).
- New glyph selection (cmap-verified) and glyph point size.
- Cursor shape over capsules, arrow-key navigation details, and any wleave-native niceties that don't contradict decisions above.
- How the entrance/exit animations are implemented (wleave native options vs GTK4 CSS transitions) — whichever wleave 0.7.1 actually supports; if reverse-stagger exit is infeasible without delaying actions, degrade to a fast fade and note the deviation.
- Layerrule specifics (namespace, blur, ignorealpha/ignorezero thresholds) for wleave's layer surface.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — WLOG-01 (re-delivered on a new engine); active migration requirement
- `.planning/ROADMAP.md` §Phase 9 — goal, the GTK3-vs-GTK4 stylesheet-discard rationale, the blur-is-compositor-global warning, the three carried Phase 6 findings (content-box sizing, no vertical label centering, gates-passed-while-broken), and the migration-surface inventory

### Surfaces being replaced (read before deleting)
- `wlogout/.config/wlogout/layout` — six audited action strings (must carry over byte-identically, D-17) + keybind letters (D-19)
- `wlogout/.config/wlogout/style.css` — current pipeline-themed stylesheet; `@import` pattern to replicate
- `hypr/.config/hypr/scripts/wlogout.sh` — geometry derivation (content-box math, focused-monitor logical-size margins) and its embedded hard-won GTK sizing lessons; becomes `wleave.sh` (D-21) with open-only semantics (D-18)
- `hypr/.config/hypr/config/windowrules.conf` (~lines 184–229) — wlogout layerrules incl. the uniform-alpha scrim / ignore_alpha tuning notes; replaced by wleave rules

### Entry points to repoint (D-21)
- `hypr/.config/hypr/config/keybinds.conf` — `Super+Shift+Q` bind (line ~26); keybind-doctor description parity required
- `waybar/.config/waybar/modules.jsonc` (~line 256) + `waybar/.config/waybar/config-floating.jsonc` (~line 82) — power-button on-clicks
- `elephant/.config/elephant/menus/main.toml` (~line 35) — power menu entry; remember the 07-05 stow-parity lesson if new files are added to an already-stowed package

### Theme pipeline (rename wlogout→wleave, D-12)
- `matugen/.config/matugen/config.toml` — `[templates.wlogout]` block (lines ~46–48)
- `matugen/.config/matugen/templates/wlogout-colors.css` — template to rename/rewrite for the capsule design
- `theme-engine/.config/theme-engine/contract.json` — `wlogout.css` entry (line ~7)
- `theme-engine/.config/theme-engine/theme-doctor` — GTK3 sheet list (line ~205) and the GTK4 non-empty-provider check to extend (D-16)
- `theme-engine/.config/theme-engine/theme-stress-test` — REPRESENTATIVE_FILES (line ~291)

### Reproducibility
- `install.sh` — `wlogout` in PACMAN_PKGS (line ~233) out; `wleave` into AUR_PKGS (D-13, human legitimacy gate)
- `stow.sh` — `wlogout` in PACKAGES (line ~38) out; wleave package in
- `verify/` container gate — must stay green after the swap (origin/main push-authorization blocker noted in STATE.md still applies to container reruns)

### Design-language references (the frost/capsule vocabulary)
- `ags/` media applet SCSS + `.planning/phases/10-ags-media-applet/` summaries — frosted-card language, GTK4 transparent-window blur prerequisite (10-06 durable finding), GTK4 slider/palette-var lessons
- `waybar/.config/waybar/style-athena.css` — capsule language + "chroma = state" precedent
- `waybar/.config/waybar/style-vertical.css` + Phase 08-14 summary — the `mix()` derived-hue technique (D-04)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `wlogout-colors.css` matugen template + state-dir `@import` pattern — same plumbing, renamed target (D-12); no new pipeline mechanism needed
- AGS media popup blur recipe: `window { background-color: transparent; }` + Hyprland layerrule (blur + ignorealpha) — the exact GTK4 frost prerequisite for D-01
- Phase 8 `mix()` hue derivation in `@define-color` — proven GTK CSS technique for D-04's two extra hues
- grim/hyprshot screenshot tooling — checkpoint evidence capture (D-14)
- keybind-doctor + theme-doctor + theme-parity + theme-stress-test — all four gates touched by the rename sweep, all rerunnable

### Established Patterns
- Blocking human visual checkpoint with screenshot evidence (Phases 8/10) — this phase's primary gate (D-14)
- AUR human package-legitimacy gate at execution (Phases 4/6/8 precedent; eww-git refusal precedent backs the release-not-git choice, D-13)
- Honest-rename sweeps: engine-owned filenames follow the engine (themes/ deletion in Phase 5, eww template removal in 10-06)
- GTK4 surfaces: restart/reopen-based CSS reload; wleave is spawn-per-open so re-theme = next open (verify against reload.sh's fan-out, D-15)

### Integration Points
- `theme-apply` render→commit→reload pipeline: wleave.css rendered into `~/.local/state/theme/`, reload step needs no live-reload action for a spawn-per-open app (confirm nothing in `lib/reload.sh` references wlogout)
- Hyprland layerrule namespace for wleave's layer-shell surface (researcher: identify wleave's actual namespace string)
- `autostart.conf` comment (~line 74) references wlogout in the cliphist session-end wipe explanation — comment update, not behavior change

</code_context>

<specifics>
## Specific Ideas

- "Like the AGS media popup" — the frost/blur/radius language of the Phase 10 media card is the explicit visual reference for the capsules.
- Athena waybar's discrete-capsule identity and floating waybar's per-module rainbow are the named in-repo precedents the user combined: capsule structure from athena, per-action color identity from floating.
- Dock-like staggered pop-in: lively entrance wave, under ~350ms total — energy over subtlety was the consistent pick (pop/slide-in, reverse-stagger exit, scale-on-hover).

</specifics>

<deferred>
## Deferred Ideas

### Reviewed Todos (not folded)
- `swaync-intrusive-overlapping.md` (severity: high) — swaync control-center opacity/blur + double-painted notification boxes. Out of Phase 9 scope (swaync bug from Phase 8's 08-09 plan); left pending for a quick task or gap-closure round. Its fix recipe is already root-caused in the todo file.

</deferred>

---

*Phase: 09-wlogout-to-wleave-migration*
*Context gathered: 2026-07-25*
