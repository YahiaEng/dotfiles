# Phase 4: Reliability Fixes & Tech Debt - Context

**Gathered:** 2026-07-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Root-cause and fix three reliability/performance defects — the wlogout shutdown blank-screen hang (FIX-01), the hyprlock first-keystroke drop (FIX-02), and slow kitty terminal startup (FIX-03) — and close the v1.0 tech-debt carry-over by listing rsync explicitly in install.sh PACMAN_PKGS (DEBT-01). This is a pure reliability phase: it de-risks the base before Phase 6 redesigns anything. No visual redesign work lands here — wlogout/hyprlock looks stay roughly as-is even if a tool gets replaced.

</domain>

<decisions>
## Implementation Decisions

### Kitty startup fix scope (FIX-03)
- **D-01:** Follow the profile — the fix goes wherever profiling points (kitty config, .zshrc, or both). Editing shell startup is fully in scope.
- **D-02:** Fastfetch stays on every new terminal (it's part of the experience) but gets trimmed: remove heavy modules such as Display Manager detection and slow disk/power polling. Savings come primarily from the other suspects.
- **D-03:** Vendor the oh-my-posh catppuccin theme JSON locally into the zshell stow package and point `oh-my-posh init` at the local file — no remote GitHub URL at shell startup (offline-safe, reproducible via stow).
- **D-04:** Lazy-load node tooling (nvm, bun) — defer sourcing until the first `node`/`npm`/`nvm`/`bun` invocation (standard shim pattern).
- **D-05:** If zinit plugin load is heavy, use zinit turbo mode (`wait` ices) to load plugins asynchronously after the prompt. No plugins dropped.
- **D-06:** No kitty single-instance masking — keep normal per-window kitty processes and fix the actual startup cost.

### Shell evaluation (zsh vs fish)
- **D-07:** Benchmark optimized zsh vs fish side-by-side during this phase **regardless** of whether optimized zsh meets the target — then pick the winner. Fish is the only candidate shell.
- **D-08:** Decision rule: speed + feel, user judges. The executor presents cold/warm time-to-usable-prompt numbers for both shells plus a short trade-off note; the user makes the final call at a checkpoint.
- **D-09:** If fish wins, do a full switch in this phase: new fish stow package, kitty launches fish, install.sh installs fish, config parity ported.
- **D-10:** Day-one parity checklist for fish (all non-negotiable): oh-my-posh prompt look (from the vendored local config), fzf + zoxide + completions, trimmed fastfetch greeting, working node tooling (lazy pattern or fish-native equivalent like nvm.fish).
- **D-11:** The zshell stow package stays in the repo as an installable fallback — zsh remains a working recovery/fallback shell even after a fish switch.
- **D-12:** Shell is set via kitty config (`shell fish` in kitty.conf), NOT chsh — the system login shell stays zsh. Declarative via stow, zero install.sh mutation, and the TTY recovery path keeps the proven zsh setup.

### wlogout fix policy (FIX-01)
- **D-13:** Diagnose first per success criteria (keyboard-vs-mouse test, journalctl/coredumpctl). If a uwsm session-teardown race is confirmed, rewrite actions uwsm-correct (end the uwsm session cleanly before/via poweroff, per the uwsm-documented pattern) — fix the class of bug, not the symptom.
- **D-14:** Audit all six wlogout actions (lock, logout, suspend, hibernate, shutdown, reboot) against the uwsm session model while in there — not just shutdown/reboot.
- **D-15:** If diagnosis points to an upstream wlogout bug (not our config), evaluate replacements rather than working around a dying tool. Preference order: **wleave first** (maintained near-drop-in wlogout fork — minimal migration, theming carries over), with the Phase 7 walker power menu unaffected.
- **D-16:** Even if a replacement happens, Phase 4 delivers function only — a reliably-working power menu with roughly current looks. All redesign/theming polish stays in Phase 6 (WLOG-01 would then target the new tool).

### Hyprlock fix policy (FIX-02)
- **D-17:** Symptom fingerprint: the keystroke drop happens **right after manual lock** (lock via keybind/menu, type immediately, first chars vanish) — points at the grace period or input-grab timing at lock startup, not the idle/resume path.
- **D-18:** The 5-second grace unlock is droppable: if diagnosis implicates `grace = 5`, set `grace = 0`. Predictable lock behavior beats the convenience.
- **D-19:** A config-level mitigation (grace=0, disabling fade, version bump/pin) satisfies FIX-02 — as long as the root cause is documented with evidence. No obligation to patch hyprlock itself.
- **D-20:** Write the documented lockout-recovery procedure (second TTY logged in, `pkill hyprlock` escape hatch) NOW, before the first hyprlock test in this phase. Phase 6 (LOCK-01) reuses the same document.

### Verification protocols
- **D-21:** Kitty: measure time-to-usable-prompt (keypress → interactive prompt), before and after, with a concrete budget — starting target ~400ms warm. Captures the full experience including zsh/fish + fastfetch.
- **D-22:** wlogout: 5 consecutive real shutdown/reboot cycles via the menu (mix of keyboard and mouse selection), all completing cleanly, journalctl checked after each for teardown errors.
- **D-23:** Hyprlock: ~10 scripted lock→immediately-type-password trials that must unlock first try, covering both manual-lock and idle-lock trigger paths. Pass = 100%.
- **D-24:** These are one-time documented protocols recorded in the phase VERIFICATION records — no permanent rerunnable gates in verify/. DEBT-01 is covered by the existing container gate rerun.

### Diagnosis documentation
- **D-25:** Root-cause write-ups live in the phase's planning artifacts (SUMMARY/VERIFICATION per plan), v1.0-style. If a diagnosis produces a project-level decision (shell switch, wlogout replacement), add a line to PROJECT.md Key Decisions.

### Claude's Discretion
- Benchmark methodology (tooling like hyperfine, cold-vs-warm run counts, exact trial procedure) — planner/executor pick.
- Exact fastfetch modules to trim beyond the named ones (DM detection, disk/power polling) — profile-driven.
- Fish config file organization within the new stow package.
- The precise uwsm-correct action commands — research the uwsm-documented pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — FIX-01, FIX-02, FIX-03, DEBT-01 definitions
- `.planning/ROADMAP.md` — Phase 4 goal + success criteria (diagnosis mandate: keyboard-vs-mouse test, journalctl/coredumpctl, before/after profiling)

### Defect surfaces (files under diagnosis/fix)
- `wlogout/.config/wlogout/layout` — all six actions; shutdown runs bare `systemctl poweroff`
- `hypr/.config/hypr/scripts/wlogout.sh` — toggle launcher (`wlogout --protocol layer-shell -b 6 -T 400 -B 400 &`)
- `hypr/.config/hypr/config/keybinds.conf` — $mainMod SHIFT+Q binds wlogout.sh
- `hypr/.config/hypr/hyprlock.conf` — `grace = 5`, `fade_on_empty = true`, themed via `source = ~/.local/state/theme/hyprland.conf`
- `hypr/.config/hypr/hypridle.conf` — `lock_cmd = pidof hyprlock || hyprlock`, `loginctl lock-session` on timeout
- `kitty/.config/kitty/kitty.conf` — small config; includes `~/.local/state/theme/kitty.conf`
- `zshell/.zshrc` — fastfetch on every interactive shell; zinit; oh-my-posh init with REMOTE GitHub URL config; nvm + bun sourced synchronously; fzf + zoxide evals
- `install.sh` — PACMAN_PKGS array (~line 52) missing explicit rsync (DEBT-01)

No external specs/ADRs beyond the above — requirements fully captured in decisions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `verify/` container gate harness — reruns install.sh end-to-end; covers DEBT-01 automatically once rsync is added to PACMAN_PKGS
- Theme pipeline state dir (`~/.local/state/theme/`) — hyprlock and kitty already consume it; any tool replacement (wleave) must keep consuming it the same way
- v1.0 phase SUMMARY/VERIFICATION document patterns in `.planning/milestones/v1.0-phases/` — the model for diagnosis write-ups

### Established Patterns
- Root-cause over patch-around (v1.0 key decision, restated in this phase's success criteria)
- One stow package per app — a fish adoption means a new `fish/` stow package; zshell package retained as fallback
- uwsm-managed session (`uwsm app --` launches, `uwsm stop` for logout) — all session-affecting commands must be uwsm-aware
- Headless guards in scripts (v1.0 lesson: `swaync-client -rs` hung in containers) — any new shell startup logic must not break the container gate

### Integration Points
- kitty.conf `shell` directive — the chosen switch point for fish (login shell stays zsh)
- install.sh PACMAN_PKGS — rsync (DEBT-01) and fish (if adopted) both land here
- Phase 6 dependencies: WLOG-01 redesign targets whatever power-menu tool survives this phase; LOCK-01 reuses this phase's lockout-recovery doc

</code_context>

<specifics>
## Specific Ideas

- Keystroke-drop fingerprint from the user: happens right after MANUAL lock (keybind/menu → type immediately), not on idle/suspend wake — diagnosis should start at the grace-period/input-grab-timing hypothesis.
- User explicitly open to replacing tools that are broken upstream rather than accumulating workarounds: wleave named for wlogout, fish named for the shell.
- "Fastfetch on every new terminal is part of the experience" — do not remove it, trim it.

</specifics>

<deferred>
## Deferred Ideas

- Nushell evaluation — considered as a second benchmark candidate, rejected for this phase (fish only). Revisit only if fish disappoints.
- Retiring the zshell stow package — deliberately NOT happening this phase; revisit after fish (if adopted) has proven itself in daily use.
- Permanent rerunnable reliability gates (kitty startup benchmark in verify/) — considered, rejected for this phase; reconsider if startup regresses again later.

</deferred>

---

*Phase: 4-Reliability Fixes & Tech Debt*
*Context gathered: 2026-07-09*
