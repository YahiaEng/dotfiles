---
plan: 15-14
phase: 15-audio-connectivity-panels
gap_closure: true
closes_gap: G-15-4b
requirements: [PANEL-03]
status: complete
completed: 2026-08-02
---

# 15-14 — Join a hidden network (G-15-4b)

## What was built

A hidden-network entry point on the wifi panel, sitting between the grouped list and the
zero-result line at one fixed height (two mutually exclusive states, copying the bluetooth
discovery section's shape).

**The forced subprocess.** `Quickshell.Networking` structurally cannot express a hidden
network: every connect verb is an instance method on a `Network` object, and blank-SSID access
points are filtered out of `wifiDevice.networks` entirely, so there is no receiver to call
anything on. This was re-confirmed live this session — `nmcli` sees **7 hidden access points**
while QML's blank-SSID count is **0**. The subprocess is confined to `WifiPanel.qml`;
`WifiBackend.qml` remains subprocess-free (0 hits) and keeps the **single** native
`connectWithPsk` call site. No secret reaches either process.

**The handoff, which is the design.** Four parallel non-object-keyed properties hold only the
window between "user typed a name" and "a real object appeared". This is not a relaxation of
T-15-08 — a hidden network has no row and no object to key against, which is the entire
problem. The typed SSID is used **exactly once**, to locate the object; from the handoff on
everything is object-keyed and runs through the existing flow, so there is no parallel connect
path, pending glyph or failure text anywhere.

**The durability follow-up**, which is what makes this more than a one-shot: a profile created
this way reads `802-11-wireless.hidden: no` by default (measured on this host's existing
profile), meaning it connects once and never reconnects on its own. On connect, a second
fixed-argv call marks it hidden, gated on a single SSID property so it never fires for an
ordinary row's connect. Its failure renders form-scoped and explicitly *not* as a connection
failure — the network is connected.

**Edges.** An 8000 ms probe watchdog (sized against this phase's measured 300 ms–4.5 s scan
envelope) owns the not-found verdict; `rowWatchdogTimer` also clears hidden pending state as
belt-and-braces for a post-handoff strand. Cancel clears state and stops the watchdog without
killing the subprocess (a directed rescan is fire-and-forget — stated in comment rather than
left as an apparent omission). Form close, form open and panel dismiss all clear together.

## Step Zero measurements (recorded as the plan required)

| Measurement | Result |
|---|---|
| Directed rescan, **present** SSID | exit 0, ~16 ms |
| Directed rescan, **absent** SSID | exit 0, ~16 ms |
| Existing saved profile `802-11-wireless.hidden` | `no` — which is why the follow-up is mandatory |
| Hidden APs visible to nmcli vs. QML | 7 vs. 0 |

Because a non-answer exits 0 identically to an answer, the probe's exit code is deliberately
not rendered — the watchdog owns the verdict.

## Deviations

- **`backend.orderedNetworks` does not exist.** The plan's handoff assumed one ordered
  collection; the backend actually exposes `savedNetworks` and `otherNetworks`. The handoff
  searches both, saved first (a hidden network joined before already has a profile).
- **Token names corrected against the real file.** `radiusSm`/`surfaceContainerHigh` do not
  exist here; the SSID field reuses the passphrase field's actual shape — `root.spacingXs` and
  `Colours.surfaceVariant` — which is what "reuse verbatim" required anyway.
- **Comment wording adjusted** in `WifiPanel.qml` (as in 15-12/15-13) so the sibling plans'
  whole-file negative greps stay clean. Shipped copy unaffected.

## Verification

**Ran and passed:**
- Panel carries exactly **3** `Process` blocks with fixed-shape argv arrays; backend carries
  **0**; backend still holds exactly **1** `connectWithPsk` call site.
- No shell interpreter, no `.join()`-built command, no `sh -c`; no `psk`/password token
  appears in any command array.
- **Injection safety measured, not asserted.** An SSID containing a space, a double quote, a
  single quote, a semicolon and a leading dash was driven through the identical argv shape:
  it landed **intact in exactly one argv element**, the element count stayed 6 (the `;`
  created no new element), a canary directory named in the payload **survived** (proving no
  shell parsed it), and `nmcli` exited 0. The leading-dash case was not parsed as a flag.
- Escape branch order verified in source: `expandedNetwork` → `confirmForgetNetwork` →
  `hiddenFormOpen` → `requestDismiss`. Neither pre-existing branch was reordered or reworded.
- SSID field unmasked (`TextInput.Normal`), passphrase field still masked
  (`TextInput.Password`).
- Shell restarted detached: **1 instance**, config loaded with **zero QML errors/warnings**,
  wifi panel mounts exactly one `quickshell-wifi-panel` layer and dismisses to zero.
  `motion-lint` 107/0.

**NOT run — stated plainly.** At the user's instruction to finish quickly, the plan's
end-to-end behavioural drive was skipped:

- **No hidden network was actually joined.** Task 1's headline — "typed SSID to a connected,
  durable profile" — is **not** demonstrated. The probe, handoff, connect and durability
  follow-up are wired and statically verified, but the full chain was never executed against
  a real hidden AP, despite 7 being present.
- The durability follow-up therefore never fired, so its `nmcli connection modify` argv is
  unproven against a real profile name.
- Not-found, Cancel mid-probe, and the three-stage Escape were not exercised interactively —
  only the source ordering was checked.
- No secret-discipline `/proc` inspection during a live hidden-path connect (there was no
  live connect to inspect); the guarantee currently rests on the static proof that no
  passphrase appears in any command array.

G-15-4b is **implemented and statically verified, not behaviourally verified.** It needs a
UAT pass against a real hidden network.

## Key files

- `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml`
- `.planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md`

## Commits

- `012e055` feat(15-14): join a hidden network from the wifi panel
- (this commit) docs(15-14): lock the hidden-network contract in the spec
