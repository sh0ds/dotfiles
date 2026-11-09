import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
// Today: the drawer under the island (click the clock). The date and the
// month on the left; on the right the machine (cpu, gpu and memory over
// the last 80 seconds), the Pi, the disks and what's playing.
// Everything is read only while it's open: sys-stats every 2 s, a ping to
// the Pi every 5 s, uptime and df once a minute.
PopupWindow {
    id: dash
    required property Item target
    required property var shell
    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // 8 px under the rail, like the volume OSD and the rail's own top
    // margin: under the island (42 px, the rail's full height).
    anchor.margins.top: 8
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 720
    implicitHeight: body.implicitHeight + 36
    onVisibleChanged: if (visible) {
        pop.restart();
        if (!once.running && memTotal === 0) once.running = true;
    } else { cpu = []; gpu = []; mem = []; }

    readonly property int samples: 40
    property var cpu: []
    property var gpu: []
    property var mem: []
    property string temp: "-"
    property real memTotal: 0
    property int piMs: -1
    property string uptime: ""
    property var disks: []
    function push(list, v) { return [...list, v].slice(-samples); }
    function last(list) { return list.length ? list[list.length - 1] : 0; }

    Process {
        id: once
        command: ["awk", "/^MemTotal/ { printf \"%.1f\", $2 / 1048576 }", "/proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: dash.memTotal = Number(text) || 0 }
    }
    Process {
        id: statsRead
        command: ["sys-stats"]
        stdout: StdioCollector { onStreamFinished: {
            const v = text.trim().split(/\s+/);
            if (v.length !== 4) return;
            dash.cpu = dash.push(dash.cpu, Number(v[0]) || 0);
            dash.mem = dash.push(dash.mem, Number(v[1]) || 0);
            dash.temp = v[2];
            if (v[3] !== "-") dash.gpu = dash.push(dash.gpu, Number(v[3]) || 0);
        } }
    }
    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: dash.visible; onTriggered: if (!statsRead.running) statsRead.running = true }
    Process {
        id: ping
        command: ["ping", "-c", "1", "-W", "1", dash.shell.piHost]
        stdout: StdioCollector { onStreamFinished: {
            const m = text.match(/time=([0-9.]+)/);
            dash.piMs = m ? Math.round(Number(m[1])) : -1;
            dash.shell.piUp = dash.piMs >= 0;
        } }
    }
    Timer { interval: 5000; repeat: true; triggeredOnStart: true; running: dash.visible; onTriggered: if (!ping.running) ping.running = true }
    Process {
        id: upRead
        command: ["uptime", "-p"]
        stdout: StdioCollector { onStreamFinished: dash.uptime = text.trim().replace(/^up\s+/, "") }
    }
    // df names the mount each path lives on; /home on the root disk shows once.
    Process {
        id: diskRead
        command: ["df", "-h", "--output=target,used,size,pcent", "/", "/home"]
        stdout: StdioCollector { onStreamFinished: {
            const out = [];
            for (const line of text.trim().split("\n").slice(1)) {
                const [target, used, size, pcent] = line.trim().split(/\s+/);
                if (!target || out.some(d => d.target === target)) continue;
                out.push({ target, used, size, pct: (parseInt(pcent) || 0) / 100 });
            }
            dash.disks = out;
        } }
    }
    Timer {
        interval: 60000; repeat: true; triggeredOnStart: true; running: dash.visible
        onTriggered: { if (!upRead.running) upRead.running = true; if (!diskRead.running) diskRead.running = true; }
    }

    // A small heading over each block (Caption.qml).
    component Heading: Caption {}
    // One reading: name, the last 80 s as bars (oldest faintest), the value.
    component Spark: RowLayout {
        id: spark
        property string name
        property var values: []
        property real ceiling: 100
        property string reading
        property bool hot: false
        spacing: 12
        Text { text: spark.name; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12; Layout.preferredWidth: 34 }
        Item {
            id: plot
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            Repeater {
                model: dash.samples
                Rectangle {
                    required property int index
                    readonly property real v: spark.values[spark.values.length - dash.samples + index] ?? -1
                    readonly property real step: plot.width / dash.samples
                    x: index * step
                    width: Math.max(1, step - 2)
                    anchors.bottom: parent.bottom
                    height: v < 0 ? 2 : 2 + Math.min(1, v / spark.ceiling) * (plot.height - 2)
                    color: spark.hot ? Theme.amber : Theme.accent
                    opacity: v < 0 ? 0.15 : 0.25 + 0.75 * index / dash.samples
                    Behavior on height { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
                }
            }
        }
        Text {
            text: spark.reading
            color: spark.hot ? Theme.amber : Theme.text
            font.family: Theme.font; font.pixelSize: 12; font.bold: true
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 78
        }
    }

    Notch {
        id: box
        anchors.fill: parent
        cut: Theme.notchLarge
        color: Theme.glass
        edge: Theme.edge
        transformOrigin: Item.Top
        PopIn { id: pop; surface: box; inner: body }
        RowLayout {
            id: body
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            spacing: 22

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Heading { text: Qt.formatDate(month.today, "dddd").toUpperCase() }
                Text { text: Qt.formatDate(month.today, "d MMMM"); color: Theme.text; font.family: Theme.font; font.pixelSize: 24; font.bold: true }
                Text {
                    text: "week " + month.isoWeek(month.today) + (dash.uptime ? "  ·  up " + dash.uptime : "")
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
                    Layout.maximumWidth: month.implicitWidth; elide: Text.ElideRight
                }
                MonthView { id: month; Layout.topMargin: 12 }
            }
            Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.edge }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Heading { text: "THIS MACHINE" }
                Spark {
                    Layout.fillWidth: true
                    name: "cpu"; values: dash.cpu
                    reading: dash.cpu.length ? dash.last(dash.cpu) + "%" + (dash.temp !== "-" ? "  " + dash.temp + "°" : "") : "…"
                    hot: dash.last(dash.cpu) >= 90 || Number(dash.temp) >= 85
                }
                Spark {
                    Layout.fillWidth: true
                    visible: dash.gpu.length > 0
                    name: "gpu"; values: dash.gpu
                    reading: dash.last(dash.gpu) + "%"
                }
                Spark {
                    Layout.fillWidth: true
                    name: "mem"; values: dash.mem; ceiling: dash.memTotal || 32
                    reading: dash.mem.length ? dash.last(dash.mem) + (dash.memTotal ? " / " + Math.round(dash.memTotal) : "") + "G" : "…"
                }
                Repeater {
                    model: dash.disks
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 12
                        Text { text: modelData.target === "/" ? "root" : modelData.target.replace(/^\//, ""); color: Theme.muted; font.family: Theme.font; font.pixelSize: 12; Layout.preferredWidth: 34; elide: Text.ElideRight }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 6
                            color: Theme.edge
                            Rectangle {
                                height: parent.height
                                width: parent.width * modelData.pct
                                color: modelData.pct >= 0.9 ? Theme.amber : Theme.accent
                                Behavior on width { NumberAnimation { duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot } }
                            }
                        }
                        Text { text: modelData.used + " / " + modelData.size; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 78 }
                    }
                }

                Heading { text: "THE PI"; Layout.topMargin: 8 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        width: 8; height: 8
                        color: dash.piMs >= 0 ? Theme.accent : Theme.danger
                        SequentialAnimation on opacity {
                            running: dash.visible && dash.piMs >= 0
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: dash.shell.piHost + "  ·  " + (dash.piMs >= 0 ? dash.piMs + " ms" : "not answering")
                        color: dash.piMs >= 0 ? Theme.text : Theme.danger
                        font.family: Theme.font; font.pixelSize: 12
                    }
                    Cell { label: "ssh"; size: 12; onClicked: { dash.visible = false; dash.shell.run(["kitty", "-e", "ssh", "pi"]); } }
                }

                Heading { text: "NOW PLAYING"; Layout.topMargin: 8; visible: dash.shell.player !== null }
                RowLayout {
                    Layout.fillWidth: true
                    visible: dash.shell.player !== null
                    spacing: 12
                    Cover {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        glyphSize: 15
                        source: dash.shell.player?.trackArtUrl ?? ""
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: dash.shell.player?.trackTitle || "Nothing playing"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.bold: true; textFormat: Text.PlainText; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: dash.shell.player?.trackArtist ?? ""; visible: text.length > 0; color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; textFormat: Text.PlainText; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    Cell {
                        label: dash.shell.player?.isPlaying ? "\uf04c" : "\uf04b"; size: 14
                        implicitWidth: 44; selected: true
                        onClicked: if (dash.shell.player?.canTogglePlaying) dash.shell.player.togglePlaying()
                    }
                }
            }
        }
    }
}
