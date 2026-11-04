pragma Singleton
// Afterhours tokens: dark cool charcoal, violet for focus and the active
// thing, amber for attention, coral for recording and errors. No blue in
// the shell (kitty keeps it for ANSI colours).
// One font for everything (JetBrains Mono, Nerd Font build for the icons).
import QtQuick
QtObject {
    readonly property color background: "#0d0c10"
    readonly property color panel: "#131218"
    readonly property color raised: "#1b1a22"
    readonly property color line: "#35323f"
    readonly property color muted: "#948fa3"
    readonly property color text: "#e0dde8"
    readonly property color accent: "#b49cf0"
    readonly property color accentSoft: "#2a2340"
    // The second stop of the violet gradient (window border, sliders).
    readonly property color accentDeep: "#8f7ad9"
    readonly property color danger: "#d9786c"
    readonly property color amber: "#d99f66"
    readonly property string font: "JetBrainsMono Nerd Font"
    // Glass: a violet-grey tint at 55 %, frosted by Hyprland's blur (the
    // "glass" layer rule in rice.lua), a faint light edge instead of a grey
    // outline, and Sheen.qml's light on top. Raised is for hover on glass.
    readonly property color glass: Qt.rgba(0.11, 0.1, 0.145, 0.55)
    readonly property color glassRaised: Qt.rgba(0.19, 0.17, 0.25, 0.72)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.1)
    // A recessed area on glass: the workspace track, the launcher's field,
    // the control centre's switches, inbox cards.
    readonly property color well: Qt.rgba(0, 0, 0, 0.22)
    readonly property int radius: 10
    readonly property int radiusLarge: 20
    // Hover and colour changes; things that move take `glide`.
    readonly property int motion: 200
    readonly property int glide: 320
    // The one spring everything that grows or travels shares: an ease-out
    // that runs a little past the target and settles back (~420 ms).
    readonly property int spring: 420
    readonly property real overshoot: 1.25
}
