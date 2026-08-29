// modules/settings/pages/VirtualizationPage.qml — quick task 260829-vfi.
//
// The Windows VM's surface: its state, and which host drives it may
// reach.
//
// Owns NO Process children. Every probe and the privileged action live on
// the `VirtualizationBackend` singleton, for the reason UpdatesPage's
// header states and SecurityPage repeats: `Pages.qml:_swapTo` destroys a
// page before incubating the next, so a page-scoped Process dies the
// instant the operator clicks another rail item. A pkexec action here
// raises an authentication dialog and lives for as long as it takes
// someone to type a password — far longer than this page does.
import QtQuick
import QtQuick.Layouts
import ".."
import "../common"
import "../../"
import "../../virtualization"

PageBase {
    id: root

    title: "Virtualization"

    Component.onCompleted: VirtualizationBackend.refreshAll()

    // ── Let the polkit prompt have focus ──────────────────────────────
    // Linking a drive raises an EXTERNAL toplevel (the polkit agent).
    // Settings' HyprlandFocusGrab is exclusive and cannot include another
    // process's window, so without this the operator's click on the
    // password box reads as a click outside the grab: Settings takes
    // focus back and the prompt drops behind it.
    //
    // A Binding rather than an assignment so the hold is RELEASED if this
    // page is destroyed mid-action; a leaked hold would disable
    // click-outside-dismiss for the rest of the session.
    Binding {
        target: root.sState
        property: "externalDialogOpen"
        value: VirtualizationBackend.actionRunning
        restoreMode: Binding.RestoreBindingOrValue
    }

    // Rows for the drives arrive from an async lsblk parse. Without this
    // the focus walker collects the section while `drives` is still empty
    // and keyboard navigation silently skips every drive row forever.
    Connections {
        target: VirtualizationBackend
        function onDrivesProbedChanged() { root.sState.focusRowsInvalidated(); }
    }

    SettingsSection {
        title: "Windows VM"
        icon: "computer"

        InfoRow {
            label: "Status"
            icon: "play_circle"
            subtext: !VirtualizationBackend.vmProbed ? "Checking…"
                   : !VirtualizationBackend.vmDefined
                     ? "Not defined — run: virsh define ~/dotfiles/vfio/win11-gaming.xml"
                     : VirtualizationBackend.vmState
        }

        InfoRow {
            label: "Passthrough"
            icon: "memory"
            subtext: "RTX 3070 + its HDMI audio, the CPU USB controller "
                   + "(keyboard, mouse, USB audio) and onboard analog audio"
        }

        InfoRow {
            label: "Single-GPU"
            icon: "warning"
            subtext: "Starting the VM shuts down this desktop for its whole "
                   + "lifetime. There is no second GPU to keep Hyprland alive."
        }
    }

    SettingsSection {
        title: "Linked drives"
        icon: "hard_drive"

        InfoRow {
            label: "Before linking"
            icon: "info"
            subtext: "Turn off Fast Startup in Windows (powercfg /h off) and "
                   + "shut down fully. A hibernated NTFS volume written by the "
                   + "guest is corrupted, and linking is refused until it is clean."
        }

        Repeater {
            model: VirtualizationBackend.drives

            delegate: ToggleRow {
                required property var modelData

                readonly property string reason:
                    VirtualizationBackend.blockedReason(modelData)
                readonly property bool blocked: reason.length > 0

                // NOTE: no `icon:` here. ToggleRow does not HAVE that property
                // — only InfoRow does — and assigning it made the whole
                // Settings type fail to load. Every static gate passed that
                // (197/0), because a lazily-loaded page is only ever type-
                // checked when something instantiates it; the sole instrument
                // was opening the page over IPC and reading quickshell.log.
                label: modelData.title
                indexLabel: modelData.title
                checked: VirtualizationBackend.isLinked(modelData.key)
                enabled: !blocked && !VirtualizationBackend.actionRunning

                subtext: {
                    const size = VirtualizationBackend.sizeText(modelData.bytes);
                    const dev = modelData.dev.length > 0 ? modelData.dev : "absent";
                    const head = dev + " · " + size
                               + (modelData.fstype.length > 0 ? " · " + modelData.fstype : "");
                    return blocked ? head + " — " + reason
                                   : head + " — " + modelData.note;
                }

                onToggled: value => {
                    if (blocked)
                        return;
                    VirtualizationBackend.runAction(
                        (value ? "link-" : "unlink-") + modelData.key);
                }
            }
        }

        InfoRow {
            visible: VirtualizationBackend.actionError.length > 0
            label: "Last error"
            icon: "error"
            subtext: VirtualizationBackend.actionError
        }
    }
}
