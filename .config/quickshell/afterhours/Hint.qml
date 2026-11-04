import QtQuick
import Quickshell
// A hover hint under an item of the rail. QtQuick's ToolTip draws inside
// its own window, and the rail's window is only 42 px tall, so a ToolTip
// there was cut off; this is a small popup window of its own instead.
// Fades in after a short delay, slides along the screen edge if needed.
PopupWindow {
    id: hint
    required property Item target
    property string text: ""
    property bool show: false
    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
    color: "transparent"
    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 12
    visible: false
    Timer { id: delay; interval: 550; onTriggered: hint.visible = true }
    onShowChanged: { if (show && text.length > 0) delay.restart(); else { delay.stop(); visible = false; } }
    onVisibleChanged: if (visible) fade.restart()
    Rectangle {
        id: box
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.raised
        border.width: 1
        border.color: Theme.line
        Text {
            id: label
            anchors.centerIn: parent
            text: hint.text
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 11
            textFormat: Text.PlainText
        }
        NumberAnimation { id: fade; target: box; property: "opacity"; from: 0; to: 1; duration: Theme.motion; easing.type: Easing.OutCubic }
    }
}
