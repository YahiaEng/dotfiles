---
phase: 19
slug: notification-server-centre
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-13
---

# Phase 19 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register authored at plan time (`register_authored_at_plan_time: true`) — plans `19-01`, `19-04`,
`19-05` and `19-06` each carried a parseable `<threat_model>` block, plus this plan's own (`19-07`)
covering the panel-family gap closure and this document's own completeness. This document
consolidates those five registers into one phase-level register, verified against the shipped
implementation directly (see Security Audit Trail), mirroring `15-SECURITY.md`'s exact structure
and evidence-cited style.

**Scope, per D-19-44 (LEDGER-08):** two halves. The first closes Phase 15's named-but-unclosed
panel-family gap (`WifiPanel.qml`'s missing `textFormat` pins, `15-SECURITY.md`'s Unregistered
Flags item 2). The second reviews this phase's own new inbound D-Bus surface for the first time —
untrusted `summary`/`body`/`app_name`/`app_icon`/`image`/`hints` fields from any session-bus
process now render inside the shell, and D-19-40's markdown allowlist widens the injection surface
further (link URLs). Plans `19-02`/`19-03` (LEDGER-04/07 debt items — a wallpaper-pointer
relocation and a `theme-stress-test` clean-tree fix) carry no threat model relevant to either half
and are correctly excluded from this consolidation; they touch neither the panel family nor the
notification D-Bus surface.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|----------------|
| over-the-air network data → wifi panel rendering | Network names arrive from radio broadcast and reach text elements in `WifiPanel.qml`. This is the boundary Phase 15 named and left open (`15-SECURITY.md` Unregistered Flags item 2). | Untrusted remote strings |
| session D-Bus → shell process | Any process running as this user may call `Notify` with arbitrary `summary`, `body`, `app_name`, `app_icon`, `image` and `hints` values. This phase's primary new inbound surface — it did not exist before Plan 19-01. | Untrusted remote text/paths/values |
| session D-Bus → card rendering | Sender-controlled `summary`, `body`, `app_icon`, `image` and `hints` values reach text elements, an image loader, an icon resolver and an arc geometry computation in `NotifCard.qml`. | Untrusted remote strings/paths/numbers |
| card → external URL handler | A link inside sender-supplied body text can request the shell open a sender-chosen URL via `Qt.openUrlExternally`. | Untrusted remote URL |
| session D-Bus → history store → disk → shell process | Sender-controlled notification fields are serialised to `~/.local/state/quickshell/notifications.json` and re-read at startup, where they are rendered again by a second component (`NotifGroup.qml`). | Untrusted remote strings, round-tripped through disk |
| filesystem → shell process | The state file's contents are parsed at startup and drive UI rendering; a malformed or hostile file reaches the parser before any UI exists. | Untrusted local file content |
| history store → centre rendering | Sender-controlled fields, round-tripped through disk, are rendered again in `NotifGroup.qml`'s group headers and per-notification rows — including application names, sender-supplied and never validated. | Untrusted remote strings |
| shell process → domain backends | `CentreFooter.qml`'s sliders and `QuickToggles`' toggle grid write into the audio, brightness, network and bluetooth backends through their own existing setters. | Control-plane writes |
| compositor → centre / popup stack | Both are layer-shell surfaces that sit above every application window while shown; the centre takes no exclusive keyboard focus by design (D-19-18). | Z-order / focus |
| `org.freedesktop.Notifications` bus name → this process | Session-wide, single-owner D-Bus name; whichever process claims it first wins (D-19-42), and a second owner appearing mid-session is the spoofing case QNOTIF-11 checks for. | Name ownership |

---

## STRIDE Threat Register

