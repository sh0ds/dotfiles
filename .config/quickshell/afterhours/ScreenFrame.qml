import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
// The screen frame: a thin border round the whole screen with notched inner
// corners (cut at 45 degrees, like the rail), so windows sit in a frame. The rail's three islands float over
// the wallpaper above it.
// Drawn on the bottom layer: fullscreen windows and games cover it, and
// it never takes a click (empty input mask). The window gaps (12 px)
// leave room for it, so nothing tiles underneath.
PanelWindow {
    id: frame
    required property var modelData
    property int band: 6
    property int side: 6
    property int corner: Theme.notch
    screen: modelData
    WlrLayershell.namespace: "afterhours-frame"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillColor: Theme.background
            fillRule: ShapePath.OddEvenFill
            // Outer edge, then the notched hole the windows live in.
            PathSvg {
                readonly property real w: frame.width
                readonly property real h: frame.height
                readonly property real l: frame.side
                readonly property real t: frame.band
                readonly property real r: frame.corner
                readonly property real rr: w - frame.side
                readonly property real b: h - frame.side
                path: "M0,0 H" + w + " V" + h + " H0 Z "
                    + "M" + (l + r) + "," + t
                    + " H" + (rr - r) + " L" + rr + "," + (t + r)
                    + " V" + (b - r) + " L" + (rr - r) + "," + b
                    + " H" + (l + r) + " L" + l + "," + (b - r)
                    + " V" + (t + r) + " L" + (l + r) + "," + t + " Z"
            }
        }
        // A faint light hairline along the inner edge, like the glass edges.
        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.edge
            fillColor: "transparent"
            PathSvg {
                readonly property real l: frame.side + 0.5
                readonly property real t: frame.band + 0.5
                readonly property real r: frame.corner
                readonly property real rr: frame.width - frame.side - 0.5
                readonly property real b: frame.height - frame.side - 0.5
                path: "M" + (l + r) + "," + t
                    + " H" + (rr - r) + " L" + rr + "," + (t + r)
                    + " V" + (b - r) + " L" + (rr - r) + "," + b
                    + " H" + (l + r) + " L" + l + "," + (b - r)
                    + " V" + (t + r) + " L" + (l + r) + "," + t + " Z"
            }
        }
    }
}
