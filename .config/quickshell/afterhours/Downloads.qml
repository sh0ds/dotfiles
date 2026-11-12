import QtQuick
import QtQuick.Layouts
import Quickshell
// The downloads card under the rail's download cell: everything aria2-rpc
// has (Firefox downloads, dl, torrents), each with a bar, its speed or
// ratio, and pause, folder and remove. A finished name opens the file
// (videos in mpv). Click outside to close.
PopupWindow {
    id: card
    required property Item target
    required property var shell
    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // 8 px under the rail, like the media card.
    anchor.margins.top: 13
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 440
    implicitHeight: body.implicitHeight + 36
    onVisibleChanged: if (visible) { intro.restart(); shell.readDownloads(); }
    function timeLeft(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "";
        const m = Math.ceil(seconds / 60);
        return m < 2 ? "under a minute left" : m < 60 ? m + " min left" : Math.floor(m / 60) + " h " + (m % 60) + " min left";
    }
    function detail(d) {
        const b = shell.bytes;
        const pct = Math.floor(d.progress * 100) + "% of " + b(d.total);
        const peers = d.torrent ? " · " + d.peers + (d.peers === 1 ? " peer" : " peers") : "";
        switch (d.phase) {
        case "metadata": return "Getting the torrent's info" + peers;
        case "down": return [pct, b(d.speed) + "/s", timeLeft((d.total - d.got) / d.speed)].filter(x => x).join(" · ") + peers;
        case "queued": return "Queued · " + b(d.total);
        case "paused": return "Paused · " + pct;
        case "seed": return "Seeding · ratio " + (d.got > 0 ? d.uploaded / d.got : 0).toFixed(2) + " · ↑ " + b(d.up) + "/s" + peers;
        case "done": return "Done · " + b(d.total);
        default: return "Failed: " + (d.error || "aria2 gave no reason");
        }
    }
    Notch {
        id: box
        anchors.fill: parent
        cut: Theme.notchLarge
        color: Theme.glass
        edge: Theme.edge
        transformOrigin: Item.Top
        PopIn { id: intro; surface: box; inner: body }
        ColumnLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Caption { text: "DOWNLOADS" }
                Text {
                    readonly property var all: card.shell.downloadStats
                    visible: all.speed > 0 || all.up > 0
                    text: "↓ " + card.shell.bytes(all.speed) + "/s  ↑ " + card.shell.bytes(all.up) + "/s"
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
                }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: count === 0 ? 44 : Math.min(contentHeight, 6 * 70)
                clip: true
                spacing: 14
                interactive: contentHeight > height
                model: card.shell.downloadRows
                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: card.shell.ariaToken ? "Nothing here. Click a magnet link, or copy one and add it." : "aria2-rpc isn't running."
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
                }
                delegate: ColumnLayout {
                    id: row
                    // The fields readDownloads() builds, by name.
                    required property string gid
                    required property string phase
                    required property bool torrent
                    required property string name
                    required property real total
                    required property real got
                    required property real progress
                    required property real speed
                    required property real up
                    required property real uploaded
                    required property int peers
                    required property string dir
                    required property string path
                    required property string error
                    readonly property bool going: ["down", "metadata", "seed", "queued"].includes(phase)
                    width: ListView.view.width
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: row.torrent ? "" : ""   // nf-fa-magnet, nf-fa-file
                            color: Theme.muted; font.family: Theme.font; font.pixelSize: 12
                        }
                        Text {
                            id: title
                            Layout.fillWidth: true
                            text: row.name
                            color: openPointer.containsMouse ? Theme.accent : Theme.text
                            font.family: Theme.font; font.pixelSize: 13; font.bold: true
                            elide: Text.ElideMiddle; textFormat: Text.PlainText
                            MouseArea {
                                id: openPointer
                                anchors.fill: parent
                                enabled: row.phase === "done" || row.phase === "seed"
                                hoverEnabled: enabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                // A torrent opens its folder or file by its name; a file by its path.
                                onClicked: {
                                    Quickshell.execDetached(["xdg-open", row.torrent ? row.dir + "/" + row.name : row.path]);
                                    card.visible = false;
                                }
                            }
                        }
                        Cell {
                            mirrored: true
                            implicitWidth: 28; implicitHeight: 26
                            visible: row.going || row.phase === "paused"
                            label: row.phase === "paused" ? "" : ""   // play, pause
                            size: 11
                            ink: Theme.muted
                            onClicked: card.shell.aria(row.phase === "paused" ? "aria2.unpause" : "aria2.pause", [row.gid], () => card.shell.readDownloads())
                        }
                        Cell {
                            mirrored: true
                            implicitWidth: 28; implicitHeight: 26
                            visible: row.dir !== ""
                            label: ""   // folder
                            size: 12
                            ink: Theme.muted
                            onClicked: { Quickshell.execDetached(["thunar", row.dir]); card.visible = false; }
                        }
                        Cell {
                            mirrored: true
                            implicitWidth: 28; implicitHeight: 26
                            // Stops it (and its seeding) and drops it from the
                            // list. The files stay where they are.
                            label: "×"
                            size: 14
                            ink: Theme.muted
                            onClicked: card.shell.aria(row.going || row.phase === "paused" ? "aria2.remove" : "aria2.removeDownloadResult", [row.gid], () => card.shell.readDownloads())
                        }
                    }
                    // Square bar in a recessed track: violet while it comes
                    // in, muted once it's there or waiting, coral when it failed.
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 3
                        Rectangle { anchors.fill: parent; color: Theme.well; border.width: 1; border.color: Theme.edge }
                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.max(0, Math.min(1, row.phase === "error" ? 1 : row.progress))
                            color: row.phase === "error" ? Theme.danger : row.phase === "down" || row.phase === "metadata" ? Theme.accent : Theme.muted
                            Behavior on width { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.motion } }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: card.detail(row)
                        color: row.phase === "error" ? Theme.danger : Theme.muted
                        font.family: Theme.font; font.pixelSize: 11
                        elide: Text.ElideRight; textFormat: Text.PlainText
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                // Whatever magnet link or .torrent link is on the clipboard.
                Cell { label: "ADD TORRENT"; size: 11; onClicked: { Quickshell.execDetached(["torrent"]); card.shell.readDownloads(); } }
                Cell { label: "CLEAR FINISHED"; size: 11; onClicked: card.shell.aria("aria2.purgeDownloadResult", [], () => card.shell.readDownloads()) }
                Item { Layout.fillWidth: true }
                Cell { label: "  ~/Downloads"; size: 11; onClicked: { Quickshell.execDetached(["thunar", Quickshell.env("HOME") + "/Downloads"]); card.visible = false; } }
            }
        }
    }
}
