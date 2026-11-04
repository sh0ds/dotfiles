pragma Singleton
// Afterhours tokens: dark cool charcoal, violet for focus and the active
// thing, amber for attention, coral for recording and errors. Blue is kept
// for the terminal's ANSI colours only.
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
    readonly property color blue: "#5e9bb4"
    readonly property color danger: "#d9786c"
    readonly property color amber: "#d99f66"
    readonly property string font: "JetBrainsMono Nerd Font"
    // Kept so older call sites resolve; all three are the same font now.
    readonly property string mono: font
    readonly property string display: font
    readonly property string sans: font
    readonly property int radius: 8
    readonly property int radiusLarge: 14
    // Hover and colour changes; things that move take `glide`.
    readonly property int motion: 200
    readonly property int glide: 320
}
