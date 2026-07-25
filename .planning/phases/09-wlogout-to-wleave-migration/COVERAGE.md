# API Coverage — Phase 09 (wlogout to wleave migration)

> Full coverage by default. Opt-outs are explicit, reasoned decisions.

No external API integration: this phase swaps one locally-installed Wayland layer-shell binary (wleave 0.7.1, AUR) for another and rewires local config files — the only "surfaces" touched are a JSON layout file, a GTK4 stylesheet, Hyprland layerrules, shell scripts, and the repo's own matugen/theme-engine pipeline. No network endpoint, SDK, REST/GraphQL/gRPC surface, webhook, or third-party service is consumed.

The deterministic detector was run over this phase's scope at plan time and returned `{"detected": false, "signals": []}`; this declaration is recorded so the seal-time gate has an explicit, reasoned artefact rather than re-deriving the same negative.

| capability | decision | reason |
|---|---|---|
| _(none — no external API surface exists in this phase)_ | | |
