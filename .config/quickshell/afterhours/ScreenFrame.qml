import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
// The screen frame: a thin border round the whole screen with rounded inner
// corners, so windows sit in a frame. The rail's three islands float over
// the wallpaper above it.
// Drawn on the bottom layer: fullscreen windows and games cover it, and
// it never takes a click (empty input mask). The window gaps (12 px)
// leave room for it, so nothing tiles underneath.
PanelWindow {
    id: frame
    required property var modelData
    property int band: 6
    property int side: 6
    property int corner: 22
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
            // Outer edge, then the rounded hole the windows live in.
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
                    + " H" + (rr - r) + " A" + r + "," + r + " 0 0 1 " + rr + "," + (t + r)
                    + " V" + (b - r) + " A" + r + "," + r + " 0 0 1 " + (rr - r) + "," + b
                    + " H" + (l + r) + " A" + r + "," + r + " 0 0 1 " + l + "," + (b - r)
                    + " V" + (t + r) + " A" + r + "," + r + " 0 0 1 " + (l + r) + "," + t + " Z"
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
                    + " H" + (rr - r) + " A" + r + "," + r + " 0 0 1 " + rr + "," + (t + r)
                    + " V" + (b - r) + " A" + r + "," + r + " 0 0 1 " + (rr - r) + "," + b
                    + " H" + (l + r) + " A" + r + "," + r + " 0 0 1 " + l + "," + (b - r)
                    + " V" + (t + r) + " A" + r + "," + r + " 0 0 1 " + (l + r) + "," + t + " Z"
            }
        }
    }
}
