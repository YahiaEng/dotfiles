// modules/settings/pages/AppInfoPage.qml — sub-page 2 of the Apps
// StackPage (quick task 260825-wj2 Task 2, D-5/D-6). Selection-dependent:
// reads `sState.selectedApp`, set by AllAppsPage's own row click, and
// auto-closes if that selection is ever lost (the reference's own
// `onAppChanged` pattern) — reachable directly only via AllAppsPage
// (RowIndex's own entries here carry `jumpSubPageIdx: 1` for exactly this
// reason, D-5).
//
// Favourite/Hidden are plain per-id string arrays with NO regex authoring
// path (D-6): unlike the reference's own hand-edited config file, this
// tree's Prefs store is written only by this settings UI, so there is no
// regex-matched entry a toggle could ever need to disable itself against.
import QtQuick
import Quickshell
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "App info"
    isSubPage: true

    readonly property var app: root.sState.selectedApp

    onAppChanged: if (!root.app)
        root.sState.closeSubPage()

    function _looksLikeThemeName(name) {
        return name.indexOf("/") === -1 && name.indexOf("://") === -1;
    }
    readonly property string _iconSrc: {
        var icon = root.app ? root.app.icon : "";
        if (!icon || icon.length === 0)
            return "";
        if (!root._looksLikeThemeName(icon) || Quickshell.hasThemeIcon(icon))
            return Quickshell.iconPath(icon, "");
        return "";
    }

    Row {
        // No explicit `x` — `bodyColumn` (PageBase's own content host) is
        // already offset by `contentInset`; setting it again here would
        // double the inset. Width follows the SAME `parent ? parent.width :
        // implicitWidth` idiom `SettingsSection.qml` uses, for the identical
        // circular-binding reason that file's own header documents.
        width: parent ? parent.width : implicitWidth
        spacing: Design.spacingMd

        Image {
            width: Design.settingsIconSize * 2
            height: Design.settingsIconSize * 2
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectFit
            source: root._iconSrc
            visible: source.length > 0 && status !== Image.Error
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.app ? root.app.name : ""
                font.pixelSize: Design.settingsFontTitle
                font.weight: Design.weightEmphasis
                color: Colours.onSurface
            }
            Text {
                readonly property string _detail: root.app ? ((root.app.comment || root.app.genericName) || "") : ""
                visible: text.length > 0
                text: _detail
                font.pixelSize: Design.settingsFontSub
                color: Colours.onSurfaceVariant
            }
        }
    }

    SettingsSection {
        title: "Launcher"
        icon: "apps"

        ToggleRow {
            label: "Favourite"
            subtext: "Pin to the top of the launcher"
            checked: root.app ? Prefs.getValue("launcher.favouriteApps").indexOf(root.app.id) !== -1 : false
            onToggled: (value) => {
                if (!root.app)
                    return;
                var apps = Prefs.getValue("launcher.favouriteApps");
                var next = value ? apps.concat([root.app.id]) : apps.filter((a) => a !== root.app.id);
                Prefs.setValue("launcher.favouriteApps", next);
            }
        }
        ToggleRow {
            label: "Hidden"
            subtext: "Hide from the launcher"
            checked: root.app ? Prefs.getValue("launcher.hiddenApps").indexOf(root.app.id) !== -1 : false
            onToggled: (value) => {
                if (!root.app)
                    return;
                var apps = Prefs.getValue("launcher.hiddenApps");
                var next = value ? apps.concat([root.app.id]) : apps.filter((a) => a !== root.app.id);
                Prefs.setValue("launcher.hiddenApps", next);
            }
        }
    }

    SettingsSection {
        title: "Details"
        icon: "info"

        InfoRow {
            label: "App ID"
            subtext: root.app ? root.app.id : ""
        }
        InfoRow {
            label: "Command"
            subtext: root.app ? (root.app.command || []).join(" ") : ""
        }
    }
}
