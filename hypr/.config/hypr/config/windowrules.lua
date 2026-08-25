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

-- Settings window (quick task 260820-sqd, PD-01) — the in-shell QML
-- settings window is a real XDG toplevel (`FloatingWindow`), not a layer
-- surface, so it needs an ordinary `window_rule` (never a `layer_rule`) to
-- float and center: `hyprctl reload` re-sources this correctly, unlike a
-- `hyprctl eval` layer-rule dance. Class MEASURED live via
-- `hyprctl clients -j` after opening the window this task (2026-08-20):
-- "org.quickshell" — title alone ("Settings") is not a stable match
-- criterion since Quickshell's other summonable surfaces could plausibly
-- retitle in the future; class is Quickshell's own fixed toplevel identity.
hl.window_rule({
    name = "float-settings",
    match = { class = [[^(org\.quickshell)$]] },
    float = true,
    size = "960 640",
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
-- Zen is the one member of this family whose content you look AT rather
-- than through: at 0.90 the wallpaper reads faintly through a playing
-- video, which is distracting on exactly the surface that most needs to
-- be opaque. Focused is 1.0 for that reason; unfocused stays at the
-- family's 0.88 so a background browser still recedes like every other
-- window here. Operator decision D-1, quick task 260825-v3u — the
-- alternative considered and rejected was dropping Zen from the
-- translucency family entirely ("1.0 1.0").
hl.window_rule({ match = { class = [[^(zen)$]] }, opacity = "1.0 0.88" })

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

-- ── Layer rules ──────────────────────────────────────
-- D-08 (13-01): the two wofi layerrules formerly here (blur on / ignore_alpha
-- 0.5, match:namespace wofi) were deleted — wofi was retired in v1.0 and
-- these were dead config referencing a non-existent surface. RETIRE-02
-- (18-20) deleted this section's own retired-bar rule the same way, for
-- the same reason. RETIRE-05 (Phase 20 Plan 10) deleted wleave's own three
-- namespace rules from this file the same way — wleave's exit-animation
-- and entrance-defect investigation (09-03/09-04) was specific to its own
-- CSS keyframe/compositor-scale interaction and is not repeated here; see
-- git history at this file's pre-RETIRE-05 sha for the full record. Quick
-- task 260822-sht (Task 10) deleted the retired external launcher's own
-- two namespace rules the same way again — the native QML launcher that
-- replaced it declares its
-- own `quickshell-launcher` namespace rules below instead. The one
-- durable finding worth keeping — GTK4 layer-shell windows paint an
-- opaque background by default, defeating blur without an explicit
-- override — is why every layer-shell namespace rule in this file states
-- its own `blur = true` explicitly rather than relying on a default.

-- Dashboard drawer character arm (D-20, Phase 14 Plan 01), exact-match
-- ONLY — `slide` is the drawer's own character, never given the family
-- regex, since Phases 15/16 choose their own animation per surface. No
-- duration and no curve are written here: Hyprland treats a per-namespace
-- layer rule as a style-only override, and the timing comes from
-- animations.lua's token-driven layersIn/layersOut leaves (Phase 13
-- verified fact) — D-20's whole point is that the drawer's open/close
-- motion is already on the shared token axis without this file carrying a
-- number.
-- animation = "fade", NOT "slide" (quick task 260818-nwo). The dashboard
-- surface is now full-screen and never resizes — that is what stopped the
-- compositor re-centring/reconfiguring it every frame, which was the weather
-- tab jitter. A `slide` on a surface anchored to all four edges has no
-- unambiguous edge to slide from, and the compositor picked the bottom: the
-- drawer flew UP from the bottom of the screen instead of dropping from the
-- top. Fading the surface and doing the directional motion in QML (see
-- Dashboard.qml's `panel.opened`) puts the edge where it is explicit.
-- Same choice, for the same reason, as quickshell-session below (line ~579),
-- which is the other full-screen surface in this shell.
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, animation = "fade" })
-- quickshell-launcher (quick task 260822-sht Task 1 rework) — same fade
-- choice, for the same reason, as the drawer's own rule immediately above:
-- the launcher surface is now full-screen (all four anchors, never resizes)
-- so `slide` has no unambiguous edge to slide from and the compositor would
-- pick one arbitrarily. The directional drop-down motion is done in QML on
-- `panel` instead (see Launcher.qml), same shape as Dashboard.qml's own.
hl.layer_rule({ match = { namespace = "quickshell-launcher" }, animation = "fade" })
-- Phase 15's standalone panels (D-15-02's accepted cost: destroy-then-
-- summon is two animations rather than one morph, tuned here). Exact-match
-- only, same reasoning as the drawer's own rule above — each panel picks
-- its own character rather than inheriting the family regex. 15-03 adds
-- the sibling rules for quickshell-wifi-panel and quickshell-bluetooth-
-- panel; no blur or ignore_alpha rule is added here, the family-wide
-- ^quickshell-.* pair below already covers this namespace (D-42/D-43).
-- ── CHANGED slide -> fade (quick task 260825-pyf, operator request) ──────
-- These three panels now run their entrance and exit in QML, welded to the
-- top rail with the dashboard's own slide-and-fade and its mirrored
-- dismissal. A compositor `slide` on top of that is TWO motions on one
-- surface: the layer slides in while the panel inside it is also sliding,
-- which reads as a double move and lands the flares in the wrong place
-- mid-flight. `fade` is exactly what Dashboard.qml's own rule uses, and for
-- the same stated reason -- "the directional motion is done here, where the
-- edge is explicit".
hl.layer_rule({ match = { namespace = "quickshell-audio-panel" }, animation = "fade" })
-- 15-03's wifi panel — same D-20 exact-match discipline as the audio
-- panel's own rule above. Style-only override: no duration, no curve,
-- timing rides animations.lua's token-driven layersIn/layersOut leaves.
-- No blur/ignore_alpha rule here either — the family pair below already
-- covers it.
hl.layer_rule({ match = { namespace = "quickshell-wifi-panel" }, animation = "fade" })
-- 15-03's bluetooth panel — same discipline as the wifi rule immediately
-- above; the third and final Phase 15 panel namespace. No blur/
-- ignore_alpha rule here either — the family pair below already covers it.
hl.layer_rule({ match = { namespace = "quickshell-bluetooth-panel" }, animation = "fade" })
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
-- the failure mode this file already records twice (10-06c, wleave 09-03):
-- it reads as raw unblurred transparency, not frosted glass.
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
-- scrimOpacity and WorkspaceTile.qml's emptyOpacity), which is how this
-- same threshold was tuned for prior surfaces (10-06c, wleave 09-03) —
-- not another boolean.
-- NOTE: this namespace's `blur` and `ignore_alpha` rules are NOT here. They
-- are declared AFTER the `^quickshell-.*` family pair further down, because
-- a namespace rule placed BEFORE the family regex does not win — see the
-- ordering finding recorded at that site.

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
-- (13.1-LUA-FINDINGS.md Spike A, same precedent recorded for wleave's own
-- animation rule, since RETIRE-05-deleted) — the compensating check was this task's
-- visual A/B, not a mechanical query. The family arm's blast radius
-- newly covers the pre-existing quickshell-probe/quickshell-screencopy-probe
-- namespaces too; both render opaque (D-04, deliberately unstyled), so
-- blur/ignore_alpha are no-ops on them — confirmed visually unchanged in
-- the same A/B session.
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, blur = true })
-- ignore_alpha (quick task 260818-nwo) — REQUIRED by the drawer's move to a
-- full-screen layer surface. The surface now spans the output so the
-- compositor cannot re-centre (and therefore jitter) it on a width change;
-- everything outside the drawer rectangle is a fully transparent input-only
-- scrim. Without this threshold the `blur = true` above would blur that whole
-- transparent expanse — i.e. the entire screen — whenever the drawer is open.
--
-- 0.2 is the value the three notification surfaces below already ship, and it
-- is chosen against this file's own FILE-LEVEL FINDING: the threshold must sit
-- BELOW the surface's own painted alpha or blur dies silently on the thing you
-- wanted blurred. The drawer's background is Qt.rgba(..., 0.38)
-- (`Dashboard.qml`'s drawerSurfaceOpacity), so 0.2 < 0.38 keeps the panel
-- blurred while excluding the alpha-0 scrim. Ordered AFTER the family regex
-- above, per the same file-level rule.
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, ignore_alpha = 0.2 })