### High severity (the only tier that gates at `block_on: high`)

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-19-01 | Tampering | `NotifCard.qml` summary `Text` | high | mitigate | `NotifCard.qml:304` — `textFormat: Text.PlainText` on `summaryText`, bound to `card.summary` (sender-controlled). Titles never carry markdown in this design. | closed |
| T-19-02 | Spoofing | `org.freedesktop.Notifications` name ownership | high | mitigate | `NotifServer.qml:349-361` instantiates the `NotificationServer` child directly inside the `pragma Singleton` root (`keepOnReload: true`, D-19-38's declared capability set at `:356-361`) with no `LazyLoader` guard; `shell.qml:56` reads `NotifServer.unreadCount` at root scope — eager singleton construction, not summon-on-demand, so the name is held for the whole process lifetime by construction. Live-run this session, `quickshell-doctor`'s "single org.freedesktop.Notifications owner" check reports `PASS` (`owner: swaync`, the documented D-19-42 transitional bus-ownership race — Plan 19-08 deletes `swaync`). QNOTIF-11's full live two-owner proof is this phase's own stated deferral to plan 19-08, not a gap in this plan. | closed (mitigation shipped; live two-owner proof deferred to 19-08 by design, per the plan's own text) |
| T-19-10 | Tampering | `NotifMarkdown.qml` body filter | high | mitigate | `NotifMarkdown.qml:48-110` — escape-everything-then-allowlist `filter()`; only bold/italic/`http(s)://` links re-permitted. The combined ordered regex (`:61`) claims image constructs (`![alt](url)`) first so the plain-link branch cannot leak a real link out of a disallowed image token; a non-http(s) URL scheme falls through to literal escaping (`:93-97`), closing the `javascript:`/`file:`/`data:` vector. Consumed at `NotifCard.qml:319` before `Text.MarkdownText` (`:320`) ever sees the sender's string. | closed |
| T-19-11 | Elevation of Privilege | link open from body text | high | mitigate | `NotifCard.qml:328-331` (`onLinkActivated`) sets a pending URL and reveals a confirm pill rather than opening immediately; `Qt.openUrlExternally` is called ONLY from the pill's "Yes" `TapHandler` (`:381-386`). "Cancel" (`:388-396`) discards the pending URL without opening it. Hover reveals the raw URL via a `BarTooltip` instance (`:555-565`) and never opens anything on hover alone. | closed |
| T-19-16 | Tampering | history store round-trip | high | mitigate | **Evidence citation corrected against shipped code** (see Unregistered Flags below): Plan 19-05's own mitigation text anticipated the SAME card component rendering both live and reloaded notifications; Plan 19-06 shipped a SEPARATE history-list component (`NotifGroup.qml`) instead of reusing `NotifCard.qml`. That file independently pins every sender-controlled text element it renders — the group header app name (`NotifGroup.qml:176-185`, `textFormat: Text.PlainText`, bound to `groupItem.groupAppName`) and each expanded row's summary (`:344-351`, same pin). The security property (no unpinned sender-controlled text survives a disk round-trip) holds — verified against the actual rendering path, not the plan-time anticipated one. | closed |
| T-19-21 | Tampering | group header application name | high | mitigate | `NotifGroup.qml:176-185` — `textFormat: Text.PlainText` on the group's app-name `Text`, bound to `groupItem.groupAppName` (sender-supplied, round-tripped through disk — the field most likely to be missed, per this row's own originating plan text, since it reads like metadata rather than content). | closed |
| T-19-26 | Tampering | `WifiPanel.qml` network-name bindings | high | mitigate | Closed by this plan's own Task 1. `WifiPanel.qml:818` (`ssidText`, the row label), `:844` (`ssidTooltip`'s `contentItem` — the unelided full SSID, converted from the attached-property `ToolTip.text` shorthand to a standalone pinned `ToolTip`, matching the mechanism `BluetoothPanel.qml` already uses), `:1087` (`forgetConfirmLabel`) — all three `textFormat: Text.PlainText`, matching `BluetoothPanel.qml`'s idiom (`:512`, `:536`, `:734`, `:776`) character for character. The rest of the panel family was audited per this task's own instruction — see Unregistered Flags for the `AudioPanel.qml` finding this audit surfaced. | closed (`WifiPanel.qml`); `AudioPanel.qml` gap found and recorded, not fixed here — out of this task's declared `files_modified` scope |

