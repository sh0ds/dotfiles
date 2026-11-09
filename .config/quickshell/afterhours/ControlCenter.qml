import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
// The control centre under the rail (click vol or the network icon):
// output and microphone, every app that plays sound with its own slider,
// Wi-Fi, and the switches (night light, quiet, keep awake, game mode).
// Replaces pavucontrol and nmtui for everyday use; both stay one click away.
PopupWindow {
    id: cc
    required property Item target
    required property var shell
    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 10
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 380
    implicitHeight: body.implicitHeight + 36
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    // Programs playing sound. Playback streams count as sinks in Quickshell
    // (they take audio in); recording streams like cava are not sinks.
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.isSink)
    PwObjectTracker { objects: [...cc.streams, ...cc.sinks] }
    function nodeName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || n?.nickname || n?.description || n?.name || "?";
    }
    onVisibleChanged: if (visible) { intro.restart(); wifiScan.running = true; nightRead.running = true; }

    // Wi-Fi: IN-USE, SIGNAL, SECURITY, SSID; colons in names come escaped.
    property var networks: []
    property bool wifiOn: true
    Process {
        id: wifiScan
        command: ["sh", "-c", "nmcli -t -f WIFI radio; nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto"]
        stdout: StdioCollector { onStreamFinished: {
            const lines = text.trim().split("\n");
            cc.wifiOn = lines.shift() === "enabled";
            const seen = new Set(), list = [];
            for (const line of lines) {
                const f = line.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
                if (f.length < 4 || !f[3] || seen.has(f[3])) continue;
                seen.add(f[3]);
                list.push({ inUse: f[0] === "*", signal: Number(f[1]) || 0, secure: f[2] !== "" && f[2] !== "--", ssid: f[3] });
            }
            list.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
            cc.networks = list.slice(0, 6);
        } }
    }
    // Known networks connect directly; a new secured one goes to the picker,
    // which asks for the password.
    Process { id: connector; onExited: wifiScan.running = true }
    function join(n) {
        if (n.inUse) return;
        if (n.secure) { cc.shell.run(["wifi"]); return; }
        connector.command = ["sh", "-c", 'nmcli connection up id "$1" || nmcli device wifi connect "$1"', "_", n.ssid];
        connector.running = true;
    }
    property bool night: false
    Process { id: nightRead; command: ["pgrep", "-x", "hyprsunset"]; onExited: code => cc.night = code === 0 }
    Timer { id: nightLater; interval: 400; onTriggered: nightRead.running = true }

    component Heading: Caption { Layout.topMargin: 4 }
    // One audio row: icon (click mutes), name, slider, percent.
    component AudioRow: RowLayout {
        id: arow
        required property var node
        property string icon: ""
        property string muteIcon: "󰝟"
        property string name: cc.nodeName(node)
        readonly property real vol: node?.audio?.volume ?? 0
        readonly property bool mute: node?.audio?.muted ?? false
        Layout.fillWidth: true
        spacing: 10
        Cell {
            label: arow.mute ? arow.muteIcon : arow.icon; size: 13; implicitWidth: 32; implicitHeight: 28
            ink: arow.mute ? Theme.muted : Theme.accent
            hint: arow.mute ? "Unmute" : "Mute"
            onClicked: if (arow.node?.audio) arow.node.audio.muted = !arow.node.audio.muted
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: arow.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true; textFormat: Text.PlainText }
            Meter {
                Layout.fillWidth: true
                value: arow.vol; muted: arow.mute
                onMoved: v => { if (arow.node?.audio) arow.node.audio.volume = v; }
            }
        }
        Text { text: Math.round(arow.vol * 100) + "%"; color: arow.mute ? Theme.muted : Theme.text; font.family: Theme.font; font.pixelSize: 11; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
    }
    // A switch tile: icon, name, state; violet when on.
    component Toggle: Notch {
        id: tg
        cut: Theme.notchSmall; cutTopRight: false; cutBottomLeft: false
        property string icon
        property string name
        property bool on: false
        signal toggled()
        Layout.fillWidth: true
        implicitHeight: 54
        color: on ? Theme.accentSoft : tgHover.hovered ? Theme.glassRaised : Theme.well
        edge: on ? Theme.accent : Theme.edge
        Behavior on color { ColorAnimation { duration: Theme.motion } }
        Behavior on edge { ColorAnimation { duration: Theme.motion } }
        Column {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: tg.icon + "  " + tg.name; color: tg.on ? Theme.accent : Theme.text; font.family: Theme.font; font.pixelSize: 12; font.bold: tg.on }
            Text { text: tg.on ? "on" : "off"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
        }
        HoverHandler { id: tgHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: tg.toggled() }
    }

    Notch {
        id: box
        anchors.fill: parent
        cut: Theme.notchLarge
        color: Theme.glass
        edge: Theme.edge
        cutInk: Theme.cutInk
        transformOrigin: Item.TopRight
        PopIn { id: intro; surface: box; inner: body }
        ColumnLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            spacing: 10

            GridLayout {
                Layout.fillWidth: true
                columns: 2; columnSpacing: 8; rowSpacing: 8
                Toggle {
                    icon: ""; name: "Night light"; on: cc.night
                    onToggled: { cc.shell.run(["nightlight"]); cc.night = !cc.night; nightLater.restart(); }
                }
                Toggle { icon: ""; name: "Quiet"; on: cc.shell.quiet; onToggled: cc.shell.quiet = !cc.shell.quiet }
                Toggle { icon: ""; name: "Keep awake"; on: cc.shell.awake; onToggled: cc.shell.awake = !cc.shell.awake }
                Toggle { icon: ""; name: "Game mode"; on: cc.shell.gameMode; onToggled: cc.shell.setGame(!cc.shell.gameMode) }
            }

            Heading { text: "SOUND" }
            AudioRow { node: cc.sink; icon: ""; name: "Output · " + cc.nodeName(cc.sink) }
            // Pick the output when there is more than one (headset, speakers).
            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: cc.sinks.length > 1
                Repeater {
                    model: cc.sinks
                    Cell {
                        required property var modelData
                        label: cc.nodeName(modelData)
                        size: 11; implicitHeight: 26
                        selected: modelData?.id === cc.sink?.id
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }
            AudioRow { node: cc.source; icon: ""; muteIcon: ""; name: "Microphone · " + cc.nodeName(cc.source); visible: cc.source !== null }

            Heading { text: "APPS"; visible: cc.streams.length > 0 }
            Repeater {
                model: cc.streams
                AudioRow { required property var modelData; node: modelData; icon: "" }
            }

            RowLayout {
                Layout.fillWidth: true
                Heading { text: "WI-FI"; Layout.fillWidth: true }
                Cell { label: cc.wifiOn ? "on" : "off"; size: 11; implicitHeight: 24; selected: cc.wifiOn; onClicked: { cc.shell.run(["nmcli", "radio", "wifi", cc.wifiOn ? "off" : "on"]); cc.wifiOn = !cc.wifiOn; } }
            }
            Repeater {
                model: cc.wifiOn ? cc.networks : []
                Notch {
                    id: net
                    cut: Theme.notchSmall; cutTopRight: false; cutBottomLeft: false
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: netHover.hovered ? Theme.glassRaised : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 10
                        Text {
                            text: net.modelData.signal >= 75 ? "󰤨" : net.modelData.signal >= 50 ? "󰤥" : net.modelData.signal >= 25 ? "󰤢" : "󰤟"
                            color: net.modelData.inUse ? Theme.accent : Theme.muted; font.family: Theme.font; font.pixelSize: 14
                        }
                        Text { text: net.modelData.ssid; color: net.modelData.inUse ? Theme.text : Theme.muted; font.bold: net.modelData.inUse; font.family: Theme.font; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true; textFormat: Text.PlainText }
                        Text { text: net.modelData.inUse ? "connected" : net.modelData.secure ? "" : ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                    }
                    HoverHandler { id: netHover; cursorShape: net.modelData.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor }
                    TapHandler { onTapped: cc.join(net.modelData) }
                }
            }
            Text { visible: cc.wifiOn && cc.networks.length === 0; text: "Looking for networks…"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11 }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8
                Cell { label: "Sound settings"; size: 11; Layout.fillWidth: true; onClicked: cc.shell.run(["pavucontrol"]) }
                Cell { label: "Network settings"; size: 11; Layout.fillWidth: true; onClicked: cc.shell.run(["wifi", "settings"]) }
            }
        }
    }
}
