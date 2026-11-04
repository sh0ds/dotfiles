import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
// The overview (Super+W): every workspace, one row per monitor, each a
// small copy of the screen with live pictures of its windows where they
// really are. Click a window to go to it, click a workspace to go there,
// drag a window onto another workspace to move it, middle-click closes it.
// Digits jump, arrows walk the workspaces of this monitor, Enter goes,
// Escape (or a click outside) closes.
PanelWindow {
    id: ov
    property bool open: false
    visible: open || fade.running
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "afterhours-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int selected: Hyprland.focusedWorkspace?.id ?? 1
    // The workspace a window is being dragged out of: its tile stops
    // clipping and sits on top, so the window can be carried across.
    property int dragFrom: 0
    onOpenChanged: if (open) {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        selected = Hyprland.focusedWorkspace?.id ?? 1;
        keys.forceActiveFocus();
        zoomLater.restart();
    } else { zoomIn.stop(); zoomFrom = null; ready = false; }

    // The zoom: the workspace you're on starts as big as the screen and
    // shrinks into its tile while the rest fades in around it. Waits one
    // frame so the tiles have their places.
    property Item zoomFrom: null
    property bool ready: false
    Timer { id: zoomLater; interval: 16; onTriggered: ov.zoom() }
    function zoom() {
        const t = zoomFrom;
        zs.xScale = 1; zs.yScale = 1; zt.x = 0; zt.y = 0;
        if (t && t.width > 0) {
            const c = t.mapToItem(board, t.width / 2, t.height / 2);
            const g = t.mapToItem(ov.contentItem, t.width / 2, t.height / 2);
            zs.origin.x = c.x; zs.origin.y = c.y;
            zoomIn.s0 = ov.width / t.width;
            zoomIn.dx = ov.width / 2 - g.x;
            zoomIn.dy = ov.height / 2 - g.y;
            zoomIn.restart();
        }
        ready = true;
    }
    ParallelAnimation {
        id: zoomIn
        property real s0: 1
        property real dx: 0
        property real dy: 0
        NumberAnimation { target: zs; property: "xScale"; from: zoomIn.s0; to: 1; duration: Theme.spring + 80; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
        NumberAnimation { target: zs; property: "yScale"; from: zoomIn.s0; to: 1; duration: Theme.spring + 80; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
        NumberAnimation { target: zt; property: "x"; from: zoomIn.dx; to: 0; duration: Theme.spring + 80; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
        NumberAnimation { target: zt; property: "y"; from: zoomIn.dy; to: 0; duration: Theme.spring + 80; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
    }
    function close() { open = false; }
    function go(id) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })"); close(); }
    function focusWindow(t) { Hyprland.dispatch('hl.dsp.focus({ window = "address:0x' + t.address + '" })'); close(); }
    function moveWindow(t, id) { Hyprland.dispatch('hl.dsp.window.move({ workspace = ' + id + ', follow = false, window = "address:0x' + t.address + '" })'); Hyprland.refreshToplevels(); }
    // A new workspace on a given monitor: focus that monitor first, since a
    // new workspace opens on the focused one.
    function newOn(m) { Hyprland.dispatch('hl.dsp.focus({ monitor = "' + m.name + '" })'); go(firstFree()); }
    function closeWindow(t) { Hyprland.dispatch('hl.dsp.window.close({ window = "address:0x' + t.address + '" })'); }

    // Rows: the main monitor always shows 1-5 (like the rail), every
    // monitor shows its open workspaces; a "+" tile per row opens a new one.
    readonly property var rows: {
        const out = [];
        for (const m of Hyprland.monitors.values) {
            const ids = new Set(m.name === "DP-4" ? [1, 2, 3, 4, 5] : []);
            for (const w of Hyprland.workspaces.values) if (w.id > 0 && w.monitor === m) ids.add(w.id);
            out.push({ monitor: m, ids: [...ids].sort((a, b) => a - b) });
        }
        return out.sort((a, b) => a.monitor.x - b.monitor.x);
    }
    readonly property var here: rows.find(r => r.monitor === Hyprland.focusedMonitor)?.ids ?? []
    function firstFree() { let id = 1; const used = new Set(Hyprland.workspaces.values.map(w => w.id)); while (used.has(id)) id++; return id; }

    Rectangle {
        id: shade
        anchors.fill: parent
        color: Theme.background
        opacity: ov.open ? 0.82 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: Theme.glide; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; onClicked: ov.close() }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ov.close()
        Keys.onReturnPressed: ov.go(ov.selected)
        Keys.onEnterPressed: ov.go(ov.selected)
        Keys.onPressed: e => {
            const i = ov.here.indexOf(ov.selected);
            if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) { ov.go(e.key - Qt.Key_0); e.accepted = true; }
            else if (e.key === Qt.Key_0) { ov.go(10); e.accepted = true; }
            else if ((e.key === Qt.Key_Right || e.key === Qt.Key_L) && i < ov.here.length - 1) { ov.selected = ov.here[i + 1]; e.accepted = true; }
            else if ((e.key === Qt.Key_Left || e.key === Qt.Key_H) && i > 0) { ov.selected = ov.here[i - 1]; e.accepted = true; }
        }
    }

    ColumnLayout {
        id: board
        anchors.centerIn: parent
        spacing: 28
        opacity: ov.open && ov.ready ? 1 : 0
        scale: ov.open ? 1 : 0.97
        transform: [Scale { id: zs }, Translate { id: zt }]
        Behavior on opacity { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "AFTERHOURS / OVERVIEW"
            color: Theme.accent; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 2
        }
        Repeater {
            model: ov.open ? ov.rows : []
            ColumnLayout {
                id: row
                required property var modelData
                readonly property var mon: modelData.monitor
                // Tiles share the screen's shape; five fit across this screen.
                readonly property real tileW: Math.min(320, (ov.width - 120) / Math.max(5, modelData.ids.length + 1) - 16)
                readonly property real tileH: tileW * (mon.height / Math.max(1, mon.width))
                readonly property real k: tileW / Math.max(1, mon.width / Math.max(0.1, mon.scale))
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Text { text: row.mon.name; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 2 }
                Row {
                    spacing: 16
                    Repeater {
                        model: row.modelData.ids
                        Rectangle {
                            id: tile
                            required property int modelData
                            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                            readonly property bool current: row.mon.activeWorkspace?.id === modelData
                            readonly property bool chosen: ov.selected === modelData
                            width: row.tileW; height: row.tileH
                            radius: Theme.radius
                            color: drop.containsDrag ? Theme.accentSoft : Theme.glass
                            border.width: chosen || drop.containsDrag ? 2 : 1
                            border.color: chosen || drop.containsDrag ? Theme.accent : current ? Theme.accentDeep : Theme.edge
                            clip: ov.dragFrom !== modelData
                            z: ov.dragFrom === modelData ? 5 : 0
                            Behavior on color { ColorAnimation { duration: Theme.motion } }
                            Text {
                                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
                                text: tile.modelData
                                color: tile.current ? Theme.accent : Theme.muted
                                font.family: Theme.font; font.pixelSize: 13; font.bold: true
                                z: 2
                            }
                            HoverHandler { id: tileHover; onHoveredChanged: if (hovered) ov.selected = tile.modelData }
                            Component.onCompleted: if (current && row.mon === Hyprland.focusedMonitor) ov.zoomFrom = tile
                            TapHandler { onTapped: ov.go(tile.modelData) }
                            DropArea {
                                id: drop
                                anchors.fill: parent
                                onDropped: d => { if (d.source?.toplevel) ov.moveWindow(d.source.toplevel, tile.modelData); }
                            }
                            // The windows, scaled down to where they sit on the screen.
                            Repeater {
                                model: tile.ws?.toplevels?.values ?? []
                                Item {
                                    id: win
                                    required property var modelData
                                    readonly property var toplevel: modelData
                                    readonly property var ipc: modelData.lastIpcObject ?? {}
                                    readonly property var at: ipc.at ?? [row.mon.x, row.mon.y]
                                    readonly property var size: ipc.size ?? [200, 120]
                                    x: (at[0] - row.mon.x) * row.k
                                    y: (at[1] - row.mon.y) * row.k
                                    width: Math.max(12, size[0] * row.k)
                                    height: Math.max(12, size[1] * row.k)
                                    z: ipc.floating ? 1 : 0
                                    Drag.active: dragger.active
                                    Drag.source: win
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 4
                                        color: Theme.raised
                                        border.width: 1
                                        border.color: winHover.hovered ? Theme.accent : Theme.edge
                                        // A picture of the window, live while the overview is open.
                                        ScreencopyView {
                                            id: shot
                                            anchors.fill: parent; anchors.margins: 1
                                            captureSource: ov.open ? win.toplevel.wayland : null
                                            live: true
                                            visible: hasContent
                                        }
                                        Image {
                                            anchors.centerIn: parent
                                            width: Math.min(28, parent.width * 0.5); height: width
                                            sourceSize: Qt.size(56, 56)
                                            visible: !shot.hasContent
                                            source: {
                                                const e = DesktopEntries.heuristicLookup(win.ipc.class ?? "");
                                                return e?.icon ? Quickshell.iconPath(e.icon, true) : "";
                                            }
                                        }
                                    }
                                    HoverHandler { id: winHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: ov.focusWindow(win.toplevel) }
                                    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: ov.closeWindow(win.toplevel) }
                                    // Lift and carry; snaps back if it isn't dropped on a workspace.
                                    DragHandler {
                                        id: dragger
                                        target: win
                                        onActiveChanged: if (active) ov.dragFrom = tile.modelData; else { ov.dragFrom = 0; win.Drag.drop(); win.x = Qt.binding(() => (win.at[0] - row.mon.x) * row.k); win.y = Qt.binding(() => (win.at[1] - row.mon.y) * row.k); }
                                    }
                                    states: State { when: dragger.active; PropertyChanges { win.z: 10; win.opacity: 0.85 } }
                                }
                            }
                        }
                    }
                    // A new workspace on this monitor.
                    Rectangle {
                        width: row.tileW * 0.4; height: row.tileH
                        radius: Theme.radius
                        color: plusHover.hovered || plusDrop.containsDrag ? Theme.glassRaised : "transparent"
                        border.width: 1; border.color: plusDrop.containsDrag ? Theme.accent : Theme.edge
                        Text { anchors.centerIn: parent; text: "+"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 24 }
                        HoverHandler { id: plusHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: ov.newOn(row.mon) }
                        DropArea { id: plusDrop; anchors.fill: parent; onDropped: d => { if (d.source?.toplevel) ov.moveWindow(d.source.toplevel, ov.firstFree()); } }
                    }
                }
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "click to go  ·  drag to move  ·  middle-click to close  ·  1–0 jump  ·  esc"
            color: Theme.muted; opacity: 0.7; font.family: Theme.font; font.pixelSize: 11
        }
    }
}
