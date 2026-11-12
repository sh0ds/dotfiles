import QtQuick
// Square cover art, or a violet note on a soft tile while there is none
// (or it is still loading). Used by the island, Today and the media card.
// A new cover fades in over the note and settles from 96 %, so a track
// change never flashes.
Item {
    id: cover
    property string source: ""
    property int glyphSize: 14
    Rectangle {
        anchors.fill: parent; color: Theme.accentSoft
        opacity: art.status === Image.Ready ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
        Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.accent; font.family: Theme.font; font.pixelSize: cover.glyphSize }
    }
    Image {
        id: art
        anchors.fill: parent
        source: cover.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(cover.width * 2, cover.height * 2)
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        scale: status === Image.Ready ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
    }
}
