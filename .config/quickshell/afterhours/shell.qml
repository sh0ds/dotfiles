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
    // The Pi (site, backups, takt) answers a ping: checked every 30 s.
    property bool piUp: false
    readonly property string piHost: Quickshell.env("PI_HOST") || "192.168.178.36"
    property string pendingAction: ""
    // Toasts on screen now, newest last. A notification leaves the toasts
    // after its timeout but stays in the inbox until dismissed.
    property var toasts: []
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    // frame (the window border) and other scripts read these flag files.
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    function flag(name, on) { Quickshell.execDetached(on ? ["touch", runDir + "/" + name] : ["rm", "-f", runDir + "/" + name]); }
    onQuietChanged: flag("diag-dnd", quiet)
    onSharingChanged: { flag("diag-live", sharing); if (sharing) toasts = []; }
    onPanelChanged: if (panel === "inbox") toasts = []
    // A share can't be running before the shell starts listening for it, so a
    // leftover flag from a crashed shell is cleared (frame would stay coral).
    Component.onCompleted: flag("diag-live", false)
    function dropToast(n) { toasts = toasts.filter(t => t !== n); }
    // KDE Connect mirrors WhatsApp from the phone; nchat already alerts for
    // those (chat-notify), so the copies are dropped. Other phone apps stay.
    function mirrored(n) {
        return /^(kde\s*connect|kdeconnect(d|\.daemon)?)$/i.test(n.appName) && /^whatsapp( business)?$/i.test(n.summary);
    }
    readonly property var tracks: [
        { name: "PICO-8", tag: "P / 01–08", detail: "Small games. Finish the cart.", command: ["game-dev", "pico"] },
        { name: "PICOTRON", tag: "T / 01–04", detail: "Tools, worlds, more room.", command: ["game-dev", "picotron"] },
        { name: "GODOT", tag: "G / 01–11", detail: "Zelda-like → metroidvania.", command: ["game-dev", "godot"] },
        { name: "PIXEL ART", tag: "A / 01–02", detail: "Silhouette, palette, motion.", command: ["game-dev", "art"] },
        { name: "SOUND", tag: "A / 03–04", detail: "PICO-8 tracker first. Your own loops.", command: ["game-dev", "audio"] },
        { name: "C + LUA", tag: "X / 01–08", detail: "Your engine. Your rules.", command: ["game-dev", "code"] },
        { name: "DEVLOG", tag: "W + F", detail: "Build the site. Show the work.", command: ["game-dev", "site"] },
        { name: "THE PLAN", tag: "NEXT STEP", detail: "45 minutes is a whole day. Show up.", command: ["game-dev", "plan"] }
    ]
    function run(command) { Quickshell.execDetached(command); panel = ""; pendingAction = ""; }
    function toggle(name, screen) {
        if (!["studio", "apps", "inbox", "session"].includes(name)) return;
        panelScreen = screen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        panel = panel === name ? "" : name;
        pendingAction = "";
    }
    function workspace(number) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + number + " })"); }
    // DP-4 always shows 1-5; every screen also lists its own open workspaces.
    function workspaceIds(screen) {
        const name = screen?.name ?? "";
        const ids = new Set(name === "DP-4" ? [1, 2, 3, 4, 5] : []);
        for (const w of Hyprland.workspaces.values) if (w.id > 0 && w.monitor?.name === name) ids.add(w.id);
        return [...ids].sort((a, b) => a - b);
    }
    // Quiet survives a restart of the shell through its flag file.
    Process {
        running: true
        command: ["test", "-e", root.runDir + "/diag-dnd"]
        onExited: code => root.quiet = code === 0
    }
    IpcHandler {
        target: "shell"
        function status(): string {
            return JSON.stringify({ panel: root.panel, notifications: notices.trackedNotifications.values.length, bars: root.barVisible, quiet: root.quiet });
        }
        function toggle(name: string): void { root.toggle(name, null); }
        function toggleBar(): void { root.barVisible = !root.barVisible; }
        function close(): void { root.panel = ""; }
        function quietMode(enabled: bool): void { root.quiet = enabled; }
        function quiet(): string { return root.quiet ? "true" : "false"; }
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
    // cava, only while something plays: eight bars, 0-7 each, one line per
    // frame (.config/cava/rail). Without cava the bars just stay flat.
    property var cavaBars: [0, 0, 0, 0, 0, 0, 0, 0]
    Process {
        id: cava
        running: root.player?.isPlaying ?? false
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/rail"]
        stdout: SplitParser {
            onRead: line => {
                const bars = line.split(";").filter(v => v !== "").map(Number);
                if (bars.length === 8) root.cavaBars = bars;
            }
        }
        onRunningChanged: if (!running) root.cavaBars = [0, 0, 0, 0, 0, 0, 0, 0]
    }
    // System readings for the rail's sys cell (sys-stats), sampled every 2 s
    // only while the cell is unfolded.
    property bool statsOpen: false
    property var stats: null
    Process {
        id: statsRead
        command: ["sys-stats"]
        stdout: StdioCollector { onStreamFinished: {
            const v = text.trim().split(/\s+/);
            if (v.length === 4) root.stats = { cpu: v[0], mem: v[1], temp: v[2], gpu: v[3] };
        } }
    }
    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: root.statsOpen; onTriggered: if (!statsRead.running) statsRead.running = true }
    Process { id: piPing; command: ["ping", "-c", "1", "-W", "1", root.piHost]; onExited: code => root.piUp = code === 0 }
    Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!piPing.running) piPing.running = true }
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
            if (root.mirrored(notification)) return;
            notification.tracked = true;
            notification.closed.connect(() => root.dropToast(notification));
            const critical = notification.urgency === NotificationUrgency.Critical;
            if (root.panel !== "inbox" && ((!root.quiet && !root.sharing) || critical))
                root.toasts = [...root.toasts.filter(t => t !== notification), notification].slice(-3);
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
            // Floats 8 px down and 12 px in, lined up with the window gaps.
            margins { top: 8; left: 12; right: 12 }
            implicitHeight: 42
            color: "transparent"
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                color: Theme.panel
                border.width: 1
                border.color: Theme.line
            }
            // The clock island in the middle of the rail: a raised pill with
            // the time large (its colon breathes in violet, once a second),
            // a hairline, then the weekday over the date. Click: calendar.
            Rectangle {
                id: clockCell
                z: 1
                anchors.centerIn: parent
                height: 34
                width: clockRow.implicitWidth + 28
                radius: height / 2
                color: calendar.visible ? Theme.accentSoft : clockHover.hovered ? Theme.raised : Theme.background
                border.width: 1
                border.color: calendar.visible ? Theme.accent : Theme.line
                Behavior on color { ColorAnimation { duration: Theme.motion } }
                Behavior on border.color { ColorAnimation { duration: Theme.motion } }
                Row {
                    id: clockRow
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
                    Rectangle { visible: rail.width > 900; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 18; color: Theme.line }
                    Column {
                        visible: rail.width > 900
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -1
                        Text { text: Qt.formatDateTime(clock.date, "dddd").toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 2; font.bold: true }
                        Text { text: Qt.formatDateTime(clock.date, "d MMMM"); color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
                HoverHandler { id: clockHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: calendar.visible = !calendar.visible }
                ToolTip.visible: clockHover.hovered && !calendar.visible
                ToolTip.delay: 650
                ToolTip.text: "Calendar"
            }
            Calendar { id: calendar; target: clockCell }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                spacing: 4
                Cell { label: "\uf303"; size: 16; implicitWidth: 38; ink: Theme.accent; hint: "Apps · Super+Space"; onClicked: root.toggle("apps", rail.screen) }
                // Workspaces: plain numbers in a soft track. The active one is a
                // wider violet pill that glides over; numbers with windows on
                // them are bright, empty ones dim, urgent ones amber. Hover lifts
                // a number, the wheel steps through them.
                Item {
                    id: spaces
                    readonly property int active: Hyprland.monitorFor(rail.screen)?.activeWorkspace?.id ?? -1
                    readonly property var ids: root.workspaceIds(rail.screen).slice(0, rail.width > 650 ? 10 : 3)
                    property real markX: 0
                    property real markW: 0
                    implicitWidth: spaceRow.implicitWidth + 8
                    implicitHeight: 30
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.background
                        border.width: 1
                        border.color: Theme.line
                    }
                    Rectangle {
                        x: spaces.markX + 4; y: 4
                        width: spaces.markW; height: parent.height - 8
                        visible: spaces.markW > 0
                        radius: height / 2
                        color: Theme.accent
                        Behavior on x { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
                    }
                    Row {
                        id: spaceRow
                        x: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: spaces.ids
                            Item {
                                id: space
                                required property int modelData
                                readonly property bool here: modelData === spaces.active
                                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                                readonly property bool used: (ws?.toplevels?.values?.length ?? 0) > 0
                                width: here ? 38 : 24
                                height: 22
                                Behavior on width { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 22; height: 22; radius: 11
                                    color: Theme.raised
                                    opacity: !space.here && pointerHover.hovered ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.motion } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: space.modelData
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.bold: space.here || space.used
                                    color: space.here ? Theme.background
                                        : space.ws?.urgent ? Theme.amber
                                        : space.used || pointerHover.hovered ? Theme.text : Theme.muted
                                    opacity: space.here || space.used || pointerHover.hovered || space.ws?.urgent ? 1 : 0.5
                                    Behavior on color { ColorAnimation { duration: Theme.motion } }
                                }
                                HoverHandler { id: pointerHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.workspace(space.modelData) }
                                Binding { target: spaces; property: "markX"; value: space.x; when: space.here; restoreMode: Binding.RestoreNone }
                                Binding { target: spaces; property: "markW"; value: space.width; when: space.here; restoreMode: Binding.RestoreNone }
                            }
                        }
                    }
                    WheelHandler { onWheel: e => root.workspace(e.angleDelta.y > 0 ? '"e-1"' : '"e+1"') }
                }
                Text {
                    id: windowTitle
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.maximumWidth: Math.max(0, clockCell.x - windowTitle.x - 24)
                    visible: rail.width > 1050
                    text: Hyprland.activeToplevel?.title ?? ""
                    color: Theme.muted
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.family: Theme.font; font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Cell {
                    visible: root.recording || root.sharing
                    label: root.sharing ? "● LIVE" : "● REC"; ink: Theme.danger
                    hint: root.recording ? "Click to stop recording" : "Sharing your screen: popups are held back"
                    onClicked: if (root.recording) root.run(["rec-toggle"])
                }
                Cell {
                    visible: rail.width > 1350 && root.player !== null
                    label: root.player ? root.player.trackTitle.slice(0, 26) : ""
                    ink: root.player?.isPlaying ? Theme.text : Theme.muted
                    // cava's bars in violet, flat while paused.
                    Repeater {
                        model: root.cavaBars
                        Rectangle {
                            required property int modelData
                            anchors.bottom: parent.bottom
                            width: 3; radius: 1.5
                            height: 3 + modelData * 2
                            color: Theme.accent
                            opacity: root.player?.isPlaying ? 0.95 : 0.35
                            Behavior on height { NumberAnimation { duration: 60 } }
                        }
                    }
                    hint: "Play / pause"
                    onClicked: { if (root.player?.canTogglePlaying) root.player.togglePlaying(); }
                }
                // sys: click unfolds cpu, memory, temperature and gpu; right-click opens btop.
                Cell {
                    visible: rail.width > 900
                    readonly property var s: root.stats
                    label: !root.statsOpen ? "sys"
                        : !s ? "…"
                        : "cpu " + s.cpu + "%  mem " + s.mem + "G" + (s.temp !== "-" ? "  " + s.temp + "°" : "") + (s.gpu !== "-" ? "  gpu " + s.gpu + "%" : "")
                    ink: !root.statsOpen ? Theme.muted
                        : s && (Number(s.cpu) >= 90 || Number(s.temp) >= 85) ? Theme.amber : Theme.text
                    hint: root.statsOpen ? "Click to fold · right-click: btop" : "Click: cpu, memory, temperature, gpu · right-click: btop"
                    onClicked: { root.statsOpen = !root.statsOpen; if (!root.statsOpen) root.stats = null; }
                    onRightClicked: root.run(["sysmon"])
                }
                Cell {
                    visible: rail.width > 900
                    label: "\uf315"   // nf-linux-raspberry_pi
                    size: 16
                    ink: root.piUp ? Theme.accent : Theme.danger
                    hint: "Raspberry Pi " + root.piHost + (root.piUp ? " is up · click: ssh" : " is not answering")
                    onClicked: root.run(["kitty", "-e", "ssh", "pi"])
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
                        implicitWidth: 30; implicitHeight: 32
                        radius: Theme.radius
                        color: trayPointer.containsMouse ? Theme.raised : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.motion } }
                        Image { anchors.centerIn: parent; width: 16; height: 16; sourceSize: Qt.size(32, 32); source: trayItem.modelData.icon }
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
        color: "transparent"
        WlrLayershell.namespace: "afterhours-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        Rectangle {
            anchors.fill: parent
            color: Theme.background
            opacity: overlay.visible ? 0.6 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
        }
        MouseArea { anchors.fill: parent; onClicked: root.panel = "" }
        Rectangle {
            id: sheet
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 820)
            height: Math.min(parent.height - 100, 660)
            color: Theme.panel
            border.color: Theme.line; border.width: 1
            radius: Theme.radiusLarge
            Keys.onEscapePressed: root.panel = ""
            // Prevent clicks on the sheet reaching the outside-click handler.
            MouseArea { anchors.fill: parent }
            // Grows in from 96 % while it fades in.
            ParallelAnimation {
                running: overlay.visible
                NumberAnimation { target: sheet; property: "opacity"; from: 0; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
                NumberAnimation { target: sheet; property: "scale"; from: 0.96; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 16
                RowLayout {
                    Text { text: "AFTERHOURS / " + root.panel.toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 2 }
                    Item { Layout.fillWidth: true }
                    Cell { label: "ESC  ×"; onClicked: root.panel = "" }
                }
                Text {
                    text: root.panel === "studio" ? "MAKE. PLAY. SHIP." : root.panel === "apps" ? "OPEN SOMETHING." : root.panel === "inbox" ? "INCOMING." : "END OF SESSION."
                    color: Theme.text; font.family: Theme.font; font.pixelSize: sheet.width < 600 ? 32 : 46
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
                                radius: Theme.radius
                                Behavior on color { ColorAnimation { duration: Theme.motion } }
                                Rectangle { x: 4; y: 10; width: 3; height: parent.height - 20; radius: 2; color: Theme.accent; opacity: track.chosen ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.motion } } }
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 12; spacing: 12
                                    Text { text: String(track.index + 1).padStart(2, "0"); color: track.chosen ? Theme.accent : Theme.muted; font.family: Theme.font; font.pixelSize: 11 }
                                    Text { text: track.modelData.name; color: track.chosen ? Theme.accent : Theme.text; font.family: Theme.font; font.pixelSize: 16; font.bold: track.chosen; Layout.fillWidth: true }
                                    Text { text: track.chosen ? "◂" : "·"; color: track.chosen ? Theme.accent : Theme.line; font.family: Theme.font; font.pixelSize: 18 }
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
                            Text { text: "SELECT / 0" + (trackMenu.currentIndex + 1); color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 2 }
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
                                            c.fillStyle = pixels[y][x] === "x" ? Theme.amber : Theme.accent;
                                            if (pixels[y][x] !== ".") c.fillRect(x*10,y*10,9,9);
                                        }
                                    }
                                }
                            }
                            Text { text: root.tracks[trackMenu.currentIndex].tag; color: Theme.accent; font.family: Theme.font; font.pixelSize: 12 }
                            Text { text: root.tracks[trackMenu.currentIndex].detail; color: Theme.text; font.family: Theme.font; font.pixelSize: 25; wrapMode: Text.WordWrap; Layout.minimumWidth: 0; Layout.fillWidth: true }
                            Text { text: "↑ ↓  SELECT    ↵  OPEN"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                        }
                    }
                    ColumnLayout {
                        TextField {
                            id: query
                            Layout.fillWidth: true
                            placeholderText: "Find an application…"
                            font.family: Theme.font; font.pixelSize: 16; color: Theme.text
                            leftPadding: 14; topPadding: 10; bottomPadding: 10
                            background: Rectangle { color: Theme.background; border.color: query.activeFocus ? Theme.accent : Theme.line; radius: Theme.radius; Behavior on border.color { ColorAnimation { duration: Theme.motion } } }
                            Keys.onEscapePressed: root.panel = ""
                            onTextChanged: appList.currentIndex = 0
                            Keys.onDownPressed: appList.incrementCurrentIndex()
                            Keys.onUpPressed: appList.decrementCurrentIndex()
                            function launchCurrent() {
                                const app = appList.model.values[Math.max(0, appList.currentIndex)];
                                if (app) { app.execute(); root.panel = ""; }
                            }
                            Keys.onReturnPressed: launchCurrent()
                            Keys.onEnterPressed: launchCurrent()
                            onAccepted: launchCurrent()
                        }
                        ListView {
                            id: appList
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                            model: ScriptModel { values: DesktopEntries.applications.values.filter(app => !app.noDisplay && (app.name + " " + (app.genericName || "")).toLowerCase().includes(query.text.toLowerCase())).sort((a,b) => a.name.localeCompare(b.name)) }
                            delegate: Rectangle {
                                id: appRow
                                required property var modelData
                                required property int index
                                width: appList.width; height: 42
                                radius: Theme.radius
                                color: appList.currentIndex === index ? Theme.raised : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
                                Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: appRow.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; textFormat: Text.PlainText }
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
                            model: ScriptModel { values: [...notices.trackedNotifications.values].reverse() }
                            delegate: Notice { required property var modelData; notification: modelData; width: ListView.view.width }
                            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion } }
                            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.glide; easing.type: Easing.OutCubic } }
                            Text { anchors.centerIn: parent; visible: notices.trackedNotifications.values.length === 0; text: "Nothing waiting. Back to the game."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                        }
                    }
                    ColumnLayout {
                        spacing: 12
                        Text { text: "Save your work. Destructive actions need a second click."; color: Theme.muted; font.family: Theme.font; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        Repeater {
                            model: [ {label:"LOCK",cmd:["loginctl","lock-session"]}, {label:"SUSPEND",cmd:["afterhours-suspend"]}, {label:"LOG OUT",cmd:["power","logout"]}, {label:"REBOOT",cmd:["power","reboot"]}, {label:"POWER OFF",cmd:["power","poweroff"]} ]
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
                    Text { text: "SHOW UP  <font color=\"" + Theme.accent + "\">◆</font>  SHIP SMALL"; textFormat: Text.StyledText; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 3; Layout.fillWidth: true; elide: Text.ElideRight }
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
        visible: root.toasts.length > 0
        screen: root.panelScreen
        WlrLayershell.namespace: "afterhours-toast"
        anchors { top: true; right: true }
        margins { top: 8; right: 12 }
        implicitWidth: Math.min(380, (screen?.width ?? 400) - 32)
        implicitHeight: toastColumn.implicitHeight
        color: "transparent"
        mask: Region { item: toastColumn }
        Column {
            id: toastColumn; width: parent.width; spacing: 8
            Repeater {
                // ScriptModel keeps existing toasts alive when one is added or
                // dropped, so their timers and slide-in don't restart.
                model: ScriptModel { values: root.toasts }
                Notice {
                    id: toast
                    required property var modelData
                    notification: modelData; width: toastColumn.width; toast: true
                    // expireTimeout is in ms; 0 or less means the server decides.
                    readonly property int life: (modelData.expireTimeout ?? 0) > 0 ? modelData.expireTimeout
                        : modelData.urgency === NotificationUrgency.Low ? 3000 : 6500
                    Timer {
                        interval: Math.max(1000, toast.life)
                        running: toast.modelData.urgency !== NotificationUrgency.Critical && !toast.hovered
                        onTriggered: { if (toast.modelData.transient) toast.modelData.expire(); else root.dropToast(toast.modelData); }
                    }
                    transform: Translate { id: slide }
                    Component.onCompleted: enter.start()
                    ParallelAnimation {
                        id: enter
                        NumberAnimation { target: slide; property: "x"; from: 48; to: 0; duration: Theme.glide; easing.type: Easing.OutCubic }
                        NumberAnimation { target: toast; property: "opacity"; from: 0; to: 1; duration: Theme.motion; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
