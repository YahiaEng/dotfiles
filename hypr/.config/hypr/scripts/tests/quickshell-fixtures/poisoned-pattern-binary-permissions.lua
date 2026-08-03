-- poisoned-pattern-binary-permissions.lua — derived from
-- compliant-permissions.lua with exactly one defect introduced: a second
-- grant uses a regular-expression alternation instead of an exact absolute
-- path — literally Hyprland's own shipped example
-- (/usr/share/hypr/hyprland.lua: `/usr/(bin|local/bin)/grim`), which
-- 13.1-PERMISSION-REVIEW.md and this repo's real permissions.lua both
-- explicitly reject (T-11-20). Target check:
-- permissions-allowlist-paths-resolve. Expected verdict: FAIL (pattern=1).

hl.config({ ecosystem = { enforce_permissions = true } })

hl.permission({ binary = "/usr/bin/bash", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(bin|local/bin)/grim", type = "screencopy", mode = "allow" })
