-- poisoned-missing-binary-permissions.lua — derived from
-- compliant-permissions.lua with exactly one defect introduced: a second
-- grant names a binary path that does not exist on disk — the real-world
-- failure this check exists to catch (a package update moving grim or the
-- portal binary breaks screenshots under enforcement with no warning until
-- a key is pressed). Target check: permissions-allowlist-paths-resolve.
-- Expected verdict: FAIL (missing=1).

hl.config({ ecosystem = { enforce_permissions = true } })

hl.permission({ binary = "/usr/bin/bash", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/bin/definitely-does-not-exist-xyz123", type = "screencopy", mode = "allow" })
