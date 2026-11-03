import QtQuick
import QtQuick.Controls
// A rounded, keyboard-focusable button: faint fill on hover, phosphor fill
// when selected, colour changes ease out.
Rectangle {
    id: cell
    property string label: ""
    property string hint: ""
    property bool selected: false
    property color ink: Theme.text
    property color fill: "transparent"
    property int size: 13
    signal clicked()
    implicitWidth: title.implicitWidth + 26
    implicitHeight: 32
    radius: Theme.radius
    color: selected ? Theme.accent : (pointer.containsMouse || activeFocus ? Theme.raised : fill)
    border.width: activeFocus ? 1 : 0
    border.color: Theme.accent
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    Text {
        id: title
        anchors.centerIn: parent
        text: cell.label
        color: cell.selected ? Theme.background : cell.ink
        font.family: Theme.font
        font.pixelSize: cell.size
        textFormat: Text.PlainText
        Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cell.clicked() }
    ToolTip.visible: pointer.containsMouse && hint.length > 0
    ToolTip.delay: 650
    ToolTip.text: hint
}
