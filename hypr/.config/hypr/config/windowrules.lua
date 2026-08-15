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

-- ── Layer rules (walker, wleave)
-- D-08 (13-01): the two wofi layerrules formerly here (blur on / ignore_alpha
-- 0.5, match:namespace wofi) were deleted — wofi was retired in v1.0 and
-- these were dead config referencing a non-existent surface. RETIRE-02
-- (18-20) deleted this section's own retired-bar rule the same way, for
-- the same reason.

hl.layer_rule({ match = { namespace = "walker" }, blur = true })
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
-- Dashboard drawer character arm (D-20, Phase 14 Plan 01), exact-match
-- ONLY — `slide` is the drawer's own character, never given the family
-- regex, since Phases 15/16 choose their own animation per surface. No
-- duration and no curve are written here: Hyprland treats a per-namespace
-- layer rule as a style-only override, and the timing comes from
-- animations.lua's token-driven layersIn/layersOut leaves (Phase 13
-- verified fact) — D-20's whole point is that the drawer's open/close
-- motion is already on the shared token axis without this file carrying a
-- number.
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, animation = "slide" })
-- Phase 15's standalone panels (D-15-02's accepted cost: destroy-then-
-- summon is two animations rather than one morph, tuned here). Exact-match
-- only, same reasoning as the drawer's own rule above — each panel picks
-- its own character rather than inheriting the family regex. 15-03 adds
-- the sibling rules for quickshell-wifi-panel and quickshell-bluetooth-
-- panel; no blur or ignore_alpha rule is added here, the family-wide
-- ^quickshell-.* pair below already covers this namespace (D-42/D-43).
hl.layer_rule({ match = { namespace = "quickshell-audio-panel" }, animation = "slide" })
-- 15-03's wifi panel — same D-20 exact-match discipline as the audio
-- panel's own rule above. Style-only override: no duration, no curve,
-- timing rides animations.lua's token-driven layersIn/layersOut leaves.
-- No blur/ignore_alpha rule here either — the family pair below already
-- covers it.
hl.layer_rule({ match = { namespace = "quickshell-wifi-panel" }, animation = "slide" })
-- 15-03's bluetooth panel — same discipline as the wifi rule immediately
-- above; the third and final Phase 15 panel namespace. No blur/
-- ignore_alpha rule here either — the family pair below already covers it.
hl.layer_rule({ match = { namespace = "quickshell-bluetooth-panel" }, animation = "slide" })
-- Workspace overview (Phase 16 Plan 02 tracer, D-16-24) — `fade`, not the
-- drawer's/panels' `slide`: a surface covering the whole screen has no edge
-- to slide in from. Exact-match only, same discipline as every rule above.
hl.layer_rule({ match = { namespace = "quickshell-overview" }, animation = "fade" })
-- D-16-06 fallback lever #1 was pulled at the Task 3 render gate
-- (2026-08-03): the operator judged the family blur "too strong" on this
-- surface, and since `LayerRule`'s only blur field is a boolean
-- (`hl.meta.lua` line 551 — `blur?: boolean`) while blur INTENSITY
-- (`decoration.blur.size`/`.passes`/etc.) is a single GLOBAL compositor
-- setting with no per-layer-rule strength override, "turn it down" had
-- exactly one expression available at the time: off.
--
-- ── REVERSED at plan 16-07's Task 3 render gate, round 5 (2026-08-08) ────
-- Same operator, later gate, different question. The 08-03 decision was
-- taken while the tiles were OPAQUE, so blur bought this surface nothing
-- and only cost strength. Plan 16-07 round 4 made the EMPTY tiles
-- translucent to stop ten solid slabs dominating a grid whose real content
-- is the few occupied tiles — and translucency without blur is precisely
-- the failure mode this file already records twice (ags-media 10-06c,
-- wleave 09-03): it reads as raw unblurred transparency, not frosted glass.
-- Reported at the gate as "empty tiles are still the same, no glass look".
-- Blur is what that request actually requires, so it goes back on.
--
-- The 08-03 note that dropping scrim alpha below the family floor does not
-- soften blur but silently disables it stays TRUE and is the reason for the
-- companion `ignore_alpha` rule below: Overview.qml's scrim is 0.45, under
-- the family's 0.5 floor, so re-enabling blur alone would have frosted the
-- translucent tiles (composited ~0.63) while leaving the bare scrim
-- unblurred — a surface blurred in patches. The threshold is therefore set
-- BELOW every alpha this surface composites, exactly as wleave's 09-03
-- re-derivation does for the same reason.
--
-- Strength remains global and remains the known risk: if this reads too
-- strong again, the lever is this surface's OWN alpha (Overview.qml's
-- scrimOpacity and WorkspaceTile.qml's emptyOpacity), which is how both
-- ags-media and wleave were tuned — not another boolean.
-- NOTE: this namespace's `blur` and `ignore_alpha` rules are NOT here. They
-- are declared AFTER the `^quickshell-.*` family pair further down, because
-- a namespace rule placed BEFORE the family regex does not win — see the
-- ordering finding recorded at that site.
-- AGS media applet (10-04, MEDIA-02). Astal.Window sets namespace
-- "ags-media" (10-02); targets ONLY this window, mirroring the other
-- namespace-scoped blur rules above. Paired with the translucent
-- .media-scrim / .media-controls backgrounds in ags/style.scss so the blur
-- has something to frost through.
hl.layer_rule({ match = { namespace = "ags-media" }, blur = true })

