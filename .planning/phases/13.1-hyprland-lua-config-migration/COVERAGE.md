No external API integration: this phase touches only the local Hyprland compositor's own Lua configuration API, shipped inside the already-installed `hyprland` package (type stub at `/usr/share/hypr/stubs/hl.meta.lua`), and the `hyprctl` IPC socket already present on this machine — no network service, external API, SDK, or credential is added or contacted.

## Why this phase trips the detector

The ROADMAP sentence "The actual Lua **API** is unverified" contains the noun `api`, which is what fires the deterministic api-coverage detector for this phase. That phrase refers to Hyprland's own local, in-process configuration API (the Lua config manager Hyprland 0.57 ships in place of hyprlang `.conf` parsing) — not an integration with any external, third-party, or network-reachable API.

## What this phase actually touches

- **Hyprland's Lua configuration API** — a local compositor-internal API exposed to `hyprland.lua` and the files it `require()`s, documented (partially) by the vendor-shipped type stub at `/usr/share/hypr/stubs/hl.meta.lua`. Verified empirically against the installed binary per D-15/13.1-CONTEXT.md, not assumed from documentation.
- **The `hyprctl` IPC socket** — a Unix domain socket already present on this machine, used read-only by `hypr-equivalence-check` (`-j getoption`, `-j binds`, `-j animations`, `version`) to prove pre/post-migration behavioural equivalence.

## What this phase does not add

- No new network endpoint, remote service, or third-party API client.
- No new credential, API key, or secret.
- No new package-manager dependency for API access — `hyprland` (already installed) already ships `lua`, the Lua config manager, the example config, and the type stub (`13.1-RESEARCH.md` §"Package Legitimacy Audit").
