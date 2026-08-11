// BrightnessBackend.qml — the brightness section's hardware-presence probe
// and single-flighted writer (Phase 18 Plan 12, QBAR-04, D-18-39).
//
// D-18-39 names this the "exact D-18-06 battery precedent": build it
// present-but-inert, gated on hardware presence, correct on hardware that
// has a backlight, rendering nothing on hardware that does not. This host
// has no backlight (/sys/class/backlight/ is empty), so the entry this
// backend feeds renders nothing here — that is NOT a Phase 18 regression:
// GATE-01's own Dead Definitions entry already records that the retired
// bar's own backlight scroll binding (config-floating.jsonc's `light -A 5`/
// `light -U 5`) was already dead on this host for want of the `light`
// binary, before this phase ever started.
//
// The presence gate below MUST NEVER become a constant, a host test or a
// commented-out block. The entire justification for shipping this
// capability inert is that the code is genuinely correct on hardware that
// HAS a backlight — a hardcoded disable wearing the costume of a probe
// would make that justification false while leaving this host's observable
// behaviour completely unchanged, so nothing here would ever catch it.
// `present` is assigned only from the parsed result of running
// `brightnessctl` and from nowhere else.
//
// ── Why a singleton, and why here rather than shell.qml ─────────────────
// A shell-mounted backend would need a mount, a handle threaded through
// `BarCapsule` and an edit to two files that exist to be bound once (by
// 18-05) and then left alone — all for one integer and one verb. A
// singleton is constructed on first reference, which is when the bar
// itself builds, and costs exactly one probe. Keeping the process out of
// `MediaConnectivityCapsule.qml` is deliberate and load-bearing: that file
// is gated on containing no process and no timer at all, and this backend
// is what lets that gate stay true while the capability still ships.
//
// ── Zero-idle claim ───────────────────────────────────────────────────────
// No timer of any kind exists in this file. The probe runs once at
// construction and the writer runs only in direct response to a wheel
// gesture, so the resulting idle cost is exactly zero subprocesses and zero
// timers — the first backend in this repo able to claim that without a
// gate, because it has nothing to poll. The one honest limitation that
// buys: presence is sampled once, so a backlight device that appears after
// the shell starts (a dock event, a hot-plugged capable monitor) is not
// noticed until the shell restarts. On the laptop deployment D-18-39
// targets, the device exists at boot, so this is a stated limit rather
// than a hidden one — adding a re-probe would mean adding the timer this
// file exists to avoid.
//
// ── Argument construction (T-18-12-01) ────────────────────────────────────
// Every `brightnessctl` invocation below is a fixed argv array whose first
// element is the literal tool name, run through Quickshell's own `Process`
// with no interpreter anywhere in the path. Exactly two variable elements
// ever reach an argument: the device name, which originates from
// `brightnessctl`'s OWN machine-readable output and from nowhere else (not
// a file, not a peer, not a user-editable setting); and an integer delta
// computed from a bounded local notch count. Nothing here is ever joined
// into a single string for something downstream to re-split. The class and
// device flags are spelled out in their LONG form (`--class`/`--device`
// rather than `-c`/`-d`) deliberately: the short `-c` form, written with
// its trailing comma as a QML array element, is textually indistinguishable
// from a shell interpreter's own `-c` flag, and this file is gated on no
// such sequence appearing anywhere in it.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../dashboard"

