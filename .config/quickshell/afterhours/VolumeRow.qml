import QtQuick
// The volume as one row: the speaker (struck through when muted), the
// meter and the percentage. The island lets you drag it; the pill that
// shows while the rail is hidden only displays it.
Row {
    id: vol
    property var sink: null
    property bool interactive: true
    signal moved(real value)
    readonly property real level: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    spacing: 14
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        text: vol.muted ? "\U000f075f" : vol.level < 0.34 ? "\uf026" : vol.level < 0.67 ? "\uf027" : "\uf028"
        color: vol.muted ? Theme.muted : Theme.accent
        font.family: Theme.font; font.pixelSize: 16
    }
    Meter {
        anchors.verticalCenter: parent.verticalCenter
        width: 170
        value: vol.level; muted: vol.muted
        enabled: vol.interactive
        onMoved: v => vol.moved(v)
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        text: vol.muted ? "mute" : Math.round(vol.level * 100) + "%"
        color: vol.muted ? Theme.muted : Theme.text
        font.family: Theme.font; font.pixelSize: 13; font.bold: !vol.muted
        horizontalAlignment: Text.AlignRight
    }
}
