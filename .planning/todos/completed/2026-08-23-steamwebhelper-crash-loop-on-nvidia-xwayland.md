---
created: 2026-08-23T01:20:00.000Z
updated: 2026-08-25T17:35:00.000Z
title: steamwebhelper crash loop — bad IPC reason 213 (INVALID_INITIATOR_ORIGIN)
area: general
severity: minor
files:
  - ~/.local/share/Steam/logs/cef_log.txt (evidence)
  - ~/.local/share/Steam/logs/webhelper.txt
---

## Problem

Steam's `steamwebhelper` (CEF/Chromium 126.0.6478.183) has its renderer killed with
`bad_message.cc(29) Terminating renderer for bad IPC message, reason 213`. Steam
respawns the browser process and the client window reappears showing a blank page.

**ROOT CAUSE NAMED 2026-08-25 (HIGH confidence, primary sources):**

**Reason 213 is `INVALID_INITIATOR_ORIGIN`.** Verified by reading Chromium's own
`content/browser/bad_message.h` at tag `126.0.6478.126` — the exact branch this
build (`126.0.6478.183`) comes from — and counting the append-only `BadMessageReason`
enum: index 212 is `RFPH_POST_MESSAGE_INVALID_SOURCE_ORIGIN`, **213 is
`INVALID_INITIATOR_ORIGIN`**, 214 is `RFHI_BEGIN_NAVIGATION_MISSING_INITIATOR_ORIGIN`.
Corroborated independently by CEF 126.2's own `CefFrame::LoadRequest` documentation,
which states verbatim:

> "This method will fail with 'bad IPC message' reason INVALID_INITIATOR_ORIGIN (213)
> unless you first navigate to the request origin using some other mechanism (LoadURL,
> link click, etc)."

**THIS IS A NAVIGATION-SECURITY CHECK, NOT A GRAPHICS FAULT.** It has no GPU, driver,
NVIDIA, XWayland or compositor component whatsoever. Two consequences:

- **It explains why `-cef-disable-gpu` did nothing** — that is a graphics flag aimed
  at a non-graphics fault. Likewise `htmlcache`: wiping a cache does not change who
  initiates a navigation. Neither remedy ever addressed this failure; their failure
  was not evidence of a deep problem, it was a category error.
- **The old title's "on NVIDIA + XWayland" framing is not supported.** The 38 ×
  `atom_cache` `STEAM_GAME` lines prove only that the webhelper runs *under* XWayland.
  They are not causally connected to 213. **"Test a different NVIDIA driver branch"
  is struck from the untried list as a measured dead end — do not spend effort there.**

**TIMING RE-MEASURED 2026-08-25 — THE ORIGINAL CHARACTERISATION WAS WRONG.**
Whole-log, all 12 kills, zero exceptions:

- **Every single kill fires 3-5 seconds after a `Crash reporting enabled for process:
  browser` line** (min 3s, max 5s, 12/12), always immediately after the two
  `atom_cache` lines. **The fault is bound to webhelper STARTUP, not to elapsed time.**
- The "minutes to hours, irregular" period the original entry recorded (gaps between
  kills: 17s, 155s, 1145s, 29s, 10s, 17s, 21s, 10s, 1080s, 5521s, 7929s) is measuring
  **the wrong interval** — it is just when the user next caused a webhelper start.
- **Not every start dies: 40 browser starts produced 12 kills.** So it is startup-bound
  but *not* unconditional — do not overclaim it as deterministic.

**THEREFORE THE OLD "JUDGE ANY FIX OVER HOURS" INSTRUCTION IS RETIRED.** It was written
to defend against the false "fixed" claim, and that caution was right — but the correct
protocol is not a longer clock, it is **restart-count**: start the webhelper N times
and count kills within 5s of each start. That takes minutes, not hours, and it is a far
stronger test than any quiet window.

**Counts:** whole-log `bad IPC message` = 12, `Tab Killed` = 12, browser starts = 40.
(The original entry's "22" was the two patterns summed at that time — 11+11; now 12+12.
Consistent append-only growth, not a discrepancy.) **Every reason code in the log is
213** — one failure mode, no mix.

**Still true from the original investigation:** this is Steam-side and reproduces with
`steam` launched bare from a terminal, no quickshell, no `uwsm`, no launcher. Ruled out:
cgroup death, MIME associations, XDG autostart, anything in this repo.

