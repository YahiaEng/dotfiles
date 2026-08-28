import QtQuick
Item {
    // Roles.notDeclaredAnywhere must NOT be reported - this is prose.
    property color a: Roles.topLevelRole
    property string s: "Roles.notDeclaredAnywhere"
}
