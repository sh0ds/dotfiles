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
import Quickshell.Services.Pipewire

ShellRoot {
    // A thin upright line between groups of rail cells.
    component Seam: Rectangle {
        implicitWidth: 1; implicitHeight: 16
        color: Theme.line
        Layout.leftMargin: 4; Layout.rightMargin: 4
        Layout.alignment: Qt.AlignVCenter
    }
    id: root
    property string panel: ""
    property var panelScreen: Quickshell.screens[0] ?? null
    property bool quiet: false
    property bool recording: false
    property bool sharing: false
    property int shareCount: 0
    property bool barVisible: true
    // The Pi (site, backups, takt) answers a ping: checked every 30 s.
    property bool piUp: false
    readonly property string piHost: Quickshell.env("PI_HOST") || "192.168.178.36"
    property string pendingAction: ""
    // What the launcher starts with ("=" for Super+C and so on); used once.
    property string launchPrefix: ""
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
    function run(command) { Quickshell.execDetached(command); panel = ""; pendingAction = ""; }
    function toggle(name, screen) {
        if (!["apps", "inbox", "session"].includes(name)) return;
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
        function lock(): void { root.lockNow(); }
        function locked(): string { return lockScreen.secure ? "true" : "false"; }
        function overview(): void { overviewWindow.open = !overviewWindow.open; }
        // Open the launcher with a mode already typed: "=", ">", "/" or ":".
        function launch(prefix: string): void {
            if (root.panel === "apps") { query.text = prefix; query.cursorPosition = prefix.length; }
            else { root.launchPrefix = prefix; root.toggle("apps", null); }
        }
        function game(on: bool): void { root.setGame(on); }
    }
    // Sound straight from PipeWire: the rail, the OSD and the control centre
    // all follow the default output live, no polling.
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property string volume: !sink?.audio ? "—" : sink.audio.muted ? "mute" : Math.round(sink.audio.volume * 100) + "%"
    function nudgeVolume(step) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, Math.round((sink.audio.volume + step * 0.05) * 20) / 20));
    }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    // The island borrows this moment: 1.5 s of volume after a change (not
    // in the first seconds, that's PipeWire settling). A new song doesn't
    // show there: now playing on the rail already has it, and every short
    // in Firefox would count as one.
    property bool volumeArmed: false
    property bool volumePulse: false
    Timer { running: true; interval: 2500; onTriggered: root.volumeArmed = true }
    Timer { id: volumeLater; interval: 1500; onTriggered: root.volumePulse = false }
    function pulseVolume() { if (!volumeArmed) return; volumePulse = true; volumeLater.restart(); }
    Connections {
        target: root.sink?.audio ?? null
        function onVolumesChanged() { root.pulseVolume(); }
        function onMutedChanged() { root.pulseVolume(); }
    }
    // Notifications and the volume go to the island while the rail is up;
    // with the rail hidden (Super+B, game mode) the toasts and the volume panel do.
    readonly property bool islandShown: barVisible && !gameMode

    // Game mode: on while a game is fullscreen on any monitor (Steam games,
    // WoW, anything Hyprland marks as game content), or when you turn it on
    // yourself. Steam itself never counts, even fullscreen on workspace 5.
    // The rail and the frame hide on the game's monitor only; the other
    // monitor keeps its rail. Animations, dimming and shadows are
    // Hyprland-wide, so they're off only while you're on the game's monitor:
    // switch to the other one and windows animate as usual. Turning it on
    // or off by hand overrides the automatic choice until the next game
    // starts or ends.
    readonly property string gameScreen: {
        for (const m of Hyprland.monitors.values) {
            const ws = m.activeWorkspace;
            if (!ws?.hasFullscreen) continue;
            for (const t of ws.toplevels.values) {
                const ipc = t.lastIpcObject ?? {};
                const wow = ipc.class === "steam_app_battlenet" && /^World of Warcraft/.test(ipc.title ?? "");
                if (ipc.fullscreen && (wow || ipc.contentType === "game" || /^(steam_app_\d+|gamescope)$/.test(ipc.class ?? ""))) return m.name;
            }
        }
        return "";
    }
    readonly property bool gameAuto: gameScreen !== ""
    property string gameOverride: ""
    property string manualScreen: ""
    onGameAutoChanged: gameOverride = ""
    readonly property bool gameMode: gameOverride === "on" || (gameOverride !== "off" && gameAuto)
    // The monitor whose rail and frame hide: the game's, or the one you were
    // on when you turned game mode on by hand.
    readonly property string gameOn: gameMode ? (gameScreen || manualScreen) : ""
    function setGame(on) {
        manualScreen = Hyprland.focusedMonitor?.name ?? "";
        gameOverride = on === gameAuto ? "" : on ? "on" : "off";
    }
    Connections {
        target: Hyprland.focusedWorkspace
        function onHasFullscreenChanged() { Hyprland.refreshToplevels(); }
    }
    readonly property bool gameFocused: gameOn !== "" && Hyprland.focusedMonitor?.name === gameOn
    onGameFocusedChanged: {
        Quickshell.execDetached(["hyprctl", "eval", gameFocused
            ? "hl.config({ animations = { enabled = false }, decoration = { dim_inactive = false, shadow = { enabled = false } } })"
            : "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = true, shadow = { enabled = true } } })"]);
    }
    // cava, only while something plays: ten bars, 0-7 each, one line per
    // frame (.config/cava/rail). Stereo, so the bass sits in the middle and
    // the two channels mirror outwards. Without cava the bars stay flat.
    readonly property var cavaRest: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var cavaBars: cavaRest
    Process {
        id: cava
        running: root.player?.isPlaying ?? false
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/rail"]
        stdout: SplitParser {
            onRead: line => {
                const bars = line.split(";").filter(v => v !== "").map(Number);
                if (bars.length === 10) root.cavaBars = bars;
            }
        }
        onRunningChanged: if (!running) root.cavaBars = root.cavaRest
    }
    // Network for the rail: "wifi:<ssid>", "ethernet" or "offline", every 10 s.
    property string net: ""
    Process {
        id: netRead
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector { onStreamFinished: {
            let out = "offline";
            for (const line of text.trim().split("\n")) {
                const [type, state, ...name] = line.split(":");
                if (state !== "connected") continue;
                if (type === "ethernet") { out = "ethernet"; break; }
                if (type === "wifi") out = "wifi:" + name.join(":");
            }
            root.net = out;
        } }
    }
    Timer { interval: 10000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!netRead.running) netRead.running = true }
    // Keep awake: holds a systemd idle inhibitor (hypridle respects it) while on.
    property bool awake: false
    Process {
        running: root.awake
        command: ["systemd-inhibit", "--what=idle", "--who=Afterhours", "--why=Keep awake from the rail", "sleep", "infinity"]
    }
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
            visible: root.barVisible && rail.modelData.name !== root.gameOn
            WlrLayershell.namespace: "afterhours-rail"
            // The media card, the control centre and Today hang under this rail.
            function openControl(cell) {
                if (control.visible && control.target === cell) { control.visible = false; return; }
                control.visible = false;
                control.target = cell;
                control.visible = true;
            }
            MediaCard { id: media; target: mediaCell; player: root.player; bars: root.cavaBars }
            Dashboard { id: dash; target: island; shell: root }
            ControlCenter { id: control; target: volCell; shell: root }
            anchors { top: true; left: true; right: true }
            // Floats 8 px down and 12 px in, lined up with the window gaps.
            margins { top: 8; left: 12; right: 12 }
            implicitHeight: 42
            color: "transparent"
            // Three glass islands: apps, workspaces and the window title on the
            // left, the island in the middle, the status cells on the right.
            // The middle one grows into the room the side pieces leave free.
            readonly property real sideWidth: Math.max(rightPill.width, appsCell.width + spaces.width + 20)
            Island {
                id: island
                z: 1
                anchors.centerIn: parent
                shell: root
                live: rail.screen?.name === Hyprland.focusedMonitor?.name
                wide: rail.width > 900
                open: dash.visible
                maxWidth: Math.max(restWidth, Math.min(560, rail.width - 2 * (rail.sideWidth + 16)))
                onClockClicked: dash.visible = !dash.visible
            }
            Hint { target: island; text: "Today: the month, graphs, disks, the Pi"; show: island.hovered && island.mode === "clock" && !dash.visible }
            Notch {
                id: leftPill
                anchors.left: parent.left
                height: parent.height
                width: leftRow.implicitWidth + 12
                cutTopRight: false; cutBottomLeft: false
                color: Theme.glass
                edge: Theme.edge
                Behavior on width { NumberAnimation { duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
            RowLayout {
                id: leftRow
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Cell { id: appsCell; label: "\uf303"; size: 16; implicitWidth: 38; ink: Theme.accent; hint: "Apps · Super+Space"; onClicked: root.toggle("apps", rail.screen) }
                // Workspaces: plain numbers in a recessed track. The active one is
                // a wider violet block that glides over; numbers with windows on
                // them are bright, empty ones dim, urgent ones amber. Hover lifts
                // a number, the wheel steps through them.
                Item {
                    id: spaces
                    readonly property int active: Hyprland.monitorFor(rail.screen)?.activeWorkspace?.id ?? -1
                    readonly property var ids: root.workspaceIds(rail.screen).slice(0, rail.width > 650 ? 10 : 3)
                    property real markX: 0
                    property real markW: 0
                    // The marker is liquid: on a switch its front edge runs
                    // ahead and its back edge catches up with a little bounce.
                    property bool rightward: true
                    property int lastActive: active
                    onActiveChanged: { rightward = active > lastActive; lastActive = active; }
                    property real edgeL: markX
                    property real edgeR: markX + markW
                    Behavior on edgeL { NumberAnimation { duration: spaces.rightward ? 460 : 220; easing.type: spaces.rightward ? Easing.OutBack : Easing.OutCubic; easing.overshoot: 1.6 } }
                    Behavior on edgeR { NumberAnimation { duration: spaces.rightward ? 220 : 460; easing.type: spaces.rightward ? Easing.OutCubic : Easing.OutBack; easing.overshoot: 1.6 } }
                    implicitWidth: spaceRow.implicitWidth + 8
                    implicitHeight: 30
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.well
                        border.width: 1
                        border.color: Theme.edge
                    }
                    Notch {
                        cut: Theme.notchSmall; cutTopRight: false; cutBottomLeft: false
                        x: Math.min(spaces.edgeL, spaces.edgeR) + 4; y: 4
                        width: Math.abs(spaces.edgeR - spaces.edgeL); height: parent.height - 8
                        visible: spaces.markW > 0
                        color: Theme.accent
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
                                Notch {
                                    anchors.centerIn: parent
                                    width: 22; height: 22
                                    cut: Theme.notchSmall; cutTopRight: false; cutBottomLeft: false
                                    color: Theme.glassRaised
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
                // Recording or sharing: on the left, before the title, which
                // shortens to make room (the right side has no room to spare).
                Cell {
                    Layout.leftMargin: 6
                    visible: root.recording || root.sharing
                    label: root.sharing ? "● LIVE" : "● REC"; ink: Theme.danger
                    hint: root.recording ? "Click to stop recording" : "Sharing your screen: popups are held back"
                    onClicked: if (root.recording) root.run(["rec-toggle"])
                }
                Text {
                    id: windowTitle
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    // Up to the room the island may grow into, so it never covers the title.
                    Layout.maximumWidth: Math.max(0, rail.width / 2 - island.maxWidth / 2 - 16 - 12 - windowTitle.x)
                    visible: rail.width > 1050
                    // Without the browser's tab count and the app's name at
                    // the end: the window itself says which app it is.
                    text: (Hyprland.activeToplevel?.title ?? "")
                        .replace(/^\[\d+ tabs?\]\s*/, "")
                        .replace(/\s+[—–-]\s+(Mozilla Firefox|Zed|Obsidian)$/, "")
                    color: Theme.muted
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.family: Theme.font; font.pixelSize: 12
                }
            }
            }
            Notch {
                id: rightPill
                anchors.right: parent.right
                height: parent.height
                width: rightRow.implicitWidth + 12
                cutTopLeft: false; cutBottomRight: false
                color: Theme.glass
                edge: Theme.edge
                Behavior on width { NumberAnimation { duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
            RowLayout {
                id: rightRow
                anchors.right: parent.right; anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Cell {
                    mirrored: true
                    visible: rail.width > 1350 && root.player !== null
                    label: root.player ? root.player.trackTitle.slice(0, 26) : ""
                    ink: root.player?.isPlaying ? Theme.text : Theme.muted
                    // cava as a small waveform: a fixed 16 px box, so the rail
                    // never moves, bars growing both ways from the centre line,
                    // brightest in the middle. Paused, it rests as a dotted line.
                    // The delegates stay put (model: 10) and only their heights
                    // ease, instead of being rebuilt every frame.
                    Item {
                        width: 10 * 3 + 9 * 2; height: 16
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: 10
                                Rectangle {
                                    required property int index
                                    readonly property int level: root.player?.isPlaying ? (root.cavaBars[index] ?? 0) : 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3
                                    height: 2 + level * 2
                                    color: Theme.accent
                                    opacity: root.player?.isPlaying ? 1 - Math.abs(index - 4.5) / 9 : 0.35
                                    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: Theme.motion } }
                                }
                            }
                        }
                    }
                    id: mediaCell
                    fill: media.visible ? Theme.accentSoft : "transparent"
                    hint: "Click: player · right-click: play / pause · wheel: next / previous track"
                    onClicked: media.visible = !media.visible
                    onRightClicked: { if (root.player?.canTogglePlaying) root.player.togglePlaying(); }
                    onWheeled: step => {
                        if (step < 0 && root.player?.canGoNext) root.player.next();
                        else if (step > 0 && root.player?.canGoPrevious) root.player.previous();
                    }
                }
                // Right side, in groups split by seams: now playing | keep
                // awake, the Pi, network | sound (network and sound both open
                // the control centre), the inbox and the tray | power. The
                // system graphs are in Today (click the clock).
                Seam { visible: mediaCell.visible }
                Cell {
                    mirrored: true
                    visible: rail.width > 900
                    label: "\uf0f4"   // nf-fa-coffee
                    size: 14
                    lit: root.awake
                    ink: Theme.muted
                    hint: root.awake ? "Keeping the screen awake · click to stop" : "Keep the screen awake (no dim, lock or sleep)"
                    onClicked: root.awake = !root.awake
                }
                Cell {
                    mirrored: true
                    visible: rail.width > 900
                    label: "\uf315"   // nf-linux-raspberry_pi
                    size: 16
                    ink: root.piUp ? Theme.accent : Theme.danger
                    hint: "Raspberry Pi " + root.piHost + (root.piUp ? " is up · click: ssh" : " is not answering")
                    onClicked: root.run(["kitty", "-e", "ssh", "pi"])
                }
                Cell {
                    mirrored: true
                    id: netCell
                    visible: rail.width > 900
                    label: root.net === "ethernet" ? "\uf0e8" : root.net.startsWith("wifi:") ? "\uf1eb" : "\uf127"
                    size: 14
                    fill: control.visible && control.target === netCell ? Theme.accentSoft : "transparent"
                    ink: root.net === "offline" ? Theme.danger : Theme.text
                    hint: (root.net === "offline" ? "Offline" : root.net === "ethernet" ? "Wired" : root.net.slice(5)) + " · click: control centre · right-click: network settings"
                    onClicked: rail.openControl(netCell)
                    onRightClicked: root.run(["wifi", "settings"])
                }
                Seam { visible: rail.width > 900 }
                Cell {
                    mirrored: true
                    id: volCell
                    label: (rail.width > 900 ? "vol " : "") + root.volume
                    fill: control.visible && control.target === volCell ? Theme.accentSoft : "transparent"
                    ink: root.volume === "mute" ? Theme.muted : Theme.text
                    hint: "Wheel: volume · right-click: mute · click: control centre"
                    onClicked: rail.openControl(volCell)
                    onRightClicked: root.toggleMute()
                    onWheeled: step => root.nudgeVolume(step)
                }
                Cell {
                    mirrored: true
                    // Pops when a notification lands.
                    readonly property int count: notices.trackedNotifications.values.length
                    property int seen: 0
                    onCountChanged: { if (count > seen) bump(); seen = count; }
                    label: (rail.width > 900 ? (root.quiet ? "quiet " : "inbox ") : "✉ ") + count
                    ink: root.quiet ? Theme.amber : Theme.muted
                    onClicked: root.toggle("inbox", rail.screen)
                }
                Repeater {
                    model: rail.width > 900 ? SystemTray.items : null
                    Notch {
                        id: trayItem
                        required property var modelData
                        implicitWidth: 30; implicitHeight: 32
                        cut: Theme.notchSmall; cutTopLeft: false; cutBottomRight: false
                        color: trayPointer.containsMouse ? Theme.glassRaised : "transparent"
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
                        Hint { target: trayItem; text: trayItem.modelData.tooltipTitle || trayItem.modelData.title || ""; show: trayPointer.containsMouse }
                    }
                }
                Seam {}
                Cell { mirrored: true; label: "⏻"; hint: "Session controls"; onClicked: root.toggle("session", rail.screen) }
            }
            }
        }
    }
    // The living wallpaper and the screen frame, one each per monitor.
    Variants { model: Quickshell.screens; Wallpaper {} }
    Variants { model: Quickshell.screens; ScreenFrame { visible: modelData?.name !== root.gameOn } }
    Osd { sink: root.sink; held: root.islandShown }
    Overview { id: overviewWindow }
    Lock { id: lockScreen }
    function lockNow() { panel = ""; overviewWindow.open = false; lockScreen.lock(); }
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
        Notch {
            id: sheet
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 820)
            height: Math.min(parent.height - 100, 660)
            color: Theme.glass
            edge: Theme.edge
            cut: Theme.notchLarge
            Keys.onEscapePressed: root.panel = ""
            // Prevent clicks on the sheet reaching the outside-click handler.
            MouseArea { anchors.fill: parent }
            // Grows in from 94 % on the shared spring while it fades in.
            ParallelAnimation {
                running: overlay.visible
                NumberAnimation { target: sheet; property: "opacity"; from: 0; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
                NumberAnimation { target: sheet; property: "scale"; from: 0.94; to: 1; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 16
                RowLayout {
                    Text { text: "AFTERHOURS / " + root.panel.toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 12; font.letterSpacing: 2 }
                    Item { Layout.fillWidth: true }
                    Cell { label: "ESC  ×"; onClicked: root.panel = "" }
                }
                Text {
                    text: root.panel === "apps" ? "OPEN SOMETHING." : root.panel === "inbox" ? "INCOMING." : "END OF SESSION."
                    color: Theme.text; font.family: Theme.font; font.pixelSize: sheet.width < 600 ? 32 : 46
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                // The rule under the title starts with a short violet run.
                Item {
                    Layout.fillWidth: true; implicitHeight: 1
                    Rectangle { anchors.fill: parent; color: Theme.edge }
                    Rectangle { width: 48; height: 1; color: Theme.accent }
                }
                StackLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    currentIndex: ({apps: 0, inbox: 1, session: 2})[root.panel] ?? 0
                    // The launcher. Plain text finds apps; a first character
                    // switches what it searches:
                    //   =  maths (qalc): Enter copies the answer
                    //   >  commands: lock, restart the shell, quiet, game mode…
                    //   /  open windows, most recent first (Alt+Tab opens this)
                    //   :  emoji: Enter types it and copies it
                    ColumnLayout {
                        id: launcher
                        readonly property string raw: query.text
                        readonly property string mode: ["=", ">", "/", ":"].includes(raw.charAt(0)) ? raw.charAt(0) : ""
                        readonly property string q: (mode ? raw.slice(1) : raw).trim().toLowerCase()
                        // Uniform rows: name, detail, an icon name or a glyph, and what Enter does.
                        readonly property var rows: {
                            if (mode === "=") return calcRows;
                            if (mode === ">") return commandRows.filter(c => !q || c.name.toLowerCase().includes(q) || c.detail.toLowerCase().includes(q));
                            if (mode === "/") return windowRows.filter(w => !q || (w.name + " " + w.detail).toLowerCase().includes(q));
                            if (mode === ":") return emojiRows;
                            const rank = app => {
                                const name = app.name.toLowerCase();
                                if (!q || name.startsWith(q)) return 0;
                                if (name.includes(q)) return 1;
                                const more = [app.genericName, app.comment, ...(app.keywords ?? [])].join(" ").toLowerCase();
                                return more.includes(q) ? 2 : 3;
                            };
                            return DesktopEntries.applications.values
                                .filter(app => !app.noDisplay && rank(app) < 3)
                                .sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name))
                                .map(app => ({ name: app.name, detail: app.genericName || "", icon: app.icon, glyph: "", act: () => app.execute() }));
                        }
                        function launch(i) {
                            const row = rows[Math.max(0, i)];
                            if (!row) return;
                            root.panel = "";
                            row.act();
                        }

                        // = maths. qalc runs a moment after you stop typing.
                        property string calcAnswer: ""
                        readonly property var calcRows: {
                            if (!q) return [{ name: "Type a sum", detail: "2^10 · 15% of 89 · 300 EUR to USD · 5 GiB to MB", icon: "", glyph: "=", act: () => {} }];
                            const answer = /meaning of life/.test(q) ? "42"
                                : /\/\s*0+([^0-9.,]|$)/.test(q) ? "nice try"
                                : calcAnswer;
                            return [{ name: answer || "…", detail: "Enter copies it", icon: "", glyph: "=",
                                      act: () => { if (answer) Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy && notify-send -a Calculator Copied "$1"', "_", answer]); } }];
                        }
                        Timer { id: calcLater; interval: 150; onTriggered: { if (launcher.mode === "=" && launcher.q) { calc.command = ["qalc", "-t", launcher.raw.slice(1)]; calc.running = true; } } }
                        onRawChanged: if (mode === "=") { calcAnswer = ""; calcLater.restart(); }
                        Process { id: calc; stdout: StdioCollector { onStreamFinished: launcher.calcAnswer = text.trim() } }

                        // > commands. Logging out and powering off go through the
                        // session panel, so they keep their second click.
                        readonly property var commandRows: [
                            { name: "Lock", detail: "the lock screen", glyph: "", icon: "", act: () => root.lockNow() },
                            { name: "Overview", detail: "every workspace · Super+W", glyph: "", icon: "", act: () => overviewWindow.open = true },
                            { name: root.quiet ? "Quiet off" : "Quiet on", detail: "hold back notifications", glyph: "", icon: "", act: () => root.quiet = !root.quiet },
                            { name: root.awake ? "Keep awake off" : "Keep awake on", detail: "no dim, lock or sleep", glyph: "", icon: "", act: () => root.awake = !root.awake },
                            { name: root.gameMode ? "Game mode off" : "Game mode on", detail: "no rail, animations or dimming on its monitor", glyph: "", icon: "", act: () => root.setGame(!root.gameMode) },
                            { name: "Night light", detail: "warm colours on / off", glyph: "", icon: "", act: () => Quickshell.execDetached(["nightlight"]) },
                            { name: "Colour picker", detail: "hex code to the clipboard", glyph: "", icon: "", act: () => Quickshell.execDetached(["hyprpicker", "-a"]) },
                            { name: "Copy text from the screen", detail: "OCR a region", glyph: "", icon: "", act: () => Quickshell.execDetached(["ocr"]) },
                            { name: "Record a region", detail: "again to stop", glyph: "", icon: "", act: () => Quickshell.execDetached(["rec-toggle"]) },
                            { name: "Docs search", detail: "Godot, PICO-8, Arch Wiki, man", glyph: "", icon: "", act: () => Quickshell.execDetached(["docs"]) },
                            { name: "Reload Hyprland", detail: "re-read hyprland.lua", glyph: "", icon: "", act: () => Quickshell.execDetached(["hyprctl", "reload"]) },
                            { name: "Restart the shell", detail: "afterhours restart", glyph: "", icon: "", act: () => Quickshell.execDetached(["afterhours", "restart"]) },
                            { name: "Log out, reboot, power off", detail: "the session panel", glyph: "", icon: "", act: () => root.toggle("session", null) }
                        ]

                        // / windows, most recently used first.
                        readonly property var windowRows: {
                            const list = Hyprland.toplevels.values
                                .filter(t => (t.lastIpcObject?.workspace?.id ?? 0) > 0)
                                .sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 99) - (b.lastIpcObject?.focusHistoryID ?? 99));
                            return list.map(t => {
                                const cls = t.lastIpcObject?.class ?? "";
                                const entry = DesktopEntries.heuristicLookup(cls);
                                return { name: t.title || cls, detail: (entry?.name ?? cls) + " · " + (t.workspace?.id ?? ""), icon: entry?.icon ?? "", glyph: "",
                                         act: () => Hyprland.dispatch('hl.dsp.focus({ window = "address:0x' + t.address + '" })') };
                            });
                        }
                        onModeChanged: { if (mode === "/") Hyprland.refreshToplevels(); cascade(); }
                        // Rows cascade in, 20 ms apart, when the launcher opens
                        // and when the mode changes; typing just filters.
                        property bool fresh: false
                        signal cascaded()
                        function cascade() { fresh = true; freshEnd.restart(); cascaded(); }
                        Timer { id: freshEnd; interval: 120; onTriggered: launcher.fresh = false }

                        // : emoji, from the unicode-emoji list, read the first time.
                        property var emojiAll: []
                        FileView {
                            path: "/usr/share/unicode/emoji/emoji-test.txt"
                            blockLoading: false
                            preload: launcher.mode === ":"
                            onLoaded: {
                                const out = [];
                                for (const line of text().split("\n")) {
                                    if (!line.includes("; fully-qualified") || line.includes("skin tone")) continue;
                                    const m = line.match(/#\s+(\S+)\s+E[0-9.]+\s+(.+)$/);
                                    if (m) out.push({ e: m[1], n: m[2] });
                                }
                                launcher.emojiAll = out;
                            }
                        }
                        readonly property var emojiRows: emojiAll.filter(x => !q || x.n.includes(q)).slice(0, 80).map(x => ({
                            name: x.n, detail: "", icon: "", glyph: x.e,
                            act: () => Quickshell.execDetached(["sh", "-c", 'wl-copy -n -- "$1"; sleep 0.2; command -v wtype >/dev/null && wtype -- "$1"', "_", x.e])
                        }))

                        TextField {
                            id: query
                            Layout.fillWidth: true
                            placeholderText: "Find an app…   = maths   > commands   / windows   : emoji"
                            font.family: Theme.font; font.pixelSize: 16; color: Theme.text
                            placeholderTextColor: Theme.muted
                            leftPadding: 14; topPadding: 10; bottomPadding: 10
                            background: Rectangle { color: Theme.well; border.color: query.activeFocus ? Theme.accent : Theme.edge; Behavior on border.color { ColorAnimation { duration: Theme.motion } } }
                            Keys.onEscapePressed: root.panel = ""
                            onTextChanged: appList.currentIndex = launcher.mode === "/" && launcher.q === "" && launcher.rows.length > 1 ? 1 : 0
                            Keys.onDownPressed: appList.incrementCurrentIndex()
                            Keys.onUpPressed: appList.decrementCurrentIndex()
                            Keys.onTabPressed: appList.incrementCurrentIndex()
                            Keys.onReturnPressed: launcher.launch(appList.currentIndex)
                            Keys.onEnterPressed: launcher.launch(appList.currentIndex)
                        }
                        ListView {
                            id: appList
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                            model: ScriptModel { values: launcher.rows }
                            // Keyboard selection keeps the chosen row in view.
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 0
                            delegate: Notch {
                                id: appRow
                                required property var modelData
                                required property int index
                                width: ListView.view.width; height: 44
                                cut: Theme.notchSmall; cutTopRight: false; cutBottomLeft: false
                                readonly property bool current: appList.currentIndex === index
                                color: current ? Theme.glassRaised : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
                                // The chosen row gets a violet edge, like the workspace marker.
                                Rectangle { x: 4; y: 11; width: 3; height: parent.height - 22; color: Theme.accent; opacity: appRow.current ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.motion } } }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 16; anchors.right: parent.right; anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12
                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22; height: 22
                                        Image {
                                            id: rowIcon
                                            anchors.fill: parent; sourceSize: Qt.size(44, 44)
                                            source: appRow.modelData.icon ? Quickshell.iconPath(appRow.modelData.icon, true) : ""
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: rowIcon.status !== Image.Ready
                                            text: appRow.modelData.glyph || ""
                                            color: Theme.accent; font.family: Theme.font
                                            font.pixelSize: launcher.mode === ":" ? 18 : 14
                                        }
                                    }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: appRow.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: launcher.mode === "=" ? 18 : 14; font.bold: appRow.current || launcher.mode === "="; textFormat: Text.PlainText; elide: Text.ElideRight; width: Math.min(implicitWidth, appRow.width * 0.6) }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: appRow.modelData.detail || ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; textFormat: Text.PlainText; elide: Text.ElideRight; width: Math.max(0, appRow.width - x - 40) }
                                }
                                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: appList.currentIndex = appRow.index; onClicked: launcher.launch(appRow.index) }
                                transform: Translate { id: rowShift }
                                function arrive() { if (index >= 14) return; opacity = 0; rowShift.y = 10; rise.restart(); }
                                Component.onCompleted: if (launcher.fresh) arrive()
                                Connections { target: launcher; function onCascaded() { appRow.arrive(); } }
                                SequentialAnimation {
                                    id: rise
                                    PauseAnimation { duration: appRow.index * 20 }
                                    ParallelAnimation {
                                        NumberAnimation { target: appRow; property: "opacity"; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: rowShift; property: "y"; to: 0; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
                                    }
                                }
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
                // The motto alone in the footer; apps have the rail button and Super+Space.
                Text { text: "SHOW UP  <font color=\"" + Theme.accent + "\">◆</font>  SHIP SMALL"; textFormat: Text.StyledText; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 3; Layout.fillWidth: true; Layout.topMargin: 4; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
            }
        }
        Connections { target: root; function onPanelChanged() { if (root.panel === "apps") { launcher.cascade(); query.text = root.launchPrefix; query.cursorPosition = query.text.length; root.launchPrefix = ""; query.forceActiveFocus(); } else sheet.forceActiveFocus(); } }
        // Capture all unhandled Escape presses, including while a text field is focused.
        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: root.panel = "" }
    }
    // Passive toasts never steal keyboard focus. Quiet mode preserves inbox history.
    // Only while the rail (and its island) is hidden: Super+B or game mode.
    PanelWindow {
        visible: root.toasts.length > 0 && !root.islandShown
        // On the monitor you're working on, not the one a panel last opened on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        WlrLayershell.namespace: "afterhours-toast"
        anchors { top: true; right: true }
        margins { top: 8; right: 12 }
        implicitWidth: Math.min(380, (screen?.width ?? 400) - 32)
        implicitHeight: toastColumn.implicitHeight
        color: "transparent"
        mask: Region { item: toastColumn }
        Column {
            id: toastColumn; width: parent.width; spacing: 8
            // When one leaves, the ones below glide up on the spring.
            move: Transition { NumberAnimation { property: "y"; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
            Repeater {
                // ScriptModel keeps existing toasts alive when one is added or
                // dropped, so their timers and slide-in don't restart.
                model: ScriptModel { values: root.islandShown ? [] : root.toasts }
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
                        onTriggered: leave.start()
                    }
                    SequentialAnimation {
                        id: leave
                        ParallelAnimation {
                            NumberAnimation { target: slide; property: "x"; to: 48; duration: Theme.glide; easing.type: Easing.InCubic }
                            NumberAnimation { target: toast; property: "opacity"; to: 0; duration: Theme.motion; easing.type: Easing.InCubic }
                        }
                        ScriptAction { script: { if (toast.modelData.transient) toast.modelData.expire(); else root.dropToast(toast.modelData); } }
                    }
                    transform: Translate { id: slide }
                    Component.onCompleted: enter.start()
                    ParallelAnimation {
                        id: enter
                        NumberAnimation { target: slide; property: "x"; from: 48; to: 0; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
                        NumberAnimation { target: toast; property: "opacity"; from: 0; to: 1; duration: Theme.motion; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
