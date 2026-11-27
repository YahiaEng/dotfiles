pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property bool softwareRendering: Quickshell.env("QUICKSHELL_SOFTWARE_RENDERING") === "1"

    // Restore the original graphics environment, including unset values.
    readonly property var environment: {
        if (!softwareRendering)
            return {};

        const result = { QUICKSHELL_SOFTWARE_RENDERING: null };
        for (const name of ["GALLIUM_DRIVER", "LIBGL_ALWAYS_SOFTWARE", "QSG_RHI_BACKEND"]) {
            const original = "QUICKSHELL_APP_" + name;
            result[name] = Quickshell.env(original);
            result[original] = null;
        }
        return result;
    }

    function execDetached(command: list<string>): void {
        Quickshell.execDetached({ command: command, environment: environment });
    }

    function openUrl(url: url): void {
        if (softwareRendering)
            execDetached(["xdg-open", url.toString()]);
        else
            Qt.openUrlExternally(url);
    }
}
