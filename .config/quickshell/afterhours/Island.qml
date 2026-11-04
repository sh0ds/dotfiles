import QtQuick
import Quickshell
import Quickshell.Services.Notifications
// The island in the middle of the rail. At rest it is the clock; it
// stretches into whatever just happened and shrinks back:
//   volume        the level, draggable, while the volume or mute changes
//   notification  app icon, summary and body, one at a time
//   track         cover, title and a little cava when a new song starts
// Only the island on the monitor you're on changes; the others keep the
// time. Click the clock for the dashboard; click a notification to open it
// (its default action, or the inbox), right-click to dismiss it.
Rectangle {
    id: island
    required property var shell
    property bool live: true
    property bool wide: true
    property bool open: false
    property real maxWidth: 560
    readonly property bool hovered: hover.hovered
    signal clockClicked()
    signal trackClicked()

    readonly property var notice: live && shell.toasts.length > 0 ? shell.toasts[0] : null
    readonly property string mode: !live ? "clock"
        : shell.volumePulse ? "volume"
        : notice ? "notice"
        : shell.trackPulse ? "track"
        : "clock"
    readonly property real restWidth: clockFace.content.implicitWidth + 32
    implicitHeight: 42
    width: mode === "volume" ? 300
        : mode === "notice" ? Math.min(maxWidth, Math.max(320, noticeFace.content.implicitWidth + 40))
        : mode === "track" ? Math.min(maxWidth * 0.8, trackFace.content.implicitWidth + 36)
        : restWidth
    // The morph: one spring for the width, so every change reads the same.
    Behavior on width { NumberAnimation { duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
    radius: height / 2
    clip: true
    color: open ? Theme.accentSoft : hover.hovered && mode === "clock" ? Theme.glassRaised : Theme.glass
    Sheen {}
    border.width: 1
    border.color: open ? Theme.accent
        : mode === "notice" && notice?.urgency === NotificationUrgency.Critical ? Theme.danger
        : Theme.edge
    Behavior on color { ColorAnimation { duration: Theme.motion } }
    Behavior on border.color { ColorAnimation { duration: Theme.motion } }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    function closeNotice(n) {
        if (!n) return;
        if (n.transient) n.expire(); else island.shell.dropToast(n);
    }

    // Faces cross-fade: the new one grows in from 92 % as the old one fades.
    component Face: Item {
        property string name
        default property alias faceData: holder.data
        readonly property Item content: holder.children[0] ?? null
        anchors.fill: parent
        readonly property bool on: island.mode === name
        opacity: on ? 1 : 0
        scale: on ? 1 : 0.92
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: on ? Theme.glide : Theme.motion * 0.6; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
        Item { id: holder; anchors.fill: parent }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Face {
        id: clockFace
        name: "clock"
        Row {
            anchors.centerIn: parent
            spacing: 12
            Row {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: Qt.formatDateTime(clock.date, "HH"); color: Theme.text; font.family: Theme.font; font.pixelSize: 18; font.bold: true }
                Text {
                    text: ":"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 18; font.bold: true
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                    }
                }
                Text { text: Qt.formatDateTime(clock.date, "mm"); color: Theme.text; font.family: Theme.font; font.pixelSize: 18; font.bold: true }
            }
            Rectangle { visible: island.wide; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 18; color: Theme.edge }
            Column {
                visible: island.wide
                anchors.verticalCenter: parent.verticalCenter
                spacing: -1
                Text { text: Qt.formatDateTime(clock.date, "dddd").toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 2; font.bold: true }
                Text { text: Qt.formatDateTime(clock.date, "d MMMM"); color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
            }
        }
    }

    Face {
        name: "volume"
        VolumeRow {
            anchors.centerIn: parent
            sink: island.shell.sink
            onMoved: v => { if (island.shell.sink?.audio) { island.shell.sink.audio.volume = v; island.shell.pulseVolume(); } }
        }
    }

    Face {
        id: noticeFace
        name: "notice"
        Row {
            anchors.centerIn: parent
            spacing: 10
            width: Math.min(implicitWidth, island.maxWidth - 40)
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20
                sourceSize: Qt.size(40, 40)
                visible: status === Image.Ready
                source: {
                    const n = island.notice;
                    if (!n) return "";
                    if (n.image) return n.image;
                    const icon = n.appIcon || n.desktopEntry || n.appName.toLowerCase();
                    return icon.startsWith("/") || icon.startsWith("file:") ? icon : Quickshell.iconPath(icon, true);
                }
            }
            Text {
                id: summary
                anchors.verticalCenter: parent.verticalCenter
                text: island.notice?.summary || island.notice?.appName || ""
                color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.bold: true
                textFormat: Text.PlainText
                width: Math.min(implicitWidth, 220); elide: Text.ElideRight
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (island.notice?.body ?? "").replace(/\s+/g, " ")
                visible: text.length > 0
                color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
                textFormat: Text.PlainText
                width: Math.min(implicitWidth, island.maxWidth - 40 - summary.width - 40); elide: Text.ElideRight
            }
        }
        // Each notification gets its time; hovering holds it, critical ones wait.
        Timer {
            id: noticeLife
            readonly property var n: island.notice
            interval: Math.max(1500, (n?.expireTimeout ?? 0) > 0 ? n.expireTimeout : n?.urgency === NotificationUrgency.Low ? 3000 : 5500)
            running: n !== null && n.urgency !== NotificationUrgency.Critical && !hover.hovered
            onTriggered: island.closeNotice(n)
            // The next one in the queue gets its own full time.
            onNChanged: if (running) restart()
        }
    }

    Face {
        id: trackFace
        name: "track"
        Row {
            anchors.centerIn: parent
            spacing: 10
            Cover {
                anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 26; radius: 6; glyphSize: 12
                source: island.shell.player?.trackArtUrl ?? ""
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: island.shell.player?.trackTitle ?? ""
                color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.bold: true
                textFormat: Text.PlainText
                width: Math.min(implicitWidth, 200); elide: Text.ElideRight
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: island.shell.player?.trackArtist ?? ""
                visible: text.length > 0
                color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
                textFormat: Text.PlainText
                width: Math.min(implicitWidth, 140); elide: Text.ElideRight
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: 6
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; radius: 1.5; color: Theme.accent
                        height: 2 + (island.shell.cavaBars[index + 2] ?? 0) * 2
                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Not over the volume face: its meter takes the drag.
    MouseArea {
        anchors.fill: parent
        enabled: island.mode !== "volume"
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (island.mode === "notice") {
                const n = island.notice;
                if (e.button === Qt.RightButton) { island.closeNotice(n); return; }
                const action = n?.actions?.find(a => a.identifier === "default");
                if (action) action.invoke(); else island.shell.toggle("inbox", null);
                island.closeNotice(n);
            } else if (island.mode === "track") island.trackClicked();
            else if (island.mode === "clock") island.clockClicked();
        }
    }
}
