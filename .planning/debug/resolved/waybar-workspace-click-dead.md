---
status: resolved
trigger: "clicking on waybar workspaces does nothing. I can only switch workspaces through keyboard shortcuts"
created: 2026-07-28T11:05:00Z
updated: 2026-07-28T17:55:00Z
---

## Current Focus
<!-- OVERWRITE on each update - always reflects NOW -->

hypothesis: ROOT CAUSE ALREADY PROVEN (see Resolution). No longer under investigation. Operator selected BRANCH C — retarget the repo-owned legacy `hyprctl dispatch <string>` call sites to the Lua `hl.dsp.*` expression form, and accept waybar's compiled-in workspace CLICK as scheduled technical debt that dies with waybar when Quickshell lands.
test: Per-site empirical proof. Workspace sites: capture `hyprctl activeworkspace` before/after each edited command form and require an observable STATE CHANGE (exit 0 alone is NOT proof — both `hyprctl keyword` and legacy `hyprctl dispatch` exit 0 on some failing paths on this system). DPMS sites: held to a higher bar — `hl.dsp.dpms()` and `hl.dsp.dpms("bogus")` were both previously observed returning `ok` with no error, so the namespace silently accepts junk; the argument shape must be established from the `hyprctl monitors -j` `dpmsStatus` field flipping, never from the reply.
expecting: Each retargeted command produces the state change its legacy predecessor was supposed to produce. If the DPMS argument shape cannot be established from observed `dpmsStatus` transitions, those three hypridle.conf lines are left UNFIXED with a plain explanation rather than shipping an unverified change to display power management.
next_action: HUMAN VERIFICATION. All 7 sites retargeted and self-verified 9/9 against compositor state (see Resolution.verification). The one link no tool on this box can drive is the waybar SCROLL gesture — scroll the mouse wheel over the workspace buttons in the bar and confirm it moves between workspaces. Expect the workspace CLICK to remain dead: that is accepted debt, not a regression (see debt item (a)).
bug_class: Bohrbug — fully deterministic, reproduced on demand from a bare CLI invocation, zero flakiness across ~12 trials.

RESTORE TARGET (recorded before any testing): workspace 1 on monitor DP-1.
RESTORE STATUS (investigation phase): RESTORED AND VERIFIED — active workspace is 1 on DP-1; workspace list back to {1,2}; the transient `ai` workspace created during API probing was auto-reaped on leave. Theme untouched (catppuccin). Compositor never restarted; hyprlock never signalled.
RESTORE TARGET (fix phase, re-recorded 2026-07-28T17:05Z): workspace 1 on monitor DP-1. DP-1 dpmsStatus=true (display ON). hyprlock NOT running at fix-phase start. hypridle running as pid 998, parented to the compositor (pid 956) via `exec-once = uwsm app -- hypridle` — it is NOT a systemd user unit (`systemctl --user is-active hypridle.service` → inactive), so "restart the service" means kill + relaunch through uwsm.

fix_branch: C (operator-selected)
  - REJECTED A (waybar-git): throwaway `-git` package in install.sh's reproducible path for a component scheduled for deletion.
  - REJECTED B (roll back to hyprlang): would undo an equivalence-proven migration for the sake of the component being deleted.
  - Quickshell does not have this bug class at all — its QML uses `GlobalShortcut` (Wayland protocol), zero IPC dispatch string sites — so replacing waybar structurally removes it.
  - Fix pattern is NOT invented here: plan 13.1-09 already established it in
    `theme-engine/.config/theme-engine/theme-stress-test` lines 368 and 571
    (`hyprctl dispatch 'hl.dsp.global("quickshell:probe")'`) with a documenting comment at ~352-367.

