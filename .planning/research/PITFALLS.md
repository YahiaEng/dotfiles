# Pitfalls Research: Shell Migration & Debt Paydown (v4.0)

**Domain:** Replacing a working GTK/GTK4 desktop shell (waybar, swaync, SwayOSD, wleave, an AGS media applet) with Quickshell/QML surfaces on a live daily-driver Hyprland desktop, then deleting the originals.
**Researched:** 2026-08-10
**Confidence:** MEDIUM-HIGH — grounded primarily in this repo's own committed evidence (`quickshell-doctor`'s existing D-Bus-owner fixtures, `autostart.lua`'s real daemon order, `windowrules.lua`'s live layerrule namespaces, `install.sh`/`stow.sh`'s package lists, and the PROJECT.md Key Decisions table's prior incidents) rather than external sources. Freedesktop notification-spec and Hyprland/Quickshell upstream claims are marked LOW where not verified against the installed binaries — the same discipline this project already applies to itself.

## Critical Pitfalls

### Pitfall 1: Two processes both hold `org.freedesktop.Notifications` (or neither does)

**What goes wrong:**
D-Bus well-known names are strictly single-owner. If the new QML notification server autostarts *before* swaync exits (or swaync is left in `autostart.lua` one line too long during the transition), whichever process calls `RequestName` second either queues behind the first owner (silently receiving zero notifications) or steals the name outright depending on the flags each server registers with — and libnotify/`notify-send` senders never see an error either way, they just talk to whichever process answered first. If the new server *crashes* after taking ownership, the name is released and every subsequent `notify-send` call either errors loudly (senders that check the D-Bus reply) or silently vanishes (senders, including some background daemons in this repo like the wifi/bluetooth panel failure copy, that fire-and-forget). Because notifications are usually low-frequency, a race here can go unnoticed for hours — you find out the compositor has been asking a dead process to render a low-battery warning only when you missed the warning.

