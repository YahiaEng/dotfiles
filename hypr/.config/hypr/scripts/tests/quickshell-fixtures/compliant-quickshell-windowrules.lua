-- compliant-quickshell-windowrules.lua — Synthetic fixture (Phase 18 Plan
-- 17, GATE-03/QBAR-12). The real quickshell-related hl.layer_rule
-- declarations from this repo's own windowrules.lua, carried in their
-- REAL file order — order is load-bearing: the quickshell-overview blur
-- pair is declared AFTER the ^quickshell-.* family pair on purpose
-- (D-42/D-43), and a replay that reorders them would silently disable
-- the later ones. One non-quickshell line (a synthetic foreign namespace)
-- is included to prove the candidate filter excludes it. Target: the
-- extractor. Expected verdict: 11 accepted, 0 rejected, in this exact
-- order.
hl.layer_rule({ match = { namespace = "some-other-shell" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-audio-panel" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-wifi-panel" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-bluetooth-panel" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-overview" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, blur = true })
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell-overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-overview" }, ignore_alpha = 0.25 })