reasoning_checkpoint:
  hypothesis: "Hyprland 0.56.1 booted from a Lua config withdraws the legacy string form of the IPC `dispatch` command — the handler unconditionally rewrites the payload to `return hl.dispatch(<payload>)` and evaluates it as Lua SOURCE. Waybar 0.15.0 has the legacy string `dispatch workspace <id>` compiled into `Workspace::handleClicked` and discards the IPC reply, so each click produces a Lua parse error that nobody reads and the workspace never changes."
  confirming_evidence:
    - "Direct observation: `hyprctl dispatch workspace 2` returns `error: [string \"return hl.dispatch(workspace 2)\"]:1: ')' expected near '2'`, exit 7, and `hyprctl activeworkspace` is unchanged before/after."
    - "Same payload over the raw `.socket.sock` (waybar's actual transport, via a Python AF_UNIX client, bypassing the hyprctl binary) reproduces byte-identically — the fault is in the compositor IPC handler, not the CLI wrapper."
    - "`strings /usr/bin/waybar` shows the literals `dispatch workspace `, `dispatch workspace name:`, `dispatch focusworkspaceoncurrentmonitor `, `dispatch togglespecialworkspace ` — and NO `hl.dsp`/`hl.dispatch` string anywhere, proving the installed build emits only the withdrawn syntax."
    - "The Lua-native equivalent works live: `hl.dsp.focus({workspace=2})` returned ok/exit 0 and actually moved 1→2, so the compositor capability is intact and only the string API was removed."
    - "Upstream corroboration: Waybar issue #5008/#5035, Hyprland discussion #14255, and Waybar PR #5013 (\"adapt dispatch commands for Lua IPC protocol\", merged 2026-05-04) — released 0.15.0 predates the merge."
  falsification_test: "If `hyprctl dispatch workspace 2` had switched workspaces, the compositor IPC path would be fine and the fault would have to be in waybar's config/build. It did not. Conversely, if waybar's binary had contained `hl.dsp` strings, the installed build would already carry PR #5013 and the diagnosis would be wrong. It does not."
  fix_rationale: "Root cause is an upstream API contract break, so the only fixes that address the CAUSE (rather than the symptom) are: make the caller speak the new API (upgrade waybar to a build carrying PR #5013), or restore the old contract (boot the compositor from hyprlang again). Rewriting the waybar config CANNOT work — the dispatch is compiled into C++ and `man 5 waybar-hyprland-workspaces` documents no `on-click` key for this module."
  blind_spots:
    - "Could not self-verify the click end-to-end: no pointer-injection tool exists on this box (ydotool/wlrctl/dotool all absent; wtype is keyboard-only). Any fix REQUIRES a human click-test — the same limitation that closed the eww-media-popup session."
    - "Have not confirmed that AUR waybar-git r822 builds cleanly on this machine, nor that it introduces no other regression relative to 0.15.0-2."
    - "`hl.dsp.dpms()` and `hl.dsp.dpms(\"bogus\")` both returned `ok` with no error — the correct dpms argument shape is NOT yet established, and that namespace appears to silently accept junk. Did not probe further to avoid blanking the live display."
  candidate_causes:
    - "environment/config: compositor booted from hyprland.lua, which withdraws the legacy IPC dispatch string API (CONFIRMED)"
    - "code (third-party binary): waybar 0.15.0 hardcodes the legacy dispatch string AND discards the IPC error reply (CONFIRMED)"
    - "code (repo-owned): waybar config `on-click: activate` is inert for this module — a red herring, not a cause (CHECKED, not causal)"
    - "data: none — no user data participates in this path (RULED OUT)"
  and_gate: "YES — genuinely two simultaneous conditions. Under hyprlang, waybar's hardcoded legacy string is harmless (worked this morning). Under Lua, a caller using the new API works fine (keybinds.lua proves it). The failure needs BOTH the Lua-config compositor AND a caller still emitting the withdrawn syntax. This is also exactly why the keyboard path survives — it satisfies only condition 1, not condition 2."
reasoning_checkpoint: null
tdd_checkpoint: null

## Symptoms
<!-- Written during gathering, then immutable -->

expected: Clicking a workspace button in waybar switches the compositor to that workspace.
actual: Clicking a workspace button does nothing at all. Workspace switching still works via keyboard shortcuts. Hover highlight on the buttons DOES work, so pointer input reaches waybar and the GTK widget responds — only the click action fails to take effect.
errors: None surfaced to the user. Note the closely-related known finding from this phase: `hyprctl keyword` under the Lua config manager prints "keyword can't work with non-legacy parsers. Use eval." and still exits 0 — a silent-failure pattern that other hyprctl/IPC paths may share.
reproduction: Click any workspace button in the waybar bar on the live session. Nothing happens. Keyboard workspace binds (Super+1..N) still work normally.
started: Worked this morning under the hyprlang config. Broke after the phase 13.1 cutover to `~/.config/hypr/hyprland.lua` (live session pid 956, `[cfg] Using lua config found at /home/aorus/.config/hypr/hyprland.lua`). Scope is narrow: every other waybar module (clock, volume, power/wleave, tray) still responds to clicks normally — only the workspaces module is affected.

## Eliminated
<!-- APPEND only - prevents re-investigating after /clear -->

- hypothesis: Waybar is not receiving pointer input at all (layer-shell / input-region problem).
  evidence: Hover highlight on the workspace buttons works, and every other waybar module responds to clicks normally.
  timestamp: 2026-07-28T11:05:00Z

- hypothesis: Waybar is talking to a STALE compositor instance — a `HYPRLAND_INSTANCE_SIGNATURE` left over from before the Lua cutover would send dispatches to a dead socket while leaving rendering intact.
  evidence: `/proc/476510/environ` HIS is `5c9377c15f85c50648f35ca5a213754f95b93ca0_1785230839_446403004`, byte-identical to the live `hyprctl instances` signature (pid 956). Additionally waybar (started 15:32:21) is NEWER than the compositor (started 12:27:20), so it could not have survived a cutover. DISPROVEN.
  timestamp: 2026-07-28T15:40:00Z