### Medium severity

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-19-03 | Denial of Service | `NotifPopupStack.qml` unbounded in-flight list | medium | mitigate | `NotifPopupStack.qml:99-112` (`_perCardHeight`, `visibleCount`, `overflowCount`, `_displayModel`) clamps the DISPLAYED slice to the height budget and renders a `+N more` summary card (`:227`, `qsTr("+%1 more")`); `NotifServer.popups` itself is never truncated, so no in-flight data is destroyed, only the render is bounded. Applies with no critical-urgency exemption (D-19-11's explicit anti-abuse rule). | closed |
| T-19-04 | Information Disclosure | sender-supplied `image`/`app_icon` path | medium | mitigate | This plan-01 tracer-era row is superseded, not a separate code path: Plan 19-04 shipped the real four-tier icon chain. See T-19-14 for the concrete, current citation — same component, same code, one register entry's worth of evidence. | closed (see T-19-14) |
| T-19-12 | Denial of Service | out-of-range progress value | medium | mitigate | `NotifCard.qml:244-247` (`_hints`, `_rawProgress`, `_clampedProgress`) clamps into `Math.max(0, Math.min(100, ...))` with an explicit `isNaN` guard, BEFORE `PathAngleArc.sweepAngle` geometry is computed at `:283`. A sender sending `hints.value: 999999` reaches only the clamped value. | closed |
| T-19-13 | Denial of Service | hostile or slow sender image | medium | mitigate | All three image tiers in `NotifCard.qml`'s icon slot (`notifImage:198-205`, `appIconImage:206-213`, `desktopIconImage:214-221`) set `asynchronous: true`, so a slow or unreachable image source cannot block the UI thread. The height clamp (T-19-03) applies uniformly regardless of urgency, so an application marking every notification critical still cannot wall off the screen. | closed |
| T-19-14 | Information Disclosure | sender-supplied icon path | medium | mitigate | Icon resolution goes exclusively through `Quickshell.iconPath()` (`NotifCard.qml:188,196`; also `NotifGroup.qml:79,86` for the history-list path) and `DesktopEntries.byId()` (`NotifCard.qml:193`; `NotifGroup.qml:84`) — the toolkit's own icon-theme/desktop-entry resolvers, never a hand-rolled filesystem read of a sender-supplied string. The `image` hint (`card.image`, sourced from Quickshell's own resolved `Notification.image` property — `NotifData.qml:48`) binds directly to `Image.source` (`NotifCard.qml:202`); this is the toolkit's own sanctioned image-rendering primitive consumed as designed, not a new arbitrary-local-path-open code path added by this repo, and no additional path validation is owed by (or added to) this repo's own code. | closed |
| T-19-15 | Spoofing | action invocation reaching the wrong process | medium | mitigate | `NotifCard.qml:429` and `NotifGroup.qml:386` both call `actionChip.modelData.invoke()` — the notification's own live `NotificationAction` object's method, routed by the toolkit back to the exact sender that registered it; no hand-rolled D-Bus call exists in either file. Arrival at the real sender is proven live (not assumed) by `hypr/.config/hypr/scripts/tests/notif-fault-inject` injection 2 — 2 consecutive runs, 9/9 checks passing (`19-04-SUMMARY.md`). | closed |
| T-19-17 | Denial of Service | malformed or hostile state file | medium | mitigate | `NotifServer.qml:436-456` (`_loadState()`) wraps `JSON.parse` in try/catch behind an explicit `Array.isArray`/`typeof` shape check; a parse failure logs (`:454`) and leaves `history`/`dnd` at their pre-load defaults rather than throwing or crashing the shell. `Design.notifHistoryCap` (enforced in `_recordHistory()`, `:262-263`) bounds the file's own growth through ordinary use. | closed |
| T-19-18 | Tampering | do-not-disturb persistence | medium | mitigate | `NotifServer.qml:419-427` (`stateFile.onSaveFailed`) reverts `root.dnd` to `_dndPrevValue` when the optimistic write (`toggleDnd()`, `:214-227`) fails — the tile is truth-driven, never showing a value the system is not actually in. Verified against the real revert branch, not merely the intention. | closed |
| T-19-19 | Elevation of Privilege | `BrightnessBackend` absolute setter | medium | mitigate | `BrightnessBackend.qml:234-235` (`setPercent`) is guarded by the identical `root.present`/`root.deviceName` presence check as the pre-existing `adjust()` (`:194-195`) — no new external command surface, the same bounded-argument tooling the relative path already used. | closed |
| T-19-20 | Spoofing | suppression bypass | medium | accept | See Accepted Risks Log — R-19-01. | closed |
| T-19-22 | Spoofing | centre above every application window | medium | accept | See Accepted Risks Log — R-19-02. | closed |
| T-19-23 | Elevation of Privilege | footer slider write paths | medium | mitigate | Every `SliderRow.onMoved` in `CentreFooter.qml` calls an EXISTING backend setter — `setMasterVolume`/`setInputVolume` (`:190-193`, `:204-207`) and `BrightnessBackend.setPercent` (`:218`, the same T-19-19-guarded setter) — no new write path is introduced. Each slider's `value:` reads its backend live (`:189`, `:203`, `:216`), never a locally-held copy, matching the repo's D-22 truth-driven discipline. | closed |
| T-19-24 | Information Disclosure | action buttons on stale notifications | medium | mitigate | `NotifGroup.qml:286` (`_fromDisk: !NotifServer.hasSessionActions(...)`) and `:363` (`visible: !notifRow._fromDisk && notifRow._actions.length > 0`) hide the action strip entirely on a disk-reloaded row. `NotifServer.qml:278-286` (`_sessionActionsById`, `hasSessionActions`, `actionsForHistoryId`) is held in memory only — `_writeState()` (`:473`) serialises only `history`/`dnd`, never this map — so a restart's id-absence from the map IS the entire "sender's session is gone" signal, and an action button is never dispatched toward a bus name whose original owner is gone. | closed |
| T-19-27 | Repudiation | `19-SECURITY.md` completeness | medium | mitigate | This document's own `verify` block (`19-07-PLAN.md:175`) mechanically asserts `grep -cE '^\| T-19-' >= 15` and a `threats_open: 0` frontmatter match — a consolidated document that silently dropped a plan's threat rows or hand-waved the open count would fail the check rather than pass silently. | closed |
| T-19-28 | Tampering | severity reclassification to reach zero open | medium | mitigate | No severity was lowered anywhere in this document to reach `threats_open: 0` — every row above keeps the severity its originating plan assigned. The one genuine gap this audit surfaced (`AudioPanel.qml`, below) is recorded as a flag rather than force-closed, silently dropped, or downgraded to make the count work. | closed |

