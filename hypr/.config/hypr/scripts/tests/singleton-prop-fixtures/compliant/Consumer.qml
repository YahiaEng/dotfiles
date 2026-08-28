import QtQuick
Item {
    property color a: Roles.topLevelRole
    property string b: Roles.nestedRole
    Component.onCompleted: Roles.someFunction()
}
