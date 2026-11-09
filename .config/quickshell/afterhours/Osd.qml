import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
// The volume panel: slides down under the rail on the monitor you're on
// whenever the output volume or mute changes (keys, rail, other apps),
// then slides away again. Replaces swayosd so it looks like the shell.
PanelWindow {
    id: osd
    required property var sink
    // Changes in the first seconds are PipeWire settling, not the user.
    property bool armed: false
    // While the rail is up the island shows the volume instead.
    property bool held: false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "afterhours-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true }
    margins { top: 58 }
    implicitWidth: 300
    // 4 px spare under the panel for the spring's overshoot.
    implicitHeight: 56
    color: "transparent"
    visible: false
    mask: Region {}
    Timer { running: true; interval: 2500; onTriggered: osd.armed = true }
    function pop() {
        if (!armed || held) return;
        leave.stop();
        visible = true;
        hide.restart();
        if (pill.y !== 0) enter.restart();
    }
    onVolumeChanged: pop()
    onMutedChanged: pop()
    Timer { id: hide; interval: 1400; onTriggered: leave.restart() }
    Notch {
        id: pill
        width: parent.width; height: 52
        y: -parent.height
        color: Theme.glass
        edge: Theme.edge
        VolumeRow { anchors.centerIn: parent; sink: osd.sink; interactive: false }
    }
    NumberAnimation { id: enter; target: pill; property: "y"; to: 0; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
    SequentialAnimation {
        id: leave
        NumberAnimation { target: pill; property: "y"; to: -osd.height; duration: Theme.glide; easing.type: Easing.InCubic }
        ScriptAction { script: osd.visible = false }
    }
}