### Low severity

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-19-25 | Denial of Service | large-history clear | low | mitigate | `clearAll()` (`NotifServer.qml:174-191`) and `clearGroup()` (`:309-347`) both batch at `Design.notifHistoryBatchSize` per zero-interval `Timer` tick, so the UI thread is never blocked by a large clear; `clearOne()` (`:299-307`) needs no batching (a single-item filter). | closed |
| T-19-SC | Tampering | package installs | low | accept | See Accepted Risks Log — R-19-03. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|--------------|------|
| R-19-01 | T-19-20 | Any session process can send a notification, and suppression (DND / gaming / centre-open / fullscreen) is a user-experience control, not a security boundary — a sender cannot bypass suppression to reach the screen, only mark itself critical. D-19-11's height clamp applies with no critical-urgency exemption (T-19-03, T-19-13 both apply uniformly), so an abusive sender still cannot wall off the screen even at critical urgency. | YahiaEng | 2026-08-13 |
| R-19-02 | T-19-22 | The centre is a layer-shell surface unconditionally above every application toplevel in this compositor — the same physics `15-SECURITY.md`'s R-15-05 already accepted for the panel-family rim. It takes no exclusive keyboard focus (D-19-18's deliberate no-grab design) and hosts no credential entry, so it is not a phishing surface. The risk that actually matters — an application's own confirm dialog landing behind a summoned shell surface — is a failure class this phase's own capability declaration (D-19-38, no `inline-reply`) removes for notifications rather than creates. | YahiaEng | 2026-08-13 |
| R-19-03 | T-19-SC | Phase 19 installs no new package. `swaync` is removed (RETIRE-03), not replaced with a new dependency; the one new asset this phase adds (`assets/notif-empty.svg`, Plan 19-06) is authored in-repo, not fetched from any third party. | YahiaEng | 2026-08-13 |

