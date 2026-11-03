import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

ShellRoot {
    id: root
    property string panel: ""
    property var panelScreen: Quickshell.screens[0] ?? null
    property bool quiet: false
    property bool recording: false
    property bool sharing: false
    property int shareCount: 0
    property bool barVisible: true
    property string volume: "—"
    property string pendingAction: ""
    readonly property var player: Mpris.players.values[0] ?? null
    readonly property var tracks: [
        { name: "PICO-8", tag: "P / 01–08", detail: "Small games. Finish the cart.", command: ["game-dev", "pico"] },
        { name: "PICOTRON", tag: "T / 01–04", detail: "Tools, worlds, more room.", command: ["game-dev", "picotron"] },
        { name: "GODOT", tag: "G / 01–11", detail: "Zelda-like → metroidvania.", command: ["game-dev", "godot"] },
        { name: "PIXEL ART", tag: "A / 01–02", detail: "Silhouette, palette, motion.", command: ["game-dev", "art"] },
        { name: "SOUND", tag: "A / 03–04", detail: "PICO-8 tracker first. Your own loops.", command: ["game-dev", "audio"] },
        { name: "C + LUA", tag: "X / 01–08", detail: "Your engine. Your rules.", command: ["game-dev", "code"] },
        { name: "DEVLOG", tag: "W + F", detail: "Build the site. Show the work.", command: ["game-dev", "site"] },
        { name: "THE PLAN", tag: "NEXT STEP", detail: "45 minutes counts. Make it small.", command: ["game-dev", "plan"] }
    ]
    function run(command) { Quickshell.execDetached(command); panel = ""; pendingAction = ""; }
    function toggle(name, screen) {
        if (!["studio", "apps", "inbox", "session"].includes(name)) return;
        panelScreen = screen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        panel = panel === name ? "" : name;
        pendingAction = "";
    }
    function workspace(number) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + number + " })"); }
    IpcHandler {
        target: "shell"
        function status(): string {
            return JSON.stringify({ panel: root.panel, notifications: notices.trackedNotifications.values.length, bars: root.barVisible, quiet: root.quiet });
        }
        function toggle(name: string): void { root.toggle(name, null); }
        function toggleBar(): void { root.barVisible = !root.barVisible; }
        function close(): void { root.panel = ""; }
        function quietMode(enabled: bool): void { root.quiet = enabled; }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    // wpctl is locale-pinned; nothing is interpolated into a shell command.
    Process {
        id: volumeRead
        command: ["env", "LC_ALL=C", "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { onStreamFinished: {
            const match = text.match(/Volume:\s+([0-9.]+)/);
            root.volume = match ? (text.includes("MUTED") ? "mute" : Math.round(Number(match[1]) * 100) + "%") : "—";
        } }
    }
    Process { id: captureRead; command: ["pgrep", "-x", "wf-recorder"]; onExited: (code) => root.recording = code === 0 }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "screencastv2") return;
            root.shareCount = Math.max(0, root.shareCount + (event.data.split(",")[0] === "1" ? 1 : -1));
            root.sharing = root.shareCount > 0;
        }
    }
    Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true; onTriggered: {
        if (!volumeRead.running) volumeRead.running = true;
        if (!captureRead.running) captureRead.running = true;
    } }
    NotificationServer {
        id: notices
        actionsSupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        onNotification: notification => {
            notification.tracked = true;
            // Bound session history, so a noisy client cannot grow it forever.
            const entries = trackedNotifications.values;
            if (entries.length > 50) entries[0].dismiss();
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: rail
            required property var modelData
            screen: modelData
            visible: root.barVisible
            WlrLayershell.namespace: "afterhours-rail"
            anchors { top: true; left: true; right: true }
            implicitHeight: 46
            color: Theme.background
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 14
                spacing: 8
                Cell { label: rail.width < 900 ? "▦" : "▦  sh0ds·16"; ink: Theme.accent; hint: "Make / Play / Ship · Super+Ctrl+G"; onClicked: root.toggle("studio", rail.screen) }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 20; color: Theme.line }
                Repeater {
                    model: rail.width > 650 ? 5 : 3
                    Cell {
                        required property int index
                        label: rail.width > 1050 ? ["01 CODE", "02 PLAY", "03 CRAFT", "04 NOTES", "05 GAMES"][index] : String(index + 1).padStart(2, "0")
                        selected: Hyprland.monitorFor(rail.screen)?.activeWorkspace?.id === index + 1
                        onClicked: root.workspace(index + 1)
                    }
                }
                Item { Layout.fillWidth: true }
                Cell {
                    visible: root.recording || root.sharing
                    label: root.sharing ? "● LIVE" : "● REC"; ink: Theme.danger
                    hint: "Click to stop recording"
                    onClicked: root.run(["rec-toggle"])
                }
                Cell {
                    visible: rail.width > 1350 && root.player !== null
                    label: root.player ? root.player.trackTitle.slice(0, 22) : ""
                    ink: Theme.blue
                    hint: "Play / pause"
                    onClicked: { if (root.player?.canTogglePlaying) root.player.togglePlaying(); }
                }
                Cell { label: (rail.width > 900 ? "vol " : "") + root.volume; hint: "Sound controls"; onClicked: root.run(["pavucontrol"]) }
                Cell {
                    label: (rail.width > 900 ? (root.quiet ? "quiet " : "inbox ") : "✉ ") + notices.trackedNotifications.values.length
                    ink: root.quiet ? Theme.amber : Theme.muted
                    onClicked: root.toggle("inbox", rail.screen)
                }
                Repeater {
                    model: rail.width > 900 ? SystemTray.items : null
                    Rectangle {
                        id: trayItem
                        required property var modelData
                        implicitWidth: 28; implicitHeight: 30; color: "transparent"
                        Image { anchors.centerIn: parent; width: 18; height: 18; source: trayItem.modelData.icon }
                        MouseArea {
                            id: trayPointer
                            anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton; hoverEnabled: true
                            onClicked: event => {
                                if (event.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                    const pos = trayItem.mapToItem(rail.contentItem, 0, trayItem.height);
                                    trayItem.modelData.display(rail, Math.round(pos.x), Math.round(pos.y));
                                } else if (event.button === Qt.MiddleButton) trayItem.modelData.secondaryActivate();
                                else trayItem.modelData.activate();
                            }
                            onWheel: event => trayItem.modelData.scroll(event.angleDelta.y, false)
                        }
                        ToolTip.visible: trayPointer.containsMouse
                        ToolTip.text: modelData.tooltipTitle || modelData.title
                    }
                }
                Text { text: Qt.formatDateTime(clock.date, rail.width > 1050 ? "ddd  dd MMM   HH:mm" : "HH:mm"); color: Theme.text; font.family: Theme.mono; font.pixelSize: 12 }
                Cell { label: "⏻"; hint: "Session controls"; onClicked: root.toggle("session", rail.screen) }
            }
        }
    }
    // One keyboard-driven overlay on the chosen output. Escape and outside click dismiss it.
    PanelWindow {
        id: overlay
        visible: root.panel !== ""
        screen: root.panelScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "#99141613"
        WlrLayershell.namespace: "afterhours-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        MouseArea { anchors.fill: parent; onClicked: root.panel = "" }
        Rectangle {
            id: sheet
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 820)
            height: Math.min(parent.height - 100, 660)
            color: Theme.panel
            border.color: Theme.line; border.width: 1
            radius: 4
            Keys.onEscapePressed: root.panel = ""
            // Prevent clicks on the sheet reaching the outside-click handler.
            MouseArea { anchors.fill: parent }
            NumberAnimation on opacity { from: 0; to: 1; duration: Theme.motion; running: overlay.visible }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 16
                RowLayout {
                    Text { text: "AFTERHOURS / " + root.panel.toUpperCase(); color: Theme.accent; font.family: Theme.mono; font.pixelSize: 12; font.letterSpacing: 2 }
                    Item { Layout.fillWidth: true }
                    Cell { label: "ESC  ×"; onClicked: root.panel = "" }
                }
                Text {
                    text: root.panel === "studio" ? "MAKE. PLAY. SHIP." : root.panel === "apps" ? "OPEN SOMETHING." : root.panel === "inbox" ? "INCOMING." : "END OF SESSION."
                    color: Theme.text; font.family: Theme.display; font.pixelSize: sheet.width < 600 ? 32 : 46
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }
                StackLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    currentIndex: ({studio: 0, apps: 1, inbox: 2, session: 3})[root.panel] ?? 0
                    RowLayout {
                        spacing: 26
                        ListView {
                            id: trackMenu
                            Layout.minimumWidth: 270; Layout.preferredWidth: 400
                            Layout.fillWidth: true; Layout.fillHeight: true
                            clip: true; spacing: 2
                            model: root.tracks
                            currentIndex: 0
                            keyNavigationEnabled: true
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_End) { currentIndex = count - 1; event.accepted = true; }
                                else if (event.key === Qt.Key_Home) { currentIndex = 0; event.accepted = true; }
                            }
                            Keys.onReturnPressed: root.run(root.tracks[currentIndex].command)
                            Keys.onSpacePressed: root.run(root.tracks[currentIndex].command)
                            Keys.onEscapePressed: root.panel = ""
                            delegate: Rectangle {
                                id: track
                                required property var modelData
                                required property int index
                                width: trackMenu.width; height: 44
                                readonly property bool chosen: trackMenu.currentIndex === index
                                color: chosen ? Theme.raised : "transparent"
                                radius: 2
                                Behavior on color { ColorAnimation { duration: Theme.motion } }
                                Rectangle { width: 3; height: parent.height; color: Theme.accent; visible: track.chosen }
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 12; spacing: 12
                                    Text { text: String(track.index + 1).padStart(2, "0"); color: track.chosen ? Theme.accent : Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                                    Text { text: track.modelData.name; color: track.chosen ? Theme.accent : Theme.text; font.family: Theme.mono; font.pixelSize: 16; font.bold: track.chosen; Layout.fillWidth: true }
                                    Text { text: track.chosen ? "◂" : "·"; color: track.chosen ? Theme.accent : Theme.line; font.family: Theme.mono; font.pixelSize: 18 }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: trackMenu.currentIndex = track.index
                                    onClicked: root.run(track.modelData.command)
                                }
                            }
                        }
                        Rectangle { visible: sheet.width > 600; Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.line }
                        ColumnLayout {
                            visible: sheet.width > 600
                            Layout.minimumWidth: 0; Layout.preferredWidth: 280; Layout.maximumWidth: 280; Layout.fillHeight: true
                            spacing: 16
                            Text { text: "SELECT / 0" + (trackMenu.currentIndex + 1); color: Theme.blue; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
                            Item {
                                visible: sheet.height > 580
                                Layout.fillWidth: true; Layout.fillHeight: true
                                Canvas {
                                    anchors.centerIn: parent; width: 160; height: 160
                                    onPaint: {
                                        const c = getContext("2d");
                                        c.clearRect(0,0,width,height);
                                        // A hand-drawn 16×16 dungeon key: the plan's rooms and gates.
                                        const pixels = ["................","....oooo........","...o....o.......","..o..xx..o......","..o..xx..o......","...o....o.......","....oooo........","......oo........","......oo........","......oooooo....","......oo..oo....","......oo........","......oooo......","......oooo......","................","................"];
                                        for (let y=0;y<16;y++) for (let x=0;x<16;x++) {
                                            c.fillStyle = pixels[y][x] === "x" ? Theme.blue : Theme.accent;
                                            if (pixels[y][x] !== ".") c.fillRect(x*10,y*10,9,9);
                                        }
                                    }
                                }
                            }
                            Text { text: root.tracks[trackMenu.currentIndex].tag; color: Theme.blue; font.family: Theme.mono; font.pixelSize: 12 }
                            Text { text: root.tracks[trackMenu.currentIndex].detail; color: Theme.text; font.family: Theme.display; font.pixelSize: 25; wrapMode: Text.WordWrap; Layout.minimumWidth: 0; Layout.fillWidth: true }
                            Text { text: "↑ ↓  SELECT    ↵  OPEN"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10 }
                        }
                    }
                    ColumnLayout {
                        TextField {
                            id: query
                            Layout.fillWidth: true
                            placeholderText: "Find an application…"
                            font.family: Theme.mono; font.pixelSize: 16; color: Theme.text
                            background: Rectangle { color: Theme.background; border.color: query.activeFocus ? Theme.accent : Theme.line; radius: 3 }
                            Keys.onEscapePressed: root.panel = ""
                            onTextChanged: appList.currentIndex = 0
                            Keys.onDownPressed: appList.incrementCurrentIndex()
                            Keys.onUpPressed: appList.decrementCurrentIndex()
                            function launchCurrent() {
                                const app = appList.model[Math.max(0, appList.currentIndex)];
                                if (app) { app.execute(); root.panel = ""; }
                            }
                            Keys.onReturnPressed: launchCurrent()
                            Keys.onEnterPressed: launchCurrent()
                            onAccepted: launchCurrent()
                        }
                        ListView {
                            id: appList
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                            model: DesktopEntries.applications.values.filter(app => !app.noDisplay && (app.name + " " + app.genericName).toLowerCase().includes(query.text.toLowerCase())).sort((a,b) => a.name.localeCompare(b.name))
                            delegate: Rectangle {
                                id: appRow
                                required property var modelData
                                required property int index
                                width: appList.width; height: 42
                                color: appList.currentIndex === index ? Theme.raised : "transparent"
                                Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: appRow.modelData.name; color: Theme.text; font.family: Theme.sans; font.pixelSize: 14; textFormat: Text.PlainText }
                                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: appList.currentIndex = appRow.index; onClicked: { appRow.modelData.execute(); root.panel = ""; } }
                            }
                        }
                    }
                    ColumnLayout {
                        RowLayout {
                            Cell { label: root.quiet ? "QUIET: ON" : "QUIET: OFF"; selected: root.quiet; onClicked: root.quiet = !root.quiet }
                            Cell { label: "CLEAR ALL"; onClicked: { for (const n of notices.trackedNotifications.values.slice()) n.dismiss(); } }
                        }
                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 10
                            model: notices.trackedNotifications
                            delegate: Notice { required property var modelData; notification: modelData; width: ListView.view.width }
                            Text { anchors.centerIn: parent; visible: notices.trackedNotifications.values.length === 0; text: "Nothing waiting. Back to the game."; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 12 }
                        }
                    }
                    ColumnLayout {
                        spacing: 12
                        Text { text: "Save your work. Destructive actions need a second click."; color: Theme.muted; font.family: Theme.sans; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        Repeater {
                            model: [ {label:"LOCK",cmd:["hyprlock"]}, {label:"SUSPEND",cmd:["afterhours-suspend"]}, {label:"LOG OUT",cmd:["power","logout"]}, {label:"REBOOT",cmd:["power","reboot"]}, {label:"POWER OFF",cmd:["power","poweroff"]} ]
                            Cell {
                                required property var modelData
                                label: root.pendingAction === modelData.label ? "CONFIRM " + modelData.label : modelData.label
                                ink: root.pendingAction === modelData.label ? Theme.danger : Theme.text
                                Layout.fillWidth: true
                                onClicked: {
                                    if (modelData.label === "LOCK" || root.pendingAction === modelData.label) root.run(modelData.cmd);
                                    else root.pendingAction = modelData.label;
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
                RowLayout {
                    Text { text: "45 MINUTES COUNTS / FINISHED BEATS BIG"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                    Cell { label: "ALL APPS →"; onClicked: root.panel = "apps" }
                }
            }
        }
        Connections { target: root; function onPanelChanged() { if (root.panel === "apps") { query.text = ""; query.forceActiveFocus(); } else if (root.panel === "studio") trackMenu.forceActiveFocus(); else sheet.forceActiveFocus(); } }
        // Capture all unhandled Escape presses, including while a text field is focused.
        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: root.panel = "" }
    }
    // Passive toasts never steal keyboard focus. Quiet mode preserves inbox history.
    PanelWindow {
        visible: !root.quiet && !root.sharing && notices.trackedNotifications.values.length > 0 && root.panel !== "inbox"
        screen: root.panelScreen
        WlrLayershell.namespace: "afterhours-toast"
        anchors { top: true; right: true }
        margins { top: 60; right: 16 }
        implicitWidth: Math.min(380, (screen?.width ?? 400) - 32)
        implicitHeight: toastColumn.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        Column {
            id: toastColumn; width: parent.width; spacing: 8
            Repeater {
                model: notices.trackedNotifications.values.slice(-3)
                Notice { required property var modelData; notification: modelData; width: toastColumn.width; toast: true }
            }
        }
    }
}
