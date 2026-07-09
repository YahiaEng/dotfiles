# Phase 1: Root-Cause Fix & Consolidated Theme Engine - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Every visible desktop app re-themes live from a single shared engine. The verified stuck-white root cause (the `adw-gtk3` package name in install.sh doesn't exist — the real package is `adw-gtk-theme` in `extra`, and the theme is not installed on this machine) is eliminated, the duplicated orchestration in `theme-switch.sh` / `theme-init.sh` is consolidated into one `theme-apply` entrypoint, generated output moves out of the git tree, and a documented full-repo audit (SCAN-01) breaks the patch-without-diagnosing loop. Covers THEME-01..06, PIPE-01, PIPE-02, PIPE-03, PIPE-05, SCAN-01, SCAN-02.

Out of this phase: static↔dynamic parity proof and switch stress-testing (Phase 2), repo cleanup / install.sh hardening / fresh-VM verification (Phase 3), all v2 expansion (OSD, walker menus, media widget, light themes).

</domain>

<decisions>
## Implementation Decisions

### Engine shape & interface
- **D-01:** Single entrypoint `theme-apply <name>` (e.g. `theme-apply catppuccin`, `theme-apply materialyou`) handles static and dynamic internally and owns the reload fan-out. The walker dmenu picker and login init become thin callers — picker only picks a name, init only reads the state file.
- **D-02:** The engine lives in its own new stow package (`theme-engine/` or similar), not in `hypr/.config/hypr/scripts/`. Theming becomes a first-class component decoupled from the hypr package.
- **D-03:** **One rendering path:** static presets become palette definitions fed into the same matugen template fan-out used by wallpaper themes — parity by construction. Research MUST verify matugen 4.1 supports preset-palette input cleanly; if not, fall back to dual paths writing an identical, contract-enforced output structure.
- **D-04:** The engine owns ALL reload fan-out (PIPE-02). Strip every `post_hook` from `matugen/.config/matugen/config.toml`; `theme-apply` runs one ordered reload step after rendering completes — reloads never fire on partially-rendered state.

### Generated output location & wiring
- **D-05:** Generated output lands in `~/.local/state/theme/` (XDG_STATE_HOME — survives cache wipes, outside the repo). The saved-theme state file moves there too (replacing `~/.cache/current-theme`).
- **D-06:** Output contract is **per-app files** (hyprland.conf, waybar.css, kitty.conf, gtk.css, …) with shared variable names across CSS files. Phase 2 will diff this structure for parity.
- **D-07:** Apps consume via **native imports where they exist** (waybar/swaync CSS `@import`, hyprland `source=`, kitty `include` — all pointing at `~/.local/state/theme/`); apps with no include mechanism (yazi theme.toml, walker style.css) get direct writes/symlinks to their config path, gitignored.
- **D-08:** GTK: the stowed `~/.config/gtk-{3,4}.0/gtk.css` becomes a static file that `@import`s the state-dir palette, followed by the base rules. No `cat colors.css gtk-base.css` concatenation anywhere. Research must verify GTK CSS `@import` path semantics (relative vs absolute).
- **D-09:** One-time wiring, no per-login hacks: the walker rice-theme dir dance in theme-init.sh (delete stow symlink, mkdir, rm style.css symlink every login) is replaced by wiring established once by the engine/stow setup. `.stow-local-ignore` excludes what must not be symlinked.
- **D-10:** First boot: `theme-init` (login) calls `theme-apply` with the saved theme, falling back to **Catppuccin Mocha** when no state exists. Repo tracks zero generated color files; install.sh needs no pre-generation step.
- **D-11:** Wofi is never added to the new engine (no template, no target). Physical removal of wofi configs stays in Phase 3.
- **D-12:** Fan-out targets: all ten as today — Hyprland, waybar, kitty, swaync, wlogout, GTK3 (Thunar), GTK4/libadwaita, walker, yazi, vscodium.
- **D-13:** `GTK_THEME`'s single source of truth is the uwsm env file (`~/.config/uwsm/env`) (PIPE-05). Scripts stop exporting it ad hoc; the engine only propagates via `dbus-update-activation-environment` / `systemctl --user import-environment` when needed.
- **D-14:** Theme application is **atomic (render-then-commit):** render everything to a temp dir, move into `~/.local/state/theme/` only on full success, then reload. A failed render leaves the desktop untouched.

