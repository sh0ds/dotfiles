import QtQuick
import QtQuick.Controls
Rectangle {
    id: cell
    property string label: ""
    property string hint: ""
    property bool selected: false
    property color ink: Theme.text
    signal clicked()
    implicitWidth: title.implicitWidth + 28
    implicitHeight: 34
    radius: 3
    color: selected ? Theme.accent : (pointer.containsMouse || activeFocus ? Theme.raised : "transparent")
    border.width: activeFocus ? 1 : 0
    border.color: Theme.accent
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Behavior on color { ColorAnimation { duration: Theme.motion } }
    Text {
        id: title
        anchors.centerIn: parent
        text: cell.label
        color: cell.selected ? Theme.background : cell.ink
        font.family: Theme.mono
        font.pixelSize: 12
        textFormat: Text.PlainText
    }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cell.clicked() }
    ToolTip.visible: pointer.containsMouse && hint.length > 0
    ToolTip.delay: 650
    ToolTip.text: hint
}
