# Pitfalls Research

**Domain:** Hyprland desktop-rice expansion (bug fixes + new utilities + menus + theme pipeline extension) on an existing Arch + stow + matugen `theme-engine`
**Researched:** 2026-07-09
**Milestone:** v2.0 Desktop Expansion (builds on the v1.0 theme-pipeline-repair foundation — see prior-milestone `PITFALLS.md` findings in git history for the original GTK/stow/theming pitfalls, now resolved and validated)
**Confidence:** LOW overall (all findings sourced via uncorroborated `websearch` — treat as directional, verify against this machine's actual versions/config before trusting; a few claims are corroborated by 2+ independent GitHub issues/threads, called out inline as MEDIUM-leaning)

## Critical Pitfalls

### Pitfall 1: wlogout/uwsm shutdown hang has no confirmed single root cause — a fix attempt can trade one hang for another

**What goes wrong:**
Multiple independent, still-open Hyprland ecosystem threads describe the exact symptom in this milestone (black screen / hang on shutdown or logout with uwsm) with *different* underlying causes: (a) Hyprland itself crashing/core-dumping on `hyprctl dispatch exit` or `uwsm stop`, leaving a dead black screen; (b) `systemctl reboot` hanging because some other systemd unit is holding shutdown (resolves after systemd's 90s default timeout force-kills it); (c) wlogout's own logout action hanging specifically when triggered by mouse click but working fine via hotkey (upstream Hyprland issue #4599); (d) Home Manager's systemd integration conflicting with uwsm's own systemd integration when both are active.

**Why it happens:**
uwsm + Hyprland + wlogout + systemd-logind is a four-layer stack where each layer can independently hang the teardown sequence, and the symptom ("blank screen, no poweroff") looks identical regardless of which layer is actually stuck. Treating it as one bug and applying one fix risks leaving 2 of the 4 possible causes unaddressed.

**How to avoid:**
Before touching wlogout's config/CSS, first isolate *which* layer hangs: reproduce via keyboard-triggered wlogout action (not mouse click) to rule out (c); check `journalctl -b` / `systemctl status` immediately after a hang for a unit stuck past the 90s timeout to rule out (b); check for a Hyprland core dump (`coredumpctl list`) around the hang time to rule out (a); confirm nothing else on this machine (Home Manager is not used here per this repo's stack, but any other systemd-user-unit that isn't `uwsm`-aware should be checked) fights uwsm's session teardown. Only then write the wlogout redesign/fix against the actual isolated cause.

**Warning signs:** Hang reproduces via hotkey too (rules out mouse-specific #4599 bug) → look at Hyprland core dumps. Hang only via wlogout's `poweroff`/`reboot` button but `uwsm stop` from a terminal works cleanly → the bug is in wlogout's own action definitions, not the session stack.

**Phase to address:** Bug-fix phase (first, before any wlogout redesign work) — a cosmetic redesign of wlogout is wasted effort if the underlying hang isn't isolated and fixed first.

---

### Pitfall 2: A misconfigured or crashed hyprlock redesign can lock you out with no visible recovery path

**What goes wrong:**
hyprlock has two distinct dangerous failure modes, both confirmed via multiple upstream issues: (1) if its config file is missing or fails to parse in every searched path, hyprlock **fails open** — it exits with an error and does *not* lock the session (a security gap, not a lockout, but silently defeats the point of relocking); (2) if hyprlock partially starts and then crashes (confirmed triggers: NVIDIA GPU issues on suspend/resume, repeated keybind activation, certain idle/timer interactions), the session can be left in a **locked-but-no-UI** state — `loginctl` reports the session as locked, the desktop is inaccessible, but there's no hyprlock client to type a password into. This requires a second TTY to recover (`pkill -USR1 hyprlock` to force-unlock, or `hyprctl keyword misc:allow_session_lock_restore 1` + `hyprctl dispatch exec hyprlock` to respawn the lock client).

**Why it happens:**
This milestone explicitly redesigns hyprlock's theming/config, and hyprlock has no built-in "safe mode" or config validation step before it becomes the thing standing between you and your own session — a syntax error or a bad exec-once hook in the new config is not caught until the moment you actually try to lock.

**How to avoid:**
Never test hyprlock config changes by locking your only session. Keep a second TTY (Ctrl+Alt+F2 or equivalent) logged in and ready *before* testing any hyprlock config change. Validate the config file's syntax where possible before triggering a live lock. After any hyprlock change, do a controlled lock/unlock test immediately (not "later") while the recovery TTY is standing by. Document the exact recovery commands (`pkill -USR1 hyprlock`, the `allow_session_lock_restore` hyprctl sequence) in the repo itself (e.g. a comment in the hyprlock config or a README note), not just tribal knowledge.

**Warning signs:** hyprlock config references a new color-source path (from `~/.local/state/theme/`) that doesn't exist yet at lock time, or a background/image directive with a broken path — both are plausible crash triggers given this milestone's "source colors from state dir" requirement.

**Phase to address:** Bug-fix/hyprlock phase — build the recovery procedure and second-TTY test discipline into the plan/verification step *before* redesign work starts, not as an afterthought once something breaks.

---

### Pitfall 3: A tap-only $SUPER menu bind can silently break every other $SUPER+key binding or trap the user in an unexitable submap

**What goes wrong:**
The only working pattern found for "tap SUPER alone with no other key" is `bindr=SUPER,Super_L,exec,<cmd>` (release-triggered, since Hyprland can't fire on press-without-any-other-key any other way) — and per this repo's own existing STACK.md notes, `bindr` binding for "Super released alone" has had at least one confirmed upstream regression (Hyprland issue "Bind super alone on release no longer works"). Two separate failure modes stack on top of that: (a) if the "menu" is implemented as a Hyprland submap (a documented, common pattern), forgetting an explicit exit bind (`bind=,escape,submap,reset`) inside that submap leaves the user's *entire* keybind set inert — every other keybind, including $SUPER+key app launches, stops working until they find the one exit key; (b) since $SUPER is this repo's primary modifier for dozens of existing keybinds, any regression in bindr's release-detection can make $SUPER+key combos misfire (fire the tap-menu action instead of the intended combo) if key press ordering/timing edge cases aren't handled — Hyprland's binding docs note there's no clean way to have a modifier-only bind coexist perfectly with the same modifier used in combos.

**Why it happens:**
Hyprland's input binding model is not really designed for "modifier tap-alone vs modifier-as-combo-prefix" disambiguation — it's a bolt-on (`bindr`) rather than a first-class feature, and combined with submap state (which has no default timeout/auto-reset), a bad interaction here breaks the entire desktop's primary input method, not just the new feature.

**How to avoid:**
Implement the exit bind in the submap FIRST, test it in isolation before adding any menu items. Test explicitly: (1) tap SUPER alone → menu opens; (2) tap SUPER, do nothing, tap SUPER again or press escape → menu closes cleanly, normal keybinds resume; (3) run a full sweep of 5-10 existing $SUPER+key bindings (workspace switch, app launch, etc.) immediately after wiring the tap bind, to catch a broken combo regression before it's discovered days later. Keep the previous keybind config in git so a broken submap can be reverted in one command from a still-working session (not requiring TTY recovery, unlike hyprlock).

**Warning signs:** Existing $SUPER+key bindings feel "laggy" or occasionally fire the menu instead of the intended action after the tap bind is added — this is the modifier-disambiguation edge case, not a fluke, and should block shipping the feature as-is.

**Phase to address:** Walker menu / keybind phase — verification step must explicitly re-test the full existing keybind set, not just the new tap gesture, given $SUPER is the shared modifier across the whole desktop.

---

### Pitfall 4: Adding light themes to a dark-first pipeline surfaces a GTK3/GTK4 propagation split this repo hasn't had to handle yet

**What goes wrong:**
`color-scheme` (prefer-dark/prefer-light) is broadcast via the freedesktop portal and picked up live by portal-aware GTK4/libadwaita apps, Electron apps, VSCodium, Firefox-family browsers — but GTK3 apps that read `~/.config/gtk-3.0/settings.ini` directly (confirmed for Thunar, already documented as this repo's pattern) do **not** react to the portal's `color-scheme` broadcast at all. A light-theme addition that only flips the portal setting will re-theme GTK4/portal-aware apps to light but leave Thunar (and any other settings.ini-reading GTK3 app) stuck on dark, or vice versa — exactly the kind of "half-themed desktop" bug class this repo's v1.0 milestone spent 3 phases eliminating for the dark-only case. The existing STACK.md documents this repo already knows GTK3 needs `settings.ini` rewrites + process restart (not portal-only) — the new risk is specifically forgetting to extend that same dual-path handling to `prefer-light`, since the current templates/scripts were only ever exercised against dark values.

**Why it happens:**
The theme-engine's existing 10-file output contract and render templates were built and validated exclusively against dark palettes (v1.0's `contract.json` + `theme-parity` gate). Adding light themes is not "render different colors through the same contract" — it potentially needs new contract fields (`gtk-application-prefer-dark-theme=0`, a different icon-theme-name lookup if Adwaita's light vs dark icon variants differ, etc.) that were never exercised.

**How to avoid:**
Explicitly extend `contract.json` and the `theme-parity` gate to include at least one light-mode fixture before merging any light preset, so light-mode output gets the same automated regression coverage dark-mode already has (217/0 style parity check) instead of relying on human eyeballing. Test the full 10-surface re-theme sweep (already used for dark in Phase 1/2) again specifically for a light switch, including a Thunar restart-and-verify step, since that's the confirmed non-portal-reactive surface.

**Warning signs:** Switching to a light preset changes Hyprland borders/waybar/kitty but Thunar (or another GTK3 surface) stays dark until manually restarted, or comes back in a mismatched half-light state (dark chrome, light content) — this is the exact symptom class v1.0 fixed for dark-mode Thunar and must not regress for light.

**Phase to address:** Light-theme phase — must reuse/extend the existing `contract.json`/`theme-parity`/`theme-doctor` gates rather than treating light themes as "just another preset," given the GTK3 propagation gap is structural, not cosmetic.

---

### Pitfall 5: cliphist persists everything unencrypted by default — a real privacy regression if enabled without limits

**What goes wrong:**
cliphist (or equivalent) writes every clipboard entry — text and images — to a plaintext history store by default, with no built-in size cap or content filtering. On a personal daily-driver machine this means passwords, SSH key fragments, API tokens, and any sensitive text ever copied become permanently browsable via the walker/rofi-style picker until manually cleared, persisting across reboots unless explicitly configured not to.

**Why it happens:**
Clipboard managers are designed for convenience, not security, and the "just works" default (unbounded history, no filtering) is what most setup guides copy-paste without adjustment — a gap this milestone's "clipboard history" feature would inherit if the reference config/script is used verbatim.

**How to avoid:**
Cap history size explicitly (tens, not hundreds, of entries) rather than accepting a large/unbounded default. Consider wiping history on session start/reboot rather than persisting indefinitely. If feasible, add a lightweight content filter in the `wl-paste` watcher script (e.g. skip entries above a certain byte size that look like key material, or exclude clipboard events from a password manager's process) before they reach the history store — evaluate this as an explicit design decision during discuss-phase, not silently accepted as "how cliphist works."
Separately: image entries need distinct handling — some sources (e.g. browser copy actions) deliver images as `text/html` MIME rather than raw image data, so a naive single wl-paste watcher may silently drop or mis-store image clipboard entries; verify image-entry capture explicitly, don't assume it "just works" alongside text capture.

**Warning signs:** Clipboard history picker shows a password or token you copied minutes ago, still fully visible — treat this as a stop-ship issue for the feature, not a nice-to-have hardening pass.

**Phase to address:** Clipboard history utility phase — privacy limits (size cap, filtering, or reboot-wipe) should be a launch requirement for the feature, decided explicitly during discuss-phase, not a follow-up.

---

### Pitfall 6: Elephant/walker version skew silently breaks custom menus without looking like a version problem

**What goes wrong:**
Walker's custom-menu/icon features depend on the separate `elephant` backend daemon and its per-provider packages (`elephant-desktopapplications`, `elephant-menus`, etc. — already in this repo's stack). Community reports confirm that installing `elephant` core and its providers from mismatched versions/sources produces errors that don't obviously point to "version mismatch" as the cause, and a full-system upgrade has been observed to leave walker/elephant binaries broken or missing entirely (regression risk on any future `pacman -Syu`, not just this milestone's initial build-out).

**Why it happens:**
walker and elephant speak a private, versioned protocol over a Unix socket (already flagged in this repo's STACK.md) — there's no compatibility-checking handshake visible to the user; a stale or partially-upgraded elephant provider just behaves wrong or silently omits menu items/icons rather than erroring loudly.

**How to avoid:**
When adding the new Omarchy-style custom menus with custom icons, verify walker and every elephant-* provider package are pinned/updated together (this repo's install.sh should install them as an atomic group, e.g. mirroring the `elephant-all` meta-package pattern some users adopted, if available in Arch repos). After any future system upgrade touching either package, re-run the existing `theme-doctor`/walker-restart health-gate script (already built in v1.0 for theming) as a general walker/elephant health check, not just a post-theme-switch check.

**Warning signs:** Custom menu items or icons silently missing/blank (not an error dialog) after a routine `pacman -Syu` — this is the confirmed skew symptom, investigate package versions before assuming it's a config bug.

**Phase to address:** Walker custom-menu phase — pin/verify package versions as part of install.sh work in this phase; also flag as a standing reproducibility risk for `theme-doctor` to catch on future upgrades.

---

## Moderate Pitfalls

### Pitfall 7: SIGUSR2 waybar reload doesn't fully refresh tooltip CSS, and can spawn duplicate bar instances

**What goes wrong:** This repo's existing matugen post_hook already sends `pkill -SIGUSR2 waybar` to reload styling (documented in STACK.md as the known pattern). Two confirmed upstream gaps: SIGUSR2 does not fully reload tooltip-specific CSS (long-open Alexays/Waybar#3986), and under some conditions (observed after wake-from-sleep) SIGUSR2 can cause duplicate waybar processes to appear rather than cleanly reloading the single instance (Alexays/Waybar#3964). Adding a second (vertical) bar instance in this milestone increases the surface for both bugs, since multi-bar SIGUSR2/reload behavior applies per bar-config-object, not globally.

**Prevention:** After adding the vertical layout, explicitly test SIGUSR2 reload behavior with both bars running simultaneously (not just the original horizontal bar). Add a `pgrep -a waybar` single-instance check into the existing reload fan-out or `theme-doctor` gate to catch duplicate-instance regressions early, mirroring the recommended community fix. If tooltip colors specifically look stale after a theme switch, that's the known #3986 gap, not a new bug in this repo's templates — consider `reload_style_on_change: true` (already flagged as a safe belt-and-suspenders addition in STACK.md) as a partial mitigation, but don't expect it to fully close the tooltip gap.

---

### Pitfall 8: Waybar vertical layout silently changes module stacking direction, breaking a config ported from the horizontal bar

**What goes wrong:** Waybar module groups stack horizontally when the bar is positioned top/bottom, but stack *vertically* when positioned left/right — a naive copy of the existing horizontal `config-*.jsonc` to a new left-positioned bar will render group layouts sideways/wrong rather than just "rotated." Per-module `rotate` (0/90/180/270) is a separate property from bar position and must be set explicitly per module for text to read correctly in a vertical bar.

**Prevention:** Treat the vertical layout as a genuinely new config file (as this repo's `config-*.jsonc` naming convention already implies) rather than a copy-paste of the horizontal one with position flipped — budget time to re-test every module's rotate/orientation individually, not just confirm the bar appears on the left edge.

---

### Pitfall 9: SwayOSD's libinput backend is a separate systemd service easy to forget, breaking hardware-key OSDs while keybind-triggered ones work fine

**What goes wrong:** SwayOSD ships three separate binaries: `swayosd-server` (renders the OSD), `swayosd-client` (CLI, what a Hyprland keybind would call), and `swayosd-libinput-backend` (a systemd service that watches raw libinput events for hardware keys like physical volume/caps-lock buttons, independent of any Hyprland bind). Wiring only Hyprland keybinds to `swayosd-client` will make the OSD work for those bound keys, but hardware volume/brightness keys that aren't bound (or laptops where XF86 keys should "just work") will show no OSD at all unless the libinput backend service is separately enabled.

**Prevention:** Explicitly add `systemctl enable --now swayosd-libinput-backend.service` (or the install.sh equivalent user-unit enablement, matching this repo's existing systemd/uwsm patterns) as part of the SwayOSD install step, not just the client binary + CSS. Verify by testing a hardware key press with zero corresponding Hyprland keybind defined — if the OSD still appears, the libinput backend is correctly running.

---

### Pitfall 10: swayosd's style.css is not auto-generated and must be explicitly wired into the matugen template set

**What goes wrong:** Unlike some of this repo's other 10 render targets, SwayOSD's `~/.config/swayosd/style.css` does not exist by default and is plain CSS (not SCSS) — if the theme-engine's `[templates.*]` wiring and `contract.json` output list aren't explicitly extended to include it, SwayOSD will render with stock/no styling and silently fall outside the "every switch re-themes everything" guarantee this project's Core Value depends on.

**Prevention:** Add swayosd as an explicit 11th contract target (extending `contract.json`, `theme-parity`, and `theme-doctor` the same way each prior surface was added in Phase 1/2) rather than a bolt-on script — this keeps it inside the same regression-tested pipeline instead of becoming an untested edge case.

---

### Pitfall 11: Zen Browser theming depends on a runtime-created profile path and a disabled-by-default preference — fragile to stow at install time

**What goes wrong:** Zen Browser theming requires `toolkit.legacyUserProfileCustomizations.stylesheets=true` set in `about:config` (off by default — a common miss on fresh installs) and a `chrome/userChrome.css` file inside the actual Firefox-style profile directory. That profile directory doesn't exist until Zen has been launched at least once, and its path differs by install method (native package vs Flatpak use different paths). A `theme-follows-switch` feature that assumes a fixed, always-present profile path will silently no-op on a fresh install or a different install method than whichever one was used to write the script.

**Prevention:** Resolve the profile path at runtime (e.g. read `profiles.ini` or search under the known parent dirs for both native and Flatpak layouts) rather than hardcoding one path. Guard the theming script/stow step to handle "profile doesn't exist yet" gracefully (skip with a clear message, don't error the whole theme-apply run) rather than assuming Zen has already been run once. Confirm the legacy stylesheets preference is set as part of the install/setup step for this feature, not left as a manual one-time step the user might forget.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Hardcoding one Zen Browser profile path (native OR flatpak) in the theming script | Faster to ship | Silently breaks theming if install method differs from what was hardcoded, with no error — just stale browser theme | Never for install.sh-driven reproducibility goal; acceptable only as a documented single-machine hack if Zen is confirmed native-only on this box |
| Skipping a light-mode fixture in `contract.json`/`theme-parity` and relying on manual visual check for new light presets | Faster to ship first light theme | Regresses the exact "half-themed desktop" bug class v1.0 spent 3 phases fixing, but now for light mode, with no automated gate to catch it | Never — extend the existing gate, it already exists and is proven |
| Unbounded cliphist history with no size cap or wipe policy | Zero extra config, "just works" | Standing plaintext-secrets-in-clipboard-history privacy exposure that grows every day | Never for a daily-driver personal machine; only acceptable on a throwaway/demo VM |
| Copying the horizontal waybar config verbatim for the new vertical bar and only flipping `position` | Fastest to get "a bar on the left" | Broken module stacking/orientation that looks superficially fine until inspected closely | Never — budget the re-test time, it's cheap relative to the bug class |
| Wiring SwayOSD client-triggered OSDs only, skipping the libinput backend service | Simpler install step, works for keybind-triggered demo | Hardware volume/brightness keys silently produce no OSD — a "looks done but isn't" gap likely to surface in daily use, not testing | Never if hardware media keys exist on the target hardware; acceptable only if this machine confirmed to have no such physical keys |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| GTK3 (Thunar) + freedesktop color-scheme portal | Assuming the portal's `prefer-light`/`prefer-dark` broadcast alone re-themes Thunar | Explicitly rewrite `~/.config/gtk-3.0/settings.ini` (`gtk-theme-name`, `gtk-application-prefer-dark-theme`) AND restart Thunar, same dual-path pattern already used for dark mode |
| walker + elephant | Upgrading/installing walker without also upgrading matching elephant-* provider packages | Install/upgrade walker + all elephant-* packages as one atomic step; re-run the existing walker-restart health-gate after any upgrade touching either |
| Zen Browser userChrome.css + stow | Assuming the browser profile directory is stable dotfiles-manageable state like other apps' configs | Confirm `toolkit.legacyUserProfileCustomizations.stylesheets=true` is set, resolve the actual profile path at runtime (native vs flatpak differ), and account for the profile not existing yet on a truly fresh install (chicken-and-egg — Zen must run once to create its profile before a `chrome/` symlink target exists) |
| hyprlock + theme-engine state dir | Sourcing colors from `~/.local/state/theme/` without a fallback if the file doesn't exist yet (e.g. before first `theme-apply` run) | Guard hyprlock's color-source include with an existence check or ship a committed fallback/default so a fresh install's first lock doesn't crash on a missing state file |
| SwayOSD + matugen templates | Treating SwayOSD as a manual one-off CSS file outside the theme-engine pipeline | Add it as a proper `contract.json` render target like the other 10 surfaces, so it's covered by `theme-parity`/`theme-doctor` |
| cliphist images + wl-paste watchers | Assuming a single wl-paste watcher captures both text and image clipboard entries correctly | Verify image-mime handling explicitly — browser-sourced "images" often arrive as `text/html`, not raw image bytes, and need separate watcher invocations/mime filtering |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| kitty `env` directive loading shell env vars at every startup | Kitty visibly slower to open than expected, worse than a bare shell | Avoid `env` in kitty.conf unless a specific variable is genuinely needed only inside kitty; prefer setting it in shell rc files instead | Immediately, on every kitty launch — this is a documented, not marginal, cost per kitty's own performance docs |
| Full `shell_integration` injecting code into the shell on every kitty startup | Startup lag proportional to shell rc complexity | Scope down `shell_integration` (e.g. `no-cursor` or a narrower feature set) if full integration isn't needed, especially if this repo's zsh config is already complex | Compounds with a heavy `.zshrc` — worth profiling `kitty --debug-config` or timing `kitty -e exit` before/after changes |
| Waybar SIGUSR2 reload after wake-from-sleep producing duplicate bar processes | Two overlapping/duplicated bars visible, or one behaving stale | Add a single-instance check (`pgrep -a waybar`) into the reload path, kill-before-relaunch rather than assuming SIGUSR2 always converges to one process | Observed specifically around suspend/resume — test explicitly if this machine suspends |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Unbounded, unfiltered clipboard history (cliphist) | Passwords/tokens/keys persist in plaintext, browsable via a fuzzy picker indefinitely | Cap history size, consider reboot/session-start wipe, filter obviously-sensitive copies at the wl-paste watcher level |
| hyprlock fail-open on config error | A broken hyprlock config from this milestone's redesign means "lock" silently does nothing — the screen stays unlocked when the user believes it's locked | Validate config before shipping; explicitly test lock/unlock after every hyprlock config change, treat a failed lock attempt as a security bug, not a cosmetic one |
| Host-absolute symlinks tracked in git (recurrence risk) | v1.0 already hit this bug for a wallpaper symlink; the same class of bug can recur for the new theme-aware wallpaper picker / wallpaper sets work in this milestone | Add an explicit check (e.g. `find -type l -lname '/*'` over stowed packages) to the existing verify/container gate, so a host-absolute symlink fails the gate instead of silently reaching git |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-------------------|
| $SUPER-tap menu submap with no exit bind | User's entire keybind set (including unrelated $SUPER+key app launches) appears "broken" until they discover the one hidden exit key | Build and test the exit bind before adding any menu content; never ship a submap without a proven escape hatch |
| Light theme shipped without extending the existing parity gate | Some surfaces (confirmed candidate: Thunar) look "themed" on the wallpaper/bar/terminal but stay dark, producing a jarring half-themed desktop the user notices immediately | Extend `contract.json`/`theme-parity` to cover a light fixture before merging, matching the rigor already applied to dark mode |
| Wlogout redesign shipped before the underlying hang is isolated | New, prettier menu that still hangs on shutdown — cosmetic work wasted, user trust in the fix erodes | Sequence: isolate and fix the hang first (bug-fix work), then redesign the now-reliable menu |
| Vertical waybar config copy-pasted from horizontal without re-testing module stacking | Left bar renders with sideways/misaligned modules, looks obviously unfinished | Treat vertical layout as new config requiring its own verification pass, not a quick copy |

## "Looks Done But Isn't" Checklist

- [ ] **wlogout fix:** Often "looks done" after testing the hotkey-triggered logout path only — verify mouse-click-triggered actions too (confirmed separate failure mode upstream), and verify actual full poweroff completes, not just that the wlogout UI closes.
- [ ] **hyprlock redesign:** Often "looks done" after one successful lock/unlock in a fresh terminal session — verify recovery works via a second TTY *before* trusting it as the daily lock screen, and verify behavior after suspend/resume specifically (confirmed higher-risk trigger).
- [ ] **SwayOSD:** Often "looks done" after testing keybind-triggered OSDs only — verify hardware key presses (if any exist on this hardware) also trigger the OSD, confirming the libinput backend service is actually enabled and running, not just the client/server binaries.
- [ ] **Light theme presets:** Often "looks done" after checking Hyprland/waybar/kitty (portal-reactive surfaces) — explicitly verify Thunar and any other settings.ini-reading GTK3 app also switched, and check contrast/readability, not just "it's not black anymore."
- [ ] **Clipboard history:** Often "looks done" after confirming text/image copy-paste works — verify a size cap or wipe policy is actually configured, not left at an unbounded default; verify image entries specifically (not just text) given the confirmed text/html MIME gotcha.
- [ ] **Walker custom menus with icons:** Often "looks done" in the dev environment right after building — re-verify after a `pacman -Syu` touching walker/elephant packages, since version skew is a confirmed silent-breakage mode, not just an install-time concern.
- [ ] **Vertical waybar bar:** Often "looks done" as "a bar appears on the left" — verify SIGUSR2 reload behaves correctly with both bars running, and verify no duplicate-instance regression after a sleep/wake cycle.
- [ ] **Zen browser theming:** Often "looks done" after manually testing on the one profile that already existed on this dev machine — verify the profile-path resolution and legacy-stylesheets preference work from a genuinely fresh Zen install too, not just the pre-existing profile.
- [ ] **Reproducibility (install.sh):** Every new package (satty, wf-recorder, cliphist, swayosd if not already present, any nerd-font packages, elephant providers) added to `install.sh` and container-gate-tested headless — session-dependent tools (swaync's existing headless guard pattern) must be replicated for any new tool that assumes a graphical session (e.g. swayosd-server, hyprlock itself).

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|------------------|
| hyprlock locks with no UI (crash after partial start) | LOW (if a second TTY is available) | Switch TTY, run `pkill -USR1 hyprlock` to force-unlock, or `hyprctl --instance 0 keyword misc:allow_session_lock_restore 1` then `hyprctl --instance 0 dispatch exec hyprlock` to respawn a working lock client |
| wlogout/uwsm shutdown hang | MEDIUM | Wait for systemd's default 90s unit-kill timeout, or force via a second TTY/SSH session (`systemctl reboot -i` or similar); check `journalctl -b` and `coredumpctl list` after recovery to identify which of the 4 known failure modes actually occurred, before attempting a permanent fix |
| Waybar stuck showing duplicate instances after SIGUSR2 | LOW | `pkill -SIGUSR2 waybar` again, or `pkill waybar && waybar &` (or the uwsm-managed equivalent) to force a clean single-instance restart |
| Broken $SUPER-tap submap trapping keybinds | LOW (if git history is clean) | `git checkout` the previous known-good hypr keybind config and reload Hyprland config (no session restart needed, Hyprland config reloads live) |
| Light theme leaves Thunar half-themed | LOW | Manually restart Thunar (already this repo's established pattern for any GTK3 stale-theme case); root-cause fix is extending the theme-parity gate so this doesn't reach a human in the first place |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| wlogout hang has multiple possible root causes | Bug-fix phase (before wlogout redesign) | Reproduce via both hotkey and mouse-click paths; check `coredumpctl`/`journalctl` after a hang; confirm real poweroff completes, not just UI dismissal |
| hyprlock can fail-open or lock-with-no-UI | Bug-fix/hyprlock phase | Test lock/unlock with a second TTY standing by after every config change; explicit suspend/resume lock test |
| $SUPER-tap submap can trap all keybinds | Walker menu / keybind phase | Test exit bind in isolation first; full sweep of existing $SUPER+key bindings after the tap bind ships |
| Light themes expose GTK3/GTK4 propagation split | Light-theme phase | Extend `contract.json` + `theme-parity` with a light fixture; explicit Thunar restart-and-verify step |
| cliphist persists sensitive data unbounded | Clipboard history utility phase | Confirm size cap / wipe policy is configured as a launch requirement, not deferred |
| walker/elephant version skew breaks custom menus silently | Walker custom-menu phase | Pin/install walker + elephant-* as one atomic install.sh step; re-run walker health-gate after any future upgrade |
| Waybar SIGUSR2 gaps (tooltip CSS, duplicate instances) | Waybar phase (vertical layout + media/OLED work) | Explicit dual-bar SIGUSR2 reload test; `pgrep -a waybar` single-instance check added to reload path or theme-doctor |
| Vertical waybar module stacking differs from horizontal | Waybar phase | Treat as new config, full module-by-module visual re-test, not a copy-paste |
| SwayOSD libinput backend forgotten | SwayOSD phase | Test hardware key press with zero Hyprland keybind defined; confirm `swayosd-libinput-backend.service` enabled in install.sh |
| SwayOSD styling left outside the render contract | SwayOSD phase | Add as an explicit `contract.json` target, covered by `theme-parity`/`theme-doctor` like the other 10 surfaces |
| Zen Browser profile path/install-method assumptions | Zen browser theming phase | Resolve profile path at runtime, not hardcoded; test on this repo's actual confirmed install method (native vs flatpak) |
| Host-absolute symlink recurrence (wallpaper picker) | Wallpaper picker/theme-aware sets phase | Add symlink-absoluteness check to the existing container/verify gate, mirroring the v1.0 lesson |
| kitty startup regressions (env directive, shell_integration) | Bug-fix phase (kitty) | Profile before/after with `time kitty -e exit`-style measurement; confirm fix against this repo's actual kitty version's changelog, not generic advice |

## Sources

All findings sourced via `websearch` (LOW confidence per this project's classify-confidence seam — no curated/Context7-grade source used for this pitfalls pass). Individual queries and representative links:
- wlogout/uwsm shutdown hang: Arch Linux Forums (bbs.archlinux.org/viewtopic.php?id=310454, id=307539), NixOS Discourse (discourse.nixos.org/t/sddm-gets-black-screen-after-logout-from-hyprland-uwsm), hyprwm/Hyprland issues/discussions #9475, #12174, #12678, #3558, #4599
- hyprlock keystroke/lockout: Hyprland Wiki hyprlock page, hyprwm/hyprlock issues #437, #305, #483, #1048, #340, #741, #695, #329
- kitty startup performance: kovidgoyal/kitty issues #4292, #330, #7540; official kitty FAQ/performance/shell-integration/changelog docs
- screenshot/recording stack: Hyprland Wiki Screenshots & Recording page, nickjanetakis.com blog, Satty-org/Satty and Gustash/Hyprshot and alonso-herreros/hyprcap GitHub repos
- cliphist privacy: sentriz/cliphist GitHub, julienturbide.com blog on securing Wayland clipboard privacy, Hyprland Wiki Clipboard Managers page, Linus789/wl-clip-persist
- GTK3/Thunar icon+font: Xfce Forums, Arch Linux Forums, GNOME developer docs on gtk-update-icon-cache
- Hyprland bindr/submap: Hyprland Wiki Binds page, hyprwm/Hyprland discussions #2506, #1703, issues #3125, #8863, #6946, basecamp/omarchy discussion #2675
- walker/elephant: basecamp/omarchy discussions #2835, #2546; abenz1267/walker and abenz1267/elephant GitHub repos; nino-mau/walker-iconify-menu; hansschnedlitz.com blog on custom Lua menus
- waybar vertical/OLED/SIGUSR2: waybar man page (man.archlinux.org), Alexays/Waybar issues #3964, #3986, niri-wm/niri discussion #2506
- swayosd: ErikReider/SwayOSD GitHub, nix-community/home-manager issue #6347, DeepWiki SwayOSD page
- GTK color-scheme portal: ArchWiki Dark mode switching, hyprwm/Hyprland discussion #5867, GNOME developer forcing-dark-color-scheme tutorial, Arch Forums #291584
- GNU Stow symlinks: GNU Stow manual, several dotfiles-management blog posts (systemcrafters.net, tamerlan.dev, msleigh.io)
- Zen Browser theming: docs.zen-browser.app (live-editing, manage-profiles), catppuccin/zen-browser, zen-browser/desktop discussion #1923, deepwiki.com/zen-browser/theme-components
- matugen light-mode/contrast: InioX/matugen GitHub + wiki, AvengeMedia/DankMaterialShell issue #109, danklinux.com application-theming docs

---
*Pitfalls research for: Hyprland desktop-rice expansion (v2.0 Desktop Expansion)*
*Researched: 2026-07-09*