## Evidence
<!-- APPEND only - facts discovered during investigation -->

- timestamp: 2026-07-28T11:05:00Z
  checked: Timeline and scope, via direct user report.
  found: Worked this morning on hyprlang; broke after the Lua cutover. Only the workspaces module is affected. Hover works, click does not.
  implication: A migration regression localized to the workspaces module's dispatch path — not a general waybar input, styling, or layer-shell fault.

- timestamp: 2026-07-28T11:05:00Z
  checked: Prior phase-13.1 finding recorded in `.planning/phases/13.1-hyprland-lua-config-migration/deferred-items.md`.
  found: `hyprctl keyword` is a silent no-op under the Lua config manager — refuses the operation, prints a message naming `eval` as the replacement, yet exits 0.
  implication: The Lua config manager changes the behaviour of at least one hyprctl surface while still reporting success. Other dispatch/IPC surfaces must be verified rather than assumed working.

- timestamp: 2026-07-28T15:45:00Z
  checked: `hyprctl dispatch workspace 2` on the live Lua-booted session (workspace confirmed unchanged before/after).
  found: |
    error: [string "return hl.dispatch(workspace 2)"]:1: ')' expected near '2'
     → Note: dispatch in lua is a shorthand for hl.dispatch(...), your syntax might need to be updated.
    exit=7
  implication: THE MECHANISM. Under a Lua config the IPC `dispatch` command no longer parses `<dispatcher> <args>` as a legacy string — it textually wraps the payload into `return hl.dispatch(<payload>)` and evaluates it as LUA SOURCE. `workspace 2` is not valid Lua, so it dies at parse time. Note this path exits 7 (unlike `hyprctl keyword`, which exits 0) — so it is loud on the CLI but silent to any caller that ignores the reply, which is exactly what waybar does.

- timestamp: 2026-07-28T15:47:00Z
  checked: Raw `.socket.sock` (the exact transport waybar uses), bypassing the `hyprctl` binary — via a Python AF_UNIX client.
  found: `/dispatch workspace 2` returns the identical Lua parse error and does not switch workspaces. `/dispatch "workspace 2"` and `/dispatch "workspace", "2"` return `hl.dispatch: expected a dispatcher (e.g. hl.dsp.window.close())`.
  implication: The failure is in the compositor's IPC handler itself, not in the `hyprctl` CLI wrapper. Confirms waybar's own IPC path is affected. `hl.dispatch` requires a dispatcher OBJECT; no string form of any kind is accepted.

- timestamp: 2026-07-28T15:50:00Z
  checked: Whether a legacy fallback survives for canonical legacy dispatcher names — `hyprctl dispatch dpms on`.
  found: `error: [string "return hl.dispatch(dpms on)"]:1: ')' expected near 'on'`, exit 7.
  implication: There is NO legacy-first-then-Lua fallback. The Lua wrap is unconditional for every dispatcher name. This also means it is impossible to rescue waybar's payload from the Lua side — `workspace 2` / `workspace name:x` are Lua SYNTAX errors, and Lua's call sugar only permits `f"str"` / `f{table}`, never `f 2` or `f name:x`. No global shim, metatable, or `_ENV` trick can make waybar's exact bytes parse.

- timestamp: 2026-07-28T15:52:00Z
  checked: `strings /usr/bin/waybar` for the dispatch strings the workspaces module emits.
  found: Hardcoded literals `dispatch workspace `, `dispatch workspace name:`, `dispatch focusworkspaceoncurrentmonitor `, `dispatch focusworkspaceoncurrentmonitor name:`, `dispatch togglespecialworkspace `. `man 5 waybar-hyprland-workspaces` documents NO `on-click` key for this module at all.
  implication: The click dispatch is compiled into waybar's C++ (`Workspace::handleClicked`), not driven by config. The `"on-click": "activate"` key in `config-floating.jsonc` is inert for this module — the per-workspace GTK buttons consume the press before any AModule-level `on-click` could fire. THEREFORE THE CLICK CANNOT BE FIXED BY WAYBAR CONFIG ALONE.

- timestamp: 2026-07-28T15:55:00Z
  checked: Why keyboard workspace binds still work — `hypr/.config/hypr/config/keybinds.lua` lines 203-233.
  found: Binds are declared as native Lua dispatcher objects, e.g. `hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))`. COVERAGE.md confirms every Lua-registered bind reads back as `dispatcher: "__lua"` with an opaque integer `arg`.
  implication: RECONCILES THE COUNTER-EVIDENCE. Keyboard binds are resolved to dispatcher closures at config-LOAD time inside the compositor and are invoked directly on keypress. They never serialize through the IPC dispatch string parser, so the parser regression cannot touch them. One mechanism explains BOTH the working keyboard path and the dead click path.

