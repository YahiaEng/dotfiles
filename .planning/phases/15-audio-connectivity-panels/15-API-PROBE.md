# Phase 15 Plan 01 — API Probe Report

Live measurement against the running build (quickshell 0.3.0-2, Hyprland 0.56.1, this host) plus a source read of the two reference shells. Every command and harness cited below actually ran during this session; no answer here is inferred from a type signature alone. A question the probe could not settle reads `unresolved` with the reason — none of the eight did.

All probe harnesses lived under `/tmp/gsd-probe-Sws01q/` (a `mktemp -d` scratch directory), deleted at the end of the executing session. No file under `quickshell/`, `hypr/`, `waybar/`, `matugen/`, `gtk/` or `install.sh` was touched; `quickshell/.config/quickshell/modules/Probe.qml` is byte-identical to its pre-plan state (`git diff HEAD -- quickshell/.config/quickshell/modules/Probe.qml` empty throughout).

## A3 — UntypedObjectModel accessor shape

**Verdict:** measured
**Evidence:** `harness_a3.qml` and `harness_a3b.qml` run via `qs -p` against the live `Pipewire`, `Networking` and `Bluetooth` singletons, plus a direct `Repeater { model: Pipewire.nodes }` instantiation test.

`UntypedObjectModel` (backing `Pipewire.nodes`, `Networking.devices`, `Bluetooth.devices`/`adapters`) has **no `count` property and no `get(index)` method** — both `'count' in model` and `'get' in model` evaluate `false` on all three live singletons, confirming the type file's declared shape and contradicting 15-RESEARCH.md Pattern 2's example code and 15-PATTERNS.md's backend snippet, which both reach for `.count`/`.get(i)`.

The model's readonly `values` property is the correct accessor. `typeof model.values` is `"object"`; `Array.isArray(model.values)` is **`false`** (it is not a real JS Array), but it fully supports `.length`, numeric index access (`vals[i]`), a plain `for` loop, and standard `Array.prototype` methods (`.map`, `.filter` both proven live — `vals.map(n => n.id)` and `vals.filter(n => n.isSink)` both returned correct results against 11 live PipeWire nodes, 4 of them sinks).

`Object.keys(model)` on all three singletons returns the full `QAbstractListModel` surface (`rowCount`, `data`, `insertRows`, …) plus `values`/`valuesChanged`/`indexOf` — confirming the `QAbstractListModel` prototype declared in the type file is real and live, not merely declared.

A `Repeater { model: Pipewire.nodes }` bound **directly to the `UntypedObjectModel` object itself (not `.values`)** instantiates exactly one delegate per object — proven live: 11 delegates instantiated for 11 real PipeWire nodes, each exposing the real node object as `modelData` (`modelData.id`, `modelData.isSink` both read correctly per delegate).

**Reactivity, proven two ways:**
1. A property bound to `Pipewire.nodes.values.length` at `Item` construction re-evaluated live 11 times over ~3 seconds as PipeWire's registry populated asynchronously after process start (0 → 1 → 2 → … → 11), each transition firing the property's change handler.
2. `Bluetooth.defaultAdapter` (same singleton-property mechanism) transitioned live from `null` → a real adapter object → `enabled: false, state: Blocked` while `rfkill` reported the adapter soft-blocked, then to `enabled: true, state: Enabled` within 3s of `rfkill unblock bluetooth`, confirming the reactive mechanism is not `Pipewire`-specific.

**Corrective finding on `PwNodeType` flags (load-bearing for A1 and any backend filter):** the `Flag` enum's named "convenience" members (`AudioSink`, `AudioSource`, `AudioOutStream`, `AudioInStream`, …) are **pre-combined composite values**, not independent bits — e.g. `AudioOutStream = Audio(1)|Stream(4)|Sink(16) = 21`, `AudioInStream = Audio(1)|Stream(4)|Source(8) = 13`. Because `AudioOutStream` and `AudioInStream` share the `Audio` and `Stream` bits, a bitwise-AND membership test (`node.type & PwNodeType.AudioInStream`) produces a **false positive** on an `AudioOutStream` node (measured live: `21 & 13 = 5`, truthy). The correct test is **exact equality** (`node.type === PwNodeType.AudioOutStream`), which was verified correct against both live playback-stream nodes measured for A1 (raw type `21`, exactly `AudioOutStream`).

