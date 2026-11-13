import QtQuick
import Quickshell
import Quickshell.Wayland
// Arriving: the first second of a session. The boot splash and the login
// both end on the Afterhours mark over charcoal; this starts as that same
// picture (the mark's bottom edge 24 px above the middle) on every screen,
// over everything, then lets go and the desktop is there. Only shown when
// Hyprland starts the shell (`afterhours start --arrive`), never on a
// restart. Clicks pass through it.
// It lets go once the wallpaper is drawn on every screen (`ready`; at login
// once the lock holds, which covers it anyway), never
// sooner than 300 ms and never later than 2.5 s, so a slow first start
// doesn't show a half-built desktop and a fast one doesn't wait for nothing.
// The swaybg that held the mark until the shell was up goes first.
PanelWindow {
    id: arrive
    required property var modelData
    screen: modelData
    WlrLayershell.namespace: "afterhours-arrive"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}
    property bool ready: false
    property bool settled: false
    Timer { running: true; interval: 300; onTriggered: arrive.settled = true }
    property bool going: false
    function go() { if (going) return; going = true; leave.start(); }
    Timer { running: true; interval: 2500; onTriggered: arrive.go() }
    onReadyChanged: if (ready && settled) go()
    onSettledChanged: if (ready && settled) go()
    Rectangle { id: curtain; anchors.fill: parent; color: Theme.background }
    Image {
        id: mark
        source: "mark.png"
        x: Math.round((arrive.width - width) / 2)
        y: Math.round(arrive.height / 2 - height - 24)
        smooth: false
    }
    SequentialAnimation {
        id: leave
        ScriptAction { script: Quickshell.execDetached(["pkill", "-x", "swaybg"]) }
        // One frame for the rail to settle after the wallpaper.
        PauseAnimation { duration: 80 }
        ParallelAnimation {
            NumberAnimation { target: curtain; property: "opacity"; to: 0; duration: 800; easing.type: Easing.OutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 150 }
                NumberAnimation { target: mark; property: "opacity"; to: 0; duration: 450; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: arrive.visible = false }
    }
}
