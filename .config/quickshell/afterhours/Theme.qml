pragma Singleton
// Afterhours tokens: dark warm charcoal, phosphor green for focus, blue for
// media and metadata, amber for attention, coral for recording and errors.
// One font for everything (JetBrains Mono, Nerd Font build for the icons).
import QtQuick
QtObject {
    readonly property color background: "#0c0d0b"
    readonly property color panel: "#121411"
    readonly property color raised: "#1a1e19"
    readonly property color line: "#343c31"
    readonly property color muted: "#929c8a"
    readonly property color text: "#dfe3d8"
    readonly property color accent: "#b4c97f"
    readonly property color accentSoft: "#2a3320"
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
