-- hypr/.config/hypr/config/windowrules.lua — Lua port of config/windowrules.conf
-- (Phase 13.1, plan 13.1-07). 30 window rules and 13 layer rules, ported
-- one-for-one in source order, with no rule merged, split, dropped or
-- reordered relative to the hyprlang original.
--
-- Every match criterion below is written as a Lua long-bracket string
-- literal ([[...]]), not a short "..." string, so a pattern's backslash
-- escapes (e.g. ^(org\.gnome\.Calculator)$) reach the compositor exactly
-- as written today — a short string would reinterpret or reject those
-- escapes. Applied uniformly to every pattern, not only the ones that
-- currently contain a backslash.
--
-- Every property spelling and value shape comes from the empirically
-- established vocabulary recorded in 13.1-LUA-FINDINGS.md (Spike A), not
-- from the hyprlang keyword (T-13.1-10) — see that document's "Spike A —
-- window-rule and layer-rule property vocabulary" table for the live
-- evidence behind each one. Compensating checks for the properties with
-- no runtime projection (opacity, no_blur, the per-rule animation
-- override) are recorded in this plan's own SUMMARY.md for the
-- end-of-phase human verification.

-- ── Float rules (grouped with named rules) ───────────

hl.window_rule({
    name = "float-pavucontrol",
    match = { class = [[^(pavucontrol)$]] },
    float = true,
    size = "800 600",
    center = true,
})

hl.window_rule({
    name = "float-blueman",
    match = { class = [[^(blueman-manager)$]] },
    float = true,
    size = "800 600",
    center = true,
})

hl.window_rule({ match = { class = [[^(nm-applet)$]] }, float = true })
hl.window_rule({ match = { class = [[^(nm-connection-editor)$]] }, float = true })
hl.window_rule({ match = { class = [[^(xdg-desktop-portal-gtk)$]] }, float = true })
hl.window_rule({ match = { class = [[^(org\.gnome\.Calculator)$]] }, float = true })
hl.window_rule({ match = { class = [[^(org\.gnome\.Settings)$]] }, float = true })
hl.window_rule({ match = { class = [[^(imv)$]] }, float = true })
hl.window_rule({ match = { class = [[^(mpv)$]] }, float = true })

-- Thunar dialogs
hl.window_rule({
    match = { class = [[^(thunar)$]], title = [[^(File Operation Progress)$]] },
    float = true,
})
hl.window_rule({
    match = { class = [[^(thunar)$]], title = [[^(Confirm)]] },
    float = true,
})

-- ── Picture in picture ───────────────────────────────

