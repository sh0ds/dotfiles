import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
// The media card under now playing: cover art, title and artist, a
// progress bar you can drag to seek, the controls, and cava large.
// Click outside to close.
PopupWindow {
    id: card
    required property Item target
    property var player: null
    property var bars: []
    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 380
    implicitHeight: body.implicitHeight + 36
    onVisibleChanged: if (visible) { intro.restart(); player?.positionChanged(); }
    function clock(seconds) {
        if (!(seconds >= 0) || !isFinite(seconds)) return "–:––";
        const s = Math.floor(seconds);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
    // MPRIS doesn't announce position changes; ask once a second while open.
    Timer {
        running: card.visible && (card.player?.isPlaying ?? false)
        interval: 1000; repeat: true
        onTriggered: card.player?.positionChanged()
    }
    Rectangle {
        id: box
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.glass
        Sheen {}
        border.width: 1; border.color: Theme.edge
        transformOrigin: Item.Top
        PopIn { id: intro; surface: box; inner: body }
        ColumnLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            spacing: 14
            RowLayout {
                spacing: 16
                Cover {
                    Layout.preferredWidth: 96; Layout.preferredHeight: 96
                    glyphSize: 30
                    source: card.player?.trackArtUrl ?? ""
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: (card.player?.identity ?? "").toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                    Text { text: card.player?.trackTitle || "Nothing playing"; color: Theme.text; font.family: Theme.font; font.pixelSize: 16; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
                    Text { text: card.player?.trackArtist ?? ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; visible: text.length > 0 }
                    Text { text: card.player?.trackAlbum ?? ""; color: Theme.muted; opacity: 0.7; font.family: Theme.font; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; visible: text.length > 0 }
                }
            }
            // cava, large: the same ten bars as the rail, mirrored from a centre line.
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 44
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Repeater {
                        model: 10
                        Rectangle {
                            required property int index
                            readonly property int level: card.player?.isPlaying ? (card.bars[index] ?? 0) : 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; radius: 4
                            height: 4 + level * 5.5
                            opacity: card.player?.isPlaying ? 1 - Math.abs(index - 4.5) / 9 : 0.3
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.accent }
                                GradientStop { position: 1; color: Theme.accentDeep }
                            }
                            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
            // Progress: drag or click to seek when the player allows it.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: (card.player?.lengthSupported ?? false) && (card.player?.length ?? 0) > 0
                Meter {
                    Layout.fillWidth: true
                    value: (card.player?.length ?? 0) > 0 ? (card.player.position / card.player.length) : 0
                    enabled: card.player?.canSeek ?? false
                    step: 0.02
                    onMoved: v => { if (card.player?.canSeek) card.player.position = v * card.player.length; }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: card.clock(card.player?.position ?? 0); color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    Text { text: card.clock(card.player?.length ?? 0); color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Cell {
                    label: ""; size: 14
                    visible: card.player?.shuffleSupported ?? false
                    ink: card.player?.shuffle ? Theme.accent : Theme.muted
                    onClicked: card.player.shuffle = !card.player.shuffle
                }
                Cell { label: ""; size: 14; enabled: card.player?.canGoPrevious ?? false; ink: enabled ? Theme.text : Theme.line; onClicked: card.player.previous() }
                Cell {
                    label: card.player?.isPlaying ? "" : ""; size: 16
                    implicitWidth: 56; selected: true
                    onClicked: if (card.player?.canTogglePlaying) card.player.togglePlaying()
                }
                Cell { label: ""; size: 14; enabled: card.player?.canGoNext ?? false; ink: enabled ? Theme.text : Theme.line; onClicked: card.player.next() }
                Cell {
                    label: ""; size: 14
                    visible: card.player?.loopSupported ?? false
                    ink: (card.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None ? Theme.accent : Theme.muted
                    onClicked: card.player.loopState = card.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                        : card.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                }
            }
        }
    }
}
