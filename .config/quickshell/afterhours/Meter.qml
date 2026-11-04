import QtQuick
// A slim slider: a rounded track, a violet fill and a knob that grows on
// hover. Drag, click or scroll; `moved(value)` fires with 0..1 while the
// user changes it, so the caller decides what to do (set a volume, seek).
Item {
    id: meter
    property real value: 0
    property bool muted: false
    property real step: 0.05
    signal moved(real value)
    implicitHeight: 18
    implicitWidth: 200
    readonly property real shown: Math.max(0, Math.min(1, drag.pressed ? drag.live : value))
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 6; radius: 3
        color: Theme.raised
        border.width: 1; border.color: Theme.line
        Rectangle {
            width: Math.max(height, track.width * meter.shown); height: parent.height; radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: meter.muted ? Theme.line : Theme.accentDeep }
                GradientStop { position: 1; color: meter.muted ? Theme.muted : Theme.accent }
            }
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
        }
    }
    Rectangle {
        property real d: drag.containsMouse || drag.pressed ? 14 : 10
        width: d; height: d; radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(meter.width - width, meter.width * meter.shown - width / 2))
        color: meter.muted ? Theme.muted : Theme.text
        Behavior on d { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: drag
        property real live: 0
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function at(x) { return Math.max(0, Math.min(1, (x - 4) / meter.width)); }
        onPressed: e => { live = at(e.x); meter.moved(live); }
        onPositionChanged: e => { if (pressed) { live = at(e.x); meter.moved(live); } }
        onWheel: e => meter.moved(Math.max(0, Math.min(1, meter.value + (e.angleDelta.y > 0 ? meter.step : -meter.step))))
    }
}