hl.window_rule({
    name = "pip-rules",
    match = { title = [[[Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture]] },
    float = true,
    pin = true,
    size = "480 270",
    move = "(monitor_w-490) (monitor_h-280)",
})

-- ── Wallpaper picker (floating kitty) ────────────────

hl.window_rule({
    name = "wallpaper-picker",
    match = { class = [[^(wallpaper-picker)$]] },
    float = true,
    size = "85% 85%",
    center = true,
    animation = "popin",
})

hl.window_rule({
    name = "icon-theme-picker",
    match = { class = [[^(icon-theme-picker)$]] },
    float = true,
    size = "85% 85%",
    center = true,
    animation = "popin",
})

hl.window_rule({
    name = "font-switcher",
    match = { class = [[^(font-switcher)$]] },
    float = true,
    size = "85% 85%",
    center = true,
    animation = "popin",
})

hl.window_rule({
    name = "network-manager",
    match = { class = [[^(network-manager)$]] },
    float = true,
    size = "85% 85%",
    center = true,
    animation = "popin",
})

hl.window_rule({
    name = "cheat-sheet",
    match = { class = [[^(cheat-sheet)$]] },
    float = true,
    size = "85% 85%",
    center = true,
    animation = "popin",
})

-- ── Yazi file manager (floating kitty) ───────────────

hl.window_rule({
    name = "yazi-fm",
    match = { class = [[^(yazi-fm)$]] },
    float = true,
    size = "70% 65%",
    center = true,
    animation = "popin",
})

-- ── AI Dashboard kitty surfaces (MENU-03, D-21/D-24) ─
-- Unlike Zen (see the big comment block below), kitty's --class is set at
-- spawn time and known immediately, so a plain class-based workspace
-- assignment works correctly here (no title-timing problem) — verified
-- live against the same instrumentation used for the Zen finding.
hl.window_rule({
    name = "ai-claude-code",
    match = { class = [[^(ai-claude-code)$]] },
    workspace = "name:ai",
})

hl.window_rule({
    name = "ai-local-models",
    match = { class = [[^(ai-local-models)$]] },
    workspace = "name:ai",
})

-- ── AI Dashboard web-app windows (MENU-03, D-21) — NO windowrule needed ──
-- Zen assigns EVERY window the identical class "zen" regardless of the URL
-- loaded (confirmed live 2026-07-13, hyprctl clients -j: a plain --new-window
-- https://claude.ai launch reports class=zen, initialClass=zen). RESEARCH
-- Assumption A1 asked whether MOZ_APP_REMOTINGNAME=<name> (Firefox 124+'s
-- documented app_id override) changes that on THIS Zen build — tested live:
-- `MOZ_APP_REMOTINGNAME=zen-claude zen-browser --new-window https://claude.ai`
-- produced a window with class/initialClass STILL "zen" (unchanged) and the
-- SAME pid as a plain pre-existing Zen window. Root cause: Zen is single-
-- instance — a second `zen-browser` invocation just asks the already-running
-- master process to open a new window; it never re-reads its own env. A1 is
-- CLOSED: the env var has no effect here, on this build, for this reason.
--
-- A title-regex windowrule (the plan's originally intended fallback) was
-- tried and PROVEN NOT TO WORK for placement, one level deeper than A1's own
-- caveat anticipated: `hyprctl clients -j` shows `initialTitle` is the
-- generic "Zen Browser" for EVERY new window regardless of URL — the page
-- title ("Sign in - Claude — Zen Browser" etc.) only arrives after the page
-- loads, which is AFTER Hyprland's one-shot `workspace` rule dispatch has
-- already run against the window's map-time state. Confirmed live: a
-- `windowrule = workspace name:ai, match:class ^(zen)$, match:title .*Claude.*`
-- rule never moved the window even minutes after its title had fully updated
-- to match — workspace-assignment rules do not get re-evaluated on later
-- title-change events the way continuous properties like opacity/float do.
--
-- The mechanism that DOES work, verified live: Hyprland spawns a new window
-- on whichever workspace is currently ACTIVE at spawn time. Placement is
-- therefore done by the menu's own launch action switching to `name:ai`
-- FIRST (`hyprctl dispatch workspace name:ai`), THEN launching zen-browser —
-- no windowrule involved. This is also a cleaner Pitfall-4 regression fix
-- than title-matching: a normal Zen window opened without that workspace-
-- switch preamble is untouched by construction, not merely by regex
-- non-match. Live-verified: a Claude-URL launch after switching to name:ai
-- landed there; a plain non-AI-URL launch made from workspace 2 (no switch)
-- stayed on workspace 2. Implemented in ai-dashboard.toml's Zen entries via
-- ai-webapp-launch.sh (plan 07-06).
--
-- Titles for all four services were verified live (2026-07-13), documented
-- here for any future script that DOES need to identify these windows by
-- content after they've loaded:
--   Claude      -> "Sign in - Claude — Zen Browser"
--   ChatGPT     -> "ChatGPT — Zen Browser"
--   Gemini      -> "Google Gemini — Zen Browser"
--   Perplexity  -> "Perplexity — Zen Browser"

-- ── Opacity rules ────────────────────────────────────
-- NOT MECHANICALLY VERIFIABLE beyond key-name/no-configerrors — no
-- `hyprctl clients -j` opacity projection exists (13.1-LUA-FINDINGS.md
-- Spike A). Compensating check: translucent kitty/yazi-fm/thunar/codium/zen
-- windows at the end-of-phase human verification.

hl.window_rule({ match = { class = [[^(kitty)$]] }, opacity = "0.88 0.85" })
hl.window_rule({ match = { class = [[^(yazi-fm)$]] }, opacity = "0.92 0.90" })
hl.window_rule({ match = { class = [[^(thunar)$]] }, opacity = "0.90 0.88" })
hl.window_rule({ match = { class = [[^(code-url-handler)$]] }, opacity = "0.90 0.88" })
hl.window_rule({ match = { class = [[^(Code)$]] }, opacity = "0.90 0.88" })
hl.window_rule({ match = { class = [[^(codium-url-handler)$]] }, opacity = "0.90 0.88" })
hl.window_rule({ match = { class = [[^(codium)$]] }, opacity = "0.90 0.88" })
hl.window_rule({ match = { class = [[^(zen)$]] }, opacity = "0.90 0.88" })

-- ── Blur rules ───────────────────────────────────────
-- NOT MECHANICALLY VERIFIABLE beyond key-name/no-configerrors — no
-- `hyprctl clients -j` blur projection exists (13.1-LUA-FINDINGS.md Spike
-- A). Compensating check: an unblurred backdrop behind firefox and
-- chromium windows at the end-of-phase human verification.

hl.window_rule({ match = { class = [[^(firefox)$]] }, no_blur = true })
-- (kept commented out, matching windowrules.conf's own commented
-- `#windowrule = no_blur on, match:class ^(zen)$` line — not ported as a
-- live rule)
hl.window_rule({ match = { class = [[^(chromium)$]] }, no_blur = true })

-- ── Layer rules (walker, waybar, swaync, wleave)
-- D-08 (13-01): the two wofi layerrules formerly here (blur on / ignore_alpha
-- 0.5, match:namespace wofi) were deleted — wofi was retired in v1.0 and
-- these were dead config referencing a non-existent surface.

hl.layer_rule({ match = { namespace = "walker" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
-- wleave power menu (WLOG-01, GTK4 cutover of the retired power-menu
-- surface). wleave is a gtk4-layer-shell surface with :namespace "wleave";
-- paired with the transparent-window + scoped-scrim split in
-- wleave/style.css so the blur has something to frost through — the same
-- 10-06 durable finding the ags-media rule below already applies (GTK4
-- windows paint an opaque background by default, defeating blur without
-- an explicit override).
hl.layer_rule({ match = { namespace = "wleave" }, blur = true })
-- 09-03 D-10 exit-animation attempt (Tier 1, RESEARCH Assumption A2).
-- `09-RESEARCH.md` flagged that wleave hides its window synchronously,
-- client-side, before delay-command-ms elapses — leaving no window-visible
-- "closing" interval a GTK CSS transition could animate — and that whether
-- a COMPOSITOR-level layerrule fires on that kind of client-initiated hide
-- was unconfirmed. This is the one must_haves.truths backstop item this
-- plan cannot close by reading source; it was checked live.
-- RESULT, observed live (not assumed): it DOES fire. A live 10-frame rapid
-- `grim` capture across a real dismissal (phase evidence would show this,
-- reproducible via: launch wleave, dismiss with Escape, grab several quick
-- sequential grim frames of the capsule row) shows the capsule row visibly
-- fading across multiple frames before the surface is gone. Achieved tier: 1
-- (compositor layerrule animation) — recorded honestly in 09-03-SUMMARY.md.
--
-- ── 09-04 render-gate defect fix: double-animation on ENTRANCE ─────────
-- REPORTED DEFECT: "the roll-in animation is still too fast and looks
-- sluggish" — a precise, non-contradictory report: the overall envelope
-- reads as an abrupt pop (too fast to register as intentional) while the
-- part that IS perceived reads as a jerky, mistimed cascade (sluggish).
--
-- ROOT CAUSE, confirmed structurally via `hyprctl animations` (not
-- guessed): the global `layers` bucket (animations.conf: `animation =
-- layers, 1, 4, md3_decel, popin 80%`) has BOTH its `layersIn` and
-- `layersOut` children reporting `overridden: 0` — i.e. fully inheriting
-- the parent's `popin 80%` style. The previous `animation layers` rule
-- below therefore pinned wleave's ENTRANCE (not just its exit) to the
-- same compositor-level 80%→100% SCALE pop already used for exit. That
-- outer scale was firing at the same time as this stylesheet's own
-- per-button `@keyframes capsule-entrance` (translateY+scale, 35ms
-- stagger) — two independently-timed scale animations compounding: the
-- compositor's own pop completes as a fast, snappy step, while the CSS
-- cascade riding on top of that same moving container reads as an
-- out-of-sync jerk once the outer frame has already visually "arrived".
--
-- CONFIRMED live via cropped rapid-`grim` capture (a `grim -g "X,Y WxH"`
-- region capture runs in ~90ms here vs ~1.4s for a full 2560x1440 shot —
-- fast enough to resolve this sub-400ms transition, unlike the 09-03
-- full-screen technique): with the OLD `animation layers` rule, an
-- in-flight frame showed only 2 of 6 capsules rendered, OUT OF THEIR
-- left-to-right delay order, with no scrim/blur yet applied — a visibly
-- broken intermediate state. With the fix below, the same technique shows
-- a clean, correctly-ordered left-to-right cascade (capsule N solid
-- before capsule N+1 appears) at every sampled frame.
--
-- FIX: pin wleave's compositor-level layer animation to the `fade` bucket
-- (a plain opacity fade, no scale) instead of `layers` (which carries the
-- competing scale-pop). This makes the CSS keyframes the ONLY system that
-- scales/translates capsules — the compositor now only cross-fades the
-- whole surface's opacity, which does not compete with an independent
-- transform. Re-verified live that this does NOT regress the exit fade
-- (still a clean multi-frame fade-out on Escape, same rapid-capture
-- technique) — Tier 1 (compositor-level animation) is unchanged, only the
-- STYLE moved from `popin 80%` to `fade`. D-10's <350ms CSS budget and
-- the immediate-fire power action are both untouched — this rule affects
-- only the compositor's own envelope, never `delay-command-ms`.
--
-- NOT MECHANICALLY VERIFIABLE via this plan's harness — no `clients -j`
-- projection exists for the animation style itself (13.1-LUA-FINDINGS.md
-- Spike A). Compensating check: the wleave capsule-row fade at the
-- end-of-phase human verification, same rapid-capture technique as above.
hl.layer_rule({ match = { namespace = "wleave" }, animation = "fade" })
-- AGS media applet (10-04, MEDIA-02). Astal.Window sets namespace
-- "ags-media" (10-02); targets ONLY this window, mirroring the other
-- namespace-scoped blur rules above. Paired with the translucent
-- .media-scrim / .media-controls backgrounds in ags/style.scss so the blur
-- has something to frost through.
hl.layer_rule({ match = { namespace = "ags-media" }, blur = true })

hl.layer_rule({ match = { namespace = "walker" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.5 })
-- An earlier draft (10-06c) lowered .media-scrim to rgba($background, 0.25)
-- and correspondingly dropped this threshold to 0.2 to chase a stronger
-- frost — but with .media-bg-art layered underneath at 0.35 too, that put
-- most of the card's composited alpha BELOW the blur cutoff, so it rendered
-- as raw unblurred transparency rather than frosted glass. That was
-- reverted back to the shared 0.5 default, but the resulting composited
-- alpha (~0.71) then read as a heavy opaque frost with the desktop barely
-- visible through it. 10-06d rebalances both sides at once: .media-bg-art
-- and .media-scrim were lowered (style.scss) to composite to ~0.44, and
-- THIS threshold is lowered in step to 0.25 so that ~0.44 stays
-- comfortably above the cutoff — the card is blurred+clickable (not raw
-- unblurred transparency) while still reading as a light, see-through
-- frost rather than a solid panel.
hl.layer_rule({ match = { namespace = "ags-media" }, ignore_alpha = 0.25 })
-- wleave's composited alpha differs from the retired single-uniform-fill
-- scrim this replaces: the new design layers a transparent window, a 0.40
-- scrim, and per-capsule fills, where the old surface had one flat fill.
-- ignore_alpha acts as an all-or-nothing blur switch for the whole
-- backdrop, so this threshold is set BELOW the 0.40 scrim alpha (0.25) so
-- the scrim still blurs. Blur STRENGTH is decoration:blur and is global —
-- it cannot be set per-layer — so this scrim alpha is the only wleave-local
-- control over how much desktop reads through.
--
-- 09-03 re-derivation: the design now actually composites THREE values at
-- this surface, not one — the 0.40 scrim alone, and the scrim WITH a
-- capsule's own fill layered on top (0.35 alpha at rest, 0.55 on hover/
-- focus). Alpha-compositing scrim-then-fill gives an effective per-capsule
-- alpha of ~0.61 at rest and ~0.73 on hover/focus (1 − (1 − 0.40) × (1 − fill)).
-- 0.25 sits below all three values (0.40 / 0.61 / 0.73), so every region of
-- the surface — bare scrim AND capsule interiors, at rest and hovered —
-- stays above the cutoff and blurs; nothing is at risk of reading as raw
-- unblurred transparency at the low end (the ags-media rule's failure mode
-- above), nor is 0.25 so low that it swings to that same rule's OTHER
-- failure mode (a heavy, barely-see-through opaque frost) — the underlying
-- alpha values here (0.40/0.61/0.73) are themselves the parts of this
-- design carrying that risk, not the threshold, and they read correctly on
-- the live rest/hover captures in this phase's evidence directory. 0.25 is
-- therefore kept unchanged from 09-02's starting value, now with this
-- recomputed justification rather than the single-flat-fill reasoning it
-- replaced — marked for a final look at the 09-04 render gate as always.
hl.layer_rule({ match = { namespace = "wleave" }, ignore_alpha = 0.25 })
