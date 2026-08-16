-- hypr/.config/hypr/config/env.lua — Hyprland-internal env vars (Lua port
-- of config/env.conf, Phase 13.1). Most env vars are now managed by UWSM:
--   ~/.config/uwsm/env          (shared)
--   ~/.config/uwsm/env-hyprland (NVIDIA/Hyprland)
-- Only Hyprland-internal vars remain here — same two hl.env(...) calls as
-- env.conf's two `env = ` declarations, positional (name, value) form
-- confirmed by the shipped /usr/share/hypr/hyprland.lua example.
--
-- D-32 (Phase 17 plan 05, option-c) unifies the cursor identity across
-- BOTH format families rather than splitting by client type:
-- XCURSOR_THEME reads BreezeX-RosePine-Linux (the real installed
-- directory of the `rose-pine-cursor` AUR package — NOT its package
-- name, confirmed by reading the PKGBUILD and verifying on disk).
-- HYPRCURSOR_THEME/HYPRCURSOR_SIZE are new here: Hyprland reads these for
-- every native Wayland client (kitty, walker, the Quickshell shell
-- process — which now carries the bar, the notification surfaces, the
-- OSD, the power menu and the dashboard in one process — and
-- Thunar-under-Wayland), pointed at `rose-pine-hyprcursor`
-- (already installed, 17-04) — the hyprcursor-format sibling of the same
-- BreezeX-remixed-to-Rose-Pine shape family (rose-pine-hyprcursor's own
-- manifest.hl description literally says so), so native and XWayland
-- clients render matching shapes/colors instead of two unrelated themes.
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")

-- GTK_THEME's single source of truth is uwsm/.config/uwsm/env (D-13/
-- PIPE-05) — do not duplicate it here.
