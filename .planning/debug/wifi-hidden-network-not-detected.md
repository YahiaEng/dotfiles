# Debug session — hidden network not detected (G-15-6)

**Opened:** 2026-08-02, UAT round 2, test 6
**Symptom:** "It cannot detect my hidden network."
**Status:** ROOT CAUSE FOUND — measured against the user's own hidden AP, not inferred.

---

## The headline

**Route B is not the problem. Route B works.** 15-14 shipped it unproven and predicted
that failure here would mean the access point does not answer directed probes, making
Route A the fallback. That prediction is **wrong on this host**, and acting on it would
have rebuilt a working mechanism for no reason.

The real defect is a **race in the panel's own handoff** that guarantees this symptom for
*every* hidden network, including one that answers a directed probe perfectly.

---

## Measurements (live, against SSID `!ono^` — the user's own router)

### 1. The directed probe DOES reveal the AP

Before any probe, the AP is one of 7 blank-SSID entries. After
`nmcli device wifi rescan ssid '!ono^'`, NetworkManager's scan list carries it by name:

```
CC\:BA\:BD\:95\:84\:B2:!ono^          <- same BSSID, now named
CC\:BA\:BD\:95\:84\:B2:               <- the old blank entry still lingering
```

Note the BSSID appears **twice** — the reveal lands as an additional entry alongside the
blank one, it does not mutate it in place.

### 2. Quickshell DOES see the revealed AP as a real, named Network object

A standalone probe shell (`Networking.devices` filtered on `DeviceType.Wifi`, matching
`WifiBackend.qml:47-54`'s own accessor exactly):

```
NETPROBE total=14
NETPROBE ssid=[go-jo]
...
NETPROBE ssid=[!ono^]                 <- present, named, ordinary
NETPROBE blank_ssid_count=0
```

This kills the second hypothesis outright. 15-14's measurement that Quickshell filters
blank-SSID APs is correct, but irrelevant once the AP is revealed — a revealed AP is an
ordinary named `Network` object and `tryHiddenHandoff()`'s `nets[i].name === hiddenSsid`
comparison would match it.

### 3. The probe process exits in 16–30 ms

```
run 1: exit=0 elapsed_ms=30
run 2: exit=0 elapsed_ms=16
run 3: exit=0 elapsed_ms=16
```

Matching 15-14's own Step Zero table (~16 ms). This is the number that breaks the feature.

### 4. Reveal latency far exceeds the probe's exit, and exceeds the watchdog

A single probe followed by 12 s of polling showed **nothing**. The AP appeared only after
repeated probes. Once revealed, the entry is **sticky** — still present 150 s later with no
further probes issued. So reveal latency is real and long; it is not a cache-eviction
artefact.

---

## Root cause

`tryHiddenHandoff()` has **exactly one caller** in the whole file:

```
WifiPanel.qml:262   function tryHiddenHandoff() { ... }
WifiPanel.qml:309       root.tryHiddenHandoff();     <- inside hiddenRescanProcess.onExited
```

`onExited` fires 16–30 ms after the probe starts. At that instant the scan has not
completed and the network list is unchanged, so the search loop finds nothing and returns.
**It is never called again.** There is no `Connections` block re-invoking it on a list
change — WifiPanel's two `Connections` blocks target `onPanelOpenChanged` (:209) and
`onConnectFailed` (:454).

The 8000 ms `hiddenProbeTimer` then fires and renders
`"No network answered to that name"` — the not-found verdict it was designed to own.

The comment at :305-308 states the design intent correctly ("a non-answer is not an error,
so the exit code is not rendered; the probe watchdog owns the not-found verdict") but the
code only ever *searches* at exit time. The watchdog owns the verdict; nothing owns the
retry.

**This is deterministic.** No hidden network can ever be found through this path, on any
host, regardless of how well it answers.

---

## What must change

1. **Retry the handoff when the network list actually changes.** The observable already
   exists and is already used: `WifiBackend.qml:244` has a `Connections` block targeting
   `wifiDevice.networks`, which is exactly the "results landed" signal 15-11 used to clear
   its rescan edge. The handoff needs the same trigger, gated on `hiddenProbing`.

2. **Re-probe while waiting, don't probe once.** A single directed probe did not reveal the
   AP within 12 s in one run; repeated probes did. A periodic re-probe during the in-flight
   window (the probe is fire-and-forget, carries no secret, and costs ~16 ms) is what makes
   the reveal reliable rather than lucky.

3. **Raise the watchdog above the measured reveal latency.** 8000 ms is demonstrably shorter
   than the observed reveal time. `hiddenProbeMs` is a logic timeout (`interval:`, never a
   motion `duration:` — the existing comment is right about that and must stay right).

4. **Do NOT switch to Route A.** It is unnecessary here and strictly worse: it duplicates
   the connect verb, puts the passphrase on `argv` unless mitigated with
   `Process.stdinEnabled` + `nmcli --ask`, and needs a whole new error mapping because nmcli
   returns exit codes and stderr instead of the `ConnectionFailReason` enum the row-scoped
   copy is wired to. Keep it documented as the fallback it already is.

5. **Consider the lingering duplicate BSSID.** The reveal adds an entry rather than mutating
   the blank one. Worth confirming the panel's list does not show a stale duplicate row after
   a successful hidden join.

---

## Artifacts

| Path | Issue |
|---|---|
| `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` | :309 — `tryHiddenHandoff()` called only from `hiddenRescanProcess.onExited`, 16–30 ms after the probe starts, and never retried. The defect. |
| `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` | :189-203 — `hiddenProbeTimer` at 8000 ms is shorter than the measured reveal latency, so it would fire early even with the retry fixed. |
| `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` | :240-250 — `startHiddenProbe()` fires exactly one probe; a single probe was measured insufficient. |
| `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml` | :244 — the existing `Connections` block on `wifiDevice.networks` is the house precedent for the missing retry trigger; it is not a defect, it is the reuse. |

## Eliminated

- **"The AP does not answer directed probes"** — FALSE. Measured: it answers and NM surfaces
  the name. This was 15-14's predicted failure branch and the reason Route A was pre-specified;
  the prediction does not hold here.
- **"Quickshell filters the revealed AP as blank-SSID"** — FALSE. Measured:
  `NETPROBE ssid=[!ono^]`, `blank_ssid_count=0`. A revealed AP is an ordinary named object.
- **"The SSID's punctuation (`!`, `^`) breaks the argv/comparison path"** — no evidence. The
  command is built as a fixed-argv array (`WifiPanel.qml:248`) so no shell parses it, and the
  name round-tripped through nmcli and QML intact in both probes.

## Residual unknown

Exact cold-cache reveal latency for a *single* probe was not pinned down: the revealed entry
stayed in NM's scan cache for 150 s+ without aging out, so the cold-start condition could not
be re-created during this session. The fix should therefore be robust to a long and variable
reveal (retry on list change + periodic re-probe) rather than tuned to a specific number.
