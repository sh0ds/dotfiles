import QtQuick
// The light on glass: a soft white sheen over the top half of a glass
// surface and a brighter rim along its top edge. The top of the haze
// behind the rail is nearly black, so the blur alone has nothing to show
// there; this is what makes the pills read as glass. Put it first in a
// glass Rectangle (it follows the parent's corners).
Item {
    anchors.fill: parent
    readonly property real corner: parent?.radius ?? 0
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.corner - 1)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.03) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
    // The rim: the top half of the outline, lit.
    Item {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Math.max(parent.corner, parent.height / 2)
        clip: true
        Rectangle {
            width: parent.width; height: parent.parent.height
            radius: parent.parent.corner
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.22)
        }
    }
}