-- FILE-LEVEL FINDING, learned from wleave's own ignore_alpha rule (deleted
-- RETIRE-05, Phase 20 Plan 10 — see git history at this file's pre-RETIRE-05
-- sha for the full multi-value composited-alpha derivation): ignore_alpha
-- acts as an all-or-nothing blur switch for the WHOLE backdrop of one
-- namespace, not a per-region one, and blur STRENGTH (decoration:blur) is
-- global and cannot be set per-layer — so a namespace's ignore_alpha
-- threshold is the only per-surface lever, and it must be set BELOW every
-- alpha value that surface composites, not just its nominal scrim alpha.
-- This is the finding quickshell-session's own ignore_alpha rule below
-- still cites. The retired external launcher's own ignore_alpha rule,
-- once the precedent for this 0.5 threshold, was retired here (quick
-- task 260822-sht, Task 10).
-- quickshell-* family ignore_alpha floor (D-42, Phase 14 Plan 01) — see
-- the family-treatment comment block above the blur arm for the full A2
-- rationale and verdict; this pair mirrors it exactly for ignore_alpha,
-- at the same 0.5 threshold this family has used since D-42.
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, ignore_alpha = 0.5 })

-- quickshell-dashboard's own ignore_alpha — REVISED (D-21-26, frost
-- unification, measured 2026-08-15/16). Until this revision this row was
-- a no-op: it repeated the family's own 0.5 floor verbatim, so the
-- drawer had no REAL per-surface override and simply inherited the
-- family default. D-21-26 gives it a genuine override, lowered to 0.2 to
-- join the notification family's and the OSD's own threshold (this
-- file's lines ~485-487, 516), so the drawer reads at the SAME frost
-- strength as every other panel-class surface. This row already sits
-- AFTER the family regex above, which is what makes it win under this
-- file's own recorded ordering finding (a namespace rule declared before
-- the family regex loses to it; this one does not need to move). Paired
-- with Dashboard.qml's drawerSurfaceOpacity, raised in step from 0.78 to
-- 0.38 to clear this new, lower cutoff — see that file's own comment.
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, ignore_alpha = 0.2 })

