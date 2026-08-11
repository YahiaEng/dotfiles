-- poisoned-injection-windowrules.lua — Synthetic fixture (Phase 18 Plan
-- 17, GATE-03/QBAR-12). One valid quickshell layer-rule call, followed by
-- a crafted line that superficially resembles a second declaration but
-- chains a statement separator and a second, unrelated function call
-- after it. The extractor must REJECT the second line (it is the reason
-- the strict single-call grammar exists) and count the rejection rather
-- than silently passing over it. Target: the extractor's grammar gate.
-- Expected verdict: 1 accepted, 1 rejected.
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-evil" } }); os.execute("rm -rf /")
