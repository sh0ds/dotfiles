import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
// The wallpaper: the haze picture with three soft violet clouds over it,
// behind the see-through windows. Still: nothing on it moves.
// `ready` once the picture is drawn (or failed to load), for Arrive.
PanelWindow {
    id: wall
    required property var modelData
    screen: modelData
    WlrLayershell.namespace: "afterhours-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.background
    readonly property bool ready: picture.status === Image.Ready || picture.status === Image.Error
    Image {
        id: picture
        anchors.fill: parent
        source: Quickshell.env("HOME") + "/.local/share/backgrounds/afterhours-haze.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(wall.width, wall.height)
    }
    // A cloud: a circle of violet that fades to nothing at its rim, stretched
    // wide. Drawn as a circle so the gradient reaches zero exactly at the
    // edge; the stretch comes from the Scale transform.
    component Cloud: Shape {
        id: cloud
        property color tint: Theme.accent
        property real strength: 0.16
        property real baseX: 0.5
        property real baseY: 0.5
        property real stretch: 1.6
        readonly property real size: wall.height * 0.75
        width: size; height: size
        x: wall.width * baseX - size / 2
        y: wall.height * baseY - size / 2
        transform: Scale {
            origin.x: cloud.size / 2; origin.y: cloud.size / 2
            xScale: cloud.stretch
        }
        preferredRendererType: Shape.CurveRenderer
        function fog(a) { return Qt.rgba(cloud.tint.r, cloud.tint.g, cloud.tint.b, cloud.strength * a) }
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: cloud.size / 2; centerY: cloud.size / 2
                centerRadius: cloud.size / 2
                focalX: centerX; focalY: centerY
                // A smooth falloff, ending at zero alpha in the same colour,
                // so nothing marks where the cloud stops.
                GradientStop { position: 0.0; color: cloud.fog(1.0) }
                GradientStop { position: 0.3; color: cloud.fog(0.75) }
                GradientStop { position: 0.6; color: cloud.fog(0.32) }
                GradientStop { position: 0.85; color: cloud.fog(0.08) }
                GradientStop { position: 1.0; color: cloud.fog(0.0) }
            }
            PathAngleArc {
                centerX: cloud.size / 2; centerY: cloud.size / 2
                radiusX: cloud.size / 2; radiusY: cloud.size / 2
                startAngle: 0; sweepAngle: 360
            }
        }
    }
    Cloud { baseX: 0.32; baseY: 0.58; strength: 0.26 }
    Cloud { baseX: 0.70; baseY: 0.42; tint: Theme.accentDeep; strength: 0.32 }
    Cloud { baseX: 0.52; baseY: 0.80; strength: 0.16; stretch: 2.2 }
}