**Accessor expression for a backend adapter (the one unambiguous sentence this section owes):** iterate any `UntypedObjectModel` (`Pipewire.nodes`, `Networking.devices`, `Bluetooth.devices`/`.adapters`) via its `.values` property using index access or `Array.prototype` methods for JS-side filtering/mapping, and bind `Repeater`/`Instantiator` `model:` directly to the `UntypedObjectModel` object (not `.values`) for one-delegate-per-object UI lists; for reactivity, bind on `<Model>.values.length` (or `.values` itself) — both re-evaluate live as the underlying registry changes, no `Connections`/manual refresh needed.

## A6 — PwObjectTracker requirement

**Verdict:** measured
**Evidence:** `harness_a6_notracker.qml` and `harness_a6_tracker.qml`, both run via `qs -p` against the same two live nodes (a real `pw-play` stream, node id 93; the live default sink, node id 54).

**Without any `PwObjectTracker` in the scene**, both nodes read: `ready: false`, `audio !== null` (the `PwNodeAudioIface` wrapper object exists) but `audio.volume: 0` and `audio.muted: false` for both — stub/default values, not the real live volume — and `Object.keys(node.properties).length: 0` for both (properties dictionary entirely empty).

**With a `PwObjectTracker { objects: [streamNode, sinkNode] }` mounted and given ~1.5s to settle**, the same two nodes read: `ready: true` for both; `audio.volume: 1` (stream, unmuted, matches `pw-play`'s stream-level gain) and `audio.volume: 0.5799...` (sink, matches the real live system volume); `properties` populated with **28 real keys** on the stream node and **53 real keys** on the sink node (verbatim key lists in the A1 section below).

**Tracker is required, unambiguously.** A node's `ready`, `audio.volume`/`audio.muted` and `properties` are all inert placeholders until that node is inside a `PwObjectTracker.objects` list — this confirms 15-RESEARCH.md's undocumented gap exactly as the planning-time read predicted. For `AudioBackend`: mount **one `PwObjectTracker` whose `objects` binds to the live, filtered node set the UI actually needs** (e.g. `Pipewire.nodes.values.filter(n => n.isStream || n.id === Pipewire.defaultAudioSink.id || n.id === Pipewire.defaultAudioSource.id)`) — a static list will not track streams that start/stop after mount, so the `objects` binding must itself be reactive on `Pipewire.nodes.values` (proven possible per A3's reactivity findings) so newly-appeared streams are tracked and departed ones are dropped automatically as `PwObjectTracker.objects` is itself a plain read/write property, not an append-only list.

## A1 — PipeWire node property keys

**Verdict:** measured
**Evidence:** `harness_a1.qml`, tracked via `PwObjectTracker`, dumping `JSON.stringify(node.properties)` for two real `AudioOutStream` nodes (a `pw-play` CLI stream and a live Zen browser tab stream), the live default sink, and a live input source. Cross-checked against `pw-dump` output for the same node ids — property sets match exactly, no Quickshell-side filtering artifact.

**Verbatim key list, real playing stream (`pw-play`, node id 93, type `AudioOutStream`, confirmed via `node.type === PwNodeType.AudioOutStream`):**
`adapt.follower.spa-node, application.name, client.id, clock.quantum-limit, factory.id, library.name, media.category, media.class, media.filename, media.format, media.name, media.role, media.software, media.type, node.async, node.autoconnect, node.driver-id, node.latency, node.loop.class, node.loop.name, node.name, node.rate, node.want-driver, object.id, object.register, object.serial, port.group, stream.is-live` (28 keys)

A second real `AudioOutStream` node (Zen browser, id 87, also confirmed `type === AudioOutStream`) carries the same shape plus GUI-app-only keys: `application.language, application.process.binary, application.process.host, application.process.id, application.process.machine-id, application.process.session-id, application.process.user, client.api, pulse.attr.*, pulse.corked, pulse.server.type, window.x11.display` (33 keys total) — confirming the key set is **not fixed per stream type**; a CLI producer (`pw-play`) and a GUI producer (Zen) both satisfy `AudioOutStream` but expose materially different property sets.

**(a) Display-name fallback chain, ordered, each link's observed non-empty candidates stated:**
1. `node.properties["application.name"]` — non-empty on **both** observed stream nodes (`"pw-play"`, `"Zen"`). Primary candidate.
2. `node.properties["application.process.binary"]` — present and non-empty on the GUI stream (`"zen-bin"`), **absent** (`undefined`) on the CLI stream. Fallback for when `application.name` itself is missing (not observed on these two, but a real gap the chain must cover — CLI tools frequently omit `application.name`).
3. `node.name` (top-level PwNode property, not inside `properties`) — always present on every observed node (`"pw-play"`, `"Zen"`, plus sink/source node names), never empty. Terminal fallback.
4. `node.nickname` / `node.description` — **empty string on both stream nodes** (not `undefined`, but `""`), the opposite of the plan's assumption; these ARE populated on sink/source nodes (`node.nickname: "ALCS1200A Analog"`, `node.description: "Starship/Matisse HD Audio Controller Analog Stereo"` for the sink; `"PRO X"` / `"Logitech G PRO X Gaming Headset Mono"` for the source) — **so `nickname`/`description` are a device-node fallback, not a stream-node fallback**, a corrective distinction downstream plans must respect.

**(b) Icon fallback chain:** `node.properties["application.icon-name"]` was **`undefined` on every node observed** (both stream nodes, the sink, the source) — no observed key ever supplied a real icon name. The icon chain therefore has **no live candidate at all** on this measurement; a generic Material Symbol (e.g. `volume_up` for a stream, `speaker`/`mic` for sink/source) must be the icon for every row unconditionally, not a fallback-of-last-resort.

**(c) Distinguishing two concurrent streams from the same app:** no properties key does this — `client.id` is shared per-process (both streams from the same app share the same `client.id`), and `application.name`/`media.name` are app-chosen strings with no per-stream uniqueness guarantee. **The node's own top-level `id` property (e.g. `93`, `87`) is the only guaranteed-unique per-stream identity** and is what 15-04's per-row row-identity truth must key on — recorded per the plan's own naming: the node id property name is `id` (`PwNodeIface.id`, a `uint`, `isReadonly: true`, `isPropertyConstant: true`).

## A4 — Call path: invokable methods vs request signals

**Verdict:** measured
**Evidence:** `harness_a4.qml`, a full live connect/forget cycle against a real, unsaved, WPA2-secured neighboring AP (`WE_1D03C9`, security `Wpa2Psk`; the plan's originally-recorded target `TONLY_TAP_9943D1C` had scrolled out of range by execution time — normal AP-visibility churn, not an environment defect, see Corrections), cross-checked at every step against `nmcli -t -f NAME,TYPE connection show`.

**Pre-state:** `nmcli connection show` listed only `Fiber:802-3-ethernet` and `lo:loopback` — zero wireless profiles, matching the plan's recorded pre-count.

**Plain `connect()` (no PSK) reached NetworkManager, unambiguously:** immediately after calling `targetNetwork.connect()`, `nmcli connection show` gained a new profile — `WE_1D03C9:802-11-wireless` — and the network's own `state` property read `1` (`ConnectionState.Connecting`) with `stateChanging: true`, `known: true`. **NetworkManager creates and persists a connection profile even with no PSK supplied**, live-confirming D-15-17's premise (the profile appearing is itself the proof 15-05's `forget` reasoning needs). No `connectionFailed` signal fired within the ~10s observation window — the connection stayed in `Connecting`/`stateChanging` the whole time, consistent with NM still negotiating (or waiting to time out on) missing secrets rather than failing fast.

**Emitting the bare `requestConnect` signal afterward produced no additional observable effect** — `state`, `stateChanging`, `known` were all unchanged from the post-`connect()` reading, and `nmcli connection show` was unchanged. With nothing subscribed to `requestConnect`, it is inert — it does not itself call NetworkManager. This settles the call-path question: **the plain invokable method (`connect()`/`forget()`) is the real actor; the `request*` signals are a request/intent channel meant for an external controller to listen to and translate into the plain-method call — they carry no default wiring of their own.**

**Plain `forget()` also reached NetworkManager and removed the profile:** calling `targetNetwork.forget()` after the connect attempt caused `WE_1D03C9` to disappear from `nmcli connection show` within the observation window, restoring the wireless-profile count to the pre-state's zero. `requestForget` was not exercised on this same object — after `forget()` succeeded, the harness's held reference to the (now-forgotten, ephemeral, never-fully-connected) network object was invalidated by the underlying model (a subsequent `.requestForget()` call threw `TypeError: Cannot call method 'requestForget' of null`, i.e. the QML wrapper object itself became `null`). **Corrective finding, load-bearing for Open Q1 and 15-05:** a `WifiNetwork` object returned from a device's `networks` model is **not guaranteed to stay alive** across a `forget()` on an unsaved/ephemeral profile — code holding a reference across such a call must re-resolve the network from the model rather than assume object identity survives.

**One-sentence conclusion:** call the plain invokable method (`connect()`, `disconnect()`, `forget()`, `connectWithPsk()`) to actually act on NetworkManager — the `request*` signals require an application-level listener to have any effect and are not a substitute action path.

## A2 — Default-sink write semantics

**Verdict:** unresolved
**Evidence:** not yet performed — owned by Task 2 of this plan, not yet executed at the time this section was written (Task 1 only). This placeholder will be replaced by Task 2's real measurement.

## Open Q1 — scannerEnabled cadence

**Verdict:** unresolved
**Evidence:** not yet performed — owned by Task 2 of this plan. Placeholder for the same reason as A2 above.

## A5 — Reference-shell source study

**Verdict:** unresolved
**Evidence:** not yet performed — owned by Task 4 of this plan, not yet executed at the time this section was written (Tasks 1 and 2 only). This placeholder will be replaced by Task 4's real measurement before the plan closes; it is written now, in canonical position, so the section-count gates for Tasks 1 and 2 do not falsely imply completion.

## Open Q2 — QtQuick Popup inside a layer-shell surface (record only)

**Verdict:** unresolved
**Evidence:** not yet performed — owned by Task 4 of this plan. Placeholder for the same reason as A5 above.

## Live mutations and restoration ledger

Every live mutation this task performed, arm-before-mutate, each re-checked true at the time this section was written. Task 2 will extend this ledger with the audio-default mutations it performs.

- RESTORED bluetooth-rfkill-soft: yes -> yes (toggled via `rfkill unblock bluetooth` to exercise the A3/A5 adapter-enabled reading, then `rfkill block bluetooth` restored it; re-checked live: `rfkill list bluetooth` reports `Soft blocked: yes`, matching pre-state)
- RESTORED wifi-scanner-enabled: false -> false (the A4 harness process that set `scannerEnabled = true` terminated — via its own `timeout` bound — before its final cleanup step ran, due to a harness bug reaching a `TypeError` on an invalidated network object per A4's finding; `scannerEnabled` is a per-process client-side scan request, not persisted NetworkManager state, and the owning process no longer exists. Re-checked live: `wlan0` state is `disconnected`, no active scan)
- RESTORED nm-wireless-profile-count: 0 -> 0 (the one wireless profile the A4 test created, `WE_1D03C9`, was removed by the plain `forget()` call within the same harness run; re-checked live: `nmcli -t -f TYPE connection show | grep -cx 802-11-wireless` returns `0`)

All probe-only network mutations from this task are fully reversed and re-verified above.

## Corrections to 15-RESEARCH.md / 15-PATTERNS.md

- **Pattern 2's accessor snippet — CONTRADICTED.** The `.count`/`.get(i)` shape it assumes does not exist on any `UntypedObjectModel` (`Pipewire.nodes`, `Networking.devices`, `Bluetooth.devices`). The measured shape is `.values` (array-like: `.length`, index access, `.map`/`.filter`, but `Array.isArray()` is `false`) for JS-side iteration, and `Repeater { model: <the UntypedObjectModel itself> }` (not `.values`) for one-delegate-per-object UI lists. See A3 above for the full measurement.
- **Pitfall 4 and Pitfall 5 — see A3 and A6 above respectively** (their content is the accessor shape and the tracker requirement measured in this plan; both are CONFIRMED as real gaps RESEARCH.md correctly flagged as unverified, now measured and settled).
- **`PwNodeType` Flag semantics — a genuinely NEW correction, not previously flagged as a risk by RESEARCH.md or PATTERNS.md.** The convenience flag members (`AudioOutStream`, `AudioInStream`, etc.) are pre-combined composites sharing bits with each other; a bitwise-AND membership test against them produces false positives. Any node-type filtering logic in a backend adapter must use exact equality against the composite constant, not bitwise AND. See A3 above.
- **Pitfall 3 (default-sink write semantics)** — not yet assessed; owned by Task 2, which performs the A2 measurement this correction depends on.

### Environment divergences from the "Environment facts measured on this host during planning" table

- **Visible APs churned relative to the planning-time snapshot**, as expected of a real neighborhood: the planning-time target `TONLY_TAP_9943D1C` was not present in this session's first scan (a fallback target, `WE_1D03C9`, was used for A4 instead — itself absent from the original planning-time list, appearing only during this session). This is ordinary AP-visibility churn, not an environment defect — the measurement re-resolved its target from the live scan rather than assuming a fixed SSID would still be present.
- All other planning-time environment facts (quickshell version `0.3.0-2`, 3 real output sinks, 2 real input sources, `wlan0` present, zero saved wifi profiles, bluetooth adapter `hci0` soft-blocked, full tooling roster present) were re-confirmed live at the start of this session and matched exactly — no other divergence found.
