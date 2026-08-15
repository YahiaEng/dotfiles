# Phase 20 API Coverage

No external API integration: this phase builds local Quickshell/QML layer-shell surfaces
(the volume/brightness/caps-lock OSD and the power menu) that drive already-installed system
binaries (`wpctl`, `brightnessctl`, `systemctl`, `hyprshutdown`, `uwsm`, `pgrep`) and a
world-readable kernel sysfs read (`/sys/class/leds/*::capslock/brightness`). There is no network
call, no SDK, no authentication, and no third-party service surface anywhere in this phase's
scope — every dependency is either a local process invocation already present on this host or a
local filesystem read of a kernel-exposed device attribute.