**REOPENED — the `data:` URL was dismissed for the wrong reason.** The original entry
called `data:text/html,%3Cbody%3E%3C%2Fbody%3E` "a red herring" because nothing was
*invoking* it. That ruled out the wrong role. `INVALID_INITIATOR_ORIGIN` is about the
origin a navigation is *initiated from*, and **a `data:` URL has an opaque origin** —
which is exactly the kind of initiator this check rejects. `webhelper.txt` shows Steam's
own client window is internally named `SteamBrowser-'data:text/'`. So the same string
may matter as the **origin context**, not as the invoker. **This is a hypothesis
consistent with the evidence, NOT a measurement — it has not been confirmed.**

**Separate, do not conflate:** Steam also cannot be closed from its own window, because
this desktop has no system tray to minimise into — see
[[add-system-tray-capsule-to-the-quickshell-bar]]. That is our gap and independently
fixable. This one is not.

## Solution

**Not fixable from this repo.** The failing call is Steam's own application code
navigating with an invalid/opaque initiator origin. Nothing in these dotfiles
participates in it.

**Do not repeat — tried and failed, and now explained:**

1. Clearing `~/.local/share/Steam/config/htmlcache` — wrong layer.
2. Launching with `-cef-disable-gpu` — wrong subsystem entirely.

**`--disable-site-isolation-trials` is the documented CEF workaround and is NOT
RECOMMENDED HERE.** It would suppress the symptom by disabling site isolation in the
very process that renders the Steam store and holds a logged-in session. That is a real
security downgrade traded against a `minor`, cosmetic annoyance that already has a clean
workaround. CEF's own forum also notes the flag may be removed. If it is ever tried, it
must be a deliberate, recorded decision — not a quiet fix.

**Upstream status (checked 2026-08-25):** no ValveSoftware/steam-for-linux issue names
reason 213 or `INVALID_INITIATOR_ORIGIN`. The closest symptom match is
[#11610](https://github.com/ValveSoftware/steam-for-linux/issues/11610) ("steamwebhelper
keeps dying and restarting randomly", client steals focus from the game) but it reports
different evidence — `Invalid browser dimensions: 0 x 0` — and is open with no Valve
reply and no confirmed workaround. **Filing a fresh upstream report naming reason 213,
the 3-5s-after-start timing and the Chromium enum would be genuinely new information
and is the highest-value remaining action.**

**Remaining untried angles, re-ordered by value after this research:**

- File upstream with the reason-213 identification (above). Highest value, low cost.
- Determine which frame/surface initiates the bad navigation — needs CEF verbose
  logging (`--enable-logging --v=1`) on the webhelper to see the frame and URL before
  the kill; would confirm or kill the `data:`-origin hypothesis.
- Check whether it correlates with a specific Steam UI surface (store/library/friends)
  reached during those first seconds.

**Workaround meanwhile (unchanged, works):** `steam -shutdown` reliably quits Steam.
If wedged, `systemctl --user stop app-Hyprland-steam-*.scope` kills the whole cgroup.

Severity stays `minor`: Steam remains usable, games launch, and the workaround holds.

## Sources

- Chromium `content/browser/bad_message.h` @ tag `126.0.6478.126` — enum index 213 read
  directly (HIGH confidence, primary source, matching branch)
- CEF 126.2 `CefFrame` API docs, `LoadRequest` — INVALID_INITIATOR_ORIGIN (213) quoted
  verbatim (HIGH confidence, primary source, matching version)
- CEF Forum thread 17176 — same identification, plus the `--disable-site-isolation-trials`
  workaround and its caveat
- Local whole-log measurement of `~/.local/share/Steam/logs/cef_log.txt` 2026-08-25
  (HIGH confidence, direct, all 12 events, log unwritten since 2026-08-23 06:30)

## Closed 2026-08-25 — NOT OURS (operator decision)

Operator closed this as **INTENDED**: reason 213 is Chromium's own
`INVALID_INITIATOR_ORIGIN`, read directly out of
`content/browser/bad_message.h` at the matching tag, so the fault is inside
Steam's CEF build and not in anything this repo configures, themes or launches.
No dotfiles change would fix it and none should be attempted.

Kept for the record rather than deleted, because the identification cost real
primary-source work and the next person to see a blank Steam window should not
have to redo it. The workaround still stands: `steam -shutdown` quits cleanly,
and `systemctl --user stop app-Hyprland-steam-*.scope` kills a wedged cgroup.

Filing it upstream stays available to the operator; it is not repo work.