- timestamp: 2026-07-28T15:57:00Z
  checked: The Lua-native equivalent, live, with before/after `hyprctl activeworkspace` readings.
  found: `hyprctl dispatch 'hl.dsp.focus({workspace=2})'` → `ok`, exit 0, workspace ACTUALLY CHANGED 1→2. Restored 2→1. `{workspace="e+1"}` / `{workspace="e-1"}` and `{workspace="name:ai"}` also verified working live.
  implication: The compositor-side capability is fully intact — only the string API was withdrawn. Any caller that can be edited is fixable; only compiled-in callers (waybar) are stuck.

- timestamp: 2026-07-28T15:59:00Z
  checked: `hl.dsp.exec_raw("workspace 2")`, suggested as the fix by a public web answer.
  found: Returns `ok`, exit 0, and the workspace DID NOT CHANGE. The stub shows `exec_cmd` is `fun(cmd: string, ...)` — a SHELL exec; `exec_raw` is its no-uwsm sibling.
  implication: The widely-circulated `hl.dsp.exec_raw("<legacy string>")` workaround is WRONG — it shell-executes the string, silently failing. Rejected on live evidence. `hl.dsp.focus({workspace=N})` is the correct form.

- timestamp: 2026-07-28T16:02:00Z
  checked: Blast radius — `grep -rn "hyprctl dispatch"` across the repo (excluding .git/.planning).
  found: Additional legacy-string call sites that are broken by the same mechanism, beyond waybar's internal one - `hypr/.config/hypr/hypridle.conf:8` (`after_sleep_cmd = hyprctl dispatch dpms on`), `:44` (`on-timeout = hyprctl dispatch dpms off`), `:45` (`on-resume = hyprctl dispatch dpms on`); `hypr/.config/hypr/scripts/ai-workspace.sh:58` and `hypr/.config/hypr/scripts/ai-webapp-launch.sh:28` (`hyprctl dispatch workspace name:ai`); `waybar/.config/waybar/config-floating.jsonc:98-99` (`hyprctl dispatch workspace e+1/e-1`); and ~8 `hyprctl dispatch global ...` sites in `scripts/quickshell-doctor`. `theme-engine/theme-stress-test` already uses the correct `hl.dsp.global(...)` form.
  implication: This is a WIDE migration regression, not a waybar-specific one. Most notably the 15-minute idle display-blank (`dpms off`) and its resume are silently dead. The waybar workspace click is the most visible symptom of a systemic API break, and the repo-owned call sites ARE fixable in config.

- timestamp: 2026-07-28T16:05:00Z
  checked: Upstream status via web search.
  found: This is a known, reported, cross-ecosystem break — Alexays/Waybar issue #5008 ("hyprland/workspaces: old-style workspace dispatch fails on Hyprland Lua dispatcher builds"), hyprwm/Hyprland discussion #14255 ("hyprctl dispatch rejects legacy syntax under Lua config"), noctalia-shell issue #2603, and a Hyprland forum thread on waybar behaving differently under .conf vs .lua. Upstream position is that downstream tools must adapt to the new Lua dispatch API.
  implication: Not a local misconfiguration and not something this repo did wrong — an upstream API break. No shipped waybar release yet carries a fix, so the click cannot be repaired by updating packages either.

- timestamp: 2026-07-28T17:20:00Z
  checked: FIX PHASE. The `hl.dsp.dpms` argument shape, held to the operator's higher bar. Static evidence first — `/usr/share/hypr/stubs/hl.meta.lua` line 864, `nm`-demangled symbols in `/usr/bin/Hyprland`, and `/usr/include/hyprland/src/config/shared/actions/ConfigActions.hpp`.
  found: |
    The stub is useless for this: `---@field dpms fun(...): HL.Dispatcher` — variadic, untyped.
    But the binary carries the real signature. Demangled:
      Config::Actions::dpms(Config::Actions::eTogglableAction, std::optional<CSharedPointer<Monitor::CMonitor>>)
    and ConfigActions.hpp:30-34 gives the enum:
      enum eTogglableAction : uint8_t { TOGGLE_ACTION_TOGGLE = 0, TOGGLE_ACTION_ENABLE, TOGGLE_ACTION_DISABLE };
    LuaBindingsInternal.hpp:134/148 gives the two parse helpers:
      parseToggleStr(const std::string&)
      tableToggleAction(lua_State*, int idx, const char* field = "action")
  implication: EXPLAINS THE PRIOR "silently accepts junk" OBSERVATION. `TOGGLE` is enum value 0, i.e. the zero-default. Any argument the parser fails to recognise falls through to TOGGLE rather than erroring — which is why `hl.dsp.dpms()` and `hl.dsp.dpms("bogus")` both replied `ok`. The `ok` reply carries no information about whether the argument was understood. Also names the likely real shape: a TABLE with an `action` field.