### Switch UX & disruption
- **D-15:** Thunar: restart only the background `thunar --daemon` — never kill visible windows. Open windows may keep the old palette until closed; the next window opens themed. Research checks whether the adw-gtk-theme fix + gsettings gtk-theme toggle re-themes *running* GTK3 windows live (GTK3 follows `gtk-theme-name` changes), which would make even open windows update.
- **D-16:** Walker: prefer `hotreload_theme` (research verifies it works on walker 2.16); fall back to a hardened restart that also checks elephant health (ties into SCAN-02). Prefer the lightest mechanism that is 100% reliable.
- **D-17:** **Dark-only for v1.** Hardcoded `prefer-dark` / `adw-gtk3-dark` is acceptable. Engine design leaves a seam for a per-theme dark/light attribute but builds/tests no light support. Light themes are a v2 THEMES item.
- **D-18:** Feedback: keep success toast (theme name) + loud error notifications. With render-then-commit, error messages should state the desktop was left unchanged.
- **D-19:** Wallpaper setting is owned by the engine/picker: set `set = false` (or remove `[config.wallpaper]`) in matugen config; `awww` is called only by the wallpaper picker and theme-init. Matugen only renders templates.
- **D-20:** An explicit wallpaper pick while Material You is active re-runs `theme-apply materialyou` — wallpaper and palette always match in dynamic mode. In static mode, picking a wallpaper changes only the wallpaper. (Re-theme on wallpaper auto-cycle remains out of scope.)
- **D-21:** Latency: **visible surface flips in <1s** (Hyprland borders, waybar, kitty, swaync, wallpaper — the signal-reload set). Restart-based targets (Thunar daemon, walker restart fallback, vscodium) may finish 1–2s later in the background, guaranteed correct by next interaction. Soft target — no correctness trade-offs to chase it; it must not displace render-then-commit or reliability.

### Audit format & fix policy
- **D-22:** Audit deliverable is a single `AUDIT.md` in the phase directory: findings grouped by component (theme pipeline, hyprland/keybinds, uwsm, stow, install scripts), each with severity (critical/major/minor), evidence (`file:line`), and disposition (`fix-in-phase-1` / `fix-in-phase-2` / `fix-in-phase-3` / `wontfix`).
- **D-23:** Fix policy: **fix everything found in Phase 1, except findings explicitly owned by Phase 2/3 requirements** (parity stress → P2; install.sh packages, stow guards, dead-config removal → P3). Deferred findings carry their phase assignment in AUDIT.md so nothing waits without an owner. Roadmap phase boundaries stay intact.
- **D-24:** Sequencing: **audit first, then fix.** Complete the full-repo audit and write AUDIT.md before building the engine — findings inform engine design. Exception: the trivially-verified root cause (install `adw-gtk-theme`) lands immediately alongside the audit.
- **D-25:** Regression protection is scripted: a rerunnable check script (e.g. `theme-doctor`) verifies the invariants — adw-gtk-theme installed, gsettings values correct, elephant running and version-matched with walker, state-dir files present, no stow conflicts. Phase 2's stress test and Phase 3's VM verification reuse it.

### Claude's Discretion
- Exact name/layout of the new stow package and script names (`theme-apply`, `theme-doctor` are working names).
- Internal engine structure (single script vs script + sourced lib), argument parsing, logging.
- Per-app reload mechanics beyond the decisions above (signals vs client commands), ordering of the reload step.
- How theme-init and the pickers pass through to the engine (exec vs source).
- Whether vscodium-theme.sh gets absorbed into the engine or stays a called helper.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — requirement IDs (THEME-01..06, PIPE-01..06, SCAN-01/02, INST, CLEAN) this phase maps to
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, and the 3-plan breakdown

