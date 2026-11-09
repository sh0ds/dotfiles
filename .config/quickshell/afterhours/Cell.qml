import QtQuick
import QtQuick.Controls
import Quickshell
// A square, keyboard-focusable button: faint fill on hover, violet fill
// when selected, colour changes ease out, a small dip when pressed.
Rectangle {
    id: cell
    property string label: ""
    property string hint: ""
    property bool selected: false
    property color ink: Theme.text
    property color fill: "transparent"
    property int size: 13
    // Child items (like the rail's cava bars) sit before the label.
    default property alias lead: leadRow.data
    signal clicked()
    signal rightClicked()
    // Mouse wheel over the whole cell: +1 up, -1 down.
    signal wheeled(int step)
    implicitWidth: content.implicitWidth + 26
    implicitHeight: 32
    color: selected ? Theme.accent : (pointer.containsMouse || activeFocus ? Theme.glassRaised : fill)
    border.width: activeFocus ? 1 : 0
    border.color: Theme.accent
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    // A press dips the cell a little; letting go springs it back. bump()
    // pops it once (the rail's inbox count when a notification lands).
    property real dip: pointer.pressed ? 0.94 : 1
    Behavior on dip { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
    property real pop: 1
    scale: dip * pop
    function bump() { popAnim.restart(); }
    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: cell; property: "pop"; to: 1.14; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { target: cell; property: "pop"; to: 1; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: 2.4 }
    }
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8
    Row {
        id: leadRow
        visible: children.length > 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
    }
    Text {
        id: title
        text: cell.label
        color: cell.selected ? Theme.background : cell.ink
        font.family: Theme.font
        font.pixelSize: cell.size
        textFormat: Text.PlainText
        Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    }
    }
    MouseArea {
        id: pointer
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? cell.rightClicked() : cell.clicked()
    }
    // In the rail (a 42 px window) a ToolTip would be cut off, so the hint
    // gets its own popup window there; the overlay keeps the plain ToolTip.
    readonly property bool inBar: Window.height > 0 && Window.height < 80
    LazyLoader {
        active: cell.inBar && cell.hint.length > 0
        Hint { target: cell; text: cell.hint; show: pointer.containsMouse }
    }
    // Here, not in a user's cell body: children declared there land in the
    // lead row, which is hidden when empty and would never see the wheel.
    WheelHandler { onWheel: e => cell.wheeled(e.angleDelta.y > 0 ? 1 : -1) }
    ToolTip.visible: !inBar && pointer.containsMouse && hint.length > 0
    ToolTip.delay: 650
    ToolTip.text: hint
}