- timestamp: 2026-07-28T17:24:00Z
  checked: Whether argument validation happens at dispatcher CONSTRUCTION (which would allow risk-free probing). Via `hyprctl repl 'local d = <expr>; return tostring(d)'` across 10 malformed shapes, plus two controls.
  found: Every shape — `hl.dsp.dpms({})`, `hl.dsp.dpms(true)`, `hl.dsp.dpms({action="bogus"})`, even the control `hl.dsp.window.tag({})` which has a documented "expected a table { tag, window? }" error — returns the opaque userdata `HL.Dispatcher`. `debug.getmetatable` shows `__metatable` (protected), `__call`, `__gc`, `__name`, `__tostring`; the object exposes no fields.
  implication: Construction NEVER validates; validation happens inside the closure at DISPATCH time. Static/introspective probing cannot establish the shape — it must be dispatched and observed. Rules out the risk-free shortcut.

- timestamp: 2026-07-28T17:30:00Z
  checked: DPMS behaviour against the `hyprctl monitors -j` `.dpmsStatus` oracle (NOT the reply), via a self-restoring probe with a trap. Pre-checked the independent safety net first: `misc:mouse_move_enables_dpms` and `misc:key_press_enables_dpms` both read `true`, so any user input wakes the display regardless of what the probe does.
  found: |
    `hl.dsp.dpms("off")` → reply ok; dpmsStatus true→false. Display GENUINELY powered off.
    `hl.dsp.dpms("on")`  → reply ok; dpmsStatus false→true. Wake path GENUINELY works.
    THEN the trap's restore ran `hl.dsp.dpms("on")` a second time while the display was ALREADY on
    — and dpmsStatus went true→FALSE. The display turned OFF in response to "on".
  implication: THE TRAP CAUGHT THE REAL BUG. A third observation from a known state broke the tie the first two could not: `"on"` from ON must not turn the display off. So the bare-string `"on"` is NOT parsed as ENABLE — it falls through to the TOGGLE zero-default. Had the probe stopped after the first two (both of which looked like clean successes), the shipped fix would have been TOGGLE semantics.

- timestamp: 2026-07-28T17:34:00Z
  checked: Full 2x2 truth-table characterization (from-ON and from-OFF decisively separates ENABLE / DISABLE / TOGGLE / NO-OP) of every bare-string form.
  found: |
    hl.dsp.dpms("on")       fromON=false fromOFF=true  => TOGGLE
    hl.dsp.dpms("off")      fromON=false fromOFF=true  => TOGGLE
    hl.dsp.dpms("enable")   fromON=false fromOFF=true  => TOGGLE
    hl.dsp.dpms("disable")  fromON=false fromOFF=true  => TOGGLE
    hl.dsp.dpms("toggle")   fromON=false fromOFF=true  => TOGGLE
    All five replied `ok`.
  implication: The bare-STRING argument to `hl.dsp.dpms` is ignored ENTIRELY — every value, valid or not, yields TOGGLE. `parseToggleStr` is not on this dispatcher's path. The string form is unusable for hypridle at any token.

- timestamp: 2026-07-28T17:38:00Z
  checked: The `eTogglableAction` TOKEN VOCABULARY, established on a harmless proxy rather than the display. `Actions::floatWindow(eTogglableAction, optional<PHLWINDOW>)` takes the SAME enum as `dpms`, and this repo's own `config/keybinds.lua:69` already uses the table form `hl.dsp.window.float({ action = "toggle" })`. Oracle: `hyprctl activewindow -j .floating` — observable and fully reversible. ZERO display blanking.
  found: |
    {action="on"}       fromFALSE=true  fromTRUE=true  => ENABLE
    {action="off"}      fromFALSE=false fromTRUE=false => DISABLE
    {action="enable"}   fromFALSE=true  fromTRUE=true  => ENABLE
    {action="disable"}  fromFALSE=false fromTRUE=false => DISABLE
    {action="toggle"}   fromFALSE=true  fromTRUE=false => TOGGLE
    {action=true}       => TOGGLE (boolean not recognised, zero-default)
    {action=false}      => TOGGLE (boolean not recognised, zero-default)
    Active window (`zen`) restored to its original floating=false at exit.
  implication: The TABLE form `{action="<str>"}` IS recognised where the bare string is not — confirming `tableToggleAction(..., field="action")` is the live path. Vocabulary: "on"/"enable" → ENABLE, "off"/"disable" → DISABLE, anything unrecognised (including booleans) → TOGGLE. Established without touching display power at all.

