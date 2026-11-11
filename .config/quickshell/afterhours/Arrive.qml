import QtQuick
import Quickshell
import Quickshell.Wayland
// Arriving: the first second of a session. The boot splash and the login
// both end on the Afterhours mark over charcoal; this starts as that same
// picture (the mark's bottom edge 24 px above the middle) on every screen,
// over everything, then lets go and the desktop is there. Only shown when
// Hyprland starts the shell (`afterhours start --arrive`), never on a
// restart. Clicks pass through it.
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
    Rectangle { id: curtain; anchors.fill: parent; color: Theme.background }
    Image {
        id: mark
        source: "mark.png"
        x: Math.round((arrive.width - width) / 2)
        y: Math.round(arrive.height / 2 - height - 24)
        smooth: false
    }
    SequentialAnimation {
        running: true
        // Long enough for the wallpaper and the rail to be drawn underneath.
        PauseAnimation { duration: 500 }
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