**Why it happens:**
This repo already autostarts one D-Bus notification-service owner (`swaync-launch.sh`, `org.freedesktop.Notifications` per `quickshell-doctor`'s own `QSD_NAME_OWNERS` registry) from a fixed line in `autostart.lua`. Migrating this surface means: (a) writing a new owner, (b) removing the old one, and (c) never letting both exist in the same boot — three edits across two files (`autostart.lua`, `swaync-launch.sh` deletion) that must land atomically, not across two commits, or every boot in between silently runs the race.

**How to avoid:**
- This project already has the exact regression net for this: `quickshell-doctor`'s `QSD_NAME_OWNERS["org.freedesktop.Notifications"]` registry plus its `poisoned-two-owner-busctl-list.txt` self-test fixture (`hypr/.config/hypr/scripts/tests/quickshell-fixtures/`) already prove the *checker* can detect a two-owner state. Update `QSD_NAME_OWNERS` to the new QML server's process name **in the same commit** that swaps `swaync-launch.sh` for the new autostart line, and run `quickshell-doctor` live (not just `--self-test`) after every boot during the migration window.
- Never remove `swaync-launch.sh`'s autostart line and add the new one in separate commits — do it as one atomic edit to `autostart.lua`, exactly as the D-Bus name-ownership model requires exactly one autostart entry at a time.
- Test the crash-recovery path deliberately: `pkill` the new server, confirm `busctl --user list | grep Notifications` goes empty (not stuck on a stale name — D-Bus should auto-release on process exit), then confirm a systemd `--user` unit or supervising wrapper restarts it, then confirm `busctl` shows exactly one owner again. Do this BEFORE calling the surface done, not after a real notification gets silently dropped in production use.
- For rollback: keep `swaync-launch.sh` and the `swaync` stow package **undeleted** until the new server has survived a real multi-day soak (see Pitfall 8) — retirement is a separate, later step from "the replacement works in a demo."

**Warning signs:**
- `busctl --user list | grep -c Notifications` ever reports 0 or 2+ during normal operation.
- A `notify-send` call returns success but no popup appears.
- `quickshell-doctor`'s existing single-owner check (search for `_qsd_notif_sample` / `_qsd_assert_client_consumer_not_owned`) goes red.

**Phase to address:**
The swaync → QML notifications phase, as its own blocking gate before any UAT — this is exactly the shape of check `quickshell-doctor` already has infrastructure for; extending it rather than inventing a new checker is the cheap path.

---

### Pitfall 2: The new notification server doesn't implement the D-Bus contract faithfully

**What goes wrong:**
`org.freedesktop.Notifications` is a contract, not just a name to own. Three specific ways a hand-rolled QML implementation under-delivers relative to swaync, each with a distinct failure signature:
- **`GetCapabilities` wrong or stale** — senders (browsers, Discord, system daemons) use this to decide whether to send actions, body-markup, images, or sound hints. Advertise a capability you don't actually render (e.g. `"actions"` with no click handler wired) and the app-side button silently does nothing; advertise capabilities you removed mid-migration and old cached sender behavior (many apps cache the capability list at their own startup, not per-notification) keeps assuming the old behavior until they restart.
- **`GetServerInformation` wrong** — some senders branch on server name/vendor to work around known bugs in specific servers (this is a real, if obscure, freedesktop ecosystem pattern). Returning garbage here isn't fatal but can silently degrade specific apps' notification quality with no visible error.
- **`replaces_id` dropped or mishandled** — this is the field that lets a sender (e.g. a download progress notification, a volume-OSD-style repeated update) update an existing bubble in place instead of stacking a new one. Drop it and every progress update becomes a new popup — visually it looks like "notifications are spamming," not like a protocol bug, so it gets misdiagnosed as a UX complaint rather than a D-Bus contract gap.
- **Action invocation silently swallowed** — `ActionInvoked` must be signaled back to the sender over D-Bus, not just visually handled in QML. A button that *looks* clickable but never emits the signal breaks "reply to message" / "snooze" / "undo" style actions with zero visible symptom other than "nothing happened."

**Why it happens:**
This repo's redesign-not-port decision (see Pitfall 6) means there is no old-implementation source to diff the new one against line-by-line, and the freedesktop notification spec is easy to under-implement partially — it's simple enough that a naive "show a popup with text" implementation looks complete in casual testing while missing every corner most real-world senders actually exercise.

**How to avoid:**
- Before writing the QML server, capture what swaync's `GetCapabilities`/`GetServerInformation` currently return live (`busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications GetCapabilities` and the `GetServerInformation` equivalent) and treat that as the baseline the new server must at least match, dropping only capabilities it deliberately doesn't implement (documented, not accidental).
- Build a small fault-injection fixture set, matching this repo's own `tests/quickshell-fixtures/` convention: a script that sends a notification, then a `replaces_id`-bearing update to it, and asserts only one bubble is visible; a script that sends a notification with an action and asserts `ActionInvoked` actually fires by watching the bus.
- Grep every real daily-driver sender this desktop currently produces notifications from (NetworkManager, the wifi/bluetooth panels' own failure copy, `swayosd`-adjacent scripts if any use `notify-send`, browser downloads, Discord/Slack if used) for `replaces_id` or action usage before assuming a bare "show text" implementation is sufficient.

**Warning signs:**
- Progress-style notifications (downloads, updates) stack instead of updating in place.
- A notification action button visibly exists but clicking it does nothing.
- Any app's own notification "richness" (images, urgency-based styling) looks worse post-migration than under swaync with no CSS change to explain it.

**Phase to address:**
The swaync → QML notifications phase; the fault-injection fixtures should exist before the human render-and-look gate, since this class of bug is invisible to visual inspection.

---

### Pitfall 3: Notifications sent while the shell is restarting or hot-reloading vanish with no trace

**What goes wrong:**
Every QML surface in this repo dies and respawns on hot reload (documented Quickshell behavior this project already relies on for iteration speed) or on a crash of the shared shell-root process. During the window where the notification server component is not yet re-registered on the bus, any `notify-send` call from anywhere on the system — including this repo's own scripts — is either silently dropped (if the caller ignores the D-Bus error) or produces a user-visible but confusing "no such service" dbus-send error. Because notification delivery is fire-and-forget by design (the spec has no persistent queue/retry), there is no "catch up" mechanism unless the new server builds one deliberately.

**Why it happens:**
GTK3 apps in this repo already needed a hard restart for CSS changes (documented precedent: "GTK3 has no live CSS reload API"); Quickshell hot-reload is faster and more frequent during development, which is exactly when this gap is most likely to bite — a developer testing a theme tweak fires a real notification mid-edit and it disappears, and the natural conclusion is "the notification logic is broken" rather than "the server was mid-respawn."

**How to avoid:**
- Treat the notification-server component as its own long-lived Quickshell singleton/root object that survives QML hot-reload of the *visual* surfaces around it if Quickshell's reload granularity permits it (verify this rather than assume it — Quickshell 0.3.0-2's reload scope is not guaranteed to be per-file). If it cannot be isolated from full-shell reloads, the acceptable mitigation is documenting the gap and keeping reload windows short, not building a queue — the queue is a client-daemon-restart-recovery feature swaync itself does not universally guarantee either.
- Add a `quickshell-doctor` check (extending the existing single-owner check) that measures the bus-ownership gap duration across a deliberate `pkill`-and-respawn cycle, so the window is a known, tracked number rather than an assumption.
- During manual dev/testing, prefer testing notification delivery immediately *after* a hot reload settles, not during it — and don't mistake a dropped test notification for a logic bug without first checking `busctl --user list` at that exact moment.

**Warning signs:**
- A notification sent immediately after a `theme-apply` switch or a QML file save is missing.
- Intermittent, non-reproducible "notification didn't show up" reports that don't correlate with sender-side changes.

**Phase to address:**
The swaync → QML notifications phase, as a measured (not assumed) characteristic recorded in that phase's evidence artifact — matching this project's own convention of writing down UNMEASURED rather than silently assuming zero-gap (see OVER-04's FPS term).

---

### Pitfall 4: Hardware-key OSD takeover breaks contexts a Hyprland `bind` structurally cannot reach

**What goes wrong:**
`swayosd-libinput-backend.service` is a **system**, not user, systemd unit (confirmed: `/usr/lib/systemd/system/swayosd-libinput-backend.service`, enabled via `sudo systemctl enable --now` in `install.sh`) that reads raw libinput events directly — this is *why* it works: it is not a Hyprland keybind at all, it is a separate daemon watching hardware input below the compositor's own bind table. That gives it reach into contexts a Hyprland `bind =`/`hl.bind` entry cannot ever have: before Hyprland has started (early boot, other DEs), on the greeter/lock screen (hyprlock is its own separate process with its own input handling — a compositor bind is not active there), and on a TTY. If SwayOSD is deleted and replaced purely with Hyprland binds calling the new QML indicator's IPC, **every one of those contexts silently loses OSD volume/brightness feedback**, and depending on how the replacement is wired, the *underlying key function itself* (not just the visual pill) may also stop working in those same contexts if nothing else is listening for the raw key there.
The failure mode is not uniform: on the lock screen, if PipeWire/`wpctl` itself is still bound via the WM or PAM/systemd session for `XF86Audio*` at a lower level, volume keys may keep changing the volume with **zero visual confirmation** (the OSD pill never shows) — this is the more dangerous mode because it looks like nothing is broken until someone is presenting/recording and the muted-but-unconfirmed state goes unnoticed. In other contexts the keys may do nothing at all.

**Why it happens:**
This is a category error waiting to happen: "SwayOSD" reads in the codebase and documentation as "the volume OSD," which invites treating its replacement as purely a rendering swap (new QML pill instead of the GTK popup). But SwayOSD is actually two things bundled — a themed renderer AND a system-wide input-capture daemon — and only the renderer half has a natural QML equivalent. The input-capture half has no Hyprland-bind equivalent by construction, because Hyprland binds only fire while Hyprland has compositor focus and is running.

**How to avoid:**
- Do not delete `swayosd-libinput-backend.service` even after retiring `swayosd-server`/`swayosd-client` and the `swayosd` stow package's *styling* — split the decision explicitly into "who renders the pill" (replaceable with QML) versus "who catches the keypress system-wide" (keep the libinput backend, or accept and document the context loss if truly retiring it).
- If the milestone's intent is genuinely to also stop depending on the libinput backend, enumerate every context where it currently provides coverage a compositor bind cannot (lock screen, pre-Hyprland-start, TTY) and get an explicit human sign-off that losing OSD feedback there is acceptable — this is exactly the kind of scope decision PROJECT.md's "no phase closes downgraded" rule should block silently.
- Test the specific failure modes deliberately, not just "press volume key and see a pill in the running session": lock the screen (`hyprlock`) and press a volume key — does the volume change? Does anything render? Switch to a TTY (`Ctrl+Alt+F2`) and press a volume key — same two questions. These are the two contexts this repo's own SwayOSD Key Decision explicitly credits the libinput backend with reaching ("system-wide... including contexts a Hyprland bind cannot reach").
- Keep `swayosd-client`'s D-Bus call as the actual volume/brightness-changing mechanism if at all possible, and have the new QML surface merely *listen* for the resulting D-Bus signal to render its own pill — this preserves the working mutation path and only replaces the renderer, which is the smaller, safer surface to redesign. Replacing the mutation mechanism itself (e.g. driving `wpctl`/`brightnessctl` directly from a new keybind chain) reintroduces the reach problem from scratch.

**Warning signs:**
- Volume/brightness changes on the lock screen or before full session start with no visual pill (the dangerous silent case).
- Media keys do nothing at all outside a fully-running Hyprland session.
- `systemctl status swayosd-libinput-backend.service` shows the unit stopped/disabled after a stow-package deletion that didn't intend to touch it.

**Phase to address:**
The SwayOSD → QML indicators phase — this needs to be scoped explicitly as "replace the renderer, evaluate the input-capture daemon separately" at phase-discussion time, not discovered mid-implementation.

---

### Pitfall 5: The bar is the project's first surface that must survive for days, not seconds — and it inherits none of the "zero-idle while dismissed" discipline built for transient surfaces

**What goes wrong:**
Every QML surface shipped before v4.0 (dashboard drawer, audio/wifi/bluetooth panels, workspace overview) is transient — summoned, used, dismissed, and per DASH-01..10's own delivered requirement, runs **zero timers and zero subprocesses while dismissed**. A bar has no dismissed state; it is visible and running for the lifetime of the session, which on this desktop can be days. That inverts the entire performance discipline this project has built to date:
- Any per-tick binding (clock, workspace indicator polling, a `Timer` driving an animation) that was "fine because it only runs while a panel is open for 30 seconds" becomes a permanent, cumulative cost.
- Any subprocess spawned per update (MPRIS polling, battery/backlight reads, network status) that was acceptable overhead in a transient surface's lifetime becomes a long-run churn source — process-table growth, zombie reaping if any spawn path doesn't wait()/reap correctly, and file-descriptor accumulation if any script-invocation pattern leaks pipes.
- QML object lifetime bugs that are invisible in a 30-second panel session (a `Connections` that isn't disconnected, a delegate that isn't destroyed by its `Repeater`/`Variants`, an image cache that isn't bounded) become visible only after hours-to-days of uptime as slow, hard-to-reproduce memory growth — exactly the kind of bug that doesn't show up in any phase-close gate because gates run for minutes, not days.

**Why it happens:**
The team's existing mental model and tooling (`quickshell-doctor`, the human render gate, UAT sessions) are all built and exercised on short-lived interactions. Nothing in the current gate suite measures behavior across hours of uptime, because nothing needed to before the bar.

**How to avoid:**
- Explicitly budget a soak-test step for the bar phase: launch it, note RSS via `ps`/`smem` at t=0, and again after several hours of normal desktop use (or an accelerated synthetic loop of theme switches, workspace changes, and MPRIS state changes if a multi-day wait isn't practical in the phase window) — this mirrors the project's own "measure, don't assume" discipline already applied to OVER-04's CPU term.
- Audit every `Timer`, `Process`/`Quickshell.execDetached`-style subprocess call, and `Connections` block introduced for the bar specifically for: does it keep running when there's nothing new to show, does every spawned subprocess get properly reaped, and does every dynamically created QML object have a corresponding destroy path.
- Layer-shell **exclusive zone**: the bar reserving screen space is fundamentally different from a panel that overlays — a wrong or flickering exclusive-zone value will visibly shove every tiled window on every reload, unlike a panel bug which is contained to the panel's own surface. Verify exclusive-zone handling against Hyprland's gap/reserved-area model specifically at each of: cold start, hot reload of the bar's QML, and a full `hyprctl reload`/compositor config reload — this repo already has one documented Hyprland-specific hazard in this exact area (`hyprctl reload` dropping layer rules per the user's own memory note), and the bar is the first surface whose exclusive zone is load-bearing for every other window's layout.
- Process-sharing blast radius: if the bar and the new notification server end up in the same Quickshell shell-root process (likely, since this repo already runs one shell-root process per `autostart.lua`), a crash or unhandled QML exception in either one takes down both — decide and document this tradeoff explicitly rather than discovering it the first time a notification-rendering bug also blanks the bar. If crash-isolation matters, that's an architecture decision for the bar phase, not a retrofit.

**Warning signs:**
- RSS creeping upward across a session with no plateau.
- `ps` showing accumulated zombie or orphaned subprocesses tied to bar module scripts hours into a session.
- Any window's tiled position shifting after a bar-related hot reload or `hyprctl reload`.
- A notification-rendering bug also freezes or blanks the bar (process-sharing blast radius, unmitigated).

**Phase to address:**
The waybar → QML bar phase (first phase) — because its patterns "seed every later surface" per PROJECT.md's own framing, the soak-test and exclusive-zone verification steps built here should become the template the SwayOSD/wleave phases reuse, not a one-off.

---

### Pitfall 6: The consumer grep for retirement misses the same classes of reference it missed last time

**What goes wrong:**
This project already has one confirmed incomplete-retirement incident (eww's popup: two inert `eww-media-popup` layerrules survived a "consumer-checked" removal) and one confirmed incomplete-registration incident in the opposite direction (`ags/` never added to `stow.sh`). Both are instances of the same underlying failure: a manual grep sweep that felt thorough but covered fewer reference classes than the file actually has. For v4.0, five surfaces are being retired in one milestone instead of one, multiplying the chances of repeating this exact mistake — and this time the reference surface (`windowrules.lua`, `autostart.lua`, `quickshell-doctor`) is materially larger and more interconnected than it was at the eww retirement.

Concretely, for waybar/swaync/SwayOSD/wleave/AGS, the reference classes a grep must cover — verified present in this repo right now, not hypothetical:
- **Layer rules by namespace** in `windowrules.lua` — confirmed live matches for `namespace = "waybar"`, `"swaync-control-center"`, `"swaync-notification-window"`, `"wleave"`, `"ags-media"` (blur, ignore_alpha, and animation rules, several per namespace).
- **`autostart.lua` exec lines** — `waybar-launch.sh`, `waybar-fullscreen-watch.sh`, `swaync-launch.sh`, `swayosd-server`, `ags run --directory ~/.config/ags` are each their own line with ordering comments explicitly marked load-bearing ("Ordering is load-bearing... no entry added, removed or reordered").
- **`install.sh` package lists** — `waybar`, `swaync`, `swayosd` in `PACMAN_PKGS`; `wleave` in `AUR_PKGS`; plus the `swayosd-libinput-backend.service` systemd-enable block, which is package-adjacent but not removed just by dropping the package line (see Pitfall 4 — this one should likely NOT be removed at all).
- **`stow.sh`'s `PACKAGES` array** — `ags`, `swaync`, `swayosd`, `waybar`, `wleave` are each their own array entry; forgetting to remove a retired one leaves a dead symlink target on fresh installs (the AGS-registration incident's mirror image).
- **`quickshell-doctor` assertions** — the `QSD_NAME_OWNERS["org.freedesktop.Notifications"] = "swaync"` registry entry (must be updated to the new owner name), plus any waybar/swaync/wleave-specific check bodies that assume those processes exist.
- **`theme-engine/.config/theme-engine/contract.json`** render-target entries for each surface's stylesheet (this repo's own precedent: the orphaned `eww.scss` contract entry blocked `theme-doctor`/`theme-parity` for an entire milestone after the 08-06/10-06 eww retirement — WINDOWS #1).
- **matugen templates** under `matugen/.config/matugen/config.toml` `[templates.*]` entries per surface.
- **keybinds** — any Hyprland bind that launches, toggles, or dispatches to the old surface (`waybar-visibility.sh`, wleave's launch keybind, an AGS media-toggle bind).
- **Systemd `--user` units, XDG autostart `.desktop` files, D-Bus `.service` activation files** — none of these five surfaces currently appear to register any of the first two beyond what's already in `autostart.lua`/`install.sh`, but this must be confirmed by an actual `find`/`systemctl --user list-unit-files` sweep per surface, not assumed absent because `autostart.lua` looks complete — the whole point of this class of miss is that it lives outside the file you're already looking at.
- **Portal config** (`xdg-desktop-portal` backend selection) — verify none of these surfaces are referenced as a portal implementation before deleting.
- **Doctor-script fixtures** — `hypr/.config/hypr/scripts/tests/quickshell-fixtures/` contains named fixtures referencing `swaync` by name (`compliant-busctl-list.txt`, `poisoned-two-owner-busctl-list.txt`); stale fixture content that still says `swaync` after the cutover will make `--self-test` runs pass against a fiction.

**Why it happens:**
A single grep pass or a mental checklist under-covers because reference classes accumulate ad hoc over the project's history (contract.json, layerrules, and quickshell-doctor's registries were each invented at different phases for different reasons) and no single file lists "everything that can reference a stow package." The eww incident is the proof: a self-described thorough sweep ("grepping every defwindow, script, autostart entry, matugen template and layerrule") still missed windowrules.conf specifically — the sweep's own description already named layerrules as a category it checked, and still missed two.

**How to avoid:**
Build (or reuse/extend, if a leftover eww-era version exists) a single **retirement checklist script**, not a manual grep, that runs the fixed set of checks above against a surface name and reports every hit — analogous to how `contract.json` + `lib/contract.sh` replaced ad hoc per-file assumptions for theming. Concretely, before deleting a package, grep the *exact* namespace/process/package strings (`waybar`, `swaync`, `swayosd`, `wleave`, `ags`, and their layer-rule namespace variants like `swaync-control-center`) across:
```
windowrules.lua, autostart.lua, keybinds*.lua, install.sh, stow.sh,
theme-engine/.config/theme-engine/contract.json,
matugen/.config/matugen/config.toml,
hypr/.config/hypr/scripts/quickshell-doctor,
hypr/.config/hypr/scripts/tests/**/*.txt,
hypr/.config/hypr/scripts/keybind-doctor (if it hardcodes surface names),
~/.config/systemd/user/*, /usr/share/dbus-1/services/*, /usr/share/applications/*.desktop (XDG autostart),
xdg-desktop-portal config
```
Run this checklist **twice**: once before deletion as a plan, once after deletion as a verification that every hit was actually resolved (not just found). The eww miss happened specifically because the check ran once, found things, fixed some, and nobody re-ran it to confirm zero hits remained.

**Right order — config then package, not package then config:**
Delete/update every *reference* first (layerrules, autostart line, contract.json entry, doctor registry, keybinds) while the package's files are still on disk, verify the desktop still boots clean and `quickshell-doctor`/`theme-doctor` are green with the reference gone, **then** delete the stow package directory and its `stow.sh`/`install.sh` entries last. Reversing this order (delete the package first) means any reference you missed fails loudly and immediately with a dangling symlink or missing binary — which sounds safer, but in practice this repo's daemons degrade rather than crash (`swaync-launch.sh` "degrading to unstyled rather than not running at all if the compiled sheet is ever absent" is the documented pattern for this codebase), so a missed reference after package deletion is *more* likely to fail silently, not less. Config-then-package also means the retirement can be validated with the old binary still present as a fallback if something regresses mid-edit.

**Warning signs:**
- `git grep -w waybar` (or swaync/swayosd/wleave/ags) after a "complete" retirement still returns hits outside comments/CHANGELOG-style history.
- `theme-doctor`/`theme-parity`/`quickshell-doctor` gates go red for a bookkeeping reason (orphaned contract entry, stale fixture) rather than a real regression — this exact shape already happened once (WINDOWS #1, the orphaned `eww.scss` entry).
- A fresh-install container/VM gate (D-34/D-36, already scheduled as debt paydown this milestone) surfaces a dead symlink or missing package that daily-driver testing never would, because the dev host still has the old package installed even after `stow.sh`/`install.sh` were edited.

**Phase to address:**
Every migration phase individually (each phase retires its own surface per the "retirement in the same phase that proves the replacement" decision), but the **checklist itself** should be built once, early — ideally as part of the waybar phase since it's first — and then reused verbatim by every subsequent phase rather than re-invented per surface.

---

### Pitfall 7: Redesign-instead-of-port loses daily-used features that never had a name

**What goes wrong:**
Reproducing a surface pixel-for-pixel makes regressions mechanical to find (this project's own `waybar-equivalence-check`/`hypr-equivalence-check` pattern). Redesigning against a reference language (end-4/Caelestia) instead means the new surface is judged against an aesthetic target, not a behavioral one — so it's entirely possible to ship something that looks better, passes every gate, and is genuinely worse because a feature nobody thought to write down as a "requirement" quietly didn't make the redesign. The canonical shape of this failure: a small interaction the user relies on unconsciously (scroll-to-change-workspace on the bar, right-click on a specific waybar module for a submenu, a swaync notification's specific dismiss-vs-click-through behavior, wleave's keyboard-only navigation path, SwayOSD's specific step-size/cap behavior on repeated key presses) isn't in any written spec because it was never a "feature," it was just how the old thing behaved — and the redesign, built from a reference screenshot/rice rather than from *this* desktop's actual behavior, has no reason to reproduce it.

**Why it happens:**
This is the explicit, acknowledged cost of the redesign-not-port decision recorded in PROJECT.md ("This deliberately forfeits the old-vs-new equivalence check..."). The mitigation named there — a mandatory-per-phase human render gate — catches *visual* regressions well (it already has, twice: Phase 6 and Phase 8's broken bars, Phase 16's false-pass thumbnails) but a render gate is a look-at-it check; it does not exercise every interaction path, and this project's own WINDOWS ledger shows exactly that gap already recurring elsewhere (multiple Phase 15 `unrun-verify` entries where "no synthetic pointer tool on host" left click/hover/scroll paths unproven even for shipped, in-scope work).

**How to avoid:**
- Before redesigning each surface, spend a cheap, deliberate pass enumerating the **current** surface's actual behavior — not its spec, its behavior — by reading the live config/script for that surface (its `.jsonc`/`layout.json`/keybind wiring) and by using it normally for a day with attention, since specs and comments have already been shown in this repo to omit things a script's actual logic reveals (per Pitfall 6's grep discipline, applied here to *behavior* instead of *references*). Write this down as a short enumerated list per surface **before** starting the redesign, so "did the redesign keep this" becomes a checklist item instead of a vague feeling.
- Specifically capture: every scroll/right-click/middle-click handler (waybar modules routinely bind these three independently of left-click), every keyboard-only path (wleave, swaync's control center), every "small state" behavior (SwayOSD's cap-at-max/min, mute-toggle vs mute-hold, the notification center's DND toggle interacting with the anti-drift state-sharing this repo already built for the Super-key menu).
- Treat this enumeration as input to each phase's own SPEC/requirements step (`gsd-spec-phase`/`gsd-discuss-phase`), not as a separate artifact nobody reads — it should generate the acceptance criteria the phase's UAT actually checks against, closing the gap a pure aesthetic render gate leaves open.
- Where a synthetic pointer tool genuinely doesn't exist on this host (confirmed absent per multiple Phase 15 WINDOWS entries), budget for real manual interaction testing rather than letting scroll/right-click/hover paths join the growing pile of `unrun-verify` WINDOWS rows — that pile is already at 16/23 open entering this milestone; each new migration phase risks adding to it rather than closing it if this isn't deliberately budgeted.

**Warning signs:**
- A UAT pass with zero human-reported regressions, followed within days of daily use by "wait, where did X go" — the classic gap between a scripted UAT session and unconscious daily muscle-memory use.
- Acceptance criteria for a redesigned surface that only describe appearance ("matches the reference rice's visual language") with no behavioral enumeration.
- Growing `unrun-verify` WINDOWS rows specifically for click/scroll/hover paths on the new surfaces, mirroring the Phase 15 pattern.

**Phase to address:**
Each surface's discuss/spec step, before planning begins — the enumeration is cheap relative to redoing a redesign after the human notices a missing feature mid-milestone.

---

### Pitfall 8: Quickshell 0.3.0-2-specific traps that behave differently for an always-on surface than a transient one

**What goes wrong:**
Several already-discovered, project-specific Quickshell quirks either get worse or newly manifest once a surface is always-on rather than summon/dismiss:
- **`Variants`/`LazyLoader` gotchas** — this project already hit an FM1 scanner race (fixed by a checked-in `modules/qmldir`) and an FM2-class multi-screen surface-creation failure (QS-03, permanently accepted-as-broken per D-13) in exactly this area. A bar built with `Variants` over `Quickshell.screens` (the natural pattern for a multi-monitor-ready bar, even though this host has one monitor) inherits the same QS-03 risk class the overview already hit — expect this to resurface, and don't re-attempt the same two structurally distinct arrangements Phase 12 already spent a bounded budget disproving; if per-screen fan-out is wanted for the bar, that needs its own explicit spike, not an assumption it'll "just work" this time on the same quickshell version.
- **`PanelWindow` exclusive zone and anchoring** — already flagged in Pitfall 5 as a bar-specific hazard; add to it that Quickshell's exclusive-zone value must stay correct across every hot reload, not just cold start, and this repo already has one documented case (the user's own memory note) of `hyprctl reload` dropping layer rules silently — a bar whose exclusive zone silently reverts to 0 after a reload will look fine (bar still renders) while every window's tiled geometry is subtly wrong, which is a much harder bug to notice than a visibly broken surface.
- **IPC quirks** — the shell already has a documented one-shot handoff bug class (subprocess `onExited` firing 16-30ms after launch, before results land, from the Phase 15 hidden-network bug) and a documented dead-API bug class (`hyprctl dispatch global <string>` withdrawn under the Lua config manager, ~8 sites still dead in `quickshell-doctor`). Any new IPC wiring for the bar/notification-server/OSD/power-menu surfaces should be checked against both patterns specifically: does any handoff rely on process-exit timing instead of a real "results landed" signal, and does any new `hyprctl dispatch` call use the bare pre-Lua string form instead of the `hl.dsp.*` table/quoted-Lua form this repo's own precedent (`theme-stress-test:368/571`) already establishes as correct.
- **Hot-reload state loss** — transient surfaces reset their state naturally on every summon, so hot-reload wiping in-memory state was invisible before. An always-on bar (and a notification server holding a queue of unread notifications, and an OSD holding a "currently showing" timer) has state that must either survive a QML hot reload or be explicitly and deliberately reset — verify which happens for each piece of state introduced, rather than discover the answer the first time a real notification gets reloaded away mid-display.
- **Qt render-loop selection** — already found once: Qt auto-selects the basic render loop, capping the dashboard drawer at ~60fps until `QSG_RENDER_LOOP=threaded` was set to reach the panel's real 165Hz. Confirm this environment variable is set for whatever process/session scope the bar and every other new always-on surface launches under — this is an easy regression to reintroduce if a new surface's launch script doesn't inherit the same environment the drawer's launch path picked up the fix from.
- **Compositor-reload behavior** — distinct from QML hot-reload: does the bar (and its exclusive zone, and the notification server's D-Bus ownership) survive a full `hyprctl reload` or a Hyprland config reload cleanly, or does it need to be re-summoned/restarted? This repo has zero precedent for this specific interaction since no always-on surface has existed before the bar.

**Why it happens:**
Every one of these bugs was discovered on a *transient* surface where the blast radius was small (dismiss and resummon fixes most of them by accident) and where phase-close testing windows (minutes) never exercised the multi-hour-uptime or repeated-reload conditions that surface them on an always-on window.

**How to avoid:**
- Treat the bar phase (and, downstream, the notification-server phase which likely shares its process) as the first phase that must explicitly test: cold start, QML hot reload mid-session, `hyprctl reload`, and a genuine multi-hour soak — four distinct conditions this project's existing gates have never all exercised on one surface.
- Reuse, don't rediscover: grep the codebase for the existing fixes to the one-shot-handoff bug class and the dead-dispatch-string bug class before writing new IPC code, and apply the same patterns proactively.
- Explicitly decide and document whether QML hot-reload during development is expected to preserve the notification queue/OSD state/bar's own internal timers, and test that decision rather than assume it either way.

**Warning signs:**
- Bar exclusive zone silently reverting after `hyprctl reload` (windows shift without a bar-visibility change).
- Frame rate dropping to ~60fps on the bar or the notification popups with no code change, on a machine capable of 165Hz — matching the exact class of bug already found once.
- A `Variants`-based multi-surface construct silently rendering on only one screen, or crashing, matching QS-03's signature.

**Phase to address:**
The waybar phase for the render-loop/reload/exclusive-zone checks (first surface, sets the pattern); the swaync phase specifically for the hot-reload-state-loss and IPC-handoff checks (a notification queue is the first piece of genuinely important in-memory state this project has put on a QML surface).

---

### Pitfall 9: Migration and debt-paydown compete for the same milestone window, and debt loses quietly

**What goes wrong:**
This exact failure already has a precedent inside this project's own history: v3.0's Key Decision "Close v3.0 as an override closeout" explicitly names the test as "whether v4.0 actually picks up the two real carry-ins... or whether they age in the backlog" — an open question the milestone itself flags as unresolved at scoping time. With five surface migrations plus a stated debt list (GradientBorder reuse, MAINT-02 Logout, OVER-04's FPS term, D-34/D-36 container rerun, 6 debug sessions, WINDOWS.md's 16 open rows) sharing one milestone, the natural failure mode when migration phases run long (which multiple phases already have — Phase 8's bar rework, Phase 16's thumbnail rework) is that debt-paydown items get pushed to "the end," and if the milestone closes as another override closeout, they carry forward untouched a second time, compounding rather than shrinking.

**Why it happens:**
Migration work has a visible, demo-able output (a new surface exists) that produces natural stopping points and stakeholder satisfaction; debt paydown items are individually small, unglamorous, and easy to defer "just one more phase." Nothing structurally forces them to interleave rather than trail — the Active requirements list in PROJECT.md already lists all migration items before all debt items, which subtly encodes an ordering even though it isn't declared as one.

**How to avoid:**
- At roadmap-creation time, deliberately interleave debt-paydown items into the migration phase sequence rather than clustering them all at the end — e.g. attach OVER-04's FPS measurement to whichever phase first needs a working `QSG_RENDER_LOOP=threaded` frame-rate-sensitive surface (the bar, given 165Hz already matters there), attach the D-34/D-36 container rerun to the retirement phase where it becomes load-bearing (per PROJECT.md's own framing: "this milestone deletes stow packages, so a fresh-install proof is a regression gate, not bookkeeping" — meaning it should run near the FIRST retirement, not the last, so a broken fresh-install path is caught early rather than discovered only at milestone close).
- Curate the 6 open debug sessions and WINDOWS.md's 16 open rows as an explicit, sized backlog at roadmap time (which ones are genuinely small, which are structural) rather than one undifferentiated "curate the backlog" line item that can be deferred wholesale.
- If a migration phase does run long, the recovery move that keeps debt-paydown from silently dying is scope-cutting the *migration* phase's stretch goals first (this project already has a precedent for this: Ambient extras in v3.0 were "explicitly the first thing cut if the milestone runs long") rather than implicitly deferring debt items that were never explicitly named as cuttable.

**Warning signs:**
- A mid-milestone status check where every recently-closed phase is a migration phase and zero debt items have moved from Active to Validated.
- The debt-paydown items still reading verbatim, unchanged, in the Active section partway through the milestone — a sign they haven't been touched, not just not-yet-finished.
- Milestone-close pressure producing a third consecutive override closeout — two in a row (v3.0's own closeout language flags this pattern explicitly) becomes a habit, not an exception, on the third.

**Phase to address:**
Roadmap-creation time (this is precisely the phase-ordering decision the roadmapper needs to make, informed by this pitfall) — not a runtime pitfall to catch mid-execution, but a structural one to design around from the first phase-sequencing decision.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Keep the old package installed (not stow-deleted) after the new surface passes UAT | De-risks rollback if the new surface regresses under real multi-day use | Two shells' worth of D-Bus/autostart/layerrule config coexisting invites exactly the two-owner race (Pitfall 1) if not carefully sequenced | Acceptable and recommended for a bounded soak window (days, not weeks) with the old daemon's autostart line explicitly disabled, not just "still on disk" |
| Redesign without first enumerating current behavior (skip Pitfall 7's cheap pre-pass) | Faster start on the visually interesting work | Silent feature loss discovered by the user in daily use, well after the phase closed green | Never — the enumeration is cheap relative to a mid-milestone regression report |
| Ship the QML notification server without a fault-injection fixture for `replaces_id`/actions | Faster to a visually-working demo | Silent protocol under-implementation that looks like a UX bug (notification spam) rather than what it is | Never for this surface specifically — the project already has the fixture pattern (`quickshell-fixtures/`) to reuse cheaply |
| Delete a stow package's config references via a single manual grep pass instead of the fixed reference-class checklist | Faster, feels thorough in the moment | Repeats the eww incident, possibly multiple times across five surfaces | Never — this is the exact mistake this milestone should not repeat given it already happened once |
| Defer the bar's soak-test (memory/timer-churn check) to "later, if it becomes a problem" | Ships the visible feature sooner | Multi-day memory growth is invisible to any phase-close gate that runs for minutes; it will surface as an unexplained slowdown weeks later, far from its cause | Acceptable only if explicitly logged as an open WINDOWS.md item with a committed follow-up, not silently dropped |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| `org.freedesktop.Notifications` D-Bus ownership | Assuming only one process will ever try to own it at a time, with no test for the race | Reuse and extend `quickshell-doctor`'s existing `QSD_NAME_OWNERS`/poisoned-fixture pattern; test the crash-and-respawn path deliberately |
| SwayOSD's libinput backend | Treating "replace SwayOSD" as a pure rendering swap | Split explicitly: renderer (replaceable with QML) vs. system-wide input capture (has no compositor-bind equivalent for lock-screen/pre-session contexts) |
| Hyprland layer rules by namespace | Assuming a namespace string match is self-documenting and safe to delete once the surface it names is gone | Grep the exact namespace string across `windowrules.lua` before AND after each retirement; namespaces are matched by substring/regex in places (`^quickshell-.*`), so a rename can silently orphan or silently over-match a rule |
| `theme-engine/contract.json` render targets | Deleting a surface's stylesheet file without dropping its `contract.json` entry | Drop the contract entry in the same commit as the file deletion — this project already broke `theme-doctor`/`theme-parity` for a full milestone this exact way (WINDOWS #1) |
| Quickshell hot reload vs. always-on state | Assuming hot reload behaves the same for a transient panel and a permanent bar/notification-queue | Explicitly test and document whether in-memory state (notification queue, OSD "currently showing" timer) survives a hot reload; don't assume either answer |
| `hyprctl dispatch` calls from new scripts/QML IPC | Copying an old bare-string dispatch form (pre-Lua-migration) into new code | Use the `hl.dsp.*`/quoted-Lua form this repo's own `theme-stress-test`/`_qsd_dispatch_global` already establish as correct; grep for the withdrawn bare-string form whenever adding a new dispatch call site |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| Per-tick QML bindings/timers ported from a "runs while open" mental model onto an always-on bar | Slowly rising CPU/battery use with no single obvious cause | Audit every `Timer` and animation trigger introduced for the bar for whether it keeps running when nothing changed | Noticeable within hours of continuous use; may not show in a phase-close gate that runs minutes |
| Subprocess-per-update polling (MPRIS, battery, network) copied from a transient surface's pattern onto an always-on bar | Process-table growth, occasional zombie processes, fd exhaustion over very long uptimes | Prefer event-driven/shared-reader patterns already established (one MPRIS reader shared across surfaces, per DASH-01..10's own precedent) over each new surface independently polling | Multi-day uptime; classic "why is my desktop slow after 3 days" bug shape |
| Basic (non-threaded) Qt render loop silently selected again on a new surface's launch path | Frame rate caps around 60fps on a 165Hz-capable machine, with animations feeling different from other surfaces with no code reason why | Confirm `QSG_RENDER_LOOP=threaded` (or its equivalent for whatever launches each new surface) explicitly, don't assume it's inherited | Immediately visible if checked; easy to miss if not, since 60fps still "looks fine" in isolation |
| Bus-ownership gap during hot-reload/restart windows treated as instantaneous | Occasional, hard-to-reproduce "notification vanished" reports | Measure the actual gap duration via a deliberate `pkill`-and-respawn test, add it to `quickshell-doctor` | Any time the shell restarts mid-notification-burst; rare but real on a daily-driver |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| A new notification server that renders arbitrary sender-supplied body markup without sanitizing it | Malicious or buggy local app sends a notification with embedded markup/URIs that misrenders or, worse, is clickable-through to something unintended | Sanitize/allowlist the small markup subset the freedesktop spec actually permits (basic `<b>`/`<i>`/`<a>`), matching this repo's existing V5 input-validation discipline (`quickshell-doctor`'s `_qsd_valid_token` allowlist pattern) applied to a new untrusted-input surface |
| Trusting `ActionInvoked`/action-button payloads from any sender without validating them before passing to a dispatch/exec call | A malicious local process could theoretically craft an action ID that, if naively string-interpolated into a shell command or Lua dispatch string, becomes a command-injection path | Apply the same strict-allowlist discipline this repo already uses for manifest-derived tokens reaching `hyprctl dispatch` (`_qsd_valid_token`, T-11-10) to any notification-action-derived string that reaches a dispatch/exec call |
| Retiring wleave's GTK4 layer-shell surface without re-verifying the new QML power menu still displaces any external prompt/dialog the same way wleave's replacement of wlogout did | Power-menu-adjacent dialogs (if any ever appear, e.g. a "confirm shutdown while X is unsaved" prompt from another app) could end up hidden behind the new layer-shell surface exactly as the wifi/bluetooth password-prompt z-order issue happened in Phase 15 | Re-run the same "who owns the prompt" check this project already learned from Phase 15's wifi/bluetooth work for any surface the new power menu might occlude |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-------------------|
| Volume/brightness key press produces no visual feedback on the lock screen or before session start | User believes the key didn't register, may press repeatedly, ends up at an unintended volume level, or believes the desktop is broken | Preserve the libinput-backend's system-wide reach (Pitfall 4) or explicitly document and accept the reduced-context coverage before shipping |
| A redesigned surface that looks better but drops a scroll/right-click/keyboard-only interaction the user relied on daily | Feels like "it got worse" despite objectively passing every visual gate — erodes trust in future redesigns | Enumerate current behavior before redesigning (Pitfall 7), verify each enumerated interaction explicitly in UAT |
| Notification popups that stack instead of updating in place for progress-style senders | Reads as "notification spam," gets misdiagnosed as a UX complaint rather than a `replaces_id` protocol gap | Fault-injection test `replaces_id` behavior explicitly (Pitfall 2) before it ever reaches a human UAT session |
| The bar's exclusive zone silently reverting after a compositor reload, shifting every tiled window | Confusing, hard-to-attribute layout jumps that look unrelated to "I just reloaded Hyprland" | Explicit reload-survival test as part of the bar phase's gate (Pitfall 8) |

## "Looks Done But Isn't" Checklist

- [ ] **Notification server takeover:** Often missing a tested crash-and-respawn path — verify `busctl --user list | grep -c Notifications` returns exactly 1 immediately after a deliberate `pkill` of the new server followed by its restart, not just after a clean boot.
- [ ] **Notification server D-Bus contract:** Often missing `replaces_id` and `ActionInvoked` handling even when popups render correctly — verify with a fault-injection script that sends a replace-update and an action, not just a bare notify-send.
- [ ] **SwayOSD replacement:** Often missing lock-screen and pre-session-start coverage — verify by locking the screen and pressing a volume key, and by testing from a TTY, not just from within a running Hyprland session.
- [ ] **Bar exclusive zone:** Often missing survival across `hyprctl reload` and QML hot reload — verify by reloading both and checking no window's tiled geometry shifted.
- [ ] **Bar long-run stability:** Often missing any multi-hour measurement at all — verify RSS and process count at two points hours apart, not just at launch.
- [ ] **Retirement consumer-check:** Often missing systemd `--user` units, XDG `.desktop` autostart entries, D-Bus `.service` activation files, and doctor-script fixture content even when config files and layerrules are correctly swept — verify with the full reference-class checklist (Pitfall 6), run twice (before and after deletion).
- [ ] **Redesigned surface behavior parity:** Often missing scroll/right-click/keyboard-only paths that were never written down as requirements — verify against a pre-redesign behavior enumeration, not just the visual render gate.
- [ ] **Debt-paydown items:** Often missing from mid-milestone status entirely once migration phases run long — verify at each phase transition that at least one debt item, not only migration items, moved from Active toward Validated.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|----------------|------------------|
| Two-owner D-Bus race discovered in production | LOW | Kill both processes, restart only the intended one, verify single ownership via `busctl --user list`; fix the autostart ordering/removal that caused the race |
| Notification server worse than swaync after real use (dropped notifications, missing capabilities) | MEDIUM | Because the old `swaync` stow package and `swaync-launch.sh` are kept undeleted during the soak window (per Pitfall 1's mitigation), rollback is: re-add the `swaync-launch.sh` autostart line, remove the new server's autostart line, restore `QSD_NAME_OWNERS` to `swaync` — a same-shape atomic edit as the original cutover, reversed |
| SwayOSD context-coverage regression discovered (lock screen / TTY keys stop giving feedback) | LOW | Re-enable `swayosd-libinput-backend.service` if it was disabled (`sudo systemctl enable --now`) — the packaged unit is unmodified by this migration if Pitfall 4's guidance was followed, so this is a one-command revert |
| Bar memory growth discovered after days of use | MEDIUM-HIGH | Requires a real debugging session (QML object lifetime audit, Timer/Connections audit) rather than a config revert — budget this as a `gsd-debug` session, not a quick fix, matching the project's own precedent for multi-cause investigations |
| Incomplete retirement discovered post-close (a missed layerrule/contract entry, mirroring the eww incident) | LOW | Run the full reference-class checklist (Pitfall 6) against the retired surface's name now, even though the phase is closed — this is exactly how the eww miss was eventually caught, just later than ideal |
| Migration ran long and debt-paydown items were silently dropped | LOW-MEDIUM (if caught before milestone close) / carries forward (if not) | At milestone-close time, explicitly re-triage the debt list rather than defaulting to another override closeout; the cost of catching this late is primarily the same cost v3.0 already paid — acknowledged debt, not a blocked milestone |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|--------------------|----------------|
| 1. Notification-server D-Bus ownership race | swaync → QML notifications phase | `quickshell-doctor`'s `QSD_NAME_OWNERS` check (extended to the new server name) passes on live boot, plus a deliberate `pkill`-and-respawn test showing single ownership restored |
| 2. Notification-server contract under-implementation | swaync → QML notifications phase | Fault-injection fixtures for `replaces_id` and `ActionInvoked`, modeled on `quickshell-fixtures/`, both green before the human render gate |
| 3. Notifications lost during hot-reload/restart | swaync → QML notifications phase | Measured (not assumed) bus-ownership gap duration recorded in the phase's evidence artifact |
| 4. SwayOSD context-coverage loss (lock screen, TTY, pre-session) | SwayOSD → QML indicators phase | Manual test: volume key at lock screen shows feedback; volume key from a TTY is explicitly evaluated and the outcome documented, not assumed |
| 5. Bar always-on resource/exclusive-zone hazards | Waybar → QML bar phase (first phase) | RSS/process-count measurement hours apart; exclusive zone verified stable across `hyprctl reload` and a QML hot reload |
| 6. Incomplete retirement consumer-check | Every migration phase, checklist built once in the waybar phase | Reference-class checklist run twice (pre- and post-deletion) per surface, zero hits after |
| 7. Redesign losing unnamed daily-used features | Each surface's discuss/spec step, before planning | Behavior enumeration exists and is checked item-by-item in that phase's UAT, not just the visual render gate |
| 8. Quickshell 0.3.0-2 always-on-specific traps | Waybar phase (render-loop/reload/exclusive-zone); swaync phase (state-survival/IPC-handoff) | Explicit test matrix: cold start / hot reload / `hyprctl reload` / multi-hour soak, all four exercised and recorded |
| 9. Debt-paydown silently dropped as migration runs long | Roadmap-creation time (phase sequencing) | At least one debt item closes per 1-2 migration phases, checked at each phase transition, not deferred to milestone close |

## Sources

- Direct repository inspection (HIGH confidence — ground truth, not a web claim): `.planning/PROJECT.md` (Key Decisions table, Active/Out-of-Scope requirements, milestone history), `.planning/MILESTONES.md` (v3.0/v2.0 known-gaps and tech-debt sections), `.planning/WINDOWS.md` (23-row broken-windows ledger, 16 open), `hypr/.config/hypr/scripts/quickshell-doctor` (existing `QSD_NAME_OWNERS`/`QSD_CLIENT_CONSUMERS` D-Bus identity model, `poisoned-two-owner-busctl-list.txt` fixture, `_qsd_dispatch_global`'s documented Lua-dispatch-string hazard), `hypr/.config/hypr/config/autostart.lua` (real, load-bearing daemon launch order), `hypr/.config/hypr/config/windowrules.lua` (live layer-rule namespaces per surface), `install.sh` (PACMAN_PKGS/AUR_PKGS entries, `swayosd-libinput-backend.service` system-unit enablement), `stow.sh` (PACKAGES array).
- This project's own documented prior incidents, cited directly rather than inferred: the eww consumer-check miss (PROJECT.md Key Decisions, "⚠ Revisit"), the `ags/` unregistered-stow-package incident, the orphaned `eww.scss` contract-entry incident (WINDOWS #1), the D-35 Hyprland-plugin permission/crash finding, the QS-03 per-screen fan-out one-way drop (D-13), the motion-token `reduced`-preset-faster inversion (G-15-1/15-11), the Phase 15 one-shot-handoff bug (`onExited` firing before results land), the withdrawn `hyprctl dispatch global <string>` form (WINDOWS #13/#14), the wifi-vs-bluetooth secret-agent z-order lesson (Key Decisions, "never fight the z-order").
- No external web research was performed for this pitfalls file — every finding above is either drawn directly from this repository's own committed evidence or is a direct logical extension of that evidence (e.g. freedesktop notification-spec contract fields named because this repo's own doctor/fixture infrastructure already models the D-Bus single-owner requirement). Confidence is HIGH for anything citing a specific file/line/commit above, MEDIUM for the general D-Bus/notification-spec/Quickshell-ecosystem claims that extend that evidence, and no LOW-confidence claim is presented as authoritative per the project's own verification discipline.

---
*Pitfalls research for: Shell migration & debt paydown, Arch + Hyprland Quickshell rewrite (v4.0)*
*Researched: 2026-08-10*