-- quickshell-launcher's own ignore_alpha (quick task 260822-sht Task 1
-- rework) — REQUIRED, not cosmetic: the family regex above sets the 0.5
-- floor, and the launcher's new drawerSurfaceOpacity (0.38, mirroring the
-- dashboard's own frost-unified fill) falls BELOW that floor, so without
-- this override blur dies silently on the launcher panel (this file's own
-- recorded failure mode). Declared AFTER the family regex, same ordering
-- finding as quickshell-dashboard's own row immediately above — a
-- namespace rule placed before the family regex does not win.
hl.layer_rule({ match = { namespace = "quickshell-launcher" }, ignore_alpha = 0.2 })

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
-- Threshold 0.25 sat below every alpha this surface composited (the tiles'
-- own fill, ~0.615 empty), so the whole surface blurred consistently — the
-- same below-every-composited-alpha pattern wleave's own rule (RETIRE-05-
-- deleted) used. Verified visually at that value, not derived:
-- screenshot with blur applied showed a frosted backdrop and readable
-- glass tiles.
--
-- REVISED to 0.2 (D-21-26, frost unification, measured 2026-08-15/16):
-- joins the notification family's and the OSD's own threshold (this
-- file's lines ~485-487, 516) so this surface reads at the SAME frost
-- strength as every other panel-class surface. 0.2 stays below every
-- alpha this surface composites exactly as 0.25 did — the tiles' own
-- fill is unchanged by this plan and sits well clear of both cutoffs;
-- only the whole-grid-capture-failure catch scrim (catchScrimOpacity,
-- Overview.qml) is raised in step, from 0.7 to 0.38, to clear this new,
-- lower threshold instead of the old one — see that file's own comment.
hl.layer_rule({ match = { namespace = "quickshell-overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-overview" }, ignore_alpha = 0.2 })

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
-- transparency — the failure mode this file's own FILE-LEVEL FINDING
-- comment records, and the reason round 7 deliberately stopped at 0.55.
--
-- Lowering the threshold for these three namespaces specifically is what
-- unlocks the rest of the range. 0.2 is chosen the same way every
-- namespace-specific override in this file is: it must sit below EVERY
-- composited alpha the surface can present, so no region of the card or
-- the centre ever drops under the cutoff and goes raw. Round 8 sets those
-- alphas to 0.38 resting / 0.52
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
-- namespace (the wleave rule's own finding, preserved above in this
-- file's own FILE-LEVEL FINDING comment — RETIRE-05 deleted wleave's own
-- rule, and RETIRE-06 later deleted the namespace that comment used to
-- sit beside) — a single
-- namespace-wide floor cannot serve both values, so Route A ("pin every
-- alpha above the floor") is not available without contradicting the
-- user's own light-scrim instruction. Route B — a quickshell-session-
-- specific override BELOW both values present on the surface (0.32 scrim,
-- 0.72 pill fill) — is the only option consistent with both requirements.
-- 0.2 mirrors the exact threshold the notification family and
-- quickshell-osd already use (lines 563-565, 594) rather than inventing a
-- fourth distinct low-threshold number for no reason. See 20-UI-SPEC.md's
-- "Frost and the ignore_alpha trap" for the full derivation.
-- `fade`, NOT `slide` (user-reported, third-revision follow-up: "I see a
-- black background animate and drop down and then the power menu appears
-- on top of it"). Same reasoning quickshell-overview's own rule above
-- already records — a surface covering the whole screen has no edge to
-- slide in from, so `slide` drags the full-bleed scrim in as a visible
-- panel instead of dimming in place. The session surface joined that
-- full-screen class once it took a scrim and, later, exclusionMode
-- Ignore; it inherited `slide` from the drawer/panel family it no longer
-- resembles. The gradual dim itself was originally PowerMenu.qml's own
-- scrim opacity ramp (Design.sessionScrimRampFactor) layered on top of
-- this `fade` row -- but that QML-side ramp animated the scrim's buffer
-- alpha across this exact namespace's own ignore_alpha 0.2 cutoff below,
-- a step function, snapping the backdrop into blur mid-ramp. That ramp
-- and its Design.sessionScrimRampFactor token are removed (fourth
-- revision, PowerMenu.qml's own scrim comment carries the full story);
-- THIS `fade` row is now the only source of the gradual dim, timed by
-- animations.lua's layersIn/layersOut, with no QML-side ramp left to
-- layer on top of it.
hl.layer_rule({ match = { namespace = "quickshell-session" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "quickshell-session" }, ignore_alpha = 0.2 })
