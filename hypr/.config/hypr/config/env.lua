-- hypr/.config/hypr/config/env.lua — Hyprland-internal env vars (Lua port
-- of config/env.conf, Phase 13.1). Most env vars are now managed by UWSM:
--   ~/.config/uwsm/env          (shared)
--   ~/.config/uwsm/env-hyprland (NVIDIA/Hyprland)
-- Only Hyprland-internal vars remain here — same two hl.env(...) calls as
-- env.conf's two `env = ` declarations, positional (name, value) form
-- confirmed by the shipped /usr/share/hypr/hyprland.lua example.
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")

-- GTK_THEME's single source of truth is uwsm/.config/uwsm/env (D-13/
-- PIPE-05) — do not duplicate it here.