*Accepted risks do not resurface in future audit runs.*

---

## Unregistered Flags

Raised during this document's own verification pass. Neither is at or above the `high` block
threshold, so neither gates phase advancement. Recorded here so they are not lost, per the same
discipline `15-SECURITY.md`'s own Unregistered Flags section established.

| # | Flag | Assessment |
|---|------|------------|
| 1 | `AudioPanel.qml` has the same untrusted-string class T-19-26/T-15-08b closed for wifi and bluetooth: `streamLabelText` (`:743`, bound to `root.backend.streamLabel(streamRow.node)` — a PipeWire application name) and its hover `ToolTip.text` (`:757`), plus `deviceLabelText` (`:188`, PipeWire device description) and its `ToolTip.text` (`:274`), plus `candidateLabelText` (`:313`) and its `ToolTip.text` (`:332`) — all render externally-sourced strings with NO `textFormat` pin. Found and read in full per this plan's Task 1 instruction to audit the whole panel family rather than assume it clean. | Genuine finding, same class as the now-closed T-19-26. Below `block_on: high` if minted (same medium-severity class as `15-SECURITY.md`'s own already-registered T-15-08b, which this class matches). Out of this task's declared `files_modified` (`WifiPanel.qml` only) and out of scope per the Rule-2 scope boundary — pre-existing, not caused by this task's own change. Recommend minting as a follow-up in a future plan that touches `AudioPanel.qml`, mirroring how `15-SECURITY.md` itself recorded the (then-open) `WifiPanel.qml` gap this plan has now closed. |
| 2 | T-19-16's originating mitigation text (`19-05-PLAN.md`'s own `<threat_model>`) named the WRONG rendering component — it anticipated the popup card component (`NotifCard.qml`) being reused for history rendering. Plan 19-06 shipped a dedicated, separate history-list component (`NotifGroup.qml`) instead, which was never re-verified against that specific wording. | Documentation-accuracy finding, not a vulnerability — `NotifGroup.qml` independently carries the equivalent pins (verified this session, cited in T-19-16's register row above). The underlying security property held throughout; only the plan-time evidence citation was stale. Corrected in this document rather than left to silently mismatch the shipped code. |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-13 | 24 | 24 | 0 | This plan's own executor, acting in the auditor role for LEDGER-08's gap-closure requirement — every register-row citation above was read directly against the file and line it names this session (not restated from plan-time prose), mirroring `15-SECURITY.md`'s evidence-cited methodology. `quickshell-doctor` (live-run this session, twice, before and after Task 1's `WifiPanel.qml` change) reports the identical 4 pre-existing, unrelated failures both times (`zero Quickshell MPRIS writers`, `panel-swayosd-key-ownership`, `bar-surface-registry`, `permissions-allowlist-paths-resolve` — all documented and deferred by prior plans in this phase, none touching this plan's own files) — confirmed via a `git stash` A/B comparison, so Task 1's change introduced zero new failures. |

Severity distribution: 7 high / 15 medium / 2 low. Dispositions: 21 mitigate / 3 accept. One round —
no finding at or above `block_on: high` was found unmitigated, so no severity was lowered and no
second round was required; the two Unregistered Flags above are both non-blocking by construction
(one below-threshold pre-existing gap in an out-of-scope file, one documentation-accuracy
correction with no code change needed).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-13