- timestamp: 2026-07-28T17:42:00Z
  checked: Confirming the table form on `dpms` ITSELF against the `.dpmsStatus` oracle (the proxy above establishes vocabulary, but only dpms can prove dpms). Baseline-setting used the independent, already-proven flipper `hl.dsp.dpms("toggle")`.
  found: |
    hl.dsp.dpms({action="on"})   reply=ok  fromON=true   fromOFF=true   => ENABLE,  IDEMPOTENT
    hl.dsp.dpms({action="off"})  reply=ok  fromON=false  fromOFF=false  => DISABLE, IDEMPOTENT
    Display observed genuinely powering off and genuinely powering back on; left ON at exit.
  implication: ARGUMENT SHAPE ESTABLISHED EMPIRICALLY. `hl.dsp.dpms({action="on"|"off"})` is correct AND idempotent — which is the property that actually matters here. Idempotence is not cosmetic: `misc:mouse_move_enables_dpms=true` means the compositor ALREADY wakes the display on input, so hypridle's `on-resume` fires against an already-ON display. Under the TOGGLE semantics every bare-string form produces, `on-resume` would have switched the display back OFF on every wake — converting a dead feature into an actively hostile one. Same hazard for `after_sleep_cmd` on a display that resumed already-on. The three hypridle lines are therefore SAFE to fix, using the table form only.

