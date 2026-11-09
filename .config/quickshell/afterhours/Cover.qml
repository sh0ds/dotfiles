import QtQuick
// Square cover art, or a violet note on a soft tile while there is none
// (or it is still loading). Used by the island, Today and the media card.
Item {
    id: cover
    property string source: ""
    property int glyphSize: 14
    Rectangle {
        anchors.fill: parent; color: Theme.accentSoft
        visible: art.status !== Image.Ready
        Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.accent; font.family: Theme.font; font.pixelSize: cover.glyphSize }
    }
    Image {
        id: art
        anchors.fill: parent
        source: cover.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(cover.width * 2, cover.height * 2)
        asynchronous: true
    }
}
