# Research Summary: v4.0 Shell Migration & Debt Paydown

**Project:** Arch + Hyprland Dotfiles (Quickshell/QML shell migration)
**Domain:** Wayland desktop shell replacement (waybar/swaync/SwayOSD/wleave/AGS → Quickshell/QML)
**Researched:** 2026-08-10
**Confidence:** HIGH (direct binary inspection + source code read) for stack/architecture; MEDIUM-HIGH for features/pitfalls

## Executive Summary

**v4.0 is a single-process, one-shell migration replacing five independently-failing GTK/GTK4 shell components (waybar, swaync, SwayOSD, wleave, AGS) with a unified Quickshell/QML renderer inside the existing `quickshell 0.3.0-2` package.** Every required service (notifications D-Bus server, PipeWire volume, battery state, tray, networks, media) is already shipped inside quickshell's own modules — no new packages are needed.

The recommended approach is **bar first** (proves always-on `PanelWindow` + exclusive-zone pattern), then notifications/OSD/power-menu in that sequence, then AGS fold-in last. The **single largest gate — notification-server D-Bus ownership** — is technically feasible (Quickshell's `NotificationServer` is real, verified installed) but operationally risky (two-owner race, hot-reload state loss) and must be explicitly decided before the notifications phase begins.

**Two carry-in debt items are already closed in code** (GradientBorder reuse in `PanelDialog.qml` per commit `4f48847`; `quickshell-doctor` dispatch form already on the correct Lua `hl.dsp.global(...)` form) — both independently re-verified by the orchestrator against the working tree, not taken on the researchers' word. Only bookkeeping remains; the roadmapper must NOT scope phases for them.

One legitimate downgrade risk remains unresolved: **the AGS cava-visualizer** that the dashboard deliberately cut in Phase 14 must be either built (new QML process reader) or explicitly sign-off-deferred before AGS retirement, or the fold-in silently violates this milestone's own "no phase closes downgraded" rule.

## Key Findings

### Recommended Stack

**All technologies already installed; no version bumps available or needed:**

- **quickshell 0.3.0-2** — the QML toolkit; this IS the v3.0 commitment. Confirmed latest in `extra`; `quickshell-git` exists in AUR but is version-behind and flagged out-of-date, and no capability gap forces it.
- **Quickshell.Services.Notifications** — verified a real `org.freedesktop.Notifications` D-Bus **server** (not merely a passive client), read directly from `/usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes`. Direct swaync protocol-layer replacement, including a genuine inline-reply capability swaync 0.12.6 lacks. Does NOT provide for free: the control-centre UI, DND persistence, or history — all already in scope to build.
- **Quickshell.Services.Pipewire** — volume/mute/sink control; already powers the Phase 15 audio panel
- **Quickshell.Services.UPower** — battery state
- **Quickshell.Services.SystemTray** (+ DBusMenu) — StatusNotifierItem tray
- **Quickshell.Hyprland** — workspaces, dispatch, layer extensions (already load-bearing for Super+D / Super+O)
- **Quickshell.Networking / .Bluetooth** — already power the Phase 15 panels
- **Quickshell.Services.Mpris** — already the shared reader
- **Quickshell.Wayland._IdleNotify / ._IdleInhibitor** — candidate native path for OLED-safe visibility
- **Quickshell.Io.FileView** (inotify-backed `watchChanges`, verified present) + sysfs `/sys/class/leds/*::capslock/brightness` — capslock OSD with **zero root daemon**
- **Quickshell.Io.Process** — shelling out to existing scripts

**Only real gap:** CPU/RAM/disk statistics have no dedicated Quickshell module and need the same `Process`-backed approach the Dashboard's Performance tab already uses.

**Retirement requirement: ATOMIC package deletion.** Package removal, `contract.json` entry deletion, matugen-template deletion, and checker-script deletion must land in the same commit per retired surface. WINDOWS #1 (an orphaned `eww.scss` blocking `theme-doctor` for a full milestone) is the standing precedent. All five packages show `Required By: None` in `pacman -Qi`, so removal is unblocked once repo consumers migrate.

**Live side-finding:** `wlogout` and `eww` are **still installed on the host** despite being retired from the repo in earlier milestones — an existing instance of the same leftover failure class this milestone exists to end. Worth an explicit cleanup line.

### Expected Features & Differentiators

**Source-verified reference-rice shapes** (read from actual QML on GitHub, not blog summaries — this project has a standing convention of source-verifying reference-rice claims after discovering neither reference uses `SpringAnimation` despite widespread belief):

- **Caelestia's bar is vertical / right-edge** with pill-grouped workspaces.
- **end-4's "ii" bar is horizontal** (top/bottom, configurable), per-monitor, with a "Hug vs Float" island `cornerStyle` switch and separate rounded `BarGroup` islands.
- **Both rices independently implement swipe-to-dismiss on notification popups** — a strong table-stakes signal precisely because two unrelated projects converged without copying each other.
- **Both instantiate `NotificationServer` directly in their own QML singleton** — the shell *is* the D-Bus server, not a client.
- **Caelestia validates the media fold-in decision**: it has no bar media entry at all — media lives only in the dashboard (a small tile plus a fuller page with a radial cava-visualizer wrapped around a shaped cover-art cutout). That is the closer structural analog to "fold into the dashboard Media tab, no standalone card."

**Table stakes (what waybar/swaync/SwayOSD/wleave/AGS ship today and a replacement must not lose):**

- Bar: click workspace to switch, scroll volume/brightness, notification-centre button, OLED auto-hide, system tray, clock, battery
- Notifications: transient popups, stacking, swipe-dismiss, auto-expire, actions, notification centre with history
- OSD: volume/brightness/capslock indicators, auto-hide
- Power: six actions (Shutdown/Reboot/Suspend/Hibernate/Logout/Lock)
- Media: play/pause/next/prev, seek bar, cover art, player switching, **audio-reactive cava visual**

**Differentiators worth taking from the reference rices:**

- Bar: per-widget contextual popouts; dual auto-hide reveal (hover + Super-peek — OLED-relevant); "island" style toggle
- Notifications: inter-surface geometry coordination, fullscreen-aware suppression, DND as a quick-toggle
- OSD: multiple simultaneous sliders (volume + mic + brightness at once)
- Power: in-context safety warnings (package-manager / download-running banners — maps directly onto this project's own unresolved Logout teardown-hazard concern); full keyboard navigation
- Media: radial cava-visualizer around shaped cover art

**Anti-features (explicitly do NOT copy, tied to PROJECT.md Out of Scope):** AI chat sidebar, full GUI settings app / Waffle alt-shell, per-track dominant-colour re-tinting (conflicts with the single-palette-source architecture), audio-sink protection banner (no equivalent trigger here), decorative mascot GIFs.

### Architecture Approach

**One process, multiple summonable surfaces + one always-mounted surface:**

- All surfaces live as `.qml` files under `quickshell/.config/quickshell/modules/`, registered in explicit `qmldir` manifests
- Summonable surfaces (dashboard, panels, power, notification centre, OSD) wrap in `LazyLoader { active: false }` — destroyed on dismiss
- **Always-mounted bar — genuinely new pattern.** Every existing QML surface uses `exclusiveZone: 0` and summon-on-demand; the bar needs `exclusiveZone > 0` and permanent mounting for the first time.
- **QS-03's answer for an always-on bar is "don't fan out."** `Overview.qml` already proves the pattern (a single `PanelWindow`, no `Variants`) since the host has one monitor (`DP-1`). The bar should copy that rather than re-attempt per-screen fan-out, which was dropped one-way under D-13. No evidence of an upstream fix was found; it is irrelevant on this host regardless.
- Notification server as its own `NotificationServer` singleton inside the shell root, holding D-Bus ownership outright
- Shared backends (MediaBackend, AudioBackend, …) mounted once unconditionally

**Contract consequences:** `contract.json` goes **29 → 17 entries** (12 removed across the five retiring packages). QML surfaces need **zero** new contract entries — an established D-18 precedent (`Colours.qml`'s own header) that already applies and needs no reinvention.

**Critical new risk — bar crash blast radius.** If the bar and the notification server share one quickshell process (the likely design), any crash takes down both — and loses the always-on surface the user depends on continuously. `quickshell-launch.sh` currently has **no restart wrapper**. Decision needed at the bar phase: add restart-on-crash supervision, or accept and document the risk.

**Regression gates replace equivalence checks.** `waybar-equivalence-check` and `waybar-design-lint` die with waybar; no generic replacement exists. The mechanical net that carries over is extending `quickshell-doctor` (already an extensible pattern) plus a new hex-literal lint mirroring `motion-lint`'s deny-by-default discipline. **Appearance judgment moves fully to the mandatory human render gate**, per the project's own stated rationale — Phase 8 and Phase 16 both shipped visibly broken surfaces through fully green automated gates.

### Critical Pitfalls

1. **D-Bus notification-server ownership race.** Two processes holding `org.freedesktop.Notifications` means silently queued or stolen name ownership; senders never see an error. *Mitigation:* extend `quickshell-doctor`'s existing `QSD_NAME_OWNERS` registry — its `poisoned-two-owner-busctl-list.txt` fixture **already models this exact failure state** and needs only the owner name updated and to be run live rather than only self-tested. Test the crash-and-respawn path deliberately; keep `swaync` installed with autostart **disabled** during a soak window; never split the autostart-line change and the package deletion across separate commits.

2. **Notification-server D-Bus contract under-implementation.** `GetCapabilities` wrong, `replaces_id` dropped (progress notifications stack instead of updating), `ActionInvoked` never emitted. *Mitigation:* capture swaync's current capabilities as a baseline; build fault-injection fixtures for `replaces_id` and action invocation. A short throwaway probe (`notify-send -r`) early in the phase is the right discipline — the same shape as QS-02.

3. **Always-on bar resource and exclusive-zone hazards.** Timers, subprocesses and caches that are harmless for 30 seconds become permanent costs over days: RSS creep, zombies, FD exhaustion. The bar inherits **none** of the "zero-idle while dismissed" discipline built for the dashboard drawer, because it has no dismissed state. None of the existing gates (which run for minutes) would catch multi-day drift. *Mitigation:* budget an explicit soak test (RSS at t=0 and t=hours); audit every `Timer`/`Process` for "keeps running when nothing changed"; verify the exclusive zone survives `hyprctl reload` and QML hot reload.

4. **Hardware-key / OSD context loss — resolved better than initially feared.** PITFALLS.md was written without STACK.md's finding and framed this more cautiously; **trust STACK.md here**, which verified directly that volume/brightness/mic/media keys already fire via Hyprland `bind ... {locked=true}` calling `swayosd-client`. Deleting SwayOSD therefore only means swapping the exec target — no lock-screen regression. **Capslock is the one real gap**, since SwayOSD's root libinput daemon is the only thing catching it today; the sysfs LED node + `FileView.watchChanges` replacement closes it without a root service. The residual open question — whether to also retire `swayosd-libinput-backend.service` itself — remains a scope decision needing explicit sign-off, not a technical unknown.

5. **Incomplete retirement consumer-check.** The eww cleanup left two orphaned layerrules despite a grep that felt thorough; `ags/` went the other way and was never registered in `stow.sh`. Five surfaces × one missed reference class = five broken regressions. *Mitigation:* build a retirement checklist **script**, not a manual grep, covering windowrules, `autostart.lua`, keybinds, `contract.json`, matugen templates, `quickshell-doctor` registries, doctor fixtures, systemd `--user` units, D-Bus `.service` activation files, XDG autostart `.desktop` files, and `install.sh`/`stow.sh` package lists. Run it **twice per surface** — before and after deletion — in config-then-package order.

6. **Redesign forfeits unnamed daily-use features.** Scroll-to-change-workspace, right-click menus, specific dismiss and click-through behaviour — none are written down as specs. Redesigning against a reference language means they disappear silently. *Mitigation:* before redesigning each surface, enumerate its current behaviour from the live config, write it down, and make it UAT acceptance criteria — while the reference implementation still exists to be read.

7. **Quickshell 0.3.0-2 always-on traps.** `Variants`/QS-03 risks, exclusive zone across reload, hot-reload state loss, render-loop selection (this project already found Qt auto-selecting the basic loop, needing `QSG_RENDER_LOOP=threaded` to reach 165Hz). *Mitigation:* test an explicit matrix — cold start / hot reload / `hyprctl reload` / multi-hour soak. Reuse existing bug-fix patterns before writing new IPC code.

8. **Debt paydown silently dropped as migration runs long.** Five migrations plus eight debt items share one milestone. Migration has visible output; debt items are easy to defer, and v3.0's own closeout language explicitly names "whether v4.0 actually picks up the two real carry-ins" as the open test. *Mitigation:* deliberately interleave debt into migration phases at roadmap time rather than trailing it; and if the milestone runs long, **scope-cut migration stretch goals first, not debt.**

## Implications for Roadmap

### Suggested Phase Sequence (continues from v3.0's Phase 17)

**Phase 18 — Bar (waybar → QML status bar)**
- *First:* highest daily contact; its patterns seed every later surface
- *Delivers:* workspace click, scroll volume/brightness, notification-centre button, system tray, clock, battery, OLED auto-hide
- *Avoids:* pitfalls 3, 6, 7 (first soak gate; behaviour enumeration; render-loop and exclusive-zone stability)
- *Gates:* soak test (RSS / process-count stability); exclusive zone verified across reload; structural checks extended into `quickshell-doctor`
- *Retirement:* remove waybar + 7 contract entries + `[templates.waybar]` + `waybar-equivalence-check` + `waybar-design-lint`; re-home visibility ownership onto the bar's own IPC verb

**Phase 19 — Notifications (swaync → QML popups + slide-out centre)**
- *After the bar:* the centre-button pattern is proven; the D-Bus ownership decision must be resolved explicitly before planning
- *Delivers:* transient popups (swipe, actions), slide-out centre (history, clear-all), DND toggle, full D-Bus contract compliance
- *Avoids:* pitfalls 1, 2, 7 (two-owner race test; contract fault injection; hot-reload state loss)
- *Watch:* promote the quick-toggle grid to a shared component rather than hand-copying it
- *Retirement:* remove swaync + 2 contract entries + `[templates.swaync]`; move DND ownership into QML

**Phase 20 — OSD (SwayOSD → QML indicators)**
- *After Phase 19:* reuses the transient-toast frame type
- *Delivers:* volume/brightness OSD on the existing Quickshell signals; capslock via the zero-root sysfs watch
- *Key decision:* keep the libinput backend running standalone for its context reach, or accept and document the loss
- *Retirement:* remove swayosd + 1 contract entry + `[templates.swayosd]`; collapse volume/brightness onto one QML path

**Phase 21 — Power menu (wleave → QML session menu)**
- *Independently schedulable:* no shared backend; lowest risk, closest existing precedent; can overlap Phase 20
- *Delivers:* six actions, keyboard-navigable grid with visible focus, in-context safety warnings, modal keyboard grab
- *Retirement:* remove wleave + 1 contract entry + `[templates.wleave]`

**Phase 22 — Media fold-in (AGS → dashboard Media tab)**
- *Last:* allows an independent cava decision gate
- *Decision gate at phase start:* build a QML cava reader, or record explicit sign-off that a static ring is acceptable — no silent downgrade
- *Delivers:* final MPRIS consolidation onto one backend owner; Media-tab refresh
- *Retirement:* remove ags + 1 contract entry + `[templates.ags]`

**Phase 23 — D-34/D-36 fresh-install container rerun.** The closing regression gate for all five package deletions. Deliberately last, after every retirement lands — not threaded through individual phases.

### Parallel / interleaved debt

- **Bookkeeping (Phase 18 start, zero cost):** flip the `GradientBorder` debug-session status and update PROJECT.md/MILESTONES.md; close WINDOWS #14. Both are already fixed in code.
- **OVER-04 FPS (attach to Phase 18):** verify `QSG_RENDER_LOOP=threaded` and baseline the bar at 165Hz — the always-on surface is the natural place to finally measure the frame-rate term.
- **Debug curation + WINDOWS triage:** 6 open sessions, 16 open rows — size and prioritise early rather than at close.
- **Retirement checklist script (Phase 18):** build once, reuse for all five retirements.
- **Host-level leftovers:** uninstall the still-present `wlogout` and `eww` packages.

### Dependency summary

```
Phase 18 (Bar) ─────────────────┐
                                ├─→ Phase 19 (Notifications) ─→ Phase 20 (OSD)
Phase 21 (Power)  ── independent, can overlap Phase 20
Phase 22 (Media)  ── needs an explicit cava go/no-go at phase start
Debt bookkeeping + OVER-04 ───── Phase 18 start
D-34/D-36 container rerun ────── Phase 23, after all five retirements
```

## Research Flags

**Phases needing deeper research at planning time:**

- **Phase 19 (Notifications)** — the notification-server ownership decision gate must be settled before the spec phase (QML becomes the D-Bus owner vs. stays a swaync client). Both are technically feasible; both reference rices chose "shell owns the server."
- **Phase 22 (Media)** — cava-visualizer go/no-go needs an explicit spike before build starts.

**Phases with proven patterns (skip detailed research):**

- **Phase 18 (Bar)** — reuse the existing `Colours`/`Motion` singletons; single `PanelWindow` with `exclusiveZone`, no multi-screen fan-out (QS-03, D-13)
- **Phase 20 (OSD)** — volume/brightness already Hyprland-bind-routed; capslock has a zero-root sysfs replacement
- **Phase 21 (Power)** — reuse the `PanelDialog` frame; keyboard-navigation pattern already proven in the dashboard

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Every technology verified directly against installed binaries on this host. No new packages needed. `Quickshell.Services.Notifications` verified as a real D-Bus server by reading the installed `.qmltypes`. |
| Features | MEDIUM-HIGH | Table stakes from direct reads of reference-rice QML; two independent implementations converge (strong signal). Differentiators grounded in a diff against PROJECT.md's Validated list. Complexity estimates are researcher judgment, not measured. |
| Architecture | HIGH | Direct repo inspection (shell root, summon mechanism, `qmldir` discipline, `contract.json` state) with file paths and `git log` verification. Two carry-ins verified in code and independently re-checked by the orchestrator. Open questions named rather than papered over. |
| Pitfalls | MEDIUM-HIGH | Grounded in this repo's own committed evidence (`quickshell-doctor` fixtures, `autostart.lua` ordering, `windowrules.lua` namespaces, prior WINDOWS incidents). Freedesktop-spec contract details are general knowledge, not binary-verified, and are marked as such. |

**Overall: HIGH.** Blocking risks are explicitly named (notification-server ownership, cava go/no-go, bar crash isolation) rather than hidden.

### Where researchers disagreed

- **Hardware keys.** PITFALLS.md framed SwayOSD's retirement as potentially losing lock-screen/TTY coverage; STACK.md then verified directly that media keys already route through Hyprland binds with `locked=true`. **Trust STACK.md** — it inspected the actual bind definitions, and PITFALLS.md was written without that finding. The residual capslock gap is real in both accounts.
- **`GradientBorder` and WINDOWS #14.** PROJECT.md, MILESTONES.md and PITFALLS.md all treat these as open carry-ins; ARCHITECTURE.md found both already closed in code. **Trust ARCHITECTURE.md** — the orchestrator independently re-verified both against the working tree (`PanelDialog.qml:191`, commit `4f48847` dated 2026-08-02; `quickshell-doctor` on `hl.dsp.global`, with the only `dispatch global` string in a comment explaining why the old form is invalid). Caveat: the commit evidences clean mount/dismiss and no new log errors, **not** a human visual confirmation that the rim renders — that check is still owed, but it is a look, not a phase.

### Gaps to address

- **Notification-server go/no-go** — research confirms feasibility; the *decision* is not research's call. Resolve at Phase 19 roadmap time.
- **Cava visualizer** — a deliberate Phase 14 scope cut. Phase 22 opens with an explicit spike and go/no-go before design.
- **Current wleave keyboard nav** — not confirmable from planning docs alone; a quick source check before Phase 21 scoping will say whether it is already wired or a new requirement.
- **SwayOSD libinput backend fate** — reaches contexts Hyprland binds cannot; needs explicit human sign-off on whether it is retired alongside the renderer.
- **Bar crash isolation** — restart wrapper vs. documented accepted risk; resolve at Phase 18 roadmap time.
- **QML hot-reload state survival** — needs the explicit test matrix; document what actually happens rather than assuming either way.
- **`replaces_id` / `expire_timeout` merge semantics** — not spelled out in the fetched Quickshell docs; settle with a throwaway `notify-send -r` probe early in Phase 19.
- **Capslock sysfs node stability** — `input5::capslock` was not verified across an actual reboot or USB re-enumeration.

## Sources

- Direct host verification: `pacman -Q`/`-Qi`/`-Si`/`-Ql`; reading installed `.qmltypes` under `/usr/lib/qt6/qml/Quickshell/`; `busctl`; sysfs LED nodes — HIGH confidence
- Direct repo inspection at `/home/aorus/dotfiles`: shell root and `qmldir` manifests, `theme-engine/contract.json`, `matugen/.config/matugen/config.toml`, `hypr/.config/hypr/config/*.lua`, `install.sh`, `stow.sh`, `hypr/.config/hypr/scripts/quickshell-doctor`, `git log`/`git show` — HIGH confidence
- Reference-rice source reads: `github.com/end-4/dots-hyprland`, `github.com/caelestia-dots/shell` (actual QML files, linked in FEATURES.md) — HIGH confidence for what they ship
- Project planning record: `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/WINDOWS.md` — HIGH confidence
- Freedesktop notification-spec contract fields (`GetCapabilities`, `replaces_id`, `ActionInvoked`) — general knowledge, NOT binary-verified; flagged LOW and owed a probe in Phase 19

---
*Synthesized 2026-08-10 at v4.0 milestone start. Orchestrator note: the synthesizer returned this document inline rather than writing it (known issue #222); the orchestrator persisted it.*
