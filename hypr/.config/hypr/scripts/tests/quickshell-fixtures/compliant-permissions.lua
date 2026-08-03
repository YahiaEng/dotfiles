-- compliant-permissions.lua — synthetic fixture (Phase 16 Plan 04, D-16-23
-- check 5) modelled on the real hypr/.config/hypr/config/permissions.lua's
-- own hl.permission() call shape. Two grants, both exact absolute paths to
-- binaries that are base-system dependencies guaranteed present and
-- executable on any host capable of running this repo's own bash scripts
-- (/usr/bin/bash and /usr/bin/env) — so this fixture's PASS verdict never
-- depends on which optional packages happen to be installed. Target check:
-- permissions-allowlist-paths-resolve. Expected verdict: PASS — every
-- granted path exists, is executable, and contains no glob/alternation
-- metacharacter (T-11-20 discipline).

hl.config({ ecosystem = { enforce_permissions = true } })

hl.permission({ binary = "/usr/bin/bash", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/bin/env", type = "screencopy", mode = "allow" })
