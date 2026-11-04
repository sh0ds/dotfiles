import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
// The living wallpaper: the haze picture, with three soft violet clouds
// drifting over it very slowly (one loop takes minutes, and the loop
// closes seamlessly). It only moves
// while the desktop shows: as soon as the workspace on this monitor has a
// window, or the shell is in game mode, the animation stops and the window
// stops rendering, so it costs nothing while you work.
PanelWindow {
    id: wall
    required property var modelData
    property bool still: false
    screen: modelData
    WlrLayershell.namespace: "afterhours-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.background
    readonly property var workspace: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
    readonly property bool bare: (workspace?.toplevels?.values?.length ?? 0) === 0
    readonly property bool drifting: bare && !still
    updatesEnabled: drifting
    Image {
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
        property int period: 90000
        property real dx: 0.12
        property real dy: 0.08
        property real baseX: 0.5
        property real baseY: 0.5
        property real stretch: 1.6
        property real offset: 0
        property real t: 0
        readonly property real phase: t + offset
        readonly property real size: wall.height * 0.75
        width: size; height: size
        x: wall.width * (baseX + dx * Math.sin(phase)) - size / 2
        y: wall.height * (baseY + dy * Math.cos(phase)) - size / 2
        transform: Scale {
            origin.x: cloud.size / 2; origin.y: cloud.size / 2
            xScale: cloud.stretch * (1 + 0.08 * Math.sin(cloud.phase * 2))
            yScale: 1 + 0.08 * Math.sin(cloud.phase * 2)
        }
        preferredRendererType: Shape.CurveRenderer
        // Paused rather than stopped, so it carries on where it was.
        NumberAnimation on t {
            from: 0; to: Math.PI * 2; duration: cloud.period
            loops: Animation.Infinite
            running: true
            paused: !wall.drifting
        }
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
    Cloud { baseX: 0.32; baseY: 0.58; period: 140000; strength: 0.14 }
    Cloud { baseX: 0.70; baseY: 0.42; period: 190000; offset: 2.1; tint: Theme.accentDeep; strength: 0.18; dx: 0.10; dy: 0.12 }
    Cloud { baseX: 0.52; baseY: 0.80; period: 240000; offset: 4.0; strength: 0.08; dx: 0.18; dy: 0.05; stretch: 2.2 }
}