- timestamp: 2026-07-28T17:50:00Z
  checked: WHY THIS WASN'T CAUGHT — git history of plan 13.1-09, the phase whose declared job was retargeting consumers at the Lua API. `git show e82f2bd -- hypr/.config/hypr/scripts/ai-webapp-launch.sh`.
  found: |
    Commit e82f2bd ("feat(13.1-09): retarget generated-file consumers at the merged Lua
    token table") MODIFIED ai-webapp-launch.sh — but only its comments, repointing
    `windowrules.conf` to `windowrules.lua`. The broken `hyprctl dispatch workspace name:ai`
    sat two lines below the edited hunk and was left untouched.
    That SAME commit message separately declares: "Rule 3 (blocking-issue) fix, narrowly
    scoped: theme-stress-test's own quickshell-probe dispatch ... is rejected outright by
    the Lua-config-managed compositor ... Fixed both call sites to the Lua expression form".
  implication: The bug class was RECOGNISED and correctly fixed in 13.1-09 — but only at the
    one site that was blocking that plan's own verification, and explicitly "narrowly scoped".
    It was not generalised, not even inside a file the same commit was editing. This is the
    honest answer to "which gate should have caught it": no gate did, because the fix was
    scoped to the blocker rather than to the pattern. The cheap generalisable guard is a
    repo-wide `grep -rn "hyprctl dispatch"` at the moment any one instance of a withdrawn
    API is fixed — that single grep would have surfaced all 15 sites at once. Recorded to
    .planning/WINDOWS.md as entry 13 (marked fixed for the 7 sites), with 14 (quickshell-doctor)
    and 15 (waybar click) left open as the deliberate remaining debt.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  CONFIRMED (two contributing conditions, AND-gated):

  (1) Hyprland 0.56.1 running from `~/.config/hypr/hyprland.lua` withdraws the legacy
      string form of the IPC `dispatch` command. The handler unconditionally rewrites
      the payload into `return hl.dispatch(<payload>)` and evaluates it as Lua SOURCE.
      `workspace 2` is not a valid Lua expression, so it fails at PARSE time. There is
      no legacy-first fallback (proven with `dpms on`, a canonical legacy dispatcher
      name, which fails identically), and no compositor config knob to restore it.

  (2) Waybar 0.15.0-2 has the legacy strings `dispatch workspace <id>` /
      `dispatch workspace name:<n>` / `dispatch focusworkspaceoncurrentmonitor ...` /
      `dispatch togglespecialworkspace ...` compiled into `Workspace::handleClicked`,
      and discards the IPC reply. So the Lua parse error is thrown away and the click
      is silently inert.

  Neither condition alone is sufficient — which is precisely why keyboard binds still
  work. `config/keybinds.lua` registers workspace switches as native Lua dispatcher
  OBJECTS (`hl.dsp.focus({ workspace = N })`), resolved to closures at config-LOAD time
  inside the compositor and invoked directly on keypress. They never serialize through
  the IPC string parser, so they satisfy condition (1) but not (2) and are unaffected.

  This is an upstream API break, not a local misconfiguration: Waybar #5008 / #5035,
  Hyprland discussion #14255. Waybar PR #5013 ("adapt dispatch commands for Lua IPC
  protocol") fixed it upstream on 2026-05-04 — after the 0.15.0 release, so no shipped
  Arch package carries the fix.

  BLAST RADIUS (same mechanism, beyond the reported symptom):
    - hypr/.config/hypr/hypridle.conf:44  `on-timeout = hyprctl dispatch dpms off`   → 15-min display blank is DEAD
    - hypr/.config/hypr/hypridle.conf:45  `on-resume  = hyprctl dispatch dpms on`    → DEAD
    - hypr/.config/hypr/hypridle.conf:8   `after_sleep_cmd = hyprctl dispatch dpms on` → DEAD
    - hypr/.config/hypr/scripts/ai-workspace.sh:58       `hyprctl dispatch workspace name:ai` → DEAD
    - hypr/.config/hypr/scripts/ai-webapp-launch.sh:28   `hyprctl dispatch workspace name:ai` → DEAD
    - waybar/.config/waybar/config-floating.jsonc:98-99  `hyprctl dispatch workspace e+1/e-1` → DEAD (scroll)
    - hypr/.config/hypr/scripts/quickshell-doctor        ~8 `hyprctl dispatch global ...` sites → DEAD
  (theme-engine/theme-stress-test already uses the correct `hl.dsp.global(...)` form.)

fix: |
  APPLIED — BRANCH C (operator-selected): retarget the repo-owned legacy call sites to
  the Lua `hl.dsp.*` expression form, and accept waybar's compiled-in workspace CLICK as
  scheduled technical debt. Branches A (waybar-git) and B (roll back to hyprlang) were
  rejected by the operator: waybar is being replaced by Quickshell shortly, so A would
  put a moving-target `-git` package into install.sh's reproducible path for a component
  scheduled for deletion, and B would undo an equivalence-proven migration for its sake.
  Quickshell has no instance of this bug class — its QML uses the `GlobalShortcut`
  Wayland protocol and contains zero IPC dispatch string sites — so replacing waybar
  removes the remaining debt structurally rather than by another code change.

  The fix pattern was NOT invented here. Plan 13.1-09 already established it in
  theme-engine/.config/theme-engine/theme-stress-test (lines 368 and 571,
  `hyprctl dispatch 'hl.dsp.global("quickshell:probe")'`, documented at ~352-367);
  these 7 sites are brought into line with it.

  7 sites retargeted:
    hypr/.config/hypr/hypridle.conf
      after_sleep_cmd  → hyprctl dispatch 'hl.dsp.dpms({action="on"})'
      on-timeout (900) → hyprctl dispatch 'hl.dsp.dpms({action="off"})'
      on-resume  (900) → hyprctl dispatch 'hl.dsp.dpms({action="on"})'
    hypr/.config/hypr/scripts/ai-workspace.sh
      exec → hyprctl dispatch 'hl.dsp.focus({workspace="name:ai"})'
    hypr/.config/hypr/scripts/ai-webapp-launch.sh
      → hyprctl dispatch 'hl.dsp.focus({workspace="name:ai"})'
    waybar/.config/waybar/config-floating.jsonc
      on-scroll-up   → "hyprctl dispatch 'hl.dsp.focus({workspace=\"e+1\"})'"
      on-scroll-down → "hyprctl dispatch 'hl.dsp.focus({workspace=\"e-1\"})'"

  THE DPMS SITES ARE NOT THE OBVIOUS FIX. `hl.dsp.dpms("on")` — the shape almost anyone
  would write, and the direct transliteration of the legacy `dpms on` — is NOT "turn on".
  The bare-string argument is ignored entirely and every value falls through to the
  eTogglableAction zero-default TOGGLE. Only the TABLE form `{action="on"|"off"}` reaches
  the real parser, and it is idempotent. This matters operationally, not academically:
  `misc:mouse_move_enables_dpms` is true, so the compositor has already woken the display
  by the time hypridle's `on-resume` runs. Under toggle semantics `on-resume` would blank
  the display on every wake — converting a silently-dead feature into an actively hostile
  one. Explanatory comments are in hypridle.conf's header so this is not re-"simplified".

  NOT fixed, by design (see verification for the debt register): waybar's compiled-in
  workspace CLICK — the reported symptom itself. It is unreachable from config.

verification: |
  HUMAN-CONFIRMED 2026-07-28 — operator replied "confirmed fixed" after testing the
  scroll gesture over the waybar workspace buttons. This closes the one link no tool on
  this machine could drive (ydotool/wlrctl/dotool absent, wtype keyboard-only).
  The waybar CLICK remains dead by design — accepted debt, tracked as WINDOWS #15,
  retired when Quickshell replaces waybar.

  SELF-VERIFIED — 9/9 checks passed.

  Method: every command string was EXTRACTED FROM THE EDITED FILE ON DISK and executed
  via /bin/sh -c exactly as its real consumer (waybar / hypridle) would run it — nothing
  hardcoded, so the shipped bytes are what got tested. Exit 0 was explicitly NOT accepted
  as evidence anywhere; this entire bug hid behind commands that exited 0 while doing
  nothing. Every check required an observed compositor STATE CHANGE.

    waybar on-scroll-up   (shipped bytes) → activeworkspace '1' → '2'   PASS
    waybar on-scroll-down (shipped bytes) → activeworkspace '2' → '1'   PASS
    ai-workspace.sh       (shipped bytes) → activeworkspace '1' → 'ai'  PASS
    ai-webapp-launch.sh   (shipped bytes) → activeworkspace '1' → 'ai'  PASS
    bash -n ai-workspace.sh                                             PASS
    bash -n ai-webapp-launch.sh                                         PASS
    hypridle on-timeout      → dpmsStatus True → False → False          PASS
    hypridle on-resume       → dpmsStatus False → True → True           PASS
    hypridle after_sleep_cmd → dpmsStatus stayed True                   PASS

  The three dpms checks are deliberately run TWICE each. A single call cannot distinguish
  DISABLE from TOGGLE, or ENABLE from TOGGLE — only the second call from the resulting
  state can. The second `on-resume` call also reproduces the exact live race (firing
  against an already-ON display) that toggle semantics would have broken.

  CONFIG-PARSE verification: hyprlang uses `{`/`}` as category delimiters, so brace-
  bearing values were a real risk. Ruled out empirically by running
  `hypridle -c <test.conf> --verbose` (timeouts set to 99999 so nothing could fire):
  it echoed both commands back byte-exact with no parse error. The waybar JSONC was
  parsed with a comment-aware validator and the decoded strings confirmed to be exactly
  `hyprctl dispatch 'hl.dsp.focus({workspace="e+1"})'`.

  DAEMONS RELOADED: hypridle and waybar were both killed and respawned FROM THE
  COMPOSITOR via `hl.dsp.exec_cmd(...)` — the same calls autostart.lua:42/:74 use at
  login. This was not cosmetic: respawning them from the agent's own shell left them at
  nice 5 (inherited), and RLIMIT_NICE=0 makes that unrecoverable by renice. Both now
  match their original process shape exactly (ppid 956, nice 0). hypridle 998 → 704321,
  waybar 476510 → 711089; waybar's layer surface is back at 2560x39.

  ONE SELF-INFLICTED ERROR, CAUGHT AND CORRECTED: the first verification pass extracted
  hypridle's FIRST `on-timeout` line — the waybar-visibility listener — instead of the
  dpms one, so it actually ran `waybar-visibility.sh idle hide/show` twice and reported a
  meaningless PASS for `on-resume`. Those three results were discarded and re-run with an
  extractor that requires the line to contain `dpms` and prints its source line number
  (L76/L77/L37) for audit. Waybar visibility was confirmed restored afterwards.

  NOT SELF-VERIFIABLE — REQUIRES A HUMAN:
    The waybar SCROLL gesture. There is no pointer-injection tool on this machine
    (ydotool/wlrctl/dotool absent; wtype is keyboard-only), so the gesture itself cannot
    be driven. What IS proven is the underlying command string, run from a shell exactly
    as waybar invokes it. The untested link is solely "waybar's scroll event reaches that
    string" — and that link was already working before this fix (the old string was
    dispatched fine; it was the compositor that rejected its contents).

  REMAINING KNOWN DEBT (deliberate, not oversight):
    (a) waybar workspace CLICK — the originally reported symptom. Unfixable from config
        (compiled into Workspace::handleClicked; no on-click key exists for this module).
        Stays dead BY DESIGN and dies with waybar when Quickshell lands.
    (b) hypr/.config/hypr/scripts/quickshell-doctor — ~8 `hyprctl dispatch global ...`
        sites, still on the legacy string form and therefore still dead. Explicitly
        deferred by the operator; left untouched. NOTE: that script must not be run to
        test this — its headless-output add/remove test previously SEGV-crashed this
        compositor during a DP-1 hotplug.
    (c) the `hl.dsp.dpms` argument shape is NOT debt — it was established empirically
        this session and is recorded above.

oracle_type: derived (contract) — per-site compositor state, never the IPC reply. For
  workspace sites the oracle is `hyprctl activeworkspace` .name before/after; for dpms it
  is `hyprctl monitors -j` .dpmsStatus before/after. The reply is explicitly untrusted
  here and was PROVEN to lie: all five bare-string dpms forms reply `ok` while silently
  toggling. Idempotence checks (calling twice from a known state) are what separate
  ENABLE/DISABLE from TOGGLE — a single observation cannot.

files_changed:
  - hypr/.config/hypr/hypridle.conf
  - hypr/.config/hypr/scripts/ai-workspace.sh
  - hypr/.config/hypr/scripts/ai-webapp-launch.sh
  - waybar/.config/waybar/config-floating.jsonc
  - .planning/WINDOWS.md
  - .planning/debug/waybar-workspace-click-dead.md