### Project research (verified findings — root cause lives here)
- `.planning/research/SUMMARY.md` — synthesized research; start here
- `.planning/research/STACK.md` — verified package/version facts: `adw-gtk-theme` (not `adw-gtk3`) is the correct package; walker 2.x = walker frontend + elephant backend daemon; GSettings/portal layer verified correct on this machine
- `.planning/research/PITFALLS.md` — known failure modes for GTK theming on Wayland (xsettingsd trap, GTK3 no-CSS-hot-reload, SIGUSR2 waybar tooltip issue)
- `.planning/research/ARCHITECTURE.md` — current pipeline architecture analysis
- `.planning/research/FEATURES.md` — feature research for this and future milestones

### Current implementation (the code being consolidated)
- `hypr/.config/hypr/scripts/theme-switch.sh` — interactive switcher (picker + apply + reload_all, to be split)
- `hypr/.config/hypr/scripts/theme-init.sh` — login restore (duplicates apply logic; walker dir hack lives here)
- `hypr/.config/hypr/scripts/gtk-reload.sh` — GTK reload + Thunar kill/restart + one of three GTK_THEME hardcodes
- `hypr/.config/hypr/scripts/walker-restart.sh`, `hypr/.config/hypr/scripts/walker-theme-gen.sh` — walker theming path
- `matugen/.config/matugen/config.toml` — template fan-out + post_hooks to strip + `[config.wallpaper]` to disable
- `themes/.config/themes/` — static preset sources (static/, css/, gtk/, kitty/, yazi/, vscodium/)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `matugen/.config/matugen/templates/*` — 10 working templates; become the single rendering path for both modes (output paths change to the state dir)
- `themes/.config/themes/` static presets — 6 themes × per-app files; become palette definitions feeding matugen (D-03) or stay as contract-matched sources in fallback
- `walker-theme-gen.sh` — proves walker needs hardcoded hex (no `@define-color`); logic folds into a matugen template
- Existing notify-send feedback pattern in theme-switch.sh — keep (D-18)

### Established Patterns
- Reload mechanisms already known-good: `hyprctl reload`, `pkill -SIGUSR2 waybar`, `pkill -SIGUSR1 kitty`, `swaync-client -rs`
- `uwsm app --` launch pattern for user services (thunar daemon relaunch)
- Stow package-per-app repo layout — the new theme-engine package must follow it
- GSettings/dconf + portal layer verified correctly configured (research) — do NOT add xsettingsd

### Integration Points
- `hypr/.config/hypr/config/autostart.conf` — where theme-init runs at login
- Hyprland keybinds — where the theme picker and wallpaper picker are bound
- `.stow-local-ignore` + `stow.sh` — wiring for files that must not be stow-symlinked (walker theme dir)
- `install.sh` AUR_PKGS list — the `adw-gtk3` → `adw-gtk-theme` fix (the immediate root-cause fix; full install.sh hardening is Phase 3)

### Known duplication being eliminated (verified in scout)
- theme-switch.sh and theme-init.sh duplicate ~80 lines of apply/reload logic (PIPE-01)
- Reload fan-out fires twice in dynamic mode: matugen post_hooks AND reload_all() (PIPE-02)
- Generated colors write through stow symlinks into the repo, dirtying git on every switch (PIPE-03)
- `GTK_THEME=adw-gtk3-dark` hardcoded in theme-init.sh, gtk-reload.sh (×2 including Thunar relaunch line) (PIPE-05)

</code_context>

<specifics>
## Specific Ideas

- "Sub-second, snappy" is the user's felt requirement for switching — clarified to visible-surface-<1s with background stragglers allowed (D-21). Planning should bias toward signal reloads and hotreload over restarts wherever reliable.
- The user chose "fix everything found" instinctively before settling on the P2/P3 carve-out — they have low tolerance for known-broken things sitting unfixed. AUDIT.md dispositions must make deferred items feel owned, not dropped.

</specifics>

<deferred>
## Deferred Ideas

- **Light theme support (per-theme dark/light attribute)** — engine leaves a seam (D-17); actual support is a v2 THEMES item.
- None other — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Root-Cause Fix & Consolidated Theme Engine*
*Context gathered: 2026-07-07*
