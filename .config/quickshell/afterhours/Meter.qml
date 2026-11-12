import QtQuick
// A slim slider: a square track with quarter marks, a violet fill and a diamond that grows on
// hover. Drag, click or scroll; `moved(value)` fires with 0..1 while the
// user changes it, so the caller decides what to do (set a volume, seek).
// `fixed` makes it a plain progress bar: no diamond, no dragging (downloads).
Item {
    id: meter
    property real value: 0
    property bool muted: false
    property real step: 0.05
    property bool fixed: false
    signal moved(real value)
    implicitHeight: 18
    implicitWidth: 200
    readonly property real shown: Math.max(0, Math.min(1, drag.pressed ? drag.live : value))
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 6
        color: Theme.well
        border.width: 1; border.color: Theme.edge
        // Quarter marks, under the fill.
        Repeater {
            model: 3
            Rectangle {
                required property int index
                x: Math.round(track.width * (index + 1) / 4); y: 1
                width: 1; height: track.height - 2
                color: Theme.line
            }
        }
        Rectangle {
            width: meter.fixed ? track.width * meter.shown : Math.max(height, track.width * meter.shown); height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: meter.muted ? Theme.line : Theme.accentDeep }
                GradientStop { position: 1; color: meter.muted ? Theme.muted : Theme.accent }
            }
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
        }
    }
    Rectangle {
        property real d: drag.containsMouse || drag.pressed ? 11 : 8
        // A small diamond, the launcher's ◆.
        width: d; height: d; rotation: 45
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(meter.width - width, meter.width * meter.shown - width / 2))
        color: meter.muted ? Theme.muted : Theme.text
        visible: !meter.fixed
        Behavior on d { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: drag
        property real live: 0
        anchors.fill: parent
        anchors.margins: -4
        enabled: !meter.fixed
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function at(x) { return Math.max(0, Math.min(1, (x - 4) / meter.width)); }
        onPressed: e => { live = at(e.x); meter.moved(live); }
        onPositionChanged: e => { if (pressed) { live = at(e.x); meter.moved(live); } }
        onWheel: e => meter.moved(Math.max(0, Math.min(1, meter.value + (e.angleDelta.y > 0 ? meter.step : -meter.step))))
    }
}