-- ── quickshell-* family treatment (D-42, Phase 14 Plan 01, RESEARCH.md
--    Assumption A2 / Open Question 2) ────────────────────────────────────
-- D-42 buys: every future QML surface this project ships (Phase 15's
-- panels, Phase 16's overview) inherits blur + the ignore_alpha floor
-- automatically by naming its own layer-shell namespace
-- "quickshell-<surface>" — nothing else to add, this rule pair is written
-- once. The family regex below was UNVERIFIED against this installed
-- Hyprland 0.56.1 build at authoring time; regex namespace matching on
-- `hl.layer_rule` is documented Hyprland capability but fails OPEN if it
-- does not actually match on this build (a non-matching regex silently
-- treats zero surfaces rather than erroring) — so the per-surface
-- exact-match fallback for quickshell-dashboard ships in this SAME commit
-- as the immediately-available substitute, not as dead code.
--
-- A2 VERDICT (settled this task, live A/B, 2026-07-29): regex-matches —
-- with only the family regex active (exact-match rules temporarily
-- commented out), the desktop behind the summoned drawer read visibly
-- blurred; with neither arm active it read unblurred. Both arms are kept:
-- the exact rules are now a retained, documented redundancy rather than a
-- required fallback. Full observation in 14-01-SUMMARY.md. Layer-rule
-- effects carry no `hyprctl` projection on this build
-- (13.1-LUA-FINDINGS.md Spike A, same precedent already recorded beside
-- the wleave fade rule above) — the compensating check was this task's
-- visual A/B, not a mechanical query. The family arm's blast radius
-- newly covers the pre-existing quickshell-probe/quickshell-screencopy-probe
-- namespaces too; both render opaque (D-04, deliberately unstyled), so
-- blur/ignore_alpha are no-ops on them — confirmed visually unchanged in
-- the same A/B session.
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, blur = true })

hl.layer_rule({ match = { namespace = "walker" }, ignore_alpha = 0.5 })
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
-- quickshell-* family ignore_alpha floor (D-42, Phase 14 Plan 01) — see
-- the family-treatment comment block above the blur arm for the full A2
-- rationale and verdict; this pair mirrors it exactly for ignore_alpha,
-- matching the 0.5 threshold the walker rule already uses.
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, ignore_alpha = 0.5 })

