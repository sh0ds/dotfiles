import QtQuick
import QtQuick.Shapes
// A panel with its corners cut off at 45 degrees instead of rounded: the
// Notched look. It stands in for a Rectangle: color is the fill, edge the
// 1 px outline (transparent for none). The rail's pieces cut opposite
// corners, cards and sheets cut all four; everything inside them is square.
Item {
    id: notch
    property color color: Theme.glass
    property color edge: "transparent"
    property real cut: Theme.notch
    property bool cutTopLeft: true
    property bool cutTopRight: true
    property bool cutBottomRight: true
    property bool cutBottomLeft: true
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: notch.color
            strokeColor: notch.edge
            strokeWidth: notch.edge.a > 0 ? 1 : -1
            joinStyle: ShapePath.MiterJoin
            // Half a pixel in, so the outline lands on whole pixels.
            PathSvg {
                readonly property real c: Math.max(0, Math.min(notch.cut, notch.width / 2, notch.height / 2))
                readonly property real tl: notch.cutTopLeft ? c : 0
                readonly property real tr: notch.cutTopRight ? c : 0
                readonly property real br: notch.cutBottomRight ? c : 0
                readonly property real bl: notch.cutBottomLeft ? c : 0
                readonly property real l: 0.5
                readonly property real t: 0.5
                readonly property real r: notch.width - 0.5
                readonly property real b: notch.height - 0.5
                path: "M" + (l + tl) + "," + t
                    + " L" + (r - tr) + "," + t + " L" + r + "," + (t + tr)
                    + " L" + r + "," + (b - br) + " L" + (r - br) + "," + b
                    + " L" + (l + bl) + "," + b + " L" + l + "," + (b - bl)
                    + " L" + l + "," + (t + tl) + " Z"
            }
        }
    }
}
