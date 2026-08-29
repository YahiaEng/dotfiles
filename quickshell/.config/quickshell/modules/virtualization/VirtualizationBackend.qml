// modules/virtualization/VirtualizationBackend.qml — quick task 260829-vfi.
//
// Owns every probe and the one privileged write path for the Windows VM
// and its linked host drives.
//
// ── WHY A SINGLETON ───────────────────────────────────────────────────
// Same reason SecurityBackend is one, and the same measurement behind it:
// `Pages.qml:_swapTo` destroys a page before incubating the next, so a
// page-scoped Process dies the instant the operator clicks another rail
// item. A pkexec action here raises an authentication dialog and can sit
// for as long as the operator takes to type a password — far longer than
// a page lives. Move any Process in this file into the page and linking
// a drive breaks silently whenever the operator navigates away mid-auth.
//
// ── ONE WRITE PATH ────────────────────────────────────────────────────
// Every state change goes through `runAction(verb)`, which invokes
//     pkexec /usr/local/lib/vm-drives/vm-drive-action <verb>
// with `verb` checked against `_ALLOWED_ACTIONS` here FIRST. The helper
// checks it again against its own hardcoded `case`. That redundancy is
// deliberate: this file is user-writable (it is stowed), the helper is
// not, so the helper's list is the real boundary and this one is a
// convenience that fails fast.
//
// Reads use `virsh -c qemu:///system`, which needs no privileges because
// the operator is in the `libvirt` group — libvirtd runs as root and
// performs the privileged work on their behalf.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string helperPath: "/usr/local/lib/vm-drives/vm-drive-action"
    readonly property string domain: "win11-gaming"

    // Declared before anything that reads them at construction time — a
    // later-declared member throws "is not a function" and a fallback
    // chain turns that into a plausible wrong answer.
    readonly property var _ALLOWED_ACTIONS: [
        "link-storage", "unlink-storage", "link-main", "unlink-main"
    ]

    // ── VM state ──
    property string vmState: "unknown"
    property bool vmProbed: false
    readonly property bool vmDefined: vmState !== "undefined" && vmState !== "unknown"
    readonly property bool vmRunning: vmState === "running"
    readonly property bool vmOff: vmState === "shut off"

    // ── link state, as reported by the helper ──
    property bool storageLinked: false
    property bool mainLinked: false
    property bool mainMapped: false
    property bool linkStateProbed: false

    // ── helper presence ──
    property bool helperMissing: false
    property bool helperProbed: false

    // ── the privileged action in flight ──
    property bool actionRunning: false
    property string actionVerb: ""
    property string actionError: ""
    signal actionFinished(string verb, bool ok, string message)

    // ── live drive inventory ──
    // Populated from lsblk so the page shows real sizes and, more
    // importantly, notices when a drive is ABSENT or currently MOUNTED
    // rather than offering a link that the helper would refuse anyway.
    property var drives: []
    property bool drivesProbed: false

    // The two linkable drives, and the one that deliberately is not.
    // Identified the way the helper identifies them — by WWN and GPT
    // PARTUUID, never by kernel name, because /dev/sda and /dev/nvme1n1
    // can reorder across boots.
    readonly property var _catalogue: [
        {
            key: "storage",
            title: "Storage",
            partuuid: "650b543b-5e73-4a28-ae88-706f101fe898",
            // The row is IDENTIFIED by its NTFS partition (that is what
            // gets probed for hibernation) but ATTACHED as the whole disk,
            // because sda carries its own GPT and Windows mounts it
            // natively. Saying so avoids a row that reads "/dev/sda2 …
            // whole disk" and contradicts itself.
            note: "Attached as the whole disk — no operating system on it",
            linkable: true
        },
        {
            key: "main",
            title: "Main",
            partuuid: "590b0c8f-7d06-4256-9ab5-0a49dd442d5f",
            note: "On the Windows boot disk — mapped so only this partition is reachable, the rest discards writes",
            linkable: true
        },
        {
            key: "windows",
            title: "Windows C:",
            partuuid: "2e3b6dd2-1146-4dde-a58d-6fb84800c624",
            note: "System volume — a second Windows would write to it for no gain",
            linkable: false
        }
    ]

    function refreshAll() {
        helperProc.running = true;
        vmProc.running = true;
        statusProc.running = true;
        lsblkProc.running = true;
    }

    function isLinked(key) {
        return key === "storage" ? root.storageLinked
             : key === "main"    ? root.mainLinked
             : false;
    }

    // Why a given drive cannot be linked right now. Empty string means it
    // can. The page renders this instead of guessing, so the reason the
    // operator sees is the same reason the helper would give.
    function blockedReason(d) {
        if (!d.linkable)
            return "Not linkable by design";
        if (!d.present)
            return "Drive not present";
        if (d.mounted)
            return "Mounted on the host — unmount it first";
        if (root.helperMissing)
            return "Helper not installed — run ./install.sh --gaming-only";
        if (!root.vmDefined)
            return "VM not defined yet";
        if (!root.vmOff)
            return "VM is " + root.vmState + " — shut it down first";
        return "";
    }

    function runAction(verb) {
        if (root.actionRunning)
            return;
        if (root._ALLOWED_ACTIONS.indexOf(verb) < 0) {
            root.actionError = "Refused unknown action: " + verb;
            return;
        }
        root.actionError = "";
        root.actionVerb = verb;
        root.actionRunning = true;
        actionProc.command = ["pkexec", root.helperPath, verb];
        actionProc.running = true;
    }

    // ── probes ───────────────────────────────────────────────────────
    // `test -x` rather than a file-exists check: what matters is whether
    // pkexec can execute it, not whether a path is present.
    Process {
        id: helperProc
        running: false
        command: ["test", "-x", root.helperPath]
        onExited: code => {
            root.helperMissing = code !== 0;
            root.helperProbed = true;
        }
    }

    Process {
        id: vmProc
        running: false
        command: ["virsh", "-c", "qemu:///system", "domstate", root.domain]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                root.vmState = s.length > 0 ? s : "undefined";
            }
        }
        onExited: code => {
            if (code !== 0)
                root.vmState = "undefined";
            root.vmProbed = true;
        }
    }

    Process {
        id: statusProc
        running: false
        command: ["sh", "-c",
            "test -r /var/lib/vm-drives/linked && cat /var/lib/vm-drives/linked || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim());
                root.storageLinked = lines.indexOf("storage") >= 0;
                root.mainLinked = lines.indexOf("main") >= 0;
            }
        }
        onExited: () => {
            root.linkStateProbed = true;
            dmProc.running = true;
        }
    }

    Process {
        id: dmProc
        running: false
        command: ["sh", "-c", "dmsetup info vm-main >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root.mainMapped = text.trim() === "yes"
        }
    }

    // lsblk in JSON so presence, size, label and mount state come from one
    // parse rather than four greps.
    Process {
        id: lsblkProc
        running: false
        command: ["lsblk", "-bJ", "-o", "NAME,PATH,SIZE,FSTYPE,LABEL,PARTUUID,MOUNTPOINT"]
        stdout: StdioCollector {
            onStreamFinished: root._parseDrives(text)
        }
        onExited: () => root.drivesProbed = true
    }

    function _parseDrives(jsonText) {
        let byPartuuid = ({});
        try {
            const walk = nodes => {
                for (const n of (nodes || [])) {
                    if (n.partuuid)
                        byPartuuid[String(n.partuuid).toLowerCase()] = n;
                    walk(n.children);
                }
            };
            walk(JSON.parse(jsonText).blockdevices);
        } catch (e) {
            root.drives = [];
            return;
        }
        root.drives = root._catalogue.map(c => {
            const n = byPartuuid[c.partuuid];
            return {
                key: c.key,
                title: c.title,
                note: c.note,
                linkable: c.linkable,
                present: n !== undefined,
                dev: n ? n.path : "",
                label: n && n.label ? n.label : "",
                fstype: n && n.fstype ? n.fstype : "",
                bytes: n && n.size ? Number(n.size) : 0,
                mounted: !!(n && n.mountpoint)
            };
        });
    }

    function sizeText(bytes) {
        if (!bytes || bytes <= 0)
            return "—";
        const tb = bytes / 1000000000000;
        if (tb >= 1)
            return tb.toFixed(1) + " TB";
        return Math.round(bytes / 1000000000) + " GB";
    }

    Process {
        id: actionProc
        running: false
        stdout: StdioCollector { id: actionOut }
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            const verb = root.actionVerb;
            root.actionRunning = false;
            root.actionVerb = "";
            const ok = code === 0;
            // pkexec exits 126 when the operator dismisses the dialog and
            // 127 when it cannot start the helper at all. Neither is a
            // failure of the action, and reporting them as one sent a
            // previous task chasing a phantom bug.
            let msg = ok ? actionOut.text.trim()
                    : code === 126 ? "Cancelled"
                    : code === 127 ? "Could not start the helper"
                    : (actionErr.text.trim() || ("Failed (exit " + code + ")"));
            if (!ok && code !== 126)
                root.actionError = msg;
            root.actionFinished(verb, ok, msg);
            root.refreshAll();
        }
    }
}