-- ── quickshell-overview blur pair — DECLARED LAST, DELIBERATELY ──────────
-- (plan 16-07 Task 3 render gate, round 8. Full rationale for WHY this
-- surface is blurred at all lives with the animation rule far above.)
--
-- ORDERING FINDING (inferred from live behaviour, 2026-08-08): a namespace
-- rule that CONTRADICTS the `^quickshell-.*` family regex loses when it is
-- declared before the family. Both arms of this pair originally sat above
-- the family and the ignore_alpha arm silently had no effect.
--
-- The evidence is two render-gate observations that bracket the threshold,
-- with the namespace rule asking for 0.25 the whole time:
--   round 5 — empty tile fill at 0.32 over the 0.45 scrim composites to
--     1 - (1 - 0.45)(1 - 0.32) = ~0.63. Frosted.
--   round 6 — fill removed, so the region is the bare 0.45 scrim.
--     NOT frosted; read as raw transparency.
-- A cutoff that passes 0.63 and fails 0.45 is 0.5 — the FAMILY value, not
-- this namespace's 0.25. Hence: later declaration wins, so these go last.
--
-- Layer-rule effects carry no `hyprctl` projection on this build
-- (13.1-LUA-FINDINGS.md Spike A), so this ordering cannot be asserted
-- mechanically and was derived from the two observations above rather than
-- read off the compositor. Declaring last is therefore belt AND braces: it
-- makes the threshold below authoritative under the inferred precedence,
-- and harmless if the inference is wrong, since the value it sets is the
-- same 0.5 the family would have supplied anyway.
--
-- ⚠ ── EDITS HERE DO NOT TAKE EFFECT ON `hyprctl reload` ─────────────────
-- Verified by screenshot A/B on 2026-08-08 (plan 16-07 render gate, round
-- 10), and it is the single reason that gate burned five rounds:
--
--   hyprctl eval '<the rule below>'  -> frost appears immediately
--   hyprctl reload                   -> frost disappears again
--
-- This build runs the Lua (non-legacy) parser, which rejects `hyprctl
-- keyword` outright ("keyword can't work with non-legacy parsers. Use
-- eval.") and silently DROPS layer-rule changes on reload — no error, no
-- warning, `hyprctl configerrors` clean. The family rules above work only
-- because they were applied at compositor STARTUP.
--
-- So a layer-rule edit needs one of:
--   * `hyprctl eval '<rule>'` to apply it to the running session, or
--   * a full Hyprland restart / re-login.
-- `hyprctl reload` is NOT sufficient and will look like the edit was wrong.
-- Rounds 5-9 of that gate were spent tuning QML alphas against rules the
-- compositor had never read; the alphas were never the problem.
--
-- Threshold 0.25 sits below every alpha this surface composites (the 0.45
-- scrim and the ~0.615 empty tile alike), so the whole surface blurs
-- consistently — the wleave/ags-media pattern. Verified visually at these
-- values, not derived: screenshot with blur applied shows a frosted
-- backdrop and readable glass tiles.
hl.layer_rule({ match = { namespace = "quickshell-overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-overview" }, ignore_alpha = 0.25 })

-- ── Notification surfaces (Phase 19 Plan 01 tracer, QNOTIF-01/02) ────────
-- Three exact-match namespace rows, all three added by this one plan even
-- though only quickshell-notif-popups has a real surface yet (this plan's
-- own instruction: "adding all three now means waves 2-3 never reopen
-- this file"). All three fall inside the `^quickshell-.*` family regex
-- above, so blur + the ignore_alpha 0.5 floor apply automatically with no
-- rule needed here for either — same D-20 exact-match-only discipline as
-- every other namespace row in this file: only the animation CHARACTER is
-- declared per surface, never blur/ignore_alpha again. Declared AFTER the
-- family regex rows (and after quickshell-overview's own late pair) per
-- this plan's own instruction and this file's already-recorded ordering
-- finding — a namespace rule placed BEFORE the family regex risks losing
-- to it if the two ever contradict, so every exact-match row in this file
-- lives at or after this point.
--
-- "slide" for all three, matching quickshell-dashboard's own precedent:
-- popups slide + fade from the anchored top-right edge (D-19-13), the
-- centre slides from off-screen right (D-19-23), and the toast slides
-- down from the top edge (D-19-36's own "Toast frame" section). No
-- duration or curve is written here — Hyprland treats a per-namespace
-- layer rule as a style-only override; timing rides animations.lua's
-- token-driven layersIn/layersOut leaves, the same as every sibling row.
hl.layer_rule({ match = { namespace = "quickshell-notif-popups" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-notif-centre" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-notif-toast" }, animation = "slide" })

-- ── notification-family ignore_alpha override (GATE-02 gap-closure,
--    round 8 item 2 — "glass/frosty look is not noticeable enough") ──────
--
-- These three namespaces already inherit `blur = true` from the
-- `^quickshell-.*` family regex, and blur was never the missing piece:
-- decoration:blur is globally enabled at size 8 / passes 3, so the
-- compositor has been frosting the backdrop of these surfaces all along.
-- What was missing is TRANSPARENCY for that frost to show through. Round 7
-- lowered the surfaces to 0.55 alpha (BarRoles.notifSurface) and that was
-- as far as the family's own `ignore_alpha = 0.5` floor allowed: below the
-- cutoff a region is not blurred AT ALL and renders as raw unblurred
-- transparency — the failure mode already recorded at the ags-media rule
-- above, and the reason round 7 deliberately stopped at 0.55.
--
-- Lowering the threshold for these three namespaces specifically is what
-- unlocks the rest of the range. 0.2 is chosen the same way ags-media's
-- own 0.25 was: it must sit below EVERY composited alpha the surface can
-- present, so no region of the card or the centre ever drops under the
-- cutoff and goes raw. Round 8 sets those alphas to 0.38 resting / 0.52
-- hover, both comfortably clear of 0.2, so the whole surface frosts while
-- reading as genuinely see-through glass rather than a tinted panel.
--
-- DECLARED LAST, DELIBERATELY — same ordering discipline as the
-- quickshell-overview pair above, and for the same reason: these rows
-- CONTRADICT the family's own 0.5 floor, and this file's recorded
-- ordering finding is that a namespace rule contradicting the family
-- regex silently loses when declared before it. `blur = true` is restated
-- alongside rather than relying on inheritance, matching how the overview
-- pair declares both arms together.
--
-- Blur STRENGTH stays global (decoration:blur:size/passes) and is
-- untouched — it cannot be set per-layer, as this file already records.
hl.layer_rule({ match = { namespace = "quickshell-notif-popups" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-notif-centre" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-notif-toast" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-notif-popups" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "quickshell-notif-centre" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "quickshell-notif-toast" }, ignore_alpha = 0.2 })

-- ── quickshell-osd / quickshell-session layer rules (Phase 20 Plan 03,
--    QOSD-01/QOSD-04, QPOWER-01) ─────────────────────────────────────────
-- Both new namespaces declared here, in this file's LAST-declared block,
-- AFTER the `^quickshell-.*` family regex rows (lines 396/445) and after
-- every exact-match namespace row above — this file's own recorded
-- ordering finding is that a namespace rule contradicting the family
-- regex silently loses if declared before it, so every exact-match row in
-- this file lives at or after this point. Additive only: the family regex
-- rows and the existing notification override block above are untouched.
--
-- quickshell-osd reuses Toast.qml's frame (Phase 19 Plan 01) but is a
-- BRAND-NEW namespace, matching the three quickshell-notif-* rows'
-- "slide" precedent and restating blur = true by name rather than relying
-- on the family regex, same idiom as the notification override block
-- above.
hl.layer_rule({ match = { namespace = "quickshell-osd" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-osd" }, blur = true })
-- quickshell-osd does NOT inherit quickshell-notif-toast's 0.2 override
-- just because it renders the same Toast.qml frame — a fresh namespace
-- inherits only the family's own ignore_alpha = 0.5 floor. Toast.qml's
-- fill is BarRoles.notifSurface at alpha 0.38, tuned against the
-- notification family's 0.2, and 0.38 < 0.5. Without this row the OSD
-- region falls below the active cutoff and blur silently turns off — a
-- symptom visually indistinguishable from "the layer rule never applied
-- at all", a different and unrelated failure mode this repo has already
-- hit once. 0.2 sits below 0.38 with the same headroom the notification
-- family already uses.
hl.layer_rule({ match = { namespace = "quickshell-osd" }, ignore_alpha = 0.2 })

-- quickshell-session — REVISED 2026-08-15 (D-20-21 revised, ring design).
-- The stale prediction below no longer holds: the grid dialog (card fill
-- 0.78, scrim 0.55, both above the family's 0.5 floor) was built, shown
-- live, and rejected by the user for a radial ring with two DIFFERENT
-- alpha values on the same namespace — the scrim at sessionScrimOpacity
-- (0.32, a deliberate light dim, BELOW the family floor) and each pill's
-- own frosted fill at sessionPillFillOpacity (0.72, ABOVE it). ignore_alpha
-- behaves as an all-or-nothing blur switch for the whole backdrop of one
-- namespace (the wleave rule's own finding, line 417 above) — a single
-- namespace-wide floor cannot serve both values, so Route A ("pin every
-- alpha above the floor") is not available without contradicting the
-- user's own light-scrim instruction. Route B — a quickshell-session-
-- specific override BELOW both values present on the surface (0.32 scrim,
-- 0.72 pill fill) — is the only option consistent with both requirements.
-- 0.2 mirrors the exact threshold the notification family and
-- quickshell-osd already use (lines 563-565, 594) rather than inventing a
-- fourth distinct low-threshold number for no reason. See 20-UI-SPEC.md's
-- "Frost and the ignore_alpha trap" for the full derivation.
hl.layer_rule({ match = { namespace = "quickshell-session" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-session" }, ignore_alpha = 0.2 })
