import QtQuick
import QtQuick.Shapes
// A panel with its corners cut off at 45 degrees instead of rounded: the
// Notched look. It stands in for a Rectangle: color is the fill, edge the
// 1 px outline (transparent for none). cutInk draws the cuts themselves in
// violet, the mark every floating surface carries (rail, island, cards,
// toasts); buttons leave it off. The rail's pieces and buttons cut
// opposite corners, cards and sheets cut all four.
Item {
    id: notch
    property color color: Theme.glass
    property color edge: "transparent"
    property color cutInk: "transparent"
    property real cut: Theme.notch
    property bool cutTopLeft: true
    property bool cutTopRight: true
    property bool cutBottomRight: true
    property bool cutBottomLeft: true
    // The outline sits half a pixel in, so it lands on whole pixels.
    readonly property real cutSize: Math.max(0, Math.min(cut, width / 2, height / 2))
    readonly property real tl: cutTopLeft ? cutSize : 0
    readonly property real tr: cutTopRight ? cutSize : 0
    readonly property real br: cutBottomRight ? cutSize : 0
    readonly property real bl: cutBottomLeft ? cutSize : 0
    readonly property real x0: 0.5
    readonly property real y0: 0.5
    readonly property real x1: width - 0.5
    readonly property real y1: height - 0.5
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: notch.color
            strokeColor: notch.edge
            strokeWidth: notch.edge.a > 0 ? 1 : -1
            joinStyle: ShapePath.MiterJoin
            PathSvg {
                path: "M" + (notch.x0 + notch.tl) + "," + notch.y0
                    + " L" + (notch.x1 - notch.tr) + "," + notch.y0 + " L" + notch.x1 + "," + (notch.y0 + notch.tr)
                    + " L" + notch.x1 + "," + (notch.y1 - notch.br) + " L" + (notch.x1 - notch.br) + "," + notch.y1
                    + " L" + (notch.x0 + notch.bl) + "," + notch.y1 + " L" + notch.x0 + "," + (notch.y1 - notch.bl)
                    + " L" + notch.x0 + "," + (notch.y0 + notch.tl) + " Z"
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: notch.cutInk
            strokeWidth: notch.cutInk.a > 0 && notch.cutSize > 0 ? 1 : -1
            capStyle: ShapePath.FlatCap
            PathSvg {
                path: (notch.tl ? "M" + notch.x0 + "," + (notch.y0 + notch.tl) + " L" + (notch.x0 + notch.tl) + "," + notch.y0 + " " : "")
                    + (notch.tr ? "M" + (notch.x1 - notch.tr) + "," + notch.y0 + " L" + notch.x1 + "," + (notch.y0 + notch.tr) + " " : "")
                    + (notch.br ? "M" + notch.x1 + "," + (notch.y1 - notch.br) + " L" + (notch.x1 - notch.br) + "," + notch.y1 + " " : "")
                    + (notch.bl ? "M" + (notch.x0 + notch.bl) + "," + notch.y1 + " L" + notch.x0 + "," + (notch.y1 - notch.bl) : "")
            }
        }
    }
}