Singleton {
    id: root

    // The one property to repoint to exercise the presence-positive path
    // on a machine with no backlight: change this to "leds" (the class
    // this host DOES populate) and save. Quickshell hot-reloads, the probe
    // below re-runs against the real tool, and a real device renders — same
    // probe, same parser, same argv builder, no test double anywhere. This
    // is what makes D-18-39's gate checkable in both directions here rather
    // than only on hardware nobody owns. Production value: "backlight".
    readonly property string deviceClass: "backlight"

    // Set ONLY from the probe's parsed stdout — never assigned a constant
    // anywhere else in this file.
    property bool present
    property string deviceName: ""
    property int percent: 0
    property bool failed: false

    // A signed pending delta, applied in exactly one follow-up child once
    // the in-flight one exits. An equal number of up and down notches
    // arriving mid-flight sums to zero here and produces no follow-up
    // child at all — the single-flight guard below and this accumulator
    // together are what keep a fast wheel spin from stacking children on a
    // surface that never has a dismissed state to fall back to.
    property int pendingDelta: 0
    // The argv's own delta-form element, rebuilt just before each adjust
    // child starts — a property binding so the Process's own argv
    // declaration stays a fixed literal array rather than an imperative
    // reassignment.
    property string _adjustDeltaForm: "+0%"

    // ── The presence probe — one Process, run once at construction ──────
    Process {
        id: probeProcess
        running: false
        command: ["brightnessctl", "-m", "-l", "--class", root.deviceClass]
        stdout: StdioCollector {
            id: probeCollector
        }
        onExited: (exitCode, exitStatus) => {
            // brightnessctl writes its "no devices" message to STDERR and
            // exits non-zero when a class is empty — an ordinary absence,
            // not a failure state. Reading stdout's line count rather than
            // exitCode is what keeps the most common case on this host
            // from tinting the glyph red the moment the shell starts.
            const lines = (probeCollector.text || "").split("\n").filter(function (l) {
                return l.trim().length > 0;
            });
            if (lines.length === 0) {
                root.present = false;
                root.deviceName = "";
                root.percent = 0;
                return;
            }
            const fields = lines[0].split(",");
            if (fields.length < 4) {
                root.present = false;
                return;
            }
            root.deviceName = fields[0];
            root.percent = parseInt(fields[3].replace("%", ""), 10) || 0;
            root.present = true;
        }
    }

    // ── The writer — single-flighted with a coalescing pending delta,
    //    copying MediaBackend.qml's own early-return-if-running guard. ───
    Process {
        id: adjustProcess
        running: false
        command: ["brightnessctl", "-m", "--class", root.deviceClass, "-d", root.deviceName, "set", root._adjustDeltaForm]
        stdout: StdioCollector {
            id: adjustCollector
        }
        onExited: (exitCode, exitStatus) => {
            // A set operation prints its own post-write device line on
            // stdout in machine-readable mode, so the percent updates from
            // the write itself and no separate read child is ever spawned.
            const text = (adjustCollector.text || "").trim();
            const fields = text.split(",");
            if (exitCode === 0 && fields.length >= 4) {
                root.percent = parseInt(fields[3].replace("%", ""), 10) || root.percent;
                root.failed = false;
            } else {
                // A non-zero exit here is a real write failure, not an
                // absence — the probe already established presence and a
                // device name before this child could ever run.
                root.failed = true;
            }
            // Chase whatever arrived while this child was in flight —
            // single-flighted (this process just cleared `running`),
            // never queued, never a second concurrent child.
            if (root.pendingDelta !== 0) {
                const next = root.pendingDelta;
                root.pendingDelta = 0;
                root._startAdjust(next);
            }
        }
    }

    // Builds the tool's own percentage-delta form — leading-plus for a
    // rise, trailing-minus for a fall — rather than computing an absolute
    // from the current percent. This is what lets this file stay ignorant
    // of a device's maximum: the tool enforces the device's own minimum
    // and maximum from its delta forms, and the minimum-value flag is
    // deliberately never passed, so no floor is invented on top of the
    // device's own.
    function _deltaForm(delta) {
        return delta >= 0 ? ("+" + delta + "%") : (Math.abs(delta) + "%-");
    }

    function _startAdjust(delta) {
        root._adjustDeltaForm = root._deltaForm(delta);
        adjustProcess.running = true;
    }

    // The one public verb: a signed notch count, never a raw percent. No
    // caller of this function ever needs to know a device's bounds.
    function adjust(steps) {
        if (!root.present || root.deviceName === "")
            return;
        const delta = steps * Design.barScrollStepPercent;
        if (adjustProcess.running) {
            root.pendingDelta += delta;
            return;
        }
        root._startAdjust(delta);
    }

    Component.onCompleted: probeProcess.running = true
}
