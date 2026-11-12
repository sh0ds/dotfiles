import QtQuick
import QtQuick.Layouts
import Quickshell
// The downloads card under the rail's dl cell, built like the control
// centre: everything aria2-rpc has (Firefox downloads, dl, torrents) in
// three sections, each row with the same bar as the volume (violet while
// it comes in, muted once it's there or paused), and pause, folder and ×
// on hover. A finished name opens the file (videos in mpv). Click outside
// to close.
PopupWindow {
    id: card
    required property Item target
    required property var shell
    // Right edges lined up with the cell, like the control centre.
    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    // 8 px under the rail, like the other cards.
    anchor.margins.top: 13
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 400
    implicitHeight: body.implicitHeight + 36
    onVisibleChanged: if (visible) { intro.restart(); shell.readDownloads(); }
    function timeLeft(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "";
        const m = Math.ceil(seconds / 60);
        return m < 2 ? "under a minute" : m < 60 ? m + " min" : Math.floor(m / 60) + " h " + (m % 60) + " min";
    }
    function detail(d) {
        const b = shell.bytes;
        const peers = d.torrent ? d.peers + (d.peers === 1 ? " peer" : " peers") : "";
        const parts = {
            metadata: ["getting the torrent's info", peers],
            down: [Math.floor(d.progress * 100) + "% of " + b(d.total), b(d.speed) + "/s", timeLeft((d.total - d.got) / d.speed), peers],
            queued: ["queued", b(d.total)],
            paused: ["paused", Math.floor(d.progress * 100) + "% of " + b(d.total)],
            seed: ["ratio " + (d.got > 0 ? d.uploaded / d.got : 0).toFixed(2), "↑ " + b(d.up) + "/s", peers],
            done: [b(d.total)],
        }[d.phase] ?? ["failed: " + (d.error || "aria2 gave no reason")];
        return parts.filter(x => x).join(" · ");
    }
    Notch {
        id: box
        anchors.fill: parent
        cut: Theme.notchLarge
        color: Theme.glass
        edge: Theme.edge
        transformOrigin: Item.TopRight
        PopIn { id: intro; surface: box; inner: body }
        ColumnLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            spacing: 10
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: count === 0 ? emptyText.implicitHeight + 28 : Math.min(contentHeight, 440)
                clip: true
                spacing: 4
                interactive: contentHeight > height
                model: card.shell.downloadRows
                // New rows rise in on the spring, gone ones fade out, the
                // rest glide into their places (a finished one moves down).
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.motion; easing.type: Easing.InCubic }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: Theme.glide; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: Theme.motion }
                    NumberAnimation { property: "scale"; to: 1; duration: Theme.motion }
                }
                move: Transition {
                    NumberAnimation { property: "y"; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
                }
                // A heading per group, the control centre's Caption.
                section.property: "group"
                section.delegate: Item {
                    required property string section
                    width: ListView.view.width
                    implicitHeight: heading.implicitHeight + 12
                    Caption { id: heading; width: parent.width; y: 2; text: parent.section }
                }
                Column {
                    id: emptyText
                    anchors.left: parent.left; anchors.right: parent.right
                    visible: list.count === 0
                    spacing: 10
                    Caption { width: parent.width; text: "DOWNLOADS" }
                    Text {
                        width: parent.width
                        text: card.shell.ariaToken ? "Nothing here. Click a magnet link, or copy one and add it." : "aria2-rpc isn't running."
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                }
                // One row: icon, name, the buttons on hover, the bar, then
                // what it's doing. Square rows that lift on hover with a cut
                // like the control centre's networks.
                delegate: Notch {
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
                    readonly property bool coming: phase === "down" || phase === "metadata"
                    width: ListView.view.width
                    implicitHeight: rowBody.implicitHeight + 16
                    cut: Theme.notchSmall; cutTopRight: false; cutBottomLeft: false
                    color: rowHover.hovered ? Theme.glassRaised : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.motion } }
                    HoverHandler { id: rowHover }
                    ColumnLayout {
                        id: rowBody
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            spacing: 10
                            Text {
                                text: row.torrent ? "" : ""   // nf-fa-magnet, nf-fa-file
                                color: row.coming ? Theme.accent : row.phase === "error" ? Theme.danger : Theme.muted
                                font.family: Theme.font; font.pixelSize: 13
                                Behavior on color { ColorAnimation { duration: Theme.motion } }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.name
                                color: openPointer.containsMouse ? Theme.accent : row.going || row.phase === "paused" ? Theme.text : Theme.muted
                                font.family: Theme.font; font.pixelSize: 12; font.bold: row.coming
                                elide: Text.ElideMiddle; textFormat: Text.PlainText
                                Behavior on color { ColorAnimation { duration: Theme.motion } }
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
                            // The buttons wait for the pointer, so the list reads calm.
                            Row {
                                spacing: 2
                                opacity: rowHover.hovered ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: Theme.motion } }
                                Cell {
                                    implicitWidth: 26; implicitHeight: 24
                                    visible: row.going || row.phase === "paused"
                                    label: row.phase === "paused" ? "" : ""   // play, pause
                                    size: 10
                                    ink: Theme.muted
                                    onClicked: card.shell.aria(row.phase === "paused" ? "aria2.unpause" : "aria2.pause", [row.gid], () => card.shell.readDownloads())
                                }
                                Cell {
                                    implicitWidth: 26; implicitHeight: 24
                                    visible: row.dir !== ""
                                    label: ""   // folder
                                    size: 11
                                    ink: Theme.muted
                                    onClicked: { Quickshell.execDetached(["thunar", row.dir]); card.visible = false; }
                                }
                                // Stops it (and its seeding) and drops it from the list. The files stay.
                                Cell {
                                    implicitWidth: 26; implicitHeight: 24
                                    label: "×"
                                    ink: Theme.muted
                                    onClicked: card.shell.aria(row.going || row.phase === "paused" ? "aria2.remove" : "aria2.removeDownloadResult", [row.gid], () => card.shell.readDownloads())
                                }
                            }
                        }
                        // The volume's bar, read-only: violet while it comes in,
                        // muted while it waits or seeds. Finished and failed
                        // ones have none, the line under the name says it.
                        Meter {
                            Layout.fillWidth: true
                            implicitHeight: 8
                            fixed: true
                            visible: row.phase !== "error" && row.phase !== "done"
                            value: row.progress
                            muted: !row.coming
                            // No size yet (a magnet link asking the swarm):
                            // a short violet run sweeps the track instead.
                            Rectangle {
                                id: sweep
                                visible: row.phase === "metadata"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width / 5; height: 6
                                color: Theme.accent
                                SequentialAnimation on x {
                                    running: sweep.visible && card.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0; to: sweep.parent.width - sweep.width; duration: 1100; easing.type: Easing.InOutCubic }
                                    NumberAnimation { to: 0; duration: 1100; easing.type: Easing.InOutCubic }
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.detail(row)
                            color: row.phase === "error" ? Theme.danger : Theme.muted
                            font.family: Theme.font; font.pixelSize: 10
                            elide: Text.ElideRight; textFormat: Text.PlainText
                        }
                    }
                }
            }
            // Totals, then the buttons, like the control centre's footer.
            Text {
                Layout.fillWidth: true
                readonly property var all: card.shell.downloadStats
                visible: all.speed > 0 || all.up > 0
                text: "↓ " + card.shell.bytes(all.speed) + "/s   ↑ " + card.shell.bytes(all.up) + "/s"
                color: Theme.muted; font.family: Theme.font; font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8
                // Whatever magnet link or .torrent link is on the clipboard.
                Cell { label: "Add torrent"; size: 11; Layout.fillWidth: true; onClicked: { Quickshell.execDetached(["torrent"]); card.shell.readDownloads(); } }
                Cell { label: "Clear finished"; size: 11; Layout.fillWidth: true; onClicked: card.shell.aria("aria2.purgeDownloadResult", [], () => card.shell.readDownloads()) }
                Cell { label: "Open folder"; size: 11; Layout.fillWidth: true; onClicked: { card.shell.run(["thunar", Quickshell.env("HOME") + "/Downloads"]); card.visible = false; } }
            }
        }
    }
}
