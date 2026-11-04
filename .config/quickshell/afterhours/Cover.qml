import QtQuick
import QtQuick.Effects
// Cover art with rounded corners, or a violet note on a soft tile while
// there is none (or it is still loading). Used by the island, Today and
// the media card.
Item {
    id: cover
    property string source: ""
    property real radius: Theme.radius
    property int glyphSize: 14
    Rectangle { id: shape; anchors.fill: parent; radius: cover.radius; visible: false; layer.enabled: true }
    Rectangle {
        anchors.fill: parent; radius: cover.radius; color: Theme.accentSoft
        Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.accent; font.family: Theme.font; font.pixelSize: cover.glyphSize }
    }
    Image {
        id: art
        anchors.fill: parent
        source: cover.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(cover.width * 2, cover.height * 2)
        asynchronous: true
        visible: false
    }
    MultiEffect { anchors.fill: parent; source: art; visible: art.status === Image.Ready; maskEnabled: true; maskSource: shape }
}
